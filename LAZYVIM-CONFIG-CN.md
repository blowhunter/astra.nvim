# Astra.nvim LazyVim 配置指南

本指南详细介绍如何在 LazyVim 中配置 astra.nvim 插件，包括自动构建 Rust 核心程序的完整方案。

## 前置要求

在开始配置之前，请确保您的系统满足以下要求：

### 系统要求
- **Neovim**: 0.8+ 版本
- **Rust**: 最新稳定版本
- **Cargo**: Rust 包管理器
- **Git**: 用于克隆和管理项目

### 安装 Rust
如果尚未安装 Rust，请运行以下命令：

```bash
# 官方安装脚本
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# 重新加载环境变量
source $HOME/.cargo/env

# 验证安装
rustc --version
cargo --version
```

## LazyVim 配置方案

### 方案一：基础配置（推荐）

在您的 LazyVim 配置文件中（通常是 `~/.config/nvim/lua/plugins/astra.lua`）添加以下内容：

```lua
-- ~/.config/nvim/lua/plugins/astra.lua
return {
  dir = "~/path/to/astra.nvim",  -- 修改为您的 astra.nvim 路径
  dependencies = {
    "nvim-lua/plenary.nvim",    -- 可选：用于更好的异步支持
  },
  config = function()
    -- 自动构建 Rust 核心程序
    local astra_core_path = vim.fn.expand("~/path/to/astra.nvim/astra-core")
    local build_script = vim.fn.expand("~/path/to/astra.nvim/scripts/build_core.sh")
    
    -- 检查并构建核心程序
    local function ensure_astra_core()
      local core_binary = astra_core_path .. "/target/release/astra-core"
      if vim.fn.filereadable(core_binary) == 0 then
        vim.notify("正在构建 Astra.nvim 核心程序...", "info", { title = "Astra.nvim" })
        
        -- 创建构建脚本
        local script_content = [[
#!/bin/bash
set -e

echo "🔨 正在构建 Astra.nvim 核心程序..."
cd "]] .. astra_core_path .. [["
cargo build --release

if [ $? -eq 0 ]; then
    echo "✅ 构建完成！"
    echo "📍 核心程序位置: $(pwd)/target/release/astra-core"
else
    echo "❌ 构建失败！"
    exit 1
fi
]]
        
        -- 写入并执行构建脚本
        vim.fn.mkdir(vim.fn.fnamemodify(build_script, ":h"), "p")
        local file = io.open(build_script, "w")
        if file then
          file:write(script_content)
          file:close()
          vim.fn.system("chmod +x " .. build_script)
          
          -- 执行构建
          local result = vim.fn.system(build_script)
          if vim.v.shell_error == 0 then
            vim.notify("Astra.nvim 核心程序构建成功！", "info", { title = "Astra.nvim" })
          else
            vim.notify("构建失败: " .. result, "error", { title = "Astra.nvim" })
          end
        end
      end
    end
    
    -- 延迟构建以避免影响启动速度
    vim.defer_fn(ensure_astra_core, 1000)
    
    -- 设置 astra.nvim
    require("astra").setup({
      -- 基本连接配置
      host = "your-server.com",
      port = 22,
      username = "your-username",
      
      -- 认证方式（二选一）
      password = "your-password",  -- 密码认证
      -- private_key_path = "/home/user/.ssh/id_rsa",  -- SSH 密钥认证
      
      -- 路径配置
      remote_path = "/remote/directory",
      local_path = vim.fn.getcwd(),
      
      -- 同步设置
      auto_sync = true,              -- 启用自动同步
      sync_on_save = true,          -- 保存时自动同步
      sync_interval = 30000,        -- 自动同步间隔（毫秒）
      
      -- 高级设置
      ignore_files = {              -- 忽略的文件模式
        "*.tmp",
        "*.log",
        ".git/*",
        "node_modules/*",
        "*.swp",
        "*.bak"
      },
      
      -- 通知设置
      notifications = {
        enabled = true,
        sync_start = true,
        sync_complete = true,
        sync_error = true,
      },
      
      -- 调试设置
      debug = false,                -- 启用调试模式
      verbose = false,              -- 详细输出
    })
    
    -- 创建用户命令
    vim.api.nvim_create_user_command("AstraBuildCore", function()
      require("astra.utils").build_core()
    end, { desc = "重新构建 Astra.nvim 核心程序" })
    
    vim.api.nvim_create_user_command("AstraUpdate", function()
      require("astra.utils").update_plugin()
    end, { desc = "更新 Astra.nvim 插件并重建核心" })
    
    -- 自动命令
    vim.api.nvim_create_autocmd("BufWritePost", {
      pattern = "*.lua",
      callback = function()
        -- 可以在这里添加文件保存后的自动同步逻辑
      end,
      desc = "文件保存后触发同步",
    })
  end,
  keys = {
    -- 键位映射
    { "<leader>as", "<cmd>AstraSync auto<cr>", desc = "Astra 同步" },
    { "<leader>au", "<cmd>AstraUpload<cr>", desc = "Astra 上传" },
    { "<leader>ad", "<cmd>AstraDownload<cr>", desc = "Astra 下载" },
    { "<leader>ab", "<cmd>AstraBuildCore<cr>", desc = "Astra 构建核心" },
    { "<leader>ai", "<cmd>AstraInit<cr>", desc = "Astra 初始化配置" },
    { "<leader>ac", "<cmd>AstraStatus<cr>", desc = "Astra 检查状态" },
  },
  cmd = {
    "AstraInit",
    "AstraSync", 
    "AstraStatus",
    "AstraUpload",
    "AstraDownload",
    "AstraBuildCore",
    "AstraUpdate",
  },
}
```

