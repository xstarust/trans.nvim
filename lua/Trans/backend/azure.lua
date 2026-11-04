local M = {
    name = 'azure',
    name_zh = 'Azure',
    method = 'post',
    endpoint = 'https://api.cognitive.microsofttranslator.com',
}

---@return boolean
function M.is_configured()
    return M.api_key ~= nil and M.api_key ~= ''
end

---@param data TransData
---@return string
function M.get_uri(data)
    local target = data.from == 'en' and 'zh-Hans' or 'en'
    return M.endpoint:gsub('/+$', '') .. '/translate?api-version=3.0&to=' .. target
end

---@return table<string, string>
function M.header()
    local headers = {
        ['Ocp-Apim-Subscription-Key'] = M.api_key,
        ['Content-Type'] = 'application/json',
    }
    if M.region and M.region ~= '' then
        headers['Ocp-Apim-Subscription-Region'] = M.region
    end
    return headers
end

---@param data TransData
---@return string
function M.get_query(data)
    return vim.json.encode { { Text = data.str } }
end

---@param body table
---@param data TransData
---@return TransResult|false
function M.formatter(body, data)
    if body.error then
        vim.notify('Azure 翻译失败: ' .. tostring(body.error.message), vim.log.levels.WARN)
        return false
    end

    local first = body[1]
    local translation = first and first.translations and first.translations[1]
    local text = translation and translation.text
    if type(text) ~= 'string' or text == '' then
        return false
    end

    return {
        str = data.str,
        [data.from == 'en' and 'translation' or 'definition'] = { text },
    }
end

return M
