local M = {
    name = 'mymemory',
    name_zh = 'MyMemory',
    method = 'get',
    uri = 'https://api.mymemory.translated.net/get',
}

---@return boolean
function M.is_configured()
    return true
end

---@param data TransData
---@return table<string, string>?
function M.get_query(data)
    if #data.str > 500 then
        vim.notify(
            'MyMemory 单次最多 500 字节（英文约 500 字符，中文约 160 字），请分段翻译',
            vim.log.levels.WARN
        )
        return nil
    end

    local query = {
        q = data.str,
        langpair = data.from == 'zh' and 'zh-CN|en' or 'en|zh-CN',
    }
    if M.email and M.email ~= '' then
        query.de = M.email
    end
    return query
end

---@param body table
---@param data TransData
---@return TransResult|false
function M.formatter(body, data)
    if tonumber(body.responseStatus) ~= 200 then
        local reason = body.responseDetails
        if type(reason) == 'string' and reason ~= '' then
            vim.notify('MyMemory 查询失败: ' .. reason, vim.log.levels.WARN)
        end
        return false
    end

    local text = body.responseData and body.responseData.translatedText
    if type(text) ~= 'string' or text == '' then
        return false
    end

    return {
        str = data.str,
        [data.from == 'en' and 'translation' or 'definition'] = { text },
    }
end

return M
