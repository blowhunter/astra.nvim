# Astra.nvim

A powerful Neovim plugin for SFTP-based file synchronization with incremental sync capabilities. Built with Rust for performance and Lua for Neovim integration.

## Features

- **SFTP Integration**: Secure file transfer over SSH
- **Incremental Sync**: Only sync modified files for efficiency
- **Real-time Monitoring**: Auto-sync on file changes or save events
- **Dual Direction Support**: Upload and download files
- **Multi-Format Configuration**: Support for TOML, VSCode SFTP, and legacy JSON formats
- **Configuration Discovery**: Automatic detection of configuration files with priority fallback
- **VSCode Compatibility**: Works with existing VSCode SFTP configuration files
- **Neovim Commands**: Seamless integration with Neovim commands
- **Performance Optimized**: Rust core for high-speed operations

## Installation

### Prerequisites

- Rust (latest stable version)
- Neovim (0.8+)
- SSH access to your remote server

### Setup

1. Build the Rust core:
```bash
cd astra-core
cargo build --release
```

2. Add the plugin to your Neovim configuration (using your favorite plugin manager):

**Lazy.nvim:**
```lua
{
    dir = "/path/to/astra.nvim",
    config = function()
        require("astra").setup({
            host = "your-server.com",
            username = "your-username",
            password = "your-password",  -- or use private_key_path
            remote_path = "/remote/directory",
            sync_on_save = true,
        })
    end
}
```

**Packer.nvim:**
```lua
use {
    "/path/to/astra.nvim",
    config = function()
        require("astra").setup({
            host = "your-server.com",
            username = "your-username",
            password = "your-password",
            remote_path = "/remote/directory",
            sync_on_save = true,
        })
    end
}
```

## Configuration

### Basic Configuration

```lua
require("astra").setup({
    host = "your-server.com",          -- Remote server hostname
    port = 22,                         -- SSH port
    username = "your-username",        -- SSH username
    password = "your-password",        -- SSH password (optional)
    private_key_path = "/path/to/key", -- Private key path (optional)
    remote_path = "/remote/directory", -- Remote directory
    local_path = vim.loop.cwd(),       -- Local directory
    auto_sync = false,                 -- Enable auto-sync
    sync_on_save = true,               -- Sync on file save
    sync_interval = 30000,             -- Auto-sync interval (ms)
})
```

### Authentication Methods

**Password Authentication:**
```lua
require("astra").setup({
    host = "server.com",
    username = "user",
    password = "password",
    remote_path = "/remote/path",
})
```

**SSH Key Authentication:**
```lua
require("astra").setup({
    host = "server.com",
    username = "user",
    private_key_path = "/home/user/.ssh/id_rsa",
    remote_path = "/remote/path",
})
```

## Usage

### Neovim Commands

- `:AstraInit` - Initialize configuration file
- `:AstraSync [mode]` - Synchronize files (upload/download/auto)
- `:AstraStatus` - Check sync status
- `:AstraUpload <local_path> <remote_path>` - Upload single file
- `:AstraDownload <remote_path> <local_path>` - Download single file

### Examples

**Initialize Configuration:**
```vim
:AstraInit
```

**Manual Sync:**
```vim
:AstraSync upload    -- Upload local changes to remote
:AstraSync download  -- Download remote changes to local
:AstraSync auto      -- Bidirectional sync
```

**Check Status:**
```vim
:AstraStatus
```

**Upload Single File:**
```vim
:AstraUpload /local/file.txt /remote/file.txt
```

**Download Single File:**
```vim
:AstraDownload /remote/file.txt /local/file.txt
```

## How It Works

### Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Neovim Lua    │    │   Rust Core     │    │  Remote Server  │
│   (Frontend)    │◄──►│   (astra-core)  │◄──►│   (SFTP)        │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

### Sync Process

1. **File Tracking**: Monitors local and remote file timestamps and checksums
2. **Change Detection**: Identifies modified files since last sync
3. **Incremental Transfer**: Only transfers changed files
4. **Conflict Resolution**: Handles conflicting changes intelligently
5. **Status Reporting**: Provides detailed sync results

### File Comparison Algorithm

The plugin uses a multi-factor approach to determine file changes:

1. **File Timestamps**: Compare modification times
2. **File Size**: Detect size changes
3. **Checksum Verification**: SHA-256 hash for content verification
4. **Metadata Comparison**: File permissions and attributes

## Development

### Building the Project

```bash
# Build the Rust core
cd astra-core
cargo build

# Run tests
cargo test

# Build with optimizations
cargo build --release

# Run linting
cargo clippy
```

### Testing

