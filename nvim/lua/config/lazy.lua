-- nvim/lua/config/lazy.lua

-- Create the data directory for nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- Set leader key to space
vim.g.mapleader = " "

require("lazy").setup({
  spec = {
    -- Import all plugin files from lua/plugins
    { import = "plugins" },
    
    -- Essential core plugins (inline for simplicity)
    "nvim-lua/plenary.nvim",
    "folke/which-key.nvim",
  },
  defaults = {
    lazy = false, -- Don't lazy-load by default
    version = false, -- Use latest commits
  },
  checker = { enabled = true }, -- Automatically check for updates
  performance = {
    rtp = {
      disabled_plugins = {
        "gzip",
        "tarPlugin",
        "tohtml",
        "tutor",
        "zipPlugin",
      },
    },
  },
})
