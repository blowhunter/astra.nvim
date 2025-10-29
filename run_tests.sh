#!/bin/bash

# Astra.nvim 测试运行脚本

echo "🚀 Astra.nvim Test Suite"
echo "========================================"

# 设置 Lua 路径
export LUA_PATH="./lua/?.lua;./lua/?/init.lua;./tests/?.lua"

# 运行测试
nvim --headless -c "
lua package.path = package.path .. ';./lua/?.lua;./lua/?/init.lua;./tests/?.lua'

-- 加载测试运行器
local Test = require('tests.test_runner')

-- 运行所有测试
local success = Test.run_all_tests()

-- 退出码
if success then
  vim.cmd('qall!')
else
  vim.cmd('cquit 1')
end
" -c "q" 2>&1 | grep -v "^\[" | grep -v "^$"

echo ""
echo "========================================"
echo "✨ 测试完成！"