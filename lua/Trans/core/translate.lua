local Trans = require 'Trans'
local util = Trans.util

local function init_opts(opts)
    opts = opts or {}
    opts.mode = opts.mode or vim.fn.mode()
    opts.str = util.get_str(opts.mode)
    return opts
end

---To Do Online Query
---@param data TransData @data
---@param backend TransOnlineBackend @backend
local function do_query(data, backend)
    local name = backend.name
    local method = backend.method
    local formatter = backend.formatter

    local query_data = vim.tbl_extend('force', data, { str = data.query_str })
    local q_ok, query = pcall(backend.get_query, query_data)
    if not q_ok or not query then
        data.result[name] = false
        return
    end

    local header
    if type(backend.header) == 'function' then
        local h_ok, h_res = pcall(backend.header, data)
        header = h_ok and h_res or nil
    elseif type(backend.header) == 'table' then
        header = backend.header
    end

    local uri = backend.get_uri and backend.get_uri(data) or backend.uri

    local function handle(output)
        if output.exit ~= 0 then
            vim.notify(('%s 请求失败: %s'):format(name, output.error), vim.log.levels.WARN)
        end

        local status, body = pcall(vim.json.decode, output.body)
        if not status or not body then
            if backend.debug then
                pcall(backend.debug, output.body)
            end
            data.trace[name] = output
            data.result[name] = false
            return
        end

        local f_ok, res = pcall(formatter, body, data)
        data.result[name] = f_ok and res or false
    end

    local c_ok = pcall(function()
        Trans.curl[method](uri, {
            query = method == 'get' and query or nil,
            body = method == 'post' and query or nil,
            headers = header,
            timeout = backend.timeout or 30,
            callback = handle,
        })
    end)

    if not c_ok then
        data.result[name] = false
    end
end

---@type table<string, fun(data: TransData):boolean>
local strategy = {
    fallback = function(data)
        local result = data.result
        local offline = Trans.conf.offline
        if offline then
            local backend = Trans.backend[offline]
            if backend and backend.query then
                backend.query(data)
                if result.offline then
                    return true
                end
            end
        end

        local update = data.frontend:wait()
        for _, backend in ipairs(data.backends) do
            do_query(data, backend)

            local name = backend.name
            ---@cast backend TransBackend
            while result[name] == nil and update(backend) do
            end

            if result[name] then
                return true
            end
        end

        return false
    end,
    --- TODO :More Strategys
}

-- HACK : Core process logic
local function process(opts)
    opts = init_opts(opts)
    local str = opts.str
    if not str or str == '' then
        return
    end

    -- Find in cache
    if Trans.cache[str] then
        local data = Trans.cache[str]
        data.frontend:process(data)
        return
    end

    local data = Trans.data.new(opts)
    if strategy[data.frontend.opts.query](data) then
        Trans.cache[data.str] = data
        data.frontend:process(data)
    else
        data.frontend:fallback()
    end
end

---@class Trans
---@field translate fun(opts: { frontend: string?, mode: string?}?) Translate string core function
return function(opts)
    coroutine.wrap(process)(opts)
end
