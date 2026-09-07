-- Keep zoxide database in sync with yazi navigation
require("zoxide"):setup({
  update_db = true,
})

-- Sync yanked files across yazi instances
require("session"):setup({
  sync_yanked = true,
})
