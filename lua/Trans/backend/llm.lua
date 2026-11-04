local M = {
    name = 'llm',
    name_zh = 'LLM',
    method = 'post',
}

local function first_nonempty(...)
    for i = 1, select('#', ...) do
        local value = select(i, ...)
        if type(value) == 'string' and value ~= '' then
            return value
        end
    end
end

local function resolve()
    return {
        api_key = first_nonempty(M.api_key, vim.env.OPENAI_API_KEY),
        base_url = first_nonempty(M.base_url, vim.env.OPENAI_BASE_URL) or 'https://api.openai.com/v1',
        model = first_nonempty(M.model, vim.env.OPENAI_MODEL) or 'gpt-4o-mini',
        temperature = M.temperature or 0.2,
    }
end

local function endpoint(base_url)
    local url = base_url:gsub('/+$', '')
    if url:match '/chat/completions$' then
        return url
    end

    return url .. '/chat/completions'
end

setmetatable(M, {
    __index = function(_, key)
        if key ~= 'uri' then
            return
        end

        return endpoint(resolve().base_url)
    end,
})

---@return boolean
function M.is_configured()
    return resolve().api_key ~= nil
end

---@param data TransData
---@return string?
function M.get_query(data)
    local conf = resolve()
    if not conf.api_key then
        vim.notify('LLM 翻译未配置 api_key（opts.backends.llm 或环境变量）', vim.log.levels.WARN)
        return nil
    end

    local target = data.from == 'en' and 'Simplified Chinese' or 'English'
    return vim.json.encode {
        model = conf.model,
        temperature = conf.temperature,
        stream = false,
        messages = {
            {
                role = 'system',
                content = "You are a translation engine. Translate the user's text into "
                    .. target
                    .. '. Return only the translation, without quotes, explanations, or markdown.',
            },
            { role = 'user', content = data.str },
        },
    }
end

---@return table<string, string>
function M.header()
    return {
        Authorization = 'Bearer ' .. (resolve().api_key or ''),
        ['Content-Type'] = 'application/json',
    }
end

---@param body table
---@param data TransData
---@return TransResult|false
function M.formatter(body, data)
    local choice = body.choices and body.choices[1]
    local content = choice and choice.message and choice.message.content
    if type(content) ~= 'string' or content == '' then
        local message = body.error and body.error.message
        if type(message) == 'string' and message ~= '' then
            vim.notify('LLM 翻译失败: ' .. message, vim.log.levels.WARN)
        end
        return false
    end

    local text = vim.trim(content)
    text = text:match '^"(.*)"$' or text

    return {
        str = data.str,
        [data.from == 'en' and 'translation' or 'definition'] = { text },
    }
end

return M
