# Astra.nvim

一个强大的 Neovim 插件，用于基于 SFTP 的文件同步，支持增量同步功能。使用 Rust 构建以获得高性能，使用 Lua 实现 Neovim 集成。

## 特性

- **SFTP 集成**：通过 SSH 进行安全文件传输
- **增量同步**：仅同步修改过的文件以提高效率
- **实时监控**：文件更改或保存事件时自动同步
- **双向支持**：上传和下载文件
- **多格式配置**：支持 TOML、VSCode SFTP 和传统 JSON 格式
- **配置发现**：自动检测配置文件，具有优先级回退功能
- **VSCode 兼容性**：适用于现有的 VSCode SFTP 配置文件
- **Neovim 命令**：与 Neovim 命令无缝集成
- **性能优化**：Rust 核心提供高速操作

## 安装

### 前置要求

- Rust（最新稳定版本）
- Neovim（0.8+）
- 对远程服务器的 SSH 访问权限

### 设置

1. 构建 Rust 核心程序：
```bash
cd astra-core
cargo build --release
```

2. 将插件添加到您的 Neovim 配置中（使用您喜欢的插件管理器）：

**Lazy.nvim:**
```lua
{
    dir = "/path/to/astra.nvim",
    config = function()
        require("astra").setup({
            host = "your-server.com",
            username = "your-username",
            password = "your-password",  -- 或使用 private_key_path
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

## 配置

### 基本配置

```lua
require("astra").setup({
    host = "your-server.com",          -- 远程服务器主机名
    port = 22,                         -- SSH 端口
    username = "your-username",        -- SSH 用户名
    password = "your-password",        -- SSH 密码（可选）
    private_key_path = "/path/to/key", -- 私钥路径（可选）
    remote_path = "/remote/directory", -- 远程目录
    local_path = vim.loop.cwd(),       -- 本地目录
    auto_sync = false,                 -- 启用自动同步
    sync_on_save = true,               -- 文件保存时同步
    sync_interval = 30000,             -- 自动同步间隔（毫秒）
})
```

### 认证方式

**密码认证：**
```lua
require("astra").setup({
    host = "server.com",
    username = "user",
    password = "password",
    remote_path = "/remote/path",
})
```

**SSH 密钥认证：**
```lua
require("astra").setup({
    host = "server.com",
    username = "user",
    private_key_path = "/home/user/.ssh/id_rsa",
    remote_path = "/remote/path",
})
```

## 使用方法

### Neovim 命令

- `:AstraInit` - 初始化配置文件
- `:AstraSync [mode]` - 同步文件（upload/download/auto）
- `:AstraStatus` - 检查同步状态
- `:AstraUpload <local_path> <remote_path>` - 上传单个文件
- `:AstraDownload <remote_path> <local_path>` - 下载单个文件

### 使用示例

**初始化配置：**
```vim
:AstraInit
```

**手动同步：**
```vim
:AstraSync upload    -- 将本地更改上传到远程
:AstraSync download  -- 将远程更改下载到本地
:AstraSync auto      -- 双向同步
```

**检查状态：**
```vim
:AstraStatus
```

**上传单个文件：**
```vim
:AstraUpload /local/file.txt /remote/file.txt
```

**下载单个文件：**
```vim
:AstraDownload /remote/file.txt /local/file.txt
```

## 工作原理

### 架构

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Neovim Lua    │    │   Rust 核心     │    │  远程服务器     │
│   (前端)        │◄──►│   (astra-core)  │◄──►│   (SFTP)        │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

### 同步过程

1. **文件跟踪**：监控本地和远程文件时间戳和校验和
2. **更改检测**：识别自上次同步以来已修改的文件
3. **增量传输**：仅传输更改的文件
4. **冲突解决**：智能处理冲突的更改
5. **状态报告**：提供详细的同步结果

### 文件比较算法

插件使用多因素方法来确定文件更改：

1. **文件时间戳**：比较修改时间
2. **文件大小**：检测大小变化
3. **校验和验证**：SHA-256 哈希用于内容验证
4. **元数据比较**：文件权限和属性

## 开发

### 构建项目

```bash
# 构建 Rust 核心
cd astra-core
cargo build

# 运行测试
cargo test

# 使用优化构建
cargo build --release

# 运行代码检查
cargo clippy
```

### 测试

```bash
# 运行所有测试
cargo test