### 方案二：高级配置（包含自动更新和错误处理）

```lua
-- ~/.config/nvim/lua/plugins/astra.lua
return {
  dir = "~/path/to/astra.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "j-hui/fidget.nvim",  -- 用于更好的状态通知
  },
  config = function()
    local fidget = require("fidget")
    
    -- Astra.nvim 配置模块
    local astra_config = {
      -- 项目路径配置
      project_root = vim.fn.expand("~/path/to/astra.nvim"),
      core_path = vim.fn.expand("~/path/to/astra.nvim/astra-core"),
      binary_path = vim.fn.expand("~/path/to/astra.nvim/astra-core/target/release/astra-core"),
      
      -- 构建配置
      build = {
        auto_build = true,           -- 启动时自动构建
        build_on_update = true,      -- 更新后自动构建
        release_build = true,       -- 使用 release 模式构建
        parallel_jobs = 4,           -- 并行构建任务数
        features = {},               -- 额外的 cargo features
      },
      
      -- 连接配置
      connection = {
        host = "your-server.com",
        port = 22,
        username = "your-username",
        password = "your-password",
        -- private_key_path = "/home/user/.ssh/id_rsa",
        remote_path = "/remote/directory",
        local_path = vim.fn.getcwd(),
        timeout = 30000,            -- 连接超时（毫秒）
      },
      
      -- 同步配置
      sync = {
        auto_sync = true,
        sync_on_save = true,
        sync_interval = 30000,
        debounce_time = 500,        -- 防抖时间（毫秒）
        batch_size = 10,            -- 批量处理文件数
        ignore_patterns = {
          "*.tmp",
          "*.log",
          ".git/*",
          "*.swp",
          "*.bak",
          "node_modules/*",
          ".DS_Store",
          "__pycache__/*",
        },
      },
      
      -- 通知配置
      notifications = {
        enabled = true,
        level = "info",              -- 通知级别
        timeout = 3000,              -- 通知显示时间
        progress = true,             -- 显示进度
      },
      
      -- 调试配置
      debug = {
        enabled = false,
        log_file = vim.fn.expand("~/.astra_debug.log"),
        log_level = "info",
        verbose_commands = false,
      },
    }
    
    -- 工具函数模块
    local astra_utils = {}
    
    -- 检查依赖项
    function astra_utils.check_dependencies()
      local deps = { "cargo", "rustc", "git" }
      local missing = {}
      
      for _, dep in ipairs(deps) do
        if vim.fn.executable(dep) == 0 then
          table.insert(missing, dep)
        end
      end
      
      if #missing > 0 then
        error("缺少依赖项: " .. table.concat(missing, ", "))
        return false
      end
      
      return true
    end
    
    -- 构建核心程序
    function astra_utils.build_core()
      if not astra_utils.check_dependencies() then
        return false
      end
      
      local config = astra_config.build
      local cmd = string.format("cd %s && cargo build", astra_config.core_path)
      
      if config.release_build then
        cmd = cmd .. " --release"
      end
      
      if config.parallel_jobs > 1 then
        cmd = cmd .. string.format(" -j %d", config.parallel_jobs)
      end
      
      if #config.features > 0 then
        cmd = cmd .. " --features " .. table.concat(config.features, ",")
      end
      
      -- 显示构建进度
      fidget.notify("🔨 正在构建 Astra.nvim 核心程序...", nil, {
        title = "Astra.nvim",
        key = "astra_build",
      })
      
      -- 异步执行构建
      vim.fn.jobstart(cmd, {
        stdout_buffered = true,
        stderr_buffered = true,
        on_stdout = function(_, data)
          if data and #data > 0 then
            for _, line in ipairs(data) do
              if line:match("Compiling") or line:match("Finished") then
                fidget.notify(line, nil, { title = "Astra.nvim", key = "astra_build" })
              end
            end
          end
        end,
        on_stderr = function(_, data)
          if data and #data > 0 then
            for _, line in ipairs(data) do
              if line:match("error:") or line:match("warning:") then
                fidget.notify(line, vim.log.levels.ERROR, { title = "Astra.nvim", key = "astra_build" })
              end
            end
          end
        end,
        on_exit = function(_, exit_code)
          if exit_code == 0 then
            fidget.notify("✅ 构建完成！", nil, { title = "Astra.nvim", key = "astra_build" })
            vim.notify("Astra.nvim 核心程序构建成功！", "info", { title = "Astra.nvim" })
          else
            fidget.notify("❌ 构建失败！", vim.log.levels.ERROR, { title = "Astra.nvim", key = "astra_build" })
            vim.notify("构建失败，请检查错误信息", "error", { title = "Astra.nvim" })
          end
        end,
      })
    end
    
    -- 检查核心程序是否存在
    function astra_utils.check_core()
      return vim.fn.filereadable(astra_config.binary_path) == 1
    end
    
    -- 更新插件
    function astra_utils.update_plugin()
      fidget.notify("🔄 正在更新 Astra.nvim...", nil, { title = "Astra.nvim", key = "astra_update" })
      
      vim.fn.jobstart(string.format("cd %s && git pull origin main", astra_config.project_root), {
        on_exit = function(_, exit_code)
          if exit_code == 0 then
            fidget.notify("✅ 更新完成！", nil, { title = "Astra.nvim", key = "astra_update" })
            if astra_config.build.build_on_update then
              vim.schedule(function()
                astra_utils.build_core()
              end)
            end
          else
            fidget.notify("❌ 更新失败！", vim.log.levels.ERROR, { title = "Astra.nvim", key = "astra_update" })
          end
        end,
      })
    end
    
    -- 初始化插件
    function astra_utils.init()
      -- 检查核心程序
      if not astra_utils.check_core() then
        if astra_config.build.auto_build then
          vim.schedule(function()
            astra_utils.build_core()
          end)
        else
          vim.notify("Astra.nvim 核心程序不存在，请运行 :AstraBuildCore", "warn", { title = "Astra.nvim" })
        end
      end
      
      -- 设置 astra.nvim
      require("astra").setup(astra_config.connection)
      
      -- 注册工具函数
      package.loaded['astra.utils'] = astra_utils
    end
    
    -- 启动初始化
    vim.schedule(astra_utils.init)
    
    -- 创建用户命令
    vim.api.nvim_create_user_command("AstraBuildCore", astra_utils.build_core, { 
      desc = "重新构建 Astra.nvim 核心程序" 
    })
    
    vim.api.nvim_create_user_command("AstraUpdate", astra_utils.update_plugin, { 
      desc = "更新 Astra.nvim 插件并重建核心" 
    })
    
    vim.api.nvim_create_user_command("AstraCheckDeps", astra_utils.check_dependencies, { 
      desc = "检查 Astra.nvim 依赖项" 
    })
    
    -- 键位映射
    local keys = {
      { "<leader>as", "<cmd>AstraSync auto<cr>", desc = "Astra 同步", mode = "n" },
      { "<leader>au", "<cmd>AstraUpload<cr>", desc = "Astra 上传", mode = "n" },
      { "<leader>ad", "<cmd>AstraDownload<cr>", desc = "Astra 下载", mode = "n" },
      { "<leader>ab", "<cmd>AstraBuildCore<cr>", desc = "Astra 构建核心", mode = "n" },
      { "<leader>ai", "<cmd>AstraInit<cr>", desc = "Astra 初始化配置", mode = "n" },
      { "<leader>ac", "<cmd>AstraStatus<cr>", desc = "Astra 检查状态", mode = "n" },
      { "<leader>au", "<cmd>AstraUpdate<cr>", desc = "Astra 更新插件", mode = "n" },
      { "<leader>ad", "<cmd>AstraCheckDeps<cr>", desc = "Astra 检查依赖", mode = "n" },
    }
    
    for _, key in ipairs(keys) do
      vim.keymap.set(key.mode or "n", key[1], key[2], { desc = key.desc })
    end
  end,
}
```

