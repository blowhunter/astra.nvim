-- Astra.nvim 主入口文件 - 新三层架构版本
-- 负责插件的初始化和功能调度

local M = {}

-- 引入核心模块
local Core = require("astra.core")

-- 默认公共配置
M.default_public_config = {
  -- 基础连接配置（可被项目配置覆盖）
  host = "",
  port = 22,
  username = "",
  password = nil,
  private_key_path = "~/.ssh/id_rsa",
  remote_path = "",
  local_path = vim.fn.getcwd(),

  -- 功能开关（公共配置默认值）
  auto_sync = false,
  sync_on_save = true,
  sync_interval = 30000,

  -- 过滤配置
  exclude_patterns = {".git/", "*.tmp", "*.log", ".DS_Store"},
  include_patterns = {},
  max_file_size = 10 * 1024 * 1024, -- 10MB

  -- 开发选项
  static_build = false,
  debug_mode = false,

  -- UI 选项
  notification_enabled = true,
  auto_save_config = false
}

-- 内部状态
M._initialized = false
M._public_config = nil
M._core_state = nil

-- 主要设置函数
function M.setup(opts)
  opts = opts or {}

  -- 合并公共配置
  M._public_config = vim.tbl_deep_extend("force", M.default_public_config, opts)

  -- 检查系统环境
  M._check_system_requirements()

  -- 初始化核心模块
  M._core_state = Core.initialize()

  -- 根据核心状态决定功能加载
  M._load_functionality_based_on_state()

  -- 设置自动保存
  if M._public_config.auto_save_config then
    M._setup_auto_save()
  end

  M._initialized = true

  -- 显示初始化结果
  M._show_initialization_result()

  return M
end

-- 检查系统要求
function M._check_system_requirements()
  -- 检查必要的模块
  local required_modules = {"vim.loop", "vim.fn", "vim.api"}
  for _, module in ipairs(required_modules) do
    if not vim[module:match("^[^.]+")] then
      vim.notify("❌ Astra: Missing required Neovim module: " .. module, vim.log.levels.ERROR)
      return false
    end
  end

  -- 检查操作系统
  local os_name = vim.loop.os_uname().sysname
  local supported_os = {"Linux", "Darwin", "Windows_NT"}
  local os_supported = false

  for _, supported in ipairs(supported_os) do
    if os_name == supported then
      os_supported = true
      break
    end
  end

  if not os_supported then
    vim.notify("⚠️  Astra: Unsupported operating system: " .. os_name, vim.log.levels.WARN)
  end

  return true
end

-- 根据核心状态加载功能
function M._load_functionality_based_on_state()
  local level = M._core_state.functionality_level

  if level == "none" then
    -- 完全未初始化状态，应该不会发生
    vim.notify("❌ Astra: Core initialization failed", vim.log.levels.ERROR)
    return
  end

  if level == "basic" then
    -- 基础功能：构建和配置
    vim.notify("🔧 Astra: Basic functionality available", vim.log.levels.INFO)
    if not M._core_state.binary_available then
      vim.notify("💡 Run :AstraBuild to compile the core binary", vim.log.levels.INFO)
    elseif not M._core_state.config_available then
      vim.notify("💡 Run :AstraInit to create project configuration", vim.log.levels.INFO)
    end
  elseif level == "full" then
    -- 完整功能：所有 SFTP 操作
    vim.notify("🚀 Astra: Full functionality available", vim.log.levels.INFO)

    -- 加载项目配置
    local Config = require("astra.core.config")
    local config_status = Config.validate_project_config()
    if config_status.available then
      local merged_config = Config.merge_config(M._public_config, config_status.config)
      M._apply_merged_config(merged_config)
    end

    -- 设置文件保存自动同步
    if M._public_config.sync_on_save then
      M._setup_sync_on_save()
    end
  end
end

-- 应用合并后的配置
function M._apply_merged_config(merged_config)
  -- 这里可以应用配置到各个模块
  -- 比如设置同步间隔、排除模式等
  local Sync = require("astra.core.sync")
  if Sync and Sync.set_config then
    Sync.set_config(merged_config)
  end
end

