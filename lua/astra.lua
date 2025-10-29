-- Astra.lua - 主入口文件
-- 整合所有核心模块，提供统一的接口

local M = {}

-- 核心模块
local Core = require("astra.core")

-- 默认公共配置
M.default_public_config = {
  host = "",
  port = 22,
  username = "",
  password = nil,
  private_key_path = "~/.ssh/id_rsa",
  remote_path = "",
  local_path = vim.fn.getcwd(),
  auto_sync = false,
  sync_on_save = true,
  sync_interval = 30000,
  exclude_patterns = {".git/", "*.tmp", "*.log", ".DS_Store"},
  include_patterns = {},
  max_file_size = 10 * 1024 * 1024, -- 10MB
  static_build = false,
  debug_mode = false,
  notification_enabled = true,
  auto_save_config = false
}

-- 内部状态
M._initialized = false
M._public_config = nil

-- 主要设置函数
function M.setup(opts)
  opts = opts or {}

  -- 合并公共配置
  M._public_config = vim.tbl_deep_extend("force", M.default_public_config, opts)

  -- 初始化核心模块
  Core.initialize()

  M._initialized = true

  -- 显示初始化结果
  local state = Core.get_state()
  if state then
    if state.functionality_level == "full" then
      vim.notify("✅ Astra: Full functionality enabled", vim.log.levels.INFO)
    elseif state.functionality_level == "basic" then
      vim.notify("⚠️  Astra: Basic mode - please run :AstraInit", vim.log.levels.WARN)
    else
      vim.notify("⚠️  Astra: No configuration found", vim.log.levels.WARN)
    end
  end

  return M
end

-- 检查状态
function M.check()
  local state = Core.get_state()
  if state then
    print(string.format("Binary: %s, Config: %s, Level: %s",
      state.binary_available and "✅" or "❌",
      state.config_available and "✅" or "❌",
      state.functionality_level))
  end
  return state and state.functionality_level ~= "none"
end

-- 重新初始化
function M.reinitialize()
  Core.reinitialize()
  return M
end

-- 获取状态
function M.get_status()
  local state = Core.get_state()
  if not state then
    return {
      initialized = false,
      functionality_level = "none",
      message = "Core not initialized"
    }
  end

  return {
    initialized = state.initialized,
    functionality_level = state.functionality_level,
    message = "Astra is " .. (state.functionality_level == "full" and "ready" or "in setup")
  }
end

-- 获取配置
function M.get_config()
  local Config = require("astra.core.config")
  local config_status = Config.validate_project_config()

  if config_status.available then
    return config_status.config
  end

  return nil
end

-- 更新配置
function M.update_config()
  local Config = require("astra.core.config")
  Core.reinitialize()
  return true
end

-- 检查是否可用
function M.is_available()
  local state = Core.get_state()
  return state and state.functionality_level == "full"
end

return M