# LazyVim Astra.nvim 配置方案

本文件提供了针对优化后的 Astra.nvim 插件的 LazyVim 配置方案。现在插件支持自动配置发现和智能路径检测，大大提升了使用体验。

## 配置文件选项

### 1. 完整功能配置 (`lazyvim-astra-config.lua`)

**适用场景**: 需要完整功能的开发者，包含通知、构建管理、依赖检查等高级功能。

**特性**:
- ✅ 自动配置发现
- ✅ 智能路径检测
- ✅ Fidget 通知集成
- ✅ 自动构建和更新
- ✅ 依赖检查
- ✅ 完整的键位映射
- ✅ 保存时自动同步
- ✅ 定期同步
- ✅ 文件忽略模式
- ✅ 调试日志

**安装方式**:
```lua
-- 在 LazyVim 配置中 (通常在 lua/config/lazy.lua)
{
  "blowhunter/astra.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "j-hui/fidget.nvim",
  },
  lazy = false,
  priority = 100,
  config = function()
    -- 复制 lazyvim-astra-config.lua 的内容到这里
    -- 或者直接 require 文件
    dofile(vim.fn.expand("~/.config/nvim/lua/lazyvim-astra-config.lua"))
  end,
}
```

### 2. 简化配置 (`lazyvim-astra-simple.lua`)

**适用场景**: 追求简单配置的用户，只需要基础的文件同步功能。

**特性**:
- ✅ 自动配置发现
- ✅ 智能路径检测
- ✅ 基础键位映射
- ✅ 保存时自动同步
- ✅ 自动构建

**安装方式**:
```lua
-- 在 LazyVim 配置中
{
  "blowhunter/astra.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
  },
  lazy = false,
  priority = 100,
  config = function()
    -- 复制 lazyvim-astra-simple.lua 的内容到这里
    -- 或者直接 require 文件
    dofile(vim.fn.expand("~/.config/nvim/lua/lazyvim-astra-simple.lua"))
  end,
}
```

## 使用指南

### 1. 基础使用

**自动路径检测**: 现在插件会自动检测文件路径，无需手动指定：

```vim
:AstraUpload              -- 自动上传当前文件
:AstraUpload file.txt    -- 自动生成远程路径
:AstraDownload /remote/file.txt  -- 自动生成本地路径
```

**智能同步**:
```vim
:AstraSync auto            -- 同步整个项目
:AstraSyncCurrent         -- 同步当前文件（智能路径）
```

### 2. 键位映射

#### 完整配置的键位映射:
- `<leader>AS` / `<leader>As` - 同步项目
- `<leader>Au` - 上传当前文件
- `<leader>Ad` - 下载文件
- `<leader>Acs` - 智能同步当前文件
- `<leader>Aps` - 同步项目
- `<leader>Ab` - 构建核心
- `<leader>Ar` - 刷新配置
- `<leader>AU` - 更新插件
- `<leader>Av` - 显示版本信息
- `<leader>Auc` - 检查更新

#### 简化配置的键位映射:
- `<leader>au` - 上传当前文件
- `<leader>as` - 同步项目
- `<leader>aq` - 快速同步
- `<leader>ab` - 构建
- `<leader>ar` - 刷新配置
- `<leader>av` - 版本信息
- `<leader>aU` - 检查更新

### 3. 自动化功能

#### 保存时自动同步
配置后，每次保存文件时会自动同步到远程服务器（排除临时文件）。

#### 定期同步
启用后会定期同步整个项目（默认30秒间隔）。

#### 自动配置发现
插件会自动检测 `.astra-settings/settings.toml`、`.vscode/sftp.json` 或 `astra.json` 配置文件。

### 4. 管理命令

```vim
:AstraBuildCore        -- 重新构建核心程序
:AstraUpdate          -- 更新插件并重建
:AstraCheckDeps       -- 检查依赖项
:AstraStatusCheck     -- 检查状态
:AstraRefreshConfig   -- 刷新配置缓存
:AstraInit           -- 初始化配置文件
:AstraVersion        -- 显示版本信息
:AstraCheckUpdate    -- 检查更新
```

## 配置文件设置

### 推荐的 TOML 配置 (.astra-settings/settings.toml)

