//! Bounded streaming file transfer engine, chunking, and progress calculation for NEXORA.

use nexora_protocol::{FileMetadata, TransferManifest};
use nexora_verification::compute_sha256;
use std::fs::File;
use std::io::{Read, Seek, SeekFrom, Write};
use std::path::Path;
use std::time::Instant;
use thiserror::Error;
use uuid::Uuid;

/// Default transfer chunk size: 1 MiB (1,048,576 bytes).
pub const DEFAULT_CHUNK_SIZE: u32 = 1024 * 1024;

#[derive(Debug, Error)]
pub enum TransferEngineError {
    #[error("I/O error: {0}")]
    Io(#[from] std::io::Error),

    #[error("Invalid chunk offset {offset} for file size {size}")]
    InvalidOffset { offset: u64, size: u64 },

    #[error("Integrity error: {0}")]
    Integrity(String),
}

/// Dynamic real-time transfer progress report.
#[derive(Debug, Clone, PartialEq)]
pub struct TransferProgress {
    pub transfer_id: Uuid,
    pub bytes_transferred: u64,
    pub total_bytes: u64,
    pub speed_bytes_per_sec: f64,
    pub eta_seconds: u64,
    pub current_file: String,
    pub files_completed: u32,
    pub total_files: u32,
    pub percentage: f32,
}

/// Helper for calculating transfer speed and ETA.
pub struct ProgressEstimator {
    transfer_id: Uuid,
    total_bytes: u64,
    total_files: u32,
    start_time: Instant,
    last_update: Instant,
    last_bytes: u64,
    current_speed_bps: f64,
}

impl ProgressEstimator {
    pub fn new(transfer_id: Uuid, total_bytes: u64, total_files: u32) -> Self {
        let now = Instant::now();
        Self {
            transfer_id,
            total_bytes,
            total_files,
            start_time: now,
            last_update: now,
            last_bytes: 0,
            current_speed_bps: 0.0,
        }
    }

    /// Computes updated progress with exponential moving average speed and ETA.
    pub fn update(
        &mut self,
        bytes_transferred: u64,
        current_file: String,
        files_completed: u32,
    ) -> TransferProgress {
        let now = Instant::now();
        let elapsed_since_last = now.duration_since(self.last_update).as_secs_f64();

        if elapsed_since_last >= 0.25 {
            let bytes_delta = bytes_transferred.saturating_sub(self.last_bytes);
            let instant_speed = (bytes_delta as f64) / elapsed_since_last;

            // Simple EMA filter for smooth UI display
            if self.current_speed_bps == 0.0 {
                self.current_speed_bps = instant_speed;
            } else {
                self.current_speed_bps = (self.current_speed_bps * 0.7) + (instant_speed * 0.3);
            }

            self.last_bytes = bytes_transferred;
            self.last_update = now;
        }

        let remaining_bytes = self.total_bytes.saturating_sub(bytes_transferred);
        let eta_seconds = if self.current_speed_bps > 0.0 {
            (remaining_bytes as f64 / self.current_speed_bps) as u64
        } else {
            0
        };

        let percentage = if self.total_bytes > 0 {
            (bytes_transferred as f32 / self.total_bytes as f32) * 100.0
        } else {
            100.0
        };

        TransferProgress {
            transfer_id: self.transfer_id,
            bytes_transferred,
            total_bytes: self.total_bytes,
            speed_bytes_per_sec: self.current_speed_bps,
            eta_seconds,
            current_file,
            files_completed,
            total_files: self.total_files,
            percentage,
        }
    }
}

/// Reads a specific chunk from a file without loading the whole file into memory.
pub fn read_file_chunk(
    path: &Path,
    offset: u64,
    chunk_size: u32,
) -> Result<(Vec<u8>, String), TransferEngineError> {
    let mut file = File::open(path)?;
    let metadata = file.metadata()?;
    let file_size = metadata.len();

    if offset > file_size {
        return Err(TransferEngineError::InvalidOffset {
            offset,
            size: file_size,
        });
    }

    file.seek(SeekFrom::Start(offset))?;

    let bytes_to_read = std::cmp::min(chunk_size as u64, file_size - offset) as usize;
    let mut buffer = vec![0u8; bytes_to_read];
    file.read_exact(&mut buffer)?;

    let chunk_hash = compute_sha256(&buffer);
    Ok((buffer, chunk_hash))
}

/// Writes a chunk to an existing or new destination file at the specified offset.
pub fn write_file_chunk(path: &Path, offset: u64, data: &[u8]) -> Result<(), TransferEngineError> {
    let mut file = std::fs::OpenOptions::new()
        .write(true)
        .create(true)
        .open(path)?;

    file.seek(SeekFrom::Start(offset))?;
    file.write_all(data)?;
    file.flush()?;
    Ok(())
}

/// Builds a transfer manifest from a collection of local file paths.
pub fn build_manifest_from_files(
    transfer_id: Uuid,
    files: &[(String, &Path)], // (relative_or_name, absolute_path)
    chunk_size: u32,
) -> Result<TransferManifest, TransferEngineError> {
    let mut total_bytes = 0u64;
    let mut file_metas = Vec::new();

    for (name, path) in files {
        let meta = std::fs::metadata(path)?;
        let size = meta.len();
        total_bytes += size;

        file_metas.push(FileMetadata {
            file_id: Uuid::new_v4().to_string(),
            name: name.clone(),
            relative_path: None,
            size_bytes: size,
            sha256_hash: None,
            mime_type: None,
        });
    }

    Ok(TransferManifest {
        transfer_id,
        total_files: file_metas.len() as u32,
        total_bytes,
        files: file_metas,
        chunk_size,
    })
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_progress_estimator() {
        let tid = Uuid::new_v4();
        let mut est = ProgressEstimator::new(tid, 1000, 2);

        let p1 = est.update(500, "doc.pdf".into(), 1);
        assert_eq!(p1.bytes_transferred, 500);
        assert_eq!(p1.percentage, 50.0);
        assert_eq!(p1.files_completed, 1);
        assert_eq!(p1.total_files, 2);
    }

    #[test]
    fn test_read_and_write_file_chunk() {
        let temp_dir = std::env::temp_dir().join(format!("nexora_test_{}", Uuid::new_v4()));
        std::fs::create_dir_all(&temp_dir).unwrap();

        let src_file = temp_dir.join("sample.bin");
        let sample_data = b"Hello, this is NEXORA file chunk test data!";
        std::fs::write(&src_file, sample_data).unwrap();

        // Read chunk of 10 bytes starting at offset 7 ("this is NE")
        let (chunk, hash) = read_file_chunk(&src_file, 7, 10).unwrap();
        assert_eq!(chunk, b"this is NE");
        assert_eq!(hash, compute_sha256(b"this is NE"));

        // Write chunk to destination file
        let dst_file = temp_dir.join("dst.bin");
        write_file_chunk(&dst_file, 0, &chunk).unwrap();
        let written = std::fs::read(&dst_file).unwrap();
        assert_eq!(written, b"this is NE");

        let _ = std::fs::remove_dir_all(&temp_dir);
    }
}
