-- LSP & Completion Config

local mason = require("mason")
local status, mason_lspconfig = pcall(require, "mason-lspconfig")
if not status then 
  print("Waiting for mason-lspconfig...")
  return 
end
local lspconfig = require("lspconfig")
local cmp = require("cmp")

-- 1. Setup Mason
mason.setup()
mason_lspconfig.setup({
  ensure_installed = {
    "lua_ls",
    "pyright",
    "vtsls", -- modern alternative to tsserver
    "bashls",
    "dockerls",
    "marksman",
  },
})

-- 2. Setup Completion
require("luasnip.loaders.from_vscode").lazy_load()

cmp.setup({
  snippet = {
    expand = function(args)
      require("luasnip").lsp_expand(args.body)
    end,
  },
  mapping = cmp.mapping.preset.insert({
    ["<C-k>"] = cmp.mapping.select_prev_item(),
    ["<C-j>"] = cmp.mapping.select_next_item(),
    ["<C-b>"] = cmp.mapping.scroll_docs(-4),
    ["<C-f>"] = cmp.mapping.scroll_docs(4),
    ["<C-Space>"] = cmp.mapping.complete(),
    ["<C-e>"] = cmp.mapping.abort(),
    ["<CR>"] = cmp.mapping.confirm({ select = false }),
  }),
  sources = cmp.config.sources({
    { name = "nvim_lsp" },
    { name = "luasnip" },
  }, {
    { name = "buffer" },
  }),
})

-- 3. LSP Capabilities & Handlers
local capabilities = require("cmp_nvim_lsp").default_capabilities()

local on_attach = function(client, bufnr)
  local opts = { noremap = true, silent = true, buffer = bufnr }
  local keymap = vim.keymap
  
  keymap.set("n", "gD", vim.lsp.buf.declaration, opts)
  keymap.set("n", "gd", vim.lsp.buf.definition, opts)
  keymap.set("n", "K", vim.lsp.buf.hover, opts)
  keymap.set("n", "gi", vim.lsp.buf.implementation, opts)
  keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts)
  keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
  keymap.set("n", "<leader>D", vim.lsp.buf.type_definition, opts)
end

-- 4. Setup Servers
mason_lspconfig.setup_handlers({
  function(server_name)
    lspconfig[server_name].setup({
      on_attach = on_attach,
      capabilities = capabilities,
    })
  end,
  -- Custom settings for specific servers
  ["lua_ls"] = function()
    lspconfig.lua_ls.setup({
      on_attach = on_attach,
      capabilities = capabilities,
      settings = {
        Lua = {
          diagnostics = { globals = { "vim" } },
          workspace = { library = vim.api.nvim_get_runtime_file("", true) },
        },
      },
    })
  end,
})
