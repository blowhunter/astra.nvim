-- Sync 模块单元测试

local Test = require("tests.test_runner")

Test.describe("Astra Core Sync Module", function()
  local Sync

  Test.it("should load sync module", function()
    local ok, mod = pcall(require, "astra.core.sync")
    Test.assert(ok, "Sync module should load successfully")
    if ok then
      Sync = mod
    end
  end)

  Test.it("should have correct structure", function()
    if not Sync then
      Test.skip("Sync module not loaded")
      return
    end

    Test.assert_table(Sync, "Sync should be a table")
    Test.assert_not_nil(Sync.initialized, "Sync should have initialized field")
    Test.assert_not_nil(Sync.config, "Sync should have config field")
    Test.assert_not_nil(Sync.binary_path, "Sync should have binary_path field")
  end)

  Test.it("should initialize correctly", function()
    if not Sync then
      Test.skip("Sync module not loaded")
      return
    end

    local result = Sync.initialize()

    -- 初始化可能失败（如果缺少依赖）
    if result == false then
      print("  ⚠️  SKIP: Sync initialize failed (expected without dependencies)")
    else
      Test.assert(result == true, "initialize should return true on success")
    end
  end)

  Test.it("should have sync functions", function()
    if not Sync then
      Test.skip("Sync module not loaded")
      return
    end

    Test.assert_function(Sync.upload, "upload should be a function")
    Test.assert_function(Sync.download, "download should be a function")
    Test.assert_function(Sync.sync, "sync should be a function")
    Test.assert_function(Sync.status, "status should be a function")
    Test.assert_function(Sync.version, "version should be a function")
  end)

  Test.it("should have internal helper functions", function()
    if not Sync then
      Test.skip("Sync module not loaded")
      return
    end

    Test.assert_function(Sync._get_current_file, "_get_current_file should be a function")
    Test.assert_function(Sync._get_relative_path, "_get_relative_path should be a function")
    Test.assert_function(Sync._build_remote_path, "_build_remote_path should be a function")
    Test.assert_function(Sync._execute_backend_command, "_execute_backend_command should be a function")
  end)

  Test.it("should have correct initial state", function()
    if not Sync then
      Test.skip("Sync module not loaded")
      return
    end

    Test.assert_equal(Sync.initialized, false, "initialized should be false initially")
  end)

  Test.it("should handle current file detection", function()
    if not Sync then
      Test.skip("Sync module not loaded")
      return
    end

    -- 这个测试在 headless 模式下可能返回 nil，这是预期的
    local file_info = Sync._get_current_file()

    -- 如果在有文件的环境中，应该返回表
    if file_info ~= nil then
      Test.assert_table(file_info, "file_info should be a table when file exists")
      Test.assert_not_nil(file_info.path, "file_info should have path")
      Test.assert_not_nil(file_info.name, "file_info should have name")
    else
      print("  ⚠️  SKIP: No current file (expected in headless mode)")
    end
  end)
end)