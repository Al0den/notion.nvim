return require("telescope").register_extension {
    setup = function(ext_config, config)
    end,
    exports = {
        notion = require("notion.telescope").openMenuTelescope
    },
}
