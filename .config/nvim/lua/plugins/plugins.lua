return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = {
        "bash",
        "csv",
        "editorconfig",
        "fish",
        "git_config",
        "git_rebase",
        "gitattributes",
        "gitignore",
        "gotmpl",
        "hcl",
        "html",
        "http",
        "hurl",
        "jq",
        "make",
        "nu",
        "toml",
        "zsh",
      },
    },
  },
  {
    "ruifm/gitlinker.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      require("gitlinker").setup({
        opts = {
          remote = nil, -- force the use of a specific remote
          -- adds current line nr in the url for normal mode
          add_current_line_on_normal_mode = true,
          -- callback for what to do with the url
          action_callback = require("gitlinker.actions").copy_to_clipboard,
          -- print the url after performing the action
          print_url = true,
        },
        -- default mapping to call url generation with action_callback
        mappings = "<leader>gy",
      })
    end,
  },
  {
    "tpope/vim-abolish",
  },
  {
    "tpope/vim-repeat",
  },
  {
    "fatih/vim-go",
    ft = "go",
    -- `ft` makes these buffer-local to Go, where vim-go's commands exist.
    keys = {
      { "<Bslash>t", "<cmd>GoTest ./...<cr>", ft = "go", desc = "Run all tests" },
      { "<Bslash>c", "<cmd>GoCoverageToggle<cr>", ft = "go", desc = "Annotate code with coverage" },
      { "<Bslash>a", "<cmd>GoAlternate!<cr>", ft = "go", desc = "switch to the alternate file" },
    },
    init = function()
      vim.g.go_def_mapping_enabled = 0
      vim.g.go_gopls_enabled = 0
      vim.g.go_doc_keywordprg_enabled = 0
      vim.g.go_textobj_enabled = 0
      vim.g.go_fmt_autosave = 0
    end,
  },
  {
    "tpope/vim-surround",
    keys = { "c", "d", "y" },
  },
}
