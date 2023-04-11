local M = {}

local status = false
local curl = require "plenary.curl"

local saveStatus = function()
    local path = vim.fn.stdpath("data") .. "/notion/prev.txt"
    local file = io.open(path, "w")
    if file == nil then return false end

    file:write("true")
end

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

    vim.print("[Notion] Status: Operational")
    status = true
    saveStatus()
end

local noKey = function()
    local newKey = vim.fn.input("Api key invalid/not set, insert new key:", "", "file")
    local storage = vim.fn.stdpath("data") .. "/notion/data.txt"
    local file = io.open(storage, "w")
    if file == nil then
        return vim.print("[Notion] Incorrect Configuration")
    else
        file:write(newKey)
        file:close()
        vim.print("[Notion] To setup, run command :NotionSetup")
    end
end

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

M.initialisation = function()
    notionSetup()
    return status
end


return M
