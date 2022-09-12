require("neorg.modules.base")
local ts_utils = require("nvim-treesitter.ts_utils")
local winnr = nil
local bufnr = nil
local ns = vim.api.nvim_create_namespace("neorg-contexts")

vim.cmd([[highlight default link NeorgContext Visual]])

local module = neorg.modules.create("external.context")

module.setup = function()
    return {
        success = true,
        requires = {
            "core.neorgcmd",
        },
    }
end

module.private = {
    enabled = true,
    toggle = function()
        if module.private.enabled == true then
            module.private.enabled = false
        else
            module.private.enabled = true
        end
    end,
    enable = function()
        module.private.enabled = true
    end,
    disable = function()
        module.private.enabled = false
    end,
    get_contexts = function()
        local highlight_table = {
            ["heading1"] = "@neorg.headings.1.title",
            ["heading2"] = "@neorg.headings.2.title",
            ["heading3"] = "@neorg.headings.3.title",
            ["heading4"] = "@neorg.headings.4.title",
            ["heading5"] = "@neorg.headings.5.title",
            ["heading6"] = "@neorg.headings.6.title",
        }
        local prefix_table = {
            ["heading1"] = neorg.modules.get_module_config("core.norg.concealer").icons.heading.level_1.icon .. " ",
            ["heading2"] = neorg.modules.get_module_config("core.norg.concealer").icons.heading.level_2.icon .. " ",
            ["heading3"] = neorg.modules.get_module_config("core.norg.concealer").icons.heading.level_3.icon .. " ",
            ["heading4"] = neorg.modules.get_module_config("core.norg.concealer").icons.heading.level_4.icon .. " ",
            ["heading5"] = neorg.modules.get_module_config("core.norg.concealer").icons.heading.level_5.icon .. " ",
            ["heading6"] = neorg.modules.get_module_config("core.norg.concealer").icons.heading.level_6.icon .. " ",
        }
        local node = ts_utils.get_node_at_cursor(0, true)
        local lines = {}
        local heading_nodes = {}
        local highlights = {}

        local function is_valid(potential_node)
            local topline = vim.fn.line("w0")
            local row = potential_node:start()
            return row <= (topline + #heading_nodes)
        end

        local function validate_heading_nodes()
            local valid_heading_nodes = heading_nodes
            for i = #heading_nodes, 1, -1 do
                if not is_valid(valid_heading_nodes[i]) then
                    table.remove(valid_heading_nodes, i)
                end
            end
            return valid_heading_nodes
        end

        while node do
            if node:type():find("heading") and is_valid(node) then
                table.insert(heading_nodes, node)
            end
            if node:parent() then
                node = node:parent()
            else
                break
            end
        end
        heading_nodes = validate_heading_nodes()
        local title_nodes = {}
        local prefixes = {}
        for _, heading_node in ipairs(heading_nodes) do
            table.insert(title_nodes, heading_node:field("title")[1])
            table.insert(highlights, highlight_table[heading_node:type()])
            table.insert(prefixes, prefix_table[heading_node:type()])
        end
        for _, title_node in ipairs(title_nodes) do
            table.insert(lines, vim.split(vim.treesitter.query.get_node_text(title_node, 0), "\n")[1])
        end
        local correct_lines = {}
        local correct_highlights = {}
        for i = #highlights, 1, -1 do
            table.insert(correct_highlights, highlights[i])
        end
        for i = #lines, 1, -1 do
            table.insert(correct_lines, prefixes[i] .. lines[i])
        end
        return correct_lines, correct_highlights
    end,
    set_buf = function()
        local lines, highlights = module.private.get_contexts()
        if not bufnr or not vim.api.nvim_buf_is_valid(bufnr) then
            bufnr = vim.api.nvim_create_buf(false, true)
        end
        vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, {})
        vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
        for i, highlight in ipairs(highlights) do
            vim.api.nvim_buf_add_highlight(bufnr, ns, highlight, i - 1, 0, -1)
        end
    end,
    open_win = function()
        module.private.set_buf()
        local col = vim.fn.getwininfo(vim.api.nvim_get_current_win())[1].textoff
        local lines = module.private.get_contexts()
        if #lines == 0 then
            if winnr and vim.api.nvim_win_is_valid(winnr) then
                vim.api.nvim_win_close(winnr, true)
                winnr = nil
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
    end,
    update_window = function()
        if not module.private.enabled then
            if winnr and vim.api.nvim_win_is_valid(winnr) then
                vim.api.nvim_win_close(winnr, true)
                winnr = nil
            end
            return
        end
        if vim.bo.filetype ~= "norg" then
            if winnr and vim.api.nvim_win_is_valid(winnr) then
                vim.api.nvim_win_close(winnr, true)
                winnr = nil
            end
            return
        end
        if string.find(vim.api.nvim_buf_get_name(0), "neorg://") then
            if winnr and vim.api.nvim_win_is_valid(winnr) then
                vim.api.nvim_win_close(winnr, true)
                winnr = nil
            end
            return
        end

        module.private.open_win()
    end,
}

module.config.public = {}

module.public = {}

module.load = function()
    module.required["core.neorgcmd"].add_commands_from_table({
        definitions = {
            context = {
                toggle = {},
                enable = {},
                disable = {},
            },
        },
        data = {
            context = {
                min_args = 1,
                max_args = 1,
                subcommands = {
                    toggle = { args = 0, name = "context.toggle" },
                    enable = { args = 0, name = "context.enable" },
                    disable = { args = 0, name = "context.disable" },
                },
            },
        },
    })
    local context_augroup = vim.api.nvim_create_augroup("neorg-contexts", {})
    vim.api.nvim_create_autocmd({ "WinScrolled", "BufEnter", "WinEnter", "CursorMoved" }, {
        callback = function()
            module.private.update_window()
        end,
        group = context_augroup,
    })
end

module.on_event = function(event)
    if vim.tbl_contains({ "core.keybinds", "core.neorgcmd" }, event.split_type[1]) then
        if event.split_type[2] == "context.toggle" then
            module.private.toggle()
        elseif event.split_type[2] == "context.enable" then
            module.private.enable()
        elseif event.split_type[2] == "context.disable" then
            module.private.disable()
        end
    end
end

module.events.subscribed = {
    ["core.neorgcmd"] = {
        ["context.toggle"] = true,
        ["context.enable"] = true,
        ["context.disable"] = true,
    },
}

return module
