pub mod types;
pub mod error;
pub mod sftp;
pub mod cli;
pub mod config;

#[cfg(test)]
mod types_tests;
#[cfg(test)]
mod sftp_tests;
#[cfg(test)]
mod cli_tests;
#[cfg(test)]
mod integration_tests;

use cli::{run_cli, Cli};
use clap::Parser;
use crate::error::AstraResult;

#[tokio::main]
async fn main() -> AstraResult<()> {
    let cli = Cli::parse();
    run_cli(cli).await
}
