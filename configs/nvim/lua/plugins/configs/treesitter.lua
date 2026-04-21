-- Treesitter Syntax Config
local status, treesitter = pcall(require, "nvim-treesitter.configs")
if not status then 
  print("Waiting for nvim-treesitter...")
  return 
end

treesitter.setup({
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
