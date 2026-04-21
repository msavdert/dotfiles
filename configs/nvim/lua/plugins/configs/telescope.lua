-- Telescope Search Config
local builtin = require("telescope.builtin")
local keymap = vim.keymap

require("telescope").setup({
  defaults = {
    path_display = { "truncate " },
    mappings = {
      i = {
        ["<C-k>"] = require("telescope.actions").move_selection_previous,
        ["<C-j>"] = require("telescope.actions").move_selection_next,
        ["<C-q>"] = require("telescope.actions").send_selected_to_qflist + require("telescope.actions").open_qflist,
      },
    },
  },
})

-- Keymaps
keymap.set("n", "<leader>ff", builtin.find_files, { desc = "Fuzzy find files in cwd" })
keymap.set("n", "<leader>fr", builtin.oldfiles, { desc = "Fuzzy find recent files" })
keymap.set("n", "<leader>fs", builtin.live_grep, { desc = "Find string in cwd" })
keymap.set("n", "<leader>fc", builtin.grep_string, { desc = "Find string under cursor" })
keymap.set("n", "<leader>fb", builtin.buffers, { desc = "List open buffers" })
keymap.set("n", "<leader>fh", builtin.help_tags, { desc = "List help tags" })
