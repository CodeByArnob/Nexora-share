//! Public typed API surface exposed to Flutter and external integrations.

use nexora_discovery::{DiscoveredPeer, PeerRegistry};
use nexora_identity::DeviceIdentity;
use nexora_protocol::DeviceInfo;
use nexora_storage::{DeviceRecord, NexoraDatabase, StorageError, TransferRecord};
use std::sync::{Arc, OnceLock, RwLock};

static CORE_INSTANCE: OnceLock<NexoraCore> = OnceLock::new();

/// Top-level coordinator for the NEXORA application.
pub struct NexoraCore {
    identity: RwLock<DeviceIdentity>,
    db: Arc<NexoraDatabase>,
    peer_registry: PeerRegistry,
}

impl NexoraCore {
    pub fn new(display_name: String, platform: String) -> Result<Self, StorageError> {
        let identity = DeviceIdentity::generate(display_name, platform);
        let db = Arc::new(NexoraDatabase::open_in_memory()?);
        let peer_registry = PeerRegistry::new();

        Ok(Self {
            identity: RwLock::new(identity),
            db,
            peer_registry,
        })
    }

    pub fn device_info(&self) -> DeviceInfo {
        self.identity.read().unwrap().to_device_info()
    }

    pub fn active_peers(&self) -> Vec<DiscoveredPeer> {
        self.peer_registry.active_peers()
    }

    pub fn trusted_devices(&self) -> Result<Vec<DeviceRecord>, StorageError> {
        self.db.list_trusted_devices()
    }

    pub fn transfer_history(&self, limit: u32) -> Result<Vec<TransferRecord>, StorageError> {
        self.db.list_transfers(limit)
    }
}

/// Initializes the global NEXORA engine instance.
pub fn init_nexora_engine(
    display_name: String,
    platform: String,
) -> Result<DeviceInfo, String> {
    let core = NexoraCore::new(display_name, platform).map_err(|e| e.to_string())?;
    let info = core.device_info();
    let _ = CORE_INSTANCE.set(core);
    Ok(info)
}

/// Retrieves the local device information.
pub fn get_local_device_info() -> Result<DeviceInfo, String> {
    let core = CORE_INSTANCE
        .get()
        .ok_or_else(|| "NEXORA engine is not initialized".to_string())?;
    Ok(core.device_info())
}

/// Lists currently discovered nearby peers on the local network.
pub fn get_discovered_peers() -> Result<Vec<DiscoveredPeer>, String> {
    let core = CORE_INSTANCE
        .get()
        .ok_or_else(|| "NEXORA engine is not initialized".to_string())?;
    Ok(core.active_peers())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_core_initialization() {
        let core = NexoraCore::new("Test Rig".into(), "windows".into()).unwrap();
        let info = core.device_info();
        assert_eq!(info.display_name, "Test Rig");
        assert_eq!(info.platform, "windows");
        assert!(info.device_id.starts_with("nexora-"));

        let peers = core.active_peers();
        assert_eq!(peers.len(), 0);

        let trusted = core.trusted_devices().unwrap();
        assert_eq!(trusted.len(), 0);
    }
}
