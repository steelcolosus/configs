return {
    "zbirenbaum/copilot.lua",
    cmd = "Copilot",
    build = ":Copilot auth",
    event = "InsertEnter",
    config = function()
        require("copilot").setup({
            suggestion = {
                enabled = false, -- Disable inline suggestions
                auto_trigger = false,
                hide_during_completion = true,
                keymap = {
                    accept = false, -- Tab is handled by nvim-cmp / the CopilotChat Tab mapping
                    accept_word = false,
                    accept_line = false,
                    dismiss = false,
                    toggle_auto_trigger = false,
                },
            },
            panel = { enabled = false },
            logger = {
                file_log_level = vim.log.levels.TRACE,
                log_lsp_messages = true,
            },
            filetypes = {
                markdown = false,
                help = true,
            },
            -- Only attach ghost-text suggestions to the CopilotChat input buffer.
            -- Normal code editing keeps using nvim-cmp for completion.
            should_attach = function(bufnr)
                return vim.endswith(vim.api.nvim_buf_get_name(bufnr), "/copilot-chat")
                    or vim.endswith(vim.api.nvim_buf_get_name(bufnr), "copilot-chat")
            end,
        })
    end,
}
