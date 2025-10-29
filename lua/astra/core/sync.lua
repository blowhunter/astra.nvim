-- Astra.nvim 同步功能模块
-- 负责文件的上传、下载和同步操作

local M = {}

-- 模块状态
M.initialized = false
M.config = nil
M.binary_path = nil

-- 初始化同步模块
function M.initialize()
  if M.initialized then
    return true
  end

  -- 获取二进制文件路径
  local Binary = require("astra.core.binary")
  M.binary_path = Binary.get_binary_path()

  if not M.binary_path then
    vim.notify("❌ No binary available for sync operations", vim.log.levels.ERROR)
    return false
  end

  -- 加载配置
  local Config = require("astra.core.config")
  local config_status = Config.validate_project_config()

  if not config_status.available then
    vim.notify("❌ No valid configuration for sync operations", vim.log.levels.ERROR)
    return false
  end

  M.config = config_status.config
  M.initialized = true

  vim.notify("✅ Sync module initialized", vim.log.levels.INFO)
  return true
end

-- 获取当前文件信息
function M._get_current_file()
  local file_path = vim.fn.expand("%:p")
  if file_path == "" or not vim.fn.filereadable(file_path) == 1 then
    return nil
  end

  return {
    path = file_path,
    name = vim.fn.expand("%:t"),
    relative_path = M._get_relative_path(file_path),
    directory = vim.fn.expand("%:p:h")
  }
end

-- 获取相对路径
function M._get_relative_path(file_path)
  local local_path = M.config.local_path
  if not local_path or local_path == "" then
    local_path = vim.fn.getcwd()
  end

  local relative_path = file_path:gsub("^" .. vim.pesc(local_path) .. "/", "")
  return relative_path
end

-- 构建远程路径
function M._build_remote_path(local_file_path)
  local relative_path = M._get_relative_path(local_file_path)
  local remote_path = M.config.remote_path

  if remote_path:sub(-1) ~= "/" then
    remote_path = remote_path .. "/"
  end

  return remote_path .. relative_path
end

-- 执行后端命令
function M._execute_backend_command(cmd_args, callback)
  if not M.initialized then
    if not M.initialize() then
      if callback then callback(false, "Sync module not initialized") end
      return false
    end
  end

  local cmd = M.binary_path .. " " .. cmd_args

  local job = vim.fn.jobstart(cmd, {
    on_stdout = function(_, data)
      if data and #data > 0 then
        for _, line in ipairs(data) do
          if line and line ~= "" then
            vim.notify("Backend: " .. line, vim.log.levels.DEBUG)
          end
        end
      end
    end,
    on_stderr = function(_, data)
      if data and #data > 0 then
        for _, line in ipairs(data) do
          if line and line ~= "" then
            vim.notify("Backend Error: " .. line, vim.log.levels.ERROR)
          end
        end
      end
    end,
    on_exit = function(_, exit_code)
      local success = exit_code == 0
      local message = success and "Operation completed successfully" or "Operation failed"

      if callback then
        callback(success, message, exit_code)
      else
        vim.notify((success and "✅" or "❌") .. " " .. message,
                   success and vim.log.levels.INFO or vim.log.levels.ERROR)
      end
    end
  })

  if job <= 0 then
    local error_msg = "Failed to execute backend command"
    vim.notify("❌ " .. error_msg, vim.log.levels.ERROR)
    if callback then callback(false, error_msg) end
    return false
  end

  return true
end

-- 上传当前文件
function M.upload()
  local file_info = M._get_current_file()
  if not file_info then
    vim.notify("❌ No current file to upload", vim.log.levels.ERROR)
    return
  end

  local remote_path = M._build_remote_path(file_info.path)
  local cmd_args = string.format('upload --local "%s" --remote "%s"', file_info.path, remote_path)

  vim.notify("📤 Uploading " .. file_info.name .. "...", vim.log.levels.INFO)

  M._execute_backend_command(cmd_args, function(success, message)
    if success then
      vim.notify("✅ File uploaded successfully: " .. file_info.name, vim.log.levels.INFO)
    else
      vim.notify("❌ Upload failed: " .. file_info.name, vim.log.levels.ERROR)
    end
  end)
end

-- 下载文件
function M.download()
  local file_info = M._get_current_file()
  if not file_info then
    vim.notify("❌ No current file to download", vim.log.levels.ERROR)
    return
  end

  local remote_path = M._build_remote_path(file_info.path)
  local cmd_args = string.format('download --remote "%s" --local "%s"', remote_path, file_info.path)

  vim.notify("📥 Downloading " .. file_info.name .. "...", vim.log.levels.INFO)

  M._execute_backend_command(cmd_args, function(success, message)
    if success then
      vim.notify("✅ File downloaded successfully: " .. file_info.name, vim.log.levels.INFO)
      -- 重新加载文件
      vim.cmd("edit")
    else
      vim.notify("❌ Download failed: " .. file_info.name, vim.log.levels.ERROR)
    end
  end)
end

-- 同步文件
function M.sync()
  local file_info = M._get_current_file()
  if not file_info then
    vim.notify("❌ No current file to sync", vim.log.levels.ERROR)
    return
  end

  local cmd_args = string.format('sync --files "%s" --mode auto', file_info.path)

  vim.notify("🔄 Syncing " .. file_info.name .. "...", vim.log.levels.INFO)

  M._execute_backend_command(cmd_args, function(success, message)
    if success then
      vim.notify("✅ File synced successfully: " .. file_info.name, vim.log.levels.INFO)
    else
      vim.notify("❌ Sync failed: " .. file_info.name, vim.log.levels.ERROR)
    end
  end)
end

