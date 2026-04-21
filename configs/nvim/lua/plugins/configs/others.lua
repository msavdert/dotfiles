-- Themes & UI Config
local status_cat, catppuccin = pcall(require, "catppuccin")
if status_cat then
  catppuccin.setup({
    flavour = "mocha",
  })
  vim.cmd.colorscheme("catppuccin")
end

-- Lualine
local status_lua, lualine = pcall(require, "lualine")
if status_lua then
  lualine.setup({
    options = {
      theme = "catppuccin",
      section_separators = { left = "", right = "" },
      component_separators = { left = "", right = "" },
    },
  })
end

-- Nvim-Tree
local status_tree, nvimtree = pcall(require, "nvim-tree")
if status_tree then
  nvimtree.setup({
    view = { width = 30 },
    renderer = { group_empty = true },
  })
end

-- Alpha (Dashboard)
local status_alpha, alpha = pcall(require, "alpha")
if status_alpha then
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
end

-- Misc UI
pcall(function() require("which-key").setup() end)
pcall(function() require("Comment").setup() end)
pcall(function() require("gitsigns").setup() end)
pcall(function() require("ibl").setup() end)
