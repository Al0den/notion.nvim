local M = {}

local actions = require "telescope.actions"

M.objectFromName = function(name)
    local raw = vim.json.decode(require "notion".raw()).results
    for _, v in pairs(raw) do
        if v.properties ~= nil and v.properties.Name ~= nil and v.properties.Name.title[1] ~= nil and v.properties.Name.title[1].plain_text == name then
            return {
                object = "databaseEntry",
                result = v
            }
        elseif v.properties ~= nil and v.properties.title ~= nil and v.properties.title.title[1] ~= nil and v.properties.title.title[1].text ~= nil and v.properties.title.title[1].text.content == name then
            return {
                object = "page",
                result = v
            }
        end
    end
    return "Problem"
end

M.objectFromID = function(id)
    local raw = vim.json.decode(require "notion".raw()).results
    for _, v in pairs(raw) do
        if v.id == id then
            return v
        end
    end
    return "Problem"
end

--Transforms a database entry into markdown
local function databaseMarkdown(block)
    vim.print(block.properties)
end

--Transform page childrens to markdown
local function pageChildrenMarkdown(pageID)

end

--Transforms notion page to markdown
local function pageMarkdown(block)

end

--Converts notion objects to markdown
M.notionToMarkdown = function(selection, buf)
    local data = M.objectFromName(selection)
    local block = data.result

    if data.object == "databaseEntry" then
        return databaseMarkdown(block)
    elseif data.object == "page" then
        return pageMarkdown(block) .. "\n\n" .. pageChildrenMarkdown(block.id)
    else
        return nil
    end
end

--Parse ISO8601 date, and return the values separated
M.parseISO8601Date = function(isoDate)
    local year, month, day, hour, minute, second, timezone = isoDate:match(
        "(%d+)-(%d+)-(%d+)T?(%d*):?(%d*):?(%d*).?([%+%-]?)(%d*:?%d*)")
    return tonumber(year), tonumber(month), tonumber(day), tonumber(hour), tonumber(minute), tonumber(second),
        timezone,
        timezone and
        (tonumber(timezone) or timezone)
end

--Gets date as comparable (integer)
M.getDate = function(v)
    if v.properties.Dates == nil or v.properties.Dates.date == vim.NIL or v.properties.Dates.date.start == nil then
        return
        "No Date"
    end

    local str = v.properties.Dates.date.start

    local date = str:gsub("-", ""):gsub("T", ""):gsub(":", ""):gsub("+", "")

    return date
end

--Returns full display date of the notion event
M.displayDate = function(v)
    if v.properties.Dates == nil or v.properties.Dates.date == vim.NIL or v.properties.Dates.date.start == nil then
        return
        "No date"
    end

    local inputDate = v.properties.Dates.date.start
    local year, month, day, hour, minute, second, timezone, timezoneValue = M.parseISO8601Date(inputDate)
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


-- Returns only the time of day of the notion event
M.displayShortDate = function(v)
    if v.properties.Dates == nil or v.properties.Dates.date == vim.NIL or v.properties.Dates.date.start == nil then
        return "No date"
    end

    local inputDate = v.properties.Dates.date.start
    local year, month, day, hour, minute, _, _, _ = M.parseISO8601Date(inputDate)
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
    if opts == " " or opts == nil then return "Bug" end
    local content = (vim.json.decode(opts)).results
    local biggestDate = " "
    local data
    for _, v in pairs(content) do
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
    if v.properties.Dates == nil or v.properties.Dates.date == vim.NIL or v.properties.Dates.date.start == nil then return true end
    local str = v.properties.Dates.date.start
    local ymd = string.sub(str, 1, 10)
    local final = ymd:gsub("-", "")

    if final >= vim.fn.strftime("%Y%m%d") then
        return final
    end
    return false
end


M.eventList = function(opts)
    if opts == " " or opts == nil then return nil end
    local content = vim.json.decode(opts).results
    local data = {}
    for _, v in pairs(content) do
        --Get the event for database entries
        if v.properties ~= nil and v.properties.Name ~= nil and v.properties.Name.title[1] ~= nil then
            table.insert(data, {
                displayName = v.properties.Name.title[1].text.content,
                id = v.id
            })
            --Get the event for pages
        elseif v.properties.title ~= nil and v.properties.title.title[1] ~= nil and v.properties.title.title[1].text ~= nil then
            table.insert(data, {
                displayName = v.properties.title.title[1].text.content,
                id = v.id
            })
        end
    end
    return data
end

--Obsolete, needs to follow recode
M.futureEventList = function(opts)
    if opts == " " or opts == nil then return nil end
    local content = vim.json.decode(opts).results
    local data = {}
    local urls = {}
    local ids = {}
    local dates = {}
    for _, v in pairs(content) do
        --Only works on database entries, dont see any use for others?
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

--Event previewer, returns array of string
M.eventPreview = function(data)
    local id = data.value.id

    local block = M.objectFromID(id)
    local final = { "Name: " .. data.value.displayName, " " }

    for i, v in pairs(block.properties) do
        if v.type == "select" and v.type.select ~= nil then
            table.insert(final, v.type .. ": " .. v.select.name)

            table.insert(final, " ")
        elseif v.type == "multi_select" then
            local temp = {}
            for _, j in pairs(v.multi_select) do
                table.insert(temp, j.name)
            end
            table.insert(final, v.type .. ": " .. table.concat(temp, ", "))

            table.insert(final, " ")
        end
    end

    return final
end

M.databaseName = function(object)
    return object.icon.emoji .. " " .. object.title.text.content
end

return M
