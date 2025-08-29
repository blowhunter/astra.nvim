# CLAUDE.md

本文件为 Claude Code (claude.ai/code) 在此代码库中工作时提供指导。

## 项目概述

Astra.nvim 是一个全面的 Neovim 插件，用于基于 SFTP 的文件同步，支持增量同步功能。使用 Rust 构建以获得高性能，使用 Lua 实现 Neovim 集成。

## 项目结构

```
astra.nvim/
├── astra-core/              # Rust 核心实现
│   ├── src/
│   │   ├── main.rs          # 主入口点和 CLI
│   │   ├── types.rs         # 数据结构 (SftpConfig, FileStatus, SyncResult)
│   │   ├── error.rs         # 错误处理，使用 AstraError 和 AstraResult
│   │   ├── sftp.rs          # SFTP 操作和客户端实现
│   │   ├── cli.rs           # 带有子命令的 CLI 接口
│   │   ├── config.rs        # 多格式支持的配置管理
│   │   ├── types_tests.rs   # 数据结构的单元测试
│   │   ├── sftp_tests.rs    # SFTP 功能的单元测试
│   │   ├── cli_tests.rs     # CLI 解析的单元测试
│   │   └── integration_tests.rs # 集成测试
│   └── Cargo.toml           # Rust 依赖项和项目配置
├── lua/
│   ├── astra.lua            # 带有 Neovim 集成的主插件模块
│   └── astra-example.lua    # 配置示例
├── CLAUDE.md                # 本文件
└── README.md               # 综合文档
```

## 构建和开发命令

### Rust 核心
- 构建 Rust 二进制文件：`cd astra-core && cargo build`
- 使用优化构建：`cd astra-core && cargo build --release`
- 运行 Rust 二进制文件：`cd astra-core && cargo run`
- 检查 Rust 代码：`cd astra-core && cargo check`
- 检查 Rust 代码风格：`cd astra-core && cargo clippy`
- 运行测试：`cd astra-core && cargo test`
- 运行特定测试模块：`cd astra-core && cargo test types_tests`
- 运行集成测试：`cd astra-core && cargo test integration_tests`

### CLI 使用
- 初始化配置：`cd astra-core && cargo run init`
- 同步文件：`cd astra-core && cargo run sync --config astra.json --mode upload`
- 检查状态：`cd astra-core && cargo run status --config astra.json`
- 上传单个文件：`cd astra-core && cargo run upload --config astra.json --local file.txt --remote /path/file.txt`
- 下载单个文件：`cd astra-core && cargo run download --config astra.json --remote /path/file.txt --local file.txt`

## 架构概述

本项目为 Neovim 插件采用混合架构：

### 1. Rust 核心 (`astra-core/`)
**目的**：高性能 SFTP 操作和文件同步
**关键组件**：
- **SftpClient**：主 SFTP 客户端，具有连接管理、文件操作和增量同步功能
- **配置管理**：多格式配置支持（TOML、VSCode SFTP、JSON）和自动发现
- **错误处理**：使用 AstraError 和 AstraResult 的综合错误系统
- **CLI 接口**：带有子命令的命令行界面（init、sync、status、upload、download）
- **文件跟踪**：使用时间戳和校验和监控本地和远程文件的更改
- **增量同步**：仅使用多因素比较传输修改的文件

**核心功能**：
- SSH 认证（密码和私钥支持）
- 文件上传/下载操作
- 目录创建和文件删除
- 使用 SHA-256 的校验和计算
- 基于时间戳的更改检测
- 双向同步
- 多格式配置支持（TOML、VSCode SFTP、JSON）
- 具有优先级回退的自动配置发现

### 2. Lua 接口 (`lua/`)
**目的**：Neovim 集成和用户界面
**关键组件**：
- **插件设置**：配置管理和初始化
- **Neovim 命令**：用户命令（AstraInit、AstraSync、AstraStatus、AstraUpload、AstraDownload）
- **自动同步**：使用计时器和自动命令的实时同步
- **事件处理**：文件保存事件和定期同步

