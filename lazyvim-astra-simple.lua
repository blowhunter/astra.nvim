-- 简化的 LazyVim Astra.nvim 配置
return {
  "blowhunter/astra.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
  },
  lazy = false,
  priority = 100,
  config = function()
    -- 基础配置
    local astra_config = {
      project_root = vim.fn.expand("~/.local/share/nvim/lazy/astra.nvim"),
      core_path = vim.fn.expand("~/.local/share/nvim/lazy/astra.nvim/astra-core"),
      binary_path = vim.fn.expand("~/.local/share/nvim/lazy/astra.nvim/astra-core/target/release/astra-core"),
    }

    -- 工具函数
    local astra_utils = {}

    function astra_utils.build_core()
      local cmd = string.format("cd %s && cargo build --release", astra_config.core_path)
      
      vim.notify("🔨 构建中 Astra.nvim...", vim.log.levels.INFO)
      
      vim.fn.jobstart(cmd, {
        on_exit = function(_, exit_code)
          if exit_code == 0 then
            vim.notify("✅ 构建完成！", vim.log.levels.INFO)
            -- 刷新配置
            vim.schedule(function()
              if vim.cmd.AstraRefreshConfig then
                vim.cmd.AstraRefreshConfig()
              end
            end)
          else
            vim.notify("❌ 构建失败", vim.log.levels.ERROR)
          end
        end,
      })
    end

    function astra_utils.check_core()
      return vim.fn.filereadable(astra_config.binary_path) == 1
    end

    function astra_utils.init()
      -- 检查并构建
      if not astra_utils.check_core() then
        vim.schedule(function()
          astra_utils.build_core()
        end)
      end

      -- 设置插件（使用自动配置发现）
      require("astra").setup({
        auto_sync = true,
        sync_on_save = true,
        sync_interval = 30000,
      })

      -- 初始化后刷新配置
      vim.schedule(function()
        if vim.cmd.AstraRefreshConfig then
          vim.cmd.AstraRefreshConfig()
        end
      end)
    end

    -- 启动
    vim.schedule(astra_utils.init)

    -- 创建命令
    vim.api.nvim_create_user_command("AstraBuildCore", astra_utils.build_core, {
      desc = "构建 Astra.nvim 核心程序",
    })

    vim.api.nvim_create_user_command("AstraQuickSync", function()
      if vim.cmd.AstraUploadCurrent then
        vim.cmd.AstraUploadCurrent()
      else
        vim.notify("Astra: 命令不可用", vim.log.levels.ERROR)
      end
    end, { desc = "快速同步当前文件" })

    vim.api.nvim_create_user_command("AstraVersion", function()
      if vim.cmd.AstraVersion then
        vim.cmd.AstraVersion()
      else
        vim.notify("Astra: 版本命令不可用", vim.log.levels.ERROR)
      end
    end, { desc = "显示版本信息" })

    vim.api.nvim_create_user_command("AstraUpdateCheck", function()
      if vim.cmd.AstraCheckUpdate then
        vim.cmd.AstraCheckUpdate()
      else
        vim.notify("Astra: 更新检查命令不可用", vim.log.levels.ERROR)
      end
    end, { desc = "检查更新" })

    -- 简洁的键位映射
    local keys = {
      { "<leader>ai", "<cmd>AstraInit<cr>", desc = "Astra 初始化配置" },
      { "<leader>au", "<cmd>AstraUploadCurrent<cr>", desc = "Astra 上传当前文件" },
      { "<leader>as", "<cmd>AstraSync auto<cr>", desc = "Astra 同步项目" },
      { "<leader>aq", "<cmd>AstraQuickSync<cr>", desc = "Astra 快速同步" },
      { "<leader>ab", "<cmd>AstraBuildCore<cr>", desc = "Astra 构建" },
      { "<leader>ar", "<cmd>AstraRefreshConfig<cr>", desc = "Astra 刷新配置" },
      { "<leader>av", "<cmd>AstraVersion<cr>", desc = "Astra 版本信息" },
      { "<leader>aU", "<cmd>AstraUpdateCheck<cr>", desc = "Astra 检查更新" },
    }

    for _, key in ipairs(keys) do
      vim.keymap.set("n", key[1], key[2], { desc = key.desc, noremap = true, silent = true })
    end

    -- 保存时自动同步
    vim.api.nvim_create_autocmd("BufWritePost", {
      pattern = "*",
      callback = function()
        -- 排除临时文件
        local file = vim.fn.expand("%:t")
        if not (file:match("%.tmp$") or file:match("%.log$") or file:match("%.swp$")) then
          vim.schedule(function()
            if vim.cmd.AstraUploadCurrent then
              vim.cmd.AstraUploadCurrent()
            end
          end)
        end
      end,
      desc = "Astra: 保存时自动同步",
    })

    vim.notify("Astra.nvim: 简化配置已加载", vim.log.levels.INFO)
  end,
}