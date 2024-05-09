local M = {}
local markdownParser = require "notion.markdown"
local va = vim.api

--Get all current buffers
local function getCurrentBuffers()
    local bufs = vim.tbl_filter(function(t)
        return va.nvim_buf_is_loaded(t) and vim.fn.buflisted(t)
    end, va.nvim_list_bufs())
    return bufs
end

--Update the currently displayed markdown
M.updateMarkdown = function()
--    local buf
--    for _, buff in pairs(getCurrentBuffers()) do
--        local ok, res = pcall(va.nvim_buf_get_var, buff, "owner")
--        if ok and res == "notionMarkdown" then
--            buf = buff
--        end
--    end
--    if not buf then return end
--    local id = vim.print(va.nvim_buf_get_var(buf, "id"))
--    for i, v in ipairs((vim.json.decode(require "notion".raw())).results) do
--        if v.id == id then
--            local markdown
--            if v.parent.type == "database_id" then
--                markdown = markdownParser.databaseEntry(v, id, true)
--            elseif v.parent.type == "page_id" then
--                markdown = markdownParser.page(v, id, true)
--            else
--                return vim.print("[Notion] Problem updating event")
--           end
--            require "notion".writeFile(vim.fn.stdpath("data") .. "/notion/temp.md", markdown)
--            local prevbuf = va.nvim_get_current_buf()
--            vim.fn.win_gotoid(vim.fn.bufwinid(buf))
--            vim.cmd("e")
--            vim.fn.win_gotoid(vim.fn.bufwinid(prevbuf))
--        end
--    end
end

--Receives data from the functions of "request" and forces the new data into storage
M.override = function(data)
    local previousData = vim.json.decode(require "notion".raw())
    for i, v in ipairs(previousData.results) do
        if v.id == data.id then
            previousData.results[i] = data
        end
    end
    require "notion".writeFile(vim.fn.stdpath("data") .. "/notion/saved.txt", vim.json.encode(previousData))
    vim.schedule(function() M.updateMarkdown() end)
end

--Remove entry from raw stored data
M.removeFromData = function(id)
    local previousData = vim.json.decode(require "notion".raw())
    for i, k in ipairs(previousData.results) do
        if k.id == id then
            table.remove(previousData.results, i)
        end
    end
    require "notion".writeFile(vim.fn.stdpath("data") .. "/notion/saved.txt", vim.json.encode(previousData))
end

--Get the full object and its type from its ID (NoteL type shouldnt be required, but simplifies and makes the code breath)
M.objectFromID = function(id)
    local raw = vim.json.decode(require "notion".raw()).results
    for _, v in pairs(raw) do
        if v.id == id then
            return {
                object = v.parent.type,
                result = v
            }
        end
    end
    return vim.err_writeln("[Notion] Cannot find object with id: " .. id)
end

--Converts notion objects to markdown
M.notionToMarkdown = function(selection)
    local data = M.objectFromID(selection.value.id)
    if data.object == "database_id" then
        return markdownParser.databaseEntry(data.result, selection.value.id, false)
    elseif data.object == "page_id" then
        return markdownParser.page(data.result, selection.value.id, false)
    else
        return vim.print("[Notion] Cannot view or edit this event")
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

--Returns full display date of the notion event
M.displayDate = function(inputDate)
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
M.displayShortDate = function(inputDate)
    local year, month, day, hour, minute, _, _, _ = M.parseISO8601Date(inputDate)
    local currentDateTime = os.date("*t")

    local currentYear = currentDateTime.year
    local currentMonth = currentDateTime.month
    local currentDay = currentDateTime.day

    if year == currentYear and month == currentMonth and day == currentDay then
        local formattedTime = string.format("%02d:%02d", hour, minute)
        return formattedTime
    else
        return M.displayDate(inputDate)
    end
end

local getDate = function(k)
    return k.date.start
end

--Returns the earliest event as a block
M.earliest = function(opts)
    if opts == " " or not opts then return vim.err_writeln("[Notion] Unexpected argument") end
    local content = (vim.json.decode(opts)).results
    local biggestDate = " "
    local data
    for _, v in pairs(content) do
        for _, k in pairs(v.properties) do
            local _, date = pcall(getDate, k)
            if date then
                date = date:gsub("-", ""):gsub("T", ""):gsub(":", ""):gsub("+", "")
                if (date < biggestDate or not data) and date > vim.fn.strftime("%Y%m%d") then
                    biggestDate = date
                    data = v
                end
            end
        end
    end
    return data
end

