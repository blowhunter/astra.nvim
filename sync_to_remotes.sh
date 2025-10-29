#!/bin/bash

# Astra.nvim 同步脚本
# 同步代码到所有远程仓库 (Gitee 和 GitHub)

echo "🔄 Astra.nvim 同步工具"
echo "=================================="
echo ""

# 检查当前分支
CURRENT_BRANCH=$(git branch --show-current)
echo "📍 当前分支: $CURRENT_BRANCH"
echo ""

# 检查是否有未提交的更改
if [ -n "$(git status --porcelain)" ]; then
    echo "⚠️  检测到未提交的更改："
    git status --short
    echo ""
    read -p "是否要提交这些更改？ (y/n): " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "📝 请输入提交信息:"
        read -r COMMIT_MSG
        git add .
        git commit -m "$COMMIT_MSG"
    else
        echo "❌ 取消同步"
        exit 1
    fi
fi

echo "🚀 开始同步到所有远程仓库..."
echo ""

# 推送到 Gitee (origin)
echo "📡 推送到 Gitee (origin)..."
if git push origin $CURRENT_BRANCH; then
    echo "✅ Gitee 同步成功"
else
    echo "❌ Gitee 同步失败"
fi
echo ""

# 推送到 GitHub
echo "📡 推送到 GitHub..."
if git push github $CURRENT_BRANCH; then
    echo "✅ GitHub 同步成功"
else
    echo "❌ GitHub 同步失败"
fi
echo ""

echo "=================================="
echo "✨ 同步完成！"