-- Themes & UI Config
require("catppuccin").setup({
  flavour = "mocha", -- latte, frappe, macchiato, mocha
})
vim.cmd.colorscheme("catppuccin")

-- Lualine
require("lualine").setup({
  options = {
    theme = "catppuccin",
    section_separators = { left = "", right = "" },
    component_separators = { left = "", right = "" },
  },
})

-- Nvim-Tree
require("nvim-tree").setup({
  view = {
    width = 30,
  },
  renderer = {
    group_empty = true,
  },
})

-- Alpha (Dashboard)
local alpha = require("alpha")
local dashboard = require("alpha.themes.dashboard")
dashboard.section.header.val = {
  [[          ▀████▀▄▄              ▄█ ]],
  [[            █▀    ▀▀▄▄▄▄▄    ▄▄▀▀█ ]],
  [[    ▄        █          ▀▀▀▀▀  ▄▀  ]],
  [[   ▄▀ ▀▄      ▀▄              █    ]],
  [[  Local  ▀▄▄    █          ▄▀▀      ]],
  [[   Workspace ▀▀▄▄█        ▄▀       ]],
  [[            ▄▀▀█▀▀▀▄    ▄▀         ]],
  [[           █    █   ▀▀▀▀           ]],
}
alpha.setup(dashboard.config)

-- Which-key
require("which-key").setup()

-- Comment
require("Comment").setup()

-- Gitsigns
require("gitsigns").setup()

-- Indent lines
require("ibl").setup()
