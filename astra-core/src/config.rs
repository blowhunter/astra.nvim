use crate::error::{AstraError, AstraResult};
use crate::types::{AstraTomlConfig, SftpConfig, VsCodeSftpConfig};
use std::env;
use std::fs;
use std::path::Path;

pub struct ConfigReader {
    base_dir: String,
}

impl ConfigReader {
    pub fn new(base_dir: Option<String>) -> Self {
        Self {
            base_dir: base_dir
                .unwrap_or_else(|| env::current_dir().unwrap().to_string_lossy().to_string()),
        }
    }

    /// Expand ~ to home directory in a path
    fn expand_tilde(path: &str) -> String {
        if let Some(rest) = path.strip_prefix("~/") {
            // Handle ~/path
            if let Ok(home_dir) = env::var("HOME") {
                format!("{}/{}", home_dir, rest)
            } else {
                // Fallback to current directory if HOME is not set
                format!("{}/{}", env::current_dir().unwrap().to_string_lossy(), rest)
            }
        } else if path == "~" {
            // Handle plain ~
            if let Ok(home_dir) = env::var("HOME") {
                home_dir
            } else {
                env::current_dir().unwrap().to_string_lossy().to_string()
            }
        } else {
            // No tilde, return as-is
            path.to_string()
        }
    }

    pub fn read_config(&self) -> AstraResult<SftpConfig> {
        // Try to read configurations in this order:
        // 1. .astra-settings/settings.toml
        // 2. .vscode/sftp.json
        // 3. astra.json (existing format)
        
        // If base_dir is already a file path (not a directory), treat it as a config file
        if self.base_dir.ends_with(".json") || self.base_dir.ends_with(".toml") {
            if self.base_dir.ends_with(".toml") {
                return self.read_astra_toml_config_from_path(&self.base_dir);
            } else {
                return self.read_legacy_astra_config_from_path(&self.base_dir);
            }
        }
        
        // First, try to use project root discovery for automatic config finding
        if let Some(project_root) = self.find_project_root() {
            let project_reader = ConfigReader::new(Some(project_root));
            if let Ok(config) = project_reader.read_astra_toml_config() {
                return Ok(config);
            }
            if let Ok(config) = project_reader.read_vscode_sftp_config() {
                return Ok(config);
            }
            if let Ok(config) = project_reader.read_legacy_astra_config() {
                return Ok(config);
            }
        }

        // If no project root found, try current directory
        if let Ok(config) = self.read_astra_toml_config() {
            return Ok(config);
        }

        if let Ok(config) = self.read_vscode_sftp_config() {
            return Ok(config);
        }

        if let Ok(config) = self.read_legacy_astra_config() {
            return Ok(config);
        }

        return Err(AstraError::ConfigurationError(
            "No valid configuration file found".to_string(),
        ));
    }

    fn read_astra_toml_config(&self) -> AstraResult<SftpConfig> {
        let config_path = format!("{}/.astra-settings/settings.toml", self.base_dir);
        self.read_astra_toml_config_from_path(&config_path)
    }

    fn read_astra_toml_config_from_path(&self, config_path: &str) -> AstraResult<SftpConfig> {
        if !Path::new(config_path).exists() {
            return Err(AstraError::ConfigurationError(
                "Astra TOML config not found".to_string(),
            ));
        }

        let content = fs::read_to_string(config_path).map_err(|e| {
            AstraError::ConfigurationError(format!("Failed to read TOML config: {}", e))
        })?;

        let config: AstraTomlConfig = toml::from_str(&content).map_err(|e| {
            AstraError::ConfigurationError(format!("Failed to parse TOML config: {}", e))
        })?;

        // Expand ~ in paths
        let mut expanded_config = config.clone();
        if let Some(private_key_path) = &expanded_config.sftp.private_key_path {
            expanded_config.sftp.private_key_path = Some(Self::expand_tilde(private_key_path));
        }
        if let Some(local_path) = &expanded_config.sftp.local_path {
            expanded_config.sftp.local_path = Some(Self::expand_tilde(local_path));
        }

        Ok(expanded_config.into())
    }