## 自动构建脚本

创建一个自动构建脚本来处理核心程序的构建：

### 创建构建脚本

```bash
# 创建脚本目录
mkdir -p ~/path/to/astra.nvim/scripts

# 创建构建脚本
cat > ~/path/to/astra.nvim/scripts/build_core.sh << 'EOF'
#!/bin/bash
set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ASTRA_CORE_DIR="$SCRIPT_DIR/../astra-core"

# 检查目录是否存在
if [ ! -d "$ASTRA_CORE_DIR" ]; then
    log_error "astra-core 目录不存在: $ASTRA_CORE_DIR"
    exit 1
fi

# 检查 cargo 是否可用
if ! command -v cargo &> /dev/null; then
    log_error "cargo 命令未找到，请确保已安装 Rust"
    exit 1
fi

# 进入 astra-core 目录
cd "$ASTRA_CORE_DIR"

log_info "开始构建 Astra.nvim 核心程序..."
log_info "构建目录: $(pwd)"

# 清理之前的构建（可选）
if [ "$1" = "--clean" ]; then
    log_info "清理之前的构建..."
    cargo clean
fi

# 构建项目
log_info "正在编译..."
if cargo build --release; then
    log_success "构建完成！"
    log_success "核心程序位置: $(pwd)/target/release/astra-core"
    
    # 检查构建结果
    if [ -f "target/release/astra-core" ]; then
        log_info "构建文件大小: $(du -h target/release/astra-core | cut -f1)"
        log_info "构建文件权限: $(ls -la target/release/astra-core | awk '{print $1}')"
    fi
else
    log_error "构建失败！"
    exit 1
fi

# 可选：运行测试
if [ "$2" = "--test" ]; then
    log_info "运行测试..."
    if cargo test --release; then
        log_success "所有测试通过！"
    else
        log_warning "部分测试失败"
    fi
fi

log_success "Astra.nvim 核心程序构建完成！"
EOF

# 设置脚本权限
chmod +x ~/path/to/astra.nvim/scripts/build_core.sh
```

