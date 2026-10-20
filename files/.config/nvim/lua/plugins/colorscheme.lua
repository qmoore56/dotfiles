-- Black background with the purple accent from the sway config (client.focused #660066).
local black = "#000000"
local purple = "#660066" -- sway focused border; used for backgrounds/borders
local purple_light = "#c46bc4" -- same hue, readable as text on black

return {
  {
    "folke/tokyonight.nvim",
    opts = {
      style = "night",
      on_colors = function(c)
        c.bg = black
        c.bg_dark = black
        c.bg_dark1 = black
        c.bg_float = black
        c.bg_popup = black
        c.bg_sidebar = black
        c.bg_statusline = black
        c.bg_highlight = "#1a001a"
        c.bg_visual = purple
        c.border = purple
        c.border_highlight = purple
        c.magenta = purple_light
        c.purple = purple_light
      end,
      on_highlights = function(hl, c)
        hl.WinSeparator = { fg = purple }
        hl.FloatBorder = { fg = purple, bg = black }
        hl.CursorLineNr = { fg = purple_light, bold = true }
        hl.Visual = { bg = purple }
        hl.Search = { bg = purple, fg = c.fg }
        hl.IncSearch = { bg = purple_light, fg = black }
        hl.CurSearch = { bg = purple_light, fg = black }
        hl.PmenuSel = { bg = purple, fg = c.fg }
        hl.TabLineSel = { bg = purple, fg = c.fg }
        hl.BufferLineIndicatorSelected = { fg = purple_light }
        hl.SnacksIndentScope = { fg = purple_light }
        hl.MatchParen = { fg = purple_light, bold = true }
      end,
    },
  },
  {
    "nvim-lualine/lualine.nvim",
    opts = function(_, opts)
      local theme = vim.deepcopy(require("lualine.themes.tokyonight"))
      theme.normal.a = { bg = purple, fg = "#ffffff", gui = "bold" }
      theme.normal.b = { bg = "#1a001a", fg = purple_light }
      for _, mode in pairs(theme) do
        mode.c = { bg = black, fg = mode.c and mode.c.fg or "#c0caf5" }
      end
      opts.options = opts.options or {}
      opts.options.theme = theme
    end,
  },
}
