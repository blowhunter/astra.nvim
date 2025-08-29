local M = {}

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

	-- Check if configuration file exists
	local cwd = vim.fn.getcwd()
	local has_config = vim.loop.fs_stat(cwd .. "/.astra-settings/settings.toml") ~= nil
		or vim.loop.fs_stat(cwd .. "/.vscode/sftp.json") ~= nil
		or vim.loop.fs_stat(cwd .. "/astra.json") ~= nil

	if not has_config then
		vim.notify("Astra: No configuration file found. Please run :AstraInit", vim.log.levels.ERROR)
		return
	end

	if M.config.host == "" or M.config.remote_path == "" then
		vim.notify("Astra: Configuration found but host/remote_path not set in Lua setup", vim.log.levels.ERROR)
		return
	end

	M:initialize_commands()

	if M.config.auto_sync then
		M:start_auto_sync()
	end

	if M.config.sync_on_save then
		M:setup_autocmds()
	end
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
		if #args ~= 2 then
			vim.notify("Usage: AstraUpload <local_path> <remote_path>", vim.log.levels.ERROR)
			return
		end
		M:upload_file(args[1], args[2])
	end, { nargs = "*", desc = "Upload a single file" })

	vim.api.nvim_create_user_command("AstraDownload", function(opts)
		local args = vim.split(opts.args, " ", true)
		if #args ~= 2 then
			vim.notify("Usage: AstraDownload <remote_path> <local_path>", vim.log.levels.ERROR)
			return
		end
		M:download_file(args[1], args[2])
	end, { nargs = "*", desc = "Download a single file" })
end

function M:init_config()
	local cmd = string.format("cd %s && cargo run init", vim.fn.getcwd() .. "/astra-core")

	vim.fn.system(cmd)

	if vim.v.shell_error == 0 then
		vim.notify("Astra: Configuration initialized successfully")
	else
		vim.notify("Astra: Failed to initialize configuration", vim.log.levels.ERROR)
	end
end

function M:sync_files(mode)
	local cmd = string.format("cd %s && cargo run sync --mode %s", vim.fn.getcwd() .. "/astra-core", mode)

	vim.fn.system(cmd)

	if vim.v.shell_error == 0 then
		vim.notify("Astra: Sync completed successfully")
	else
		vim.notify("Astra: Sync failed", vim.log.levels.ERROR)
	end
end

function M:check_status()
	local cmd = string.format("cd %s && cargo run status", vim.fn.getcwd() .. "/astra-core")

	local output = vim.fn.system(cmd)

	if vim.v.shell_error == 0 then
		vim.notify("Astra Status:\n" .. output)
	else
		vim.notify("Astra: Failed to check status", vim.log.levels.ERROR)
	end
end

function M:upload_file(local_path, remote_path)
	local cmd = string.format(
		"cd %s && cargo run upload --local %s --remote %s",
		vim.fn.getcwd() .. "/astra-core",
		local_path,
		remote_path
	)

	vim.fn.system(cmd)

	if vim.v.shell_error == 0 then
		vim.notify("Astra: File uploaded successfully")
	else
		vim.notify("Astra: Failed to upload file", vim.log.levels.ERROR)
	end
end

function M:download_file(remote_path, local_path)
	local cmd = string.format(
		"cd %s && cargo run download --remote %s --local %s",
		vim.fn.getcwd() .. "/astra-core",
		remote_path,
		local_path
	)

	vim.fn.system(cmd)

	if vim.v.shell_error == 0 then
		vim.notify("Astra: File downloaded successfully")
	else
		vim.notify("Astra: Failed to download file", vim.log.levels.ERROR)
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
	local relative_path = vim.fn.fnamemodify(file_path, ":.")
	local remote_path = M.config.remote_path .. "/" .. relative_path

	M:upload_file(file_path, remote_path)
end

function M:stop_auto_sync()
	if M.auto_sync_timer then
		M.auto_sync_timer:close()
		M.auto_sync_timer = nil
		vim.notify("Astra: Auto sync stopped")
	end
end

return M

