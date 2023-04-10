local storage = vim.fn.stdpath("data") .. "/notion-nvim/data.txt"
local Job = require('plenary.job')

local M = {}

M.aReq = function(callback)
    local file = io.open(storage, "r")
    if file == nil then
        print(storage)
        vim.print("[Notion] Error")
        return false
    end

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
                print("err")
            end
        end,
    })

    job:start()
end

return M
