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
if ! command -v cargo &>/dev/null; then
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
