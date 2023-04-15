local M = {}

local parser = require "notion.parse"

local function getEarliestData()
    local initData = require("notion")
    local data = parser.earliest(initData.raw())
    return data
end

M.nextEventName = function()
    local data = getEarliestData()
    if data == nil then return "No Events" end
    return data.properties.Name.title[1].plain_text
end


M.nextEventDate = function()
    local data = getEarliestData()
    if data == nil then return " " end
    for i, v in pairs(data.properties) do
        if v.type == "date" then
            return parser.displayDate(v.date.start)
        end
    end
    return " "
end


M.nextEventShortDate = function()
    local data = getEarliestData()
    if data == nil then return " " end
    for i, v in pairs(data.properties) do
        if v.type == "date" then
            return parser.displayShortDate(v.date.start)
        end
    end

    return " "
end

M.nextEvent = function()
    if M.nextEventDate() == " " then
        return M.nextEventName()
    else
        return M.nextEventName() .. " - " .. M.nextEventShortDate()
    end
end

return M
