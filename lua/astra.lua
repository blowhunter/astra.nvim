local M = {}

-- Core configuration and paths
M.core_path = vim.fn.expand("~/.local/share/nvim/lazy/astra.nvim/astra-core")
M.binary_path = vim.fn.expand("~/.local/share/nvim/lazy/astra.nvim/astra-core/target/release/astra-core")
M.config_cache = nil
M.last_config_check = 0

function M.setup(opts)
	opts = opts or {}

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
	}, opts)

	-- Initialize with automatic configuration discovery
	M:discover_configuration()

	M:initialize_commands()

	if M.config.auto_sync then
		M:start_auto_sync()
	end

	if M.config.sync_on_save then
		M:setup_autocmds()
	end
end

-- Automatic configuration discovery
function M:discover_configuration()
	local current_time = vim.loop.hrtime() / 1000000000
	
	-- Cache configuration for 30 seconds to avoid frequent checks
	if M.config_cache and (current_time - M.last_config_check) < 30 then
		return M.config_cache
	end

	local cmd = string.format("cd %s && %s config-test 2>/dev/null", self.core_path, self.binary_path)
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
	
	-- Fallback to config file check
	local cwd = vim.fn.getcwd()
	local has_config = vim.loop.fs_stat(cwd .. "/.astra-settings/settings.toml") ~= nil
		or vim.loop.fs_stat(cwd .. "/.vscode/sftp.json") ~= nil
		or vim.loop.fs_stat(cwd .. "/astra.json") ~= nil

	if not has_config then
		vim.notify("Astra: No configuration file found. Please run :AstraInit", vim.log.levels.ERROR)
		return nil
	end

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
	
	-- Calculate relative path from local_path
	local relative_path = local_file_path:gsub("^" .. config.local_path .. "/", "")
	
	-- Remove leading slash if present
	if relative_path:match("^/") then
		relative_path = relative_path:sub(2)
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
	
	-- Calculate relative path from remote_path
	local relative_path = remote_file_path:gsub("^" .. config.remote_path .. "/", "")
	
	-- Remove leading slash if present
	if relative_path:match("^/") then
		relative_path = relative_path:sub(2)
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
end

function M:init_config()
	local cmd = string.format("cd %s && %s init", self.core_path, self.binary_path)

	vim.fn.system(cmd)

	if vim.v.shell_error == 0 then
		vim.notify("Astra: Configuration initialized successfully")
		-- Refresh configuration cache after init
		M.config_cache = nil
		M.last_config_check = 0
		M:discover_configuration()
	else
		vim.notify("Astra: Failed to initialize configuration", vim.log.levels.ERROR)
	end
end

function M:sync_files(mode)
	local cmd = string.format("cd %s && %s sync --mode %s", self.core_path, self.binary_path, mode)

	vim.fn.system(cmd)

	if vim.v.shell_error == 0 then
		vim.notify("Astra: Sync completed successfully")
	else
		vim.notify("Astra: Sync failed", vim.log.levels.ERROR)
	end
end

function M:check_status()
	local cmd = string.format("cd %s && %s status", self.core_path, self.binary_path)

	local output = vim.fn.system(cmd)

	if vim.v.shell_error == 0 then
		vim.notify("Astra Status:\n" .. output)
	else
		vim.notify("Astra: Failed to check status", vim.log.levels.ERROR)
	end
end

function M:upload_file(local_path, remote_path)
	-- Ensure local_path is absolute
	if not local_path:match("^/") then
		local_path = vim.fn.fnamemodify(local_path, ":p")
	end
	
	local cmd = string.format(
		"cd %s && %s upload --local %s --remote %s",
		self.core_path,
		self.binary_path,
		local_path,
		remote_path
	)

	vim.fn.system(cmd)

	if vim.v.shell_error == 0 then
		vim.notify("Astra: File uploaded successfully\n" .. local_path .. " -> " .. remote_path)
	else
		vim.notify("Astra: Failed to upload file\n" .. local_path .. " -> " .. remote_path, vim.log.levels.ERROR)
	end
end

function M:download_file(remote_path, local_path)
	-- Ensure local_path is absolute
	if not local_path:match("^/") then
		local_path = vim.fn.fnamemodify(local_path, ":p")
	end
	
	local cmd = string.format(
		"cd %s && %s download --remote %s --local %s",
		self.core_path,
		self.binary_path,
		remote_path,
		local_path
	)

	vim.fn.system(cmd)

	if vim.v.shell_error == 0 then
		vim.notify("Astra: File downloaded successfully\n" .. remote_path .. " -> " .. local_path)
	else
		vim.notify("Astra: Failed to download file\n" .. remote_path .. " -> " .. local_path, vim.log.levels.ERROR)
	end
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
	-- Ensure file_path is absolute
	if not file_path:match("^/") then
		file_path = vim.fn.fnamemodify(file_path, ":p")
	end
	
	local remote_path = M:get_remote_path(file_path)
	if remote_path then
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

return M