--Get list of event - Only supports databse entries and pages
M.eventList = function(opts)
    if opts == " " or not opts then return end
    local content = vim.json.decode(opts).results
    local data = {}
    for _, v in pairs(content) do
        if v == vim.NIL or v.parent == vim.NIL then return end
        if v.parent.type == "database_id" then
            local added = false
            for i, k in pairs(v.properties) do
                if k.type == "title" and not added and k.title[1] and k.title[1].plain_text then
                    table.insert(data, {
                        displayName = k.title[1].plain_text,
                        id = v.id
                    })
                    added = true
                end
            end
        elseif v.parent.type == "page_id" then
            table.insert(data, {
                displayName = v.properties.title.title[1].plain_text,
                id = v.id
            })
        end
    end
    return data
end

--Event previewer, returns array of string
M.eventPreview = function(data)
    local id = data.value.id

    local block = (M.objectFromID(id)).result
    local final = { "Name: " .. data.value.displayName, " " }

    --Display every individual property block
    for i, v in pairs(block.properties) do
        if v.type == "date" and v.date ~= vim.NIL then
            table.insert(final, i .. ": " .. M.displayDate(v.date.start))
        elseif v.type == "select" and v.select ~= vim.NIL and v.select.name ~= vim.NIL then
            table.insert(final, i .. ": " .. v.select.name)
        elseif v.type == "multi_select" then
            local temp = {}
            for _, j in pairs(v.multi_select) do
                table.insert(temp, j.name)
            end
            table.insert(final, i .. ": " .. table.concat(temp, ", "))
        elseif v.type == "number" and v.number ~= vim.NIL then
            table.insert(final, i .. ": " .. v.number)
        elseif v.type == "email" and v.email ~= vim.NIL then
            table.insert(final, i .. ": " .. v.email)
        elseif v.type == "url" and v.url ~= vim.NIL then
            table.insert(final, i .. ": " .. v.url)
        elseif v.type == "people" and v.people[1] then
            table.insert(final, i .. ": " .. v.people[1].name)
        else
            goto continue
        end
        table.insert(final, " ")
        ::continue::
    end

    local data, previous = pcall(require "notion".readFile, vim.fn.stdpath("data") .. "/notion/data/" .. block.id)

    --Display potential saved data that was stored on previous load
    if data then
        local toWrite = require "notion.markdown".removeChildrenTrash(vim.json.decode(previous).results)
        require "notion".writeFile(vim.fn.stdpath("data") .. "/notion/tempJson.json", vim.json.encode(toWrite))
        require "notion".writeFile(vim.fn.stdpath("data") .. "/notion/staticJson.json", vim.json.encode(toWrite))

        local response = (vim.json.decode(previous)).results

        local function parseRichText(richText)
            local markdown = ""
            for _, value in ipairs(richText) do
                local text = value.text.content
                local annotations = value.annotations
                if annotations.bold then
                    text = "**" .. text .. "**"
                end
                if annotations.italic then
                    text = "_" .. text .. "_"
                end
                if annotations.strikethrough then
                    text = "~~" .. text .. "~~"
                end
                if annotations.underline then
                    text = "__" .. text .. "__"
                end
                if annotations.code then
                    text = "`" .. text .. "`"
                end
                if value.type == "link" then
                    text = "[" .. text .. "](" .. value.url .. ")"
                end
                markdown = markdown .. text
            end
            return markdown
        end

        local function parseBlocks(blocks)
            local markdown = ""
            local numbered_list_counter = 1
            local prevBlock = nil
            for _, block in ipairs(blocks) do
                if (prevBlock == "bulleted_list_item" and block.type ~= "bulleted_list_item") or (prevBlock == "numbered_list_item" and block.type ~= "numbered_list_item") then
                    table.insert(final, "")
                end
                if block.type == "heading_1" then
                    table.insert(final, "# " .. parseRichText(block.heading_1.rich_text))
                elseif block.type == "heading_2" then
                    table.insert(final, "## " .. parseRichText(block.heading_2.rich_text))
                elseif block.type == "heading_3" then
                    table.insert(final, "### " .. parseRichText(block.heading_3.rich_text))
                elseif block.type == "paragraph" then
                    table.insert(final, parseRichText(block.paragraph.rich_text))
                elseif block.type == "bulleted_list_item" then
                    table.insert(final, "- " .. parseRichText(block.bulleted_list_item.rich_text))
                    goto next
                elseif block.type == "numbered_list_item" then
                    if prevBlock == "numbered_list_item" then
                        numbered_list_counter = numbered_list_counter + 1
                    else
                        numbered_list_counter = 1
                    end
                    table.insert(final,
                        numbered_list_counter .. ". " .. parseRichText(block.numbered_list_item.rich_text))
                    goto next
                elseif block.type == "toggle" then
                    table.insert(final, "<details><summary>" .. parseRichText(block.toggle.rich_text) .. "</summary>")
                end
                table.insert(final, "")
                ::next::
                prevBlock = block.type
            end
            return data
        end
        parseBlocks(response)
    end

    --Returns object containing all display preview lines
    return final
end

return M
