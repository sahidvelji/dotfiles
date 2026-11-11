return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = {
        "csv",
        "editorconfig",
        "gotmpl",
        "hcl",
        "http",
        "hurl",
        "jq",
        "make",
        "zsh",
      },
    },
  },
  -- Language servers and tools come from mise and Homebrew on PATH.
  { "mason-org/mason.nvim", enabled = false },
  { "mason-org/mason-lspconfig.nvim", enabled = false },
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        rumdl = {},
        gopls = {
          settings = {
            gopls = {
              hints = {
                assignVariableTypes = false,
                compositeLiteralFields = false,
                compositeLiteralTypes = false,
                constantValues = false,
                functionTypeParameters = false,
                parameterNames = false,
                rangeVariableTypes = false,
              },
            },
          },
        },
      },
    },
  },
  {
    "ruifm/gitlinker.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = {},
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
