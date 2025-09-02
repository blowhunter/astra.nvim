# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Documentation Guidelines

### 📝 Change Documentation Policy

**重要说明：所有后续的说明性文字、变更记录、问题解决方案等都应该写入 `CHANGELOG.md` 文件，而不是创建单独的文档文件。**

#### 何时更新 CHANGELOG.md：
- **功能变更**：新增、修改或删除功能时
- **问题修复**：修复bug或解决问题时
- **配置变更**：配置文件格式或选项变更时
- **架构调整**：代码结构或架构变更时
- **性能优化**：重要的性能改进时
- **文档更新**：重要文档更新时

#### CHANGELOG.md 内容结构：
- **版本号**：使用语义化版本号 (major.minor.patch)
- **新增功能**：🌍 标记新功能
- **技术改进**：🔧 标记技术变更
- **问题修复**：🐛 标记修复的问题
- **文件变更**：📦 标记文件变更
- **测试覆盖**：🧪 标记测试情况
- **使用示例**：📝 提供使用示例
- **统计信息**：📊 提供变更统计

#### 禁止创建的文件类型：
- ❌ 临时解决方案文档 (如 `SSH-AUTH-FIX.md`)
- ❌ 问题总结文档 (如 `SOLUTION-SUMMARY.md`)
- ❌ 功能说明文档 (如 `CONFIG_MANAGEMENT.md`)
- ❌ 故障排除文档 (如 `TROUBLESHOOTING.md`)
- ❌ 重复的说明性文档

#### 例外情况：
- ✅ **CLAUDE.md**：项目指导文档（更新此文件）
- ✅ **README.md**：项目主要说明文档
- ✅ **CONTRIBUTING.md**：贡献指南
- ✅ **特定功能文档**：如 `I18N_README.md`（复杂功能的详细说明）
- ✅ **配置示例**：如 `example-config.toml`
- ✅ **翻译文件**：如 `translations.json`

#### 文档维护原则：
1. **单一来源**：每个信息只在一个地方维护
2. **时效性**：及时更新变更日志
3. **简洁性**：避免重复和冗余信息
4. **可追溯性**：所有变更都有记录
5. **用户友好**：用户可以轻松找到需要的信息

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
1. **TOML Configuration** (`.astra-settings/settings.toml`)
2. **VSCode SFTP Configuration** (`.vscode/sftp.json`)  
3. **Legacy Astra Configuration** (`astra.json`)

### TOML Configuration (.astra-settings/settings.toml)
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
  "privateKeyPath": "/path/to/your/private_key_file",
  "remotePath": "/remote/directory",
  "uploadOnSave": true
}
```

**VSCode SFTP with private key authentication:**
```json
{
  "name": "YourServerProfileName",
  "host": "your_sftp_host_or_ip",
  "protocol": "sftp",
  "port": 22,
  "username": "your_sftp_username",
  "remotePath": "/path/to/your/remote/project",
  "privateKeyPath": "/path/to/your/private_key_file",
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
6. **Update CHANGELOG.md** with the new operation details

### Modifying Configuration
1. Update `SftpConfig` struct in `types.rs`
2. Update configuration validation in Lua frontend
3. Update documentation and examples
4. Add tests for new configuration options
5. **Update CHANGELOG.md** with configuration changes

### Performance Optimization
1. Profile existing operations with `cargo build --release`
2. Identify bottlenecks in file operations
3. Optimize algorithmic complexity
4. Add async operations where beneficial
5. Test performance improvements
6. **Update CHANGELOG.md** with performance improvements

### Documentation Updates
1. **ALWAYS update CHANGELOG.md** for any significant changes
2. Update CLAUDE.md for architectural changes or new development guidelines
3. Update README.md for user-facing changes
4. **DO NOT create separate documentation files** for solutions or fixes
5. Keep documentation concise and avoid redundancy

## 📋 Documentation Requirements Checklist

Before committing any changes, ensure you have:

- [ ] **Updated CHANGELOG.md** with all changes
- [ ] **Added appropriate tests** for new functionality
- [ ] **Updated relevant documentation** (README.md, CLAUDE.md)
- [ ] **Verified existing tests still pass**
- [ ] **Avoided creating redundant documentation files**
- [ ] **Followed the established documentation structure**

### 🚫 Prohibited Documentation Patterns
- Creating `*-FIX.md` files for problem solutions
- Creating `SOLUTION-*.md` files for issue summaries  
- Creating standalone documentation for temporary fixes
- Duplicating information across multiple files
- Creating documentation that will quickly become outdated

### ✅ Preferred Documentation Patterns
- Updating CHANGELOG.md with detailed change information
- Adding inline code comments for complex logic
- Updating existing documentation files with new information
- Creating comprehensive test cases that serve as documentation
- Using descriptive commit messages that reference the changelog