//! Wire protocol definitions, framing, schema validation and error codes for NEXORA.

use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use thiserror::Error;
use uuid::Uuid;

/// Current supported NEXORA wire protocol version.
pub const CURRENT_PROTOCOL_VERSION: u32 = 1;

/// Maximum allowed message frame size in bytes (5 MB: chunks are max 1-4 MB).
pub const MAX_FRAME_SIZE: usize = 5 * 1024 * 1024;

/// Standard length prefix size in bytes (4-byte big endian u32).
pub const LENGTH_PREFIX_SIZE: usize = 4;

#[derive(Debug, Error, PartialEq, Eq)]
pub enum ProtocolError {
    #[error("Message length {0} exceeds maximum allowed frame size {MAX_FRAME_SIZE}")]
    FrameTooLarge(usize),

    #[error("Incomplete frame: expected at least {expected} bytes, got {actual}")]
    IncompleteFrame { expected: usize, actual: usize },

    #[error("Failed to serialize message: {0}")]
    SerializationError(String),

    #[error("Failed to deserialize message: {0}")]
    DeserializationError(String),

    #[error("Unsupported protocol version: {version}")]
    UnsupportedVersion { version: u32 },

    #[error("Protocol error code {code:?}: {message}")]
    RemoteError {
        code: ErrorCode,
        message: String,
        details: Option<String>,
    },
}

/// Official NEXORA error codes specified in Section 17 of PRD.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "SCREAMING_SNAKE_CASE")]
pub enum ErrorCode {
    DeviceNotFound,
    DeviceOffline,
    PairingRejected,
    PairingExpired,
    AuthenticationFailed,
    CertificateInvalid,
    NetworkUnavailable,
    ConnectionTimeout,
    ReceiverBusy,
    InsufficientStorage,
    FileAccessDenied,
    FileAlreadyExists,
    InvalidFilename,
    TransferInterrupted,
    ChecksumMismatch,
    ProtocolVersionUnsupported,
}

impl ErrorCode {
    /// Safe user-friendly recovery guidance for each error code.
    pub fn recovery_guidance(&self) -> &'static str {
        match self {
            Self::DeviceNotFound => "Ensure both devices are on the same Wi-Fi network and discovery is enabled.",
            Self::DeviceOffline => "The target device went offline or closed NEXORA. Check its connection.",
            Self::PairingRejected => "The pairing invitation was declined by the remote device.",
            Self::PairingExpired => "The pairing challenge timed out. Please initiate pairing again.",
            Self::AuthenticationFailed => "Cryptographic authentication failed. Verify identity or re-pair devices.",
            Self::CertificateInvalid => "TLS certificate validation failed. Ensure correct device certificates.",
            Self::NetworkUnavailable => "No active network interface was detected. Check your Wi-Fi or local network.",
            Self::ConnectionTimeout => "The connection timed out. Check network firewalls or router client isolation.",
            Self::ReceiverBusy => "The receiving device is currently busy with another transfer.",
            Self::InsufficientStorage => "The destination drive does not have enough free space for the incoming files.",
            Self::FileAccessDenied => "File access was denied by the operating system. Check file and folder permissions.",
            Self::FileAlreadyExists => "A file with the same name already exists and overwrite protection prevented replacement.",
            Self::InvalidFilename => "The file name contains illegal characters or attempted path traversal.",
            Self::TransferInterrupted => "The transfer stream was interrupted. You can resume from the last verified chunk.",
            Self::ChecksumMismatch => "SHA-256 verification failed. The received data is corrupted.",
            Self::ProtocolVersionUnsupported => "The remote device uses an incompatible NEXORA protocol version. Please update.",
        }
    }
}

/// Device metadata exchanged during discovery and pairing.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct DeviceInfo {
    pub device_id: String,
    pub display_name: String,
    pub platform: String,
    pub protocol_version: u32,
    pub fingerprint: String,
}

/// Metadata describing an individual file in a transfer manifest.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct FileMetadata {
    pub file_id: String,
    pub name: String,
    pub relative_path: Option<String>,
    pub size_bytes: u64,
    pub sha256_hash: Option<String>,
    pub mime_type: Option<String>,
}

/// Overall transfer manifest.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct TransferManifest {
    pub transfer_id: Uuid,
    pub total_files: u32,
    pub total_bytes: u64,
    pub files: Vec<FileMetadata>,
    pub chunk_size: u32,
}

