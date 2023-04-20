local M = {}

local initialized = false

local defaults = require "notion.defaults"
local req = require "notion.request"

M.readFile = function(filename)
    local f = assert(io.open(filename, "r"))
    local content = f:read("*a")
    f:close()
    return content
end

M.writeFile = function(filename, content)
    local f = assert(io.open(filename, "w"))
    f:write(content)
    f:close()
    return
end

--Access init status from other files
M.checkInit = function()
    if not initialized then
        vim.print("[Notion] Not initialised, please run :NotionSetup")
        return false
    end
    return true
end

--Save status for next neovim log in
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

    local window = nil

    if opts.silent == false and M.opts.notification == true then
        window = require "notion.window".create("Updating")
    end

    if opts.window ~= nil then
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
end

--Self explanatory
local function clearData()
    if not M.checkInit() then return end

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
    vim.api.nvim_create_user_command("Notion", function() require "notion.telescope".openMenu() end, {})
    vim.api.nvim_create_user_command("NotionClear", function() clearData() end, {})

    prevStatus()
    if not initialized then return end

    if M.opts.autoUpdate then
        M.update({ silent = true })
        vim.fn.timer_start(M.opts.updateDelay, function() M.update({ silent = true, window = nil }) end,
            { ["repeat"] = -1 })
    end
end

M.test = function()

end

return M
