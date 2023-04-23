local M = {}

local parser = require "notion.parse"

--Get's earliest date of a database entry
local function getEarliestData()
    local initData = require("notion")
    local data = parser.earliest(initData.raw())
    return data
end

--Get the name of the next event
M.nextEventName = function()
    local data = getEarliestData()
    if data == nil then return "No Events" end
    return data.properties.Name.title[1].plain_text
end

M.lastUpdate = function()
    return "Last Update: " .. os.difftime(os.time(), require "notion".lastUpdate) .. " seconds ago"
end

--Get the date of future event
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

--Get a shorter, more display efficient date
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

--Full user friendly string for next event
M.nextEvent = function()
    if M.nextEventDate() == " " then
        return M.nextEventName()
    else
        return M.nextEventName() .. " - " .. M.nextEventShortDate()
    end
end

return M
