-- Astra.nvim UI 和通知模块
-- 负责用户界面和通知显示

local M = {}

-- 通知配置
M.notification_config = {
  max_history = 10,
  display_duration = 3000,
  fade_duration = 500,
  position = "bottom_right",
  max_width = 60,
  border_chars = {"┌", "─", "┐", "│", "┘", "─", "└", "│"}
}

-- 通知历史
M.notification_history = {}

-- 通知队列
M.notification_queue = {}
M.notification_running = false

-- 创建浮动通知窗口
function M.create_floating_notification(content, level)
  level = level or vim.log.levels.INFO

  -- 计算窗口尺寸
  local dims = M.calculate_notification_dimensions(content, level)
  local win_config = {
    relative = "editor",
    width = dims.width,
    height = dims.height,
    col = dims.col,
    row = dims.row,
    border = "rounded",
    style = "minimal",
    title = M.get_notification_title(level),
    title_pos = "center"
  }

  -- 创建缓冲区
  local buf = vim.api.nvim_create_buf(false, true)

  -- 设置内容
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, content)
  vim.api.nvim_buf_set_option(buf, "modifiable", false)

  -- 高亮设置
  M.setup_notification_highlight(buf, level)

  -- 创建窗口
  local win = vim.api.nvim_open_win(buf, false, win_config)

  -- 设置窗口选项
  vim.api.nvim_win_set_option(win, "winhl", "Normal:Normal")
  vim.api.nvim_win_set_option(win, "wrap", true)

  -- 自动关闭
  local close_timer = vim.defer_fn(function()
    M.fade_out_notification(win, buf)
  end, M.notification_config.display_duration)

  -- 关闭时清理
  vim.api.nvim_create_autocmd({"WinClosed", "BufLeave"}, {
    buffer = buf,
    once = true,
    callback = function()
      pcall(vim.fn.timer_stop, close_timer)
      pcall(vim.api.nvim_buf_delete, buf, {force = true})
    end
  })

  return win, buf
end

-- 计算通知窗口尺寸
function M.calculate_notification_dimensions(content, level)
  local max_width = M.notification_config.max_width
  local min_width = 20

  -- 计算内容行长度
  local max_line_length = 0
  for _, line in ipairs(content) do
    local line_length = vim.fn.strdisplaywidth(line)
    max_line_length = math.max(max_line_length, line_length)
  end

  local width = math.max(min_width, math.min(max_width, max_line_length + 4)) -- 加 4 为边框留空间
  local height = #content + 2 -- 加 2 为边框留空间

  -- 计算位置
  local ui = vim.api.nvim_list_uis()[1]
  local screen_width = ui.width
  local screen_height = ui.height

  local position = M.notification_config.position
  local col, row

  if position == "bottom_right" then
    col = screen_width - width - 2
    row = screen_height - height - 2
  elseif position == "bottom_left" then
    col = 2
    row = screen_height - height - 2
  elseif position == "top_right" then
    col = screen_width - width - 2
    row = 2
  else -- bottom_right (default)
    col = screen_width - width - 2
    row = screen_height - height - 2
  end

  return {
    width = width,
    height = height,
    col = math.max(0, col),
    row = math.max(0, row)
  }
end

-- 获取通知标题
function M.get_notification_title(level)
  local titles = {
    [vim.log.levels.DEBUG] = "🔍 Debug",
    [vim.log.levels.INFO] = "ℹ️  Info",
    [vim.log.levels.WARN] = "⚠️  Warning",
    [vim.log.levels.ERROR] = "❌ Error"
  }
  return titles[level] or "📢 Notification"
end

-- 设置通知高亮
function M.setup_notification_highlight(buf, level)
  local highlights = {
    [vim.log.levels.DEBUG] = "AstraDebug",
    [vim.log.levels.INFO] = "AstraInfo",
    [vim.log.levels.WARN] = "AstraWarn",
    [vim.log.levels.ERROR] = "AstraError"
  }

  local highlight = highlights[level] or "AstraInfo"

  -- 定义高亮组（如果不存在）
  if not vim.fn.hl_exists(highlight) then
    local colors = {
      AstraDebug = {bg = "#1e1e1e", fg = "#8c8c8c"},
      AstraInfo = {bg = "#1e3a5f", fg = "#7dd3fc"},
      AstraWarn = {bg = "#5f4a1e", fg = "#fbbf24"},
      AstraError = {bg = "#5f1e1e", fg = "#f87171"}
    }

    local color = colors[highlight] or colors.AstraInfo
    vim.api.nvim_set_hl(0, highlight, color)
  end

  vim.api.nvim_win_set_option(vim.fn.bufwinid(buf), "winhl", "Normal:" .. highlight)
