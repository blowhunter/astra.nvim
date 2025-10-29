-- Binary 模块单元测试

local Test = require("tests.test_runner")

Test.describe("Astra Core Binary Module", function()
  local Binary

  Test.it("should load binary module", function()
    local ok, mod = pcall(require, "astra.core.binary")
    Test.assert(ok, "Binary module should load successfully")
    if ok then
      Binary = mod
    end
  end)

  Test.it("should have correct structure", function()
    if not Binary then
      Test.skip("Binary module not loaded")
      return
    end

    Test.assert_table(Binary, "Binary should be a table")
    Test.assert_function(Binary.get_binary_path, "get_binary_path should be a function")
    Test.assert_function(Binary.validate, "validate should be a function")
    Test.assert_function(Binary.build, "build should be a function")
    Test.assert_function(Binary.install, "install should be a function")
  end)

  Test.it("should have paths configuration", function()
    if not Binary then
      Test.skip("Binary module not loaded")
      return
    end

    Test.assert_table(Binary.paths, "paths should be a table")
    Test.assert_string(Binary.paths.plugin, "plugin path should be a string")
    Test.assert_string(Binary.paths.debug, "debug path should be a string")
    Test.assert_string(Binary.paths.release, "release path should be a string")
  end)

  Test.it("should validate binary correctly", function()
    if not Binary then
      Test.skip("Binary module not loaded")
      return
    end

    local status = Binary.validate()

    Test.assert_table(status, "validate should return a table")
    Test.assert_not_nil(status.available, "status should have 'available' field")
    Test.assert_not_nil(status.reason, "status should have 'reason' field")
    Test.assert_not_nil(status.suggestion, "status should have 'suggestion' field")

    -- 如果二进制文件可用，应该有更多字段
    if status.available then
      Test.assert_not_nil(status.path, "Available status should have path")
      Test.assert_not_nil(status.version, "Available status should have version")
      Test.assert_not_nil(status.type, "Available status should have type")
    end
  end)

  Test.it("should get binary path", function()
    if not Binary then
      Test.skip("Binary module not loaded")
      return
    end

    local path = Binary.get_binary_path()

    -- 二进制路径可能是 nil（如果不存在）
    if path ~= nil then
      Test.assert_string(path, "get_binary_path should return a string when binary exists")
      Test.assert(string.len(path) > 0, "Binary path should not be empty")
    end
  end)

  Test.it("should have build function", function()
    if not Binary then
      Test.skip("Binary module not loaded")
      return
    end

    Test.assert_function(Binary.build, "build should be callable")
  end)

  Test.it("should have install function", function()
    if not Binary then
      Test.skip("Binary module not loaded")
      return
    end

    Test.assert_function(Binary.install, "install should be callable")
  end)

  Test.it("should have info function", function()
    if not Binary then
      Test.skip("Binary module not loaded")
      return
    end

    Test.assert_function(Binary.info, "info should be callable")
  end)

  Test.it("should have clean function", function()
    if not Binary then
      Test.skip("Binary module not loaded")
      return
    end

    Test.assert_function(Binary.clean, "clean should be callable")
  end)
end)