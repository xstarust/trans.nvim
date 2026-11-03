---@class TransCurl
local M = {}

---@class RequestResult
---@field body string
---@field exit integer
---@field error string

---@class TransCurlOptions
---@field query? table<string, string>
---@field body? string
---@field headers? table<string, string>
---@field timeout? integer
---@field callback fun(result: RequestResult)

---@param method 'GET' | 'POST'
---@param uri string
---@param opts TransCurlOptions
local function request(method, uri, opts)
    local cmd = { 'curl', '-sS', '-X', method, '-m', tostring(opts.timeout or 30) }

    for key, value in pairs(opts.headers or {}) do
        vim.list_extend(cmd, { '-H', ('%s: %s'):format(key, value) })
    end

    if method == 'GET' then
        vim.list_extend(cmd, { '-G' })
        for key, value in pairs(opts.query or {}) do
            vim.list_extend(cmd, { '--data-urlencode', ('%s=%s'):format(key, value) })
        end
    else
        vim.list_extend(cmd, { '--data-binary', opts.body or '' })
    end

    vim.list_extend(cmd, { uri })

    vim.system(cmd, { text = true }, function(obj)
        opts.callback({
            body = obj.stdout or '',
            exit = obj.code,
            error = obj.stderr or '',
        })
    end)
end

---@param uri string
---@param opts TransCurlOptions
function M.get(uri, opts)
    request('GET', uri, opts)
end

---@param uri string
---@param opts TransCurlOptions
function M.post(uri, opts)
    request('POST', uri, opts)
end

return M
