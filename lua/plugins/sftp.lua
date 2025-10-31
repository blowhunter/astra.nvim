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
  if ok_core then
    Core.initialize()
    vim.notify("✅ Astra: Core module initialized", vim.log.levels.INFO)
  else
    vim.notify("ℹ️  Astra: Core module will be loaded on demand", vim.log.levels.INFO)
  end

  -- 检查二进制文件状态
  local ok_binary, Binary = pcall(require, "astra.core.binary")
  if ok_binary then
    local status = Binary.validate()
    if status.available then
      vim.notify("✅ Astra: Binary available - " .. (status.version or "unknown"), vim.log.levels.INFO)
    else
      vim.notify("ℹ️  Astra: Run :AstraBuild to build binary", vim.log.levels.INFO)
    end
  end

  -- 检查配置状态
  local ok_config, Config = pcall(require, "astra.core.config")
  if ok_config then
    local config_status = Config.validate_project_config()
    if config_status.available then
      vim.notify("✅ Astra: Configuration available", vim.log.levels.INFO)
    else
      vim.notify("ℹ️  Astra: Run :AstraInit to initialize configuration", vim.log.levels.INFO)
    end
  end
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
        local status = Config.validate_project_config()
        if status.available then
          vim.notify("📋 Astra Configuration:", vim.log.levels.INFO)
          for k, v in pairs(status.config) do
            if type(v) ~= "table" then
              vim.notify(string.format("  %s: %s", k, tostring(v)), vim.log.levels.INFO)
            end
          end
        else
          vim.notify("❌ No configuration found", vim.log.levels.WARN)
        end
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
  end,

  -- 核心键映射注册
M._register_core_keymaps = function()
    local leader = vim.g.maplocalleader or vim.g.mapleader or " "

    local function safe_keymap(key, func, desc)
      vim.keymap.set('n', leader .. key, function()
        local ok, result = pcall(func)
        if not ok then
          vim.notify("❌ Astra: " .. desc .. " failed: " .. tostring(result), vim.log.levels.ERROR)
        end
      end, { desc = desc, noremap = true, silent = true })
    end

    -- 配置管理键映射
    safe_keymap("Ai", function()
      vim.cmd("AstraInit")
    end, "Initialize config")

    safe_keymap("Ab", function()
      vim.cmd("AstraBuild")
    end, "Build binary")

    safe_keymap("Ac", function()
      vim.cmd("AstraConfig")
    end, "Show config")

    -- 文件操作键映射
    safe_keymap("Au", function()
      vim.cmd("AstraUpload")
    end, "Upload file")

    safe_keymap("Ad", function()
      vim.cmd("AstraDownload")
    end, "Download file")

    -- 同步功能键映射
    safe_keymap("As", function()
      vim.cmd("AstraSync")
    end, "Sync project")

    safe_keymap("Aa", function()
      vim.cmd("AstraIncSync")
    end, "Incremental sync")

    -- 信息查看键映射
    safe_keymap("Av", function()
      vim.cmd("AstraVersion")
    end, "Show version")

    safe_keymap("Ah", function()
      vim.cmd("AstraHelp")
    end, "Show help")
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

  -- 配置函数
  config = function(_, opts)
    -- 初始化插件设置
    M._setup_plugin(opts)

    -- 注册核心命令（8个使用场景）
    M._register_core_commands()

    -- 注册核心键映射
    M._register_core_keymaps()
  end,
}