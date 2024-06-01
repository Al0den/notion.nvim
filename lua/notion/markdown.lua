local M = {}

local type

--Remove id's
local removeDatabaseTrash = function(properties)
    for i, v in pairs(properties) do
        if v.type == "select" and v.select ~= nil and v.select ~= vim.NIL then
            properties[i].select.id = nil
            properties[i].select.color = nil
        elseif v.type == "multi_select" then
            for _, value in ipairs(v.multi_select) do
                value.id = nil
            end
        elseif v.type == "title" then
            for _, k in pairs(v.title) do
                k.plain_text = nil
                if require "notion".opts.editor == "light" then
                    k.annotations = nil
                    k.href = nil
                    k.type = nil
                    k.text.link = nil
                end
            end
        end
        v.id = nil
    end
    return properties
end

--Executed on editor save
local function onSave()
    if vim.api.nvim_buf_get_var(0, "owner") ~= "notionJson" then return end
    local new = string.gsub(require "notion".readFile(vim.fn.stdpath("data") .. "/notion/tempJson.json"), "\n", "")
    local data = vim.json.decode(new)
    local id = require "notion".readFile(vim.fn.stdpath("data") .. "/notion/id.txt")
    if type == "page" then
        local temp = {}
        local i = 1
        for k, v in ipairs(data) do
            temp[k] = v
        end
        local window = require "notion.window".create("Saving: " .. 0 .. "/" .. #temp)
        vim.fn.timer_start(1000, function()
            require "notion.request".saveBlock(vim.json.encode(temp[i]), temp[i].id)
            require "notion.window".close(window)
            window = require "notion.window".create("Saving: " .. i .. "/" .. #temp)
            require "notion".writeFile(vim.fn.stdpath("data") .. "/notion/currentJob.txt",
                "\nSaving data: " .. i .. "/" .. #temp)
            i = i + 1
            if i == #temp + 1 then
                require "notion.window".close(window)
                require "notion".writeFile(vim.fn.stdpath("data") .. "/notion/currentJob.txt", "")
            end
        end, { ["repeat"] = #temp })
    elseif type == "databaseEntry" then
        local window = require "notion.window".create("Updating: 1/1")
        require "notion.request".savePage('{"properties": ' .. vim.json.encode(data) .. "}", id, window)
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
        if require "notion".opts.viewOnEdit.enabled then
            if require "notion".opts.viewOnEdit.replace then
                vim.cmd("edit " .. path)
            else
                vim.cmd(require "notion".opts.direction .. " " .. path)
            end
            vim.api.nvim_buf_set_var(0, "owner", "notionMarkdown")
            vim.api.nvim_buf_set_var(0, "id", id)
        end
        vim.cmd(require "notion".opts.direction .. " " .. jsonPath)
        vim.api.nvim_buf_set_var(0, "owner", "notionJson")
        vim.api.nvim_buf_set_var(0, "id", id)
        local buf = vim.api.nvim_get_current_buf()
        vim.cmd('set ma')
        vim.defer_fn(function() vim.lsp.buf.format({ bufnr = buf }) end, require "notion".opts.delays.format)
        vim.api.nvim_create_autocmd("BufWritePost", {
            callback = onSave,
            buffer = 0
        })
    end)
end

--Remove according to editor preferences
local removeChildrenTrash = function(childs)
    local editorType = require "notion".opts.editor
    if editorType == "full" then return childs end
    if childs == nil then return "" end
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
                    k.annotations = nil
                    k.href = nil
                end
            end
        end
        if v["heading_1"] then
            for _, k in ipairs(v.heading_1.rich_text) do
                k.plain_text = nil
                if editorType == "light" then
                    k.annotations = nil
                    k.href = nil
                end
            end
        end
        if v["numbered_list_item"] then
            for _, k in ipairs(v.numbered_list_item.rich_text) do
                k.plain_text = nil
                if editorType == "light" then
                    k.annotations = nil
                    k.href = nil
                end
            end
        end
        if v["heading_3"] then
            for _, k in ipairs(v.heading_3.rich_text) do
                k.plain_text = nil
                if editorType == "light" then
                    k.annotations = nil
                    k.href = nil
                end
            end
        end
        if v["heading_2"] then
            for _, k in ipairs(v.heading_2.rich_text) do
                k.plain_text = nil
                if editorType == "light" then
                    k.annotations = nil
                    k.href = nil
                end
            end
        end
        if v["bulleted_list_item"] then
            for _, k in ipairs(v.bulleted_list_item.rich_text) do
                k.plain_text = nil
                if editorType == "light" then
                    k.annotations = nil
                    k.href = nil
                end
            end
        end
    end
    return childs
end

--Global access
M.removeChildrenTrash = removeChildrenTrash

--Transfom a page into markdown
M.page = function(data, id, silent, open)
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
            if richText == nil then return "" end
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
            if blocks == nil then return "" end
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
        if open then
            createFile(ftext .. "\n\n" .. markdown, data, id)
        end
        vim.schedule(function()
            require "notion".writeFile(vim.fn.stdpath("data") .. "/notion/temp.md", ftext .. "\n\n" .. markdown)
            if open then
                vim.cmd("vsplit " .. vim.fn.stdpath("data") .. "/notion/temp.md")
                vim.api.nvim_buf_set_var(0, "owner", "notionMarkdown")
                vim.api.nvim_buf_set_var(0, "id", id)
            end
        end)
        return markdown
    end
    require "notion.request".getChildren(id, onChild)
end

--Transform a databse entry into markdown
M.databaseEntry = function(data, id, silent, open)
    local ftext = ""
    for i, v in pairs(data.properties) do
        if v.type == "title" and v.title[1] ~= vim.NIL then
            ftext = ftext .. "**" .. i .. "**: " .. v.title[1].plain_text .. "\n"
        elseif v.type == "select" and v.select ~= nil and v.select ~= vim.NIL and v.select.name ~= nil and v.select.name ~= vim.NIL then
            ftext = ftext .. "**" .. i .. "**: " .. v.select.name .. "\n"
        elseif v.type == "multi_select" then
            local temp = {}
            for _, j in pairs(v.multi_select) do
                table.insert(temp, j.name)
            end
            ftext = ftext .. "**" .. i .. "**: " .. table.concat(temp, ", ") .. "\n"
        elseif v.type == "number" and v.number ~= vim.NIL then
            ftext = ftext .. "**" .. i .. "**: " .. v.number .. "\n"
        elseif v.type == "email" and v.email ~= vim.NIL then
            ftext = ftext .. "**" .. i .. "**: " .. v.email .. "\n"
        elseif v.type == "url" and v.url ~= vim.NIL then
            ftext = ftext .. "**" .. i .. "**: " .. v.url .. "\n"
        elseif v.type == "people" and v.people[1] then
            ftext = ftext .. "**" .. i .. "**: " .. v.people[1].name .. "\n"
        end
    end
    require "notion".writeFile(vim.fn.stdpath("data") .. "/notion/tempJson.json", vim.json.encode(removeDatabaseTrash(data.properties)))

    type = "databaseEntry"
    if silent then return ftext end
    if open then
        createFile(ftext, data, id)
        return
    else
        require "notion".writeFile(vim.fn.stdpath("data") .. "/notion/temp.md", ftext)
    end
end

M.removeIDs = removeDatabaseTrash

return M
