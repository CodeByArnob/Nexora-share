//! Streaming SHA-256 integrity verification and chunk validation for NEXORA.

use sha2::{Digest, Sha256};
use std::fs::File;
use std::io::{BufReader, Read};
use std::path::Path;
use thiserror::Error;

#[derive(Debug, Error)]
pub enum VerificationError {
    #[error("I/O error while reading file for verification: {0}")]
    IoError(#[from] std::io::Error),

    #[error("Hex decoding error: {0}")]
    HexError(#[from] hex::FromHexError),

    #[error("Checksum mismatch: expected '{expected}', computed '{computed}'")]
    ChecksumMismatch { expected: String, computed: String },
}

/// Computes the hex-encoded SHA-256 hash of a memory slice.
pub fn compute_sha256(bytes: &[u8]) -> String {
    let mut hasher = Sha256::new();
    hasher.update(bytes);
    hex::encode(hasher.finalize())
}

/// Verifies whether the provided chunk bytes match the expected SHA-256 hex string.
pub fn verify_chunk(bytes: &[u8], expected_sha256: &str) -> bool {
    let computed = compute_sha256(bytes);
    computed.eq_ignore_ascii_case(expected_sha256)
}

/// Incremental streaming hasher for files and streams.
pub struct StreamingHasher {
    hasher: Sha256,
    bytes_processed: u64,
}

impl Default for StreamingHasher {
    fn default() -> Self {
        Self::new()
    }
}

impl StreamingHasher {
    pub fn new() -> Self {
        Self {
            hasher: Sha256::new(),
            bytes_processed: 0,
        }
    }

    /// Feeds a chunk of bytes to the streaming hasher.
    pub fn update(&mut self, chunk: &[u8]) {
        self.hasher.update(chunk);
        self.bytes_processed += chunk.len() as u64;
    }

    pub fn bytes_processed(&self) -> u64 {
        self.bytes_processed
    }

    /// Consumes the hasher and outputs the final hex digest.
    pub fn finalize(self) -> String {
        hex::encode(self.hasher.finalize())
    }
}

/// Verifies a complete file against an expected SHA-256 hash using bounded buffer streaming.
pub fn verify_file_sha256(path: &Path, expected_hex: &str) -> Result<bool, VerificationError> {
    let file = File::open(path)?;
    let mut reader = BufReader::with_capacity(64 * 1024, file);
    let mut streaming = StreamingHasher::new();
    let mut buffer = [0u8; 64 * 1024];

    loop {
        let count = reader.read(&mut buffer)?;
        if count == 0 {
            break;
        }
        streaming.update(&buffer[..count]);
    }

    let computed = streaming.finalize();
    if computed.eq_ignore_ascii_case(expected_hex) {
        Ok(true)
    } else {
        Err(VerificationError::ChecksumMismatch {
            expected: expected_hex.to_string(),
            computed,
        })
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_compute_sha256_known_vector() {
        // SHA-256("NEXORA")
        let hash = compute_sha256(b"NEXORA");
        assert_eq!(
            hash,
            "1151b79b4a2e1ea489d5c1ffaa3955e305e3f1bd1364eff88a20870065ae11aa"
        );
    }

    #[test]
    fn test_verify_chunk() {
        let data = b"Chunk payload data 1234567890";
        let expected = compute_sha256(data);
        assert!(verify_chunk(data, &expected));
        assert!(!verify_chunk(b"Corrupted data", &expected));
    }

    #[test]
    fn test_streaming_hasher() {
        let mut stream = StreamingHasher::new();
        stream.update(b"NEX");
        stream.update(b"ORA");
        assert_eq!(stream.bytes_processed(), 6);
        assert_eq!(
            stream.finalize(),
            "169992f15dc8ca620b7ba405628b030491a9235e8f4cbcf3046bc9ae62e9ddab"
        );
    }
}
