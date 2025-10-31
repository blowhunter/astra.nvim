-- Astra.nvim 核心功能抽象层
-- 提供插件的核心功能接口和实现

local M = {}

-- 加载核心模块
local Binary = require("astra.core.binary")
local Config = require("astra.core.config")
local Sync = require("astra.core.sync")
local UI = require("astra.core.ui")

-- 核心状态管理
M.state = {
  initialized = false,
  binary_available = false,
  config_available = false,
  functionality_level = "none"  -- none, basic, full
}

-- 核心初始化函数
function M.initialize()
  if M.state.initialized then
    return M.state
  end

  -- 1. 验证二进制文件
  local binary_status = Binary.validate()
  M.state.binary_available = binary_status.available

  -- 2. 验证项目配置
  local config_status = Config.validate_project_config()
  M.state.config_available = config_status.available

  -- 3. 确定功能级别
  M.state.functionality_level = M:_determine_functionality_level()

  -- 4. 初始化相应级别的功能
  M:_initialize_functionality()

  M.state.initialized = true
  return M.state
end

-- 确定功能级别
function M:_determine_functionality_level()
  if not M.state.binary_available then
    return "basic"  -- 只有基本功能：构建、配置向导
  end

  if not M.state.config_available then
    return "basic"  -- 只有基本功能：配置初始化
  end

  return "full"     -- 完整功能
end

-- 根据功能级别初始化功能
function M:_initialize_functionality()
  local level = M.state.functionality_level

  if level == "basic" then
    M._register_basic_commands()
    M._register_basic_keymaps()
  elseif level == "full" then
    M._register_full_commands()
    M._register_full_keymaps()
    -- 初始化同步模块
    Sync.initialize()
  end
end

-- 注册基本命令
function M._register_basic_commands()
  -- 始终注册帮助命令
  vim.api.nvim_create_user_command("AstraHelp", function()
    M._show_help()
  end, { desc = "Show Astra help" })

  -- 主菜单命令
  vim.api.nvim_create_user_command("AstraMenu", function()
    M._show_main_menu()
  end, { desc = "Show Astra main menu" })

  if not M.state.binary_available then
    -- 只有二进制管理相关命令
    vim.api.nvim_create_user_command("AstraBuild", function()
      Binary.build()
    end, { desc = "Build Astra core binary" })

    vim.api.nvim_create_user_command("AstraInstall", function()
      Binary.install()
    end, { desc = "Install Astra core binary" })
  end

  if M.state.binary_available and not M.state.config_available then
    -- 配置初始化相关命令
    vim.api.nvim_create_user_command("AstraInit", function()
      Config.init_project_config()
    end, { desc = "Initialize project configuration" })

    vim.api.nvim_create_user_command("AstraQuickSetup", function()
      Config.quick_setup()
    end, { desc = "Quick setup wizard" })
  end
end

-- 注册完整命令
function M._register_full_commands()
  -- 包含基本命令
  M._register_basic_commands()

  -- 完整功能命令 - 只注册实际实现的命令
  vim.api.nvim_create_user_command("AstraUpload", function()
    Sync.upload()
  end, { desc = "Astra: Upload current file" })

  vim.api.nvim_create_user_command("AstraDownload", function()
    Sync.download()
  end, { desc = "Astra: Download current file" })

  vim.api.nvim_create_user_command("AstraSync", function()
    Sync.sync()
  end, { desc = "Astra: Sync current file" })

  vim.api.nvim_create_user_command("AstraStatus", function()
    Sync.status()
  end, { desc = "Astra: Check sync status" })

  vim.api.nvim_create_user_command("AstraVersion", function()
    Sync.version()
  end, { desc = "Show Astra version" })
end

-- 注册基本键映射
function M._register_basic_keymaps()
  local leader = vim.g.maplocalleader or vim.g.mapleader or " "
  local Binary = require("astra.core.binary")

  -- 主菜单快捷键 - 通过命令触发
  vim.keymap.set('n', leader .. 'A', ":AstraMenu<CR>",
    { desc = "Astra Menu", noremap = true, silent = true })

  -- 帮助和版本快捷键
  vim.keymap.set('n', leader .. 'Ah', ":AstraHelp<CR>",
    { desc = "Show Help", noremap = true, silent = true })

  vim.keymap.set('n', leader .. 'Av', function()
    local binary_status = Binary.validate()
    if binary_status.available then
      vim.notify("📊 Astra Version: " .. (binary_status.version or "unknown"), vim.log.levels.INFO)
      vim.notify("🔧 Binary: " .. binary_status.path, vim.log.levels.INFO)
      vim.notify("🏗️  Build Type: " .. binary_status.type, vim.log.levels.INFO)
    else
      vim.notify("❌ No binary available - run :AstraBuild", vim.log.levels.ERROR)
    end
  end, { desc = "Show Version", noremap = true, silent = true })

  -- 没有二进制文件时的快捷键
  if not M.state.binary_available then
    vim.keymap.set('n', leader .. 'Abc', function() Binary.build() end,
      { desc = "Build Core", noremap = true, silent = true })
  end

  -- 有二进制文件但没有配置文件时的快捷键
  if M.state.binary_available and not M.state.config_available then
    vim.keymap.set('n', leader .. 'Arc', function() Config.init_project_config() end,
      { desc = "Init Config", noremap = true, silent = true })
    vim.keymap.set('n', leader .. 'Aq', function() Config.quick_setup() end,
      { desc = "Quick Setup", noremap = true, silent = true })
  end
