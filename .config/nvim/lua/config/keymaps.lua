-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local map = vim.keymap.set

-- save file
map({ "n" }, "<leader>w", "<cmd>w<cr><esc>", { desc = "Save File" })
-- LazyVim's longer <leader>w maps make the save wait for timeoutlen. Use
-- <C-w>c to close a window and <leader>uZ to toggle zoom instead.
pcall(vim.keymap.del, "n", "<leader>wd")
pcall(vim.keymap.del, "n", "<leader>wm")
