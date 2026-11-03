local Trans = require 'Trans'

local function define_highlights(conf)
    local set_hl = vim.api.nvim_set_hl
    local highlights = Trans.style.theme[conf.theme]
    for hl, opt in pairs(highlights) do
        set_hl(0, hl, opt)
    end
end

---@class Trans
---@field setup fun(opts: table?)
return function(opts)
    if opts then
        Trans.conf = vim.tbl_deep_extend('force', Trans.conf, opts)
    end
    define_highlights(Trans.conf)
end
