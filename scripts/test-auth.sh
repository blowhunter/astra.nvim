#!/bin/bash

# Astra.nvim 认证测试脚本
# 用于诊断 SSH 认证问题

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

log_info "开始 Astra.nvim 认证测试..."
log_info "astra-core 目录: $ASTRA_CORE_DIR"

# 检查 astra-core 二进制文件
if [ ! -f "$ASTRA_CORE_DIR/target/debug/astra-core" ]; then
    log_error "astra-core 二进制文件不存在"
    log_info "请先构建: cd $ASTRA_CORE_DIR && cargo build"
    exit 1
fi

# 检查配置文件
PROJECT_ROOT="$SCRIPT_DIR/.."
CONFIG_FILES=(".astra-settings/settings.toml" ".vscode/sftp.json" "astra.json")
CONFIG_FOUND=""

for config_file in "${CONFIG_FILES[@]}"; do
    if [ -f "$PROJECT_ROOT/$config_file" ]; then
        CONFIG_FOUND="$PROJECT_ROOT/$config_file"
        break
    fi
done

if [ -z "$CONFIG_FOUND" ]; then
    log_error "未找到配置文件"
    log_info "请创建以下任一配置文件："
    for config_file in "${CONFIG_FILES[@]}"; do
        echo "  - $PROJECT_ROOT/$config_file"
    done
    exit 1
fi

log_info "找到配置文件: $CONFIG_FOUND"

# 测试配置加载
log_info "测试配置文件加载..."
cd "$PROJECT_ROOT"
if timeout 10s "$ASTRA_CORE_DIR/target/debug/astra-core" config-test >/dev/null 2>&1; then
    log_success "配置文件加载成功"
else
    log_error "配置文件加载失败"
    log_info "请检查配置文件格式"
    exit 1
fi

# 从配置文件中提取连接信息
if [[ "$CONFIG_FOUND" == *".toml" ]]; then
    # 解析 TOML 配置
    HOST=$(grep -oP 'host = "\K[^"]+' "$CONFIG_FOUND" | head -1)
    PORT=$(grep -oP 'port = \K\d+' "$CONFIG_FOUND" | head -1)
    USERNAME=$(grep -oP 'username = "\K[^"]+' "$CONFIG_FOUND" | head -1)
    PASSWORD=$(grep -oP 'password = "\K[^"]+' "$CONFIG_FOUND" | head -1)
    PRIVATE_KEY=$(grep -oP 'private_key_path = "\K[^"]+' "$CONFIG_FOUND" | head -1)
else
    # 解析 JSON 配置
    HOST=$(grep -oP '"host":\s*"\K[^"]+' "$CONFIG_FOUND" | head -1)
    PORT=$(grep -oP '"port":\s*\K\d+' "$CONFIG_FOUND" | head -1)
    USERNAME=$(grep -oP '"username":\s*"\K[^"]+' "$CONFIG_FOUND" | head -1)
    PASSWORD=$(grep -oP '"password":\s*"\K[^"]+' "$CONFIG_FOUND" | head -1)
    PRIVATE_KEY=$(grep -oP '"private_key_path":\s*"\K[^"]+' "$CONFIG_FOUND" | head -1)
fi

log_info "连接信息:"
log_info "  主机: $HOST"
log_info "  端口: ${PORT:-22}"
log_info "  用户名: $USERNAME"

# 测试网络连接
log_info "测试网络连接..."
if timeout 5s nc -z "$HOST" "${PORT:-22}" >/dev/null 2>&1; then
    log_success "网络连接正常"
else
    log_error "无法连接到 $HOST:${PORT:-22}"
    log_info "请检查："
    log_info "  1. 服务器地址是否正确"
    log_info "  2. SSH 服务是否运行"
    log_info "  3. 防火墙设置"
    log_info "  4. 网络连接"
    exit 1
fi

# 测试 SSH 连接
log_info "测试 SSH 连接..."

if [ -n "$PRIVATE_KEY" ] && [ -f "$PRIVATE_KEY" ]; then
    log_info "使用 SSH 密钥认证测试..."
    if timeout 10s ssh -o StrictHostKeyChecking=no -o BatchMode=yes -i "$PRIVATE_KEY" "$USERNAME@$HOST" -p "${PORT:-22}" echo "SSH连接测试成功" 2>/dev/null; then
        log_success "SSH 密钥认证测试成功"
    else
        log_error "SSH 密钥认证失败"
        log_info "检查："
        log_info "  1. 私钥文件权限 (应该是 600): $(ls -la "$PRIVATE_KEY" 2>/dev/null || echo '文件不存在')"
        log_info "  2. 公钥是否添加到服务器"
        log_info "  3. SSH 服务器是否允许密钥认证"
        log_info ""
        log_info "测试命令: ssh -v -i \"$PRIVATE_KEY\" \"$USERNAME@$HOST\" -p ${PORT:-22}"
    fi
elif [ -n "$PASSWORD" ]; then
    log_info "使用密码认证测试..."
    if timeout 10s ssh -o StrictHostKeyChecking=no "$USERNAME@$HOST" -p "${PORT:-22}" echo "SSH连接测试成功" 2>/dev/null; then
        log_success "SSH 密码认证测试成功"
    else
        log_error "SSH 密码认证失败"
        log_info "检查："
        log_info "  1. 用户名和密码是否正确"
        log_info "  2. 用户账户是否被锁定"
        log_info "  3. SSH 服务器是否允许密码认证"
        log_info "  4. 查看服务器日志: sudo journalctl -u sshd -n 20"
        log_info ""
        log_info "手动测试命令: ssh \"$USERNAME@$HOST\" -p ${PORT:-22}"
    fi
else
    log_warning "未配置认证信息（密码或私钥路径）"
    log_info "请在配置文件中添加认证信息"
    exit 1
fi

# 测试 astra-core 状态
log_info "测试 astra-core 状态..."
cd "$PROJECT_ROOT"
if timeout 15s "$ASTRA_CORE_DIR/target/debug/astra-core" status >/dev/null 2>&1; then
    log_success "astra-core 状态测试成功"
else
    log_error "astra-core 状态测试失败"
    log_info "请查看详细错误信息："
    log_info "  cd $PROJECT_ROOT"
    log_info "  $ASTRA_CORE_DIR/target/debug/astra-core status"
    log_info ""
    log_info "或启用调试模式："
    log_info "  export RUST_LOG=debug"
    log_info "  $ASTRA_CORE_DIR/target/debug/astra-core status"
fi

log_success "认证测试完成！"
log_info ""
log_info "下一步建议："
log_info "1. 如果 SSH 连接成功但 astra-core 失败，检查配置文件"
log_info "2. 查看 TROUBLESHOOTING.md 获取详细解决方案"
log_info "3. 启用调试模式获取更多信息"
log_info "4. 检查系统日志: sudo journalctl -u sshd -f"