local M = {}

M.earliest = function(opts)
    if opts == " " or opts == nil then return nil end
    local content = (vim.json.decode(opts)).results
    local biggestDate = ""
    local data
    for k, v in pairs(content) do
        if v.properties.Dates ~= nil and v.properties.Dates.date ~= vim.NIL then
            if v.properties.Dates.date.start ~= nil then
                local str = v.properties.Dates.date.start
                local ymd = string.sub(str, 1, 10)
                local final = ymd:gsub("-", "")

                if final < biggestDate or data == nil then
                    if final > vim.fn.strftime("%Y%m%d") then
                        biggestDate = final
                        data = v
                    end
                end
            end
        end
    end
    return data
end

local function compareDates(v)
    if v == nil then return end
    if v.properties.Dates ~= nil and v.properties.Dates.date ~= vim.NIL then
        if v.properties.Dates.date.start ~= nil then
            local str = v.properties.Dates.date.start
            local ymd = string.sub(str, 1, 10)
            local final = ymd:gsub("-", "")

            if final >= vim.fn.strftime("%Y%m%d") then
                return true
            end
            return false
        end
    end
end

M.eventList = function(opts)
    if opts == " " or opts == nil then return nil end
    local content = vim.json.decode(opts).results
    local data = {}
    local urls = {}
    for _, v in pairs(content) do
        if v.properties ~= nil and v.properties.Name ~= nil and v.properties.Name.title[1] ~= nil then
            if compareDates(v) then
                table.insert(data, v.properties.Name.title[1].plain_text)
                urls[v.properties.Name.title[1].plain_text] = v.url
            end
        end
    end
    return { data = data, urls = urls }
end

return M
