-- nvim/lua/config/keymaps.lua
local keymap = vim.keymap

-- Use jk to exit insert mode
keymap.set("i", "jk", "<ESC>", { desc = "Exit insert mode" })

-- Better navigation
keymap.set("n", "<C-h>", "<C-w>h", { desc = "Move to left window" })
keymap.set("n", "<C-j>", "<C-w>j", { desc = "Move to bottom window" })
keymap.set("n", "<C-k>", "<C-w>k", { desc = "Move to top window" })
keymap.set("n", "<C-l>", "<C-w>l", { desc = "Move to right window" })

-- Clear search highlights
keymap.set("n", "<leader>h", ":nohl<CR>", { desc = "Clear search highlights" })

-- File explorer (standard fallback)
keymap.set("n", "<leader>e", ":Lex 30<CR>", { desc = "Vertical File Explorer" })

-- Indentation
keymap.set("v", "<", "<gv", { desc = "Shift left" })
keymap.set("v", ">", ">gv", { desc = "Shift right" })
