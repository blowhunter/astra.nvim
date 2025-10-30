use crate::error::{AstraError, AstraResult};
use crate::types::{FileStatus, OperationType, SftpConfig, SyncOperation};
use chrono::{DateTime, Utc};
use ssh2::Session;
use std::collections::HashMap;
use std::fs;
use std::path::{Path, PathBuf};
use tracing::info;
use walkdir::WalkDir;

pub struct SftpClient {
    session: Session,
    config: SftpConfig,
}

impl SftpClient {
    pub fn new(config: SftpConfig) -> AstraResult<Self> {
        let tcp = std::net::TcpStream::connect(format!("{}:{}", config.host, config.port))
            .map_err(|e| AstraError::SftpConnectionError(e.to_string()))?;

        let mut session =
            Session::new().map_err(|e| AstraError::SftpConnectionError(e.to_string()))?;

        session.set_tcp_stream(tcp);
        session
            .handshake()
            .map_err(|e| AstraError::SftpConnectionError(e.to_string()))?;

        if let Some(private_key_path) = &config.private_key_path {
            session
                .userauth_pubkey_file(&config.username, None, Path::new(private_key_path), None)
                .map_err(|e| AstraError::AuthenticationError(e.to_string()))?;
        } else if let Some(password) = &config.password {
            session
                .userauth_password(&config.username, password)
                .map_err(|e| AstraError::AuthenticationError(e.to_string()))?;
        } else {
            return Err(AstraError::AuthenticationError(
                "Either password or private key must be provided".to_string(),
            ));
        }

        if !session.authenticated() {
            return Err(AstraError::AuthenticationError(
                "Authentication failed".to_string(),
            ));
        }

        Ok(Self {
            session,
            config,
        })
    }

    pub fn get_remote_files(&self, remote_path: &Path) -> AstraResult<Vec<FileStatus>> {
        let sftp = self
            .session
            .sftp()
            .map_err(|e| AstraError::SftpConnectionError(e.to_string()))?;

        let mut files = Vec::new();

        let readdir = match sftp.readdir(remote_path) {
            Ok(files) => files,
            Err(_) => return Ok(vec![]),
        };

        for (path, stat) in readdir {
            let file_status = FileStatus {
                path: path.to_path_buf(),
                size: stat.size.unwrap_or(0),
                modified: DateTime::from_timestamp(stat.mtime.unwrap_or(0) as i64, 0)
                    .unwrap_or_else(Utc::now),
                is_directory: stat.is_dir(),
                checksum: None,
            };

            files.push(file_status);
        }

        Ok(files)
    }

    pub fn get_local_files(&self, local_path: &Path) -> AstraResult<Vec<FileStatus>> {
        let mut files = Vec::new();

        if !local_path.exists() {
            return Ok(files);
        }

        for entry in WalkDir::new(local_path)
            .into_iter()
            .filter_entry(|e| e.path() != local_path)
        {
            let entry = entry.map_err(|e| AstraError::IoError(e.into()))?;
            let path = entry.path();

            if path.is_file() {
                let metadata = fs::metadata(path).map_err(AstraError::IoError)?;

                let modified: DateTime<Utc> =
                    metadata.modified().map_err(AstraError::IoError)?.into();

                let checksum = self.calculate_file_checksum(path)?;

                let file_status = FileStatus {
                    path: path.to_path_buf(),
                    size: metadata.len(),
                    modified,
                    is_directory: false,
                    checksum,
                };

                files.push(file_status);
            }
        }

        Ok(files)
    }

    pub fn calculate_file_checksum(&self, path: &Path) -> AstraResult<Option<String>> {
        let content = fs::read(path).map_err(AstraError::IoError)?;

        use sha2::{Digest, Sha256};
        let mut hasher = Sha256::new();
        hasher.update(&content);
        let result = hasher.finalize();

        Ok(Some(format!("{:x}", result)))
    }

    pub fn upload_file(&self, local_path: &Path, remote_path: &Path) -> AstraResult<()> {
        info!(
            "Uploading {} to {}",
            local_path.display(),
            remote_path.display()
        );

        let sftp = self
            .session
            .sftp()
            .map_err(|e| AstraError::SftpConnectionError(e.to_string()))?;

        if let Some(parent) = remote_path.parent() {
            match sftp.stat(parent) {
                Ok(_) => {}
                Err(_) => {
                    self.create_remote_directory(parent)?;
                }
            }
        }

        let mut local_file = fs::File::open(local_path).map_err(AstraError::IoError)?;

        let mut remote_file = sftp
            .create(remote_path)
            .map_err(|e| AstraError::FileOperationError(e.to_string()))?;

        std::io::copy(&mut local_file, &mut remote_file).map_err(AstraError::IoError)?;

        Ok(())
    }

