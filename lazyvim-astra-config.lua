return {
  "blowhunter/astra.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "j-hui/fidget.nvim", -- 用于更好的状态通知
  },
  lazy = false, -- 立即加载，因为需要初始化配置
  priority = 100, -- 高优先级确保早期加载
  debug = true,
  config = function()
    local fidget = require("fidget")

    -- Astra.nvim 优化配置模块
    local astra_config = {
      -- 项目路径配置（自动检测）
      project_root = vim.fn.expand("~/.local/share/nvim/lazy/astra.nvim"),
      core_path = vim.fn.expand("~/.local/share/nvim/lazy/astra.nvim/astra-core"),
      binary_path = vim.fn.expand("~/.local/share/nvim/lazy/astra.nvim/astra-core/target/release/astra-core"),

      -- 构建配置
      build = {
        auto_build = true, -- 启动时自动构建
        build_on_update = true, -- 更新后自动构建
        release_build = true, -- 使用 release 模式构建
        parallel_jobs = 4, -- 并行构建任务数
        features = {}, -- 额外的 cargo features
      },

      -- 连接配置（现在使用自动配置发现，这些作为备用）
      connection = {
        host = "", -- 留空以使用自动配置发现
        port = 22,
        username = "",
        password = nil,
        private_key_path = nil,
        remote_path = "", -- 留空以使用自动配置发现
        local_path = vim.fn.getcwd(),
        timeout = 30000, -- 连接超时（毫秒）
      },

      -- 同步配置
      sync = {
        auto_sync = true, -- 启用自动同步
        sync_on_save = true, -- 保存时同步
        sync_interval = 30000, -- 同步间隔（毫秒）
        debounce_time = 500, -- 防抖时间（毫秒）
        batch_size = 10, -- 批量处理文件数
        ignore_patterns = {
          "*.tmp",
          "*.log",
          ".git/*",
          "*.swp",
          "*.bak",
          "node_modules/*",
          ".DS_Store",
          "__pycache__/*",
          "*.pyc",
          "target/*", -- Rust target 目录
          "build/*", -- 构建目录
          "dist/*", -- 分发目录
        },
      },

      -- 通知配置
      notifications = {
        enabled = true,
        level = "info", -- 通知级别
        timeout = 3000, -- 通知显示时间
        progress = true, -- 显示进度
      },

      -- 调试配置
      debug = {
        enabled = true,
        log_file = vim.fn.expand("/tmp/astra.nvim_debug.log"),
        log_level = "debug",
        verbose_commands = true,
      },
    }

    -- 工具函数模块
    local astra_utils = {}

    -- 检查依赖项
    function astra_utils.check_dependencies()
      local deps = { "cargo", "rustc", "git" }
      local missing = {}

      for _, dep in ipairs(deps) do
        if vim.fn.executable(dep) == 0 then
          table.insert(missing, dep)
        end
      end

      if #missing > 0 then
        vim.notify("Astra.nvim: 缺少依赖项: " .. table.concat(missing, ", "), vim.log.levels.ERROR)
        return false
      end

      return true
    end

    -- 构建核心程序
    function astra_utils.build_core()
      if not astra_utils.check_dependencies() then
        return false
      end

      local config = astra_config.build
      local cmd = string.format("cd %s && cargo build", astra_config.core_path)

      if config.release_build then
        cmd = cmd .. " --release"
      end

      if config.parallel_jobs > 1 then
        cmd = cmd .. string.format(" -j %d", config.parallel_jobs)
      end

      if #config.features > 0 then
        cmd = cmd .. " --features " .. table.concat(config.features, ",")
      end

      -- 显示构建进度
      fidget.notify("🔨 正在构建 Astra.nvim 核心程序...", nil, {
        title = "Astra.nvim",
        key = "astra_build",
      })

      -- 异步执行构建
      vim.fn.jobstart(cmd, {
        stdout_buffered = true,
        stderr_buffered = true,
        on_stdout = function(_, data)
          if data and #data > 0 then
            for _, line in ipairs(data) do
              if line:match("Compiling") or line:match("Finished") then
                fidget.notify(line, nil, { title = "Astra.nvim", key = "astra_build" })
              end
            end
          end
        end,
        on_stderr = function(_, data)
          if data and #data > 0 then
            for _, line in ipairs(data) do
              if line:match("error:") or line:match("warning:") then
                fidget.notify(line, vim.log.levels.ERROR, { title = "Astra.nvim", key = "astra_build" })
              end
            end
          end
        end,
        on_exit = function(_, exit_code)
          if exit_code == 0 then
            fidget.notify("✅ 构建完成！", nil, { title = "Astra.nvim", key = "astra_build" })
            vim.notify("Astra.nvim 核心程序构建成功！", vim.log.levels.INFO, { title = "Astra.nvim" })
            -- 构建成功后刷新配置
            vim.schedule(function()
              if vim.cmd.AstraRefreshConfig then
                vim.cmd.AstraRefreshConfig()
              end
            end)
          else
            fidget.notify("❌ 构建失败！", vim.log.levels.ERROR, { title = "Astra.nvim", key = "astra_build" })
            vim.notify("构建失败，请检查错误信息", vim.log.levels.ERROR, { title = "Astra.nvim" })
          end
        end,
      })
    end

    -- 检查核心程序是否存在
    function astra_utils.check_core()
      return vim.fn.filereadable(astra_config.binary_path) == 1
    end

    -- 更新插件
    function astra_utils.update_plugin()
      fidget.notify("🔄 正在更新 Astra.nvim...", nil, { title = "Astra.nvim", key = "astra_update" })

      vim.fn.jobstart(string.format("cd %s && git pull origin main", astra_config.project_root), {
        on_exit = function(_, exit_code)
          if exit_code == 0 then
            fidget.notify("✅ 更新完成！", nil, { title = "Astra.nvim", key = "astra_update" })
            if astra_config.build.build_on_update then
              vim.schedule(function()
                astra_utils.build_core()
              end)
            end
          else
            fidget.notify("❌ 更新失败！", vim.log.levels.ERROR, { title = "Astra.nvim", key = "astra_update" })
          end
        end,
      })
    end

    -- 初始化插件
    function astra_utils.init()
      -- 检查核心程序
      if not astra_utils.check_core() then
        if astra_config.build.auto_build then
          vim.schedule(function()
            astra_utils.build_core()
          end)
        else
          vim.notify("Astra.nvim 核心程序不存在，请运行 :AstraBuildCore", vim.log.levels.WARN, { title = "Astra.nvim" })
        end
      end

      -- 设置 astra.nvim - 使用优化的配置
      local plugin_config = {
        -- 连接配置（现在主要依赖自动配置发现）
        host = astra_config.connection.host,
        port = astra_config.connection.port,
        username = astra_config.connection.username,
        password = astra_config.connection.password,
        private_key_path = astra_config.connection.private_key_path,
        remote_path = astra_config.connection.remote_path,
        local_path = astra_config.connection.local_path,
        
        -- 同步配置
        auto_sync = astra_config.sync.auto_sync,
        sync_on_save = astra_config.sync.sync_on_save,
        sync_interval = astra_config.sync.sync_interval,
      }

      require("astra").setup(plugin_config)

      -- 注册工具函数
      package.loaded["astra.utils"] = astra_utils

      -- 初始化后刷新配置
      vim.schedule(function()
        if vim.cmd.AstraRefreshConfig then
          vim.cmd.AstraRefreshConfig()
        end
      end)
    end

    -- 状态检查函数
    function astra_utils.check_status()
      -- 检查配置状态
      if vim.cmd.AstraStatus then
        vim.cmd.AstraStatus()
      else
        vim.notify("Astra.nvim: 插件未正确初始化", vim.log.levels.ERROR)
      end
    end

    -- 智能文件同步函数
    function astra_utils.sync_current_file()
      -- 检查当前是否有文件
      local current_file = vim.fn.expand("%:p")
      if current_file == "" or current_file:match("^/tmp/") then
        vim.notify("Astra.nvim: 没有有效的文件可以同步", vim.log.levels.WARN)
        return
      end

      -- 检查文件是否在忽略列表中
      local relative_path = vim.fn.fnamemodify(current_file, ":.")
      for _, pattern in ipairs(astra_config.sync.ignore_patterns) do
        if relative_path:match(pattern:gsub("%*", ".*")) then
          vim.notify("Astra.nvim: 文件在忽略列表中: " .. relative_path, vim.log.levels.INFO)
          return
        end
      end

      -- 上传当前文件
      if vim.cmd.AstraUploadCurrent then
        vim.notify("Astra.nvim: 正在同步文件: " .. relative_path, vim.log.levels.INFO)
        vim.cmd.AstraUploadCurrent()
      else
        vim.notify("Astra.nvim: 上传命令不可用", vim.log.levels.ERROR)
      end
    end

    -- 批量同步函数
    function astra_utils.sync_project()
      if vim.cmd.AstraSync then
        vim.notify("Astra.nvim: 正在同步项目...", vim.log.levels.INFO)
        vim.cmd("AstraSync auto")
      else
        vim.notify("Astra.nvim: 同步命令不可用", vim.log.levels.ERROR)
      end
    end

    -- 启动初始化
    vim.schedule(astra_utils.init)

    -- 创建用户命令
    vim.api.nvim_create_user_command("AstraBuildCore", astra_utils.build_core, {
      desc = "重新构建 Astra.nvim 核心程序",
    })

    vim.api.nvim_create_user_command("AstraUpdate", astra_utils.update_plugin, {
      desc = "更新 Astra.nvim 插件并重建核心",
    })

    vim.api.nvim_create_user_command("AstraCheckDeps", astra_utils.check_dependencies, {
      desc = "检查 Astra.nvim 依赖项",
    })

    vim.api.nvim_create_user_command("AstraStatusCheck", astra_utils.check_status, {
      desc = "检查 Astra.nvim 状态和配置",
    })

    vim.api.nvim_create_user_command("AstraSyncCurrent", astra_utils.sync_current_file, {
      desc = "智能同步当前文件（自动检测路径）",
    })

    vim.api.nvim_create_user_command("AstraSyncProject", astra_utils.sync_project, {
      desc = "同步整个项目",
    })

    vim.api.nvim_create_user_command("AstraVersion", function()
      if vim.cmd.AstraVersion then
        vim.cmd.AstraVersion()
      else
        vim.notify("Astra.nvim: 版本命令不可用", vim.log.levels.ERROR)
      end
    end, { desc = "显示 Astra.nvim 版本信息" })

    vim.api.nvim_create_user_command("AstraUpdateCheck", function()
      if vim.cmd.AstraCheckUpdate then
        vim.cmd.AstraCheckUpdate()
      else
        vim.notify("Astra.nvim: 更新检查命令不可用", vim.log.levels.ERROR)
      end
    end, { desc = "检查 Astra.nvim 更新" })

    -- 优化的键位映射
    local keys = {
      -- 基础操作
      { "<leader>AS", "<cmd>AstraSync auto<cr>", desc = "Astra 同步项目", mode = "n" },
      { "<leader>As", "<cmd>AstraSync auto<cr>", desc = "Astra 同步项目", mode = "n" },
      { "<leader>Au", "<cmd>AstraUploadCurrent<cr>", desc = "Astra 上传当前文件", mode = "n" },
      { "<leader>Ad", "<cmd>AstraDownload<cr>", desc = "Astra 下载文件", mode = "n" },
      
      -- 便捷操作
      { "<leader>Acs", "<cmd>AstraSyncCurrent<cr>", desc = "Astra 同步当前文件", mode = "n" },
      { "<leader>Aps", "<cmd>AstraSyncProject<cr>", desc = "Astra 同步项目", mode = "n" },
      
      -- 配置和管理
      { "<leader>Ab", "<cmd>AstraBuildCore<cr>", desc = "Astra 构建核心", mode = "n" },
      { "<leader>Ai", "<cmd>AstraInit<cr>", desc = "Astra 初始化配置", mode = "n" },
      { "<leader>Ac", "<cmd>AstraStatusCheck<cr>", desc = "Astra 检查状态", mode = "n" },
      { "<leader>Ar", "<cmd>AstraRefreshConfig<cr>", desc = "Astra 刷新配置", mode = "n" },
      { "<leader>AU", "<cmd>AstraUpdate<cr>", desc = "Astra 更新插件", mode = "n" },
      { "<leader>AD", "<cmd>AstraCheckDeps<cr>", desc = "Astra 检查依赖", mode = "n" },
      
      -- 版本和更新
      { "<leader>Av", "<cmd>AstraVersion<cr>", desc = "Astra 显示版本", mode = "n" },
      { "<leader>Auc", "<cmd>AstraUpdateCheck<cr>", desc = "Astra 检查更新", mode = "n" },
      
      -- 可视模式操作
      { "<leader>Au", ":<c-u>lua require('astra.utils').sync_current_file()<cr>", desc = "Astra 同步选中文件", mode = "v" },
    }

    for _, key in ipairs(keys) do
      vim.keymap.set(key.mode or "n", key[1], key[2], { desc = key.desc, noremap = true, silent = true })
    end

    -- 自动命令增强
    vim.api.nvim_create_autocmd("BufWritePost", {
      pattern = "*",
      callback = function()
        -- 检查是否应该自动同步
        if astra_config.sync.sync_on_save then
          local current_file = vim.fn.expand("%:p")
          local relative_path = vim.fn.fnamemodify(current_file, ":.")
          
          -- 检查是否在忽略列表中
          local should_sync = true
          for _, pattern in ipairs(astra_config.sync.ignore_patterns) do
            if relative_path:match(pattern:gsub("%*", ".*")) then
              should_sync = false
              break
            end
          end
          
          if should_sync then
            vim.schedule(function()
              astra_utils.sync_current_file()
            end)
          end
        end
      end,
      desc = "Astra: 文件保存时自动同步",
    })

    -- 定期同步
    if astra_config.sync.auto_sync then
      local timer = vim.loop.new_timer()
      timer:start(astra_config.sync.sync_interval, astra_config.sync.sync_interval, function()
        vim.schedule(function()
          if astra_config.sync.auto_sync then
            vim.notify("Astra.nvim: 执行定期同步...", vim.log.levels.DEBUG)
            astra_utils.sync_project()
          end
        end)
      end)
    end

    -- 初始化完成提示
    vim.notify("Astra.nvim: 插件初始化完成", vim.log.levels.INFO, { title = "Astra.nvim" })
    
    -- 显示使用提示
    vim.schedule(function()
      vim.notify("Astra.nvim 使用提示:", vim.log.levels.INFO, { title = "Astra.nvim" })
      vim.notify("  • <leader>As - 同步项目", vim.log.levels.INFO)
      vim.notify("  • <leader>Au - 上传当前文件", vim.log.levels.INFO)
      vim.notify("  • <leader>Acs - 智能同步当前文件", vim.log.levels.INFO)
      vim.notify("  • <leader>Ar - 刷新配置", vim.log.levels.INFO)
      vim.notify("  • <leader>Av - 显示版本信息", vim.log.levels.INFO)
      vim.notify("  • <leader>Auc - 检查更新", vim.log.levels.INFO)
    end)
  end,
}