```toml
[sftp]
host = "your-server.com"
port = 22
username = "your-username"
# password = "your-password"  # 可选，密码认证
private_key_path = "~/.ssh/id_rsa"  # 支持 ~ 符号自动展开
remote_path = "/remote/project"
local_path = "~/local/project"  # 支持 ~ 符号自动展开

[sync]
auto_sync = true
sync_on_save = true
sync_interval = 30000
```

### VSCode SFTP 配置 (.vscode/sftp.json)

```json
{
  "name": "My Server",
  "host": "your-server.com",
  "protocol": "sftp",
  "port": 22,
  "username": "your-username",
  "password": "your-password",
  "remotePath": "/remote/project",
  "uploadOnSave": true
}
```

### 传统 JSON 配置 (astra.json)

```json
{
  "host": "your-server.com",
  "port": 22,
  "username": "your-username",
  "password": "your-password",
  "private_key_path": "~/.ssh/id_rsa",
  "remote_path": "/remote/project",
  "local_path": "~/local/project"
}
```

## 故障排除

### 1. 构建失败
```vim
:AstraBuildCore  -- 手动构建
:AstraCheckDeps  -- 检查依赖
```

### 2. 配置问题
```vim
:AstraRefreshConfig  -- 刷新配置缓存
:AstraStatusCheck     -- 检查状态
```

### 3. 路径问题
- 确保配置文件路径正确（支持 ~ 符号）
- 检查文件权限
- 验证 SSH 连接

### 4. 同步问题
- 检查网络连接
- 验证服务器配置
- 查看调试日志

## 性能优化

### 1. 忽略文件模式
```lua
ignore_patterns = {
  "*.tmp",
  "*.log",
  ".git/*",
  "*.swp",
  "*.bak",
  "node_modules/*",
  "target/*",  -- Rust
  "build/*",  -- 通用构建目录
}
```

### 2. 同步设置
```lua
sync = {
  sync_interval = 60000,  -- 增加到60秒
  debounce_time = 1000, -- 增加防抖时间
  batch_size = 20,      -- 增加批量处理
}
```

### 3. 构建优化
```lua
build = {
  release_build = true,
  parallel_jobs = 8,  -- 增加并行任务
}
```

## 高级用法

### 1. 多项目配置
不同项目可以有不同的 `.astra-settings/settings.toml` 文件，插件会自动检测。

### 2. 条件同步
```lua
-- 只在特定项目启用自动同步
if vim.fn.getcwd():match("project-name") then
  astra_config.sync.auto_sync = true
  astra_config.sync.sync_on_save = true
end
```

### 3. 自定义通知
```lua
-- 集成其他通知插件
vim.notify = function(msg, level, opts)
  -- 自定义通知逻辑
end
```

## 版本管理功能

### 1. 版本信息查看

Astra.nvim 现在支持版本信息查看：

```vim
:AstraVersion        -- 显示版本信息
<leader>Av          -- 键位映射显示版本
```

**显示信息包括**:
- 当前版本号
- 构建日期
- Rust 版本
- 当前时间

### 2. 更新检查

支持检查插件更新：

```vim
:AstraCheckUpdate    -- 检查更新
<leader>Auc          -- 键位映射检查更新
```

**更新检查功能**:
- 自动连接到远程仓库检查最新版本
- 显示当前版本和最新版本信息
- 提供更新建议和指导

### 3. CLI 版本命令

也可以直接通过命令行使用版本功能：

```bash
# 在 astra-core 目录中
./astra-core version          # 显示版本信息
./astra-core check-update     # 检查更新
```

## 升级说明

### 从旧版本升级
1. 删除硬编码的连接配置
2. 使用配置文件 instead of Lua 设置
3. 重新构建核心程序 `:AstraBuildCore`
4. 刷新配置 `:AstraRefreshConfig`

### 配置迁移
- 如果原来在 Lua 中配置了连接信息，请移动到配置文件中
- 新的自动配置发现会优先使用配置文件
- Lua 中的配置只作为备用

## 总结

优化后的 Astra.nvim 配置方案提供了：

1. **自动化**: 自动配置发现和路径检测
2. **智能化**: 智能路径映射和文件同步
3. **用户友好**: 简化的命令和键位映射
4. **高性能**: 缓存机制和批量处理
5. **可扩展**: 支持自定义和高级配置
6. **版本管理**: 版本信息查看和更新检查

选择适合你需求的配置方案，享受无缝的文件同步体验！