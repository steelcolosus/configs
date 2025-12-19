local set = vim.opt_local

-- Set local settings for terminal buffer

vim.api.nvim_create_autocmd("TermOpen", {
    group = vim.api.nvim_create_augroup("custom-term-open", {}),
    callback = function()
        set.number = false
        set.relativenumber = false
        set.scrolloff = 0
    end,
})

-- eAsily hit escape in terminal mode.

vim.keymap.set("t", "<esc><esc>", "<c-\\><c-n>")
vim.keymap.set("t", "<C-o>", "<c-\\><c-n>") -- Alternative that works well in tmux

-- Terminal state variables
local term_bufnr = nil
local term_win = nil

-- Open a terminal at the bottom of the screen with a fixed height
vim.keymap.set("n", "~", function()
    -- If we already have a terminal buffer
    if term_bufnr and vim.api.nvim_buf_is_valid(term_bufnr) then
        -- Check if terminal window exists
        local win_open = false
        if term_win and vim.api.nvim_win_is_valid(term_win) then
            win_open = true
            vim.api.nvim_win_close(term_win, false)
            term_win = nil
        end

        -- If window was not open, create a new window for existing buffer
        if not win_open then
            vim.cmd.split()
            vim.cmd.wincmd("J")
            vim.api.nvim_win_set_height(0, 12)
            vim.wo.winfixheight = true
            vim.cmd("buffer " .. term_bufnr)
            term_win = vim.api.nvim_get_current_win()
            -- Go to insert mode in terminal
            vim.cmd("startinsert")
        end
    else
        -- Create new terminal
        vim.cmd.split()
        vim.cmd.wincmd("J")
        vim.api.nvim_win_set_height(0, 12)
        vim.wo.winfixheight = true
        vim.cmd.terminal()
        term_bufnr = vim.api.nvim_get_current_buf()
        term_win = vim.api.nvim_get_current_win()
        vim.cmd("startinsert")
    end
end, { desc = "Toggle terminal window" })
