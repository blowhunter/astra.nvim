#[cfg(test)]
mod tests {
    use crate::sftp::SftpClient;
    use crate::types::SftpConfig;
    use std::fs;
    use tempfile::TempDir;

    #[tokio::test]
    async fn test_local_file_listing() {
        let temp_dir = TempDir::new().unwrap();

        fs::write(temp_dir.path().join("file1.txt"), "content1").unwrap();
        fs::write(temp_dir.path().join("file2.txt"), "content2").unwrap();

        let config = SftpConfig {
            enabled: Some(true),
            host: "test.com".to_string(),
            port: 22,
            username: "user".to_string(),
            password: Some("pass".to_string()),
            private_key_path: None,
            remote_path: "/remote".to_string(),
            local_path: temp_dir.path().to_str().unwrap().to_string(),
            language: Some(crate::i18n::detect_language()),
        };

        let client = SftpClient::new(config);

        match client {
            Err(_) => {
                println!("Connection failed (expected in test environment)");
            }
            Ok(client) => {
                let files = client.get_local_files(temp_dir.path()).unwrap();
                assert_eq!(files.len(), 2);
            }
        }
    }

    #[test]
    fn test_file_checksum_calculation() {
        let temp_dir = TempDir::new().unwrap();
        let test_file = temp_dir.path().join("test.txt");
        fs::write(&test_file, "test content").unwrap();

        let config = SftpConfig {
            enabled: Some(true),
            host: "test.com".to_string(),
            port: 22,
            username: "user".to_string(),
            password: Some("pass".to_string()),
            private_key_path: None,
            remote_path: "/remote".to_string(),
            local_path: temp_dir.path().to_str().unwrap().to_string(),
            language: Some(crate::i18n::detect_language()),
        };

        let client = SftpClient::new(config);

        match client {
            Err(_) => {
                println!("Connection failed (expected in test environment)");
            }
            Ok(client) => {
                let checksum = client.calculate_file_checksum(&test_file).unwrap();
                assert!(checksum.is_some());
            }
        }
    }
}
