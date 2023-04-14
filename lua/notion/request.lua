local storage = vim.fn.stdpath("data") .. "/notion/data.txt"
local Job = require('plenary.job')

local parser = require "notion.parse"

local M = {}

--Makes an asynchronous request to the Notion API, and calls the `callback` with the output
M.request = function(callback, window)
    local file = io.open(storage, "r")
    if file == nil then return end

    local l = file:read("*a")

    local data = {
        sort = {
            direction = "ascending",
            timestamp = "last_edited_time",
        },
    }

    local job = Job:new({
        command = 'curl',
        args = {
            '-X', 'POST',
            '-H', 'Authorization: Bearer ' .. l,
            '-H', 'Content-Type: application/json',
            '-H', 'Notion-Version: 2022-06-28',
            '--data', vim.fn.json_encode(data),
            'https://api.notion.com/v1/search',
        },
        enabled_recording = true,
        on_exit = function(b, code)
            if code == 0 then
                callback(b._stdout_results[1])
            else
                vim.print("[Notion] Error calling API")
            end
            if window ~= nil then
                vim.schedule(function()
                    require "notion.window".close(window)
                end)
            end
        end,
    })

    job:start()
end

--Get database object from its ID
M.resolveDatabase = function(id, callback)
    local file = io.open(storage, "r")
    if file == nil then return end
    local l = file:read("*a")

    local job = Job:new({
        command = 'curl',
        args = {
            '-H', 'Authorization: Bearer ' .. l,
            '-H', 'Notion-Version: 2022-06-28',
            'https://api.notion.com/v1/databases/' .. id
        },
        enabled_recording = true,
        on_exit = function(b, code)
            if code == 0 then
                callback(b._stdout_results[1])
            else
                vim.print("[Notion] Error calling API")
            end
        end,
    })

    job:start()
end

--Delete item from Notion
M.deleteItem = function(selection, window)
    local initData = require "notion".raw()
    local raw = parser.eventList(initData)

    if raw == nil then return end
    local id = raw.ids[selection[1]]

    local file = io.open(storage, "r")

    if file == nil then return end

    local l = file:read("*a")


    local job = Job:new({
        command = 'curl',
        args = {
            '-X', 'DELETE',
            '-H', 'Authorization: Bearer ' .. l,
            '-H', 'Notion-version: 2022-02-22',
            'https://api.notion.com/v1/blocks/' .. id
        },
        enabled_recording = true,
        on_exit = function(b, code)
            if code == 0 then
                vim.schedule(function()
                    require "notion.window".close(window)
                end)
            else
                print("[Notion] Error calling API")
            end
        end,
    })

    job:start()
end

--Get childrens of particular block ID
M.getChildren = function(id, callback)
    local file = io.open(storage, "r")
    if file == nil then return end
    local l = file:read("*a")

    local job = Job:new({
        command = 'curl',
        args = {
            '-H', 'Authorization: Bearer ' .. l,
            '-H', 'Notion-Version: 2022-02-22',
            'https://api.notion.com/v1/blocks/' .. id .. '/children'
        },
        enabled_recording = true,
        on_exit = function(b, code)
            if code == 0 then
                callback(b._stdout_results[1])
            else
                vim.print("[Notion] Error calling api")
            end
        end
    })

    job:start()
end

return M
