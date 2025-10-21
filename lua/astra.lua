local M = {}

-- Core configuration and paths
M.core_path = vim.fn.expand("~/.local/share/nvim/lazy/astra.nvim/astra-core")
M.binary_path = vim.fn.expand("~/.local/share/nvim/lazy/astra.nvim/astra-core/target/release/astra-core")
M.static_binary_path = vim.fn.expand("~/.local/share/nvim/lazy/astra.nvim/astra-core/target/x86_64-unknown-linux-musl/release/astra-core")
M.config_cache = nil
M.last_config_check = 0
M.sync_queue = {}
M.sync_queue_running = false
M.last_sync_errors = {}
M.notification_history = {}
M.notification_queue = {}
M.notification_running = false

-- LazyVim风格通知管理
local notification_config = {
  max_history = 10,
  display_duration = 3000, -- 3秒显示时间
  fade_duration = 500, -- 0.5秒淡出时间
  position = "bottom_right",
}

-- 创建浮动通知窗口
local function create_floating_notification(content, level)
  level = level or vim.log.levels.INFO
  local width = math.min(60, vim.fn.strdisplaywidth(content) + 4)
  local height = 3

  -- 计算位置（右下角）
  local ui = vim.api.nvim_list_uis()[1]
  local win_width = ui.width
  local win_height = ui.height

  local col = win_width - width - 2
  local row = win_height - height - 3

  -- 创建buffer
  local buf = vim.api.nvim_create_buf(false, true)

  -- 设置buffer内容
  local lines = {
    " " .. content .. " ",
    "",
  }
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(buf, "modifiable", false)

  -- 设置高亮
  local hl_group = "AstraNotification" .. (level == vim.log.levels.ERROR and "Error" or
                                            level == vim.log.levels.WARN and "Warn" or "Info")

  -- 定义高亮组
  vim.api.nvim_set_hl(0, hl_group, {
    fg = (level == vim.log.levels.ERROR and "#ff6b6b" or
          level == vim.log.levels.WARN and "#feca57" or "#48cae4"),
    bg = "#1e1e2e",
    bold = true,
  })

  -- 设置buffer高亮
  vim.api.nvim_buf_add_highlight(buf, 0, hl_group, 0, 0, -1)

  -- 创建浮动窗口
  local win = vim.api.nvim_open_win(buf, false, {
    relative = "editor",
    width = width,
    height = height,
    col = col,
    row = row,
    style = "minimal",
    border = "rounded",
    title = " Astra.nvim ",
    title_pos = "center",
  })

  -- 设置窗口选项
  vim.api.nvim_win_set_option(win, "winhl", "Normal:Normal,FloatBorder:FloatBorder")
  vim.api.nvim_win_set_option(win, "winblend", 10)

  return win, buf
end

-- 添加通知到队列
local function add_notification_to_queue(content, level)
  table.insert(M.notification_queue, {
    content = content,
    level = level,
    timestamp = vim.loop.hrtime(),
  })

  -- 限制历史记录长度
  if #M.notification_queue > notification_config.max_history then
    table.remove(M.notification_queue, 1)
  end

  -- 如果没有正在显示的通知，立即显示
  if not M.notification_running then
    M:process_notification_queue()
  end
end

-- 处理通知队列
M.process_notification_queue = function()
  if #M.notification_queue == 0 then
    M.notification_running = false
    return
  end

  M.notification_running = true
  local notification = table.remove(M.notification_queue, 1)

  -- 显示通知
  local win, buf = create_floating_notification(notification.content, notification.level)

  -- 设置自动关闭定时器
  local close_timer = vim.loop.new_timer()
  close_timer:start(notification_config.display_duration, 0, function()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, false)
    end
    if vim.api.nvim_buf_is_valid(buf) then
      vim.api.nvim_buf_delete(buf, {force = true})
    end
    close_timer:close()

    -- 处理下一个通知
    vim.schedule(function()
      M:process_notification_queue()
    end)
  end)
end

-- 发送LazyVim风格通知
M.show_lazyvim_notification = function(content, level)
  level = level or vim.log.levels.INFO

  -- 使用LazyVim的vim.notify如果可用
  if vim.notify and vim.notify ~= print then
    vim.notify(content, level, {
      title = "Astra.nvim",
      icon = (level == vim.log.levels.ERROR and "❌" or
              level == vim.log.levels.WARN and "⚠️" or "🚀"),
      timeout = notification_config.display_duration,
    })
  else
    -- 回退到浮动窗口通知
    add_notification_to_queue(content, level)
  end
end

function M.setup(opts)
  opts = opts or {}

  -- Default configuration with all sync features disabled
  M.config = vim.tbl_extend("force", {
    host = "",
    port = 22,
    username = "",
    password = nil,
    private_key_path = nil,
    remote_path = "",
    local_path = vim.loop.cwd(),
    auto_sync = false,
    sync_on_save = false,
    sync_interval = 30000,
    static_build = false,
  }, opts)

  -- Initialize with automatic configuration discovery
  local config = M:discover_configuration()

  -- Store configuration status for command availability
  M.has_config = (config ~= nil)

  -- Check if configuration exists and is enabled
  local is_config_enabled = config and config.enabled ~= false

  -- Only initialize commands and enable features if configuration is available and enabled
  if is_config_enabled then
    M:initialize_commands()

    -- Enable sync features from configuration
    if config.auto_sync then
      M:start_auto_sync()
    end

    if config.sync_on_save then
      M:setup_autocmds()
    end

    vim.notify("Astra: Configuration loaded successfully", vim.log.levels.INFO)
  else
    -- Always initialize basic commands for configuration management
    vim.api.nvim_create_user_command("AstraInit", function()
      M:init_config()
    end, { desc = "Initialize Astra configuration" })

    -- Always make AstraConfigTest available for testing
    vim.api.nvim_create_user_command("AstraConfigTest", function()
      M:test_config()
    end, { desc = "Test configuration discovery and show detailed parsing results" })

    vim.api.nvim_create_user_command("AstraEnable", function()
      M:enable_plugin()
    end, { desc = "Enable Astra plugin" })

    -- Show plugin disabled notification
    if config and config.enabled == false then
      M:show_plugin_disabled_notification()
    else
      vim.notify("Astra: No configuration found. Use :AstraInit to create configuration", vim.log.levels.INFO)
    end
  end
end

-- Automatic configuration discovery
function M:discover_configuration()
  local current_time = vim.loop.hrtime() / 1000000000
  
  -- Cache configuration for 30 seconds to avoid frequent checks
  if M.config_cache and (current_time - M.last_config_check) < 30 then
    return M.config_cache
  end

  -- Check if any configuration file exists
  local cwd = vim.fn.getcwd()
  local toml_path = cwd .. "/.astra-settings/settings.toml"
  local vscode_path = cwd .. "/.vscode/sftp.json"
  local json_path = cwd .. "/astra.json"
  
  local has_toml = vim.loop.fs_stat(toml_path) ~= nil
  local has_vscode = vim.loop.fs_stat(vscode_path) ~= nil
  local has_json = vim.loop.fs_stat(json_path) ~= nil
  local has_config = has_toml or has_vscode or has_json

  if not has_config then
    M.config_cache = nil
    M.last_config_check = current_time
    return nil
  end

  -- Smart binary path selection - try both static and release builds
  local binary_path = nil
  local static_binary_exists = vim.loop.fs_stat(M.static_binary_path) ~= nil
  local release_binary_exists = vim.loop.fs_stat(M.binary_path) ~= nil

  if M.config.static_build and static_binary_exists then
    binary_path = M.static_binary_path
  elseif release_binary_exists then
    binary_path = M.binary_path
  elseif static_binary_exists then
    -- Fallback to static binary if release doesn't exist
    binary_path = M.static_binary_path
  else
    vim.notify("Astra: No binary file found. Please build the project first.", vim.log.levels.ERROR)
    M.config_cache = nil
    M.last_config_check = current_time
    return nil
  end
  
  local cmd = string.format("cd %s && %s config-test 2>/dev/null", self.core_path, binary_path)
  local output = vim.fn.system(cmd)
  
  if vim.v.shell_error == 0 then
    -- Parse the config-test output
    local config_info = self:parse_config_output(output)
    if config_info then
      M.config_cache = config_info
      M.last_config_check = current_time
      
      -- Update runtime config with discovered settings
      M.config.host = config_info.host
      M.config.port = config_info.port
      M.config.username = config_info.username
      M.config.password = config_info.password
      M.config.private_key_path = config_info.private_key_path
      M.config.remote_path = config_info.remote_path
      M.config.local_path = config_info.local_path
      
      return config_info
    end
  end
  
  -- No valid configuration found
  M.config_cache = nil
  M.last_config_check = current_time
  return nil
