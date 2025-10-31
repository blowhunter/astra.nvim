-- Astra.nvim 核心测试用例
-- 覆盖8个核心使用场景和需求

local M = {}

-- 测试辅助函数
local function test_result(test_name, success, message)
  local status = success and "✅" or "❌"
  print(string.format("%s %s: %s", status, test_name, message or ""))
  return success
end

-- 测试1: 不存在配置文件时手工初始化默认配置
function M.test_config_initialization()
  print("\n🧪 测试1: 配置文件初始化")

  local ok, Config = pcall(require, "astra.core.config")
  if not ok then
    return test_result("配置模块加载", false, "无法加载配置模块")
  end

  -- 测试初始化配置
  local success, result = pcall(Config.init_project_config)
  if success then
    return test_result("配置初始化", true, "成功初始化项目配置")
  else
    return test_result("配置初始化", false, "初始化失败: " .. tostring(result))
  end
end

-- 测试2: 二进制文件不存在时的构建能力
function M.test_binary_build()
  print("\n🧪 测试2: 二进制文件构建")

  local ok, Binary = pcall(require, "astra.core.binary")
  if not ok then
    return test_result("二进制模块加载", false, "无法加载二进制模块")
  end

  -- 检查二进制状态
  local status = Binary.validate()
  if not status.available then
    -- 尝试构建
    local success, result = pcall(Binary.build)
    if success then
      return test_result("二进制构建", true, "成功构建二进制文件")
    else
      return test_result("二进制构建", false, "构建失败: " .. tostring(result))
    end
  else
    return test_result("二进制状态", true, "二进制文件已存在")
  end
end

-- 测试3: 单个文件上传
function M.test_single_file_upload()
  print("\n🧪 测试3: 单个文件上传")

  local ok, Sync = pcall(require, "astra.core.sync")
  if not ok then
    return test_result("同步模块加载", false, "无法加载同步模块")
  end

  -- 测试当前文件上传
  local success, result = pcall(Sync.upload_current_file)
  if success then
    return test_result("单文件上传", true, "成功上传当前文件")
  else
    return test_result("单文件上传", false, "上传失败: " .. tostring(result))
  end
end

-- 测试4: 单个文件下载
function M.test_single_file_download()
  print("\n🧪 测试4: 单个文件下载")

  local ok, Sync = pcall(require, "astra.core.sync")
  if not ok then
    return test_result("同步模块加载", false, "无法加载同步模块")
  end

  -- 测试当前文件下载
  local success, result = pcall(Sync.download_current_file)
  if success then
    return test_result("单文件下载", true, "成功下载当前文件")
  else
    return test_result("单文件下载", false, "下载失败: " .. tostring(result))
  end
end

-- 测试5: 目录文件上传
function M.test_directory_upload()
  print("\n🧪 测试5: 目录文件上传")

  local ok, Sync = pcall(require, "astra.core.sync")
  if not ok then
    return test_result("同步模块加载", false, "无法加载同步模块")
  end

  -- 测试目录上传
  local success, result = pcall(Sync.upload_directory)
  if success then
    return test_result("目录上传", true, "成功上传目录文件")
  else
    return test_result("目录上传", false, "上传失败: " .. tostring(result))
  end
end

-- 测试6: 目录文件下载
function M.test_directory_download()
  print("\n🧪 测试6: 目录文件下载")

  local ok, Sync = pcall(require, "astra.core.sync")
  if not ok then
    return test_result("同步模块加载", false, "无法加载同步模块")
  end

  -- 测试目录下载
  local success, result = pcall(Sync.download_directory)
  if success then
    return test_result("目录下载", true, "成功下载目录文件")
  else
    return test_result("目录下载", false, "下载失败: " .. tostring(result))
  end
end

