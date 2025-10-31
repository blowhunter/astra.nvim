-- Astra.nvim 配置管理模块
-- 负责配置文件的管理、验证和加载

local M = {}

-- 安全的 Vim API 访问（用于测试模式）
local safe_vim = {}
if vim and vim.fn then
  safe_vim.fn = vim.fn
else
  safe_vim.fn = {
    getcwd = function()
      return "."
    end,
    filereadable = function(path)
      local file = io.open(path, "r")
      if file then
        io.close(file)
        return 1
      end
      return 0
    end,
    readfile = function(path)
      local file = io.open(path, "r")
      if not file then
        return nil
      end
      local lines = {}
      for line in file:lines() do
        table.insert(lines, line)
      end
      io.close(file)
      return lines
    end,
    writefile = function(lines, path)
      local file = io.open(path, "w")
      if file then
        for _, line in ipairs(lines) do
          file:write(line .. "\n")
        end
        io.close(file)
        return true
      end
      return false
    end,
    expand = function(expr)
      if expr == "~" then
        return os.getenv("HOME") or ""
      end
      return expr
    end,
    fnamemodify = function(path, mods)
      if mods == ":t" then
        return path:match("([^/]+)$") or ""
      elseif mods == ":p" then
        return path
      elseif mods == ":p:h" then
        return path:match("(.*/)") or ""
      end
      return path
    end
  }
end

-- 默认配置（公共配置层）
M.default_config = {
  -- 基础连接配置
  host = "",
  port = 22,
  username = "",
  password = nil,
  private_key_path = "~/.ssh/id_rsa",
  remote_path = "",
  local_path = safe_vim.fn.getcwd(),

  -- 功能开关
  auto_sync = false,
  sync_on_save = true,
  sync_interval = 30000,

  -- 高级选项
  exclude_patterns = {".git/", "*.tmp", "*.log", ".DS_Store"},
  include_patterns = {},
  max_file_size = 10 * 1024 * 1024, -- 10MB

  -- 开发选项
  static_build = false,
  debug_mode = false,
}

-- 项目配置文件路径（按优先级排序）
-- 优先级原则：隐藏目录 > 隐藏文件 > 避免项目代码污染
M.project_config_files = {
  ".astra-settings/settings.json",    -- 隐藏目录 + JSON格式，最高优先级
  ".astra-settings/settings.toml",   -- 隐藏目录 + TOML格式，可选支持
  ".astra-settings.json",            -- 隐藏文件 + JSON格式
  ".astra-settings.toml",            -- 隐藏文件 + TOML格式，可选支持
  ".astra.json",                     -- 项目根隐藏文件，兼容性
  ".vscode/sftp.json"                -- VSCode兼容，最低优先级
}

-- 验证项目配置文件
function M.validate_project_config()
  local config_info = M.discover_project_config()

  if not config_info then
    return {
      available = false,
      path = nil,
      reason = "No project configuration file found",
      suggestion = "Run :AstraInit to create project configuration"
    }
  end

  -- 验证配置文件内容
  local config = M.load_config_file(config_info.path)
  if not config then
    return {
      available = false,
      path = config_info.path,
      reason = "Configuration file is invalid or empty",
      suggestion = "Check configuration file format"
    }
  end

  -- 验证必要字段
  local required_fields = {"host", "username", "remote_path"}
  local missing_fields = {}

  for _, field in ipairs(required_fields) do
    if not config[field] or config[field] == "" then
      table.insert(missing_fields, field)
    end
  end

  if #missing_fields > 0 then
    return {
      available = false,
      path = config_info.path,
      reason = "Missing required fields: " .. table.concat(missing_fields, ", "),
      suggestion = "Add missing fields to configuration file"
    }
  end

  return {
    available = true,
    path = config_info.path,
    format = config_info.format,
    config = config
  }
end

-- 发现项目配置文件
function M.discover_project_config()
  local cwd = safe_vim.fn.getcwd()

  for _, filename in ipairs(M.project_config_files) do
    local full_path = cwd .. "/" .. filename
    if safe_vim.fn.filereadable(full_path) == 1 then
      local format = M._detect_format(filename)
      return {
        path = full_path,
        filename = filename,
        format = format
      }
    end
  end

  return nil
end

-- 检测配置文件格式
function M._detect_format(filename)
  if filename:match("%.toml$") then
    return "toml"
  elseif filename:match("%.json$") then
    return "json"
  else
    return "unknown"
  end
end