end

-- Parse config-test output to extract configuration
function M:parse_config_output(output)
  local config = {}
  
  -- Extract host
  config.host = output:match("Host: ([^\n]+)") or ""
  -- Extract port
  local port_str = output:match("Port: ([^\n]+)") or "22"
  config.port = tonumber(port_str) or 22
  -- Extract username
  config.username = output:match("Username: ([^\n]+)") or ""
  -- Extract password
  config.password = output:match("Password: ([^\n]+)")
  if config.password == "None" then config.password = nil end
  -- Extract private key path
  config.private_key_path = output:match("Private key path: ([^\n]+)")
  if config.private_key_path == "None" then config.private_key_path = nil end
  -- Extract remote path
  config.remote_path = output:match("Remote path: ([^\n]+)") or ""
  -- Extract local path
  config.local_path = output:match("Local path: ([^\n]+)") or vim.loop.cwd()
  -- Extract sync options
  config.auto_sync = output:match("Auto sync: ([^\n]+)") == "true"
  config.sync_on_save = output:match("Sync on save: ([^\n]+)") == "true"
  local sync_interval_str = output:match("Sync interval: ([^\n]+)") or "30000"
  config.sync_interval = tonumber(sync_interval_str) or 30000

  -- Extract enabled status
  local enabled_str = output:match("Enabled: ([^\n]+)")
  if enabled_str then
    config.enabled = enabled_str == "true"
  else
    config.enabled = true -- Default to enabled if not specified
  end

  return config
end

-- Get current file information for intelligent path handling
function M:get_current_file_info()
  local file_path = vim.fn.expand("%:p")
  local file_name = vim.fn.expand("%:t")
  local relative_path = vim.fn.fnamemodify(file_path, ":.")
  
  return {
    absolute_path = file_path,
    relative_path = relative_path,
    file_name = file_name,
    directory = vim.fn.expand("%:p:h")
  }
end

