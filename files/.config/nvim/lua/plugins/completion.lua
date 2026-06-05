return {
  -- 1. Main Completion Engine
  {
    "hrsh7th/nvim-cmp",
    version = false, -- Last release is very old, use latest main branch
    event = "InsertEnter",
    dependencies = {
      -- 2. Snippet Engine & its associated nvim-cmp source
      {
        "L3MON4D3/LuaSnip",
        build = (function()
          -- Build step for regex support in snippets (optional but recommended)
          if vim.fn.has("win32") == 1 or vim.fn.executable("make") == 0 then
            return
          end
          return "make install_jsregexp"
        end)(),
      },
      "saadparwaiz1/cmp_luasnip",

      -- 3. Core Completion Sources
      "hrsh7th/cmp-nvim-lsp", -- LSP completion
      "hrsh7th/cmp-buffer",   -- Buffer text completion
      "hrsh7th/cmp-path",     -- File system paths completion
    },
    config = function()
      local cmp = require("cmp")
      local luasnip = require("luasnip")

      -- Optional: Loads vscode-style snippets from installed plugins (e.g., friendly-snippets)
      require("luasnip.loaders.from_vscode").lazy_load()
      luasnip.config.setup({})

      cmp.setup({
        snippet = {
          expand = function(args)
            luasnip.lsp_expand(args.body)
          end,
        },
        completion = {
          completeopt = "menu,menuone,noinsert",
        },
        
        -- Keymaps for navigating the completion menu
        mapping = cmp.mapping.preset.insert({
          ["<C-n>"] = cmp.mapping.select_next_item(), -- Next suggestion
          ["<C-p>"] = cmp.mapping.select_prev_item(), -- Previous suggestion
          ["<C-b>"] = cmp.mapping.scroll_docs(-4),    -- Scroll docs up
          ["<C-f>"] = cmp.mapping.scroll_docs(4),     -- Scroll docs down
          ["<C-Space>"] = cmp.mapping.complete({}),   -- Trigger completion menu
          ["<CR>"] = cmp.mapping.confirm({
            behavior = cmp.ConfirmBehavior.Replace,
            select = true,
          }),
          
          -- Tab mapping for navigating snippets
          ["<Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_next_item()
            elseif luasnip.expand_or_locally_jumpable() then
              luasnip.expand_or_jump()
            else
              fallback()
            end
          end, { "i", "s" }),
          ["<S-Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_prev_item()
            elseif luasnip.locally_jumpable(-1) then
              luasnip.jump(-1)
            else
              fallback()
            end
          end, { "i", "s" }),
        }),
        
        -- Define where nvim-cmp looks for data (Order defines priority)
        sources = cmp.config.sources({
          { name = "nvim_lsp" }, -- LSP first
          { name = "luasnip" },  -- Snippets second
          { name = "path" },     -- File paths third
          { name = "buffer" },   -- Text within current buffer fourth
        }),
      })
    end,
  },
}
