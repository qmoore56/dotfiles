return {
  "neovim/nvim-lspconfig",
  config = function()
    require("lspconfig").nixd.setup({})
  end,
}
