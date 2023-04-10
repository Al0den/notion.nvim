local M = {}
local initialized = false

local defaults = require "notion.defaults"
local req = require "notion.request"

local prevStatus = function()
    local path = vim.fn.stdpath("data") .. "/notion-nvim/prev.txt"
    local file = io.open(path, "r")
    if file == nil then return false end
    local l = file:read("*a")

    if l == "true" then
        initialized = true
    end
end

local saveData = function(data)
    local path = vim.fn.stdpath("data") .. "/notion/saved.txt"
    local file = io.open(path, "w")
    if file == nil then return end
    file:write(data)
    file:close()
end

M.raw = function()
    local path = vim.fn.stdpath("data") .. "/notion/saved.txt"
    local file = io.open(path, "r")
    if file == nil then return end
    local l = file:read("*a")
    file:close()
    return l
end

M.update = function()
    if not initialized then
        return vim.print("[Notion] Not initialised, please run :NotionSetup")
    end
    req.request(function(data) saveData(data) end)
end
local function initialiseFiles()
    local path = vim.fn.stdpath("data") .. "/notion/"
    os.execute("mkdir -p " .. path)
    os.execute("touch " .. path .. "data.txt")
    os.execute("touch " .. path .. "prev.txt")
    os.execute("touch " .. path .. "saved.txt")
end

local function clearData()
    os.execute("rm -rf -d -R " .. vim.fn.stdpath("data") .. "/notion/")
    vim.print("[Notion] Cleared all saved data")
end

M.setup = function(opts)
    initialiseFiles()
    M.opts = vim.tbl_deep_extend("force", defaults, opts or {})
    vim.api.nvim_create_user_command("NotionSetup", function() initialized = require("notion.setup").initialisation() end,
        {})
    vim.api.nvim_create_user_command("NotionUpdate", function() M.update() end, {})
    vim.api.nvim_create_user_command("NotionMenu", function() require "notion.telescope".openFutureEventsMenu() end, {})
    vim.api.nvim_create_user_command("NotionClear", function() clearData() end)
    prevStatus()

    if not initialized then return end

    if M.opts.autoUpdate then
        M.update()
        vim.fn.timer_start(M.opts.updateDelay, function() M.update() end, { ["repeat"] = -1 })
    end
end

return M