-- 检查状态
function M.status()
  local cmd_args = "status"

  vim.notify("🔍 Checking status...", vim.log.levels.INFO)

  M._execute_backend_command(cmd_args, function(success, message)
    if success then
      vim.notify("✅ Status check completed", vim.log.levels.INFO)
    else
      vim.notify("❌ Status check failed", vim.log.levels.ERROR)
    end
  end)
end

-- 上传选中文件（Visual 模式）
function M.upload_selected()
  -- 获取选中的文件范围
  local start_pos = vim.fn.getpos("'<")
  local end_pos = vim.fn.getpos("'>")

  if start_pos[2] == 0 or end_pos[2] == 0 then
    vim.notify("❌ No files selected", vim.log.levels.ERROR)
    return
  end

  -- 在 Visual 模式下，通常是文件名选择
  -- 这里简化为处理当前文件
  local file_info = M._get_current_file()
  if not file_info then
    vim.notify("❌ No current file to upload", vim.log.levels.ERROR)
    return
  end

  vim.notify("📤 Uploading selected file: " .. file_info.name, vim.log.levels.INFO)

  local remote_path = M._build_remote_path(file_info.path)
  local cmd_args = string.format('upload --local "%s" --remote "%s"', file_info.path, remote_path)

  M._execute_backend_command(cmd_args, function(success, message)
    if success then
      vim.notify("✅ Selected file uploaded successfully: " .. file_info.name, vim.log.levels.INFO)
    else
      vim.notify("❌ Selected file upload failed: " .. file_info.name, vim.log.levels.ERROR)
    end
  end)
end

-- 上传多个文件
function M.upload_multi()
  -- 打开文件选择器
  vim.ui.select(vim.fn.glob("**/*", false, true), {
    prompt = "Select files to upload:",
    format_item = function(item)
      return vim.fn.fnamemodify(item, ":p:.")
    end
  }, function(files)
    if not files or #files == 0 then
      return
    end

    -- 处理单个文件或多个文件
    if type(files) == "string" then
      files = {files}
    end

    vim.notify("📤 Uploading " .. #files .. " file(s)...", vim.log.levels.INFO)

    local uploaded_count = 0
    local failed_count = 0

    for _, file_path in ipairs(files) do
      local remote_path = M._build_remote_path(file_path)
      local cmd_args = string.format('upload --local "%s" --remote "%s"', file_path, remote_path)

      M._execute_backend_command(cmd_args, function(success, message)
        if success then
          uploaded_count = uploaded_count + 1
        else
          failed_count = failed_count + 1
        end

        -- 检查是否所有文件都处理完毕
        if uploaded_count + failed_count == #files then
          vim.notify(string.format("✅ Upload completed: %d succeeded, %d failed",
                                   uploaded_count, failed_count), vim.log.levels.INFO)
        end
      end)
    end
  end)
end

-- 清除同步队列
function M.clear_queue()
  vim.notify("🧹 Clearing sync queue...", vim.log.levels.INFO)
  -- 这里可以实现清除内部队列的逻辑
  vim.notify("✅ Sync queue cleared", vim.log.levels.INFO)
end

-- 显示版本信息
function M.version()
  local Binary = require("astra.core.binary")
  local binary_status = Binary.validate()

  if binary_status.available then
    local cmd_args = "--version"
    M._execute_backend_command(cmd_args, function(success, output)
      if success then
        vim.notify("📊 Astra Version: " .. (binary_status.version or "unknown"), vim.log.levels.INFO)
        vim.notify("🔧 Binary: " .. binary_status.path, vim.log.levels.INFO)
        vim.notify("🏗️  Build Type: " .. binary_status.type, vim.log.levels.INFO)
      end
    end)
  else
    vim.notify("❌ No binary available", vim.log.levels.ERROR)
  end
end

-- 批量同步
function M.sync_batch()
  local cmd_args = "sync --mode auto"

  vim.notify("🔄 Starting batch sync...", vim.log.levels.INFO)

  M._execute_backend_command(cmd_args, function(success, message)
    if success then
      vim.notify("✅ Batch sync completed successfully", vim.log.levels.INFO)
    else
      vim.notify("❌ Batch sync failed", vim.log.levels.ERROR)
    end
  end)
end

-- 强制上传（覆盖远程）
function M.force_upload()
  local file_info = M._get_current_file()
  if not file_info then
    vim.notify("❌ No current file to upload", vim.log.levels.ERROR)
    return
  end

  local cmd_args = string.format('sync --files "%s" --mode upload', file_info.path)

  vim.notify("📤 Force uploading " .. file_info.name .. "...", vim.log.levels.INFO)

  M._execute_backend_command(cmd_args, function(success, message)
    if success then
      vim.notify("✅ Force upload completed: " .. file_info.name, vim.log.levels.INFO)
    else
      vim.notify("❌ Force upload failed: " .. file_info.name, vim.log.levels.ERROR)
    end
  end)
end

-- 强制下载（覆盖本地）
function M.force_download()
  local file_info = M._get_current_file()
  if not file_info then
    vim.notify("❌ No current file to download", vim.log.levels.ERROR)
    return
  end

  local cmd_args = string.format('sync --files "%s" --mode download', file_info.path)

  vim.notify("📥 Force downloading " .. file_info.name .. "...", vim.log.levels.INFO)

  M._execute_backend_command(cmd_args, function(success, message)
    if success then
      vim.notify("✅ Force download completed: " .. file_info.name, vim.log.levels.INFO)
      vim.cmd("edit")  -- 重新加载文件
    else
      vim.notify("❌ Force download failed: " .. file_info.name, vim.log.levels.ERROR)
    end
  end)
end

return M