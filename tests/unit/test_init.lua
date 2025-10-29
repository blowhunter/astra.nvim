-- Init 模块单元测试

local Test = require("tests.test_runner")

Test.describe("Astra Core Init Module", function()
  local Core

  Test.it("should load init module", function()
    local ok, mod = pcall(require, "astra.core")
    Test.assert(ok, "Core module should load successfully")
    if ok then
      Core = mod
    end
  end)

  Test.it("should have correct structure", function()
    if not Core then
      Test.skip("Core module not loaded")
      return
    end

    Test.assert_table(Core, "Core should be a table")
    Test.assert_table(Core.state, "Core should have state table")
  end)

  Test.it("should have correct state structure", function()
    if not Core then
      Test.skip("Core module not loaded")
      return
    end

    local state = Core.state

    Test.assert_not_nil(state.initialized, "state should have initialized field")
    Test.assert_not_nil(state.binary_available, "state should have binary_available field")
    Test.assert_not_nil(state.config_available, "state should have config_available field")
    Test.assert_not_nil(state.functionality_level, "state should have functionality_level field")

    -- 验证类型
    Test.assert(type(state.initialized) == "boolean", "initialized should be boolean")
    Test.assert(type(state.binary_available) == "boolean", "binary_available should be boolean")
    Test.assert(type(state.config_available) == "boolean", "config_available should be boolean")
    Test.assert(type(state.functionality_level) == "string", "functionality_level should be string")
  end)

  Test.it("should initialize correctly", function()
    if not Core then
      Test.skip("Core module not loaded")
      return
    end

    local result = Core.initialize()

    Test.assert_table(result, "initialize should return a table")

    if result.initialized then
      Test.assert(type(result.functionality_level) == "string", "initialized state should have functionality_level")
    end
  end)

  Test.it("should have public interface functions", function()
    if not Core then
      Test.skip("Core module not loaded")
      return
    end

    Test.assert_function(Core.initialize, "initialize should be a function")
    Test.assert_function(Core.get_state, "get_state should be a function")
    Test.assert_function(Core.reinitialize, "reinitialize should be a function")
  end)

  Test.it("should have correct initial state", function()
    if not Core then
      Test.skip("Core module not loaded")
      return
    end

    -- 初始化前状态检查
    Test.assert_equal(Core.state.initialized, false, "initialized should be false initially")
  end)

  Test.it("should determine functionality level correctly", function()
    if not Core then
      Test.skip("Core module not loaded")
      return
    end

    -- 初始化以确定功能级别
    Core.initialize()

    local level = Core.state.functionality_level
    Test.assert_not_nil(level, "functionality_level should be set")
    Test.assert(string.len(level) > 0, "functionality_level should not be empty")

    -- 验证功能级别是预期的值之一
    local valid_levels = {"none", "basic", "full"}
    local is_valid = false

    for _, valid_level in ipairs(valid_levels) do
      if level == valid_level then
        is_valid = true
        break
      end
    end

    Test.assert(is_valid, "functionality_level should be one of: none, basic, full")
  end)

  Test.it("should handle reinitialize correctly", function()
    if not Core then
      Test.skip("Core module not loaded")
      return
    end

    -- 第一次初始化
    Core.initialize()
    local first_level = Core.state.functionality_level

    -- 重新初始化
    Core.reinitialize()
    local second_level = Core.state.functionality_level

    -- 功能级别应该相同或重新计算
    Test.assert_not_nil(second_level, "reinitialize should set functionality_level")

    print("  ℹ️  INFO: First level: " .. first_level .. ", Second level: " .. second_level)
  end)
end)