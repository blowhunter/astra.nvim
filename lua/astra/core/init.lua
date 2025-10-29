-- Astra.nvim 核心功能抽象层
-- 提供插件的核心功能接口和实现

local M = {}

-- 加载核心模块
local Binary = require("astra.core.binary")
local Config = require("astra.core.config")
local Sync = require("astra.core.sync")
local UI = require("astra.core.ui")

-- 核心状态管理
M.state = {
  initialized = false,
  binary_available = false,
  config_available = false,
  functionality_level = "none"  -- none, basic, full
}

-- 核心初始化函数
function M.initialize()
  if M.state.initialized then
    return M.state
  end

  -- 1. 验证二进制文件
  local binary_status = Binary.validate()
  M.state.binary_available = binary_status.available

  -- 2. 验证项目配置
  local config_status = Config.validate_project_config()
  M.state.config_available = config_status.available

  -- 3. 确定功能级别
  M.state.functionality_level = M:_determine_functionality_level()

  -- 4. 初始化相应级别的功能
  M:_initialize_functionality()

  M.state.initialized = true
  return M.state
end

-- 确定功能级别
function M:_determine_functionality_level()
  if not M.state.binary_available then
    return "basic"  -- 只有基本功能：构建、配置向导
  end

  if not M.state.config_available then
    return "basic"  -- 只有基本功能：配置初始化
  end

  return "full"     -- 完整功能
end

-- 根据功能级别初始化功能
function M:_initialize_functionality()
  local level = M.state.functionality_level

  if level == "basic" then
    M._register_basic_commands()
    M._register_basic_keymaps()
  elseif level == "full" then
    M._register_full_commands()
    M._register_full_keymaps()
    -- 初始化同步模块
    Sync.initialize()
  end
end

-- 注册基本命令
function M._register_basic_commands()
  if not M.state.binary_available then
    -- 只有二进制管理相关命令
    vim.api.nvim_create_user_command("AstraBuild", function()
      Binary.build()
    end, { desc = "Build Astra core binary" })

    vim.api.nvim_create_user_command("AstraInstall", function()
      Binary.install()
    end, { desc = "Install Astra core binary" })
  end

  if M.state.binary_available and not M.state.config_available then
    -- 配置初始化相关命令
    vim.api.nvim_create_user_command("AstraInit", function()
      Config.init_project_config()
    end, { desc = "Initialize project configuration" })

    vim.api.nvim_create_user_command("AstraQuickSetup", function()
      Config.quick_setup()
    end, { desc = "Quick setup wizard" })
  end
end

-- 注册完整命令
function M._register_full_commands()
  -- 包含基本命令
  M._register_basic_commands()

  -- 完整功能命令
  local full_commands = {
    "AstraUpload", "AstraDownload", "AstraSync", "AstraStatus",
    "AstraUploadMulti", "AstraSyncClear", "AstraVersion"
  }

  for _, cmd in ipairs(full_commands) do
    local cmd_func = function()
      local module = cmd:match("Astra(%w+)")
      if Sync[module:lower()] then
        Sync[module:lower()]()
      end
    end

    vim.api.nvim_create_user_command(cmd, cmd_func, {
      desc = "Astra: " .. module
    })
  end
end

-- 注册基本键映射
function M._register_basic_keymaps()
  local leader = vim.g.maplocalleader or vim.g.mapleader or "\\"

  if not M.state.binary_available then
    vim.keymap.set('n', leader .. 'Abc', function() Binary.build() end,
      { desc = "Astra: Build core", noremap = true, silent = true })
  end

  if M.state.binary_available and not M.state.config_available then
    vim.keymap.set('n', leader .. 'Arc', function() Config.init_project_config() end,
      { desc = "Astra: Initialize config", noremap = true, silent = true })
    vim.keymap.set('n', leader .. 'Aq', function() Config.quick_setup() end,
      { desc = "Astra: Quick setup", noremap = true, silent = true })
  end
end

-- 注册完整键映射
function M._register_full_keymaps()
  -- 包含基本键映射
  M._register_basic_keymaps()

  -- 完整功能键映射
  local leader = vim.g.maplocalleader or vim.g.mapleader or "\\"
  local full_mappings = {
    ['Au'] = 'upload',
    ['Ad'] = 'download',
    ['As'] = 'sync',
    ['Ass'] = 'status',
    ['Av'] = 'version',
    ['Aus'] = 'upload_selected'
  }

  for mapping, func in pairs(full_mappings) do
    local keymap_func = function()
      if Sync[func] then
        Sync[func]()
      end
    end

    if mapping == 'Aus' then
      vim.keymap.set('x', leader .. mapping, keymap_func,
        { desc = "Astra: " .. func, noremap = true, silent = true })
    else
      vim.keymap.set('n', leader .. mapping, keymap_func,
        { desc = "Astra: " .. func, noremap = true, silent = true })
    end
  end
end

-- 获取当前状态
function M.get_state()
  return vim.deepcopy(M.state)
end

-- 重新初始化（用于状态变更时）
function M.reinitialize()
  M.state.initialized = false
  return M.initialize()
end

return M