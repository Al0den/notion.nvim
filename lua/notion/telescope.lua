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

local function attach_mappings(prompt_bufnr, map)
    actions.select_default:replace(function()
        local initData = require "notion".raw()
        local raw = parser.eventList(initData)

        if raw == nil then return end

        local urls = raw.urls

        actions.close(prompt_bufnr)
        local selection = action_state.get_selected_entry()
        os.execute("open " .. urls[selection[1]])
    end)
    map("n", "d", deleteItem)

    return true
end



--local function sort(data, dates)
--    local sorted = {}
--    for i, v in pairs(data) do
--        if dates[v] == nil then
--            table.insert(sorted, v)
--            data[i] = nil
--        end
--    end
--    local tmp = {}
--
--    for i, v in pairs(data) do
--        if tmp == {} then
--            tmp = { v }
--        else
--            for k, j in pairs(tmp) do
--                vim.print(tmp)
--                if dates[v] < dates[j] then
--                    table.insert(tmp, v)
--                end
--            end
--        end
--    end
--    return data
--end

M.openFutureEventsMenu = function(opts)
    opts = opts or {}

    local initData = require "notion".raw()
    local raw = parser.eventList(initData)
    if raw == nil then return end

    local data = raw.data

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