end

-- 注册完整键映射
function M._register_full_keymaps()
  -- 包含基本键映射
  M._register_basic_keymaps()

  -- 完整功能键映射 - 只保留实际可用的核心功能
  local leader = vim.g.maplocalleader or vim.g.mapleader or "\\"

  -- 文件操作核心功能
  vim.keymap.set('n', leader .. 'Au', function() Sync.upload() end,
    { desc = "Astra: Upload current file", noremap = true, silent = true })

  vim.keymap.set('n', leader .. 'Ad', function() Sync.download() end,
    { desc = "Astra: Download current file", noremap = true, silent = true })

  vim.keymap.set('n', leader .. 'As', function() Sync.sync() end,
    { desc = "Astra: Sync current file", noremap = true, silent = true })

  vim.keymap.set('n', leader .. 'Ai', function() Sync.status() end,
    { desc = "Astra: Check status", noremap = true, silent = true })


end

-- 显示主菜单
function M._show_main_menu()
  -- 添加错误处理
  local ok, result = pcall(function()
    local level = M.state.functionality_level
    local menu_lines = {}

    table.insert(menu_lines, "🚀 Astra.nvim - 主菜单")
    table.insert(menu_lines, "")

    -- 状态信息
    local status_text = "状态: "
    if level == "full" then
      status_text = status_text .. "✅ 完整功能"
    elseif level == "basic" then
      status_text = status_text .. "⚙️  基础功能"
    else
      status_text = status_text .. "❌ 未初始化"
    end
    table.insert(menu_lines, status_text)
    table.insert(menu_lines, "")

    -- 核心命令
    table.insert(menu_lines, "核心命令:")
    table.insert(menu_lines, "  h) 帮助信息")
    table.insert(menu_lines, "  v) 版本信息")

    -- 根据状态显示不同命令
    if level == "full" then
      table.insert(menu_lines, "")
      table.insert(menu_lines, "文件操作:")
      table.insert(menu_lines, "  u) 上传当前文件")
      table.insert(menu_lines, "  d) 下载当前文件")
      table.insert(menu_lines, "  s) 同步当前文件")
      table.insert(menu_lines, "  i) 检查同步状态")

      table.insert(menu_lines, "")
      table.insert(menu_lines, "配置管理:")
      table.insert(menu_lines, "  c) 初始化配置")
      table.insert(menu_lines, "  w) 快速配置向导")
    elseif level == "basic" then
      if not M.state.binary_available then
        table.insert(menu_lines, "")
        table.insert(menu_lines, "初始化:")
        table.insert(menu_lines, "  b) 构建核心二进制")
        table.insert(menu_lines, "  I) 安装预编译二进制")
      else
        table.insert(menu_lines, "")
        table.insert(menu_lines, "配置:")
        table.insert(menu_lines, "  c) 初始化项目配置")
        table.insert(menu_lines, "  w) 快速配置向导")
      end
    end

    table.insert(menu_lines, "")
    table.insert(menu_lines, "按 ESC 或 q 退出菜单")
    table.insert(menu_lines, "按对应字母键执行命令")

    -- 使用浮动窗口显示菜单
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, menu_lines)
    vim.api.nvim_buf_set_option(buf, "modifiable", false)
    vim.api.nvim_buf_set_option(buf, "filetype", "text")

    local ui = vim.api.nvim_list_uis()[1]
    local width = math.min(50, ui.width - 10)
    local height = math.min(#menu_lines, ui.height - 10)

    local win_config = {
      relative = "editor",
      width = width,
      height = height,
      col = math.floor((ui.width - width) / 2),
      row = math.floor((ui.height - height) / 2),
      border = "rounded",
      style = "minimal",
      title = "Astra Menu",
      title_pos = "center"
    }

    local win = vim.api.nvim_open_win(buf, true, win_config)
    vim.api.nvim_win_set_option(win, "wrap", true)
    vim.api.nvim_win_set_option(win, "cursorline", true)

    -- 创建菜单处理器
    local menu_handler = vim.api.nvim_create_augroup("AstraMenu", { clear = true })

    -- 设置快捷键
    vim.api.nvim_buf_set_keymap(buf, "n", "q", "", {
      callback = function()
        vim.api.nvim_win_close(win, true)
        vim.api.nvim_del_augroup_by_id(menu_handler)
      end,
      noremap = true,
      silent = true
    })

    vim.api.nvim_buf_set_keymap(buf, "n", "<Esc>", "", {
      callback = function()
        vim.api.nvim_win_close(win, true)
        vim.api.nvim_del_augroup_by_id(menu_handler)
      end,
      noremap = true,
      silent = true
    })

    -- 为菜单项设置按键绑定
    vim.api.nvim_buf_set_keymap(buf, "n", "h", "", {
      callback = function()
        vim.api.nvim_win_close(win, true)
        vim.api.nvim_del_augroup_by_id(menu_handler)
        M._show_help()
      end,
      noremap = true,
      silent = true
    })

    vim.api.nvim_buf_set_keymap(buf, "n", "v", "", {
      callback = function()
        vim.api.nvim_win_close(win, true)
        vim.api.nvim_del_augroup_by_id(menu_handler)
        local Binary = require("astra.core.binary")
        local binary_status = Binary.validate()
        if binary_status.available then
          vim.notify("📊 Astra Version: " .. (binary_status.version or "unknown"), vim.log.levels.INFO)
          vim.notify("🔧 Binary: " .. binary_status.path, vim.log.levels.INFO)
          vim.notify("🏗️  Build Type: " .. binary_status.type, vim.log.levels.INFO)
        else
          vim.notify("❌ No binary available - run :AstraBuild", vim.log.levels.ERROR)
        end
      end,
      noremap = true,
      silent = true
    })

    -- 根据功能级别设置不同的按键
    if level == "full" then
      vim.api.nvim_buf_set_keymap(buf, "n", "u", "", {
        callback = function()
          vim.api.nvim_win_close(win, true)
          vim.api.nvim_del_augroup_by_id(menu_handler)
          Sync.upload()
        end,
        noremap = true,
        silent = true
      })

      vim.api.nvim_buf_set_keymap(buf, "n", "d", "", {
        callback = function()
          vim.api.nvim_win_close(win, true)
          vim.api.nvim_del_augroup_by_id(menu_handler)
          Sync.download()
        end,
        noremap = true,
        silent = true
      })

      vim.api.nvim_buf_set_keymap(buf, "n", "s", "", {
        callback = function()
          vim.api.nvim_win_close(win, true)
          vim.api.nvim_del_augroup_by_id(menu_handler)
          Sync.sync()
        end,
        noremap = true,
        silent = true
      })

      vim.api.nvim_buf_set_keymap(buf, "n", "i", "", {
        callback = function()
          vim.api.nvim_win_close(win, true)
          vim.api.nvim_del_augroup_by_id(menu_handler)
          Sync.status()
        end,
        noremap = true,
        silent = true
      })

      vim.api.nvim_buf_set_keymap(buf, "n", "c", "", {
        callback = function()
          vim.api.nvim_win_close(win, true)
          vim.api.nvim_del_augroup_by_id(menu_handler)
          Config.init_project_config()
        end,
        noremap = true,
        silent = true
      })

      vim.api.nvim_buf_set_keymap(buf, "n", "w", "", {
        callback = function()
          vim.api.nvim_win_close(win, true)
          vim.api.nvim_del_augroup_by_id(menu_handler)
          Config.quick_setup()
        end,
        noremap = true,
        silent = true
      })
    elseif level == "basic" then
      if not M.state.binary_available then
        vim.api.nvim_buf_set_keymap(buf, "n", "b", "", {
          callback = function()
            vim.api.nvim_win_close(win, true)
            vim.api.nvim_del_augroup_by_id(menu_handler)
            Binary.build()
          end,
          noremap = true,
          silent = true
        })
      else
        vim.api.nvim_buf_set_keymap(buf, "n", "c", "", {
          callback = function()
            vim.api.nvim_win_close(win, true)
            vim.api.nvim_del_augroup_by_id(menu_handler)
            Config.init_project_config()
          end,
          noremap = true,
          silent = true
        })

        vim.api.nvim_buf_set_keymap(buf, "n", "w", "", {
          callback = function()
            vim.api.nvim_win_close(win, true)
            vim.api.nvim_del_augroup_by_id(menu_handler)
            Config.quick_setup()
          end,
          noremap = true,
          silent = true
        })
      end
    end

    -- 关闭时清理
    vim.api.nvim_create_autocmd("WinClosed", {
      pattern = tostring(win),
      once = true,
      callback = function()
        if vim.api.nvim_buf_is_valid(buf) then
          vim.api.nvim_buf_delete(buf, {force = true})
        end
        vim.api.nvim_del_augroup_by_id(menu_handler)
      end
    })
  end)

  if not ok then
    vim.notify("❌ Astra: Error showing menu - " .. tostring(result), vim.log.levels.ERROR)
    vim.notify("💡 Try :AstraHelp for available commands", vim.log.levels.INFO)
  end
end
