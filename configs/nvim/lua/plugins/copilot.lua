return {
  "github/copilot.vim",
  event = "InsertEnter",
  config = function()
    -- Tab ile onaylamayı aktifleştirmek için (bazı durumlarda gerekir)
    vim.g.copilot_no_tab_map = true
    vim.api.nvim_set_keymap("i", "<C-J>", 'copilot#Accept("<CR>")', { silent = true, expr = true })
  end,
}
