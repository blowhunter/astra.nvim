-- Astra.nvim 公共配置示例 - 新三层架构
-- 这个文件展示了如何在 ~/.config/nvim/lua/plugins/ 中配置 Astra.nvim

return {
  "blowhunter/astra.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",  -- 必需依赖
    "nvim-lua/popup.nvim",    -- 可选：用于更好的UI
  },
  lazy = false,  -- 立即加载，因为需要检查项目配置
  priority = 100,  -- 高优先级

  -- 公共配置层：为常用项目和功能提供常用配置
  opts = {
    -- 基础连接配置（可被项目配置覆盖）
    host = "",           -- 你的默认服务器
    port = 22,
    username = "",       -- 你的默认用户名
    password = nil,      -- 建议使用私钥而非密码
    private_key_path = "~/.ssh/id_rsa",
    remote_path = "",    -- 你的默认远程路径
    local_path = vim.fn.getcwd(),

    -- 功能开关（公共配置默认值）
    auto_sync = false,           -- 关闭自动同步，避免意外
    sync_on_save = true,         -- 保存时同步（推荐）
    sync_interval = 30000,       -- 同步间隔（毫秒）

    -- 文件过滤配置（适用于大多数项目）
    exclude_patterns = {
      ".git/",
      "*.tmp",
      "*.log",
      ".DS_Store",
      "node_modules/",
      ".vscode/",
      "*.pyc",
      "__pycache__/",
      ".pytest_cache/",
      "target/",
      "build/",
      "dist/",
      ".astra-settings/"
    },
    include_patterns = {},       -- 空表示包含所有文件
    max_file_size = 10 * 1024 * 1024,  -- 10MB 限制

    -- 开发选项
    static_build = false,        -- 使用动态链接版本（推荐用于开发）
    debug_mode = false,          -- 关闭调试模式

    -- UI 选项
    notification_enabled = true, -- 启用通知
    auto_save_config = false,    -- 关闭自动保存配置
  },

  -- 智能键映射：根据功能级别自动注册
  keys = function()
    local keys = {}

    -- 基础键映射（总是可用）
    vim.list_extend(keys, {
      { "<leader>Ah", "<cmd>AstraHelp<cr>", desc = "Astra: Show help", noremap = true, silent = true },
      { "<leader>As", "<cmd>AstraStatus<cr>", desc = "Astra: Show status", noremap = true, silent = true },
    })

    -- 检查插件功能级别
    local Core = require("astra.core")
    local state = Core.get_state()

    if state.functionality_level == "basic" then
      -- 基础功能键映射
      if not state.binary_available then
        vim.list_extend(keys, {
          { "<leader>Ab", "<cmd>AstraBuild<cr>", desc = "Astra: Build core", noremap = true, silent = true },
          { "<leader>Ai", "<cmd>AstraInstall<cr>", desc = "Astra: Install binary", noremap = true, silent = true },
        })
      end

      if state.binary_available and not state.config_available then
        vim.list_extend(keys, {
          { "<leader>Ac", "<cmd>AstraInit<cr>", desc = "Astra: Initialize config", noremap = true, silent = true },
          { "<leader>Aq", "<cmd>AstraQuickSetup<cr>", desc = "Astra: Quick setup", noremap = true, silent = true },
        })
      end
    elseif state.functionality_level == "full" then
      -- 完整功能键映射
      vim.list_extend(keys, {
        -- 文件操作
        { "<leader>Au", "<cmd>AstraUpload<cr>", desc = "Astra: Upload current file", noremap = true, silent = true },
        { "<leader>Ad", "<cmd>AstraDownload<cr>", desc = "Astra: Download current file", noremap = true, silent = true },
        { "<leader>As", "<cmd>AstraSync<cr>", desc = "Astra: Sync current file", noremap = true, silent = true },
        { "<leader>Ass", "<cmd>AstraStatus<cr>", desc = "Astra: Check status", noremap = true, silent = true },

        -- Visual 模式操作
        { "<leader>Aus", "<cmd>AstraUploadSelected<cr>", desc = "Astra: Upload selected", mode = "x", noremap = true, silent = true },

        -- 批量操作
        { "<leader>Aum", "<cmd>AstraUploadMulti<cr>", desc = "Astra: Upload multiple", noremap = true, silent = true },
        { "<leader>Af", "<cmd>AstraSyncClear<cr>", desc = "Astra: Clear queue", noremap = true, silent = true },

        -- 版本和信息
        { "<leader>Av", "<cmd>AstraVersion<cr>", desc = "Astra: Show version", noremap = true, silent = true },

        -- 构建和配置（仍然可用）
        { "<leader>Ab", "<cmd>AstraBuild<cr>", desc = "Astra: Build core", noremap = true, silent = true },
        { "<leader>Ac", "<cmd>AstraInit<cr>", desc = "Astra: Initialize config", noremap = true, silent = true },
      })
    end

    return keys
  end,

  -- 配置函数
  config = function(_, opts)
    -- 调用新的 setup 函数
    require("astra").setup(opts)
  end,

  -- 事件处理
  event = "VeryLazy",  -- 在所有插件加载后执行

  -- 模块加载时的初始化
  init = function()
    -- 创建用户命令（用于向后兼容）
    vim.api.nvim_create_user_command("Astra", function(opts)
      local subcommand = opts.args
      if subcommand == "check" then
        require("astra").check()
      elseif subcommand == "reload" then
        require("astra").reload()
      elseif subcommand == "help" then
        vim.cmd("AstraHelp")
      else
        vim.notify("Available Astra commands: check, reload, help", vim.log.levels.INFO)
      end
    end, {
      nargs = "?",
      complete = function()
        return {"check", "reload", "help"}
      end,
      desc = "Astra: Main command interface"
    })
  end,
}

-- 使用说明：
-- 1. 将此文件保存为 ~/.config/nvim/lua/plugins/astra.lua
-- 2. 修改 opts 中的配置为你常用的设置
-- 3. 在项目中创建 .astra.toml 文件来配置项目特定的设置
-- 4. 如果没有二进制文件，运行 :AstraBuild 来编译
-- 5. 如果没有项目配置，运行 :AstraInit 来创建配置文件