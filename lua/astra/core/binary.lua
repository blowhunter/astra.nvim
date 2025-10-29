-- Astra.nvim 二进制文件管理模块
-- 负责二进制文件的验证、构建、下载和安装

local M = {}

-- 安全的 Vim API 访问（用于测试模式）
local safe_vim = {}
if vim and vim.fn then
  safe_vim.fn = vim.fn
else
  safe_vim.fn = {
    expand = function(expr)
      if expr == "%:p" then
        return ""
      elseif expr == "%:t" then
        return ""
      elseif expr == "%:p:h" then
        return ""
      elseif expr:match("^~") then
        return os.getenv("HOME") .. expr:sub(2)
      end
      return expr
    end,
    executable = function(path)
      return os.execute("test -x " .. path .. " 2>/dev/null") == 0 and 1 or 0
    end,
    getcwd = function()
      return "."
    end,
    system = function(cmd)
      local handle = io.popen(cmd)
      local result = handle:read("*all")
      handle:close()
      return result
    end,
    filereadable = function(path)
      local file = io.open(path, "r")
      if file then
        io.close(file)
        return 1
      end
      return 0
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
    end
  }
end

-- 二进制文件路径配置
M.paths = {
  plugin = safe_vim.fn.expand("~/.local/share/nvim/lazy/astra.nvim"),
  release = "target/release/astra-core",
  debug = "target/debug/astra-core",
  static = "target/x86_64-unknown-linux-musl/release/astra-core"
}

-- 获取二进制文件路径
function M.get_binary_path()
  -- 1. 优先检查本地项目构建
  local local_debug = safe_vim.fn.getcwd() .. "/astra-core/" .. M.paths.debug
  if safe_vim.fn.executable(local_debug) == 1 then
    return local_debug
  end

  -- 2. 检查插件目录中的各种构建
  local plugin_dir = M.paths.plugin

  local plugin_paths = {
    plugin_dir .. "/astra-core/" .. M.paths.debug,
    plugin_dir .. "/astra-core/" .. M.paths.release,
    plugin_dir .. "/astra-core/" .. M.paths.static
  }

  for _, path in ipairs(plugin_paths) do
    if safe_vim.fn.executable(path) == 1 then
      return path
    end
  end

  return nil
end

-- 验证二进制文件
function M.validate()
  local binary_path = M.get_binary_path()

  if not binary_path then
    return {
      available = false,
      path = nil,
      reason = "No binary file found",
      suggestion = "Run :AstraBuild or :AstraInstall"
    }
  end

  -- 测试二进制文件是否可执行
  local test_result = safe_vim.fn.system(binary_path .. " --help", "")
  if os.execute(binary_path .. " --help >/dev/null 2>&1") ~= 0 then
    return {
      available = false,
      path = binary_path,
      reason = "Binary file is not executable",
      suggestion = "Rebuild with :AstraBuild"
    }
  end

  return {
    available = true,
    path = binary_path,
    version = M._get_version(binary_path),
    type = M._get_build_type(binary_path)
  }
end

-- 获取二进制版本
function M._get_version(binary_path)
  local output = vim.fn.system(binary_path .. " --version", "")
  if vim.v.shell_error == 0 then
    return output:gsub("\n", ""):match("version (%S+)") or "unknown"
  end
  return "unknown"
end

-- 获取构建类型
function M._get_build_type(binary_path)
  if binary_path:match("debug") then
    return "debug"
  elseif binary_path:match("static") then
    return "static"
  else
    return "release"
  end
end

