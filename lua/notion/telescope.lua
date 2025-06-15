local pickers = require "telescope.pickers"
local finders = require "telescope.finders"
local conf = require("telescope.config").values
local actions = require "telescope.actions"
local action_state = require "telescope.actions.state"
local previewers = require "telescope.previewers"

local parser = require "notion.parse"
local request = require "notion.request"
local markdownParser = require "notion.markdown"
local notion = require "notion"

local M = {}

--Function linked to "deleteKey", deletes the item from notion and calls update silently
local deleteItem = function(prompt_bufnr)
    local selection = action_state.get_selected_entry()
    actions.close(prompt_bufnr)

    local window = require "notion.window".create("Deleting")
    request.deleteItem(selection.value.id, window)
end

--Function linked to edit key, opens a markdown file with content if possible
local editItem = function(prompt_bufnr)
    local selection = action_state.get_selected_entry()
    actions.close(prompt_bufnr)
    parser.notionToMarkdown(selection)
end

local openNotion = function(_)
    local function command_exists(cmd)
        local check = io.popen("command -v " .. cmd .. " 2>/dev/null")
        if check then
            local result = check:read("*l")
            check:close()
            return result ~= nil
        end
        return false
    end
    if command_exists("open") then
        if require "notion".opts.open == "notion" then
            os.execute("open notion://www.notion.com")
        else
            os.execute("open https://www.notion.com")
        end
    elseif command_exists("xdg-open") then
        if require "notion".opts.open == "notion" then
            os.execute("xdg-open notion://www.notion.com")
        else
            os.execute("xdg-open https://www.notion.com")
        end
    else
        print("No known command to open notion")
    end
end

--Function linked to viewItem key
local viewItem = function(prompt_bufnr)
    local selection = action_state.get_selected_entry()
    local data = parser.objectFromID(selection.value.id)
    local markdown
    actions.close(prompt_bufnr)

    if data.object == "database_id" then
        markdown = markdownParser.databaseEntry(data.result, selection.value.id, true, true)
    elseif data.object == "page_id" then
        markdown = markdownParser.page(data.result, selection.value.id, true, true)
        return
    else
        return vim.print("[Notion] Cannot view or edit this event")
    end
    local path = vim.fn.stdpath("data") .. "/notion/temp.md"
    require "notion".writeFile(path, markdown)
    vim.cmd("vsplit " .. path)
    local buffer_number = vim.api.nvim_get_current_buf()
    vim.api.nvim_buf_set_var(buffer_number, "owner", "notionMarkdown")
    vim.api.nvim_buf_set_var(buffer_number, "id", selection.value.id)
    vim.api.nvim_buf_set_option(buffer_number, "readonly", true)
    vim.api.nvim_buf_set_option(buffer_number, "modified", false)
end

--Set a reminder for a specific event
local remind = function(prompt_bufnr)
    actions.close(prompt_bufnr)
    local selection = action_state.get_selected_entry()
    local min_hour = vim.fn.input("Time (hh:mm): ")
    local date = vim.fn.input("Date (yyyy-mm-dd): ")
    if not date or date == "" or date == " " then
        date = vim.fn.strftime("%Y-%m-%d")
    end
    if not min_hour or min_hour == "" or min_hour == " " then
        min_hour = vim.fn.strftime("%H:%M")
    end
    local path = vim.fn.stdpath("data") .. '/notion/reminders.txt'
    local file = io.open(path, "a")
    if not file then return vim.notify("[Notion] Setup is incomplete") end
    file:write(date .. "T" .. min_hour .. " " .. selection.value.displayName .. "\n")
    vim.print("[Notion] Reminder set for " .. date .. " at " .. min_hour)
end

--Executed when an option is "hovered" inside the menu
local function attach_mappings(prompt_bufnr, map)
    local notion_ref = require "notion"
    --On menu click
    actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        local selection = action_state.get_selected_entry()
        local obj = (parser.objectFromID(selection.value.id)).result

        if notion.opts.open == "notion" then
            os.execute("open notion://" .. obj.url)
        else
            os.execute("open " .. obj.url)
        end
    end)

    map("n", notion_ref.opts.keys.deleteKey, deleteItem)
    map("n", notion_ref.opts.keys.editKey, editItem)
    map("n", notion_ref.opts.keys.openNotion, openNotion)
    map("n", notion_ref.opts.keys.viewKey, viewItem)
    map("n", notion_ref.opts.keys.remindKey, remind)

    return true
end

--Opens the notion menu
M.openMenu = function(opts)
    if not require "notion".checkInit() then return end

    opts = opts or {}

    if not notion.checkInit() then return end

    local initData = notion.raw()
    local data = parser.eventList(initData)
    if not data then return end

    --Initialise and show picker
    local picker = pickers.new(opts, {
        prompt_title = "Notion Event's",
        finder = finders.new_table {
            results = data,
            entry_maker = function(entry)
                return {
                    value = entry,
                    display = entry["displayName"],
                    ordinal = entry["displayName"],
                }
            end
        },
        sorter = conf.generic_sorter(opts),
        attach_mappings = attach_mappings,
        previewer = previewers.new_buffer_previewer {
            title = "Preview",
            define_preview = function(self, entry, _)
                vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, parser.eventPreview(entry))
            end
        }
    }):find()

    return picker
end

M.openMenuTelescope = function(opts)
    opts = opts or {}

    local initData = require "notion".raw()
    local data = parser.eventList(initData)

    --Initialise and show picker
    local picker = pickers.new(opts, {
        prompt_title = "Notion Event's",
        finder = finders.new_table {
            results = data,
            entry_maker = function(entry)
                return {
                    value = entry,
                    display = entry["displayName"],
                    ordinal = entry["displayName"],
                }
            end
        },
        sorter = conf.generic_sorter(opts),
        attach_mappings = attach_mappings,
        previewer = previewers.new_buffer_previewer {
            title = "Preview",
            define_preview = function(self, entry, _)
                vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, parser.eventPreview(entry))
            end
        }
    })

    return picker
end



return M
