return {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
        "hrsh7th/cmp-nvim-lsp",
        { "antosha417/nvim-lsp-file-operations", config = true },
        { "folke/neodev.nvim", opts = {} },
    },
    config = function()
        -- import lspconfig plugin
        local lspconfig = require("lspconfig")

        -- import cmp-nvim-lsp plugin
        local cmp_nvim_lsp = require("cmp_nvim_lsp")

        local keymap = vim.keymap -- for conciseness

        vim.api.nvim_create_autocmd("LspAttach", {
            group = vim.api.nvim_create_augroup("UserLspConfig", {}),
            callback = function(ev)
                -- Buffer local mappings.
                -- See `:help vim.lsp.*` for documentation on any of the below functions
                local opts = { buffer = ev.buf, silent = true }

                -- set keybinds
                opts.desc = "Show LSP references"
                keymap.set("n", "gR", "<cmd>Telescope lsp_references<CR>", opts) -- show definition, references

                opts.desc = "Go to declaration"
                keymap.set("n", "gD", vim.lsp.buf.declaration, opts) -- go to declaration

                opts.desc = "Show LSP definitions"
                keymap.set("n", "gd", "<cmd>Telescope lsp_definitions<CR>", opts) -- show lsp definitions

                opts.desc = "Show LSP implementations"
                keymap.set("n", "gi", "<cmd>Telescope lsp_implementations<CR>", opts) -- show lsp implementations

                opts.desc = "Show LSP type definitions"
                keymap.set("n", "gt", "<cmd>Telescope lsp_type_definitions<CR>", opts) -- show lsp type definitions

                opts.desc = "See available code actions"
                keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, opts) -- see available code actions, in visual mode will apply to selection

                opts.desc = "Smart rename"
                keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts) -- smart rename

                opts.desc = "Show buffer diagnostics"
                keymap.set("n", "<leader>D", "<cmd>Telescope diagnostics bufnr=0<CR>", opts) -- show  diagnostics for file

                opts.desc = "Show line diagnostics"
                keymap.set("n", "<leader>d", vim.diagnostic.open_float, opts) -- show diagnostics for line

                opts.desc = "Go to previous diagnostic"
                keymap.set("n", "[d", vim.diagnostic.goto_prev, opts) -- jump to previous diagnostic in buffer

                opts.desc = "Go to next diagnostic"
                keymap.set("n", "]d", vim.diagnostic.goto_next, opts) -- jump to next diagnostic in buffer

                opts.desc = "Show documentation for what is under cursor"
                keymap.set("n", "I", vim.lsp.buf.hover, opts) -- show documentation for what is under cursor

                opts.desc = "Restart LSP"
                keymap.set("n", "<leader>rs", ":LspRestart<CR>", opts) -- mapping to restart lsp if necessary
            end,
        })

        -- used to enable autocompletion (assign to every lsp server config)
        local capabilities = cmp_nvim_lsp.default_capabilities()
        vim.lsp.config["lua_ls"] = {
            capabilities = capabilities,
            settings = {
                Lua = {
                    -- make the language server recognize "vim" global
                    diagnostics = {
                        globals = { "vim" },
                    },
                    completion = {
                        callSnippet = "Replace",
                    },
                },
            },
        }

        vim.lsp.config["graphql"] = {
            capabilities = capabilities,
            filetypes = { "graphql", "gql", "svelte", "typescriptreact", "javascriptreact" },
        }

        vim.lsp.config["emmet_ls"] = {
            capabilities = capabilities,
            filetypes = {
                "html",
                "typescriptreact",
                "javascriptreact",
                "css",
                "sass",
                "scss",
                "less",
                "svelte",
            },
        }
        vim.lsp.config["pyright"] = {
            capabilities = capabilities,
            settings = {
                python = {
                    analysis = {
                        autoSearchPaths = true,
                        diagnosticMode = "openFilesOnly",
                        useLibraryCodeForTypes = true,
                    },
                },
            },
        }
        vim.lsp.config["ts_ls"] = {
            capabilities = capabilities,
            init_options = {
                preferences = {
                    importModuleSpecifierPreference = "relative",
                    importModuleSpecifierEnding = "minimal",
                },
            },
            on_attach = function(client, bufnr)
                -- set keybinds for typescript
                client.server_capabilities.documentFormattingProvider = false
                local opts = { buffer = bufnr, silent = true }
                opts.desc = "Organize imports"
                keymap.set("n", "<leader>co", function()
                    vim.lsp.buf.code_action({
                        apply = true,
                        context = {
                            only = { "source.organizeImports" },
                            diagnostics = {},
                        },
                    })
                end, opts) -- organize imports

                opts.desc = "Remove Unused Imports"
                keymap.set("n", "<leader>cR", function()
                    vim.lsp.buf.code_action({
                        apply = true,
                        context = {
                            only = { "source.removeUnused.ts" },
                            diagnostics = {},
                        },
                    })
                end, opts) -- remove unused imports

                opts.desc = "Add missing Imports"
                keymap.set("n", "<leader>cA", function()
                    vim.lsp.buf.code_action({
                        apply = true,
                        context = {
                            only = { "source.addMissingImports.ts" },
                            diagnostics = {},
                        },
                    })
                end, opts) -- add missing imports

                opts.desc = "Fix all diagnostics"
                keymap.set("n", "<leader>cf", function()
                    vim.lsp.buf.code_action({
                        apply = true,
                        context = {
                            only = { "source.fixAll.ts" },
                            diagnostics = {},
                        },
                    })
                end, opts) -- fix all diagnostics
            end,
        }
        vim.lsp.enable("lua_ls")
        vim.lsp.enable("graphql")
        vim.lsp.enable("emmet_ls")
        vim.lsp.enable("pyright")
        vim.lsp.enable("ts_ls")
    end,
}
