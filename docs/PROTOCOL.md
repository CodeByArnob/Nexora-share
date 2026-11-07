# NEXORA Protocol Specification (v1.0)

## 1. Overview & Core Philosophy

NEXORA uses a high-performance, length-prefixed, privacy-first peer-to-peer wire protocol over local networks (TCP/TLS 1.3). It requires no accounts, no central coordination servers, and no internet access.

All network messages are treated as **untrusted input** and subject to strict schema validation, frame length bounds, and replay protection.

---

## 2. Framing & Transport Layer

### 2.1 Frame Format
Every wire packet is framed by a 4-byte big-endian unsigned 32-bit integer length prefix, followed by the UTF-8 JSON payload:

```
+-----------------------------------+-----------------------------------------+
| Length Prefix (4 bytes, Big-Endian)| Payload (JSON UTF-8, `Length` bytes)    |
+-----------------------------------+-----------------------------------------+
```

### 2.2 Bounds & Constraints
- **Maximum Frame Size**: `5,242,880 bytes` (5 MiB). Any frame indicating length > 5 MiB is dropped immediately with `FrameTooLarge` error and connection terminated.
- **Default Chunk Size**: `1,048,576 bytes` (1 MiB).
- **Socket Timeouts**: Standard frame read/write timeout is `15 seconds`. Keepalive interval is `30 seconds`.

---

## 3. Protocol Message Set

All messages conform to the tagged JSON schema:
```json
{
  "type": "<MESSAGE_TYPE>",
  "payload": { ... }
}
```

### 3.1 Handshake & Discovery
- **`HELLO`**: Initiates protocol version negotiation and exchanges device metadata.
  ```json
  {
    "type": "Hello",
    "payload": {
      "protocol_version": 1,
      "device": {
        "device_id": "nexora-a1b2c3d4",
        "display_name": "Pixel 9 Pro",
        "platform": "android",
        "protocol_version": 1,
        "fingerprint": "<64-hex-sha256-of-ed25519-public-key>"
      }
    }
  }
  ```
- **`DISCOVERY_INFO`**: Broadcast via mDNS (`_nexora._tcp.local.`) or direct socket.

### 3.2 Secure Pairing & Authentication
- **`PAIR_REQUEST`**: Initiates pairing with a 6-digit Short Authentication String (SAS) code and timestamp.
- **`PAIR_CHALLENGE`**: Remote peer returns a 16-byte cryptographically secure random nonce with expiration timestamp.
- **`PAIR_CONFIRM`**: Initiator returns Ed25519 signature over the challenge nonce.
- **`SESSION_READY`**: Both sides establish an authenticated transfer session.

### 3.3 Transfer Negotiation (Receiver Approval)
- **`TRANSFER_OFFER`**: Sender presents complete manifest.
  ```json
  {
    "type": "TransferOffer",
    "payload": {
      "transfer_id": "9b1deb4d-3b7d-4bad-9bdd-2b0d7b3dcb6d",
      "sender": { ... },
      "manifest": {
        "transfer_id": "9b1deb4d-3b7d-4bad-9bdd-2b0d7b3dcb6d",
        "total_files": 2,
        "total_bytes": 104857600,
        "chunk_size": 1048576,
        "files": [
          {
            "file_id": "f-1",
            "name": "presentation.pdf",
            "relative_path": null,
            "size_bytes": 104857600,
            "sha256_hash": null,
            "mime_type": "application/pdf"
          }
        ]
      }
    }
  }
  ```
- **`TRANSFER_ACCEPT`**: Explicit receiver approval detailing accepted file IDs.
- **`TRANSFER_REJECT`**: Explicit receiver rejection with reason code.
- **`TRANSFER_START`**: Sender signals chunk transmission kickoff.

### 3.4 Data Streaming & Chunk Acknowledgments
- **`CHUNK_DATA`**: Fixed-size chunk stream with individual SHA-256 chunk checksums.
  ```json
  {
    "type": "ChunkData",
    "payload": {
      "transfer_id": "...",
      "file_id": "f-1",
      "chunk_index": 0,
      "total_chunks": 100,
      "offset": 0,
      "data": [ ... ],
      "chunk_sha256": "..."
    }
  }
  ```
- **`CHUNK_ACK`**: Receiver acknowledges verified chunk write to disk.

### 3.5 Session Control & Recovery
- **`TRANSFER_PAUSE`**: Pauses stream without disconnecting.
- **`TRANSFER_RESUME`**: Resumes from last verified chunk index.
- **`TRANSFER_CANCEL`**: Graceful cancellation by sender or receiver.
- **`TRANSFER_COMPLETE`**: Completion report with total verified file count.
- **`TRANSFER_ERROR`**: Standardized error envelope.

---

## 4. Standardized Error Codes

| Code | Reason | User Recovery Guidance |
|---|---|---|
| `DEVICE_NOT_FOUND` | Target device unreachable | Check Wi-Fi connection and discovery settings. |
| `DEVICE_OFFLINE` | Remote peer disconnected | Remote device went offline. |
| `PAIRING_REJECTED` | User tapped Decline | Pairing was declined on the remote device. |
| `PAIRING_EXPIRED` | Challenge TTL elapsed | Pairing timed out. Please initiate pairing again. |
| `AUTHENTICATION_FAILED` | Cryptographic signature failure | Cryptographic authentication failed. Re-pair devices. |
| `CERTIFICATE_INVALID` | TLS certificate issue | Certificate validation failed. |
| `NETWORK_UNAVAILABLE` | No network interface found | Check your Wi-Fi or local network connection. |
| `CONNECTION_TIMEOUT` | Socket timed out | Connection timed out. Check router isolation/firewalls. |
| `RECEIVER_BUSY` | Active transfer in progress | The receiver is currently busy with another transfer. |
| `INSUFFICIENT_STORAGE` | Not enough disk space | Destination drive has insufficient free space. |
| `FILE_ACCESS_DENIED` | OS permissions error | Check file and folder read/write permissions. |
| `FILE_ALREADY_EXISTS` | Overwrite protection | A file with the same name exists and cannot be overwritten. |
| `INVALID_FILENAME` | Illegal character or path traversal | Path contains illegal characters or traversal tokens. |
| `TRANSFER_INTERRUPTED` | Network dropped mid-stream | Transfer interrupted. Can resume from last chunk. |
| `CHECKSUM_MISMATCH` | SHA-256 validation failure | Received file data failed SHA-256 verification. |
| `PROTOCOL_VERSION_UNSUPPORTED`| Incompatible version | Remote device uses an incompatible version. Update app. |

---

## 5. Security & Threat Model

1. **Path Traversal Protection**: Relative paths are parsed component by component. Any `..`, root directories, or Windows drive prefixes are rejected.
2. **Replay Protection**: Messages must include valid timestamps within a 60-second drift window; challenge nonces are tracked in memory.
3. **Bounded Memory Streaming**: Chunks are streamed in 1 MiB slices with OS backpressure, ensuring low memory footprint even for 10+ GB files.
4. **No Plaintext Fallback**: Direct peer data exchange runs over TLS 1.3 or authenticated Ed25519 signed sessions.
