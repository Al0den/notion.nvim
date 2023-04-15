local M = {}

local function createFile(text)
    local path = vim.fn.stdpath("data") .. "/notion/temp.md"
    local file = io.open(path, "w")
    if file == nil then return end
    file:write(text)
    file:close()
    vim.schedule(function()
        vim.cmd("vsplit " .. path)
    end)
end


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
            for _, block in ipairs(blocks) do
                if block.type == "heading_1" then
                    markdown = markdown .. "# " .. parseRichText(block.heading_1.rich_text) .. "\n"
                elseif block.type == "heading_2" then
                    markdown = markdown .. "## " .. parseRichText(block.heading_2.rich_text) .. "\n"
                elseif block.type == "heading_3" then
                    markdown = markdown .. "### " .. parseRichText(block.heading_3.rich_text) .. "\n"
                elseif block.type == "paragraph" then
                    markdown = markdown .. parseRichText(block.paragraph.rich_text) .. "\n"
                elseif block.type == "bulleted_list_item" then
                    markdown = markdown .. "- " .. parseRichText(block.bulleted_list_item.rich_text) .. "\n"
                elseif block.type == "numbered_list_item" then
                    markdown = markdown .. "1. " .. parseRichText(block.numbered_list_item.rich_text) .. "\n"
                elseif block.type == "toggle" then
                    markdown = markdown ..
                        "<details><summary>" .. parseRichText(block.toggle.rich_text) .. "</summary>\n"
                    markdown = markdown .. parseBlocks(block.toggle.children) .. "</details>\n"
                end
            end
            return markdown
        end

        local markdown = parseBlocks(response)
        createFile(ftext .. "\n\n" .. markdown)
    end
    require "notion.request".getChildren(id, onChild)
end

M.databaseEntry = function(data, id)
    return vim.print("[Notion] No markdown for database entries as of right now")
end

return M
