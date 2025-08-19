#[cfg(test)]
mod tests {
    use crate::types::{SftpConfig, FileStatus, SyncOperation, OperationType};
    use chrono::{DateTime, Utc};
    use tempfile::TempDir;
    use std::fs;
    use std::path::PathBuf;
    
    #[test]
    fn test_config_serialization() {
        let config = SftpConfig {
            host: "test.com".to_string(),
            port: 22,
            username: "user".to_string(),
            password: Some("pass".to_string()),
            private_key_path: None,
            remote_path: "/remote".to_string(),
            local_path: "/local".to_string(),
        };
        
        let json = serde_json::to_string(&config).unwrap();
        let deserialized: SftpConfig = serde_json::from_str(&json).unwrap();
        
        assert_eq!(config.host, deserialized.host);
        assert_eq!(config.port, deserialized.port);
        assert_eq!(config.username, deserialized.username);
        assert_eq!(config.password, deserialized.password);
    }
    
    #[test]
    fn test_file_status_creation() {
        let temp_dir = TempDir::new().unwrap();
        let test_file = temp_dir.path().join("test.txt");
        fs::write(&test_file, "test content").unwrap();
        
        let metadata = fs::metadata(&test_file).unwrap();
        let modified: DateTime<Utc> = metadata.modified().unwrap().into();
        
        let file_status = FileStatus {
            path: test_file.clone(),
            size: metadata.len(),
            modified,
            is_directory: false,
            checksum: None,
        };
        
        assert_eq!(file_status.path, test_file);
        assert_eq!(file_status.size, 12);
        assert!(!file_status.is_directory);
    }
    
    #[test]
    fn test_sync_operation_creation() {
        let operation = SyncOperation {
            operation_type: OperationType::Upload,
            local_path: PathBuf::from("/local/file.txt"),
            remote_path: PathBuf::from("/remote/file.txt"),
            timestamp: Utc::now(),
        };
        
        matches!(operation.operation_type, OperationType::Upload);
        assert_eq!(operation.local_path, PathBuf::from("/local/file.txt"));
        assert_eq!(operation.remote_path, PathBuf::from("/remote/file.txt"));
    }
}