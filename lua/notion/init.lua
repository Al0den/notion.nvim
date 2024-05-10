local M = {}

local defaults = require "notion.defaults"
local req = require "notion.request"

local initialized = false

--Previous update time
M.lastUpdate = os.time()

--Read specific file
M.readFile = function(filename)
    local f = assert(io.open(filename, "r"))
    local content = f:read("*a")
    f:close()
    return content
end

--Force write in specified file path
M.writeFile = function(filename, content)
    local f = assert(io.open(filename, "w"))
    f:write(content)
    f:close()
    return content
end

--Access init status from other files
M.checkInit = function()
    if not initialized then
        vim.print("[Notion] Not initialised, please run :NotionSetup")
        return false
    end
    return true
end

--Save status for next neovim login
local prevStatus = function()
    if M.readFile(vim.fn.stdpath("data") .. "/notion/prev.txt") == "true" then
        initialized = true
    end
end

--Returns the raw output of the api, as a string
M.raw = function()
    if not M.checkInit() then return end
    return M.readFile(vim.fn.stdpath("data") .. "/notion/saved.txt")
end

--Updates the saved data
M.update = function(opts)
    opts = opts or {}
    opts.silent = opts.silent or false
    opts.window = opts.window or nil

    if not M.checkInit() then return end
    M.lastUpdate = os.time()

    local window = nil

    if not opts.silent and M.opts.notification then
        window = require "notion.window".create("Updating")
    end

    if opts.window then
        window = opts.window
    end

    local saveData = function(data)
        M.writeFile(vim.fn.stdpath("data") .. "/notion/saved.txt", data) --Save data
    end

    req.request(function(data) saveData(data) end, window)

    M.writeFile(vim.fn.stdpath("data") .. "prev.txt", "true") --Save status
end

--Make sure all files are created (Probably a better way to do this?)
local function initialiseFiles()
    local path = vim.fn.stdpath("data") .. "/notion/"
    os.execute("mkdir -p " .. path)
    os.execute("touch " .. path .. "data.txt")
    os.execute("touch " .. path .. "prev.txt")
    os.execute("touch " .. path .. "saved.txt")
    os.execute("touch " .. path .. "temp.md")
    os.execute("touch " .. path .. "tempData.txt")
    os.execute("touch " .. path .. "tempJson.json")
    os.execute("touch " .. path .. "reminders.txt")
    os.execute("touch " .. path .. "currentJob.txt")
    os.execute("touch " .. path .. "prev.txt")
    os.execute("mkdir -p " .. path .. "data/")
end

M.fileInit = initialiseFiles

--Self explanatory
local function clearData()
    if not M.checkInit() then return end

    os.execute("rm -rf -d -R " .. vim.fn.stdpath("data") .. "/notion/")
    initialized = false
    initialiseFiles()
    vim.print("[Notion] Cleared all saved data")
end

--Run timer checks
local function checkReminders()
    local reminders = M.readFile(vim.fn.stdpath("data") .. "/notion/reminders.txt")
    local lines = vim.split(reminders, "\n")
    local final = {}
    for _, k in ipairs(lines) do
        if k == "" or k == " " then break end
        local data = vim.split(k, " ")
        local Y, Mo, D, H, min = data[1]:match("(%d+)%-(%d+)%-(%d+)T(%d+):(%d+)")
        local difference = os.difftime(os.time({ year = Y, month = Mo, day = D, hour = H, min = min }), os.time())
        if difference < 60 then
            data[1] = ""
            local name = table.concat(data, " ")
            local win = require "notion.window".createBig("Reminder for: " .. name)
            vim.defer_fn(function() require "notion.window".close(win) end, 5000)
        else
            table.insert(final, k)
        end
    end
    require "notion".writeFile(vim.fn.stdpath("data") .. "/notion/reminders.txt", table.concat(final, "\n"))
end

local function notion(args)
    if args.args == "" then 
        require "notion.telescope".openMenu()
    elseif args.args == "clear" then
        clearData()
    elseif args.args == "update" then
        M.update()
    elseif args.args == "setup" then
        initialized = require "notion.setup".initialisation()
    elseif args.args == "menu" then
        require "notion.telescope".openMenu()
    elseif args.args == "status" then
        require "notion".status()
    end
end

--Initial function
M.setup = function(opts)
    initialiseFiles()
    M.opts = vim.tbl_deep_extend("force", defaults, opts or {})
    vim.api.nvim_create_user_command("Notion", notion, {
        nargs = '?',
        complete = function(ArgLead, CmdLine, CursorPos)
            local function levenshtein(str1, str2)
                local matrix = {}

                for i = 0, #str1 do
                    matrix[i] = { [0] = i }
                end
                for j = 0, #str2 do
                    matrix[0][j] = j
                end

                for i = 1, #str1 do
                    for j = 1, #str2 do
                        local cost = (str1:sub(i, i) == str2:sub(j, j) and 0 or 1)
                        matrix[i][j] = math.min(matrix[i - 1][j] + 1, matrix[i][j - 1] + 1, matrix[i - 1][j - 1] + cost)
                    end
                end

                return matrix[#str1][#str2]
            end

            local function closest_match(target, strings)
                local closest, distance = nil, math.huge

                for _, str in pairs(strings) do
                    local d = levenshtein(target, str)
                    if d < distance then
                        closest, distance = str, d
                    end
                end
                return closest
            end

            if ArgLead == "" or ArgLead == nil or ArgLead == " " then
                return { "clear", "update", "setup", "menu", "status" }
            else
                return { closest_match(ArgLead, { "clear", "update", "setup", "menu", "status" }) }
            end
        end
    })
    prevStatus()
    if not initialized then return end

    if M.opts.autoUpdate then
        M.update({ silent = true })
        vim.fn.timer_start(M.opts.delays.update, function() M.update({ silent = true, window = nil }) end,
            { ["repeat"] = -1 })
        vim.fn.timer_start(M.opts.delays.reminder, function() checkReminders() end, { ["repeat"] = -1 })
    end
end

--Give updates about current status
M.status = function()
    if not M.checkInit() then return end

    local str = "[Notion] Last Update: " .. os.difftime(os.time(), M.lastUpdate) .. " seconds ago"
    local currentJob = M.readFile(vim.fn.stdpath("data") .. "/notion/currentJob.txt")
    str = str .. currentJob
    vim.print(str)
end

return M