end

-- 淡出通知
function M.fade_out_notification(win, buf)
  if vim.api.nvim_win_is_valid(win) then
    vim.api.nvim_win_close(win, true)
  end
  if vim.api.nvim_buf_is_valid(buf) then
    vim.api.nvim_buf_delete(buf, {force = true})
  end
end

-- 智能通知（去重和队列）
function M.smart_notify(message, level, opts)
  opts = opts or {}

  -- 检查重复通知
  if not opts.force and M.is_duplicate_notification(message, level) then
    return
  end

  -- 添加到历史记录
  M.add_to_history(message, level)

  -- 添加到队列
  table.insert(M.notification_queue, {
    message = message,
    level = level,
    opts = opts
  })

  -- 处理队列
  if not M.notification_running then
    M.process_notification_queue()
  end
end

-- 检查重复通知
function M.is_duplicate_notification(message, level)
  local recent_threshold = 5 -- 5秒内的重复通知
  local current_time = os.time()

  for i = #M.notification_history, 1, math.max(1, #M.notification_history - 3) do
    local notification = M.notification_history[i]
    if current_time - notification.time < recent_threshold and
       notification.message == message and
       notification.level == level then
      return true
    end
  end

  return false
end

-- 添加到历史记录
function M.add_to_history(message, level)
  table.insert(M.notification_history, {
    message = message,
    level = level,
    time = os.time()
  })

  -- 限制历史记录数量
  if #M.notification_history > M.notification_config.max_history then
    table.remove(M.notification_history, 1)
  end
end

-- 处理通知队列
function M.process_notification_queue()
  if #M.notification_queue == 0 then
    M.notification_running = false
    return
  end

  M.notification_running = true

  local notification = table.remove(M.notification_queue, 1)
  local content = vim.split(notification.message, "\n")

  -- 创建浮动通知
  M.create_floating_notification(content, notification.level)

  -- 延迟处理下一个通知
  vim.defer_fn(function()
    M.process_notification_queue()
  end, M.notification_config.display_duration + 500)
end

