# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Astra.nvim is a comprehensive Neovim plugin for SFTP-based file synchronization with incremental sync capabilities. Built with Rust for performance and Lua for Neovim integration.

## Project Structure

```
astra.nvim/
├── astra-core/              # Rust core implementation
│   ├── src/
│   │   ├── main.rs          # Main entry point and CLI
│   │   ├── types.rs         # Data structures (SftpConfig, FileStatus, SyncResult)
│   │   ├── error.rs         # Error handling with AstraError and AstraResult
│   │   ├── sftp.rs          # SFTP operations and client implementation
│   │   ├── cli.rs           # CLI interface with subcommands
│   │   ├── config.rs        # Configuration management with multi-format support
│   │   ├── types_tests.rs   # Unit tests for data structures
│   │   ├── sftp_tests.rs    # Unit tests for SFTP functionality
│   │   ├── cli_tests.rs     # Unit tests for CLI parsing
│   │   └── integration_tests.rs # Integration tests
│   └── Cargo.toml           # Rust dependencies and project config
├── lua/
│   ├── astra.lua            # Main plugin module with Neovim integration
│   └── astra-example.lua    # Configuration example
├── CLAUDE.md                # This file
└── README.md               # Comprehensive documentation
```

## Build and Development Commands

### Rust Core
- Build the Rust binary: `cd astra-core && cargo build`
- Build with optimizations: `cd astra-core && cargo build --release`
- Run the Rust binary: `cd astra-core && cargo run`
- Check Rust code: `cd astra-core && cargo check`
- Lint Rust code: `cd astra-core && cargo clippy`
- Run tests: `cd astra-core && cargo test`
- Run specific test module: `cd astra-core && cargo test types_tests`
- Run integration tests: `cd astra-core && cargo test integration_tests`

### CLI Usage
- Initialize configuration: `cd astra-core && cargo run init`
- Sync files: `cd astra-core && cargo run sync --config astra.json --mode upload`
- Check status: `cd astra-core && cargo run status --config astra.json`
- Upload single file: `cd astra-core && cargo run upload --config astra.json --local file.txt --remote /path/file.txt`
- Download single file: `cd astra-core && cargo run download --config astra.json --remote /path/file.txt --local file.txt`

## Architecture Overview

This project follows a hybrid architecture for a Neovim plugin:

### 1. Rust Core (`astra-core/`)
**Purpose**: High-performance SFTP operations and file synchronization
**Key Components**:
- **SftpClient**: Main SFTP client with connection management, file operations, and incremental sync
- **Configuration Management**: Multi-format configuration support (TOML, VSCode SFTP, JSON) with automatic discovery and fallback
- **Error Handling**: Comprehensive error system with AstraError and AstraResult
- **CLI Interface**: Command-line interface with subcommands (init, sync, status, upload, download)
- **File Tracking**: Monitors local and remote files for changes using timestamps and checksums
- **Incremental Sync**: Only transfers modified files using multi-factor comparison

**Core Features**:
- SSH authentication (password and private key support)
- File upload/download operations
- Directory creation and file deletion
- Checksum calculation using SHA-256
- Timestamp-based change detection
- Bidirectional synchronization
- Multi-format configuration support (TOML, VSCode SFTP, JSON)
- Automatic configuration discovery with priority fallback

### 2. Lua Interface (`lua/`)
**Purpose**: Neovim integration and user interface
**Key Components**:
- **Plugin Setup**: Configuration management and initialization
- **Neovim Commands**: User commands (AstraInit, AstraSync, AstraStatus, AstraUpload, AstraDownload)
- **Auto-sync**: Real-time synchronization with timers and autocmds
- **Event Handling**: File save events and periodic sync

**Features**:
- Seamless Neovim integration
- Auto-sync on file save
- Periodic background synchronization
- Configuration validation and setup
- User notifications and error reporting

### 3. Communication Pattern
The Rust core and Lua frontend communicate through:
- **CLI Interface**: Lua calls Rust binary with command-line arguments
- **JSON Configuration**: Shared configuration file format
- **Process Execution**: Lua spawns Rust processes for operations
- **Status Reporting**: JSON-formatted results returned to Lua

## Key Data Structures

