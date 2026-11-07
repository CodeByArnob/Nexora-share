//! mDNS / DNS-SD discovery service and peer registry for NEXORA.

use chrono::{DateTime, Duration, Utc};
use nexora_protocol::DeviceInfo;
use std::collections::HashMap;
use std::sync::{Arc, Mutex};
use thiserror::Error;

/// Standard mDNS service type for NEXORA.
pub const NEXORA_SERVICE_TYPE: &str = "_nexora._tcp.local.";

/// Default peer expiration timeout in seconds.
pub const DEFAULT_PEER_TTL_SECONDS: i64 = 15;

#[derive(Debug, Error)]
pub enum DiscoveryError {
    #[error("mDNS engine error: {0}")]
    EngineError(String),

    #[error("Failed to parse TXT record: {0}")]
    InvalidTxtRecord(String),
}

/// A discovered remote peer available on the local network.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct DiscoveredPeer {
    pub device: DeviceInfo,
    pub address: String,
    pub port: u16,
    pub last_seen: DateTime<Utc>,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub enum DiscoveryEvent {
    PeerDiscovered(DiscoveredPeer),
    PeerUpdated(DiscoveredPeer),
    PeerLost(String), // device_id
}

/// Thread-safe active peer registry with stale device expiration.
#[derive(Clone, Default)]
pub struct PeerRegistry {
    peers: Arc<Mutex<HashMap<String, DiscoveredPeer>>>,
}

impl PeerRegistry {
    pub fn new() -> Self {
        Self {
            peers: Arc::new(Mutex::new(HashMap::new())),
        }
    }

    /// Registers or updates a discovered peer, returning the appropriate discovery event.
    pub fn upsert_peer(
        &self,
        device: DeviceInfo,
        address: String,
        port: u16,
    ) -> DiscoveryEvent {
        let mut map = self.peers.lock().unwrap();
        let device_id = device.device_id.clone();
        let peer = DiscoveredPeer {
            device,
            address,
            port,
            last_seen: Utc::now(),
        };

        if map.contains_key(&device_id) {
            map.insert(device_id, peer.clone());
            DiscoveryEvent::PeerUpdated(peer)
        } else {
            map.insert(device_id, peer.clone());
            DiscoveryEvent::PeerDiscovered(peer)
        }
    }

    /// Evicts devices that have not been seen within `ttl_seconds`.
    pub fn evict_stale_peers(&self, ttl_seconds: i64) -> Vec<DiscoveryEvent> {
        let mut map = self.peers.lock().unwrap();
        let now = Utc::now();
        let cutoff = now - Duration::seconds(ttl_seconds);

        let mut lost_events = Vec::new();
        map.retain(|id, peer| {
            if peer.last_seen < cutoff {
                lost_events.push(DiscoveryEvent::PeerLost(id.clone()));
                false
            } else {
                true
            }
        });

        lost_events
    }

    /// Retrieves all currently active peers.
    pub fn active_peers(&self) -> Vec<DiscoveredPeer> {
        let map = self.peers.lock().unwrap();
        map.values().cloned().collect()
    }

    /// Removes a specific peer immediately.
    pub fn remove_peer(&self, device_id: &str) -> Option<DiscoveredPeer> {
        let mut map = self.peers.lock().unwrap();
        map.remove(device_id)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_peer_registry_lifecycle() {
        let registry = PeerRegistry::new();
        let device = DeviceInfo {
            device_id: "phone-1".into(),
            display_name: "Pixel 9".into(),
            platform: "android".into(),
            protocol_version: 1,
            fingerprint: "fingerprint1".into(),
        };

        let event = registry.upsert_peer(device.clone(), "192.168.1.100".into(), 48842);
        assert!(matches!(event, DiscoveryEvent::PeerDiscovered(_)));
        assert_eq!(registry.active_peers().len(), 1);

        let update_event = registry.upsert_peer(device.clone(), "192.168.1.100".into(), 48842);
        assert!(matches!(update_event, DiscoveryEvent::PeerUpdated(_)));

        // Remove
        let removed = registry.remove_peer("phone-1");
        assert!(removed.is_some());
        assert_eq!(registry.active_peers().len(), 0);
    }
}
