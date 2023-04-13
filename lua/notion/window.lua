local M = {}

M.create = function(content)
    local bufnr = vim.api.nvim_create_buf(false, true)
    local width = 20
    local height = 2

    local config = {
        relative = 'editor',
        row = 1,
        col = 162,
        width = width,
        height = 1,
        noautocmd = true,
        border = "rounded",
        focusable = false,
        style = "minimal"
    }

    if vim.fn.has('nvim-0.9.0') == 1 then
        config.title = "Notion"
    end

    local winid = vim.api.nvim_open_win(bufnr, false, config)

    vim.api.nvim_buf_set_lines(
        bufnr,
        vim.fn.round(height / 2) - 1,
        vim.fn.round(height / 2),
        false,
        { string.rep(" ", (width - string.len(content)) / 2) .. content }
    )

    return winid
end

M.close = function(winid)
    vim.api.nvim_win_close(winid, true)
end


return M
