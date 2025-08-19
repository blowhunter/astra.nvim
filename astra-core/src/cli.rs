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
}

pub async fn run_cli(cli: Cli) -> AstraResult<()> {
    tracing_subscriber::fmt::init();
    
    match cli.command {
        Commands::Init { config } => {
            init_config(&config).await?;
        }
        Commands::Sync { config, mode } => {
            sync_files(config.as_deref().unwrap_or("astra.json"), &mode).await?;
        }
        Commands::Status { config } => {
            check_status(config.as_deref().unwrap_or("astra.json")).await?;
        }
        Commands::Upload { config, local, remote } => {
            upload_single_file(config.as_deref().unwrap_or("astra.json"), &local, &remote).await?;
        }
        Commands::Download { config, remote, local } => {
            download_single_file(config.as_deref().unwrap_or("astra.json"), &remote, &local).await?;
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

async fn sync_files(config_path: &str, _mode: &str) -> AstraResult<()> {
    let config_reader = ConfigReader::new(Some(config_path.to_string()));
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

async fn check_status(config_path: &str) -> AstraResult<()> {
    let config_reader = ConfigReader::new(Some(config_path.to_string()));
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

async fn upload_single_file(config_path: &str, local_path: &str, remote_path: &str) -> AstraResult<()> {
    let config_reader = ConfigReader::new(Some(config_path.to_string()));
    let config = config_reader.read_config()?;
    
    let client = SftpClient::new(config)?;
    client.upload_file(Path::new(local_path), Path::new(remote_path))?;
    
    println!("File uploaded successfully: {} -> {}", local_path, remote_path);
    Ok(())
}

async fn download_single_file(config_path: &str, remote_path: &str, local_path: &str) -> AstraResult<()> {
    let config_reader = ConfigReader::new(Some(config_path.to_string()));
    let config = config_reader.read_config()?;
    
    let client = SftpClient::new(config)?;
    client.download_file(Path::new(remote_path), Path::new(local_path))?;
    
    println!("File downloaded successfully: {} -> {}", remote_path, local_path);
    Ok(())
}