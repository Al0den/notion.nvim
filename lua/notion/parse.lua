local M = {}
local utils = require "notion-utils"

M.getDate = function(v)
    if v.properties.Dates == nil and v.properties.Dates.date == vim.NIL and v.properties.Dates.date.start == nil then
        return
        "No Date"
    end

    local str = v.properties.Dates.date.start

    local date = str:gsub("-", ""):gsub("T", ""):gsub(":", ""):gsub("+", "")
    return date
end

M.displayDate = function(v)
    if v.properties.Dates == nil and v.properties.Dates.date == vim.NIL and v.properties.Dates.date.start == nil then
        return
        "No date"
    end

    local inputDate = v.properties.Dates.date.start
    local year, month, day, hour, minute, second, timezone, timezoneValue = utils.parseISO8601Date(inputDate)
    local humanReadableDate

    if hour and minute and second then
        local timezoneSign = (timezone == "+") and "+" or "-"
        local timezoneHoursDiff = tonumber(timezoneValue) or 0
        humanReadableDate = string.format("%s %d, %d at %02d:%02d %s%02d:%02d",
            os.date("%B", os.time({ year = year, month = month, day = day })), day, year, hour, minute, timezoneSign,
            timezoneHoursDiff, 0)
    else
        humanReadableDate = string.format("%s %d, %d",
            os.date("%B", os.time({ year = year, month = month, day = day })),
            day, year)
    end
    return humanReadableDate
end

M.displayShortDate = function(v)
    if v.properties.Dates == nil and v.properties.Dates.date == vim.NIL and v.properties.Dates.date.start == nil then
        return "No date"
    end

    local inputDate = v.properties.Dates.date.start
    local year, month, day, hour, minute, second, timezone, timezoneValue = utils.parseISO8601Date(inputDate)
    local currentDateTime = os.date("*t")

    local currentYear = currentDateTime.year
    local currentMonth = currentDateTime.month
    local currentDay = currentDateTime.day

    if year == currentYear and month == currentMonth and day == currentDay then
        local formattedTime = string.format("%02d:%02d", hour, minute)
        return formattedTime
    else
        return M.displayDate(v)
    end
end

M.earliest = function(opts)
    if opts == " " or opts == nil then return nil end
    local content = (vim.json.decode(opts)).results
    local biggestDate = "No earliest event"
    local data
    for k, v in pairs(content) do
        if v.properties.Dates ~= nil and v.properties.Dates.date ~= vim.NIL and v.properties.Dates.date.start ~= nil then
            local final = M.getDate(v)

            if (final < biggestDate or data == nil) and final > vim.fn.strftime("%Y%m%d") then
                biggestDate = final
                data = v
            end
        end
    end
    return data
end

local function compareDates(v)
    if v == nil then return end
    if v.properties.Dates == nil and v.properties.Dates.date == vim.NIL and v.properties.Dates.date.start == nil then return true end

    local str = v.properties.Dates.date.start
    local ymd = string.sub(str, 1, 10)
    local final = ymd:gsub("-", "")

    if final >= vim.fn.strftime("%Y%m%d") then
        return final
    end
    return false
end

M.objectFromName = function(name)
    local raw = vim.json.decode(require "notion".raw()).results
    for i, v in pairs(raw) do
        if v.properties ~= nil and v.properties.Name ~= nil and v.properties.Name.title[1] ~= nil and v.properties.Name.title[1].plain_text == name then
            return v
        end
    end
    return "Problem"
end

M.eventList = function(opts)
    if opts == " " or opts == nil then return nil end
    local content = vim.json.decode(opts).results
    local data = {}
    local urls = {}
    local ids = {}
    local dates = {}
    for _, v in pairs(content) do
        if v.properties ~= nil and v.properties.Name ~= nil and v.properties.Name.title[1] ~= nil and compareDates(v) then
            if compareDates(v) ~= true then
                table.insert(data, v.properties.Name.title[1].plain_text)
            end
            dates[v.properties.Name.title[1].plain_text] = compareDates(v)

            urls[v.properties.Name.title[1].plain_text] = v.url
            ids[v.properties.Name.title[1].plain_text] = v.id
        end
    end
    return { data = data, urls = urls, ids = ids, dates = dates }
end

M.eventPreview = function(name)
    local opts = require "notion".raw()
    local content = (vim.json.decode(opts)).results

    local final = {}
    local block = {}

    for _, v in pairs(content) do
        if v.properties ~= nil and v.properties.Name ~= nil and v.properties.Name.title[1] ~= nil and v.properties.Name.title[1].plain_text == name then
            block = v
        end
    end

    if block == {} then return { "No data" } end
    if block.properties.Dates ~= nil and block.properties.Dates.date ~= vim.NIL then
        local toAdd = M.displayDate(block) or "No date"
        table.insert(final, "Date: " .. toAdd)
        table.insert(final, " ")
    end
    if block.properties.Type ~= nil and block.properties.Type.select ~= vim.NIL and block.properties.Type.select.name ~= vim.NIL then
        local toAdd = block.properties.Type.select.name or "None"
        table.insert(final, "Type: " .. toAdd)
        table.insert(final, " ")
    end
    if block.properties.Topic ~= nil then
        local l = "Topics: "
        local count = true
        for _, v in pairs(block.properties.Topic.multi_select) do
            if count == true then
                l = l .. v.name
                count = false
            else
                l = l .. ", " .. v.name
            end
        end
        if l == "Topics: " then l = l .. "None" end
        table.insert(final, l)
        table.insert(final, " ")
    end
    return final
end

M.databaseName = function(object)
    return object.icon.emoji .. " " .. object.title.text.content
end

return M
