-- Treesitter Syntax Config
require("nvim-treesitter.configs").setup({
  ensure_installed = {
    "lua",
    "python",
    "javascript",
    "typescript",
    "bash",
    "dockerfile",
    "markdown",
    "markdown_inline",
    "yaml",
    "json",
    "toml",
    "git_config",
  },
  auto_install = true,
  highlight = {
    enable = true,
    additional_vim_regex_highlighting = false,
  },
  indent = { enable = true },
})