-- 设置同步保存
function M._setup_sync_on_save()
  vim.api.nvim_create_autocmd("BufWritePost", {
    callback = function(args)
      -- 检查是否在项目目录中
      local Config = require("astra.core.config")
      local config_status = Config.validate_project_config()

      if config_status.available then
        local Sync = require("astra.core.sync")
        if Sync and M._should_auto_sync_file(args.file) then
          vim.defer_fn(function()
            Sync.sync()
          end, 100) -- 延迟100ms执行，避免文件保存冲突
        end
      end
    end,
    desc = "Astra: Auto sync on save"
  })
end

-- 检查文件是否应该自动同步
function M._should_auto_sync_file(file_path)
  local config = M._public_config

  -- 检查排除模式
  for _, pattern in ipairs(config.exclude_patterns) do
    if file_path:match(pattern) then
      return false
    end
  end

  -- 检查包含模式
  if #config.include_patterns > 0 then
    local should_include = false
    for _, pattern in ipairs(config.include_patterns) do
      if file_path:match(pattern) then
        should_include = true
        break
      end
    end
    if not should_include then
      return false
    end
  end

  -- 检查文件大小
  local file_size = vim.fn.getfsize(file_path)
  if file_size > config.max_file_size and config.max_file_size > 0 then
    return false
  end

  return true
end

-- 设置自动保存配置
function M._setup_auto_save()
  vim.api.nvim_create_autocmd("VimLeavePre", {
    callback = function()
      if M._public_config and M._core_state and M._core_state.config_available then
        -- 这里可以实现配置的自动保存
        -- 比如保存用户的临时设置等
      end
    end,
    desc = "Astra: Auto save configuration on exit"
  })
end

-- 显示初始化结果
function M._show_initialization_result()
  local UI = require("astra.core.ui")

  if M._public_config.notification_enabled then
    -- 显示状态信息
    vim.defer_fn(function()
      UI.show_status(M._core_state)
    end, 1000) -- 延迟1秒显示，让其他插件先初始化
  end
end

-- 手动重新初始化
function M.reinitialize()
  if not M._initialized then
    return M.setup()
  end

  -- 清理现有状态
  M._cleanup()

  -- 重新初始化
  M._core_state = Core.initialize()
  M._load_functionality_based_on_state()

  vim.notify("🔄 Astra: Reinitialized", vim.log.levels.INFO)
end

-- 清理资源
function M._cleanup()
  -- 清理自动命令
  local augroup = vim.api.nvim_create_augroup("Astra", {})
  vim.api.nvim_clear_autocmds({group = augroup})

  -- 其他清理工作...
end

-- 获取当前状态
function M.get_status()
  if not M._initialized then
    return {
      initialized = false,
      functionality_level = "none",
      message = "Plugin not initialized"
    }
  end

  return vim.deepcopy(M._core_state)
end

-- 获取配置信息
function M.get_config()
  return vim.deepcopy(M._public_config)
end

-- 更新公共配置
function M.update_config(new_config)
  if not M._initialized then
    vim.notify("❌ Astra: Plugin not initialized", vim.log.levels.ERROR)
    return false
  end

  M._public_config = vim.tbl_deep_extend("force", M._public_config, new_config or {})
  M._load_functionality_based_on_state()

  vim.notify("✅ Astra: Configuration updated", vim.log.levels.INFO)
  return true
end

-- 检查插件是否可用
function M.is_available()
  return M._initialized and M._core_state and M._core_state.functionality_level == "full"
end

-- 便捷函数：快速检查
function M.check()
  local status = M.get_status()
  local available = M.is_available()

  if available then
    vim.notify("✅ Astra: Ready to use", vim.log.levels.INFO)
  else
    local reason = "Unknown"
    if not status.binary_available then
      reason = "No binary available - run :AstraBuild"
    elseif not status.config_available then
      reason = "No project config - run :AstraInit"
    end
    vim.notify("❌ Astra: Not available - " .. reason, vim.log.levels.WARN)
  end

  return available
end

-- 向后兼容的别名
M.status = M.get_status
M.config = M.get_config
M.reload = M.reinitialize

return M