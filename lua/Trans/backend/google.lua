local M = {
    name = 'google',
    name_zh = 'Google',
    method = 'post',
    uri = 'https://translation.googleapis.com/language/translate/v2',
}

local ENTITIES = {
    quot = '"',
    amp = '&',
    lt = '<',
    gt = '>',
    apos = "'",
    ['#39'] = "'",
    ['#34'] = '"',
}

local function decode_entities(text)
    return (text:gsub('&([#%w]+);', function(code)
        return ENTITIES[code] or ('&' .. code .. ';')
    end))
end

---@return boolean
function M.is_configured()
    return M.api_key ~= nil and M.api_key ~= ''
end

---@return string
function M.get_uri()
    local sep = M.uri:find('?', 1, true) and '&' or '?'
    return M.uri .. sep .. 'key=' .. M.api_key
end

---@return table<string, string>
function M.header()
    return { ['Content-Type'] = 'application/json' }
end

---@param data TransData
---@return string
function M.get_query(data)
    return vim.json.encode({
        q = data.str,
        target = data.from == 'en' and 'zh-CN' or 'en',
        format = 'text',
    })
end

---@param body table
---@param data TransData
---@return TransResult|false
function M.formatter(body, data)
    if body.error then
        vim.notify('Google 翻译失败: ' .. tostring(body.error.message), vim.log.levels.WARN)
        return false
    end

    local translation = body.data and body.data.translations and body.data.translations[1]
    local text = translation and translation.translatedText
    if type(text) ~= 'string' or text == '' then
        return false
    end

    return {
        str = data.str,
        [data.from == 'en' and 'translation' or 'definition'] = { decode_entities(text) },
    }
end

return M
