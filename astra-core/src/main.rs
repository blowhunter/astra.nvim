pub mod background;
pub mod cli;
pub mod config;
pub mod error;
pub mod i18n;
pub mod sftp;
pub mod types;
pub mod version;

#[cfg(test)]
mod cli_tests;
#[cfg(test)]
mod integration_tests;
#[cfg(test)]
mod sftp_tests;
#[cfg(test)]
mod test_tilde;
#[cfg(test)]
mod types_tests;

use crate::error::AstraResult;
use clap::Parser;
use cli::{run_cli, Cli};

#[tokio::main]
async fn main() -> AstraResult<()> {
    let cli = Cli::parse();
    run_cli(cli).await
}