-- 构建二进制文件
function M.build()
  local plugin_dir = M.paths.plugin
  local build_cmd = string.format("cd %s && make build", plugin_dir)

  vim.notify("🔨 Building Astra core binary...", vim.log.levels.INFO)

  local job = vim.fn.jobstart(build_cmd, {
    on_stdout = function(_, data)
      if data and #data > 0 then
        for _, line in ipairs(data) do
          if line and line ~= "" then
            vim.notify("Build: " .. line, vim.log.levels.DEBUG)
          end
        end
      end
    end,
    on_stderr = function(_, data)
      if data and #data > 0 then
        for _, line in ipairs(data) do
          if line and line ~= "" then
            vim.notify("Build Error: " .. line, vim.log.levels.ERROR)
          end
        end
      end
    end,
    on_exit = function(_, exit_code)
      if exit_code == 0 then
        vim.notify("✅ Astra core binary built successfully!", vim.log.levels.INFO)

        -- 重新验证二进制文件
        local status = M.validate()
        if status.available then
          vim.notify(string.format("🚀 Binary available: %s (%s)", status.path, status.type), vim.log.levels.INFO)

          -- 重新初始化核心模块
          local Core = require("astra.core")
          Core.reinitialize()
        end
      else
        vim.notify("❌ Build failed with exit code: " .. exit_code, vim.log.levels.ERROR)
        vim.notify("💡 Please check if Rust toolchain is installed", vim.log.levels.WARN)
      end
    end
  })

  if job <= 0 then
    vim.notify("❌ Failed to start build process", vim.log.levels.ERROR)
  end
end

-- 安装预编译二进制文件
function M.install()
  vim.notify("📦 Installing precompiled Astra core binary...", vim.log.levels.INFO)

  -- 这里可以实现从 GitHub Releases 下载预编译版本
  -- 暂时提示用户手动构建
  vim.notify("🔧 Precompiled binaries not yet available", vim.log.levels.WARN)
  vim.notify("💡 Please run :AstraBuild to compile from source", vim.log.levels.INFO)

  -- 检查系统信息
  local system_info = {
    os = vim.loop.os_uname().sysname,
    arch = vim.loop.os_uname().machine
  }

  vim.notify(string.format("📊 System: %s %s", system_info.os, system_info.arch), vim.log.levels.INFO)
end

-- 显示二进制信息
function M.info()
  local status = M.validate()

  vim.notify("🔍 Astra Binary Information:", vim.log.levels.INFO)
  vim.notify("  Available: " .. (status.available and "✅ Yes" or "❌ No"), vim.log.levels.INFO)

  if status.available then
    vim.notify("  Path: " .. status.path, vim.log.levels.INFO)
    vim.notify("  Version: " .. status.version, vim.log.levels.INFO)
    vim.notify("  Type: " .. status.type, vim.log.levels.INFO)
  else
    vim.notify("  Reason: " .. status.reason, vim.log.levels.WARN)
    vim.notify("  Suggestion: " .. status.suggestion, vim.log.levels.INFO)
  end

  -- 显示构建路径信息
  vim.notify("\n📁 Search Paths:", vim.log.levels.DEBUG)
  local plugin_dir = M.paths.plugin
  local paths_to_check = {
    "Local debug: " .. vim.fn.getcwd() .. "/astra-core/target/debug/astra-core",
    "Plugin debug: " .. plugin_dir .. "/astra-core/target/debug/astra-core",
    "Plugin release: " .. plugin_dir .. "/astra-core/target/release/astra-core",
    "Plugin static: " .. plugin_dir .. "/astra-core/target/x86_64-unknown-linux-musl/release/astra-core"
  }

  for _, path in ipairs(paths_to_check) do
    local exists = vim.fn.executable(path:match(": (.+)")) == 1
    vim.notify("  " .. (exists and "✅" or "❌") .. " " .. path, vim.log.levels.DEBUG)
  end
end

-- 清理构建文件
function M.clean()
  local plugin_dir = M.paths.plugin
  local clean_cmd = string.format("cd %s && make clean", plugin_dir)

  vim.notify("🧹 Cleaning build files...", vim.log.levels.INFO)

  local job = vim.fn.jobstart(clean_cmd, {
    on_exit = function(_, exit_code)
      if exit_code == 0 then
        vim.notify("✅ Build files cleaned successfully!", vim.log.levels.INFO)
      else
        vim.notify("❌ Clean failed with exit code: " .. exit_code, vim.log.levels.ERROR)
      end
    end
  })
end

return M