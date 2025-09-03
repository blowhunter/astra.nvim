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

    /// Expand ~ to local home directory in a path (for local paths)
    fn expand_tilde_local(path: &str) -> String {
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

    /// Expand ~ to remote home directory in a path (for remote paths)
    /// Convert ~ to appropriate home directory format for remote paths
    pub fn expand_tilde_remote(path: &str, username: &str) -> String {
        if let Some(rest) = path.strip_prefix("~/") {
            // Convert ~/path to appropriate home directory/path
            let home_dir = if username == "root" { "/root".to_string() } else { format!("/home/{}", username) };
            format!("{}/{}", home_dir, rest)
        } else if path == "~" {
            // Convert ~ to appropriate home directory
            if username == "root" {
                "/root".to_string()
            } else {
                format!("/home/{}", username)
            }
        } else {
            // No tilde, return as-is (absolute paths remain unchanged)
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
                // For .json files, try to detect if it's VSCode SFTP config or Legacy Astra config
                let content = fs::read_to_string(&self.base_dir).map_err(|e| {
                    AstraError::ConfigurationError(format!("Failed to read config file: {}", e))
                })?;

                // Try to parse as VSCode SFTP config first
                if let Ok(vscode_config) = serde_json::from_str::<VsCodeSftpConfig>(&content) {
                    if vscode_config.protocol == "sftp" || vscode_config.protocol == "ftp" {
                        let expanded_config: SftpConfig = vscode_config.into();
                        let mut final_config = expanded_config.clone();

                        // Expand ~ in paths
                        if let Some(private_key_path) = &final_config.private_key_path {
                            if private_key_path.starts_with("~") {
                                final_config.private_key_path =
                                    Some(Self::expand_tilde_local(private_key_path));
                            }
                        }
                        if final_config.local_path.starts_with("~") {
                            final_config.local_path =
                                Self::expand_tilde_local(&final_config.local_path);
                        }
                        // Convert ~ to /home/username format for remote paths
                        if final_config.remote_path.starts_with("~") {
                            final_config.remote_path = Self::expand_tilde_remote(
                                &final_config.remote_path,
                                &final_config.username,
                            );
                        }

                        return Ok(final_config);
                    }
                }

                // Fall back to Legacy Astra config
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

        Err(AstraError::ConfigurationError(
            "No valid configuration file found".to_string(),
        ))
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
            expanded_config.sftp.private_key_path =
                Some(Self::expand_tilde_local(private_key_path));
        }
        if let Some(local_path) = &expanded_config.sftp.local_path {
            expanded_config.sftp.local_path = Some(Self::expand_tilde_local(local_path));
        }
        // remote_path is required in TOML config, not optional
        // Convert ~ to /home/username format for remote paths
        expanded_config.sftp.remote_path = Self::expand_tilde_remote(
            &expanded_config.sftp.remote_path,
            &expanded_config.sftp.username,
        );

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
                final_config.private_key_path = Some(Self::expand_tilde_local(private_key_path));
            }
        }
        if final_config.local_path.starts_with("~") {
            final_config.local_path = Self::expand_tilde_local(&final_config.local_path);
        }
        // Convert ~ to /home/username format for remote paths
        if final_config.remote_path.starts_with("~") {
            final_config.remote_path =
                Self::expand_tilde_remote(&final_config.remote_path, &final_config.username);
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

        // Set default language if not specified
        if config.language.is_none() {
            config.language = Some(crate::i18n::detect_language());
        }

        // Expand ~ in paths
        if let Some(private_key_path) = &config.private_key_path {
            if private_key_path.starts_with("~") {
                config.private_key_path = Some(Self::expand_tilde_local(private_key_path));
            }
        }
        if config.local_path.starts_with("~") {
            config.local_path = Self::expand_tilde_local(&config.local_path);
        }
        // Convert ~ to /home/username format for remote paths
        if config.remote_path.starts_with("~") {
            config.remote_path = Self::expand_tilde_remote(&config.remote_path, &config.username);
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

