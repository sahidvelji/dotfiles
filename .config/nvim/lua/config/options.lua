-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

vim.opt.whichwrap = "b,s"
vim.opt.wrap = true

-- Disable cursor blinking in terminal mode
vim.opt.guicursor:append("t:block-blinkon0")
-- Prevent programs inside the Neovim terminal from changing the cursor shape
vim.g.terminal_set_colors = 0
