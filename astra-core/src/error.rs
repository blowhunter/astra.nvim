use thiserror::Error;

#[derive(Debug, Error)]
pub enum AstraError {
    #[error("SFTP connection error: {0}")]
    SftpConnectionError(String),

    #[error("Authentication error: {0}")]
    AuthenticationError(String),

    #[error("File operation error: {0}")]
    FileOperationError(String),

    #[error("Configuration error: {0}")]
    ConfigurationError(String),

    #[error("IO error: {0}")]
    IoError(#[from] std::io::Error),

    #[error("SSH2 error: {0}")]
    Ssh2Error(#[from] ssh2::Error),

    #[error("JSON error: {0}")]
    JsonError(#[from] serde_json::Error),

    #[error("Chrono error: {0}")]
    ChronoError(#[from] chrono::ParseError),

    #[error("System error: {0}")]
    SystemError(String),

    #[error("Task error: {0}")]
    TaskError(String),
}

pub type AstraResult<T> = Result<T, AstraError>;
