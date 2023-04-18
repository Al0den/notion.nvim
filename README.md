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
    autoUpdate = true, --Allow the plugin to automatically update 
    updateDelay = 60000, --Delay between updates, only useful if autoUpdate true
    open = "notion", --If not set, or set to something different to notion, will open in  web browser
    keys = { --Menu keys
        deleteKey = "d", 
        editKey = "e",
        openNotion = "o",
        itemAdd = "a"
    },
    notifications = true --Enable notifications
}
```
It can of course be overwritten. If you want to manually handle data update, `:NotionUpdate` or `require"notion".update({})`. Those commands aren't meant to return anything apart errors, you'll need to call `require"notion".raw()` to get the new data, after it has been updated (asynchronous)

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
require"notion.components".nextEventShortDate() --Matches by day to adapt string making it shorter, used in `nextEvent()`

--Display all events menu
require"notion".openMenu()
```

Inside the `menu`, different functions are accesible through the default keys. As of right now, editKey will open, if possible, a markdown file containing all the data of the event/page. As of right now, saving the file doesnt push to the API, but this is a work in progress.

In it's current state, two things can happen when calling the editKey:
- Hovering a database entry, will create the file instantaneously
- Hovering a page, will take a bit of time to fetch the different page blocks

Currently not caching or auto-updating page childrens as to not overwhelm the API, as a new API call would anyways be needed on key press to get the latest information

Pressing deleteKey when hovering over an event will delete an item from Notion. Note that once deleted, it will try to update the saved data straight away, but re-opening the menu fast may still show the event

## Roadmap

- Add addItem key
- Add support for updating notion pages / database entries
- Add reminder notifications
- Add support for nvim-notify (Not in the near future)
- Improve deleting as to force deleting in saved data rather than force api update (Not in the near future)
