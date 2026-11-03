local Trans = require 'Trans'

---@class TransBackends
---@field get fun(name: string): TransBackend

return setmetatable({}, {
    __index = function(self, name)
        ---@type TransBackend
        local backend = require('Trans.backend.' .. name)
        for key, value in pairs((Trans.conf.backends or {})[name] or {}) do
            backend[key] = value
        end
        self[name] = backend
        return backend
    end,
})
