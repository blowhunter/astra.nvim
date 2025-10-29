-- 端到端测试

local Test = require("tests.test_runner")

Test.describe("Astra End-to-End Workflow", function()
  local Astra

  Test.it("should load main Astra module", function()
    local ok, mod = pcall(require, "astra")
    Test.assert(ok, "Should load Astra main module")
    if ok then
      Astra = mod
    end
  end)

  Test.it("should have main API functions", function()
    if not Astra then
      Test.skip("Astra module not loaded")
      return
    end

    Test.assert_function(Astra.setup, "setup should be a function")
    Test.assert_function(Astra.check, "check should be a function")
    Test.assert_function(Astra.get_status, "get_status should be a function")
    Test.assert_function(Astra.is_available, "is_available should be a function")
  end)

  Test.it("should setup with default config", function()
    if not Astra then
      Test.skip("Astra module not loaded")
      return
    end

    local result = Astra.setup({})

    Test.assert_equal(result, Astra, "setup should return the module instance")
    Test.assert_equal(Astra._initialized, true, "Astra should be initialized")
  end)

  Test.it("should check plugin status", function()
    if not Astra then
      Test.skip("Astra module not loaded")
      return
    end

    local available = Astra.check()

    -- 可用性取决于环境
    Test.assert(type(available) == "boolean", "check should return boolean")
  end)

  Test.it("should get plugin status", function()
    if not Astra then
      Test.skip("Astra module not loaded")
      return
    end

    local status = Astra.get_status()

    Test.assert_table(status, "get_status should return a table")
    Test.assert_not_nil(status.initialized, "status should have initialized field")
    Test.assert_not_nil(status.functionality_level, "status should have functionality_level field")
    Test.assert_not_nil(status.message, "status should have message field")

    -- 验证类型
    Test.assert(type(status.initialized) == "boolean", "initialized should be boolean")
    Test.assert(type(status.functionality_level) == "string", "functionality_level should be string")
    Test.assert(type(status.message) == "string", "message should be string")
  end)

  Test.it("should check availability", function()
    if not Astra then
      Test.skip("Astra module not loaded")
      return
    end

    local available = Astra.is_available()

    -- 可用性取决于环境
    Test.assert(type(available) == "boolean", "is_available should return boolean")
  end)

  Test.it("should have configuration management", function()
    if not Astra then
      Test.skip("Astra module not loaded")
      return
    end

    Test.assert_function(Astra.get_config, "get_config should be a function")
    Test.assert_function(Astra.update_config, "update_config should be a function")

    local config = Astra.get_config()

    -- 配置可能为 nil（如果没有项目配置）
    if config ~= nil then
      Test.assert_table(config, "get_config should return table when config exists")
      print("  ℹ️  INFO: Project config found")
    else
      print("  ℹ️  INFO: No project config (expected in test environment)")
    end
  end)

  Test.it("should have default configuration", function()
    if not Astra then
      Test.skip("Astra module not loaded")
      return
    end

    Test.assert_table(Astra.default_public_config, "default_public_config should exist")

    local default = Astra.default_public_config

    -- 检查基本字段
    Test.assert_not_nil(default.port, "default config should have port")
    Test.assert_not_nil(default.auto_sync, "default config should have auto_sync")
    Test.assert_not_nil(default.sync_on_save, "default config should have sync_on_save")

    Test.assert_equal(default.port, 22, "default port should be 22")
  end)

  Test.it("should reinitialize correctly", function()
    if not Astra then
      Test.skip("Astra module not loaded")
      return
    end

    local result = Astra.reinitialize()

    Test.assert_equal(result, Astra, "reinitialize should return the module instance")
  end)
end)