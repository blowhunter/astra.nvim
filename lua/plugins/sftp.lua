-- Astra.nvim 核心配置文件
-- 专注于8个核心使用场景，保持代码简洁

local M = {}

-- 插件设置初始化
M._setup_plugin = function(opts)
  -- 保存配置到全局变量供其他模块使用
  _G.AstraConfig = opts

  -- 添加插件路径到 package.path
  local plugin_path = vim.fn.stdpath("data") .. "/lazy/astra.nvim/lua"
  package.path = plugin_path .. "/?.lua;" .. package.path

  -- 尝试初始化核心模块（如果可用）
  local ok_core, Core = pcall(require, "astra.core")
  if ok_core and type(Core) == "table" and Core.initialize then
    Core.initialize()
    vim.notify("✅ Astra: Core module initialized", vim.log.levels.INFO)
  else
    vim.notify("ℹ️  Astra: Core module will be loaded on demand", vim.log.levels.INFO)
  end

  -- 检查二进制文件状态
  local ok_binary, Binary = pcall(require, "astra.core.binary")
  if ok_binary and type(Binary) == "table" and Binary.validate then
    local status = Binary.validate()
    if status.available then
      vim.notify("✅ Astra: Binary available - " .. (status.version or "unknown"), vim.log.levels.INFO)
    else
      vim.notify("ℹ️  Astra: Run :AstraBuild to build binary", vim.log.levels.INFO)
    end
  end

  -- 检查配置状态
  local ok_config, Config = pcall(require, "astra.core.config")
  if ok_config and type(Config) == "table" and Config.validate_project_config then
    local config_status = Config.validate_project_config()
    if config_status.available then
      vim.notify("✅ Astra: Configuration available", vim.log.levels.INFO)
    else
      vim.notify("ℹ️  Astra: Run :AstraInit to initialize configuration", vim.log.levels.INFO)
    end
  end
end

-- 动态状态检查函数
M._check_status = function()
  local status = {
    core_loaded = false,
    binary_available = false,
    config_available = false,
    current_file = vim.fn.expand("%:p") ~= ""
  }

  -- 检查核心模块
  local ok_core, Core = pcall(require, "astra.core")
  if ok_core and type(Core) == "table" then
    status.core_loaded = true

    -- 检查二进制文件
    local ok_binary, Binary = pcall(require, "astra.core.binary")
    if ok_binary and type(Binary) == "table" and Binary.validate then
      local binary_status = Binary.validate()
      status.binary_available = binary_status.available
    end

    -- 检查配置文件
    local ok_config, Config = pcall(require, "astra.core.config")
    if ok_config and type(Config) == "table" and Config.validate_project_config then
      local config_status = Config.validate_project_config()
      status.config_available = config_status.available
    end
  end

  return status
end

-- 基础功能函数
M._show_help = function()
  local help_lines = {
    "🚀 Astra.nvim - 动态快捷键系统",
    "",
    "基础功能 (始终可用):",
    "  <leader>Ah - 显示帮助 (当前)",
    "  <leader>Av - 显示版本信息",
    "",
    "配置管理 (智能处理):",
    "  <leader>Ai - 初始化配置",
    "  <leader>Ab - 构建二进制文件",
    "  <leader>Ac - 查看当前配置",
    "",
    "文件操作 (状态感知):",
    "  <leader>Au - 上传当前文件",
    "  <leader>Ad - 下载当前文件",
    "",
    "同步功能 (条件执行):",
    "  <leader>As - 同步整个项目",
    "  <leader>Aa - 增量同步",
    "",
    "特性:",
    "  ✓ 智能状态检测",
    "  ✓ 自动错误处理",
    "  ✓ 动态功能可用性",
    "  ✓ 用户友好的提示",
  }

  local help_text = table.concat(help_lines, "\n")
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(help_text, "\n"))
  vim.api.nvim_buf_set_option(buf, "buftype", "nofile")
  vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe")
  vim.api.nvim_buf_set_option(buf, "modifiable", false)

  vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = math.min(60, vim.o.columns - 4),
    height = math.min(#help_lines + 2, vim.o.lines - 4),
    col = 2,
    row = 2,
    border = "single",
    title = "Astra Dynamic Help",
    title_pos = "center",
  })

  vim.keymap.set('n', 'q', '<cmd>q<cr>', { buffer = buf, silent = true })
  vim.keymap.set('n', '<Esc>', '<cmd>q<cr>', { buffer = buf, silent = true })
