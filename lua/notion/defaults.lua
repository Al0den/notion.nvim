local M = {}

M.autoUpdate = true
M.open = "browser"
M.keys = {
    deleteKey = "d",
    openNotion = "o",
    editKey = "e",
    itemAdd = "a",
    viewKey = "v",
    remindKey = "r"
}
M.delays = {
    reminder = 4000,
    format = 500,
    update = 10000
}
M.notification = true
M.editor = "light"
M.viewOnEdit = {
    enabled = false,
    replace = false
}
M.direction = "vsplit"
M.noEvent = "No Events"
M.debug = false

return M
