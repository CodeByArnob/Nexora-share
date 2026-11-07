//! Chunk-level resume tracking, checkpointing and verified state recovery for NEXORA.

use serde::{Deserialize, Serialize};
use std::collections::BTreeSet;
use thiserror::Error;
use uuid::Uuid;

#[derive(Debug, Error, PartialEq, Eq)]
pub enum ResumeError {
    #[error("Chunk index {0} out of bounds (total chunks: {1})")]
    ChunkOutOfBounds(u64, u64),

    #[error("Invalid resume checkpoint file: {0}")]
    InvalidCheckpoint(String),
}

/// Tracks the verified chunk progress of an ongoing transfer.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct TransferResumeTracker {
    pub transfer_id: Uuid,
    pub file_id: String,
    pub chunk_size: u32,
    pub total_chunks: u64,
    pub total_bytes: u64,
    pub verified_chunks: BTreeSet<u64>,
}

impl TransferResumeTracker {
    pub fn new(transfer_id: Uuid, file_id: String, chunk_size: u32, total_bytes: u64) -> Self {
        let total_chunks = if total_bytes == 0 {
            1
        } else {
            (total_bytes + chunk_size as u64 - 1) / chunk_size as u64
        };

        Self {
            transfer_id,
            file_id,
            chunk_size,
            total_chunks,
            total_bytes,
            verified_chunks: BTreeSet::new(),
        }
    }

    /// Marks a chunk index as successfully received and verified against its SHA-256.
    pub fn mark_chunk_verified(&mut self, chunk_index: u64) -> Result<(), ResumeError> {
        if chunk_index >= self.total_chunks {
            return Err(ResumeError::ChunkOutOfBounds(
                chunk_index,
                self.total_chunks,
            ));
        }
        self.verified_chunks.insert(chunk_index);
        Ok(())
    }

    /// Checks if a chunk has already been verified.
    pub fn is_chunk_verified(&self, chunk_index: u64) -> bool {
        self.verified_chunks.contains(&chunk_index)
    }

    /// Finds the lowest chunk index that has not yet been verified.
    pub fn next_missing_chunk(&self) -> Option<u64> {
        for idx in 0..self.total_chunks {
            if !self.verified_chunks.contains(&idx) {
                return Some(idx);
            }
        }
        None
    }

    /// Returns the number of verified chunks.
    pub fn verified_chunk_count(&self) -> u64 {
        self.verified_chunks.len() as u64
    }

    /// Checks if all chunks have been verified.
    pub fn is_complete(&self) -> bool {
        self.verified_chunks.len() as u64 == self.total_chunks
    }

    /// Serializes tracker checkpoint to JSON string.
    pub fn to_checkpoint_json(&self) -> Result<String, ResumeError> {
        serde_json::to_string(self).map_err(|e| ResumeError::InvalidCheckpoint(e.to_string()))
    }

    /// Deserializes tracker checkpoint from JSON string.
    pub fn from_checkpoint_json(json: &str) -> Result<Self, ResumeError> {
        serde_json::from_str(json).map_err(|e| ResumeError::InvalidCheckpoint(e.to_string()))
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_resume_tracker_chunk_progress() {
        let tid = Uuid::new_v4();
        // 10 MB total with 1 MB chunks = 10 chunks
        let mut tracker =
            TransferResumeTracker::new(tid, "file-1".into(), 1024 * 1024, 10 * 1024 * 1024);
        assert_eq!(tracker.total_chunks, 10);
        assert_eq!(tracker.next_missing_chunk(), Some(0));
        assert!(!tracker.is_complete());

        tracker.mark_chunk_verified(0).unwrap();
        tracker.mark_chunk_verified(1).unwrap();
        assert_eq!(tracker.next_missing_chunk(), Some(2));
        assert_eq!(tracker.verified_chunk_count(), 2);

        // Out of bounds fails
        assert_eq!(
            tracker.mark_chunk_verified(10),
            Err(ResumeError::ChunkOutOfBounds(10, 10))
        );

        // Fill remaining chunks
        for i in 2..10 {
            tracker.mark_chunk_verified(i).unwrap();
        }
        assert!(tracker.is_complete());
        assert_eq!(tracker.next_missing_chunk(), None);
    }

    #[test]
    fn test_checkpoint_serialization_roundtrip() {
        let tid = Uuid::new_v4();
        let mut tracker = TransferResumeTracker::new(tid, "file-abc".into(), 64 * 1024, 128 * 1024);
        tracker.mark_chunk_verified(0).unwrap();

        let json = tracker
            .to_checkpoint_json()
            .expect("Checkpoint JSON serialization");
        let restored = TransferResumeTracker::from_checkpoint_json(&json)
            .expect("Checkpoint JSON deserialization");

        assert_eq!(tracker, restored);
    }
}
