local Trans = require 'Trans'

---@class TransData
---@field from string @Source language type
---@field to string @Target language type
---@field is_word boolean @Is the str a word
---@field str string @The original string
---@field query_str string @The string sent to providers (identifiers split into words)
---@field mode string @The mode of the str
---@field result table<string, TransResult|nil|false> @The result of the translation
---@field frontend TransFrontend
---@field trace table<string, string> debug message
---@field backends table<string, TransBackend>
local M = {}
M.__index = M

---TransData constructor
---@param opts table
---@return TransData
function M.new(opts)
    local mode = opts.mode
    local str = opts.str

    local strategy = Trans.conf.strategy.default
    local data = setmetatable({
        str = str,
        query_str = Trans.util.normalize_identifier(str),
        mode = mode,
        result = {},
        trace = {},
    }, M)

    data.frontend = Trans.frontend[strategy.frontend].new()
    data.backends = {}
    for _, name in ipairs(Trans.conf.order or {}) do
        if name ~= Trans.conf.offline then
            local backend = Trans.backend[name]
            if not backend.is_configured or backend.is_configured() then
                data.backends[#data.backends + 1] = backend
            end
        end
    end

    if Trans.util.is_english(str) then
        data.from = 'en'
        data.to = 'zh'
    else
        data.from = 'zh'
        data.to = 'en'
    end

    data.is_word = Trans.util.is_word(str)

    return data
end

---@class TransResult
---@field str? string? @The original string
---@field title table | string @table: {word, phonetic, oxford, collins}
---@field tag string[]? @array of tags
---@field pos table<string, string>? @table: {name, value}
---@field exchange table<string, string>? @table: {name, value}
---@field definition? string[]? @array of definitions
---@field translation? string[]? @array of translations
---@field web? table<string, string[]>[]? @web definitions
---@field explains? string[]? @basic explains

---Get the first available result [return nil if no result]
---@return TransResult | false?
---@return string? backend.name
function M:get_available_result()
    local result = self.result

    if result['offline'] then
        return result['offline'], 'offline'
    end

    for _, backend in ipairs(self.backends) do
        if result[backend.name] then
            ---@diagnostic disable-next-line: return-type-mismatch
            return result[backend.name], backend.name
        end
    end
end

---@class Trans
---@field data TransData
return M