-- 加载配置文件
function M.load_config_file(path)
  local format = M._detect_format(path)

  if format == "toml" then
    return M._load_toml(path)
  elseif format == "json" then
    return M._load_json(path)
  else
    vim.notify("❌ Unsupported configuration format: " .. format, vim.log.levels.ERROR)
    return nil
  end
end

-- 加载 TOML 配置文件
function M._load_toml(path)
  -- 尝试加载 toml.nvim 插件
  local ok, toml = pcall(require, "toml")
  if not ok then
    vim.notify("⚠️  toml.nvim not installed, TOML support disabled", vim.log.levels.WARN)
    vim.notify("💡 Install with: :Lazy install toml.nvim", vim.log.levels.INFO)
    vim.notify("💡 Or use JSON format: .vscode/sftp.json or astra.json", vim.log.levels.INFO)
    return nil
  end

  local content = safe_vim.fn.readfile(path)
  if not content or #content == 0 then
    return nil
  end

  local config_str = table.concat(content, "\n")
  local config, err = toml.parse(config_str)

  if err then
    vim.notify("❌ Failed to parse TOML configuration: " .. err, vim.log.levels.ERROR)
    return nil
  end

  -- 处理 TOML 特定的结构
  if config.sftp then
    return config.sftp
  end
  return config
end

-- 加载 JSON 配置文件
function M._load_json(path)
  local content = safe_vim.fn.readfile(path)
  if not content or #content == 0 then
    return nil
  end

  local config_str = table.concat(content, "\n")
  local ok, config = pcall(vim.json.decode, config_str)

  if not ok then
    if vim and vim.notify then
      vim.notify("❌ Failed to parse JSON configuration: " .. config, vim.log.levels.ERROR)
    end
    return nil
  end

  -- 处理 VSCode SFTP 特定的结构
  if config.host and config.protocol == "sftp" then
    return {
      host = config.host,
      port = config.port or 22,
      username = config.username,
      password = config.password,
      private_key_path = config.privateKeyPath,
      remote_path = config.remotePath,
      local_path = config.localPath or safe_vim.fn.getcwd()
    }
  end

  return config
end

-- 合并配置（优先级：项目配置 > 公共配置 > 默认配置）
function M.merge_config(public_config, project_config)
  local merged = vim.deepcopy(M.default_config)

  -- 合并公共配置
  if public_config then
    merged = vim.tbl_deep_extend("force", merged, public_config)
  end

  -- 合并项目配置
  if project_config then
    merged = vim.tbl_deep_extend("force", merged, project_config)
  end

  return merged
end

-- 初始化项目配置文件
function M.init_project_config()
  local cwd = safe_vim.fn.getcwd()
  local config_dir = cwd .. "/.astra-settings"
  local config_path = config_dir .. "/settings.json"

  -- 检查是否已存在任何配置文件
  local existing_config = M.discover_project_config()
  if existing_config then
    if vim and vim.notify then
      vim.notify("⚠️  Project configuration already exists: " .. existing_config.filename, vim.log.levels.WARN)
    end
    return
  end

  -- 创建隐藏目录
  local ok, err = pcall(safe_vim.fn.mkdir, config_dir, "p")
  if not ok then
    if vim and vim.notify then
      vim.notify("❌ Failed to create config directory: " .. err, vim.log.levels.ERROR)
    end
    return
  end

  -- 创建默认项目配置
  local project_name = safe_vim.fn.fnamemodify(cwd, ":t")
  local default_project_config = {
    host = "your-server.com",
    port = 22,
    username = "your-username",
    password = nil,
    private_key_path = "~/.ssh/id_rsa",
    remote_path = "/remote/path/to/" .. project_name,
    local_path = cwd,
    auto_sync = false,
    sync_on_save = true,
    sync_interval = 30000,
    exclude_patterns = {".git/", "*.tmp", "*.log", ".DS_Store"},
    include_patterns = {},
    max_file_size = 10485760 -- 10MB
  }

  -- 生成 JSON 配置文件内容
  local json_content = vim.json.encode(default_project_config)

  -- 写入配置文件
  local ok, err = pcall(safe_vim.fn.writefile, {json_content}, config_path)
  if not ok then
    if vim and vim.notify then
      vim.notify("❌ Failed to create project configuration: " .. err, vim.log.levels.ERROR)
    end
    return
  end

  -- 创建 .gitignore 文件（如果不存在）
  local gitignore_path = cwd .. "/.gitignore"
  local gitignore_content = safe_vim.fn.readfile(gitignore_path)
  local gitignore_needs_update = true

  if gitignore_content then
    local gitignore_text = table.concat(gitignore_content, "\n")
    if gitignore_text:match("%.astra%-settings") then
      gitignore_needs_update = false
    end
  end

  if gitignore_needs_update then
    local gitignore_entries = {
      "# Astra.nvim configuration",
      ".astra-settings/",
      ""
    }

    -- 追加到现有 .gitignore 或创建新的
    local final_gitignore = gitignore_content and gitignore_content or {}
    for _, entry in ipairs(gitignore_entries) do
      table.insert(final_gitignore, entry)
    end

    safe_vim.fn.writefile(final_gitignore, gitignore_path)
  end

  if vim and vim.notify then
    vim.notify("✅ Astra configuration created: " .. config_path, vim.log.levels.INFO)
    vim.notify("💡 Configuration directory excluded from version control", vim.log.levels.INFO)
    vim.notify("📝 Please edit the configuration with your server details", vim.log.levels.INFO)
  end

  -- 重新初始化核心模块
  local Core = require("astra.core")
  Core.reinitialize()
