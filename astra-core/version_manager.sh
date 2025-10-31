#!/bin/bash

# Astra-Core Version Management Script
# 用于管理版本号和生成版本信息

set -e

PROJECT_ROOT="/home/ethan/work/rust/astra.nvim/astra-core"
CARGO_TOML="$PROJECT_ROOT/Cargo.toml"
BUILD_RS="$PROJECT_ROOT/build.rs"
VERSION_RS="$PROJECT_ROOT/src/version.rs"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}======================================${NC}"
echo -e "${BLUE} Astra-Core Version Manager${NC}"
echo -e "${BLUE}======================================${NC}"
echo ""

# 显示帮助信息
show_help() {
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  info         Show current version information"
    echo "  build        Build project with version info"
    echo "  build-release Build release version"
    echo "  clean        Clean generated files"
    echo "  clean-build  Clean and rebuild"
    echo "  test-version Test version commands"
    echo "  help         Show this help message"
    echo ""
}

# 显示版本信息
show_version_info() {
    echo -e "${GREEN}Current Version Information:${NC}"
    echo ""

    if [ -f "$VERSION_RS" ]; then
        echo "Generated version file:"
        echo "==================="
        head -10 "$VERSION_RS"
        echo ""
    else
        echo -e "${YELLOW}Version file not generated. Run build first.${NC}"
    fi

    echo ""
    echo -e "${GREEN}Cargo.toml Information:${NC}"
    echo "======================"
    if [ -f "$CARGO_TOML" ]; then
        grep -A 5 '\[package\]' "$CARGO_TOML" | grep -E 'version|name|description'
    fi

    echo ""
    echo -e "${GREEN}Git Information:${NC}"
    echo "==============="
    if [ -d "$PROJECT_ROOT/.git" ]; then
        cd "$PROJECT_ROOT"
        echo "Latest commit:"
        git log --oneline -1 2>/dev/null || echo "No commits yet"
        echo ""
        echo "Working directory status:"
        git status --short 2>/dev/null | head -5 || echo "Clean working directory"
        echo ""
        echo "Branch:"
        git branch --show-current 2>/dev/null || echo "No branch"
    else
        echo "Not a git repository"
    fi
}

# 清理生成的文件
clean_version_files() {
    echo -e "${YELLOW}Cleaning generated version files...${NC}"

    if [ -f "$VERSION_RS" ]; then
        rm "$VERSION_RS"
        echo "  ✓ Removed $VERSION_RS"
    fi

    # Clean cargo build artifacts
    cd "$PROJECT_ROOT"
    cargo clean 2>/dev/null || echo "  ✓ Cargo clean completed"

    echo -e "${GREEN}Clean complete${NC}"
}

# 构建项目
build_project() {
    local release_mode="${1:-false}"

    echo -e "${GREEN}Building project with version info...${NC}"
    echo ""

    cd "$PROJECT_ROOT"

    if [ "$release_mode" = "true" ]; then
        echo "Building release version..."
        cargo build --release
    else
        echo "Building debug version..."
        cargo build
    fi

    if [ $? -eq 0 ]; then
        echo ""
        echo -e "${GREEN}Build complete!${NC}"
        echo ""

        # 运行版本信息
        if [ "$release_mode" = "true" ]; then
            if [ -f "target/release/astra-core" ]; then
                echo -e "${BLUE}Version Information:${NC}"
                echo "==================="
                echo ""
                echo "$ ./target/release/astra-core --version"
                ./target/release/astra-core --version
                echo ""
                echo "$ ./target/release/astra-core --build-info"
                ./target/release/astra-core --build-info
            fi
        else
            if [ -f "target/debug/astra-core" ]; then
                echo -e "${BLUE}Version Information:${NC}"
                echo "==================="
                echo ""
                echo "$ ./target/debug/astra-core --version"
                ./target/debug/astra-core --version
                echo ""
                echo "$ ./target/debug/astra-core --build-info"
                ./target/debug/astra-core --build-info
            fi
        fi
    else
        echo -e "${RED}Build failed!${NC}"
        return 1
    fi
}

# 清理并重新构建
clean_build() {
    echo -e "${YELLOW}Cleaning and rebuilding...${NC}"
    echo ""
    clean_version_files
    echo ""
    build_project
}

# 测试版本命令
test_version_commands() {
    echo -e "${GREEN}Testing version commands...${NC}"
    echo ""

    cd "$PROJECT_ROOT"

    # 检查二进制文件是否存在
    local binary="target/debug/astra-core"
    if [ ! -f "$binary" ]; then
        echo -e "${YELLOW}Binary not found, building first...${NC}"
        cargo build
    fi

    if [ -f "$binary" ]; then
        echo -e "${BLUE}Testing --version command:${NC}"
        echo "======================"
        "$binary" --version
        echo ""

        echo -e "${BLUE}Testing --build-info command:${NC}"
        echo "==========================="
        "$binary" --build-info
        echo ""

        echo -e "${BLUE}Testing version subcommand:${NC}"
        echo "==========================="
        "$binary" version
        echo ""

        echo -e "${GREEN}All version commands tested successfully!${NC}"
    else
        echo -e "${RED}Binary not found after build!${NC}"
        return 1
    fi
}

# 主逻辑
case "${1:-}" in
    info)
        show_version_info
        ;;
    clean)
        clean_version_files
        ;;
    build)
        build_project false
        ;;
    build-release)
        build_project true
        ;;
    clean-build)
        clean_build
        ;;
    test-version)
        test_version_commands
        ;;
    help|--help|-h)
        show_help
        ;;
    "")
        show_help
        ;;
    *)
        echo -e "${RED}Unknown command: $1${NC}"
        echo ""
        show_help
        exit 1
        ;;
esac