# notion.nvim

Access your neovim events from inside of neovim, and access the wrapper behind it

## Installation and setup

Any plugin manager should do the trick. Calling the setup function is required if you want to access the plugin

Note: Telescope (And as such, plenary.nvim) are required respectively to open the menu and make API calls

[**packer.nvim**](https://github.com/wbthomason/packer.nvim)
```lua
use {
    "Al0den/notion.nvim",
    requires = { 'nvim-telescope/telescope.nvim'},
    config = function()
        require"notion".setup()
    end
}
```

[**vim-plug**](https://github.com/junegunn)
```lua
Plug 'Al0den/tester.nvim'

lua << END
require('tester').setup()
END
```

## How to use

By default, the plugin simply wont do anything. Call the `:NotionSetup` function to initialise the plugin and enable it's features. 

The simplest of use is the `Notion` (`require"notion".openMenu()`), which opens a menu will all upcomings events. However, a lot of functions are exposed through the `notions.components` file.

```lua
-- keymaps.lua
vim.keymaps.set("n", "<leader>no", function () require"notion".openMenu() end)
```

As an example, to insert the next event inside your lualine something, you could do something such as:

```lua
--lualine.lua

require'lualine'.setup {
    ...
    sections = {
        lualine_a = { 'mode' },
        lualine_b = { 'branch', 'diff', 'diagnostics' },
        lualine_c = { 'require"notion.components".nextEvent()' },
        lualine_x = { 'encoding', 'fileformat', 'filetype' },
        lualine_y = { 'progress' },
        lualine_z = { 'location' }
    },  
    ...
}
```
## Defaults

The default configuration is:

```lua
require"notion".setup {
    autoUpdate = true,
    updateDelay = 60000,
    open = "notion",
    keys = {
        deleteKey = "d",
        editKey = "e",
        openNotion = "o"
    },
    notifications = false -- Would recommend using that, spits out errors right now
}
```

It can of course be overwritten. If you want to manually handle data update, `:NotionUpdate` or `require"notion".update()`. Those commands aren't meant to return anything apart errors, you'll need to call `require"notion".raw()` to get the new data, after it has been updated (asynchronous)

## Customisation

Available lua functions are, as of right now:

```lua
--Get raw output from the api, as a string
require"notion".raw()

--Get formatted earliest event
require"notion.components".nextEvent()

--Get next event name
require"notion.components".nextEventName()

--Get next event date
require"notion.components".nextEventDate() --In its full format
require"notion.components".nextEventShortDate() --Matches by day to adapt displaystyle, used in `nextEvent()`

--Display all future events menu
require"notion".openFutureEventsMenu()
```

## Roadmap

- Extend available functions list
- Add reminder notifications
- Add events/reminder creation feature
- Improve deleting as to force deleting in saved data rather than force update (Not in the near future)
- Add creation/modification capabilities (Useless?)
