local M = {}

local parser = require "notion.parse"

local function getEarliestData()
    local initData = require("notion.init")
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
    if data.properties.Date == nil or data.properties.Date.date == nil or data.properites.Date.date.start == nil then
        return
        " "
    end
    return data.properties.Date.date.start
end

M.nextEvent = function()
    if M.nextEventDate() == " " then
        return M.nextEventName()
    else
        return M.nextEventName() .. " - " .. M.nextEventDate()
    end
end

return M
