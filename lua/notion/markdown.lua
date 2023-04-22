local M = {}

local type

M.onUpdate = function(data)
    data = vim.json.decode(data)
end

local removeIDs = function(properties)
    for i, v in pairs(properties) do
        if v.type == "select" then
            properties[i].select.id = nil
        elseif v.type == "multi_select" then
            for _, value in ipairs(v.multi_select) do
                value.id = nil
            end
        end
        v.type = nil
        v.id = nil
    end
    return properties
end

local removeChildrenTrash = function(childs)
    local editorType = require "notion".opts.editor
    if editorType == "full" then return childs end
    for i, v in ipairs(childs) do
        v.archived = nil
        v.object = nil
        v.last_edited_time = nil
        v.created_time = nil
        v.has_children = nil
        v.created_by = nil
        v.last_edited_by = nil
        v.parent = nil
        if v["paragraph"] then
            for _, k in ipairs(v.paragraph.rich_text) do
                k.plain_text = nil
                if editorType == "light" then
                    k.text.link = nil
                    k.annotations = nil
                    k.type = nil
                    k.href = nil
                end
            end
        end
        if v["heading_1"] then
            if editorType == "light" then v.heading_1.is_toggleable = nil end
            for _, k in ipairs(v.heading_1.rich_text) do
                k.plain_text = nil
                if editorType == "light" then
                    k.text.link = nil
                    k.annotations = nil
                    k.type = nil
                    k.href = nil
                end
            end
        end
        if v["numbered_list_item"] then
            for _, k in ipairs(v.numbered_list_item.rich_text) do
                k.plain_text = nil
                if editorType == "light" then
                    k.text.link = nil
                    k.annotations = nil
                    k.type = nil
                    k.href = nil
                end
            end
        end
        if v["heading_3"] then
            if editorType == "light" then v.heading_3.is_toggleable = nil end
            for _, k in ipairs(v.heading_3.rich_text) do
                k.plain_text = nil
                if editorType == "light" then
                    k.text.link = nil
                    k.annotations = nil
                    k.type = nil
                    k.href = nil
                end
            end
        end
        if v["heading_2"] then
            if editorType == "light" then v.heading_2.is_toggleable = nil end
            for _, k in ipairs(v.heading_2.rich_text) do
                k.plain_text = nil
                if editorType == "light" then
                    k.text.link = nil
                    k.annotations = nil
                    k.type = nil
                    k.href = nil
                end
            end
        end
        if v["bulleted_list_item"] then
            if editorType == "light" then v.bulleted_list_item.is_toggleable = nil end
            for _, k in ipairs(v.bulleted_list_item.rich_text) do
                k.plain_text = nil
                if editorType == "light" then
                    k.text.link = nil
                    k.annotations = nil
                    k.type = nil
                    k.href = nil
                end
            end
        end
    end
    return childs
end

local function onSave()
    if vim.api.nvim_buf_get_var(0, "owner") ~= "notionJson" then return end
    local prev = require "notion".readFile(vim.fn.stdpath("data") .. "/notion/staticJson.json")
    local new = require "notion".readFile(vim.fn.stdpath("data") .. "/notion/tempJson.json")
    new = string.gsub(new, "\n", "")
    local data = vim.json.decode(new)
    local prevData = vim.json.decode(prev)
    local id = require "notion".readFile(vim.fn.stdpath("data") .. "/notion/id.txt")
    if type == "page" then
        for _, v in ipairs(data) do
            require "notion.request".saveBlock(vim.json.encode(v), v.id)
        end
        return vim.notify("WIP")
    elseif type == "databaseEntry" then
        require "notion.request".savePage('{"properties": ' .. vim.json.encode(data) .. "}", id)
    end
end