-- 显示帮助信息
function M.show_help(functionality_level)
  local help_content = M.generate_help_content(functionality_level)

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, help_content)
  vim.api.nvim_buf_set_option(buf, "modifiable", false)
  vim.api.nvim_buf_set_option(buf, "filetype", "text")

  -- 设置窗口配置
  local ui = vim.api.nvim_list_uis()[1]
  local width = math.min(80, ui.width - 10)
  local height = math.min(#help_content, ui.height - 10)

  local win_config = {
    relative = "editor",
    width = width,
    height = height,
    col = math.floor((ui.width - width) / 2),
    row = math.floor((ui.height - height) / 2),
    border = "rounded",
    style = "minimal",
    title = "Astra.nvim Help",
    title_pos = "center"
  }

  local win = vim.api.nvim_open_win(buf, true, win_config)

  -- 设置窗口选项
  vim.api.nvim_win_set_option(win, "wrap", true)
  vim.api.nvim_win_set_option(win, "cursorline", true)

  -- 关闭时清理
  vim.api.nvim_create_autocmd("WinClosed", {
    pattern = tostring(win),
    once = true,
    callback = function()
      if vim.api.nvim_buf_is_valid(buf) then
        vim.api.nvim_buf_delete(buf, {force = true})
      end
    end
  })

  -- 设置快捷键关闭
  vim.api.nvim_buf_set_keymap(buf, "n", "q", "", {
    callback = function()
      vim.api.nvim_win_close(win, true)
    end,
    noremap = true,
    silent = true
  })

  vim.api.nvim_buf_set_keymap(buf, "n", "<Esc>", "", {
    callback = function()
      vim.api.nvim_win_close(win, true)
    end,
    noremap = true,
    silent = true
  })
end

-- 生成帮助内容
function M.generate_help_content(functionality_level)
  local content = {
    "🚀 Astra.nvim - Neovim SFTP/SSH Plugin",
    "",
    "Current Status: " .. functionality_level,
    "",
    "📋 Available Commands:",
    ""
  }

  if functionality_level == "basic" then
    vim.list_extend(content, {
      "  :AstraBuild        - Build the core binary",
      "  :AstraInstall      - Install precompiled binary",
      "  :AstraInit         - Initialize project configuration",
      "  :AstraQuickSetup   - Quick configuration wizard",
      "  :AstraVersion      - Show version",
      "  :AstraHelp         - Show this help message",
      "",
      "🔧 Basic Key Mappings:",
      "  <leader>Ab         - Build core binary",
      "  <leader>Ac         - Initialize config",
      "  <leader>Aq         - Quick setup",
      "  <leader>Av         - Show version",
      ""
    })
  elseif functionality_level == "full" then
    vim.list_extend(content, {
      "  :AstraUpload       - Upload current file",
      "  :AstraDownload     - Download current file",
      "  :AstraSync         - Sync current file",
      "  :AstraStatus       - Check status",
      "  :AstraVersion      - Show version",
      "  :AstraInit         - Initialize project configuration",
      "  :AstraQuickSetup   - Quick configuration wizard",
      "  :AstraBuild        - Build the core binary",
      "  :AstraHelp         - Show this help message",
      "",
      "🔧 Core File Operations:",
      "  <leader>Au         - Upload current file",
      "  <leader>Ad         - Download current file",
      "  <leader>As         - Sync current file",
      "  <leader>Ai         - Check status",
      "",
      "🔧 Configuration Management:",
      "  <leader>Ab         - Build core",
      "  <leader>Ac         - Initialize config",
      "  <leader>Aq         - Quick setup",
      "",
      "🔧 System Commands:",
      "  <leader>Ah         - Show help",
      "  <leader>Av         - Show version",
      "",
      "💡 Tips:",
      "  - Use :AstraInit to create project configuration",
      "  - All commands are dynamically enabled based on your setup",
      "  - Configuration files: .astra.toml, .vscode/sftp.json",
      ""
    })
  end

  vim.list_extend(content, {
    "📖 Configuration:",
    "  1. Project config: .astra.toml (recommended)",
    "  2. VSCode config: .vscode/sftp.json",
    "  3. Legacy config: astra.json",
    "",
    "🌐 Project: https://github.com/blowhunter/astra.nvim",
    "📚 Documentation: Check README.md for detailed usage",
    "",
    "Press 'q' or <Esc> to close this window"
  })

  return content
end

-- 显示状态信息
function M.show_status(state)
  local status_content = {
    "🔍 Astra.nvim Status",
    "",
    "Plugin Status: " .. state.functionality_level,
    "Binary Available: " .. (state.binary_available and "✅ Yes" or "❌ No"),
    "Config Available: " .. (state.config_available and "✅ Yes" or "❌ No"),
    "Initialized: " .. (state.initialized and "✅ Yes" or "❌ No"),
    ""
  }

  if state.binary_available then
    local Binary = require("astra.core.binary")
    local binary_status = Binary.validate()
    if binary_status.available then
      vim.list_extend(status_content, {
        "Binary Info:",
        "  Path: " .. binary_status.path,
        "  Version: " .. (binary_status.version or "unknown"),
        "  Type: " .. binary_status.type,
        ""
      })
    end
  end

  if state.config_available then
    local Config = require("astra.core.config")
    local config_status = Config.validate_project_config()
    if config_status.available then
      vim.list_extend(status_content, {
        "Config Info:",
        "  Path: " .. config_status.path,
        "  Format: " .. config_status.format,
        ""
      })
    end
  end

  vim.list_extend(status_content, {
    "Next Steps:",
    ""
  })

  if not state.binary_available then
    vim.list_extend(status_content, {
      "  1. Run :AstraBuild to compile the core binary",
      "  2. Or run :AstraInstall to download precompiled binary",
      ""
    })
  end

  if state.binary_available and not state.config_available then
    vim.list_extend(status_content, {
      "  1. Run :AstraInit to create project configuration",
      "  2. Or run :AstraQuickSetup for interactive setup",
      ""
    })
  end

  if state.functionality_level == "full" then
    vim.list_extend(status_content, {
      "  ✅ Astra is ready to use!",
      "  - Use <leader>Au to upload files",
      "  - Use <leader>As to sync files",
      "  - Use :AstraHelp for more information",
      ""
    })
  end

  -- 显示浮动窗口
  M.create_floating_notification(status_content, vim.log.levels.INFO)
end

return M