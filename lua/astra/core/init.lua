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
  -- 始终注册帮助命令
  vim.api.nvim_create_user_command("AstraHelp", function()
    M._show_help()
  end, { desc = "Show Astra help" })

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

  -- 完整功能命令 - 只注册实际实现的命令
  vim.api.nvim_create_user_command("AstraUpload", function()
    Sync.upload()
  end, { desc = "Astra: Upload current file" })

  vim.api.nvim_create_user_command("AstraDownload", function()
    Sync.download()
  end, { desc = "Astra: Download current file" })

  vim.api.nvim_create_user_command("AstraSync", function()
    Sync.sync()
  end, { desc = "Astra: Sync current file" })

  vim.api.nvim_create_user_command("AstraStatus", function()
    Sync.status()
  end, { desc = "Astra: Check sync status" })

  vim.api.nvim_create_user_command("AstraVersion", function()
    Sync.version()
  end, { desc = "Show Astra version" })
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

  -- 完整功能键映射 - 只保留实际可用的核心功能
  local leader = vim.g.maplocalleader or vim.g.mapleader or "\\"

  -- 文件操作核心功能
  vim.keymap.set('n', leader .. 'Au', function() Sync.upload() end,
    { desc = "Astra: Upload current file", noremap = true, silent = true })

  vim.keymap.set('n', leader .. 'Ad', function() Sync.download() end,
    { desc = "Astra: Download current file", noremap = true, silent = true })

  vim.keymap.set('n', leader .. 'As', function() Sync.sync() end,
    { desc = "Astra: Sync current file", noremap = true, silent = true })

  vim.keymap.set('n', leader .. 'Ai', function() Sync.status() end,
    { desc = "Astra: Check status", noremap = true, silent = true })

  vim.keymap.set('n', leader .. 'Av', function() Sync.version() end,
    { desc = "Astra: Show version", noremap = true, silent = true })
end

-- 显示帮助信息
function M._show_help()
  local level = M.state.functionality_level
  local help_lines = {}

  table.insert(help_lines, "🚀 Astra.nvim - SFTP File Synchronization")
  table.insert(help_lines, "")

  if level == "none" then
    table.insert(help_lines, "当前状态：未初始化")
    table.insert(help_lines, "")
    table.insert(help_lines, "可用命令：")
    table.insert(help_lines, "  :AstraHelp     - 显示此帮助信息")
  elseif level == "basic" then
    table.insert(help_lines, "当前状态：基础功能模式")
    table.insert(help_lines, "")

    if not M.state.binary_available then
      table.insert(help_lines, "可用命令：")
      table.insert(help_lines, "  :AstraHelp     - 显示帮助信息")
      table.insert(help_lines, "  :AstraBuild    - 构建核心二进制文件")
      table.insert(help_lines, "  :AstraInstall  - 安装核心二进制文件")
    else
      table.insert(help_lines, "可用命令：")
      table.insert(help_lines, "  :AstraHelp       - 显示帮助信息")
      table.insert(help_lines, "  :AstraInit       - 初始化项目配置")
      table.insert(help_lines, "  :AstraQuickSetup - 快速配置向导")
    end
  elseif level == "full" then
    table.insert(help_lines, "当前状态：完整功能模式")
    table.insert(help_lines, "")
    table.insert(help_lines, "核心文件操作：")
    table.insert(help_lines, "  :AstraUpload   - 上传当前文件")
    table.insert(help_lines, "  :AstraDownload - 下载当前文件")
    table.insert(help_lines, "  :AstraSync     - 同步当前文件")
    table.insert(help_lines, "  :AstraStatus   - 检查同步状态")
    table.insert(help_lines, "  :AstraVersion  - 显示版本信息")
    table.insert(help_lines, "")
    table.insert(help_lines, "配置管理：")
    table.insert(help_lines, "  :AstraInit       - 初始化项目配置")
    table.insert(help_lines, "  :AstraQuickSetup - 快速配置向导")
    table.insert(help_lines, "  :AstraHelp       - 显示帮助信息")
  end

  table.insert(help_lines, "")
  table.insert(help_lines, "快捷键：")
  table.insert(help_lines, "  <leader>Ah - 显示帮助")
  table.insert(help_lines, "  <leader>Av - 显示版本")

  if level == "full" then
    table.insert(help_lines, "  <leader>Au - 上传当前文件")
    table.insert(help_lines, "  <leader>Ad - 下载当前文件")
    table.insert(help_lines, "  <leader>As - 同步当前文件")
    table.insert(help_lines, "  <leader>Ai - 检查状态")
  end

  if level == "basic" then
    if not M.state.binary_available then
      table.insert(help_lines, "  <leader>Ab - 构建核心")
    else
      table.insert(help_lines, "  <leader>Ac - 初始化配置")
      table.insert(help_lines, "  <leader>Aq - 快速配置")
    end
  end

  -- 使用 vim.notify 显示帮助
  local help_text = table.concat(help_lines, "\n")
  vim.notify(help_text, vim.log.levels.INFO)
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