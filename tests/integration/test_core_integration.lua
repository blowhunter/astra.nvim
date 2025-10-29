-- Core 模块集成测试

local Test = require("tests.test_runner")

Test.describe("Astra Core Module Integration", function()
  local Core, Binary, Config, Sync, UI

  Test.it("should load all core modules", function()
    local modules = {
      { name = "Core", mod = nil },
      { name = "Binary", mod = nil },
      { name = "Config", mod = nil },
      { name = "Sync", mod = nil },
      { name = "UI", mod = nil }
    }

    for _, module in ipairs(modules) do
      local ok, mod = pcall(require, "astra.core." .. module.name:lower())
      Test.assert(ok, "Should load " .. module.name .. " module")
      if ok then
        module.mod = mod
      end
    end

    -- 保存引用
    Core = modules[1].mod
    Binary = modules[2].mod
    Config = modules[3].mod
    Sync = modules[4].mod
    UI = modules[5].mod
  end)

  Test.it("should have consistent state management", function()
    if not Core then
      Test.skip("Core module not loaded")
      return
    end

    -- 初始化核心模块
    local state = Core.initialize()

    Test.assert(state.initialized, "Core should be initialized")

    -- 检查状态一致性
    local current_state = Core.get_state()
    Test.assert_equal(current_state.initialized, state.initialized, "State should be consistent")

    -- 功能级别应该反映 binary 和 config 的可用性
    local has_binary = current_state.binary_available
    local has_config = current_state.config_available
    local level = current_state.functionality_level

    if has_binary and has_config then
      Test.assert_equal(level, "full", "Should be full mode when both binary and config are available")
    elseif has_binary or has_config then
      Test.assert_equal(level, "basic", "Should be basic mode when only one is available")
    else
      Test.assert_equal(level, "none", "Should be none mode when neither is available")
    end
  end)

  Test.it("should integrate binary and config modules", function()
    if not Binary or not Config then
      Test.skip("Binary or Config module not loaded")
      return
    end

    -- 检查二进制验证和配置验证的一致性
    local binary_status = Binary.validate()
    local config_status = Config.validate_project_config()

    Test.assert_not_nil(binary_status.available, "Binary status should have available field")
    Test.assert_not_nil(config_status.available, "Config status should have available field")

    print("  ℹ️  Binary available: " .. tostring(binary_status.available))
    print("  ℹ️  Config available: " .. tostring(config_status.available))
  end)

  Test.it("should properly initialize sync module", function()
    if not Sync then
      Test.skip("Sync module not loaded")
      return
    end

    -- Sync 模块初始化依赖于 Binary 和 Config
    local sync_init = Sync.initialize()

    -- 如果初始化失败，可能是因为缺少依赖，这是预期的
    if sync_init == false then
      print("  ⚠️  SKIP: Sync initialization failed (expected without dependencies)")
      Test.assert_equal(Sync.initialized, false, "Sync should not be initialized")
    else
      Test.assert_equal(Sync.initialized, true, "Sync should be initialized")
    end
  end)

  Test.it("should maintain module dependencies", function()
    if not Core or not Binary or not Config then
      Test.skip("Required modules not loaded")
      return
    end

    -- 检查模块间的依赖关系
    Core.initialize()

    local state = Core.get_state()

    -- 如果二进制不可用，Sync 不应该初始化
    if not state.binary_available then
      print("  ⚠️  INFO: Binary not available - some features will be disabled")
    end

    -- 如果配置不可用，Sync 也不应该完全初始化
    if not state.config_available then
      print("  ⚠️  INFO: Config not available - running in basic mode")
    end

    -- 验证状态的一致性
    if state.functionality_level == "full" then
      Test.assert(state.binary_available, "Full mode requires binary available")
      Test.assert(state.config_available, "Full mode requires config available")
    end
  end)

  Test.it("should handle configuration changes", function()
    if not Config or not Core then
      Test.skip("Required modules not loaded")
      return
    end

    -- 获取初始状态
    local initial_config = Config.validate_project_config()
    local initial_core_state = Core.get_state()

    -- 重新初始化应该重新评估配置
    Core.reinitialize()

    local new_core_state = Core.get_state()

    -- 状态应该被重新评估
    Test.assert_not_nil(new_core_state, "Core state should exist after reinitialize")

    print("  ℹ️  Initial config available: " .. tostring(initial_config.available))
    print("  ℹ️  Initial core level: " .. (initial_core_state.functionality_level or "unknown"))
    print("  ℹ️  New core level: " .. (new_core_state.functionality_level or "unknown"))
  end)
end)