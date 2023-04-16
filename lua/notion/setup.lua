local M = {}

local status = false
local curl = require "plenary.curl"

--Saves the current key status for next neovim open
local saveStatus = function()
    local path = vim.fn.stdpath("data") .. "/notion/prev.txt"
    local file = io.open(path, "w")
    if file == nil then return false end
    if status == true then
        file:write("true")
    end
    file:close()
end

--Try a key synchronously
local tryKey = function()
    local headers = {}
    local storageFile = vim.fn.stdpath("data") .. "/notion/data.txt"
    local file = io.open(storageFile, "r")

    if file == nil then return true end

    local l = file:read("*a")

    headers["Content-Type"] = "application/json"
    headers["Notion-Version"] = "2021-05-13"
    headers["Authorization"] = "Bearer " .. l

    local res = curl.get({
        method = "POST",
        url = "https://api.notion.com/v1/search",
        headers = headers
    })

    if res.status == 401 then return true end
    require "notion".saveData(res.body)
    vim.print("[Notion] Status: Operational")
    status = true
    saveStatus()
end

--When a key is not set/invalid
local noKey = function()
    local newKey = vim.fn.input("Api key invalid/not set, insert new key:", "", "file")
    local storage = vim.fn.stdpath("data") .. "/notion/data.txt"
    local file = io.open(storage, "w")
    if file == nil then
        return vim.print("[Notion] Incorrect Configuration")
    else
        file:write(newKey)
        file:close()
        if tryKey() then
            return vim.print("[Notion] Invalid key, please try again")
        end
    end
end

--Function linked to NotionSetup
local notionSetup = function()
    local storage = vim.fn.stdpath("data") .. "/notion/data.txt"

    local file = io.open(storage, "r")
    local l = {}

    if file == nil then
        print("[Notion] Please report bug")
    else
        l = file:read("*a")
        file:close()
        if l == " " or l == "" or l == "\n" then
            print(l)
            noKey()
        else
            if tryKey() then noKey() end
        end
    end
end

--User accesible function
M.initialisation = function()
    notionSetup()
    return status
end


return M
