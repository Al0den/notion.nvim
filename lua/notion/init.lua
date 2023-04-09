local M = {}

local defaults = require "notion.defaults"
local parser = require "notion.parse"

local initialized = false

local req = require "notion.request"

M.latest = ""

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

M.raw = function()
    return latest
end

M.update = function(opts)
    if not initialized then
        return vim.print("[Notion] Not initialised, please run :NotionSetup")
    end
    req.aReq(function(data) latest = data end)
end

local cycle = function()
    vim.fn.timer_start(M.opts.updateDelay, function() M.update() end, { ["repeat"] = -1 })
end

M.setup = function(opts)
    M.opts = vim.tbl_deep_extend("force", defaults, opts or {})
    vim.api.nvim_create_user_command("NotionSetup", function() initialized = require("notion.setup").initialisation() end,
        {})
    vim.api.nvim_create_user_command("NotionUpdate", function() M.update() end, {})
    prevStatus()
    if not initialized then return end
    M.update()
    if M.opts.autoUpdate then cycle() end
end

M.taste = function()
    vim.print(components.earliestDate())
end

return M