end

M._show_version = function()
  local status = M._check_status()

  if status.binary_available then
    local ok_binary, Binary = pcall(require, "astra.core.binary")
    if ok_binary then
      local binary_status = Binary.validate()
      vim.notify("📊 Astra Version: " .. (binary_status.version or "unknown"), vim.log.levels.INFO)
      vim.notify("🔧 Binary: " .. binary_status.path, vim.log.levels.INFO)
      vim.notify("🏗️  Build Type: " .. binary_status.type, vim.log.levels.INFO)
    end
  else
    vim.notify("📊 Astra: Plugin loaded", vim.log.levels.INFO)
    vim.notify("❌ Binary not available - run :AstraBuild", vim.log.levels.WARN)
  end

  local status_info = string.format("状态: 核心=%s, 二进制=%s, 配置=%s",
    status.core_loaded and "✅" or "❌",
    status.binary_available and "✅" or "❌",
    status.config_available and "✅" or "❌")
  vim.notify(status_info, vim.log.levels.INFO)
end

-- 智能配置管理函数
M._smart_init = function()
  local status = M._check_status()

  if status.config_available then
    vim.notify("✅ 配置文件已存在", vim.log.levels.INFO)
    vim.notify("💡 位置: 在当前项目目录的配置文件中", vim.log.levels.INFO)
  else
    vim.notify("🔧 正在初始化配置文件...", vim.log.levels.INFO)
    vim.cmd("AstraInit")
  end
end

M._smart_build = function()
  local status = M._check_status()

  if status.binary_available then
    local ok_binary, Binary = pcall(require, "astra.core.binary")
    if ok_binary then
      local binary_status = Binary.validate()
      vim.notify("✅ 二进制文件已存在", vim.log.levels.INFO)
      vim.notify("📊 版本: " .. (binary_status.version or "unknown"), vim.log.levels.INFO)
      vim.notify("🔧 路径: " .. binary_status.path, vim.log.levels.INFO)
      vim.notify("💡 如需重新构建，请运行 :AstraBuild", vim.log.levels.INFO)
    end
  else
    vim.notify("🔧 正在构建二进制文件...", vim.log.levels.INFO)
    vim.cmd("AstraBuild")
  end
end

M._smart_config = function()
  local Config = safe_require("astra.core.config")
  if Config then
    Config.info()  -- 使用新的弹窗展示
  end
end

-- 智能文件操作函数
M._smart_upload = function()
  local status = M._check_status()

  if not status.current_file then
    vim.notify("❌ 没有当前文件可上传", vim.log.levels.ERROR)
    return
  end

  if not status.binary_available then
    vim.notify("❌ 二进制文件不可用", vim.log.levels.ERROR)
    vim.notify("💡 请先运行 <leader>Ab 构建二进制文件", vim.log.levels.INFO)
    return
  end

  if not status.config_available then
    vim.notify("❌ 配置文件不可用", vim.log.levels.ERROR)
    vim.notify("💡 请先运行 <leader>Ai 初始化配置", vim.log.levels.INFO)
    return
  end

  vim.cmd("AstraUpload")
end

M._smart_download = function()
  local status = M._check_status()

  if not status.current_file then
    vim.notify("❌ 没有当前文件可下载", vim.log.levels.ERROR)
    return
  end

  if not status.binary_available then
    vim.notify("❌ 二进制文件不可用", vim.log.levels.ERROR)
    vim.notify("💡 请先运行 <leader>Ab 构建二进制文件", vim.log.levels.INFO)
    return
  end

  if not status.config_available then
    vim.notify("❌ 配置文件不可用", vim.log.levels.ERROR)
    vim.notify("💡 请先运行 <leader>Ai 初始化配置", vim.log.levels.INFO)
    return
  end

  vim.cmd("AstraDownload")
end

-- 智能同步函数
M._smart_sync = function()
  local status = M._check_status()

  if not status.binary_available then
    vim.notify("❌ 二进制文件不可用", vim.log.levels.ERROR)
    vim.notify("💡 请先运行 <leader>Ab 构建二进制文件", vim.log.levels.INFO)
    return
  end

  if not status.config_available then
    vim.notify("❌ 配置文件不可用", vim.log.levels.ERROR)
    vim.notify("💡 请先运行 <leader>Ai 初始化配置", vim.log.levels.INFO)
    return
  end

  vim.cmd("AstraSync")
end

