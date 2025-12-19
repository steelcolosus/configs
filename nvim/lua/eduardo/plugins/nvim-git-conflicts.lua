return {
    -- lazy.nvim
    {
        "akinsho/git-conflict.nvim",
        version = "*",
        config = function()
            require("git-conflict").setup({
                list_opener = "git-conflict#ListOpen",
                disable_diagnostics = true,
                highlights = {
                    incoming = "DiffText",
                    current = "DiffAdd",
                },
                debug = false,
                default_mappings = {
                    ours = "<leader>gco",
                    theirs = "<leader>gct",
                    none = "<leader>gcn",
                    both = "<leader>gcb",
                    next = "<leader>gcn",
                    prev = "<leader>ccp",
                },
            })
        end,
    },
}
