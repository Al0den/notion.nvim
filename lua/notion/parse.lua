local M = {}

M.earliest = function(opts)
    if opts == " " or opts == nil then return nil end
    local content = (vim.json.decode(opts)).results
    local biggestDate = ""
    local data
    for k, v in pairs(content) do
        if v.properties.Dates ~= nil and v.properties.Dates.date ~= vim.NIL and v.properties.Dates.date.start ~= nil then
            local str = v.properties.Dates.date.start
            local ymd = string.sub(str, 1, 10)
            local final = ymd:gsub("-", "")

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
    if v.properties.Dates ~= nil and v.properties.Dates.date ~= vim.NIL and v.properties.Dates.date.start ~= nil then
        local str = v.properties.Dates.date.start
        local ymd = string.sub(str, 1, 10)
        local final = ymd:gsub("-", "")

        if final >= vim.fn.strftime("%Y%m%d") then
            return final
        end
        return false
    end
    return true
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
    local sorter = {}
    for _, v in pairs(content) do
        if v.properties ~= nil and v.properties.Name ~= nil and v.properties.Name.title[1] ~= nil and compareDates(v) then
            if compareDates(v) == true then
                dates[v.properties.Name.title[1].plain_text] = compareDates(v)
            else
                dates[v.properties.Name.title[1].plain_text] = compareDates(v)
                table.insert(data, v.properties.Name.title[1].plain_text)
            end
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
    if block.properties.Dates ~= nil and block.properties.Dates.date ~= nil then
        table.insert(final, "Date: " .. block.properties.Dates.date.start)
        table.insert(final, " ")
    end
    if block.properties.Type ~= nil and block.properties.Type.select ~= nil then
        table.insert(final, "Type: " .. block.properties.Type.select.name)
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
        table.insert(final, l)
        table.insert(final, " ")
    end
    return final
end

M.databaseName = function(object)
    return object.icon.emoji .. " " .. object.title.text.content
end

return M
