local M = {}

-- Core configuration and paths
M.core_path = vim.fn.expand("~/.local/share/nvim/lazy/astra.nvim/astra-core")
M.binary_path = vim.fn.expand("~/.local/share/nvim/lazy/astra.nvim/astra-core/target/release/astra-core")
M.static_binary_path = vim.fn.expand("~/.local/share/nvim/lazy/astra.nvim/astra-core/target/x86_64-unknown-linux-musl/release/astra-core")
M.config_cache = nil
M.last_config_check = 0

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

  -- Only initialize commands and enable features if configuration is available
  if config then
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
    -- Only initialize the AstraInit command when no configuration exists
    vim.api.nvim_create_user_command("AstraInit", function()
      M:init_config()
    end, { desc = "Initialize Astra configuration" })

    -- Always make AstraConfigTest available for testing
    vim.api.nvim_create_user_command("AstraConfigTest", function()
      M:test_config()
    end, { desc = "Test configuration discovery and show detailed parsing results" })
    
    vim.notify("Astra: No configuration found. Use :AstraInit to create configuration", vim.log.levels.INFO)
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

  local binary_path = M.config.static_build and M.static_binary_path or M.binary_path
  local cmd = string.format(
    "cd %s && %s upload --local %s --remote %s",
    self.core_path,
    binary_path,
    local_path,
    remote_path
  )

  vim.notify("Astra: Uploading file in background...\n" .. local_path .. " -> " .. remote_path, vim.log.levels.INFO)

  vim.fn.jobstart(cmd, {
    stdout_buffered = true,
    stderr_buffered = true,
    on_stdout = function(_, data)
      if data and #data > 0 then
        local output = table.concat(data, "\n")
        if output:match("successfully") or output:match("completed") then
          vim.notify("Astra: File uploaded successfully\n" .. local_path .. " -> " .. remote_path, vim.log.levels.INFO)
        end
      end
    end,
    on_stderr = function(_, data)
      if data and #data > 0 then
        local error_output = table.concat(data, "\n")
        vim.notify("Astra: Upload error\n" .. error_output, vim.log.levels.ERROR)
      end
    end,
    on_exit = function(_, exit_code)
      if exit_code ~= 0 then
        vim.notify("Astra: Failed to upload file\n" .. local_path .. " -> " .. remote_path, vim.log.levels.ERROR)
      end
    end,
  })
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

  vim.notify("Astra: Downloading file in background...\n" .. remote_path .. " -> " .. local_path, vim.log.levels.INFO)

  vim.fn.jobstart(cmd, {
    stdout_buffered = true,
    stderr_buffered = true,
    on_stdout = function(_, data)
      if data and #data > 0 then
        local output = table.concat(data, "\n")
        if output:match("successfully") or output:match("completed") then
          vim.notify("Astra: File downloaded successfully\n" .. remote_path .. " -> " .. local_path, vim.log.levels.INFO)
        end
      end
    end,
    on_stderr = function(_, data)
      if data and #data > 0 then
        local error_output = table.concat(data, "\n")
        vim.notify("Astra: Download error\n" .. error_output, vim.log.levels.ERROR)
      end
    end,
    on_exit = function(_, exit_code)
      if exit_code ~= 0 then
        vim.notify("Astra: Failed to download file\n" .. remote_path .. " -> " .. local_path, vim.log.levels.ERROR)
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
    -- Debounce: avoid multiple syncs for the same file within short time
    local file_key = file_path .. ":" .. remote_path
    local current_time = vim.loop.hrtime() / 1000000000 -- Convert to seconds

    if M.sync_debounce_time and (current_time - M.sync_debounce_time) < 2 then
      return -- Skip if sync was attempted within last 2 seconds
    end

    M.sync_debounce_time = current_time
    M:upload_file(file_path, remote_path)
  else
    vim.notify("Astra: Cannot determine remote path for " .. file_path, vim.log.levels.ERROR)
  end
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
  vim.api.nvim_buf_set_lines(buf, 0, -1, result_lines, false)

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

return M