    pub fn download_file(&self, remote_path: &Path, local_path: &Path) -> AstraResult<()> {
        info!(
            "Downloading {} to {}",
            remote_path.display(),
            local_path.display()
        );

        let sftp = self
            .session
            .sftp()
            .map_err(|e| AstraError::SftpConnectionError(e.to_string()))?;

        if let Some(parent) = local_path.parent() {
            fs::create_dir_all(parent).map_err(AstraError::IoError)?;
        }

        let mut remote_file = sftp
            .open(remote_path)
            .map_err(|e| AstraError::FileOperationError(e.to_string()))?;

        let mut local_file = fs::File::create(local_path).map_err(AstraError::IoError)?;

        std::io::copy(&mut remote_file, &mut local_file).map_err(AstraError::IoError)?;

        Ok(())
    }

    pub fn create_remote_directory(&self, remote_path: &Path) -> AstraResult<()> {
        let sftp = self
            .session
            .sftp()
            .map_err(|e| AstraError::SftpConnectionError(e.to_string()))?;

        sftp.mkdir(remote_path, 0o755)
            .map_err(|e| AstraError::FileOperationError(e.to_string()))?;

        Ok(())
    }

    pub fn delete_remote_file(&self, remote_path: &Path) -> AstraResult<()> {
        let sftp = self
            .session
            .sftp()
            .map_err(|e| AstraError::SftpConnectionError(e.to_string()))?;

        sftp.unlink(remote_path)
            .map_err(|e| AstraError::FileOperationError(e.to_string()))?;

        Ok(())
    }

    pub fn sync_incremental(&self) -> AstraResult<Vec<SyncOperation>> {
        info!("Starting incremental sync");

        let local_path = Path::new(&self.config.local_path);
        let remote_path = Path::new(&self.config.remote_path);

        let local_files = self.get_local_files(local_path)?;
        let remote_files = self.get_remote_files(remote_path)?;

        let mut operations = Vec::new();
        let local_map: HashMap<PathBuf, FileStatus> = local_files
            .into_iter()
            .map(|f| (f.path.clone(), f))
            .collect();

        let remote_map: HashMap<PathBuf, FileStatus> = remote_files
            .into_iter()
            .map(|f| (f.path.clone(), f))
            .collect();

        for (local_path, local_file) in local_map.iter() {
            let relative_path = local_path.strip_prefix(local_path).unwrap_or(local_path);
            let remote_file_path = remote_path.join(relative_path);

            match remote_map.get(&remote_file_path) {
                Some(remote_file) => {
                    if local_file.modified > remote_file.modified
                        || local_file.checksum != remote_file.checksum
                    {
                        operations.push(SyncOperation {
                            operation_type: OperationType::Upload,
                            local_path: local_path.clone(),
                            remote_path: remote_file_path,
                            timestamp: Utc::now(),
                        });
                    }
                }
                None => {
                    operations.push(SyncOperation {
                        operation_type: OperationType::Upload,
                        local_path: local_path.clone(),
                        remote_path: remote_file_path,
                        timestamp: Utc::now(),
                    });
                }
            }
        }

        for (remote_path, _remote_file) in remote_map.iter() {
            let relative_path = remote_path.strip_prefix(remote_path).unwrap_or(remote_path);
            let local_file_path = local_path.join(relative_path);

            if !local_map.contains_key(&local_file_path) {
                operations.push(SyncOperation {
                    operation_type: OperationType::Download,
                    local_path: local_file_path,
                    remote_path: remote_path.clone(),
                    timestamp: Utc::now(),
                });
            }
        }

        Ok(operations)
    }

    pub fn execute_operations(&self, operations: &[SyncOperation]) -> AstraResult<()> {
        for operation in operations {
            match operation.operation_type {
                OperationType::Upload => {
                    self.upload_file(&operation.local_path, &operation.remote_path)?;
                }
                OperationType::Download => {
                    self.download_file(&operation.remote_path, &operation.local_path)?;
                }
                OperationType::Delete => {
                    self.delete_remote_file(&operation.remote_path)?;
                }
                OperationType::CreateDirectory => {
                    self.create_remote_directory(&operation.remote_path)?;
                }
            }
        }
        Ok(())
    }
}
