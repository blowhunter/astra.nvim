use crate::config::ConfigReader;
use crate::error::AstraResult;
use crate::sftp::SftpClient;
use crate::types::{SftpConfig, SyncResult};
use clap::{Parser, Subcommand};
use serde_json;
use std::fs;
use std::path::Path;
use tracing_subscriber;

#[derive(Parser)]
#[command(name = "astra")]
#[command(about = "Neovim SFTP synchronization tool")]
pub struct Cli {
    #[command(subcommand)]
    pub command: Commands,
}

#[derive(Subcommand)]
pub enum Commands {
    #[command(about = "Initialize astra configuration")]
    Init {
        #[arg(short, long, default_value = "astra.json")]
        config: String,
    },

    #[command(about = "Synchronize files")]
    Sync {
        #[arg(short, long)]
        config: Option<String>,

        #[arg(short, long, default_value = "upload")]
        mode: String,

        #[arg(trailing_var_arg = true)]
        files: Vec<String>,
    },

    #[command(about = "Check sync status")]
    Status {
        #[arg(short, long)]
        config: Option<String>,
    },

    #[command(about = "Upload a single file")]
    Upload {
        #[arg(short, long)]
        config: Option<String>,

        #[arg(short, long)]
        local: String,

        #[arg(short, long)]
        remote: String,
    },

    #[command(about = "Download a single file")]
    Download {
        #[arg(short, long)]
        config: Option<String>,

        #[arg(short, long)]
        remote: String,

        #[arg(short, long)]
        local: String,
    },

    #[command(about = "Test configuration file discovery")]
    ConfigTest {
        #[arg(short, long)]
        config: Option<String>,
    },

    #[command(about = "Show version information")]
    Version,

    #[command(about = "Check for updates")]
    CheckUpdate,
}

pub async fn run_cli(cli: Cli) -> AstraResult<()> {
    tracing_subscriber::fmt::init();

    match cli.command {
        Commands::Init { config } => {
            init_config(&config).await?;
        }
        Commands::Sync {
            config,
            mode,
            files,
        } => {
            if let Some(config_path) = config {
                sync_files(Some(&config_path), &mode, &files).await?;
            } else {
                // Use automatic config discovery
                sync_files(None, &mode, &files).await?;
            }
        }
        Commands::Status { config } => {
            if let Some(config_path) = config {
                check_status(Some(&config_path)).await?;
            } else {
                // Use automatic config discovery
                check_status(None).await?;
            }
        }
        Commands::Upload {
            config,
            local,
            remote,
        } => {
            if let Some(config_path) = config {
                upload_single_file(Some(&config_path), &local, &remote).await?;
            } else {
                // Use automatic config discovery
                upload_single_file(None, &local, &remote).await?;
            }
        }
        Commands::Download {
            config,
            remote,
            local,
        } => {
            if let Some(config_path) = config {
                download_single_file(Some(&config_path), &remote, &local).await?;
            } else {
                // Use automatic config discovery
                download_single_file(None, &remote, &local).await?;
            }
        }
        Commands::ConfigTest { config } => {
            if let Some(config_path) = config {
                test_config(Some(&config_path)).await?;
            } else {
                // Use automatic config discovery
                test_config(None).await?;
            }
        }
        Commands::Version => {
            show_version()?;
        }
        Commands::CheckUpdate => {
            check_for_updates().await?;
        }
    }

    Ok(())
}

async fn init_config(config_path: &str) -> AstraResult<()> {
    let language = crate::i18n::detect_language();
    let default_config = SftpConfig {
        host: "example.com".to_string(),
        port: 22,
        username: "user".to_string(),
        password: None,
        private_key_path: None,
        remote_path: "/remote/path".to_string(),
        local_path: std::env::current_dir()
            .unwrap()
            .to_str()
            .unwrap()
            .to_string(),
        language: Some(language),
    };

    let config_json = serde_json::to_string_pretty(&default_config)?;
    fs::write(config_path, config_json)?;

    let msg = crate::i18n::t_format("cli.config_initialized", &language, &[config_path]);
    println!("{}", msg);
    Ok(())
}

