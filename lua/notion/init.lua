local M = {}
local initialized = false

local defaults = require "notion.defaults"
local parser = require "notion.parse"
local req = require "notion.request"
local telescope = require "notion.telescope"
local components = require "notion.components"

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
    local path = vim.fn.stdpath("data") .. "/notion/"
    os.execute("mkdir -p " .. path)
    path = path .. "saved.txt"
    os.execute("touch " .. path)
    local file = io.open(path, "w")
    if file == nil then return end
    file:write(data)
    file:close()
end

M.raw = function()
    local path = vim.fn.stdpath("data") .. "/notion/"
    os.execute("mkdir -p " .. path)
    path = path .. "saved.txt"
    os.execute("touch " .. path)
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
    req.aReq(function(data) saveData(data) end)
end

local cycle = function()
    vim.fn.timer_start(M.opts.updateDelay, function() M.update() end, { ["repeat"] = -1 })
end

M.setup = function(opts)
    M.opts = vim.tbl_deep_extend("force", defaults, opts or {})
    vim.api.nvim_create_user_command("NotionSetup", function() initialized = require("notion.setup").initialisation() end,
        {})
    vim.api.nvim_create_user_command("NotionUpdate", function() M.update() end, {})
    vim.api.nvim_create_user_command("NotionMenu", function() telescope.openMenu() end, {})
    prevStatus()
    if not initialized then return end
    M.update()
    if M.opts.autoUpdate then cycle() end
end

return M