**功能**：
- 无缝的 Neovim 集成
- 文件保存时自动同步
- 定期后台同步
- 配置验证和设置
- 用户通知和错误报告

### 3. 通信模式
Rust 核心和 Lua 前端通过以下方式通信：
- **CLI 接口**：Lua 使用命令行参数调用 Rust 二进制文件
- **JSON 配置**：共享配置文件格式
- **进程执行**：Lua 为操作生成 Rust 进程
- **状态报告**：JSON 格式的结果返回给 Lua

## 关键数据结构

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

## 同步算法

增量同步过程如下：

1. **文件发现**：扫描本地和远程目录
2. **更改检测**：使用以下方式比较文件：
   - 修改时间戳
   - 文件大小
   - SHA-256 校验和
3. **操作生成**：为更改的文件创建同步操作
4. **执行**：执行上传/下载操作
5. **状态报告**：返回详细结果

## 依赖项

### Rust 依赖项
- **tokio**：异步运行时和网络
- **ssh2**：SSH/SFTP 协议实现
- **serde/serde_json**：JSON 序列化
- **toml**：TOML 配置文件解析
- **clap**：命令行参数解析
- **chrono**：日期/时间处理
- **walkdir**：目录遍历
- **sha2**：校验和计算
- **tracing**：日志和调试
- **anyhow/thiserror**：错误处理

### 测试依赖项
- **tempfile**：测试的临时文件管理
- **tokio-test**：异步测试工具

## 配置

插件支持多种配置文件格式，具有自动发现功能：

### 优先级顺序
1. **TOML 配置**（`.astra-settings/settings.toml`）
2. **VSCode SFTP 配置**（`.vscode/sftp.json`）  
3. **传统 Astra 配置**（`astra.json`）

### TOML 配置 (.astra-settings/settings.toml)
```toml
[sftp]
host = "server.com"
port = 22
username = "user"
password = "password"  # 可选
private_key_path = "/path/to/key"  # 可选
remote_path = "/remote/directory"
local_path = "/local/directory"

[sync]
auto_sync = true
sync_on_save = true
sync_interval = 30000
```

### VSCode SFTP 配置 (.vscode/sftp.json)
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

### 传统 Astra 配置 (astra.json)
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

## 开发指南

### 添加新功能
1. 在 `astra-core/src/` 中更新 Rust 核心模块
2. 在适当的测试模块中添加相应的测试
3. 在 `lua/astra.lua` 中更新 Lua 前端
4. 在 `README.md` 中更新文档
5. 在此 CLAUDE.md 文件中更新架构更改

### 代码标准
- 遵循 Rust 最佳实践和惯用方法
- 使用 AstraResult 进行全面的错误处理
- 为新功能添加单元测试
- 记录公共 API
- 尽可能保持向后兼容性

### 测试策略
- 单个模块的单元测试
- 端到端功能的集成测试
- 使用 tempfile 进行测试隔离
- 在适当的情况下模拟网络操作
- 测试成功和错误情况

## 常见开发任务

### 添加新的 SFTP 操作
1. 在 `types.rs` 中的 `OperationType` 枚举中添加操作类型
2. 在 `sftp.rs` 中的 `SftpClient` 中实现操作
3. 在 `cli.rs` 中添加 CLI 命令
4. 在 `astra.lua` 中添加 Lua 命令包装器
5. 为新操作编写测试

### 修改配置
1. 在 `types.rs` 中更新 `SftpConfig` 结构
2. 在 Lua 前端中更新配置验证
3. 更新文档和示例
4. 为新配置选项添加测试

### 性能优化
1. 使用 `cargo build --release` 分析现有操作
2. 识别文件操作中的瓶颈
3. 优化算法复杂性
4. 在有益的地方添加异步操作
5. 测试性能改进