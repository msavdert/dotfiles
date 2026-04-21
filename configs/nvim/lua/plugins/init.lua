-- Bootstrap lazy.nvim
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

-- Define Plugins
require("lazy").setup({
  -- UI & Essentials
  { "catppuccin/nvim", name = "catppuccin", priority = 1000, config = function() require("plugins.configs.others") end },
  { "nvim-lualine/lualine.nvim", dependencies = { "nvim-tree/nvim-web-devicons" } },
  { "nvim-tree/nvim-tree.lua", dependencies = { "nvim-tree/nvim-web-devicons" } },
  { "goolord/alpha-nvim" },
  { "lukas-reineke/indent-blankline.nvim", main = "ibl" },

  -- Navigation & Search
  { 
    "nvim-telescope/telescope.nvim", 
    branch = "0.1.x", 
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function() require("plugins.configs.telescope") end
  },

  -- Treesitter
  { 
    "nvim-treesitter/nvim-treesitter", 
    build = ":TSUpdate",
    config = function() require("plugins.configs.treesitter") end
  },

  -- LSP & Completion
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      "williamboman/mason.nvim",
      "williamboman/mason-lspconfig.nvim",
      "hrsh7th/nvim-cmp",
      "hrsh7th/cmp-nvim-lsp",
      "L3MON4D3/LuaSnip",
      "saadparwaiz1/cmp_luasnip",
      "rafamadriz/friendly-snippets",
    },
    config = function() require("plugins.configs.lsp") end
  },

  -- Git & UX
  { "lewis6991/gitsigns.nvim" },
  { "folke/which-key.nvim" },
  { "numToStr/Comment.nvim" },
})
