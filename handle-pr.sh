#!/bin/bash

# Astra.nvim PR 处理脚本
# 用于处理包含格式化修复的 PR

echo "🚀 Astra PR 处理工具"
echo "================================"
echo ""

# 检查参数
if [ $# -eq 0 ]; then
    echo "用法:"
    echo "  $0 <PR-branch-name>  # 从 PR 分支创建合并请求"
    echo "  $0 --apply-fix       # 应用格式化修复到当前分支"
    echo ""
    exit 1
fi

if [ "$1" == "--apply-fix" ]; then
    echo "📝 应用格式化修复..."
    echo ""

    # 创建 rustfmt.toml
    cat > astra-core/rustfmt.toml << 'EOF'
# Astra.core Rustfmt configuration
edition = "2021"

# 控制代码宽度
max_width = 100
tab_spaces = 4

# 格式化选项
fn_params_layout = "Compressed"
struct_lit_width = 0

# 导入语句
imports_granularity = "Module"
imports_layout = "Mixed"

# 宏格式化
match_arm_blocks = true
match_arm_leading_pipes = "Never"

# 空行和换行
empty_item_single_line = true
fn_single_line = false
where_single_line = false

# 注释
wrap_comments = true
comment_width = 100

# 其他选项
force_explicit_abi = true
use_try_shorthand = true
use_field_init_shorthand = true
merge_derives = true
EOF

    echo "✅ 已创建 rustfmt.toml"

    # 格式化代码
    echo ""
    echo "🔨 运行 cargo fmt..."
    cd astra-core && cargo fmt
    cd ..

    echo "✅ 格式化完成"

    # 验证
    echo ""
    echo "🔍 验证格式化..."
    if make format-check > /dev/null 2>&1; then
        echo "✅ 格式化检查通过！"
        echo ""
        echo "请运行:"
        echo "  git add ."
        echo "  git commit -m 'fix: 修复 Rust 代码格式化问题'"
        echo "  git push origin main"
    else
        echo "❌ 格式化检查失败"
        echo "请检查代码并重试"
        exit 1
    fi

elif [ -n "$1" ]; then
    PR_BRANCH="$1"
    echo "📋 处理 PR: $PR_BRANCH"
    echo ""

    # 检查分支是否存在
    if git show-ref --verify --quiet refs/remotes/origin/$PR_BRANCH; then
        echo "✅ 找到 PR 分支: origin/$PR_BRANCH"

        # 切换到分支
        git checkout $PR_BRANCH

        # 应用修复
        echo ""
        echo "🔨 应用格式化修复..."
        $0 --apply-fix

        # 提交更改
        git add .
        git commit -m "fix: 修复 Rust 代码格式化问题

解决 GitHub Actions check formatting 报错

🔧 问题修复:
- 添加 rustfmt.toml 配置文件
- 运行 cargo fmt 修复代码格式化
- 确保 CI/CD 流水线通过

🤖 Generated with Claude Code"

        # 推送到 PR 分支
        echo ""
        echo "📤 推送到 PR 分支..."
        git push origin $PR_BRANCH

        echo ""
        echo "✅ PR 已更新，请刷新 GitHub 页面查看更改"
        echo ""
        echo "下一步："
        echo "1. 在 GitHub 上查看 PR"
        echo "2. 确保 CI/CD 流水线通过"
        echo "3. 合并 PR"
    else
        echo "❌ 未找到 PR 分支: origin/$PR_BRANCH"
        echo ""
        echo "可用的分支："
        git branch -r | grep -E "origin/(main|develop|feature|fix|PR_)"
        exit 1
    fi
fi

echo ""
echo "✨ 处理完成！"