    fn read_vscode_sftp_config(&self) -> AstraResult<SftpConfig> {
        let config_path = format!("{}/.vscode/sftp.json", self.base_dir);

        if !Path::new(&config_path).exists() {
            return Err(AstraError::ConfigurationError(
                "VSCode SFTP config not found".to_string(),
            ));
        }

        let content = fs::read_to_string(&config_path).map_err(|e| {
            AstraError::ConfigurationError(format!("Failed to read VSCode SFTP config: {}", e))
        })?;

        let config: VsCodeSftpConfig = serde_json::from_str(&content).map_err(|e| {
            AstraError::ConfigurationError(format!("Failed to parse VSCode SFTP config: {}", e))
        })?;

        // Only accept if protocol is sftp or ftp
        if config.protocol != "sftp" && config.protocol != "ftp" {
            return Err(AstraError::ConfigurationError(
                "Unsupported protocol in VSCode SFTP config".to_string(),
            ));
        }

        // Expand ~ in paths and convert to SftpConfig
        let expanded_config: SftpConfig = config.into();
        let mut final_config = expanded_config.clone();
        
        if let Some(private_key_path) = &final_config.private_key_path {
            if private_key_path.starts_with("~") {
                final_config.private_key_path = Some(Self::expand_tilde(private_key_path));
            }
        }
        if final_config.local_path.starts_with("~") {
            final_config.local_path = Self::expand_tilde(&final_config.local_path);
        }

        Ok(final_config)
    }

    fn read_legacy_astra_config(&self) -> AstraResult<SftpConfig> {
        let config_path = format!("{}/astra.json", self.base_dir);
        self.read_legacy_astra_config_from_path(&config_path)
    }

    fn read_legacy_astra_config_from_path(&self, config_path: &str) -> AstraResult<SftpConfig> {
        if !Path::new(config_path).exists() {
            return Err(AstraError::ConfigurationError(
                "Legacy Astra config not found".to_string(),
            ));
        }

        let content = fs::read_to_string(config_path).map_err(|e| {
            AstraError::ConfigurationError(format!("Failed to read legacy Astra config: {}", e))
        })?;

        let mut config: SftpConfig = serde_json::from_str(&content).map_err(|e| {
            AstraError::ConfigurationError(format!("Failed to parse legacy Astra config: {}", e))
        })?;

        // Expand ~ in paths
        if let Some(private_key_path) = &config.private_key_path {
            if private_key_path.starts_with("~") {
                config.private_key_path = Some(Self::expand_tilde(private_key_path));
            }
        }
        if config.local_path.starts_with("~") {
            config.local_path = Self::expand_tilde(&config.local_path);
        }

        Ok(config)
    }

