-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local map = vim.keymap.set

-- save file
map({ "n" }, "<leader>w", "<cmd>w<cr><esc>", { desc = "Save File" })

map({ "n" }, "<Bslash>t", "<cmd>GoTest ./...<cr>", { desc = "Run all tests" })
map({ "n" }, "<Bslash>c", "<cmd>GoCoverageToggle<cr>", { desc = "Annotate code with coverage" })
map({ "n" }, "<Bslash>a", "<cmd>GoAlternate!<cr>", { desc = "switch to the alternate file" })

-- search for last visual selection: visual select text, press Esc, then <C-s>
map(
  { "n" },
  "<C-s>",
  [[:<c-u>let @/=@"<cr>gvy:let [@/,@"]=[@",@/]<cr>/\V<c-r>=substitute(escape(@/,'/\'),'\n','\\n','g')<cr><cr>]],
  { desc = "Search for last visual selection" }
)
