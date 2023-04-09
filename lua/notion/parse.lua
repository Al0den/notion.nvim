local M = {}

M.earliest = function(opts)
    if opts == "" or opts == nil then return end
    content = (vim.json.decode(opts)).results
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

return M
