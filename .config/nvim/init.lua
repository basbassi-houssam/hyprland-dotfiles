-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")

vim.api.nvim_set_hl(0, "Normal", { bg = "NONE" })
vim.api.nvim_set_hl(0, "NormalNC", { bg = "NONE" })    -- for inactive windows

vim.api.nvim_set_hl(0, "SignColumn", { bg = "NONE" })  -- for git signs, diagnostics
vim.api.nvim_set_hl(0, "EndOfBuffer", { bg = "NONE" }) -- the ~ characters
vim.api.nvim_set_hl(0, "FoldColumn", { bg = "NONE" })  -- for folds

require("tokyonight").setup({
  style = "night",
  transparent = true, -- This makes it transparent
})