```bash
# Run all tests
cargo test

# Run specific test module
cargo test types_tests

# Run integration tests
cargo test integration_tests
```

### Project Structure

```
astra.nvim/
├── astra-core/              # Rust core implementation
│   ├── src/
│   │   ├── main.rs          # Main entry point
│   │   ├── types.rs         # Data structures
│   │   ├── error.rs         # Error handling
│   │   ├── sftp.rs          # SFTP operations
│   │   ├── cli.rs           # CLI interface
│   │   ├── config.rs        # Configuration management
│   │   ├── types_tests.rs   # Type tests
│   │   ├── sftp_tests.rs    # SFTP tests
│   │   ├── cli_tests.rs     # CLI tests
│   │   └── integration_tests.rs # Integration tests
│   └── Cargo.toml           # Rust dependencies
├── lua/
│   ├── astra.lua            # Main plugin module
│   └── astra-example.lua    # Configuration example
└── README.md               # This file
```

## Configuration File Format

The plugin supports multiple configuration file formats with the following priority order:

1. **TOML Configuration** (`.astro-settings/settings.toml`)
2. **VSCode SFTP Configuration** (`.vscode/sftp.json`)
3. **Legacy Astra Configuration** (`astra.json`)

### TOML Configuration (.astro-settings/settings.toml)

The recommended format for new projects:

```toml
[sftp]
host = "your-server.com"
port = 22
username = "your-username"
password = "your-password"  # optional
private_key_path = "/path/to/private/key"  # optional
remote_path = "/remote/directory"
local_path = "/local/directory"

[sync]
auto_sync = true
sync_on_save = true
sync_interval = 30000
```

### VSCode SFTP Configuration (.vscode/sftp.json)

Compatible with VSCode SFTP extension:

```json
{
  "name": "My Server",
  "host": "your-server.com",
  "protocol": "sftp",
  "port": 22,
  "username": "your-username",
  "password": "your-password",
  "remotePath": "/remote/directory",
  "uploadOnSave": true
}
```

### Legacy Astra Configuration (astra.json)

The original format:

```json
{
  "host": "your-server.com",
  "port": 22,
  "username": "your-username",
  "password": "your-password",
  "private_key_path": "/path/to/private/key",
  "remote_path": "/remote/directory",
  "local_path": "/local/directory"
}
```

### Configuration Discovery

The plugin automatically searches for configuration files in the following order:

1. **TOML Configuration**: Looks for `.astro-settings/settings.toml` in the current directory or parent directories
2. **VSCode SFTP Configuration**: Looks for `.vscode/sftp.json` in the current directory or parent directories
3. **Legacy Astra Configuration**: Looks for `astra.json` in the current directory

The plugin will automatically detect and use the first available configuration file format. This allows for seamless migration between formats and compatibility with existing VSCode SFTP setups.

## Troubleshooting

### Common Issues

**Connection Failed:**
- Verify SSH credentials and server accessibility
- Check firewall settings
- Ensure SFTP is enabled on the remote server

**Permission Denied:**
- Verify user permissions on remote directory
- Check SSH key permissions (600)
- Ensure password is correct

**Sync Issues:**
- Check file permissions
- Verify disk space
- Ensure network connectivity

### Debug Mode

Enable debug logging:

```bash
export RUST_LOG=debug
cargo run sync
```

## Performance Considerations

### Optimization Tips

1. **Use SSH Keys**: Key-based authentication is faster than password
2. **Incremental Sync**: Only sync changed files
3. **Network Conditions**: Consider bandwidth and latency
4. **File Size**: Large files may need special handling
5. **Concurrent Transfers**: Multiple files can be transferred simultaneously

### Resource Usage

- **Memory**: Minimal memory footprint
- **CPU**: Low CPU usage during idle, moderate during transfers
- **Network**: Efficient protocol usage with compression support

## Security

### Best Practices

1. **SSH Keys**: Use key-based authentication when possible
2. **Password Storage**: Avoid storing passwords in plain text
3. **Network Security**: Use encrypted connections
4. **File Permissions**: Set appropriate file permissions
5. **Access Control**: Limit remote directory access

### Security Features

- **SSH Encryption**: All transfers are encrypted via SSH
- **Authentication**: Multiple authentication methods
- **Session Management**: Secure session handling
- **Error Handling**: Graceful error recovery

## Contributing

### Development Setup

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Submit a pull request

### Code Style

- Follow Rust coding standards
- Use proper error handling
- Add comprehensive tests
- Document your code

## License

This project is licensed under the MIT License.

## Support

For issues and questions:
- Create an issue on GitHub
- Check the troubleshooting section
- Review the configuration examples