--Create the temporary markdown file with the given content
local function createFile(text, data, id)
    local idPATH = vim.fn.stdpath("data") .. "/notion/id.txt"
    require "notion".writeFile(idPATH, id)
    local path = vim.fn.stdpath("data") .. "/notion/temp.md"
    local jsonPath = vim.fn.stdpath("data") .. "/notion/tempJson.json"
    require "notion".writeFile(path, text)
    vim.schedule(function()
        --        vim.cmd("edit " .. path)
        --      vim.api.nvim_buf_set_var(0, "owner", "notionMarkdown")
        --    vim.cmd("set noma")
        vim.cmd("vsplit " .. jsonPath)
        vim.api.nvim_buf_set_var(0, "owner", "notionJson")
        vim.cmd('set ma')
        vim.defer_fn(function() vim.lsp.buf.format() end, require "notion".opts.formatDelay)
        vim.api.nvim_create_autocmd("BufWritePost", {
            callback = onSave,
            buffer = 0
        })
    end)
end

--Transfom a page into markdown
M.page = function(data, id, silent)
    local ftext = " # Title: " .. data.properties.title.title[1].plain_text
    local buf = require "notion.window".create("Loading...")
    local function onChild(child)
        local toWrite = removeChildrenTrash(vim.json.decode(child).results)
        require "notion".writeFile(vim.fn.stdpath("data") .. "/notion/tempJson.json", vim.json.encode(toWrite))
        require "notion".writeFile(vim.fn.stdpath("data") .. "/notion/staticJson.json", vim.json.encode(toWrite))
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
            local numbered_list_counter = 1
            local prevBlock = nil
            for _, block in ipairs(blocks) do
                if (prevBlock == "bulleted_list_item" and block.type ~= "bulleted_list_item") or (prevBlock == "numbered_list_item" and block.type ~= "numbered_list_item") then
                    markdown = markdown .. "\n"
                end
                if block.type == "heading_1" then
                    markdown = markdown .. "# " .. parseRichText(block.heading_1.rich_text) .. "\n\n"
                    prevBlock = block.type
                elseif block.type == "heading_2" then
                    markdown = markdown .. "## " .. parseRichText(block.heading_2.rich_text) .. "\n\n"
                    prevBlock = block.type
                elseif block.type == "heading_3" then
                    markdown = markdown .. "### " .. parseRichText(block.heading_3.rich_text) .. "\n\n"
                    prevBlock = nil
                elseif block.type == "paragraph" then
                    markdown = markdown .. parseRichText(block.paragraph.rich_text) .. "\n\n"
                    prevBlock = nil
                elseif block.type == "bulleted_list_item" then
                    markdown = markdown .. "- " .. parseRichText(block.bulleted_list_item.rich_text) .. "\n"
                    prevBlock = block.type
                elseif block.type == "numbered_list_item" then
                    if prevBlock == "numbered_list_item" then
                        numbered_list_counter = numbered_list_counter + 1
                    else
                        numbered_list_counter = 1
                    end
                    markdown = markdown ..
                        numbered_list_counter .. ". " .. parseRichText(block.numbered_list_item.rich_text) .. "\n"
                    prevBlock = block.type
                elseif block.type == "toggle" then
                    markdown = markdown ..
                        "<details><summary>" .. parseRichText(block.toggle.rich_text) .. "</summary>\n"
                    markdown = markdown .. parseBlocks(block.toggle.children) .. "</details>\n\n"
                end
            end
            return markdown
        end

        local markdown = parseBlocks(response)
        type = "page"
        if silent then
            vim.schedule(function()
                require "notion".writeFile(vim.fn.stdpath("data") .. "/notion/temp.md", ftext .. "\n\n" .. markdown)
                vim.cmd("vsplit " .. vim.fn.stdpath("data") .. "/notion/temp.md")
                vim.api.nvim_buf_set_var(0, "owner", "notionMarkdown")
            end)
            return
        end
        createFile(ftext .. "\n\n" .. markdown, data, data.id)
    end
    require "notion.request".getChildren(id, onChild)
end

--Transform a databse entry into markdown
M.databaseEntry = function(data, id, silent)
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
    require "notion".writeFile(vim.fn.stdpath("data") .. "/notion/tempJson.json",
        vim.json.encode(removeIDs(data.properties)))

    type = "databaseEntry"
    if silent then return ftext end
    createFile(ftext, data, data.id)
end

return M
