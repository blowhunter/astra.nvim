return {
  "blowhunter/astra.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "j-hui/fidget.nvim", -- 用于更好的状态通知
  },
  lazy = false, -- 立即加载，因为需要初始化配置
  priority = 100, -- 高优先级确保早期加载
  debug = false,

  -- 纯粹的配置部分，所有业务逻辑都在插件端实现
  config = function()
    require("astra").setup({
      -- 基础连接配置（主要依赖自动配置发现）
      host = "",
      port = 22,
      username = "",
      password = nil,
      private_key_path = nil,
      remote_path = "",
      local_path = vim.fn.getcwd(),

      -- 同步配置
      auto_sync = false,
      sync_on_save = true,
      sync_interval = 30000,

      -- 构建配置
      static_build = false,
    })
  end,
}