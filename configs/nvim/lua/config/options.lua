-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

local opt = vim.opt

opt.relativenumber = true -- Relative line numbers
opt.number = true -- Print line number

-- Better search
opt.ignorecase = true
opt.smartcase = true

-- Appearance
opt.termguicolors = true
opt.signcolumn = "yes"

-- Split behavior
opt.splitright = true
opt.splitbelow = true

-- Clipboard integration
opt.clipboard = "unnamedplus"


