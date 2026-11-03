local M = {
    name = 'youdao',
    name_zh = '有道',
    method = 'get',
    uri = 'https://openapi.youdao.com/api',
}

local ERRORS = {
    ['103'] = '翻译文本过长',
    ['108'] = '应用 ID 无效',
    ['110'] = '应用未绑定文本翻译服务',
    ['202'] = '签名检验失败，请检查应用密钥',
    ['205'] = '应用接入方式不是 API',
    ['401'] = '账户欠费',
    ['411'] = '访问频率受限',
    ['412'] = '长请求过于频繁',
}

---@return boolean
function M.is_configured()
    return M.app_id ~= nil and M.app_id ~= '' and M.app_passwd ~= nil and M.app_passwd ~= ''
end

---@param data TransData
---@return table<string, string>?
function M.get_query(data)
    if not M.is_configured() then
        vim.notify(
            '有道翻译未配置 app_id/app_passwd（opts.backends.youdao 或环境变量）',
            vim.log.levels.WARN
        )
        return nil
    end

    local salt = tostring(math.random(10000, 99999))
    local curtime = tostring(os.time())
    local chars = vim.str_utf_pos(data.str)
    local count = #chars
    local input = count <= 20 and data.str or data.str:sub(1, chars[11] - 1) .. count .. data.str:sub(chars[count - 9])
    local sign = vim.fn.sha256(M.app_id .. input .. salt .. curtime .. M.app_passwd)

    return {
        q = data.str,
        from = 'auto',
        to = data.from == 'zh' and 'en' or 'zh-CHS',
        appKey = M.app_id,
        salt = salt,
        curtime = curtime,
        signType = 'v3',
        sign = sign,
    }
end

---@param body table
---@param data TransData
---@return TransResult|false
function M.formatter(body, data)
    if body.errorCode ~= '0' then
        local code = tostring(body.errorCode)
        vim.notify('有道翻译失败: ' .. (ERRORS[code] or code), vim.log.levels.WARN)
        return false
    end

    local text = body.translation and body.translation[1]
    if type(text) ~= 'string' or text == '' then
        return false
    end

    return {
        str = data.str,
        [data.from == 'en' and 'translation' or 'definition'] = { text },
    }
end

return M