-- 测试7: 整个项目的上传下载
function M.test_project_sync()
  print("\n🧪 测试7: 项目同步")

  local ok, Sync = pcall(require, "astra.core.sync")
  if not ok then
    return test_result("同步模块加载", false, "无法加载同步模块")
  end

  -- 测试项目同步
  local success, result = pcall(Sync.sync_project)
  if success then
    return test_result("项目同步", true, "成功同步整个项目")
  else
    return test_result("项目同步", false, "同步失败: " .. tostring(result))
  end
end

-- 测试8: 增量同步能力
function M.test_incremental_sync()
  print("\n🧪 测试8: 增量同步")

  local ok, Sync = pcall(require, "astra.core.sync")
  if not ok then
    return test_result("同步模块加载", false, "无法加载同步模块")
  end

  -- 测试增量同步
  local success, result = pcall(Sync.incremental_sync)
  if success then
    return test_result("增量同步", true, "成功执行增量同步")
  else
    return test_result("增量同步", false, "同步失败: " .. tostring(result))
  end
end

-- 测试9: 当前配置信息查看
function M.test_config_info()
  print("\n🧪 测试9: 配置信息查看")

  local ok, Config = pcall(require, "astra.core.config")
  if not ok then
    return test_result("配置模块加载", false, "无法加载配置模块")
  end

  -- 测试获取配置信息
  local config_status = Config.validate_project_config()
  if config_status.available then
    return test_result("配置查看", true, "成功获取配置信息")
  else
    return test_result("配置查看", false, "无可用配置")
  end
end

-- 测试10: 版本信息查看
function M.test_version_info()
  print("\n🧪 测试10: 版本信息查看")

  local ok, Binary = pcall(require, "astra.core.binary")
  if not ok then
    return test_result("二进制模块加载", false, "无法加载二进制模块")
  end

  -- 测试版本信息
  local status = Binary.validate()
  if status.available and status.version then
    return test_result("版本查看", true, "版本: " .. status.version)
  else
    return test_result("版本查看", false, "无法获取版本信息")
  end
end

-- 运行所有测试
function M.run_all_tests()
  print("🚀 开始运行 Astra.nvim 核心功能测试")
  print("=" .. string.rep("=", 50))

  local tests = {
    "test_config_initialization",
    "test_binary_build",
    "test_single_file_upload",
    "test_single_file_download",
    "test_directory_upload",
    "test_directory_download",
    "test_project_sync",
    "test_incremental_sync",
    "test_config_info",
    "test_version_info"
  }

  local passed = 0
  local total = #tests

  for _, test_name in ipairs(tests) do
    local success = M[test_name]()
    if success then passed = passed + 1 end
  end

  print("\n" .. string.rep("=", 50))
  print(string.format("📊 测试完成: %d/%d 通过", passed, total))

  if passed == total then
    print("🎉 所有测试通过！")
  else
    print("⚠️  部分测试失败，请检查相关功能")
  end

  return passed == total
end

-- 快速测试核心功能
function M.quick_test()
  print("⚡ Astra.nvim 快速功能检查")

  -- 检查核心模块
  local core_modules = {"astra.core.config", "astra.core.binary", "astra.core.sync"}
  local modules_ok = 0

  for _, module in ipairs(core_modules) do
    local ok, _ = pcall(require, module)
    if ok then modules_ok = modules_ok + 1 end
  end

  print(string.format("📦 核心模块: %d/%d 可用", modules_ok, #core_modules))

  -- 检查二进制状态
  local ok, Binary = pcall(require, "astra.core.binary")
  if ok then
    local status = Binary.validate()
    print(string.format("🔧 二进制文件: %s", status.available and "✅ 可用" or "❌ 不可用"))
    if status.available then
      print(string.format("📊 版本: %s", status.version or "未知"))
    end
  end

  -- 检查配置状态
  local ok, Config = pcall(require, "astra.core.config")
  if ok then
    local config_status = Config.validate_project_config()
    print(string.format("⚙️  配置文件: %s", config_status.available and "✅ 可用" or "❌ 不可用"))
  end
end

-- 导出到全局变量，以便插件配置可以访问
_G.TestCoreFunctionality = M

return M