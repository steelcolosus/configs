local function get_python_path()
    local util = require("lspconfig/util")
    local path = util.path

    -- Use activated virtualenv if available
    if vim.env.VIRTUAL_ENV then
        return path.join(vim.env.VIRTUAL_ENV, "bin", "python")
    end

    -- Use the workspace folder's Python, fallback to system Python
    return vim.fn.exepath("python3") or vim.fn.exepath("python") or "python"
end

return {
    "mfussenegger/nvim-dap-python",
    keys = {
        {
            "<leader>dPt",
            function()
                require("dap-python").test_method()
            end,
            desc = "Debug Method",
            ft = "python",
        },
        {
            "<leader>dPc",
            function()
                require("dap-python").test_class()
            end,
            desc = "Debug Class",
            ft = "python",
        },
    },
    ft = "python",
    dependencies = {
        "mfussenegger/nvim-dap",
        "rcarriga/nvim-dap-ui",
    },
    config = function()
        -- Dynamically setting the Python interpreter
        require("dap-python").setup(get_python_path())
    end,
}
