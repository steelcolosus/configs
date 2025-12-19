return {
    "zbirenbaum/copilot.lua",
    cmd = "Copilot",
    build = ":Copilot auth",
    event = "InsertEnter",
    config = function()
        require("copilot").setup({
            suggestion = {
                enabled = false,
                auto_trigger = false,
                -- hide_during_completion = true,
                -- keymap = {
                --     accept = false, -- handled by nvim-cmp / blink.cmp
                --     next = "<M-]>",
                --     prev = "<M-[>",
                -- },
            },
            panel = { enabled = false },
            filetypes = {
                markdown = true,
                help = true,
            },
        })
    end,
}