/// All official wire messages mandated by Section 12 of NEXORA PRD.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
#[serde(tag = "type", content = "payload")]
pub enum WireMessage {
    Hello {
        protocol_version: u32,
        device: DeviceInfo,
    },
    DiscoveryInfo {
        device: DeviceInfo,
        port: u16,
    },
    PairRequest {
        session_id: Uuid,
        initiator: DeviceInfo,
        sas_code: String,
        timestamp: DateTime<Utc>,
    },
    PairChallenge {
        session_id: Uuid,
        challenge_nonce: String,
        expires_at: DateTime<Utc>,
    },
    PairConfirm {
        session_id: Uuid,
        accepted: bool,
        signature: Option<String>,
    },
    SessionReady {
        session_id: Uuid,
        established_at: DateTime<Utc>,
    },
    TransferOffer {
        transfer_id: Uuid,
        sender: DeviceInfo,
        manifest: TransferManifest,
    },
    TransferAccept {
        transfer_id: Uuid,
        accepted_file_ids: Vec<String>,
    },
    TransferReject {
        transfer_id: Uuid,
        reason: String,
    },
    TransferStart {
        transfer_id: Uuid,
    },
    ChunkData {
        transfer_id: Uuid,
        file_id: String,
        chunk_index: u64,
        total_chunks: u64,
        offset: u64,
        data: Vec<u8>,
        chunk_sha256: String,
    },
    ChunkAck {
        transfer_id: Uuid,
        file_id: String,
        chunk_index: u64,
        verified: bool,
    },
    TransferPause {
        transfer_id: Uuid,
    },
    TransferResume {
        transfer_id: Uuid,
        last_verified_chunk: u64,
    },
    TransferCancel {
        transfer_id: Uuid,
        reason: String,
    },
    TransferComplete {
        transfer_id: Uuid,
        verified_files: u32,
    },
    TransferError {
        transfer_id: Option<Uuid>,
        code: ErrorCode,
        message: String,
        details: Option<String>,
    },
}

/// Encodes a WireMessage into a 4-byte length-prefixed binary frame.
pub fn encode_frame(msg: &WireMessage) -> Result<Vec<u8>, ProtocolError> {
    let payload =
        serde_json::to_vec(msg).map_err(|e| ProtocolError::SerializationError(e.to_string()))?;

    let length = payload.len();
    if length > MAX_FRAME_SIZE {
        return Err(ProtocolError::FrameTooLarge(length));
    }

    let mut frame = Vec::with_capacity(LENGTH_PREFIX_SIZE + length);
    frame.extend_from_slice(&(length as u32).to_be_bytes());
    frame.extend_from_slice(&payload);
    Ok(frame)
}

/// Decodes a 4-byte length-prefixed binary frame into a WireMessage.
pub fn decode_frame(bytes: &[u8]) -> Result<WireMessage, ProtocolError> {
    if bytes.len() < LENGTH_PREFIX_SIZE {
        return Err(ProtocolError::IncompleteFrame {
            expected: LENGTH_PREFIX_SIZE,
            actual: bytes.len(),
        });
    }

    let length = u32::from_be_bytes([bytes[0], bytes[1], bytes[2], bytes[3]]) as usize;
    if length > MAX_FRAME_SIZE {
        return Err(ProtocolError::FrameTooLarge(length));
    }

    let total_required = LENGTH_PREFIX_SIZE + length;
    if bytes.len() < total_required {
        return Err(ProtocolError::IncompleteFrame {
            expected: total_required,
            actual: bytes.len(),
        });
    }

    let payload = &bytes[LENGTH_PREFIX_SIZE..total_required];
    serde_json::from_slice(payload).map_err(|e| ProtocolError::DeserializationError(e.to_string()))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_hello_encode_decode_roundtrip() {
        let msg = WireMessage::Hello {
            protocol_version: CURRENT_PROTOCOL_VERSION,
            device: DeviceInfo {
                device_id: "nexora-device-123".into(),
                display_name: "Pixel 9 Pro".into(),
                platform: "android".into(),
                protocol_version: CURRENT_PROTOCOL_VERSION,
                fingerprint: "abc123sha256fingerprint".into(),
            },
        };

        let encoded = encode_frame(&msg).expect("Encoding should succeed");
        assert!(encoded.len() > LENGTH_PREFIX_SIZE);

        let decoded = decode_frame(&encoded).expect("Decoding should succeed");
        assert_eq!(msg, decoded);
    }

    #[test]
    fn test_chunk_data_frame() {
        let chunk_data = vec![0xAB; 4096];
        let msg = WireMessage::ChunkData {
            transfer_id: Uuid::new_v4(),
            file_id: "file-01".into(),
            chunk_index: 0,
            total_chunks: 10,
            offset: 0,
            data: chunk_data.clone(),
            chunk_sha256: "dummy-hash".into(),
        };

        let encoded = encode_frame(&msg).expect("Encoding should succeed");
        let decoded = decode_frame(&encoded).expect("Decoding should succeed");
        assert_eq!(msg, decoded);
    }

    #[test]
    fn test_error_code_guidance() {
        assert_eq!(
            ErrorCode::ChecksumMismatch.recovery_guidance(),
            "SHA-256 verification failed. The received data is corrupted."
        );
    }

    #[test]
    fn test_frame_too_large_rejection() {
        // Construct a frame header stating size > MAX_FRAME_SIZE
        let invalid_len = (MAX_FRAME_SIZE + 1) as u32;
        let mut header = invalid_len.to_be_bytes().to_vec();
        header.extend(vec![0u8; 10]);

        let result = decode_frame(&header);
        assert!(matches!(result, Err(ProtocolError::FrameTooLarge(_))));
    }
}
