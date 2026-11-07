//! Device identity, Ed25519 cryptographic key management, and fingerprinting for NEXORA.

use ed25519_dalek::{Signature, Signer, SigningKey, Verifier, VerifyingKey};
use nexora_protocol::{CURRENT_PROTOCOL_VERSION, DeviceInfo};
use rand::rngs::OsRng;
use sha2::{Digest, Sha256};
use thiserror::Error;

#[derive(Debug, Error)]
pub enum IdentityError {
    #[error("Invalid public key encoding: {0}")]
    InvalidPublicKey(String),

    #[error("Invalid signature format: {0}")]
    InvalidSignature(String),

    #[error("Cryptographic signature verification failed")]
    VerificationFailed,
}

/// Represents the cryptographic identity of the local NEXORA installation.
#[derive(Clone)]
pub struct DeviceIdentity {
    pub device_id: String,
    pub display_name: String,
    pub platform: String,
    signing_key: SigningKey,
}

impl DeviceIdentity {
    /// Generates a new cryptographically secure device identity with an Ed25519 keypair.
    pub fn generate(display_name: String, platform: String) -> Self {
        let mut csprng = OsRng;
        let signing_key = SigningKey::generate(&mut csprng);
        let verifying_key = signing_key.verifying_key();

        // Stable device_id derived from the first 16 bytes of the public key's SHA-256
        let mut hasher = Sha256::new();
        hasher.update(verifying_key.as_bytes());
        let hash = hasher.finalize();
        let device_id = format!("nexora-{}", hex::encode(&hash[0..8]));

        Self {
            device_id,
            display_name,
            platform,
            signing_key,
        }
    }

    /// Reconstructs an identity from existing 32-byte secret key material.
    pub fn from_secret_bytes(
        secret_bytes: &[u8; 32],
        display_name: String,
        platform: String,
    ) -> Self {
        let signing_key = SigningKey::from_bytes(secret_bytes);
        let verifying_key = signing_key.verifying_key();

        let mut hasher = Sha256::new();
        hasher.update(verifying_key.as_bytes());
        let hash = hasher.finalize();
        let device_id = format!("nexora-{}", hex::encode(&hash[0..8]));

        Self {
            device_id,
            display_name,
            platform,
            signing_key,
        }
    }

    /// Returns the Ed25519 public key bytes (32 bytes).
    pub fn public_key_bytes(&self) -> [u8; 32] {
        self.signing_key.verifying_key().to_bytes()
    }

    /// Returns the SHA-256 hex fingerprint of the public key.
    pub fn fingerprint(&self) -> String {
        let mut hasher = Sha256::new();
        hasher.update(self.public_key_bytes());
        hex::encode(hasher.finalize())
    }

    /// Signs an arbitrary message using this device's private key.
    pub fn sign(&self, message: &[u8]) -> String {
        let signature: Signature = self.signing_key.sign(message);
        hex::encode(signature.to_bytes())
    }

    /// Converts this identity into a public `DeviceInfo` payload safe for discovery & pairing.
    pub fn to_device_info(&self) -> DeviceInfo {
        DeviceInfo {
            device_id: self.device_id.clone(),
            display_name: self.display_name.clone(),
            platform: self.platform.clone(),
            protocol_version: CURRENT_PROTOCOL_VERSION,
            fingerprint: self.fingerprint(),
        }
    }

    /// Exports raw 32-byte secret key bytes for secure platform keystore storage.
    pub fn secret_key_bytes(&self) -> [u8; 32] {
        self.signing_key.to_bytes()
    }
}

/// Verifies a signature from a remote peer given their Ed25519 public key bytes.
pub fn verify_peer_signature(
    public_key_bytes: &[u8; 32],
    message: &[u8],
    signature_hex: &str,
) -> Result<bool, IdentityError> {
    let verifying_key = VerifyingKey::from_bytes(public_key_bytes)
        .map_err(|e| IdentityError::InvalidPublicKey(e.to_string()))?;

    let sig_bytes = hex::decode(signature_hex)
        .map_err(|e| IdentityError::InvalidSignature(e.to_string()))?;

    if sig_bytes.len() != 64 {
        return Err(IdentityError::InvalidSignature("Signature must be 64 bytes".into()));
    }

    let mut sig_arr = [0u8; 64];
    sig_arr.copy_from_slice(&sig_bytes);
    let signature = Signature::from_bytes(&sig_arr);

    match verifying_key.verify(message, &signature) {
        Ok(_) => Ok(true),
        Err(_) => Ok(false),
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_device_identity_generation_and_fingerprint() {
        let identity = DeviceIdentity::generate("Test Device".into(), "windows".into());
        assert!(identity.device_id.starts_with("nexora-"));
        assert_eq!(identity.fingerprint().len(), 64);
        assert_eq!(identity.display_name, "Test Device");
        assert_eq!(identity.platform, "windows");
    }

    #[test]
    fn test_signature_sign_and_verify() {
        let identity = DeviceIdentity::generate("Sender Device".into(), "android".into());
        let message = b"NEXORA-PAIR-CHALLENGE-2026";

        let signature = identity.sign(message);
        let pub_key = identity.public_key_bytes();

        let valid = verify_peer_signature(&pub_key, message, &signature).expect("Verification check should run");
        assert!(valid, "Valid signature must verify successfully");

        let invalid = verify_peer_signature(&pub_key, b"Tampered Message", &signature).expect("Verification check should run");
        assert!(!invalid, "Tampered message must fail verification");
    }

    #[test]
    fn test_device_info_conversion() {
        let identity = DeviceIdentity::generate("Windows Workstation".into(), "windows".into());
        let info = identity.to_device_info();
        assert_eq!(info.device_id, identity.device_id);
        assert_eq!(info.display_name, "Windows Workstation");
        assert_eq!(info.fingerprint, identity.fingerprint());
    }
}
