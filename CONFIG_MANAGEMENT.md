# Astra.nvim 配置管理功能更新

## 概述

Astra.nvim 现在支持智能配置管理，当项目下没有任何配置文件时，插件会默认关闭所有同步选项和功能，只提供配置初始化能力。初始化完成后，插件会自动获取所有配置信息并根据配置项开启相应的功能。

## 新功能特性

### 1. 智能配置检测

- **自动配置发现**: 插件启动时自动检测配置文件存在性
- **多格式支持**: 支持 `.astra-settings/settings.toml`、`.vscode/sftp.json`、`astra.json` 格式
- **配置优先级**: TOML > VSCode SFTP > Legacy Astra
- **配置缓存**: 30秒缓存避免频繁检测

### 2. 无配置时的行为

- **默认关闭同步**: 没有配置文件时，所有同步功能默认关闭
- **友好提示**: 显示配置初始化提示信息
- **命令可用性**: 所有命令仍然可用，但会提示需要配置
- **优雅降级**: 插件功能优雅降级，不影响其他操作

### 3. 配置初始化

- **一键初始化**: `:AstraInit` 命令自动创建配置文件
- **自动重载**: 初始化完成后自动重新加载配置
- **功能启用**: 根据新配置自动启用相应功能
- **状态通知**: 实时反馈配置状态

### 4. 配置验证

- **存在性检查**: 检查配置文件是否存在
- **有效性验证**: 验证配置格式和内容
- **错误提示**: 提供详细的配置错误信息
- **恢复建议**: 提供配置修复建议

## 使用流程

### 首次使用

1. **安装插件**: 在 LazyVim 中配置 Astra.nvim
2. **启动 Neovim**: 插件自动加载，提示需要配置
3. **初始化配置**: 运行 `:AstraInit` 或按 `<leader>Ai`
4. **配置完成**: 插件自动加载配置并启用功能

### 日常使用

1. **正常启动**: 有配置时插件自动启用所有功能
2. **配置刷新**: 使用 `:AstraRefreshConfig` 或 `<leader>Ar` 刷新配置
3. **状态检查**: 使用 `:AstraStatus` 检查同步状态
4. **文件同步**: 正常使用同步功能

## 配置文件格式

### TOML 格式 (推荐)

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

### VSCode SFTP 格式

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

### Legacy Astra 格式

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

## 错误处理

### 无配置文件

```
[INFO] Astra: No configuration found. Use :AstraInit to create configuration
```

### 配置初始化失败

```
[ERROR] Astra: Failed to initialize configuration
```

### 同步功能无配置

```
[ERROR] Astra: No configuration found. Please run :AstraInit to create configuration
```

## 开发者信息

### 修改的文件

1. **lua/astra.lua**: 核心配置管理逻辑
2. **lazyvim-astra-config.lua**: 完整配置更新
3. **lazyvim-astra-simple.lua**: 简化配置更新

### 主要改进

1. **配置发现逻辑**: 优化配置文件检测和缓存
2. **错误处理**: 统一错误提示和处理流程
3. **初始化流程**: 改进配置初始化和重载机制
4. **用户体验**: 提供更友好的提示信息

### 测试覆盖

- ✅ 无配置文件时的行为
- ✅ 配置初始化功能
- ✅ 配置重载和缓存
- ✅ 错误处理和提示
- ✅ 同步功能启用/禁用

## 兼容性

- **向后兼容**: 现有配置文件继续有效
- **格式支持**: 支持所有现有配置格式
- **功能保留**: 所有现有功能保持不变
- **LazyVim**: 完全兼容 LazyVim 配置

## 总结

新的配置管理功能使 Astra.nvim 更加用户友好，特别是对于新用户：

1. **简化上手**: 首次使用时只需运行一个命令
2. **智能管理**: 自动检测和管理配置状态
3. **错误恢复**: 提供清晰的错误信息和恢复建议
4. **无缝体验**: 配置初始化后立即获得完整功能

这个改进使 Astra.nvim 成为一个更加成熟和易用的 Neovim SFTP 同步插件。