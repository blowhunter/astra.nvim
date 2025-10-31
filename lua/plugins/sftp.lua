-- Astra.nvim 三层架构配置文件
-- 专注于核心功能，确保稳定性和正确性

return {
  "blowhunter/astra.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
  },
  lazy = false,
  priority = 100,
  debug = false,

  -- 核心公共配置层：为常用项目提供合理默认设置
  opts = {
    -- 基础连接配置（项目配置可覆盖）
    host = "",
    port = 22,
    username = "",
    password = nil,
    private_key_path = "~/.ssh/id_rsa",
    remote_path = "",
    local_path = vim.fn.getcwd(),

    -- 核心功能开关（精简配置，专注稳定性）
    auto_sync = false,           -- 关闭自动同步，避免意外
    sync_on_save = true,         -- 保存时同步（核心功能）
    sync_interval = 30000,       -- 同步间隔

    -- 基础文件过滤（常用项目）
    exclude_patterns = {
      ".git/",
      "*.tmp",
      "*.log",
      ".DS_Store",
      "node_modules/",
      "target/",
      "build/",
      "dist/"
    },
    include_patterns = {},
    max_file_size = 10 * 1024 * 1024,  -- 10MB

    -- 开发选项
    static_build = false,        -- 使用动态链接版本
    debug_mode = false,          -- 关闭调试模式，确保稳定

    -- UI 选项（专注核心功能）
    notification_enabled = true, -- 启用通知
    auto_save_config = false,    -- 关闭自动保存
  },

  -- 配置函数：使用新的三层架构
  config = function(_, opts)
    -- 直接加载和设置
    local ok, astra = pcall(require, "astra")
    if ok then
      astra.setup(opts)
    else
      vim.notify("❌ Astra: Failed to load core module", vim.log.levels.ERROR)
      vim.notify("💡 Make sure the plugin is properly installed and compiled", vim.log.levels.WARN)
    end
  end,

  -- 事件处理
  event = "VeryLazy",

  -- 初始化函数
  init = function()
    -- 通用错误处理函数
    local function handle_error(msg)
      vim.notify(msg, vim.log.levels.ERROR)
      vim.notify("💡 Try :AstraHelp for available commands", vim.log.levels.INFO)
    end

    -- 创建统一的主命令接口
    vim.api.nvim_create_user_command("Astra", function(opts)
      local subcommand = opts.args
      if subcommand == "check" then
        local ok, astra = pcall(require, "astra")
        if ok then
          astra.check()
        else
          handle_error("❌ Astra: Plugin not loaded")
        end
      elseif subcommand == "reload" then
        local ok, astra = pcall(require, "astra")
        if ok then
          astra.reinitialize()
        else
          handle_error("❌ Astra: Plugin not loaded")
        end
      elseif subcommand == "help" then
        vim.cmd("AstraHelp")
      elseif subcommand == "status" then
        local ok, Core = pcall(require, "astra.core")
        if ok then
          local UI = require("astra.core.ui")
          UI.show_status(Core.get_state())
        else
          handle_error("❌ Astra: Core module not loaded - try :AstraBuild")
        end
      else
        vim.notify("Astra commands: check, reload, help, status", vim.log.levels.INFO)
      end
    end, {
      nargs = "?",
      complete = function()
        return {"check", "reload", "help", "status"}
      end,
      desc = "Astra: Main command interface"
    })
  end,
}