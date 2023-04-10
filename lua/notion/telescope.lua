local pickers = require "telescope.pickers"
local finders = require "telescope.finders"
local conf = require("telescope.config").values
local actions = require "telescope.actions"
local action_state = require "telescope.actions.state"

local parser = require "notion.parse"

local M = {}

local function attach_mappings(prompt_bufnr, map)
    actions.select_default:replace(function()
        local initData = require "notion.init".raw()
        local raw = parser.eventList(initData)

        if raw == nil then return end

        local urls = raw.urls

        actions.close(prompt_bufnr)
        local selection = action_state.get_selected_entry()
        os.execute("open " .. urls[selection[1]])
    end)
    return true
end

M.openMenu = function(opts)
    opts = opts or {}

    local initData = require "notion.init".raw()
    local raw = parser.eventList(initData)
    if raw == nil then return end

    local data = raw.data

    pickers.new(opts, {
        prompt_title = "Notion Future Event's",
        finder = finders.new_table {
            results = data
        },
        sorter = conf.generic_sorter(opts),
        attach_mappings = attach_mappings
    }):find()
end

return M
