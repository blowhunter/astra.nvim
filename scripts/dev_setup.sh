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

  if ! command -v rustc &>/dev/null; then
    log_error "Rust 未安装，请先安装 Rust"
    log_info "安装命令: curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh"
    exit 1
  fi

  if ! command -v cargo &>/dev/null; then
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

  local config_dir="$ASTRA_ROOT_DIR/.astro-settings"
  mkdir -p "$config_dir"

  cat >"$config_dir/settings.toml" <<'CONFIG_EOF'
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
  log_info "1. 编辑配置文件: $ASTRA_ROOT_DIR/.astro-settings/settings.toml"
  log_info "2. 在 LazyVim 中配置插件路径"
  log_info "3. 启动 Neovim 并测试功能"
}

# 执行主函数
main "$@"
