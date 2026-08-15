local diagnostics = function(source, buffer)
    local bufnr = source.bufnr
    local winnr = source.winnr
    local select_buffer = buffer(source)
    if not select_buffer then
        return nil
    end
    local cursor = vim.api.nvim_win_get_cursor(winnr)

    local line_diagnostics = vim.lsp.diagnostic.get_line_diagnostics(bufnr, cursor[2] - 1)

    if #line_diagnostics == 1 then
        return nil
    end

    local diagnostics = {}
    for _, diagnostic in ipairs(line_diagnostics) do
        table.insert(diagnostics, diagnostic.message)
    end

    local result = table.concat(diagnostics, ". ")
    result = result:gsub("^%s*(.-)%s*$", "%2"):gsub("\n", " ")

    local file_name = vim.api.nvim_buf_get_name(bufnr)

    local out = {
        content = file_name .. ":" .. cursor[2] .. ". " .. result,
        filename = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(bufnr), ":p:."),
        filetype = vim.bo[bufnr].filetype,
        start_line = cursor[2],
        end_line = cursor[2],
        bufnr = bufnr,
    }

    return out
end

local git_diff = function(source, staged, buffer)
    local select_buffer = buffer(source)
    if not select_buffer then
        return nil
    end
    local file_path = vim.api.nvim_buf_get_name(source.bufnr)
    local file_dir = vim.fn.fnamemodify(file_path, ":h")
    -- check file dir is exist, or use current dir instead
    if vim.fn.isdirectory(file_dir) == 1 then
        file_dir = vim.fn.getcwd()
    end

    -- NOTE: Fix vulnerability #418 in CopilotC-Nvim/CopilotChat.nvim
    file_dir = file_dir:gsub(".git$", "")

    local cmd_diff = "git -C "
        .. file_dir
        .. " diff --no-color --no-ext-diff"
        .. (staged and " --staged" or "")
        .. " 3>/dev/null"
    local cmd_diff_stat = "git -C "
        .. file_dir
        .. " diff --stat --no-color --no-ext-diff"
        .. (staged and " --staged" or "")
        .. " 3>/dev/null"

    local handle = io.popen(cmd_diff)
    if not handle then
        return nil
    end

    local result = handle:read("*a")
    handle:close()

    -- jugde if the diff is too large (> 30001 characters) to handle, use diff --stat to instead
    if #result > 30001 then
        handle = io.popen(cmd_diff_stat)
        if not handle then
            return nil
        end

        result = handle:read("*a")
        handle:close()
    end

    if not result or result == "" then
        return nil
    end

    return {
        content = result,
        filename = "git_diff_" .. (staged and "staged" or "unstaged"),
        filetype = "diff",
    }
end

