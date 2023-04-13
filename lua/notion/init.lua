local M = {}

local initialized = false

local defaults = require "notion.defaults"
local req = require "notion.request"

local function checkInit()
    if not initialized then
        return vim.print("[Notion] Not initialised, please run :NotionSetup")
    end
end

--Save status for next neovim log in
local prevStatus = function()
    local path = vim.fn.stdpath("data") .. "/notion/prev.txt"
    local file = io.open(path, "r")
    if file == nil then return false end
    local l = file:read("*a")

    if l == "true" then
        initialized = true
    end
end

--Returns the raw output of the api, as a string
M.raw = function()
    local path = vim.fn.stdpath("data") .. "/notion/saved.txt"
    local file = io.open(path, "r")
    if file == nil then return end
    local l = file:read("*a")
    file:close()
    return l
end

--Updates the saved data
M.update = function(opts)
    opts = opts or { silent = false }
    if not initialized then
        return vim.print("[Notion] Not initialised, please run :NotionSetup")
    end
    local window = nil

    if opts.silent == false and M.opts.notification == true then
        window = require "notion.window".create("Updating")
    end

    local saveData = function(data)
        local path = vim.fn.stdpath("data") .. "/notion/saved.txt"
        local file = io.open(path, "w")
        if file == nil then return vim.print("[Notion] Incorrect Setup") end
        file:write(data)
        file:close()
    end

    req.request(function(data) saveData(data) end, window)

    local path = vim.fn.stdpath("data") .. "/notion/prev.txt"
    local file = io.open(path, "w")
    if file == nil then return false end
    file:write("true")
    file:close()
end

--Make sure all files are created (Probably a better way to do this?)
local function initialiseFiles()
    local path = vim.fn.stdpath("data") .. "/notion/"
    os.execute("mkdir -p " .. path)
    os.execute("touch " .. path .. "data.txt")
    os.execute("touch " .. path .. "prev.txt")
    os.execute("touch " .. path .. "saved.txt")
end

--Self explanatory
local function clearData()
    os.execute("rm -rf -d -R " .. vim.fn.stdpath("data") .. "/notion/")
    initialized = false
    initialiseFiles()
    vim.print("[Notion] Cleared all saved data")
end

--Initial function
M.setup = function(opts)
    initialiseFiles()
    M.opts = vim.tbl_deep_extend("force", defaults, opts or {})

    vim.api.nvim_create_user_command("NotionSetup", function() initialized = require("notion.setup").initialisation() end,
        {})
    vim.api.nvim_create_user_command("NotionUpdate", function() M.update() end, {})
    vim.api.nvim_create_user_command("Notion", function() require "notion.telescope".openFutureEventsMenu() end, {})
    vim.api.nvim_create_user_command("NotionClear", function() clearData() end, {})

    prevStatus()
    if not initialized then return end

    if M.opts.autoUpdate then
        M.update({ silent = true })
        vim.fn.timer_start(M.opts.updateDelay, function() M.update({ silent = true }) end, { ["repeat"] = -1 })
    end
end

return M
