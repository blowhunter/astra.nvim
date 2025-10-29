-- 测试精简后的 Astra.nvim 功能
print("🔧 测试精简后的 Astra.nvim 功能")

-- 设置路径
package.path = package.path .. ';./lua/?.lua;./lua/?/init.lua'

-- 测试核心模块加载
print("\n📋 测试核心模块加载:")

local core_ok, Core = pcall(require, "astra.core")
if core_ok then
  print("  ✅ Core 模块加载成功")

  -- 测试状态初始化
  local state = Core.initialize()
  print("  📊 功能级别: " .. (state.functionality_level or "unknown"))
  print("  📊 初始化状态: " .. (state.initialized and "true" or "false"))
  print("  📊 二进制可用: " .. (state.binary_available and "true" or "false"))
  print("  📊 配置可用: " .. (state.config_available and "true" or "false"))
else
  print("  ❌ Core 模块加载失败: " .. tostring(Core))
end

-- 测试新架构入口
print("\n📋 测试新架构入口:")
local init_ok, Init = pcall(require, "astra.init_new")
if init_ok then
  print("  ✅ Init 模块加载成功")

  -- 测试 get_status 方法
  local status = Init.get_status()
  print("  📊 状态级别: " .. (status.functionality_level or "unknown"))
  print("  📊 初始化状态: " .. (status.initialized and "true" or "false"))
else
  print("  ❌ Init 模块加载失败: " .. tostring(Init))
end

-- 测试 Sync 模块
print("\n📋 测试 Sync 模块:")
local sync_ok, Sync = pcall(require, "astra.core.sync")
if sync_ok then
  print("  ✅ Sync 模块加载成功")

  -- 检查可用的函数
  local functions = {"upload", "download", "sync", "status", "version"}
  for _, func in ipairs(functions) do
    if Sync[func] and type(Sync[func]) == "function" then
      print("  ✅ " .. func .. "() 函数可用")
    else
      print("  ❌ " .. func .. "() 函数不可用")
    end
  end
else
  print("  ❌ Sync 模块加载失败: " .. tostring(Sync))
end

print("\n🔍 测试完成")