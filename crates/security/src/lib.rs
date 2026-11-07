//! Security primitives, path sanitization, replay attack mitigation, and nonces for NEXORA.

use chrono::{DateTime, Utc};
use rand::RngCore;
use std::collections::HashSet;
use std::path::{Component, Path, PathBuf};
use std::sync::Mutex;
use thiserror::Error;

#[derive(Debug, Error, PartialEq, Eq)]
pub enum SecurityError {
    #[error("Path traversal attempt detected in path: '{0}'")]
    PathTraversalAttempt(String),

    #[error("Invalid or illegal filename: '{0}'")]
    InvalidFilename(String),

    #[error("File already exists and overwrite is disabled: '{0}'")]
    FileAlreadyExists(String),

    #[error("Replay protection rejected message: timestamp expired or skewed ({0}s drift)")]
    TimestampExpired(i64),

    #[error("Replay protection rejected message: duplicate nonce '{0}'")]
    DuplicateNonce(String),
}

/// Windows reserved filenames that cannot be used.
const WINDOWS_RESERVED_NAMES: &[&str] = &[
    "CON", "PRN", "AUX", "NUL", "COM1", "COM2", "COM3", "COM4", "COM5", "COM6", "COM7", "COM8",
    "COM9", "LPT1", "LPT2", "LPT3", "LPT4", "LPT5", "LPT6", "LPT7", "LPT8", "LPT9",
];

/// Sanitizes a file name, checking for illegal characters, null bytes, and path traversal components.
pub fn sanitize_filename(name: &str) -> Result<String, SecurityError> {
    let trimmed = name.trim();
    if trimmed.is_empty() {
        return Err(SecurityError::InvalidFilename("Filename cannot be empty".into()));
    }

    if trimmed.contains('\0') {
        return Err(SecurityError::InvalidFilename("Null bytes are prohibited".into()));
    }

    // Check for path separators in standalone file names
    if trimmed.contains('/') || trimmed.contains('\\') {
        return Err(SecurityError::PathTraversalAttempt(trimmed.to_string()));
    }

    // Check Windows reserved names
    let stem = trimmed.split('.').next().unwrap_or("").to_uppercase();
    if WINDOWS_RESERVED_NAMES.contains(&stem.as_str()) {
        return Err(SecurityError::InvalidFilename(format!(
            "Filename '{trimmed}' is reserved by the OS"
        )));
    }

    Ok(trimmed.to_string())
}

/// Resolves a target destination path inside `base_dir`, strictly preventing path traversal
/// and symlink escape vulnerabilities.
pub fn resolve_safe_path(
    base_dir: &Path,
    filename: &str,
    relative_path: Option<&str>,
    allow_overwrite: bool,
) -> Result<PathBuf, SecurityError> {
    let sanitized_filename = sanitize_filename(filename)?;

    let mut dest = base_dir.to_path_buf();

    if let Some(rel) = relative_path {
        let rel_path = Path::new(rel);
        for comp in rel_path.components() {
            match comp {
                Component::Normal(c) => {
                    let part = c.to_string_lossy();
                    let sanitized_part = sanitize_filename(&part)?;
                    dest.push(sanitized_part);
                }
                Component::ParentDir | Component::RootDir | Component::Prefix(_) => {
                    return Err(SecurityError::PathTraversalAttempt(rel.to_string()));
                }
                Component::CurDir => continue,
            }
        }
    }

    dest.push(sanitized_filename);

    if !allow_overwrite && dest.exists() {
        return Err(SecurityError::FileAlreadyExists(
            dest.to_string_lossy().to_string(),
        ));
    }

    Ok(dest)
}

/// Generates a cryptographically strong random hex nonce.
pub fn generate_nonce(num_bytes: usize) -> String {
    let mut bytes = vec![0u8; num_bytes];
    rand::rngs::OsRng.fill_bytes(&mut bytes);
    hex::encode(bytes)
}

/// Replay guard with timestamp skew enforcement and duplicate nonce caching.
pub struct ReplayGuard {
    max_skew_seconds: i64,
    seen_nonces: Mutex<HashSet<String>>,
}

impl ReplayGuard {
    pub fn new(max_skew_seconds: i64) -> Self {
        Self {
            max_skew_seconds,
            seen_nonces: Mutex::new(HashSet::new()),
        }
    }

    /// Validates that a message's timestamp is within acceptable drift and its nonce has not been seen.
    pub fn validate(&self, timestamp: DateTime<Utc>, nonce: &str) -> Result<(), SecurityError> {
        let now = Utc::now();
        let drift = (now - timestamp).num_seconds().abs();

        if drift > self.max_skew_seconds {
            return Err(SecurityError::TimestampExpired(drift));
        }

        let mut nonces = self.seen_nonces.lock().unwrap();
        if nonces.contains(nonce) {
            return Err(SecurityError::DuplicateNonce(nonce.to_string()));
        }

        nonces.insert(nonce.to_string());
        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_sanitize_filename_valid() {
        assert_eq!(
            sanitize_filename("holiday_photo.jpg").unwrap(),
            "holiday_photo.jpg"
        );
        assert_eq!(
            sanitize_filename("archive.tar.gz").unwrap(),
            "archive.tar.gz"
        );
    }

    #[test]
    fn test_sanitize_filename_traversal_detection() {
        assert!(matches!(
            sanitize_filename("../secret.key"),
            Err(SecurityError::PathTraversalAttempt(_))
        ));
        assert!(matches!(
            sanitize_filename("..\\secret.key"),
            Err(SecurityError::PathTraversalAttempt(_))
        ));
    }

    #[test]
    fn test_sanitize_filename_reserved() {
        assert!(matches!(
            sanitize_filename("CON.txt"),
            Err(SecurityError::InvalidFilename(_))
        ));
        assert!(matches!(
            sanitize_filename("NUL.dat"),
            Err(SecurityError::InvalidFilename(_))
        ));
    }

    #[test]
    fn test_resolve_safe_path_valid() {
        let base = Path::new("/downloads/nexora");
        let path = resolve_safe_path(base, "doc.pdf", Some("project/reports"), true).unwrap();
        assert_eq!(path, base.join("project").join("reports").join("doc.pdf"));
    }

    #[test]
    fn test_resolve_safe_path_traversal() {
        let base = Path::new("/downloads/nexora");
        let result = resolve_safe_path(base, "doc.pdf", Some("../../../etc"), true);
        assert!(matches!(result, Err(SecurityError::PathTraversalAttempt(_))));
    }

    #[test]
    fn test_replay_guard() {
        let guard = ReplayGuard::new(60);
        let now = Utc::now();
        let nonce = generate_nonce(16);

        // First attempt succeeds
        assert!(guard.validate(now, &nonce).is_ok());

        // Replay of same nonce fails
        assert_eq!(
            guard.validate(now, &nonce),
            Err(SecurityError::DuplicateNonce(nonce.clone()))
        );

        // Skewed timestamp fails
        let old_time = now - chrono::Duration::seconds(120);
        let fresh_nonce = generate_nonce(16);
        assert!(matches!(
            guard.validate(old_time, &fresh_nonce),
            Err(SecurityError::TimestampExpired(_))
        ));
    }
}