end

-- 生成 TOML 配置文件内容
function M._generate_toml_content(config)
  local lines = {
    "# Astra.nvim Project Configuration",
    "# Generated on " .. os.date("%Y-%m-%d %H:%M:%S"),
    "",
    "[connection]",
    "host = \"" .. config.host .. "\"",
    "port = " .. config.port,
    "username = \"" .. config.username .. "\"",
    "password = " .. (config.password and "\"" .. config.password .. "\"" or "null"),
    "private_key_path = \"" .. config.private_key_path .. "\"",
    "remote_path = \"" .. config.remote_path .. "\"",
    "local_path = \"" .. config.local_path .. "\"",
    "",
    "[sync]",
    "auto_sync = " .. tostring(config.auto_sync),
    "sync_on_save = " .. tostring(config.sync_on_save),
    "sync_interval = " .. config.sync_interval,
    "",
    "[filters]",
    "# File patterns to exclude from synchronization",
    "exclude_patterns = [",
  }

  for _, pattern in ipairs(config.exclude_patterns) do
    table.insert(lines, "  \"" .. pattern .. "\",")
  end

  table.insert(lines, "]")
  table.insert(lines, "")
  table.insert(lines, "# File patterns to include (empty means include all)")
  table.insert(lines, "include_patterns = [")

  for _, pattern in ipairs(config.include_patterns) do
    table.insert(lines, "  \"" .. pattern .. "\",")
  end

  table.insert(lines, "]")
  table.insert(lines, "")
  table.insert(lines, "# Maximum file size in bytes (0 = no limit)")
  table.insert(lines, "max_file_size = " .. config.max_file_size)

  return table.concat(lines, "\n")
end

-- 快速配置向导
function M.quick_setup()
  -- 创建交互式配置向导
  local config = {}

  vim.ui.input({prompt = "Server host: "}, function(value)
    config.host = value or ""

    vim.ui.input({prompt = "Username: "}, function(value)
      config.username = value or ""

      vim.ui.input({prompt = "Remote path: "}, function(value)
        config.remote_path = value or ""

        -- 完成配置，创建配置文件
        if config.host ~= "" and config.username ~= "" and config.remote_path ~= "" then
          M._create_quick_config(config)
        else
          vim.notify("❌ All fields are required", vim.log.levels.ERROR)
        end
      end)
    end)
  end)
end

-- 创建快速配置
function M._create_quick_config(config)
  local cwd = vim.fn.getcwd()
  local config_path = cwd .. "/.astra.toml"

  local project_config = vim.tbl_deep_extend("force", M.default_config, {
    host = config.host,
    username = config.username,
    remote_path = config.remote_path,
    local_path = cwd
  })

  local toml_content = M._generate_toml_content(project_config)
  local ok, err = pcall(vim.fn.writefile, vim.split(toml_content, "\n"), config_path)

  if ok then
    vim.notify("✅ Quick configuration created successfully!", vim.log.levels.INFO)
    vim.notify("🚀 Astra is ready to use!", vim.log.levels.INFO)

    -- 重新初始化核心模块
    local Core = require("astra.core")
    Core.reinitialize()
  else
    vim.notify("❌ Failed to create configuration: " .. err, vim.log.levels.ERROR)
  end
end