### 创建开发脚本

```bash
# 创建开发辅助脚本
cat > ~/path/to/astra.nvim/scripts/dev_setup.sh << 'EOF'
#!/bin/bash
set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ASTRA_ROOT_DIR="$SCRIPT_DIR/.."

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查 Rust 环境
check_rust_env() {
    log_info "检查 Rust 环境..."
    
    if ! command -v rustc &> /dev/null; then
        log_error "Rust 未安装，请先安装 Rust"
        log_info "安装命令: curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh"
        exit 1
    fi
    
    if ! command -v cargo &> /dev/null; then
        log_error "Cargo 未找到，请检查 Rust 安装"
        exit 1
    fi
    
    log_success "Rust 环境检查通过"
    log_info "Rust 版本: $(rustc --version)"
    log_info "Cargo 版本: $(cargo --version)"
}

# 安装依赖
install_dependencies() {
    log_info "检查并安装依赖..."
    
    cd "$ASTRA_ROOT_DIR/astra-core"
    
    # 检查并安装 Cargo 扩展
    local extensions=("cargo-nextest" "cargo-watch" "cargo-tree")
    
    for ext in "${extensions[@]}"; do
        if ! cargo install --list | grep -q "$ext"; then
            log_info "安装 $ext..."
            cargo install "$ext"
        fi
    done
    
    log_success "依赖安装完成"
}

# 初始构建
initial_build() {
    log_info "执行初始构建..."
    
    cd "$ASTRA_ROOT_DIR/astra-core"
    
    # 构建调试版本
    log_info "构建调试版本..."
    cargo build
    
    # 构建发布版本
    log_info "构建发布版本..."
    cargo build --release
    
    log_success "初始构建完成"
}

# 运行测试
run_tests() {
    log_info "运行测试套件..."
    
    cd "$ASTRA_ROOT_DIR/astra-core"
    
    # 运行单元测试
    log_info "运行单元测试..."
    cargo test
    
    # 运行集成测试
    log_info "运行集成测试..."
    cargo test --test integration_tests
    
    log_success "所有测试完成"
}

# 创建示例配置
create_example_config() {
    log_info "创建示例配置..."
    
    local config_dir="$ASTRA_ROOT_DIR/.astra-settings"
    mkdir -p "$config_dir"
    
    cat > "$config_dir/settings.toml" << 'CONFIG_EOF'
[sftp]
host = "example.com"
port = 22
username = "your-username"
password = "your-password"
# private_key_path = "/home/user/.ssh/id_rsa"
remote_path = "/remote/path"
local_path = "/local/path"

[sync]
auto_sync = true
sync_on_save = true
sync_interval = 30000
CONFIG_EOF
    
    log_success "示例配置已创建: $config_dir/settings.toml"
}

# 主函数
main() {
    log_info "开始 Astra.nvim 开发环境设置..."
    log_info "项目根目录: $ASTRA_ROOT_DIR"
    
    check_rust_env
    install_dependencies
    initial_build
    run_tests
    create_example_config
    
    log_success "Astra.nvim 开发环境设置完成！"
    log_info "下一步："
    log_info "1. 编辑配置文件: $ASTRA_ROOT_DIR/.astra-settings/settings.toml"
    log_info "2. 在 LazyVim 中配置插件路径"
    log_info "3. 启动 Neovim 并测试功能"
}

# 执行主函数
main "$@"
EOF

# 设置脚本权限
chmod +x ~/path/to/astra.nvim/scripts/dev_setup.sh
```

