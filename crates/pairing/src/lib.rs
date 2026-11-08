//! Secure pairing state machine, QR payload encoding/decoding, SAS codes and challenge-response for NEXORA.

use chrono::{DateTime, Duration, Utc};
use nexora_identity::{verify_peer_signature, DeviceIdentity};
use nexora_protocol::DeviceInfo;
use nexora_security::generate_nonce;
use rand::Rng;
use serde::{Deserialize, Serialize};
use thiserror::Error;
use uuid::Uuid;

#[derive(Debug, Error, PartialEq, Eq)]
pub enum PairingError {
    #[error("Pairing session expired")]
    SessionExpired,

    #[error("Short Authentication Code (SAS) mismatch")]
    SasMismatch,

    #[error("Invalid pairing payload format: {0}")]
    InvalidPayload(String),

    #[error("Pairing state transition invalid: cannot transition from {from:?} to {to:?}")]
    InvalidStateTransition {
        from: PairingState,
        to: PairingState,
    },

    #[error("Cryptographic signature check failed during pairing verification")]
    SignatureVerificationFailed,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum PairingState {
    Initiated,
    ChallengeSent,
    Confirmed,
    Paired,
    Rejected,
    Expired,
}

/// Generates a human-friendly 6-digit Short Authentication String (SAS).
pub fn generate_sas_code() -> String {
    let mut rng = rand::thread_rng();
    let num: u32 = rng.gen_range(100_000..999_999);
    num.to_string()
}

/// Payload encoded into QR codes for instant optical pairing.
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct QrPairingPayload {
    pub version: u32,
    pub session_id: Uuid,
    pub host: String,
    pub port: u16,
    pub device: DeviceInfo,
    pub challenge_nonce: String,
    pub sas_code: String,
    pub expires_at: DateTime<Utc>,
}

impl QrPairingPayload {
    pub fn new(
        host: String,
        port: u16,
        identity: &DeviceIdentity,
        ttl_seconds: i64,
    ) -> (Self, String) {
        let session_id = Uuid::new_v4();
        let challenge_nonce = generate_nonce(16);
        let sas_code = generate_sas_code();
        let expires_at = Utc::now() + Duration::seconds(ttl_seconds);

        let payload = Self {
            version: nexora_protocol::CURRENT_PROTOCOL_VERSION,
            session_id,
            host,
            port,
            device: identity.to_device_info(),
            challenge_nonce,
            sas_code: sas_code.clone(),
            expires_at,
        };

        (payload, sas_code)
    }

    /// Encodes this payload to a JSON string for QR code generation.
    pub fn to_qr_string(&self) -> Result<String, PairingError> {
        serde_json::to_string(self).map_err(|e| PairingError::InvalidPayload(e.to_string()))
    }

    /// Parses a scanned QR code string into a validated pairing payload.
    pub fn from_qr_string(qr_str: &str) -> Result<Self, PairingError> {
        let payload: Self = serde_json::from_str(qr_str)
            .map_err(|e| PairingError::InvalidPayload(e.to_string()))?;

        if Utc::now() > payload.expires_at {
            return Err(PairingError::SessionExpired);
        }

        Ok(payload)
    }
}

/// Manages an active pairing session lifecycle.
pub struct PairingSession {
    pub session_id: Uuid,
    pub state: PairingState,
    pub challenge_nonce: String,
    pub sas_code: String,
    pub expires_at: DateTime<Utc>,
    pub peer_device: Option<DeviceInfo>,
}

impl PairingSession {
    pub fn new(challenge_nonce: String, sas_code: String, ttl_seconds: i64) -> Self {
        Self {
            session_id: Uuid::new_v4(),
            state: PairingState::Initiated,
            challenge_nonce,
            sas_code,
            expires_at: Utc::now() + Duration::seconds(ttl_seconds),
            peer_device: None,
        }
    }

    /// Verifies peer's cryptographic response to the pairing challenge.
    pub fn verify_peer_response(
        &mut self,
        peer: DeviceInfo,
        peer_public_key: &[u8; 32],
        signature_hex: &str,
    ) -> Result<(), PairingError> {
        if Utc::now() > self.expires_at {
            self.state = PairingState::Expired;
            return Err(PairingError::SessionExpired);
        }

        let is_valid = verify_peer_signature(
            peer_public_key,
            self.challenge_nonce.as_bytes(),
            signature_hex,
        )
        .map_err(|_| PairingError::SignatureVerificationFailed)?;

        if !is_valid {
            self.state = PairingState::Rejected;
            return Err(PairingError::SignatureVerificationFailed);
        }

        self.peer_device = Some(peer);
        self.state = PairingState::Paired;
        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_sas_code_format() {
        let sas = generate_sas_code();
        assert_eq!(sas.len(), 6);
        let num: u32 = sas.parse().expect("SAS must parse to integer");
        assert!((100_000..=999_999).contains(&num));
    }

    #[test]
    fn test_qr_pairing_payload_lifecycle() {
        let id = DeviceIdentity::generate("Android Phone".into(), "android".into());
        let (payload, sas) = QrPairingPayload::new("192.168.1.50".into(), 48842, &id, 60);

        assert_eq!(payload.sas_code, sas);
        let qr_string = payload.to_qr_string().unwrap();

        let parsed = QrPairingPayload::from_qr_string(&qr_string).unwrap();
        assert_eq!(payload, parsed);
    }

    #[test]
    fn test_challenge_response_verification() {
        let _receiver = DeviceIdentity::generate("Windows PC".into(), "windows".into());
        let sender = DeviceIdentity::generate("Pixel 9".into(), "android".into());

        let challenge = generate_nonce(16);
        let sas = generate_sas_code();
        let mut session = PairingSession::new(challenge.clone(), sas, 30);

        // Sender signs receiver's challenge nonce
        let signature = sender.sign(challenge.as_bytes());

        // Receiver verifies sender's signature
        let pub_key = sender.public_key_bytes();
        let result = session.verify_peer_response(sender.to_device_info(), &pub_key, &signature);
        assert!(result.is_ok());
        assert_eq!(session.state, PairingState::Paired);
    }
}
