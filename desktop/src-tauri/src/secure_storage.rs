use keyring::Entry;
use log::{error, info};

const SERVICE_NAME: &str = "AutoDoc Agent";

/// Securely store a credential in the OS keychain
pub fn store_credential(key: &str, value: &str) -> Result<(), String> {
    match Entry::new(SERVICE_NAME, key) {
        Ok(entry) => {
            match entry.set_password(value) {
                Ok(_) => {
                    info!("Credential '{}' stored securely in keychain", key);
                    Ok(())
                }
                Err(e) => {
                    error!("Failed to store credential '{}': {}", key, e);
                    Err(format!("Failed to store credential: {}", e))
                }
            }
        }
        Err(e) => {
            error!("Failed to create keychain entry for '{}': {}", key, e);
            Err(format!("Failed to create keychain entry: {}", e))
        }
    }
}

/// Retrieve a credential from the OS keychain
pub fn get_credential(key: &str) -> Result<String, String> {
    match Entry::new(SERVICE_NAME, key) {
        Ok(entry) => {
            match entry.get_password() {
                Ok(password) => {
                    info!("Credential '{}' retrieved from keychain", key);
                    Ok(password)
                }
                Err(e) => {
                    // Don't log the full error as it might contain sensitive info
                    Err(format!("Credential not found or inaccessible: {}", key))
                }
            }
        }
        Err(e) => {
            error!("Failed to access keychain for '{}': {}", key, e);
            Err(format!("Failed to access keychain: {}", e))
        }
    }
}

/// Delete a credential from the OS keychain
pub fn delete_credential(key: &str) -> Result<(), String> {
    match Entry::new(SERVICE_NAME, key) {
        Ok(entry) => {
            match entry.delete_password() {
                Ok(_) => {
                    info!("Credential '{}' deleted from keychain", key);
                    Ok(())
                }
                Err(e) => {
                    // It's okay if the credential doesn't exist
                    info!("Credential '{}' was not in keychain", key);
                    Ok(())
                }
            }
        }
        Err(e) => {
            error!("Failed to access keychain for deletion of '{}': {}", key, e);
            Err(format!("Failed to access keychain: {}", e))
        }
    }
}

/// Check if a credential exists in the keychain
pub fn has_credential(key: &str) -> bool {
    match Entry::new(SERVICE_NAME, key) {
        Ok(entry) => entry.get_password().is_ok(),
        Err(_) => false,
    }
}

// Tauri commands

#[tauri::command]
pub fn store_secure_credential(key: String, value: String) -> Result<(), String> {
    store_credential(&key, &value)
}

#[tauri::command]
pub fn get_secure_credential(key: String) -> Result<String, String> {
    get_credential(&key)
}

#[tauri::command]
pub fn delete_secure_credential(key: String) -> Result<(), String> {
    delete_credential(&key)
}

#[tauri::command]
pub fn has_secure_credential(key: String) -> Result<bool, String> {
    Ok(has_credential(&key))
}

/// Migrate plaintext credentials to secure storage
pub fn migrate_credential_to_keychain(key: &str, plaintext_value: Option<String>) -> Result<bool, String> {
    if let Some(value) = plaintext_value {
        if !value.is_empty() {
            info!("Migrating credential '{}' to keychain", key);
            store_credential(key, &value)?;
            return Ok(true); // Migration performed
        }
    }
    Ok(false) // No migration needed
}
