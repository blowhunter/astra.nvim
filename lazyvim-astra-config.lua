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
      static_binary_path = vim.fn.expand("~/.local/share/nvim/lazy/astra.nvim/astra-core/target/x86_64-unknown-linux-musl/release/astra-core"),

      -- 构建配置
      build = {
        auto_build = true, -- 启动时自动构建
        build_on_update = true, -- 更新后自动构建
        release_build = true, -- 使用 release 模式构建
        static_build = false, -- 使用 musl target 静态构建
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
        auto_sync = false, -- 启用自动同步
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

      -- 静态构建总是使用 release 模式
      if config.static_build then
        cmd = cmd .. " --target x86_64-unknown-linux-musl --release"
      elseif config.release_build then
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

      -- 添加调试信息
      fidget.notify("构建命令: " .. cmd, nil, { title = "Astra.nvim", key = "astra_build" })
      
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
            
            -- 验证目标文件是否正确创建
            local target_path
            if config.static_build then
              target_path = astra_config.static_binary_path
            else
              target_path = astra_config.binary_path
            end
            
            if vim.fn.filereadable(target_path) == 1 then
              local size = vim.fn.getfsize(target_path)
              fidget.notify(string.format("📦 目标文件已创建: %s (%.1fMB)", target_path, size / 1024 / 1024), nil, { title = "Astra.nvim", key = "astra_build" })
              
              vim.notify(
                "Astra.nvim 核心程序构建成功！",
                vim.log.levels.INFO,
                { title = "Astra.nvim" }
              )
              
              -- 构建成功后刷新配置
              vim.schedule(function()
                pcall(function()
                  vim.cmd.AstraRefreshConfig()
                end)
              end)
            else
              fidget.notify(
                "❌ 构建完成但目标文件未找到: " .. target_path,
                vim.log.levels.ERROR,
                { title = "Astra.nvim", key = "astra_build" }
              )
            end
          else
            fidget.notify(
              "❌ 构建失败！",
              vim.log.levels.ERROR,
              { title = "Astra.nvim", key = "astra_build" }
            )
            vim.notify(
              "构建失败，请检查错误信息",
              vim.log.levels.ERROR,
              { title = "Astra.nvim" }
            )
          end
        end,
      })
    end

    -- 检查核心程序是否存在（智能检查静态和release版本）
    function astra_utils.check_core()
      local release_exists = vim.fn.filereadable(astra_config.binary_path) == 1
      local static_exists = vim.fn.filereadable(astra_config.static_binary_path) == 1
      
      if astra_config.build.static_build then
        return static_exists or release_exists
      else
        return release_exists or static_exists
      end
    end

    -- 清理debug版本（节省空间）
    function astra_utils.cleanup_debug()
      local debug_path = astra_config.core_path .. "/target/debug/astra-core"
      if vim.fn.filereadable(debug_path) == 1 then
        vim.fn.delete(debug_path)
        fidget.notify("🧹 已清理debug版本", nil, { title = "Astra.nvim" })
      else
        fidget.notify("未找到debug版本", nil, { title = "Astra.nvim" })
      end
    end

    -- 显示构建信息
    function astra_utils.show_build_info()
      local release_exists = vim.fn.filereadable(astra_config.binary_path) == 1
      local static_exists = vim.fn.filereadable(astra_config.static_binary_path) == 1
      local debug_exists = vim.fn.filereadable(astra_config.core_path .. "/target/debug/astra-core") == 1
      
      local info = {}
      table.insert(info, "🔧 Astra.nvim 构建信息:")
      table.insert(info, string.format("  Release版本: %s", release_exists and "✅" or "❌"))
      table.insert(info, string.format("  Static版本: %s", static_exists and "✅" or "❌"))
      table.insert(info, string.format("  Debug版本: %s", debug_exists and "✅" or "❌"))
      table.insert(info, string.format("  静态构建模式: %s", astra_config.build.static_build and "启用" or "禁用"))
      table.insert(info, string.format("  Release构建模式: %s", astra_config.build.release_build and "启用" or "禁用"))
      if astra_config.build.static_build then
        table.insert(info, "  注意: 静态构建总是使用release模式")
      end
      
      for _, line in ipairs(info) do
        fidget.notify(line, nil, { title = "Astra.nvim" })
      end
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
            fidget.notify(
              "❌ 更新失败！",
              vim.log.levels.ERROR,
              { title = "Astra.nvim", key = "astra_update" }
            )
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
          vim.notify(
            "Astra.nvim 核心程序不存在，请运行 :AstraBuildCore",
            vim.log.levels.WARN,
            { title = "Astra.nvim" }
          )
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
        pcall(function()
          vim.cmd.AstraRefreshConfig()
        end)
      end)
    end

    -- 状态检查函数
    function astra_utils.check_status()
      -- 检查配置状态
      local success, err = pcall(function()
        vim.cmd.AstraStatus()
      end)
      if not success then
        vim.notify("Astra.nvim: 插件未正确初始化或无配置", vim.log.levels.ERROR)
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
      local success, err = pcall(function()
        vim.cmd.AstraUploadCurrent()
      end)
      if success then
        vim.notify("Astra.nvim: 正在同步文件: " .. relative_path, vim.log.levels.INFO)
      else
        vim.notify("Astra.nvim: 上传命令不可用或无配置", vim.log.levels.ERROR)
      end
    end

    -- 批量同步函数
    function astra_utils.sync_project()
      local success, err = pcall(function()
        vim.cmd("AstraSync auto")
      end)
      if success then
        vim.notify("Astra.nvim: 正在同步项目...", vim.log.levels.INFO)
      else
        vim.notify("Astra.nvim: 同步命令不可用或无配置", vim.log.levels.ERROR)
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

    vim.api.nvim_create_user_command("AstraCleanupDebug", astra_utils.cleanup_debug, {
      desc = "清理 Astra.nvim debug版本",
    })

    vim.api.nvim_create_user_command("AstraBuildInfo", astra_utils.show_build_info, {
      desc = "显示 Astra.nvim 构建信息",
    })

    vim.api.nvim_create_user_command("AstraSyncCurrent", astra_utils.sync_current_file, {
      desc = "智能同步当前文件（自动检测路径）",
    })

    vim.api.nvim_create_user_command("AstraSyncProject", astra_utils.sync_project, {
      desc = "同步整个项目",
    })

    vim.api.nvim_create_user_command("AstraVersion", function()
      local success, err = pcall(function()
        vim.cmd.AstraVersion()
      end)
      if not success then
        vim.notify("Astra.nvim: 版本命令不可用或无配置", vim.log.levels.ERROR)
      end
    end, { desc = "显示 Astra.nvim 版本信息" })

    vim.api.nvim_create_user_command("AstraUpdateCheck", function()
      local success, err = pcall(function()
        vim.cmd.AstraCheckUpdate()
      end)
      if not success then
        vim.notify("Astra.nvim: 更新检查命令不可用或无配置", vim.log.levels.ERROR)
      end
    end, { desc = "检查 Astra.nvim 更新" })

    -- 优化的键位映射
    local keys = {
      -- 同步操作 (As - Sync)
      { "<leader>AS", "<cmd>AstraSync auto<cr>", desc = "Astra 同步项目", mode = "n" },
      { "<leader>As", "<cmd>AstraSync auto<cr>", desc = "Astra 同步项目", mode = "n" },
      { "<leader>Ass", "<cmd>AstraSync auto<cr>", desc = "Astra 同步项目", mode = "n" },
      { "<leader>Asf", "<cmd>AstraSyncCurrent<cr>", desc = "Astra 同步当前文件", mode = "n" },
      { "<leader>Asp", "<cmd>AstraSyncProject<cr>", desc = "Astra 同步项目", mode = "n" },

      -- 上传下载操作 (Ad - Download/Upload)  
      { "<leader>Ad", "<cmd>AstraDownload<cr>", desc = "Astra 下载文件", mode = "n" },
      { "<leader>Adu", "<cmd>AstraUploadCurrent<cr>", desc = "Astra 上传当前文件", mode = "n" },
      { "<leader>Add", "<cmd>AstraDownload<cr>", desc = "Astra 下载文件", mode = "n" },

      -- 构建操作 (Ab - Build)
      { "<leader>Ab", "<cmd>AstraBuildCore<cr>", desc = "Astra 构建核心", mode = "n" },
      { "<leader>Abb", "<cmd>AstraBuildCore<cr>", desc = "Astra 构建核心", mode = "n" },
      { "<leader>Abi", "<cmd>AstraBuildInfo<cr>", desc = "Astra 构建信息", mode = "n" },
      { "<leader>Abc", "<cmd>AstraCleanupDebug<cr>", desc = "Astra 清理debug", mode = "n" },

      -- 更新操作 (AU - Update)
      { "<leader>AU", "<cmd>AstraUpdate<cr>", desc = "Astra 更新插件", mode = "n" },
      { "<leader>AUu", "<cmd>AstraUpdate<cr>", desc = "Astra 更新插件", mode = "n" },
      { "<leader>AUc", "<cmd>AstraUpdateCheck<cr>", desc = "Astra 检查更新", mode = "n" },

      -- 检查操作 (Ac - Check)
      { "<leader>Ac", "<cmd>AstraStatusCheck<cr>", desc = "Astra 检查状态", mode = "n" },
      { "<leader>Acs", "<cmd>AstraStatusCheck<cr>", desc = "Astra 检查状态", mode = "n" },
      { "<leader>Acd", "<cmd>AstraCheckDeps<cr>", desc = "Astra 检查依赖", mode = "n" },

      -- 配置操作 (Ar - Configure)
      { "<leader>Ar", "<cmd>AstraRefreshConfig<cr>", desc = "Astra 刷新配置", mode = "n" },
      { "<leader>Arc", "<cmd>AstraRefreshConfig<cr>", desc = "Astra 刷新配置", mode = "n" },
      { "<leader>Ari", "<cmd>AstraInit<cr>", desc = "Astra 初始化配置", mode = "n" },

      -- 版本操作 (Av - Version)
      { "<leader>Av", "<cmd>AstraVersion<cr>", desc = "Astra 显示版本", mode = "n" },
      { "<leader>Avv", "<cmd>AstraVersion<cr>", desc = "Astra 显示版本", mode = "n" },

      -- 可视模式操作
      {
        "<leader>Adu",
        ":<c-u>lua require('astra.utils').sync_current_file()<cr>",
        desc = "Astra 同步选中文件",
        mode = "v",
      },
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

    -- 显示简洁的使用提示
    vim.schedule(function()
      vim.notify("Astra.nvim 插件已加载完成", vim.log.levels.INFO, { title = "Astra.nvim" })
      vim.notify("使用 <leader>A 查看所有可用快捷键", vim.log.levels.INFO, { title = "Astra.nvim" })
    end)
  end,
}

