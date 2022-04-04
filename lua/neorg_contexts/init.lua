local ts_utils = require("nvim-treesitter.ts_utils")
local winnr = nil
local bufnr = nil

local function get_contexts()
    local node = ts_utils.get_node_at_cursor()
    local lines = {}
    local heading_nodes = {}
    while node do
        if node:type():find("heading") then
            table.insert(heading_nodes, node)
        end
        if node:parent() then
            node = node:parent()
        else
            break
        end
    end
    for _, heading_node in ipairs(heading_nodes) do
        table.insert(lines, ts_utils.get_node_text(heading_node, 0)[1])
    end
    local correct_lines = {}
    for i = #lines, 1, -1 do
        table.insert(correct_lines, lines[i])
    end
    return correct_lines
end

local function set_buf()
    local lines = get_contexts()
    if not bufnr or not vim.api.nvim_buf_is_valid(bufnr) then
        bufnr = vim.api.nvim_create_buf(false, true)
    end
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, {})
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
end

local function open_win()
    set_buf()
    local col = vim.fn.getwininfo(vim.api.nvim_get_current_win())[1].textoff
    local lines = get_contexts()
    if #lines == 0 then
        return
    end
    if not winnr or not vim.api.nvim_win_is_valid(winnr) then
        winnr = vim.api.nvim_open_win(bufnr, false, {
            relative = "win",
            width = vim.api.nvim_win_get_width(0) - col,
            height = #lines,
            row = 0,
            col = col,
            focusable = false,
            style = "minimal",
            noautocmd = true,
        })
    else
        vim.api.nvim_win_set_config(winnr, {
            win = vim.api.nvim_get_current_win(),
            relative = "win",
            width = vim.api.nvim_win_get_width(0),
            height = #lines,
            row = 0,
            col = 1,
        })
    end
end

local function update_window()
    open_win()
end

local context_augroup = vim.api.nvim_create_augroup("neorg-contexts", {})
vim.api.nvim_create_autocmd({ "WinScrolled", "BufEnter", "WinEnter", "CursorMoved" }, {
    callback = function()
        update_window()
    end,
    group = context_augroup,
})

open_win()
vim.api.nvim_win_close(winnr, true)
