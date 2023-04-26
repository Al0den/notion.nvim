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
            if window then
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
            '--data', data,
        },
        on_exit = function(b, code)
            if code == 0 and b._stdout_results[1].object ~= "error" then
                local ans = vim.json.decode(b._stdout_results[1])
                if ans.object == "error" then
                    vim.print(b._stdout_results[1])
                end
            else
                vim.print(b._stdout_results[1].message or code)
            end
        end
    })

    job:start()
end

M.saveBlock = function(data, id)
    local l = require "notion".readFile(storage)
    local job = Job:new({
        command = 'curl',
        args = {
            'https://api.notion.com/v1/blocks/' .. id,
            '-H', 'Authorization: Bearer ' .. l,
            '-H', 'Content-Type: application/json',
            '-H', 'Notion-Version: 2022-06-28',
            '-X', 'PATCH',
            '--data', data,
        },
        on_exit = function(b, code)
            if code == 0 then
                local ans = vim.json.decode(b._stdout_results[1])
                if ans.object == "error" then
                    vim.print(b._stdout_results[1])
                end
            else
                vim.print(code)
            end
        end
    })

    job:start()
end

return M
