//! SQLite persistence layer, migrations, and transfer history for NEXORA.

use chrono::{DateTime, Utc};
use nexora_protocol::DeviceInfo;
use rusqlite::{params, Connection};
use std::path::Path;
use std::sync::Mutex;
use thiserror::Error;
use uuid::Uuid;

#[derive(Debug, Error)]
pub enum StorageError {
    #[error("Database error: {0}")]
    SqliteError(#[from] rusqlite::Error),

    #[error("Migration failed at version {version}: {error}")]
    MigrationError { version: u32, error: String },
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct DeviceRecord {
    pub device_id: String,
    pub display_name: String,
    pub platform: String,
    pub fingerprint: String,
    pub public_key_hex: String,
    pub is_trusted: bool,
    pub paired_at: DateTime<Utc>,
    pub last_seen: DateTime<Utc>,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct TransferRecord {
    pub transfer_id: Uuid,
    pub direction: String, // "send" or "receive"
    pub remote_device_id: String,
    pub remote_device_name: String,
    pub total_files: u32,
    pub total_bytes: u64,
    pub status: String, // "pending", "in_progress", "completed", "failed", "cancelled"
    pub created_at: DateTime<Utc>,
    pub completed_at: Option<DateTime<Utc>>,
}

pub struct NexoraDatabase {
    conn: Mutex<Connection>,
}

impl NexoraDatabase {
    /// Opens an in-memory SQLite database, running all pending migrations.
    pub fn open_in_memory() -> Result<Self, StorageError> {
        let conn = Connection::open_in_memory()?;
        let db = Self {
            conn: Mutex::new(conn),
        };
        db.run_migrations()?;
        Ok(db)
    }

    /// Opens an on-disk SQLite database, running all pending migrations.
    pub fn open(path: &Path) -> Result<Self, StorageError> {
        let conn = Connection::open(path)?;
        let db = Self {
            conn: Mutex::new(conn),
        };
        db.run_migrations()?;
        Ok(db)
    }

    /// Executes database schema migrations.
    fn run_migrations(&self) -> Result<(), StorageError> {
        let conn = self.conn.lock().unwrap();

        conn.execute_batch(
            r#"
            CREATE TABLE IF NOT EXISTS schema_migrations (
                version INTEGER PRIMARY KEY,
                applied_at TEXT NOT NULL
            );

            CREATE TABLE IF NOT EXISTS devices (
                device_id TEXT PRIMARY KEY,
                display_name TEXT NOT NULL,
                platform TEXT NOT NULL,
                fingerprint TEXT NOT NULL,
                public_key_hex TEXT NOT NULL,
                is_trusted INTEGER NOT NULL DEFAULT 0,
                paired_at TEXT NOT NULL,
                last_seen TEXT NOT NULL
            );

            CREATE TABLE IF NOT EXISTS transfers (
                transfer_id TEXT PRIMARY KEY,
                direction TEXT NOT NULL,
                remote_device_id TEXT NOT NULL,
                remote_device_name TEXT NOT NULL,
                total_files INTEGER NOT NULL,
                total_bytes INTEGER NOT NULL,
                status TEXT NOT NULL,
                created_at TEXT NOT NULL,
                completed_at TEXT
            );

            CREATE TABLE IF NOT EXISTS transfer_files (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                transfer_id TEXT NOT NULL,
                file_id TEXT NOT NULL,
                filename TEXT NOT NULL,
                relative_path TEXT,
                size_bytes INTEGER NOT NULL,
                sha256_hash TEXT,
                status TEXT NOT NULL,
                FOREIGN KEY(transfer_id) REFERENCES transfers(transfer_id)
            );

            CREATE TABLE IF NOT EXISTS settings (
                key TEXT PRIMARY KEY,
                value TEXT NOT NULL
            );
            "#,
        )?;

        Ok(())
    }

    /// Adds or updates a device record.
    pub fn upsert_device(
        &self,
        device: &DeviceInfo,
        public_key_hex: &str,
        is_trusted: bool,
    ) -> Result<(), StorageError> {
        let conn = self.conn.lock().unwrap();
        let now = Utc::now().to_rfc3339();

        conn.execute(
            r#"
            INSERT INTO devices (device_id, display_name, platform, fingerprint, public_key_hex, is_trusted, paired_at, last_seen)
            VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?7)
            ON CONFLICT(device_id) DO UPDATE SET
                display_name = excluded.display_name,
                platform = excluded.platform,
                fingerprint = excluded.fingerprint,
                is_trusted = excluded.is_trusted,
                last_seen = excluded.last_seen;
            "#,
            params![
                device.device_id,
                device.display_name,
                device.platform,
                device.fingerprint,
                public_key_hex,
                if is_trusted { 1 } else { 0 },
                now
            ],
        )?;

        Ok(())
    }

    /// Lists all trusted devices.
    pub fn list_trusted_devices(&self) -> Result<Vec<DeviceRecord>, StorageError> {
        let conn = self.conn.lock().unwrap();
        let mut stmt = conn.prepare(
            r#"
            SELECT device_id, display_name, platform, fingerprint, public_key_hex, is_trusted, paired_at, last_seen
            FROM devices
            WHERE is_trusted = 1
            ORDER BY last_seen DESC;
            "#,
        )?;

        let rows = stmt.query_map([], |row| {
            let paired_at_str: String = row.get(6)?;
            let last_seen_str: String = row.get(7)?;

            Ok(DeviceRecord {
                device_id: row.get(0)?,
                display_name: row.get(1)?,
                platform: row.get(2)?,
                fingerprint: row.get(3)?,
                public_key_hex: row.get(4)?,
                is_trusted: row.get::<_, i32>(5)? == 1,
                paired_at: DateTime::parse_from_rfc3339(&paired_at_str)
                    .unwrap_or_default()
                    .with_timezone(&Utc),
                last_seen: DateTime::parse_from_rfc3339(&last_seen_str)
                    .unwrap_or_default()
                    .with_timezone(&Utc),
            })
        })?;

        let mut devices = Vec::new();
        for r in rows {
            devices.push(r?);
        }
        Ok(devices)
    }

    /// Records a new transfer in the database.
    pub fn insert_transfer(&self, record: &TransferRecord) -> Result<(), StorageError> {
        let conn = self.conn.lock().unwrap();
        conn.execute(
            r#"
            INSERT INTO transfers (transfer_id, direction, remote_device_id, remote_device_name, total_files, total_bytes, status, created_at, completed_at)
            VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9);
            "#,
            params![
                record.transfer_id.to_string(),
                record.direction,
                record.remote_device_id,
                record.remote_device_name,
                record.total_files,
                record.total_bytes as i64,
                record.status,
                record.created_at.to_rfc3339(),
                record.completed_at.map(|t| t.to_rfc3339()),
            ],
        )?;
        Ok(())
    }

    /// Updates transfer status.
    pub fn update_transfer_status(
        &self,
        transfer_id: &Uuid,
        status: &str,
    ) -> Result<(), StorageError> {
        let conn = self.conn.lock().unwrap();
        let now = Utc::now().to_rfc3339();
        conn.execute(
            r#"
            UPDATE transfers
            SET status = ?1, completed_at = CASE WHEN ?1 IN ('completed', 'failed', 'cancelled') THEN ?2 ELSE completed_at END
            WHERE transfer_id = ?3;
            "#,
            params![status, now, transfer_id.to_string()],
        )?;
        Ok(())
    }

    /// Retrieves transfer history.
    pub fn list_transfers(&self, limit: u32) -> Result<Vec<TransferRecord>, StorageError> {
        let conn = self.conn.lock().unwrap();
        let mut stmt = conn.prepare(
            r#"
            SELECT transfer_id, direction, remote_device_id, remote_device_name, total_files, total_bytes, status, created_at, completed_at
            FROM transfers
            ORDER BY created_at DESC
            LIMIT ?1;
            "#,
        )?;

        let rows = stmt.query_map(params![limit], |row| {
            let tid_str: String = row.get(0)?;
            let created_at_str: String = row.get(7)?;
            let completed_at_str: Option<String> = row.get(8)?;

            Ok(TransferRecord {
                transfer_id: Uuid::parse_str(&tid_str).unwrap_or_default(),
                direction: row.get(1)?,
                remote_device_id: row.get(2)?,
                remote_device_name: row.get(3)?,
                total_files: row.get(4)?,
                total_bytes: row.get::<_, i64>(5)? as u64,
                status: row.get(6)?,
                created_at: DateTime::parse_from_rfc3339(&created_at_str)
                    .unwrap_or_default()
                    .with_timezone(&Utc),
                completed_at: completed_at_str.and_then(|s| {
                    DateTime::parse_from_rfc3339(&s)
                        .ok()
                        .map(|dt| dt.with_timezone(&Utc))
                }),
            })
        })?;

        let mut transfers = Vec::new();
        for r in rows {
            transfers.push(r?);
        }
        Ok(transfers)
    }

    /// Sets an app setting value.
    pub fn set_setting(&self, key: &str, value: &str) -> Result<(), StorageError> {
        let conn = self.conn.lock().unwrap();
        conn.execute(
            "INSERT INTO settings (key, value) VALUES (?1, ?2) ON CONFLICT(key) DO UPDATE SET value = excluded.value;",
            params![key, value],
        )?;
        Ok(())
    }

    /// Gets an app setting value.
    pub fn get_setting(&self, key: &str) -> Result<Option<String>, StorageError> {
        let conn = self.conn.lock().unwrap();
        let mut stmt = conn.prepare("SELECT value FROM settings WHERE key = ?1;")?;
        let mut rows = stmt.query(params![key])?;
        if let Some(row) = rows.next()? {
            Ok(Some(row.get(0)?))
        } else {
            Ok(None)
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_database_initialization_and_device_persistence() {
        let db = NexoraDatabase::open_in_memory().expect("In-memory DB should initialize");

        let device = DeviceInfo {
            device_id: "nexora-phone-01".into(),
            display_name: "Pixel 9".into(),
            platform: "android".into(),
            protocol_version: 1,
            fingerprint: "0123456789abcdef".into(),
        };

        db.upsert_device(&device, "deadbeef1234", true)
            .expect("Upserting trusted device");

        let trusted = db.list_trusted_devices().expect("Listing trusted devices");
        assert_eq!(trusted.len(), 1);
        assert_eq!(trusted[0].device_id, "nexora-phone-01");
        assert_eq!(trusted[0].display_name, "Pixel 9");
        assert!(trusted[0].is_trusted);
    }

    #[test]
    fn test_transfer_history() {
        let db = NexoraDatabase::open_in_memory().unwrap();
        let tid = Uuid::new_v4();

        let record = TransferRecord {
            transfer_id: tid,
            direction: "receive".into(),
            remote_device_id: "nexora-pc".into(),
            remote_device_name: "Windows Desktop".into(),
            total_files: 3,
            total_bytes: 4096000,
            status: "pending".into(),
            created_at: Utc::now(),
            completed_at: None,
        };

        db.insert_transfer(&record).unwrap();
        db.update_transfer_status(&tid, "completed").unwrap();

        let list = db.list_transfers(10).unwrap();
        assert_eq!(list.len(), 1);
        assert_eq!(list[0].transfer_id, tid);
        assert_eq!(list[0].status, "completed");
        assert!(list[0].completed_at.is_some());
    }

    #[test]
    fn test_app_settings() {
        let db = NexoraDatabase::open_in_memory().unwrap();
        db.set_setting("auto_accept_trusted", "true").unwrap();

        let val = db.get_setting("auto_accept_trusted").unwrap();
        assert_eq!(val, Some("true".into()));

        let missing = db.get_setting("non_existent").unwrap();
        assert_eq!(missing, None);
    }
}