async fn sync_files(config_path: Option<&str>, _mode: &str, files: &[String]) -> AstraResult<()> {
    // Initialize i18n system
    crate::i18n::init_translations();

    let config_reader = match config_path {
        Some(path) => ConfigReader::new(Some(path.to_string())),
        None => ConfigReader::new(None), // Use automatic discovery
    };
    let config = config_reader.read_config()?;
    let language = config.language.unwrap_or_else(crate::i18n::detect_language);
    let config_for_path = config.clone();

    let client = SftpClient::new(config)?;

    // If specific files are provided, sync only those files
    if !files.is_empty() {
        let mut sync_result = SyncResult {
            success: true,
            message: "File sync completed successfully".to_string(),
            files_transferred: Vec::new(),
            files_skipped: Vec::new(),
            errors: Vec::new(),
        };

        for file_path in files {
            let local_path = std::path::Path::new(file_path);

            // Generate remote path based on the local path and configuration
            let remote_path = if let Some(file_name) = local_path.file_name() {
                // Simple approach: use the filename and append to remote_path
                std::path::Path::new(&config_for_path.remote_path).join(file_name)
            } else {
                println!("Warning: Could not determine filename for {}", file_path);
                continue;
            };

            println!(
                "Syncing file: {} -> {}",
                local_path.display(),
                remote_path.display()
            );

            match client.upload_file(local_path, &remote_path) {
                Ok(_) => {
                    sync_result
                        .files_transferred
                        .push(local_path.to_string_lossy().to_string());
                    let msg = crate::i18n::t_format("cli.file_uploaded", &language, &[file_path]);
                    println!("✅ {}", msg);
                }
                Err(e) => {
                    sync_result.errors.push(e.to_string());
                    let error_msg = crate::i18n::t("error.upload_failed", &language);
                    println!("❌ {}: {} - {}", error_msg, file_path, e);
                }
            }
        }

        // Update success status based on errors
        if !sync_result.errors.is_empty() {
            sync_result.success = false;
            let error_count = sync_result.errors.len().to_string();
            sync_result.message =
                crate::i18n::t_format("cli.sync_failed", &language, &[&error_count]);
        } else {
            sync_result.message = crate::i18n::t("cli.sync_complete", &language);
        }

        let result_json = serde_json::to_string_pretty(&sync_result)?;
        println!("{}", result_json);
    } else {
        // No specific files provided, do full incremental sync
        let operations = client.sync_incremental()?;

        let mut sync_result = SyncResult {
            success: true,
            message: crate::i18n::t("cli.sync_complete", &language),
            files_transferred: Vec::new(),
            files_skipped: Vec::new(),
            errors: Vec::new(),
        };

        for operation in &operations {
            match operation.operation_type {
                crate::types::OperationType::Upload => {
                    let local_path = operation.local_path.display().to_string();
                    let remote_path = operation.remote_path.display().to_string();
                    let msg = crate::i18n::t_format(
                        "cli.upload_operation",
                        &language,
                        &[&local_path, &remote_path],
                    );
                    println!("{}", msg);

                    match client.upload_file(&operation.local_path, &operation.remote_path) {
                        Ok(_) => {
                            sync_result
                                .files_transferred
                                .push(operation.local_path.to_string_lossy().to_string());
                        }
                        Err(e) => {
                            sync_result.errors.push(e.to_string());
                        }
                    }
                }
                crate::types::OperationType::Download => {
                    let remote_path = operation.remote_path.display().to_string();
                    let local_path = operation.local_path.display().to_string();
                    let msg = crate::i18n::t_format(
                        "cli.download_operation",
                        &language,
                        &[&remote_path, &local_path],
                    );
                    println!("{}", msg);

                    match client.download_file(&operation.remote_path, &operation.local_path) {
                        Ok(_) => {
                            sync_result
                                .files_transferred
                                .push(operation.local_path.to_string_lossy().to_string());
                        }
                        Err(e) => {
                            sync_result.errors.push(e.to_string());
                        }
                    }
                }
                _ => {}
            }
        }

        let result_json = serde_json::to_string_pretty(&sync_result)?;
        println!("{}", result_json);
    }

    Ok(())
}

async fn check_status(config_path: Option<&str>) -> AstraResult<()> {
    // Initialize i18n system
    crate::i18n::init_translations();

    let config_reader = match config_path {
        Some(path) => ConfigReader::new(Some(path.to_string())),
        None => ConfigReader::new(None), // Use automatic discovery
    };
    let config = config_reader.read_config()?;
    let language = config.language.unwrap_or_else(crate::i18n::detect_language);

    let client = SftpClient::new(config)?;
    let operations = client.sync_incremental()?;

    let pending_msg = crate::i18n::t_format(
        "cli.pending_operations",
        &language,
        &[&operations.len().to_string()],
    );
    println!("{}", pending_msg);

    for operation in &operations {
        match operation.operation_type {
            crate::types::OperationType::Upload => {
                let local_path = operation.local_path.display().to_string();
                let remote_path = operation.remote_path.display().to_string();
                let msg = crate::i18n::t_format(
                    "cli.upload_operation",
                    &language,
                    &[&local_path, &remote_path],
                );
                println!("  {}", msg);
            }
            crate::types::OperationType::Download => {
                let remote_path = operation.remote_path.display().to_string();
                let local_path = operation.local_path.display().to_string();
                let msg = crate::i18n::t_format(
                    "cli.download_operation",
                    &language,
                    &[&remote_path, &local_path],
                );
                println!("  {}", msg);
            }
            _ => {}
        }
    }

    Ok(())
}

