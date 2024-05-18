# notion.nvim

`notion.nvim` is a [Neovim](https://neovim.io) plugin made for accesing the [Notion](https://notion.so) API, formatting and ease of integration.

View, edit and update your notion pages and database entries from inside neovim, and access pre-coded functions

## Screenshots

### Menu
![image](https://user-images.githubusercontent.com/111601320/232697205-df41c239-bdd0-40e7-800c-3a9bb9f5bf06.jpeg)
### Markdown 
![image](https://user-images.githubusercontent.com/111601320/232716446-96a696b3-9df4-4b4f-848f-ee76c15af61b.jpeg)
### Database entry modification
![image](https://user-images.githubusercontent.com/111601320/233300186-a45a871e-bd5b-4757-9863-5d512858c373.jpeg)

## Installation and setup

Any plugin manager should do the trick. Calling the setup function is required if you want to access the plugin

Note: Telescope (And as such, plenary.nvim) are required respectively to open the menu and make API calls

[**packer.nvim**](https://github.com/wbthomason/packer.nvim)
```lua
use {
    "Al0den/notion.nvim",
    requires = { 'nvim-telescope/telescope.nvim', 'nvim-lua/plenary.nvim' },
    after = { 'nvim-lua/plenary.nvim' }
    config = function()
        require"notion".setup()
    end
}
```

[**vim-plug**](https://github.com/junegunn)
```lua
Plug 'Al0den/tester.nvim'

lua << END
require"notion".setup()
END
```

[**lazy**](https://github.com/folke/lazy.nvim)
```lua
{
    "Al0den/notion.nvim",
    lazy = false, --Should work when lazy loaded, not tested
    dependencies = {
      "nvim-telescope/telescope.nvim",
      "nvim-lua/plenary.nvim",
    },
    config = function()
        require"notion".setup()
    end,
},
```

## How to use

By default, the plugin simply wont do anything. Call the `:Notion setup` function to initialise the plugin and enable it's features. 

You will need your [Notion integration key](https://developers.notion.com), and have  the integration to access the specific pages/databases you want to display inside of Neovim.

The plugin can view and edit notion pages, and as such I would recommend to allow it to do both, however only allowing view shouldnt have an impact on features unrelated to editing

If your environment variable `NOTION_API_KEY` (`os.getenv("NOTION_API_KEY)`) is already set, simply running `:Notion setup` while initialise the plugin once and for all

The simplest of use is the `:Notion` command, (The call is: `require"notion".openMenu()`), which opens a menu will all upcomings events. However, a lot of functions are exposed through the `notions.components` file.

```lua
-- keymaps.lua
vim.keymaps.set("n", "<leader>no", function () require"notion".openMenu() end)
```

As an example, to insert the next event inside your lualine, you could do something such as:

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
    autoUpdate = true, --Allow the plugin to automatically update the data from the Notion API
    open = "notion", --If not set, or set to something different to notion, will open in web browser
    keys = { --Menu keys
        deleteKey = "d", 
        editKey = "e",
        openNotion = "o",
        itemAdd = "a",
        viewKey = "v"
    },
    delays = { --Delays before running specific actions
        reminder = 4000,
        format = 200,
        update = 10000
    },
    notifications = true, --Enable notifications
    editor = "light", --light/medium/full, changes the amount of data displayed in editor
    viewOnEdit = {
        enabled = true, --Enable double window, view and edit simultaneously
        replace = true --Replace current window with preview window, only if enabled = true
    }
    direction = "vsplit", --Direction windows will be opened in
    noEvent = "No events"
}
```

Any options can be set/unset, and if not set will default to the above

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

Inside the `menu`, different functions are accesible through the default keys. As of right now, editKey will open, if possible, a json file containing all the data of the event/page (according to defaults editor preference). Saving said file will push to the API. Note that for pages, every single block is pushed indivudally, and due to API rate limits, only one per second is pushed. Feel free to do anything during this time and let the plugin do its update. If notifications are enabled, a small pop-up in the top right corner will indicated progress. Database entries are saved in one time

In it's current state, two things can happen when calling the viewKey or editKey:
- Hovering a database entry, will create the file instantaneously
- Hovering a page, will take a bit of time to fetch the different page blocks

Currently not caching or auto-updating page childrens as to not overwhelm the API, as a new API call would anyways be needed on key press to get the latest information

Pressing deleteKey when hovering over an event will attempt to delete block from notion, and instantly delete it from raw saved data on success

Pressing remindKey will allow you to set reminders that will send you a notification on the specified time. Works even if nvim is relaunched or closed
### Updates

If you want to manually update the data stored, you can use `require"notion".update` function, used as such:
```lua
require"notion".update({
    silent = false,
    window = nil
})
```
`silent` determines wether to show a notification or not. Does not override the default `notifications`, so if set to false, no window will be showed, otherwise depends on `notifications`

If you want to manually handle your notifications, `window` takes a window ID as an argument and will close said window when the action has completed

Note: `update` is asynchronous, and as such the data will be updated in the background, not instantaneously, and `menu` will update accordingly  

## Roadmap

- Add addItem key 
- Add support for nvim-notify (Not in the near future)

## Credits

- [impulse.nvim](https://github.com/chrsm/impulse.nvim), Similar results, but not maintained, buggy in certain aspects and impossible for me to recode due to yue/moonscript, thus cannot add edit support
- [plenary.nvim](https://github.com/nvim-lua/plenary.nvim), Use of jobs for asynchronous updates
- [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim), Use of pickers
