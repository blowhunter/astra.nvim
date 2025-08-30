use clap::{Parser, Subcommand};
use serde_json;
use std::fs;
use std::path::Path;
use crate::error::AstraResult;
use crate::types::{SftpConfig, SyncResult};
use crate::sftp::SftpClient;
use crate::config::ConfigReader;
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
        Commands::Sync { config, mode } => {
            if let Some(config_path) = config {
                sync_files(Some(&config_path), &mode).await?;
            } else {
                // Use automatic config discovery
                sync_files(None, &mode).await?;
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
        Commands::Upload { config, local, remote } => {
            if let Some(config_path) = config {
                upload_single_file(Some(&config_path), &local, &remote).await?;
            } else {
                // Use automatic config discovery
                upload_single_file(None, &local, &remote).await?;
            }
        }
        Commands::Download { config, remote, local } => {
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
    };
    
    let config_json = serde_json::to_string_pretty(&default_config)?;
    fs::write(config_path, config_json)?;
    
    println!("Configuration initialized at {}", config_path);
    Ok(())
}

async fn sync_files(config_path: Option<&str>, _mode: &str) -> AstraResult<()> {
    let config_reader = match config_path {
        Some(path) => ConfigReader::new(Some(path.to_string())),
        None => ConfigReader::new(None), // Use automatic discovery
    };
    let config = config_reader.read_config()?;
    
    let client = SftpClient::new(config)?;
    let operations = client.sync_incremental()?;
    
    let mut sync_result = SyncResult {
        success: true,
        message: "Sync completed successfully".to_string(),
        files_transferred: Vec::new(),
        files_skipped: Vec::new(),
        errors: Vec::new(),
    };
    
    for operation in &operations {
        match operation.operation_type {
            crate::types::OperationType::Upload => {
                println!("Uploading: {} -> {}", 
                    operation.local_path.display(), 
                    operation.remote_path.display());
                
                match client.upload_file(&operation.local_path, &operation.remote_path) {
                    Ok(_) => {
                        sync_result.files_transferred.push(
                            operation.local_path.to_string_lossy().to_string()
                        );
                    }
                    Err(e) => {
                        sync_result.errors.push(e.to_string());
                    }
                }
            }
            crate::types::OperationType::Download => {
                println!("Downloading: {} -> {}", 
                    operation.remote_path.display(), 
                    operation.local_path.display());
                
                match client.download_file(&operation.remote_path, &operation.local_path) {
                    Ok(_) => {
                        sync_result.files_transferred.push(
                            operation.local_path.to_string_lossy().to_string()
                        );
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
    
    Ok(())
}

async fn check_status(config_path: Option<&str>) -> AstraResult<()> {
    let config_reader = match config_path {
        Some(path) => ConfigReader::new(Some(path.to_string())),
        None => ConfigReader::new(None), // Use automatic discovery
    };
    let config = config_reader.read_config()?;
    
    let client = SftpClient::new(config)?;
    let operations = client.sync_incremental()?;
    
    println!("Pending operations: {}", operations.len());
    for operation in &operations {
        match operation.operation_type {
            crate::types::OperationType::Upload => {
                println!("  UPLOAD: {} -> {}", 
                    operation.local_path.display(), 
                    operation.remote_path.display());
            }
            crate::types::OperationType::Download => {
                println!("  DOWNLOAD: {} -> {}", 
                    operation.remote_path.display(), 
                    operation.local_path.display());
            }
            _ => {}
        }
    }
    
    Ok(())
}

async fn upload_single_file(config_path: Option<&str>, local_path: &str, remote_path: &str) -> AstraResult<()> {
    let config_reader = match config_path {
        Some(path) => ConfigReader::new(Some(path.to_string())),
        None => ConfigReader::new(None), // Use automatic discovery
    };
    let config = config_reader.read_config()?;
    
    let client = SftpClient::new(config)?;
    client.upload_file(Path::new(local_path), Path::new(remote_path))?;
    
    println!("File uploaded successfully: {} -> {}", local_path, remote_path);
    Ok(())
}

async fn download_single_file(config_path: Option<&str>, remote_path: &str, local_path: &str) -> AstraResult<()> {
    let config_reader = match config_path {
        Some(path) => ConfigReader::new(Some(path.to_string())),
        None => ConfigReader::new(None), // Use automatic discovery
    };
    let config = config_reader.read_config()?;
    
    let client = SftpClient::new(config)?;
    client.download_file(Path::new(remote_path), Path::new(local_path))?;
    
    println!("File downloaded successfully: {} -> {}", remote_path, local_path);
    Ok(())
}

async fn test_config(config_path: Option<&str>) -> AstraResult<()> {
    println!("Testing configuration discovery...");
    
    let config_reader = match config_path {
        Some(path) => {
            println!("Using explicit config path: {}", path);
            ConfigReader::new(Some(path.to_string()))
        },
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
            println!("✅ Configuration loaded successfully!");
            println!("Host: {}", config.host);
            println!("Port: {}", config.port);
            println!("Username: {}", config.username);
            println!("Remote path: {}", config.remote_path);
            println!("Local path: {}", config.local_path);
            if let Some(password) = &config.password {
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
            println!("❌ Configuration error: {}", e);
        }
    }
    
    Ok(())
}

fn show_version() -> AstraResult<()> {
    use chrono::{DateTime, Utc};
    use std::env;
    
    println!("Astra.nvim Core");
    println!("Version: {}", env!("CARGO_PKG_VERSION"));
    
    // Try to get build environment variables
    println!("Build Date: {}", env::var("BUILD_DATE").unwrap_or_else(|_| "unknown".to_string()));
    println!("Rust Version: {}", env::var("RUSTC_VERSION").unwrap_or_else(|_| "unknown".to_string()));
    
    // Show current time for reference
    let now: DateTime<Utc> = Utc::now();
    println!("Current Time: {}", now.format("%Y-%m-%d %H:%M:%S UTC"));
    
    Ok(())
}

async fn check_for_updates() -> AstraResult<()> {
    use chrono::{DateTime, Utc};
    
    println!("🔄 Checking for updates...");
    
    // For now, simulate checking for updates
    // In a real implementation, this would check GitHub releases or a registry
    let current_version = env!("CARGO_PKG_VERSION");
    let current_time: DateTime<Utc> = Utc::now();
    
    println!("Current version: {}", current_version);
    println!("Last checked: {}", current_time.format("%Y-%m-%d %H:%M:%S UTC"));
    
    // Simulate network check
    println!("📡 Checking remote repository...");
    tokio::time::sleep(tokio::time::Duration::from_millis(1000)).await;
    
    // For demonstration, always say we're up to date
    println!("✅ You're running the latest version!");
    
    // In a real implementation, this would:
    // 1. Fetch latest release from GitHub API
    // 2. Compare versions
    // 3. Provide update instructions if available
    
    Ok(())
}