-- 显示配置信息弹窗
function M.info()
  local config_status = M.validate_project_config()

  local info_lines = {
    "🔍 Astra Configuration Information",
    "",
    "📊 配置状态: " .. (config_status.available and "✅ 可用" or "❌ 不可用")
  }

  if config_status.available then
    table.insert(info_lines, "")
    table.insert(info_lines, "📁 配置文件:")
    table.insert(info_lines, "  路径: " .. config_status.path)
    table.insert(info_lines, "  格式: " .. config_status.format:upper())
    table.insert(info_lines, "  文件名: " .. config_status.filename)

    if config_status.config then
      table.insert(info_lines, "")
      table.insert(info_lines, "🌐 连接信息:")
      table.insert(info_lines, "  主机: " .. config_status.config.host)
      table.insert(info_lines, "  端口: " .. config_status.config.port)
      table.insert(info_lines, "  用户名: " .. config_status.config.username)
      table.insert(info_lines, "  密钥: " .. (config_status.config.password and "已设置" or "使用密钥文件"))
      table.insert(info_lines, "  密钥文件: " .. (config_status.config.private_key_path or "未设置"))

      table.insert(info_lines, "")
      table.insert(info_lines, "📂 路径配置:")
      table.insert(info_lines, "  本地路径: " .. config_status.config.local_path)
      table.insert(info_lines, "  远程路径: " .. config_status.config.remote_path)

      if config_status.config.auto_sync ~= nil then
        table.insert(info_lines, "")
        table.insert(info_lines, "⚙️ 同步设置:")
        table.insert(info_lines, "  自动同步: " .. (config_status.config.auto_sync and "开启" or "关闭"))
        table.insert(info_lines, "  保存时同步: " .. (config_status.config.sync_on_save and "开启" or "关闭"))
        table.insert(info_lines, "  同步间隔: " .. (config_status.config.sync_interval / 1000) .. "s")
      end

      if config_status.config.exclude_patterns and #config_status.config.exclude_patterns > 0 then
        table.insert(info_lines, "")
        table.insert(info_lines, "🚫 排除规则:")
        local exclude_preview = {}
        for i, pattern in ipairs(config_status.config.exclude_patterns) do
          if i <= 5 then
            table.insert(exclude_preview, "  " .. pattern)
          end
        end
        for _, pattern in ipairs(exclude_preview) do
          table.insert(info_lines, pattern)
        end
        if #config_status.config.exclude_patterns > 5 then
          table.insert(info_lines, "  ... 还有 " .. (#config_status.config.exclude_patterns - 5) .. " 个规则")
        end
      end
    end
  else
    table.insert(info_lines, "")
    table.insert(info_lines, "❌ 配置问题:")
    table.insert(info_lines, "  原因: " .. config_status.reason)
    table.insert(info_lines, "  建议: " .. config_status.suggestion)
    table.insert(info_lines, "")
    table.insert(info_lines, "💡 快速解决方案:")
    table.insert(info_lines, "  1. 按 <leader>Ai 初始化配置")
    table.insert(info_lines, "  2. 或运行 :AstraInit 命令")
    table.insert(info_lines, "  3. 编辑配置文件设置服务器信息")
  end

  table.insert(info_lines, "")
  table.insert(info_lines, "按 q 或 Esc 关闭此窗口")

  -- 创建弹窗显示配置信息
  local info_text = table.concat(info_lines, "\n")
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(info_text, "\n"))
  vim.api.nvim_buf_set_option(buf, "buftype", "nofile")
  vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe")
  vim.api.nvim_buf_set_option(buf, "modifiable", false)

  -- 设置语法高亮
  vim.api.nvim_buf_set_option(buf, "filetype", "text")

  -- 计算窗口大小
  local ui = vim.api.nvim_list_uis()[1]
  local width = math.min(80, ui.width - 10)
  local height = math.min(#info_lines + 2, ui.height - 8)

  local win_config = {
    relative = "editor",
    width = width,
    height = height,
    col = math.floor((ui.width - width) / 2),
    row = math.floor((ui.height - height) / 2),
    border = "rounded",
    style = "minimal",
    title = "Astra Configuration",
    title_pos = "center",
  }

  local win = vim.api.nvim_open_win(buf, true, win_config)
  vim.api.nvim_win_set_option(win, "wrap", true)
  vim.api.nvim_win_set_option(win, "cursorline", true)

  -- 设置退出快捷键
  vim.keymap.set('n', 'q', '<cmd>q<cr>', { buffer = buf, silent = true })
  vim.keymap.set('n', '<Esc>', '<cmd>q<cr>', { buffer = buf, silent = true })

  -- 可选：添加快捷键进行快速操作
  if not config_status.available then
    vim.keymap.set('n', 'i', function()
      vim.api.nvim_win_close(win, true)
      M.init_project_config()
    end, { buffer = buf, desc = "Initialize configuration", silent = true })

    -- 更新帮助信息
    info_lines[#info_lines - 1] = "按 i 初始化配置, q/Esc 关闭窗口"
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(table.concat(info_lines, "\n"), "\n"))
  end
end

return M