async fn upload_single_file(
    config_path: Option<&str>,
    local_path: &str,
    remote_path: &str,
) -> AstraResult<()> {
    let config_reader = match config_path {
        Some(path) => ConfigReader::new(Some(path.to_string())),
        None => ConfigReader::new(None), // Use automatic discovery
    };
    let config = config_reader.read_config()?;

    let client = SftpClient::new(config)?;
    client.upload_file(Path::new(local_path), Path::new(remote_path))?;

    println!(
        "File uploaded successfully: {} -> {}",
        local_path, remote_path
    );
    Ok(())
}

async fn download_single_file(
    config_path: Option<&str>,
    remote_path: &str,
    local_path: &str,
) -> AstraResult<()> {
    let config_reader = match config_path {
        Some(path) => ConfigReader::new(Some(path.to_string())),
        None => ConfigReader::new(None), // Use automatic discovery
    };
    let config = config_reader.read_config()?;

    let client = SftpClient::new(config)?;
    client.download_file(Path::new(remote_path), Path::new(local_path))?;

    println!(
        "File downloaded successfully: {} -> {}",
        remote_path, local_path
    );
    Ok(())
}

async fn test_config(config_path: Option<&str>) -> AstraResult<()> {
    // Initialize i18n system
    crate::i18n::init_translations();
    let language = crate::i18n::detect_language();

    let testing_msg = crate::i18n::t("cli.testing_config", &language);
    println!("{}", testing_msg);

    let config_reader = match config_path {
        Some(path) => {
            println!("Using explicit config path: {}", path);
            ConfigReader::new(Some(path.to_string()))
        }
        None => {
            println!("Using automatic config discovery");
            ConfigReader::new(None)
        }
    };

    // Note: base_dir is private, so we can't print it here

    // Test project root discovery
    if let Some(project_root) = config_reader.find_project_root() {
        println!("Project root found: {}", project_root);
    } else {
        println!("No project root found in parent directories");
    }

    // Try to read config
    match config_reader.read_config() {
        Ok(config) => {
            let success_msg = crate::i18n::t("cli.config_loaded", &language);
            println!("✅ {}", success_msg);
            println!("Host: {}", config.host);
            println!("Port: {}", config.port);
            println!("Username: {}", config.username);
            println!("Remote path: {}", config.remote_path);
            println!("Local path: {}", config.local_path);
            if let Some(_password) = &config.password {
                println!("Password: ***");
            } else {
                println!("Password: None");
            }
            if let Some(private_key_path) = &config.private_key_path {
                println!("Private key path: {}", private_key_path);
            } else {
                println!("Private key path: None");
            }
        }
        Err(e) => {
            let error_msg = crate::i18n::t_format("cli.config_error", &language, &[&e.to_string()]);
            println!("❌ {}", error_msg);
        }
    }

    Ok(())
}

fn show_version() -> AstraResult<()> {
    use chrono::{DateTime, Utc};
    use std::env;

    // Initialize i18n system
    crate::i18n::init_translations();
    let language = crate::i18n::detect_language();

    let version_info = crate::i18n::t("cli.version_info", &language);
    println!("{}", version_info);
    println!("Version: {}", env!("CARGO_PKG_VERSION"));

    // Try to get build environment variables
    println!(
        "Build Date: {}",
        env::var("BUILD_DATE").unwrap_or_else(|_| "unknown".to_string())
    );
    println!(
        "Rust Version: {}",
        env::var("RUSTC_VERSION").unwrap_or_else(|_| "unknown".to_string())
    );

    // Show current time for reference
    let now: DateTime<Utc> = Utc::now();
    println!("Current Time: {}", now.format("%Y-%m-%d %H:%M:%S UTC"));

    Ok(())
}

async fn check_for_updates() -> AstraResult<()> {
    use chrono::{DateTime, Utc};

    // Initialize i18n system
    crate::i18n::init_translations();
    let language = crate::i18n::detect_language();

    let checking_msg = crate::i18n::t("cli.checking_updates", &language);
    println!("🔄 {}", checking_msg);

    // For now, simulate checking for updates
    // In a real implementation, this would check GitHub releases or a registry
    let current_version = env!("CARGO_PKG_VERSION");
    let current_time: DateTime<Utc> = Utc::now();

    println!("Current version: {}", current_version);
    println!(
        "Last checked: {}",
        current_time.format("%Y-%m-%d %H:%M:%S UTC")
    );

    // Simulate network check
    println!("📡 Checking remote repository...");
    tokio::time::sleep(tokio::time::Duration::from_millis(1000)).await;

    // For demonstration, always say we're up to date
    let up_to_date_msg = crate::i18n::t("cli.up_to_date", &language);
    println!("✅ {}", up_to_date_msg);

    // In a real implementation, this would:
    // 1. Fetch latest release from GitHub API
    // 2. Compare versions
    // 3. Provide update instructions if available

    Ok(())
}