M._smart_incremental_sync = function()
  local status = M._check_status()

  if not status.binary_available then
    vim.notify("❌ 二进制文件不可用", vim.log.levels.ERROR)
    vim.notify("💡 请先运行 <leader>Ab 构建二进制文件", vim.log.levels.INFO)
    return
  end

  if not status.config_available then
    vim.notify("❌ 配置文件不可用", vim.log.levels.ERROR)
    vim.notify("💡 请先运行 <leader>Ai 初始化配置", vim.log.levels.INFO)
    return
  end

  vim.cmd("AstraIncSync")
end

-- 核心命令注册
M._register_core_commands = function()
    local function safe_require(module_name)
      local ok, module = pcall(require, module_name)
      if not ok then
        vim.notify("❌ Failed to load module: " .. module_name, vim.log.levels.ERROR)
        return nil
      end
      return module
    end

    local function safe_command(cmd_name, cmd_func, desc)
      vim.api.nvim_create_user_command(cmd_name, function()
        local ok, result = pcall(cmd_func)
        if not ok then
          vim.notify("❌ Astra " .. cmd_name .. " failed: " .. tostring(result), vim.log.levels.ERROR)
        end
      end, { desc = desc })
    end

    -- 1. 配置初始化命令
    safe_command("AstraInit", function()
      local Config = safe_require("astra.core.config")
      if Config then Config.init_project_config() end
    end, "Initialize project configuration")

    -- 2. 二进制构建命令
    safe_command("AstraBuild", function()
      local Binary = safe_require("astra.core.binary")
      if Binary then Binary.build() end
    end, "Build astra-core binary")

    -- 3. 单文件上传
    safe_command("AstraUpload", function()
      local Sync = safe_require("astra.core.sync")
      if Sync then Sync.upload_current_file() end
    end, "Upload current file")

    -- 4. 单文件下载
    safe_command("AstraDownload", function()
      local Sync = safe_require("astra.core.sync")
      if Sync then Sync.download_current_file() end
    end, "Download current file")

    -- 5. 目录上传
    safe_command("AstraUploadDir", function()
      local Sync = safe_require("astra.core.sync")
      if Sync then Sync.upload_directory() end
    end, "Upload current directory")

    -- 6. 目录下载
    safe_command("AstraDownloadDir", function()
      local Sync = safe_require("astra.core.sync")
      if Sync then Sync.download_directory() end
    end, "Download current directory")

    -- 7. 项目同步
    safe_command("AstraSync", function()
      local Sync = safe_require("astra.core.sync")
      if Sync then Sync.sync_project() end
    end, "Sync entire project")

    -- 8. 增量同步
    safe_command("AstraIncSync", function()
      local Sync = safe_require("astra.core.sync")
      if Sync then Sync.incremental_sync() end
    end, "Incremental sync")

    -- 辅助命令
    safe_command("AstraConfig", function()
      local Config = safe_require("astra.core.config")
      if Config then
        Config.info()  -- 使用新的弹窗展示
      end
    end, "Show current configuration")

    safe_command("AstraVersion", function()
      local Binary = safe_require("astra.core.binary")
      if Binary then
        local status = Binary.validate()
        if status.available then
          vim.notify(string.format("📊 Astra Version: %s", status.version or "unknown"), vim.log.levels.INFO)
          vim.notify(string.format("🔧 Binary: %s", status.path), vim.log.levels.INFO)
        else
          vim.notify("❌ No binary available - run :AstraBuild", vim.log.levels.ERROR)
        end
      end
    end, "Show version information")

    safe_command("AstraHelp", function()
      local help_lines = {
        "🚀 Astra.nvim - 8个核心功能",
        "",
        "配置管理:",
        "  :AstraInit      - 初始化项目配置",
        "  :AstraConfig    - 查看当前配置",
        "  :AstraBuild     - 构建二进制文件",
        "",
        "文件操作:",
        "  :AstraUpload    - 上传当前文件",
        "  :AstraDownload  - 下载当前文件",
        "  :AstraUploadDir - 上传当前目录",
        "  :AstraDownloadDir- 下载当前目录",
        "",
        "同步功能:",
        "  :AstraSync      - 同步整个项目",
        "  :AstraIncSync   - 增量同步",
        "",
        "信息查看:",
        "  :AstraVersion   - 查看版本信息",
        "",
        "快捷键:",
        "  <leader>Ai - 初始化配置",
        "  <leader>Ab - 构建二进制",
        "  <leader>Au - 上传文件",
        "  <leader>Ad - 下载文件",
        "  <leader>As - 同步项目",
        "  <leader>Aa - 增量同步",
        "  <leader>Ac - 查看配置",
        "  <leader>Av - 查看版本",
      }

      local help_text = table.concat(help_lines, "\n")
      local buf = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(help_text, "\n"))
      vim.api.nvim_buf_set_option(buf, "buftype", "nofile")
      vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe")
      vim.api.nvim_buf_set_option(buf, "modifiable", false)

      vim.api.nvim_open_win(buf, true, {
        relative = "editor",
        width = math.min(60, vim.o.columns - 4),
        height = math.min(#help_lines + 2, vim.o.lines - 4),
        col = 2,
        row = 2,
        border = "single",
        title = "Astra Help",
        title_pos = "center",
      })

      vim.keymap.set('n', 'q', '<cmd>q<cr>', { buffer = buf, silent = true })
      vim.keymap.set('n', '<Esc>', '<cmd>q<cr>', { buffer = buf, silent = true })
    end, "Show help information")

    -- 测试命令
    safe_command("AstraTest", function()
      local test_path = vim.fn.stdpath("data") .. "/lazy/astra.nvim/test/test_core_functionality.lua"
      if vim.fn.filereadable(test_path) == 1 then
        dofile(test_path)
        if _G.TestCoreFunctionality then
          _G.TestCoreFunctionality.quick_test()
        else
          vim.notify("❌ Test module not found", vim.log.levels.ERROR)
        end
      else
        vim.notify("❌ Test file not found: " .. test_path, vim.log.levels.ERROR)
      end
    end, "Run quick functionality test")

    safe_command("AstraTestAll", function()
      local test_path = vim.fn.stdpath("data") .. "/lazy/astra.nvim/test/test_core_functionality.lua"
      if vim.fn.filereadable(test_path) == 1 then
        dofile(test_path)
        if _G.TestCoreFunctionality then
          _G.TestCoreFunctionality.run_all_tests()
        else
          vim.notify("❌ Test module not found", vim.log.levels.ERROR)
        end
      else
        vim.notify("❌ Test file not found: " .. test_path, vim.log.levels.ERROR)
      end
    end, "Run all functionality tests")
