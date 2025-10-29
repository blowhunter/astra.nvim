-- Config 模块单元测试

local Test = require("tests.test_runner")

Test.describe("Astra Core Config Module", function()
  local Config

  Test.it("should load config module", function()
    local ok, mod = pcall(require, "astra.core.config")
    Test.assert(ok, "Config module should load successfully")
    if ok then
      Config = mod
    end
  end)

  Test.it("should have correct structure", function()
    if not Config then
      Test.skip("Config module not loaded")
      return
    end

    Test.assert_table(Config, "Config should be a table")
    Test.assert_table(Config.default_config, "default_config should be a table")
    Test.assert_table(Config.project_config_files, "project_config_files should be a table")
  end)

  Test.it("should have default configuration", function()
    if not Config then
      Test.skip("Config module not loaded")
      return
    end

    local default = Config.default_config

    -- 检查基本字段
    Test.assert_not_nil(default.host, "default_config should have host field")
    Test.assert_not_nil(default.port, "default_config should have port field")
    Test.assert_not_nil(default.username, "default_config should have username field")
    Test.assert_not_nil(default.remote_path, "default_config should have remote_path field")

    -- 检查功能开关
    Test.assert_not_nil(default.auto_sync, "default_config should have auto_sync field")
    Test.assert_not_nil(default.sync_on_save, "default_config should have sync_on_save field")

    -- 检查过滤配置
    Test.assert_table(default.exclude_patterns, "default_config should have exclude_patterns table")
    Test.assert_table(default.include_patterns, "default_config should have include_patterns table")
  end)

  Test.it("should have project config files list", function()
    if not Config then
      Test.skip("Config module not loaded")
      return
    end

    Test.assert(#Config.project_config_files > 0, "project_config_files should not be empty")

    -- 检查优先级排序
    local has_astra_toml = false
    for _, filename in ipairs(Config.project_config_files) do
      if filename == ".astra.toml" then
        has_astra_toml = true
        break
      end
    end
    Test.assert(has_astra_toml, "project_config_files should include .astra.toml")
  end)

  Test.it("should validate project configuration", function()
    if not Config then
      Test.skip("Config module not loaded")
      return
    end

    local status = Config.validate_project_config()

    Test.assert_table(status, "validate_project_config should return a table")
    Test.assert_not_nil(status.available, "status should have 'available' field")
    Test.assert_not_nil(status.reason, "status should have 'reason' field")
    Test.assert_not_nil(status.suggestion, "status should have 'suggestion' field")

    -- 如果配置文件可用，应该有更多字段
    if status.available then
      Test.assert_not_nil(status.path, "Available status should have path")
      Test.assert_not_nil(status.format, "Available status should have format")
      Test.assert_not_nil(status.config, "Available status should have config")
    end
  end)

  Test.it("should discover project configuration", function()
    if not Config then
      Test.skip("Config module not loaded")
      return
    end

    local config_info = Config.discover_project_config()

    -- 可能为 nil（如果当前目录没有配置文件）
    if config_info ~= nil then
      Test.assert_table(config_info, "discover_project_config should return table when found")
      Test.assert_not_nil(config_info.path, "config_info should have path")
      Test.assert_not_nil(config_info.filename, "config_info should have filename")
      Test.assert_not_nil(config_info.format, "config_info should have format")

      Test.assert_string(config_info.path, "path should be a string")
      Test.assert_string(config_info.filename, "filename should be a string")
      Test.assert_string(config_info.format, "format should be a string")
    end
  end)

  Test.it("should detect configuration format", function()
    if not Config then
      Test.skip("Config module not loaded")
      return
    end

    local toml_format = Config._detect_format("test.toml")
    Test.assert_equal(toml_format, "toml", "Should detect TOML format")

    local json_format = Config._detect_format("test.json")
    Test.assert_equal(json_format, "json", "Should detect JSON format")

    local unknown_format = Config._detect_format("test.txt")
    Test.assert_equal(unknown_format, "unknown", "Should return unknown for unsupported formats")
  end)

  Test.it("should have configuration functions", function()
    if not Config then
      Test.skip("Config module not loaded")
      return
    end

    Test.assert_function(Config.init_project_config, "init_project_config should be a function")
    Test.assert_function(Config.quick_setup, "quick_setup should be a function")
    Test.assert_function(Config.info, "info should be a function")
    Test.assert_function(Config.merge_config, "merge_config should be a function")
  end)
end)