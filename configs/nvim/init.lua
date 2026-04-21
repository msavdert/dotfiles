-- Main Neovim Configuration Entrypoint

-- 1. Load Core Settings
require("core.options")
require("core.keymaps")

-- 2. Setup Plugin Manager (Lazy.nvim)
require("plugins.init")
