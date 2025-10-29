-- UI 模块单元测试

local Test = require("tests.test_runner")

Test.describe("Astra Core UI Module", function()
  local UI

  Test.it("should load ui module", function()
    local ok, mod = pcall(require, "astra.core.ui")
    Test.assert(ok, "UI module should load successfully")
    if ok then
      UI = mod
    end
  end)

  Test.it("should have correct structure", function()
    if not UI then
      Test.skip("UI module not loaded")
      return
    end

    Test.assert_table(UI, "UI should be a table")
    Test.assert_table(UI.notification_config, "notification_config should be a table")
    Test.assert_table(UI.notification_history, "notification_history should be a table")
    Test.assert_table(UI.notification_queue, "notification_queue should be a table")
  end)

  Test.it("should have notification configuration", function()
    if not UI then
      Test.skip("UI module not loaded")
      return
    end

    local config = UI.notification_config

    Test.assert_not_nil(config.max_history, "notification_config should have max_history")
    Test.assert_not_nil(config.display_duration, "notification_config should have display_duration")
    Test.assert_not_nil(config.position, "notification_config should have position")
    Test.assert_not_nil(config.max_width, "notification_config should have max_width")

    Test.assert_number(config.max_history, "max_history should be a number")
    Test.assert_number(config.display_duration, "display_duration should be a number")
    Test.assert_number(config.max_width, "max_width should be a number")
  end)

  Test.it("should have notification functions", function()
    if not UI then
      Test.skip("UI module not loaded")
      return
    end

    Test.assert_function(UI.smart_notify, "smart_notify should be a function")
    Test.assert_function(UI.create_floating_notification, "create_floating_notification should be a function")
    Test.assert_function(UI.is_duplicate_notification, "is_duplicate_notification should be a function")
    Test.assert_function(UI.add_to_history, "add_to_history should be a function")
    Test.assert_function(UI.process_notification_queue, "process_notification_queue should be a function")
  end)

  Test.it("should have help and status functions", function()
    if not UI then
      Test.skip("UI module not loaded")
      return
    end

    Test.assert_function(UI.show_help, "show_help should be a function")
    Test.assert_function(UI.generate_help_content, "generate_help_content should be a function")
    Test.assert_function(UI.show_status, "show_status should be a function")
  end)

  Test.it("should have utility functions", function()
    if not UI then
      Test.skip("UI module not loaded")
      return
    end

    Test.assert_function(UI.calculate_notification_dimensions, "calculate_notification_dimensions should be a function")
    Test.assert_function(UI.get_notification_title, "get_notification_title should be a function")
    Test.assert_function(UI.setup_notification_highlight, "setup_notification_highlight should be a function")
    Test.assert_function(UI.fade_out_notification, "fade_out_notification should be a function")
  end)

  Test.it("should generate help content correctly", function()
    if not UI then
      Test.skip("UI module not loaded")
      return
    end

    local content = UI.generate_help_content("full")

    Test.assert_table(content, "generate_help_content should return a table")
    Test.assert(#content > 0, "help content should not be empty")

    -- 检查是否包含基本元素
    local has_title = false
    local has_commands = false

    for _, line in ipairs(content) do
      if line:match("Astra") and line:match("SFTP") then
        has_title = true
      end
      if line:match(":Astra") then
        has_commands = true
      end
    end

    Test.assert(has_title, "help content should include title")
    Test.assert(has_commands, "help content should include commands")
  end)

  Test.it("should have correct initial state", function()
    if not UI then
      Test.skip("UI module not loaded")
      return
    end

    Test.assert_equal(UI.notification_running, false, "notification_running should be false initially")
    Test.assert_table(UI.notification_queue, "notification_queue should be an empty table initially")
  end)
end)