-- Intelligent remote path generation
function M:get_remote_path(local_file_path)
  local config = self:discover_configuration()
  if not config then
    vim.notify("Astra: Cannot determine configuration", vim.log.levels.ERROR)
    return nil
  end
  
  -- If local_file_path is relative, make it absolute
  if not local_file_path:match("^/") then
    local_file_path = vim.fn.fnamemodify(local_file_path, ":p")
  end
  
  -- Normalize paths for comparison
  local normalized_local_path = config.local_path:gsub("/+$", "")
  local normalized_file_path = local_file_path:gsub("/+$", "")
  
  -- Calculate relative path from local_path
  local relative_path = ""
  
  -- Check if the file is directly under the local_path
  if normalized_file_path:match("^" .. normalized_local_path .. "/") then
    relative_path = normalized_file_path:gsub("^" .. normalized_local_path .. "/", "")
  elseif normalized_file_path == normalized_local_path then
    -- File is exactly the local_path directory itself
    relative_path = ""
  else
    -- File is not under local_path, try to find common parent directory
    -- This handles cases where the file is in a subdirectory of the project
    local file_parts = {}
    for part in string.gmatch(normalized_file_path, "([^/]+)") do
      table.insert(file_parts, part)
    end
    
    local local_parts = {}
    for part in string.gmatch(normalized_local_path, "([^/]+)") do
      table.insert(local_parts, part)
    end
    
    -- Find common prefix
    local common_count = 0
    for i = 1, math.min(#file_parts, #local_parts) do
      if file_parts[i] == local_parts[i] then
        common_count = i
      else
        break
      end
    end
    
    if common_count > 0 then
      -- Build relative path from common parent
      relative_path = table.concat(file_parts, "/", common_count + 1)
    else
      -- No common parent, use filename only as fallback
      relative_path = vim.fn.fnamemodify(normalized_file_path, ":t")
    end
  end
  
  -- Remove leading slash if present
  if relative_path:match("^/") then
    relative_path = relative_path:sub(2)
  end
  
  -- If relative_path is empty, use a default name
  if relative_path == "" then
    relative_path = vim.fn.fnamemodify(normalized_file_path, ":t")
    if relative_path == "" then
      relative_path = "file"
    end
  end
  
  return config.remote_path .. "/" .. relative_path
end

-- Intelligent local path generation
function M:get_local_path(remote_file_path)
  local config = self:discover_configuration()
  if not config then
    vim.notify("Astra: Cannot determine configuration", vim.log.levels.ERROR)
    return nil
  end
  
  -- Normalize paths for comparison
  local normalized_remote_path = config.remote_path:gsub("/+$", "")
  local normalized_file_path = remote_file_path:gsub("/+$", "")
  
  -- Calculate relative path from remote_path
  local relative_path = ""
  
  -- Check if the file is directly under the remote_path
  if normalized_file_path:match("^" .. normalized_remote_path .. "/") then
    relative_path = normalized_file_path:gsub("^" .. normalized_remote_path .. "/", "")
  elseif normalized_file_path == normalized_remote_path then
    -- File is exactly the remote_path directory itself
    relative_path = ""
  else
    -- File is not under remote_path, try to find common parent directory
    -- This handles cases where the file is in a subdirectory of the remote project
    local file_parts = {}
    for part in string.gmatch(normalized_file_path, "([^/]+)") do
      table.insert(file_parts, part)
    end
    
    local remote_parts = {}
    for part in string.gmatch(normalized_remote_path, "([^/]+)") do
      table.insert(remote_parts, part)
    end
    
    -- Find common prefix
    local common_count = 0
    for i = 1, math.min(#file_parts, #remote_parts) do
      if file_parts[i] == remote_parts[i] then
        common_count = i
      else
        break
      end
    end
    
    if common_count > 0 then
      -- Build relative path from common parent
      relative_path = table.concat(file_parts, "/", common_count + 1)
    else
      -- No common parent, use filename only as fallback
      relative_path = vim.fn.fnamemodify(normalized_file_path, ":t")
    end
  end
  
  -- Remove leading slash if present
  if relative_path:match("^/") then
    relative_path = relative_path:sub(2)
  end
  
  -- If relative_path is empty, use a default name
  if relative_path == "" then
    relative_path = vim.fn.fnamemodify(normalized_file_path, ":t")
    if relative_path == "" then
      relative_path = "file"
    end
  end
  
  return config.local_path .. "/" .. relative_path
end

function M:initialize_commands()
  vim.api.nvim_create_user_command("AstraInit", function()
    M:init_config()
  end, { desc = "Initialize Astra configuration" })

  vim.api.nvim_create_user_command("AstraSync", function(opts)
    local mode = opts.args or "upload"
    M:sync_files(mode)
  end, { nargs = "?", desc = "Synchronize files" })

  vim.api.nvim_create_user_command("AstraStatus", function()
    M:check_status()
  end, { desc = "Check sync status" })

  vim.api.nvim_create_user_command("AstraUpload", function(opts)
    local args = vim.split(opts.args, " ", true)
    
    -- Auto-detect file paths if no arguments provided
    if #args == 0 then
      local file_info = M:get_current_file_info()
      if file_info and file_info.absolute_path then
        local remote_path = M:get_remote_path(file_info.absolute_path)
        if remote_path then
          M:upload_file(file_info.absolute_path, remote_path)
        else
          vim.notify("Astra: Cannot determine remote path for current file", vim.log.levels.ERROR)
        end
      else
        vim.notify("Astra: No current file to upload", vim.log.levels.ERROR)
      end
      return
    end
    
    -- Handle single argument (local file only, auto-generate remote path)
    if #args == 1 then
      local local_path = args[1]
      local remote_path = M:get_remote_path(local_path)
      if remote_path then
        M:upload_file(local_path, remote_path)
      else
        vim.notify("Astra: Cannot determine remote path for " .. local_path, vim.log.levels.ERROR)
      end
      return
    end
    
    -- Handle two arguments (explicit paths)
    if #args == 2 then
      M:upload_file(args[1], args[2])
    else
      vim.notify("Usage: AstraUpload [local_path] [remote_path]\nIf no arguments provided, uses current file", vim.log.levels.ERROR)
    end
  end, { nargs = "*", desc = "Upload file (auto-detects paths if not specified)" })

  vim.api.nvim_create_user_command("AstraDownload", function(opts)
    local args = vim.split(opts.args, " ", true)
    
    -- Auto-detect file paths if no arguments provided
    if #args == 0 then
      vim.notify("Astra: Please specify remote file path to download", vim.log.levels.ERROR)
      return
    end
    
    -- Handle single argument (remote file only, auto-generate local path)
    if #args == 1 then
      local remote_path = args[1]
      local local_path = M:get_local_path(remote_path)
      if local_path then
        M:download_file(remote_path, local_path)
      else
        vim.notify("Astra: Cannot determine local path for " .. remote_path, vim.log.levels.ERROR)
      end
      return
    end
    
    -- Handle two arguments (explicit paths)
    if #args == 2 then
      M:download_file(args[1], args[2])
    else
      vim.notify("Usage: AstraDownload <remote_path> [local_path]\nIf local_path not specified, auto-generates based on config", vim.log.levels.ERROR)
    end
  end, { nargs = "*", desc = "Download file (auto-generates local path if not specified)" })

  -- Add convenient single-key commands for current file
  vim.api.nvim_create_user_command("AstraUploadCurrent", function()
    local file_info = M:get_current_file_info()
    if file_info and file_info.absolute_path then
      local remote_path = M:get_remote_path(file_info.absolute_path)
      if remote_path then
        M:upload_file(file_info.absolute_path, remote_path)
      else
        vim.notify("Astra: Cannot determine remote path for current file", vim.log.levels.ERROR)
      end
    else
      vim.notify("Astra: No current file to upload", vim.log.levels.ERROR)
    end
  end, { desc = "Upload current file with auto-detected remote path" })

  vim.api.nvim_create_user_command("AstraRefreshConfig", function()
    M.config_cache = nil
    M.last_config_check = 0
    local config = M:discover_configuration()
    if config then
      vim.notify("Astra: Configuration refreshed successfully", vim.log.levels.INFO)
    else
      vim.notify("Astra: Failed to refresh configuration", vim.log.levels.ERROR)
    end
  end, { desc = "Refresh cached configuration" })

  vim.api.nvim_create_user_command("AstraVersion", function()
    M:show_version()
  end, { desc = "Show Astra.nvim version information" })

  vim.api.nvim_create_user_command("AstraCheckUpdate", function()
    M:check_for_updates()
  end, { desc = "Check for Astra.nvim updates" })

  vim.api.nvim_create_user_command("AstraConfigTest", function()
    M:test_config()
  end, { desc = "Test configuration discovery and show detailed parsing results" })

  vim.api.nvim_create_user_command("AstraConfigInfo", function()
    M:show_config_info()
  end, { desc = "Show current loaded configuration information" })

  vim.api.nvim_create_user_command("AstraInfo", function()
    M:show_config_info()
  end, { desc = "Show current loaded configuration information (alias)" })

  vim.api.nvim_create_user_command("AstraSyncStatus", function()
    M:show_sync_status()
  end, { desc = "Show sync queue status and error history" })

  vim.api.nvim_create_user_command("AstraClearQueue", function()
    M:clear_sync_queue()
  end, { desc = "Clear pending sync uploads" })

  vim.api.nvim_create_user_command("AstraTestNotification", function()
    M:test_notifications()
  end, { desc = "Test LazyVim-style notification system" })
end

function M:init_config()
  local binary_path = M.config.static_build and M.static_binary_path or M.binary_path
  local cmd = string.format("cd %s && %s init", self.core_path, binary_path)

  vim.notify("Astra: Initializing configuration...", vim.log.levels.INFO)

  vim.fn.jobstart(cmd, {
    stdout_buffered = true,
    stderr_buffered = true,
    on_stdout = function(_, data)
      if data and #data > 0 then
        local output = table.concat(data, "\n")
        if output:match("Configuration initialized") then
          vim.notify("Astra: Configuration initialized successfully")

          -- Reload the plugin with new configuration
          vim.notify("Astra: Reloading plugin with new configuration...", vim.log.levels.INFO)

          -- Clear existing configuration cache
          M.config_cache = nil
          M.last_config_check = 0

          -- Clean up existing features
          if M.auto_sync_timer then
            M.auto_sync_timer:close()
            M.auto_sync_timer = nil
          end

          -- Re-run setup with existing options (delay to ensure file is written)
          vim.defer_fn(function()
            M.setup(M.config)
          end, 1000)
        end
      end
    end,
    on_stderr = function(_, data)
      if data and #data > 0 then
        local error_output = table.concat(data, "\n")
        vim.notify("Astra: Configuration error\n" .. error_output, vim.log.levels.ERROR)
      end
    end,
    on_exit = function(_, exit_code)
      if exit_code ~= 0 then
        vim.notify("Astra: Failed to initialize configuration", vim.log.levels.ERROR)
      end
    end,
  })
end

function M:sync_files(mode)
  local config = self:discover_configuration()
  if not config then
    vim.notify("Astra: No configuration found. Please run :AstraInit to create configuration", vim.log.levels.ERROR)
    return
  end

  local binary_path = M.config.static_build and M.static_binary_path or M.binary_path
  local cmd = string.format("cd %s && %s sync --mode %s", self.core_path, binary_path, mode)

  vim.notify("Astra: Starting sync operation in background...", vim.log.levels.INFO)

  vim.fn.jobstart(cmd, {
    stdout_buffered = true,
    stderr_buffered = true,
    on_stdout = function(_, data)
      if data and #data > 0 then
        local output = table.concat(data, "\n")
        -- Parse sync result from JSON output
        local success = self:parse_sync_result(output)
        if success then
          vim.notify("Astra: Sync completed successfully", vim.log.levels.INFO)
        else
          vim.notify("Astra: Sync completed with some issues", vim.log.levels.WARN)
        end
      end
    end,
    on_stderr = function(_, data)
      if data and #data > 0 then
        local error_output = table.concat(data, "\n")
        vim.notify("Astra: Sync error\n" .. error_output, vim.log.levels.ERROR)
      end
    end,
    on_exit = function(_, exit_code)
      if exit_code ~= 0 then
        vim.notify("Astra: Sync failed with exit code: " .. exit_code, vim.log.levels.ERROR)
      end
    end,
  })
end

function M:check_status()
  local config = self:discover_configuration()
  if not config then
    vim.notify("Astra: No configuration found. Please run :AstraInit to create configuration", vim.log.levels.ERROR)
    return
  end
  
  local binary_path = M.config.static_build and M.static_binary_path or M.binary_path
  local cmd = string.format("cd %s && %s status", self.core_path, binary_path)

  local output = vim.fn.system(cmd)

  if vim.v.shell_error == 0 then
    vim.notify("Astra Status:\n" .. output)
  else
    vim.notify("Astra: Failed to check status", vim.log.levels.ERROR)
  end
end

function M:upload_file(local_path, remote_path)
  local config = self:discover_configuration()
  if not config then
    vim.notify("Astra: No configuration found. Please run :AstraInit to create configuration", vim.log.levels.ERROR)
    return
  end

  -- Ensure local_path is absolute
  if not local_path:match("^/") then
    local_path = vim.fn.fnamemodify(local_path, ":p")
  end

  -- Create a unique job ID for this upload
  local job_id = local_path .. ":" .. remote_path
  local current_time = vim.loop.hrtime() / 1000000000

  -- Check if this file had recent errors (implement exponential backoff)
  local error_info = M.last_sync_errors[job_id]
  if error_info then
    local time_since_error = current_time - error_info.last_error_time
    local backoff_delay = math.min(300, math.exp(error_info.error_count) * 2) -- Max 5 minutes

    if time_since_error < backoff_delay then
      local remaining_wait = math.ceil(backoff_delay - time_since_error)
      vim.notify(string.format("Astra: Upload delayed due to recent errors. Retrying in %d seconds...", remaining_wait), vim.log.levels.WARN)
      return
    end
  end

  local binary_path = M.config.static_build and M.static_binary_path or M.binary_path
  local cmd = string.format(
    "timeout 30s cd %s && %s upload --local %s --remote %s",
    self.core_path,
    binary_path,
    local_path,
    remote_path
  )

  -- 使用LazyVim风格通知开始上传
  M.show_lazyvim_notification("🚀 Uploading: " .. vim.fn.fnamemodify(local_path, ":t"), vim.log.levels.INFO)

  local job_handle = vim.fn.jobstart(cmd, {
    stdout_buffered = true,
    stderr_buffered = true,
    on_stdout = function(_, data)
      if data and #data > 0 then
        local output = table.concat(data, "\n")
        if output:match("successfully") or output:match("completed") then
          -- 使用LazyVim风格通知成功上传
          M.show_lazyvim_notification("✅ Uploaded: " .. vim.fn.fnamemodify(local_path, ":t"), vim.log.levels.INFO)
          -- Clear error history on success
          M.last_sync_errors[job_id] = nil
        end
      end
    end,
    on_stderr = function(_, data)
      if data and #data > 0 then
        local error_output = table.concat(data, "\n")

        -- Classify error types
        local is_timeout = error_output:match("timeout") or error_output:match("Timed out")
        local is_connection_error = error_output:match("connection refused") or error_output:match("network is unreachable") or error_output:match("no route to host")
        local is_auth_error = error_output:match("authentication failed") or error_output:match("permission denied")

        -- Update error tracking
        if not M.last_sync_errors[job_id] then
          M.last_sync_errors[job_id] = { error_count = 0, last_error_time = 0 }
        end
        M.last_sync_errors[job_id].error_count = M.last_sync_errors[job_id].error_count + 1
        M.last_sync_errors[job_id].last_error_time = current_time

        -- Provide user-friendly error messages
        local error_msg = "Astra: Upload error"
        if is_timeout then
          error_msg = "Astra: Upload timeout - server may be unreachable or slow to respond"
        elseif is_connection_error then
          error_msg = "Astra: Connection failed - server may be down or network issues"
        elseif is_auth_error then
          error_msg = "Astra: Authentication failed - check your credentials"
        end

        -- 使用LazyVim风格通知上传错误
        M.show_lazyvim_notification("❌ Upload failed: " .. vim.fn.fnamemodify(local_path, ":t"), vim.log.levels.ERROR)
      end
    end,
    on_exit = function(job_id, exit_code, event_type)
      if exit_code ~= 0 then
        -- Handle specific exit codes
        local error_msg = "Astra: Failed to upload file\n" .. local_path .. " -> " .. remote_path
        if exit_code == 124 then -- timeout exit code
          error_msg = "Astra: Upload timed out after 30 seconds\n" .. local_path .. " -> " .. remote_path
        elseif exit_code == 255 then -- network error
          error_msg = "Astra: Network error during upload\n" .. local_path .. " -> " .. remote_path
        end

        -- 使用LazyVim风格通知上传失败
        M.show_lazyvim_notification("❌ Upload failed: " .. vim.fn.fnamemodify(local_path, ":t"), vim.log.levels.ERROR)

        -- Update error tracking for backoff
        if not M.last_sync_errors[job_id] then
          M.last_sync_errors[job_id] = { error_count = 1, last_error_time = current_time }
        else
          M.last_sync_errors[job_id].error_count = M.last_sync_errors[job_id].error_count + 1
          M.last_sync_errors[job_id].last_error_time = current_time
        end
      end
    end,
  })

  -- Store job handle for potential cancellation
  return job_handle
end

function M:download_file(remote_path, local_path)
  local config = self:discover_configuration()
  if not config then
    vim.notify("Astra: No configuration found. Please run :AstraInit to create configuration", vim.log.levels.ERROR)
    return
  end

  -- Ensure local_path is absolute
  if not local_path:match("^/") then
    local_path = vim.fn.fnamemodify(local_path, ":p")
  end

  local binary_path = M.config.static_build and M.static_binary_path or M.binary_path
  local cmd = string.format(
    "cd %s && %s download --remote %s --local %s",
    self.core_path,
    binary_path,
    remote_path,
    local_path
  )

  -- 使用LazyVim风格通知开始下载
  M.show_lazyvim_notification("📥 Downloading: " .. vim.fn.fnamemodify(remote_path, ":t"), vim.log.levels.INFO)

  vim.fn.jobstart(cmd, {
    stdout_buffered = true,
    stderr_buffered = true,
    on_stdout = function(_, data)
      if data and #data > 0 then
        local output = table.concat(data, "\n")
        if output:match("successfully") or output:match("completed") then
          -- 使用LazyVim风格通知成功下载
          M.show_lazyvim_notification("✅ Downloaded: " .. vim.fn.fnamemodify(remote_path, ":t"), vim.log.levels.INFO)
        end
      end
    end,
    on_stderr = function(_, data)
      if data and #data > 0 then
        local error_output = table.concat(data, "\n")
        -- 使用LazyVim风格通知下载错误
        M.show_lazyvim_notification("❌ Download failed: " .. vim.fn.fnamemodify(remote_path, ":t"), vim.log.levels.ERROR)
      end
    end,
    on_exit = function(_, exit_code)
      if exit_code ~= 0 then
        -- 使用LazyVim风格通知下载失败
        M.show_lazyvim_notification("❌ Download failed: " .. vim.fn.fnamemodify(remote_path, ":t"), vim.log.levels.ERROR)
      end
    end,
  })
end

function M:start_auto_sync()
  local timer = vim.loop.new_timer()
  timer:start(0, M.config.sync_interval, function()
    vim.schedule(function()
      M:sync_files("auto")
    end)
  end)

  M.auto_sync_timer = timer
  vim.notify("Astra: Auto sync started")
end

function M:setup_autocmds()
  if not M.has_config then
    return
  end
  
  vim.api.nvim_create_autocmd("BufWritePost", {
    pattern = "*",
    callback = function()
      local file_path = vim.fn.expand("%:p")
      M:sync_single_file(file_path)
    end,
    desc = "Sync file on save",
  })

  vim.notify("Astra: Sync on save enabled")
end

function M:sync_single_file(file_path)
  local config = self:discover_configuration()
  if not config then
    vim.notify("Astra: No configuration found. Please run :AstraInit to create configuration", vim.log.levels.ERROR)
    return
  end

  -- Ensure file_path is absolute
  if not file_path:match("^/") then
    file_path = vim.fn.fnamemodify(file_path, ":p")
  end

  local remote_path = M:get_remote_path(file_path)
  if remote_path then
    -- Enhanced debounce with file-specific tracking
    local file_key = file_path .. ":" .. remote_path
    local current_time = vim.loop.hrtime() / 1000000000 -- Convert to seconds

    -- Check if this specific file was recently synced
    local last_sync_time = M.sync_debounce_times and M.sync_debounce_times[file_key]
    if last_sync_time and (current_time - last_sync_time) < 2 then
      return -- Skip if this specific file was synced within last 2 seconds
    end

    -- Initialize debounce tracking if needed
    if not M.sync_debounce_times then
      M.sync_debounce_times = {}
    end
    M.sync_debounce_times[file_key] = current_time

    -- Add to sync queue with priority
    local sync_item = {
      file_path = file_path,
      remote_path = remote_path,
      timestamp = current_time,
      file_key = file_key
    }

    table.insert(M.sync_queue, sync_item)

    -- Process queue if not already running
    if not M.sync_queue_running then
      M:process_sync_queue()
    end
  else
    vim.notify("Astra: Cannot determine remote path for " .. file_path, vim.log.levels.ERROR)
  end
end

-- Process sync queue with concurrency control
function M:process_sync_queue()
  if M.sync_queue_running or #M.sync_queue == 0 then
    return
  end

  M.sync_queue_running = true

  -- Process queue items one by one
  local function process_next()
    if #M.sync_queue == 0 then
      M.sync_queue_running = false
      return
    end

    local sync_item = table.remove(M.sync_queue, 1)
    local file_key = sync_item.file_key

    -- Check if we have recent errors for this file
    local error_info = M.last_sync_errors[file_key]
    local current_time = vim.loop.hrtime() / 1000000000

    if error_info then
      local time_since_error = current_time - error_info.last_error_time
      local backoff_delay = math.min(300, math.exp(error_info.error_count) * 2) -- Max 5 minutes

      if time_since_error < backoff_delay then
        -- Skip this item and process next
        vim.defer_fn(process_next, 100) -- Small delay before next item
        return
      end
    end

    -- Perform the upload
    M:upload_file(sync_item.file_path, sync_item.remote_path)

    -- Wait a bit before processing next item to avoid overwhelming the server
    vim.defer_fn(process_next, 500) -- 500ms delay between uploads
  end

  -- Start processing
  process_next()
end

-- Clear sync queue (useful for stopping all pending uploads)
function M:clear_sync_queue()
  M.sync_queue = {}
  M.sync_queue_running = false
  vim.notify("Astra: Sync queue cleared", vim.log.levels.INFO)
end

function M:stop_auto_sync()
  if M.auto_sync_timer then
    M.auto_sync_timer:close()
    M.auto_sync_timer = nil
    vim.notify("Astra: Auto sync stopped")
  end
end

function M:show_version()
  local binary_path = M.config.static_build and M.static_binary_path or M.binary_path
  local cmd = string.format("cd %s && %s version", self.core_path, binary_path)
  
  local output = vim.fn.system(cmd)
  
  if vim.v.shell_error == 0 then
    -- Parse and display version information
    local version_info = self:parse_version_output(output)
    if version_info then
      vim.notify("Astra.nvim Version Information:\n" .. version_info, vim.log.levels.INFO, { title = "Astra.nvim" })
    else
      vim.notify("Astra: Version information\n" .. output, vim.log.levels.INFO, { title = "Astra.nvim" })
    end
  else
    vim.notify("Astra: Failed to get version information", vim.log.levels.ERROR)
  end
end

function M:check_for_updates()
  local binary_path = M.config.static_build and M.static_binary_path or M.binary_path
  local cmd = string.format("cd %s && %s check-update", self.core_path, binary_path)
  
  vim.notify("Astra: Checking for updates...", vim.log.levels.INFO)
  
  -- Run update check in background
  vim.fn.jobstart(cmd, {
    stdout_buffered = true,
    stderr_buffered = true,
    on_stdout = function(_, data)
      if data and #data > 0 then
        local output = table.concat(data, "\n")
        vim.notify("Astra Update Check:\n" .. output, vim.log.levels.INFO, { title = "Astra.nvim" })
      end
    end,
    on_stderr = function(_, data)
      if data and #data > 0 then
        local error_output = table.concat(data, "\n")
        vim.notify("Astra: Update check error\n" .. error_output, vim.log.levels.ERROR)
      end
    end,
    on_exit = function(_, exit_code)
      if exit_code ~= 0 then
        vim.notify("Astra: Update check failed", vim.log.levels.ERROR)
      end
    end,
  })
end

function M:parse_sync_result(output)
  -- Parse sync result from JSON or text output
  local lines = vim.split(output, "\n")
  for _, line in ipairs(lines) do
    -- Look for success indicators in output
    if line:match('"success"%s*:%s*true') or line:match("successfully") then
      return true
    end
    -- Look for failure indicators
    if line:match('"success"%s*:%s*false') or line:match("failed") or line:match("error") then
      return false
    end
  end
  -- If no clear success/failure indicator, assume success
  return true
end

function M:test_config()
  local binary_path = M.config.static_build and M.static_binary_path or M.binary_path
  local cmd = string.format("cd %s && %s config-test", self.core_path, binary_path)

  vim.notify("Astra: Testing configuration discovery...", vim.log.levels.INFO)

  -- Run config test in background to get detailed results
  vim.fn.jobstart(cmd, {
    stdout_buffered = true,
    stderr_buffered = true,
    on_stdout = function(_, data)
      if data and #data > 0 then
        local output = table.concat(data, "\n")
        M:display_config_test_result(output)
      end
    end,
    on_stderr = function(_, data)
      if data and #data > 0 then
        local error_output = table.concat(data, "\n")
        vim.notify("Astra: Configuration test error\n" .. error_output, vim.log.levels.ERROR)
      end
    end,
    on_exit = function(_, exit_code)
      if exit_code ~= 0 then
        vim.notify("Astra: Configuration test failed with exit code: " .. exit_code, vim.log.levels.ERROR)
      end
    end,
  })
end

function M:display_config_test_result(output)
  -- Parse and display the config-test output in a user-friendly format
  local lines = vim.split(output, "\n")
  local result_lines = {}

  -- Add header
  table.insert(result_lines, "🔧 Astra Configuration Test Results")
  table.insert(result_lines, "")

  -- Extract key information from output
  local config_info = {}
  local has_config = false

  for _, line in ipairs(lines) do
    -- Check for configuration loaded success
    if line:match("✅.*Configuration loaded successfully") then
      has_config = true
      table.insert(result_lines, line)
    end

    -- Extract configuration details
    local host = line:match("Host: ([^\n]+)")
    if host then config_info.host = host end

    local port = line:match("Port: ([^\n]+)")
    if port then config_info.port = port end

    local username = line:match("Username: ([^\n]+)")
    if username then config_info.username = username end

    local remote_path = line:match("Remote path: ([^\n]+)")
    if remote_path then config_info.remote_path = remote_path end

    local local_path = line:match("Local path: ([^\n]+)")
    if local_path then config_info.local_path = local_path end

    local password = line:match("Password: ([^\n]+)")
    if password then config_info.password = password end

    local private_key_path = line:match("Private key path: ([^\n]+)")
    if private_key_path then config_info.private_key_path = private_key_path end

    -- Check for project root information
    if line:match("Project root found:") then
      table.insert(result_lines, "")
      table.insert(result_lines, line)
    end

    -- Check for explicit config path
    if line:match("Using explicit config path:") then
      table.insert(result_lines, "")
      table.insert(result_lines, line)
    end

    -- Check for automatic discovery
    if line:match("Using automatic config discovery") then
      table.insert(result_lines, "")
      table.insert(result_lines, line)
    end
  end

  -- If configuration was found, add detailed information
  if has_config then
    table.insert(result_lines, "")
    table.insert(result_lines, "📋 Configuration Details:")

    -- Display basic connection info
    if config_info.host then
      table.insert(result_lines, string.format("  Host: %s", config_info.host))
    end
    if config_info.port then
      table.insert(result_lines, string.format("  Port: %s", config_info.port))
    end
    if config_info.username then
      table.insert(result_lines, string.format("  Username: %s", config_info.username))
    end

    -- Display authentication info
    table.insert(result_lines, "  Authentication:")
    if config_info.password and config_info.password ~= "None" then
      table.insert(result_lines, "    Type: Password")
      table.insert(result_lines, "    Status: ✓ Configured")
    elseif config_info.private_key_path and config_info.private_key_path ~= "None" then
      table.insert(result_lines, "    Type: Private Key")
      table.insert(result_lines, string.format("    Path: %s", config_info.private_key_path))
      table.insert(result_lines, "    Status: ✓ Configured")
    else
      table.insert(result_lines, "    Type: Not configured")
      table.insert(result_lines, "    Status: ⚠️  Missing authentication")
    end

    -- Display paths
    if config_info.remote_path then
      table.insert(result_lines, string.format("  Remote Path: %s", config_info.remote_path))
    end
    if config_info.local_path then
      table.insert(result_lines, string.format("  Local Path: %s", config_info.local_path))
    end

    -- Add status indicators
    table.insert(result_lines, "")
    table.insert(result_lines, "✅ Configuration: Valid and ready to use")

  else
    table.insert(result_lines, "")
    table.insert(result_lines, "❌ No valid configuration found")
    table.insert(result_lines, "")
    table.insert(result_lines, "💡 Suggested actions:")
    table.insert(result_lines, "  1. Run :AstraInit to create a new configuration")
    table.insert(result_lines, "  2. Check if you have any of these files:")
    table.insert(result_lines, "     - .astra-settings/settings.toml")
    table.insert(result_lines, "     - .vscode/sftp.json")
    table.insert(result_lines, "     - astra.json")
  end

  -- Display result in a floating window
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, result_lines)

  -- Set up a floating window
  local width = math.min(80, vim.fn.winwidth(0) - 10)
  local height = math.min(#result_lines, vim.fn.winheight(0) - 10)
  local win = vim.api.nvim_open_win(0, true, buf, {
    relative = "editor",
    width = width,
    height = height,
    col = math.floor((vim.fn.winwidth(0) - width) / 2),
    row = math.floor((vim.fn.winheight(0) - height) / 2),
    border = "rounded",
    title = " Astra Configuration Test",
    title_pos = "center",
  })

  -- Set up syntax highlighting if possible
  vim.api.nvim_win_set_option(win, "wrap", false)
  vim.api.nvim_win_set_option(win, "cursorline", true)

  -- Set up key mappings for the floating window
  vim.api.nvim_buf_set_keymap(buf, "n", "q", "<cmd>close<CR>", { noremap = true, silent = true })
  vim.api.nvim_buf_set_keymap(buf, "n", "<Esc>", "<cmd>close<CR>", { noremap = true, silent = true })

  -- Make the buffer modifiable for potential copying
  vim.api.nvim_buf_set_option(buf, "modifiable", true)
  vim.api.nvim_buf_set_option(buf, "readonly", false)
end

function M:parse_version_output(output)
  -- Parse version output for better display
  local lines = vim.split(output, "\n")
  local result = {}

  for _, line in ipairs(lines) do
    if line:match("^Version:") or line:match("^Build Date:") or line:match("^Rust Version:") then
      table.insert(result, line)
    end
  end

  return #result > 0 and table.concat(result, "\n") or nil
end

-- Enable the plugin by setting enabled = true in configuration
function M:enable_plugin()
  local config = self:discover_configuration()
  if not config then
    vim.notify("Astra: No configuration found. Please run :AstraInit to create configuration", vim.log.levels.ERROR)
    return
  end

  -- For now, provide instructions on how to enable the plugin
  -- In a future version, this could automatically modify the config file
  local message = table.concat({
    "To enable Astra.nvim plugin, please edit your configuration file:",
    "",
    "For TOML configuration (.astra-settings/settings.toml):",
    "  enabled = true",
    "",
    "For JSON configuration (astra.json):",
    "  \"enabled\": true,",
    "",
    "After modifying the configuration, restart Neovim or run :AstraRefreshConfig"
  }, "\n")

  -- Show the message in a floating window
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(message, "\n"))

  local width = math.min(60, vim.fn.winwidth(0) - 10)
  local height = #vim.split(message, "\n") + 2
  local win = vim.api.nvim_open_win(0, true, buf, {
    relative = "editor",
    width = width,
    height = height,
    col = math.floor((vim.fn.winwidth(0) - width) / 2),
    row = math.floor((vim.fn.winheight(0) - height) / 2),
    border = "rounded",
    title = " Enable Astra.nvim Plugin",
    title_pos = "center",
  })

  vim.api.nvim_win_set_option(win, "wrap", false)
  vim.api.nvim_buf_set_keymap(buf, "n", "q", "<cmd>close<CR>", { noremap = true, silent = true })
  vim.api.nvim_buf_set_keymap(buf, "n", "<Esc>", "<cmd>close<CR>", { noremap = true, silent = true })
  vim.api.nvim_buf_set_option(buf, "modifiable", false)
  vim.api.nvim_buf_set_option(buf, "readonly", true)
end

-- Show plugin disabled notification (only shown once per Neovim session)
function M:show_plugin_disabled_notification()
  -- Check if we've already shown this notification in this session
  if vim.g.astra_disabled_shown then
    return
  end

  vim.g.astra_disabled_shown = true

  local message = table.concat({
    "⚠️  Astra.nvim 插件已禁用",
    "",
    "插件已配置但被禁用。如需启用，请编辑配置文件设置 enabled = true",
    "或运行 :AstraEnable 查看详细说明",
    "",
    "如需创建新配置，请运行 :AstraInit"
  }, "\n")

  vim.schedule(function()
    vim.notify(message, vim.log.levels.WARN, {
      title = "Astra.nvim",
      timeout = 10000, -- Show for 10 seconds
    })
  end)
end

-- Show current loaded configuration information
function M:show_config_info()
  local config = self:discover_configuration()
  local cwd = vim.fn.getcwd()

  -- Check for configuration files
  local toml_path = cwd .. "/.astra-settings/settings.toml"
  local vscode_path = cwd .. "/.vscode/sftp.json"
  local json_path = cwd .. "/astra.json"

  local has_toml = vim.loop.fs_stat(toml_path) ~= nil
  local has_vscode = vim.loop.fs_stat(vscode_path) ~= nil
  local has_json = vim.loop.fs_stat(json_path) ~= nil

  local config_info = {}

  -- Header
  table.insert(config_info, "📋 Astra.nvim Configuration Information")
  table.insert(config_info, string.rep("─", 50))
  table.insert(config_info, "")

  -- Configuration file information
  table.insert(config_info, "📁 Configuration Files:")
  if has_toml then
    table.insert(config_info, string.format("  ✓ TOML: .astra-settings/settings.toml"))
  end
  if has_json then
    table.insert(config_info, string.format("  ✓ JSON: astra.json"))
  end
  if has_vscode then
    table.insert(config_info, string.format("  ✓ VSCode: .vscode/sftp.json"))
  end
  if not (has_toml or has_json or has_vscode) then
    table.insert(config_info, "  ❌ No configuration files found")
  end
  table.insert(config_info, "")

  if config then
    -- Plugin status
    table.insert(config_info, "🔌 Plugin Status:")
    local status_icon = config.enabled and "✅ Enabled" or "❌ Disabled"
    local status_color = config.enabled and "Success" or "Error"
    table.insert(config_info, string.format("  Status: %s", status_icon))
    table.insert(config_info, string.format("  Commands: %s", config.enabled and "Available" or "Disabled"))
    table.insert(config_info, "")

    -- Connection information
    table.insert(config_info, "🌐 Connection Information:")
    table.insert(config_info, string.format("  Host: %s", config.host or "Not configured"))
    table.insert(config_info, string.format("  Port: %d", config.port or 22))
    table.insert(config_info, string.format("  Username: %s", config.username or "Not configured"))
    table.insert(config_info, "")

    -- Authentication
    table.insert(config_info, "🔐 Authentication:")
    if config.password then
      table.insert(config_info, "  Type: Password")
      table.insert(config_info, "  Status: ✓ Configured")
    elseif config.private_key_path then
      table.insert(config_info, "  Type: Private Key")
      table.insert(config_info, string.format("  Path: %s", config.private_key_path))
      table.insert(config_info, "  Status: ✓ Configured")
    else
      table.insert(config_info, "  Type: Not configured")
      table.insert(config_info, "  Status: ⚠️  Missing authentication")
    end
    table.insert(config_info, "")

    -- Path information
    table.insert(config_info, "📂 Path Information:")
    table.insert(config_info, string.format("  Remote: %s", config.remote_path or "Not configured"))
    table.insert(config_info, string.format("  Local:  %s", config.local_path or vim.fn.getcwd()))
    table.insert(config_info, "")

    -- Sync settings (if available)
    if config.auto_sync ~= nil or config.sync_on_save ~= nil then
      table.insert(config_info, "🔄 Sync Settings:")
      if config.auto_sync ~= nil then
        local auto_sync_icon = config.auto_sync and "✅" or "❌"
        table.insert(config_info, string.format("  Auto Sync: %s %s", auto_sync_icon, config.auto_sync and "Enabled" or "Disabled"))
      end
      if config.sync_on_save ~= nil then
        local sync_on_save_icon = config.sync_on_save and "✅" or "❌"
        table.insert(config_info, string.format("  Sync on Save: %s %s", sync_on_save_icon, config.sync_on_save and "Enabled" or "Disabled"))
      end
      if config.sync_interval then
        table.insert(config_info, string.format("  Sync Interval: %d seconds", config.sync_interval / 1000))
      end
      table.insert(config_info, "")
    end

    -- Available commands
    table.insert(config_info, "⚡ Available Commands:")
    table.insert(config_info, "  :AstraSync [mode]     - Synchronize files")
    table.insert(config_info, "  :AstraStatus          - Check sync status")
    table.insert(config_info, "  :AstraUpload [paths]  - Upload files")
    table.insert(config_info, "  :AstraDownload [paths] - Download files")
    table.insert(config_info, "  :AstraUploadCurrent   - Upload current file")
    table.insert(config_info, "  :AstraRefreshConfig   - Refresh configuration")
    table.insert(config_info, "  :AstraConfigTest      - Test configuration")
    table.insert(config_info, "  :AstraConfigInfo      - Show this information")
    table.insert(config_info, "  :AstraSyncStatus      - Show sync queue status")
    table.insert(config_info, "  :AstraClearQueue      - Clear pending uploads")
    table.insert(config_info, "")

    -- Overall status
    table.insert(config_info, string.rep("─", 50))
    if config.enabled then
      table.insert(config_info, "✅ Configuration: Ready to use")
    else
      table.insert(config_info, "⚠️  Configuration: Plugin is disabled")
      table.insert(config_info, "")
      table.insert(config_info, "To enable the plugin:")
      table.insert(config_info, "  1. Edit your configuration file")
      table.insert(config_info, "  2. Set 'enabled = true'")
      table.insert(config_info, "  3. Run ':AstraRefreshConfig' or restart Neovim")
    end

  else
    -- No configuration found
    table.insert(config_info, "❌ Configuration Status: No valid configuration found")
    table.insert(config_info, "")
    table.insert(config_info, "💡 Getting Started:")
    table.insert(config_info, "  1. Run ':AstraInit' to create a new configuration")
    table.insert(config_info, "  2. Or create one of these files manually:")
    table.insert(config_info, "     • .astra-settings/settings.toml (recommended)")
    table.insert(config_info, "     • astra.json (legacy format)")
    table.insert(config_info, "     • .vscode/sftp.json (VSCode format)")
    table.insert(config_info, "")
    table.insert(config_info, "📖 For help, see: ':help astra-nvim'")
  end

  -- Display in a floating window
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, config_info)

  -- Set up syntax highlighting
  vim.api.nvim_buf_set_option(buf, "filetype", "text")

  -- Calculate window dimensions
  local width = math.min(80, vim.fn.winwidth(0) - 10)
  local height = math.min(#config_info + 2, vim.fn.winheight(0) - 5)

  local win = vim.api.nvim_open_win(0, true, buf, {
    relative = "editor",
    width = width,
    height = height,
    col = math.floor((vim.fn.winwidth(0) - width) / 2),
    row = math.floor((vim.fn.winheight(0) - height) / 2),
    border = "rounded",
    title = " Astra Configuration Info",
    title_pos = "center",
    style = "minimal",
  })

  -- Configure window options
  vim.api.nvim_win_set_option(win, "wrap", false)
  vim.api.nvim_win_set_option(win, "cursorline", true)
  vim.api.nvim_win_set_option(win, "number", false)
  vim.api.nvim_win_set_option(win, "relativenumber", false)

  -- Set up key mappings
  local opts = { noremap = true, silent = true }
  vim.api.nvim_buf_set_keymap(buf, "n", "q", "<cmd>close<CR>", opts)
  vim.api.nvim_buf_set_keymap(buf, "n", "<Esc>", "<cmd>close<CR>", opts)
  vim.api.nvim_buf_set_keymap(buf, "n", "<C-c>", "<cmd>close<CR>", opts)

  -- Make buffer read-only
  vim.api.nvim_buf_set_option(buf, "modifiable", false)
  vim.api.nvim_buf_set_option(buf, "readonly", true)

  -- Highlight important sections
  vim.schedule(function()
    -- Highlight headers
    local ns_id = vim.api.nvim_create_namespace("astra_config_info")

    for i, line in ipairs(config_info) do
      local line_idx = i - 1

      -- Highlight headers (lines with emoji and :)
      if line:match("^🔌") or line:match("^🌐") or line:match("^🔐") or line:match("^📂") or line:match("^🔄") or line:match("^⚡") or line:match("^📁") then
        vim.api.nvim_buf_add_highlight(buf, ns_id, "Title", line_idx, 0, -1)
      end

      -- Highlight success states
      if line:match("✅") then
        vim.api.nvim_buf_add_highlight(buf, ns_id, "String", line_idx, 0, -1)
      end

      -- Highlight error states
      if line:match("❌") then
        vim.api.nvim_buf_add_highlight(buf, ns_id, "Error", line_idx, 0, -1)
      end

      -- Highlight warning states
      if line:match("⚠️") then
        vim.api.nvim_buf_add_highlight(buf, ns_id, "WarningMsg", line_idx, 0, -1)
      end
    end
  end)
end

-- Show sync queue status and error history
function M:show_sync_status()
  local status_info = {}

  -- Header
  table.insert(status_info, "🔄 Astra.nvim Sync Status")
  table.insert(status_info, string.rep("─", 50))
  table.insert(status_info, "")

  -- Queue status
  table.insert(status_info, "📋 Sync Queue Status:")
  table.insert(status_info, string.format("  Queue running: %s", M.sync_queue_running and "✅ Yes" or "❌ No"))
  table.insert(status_info, string.format("  Pending items: %d", #M.sync_queue))
  table.insert(status_info, "")

  -- Show pending items if any
  if #M.sync_queue > 0 then
    table.insert(status_info, "📝 Pending Uploads:")
    for i, item in ipairs(M.sync_queue) do
      local file_name = vim.fn.fnamemodify(item.file_path, ":t")
      local wait_time = math.floor(vim.loop.hrtime() / 1000000000 - item.timestamp)
      table.insert(status_info, string.format("  %d. %s (waiting %ds)", i, file_name, wait_time))
    end
    table.insert(status_info, "")
  end

  -- Error history
  local error_count = 0
  for _ in pairs(M.last_sync_errors) do
    error_count = error_count + 1
  end

  table.insert(status_info, "🚨 Error History:")
  table.insert(status_info, string.format("  Files with errors: %d", error_count))

  if error_count > 0 then
    table.insert(status_info, "")
    table.insert(status_info, "Recent Errors:")

    local current_time = vim.loop.hrtime() / 1000000000
    local sorted_errors = {}

    -- Sort errors by time
    for file_key, error_info in pairs(M.last_sync_errors) do
      table.insert(sorted_errors, {
        file_key = file_key,
        error_count = error_info.error_count,
        last_error_time = error_info.last_error_time,
        time_ago = math.floor(current_time - error_info.last_error_time)
      })
    end

    table.sort(sorted_errors, function(a, b)
      return a.last_error_time > b.last_error_time
    end)

    -- Show top 10 most recent errors
    for i, error_data in ipairs(sorted_errors) do
      if i > 10 then break end

      local file_name = vim.fn.fnamemodify(error_data.file_key, ":t")
      local status = "⚠️"
      if error_data.time_ago < 60 then
        status = "🔴" -- Recent error (within 1 minute)
      elseif error_data.time_ago < 300 then
        status = "🟠" -- Recent error (within 5 minutes)
      else
        status = "🟡" -- Older error
      end

      local backoff_info = ""
      if error_data.error_count > 1 then
        local backoff_delay = math.min(300, math.exp(error_data.error_count) * 2)
        local next_retry = math.max(0, backoff_delay - (current_time - error_data.last_error_time))
        if next_retry > 0 then
          backoff_info = string.format(" (retry in %ds)", math.ceil(next_retry))
        end
      end

      table.insert(status_info, string.format("  %s %s (%d errors, %s ago)%s",
        status, file_name, error_data.error_count,
        error_data.time_ago < 60 and math.floor(error_data.time_ago) .. "s" or
        math.floor(error_data.time_ago / 60) .. "m",
        backoff_info))
    end
  else
    table.insert(status_info, "  ✅ No recent errors")
  end

  table.insert(status_info, "")

  -- Configuration status
  local config = self:discover_configuration()
  if config then
    table.insert(status_info, "🔌 Plugin Status:")
    table.insert(status_info, string.format("  Enabled: %s", config.enabled and "✅ Yes" or "❌ No"))
    table.insert(status_info, string.format("  Sync on Save: %s", config.sync_on_save and "✅ Yes" or "❌ No"))
  else
    table.insert(status_info, "❌ No configuration found")
  end

  table.insert(status_info, "")

  -- Available actions
  table.insert(status_info, "⚡ Available Actions:")
  table.insert(status_info, "  :AstraClearQueue - Clear pending uploads")
  table.insert(status_info, "  :AstraConfigInfo - Show configuration")
  table.insert(status_info, "  :AstraSyncStatus - Refresh this status")
  table.insert(status_info, "")

  -- Display in floating window
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, status_info)

  -- Set up syntax highlighting
  vim.api.nvim_buf_set_option(buf, "filetype", "text")

  -- Calculate window dimensions
  local width = math.min(80, vim.fn.winwidth(0) - 10)
  local height = math.min(#status_info + 2, vim.fn.winheight(0) - 5)

  local win = vim.api.nvim_open_win(0, true, buf, {
    relative = "editor",
    width = width,
    height = height,
    col = math.floor((vim.fn.winwidth(0) - width) / 2),
    row = math.floor((vim.fn.winheight(0) - height) / 2),
    border = "rounded",
    title = " Astra Sync Status",
    title_pos = "center",
    style = "minimal",
  })

  -- Configure window options
  vim.api.nvim_win_set_option(win, "wrap", false)
  vim.api.nvim_win_set_option(win, "cursorline", true)
  vim.api.nvim_win_set_option(win, "number", false)
  vim.api.nvim_win_set_option(win, "relativenumber", false)

  -- Set up key mappings
  local opts = { noremap = true, silent = true }
  vim.api.nvim_buf_set_keymap(buf, "n", "q", "<cmd>close<CR>", opts)
  vim.api.nvim_buf_set_keymap(buf, "n", "<Esc>", "<cmd>close<CR>", opts)
  vim.api.nvim_buf_set_keymap(buf, "n", "<C-c>", "<cmd>close<CR>", opts)
  vim.api.nvim_buf_set_keymap(buf, "n", "r", "<cmd>AstraSyncStatus<CR>", opts) -- Refresh
  vim.api.nvim_buf_set_keymap(buf, "n", "c", "<cmd>AstraClearQueue<CR>", opts) -- Clear queue

  -- Make buffer read-only
  vim.api.nvim_buf_set_option(buf, "modifiable", false)
  vim.api.nvim_buf_set_option(buf, "readonly", true)

  -- Highlight important sections
  vim.schedule(function()
    local ns_id = vim.api.nvim_create_namespace("astra_sync_status")

    for i, line in ipairs(status_info) do
      local line_idx = i - 1

      -- Highlight headers
      if line:match("^🔄") or line:match("^📋") or line:match("^📝") or line:match("^🚨") or line:match("^⚡") then
        vim.api.nvim_buf_add_highlight(buf, ns_id, "Title", line_idx, 0, -1)
      end

      -- Highlight status indicators
      if line:match("✅") then
        vim.api.nvim_buf_add_highlight(buf, ns_id, "String", line_idx, 0, -1)
      elseif line:match("❌") then
        vim.api.nvim_buf_add_highlight(buf, ns_id, "Error", line_idx, 0, -1)
      elseif line:match("🔴") or line:match("🟠") then
        vim.api.nvim_buf_add_highlight(buf, ns_id, "WarningMsg", line_idx, 0, -1)
      end
    end
  end)
end

-- 测试LazyVim风格通知系统
M.test_notifications = function()
  local test_messages = {
    { content = "🚀 Starting upload test", level = vim.log.levels.INFO },
    { content = "📥 Downloading file example.txt", level = vim.log.levels.INFO },
    { content = "✅ Upload completed successfully", level = vim.log.levels.INFO },
    { content = "⚠️  Connection slow warning", level = vim.log.levels.WARN },
    { content = "❌ Upload failed example", level = vim.log.levels.ERROR },
  }

  -- 添加延迟来展示滚动效果
  local function show_next_notification(index)
    if index > #test_messages then
      vim.notify("Notification test completed!", vim.log.levels.INFO, { title = "Astra.nvim" })
      return
    end

    local message = test_messages[index]
    M.show_lazyvim_notification(message.content, message.level)

    -- 1秒后显示下一个通知
    vim.defer_fn(function()
      show_next_notification(index + 1)
    end, 1000)
  end

  -- 开始测试
  vim.notify("Starting LazyVim-style notification test...", vim.log.levels.INFO, { title = "Astra.nvim" })
  show_next_notification(1)
end

return M

