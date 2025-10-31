-- Astra.nvim 同步功能模块
-- 专注8个核心功能：配置初始化、二进制构建、文件上传/下载、目录上传/下载、项目同步、增量同步、配置查看、版本查看

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

  -- 加载配置
  local Config = require("astra.core.config")
  local config_status = Config.validate_project_config()

  if config_status.available then
    M.config = config_status.config
  end

  M.initialized = true
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
  if not M.config then return file_path end

  local local_path = M.config.local_path
  if not local_path or local_path == "" then
    local_path = vim.fn.getcwd()
  end

  local relative_path = file_path:gsub("^" .. vim.pesc(local_path) .. "/", "")
  return relative_path
end

-- 构建远程路径
function M._build_remote_path(local_file_path)
  if not M.config then return local_file_path end

  local relative_path = M._get_relative_path(local_file_path)
  local remote_path = M.config.remote_path

  if remote_path:sub(-1) ~= "/" then
    remote_path = remote_path .. "/"
  end

  return remote_path .. relative_path
end

-- 执行后端命令
function M._execute_backend_command(cmd_args, callback)
  if not M.binary_path then
    local Binary = require("astra.core.binary")
    local binary_status = Binary.validate()
    if not binary_status.available then
      if callback then callback(false, "No binary available") end
      return false
    end
    M.binary_path = binary_status.path
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
            vim.notify("Error: " .. line, vim.log.levels.ERROR)
          end
        end
      end
    end,
    on_exit = function(_, exit_code)
      if exit_code == 0 then
        if callback then callback(true, "Command completed successfully") end
      else
        if callback then callback(false, "Command failed with exit code " .. exit_code) end
      end
    end
  })

  if job <= 0 then
    vim.notify("❌ Failed to start backend command", vim.log.levels.ERROR)
    if callback then callback(false, "Failed to start command") end
  end

  return job
end

-- 3. 单个文件上传
function M.upload_current_file()
  local file_info = M._get_current_file()
  if not file_info then
    vim.notify("❌ No current file to upload", vim.log.levels.ERROR)
    return
  end

  if not M.config then
    vim.notify("❌ No configuration available", vim.log.levels.ERROR)
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

-- 4. 单个文件下载
function M.download_current_file()
  local file_info = M._get_current_file()
  if not file_info then
    vim.notify("❌ No current file to download", vim.log.levels.ERROR)
    return
  end

  if not M.config then
    vim.notify("❌ No configuration available", vim.log.levels.ERROR)
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

-- 5. 目录文件上传
function M.upload_directory()
  if not M.config then
    vim.notify("❌ No configuration available", vim.log.levels.ERROR)
    return
  end

  local current_dir = vim.fn.expand("%:p:h")
  local dir_name = vim.fn.fnamemodify(current_dir, ":t")
  local cmd_args = string.format('upload --local "%s" --remote "%s/%s"',
                                current_dir, M.config.remote_path, dir_name)

  vim.notify("📤 Uploading directory: " .. dir_name .. "...", vim.log.levels.INFO)

  M._execute_backend_command(cmd_args, function(success, message)
    if success then
      vim.notify("✅ Directory uploaded successfully: " .. dir_name, vim.log.levels.INFO)
    else
      vim.notify("❌ Directory upload failed: " .. dir_name, vim.log.levels.ERROR)
    end
  end)
end

-- 6. 目录文件下载
function M.download_directory()
  if not M.config then
    vim.notify("❌ No configuration available", vim.log.levels.ERROR)
    return
  end

  local current_dir = vim.fn.expand("%:p:h")
  local dir_name = vim.fn.fnamemodify(current_dir, ":t")
  local remote_dir = M.config.remote_path .. "/" .. dir_name
  local cmd_args = string.format('download --remote "%s" --local "%s"', remote_dir, current_dir)

  vim.notify("📥 Downloading directory: " .. dir_name .. "...", vim.log.levels.INFO)

  M._execute_backend_command(cmd_args, function(success, message)
    if success then
      vim.notify("✅ Directory downloaded successfully: " .. dir_name, vim.log.levels.INFO)
    else
      vim.notify("❌ Directory download failed: " .. dir_name, vim.log.levels.ERROR)
    end
  end)
end

-- 7. 整个项目的上传下载
function M.sync_project()
  if not M.config then
    vim.notify("❌ No configuration available", vim.log.levels.ERROR)
    return
  end

  local cmd_args = string.format('sync --local "%s" --remote "%s" --mode bidirectional',
                                M.config.local_path, M.config.remote_path)

  vim.notify("🔄 Syncing entire project...", vim.log.levels.INFO)

  M._execute_backend_command(cmd_args, function(success, message)
    if success then
      vim.notify("✅ Project synced successfully", vim.log.levels.INFO)
    else
      vim.notify("❌ Project sync failed", vim.log.levels.ERROR)
    end
  end)
end

-- 8. 增量上下同步的能力
function M.incremental_sync()
  if not M.config then
    vim.notify("❌ No configuration available", vim.log.levels.ERROR)
    return
  end

  local cmd_args = string.format('sync --local "%s" --remote "%s" --mode incremental',
                                M.config.local_path, M.config.remote_path)

  vim.notify("🔄 Performing incremental sync...", vim.log.levels.INFO)

  M._execute_backend_command(cmd_args, function(success, message)
    if success then
      vim.notify("✅ Incremental sync completed", vim.log.levels.INFO)
    else
      vim.notify("❌ Incremental sync failed", vim.log.levels.ERROR)
    end
  end)
end

-- 兼容性函数（保持向后兼容）
function M.upload()
  M.upload_current_file()
end

function M.download()
  M.download_current_file()
end

function M.sync()
  M.incremental_sync()
end

function M.status()
  if not M.config then
    vim.notify("❌ No configuration available", vim.log.levels.ERROR)
    return
  end

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

function M.version()
  local Binary = require("astra.core.binary")
  local binary_status = Binary.validate()

  if binary_status.available then
    vim.notify("📊 Astra Version: " .. (binary_status.version or "unknown"), vim.log.levels.INFO)
    vim.notify("🔧 Binary: " .. binary_status.path, vim.log.levels.INFO)
    vim.notify("🏗️  Build Type: " .. binary_status.type, vim.log.levels.INFO)
  else
    vim.notify("❌ No binary available", vim.log.levels.ERROR)
  end
end

return M