end


-- 返回Lazyvim插件配置
return {
  "blowhunter/astra.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
  },
  lazy = false,
  priority = 100,

  -- 核心配置：支持8个使用场景
  opts = {
    -- 基础连接配置
    host = "",
    port = 22,
    username = "",
    password = nil,
    private_key_path = "~/.ssh/id_rsa",
    remote_path = "",
    local_path = vim.fn.getcwd(),

    -- 同步设置
    auto_sync = false,
    sync_on_save = true,
    sync_interval = 30000,

    -- 文件过滤
    exclude_patterns = {
      ".git/", "*.tmp", "*.log", ".DS_Store",
      "node_modules/", "target/", "build/", "dist/"
    },
    max_file_size = 10 * 1024 * 1024,  -- 10MB

    -- 开发选项
    static_build = false,
    debug_mode = false,
    notification_enabled = true,
    auto_save_config = false,
  },

  -- 动态快捷键定义
  keys = {
    -- 基础功能键映射（始终可用）
    { "<leader>Ah", function() M._show_help() end, desc = "Astra: Show help" },
    { "<leader>Av", function() M._show_version() end, desc = "Astra: Show version" },

    -- 配置管理键映射（智能处理）
    { "<leader>Ai", function() M._smart_init() end, desc = "Astra: Initialize config" },
    { "<leader>Ab", function() M._smart_build() end, desc = "Astra: Build binary" },
    { "<leader>Ac", function() M._smart_config() end, desc = "Astra: Show config" },

    -- 文件操作键映射（状态感知）
    { "<leader>Au", function() M._smart_upload() end, desc = "Astra: Upload file" },
    { "<leader>Ad", function() M._smart_download() end, desc = "Astra: Download file" },

    -- 同步功能键映射（条件执行）
    { "<leader>As", function() M._smart_sync() end, desc = "Astra: Sync project" },
    { "<leader>Aa", function() M._smart_incremental_sync() end, desc = "Astra: Incremental sync" },
  },

  -- 配置函数
  config = function(_, opts)
    -- 初始化插件设置
    M._setup_plugin(opts)

    -- 注册核心命令（8个使用场景）
    M._register_core_commands()
  end,
}