## 使用说明

### 1. 首次设置

```bash
# 运行开发环境设置脚本
~/path/to/astra.nvim/scripts/dev_setup.sh

# 或者手动构建
~/path/to/astra.nvim/scripts/build_core.sh
```

### 2. LazyVim 配置

将上述配置方案之一添加到您的 LazyVim 配置中，确保修改路径为您实际的 astra.nvim 路径。

### 3. 启动和使用

```bash
# 启动 Neovim
nvim

# 在 Neovim 中使用以下命令
:AstraInit        # 初始化配置
:AstraBuildCore   # 构建核心程序
:AstraSync auto   # 开始同步
:AstraStatus      # 检查状态
```

### 4. 键位映射

配置中已包含以下键位映射：

- `<leader>as` - 同步文件
- `<leader>au` - 上传文件
- `<leader>ad` - 下载文件
- `<leader>ab` - 构建核心程序
- `<leader>ai` - 初始化配置
- `<leader>ac` - 检查状态

## 故障排除

### 常见问题

**1. 构建失败**
```bash
# 检查 Rust 版本
rustc --version

# 清理并重新构建
cd ~/path/to/astra.nvim/astra-core
cargo clean
cargo build --release
```

**2. 路径问题**
确保配置文件中的路径正确：
- 项目路径：`~/path/to/astra.nvim`
- 核心路径：`~/path/to/astra.nvim/astra-core`
- 二进制路径：`~/path/to/astra.nvim/astra-core/target/release/astra-core`

