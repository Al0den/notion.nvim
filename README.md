# notion.nvim

[Neovim](https://neovim.io) wrapper for the notion api

## Installation and setup

Any plugin manager should do the trick. Calling the setup function is required if you want to access the plugin

[**packer.nvim**](https://github.com/wbthomason/packer.nvim)
```lua
use {
    "Al0den/notion.nvim",
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

## Customisation

Available lua functions are, as of right now:

```lua
--Get raw output from the api, as a string
require"notion".raw()

--Get next event name
require"notion".nextEventName()

--Get next event date
require"notion".nextEventDate()
```

## Roadmap

- Extend available functions list
- Create menu with all future events
- Add events/reminder creation feature
