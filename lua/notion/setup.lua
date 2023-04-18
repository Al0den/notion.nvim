local M = {}

local status = false
local curl = require "plenary.curl"

--Saves the current key status for next neovim open
local saveStatus = function()
    if status == true then
        require "notion".writeFile(vim.fn.stdpath("data") .. "/notion/prev.txt", "true")
    end
end

--Try a key synchronously
local tryKey = function()
    local l = require "notion".readFile(vim.fn.stdpath("data") .. "/notion/data.txt")
    local headers = {}
    headers["Content-Type"] = "application/json"
    headers["Notion-Version"] = "2021-05-13"
    headers["Authorization"] = "Bearer " .. l

    local res = curl.get({
        method = "POST",
        url = "https://api.notion.com/v1/search",
        headers = headers
    })

    if res.status == 401 then return true end
    vim.print("[Notion] Status: Operational")
    status = true
    saveStatus()
    vim.schedule(function()
        require "notion".update({ silent = false })
    end)
end

--When a key is not set/invalid
local noKey = function()
    local newKey = vim.fn.input("Api key invalid/not set, insert new key:", "", "file")
    require "notion".writeFile(vim.fn.stdpath("data") .. "/notion/data.txt", newKey)
    if tryKey() then
        return vim.print("[Notion] Invalid key, please try again")
    end
end

--Function linked to NotionSetup
local notionSetup = function()
    local content = require "notion".readFile(vim.fn.stdpath("data") .. "/notion/data.txt")
    if content == nil or content == "" or content == " " then
        if os.getenv("NOTION_API_KEY") ~= nil then
            require "notion".writeFile(vim.fn.stdpath("data") .. "/notion/data.txt", os.getenv("NOTION_API_KEY"))
            if tryKey() then noKey() end
        else
            noKey()
        end
    else
        if tryKey() then noKey() end
    end
end

--User accesible function
M.initialisation = function()
    notionSetup()
    return status
end


return M
