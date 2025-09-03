use crate::i18n::Language;
use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use std::path::PathBuf;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SftpConfig {
    pub host: String,
    pub port: u16,
    pub username: String,
    pub password: Option<String>,
    pub private_key_path: Option<String>,
    pub remote_path: String,
    pub local_path: String,
    pub language: Option<Language>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct FileStatus {
    pub path: PathBuf,
    pub size: u64,
    pub modified: DateTime<Utc>,
    pub is_directory: bool,
    pub checksum: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SyncResult {
    pub success: bool,
    pub message: String,
    pub files_transferred: Vec<String>,
    pub files_skipped: Vec<String>,
    pub errors: Vec<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SyncOperation {
    pub operation_type: OperationType,
    pub local_path: PathBuf,
    pub remote_path: PathBuf,
    pub timestamp: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum OperationType {
    Upload,
    Download,
    Delete,
    CreateDirectory,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AstraTomlConfig {
    pub sftp: SftpTomlConfig,
    pub sync: Option<SyncTomlConfig>,
    pub language: Option<Language>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SftpTomlConfig {
    pub host: String,
    pub port: Option<u16>,
    pub username: String,
    pub password: Option<String>,
    pub private_key_path: Option<String>,
    pub remote_path: String,
    pub local_path: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SyncTomlConfig {
    pub auto_sync: Option<bool>,
    pub sync_on_save: Option<bool>,
    pub sync_interval: Option<u64>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct VsCodeSftpConfig {
    pub name: String,
    pub host: String,
    pub protocol: String,
    pub port: u16,
    pub secure: Option<bool>,
    pub username: String,
    #[serde(rename = "remotePath")]
    pub remote_path: String,
    pub password: Option<String>,
    #[serde(rename = "privateKeyPath")]
    pub private_key_path: Option<String>,
    #[serde(rename = "uploadOnSave")]
    pub upload_on_save: Option<bool>,
}

impl From<AstraTomlConfig> for SftpConfig {
    fn from(config: AstraTomlConfig) -> Self {
        Self {
            host: config.sftp.host,
            port: config.sftp.port.unwrap_or(22),
            username: config.sftp.username,
            password: config.sftp.password,
            private_key_path: config.sftp.private_key_path,
            remote_path: config.sftp.remote_path,
            local_path: config.sftp.local_path.unwrap_or_else(|| {
                std::env::current_dir()
                    .unwrap()
                    .to_string_lossy()
                    .to_string()
            }),
            language: config.language,
        }
    }
}

impl From<VsCodeSftpConfig> for SftpConfig {
    fn from(config: VsCodeSftpConfig) -> Self {
        Self {
            host: config.host,
            port: config.port,
            username: config.username,
            password: config.password,
            private_key_path: config.private_key_path,
            remote_path: config.remote_path,
            local_path: std::env::current_dir()
                .unwrap()
                .to_string_lossy()
                .to_string(),
            language: None,
        }
    }
}
