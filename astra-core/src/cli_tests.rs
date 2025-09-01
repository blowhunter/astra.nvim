#[cfg(test)]
mod tests {
    use crate::cli::{Cli, Commands};
    use crate::types::SftpConfig;
    use clap::Parser;
    use std::fs;
    use tempfile::TempDir;

    #[test]
    fn test_cli_command_parsing() {
        let cli = Cli::try_parse_from(&["astra", "init", "--config", "test.json"]).unwrap();

        match cli.command {
            Commands::Init { config } => {
                assert_eq!(config, "test.json");
            }
            _ => panic!("Expected Init command"),
        }
    }

    #[test]
    fn test_sync_command_parsing() {
        let cli =
            Cli::try_parse_from(&["astra", "sync", "--config", "test.json", "--mode", "upload"])
                .unwrap();

        match cli.command {
            Commands::Sync {
                config,
                mode,
                files,
            } => {
                assert_eq!(config, Some("test.json".to_string()));
                assert_eq!(mode, "upload");
                assert_eq!(files, Vec::<String>::new());
            }
            _ => panic!("Expected Sync command"),
        }
    }

    #[test]
    fn test_status_command_parsing() {
        let cli = Cli::try_parse_from(&["astra", "status", "--config", "test.json"]).unwrap();

        match cli.command {
            Commands::Status { config } => {
                assert_eq!(config, Some("test.json".to_string()));
            }
            _ => panic!("Expected Status command"),
        }
    }

    #[tokio::test]
    async fn test_config_file_creation() {
        let temp_dir = TempDir::new().unwrap();
        let config_path = temp_dir.path().join("test_config.json");

        let config = SftpConfig {
            host: "test.com".to_string(),
            port: 22,
            username: "user".to_string(),
            password: Some("pass".to_string()),
            private_key_path: None,
            remote_path: "/remote".to_string(),
            local_path: temp_dir.path().to_str().unwrap().to_string(),
            language: None,
        };

        let config_json = serde_json::to_string_pretty(&config).unwrap();
        fs::write(&config_path, config_json).unwrap();

        assert!(config_path.exists());

        let read_content = fs::read_to_string(&config_path).unwrap();
        let deserialized_config: SftpConfig = serde_json::from_str(&read_content).unwrap();

        assert_eq!(config.host, deserialized_config.host);
        assert_eq!(config.port, deserialized_config.port);
        assert_eq!(config.username, deserialized_config.username);
    }
}
