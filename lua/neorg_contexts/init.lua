local ts_utils = require("nvim-treesitter.ts_utils")
local winnr = nil
local bufnr = nil
local ns = vim.api.nvim_create_namespace("neorg-contexts")

-- local config = { bg = "#" .. bit.tohex(vim.api.nvim_get_hl_by_name("Visual", true)["background"], 6) }

for i = 1, 6 do
    vim.api.nvim_set_hl(0, "NeorgHeading" .. i .. "Context", {
        fg = "#" .. bit.tohex(vim.api.nvim_get_hl_by_name("NeorgHeading" .. i .. "Title", true)["foreground"], 6),
        -- bg = config.bg,
    })
end

vim.cmd([[highlight default link NeorgContext Visual]])

local function get_contexts()
    local highlight_table = {
        ["heading1"] = "NeorgHeading1Context",
        ["heading2"] = "NeorgHeading2Context",
        ["heading3"] = "NeorgHeading3Context",
        ["heading4"] = "NeorgHeading4Context",
        ["heading5"] = "NeorgHeading5Context",
        ["heading6"] = "NeorgHeading6Context",
    }
    local node = ts_utils.get_node_at_cursor()
    local lines = {}
    local heading_nodes = {}
    local highlights = {}
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
    local title_nodes = {}
    for _, heading_node in ipairs(heading_nodes) do
        table.insert(title_nodes, heading_node:field("title")[1])
        table.insert(highlights, highlight_table[heading_node:type()])
    end
    for _, title_node in ipairs(title_nodes) do
        table.insert(lines, ts_utils.get_node_text(title_node, 0)[1])
    end
    local correct_lines = {}
    local correct_highlights = {}
    for i = #highlights, 1, -1 do
        table.insert(correct_highlights, highlights[i])
    end
    for i = #lines, 1, -1 do
        table.insert(correct_lines, lines[i])
    end
    return correct_lines, correct_highlights
end

local function set_buf()
    local lines, highlights = get_contexts()
    if not bufnr or not vim.api.nvim_buf_is_valid(bufnr) then
        bufnr = vim.api.nvim_create_buf(false, true)
    end
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, {})
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
    for i, highlight in ipairs(highlights) do
        vim.api.nvim_buf_add_highlight(bufnr, ns, highlight, i - 1, 0, -1)
    end
end

local function open_win()
    set_buf()
    local col = vim.fn.getwininfo(vim.api.nvim_get_current_win())[1].textoff
    local lines = get_contexts()
    if #lines == 0 then
        if vim.api.nvim_win_is_valid(winnr) then
            vim.api.nvim_win_close(winnr, true)
        end
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
            width = vim.api.nvim_win_get_width(0) - col,
            height = #lines,
            row = 0,
            col = col,
        })
    end
    vim.api.nvim_win_set_option(winnr, "winhl", "NormalFloat:NeorgContext")
end

local function update_window()
    if vim.bo.filetype ~= "norg" then
        return
    end
    open_win()
end

local context_augroup = vim.api.nvim_create_augroup("neorg-contexts", {})
vim.api.nvim_create_autocmd({ "WinScrolled", "BufEnter", "WinEnter", "CursorMoved" }, {
    callback = function()
        update_window()
    end,
    group = context_augroup,
})