    pub fn find_project_root(&self) -> Option<String> {
        let base_path = Path::new(&self.base_dir);
        let mut current_path = base_path;

        loop {
            if current_path.join(".astra-settings").exists()
                || current_path.join(".vscode").exists()
                || current_path.join("astra.json").exists()
            {
                return Some(current_path.to_string_lossy().to_string());
            }

            if let Some(parent) = current_path.parent() {
                current_path = parent;
            } else {
                break;
            }
        }

        None
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::fs;
    use tempfile::TempDir;

    #[test]
    fn test_find_project_root() {
        let temp_dir = TempDir::new().unwrap();
        let config_reader = ConfigReader::new(Some(temp_dir.path().to_string_lossy().to_string()));

        // Test with .astra-settings
        fs::create_dir_all(temp_dir.path().join(".astra-settings")).unwrap();
        let root = config_reader.find_project_root();
        assert_eq!(root, Some(temp_dir.path().to_string_lossy().to_string()));

        // Test with .vscode
        fs::remove_dir_all(temp_dir.path().join(".astra-settings")).unwrap();
        fs::create_dir_all(temp_dir.path().join(".vscode")).unwrap();
        let root = config_reader.find_project_root();
        assert_eq!(root, Some(temp_dir.path().to_string_lossy().to_string()));

        // Test with astra.json
        fs::remove_dir_all(temp_dir.path().join(".vscode")).unwrap();
        fs::write(temp_dir.path().join("astra.json"), "{}").unwrap();
        let root = config_reader.find_project_root();
        assert_eq!(root, Some(temp_dir.path().to_string_lossy().to_string()));
    }

    #[test]
    fn test_read_astra_toml_config() {
        let temp_dir = TempDir::new().unwrap();
        let config_reader = ConfigReader::new(Some(temp_dir.path().to_string_lossy().to_string()));

        // Create .astra-settings directory and settings.toml
        fs::create_dir_all(temp_dir.path().join(".astra-settings")).unwrap();
        let toml_content = r#"
[sftp]
host = "example.com"
port = 2222
username = "testuser"
password = "testpass"
remote_path = "/remote/test"
local_path = "/local/test"

[sync]
auto_sync = true
sync_on_save = true
sync_interval = 60000
"#;
        fs::write(
            temp_dir.path().join(".astra-settings/settings.toml"),
            toml_content,
        )
        .unwrap();

        let config = config_reader.read_astra_toml_config().unwrap();
        assert_eq!(config.host, "example.com");
        assert_eq!(config.port, 2222);
        assert_eq!(config.username, "testuser");
        assert_eq!(config.password, Some("testpass".to_string()));
        assert_eq!(config.remote_path, "/remote/test");
        assert_eq!(config.local_path, "/local/test");
    }

    #[test]
    fn test_read_vscode_sftp_config() {
        let temp_dir = TempDir::new().unwrap();
        let config_reader = ConfigReader::new(Some(temp_dir.path().to_string_lossy().to_string()));

        // Create .vscode directory and sftp.json
        fs::create_dir_all(temp_dir.path().join(".vscode")).unwrap();
        let vscode_config = r#"
{
  "name": "Test Server",
  "host": "vscode.example.com",
  "protocol": "sftp",
  "port": 22,
  "username": "vscodeuser",
  "remotePath": "/remote/vscode",
  "password": "vscodepass",
  "uploadOnSave": true
}
"#;
        fs::write(temp_dir.path().join(".vscode/sftp.json"), vscode_config).unwrap();

        let config = config_reader.read_vscode_sftp_config().unwrap();
        assert_eq!(config.host, "vscode.example.com");
        assert_eq!(config.port, 22);
        assert_eq!(config.username, "vscodeuser");
        assert_eq!(config.password, Some("vscodepass".to_string()));
        assert_eq!(config.remote_path, "/remote/vscode");
    }

    #[test]
    fn test_read_legacy_astra_config() {
        let temp_dir = TempDir::new().unwrap();
        let config_reader = ConfigReader::new(Some(temp_dir.path().to_string_lossy().to_string()));

        // Create astra.json
        let legacy_config = r#"
{
  "host": "legacy.example.com",
  "port": 2222,
  "username": "legacyuser",
  "password": "legacypass",
  "private_key_path": "/path/to/key",
  "remote_path": "/remote/legacy",
  "local_path": "/local/legacy"
}
"#;
        fs::write(temp_dir.path().join("astra.json"), legacy_config).unwrap();

        let config = config_reader.read_legacy_astra_config().unwrap();
        assert_eq!(config.host, "legacy.example.com");
        assert_eq!(config.port, 2222);
        assert_eq!(config.username, "legacyuser");
        assert_eq!(config.password, Some("legacypass".to_string()));
        assert_eq!(config.private_key_path, Some("/path/to/key".to_string()));
        assert_eq!(config.remote_path, "/remote/legacy");
        assert_eq!(config.local_path, "/local/legacy");
    }

    #[test]
    fn test_config_fallback_chain() {
        let temp_dir = TempDir::new().unwrap();
        let config_reader = ConfigReader::new(Some(temp_dir.path().to_string_lossy().to_string()));

        // Test no config files
        let result = config_reader.read_config();
        assert!(result.is_err());

        // Test with VSCode config (should be ignored if unsupported protocol)
        fs::create_dir_all(temp_dir.path().join(".vscode")).unwrap();
        let unsupported_config = r#"
{
  "name": "Test Server",
  "host": "example.com",
  "protocol": "http",
  "port": 80,
  "username": "user",
  "remotePath": "/remote",
  "password": "pass"
}
"#;
        fs::write(
            temp_dir.path().join(".vscode/sftp.json"),
            unsupported_config,
        )
        .unwrap();

        let result = config_reader.read_config();
        assert!(result.is_err());

        // Test with TOML config
        fs::create_dir_all(temp_dir.path().join(".astra-settings")).unwrap();
        let toml_content = r#"
[sftp]
host = "example.com"
port = 22
username = "testuser"
remote_path = "/remote/test"
"#;
        fs::write(
            temp_dir.path().join(".astra-settings/settings.toml"),
            toml_content,
        )
        .unwrap();

        let config = config_reader.read_config().unwrap();
        assert_eq!(config.host, "example.com");
        assert_eq!(config.username, "testuser");
    }

    #[test]
    fn test_vscode_unsupported_protocol() {
        let temp_dir = TempDir::new().unwrap();
        let config_reader = ConfigReader::new(Some(temp_dir.path().to_string_lossy().to_string()));

        // Create VSCode config with unsupported protocol
        fs::create_dir_all(temp_dir.path().join(".vscode")).unwrap();
        let unsupported_config = r#"
{
  "name": "Test Server",
  "host": "example.com",
  "protocol": "http",
  "port": 80,
  "username": "user",
  "remotePath": "/remote",
  "password": "pass"
}
"#;
        fs::write(
            temp_dir.path().join(".vscode/sftp.json"),
            unsupported_config,
        )
        .unwrap();

        let result = config_reader.read_vscode_sftp_config();
        assert!(result.is_err());
    }
}