**3. 权限问题**
```bash
# 设置脚本权限
chmod +x ~/path/to/astra.nvim/scripts/*.sh

# 设置二进制文件权限
chmod +x ~/path/to/astra.nvim/astra-core/target/release/astra-core
```

**4. 依赖问题**
```bash
# 更新 Rust
rustup update

# 安装缺失的依赖
cargo install cargo-watch
```

### 调试模式

启用调试模式来获取详细信息：

```lua
require("astra").setup({
  -- ... 其他配置
  debug = true,
  verbose = true,
})
```

### 日志查看

```bash
# 查看构建日志
tail -f ~/.astra_debug.log

# 查看 Neovim 日志
:messages
```

## 性能优化

### 1. 构建优化

```lua
build = {
  parallel_jobs = 4,           -- 根据CPU核心数调整
  release_build = true,       -- 使用发布版本
  incremental = false,        -- 禁用增量构建以获得更好的性能
}
```

### 2. 同步优化

```lua
sync = {
  debounce_time = 500,        -- 防抖时间
  batch_size = 10,            -- 批量处理
  ignore_patterns = {          -- 忽略大文件和临时文件
    "*.tmp",
    "*.log",
    "node_modules/*",
    ".git/*",
  },
}
```

### 3. 网络优化

```lua
connection = {
  timeout = 30000,            -- 增加超时时间
  retry_count = 3,            -- 重试次数
  retry_delay = 1000,         -- 重试延迟
}
```

## 最佳实践

### 1. 项目结构
```
your-project/
├── .astra-settings/
│   └── settings.toml         # TOML 配置
├── .vscode/
│   └── sftp.json            # VSCode SFTP 配置（可选）
├── astra.json               # 传统配置（可选）
└── ... (您的项目文件)
```

### 2. 配置管理
- 使用 TOML 格式作为主要配置
- 在团队项目中使用 `.vscode/sftp.json` 以便 VSCode 用户兼容
- 保留 `astra.json` 用于向后兼容

### 3. 安全考虑
- 不要在配置文件中存储敏感信息
- 使用 SSH 密钥认证而不是密码
- 设置适当的文件权限
- 使用 `.gitignore` 排除敏感配置

### 4. 开发工作流
```bash
# 1. 更新代码
git pull origin main

# 2. 重新构建
~/path/to/astra.nvim/scripts/build_core.sh

# 3. 运行测试
cd ~/path/to/astra.nvim/astra-core && cargo test

# 4. 启动 Neovim 测试
nvim
```

## 总结

本指南提供了完整的 LazyVim 配置方案，包括：

1. **自动构建功能**：启动时自动检查和构建 Rust 核心程序
2. **错误处理**：完善的错误处理和用户友好的通知
3. **键位映射**：便捷的键位映射以提高工作效率
4. **调试支持**：详细的调试信息和日志记录
5. **性能优化**：针对构建和同步的性能优化建议
6. **故障排除**：常见问题的解决方案和调试方法

通过本指南，您可以在 LazyVim 中轻松配置和使用 astra.nvim 插件，享受高效的 SFTP 文件同步体验。