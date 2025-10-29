-- Astra.nvim 测试运行器
-- 整合所有测试用例，提供统一的测试接口

local M = {}

-- 测试统计
M.results = {
  total = 0,
  passed = 0,
  failed = 0,
  skipped = 0,
  tests = {}
}

-- 跳过测试
function M.skip(message)
  M.results.skipped = M.results.skipped + 1
  print("  ⏭️  SKIP: " .. (message or "Test skipped"))
  return true
end

-- 断言函数
function M.assert(condition, message)
  M.results.total = M.results.total + 1

  if condition then
    M.results.passed = M.results.passed + 1
    print("  ✅ PASS: " .. (message or "Test passed"))
    return true
  else
    M.results.failed = M.results.failed + 1
    print("  ❌ FAIL: " .. (message or "Test failed"))
    return false
  end
end

function M.assert_equal(actual, expected, message)
  local success = actual == expected
  M.assert(success, message or ("Expected: " .. tostring(expected) .. ", Got: " .. tostring(actual)))
  return success
end

function M.assert_not_equal(actual, expected, message)
  local success = actual ~= expected
  M.assert(success, message or ("Expected not: " .. tostring(expected) .. ", Got: " .. tostring(actual)))
  return success
end

function M.assert_nil(value, message)
  M.assert(value == nil, message or ("Expected nil, got: " .. tostring(value)))
  return value == nil
end

function M.assert_not_nil(value, message)
  M.assert(value ~= nil, message or ("Expected not nil, got: " .. tostring(value)))
  return value ~= nil
end

function M.assert_table(t, message)
  local success = type(t) == "table"
  M.assert(success, message or ("Expected table, got: " .. type(t)))
  return success
end

function M.assert_string(s, message)
  local success = type(s) == "string"
  M.assert(success, message or ("Expected string, got: " .. type(s)))
  return success
end

function M.assert_number(n, message)
  local success = type(n) == "number"
  M.assert(success, message or ("Expected number, got: " .. type(n)))
  return success
end

function M.assert_function(f, message)
  local success = type(f) == "function"
  M.assert(success, message or ("Expected function, got: " .. type(f)))
  return success
end

-- 测试套件管理
function M.describe(name, fn)
  print("\n📋 Test Suite: " .. name)
  print("=" .. string.rep("=", 50))
  fn()
end

function M.it(name, fn)
  print("\n🧪 Test: " .. name)
  fn()
end

-- 运行测试文件
function M.run_test_file(filepath)
  print("\n" .. string.rep("=", 60))
  print("🔍 Running: " .. filepath)
  print(string.rep("=", 60))

  local ok, err = pcall(dofile, filepath)
  if not ok then
    print("❌ Error loading test file: " .. err)
    return false
  end
  return true
end

-- 运行目录中的所有测试
function M.run_tests_in_directory(dirpath)
  local handle = io.popen("find '" .. dirpath .. "' -name '*.lua' -type f")
  if not handle then
    print("❌ Failed to open directory: " .. dirpath)
    return false
  end

  local files = handle:read("*all")
  handle:close()

  for filepath in files:gmatch("[^\n]+") do
    M.run_test_file(filepath)
  end

  return true
end

-- 运行所有测试
function M.run_all_tests()
  print("\n" .. string.rep("=", 60))
  print("🚀 Astra.nvim Test Suite")
  print(string.rep("=", 60))

  M.results = {
    total = 0,
    passed = 0,
    failed = 0,
    tests = {}
  }

  -- 重置计数器
  M.results.total = 0
  M.results.passed = 0
  M.results.failed = 0

  -- 运行所有测试类型
  M.run_tests_in_directory("./tests/unit")
  M.run_tests_in_directory("./tests/integration")
  M.run_tests_in_directory("./tests/e2e")

  -- 显示结果
  print("\n" .. string.rep("=", 60))
  print("📊 Test Results Summary")
  print(string.rep("=", 60))
  print("Total Tests:  " .. M.results.total)
  print("✅ Passed:     " .. M.results.passed)
  print("❌ Failed:     " .. M.results.failed)
  print("⏭️  Skipped:    " .. M.results.skipped)

  local success_rate = 0
  if M.results.total > 0 then
    success_rate = (M.results.passed / M.results.total) * 100
  end
  print("Success Rate: " .. string.format("%.1f%%", success_rate))

  if M.results.failed > 0 then
    print("\n❌ Some tests failed!")
    return false
  else
    print("\n✅ All tests passed!")
    return true
  end
end

return M