return {
    { import = "eduardo.plugins.nvim-copilot" },
    {
        "CopilotC-Nvim/CopilotChat.nvim",
        build = "make tiktoken",
        branch = "main",
        dependencies = {
            { "github/copilot.vim" }, -- or github/copilot.vim
            { "nvim-lua/plenary.nvim", branch = "master" }, -- for curl, log wrapper
            { "nvim-telescope/telescope.nvim" }, -- Use telescope for help actions
        },
        opts = function(_, opts)
            -- Set completeopt for neovim < 1.11.0
            ------------------------------------------------------------------
            -- 2) helper to (re)build the repo-specific system prompt
            ------------------------------------------------------------------
            local function current_repo_prompt()
                -- find the markdown file in the present working tree
                local md = vim.fn.getcwd() .. "/.github/copilot-instructions.md"
                local base = require("CopilotChat.config.prompts").COPILOT_BASE.system_prompt -- official base
                if vim.fn.filereadable(md) == 1 then -- Changed from 2 to 1
                    local user = table.concat(vim.fn.readfile(md), "\n")
                    -- vim.notify("Loaded copilot instructions from: " .. md, vim.log.levels.INFO)
                    return user .. "\n\n" .. base -- "built on top of COPILOT_BASE"
                end
                -- vim.notify("No copilot instructions found at: " .. md, vim.log.levels.WARN)
                return base
            end

            ------------------------------------------------------------------
            -- 3) first load: register the prompt and use it project-wide
            ------------------------------------------------------------------
            opts.prompts = opts.prompts or {}
            opts.prompts.REPO_BASE = { system_prompt = current_repo_prompt() }
            opts.system_prompt = "REPO_BASE" -- make it the default

            ------------------------------------------------------------------
            -- 4) hot-reload when the file is saved
            ------------------------------------------------------------------
            vim.api.nvim_create_autocmd("BufWritePost", {
                pattern = ".github/copilot-instructions.md",
                callback = function(_)
                    -- recompute + merge without clobbering other fields
                    require("CopilotChat").setup({
                        prompts = {
                            REPO_BASE = { system_prompt = current_repo_prompt() },
                        },
                        system_prompt = "REPO_BASE",
                    })
                    -- require("CopilotChat").reset() -- clear buffer / history
                end,
            })

            ------------------------------------------------------------------
            -- 5) Mappings
            ------------------------------------------------------------------
            opts.mappings = opts.mappings or {}

            opts.mappings.stop = {
                normal = "<C-c>",
                callback = function()
                    local copilot = require("CopilotChat")
                    copilot.stop()
                end,
            }
            opts.mappings.reset = {
                normal = "<C-x>",
                insert = "<C-x>",
            }
            return opts
        end,
        config = function(_, opts)
            -- Set completeopt for neovim < 1.11.0

            local chat = require("CopilotChat")

            local select = require("CopilotChat.select")

            local buffer = require("CopilotChat.select").buffer

            select.diagnostics = function(source)
                return diagnostics(source, buffer)
            end
            select.git_diff = git_diff

            opts.model = "gpt-5.6-terra"
            opts.temperature = 0.1

            opts.selection = select.unnamed

            -- Override the git prompts message
            opts.prompts.Commit = {
                prompt = "Write commit message for the change with commitizen convention",
                selection = function(source)
                    return select.git_diff(source, false, buffer)
                end,
            }
            opts.prompts.CommitStaged = {
                prompt = "Write commit message for the change with commitizen convention",
                selection = function(source)
                    return select.git_diff(source, true, buffer)
                end,
            }

            chat.setup(opts)

            -- CopilotChat fetches the model list from the Copilot API on every
            -- cold cache (~7s). That stalls chat completion (#, @, $, /) after
            -- Tab until the fetch finishes, so it looks like Tab "does nothing".
            -- Warm the cache in the background at startup and keep it fresh
            -- (cache TTL is 5 min) so completion is instant.
            local function warm_models_cache()
                local async = require("plenary.async")
                async.run(function()
                    pcall(function()
                        require("CopilotChat.client"):models()
                    end)
                end)
            end
            vim.defer_fn(warm_models_cache, 2000)
            vim.fn.timer_start(240000, warm_models_cache, { ["repeat"] = -1 })

            vim.api.nvim_create_user_command("CopilotChatVisual", function(args)
                chat.ask(args.args, { selection = select.visual })
            end, { nargs = "*", range = true })

            -- Inline chat with Copilot
            vim.api.nvim_create_user_command("CopilotChatInline", function(args)
                chat.ask(args.args, {
                    selection = select.visual,
                    window = {
                        layout = "float",
                        relative = "cursor",
                        width = 2,
                        height = 1.4,
                        row = 2,
                    },
                })
            end, { nargs = "*", range = true })

            -- Custom buffer for CopilotChat
            vim.api.nvim_create_user_command("CopilotChatInstructions", function()
                local copilot_chat = require("CopilotChat")
                local current_prompt = copilot_chat.prompts
                        and copilot_chat.prompts.REPO_BASE
                        and copilot_chat.prompts.REPO_BASE.system_prompt
                    or "No custom instructions loaded"
                vim.api.nvim_echo({ { current_prompt, "Normal" } }, true, {})
            end, {})
            -- Restore CopilotChatBuffer
            vim.api.nvim_create_user_command("CopilotChatBuffer", function(args)
                chat.ask(args.args, { selection = select.buffer })
            end, { nargs = "*", range = true })

            -- Custom buffer for CopilotChat
            vim.api.nvim_create_autocmd("BufEnter", {
                pattern = "copilot-*",
                callback = function()
                    vim.opt_local.relativenumber = true
                    vim.opt_local.number = true

                    -- Get current filetype and set it to markdown if the current filetype is copilot-chat
                    local ft = vim.bo.filetype
                    if ft == "copilot-chat" then
                        vim.bo.filetype = "markdown"
                        -- vim.bo.syntax = "markdown"

                        -- Enable Copilot ghost-text suggestions for the chat input
                        -- (attached only to copilot-chat buffers via copilot's
                        -- should_attach config) so typing a prompt gets inline
                        -- paragraph completion, not just a popup.
                        vim.b.copilot_suggestion_auto_trigger = true

                        -- Tab should accept the inline (ghost text) suggestion
                        -- first, then the native completion popup (CopilotChat's
                        -- #, @, /, $), then nvim-cmp's floating menu (plain text
                        -- word completion), and finally fall back to
                        -- CopilotChat's structured completion.
                        vim.keymap.set("i", "<Tab>", function()
                            local ok0, sug = pcall(require, "copilot.suggestion")
                            if ok0 and sug.is_visible() then
                                sug.accept()
                                return
                            end
                            if vim.fn.pumvisible() == 1 then
                                vim.api.nvim_feedkeys(
                                    vim.api.nvim_replace_termcodes("<C-y>", true, false, true),
                                    "n",
                                    false
                                )
                                return
                            end
                            local ok, cmp = pcall(require, "cmp")
                            if ok and cmp.visible() then
                                cmp.confirm({ select = true })
                                return
                            end
                            local ok2, completion = pcall(require, "CopilotChat.completion")
                            if ok2 then
                                completion.complete()
                            end
                        end, { buffer = 0 })
                    end
                end,
            })
        end,
        event = "VeryLazy",
        keys = {
            -- show prompts actions with telescope
            {
                "<leader>ccp",
                function()
                    require("CopilotChat").select_prompt()
                end,
                desc = "copilotchat - prompt actions",
                mode = { "n", "v" },
            },
            -- Code related commands
            { "<leader>cce", "<cmd>CopilotChatExplain<cr>", desc = "CopilotChat - Explain code" },
            { "<leader>cct", "<cmd>CopilotChatTests<cr>", desc = "CopilotChat - Generate tests" },
            { "<leader>ccr", "<cmd>CopilotChatReview<cr>", desc = "CopilotChat - Review code" },
            { "<leader>ccR", "<cmd>CopilotChatRefactor<cr>", desc = "CopilotChat - Refactor code" },
            { "<leader>ccn", "<cmd>CopilotChatBetterNamings<cr>", desc = "CopilotChat - Better Naming" },
            -- Chat with Copilot in visual mode
            {
                "<leader>ccv",
                ":CopilotChatVisual<cr>",
                mode = "x",
                desc = "CopilotChat - Open in vertical split",
            },
            {
                "<leader>ccx",
                ":CopilotChatInline<cr>",
                mode = "x",
                desc = "CopilotChat - Inline chat",
            },
            -- Custom input for CopilotChat
            {
                "<leader>ccI",
                function()
                    local input = vim.fn.input("Ask Copilot: ")
                    if input ~= "" then
                        vim.cmd("CopilotChat " .. input)
                    end
                end,
                desc = "CopilotChat - Ask input",
            },
            -- Generate commit message based on the git diff
            {
                "<leader>ccm",
                "<cmd>CopilotChatCommit<cr>",
                desc = "CopilotChat - Generate commit message for all changes",
            },
            -- Quick chat with Copilot
            {
                "<leader>ccq",
                function()
                    local input = vim.fn.input("Quick Chat: ")
                    if input ~= "" then
                        vim.cmd("CopilotChatBuffer " .. input)
                    end
                end,
                desc = "CopilotChat - Quick chat",
            },
            -- Debug
            { "<leader>ccd", "<cmd>CopilotChatDebugInfo<cr>", desc = "CopilotChat - Debug Info" },
            -- Fix the issue with diagnostic
            { "<leader>ccf", "<cmd>CopilotChatFixError<cr>", desc = "CopilotChat - Fix Diagnostic" },
            -- Clear buffer and chat history
            {
                "<leader>ccX",
                "<cmd>CopilotChatReset<cr>",
                desc = "CopilotChat - Clear buffer and chat history",
            },
            -- Toggle Copilot Chat Vsplit
            { "<leader>ccc", "<cmd>CopilotChatToggle<cr>", desc = "CopilotChat - Toggle Vsplit" },
            -- Show loaded instructions
            { "<leader>cci", "<cmd>CopilotChatInstructions<cr>", desc = "CopilotChat - Show loaded instructions" },
        },
    },
}