# 运行特定测试模块
cargo test types_tests

# 运行集成测试
cargo test integration_tests
```

### 项目结构

```
astra.nvim/
├── astra-core/              # Rust 核心实现
│   ├── src/
│   │   ├── main.rs          # 主入口点
│   │   ├── types.rs         # 数据结构
│   │   ├── error.rs         # 错误处理
│   │   ├── sftp.rs          # SFTP 操作
│   │   ├── cli.rs           # CLI 接口
│   │   ├── config.rs        # 配置管理
│   │   ├── types_tests.rs   # 类型测试
│   │   ├── sftp_tests.rs    # SFTP 测试
│   │   ├── cli_tests.rs     # CLI 测试
│   │   └── integration_tests.rs # 集成测试
│   └── Cargo.toml           # Rust 依赖项
├── lua/
│   ├── astra.lua            # 主插件模块
│   └── astra-example.lua    # 配置示例
└── README.md               # 本文件
```

## 配置文件格式

插件支持多种配置文件格式，按以下优先级顺序：

1. **TOML 配置**（`.astra-settings/settings.toml`）
2. **VSCode SFTP 配置**（`.vscode/sftp.json`）
3. **传统 Astra 配置**（`astra.json`）

### TOML 配置 (.astra-settings/settings.toml)

推荐用于新项目的格式：

```toml
[sftp]
host = "your-server.com"
port = 22
username = "your-username"
password = "your-password"  # 可选
private_key_path = "/path/to/private/key"  # 可选
remote_path = "/remote/directory"
local_path = "/local/directory"

[sync]
auto_sync = true
sync_on_save = true
sync_interval = 30000
```

### VSCode SFTP 配置 (.vscode/sftp.json)

与 VSCode SFTP 扩展兼容：

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

### 传统 Astra 配置 (astra.json)

原始格式：

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

### 配置发现

插件自动按以下顺序搜索配置文件：

1. **TOML 配置**：在当前目录或父目录中查找 `.astra-settings/settings.toml`
2. **VSCode SFTP 配置**：在当前目录或父目录中查找 `.vscode/sftp.json`
3. **传统 Astra 配置**：在当前目录中查找 `astra.json`

插件将自动检测并使用第一个可用的配置文件格式。这允许在格式之间无缝迁移并与现有 VSCode SFTP 设置兼容。

## 故障排除

### 常见问题

**连接失败：**
- 验证 SSH 凭据和服务器可访问性
- 检查防火墙设置
- 确保远程服务器上启用了 SFTP

**权限被拒绝：**
- 验证远程目录上的用户权限
- 检查 SSH 密钥权限（600）
- 确保密码正确

**同步问题：**
- 检查文件权限
- 验证磁盘空间
- 确保网络连接

### 调试模式

启用调试日志：

```bash
export RUST_LOG=debug
cargo run sync
```

## 性能考虑

### 优化技巧

1. **使用 SSH 密钥**：基于密钥的认证比密码更快
2. **增量同步**：仅同步更改的文件
3. **网络条件**：考虑带宽和延迟
4. **文件大小**：大文件可能需要特殊处理
5. **并发传输**：可以同时传输多个文件

### 资源使用

- **内存**：最小的内存占用
- **CPU**：空闲时 CPU 使用率低，传输时适中
- **网络**：高效使用协议并支持压缩

## 安全性

### 最佳实践

1. **SSH 密钥**：尽可能使用基于密钥的认证
2. **密码存储**：避免以明文形式存储密码
3. **网络安全**：使用加密连接
4. **文件权限**：设置适当的文件权限
5. **访问控制**：限制远程目录访问

### 安全特性

- **SSH 加密**：所有传输都通过 SSH 加密
- **认证**：多种认证方式
- **会话管理**：安全的会话处理
- **错误处理**：优雅的错误恢复

## 贡献

### 开发设置

1. Fork 仓库
2. 创建功能分支
3. 进行更改
4. 添加测试
5. 提交拉取请求

### 代码风格

- 遵循 Rust 编码标准
- 使用适当的错误处理
- 添加全面的测试
- 为代码添加文档

## 许可证

本项目基于 MIT 许可证。

## 支持

如有问题和疑问：
- 在 GitHub 上创建问题
- 查看故障排除部分
- 查看配置示例