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
    notion.update({ silent = true, window = nil })
end

--Function linked to edit key, opens a markdown file with content if possible
local editItem = function(prompt_bufnr)
    local selection = action_state.get_selected_entry()
    actions.close(prompt_bufnr)
    parser.notionToMarkdown(selection)
end

--Function linked to itemAdd key
local addItem = function(prompt_bufnr)
    vim.notify("Not yet implemented")
end
local openNotion = function(prompt_bufnr)
    if require "notion".opts.open == "notion" then
        os.execute("open notion://www.notion.so")
    else
        os.execute("open https://www.notion.so")
    end
end

local viewItem = function(prompt_bufnr)
    local selection = action_state.get_selected_entry()
    local data = parser.objectFromID(selection.value.id)
    local markdown
    actions.close(prompt_bufnr)

    if data.object == "database_id" then
        markdown = markdownParser.databaseEntry(data.result, selection.value.id, true)
    elseif data.object == "page_id" then
        markdown = markdownParser.page(data.result, selection.value.id, true)
        return
    else
        return vim.print("[Notion] Cannot view or edit this event")
    end
    local path = vim.fn.stdpath("data") .. "/notion/temp.md"
    require "notion".writeFile(path, markdown)
    vim.cmd("vsplit " .. path)
    vim.api.nvim_buf_set_var(0, "owner", "notionMarkdown")
end
--Executed when an option is "hovered" inside the menu
local function attach_mappings(prompt_bufnr, map)
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

    map("n", notion.opts.keys.deleteKey, deleteItem)
    map("n", notion.opts.keys.editKey, editItem)
    map("n", notion.opts.keys.openNotion, openNotion)
    map("n", notion.opts.keys.itemAdd, addItem)
    map("n", notion.opts.keys.viewKey, viewItem)

    return true
end

--Opens the notion menu
M.openMenu = function(opts)
    opts = opts or {}

    if not notion.checkInit() then return end

    local initData = notion.raw()
    local data = parser.eventList(initData)
    if data == nil then return end

    --Initialise and show picker
    pickers.new(opts, {
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
            define_preview = function(self, entry, status)
                vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, parser.eventPreview(entry))
            end
        }
    }):find()
end

return M
