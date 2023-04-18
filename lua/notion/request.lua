local storage = vim.fn.stdpath("data") .. "/notion/data.txt"
local Job = require('plenary.job')

local M = {}

--Makes an asynchronous request to the Notion API, and calls the `callback` with the output
M.request = function(callback, window)
    local l = require "notion".readFile(storage)

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
                vim.print("[Notion] Error calling API, code: " .. code)
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
    local l = require "notion".readFile(storage)

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
                vim.print("[Notion] Error calling API, code: " .. code)
            end
        end,
    })

    job:start()
end

--Delete item from Notion
M.deleteItem = function(id, window)
    local l = require "notion".readFile(storage)

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
                print("[Notion] Error calling API, code: " .. code)
            end
        end,
    })

    job:start()
end

--Get childrens of particular block ID
M.getChildren = function(id, callback)
    local l = require "notion".readFile(storage)

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
                vim.print("[Notion] Error calling api, code: " .. code)
            end
        end
    })

    job:start()
end

--Save a page with the new information provided
M.savePage = function(data, id)
    local l = require "notion".readFile(storage)

    local job = Job:new({
        command = 'curl',
        args = {
            'https://api.notion.com/v1/pages/' .. id,
            '-H', 'Authorization: Bearer ' .. l,
            '-H', 'Content-Type: application/json',
            '-H', 'Notion-Version: 2022-06-28',
            '-X', 'PATCH',
            '--data', vim.fn.json_encode(data),
        },
        on_exit = function(b, code)
            if code == 0 then
                vim.print("[Notion] Page updated successfully")
            else
                vim.print("[Notion] Failed with code " .. code)
            end
        end
    })

    job:start()
end

--Save a page children's
M.saveChildrens = function(data, id)
    local l = require "notion".readFile(storage)

    local job = Job:new({
        command = 'curl',
        args = {
            'https://api.notion.com/v1/blocks/' .. id .. '/children',
            '-H', 'Authorization: Bearer ' .. l,
            '-H', 'Content-Type: application/json',
            '-H', 'Notion-Version: 2022-06-28',
            '-X', 'PATCH',
            '--data', vim.fn.json_encode(data),
        },
        on_exit = function(b, code)
            if code == 0 then
                vim.print("[Notion] Childrens updated successfully")
            else
                vim.print("[Notion] Failed with code " .. code)
            end
        end
    })

    job:start()
end

return M