### SftpConfig
```rust
pub struct SftpConfig {
    pub host: String,
    pub port: u16,
    pub username: String,
    pub password: Option<String>,
    pub private_key_path: Option<String>,
    pub remote_path: String,
    pub local_path: String,
}
```

### FileStatus
```rust
pub struct FileStatus {
    pub path: PathBuf,
    pub size: u64,
    pub modified: DateTime<Utc>,
    pub is_directory: bool,
    pub checksum: Option<String>,
}
```

### SyncResult
```rust
pub struct SyncResult {
    pub success: bool,
    pub message: String,
    pub files_transferred: Vec<String>,
    pub files_skipped: Vec<String>,
    pub errors: Vec<String>,
}
```

## Synchronization Algorithm

The incremental sync process works as follows:

1. **File Discovery**: Scan local and remote directories
2. **Change Detection**: Compare files using:
   - Modification timestamps
   - File sizes
   - SHA-256 checksums
3. **Operation Generation**: Create sync operations for changed files
4. **Execution**: Perform upload/download operations
5. **Status Reporting**: Return detailed results

## Dependencies

### Rust Dependencies
- **tokio**: Async runtime and networking
- **ssh2**: SSH/SFTP protocol implementation
- **serde/serde_json**: JSON serialization
- **toml**: TOML configuration file parsing
- **clap**: Command-line argument parsing
- **chrono**: Date/time handling
- **walkdir**: Directory traversal
- **sha2**: Checksum calculation
- **tracing**: Logging and debugging
- **anyhow/thiserror**: Error handling

### Testing Dependencies
- **tempfile**: Temporary file management for tests
- **tokio-test**: Async testing utilities

## Configuration

The plugin supports multiple configuration file formats with automatic discovery:

### Priority Order
1. **TOML Configuration** (`.astro-settings/settings.toml`)
2. **VSCode SFTP Configuration** (`.vscode/sftp.json`)  
3. **Legacy Astra Configuration** (`astra.json`)

### TOML Configuration (.astro-settings/settings.toml)
```toml
[sftp]
host = "server.com"
port = 22
username = "user"
password = "password"  # optional
private_key_path = "/path/to/key"  # optional
remote_path = "/remote/directory"
local_path = "/local/directory"

[sync]
auto_sync = true
sync_on_save = true
sync_interval = 30000
```

### VSCode SFTP Configuration (.vscode/sftp.json)
```json
{
  "name": "My Server",
  "host": "server.com",
  "protocol": "sftp",
  "port": 22,
  "username": "user",
  "password": "password",
  "remotePath": "/remote/directory",
  "uploadOnSave": true
}
```

### Legacy Astra Configuration (astra.json)
```json
{
  "host": "server.com",
  "port": 22,
  "username": "user",
  "password": "password",
  "private_key_path": "/path/to/key",
  "remote_path": "/remote/directory",
  "local_path": "/local/directory"
}
```

## Development Guidelines

### Adding New Features
1. Update Rust core modules in `astra-core/src/`
2. Add corresponding tests in appropriate test modules
3. Update Lua frontend in `lua/astra.lua`
4. Update documentation in `README.md`
5. Update this CLAUDE.md file with architectural changes

### Code Standards
- Follow Rust best practices and idioms
- Use comprehensive error handling with AstraResult
- Add unit tests for new functionality
- Document public APIs
- Maintain backward compatibility where possible

### Testing Strategy
- Unit tests for individual modules
- Integration tests for end-to-end functionality
- Use tempfile for test isolation
- Mock network operations where appropriate
- Test both success and error cases

## Common Development Tasks

### Adding New SFTP Operations
1. Add operation type to `OperationType` enum in `types.rs`
2. Implement operation in `SftpClient` in `sftp.rs`
3. Add CLI command in `cli.rs`
4. Add Lua command wrapper in `astra.lua`
5. Write tests for the new operation

### Modifying Configuration
1. Update `SftpConfig` struct in `types.rs`
2. Update configuration validation in Lua frontend
3. Update documentation and examples
4. Add tests for new configuration options

### Performance Optimization
1. Profile existing operations with `cargo build --release`
2. Identify bottlenecks in file operations
3. Optimize algorithmic complexity
4. Add async operations where beneficial
5. Test performance improvements