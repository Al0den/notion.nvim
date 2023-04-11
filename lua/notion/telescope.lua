local pickers = require "telescope.pickers"
local finders = require "telescope.finders"
local conf = require("telescope.config").values
local actions = require "telescope.actions"
local action_state = require "telescope.actions.state"
local previewers = require "telescope.previewers"

local parser = require "notion.parse"
local request = require "notion.request"
local M = {}

local deleteItem = function(prompt_bufnr)
    local selection = action_state.get_selected_entry()
    request.deleteItem(selection)
    require "notion".update()
end

local editItem = function(prompt_bufnr)
    local selection = action_state.get_selected_entry()
    vim.print("WIP")
end

local function attach_mappings(prompt_bufnr, map)
    actions.select_default:replace(function()
        local initData = require "notion".raw()
        local raw = parser.eventList(initData)

        if raw == nil then return end

        local urls = raw.urls

        actions.close(prompt_bufnr)
        local selection = action_state.get_selected_entry()
        if require "notion".opts.open == "notion" then
            os.execute("open notion://" .. "www." .. urls[selection[1]]:sub(9))
        else
            os.execute("open " .. urls[selection[1]])
        end
    end)
    map("n", "d", deleteItem)
    map("n", "e", editItem)

    return true
end

M.openFutureEventsMenu = function(opts)
    opts = opts or {}

    local initData = require "notion".raw()
    local raw = parser.eventList(initData)
    if raw == nil then return end

    local data = raw.data
    local dates = raw.dates

    local function customSort(a, b)
        local dateA = dates[a] or "99999999"
        local dateB = dates[b] or "99999999"
        if dateA == true then dateA = "99999999" end
        if dateB == true then dateB = "99999999" end
        if dateA ~= dateB then
            return dateA < dateB
        else
            return a < b
        end
    end

    table.sort(data, customSort)

    pickers.new(opts, {
        prompt_title = "Notion Future Event's",
        finder = finders.new_table {
            results = data
        },
        sorter = conf.generic_sorter(opts),
        attach_mappings = attach_mappings,
        previewer = previewers.new_buffer_previewer {
            title = "Preview",
            define_preview = function(self, entry, status)
                vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, parser.eventPreview(entry[1]))
            end
        }
    }):find()
end

return M
