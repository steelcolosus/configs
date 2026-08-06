return {
    "nvim-treesitter/nvim-treesitter",
    -- `master` is the backward-compatible branch for Neovim 0.11.
    -- The `main` rewrite requires Neovim 0.12+.
    branch = "master",
    lazy = false,
    build = ":TSUpdate",
    dependencies = {
        { "windwp/nvim-ts-autotag", opts = {} },
    },
    config = function()
        local treesitter = require("nvim-treesitter")

        treesitter.setup({
            highlight = {
                enable = true,
            },
            indent = { enable = true },
            ensure_installed = {
                "json",
                "javascript",
                "typescript",
                "tsx",
                "yaml",
                "html",
                "css",
                "prisma",
                "markdown",
                "make",
                "markdown_inline",
                "svelte",
                "graphql",
                "bash",
                "lua",
                "vim",
                "dockerfile",
                "gitignore",
                "query",
                "vimdoc",
                "c",
                "python",
                "rst",
                "toml",
            },
        })
    end,
}
