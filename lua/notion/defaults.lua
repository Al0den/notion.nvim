local M = {}

M.autoUpdate = true
M.open = "notion"
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
    format = 300,
    update = 10000
}
M.notification = true
M.editor = "light"
M.viewOnEdit = {
    enabled = true,
    replace = true
}
M.direction = "vsplit"

return M
