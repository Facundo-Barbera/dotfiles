-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- Enable format on save
vim.g.autoformat = true

-- Enable text wrapping
vim.opt.wrap = true
vim.opt.breakindent = true -- Wrapped lines maintain indent level

-- Enable spell checking for Spanish and English
vim.opt.spell = true
vim.opt.spelllang = { "en", "es" }
