local M = {}

--Creates the markdown file for user edition
local function createMarkdownFile(markdown)
    vim.print(markdown)
end

--Transforms children blocks into markdown
local function childrenToMarkdown(childrens)
    local markdown = ""
    for _, result in ipairs(childrens) do
        if result.object ~= "block" then return end

        if result.type == "heading_2" then
            markdown = markdown .. "# " .. result.heading_2.rich_text[1].plain_text .. "\n"
        elseif result.type == "paragraph" then
            local content = result.paragraph.rich_text[1].plain_text
            local url = result.paragraph.rich_text[1].text.link.url
            markdown = markdown .. content
            if url then
                markdown = markdown .. " [Read more](" .. url .. ")"
            end
            markdown = markdown .. "\n\n"
        end
    end
    return markdown
end

--Converts notion pages to markdown, and calls the create markdown function
M.notionToMarkdown = function(block)
    local name = block.properties.Name.title[1].plain_text
    local url = block.url
    local dates = block.properties.Dates.date.start
    local topic = block.properties.Topic.multi_select[1].name
    local type = block.properties.Type.select.name

    local markdown = string.format("# [%s](%s)\n\n- **Dates:** %s\n- **Topic:** %s\n- **Type:** %s\n",
        name, url, dates, topic, type)

    local function callback(childrens)
        childrens = vim.json.decode(childrens).results
        createMarkdownFile(markdown .. "\n \n" .. childrenToMarkdown(childrens))
    end

    require "notion.request".getChildren(block.id, callback)
end

--Parse ISO8601 date (Function reused and heavy, relocated to this file)
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

M.objectFromName = function(name)
    local raw = vim.json.decode(require "notion".raw()).results
    for _, v in pairs(raw) do
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
