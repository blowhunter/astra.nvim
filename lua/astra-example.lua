local astra = require("astra")

astra.setup({
    host = "your-server.com",
    username = "your-username",
    password = "your-password",  -- or use private_key_path
    private_key_path = "/path/to/private/key",
    remote_path = "/remote/directory",
    local_path = vim.loop.cwd(),
    auto_sync = false,           -- Enable auto sync
    sync_on_save = true,         -- Sync on file save
    sync_interval = 30000,       -- Sync every 30 seconds
})