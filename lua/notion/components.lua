local M = {}

local parser = require "notion.parse"

local function getEarliestData()
    local initData = require("notion.init")
    local data = parser.earliest(initData.raw())
    return data
end

M.nextEventName = function()
    local data = getEarliestData()
    if data == nil then return "None" end
    return data.properties.Name.title[1].plain_text
end


M.nextEventDate = function()
    local data = getEarliestData()
    if data == nil then return "None" end
    return data.properties.Date.date.start
end

return M
