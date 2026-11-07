//! Framed network transport, async reader/writer with length prefixing and timeouts for NEXORA.

use nexora_protocol::{decode_frame, encode_frame, ProtocolError, WireMessage, LENGTH_PREFIX_SIZE, MAX_FRAME_SIZE};
use std::time::Duration;
use thiserror::Error;
use tokio::io::{AsyncRead, AsyncReadExt, AsyncWrite, AsyncWriteExt};
use tokio::time::timeout;

#[derive(Debug, Error)]
pub enum TransportError {
    #[error("I/O error during network operation: {0}")]
    Io(#[from] std::io::Error),

    #[error("Protocol error: {0}")]
    Protocol(#[from] ProtocolError),

    #[error("Network operation timed out after {0:?}")]
    Timeout(Duration),

    #[error("Connection closed by remote peer")]
    ConnectionClosed,
}

/// Reads a single length-prefixed WireMessage from an async stream.
pub async fn read_framed_message<R>(
    reader: &mut R,
    read_timeout: Duration,
) -> Result<WireMessage, TransportError>
where
    R: AsyncRead + Unpin,
{
    let read_future = async {
        let mut len_buf = [0u8; LENGTH_PREFIX_SIZE];
        reader.read_exact(&mut len_buf).await.map_err(|e| {
            if e.kind() == std::io::ErrorKind::UnexpectedEof {
                TransportError::ConnectionClosed
            } else {
                TransportError::Io(e)
            }
        })?;

        let length = u32::from_be_bytes(len_buf) as usize;
        if length > MAX_FRAME_SIZE {
            return Err(TransportError::Protocol(ProtocolError::FrameTooLarge(length)));
        }

        let mut payload_buf = vec![0u8; length];
        reader.read_exact(&mut payload_buf).await?;

        let mut full_frame = Vec::with_capacity(LENGTH_PREFIX_SIZE + length);
        full_frame.extend_from_slice(&len_buf);
        full_frame.extend_from_slice(&payload_buf);

        let msg = decode_frame(&full_frame)?;
        Ok(msg)
    };

    match timeout(read_timeout, read_future).await {
        Ok(res) => res,
        Err(_) => Err(TransportError::Timeout(read_timeout)),
    }
}

/// Writes a single length-prefixed WireMessage to an async stream.
pub async fn write_framed_message<W>(
    writer: &mut W,
    msg: &WireMessage,
    write_timeout: Duration,
) -> Result<(), TransportError>
where
    W: AsyncWrite + Unpin,
{
    let frame = encode_frame(msg)?;

    let write_future = async {
        writer.write_all(&frame).await?;
        writer.flush().await?;
        Ok(())
    };

    match timeout(write_timeout, write_future).await {
        Ok(res) => res,
        Err(_) => Err(TransportError::Timeout(write_timeout)),
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use nexora_protocol::{CURRENT_PROTOCOL_VERSION, DeviceInfo};

    #[tokio::test]
    async fn test_duplex_framed_transport() {
        let (mut client, mut server) = tokio::io::duplex(64 * 1024);

        let test_msg = WireMessage::Hello {
            protocol_version: CURRENT_PROTOCOL_VERSION,
            device: DeviceInfo {
                device_id: "test-device-42".into(),
                display_name: "Test Laptop".into(),
                platform: "windows".into(),
                protocol_version: CURRENT_PROTOCOL_VERSION,
                fingerprint: "abc123fingerprint".into(),
            },
        };

        // Write from client to server
        write_framed_message(&mut client, &test_msg, Duration::from_secs(5))
            .await
            .expect("Writing framed message must succeed");

        // Read on server
        let received = read_framed_message(&mut server, Duration::from_secs(5))
            .await
            .expect("Reading framed message must succeed");

        assert_eq!(test_msg, received);
    }

    #[tokio::test]
    async fn test_read_timeout() {
        let (mut _client, mut server) = tokio::io::duplex(64 * 1024);

        let result = read_framed_message(&mut server, Duration::from_millis(100)).await;
        assert!(matches!(result, Err(TransportError::Timeout(_))));
    }
}
