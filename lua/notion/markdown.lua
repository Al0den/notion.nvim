local M = {}

local function onSave()
    local f = io.open(vim.fn.stdpath("data") .. "/notion/tempData.txt", "r")
    if f == nil then return end
    local prev = vim.json.decode(f:read("*a"))
    f:close()
    local f = io.open(vim.fn.stdpath("data") .. "/notion/temp.md", "r")
    if f == nil then return end
    local new = f:read("*a")
    local result = {}
    local pattern = "%*%*(.-)%*%*:%s*(.-)\n"
    for key, value in string.gmatch(new, pattern) do
        result[key] = value -- Add the key-value pair to the result table
    end
    for i, v in pairs(result) do
        if prev.properties[i] ~= nil then
            if prev.properties[i].type == "title" then
                prev.properties[i].title[1].plain_text = v
                prev.properties[i].title[1].text.content = v
            elseif prev.properties[i].type == "select" then
                prev.properties[i].select.name = v
            end
        end
    end
    local payload = '{"properties": ' .. vim.json.encode(prev.properties) .. "}"
    vim.print(payload)
    require "notion.request".savePage(payload, prev.id)
end

--Create the temporary markdown file with the given content
local function createFile(text)
    local path = vim.fn.stdpath("data") .. "/notion/temp.md"
    local file = io.open(path, "w")
    if file == nil then return end
    file:write(text)
    file:close()
    vim.schedule(function()
        vim.cmd("vsplit " .. path)
        vim.api.nvim_create_autocmd("BufWritePost", {
            callback = onSave,
            buffer = 0
        })
    end)
end

--Transfom a page into markdown
M.page = function(data, id)
    local ftext = " # Title: " .. data.properties.title.title[1].plain_text
    local buf = require "notion.window".create("Loading...")
    local function onChild(child)
        vim.schedule(function()
            require "notion.window".close(buf)
        end)
        local response = (vim.json.decode(child)).results
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
            local numbered_list_counter = 0
            local prevBlock = nil
            for _, block in ipairs(blocks) do
                if block.type == "heading_1" then
                    markdown = markdown .. "# " .. parseRichText(block.heading_1.rich_text) .. "\n\n"
                    prevBlock = nil
                elseif block.type == "heading_2" then
                    markdown = markdown .. "## " .. parseRichText(block.heading_2.rich_text) .. "\n\n"
                    prevBlock = nil
                elseif block.type == "heading_3" then
                    markdown = markdown .. "### " .. parseRichText(block.heading_3.rich_text) .. "\n\n"
                    prevBlock = nil
                elseif block.type == "paragraph" then
                    markdown = markdown .. parseRichText(block.paragraph.rich_text) .. "\n\n"
                    prevBlock = nil
                elseif block.type == "bulleted_list_item" then
                    markdown = markdown .. "- " .. parseRichText(block.bulleted_list_item.rich_text) .. "\n\n"
                    prevBlock = nil
                elseif block.type == "numbered_list_item" then
                    vim.print(prevBlock)
                    if prevBlock == "numbered_list_item" then
                        numbered_list_counter = numbered_list_counter + 1
                    else
                        numbered_list_counter = 1
                    end
                    markdown = markdown ..
                    numbered_list_counter .. ". " .. parseRichText(block.numbered_list_item.rich_text) .. "\n\n"
                    prevBlock = "numbered_list_item"
                elseif block.type == "toggle" then
                    markdown = markdown ..
                        "<details><summary>" .. parseRichText(block.toggle.rich_text) .. "</summary>\n"
                    markdown = markdown .. parseBlocks(block.toggle.children) .. "</details>\n\n"
                end
            end
            return markdown
        end

        local markdown = parseBlocks(response)
        createFile(ftext .. "\n\n" .. markdown)
    end
    require "notion.request".getChildren(id, onChild)
end

--Transform a databse entry into markdown
M.databaseEntry = function(data, id)
    local f = io.open(vim.fn.stdpath("data") .. "/notion/tempData.txt", "w")
    if f == nil then return end
    f:write(vim.json.encode(data))
    f:close()
    local ftext = ""
    for i, v in pairs(data.properties) do
        if v.type == "title" and v.title[1] ~= vim.NIL then
            ftext = ftext .. "\n**" .. i .. "**: " .. v.title[1].plain_text
        elseif v.type == "select" and v.select ~= nil then
            ftext = ftext .. "\n**" .. i .. "**: " .. v.select.name
        elseif v.type == "multi_select" then
            local temp = {}
            for _, j in pairs(v.multi_select) do
                table.insert(temp, j.name)
            end
            ftext = ftext .. "\n**" .. i .. "**: " .. table.concat(temp, ", ")
        elseif v.type == "number" and v.number ~= vim.NIL then
            ftext = ftext .. "\n**" .. i .. "**: " .. v.number
        elseif v.type == "email" and v.email ~= vim.NIL then
            ftext = ftext .. "\n**" .. i .. "**: " .. v.email
        elseif v.type == "url" and v.url ~= vim.NIL then
            ftext = ftext .. "\n**" .. i .. "**: " .. v.url
        elseif v.type == "people" and v.people[1] ~= nil then
            ftext = ftext .. "\n**" .. i .. "**: " .. v.people[1].name
        end
    end
    createFile(ftext)
end

return M
