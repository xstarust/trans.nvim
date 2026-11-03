local M = {
    name = 'sdcv',
    name_zh = 'sdcv',
}

local warned = false

local function collect_lines(definition, seen)
    local lines = {}
    local pending

    for line in definition:gmatch '[^\n]+' do
        line = vim.trim(line)
        if line ~= '' and not line:match '^%*?%[[^%]]+%]$' then
            if line:match '^%a+%.$' then
                pending = line
            else
                local merged = pending and (pending .. ' ' .. line) or line
                pending = nil
                if not seen[merged] then
                    seen[merged] = true
                    lines[#lines + 1] = merged
                end
            end
        end
    end

    if pending and not seen[pending] then
        seen[pending] = true
        lines[#lines + 1] = pending
    end

    return lines
end

local function stems(word)
    local list = {}

    local function add(candidate)
        if #candidate >= 2 and candidate ~= word then
            list[#list + 1] = candidate
        end
    end

    local tail3 = word:sub(-3)
    if tail3 == 'ies' or tail3 == 'ied' then
        add(word:sub(1, -4) .. 'y')
    end

    if word:sub(-1) == 's' and word:sub(-2) ~= 'ss' then
        add(word:sub(1, -2))
    end

    if word:sub(-2) == 'es' then
        add(word:sub(1, -3))
    end

    if word:sub(-2) == 'ed' then
        local base = word:sub(1, -3)
        add(base)
        add(base .. 'e')
        if #base >= 2 and base:sub(-1) == base:sub(-2) then
            add(base:sub(1, -2))
        end
    end

    if tail3 == 'ing' then
        local base = word:sub(1, -4)
        add(base)
        add(base .. 'e')
        if #base >= 2 and base:sub(-1) == base:sub(-2) then
            add(base:sub(1, -2))
        end
    end

    if word:sub(-2) == 'ly' then
        add(word:sub(1, -3))
    end

    return list
end

---@param word string
---@return string[]
local function candidates(word)
    local list, seen = {}, {}

    local function push(candidate)
        if candidate ~= '' and not seen[candidate] then
            seen[candidate] = true
            list[#list + 1] = candidate
        end
    end

    local lower = word:lower()
    push(word)
    push(lower)
    for _, stem in ipairs(stems(lower)) do
        push(stem)
    end

    return list
end

local function lookup(cmd, word)
    local argv = vim.list_extend(vim.deepcopy(cmd), { word })
    local output = vim.fn.system(argv)
    if vim.v.shell_error ~= 0 then
        return nil
    end

    local ok, entries = pcall(vim.json.decode, output)
    if not ok or type(entries) ~= 'table' or #entries == 0 then
        return nil
    end

    return entries
end

---@param cmd string[]
---@param word string
---@param tries string[]
---@return table[]?
local function fuzzy_entries(cmd, word, tries)
    local fuzzy_cmd = {}
    for _, arg in ipairs(cmd) do
        if arg ~= '-e' and arg ~= '--exact-search' then
            fuzzy_cmd[#fuzzy_cmd + 1] = arg
        end
    end

    local entries = lookup(fuzzy_cmd, word)
    if not entries then
        return nil
    end

    local wanted = {}
    for _, candidate in ipairs(tries) do
        wanted[(candidate:lower():gsub('%s+', ''))] = true
    end

    local matched = {}
    for _, entry in ipairs(entries) do
        local key = ((entry.word or ''):lower():gsub('%s+', ''))
        if wanted[key] then
            matched[#matched + 1] = entry
        end
    end

    return #matched > 0 and matched or nil
end

---@return boolean
function M.is_configured()
    return vim.fn.executable(M.cmd or 'sdcv') == 1
end

---@param data TransData
function M.query(data)
    if not M.is_configured() then
        if not warned then
            vim.notify('sdcv 未安装，无法使用本地词典', vim.log.levels.WARN)
            warned = true
        end
        data.result.offline = false
        return
    end

    local cmd = { M.cmd or 'sdcv' }
    vim.list_extend(cmd, M.args or { '-n', '-j', '-0', '-1', '-e' })
    if M.data_dir then
        vim.list_extend(cmd, { '-2', M.data_dir, '-x' })
    end

    local tries = candidates(data.str)
    local entries
    for _, candidate in ipairs(tries) do
        entries = lookup(cmd, candidate)
        if entries then
            break
        end
    end

    if not entries then
        entries = fuzzy_entries(cmd, data.str, tries)
    end

    if not entries then
        data.result.offline = false
        return
    end

    local translation, phonetic, seen = {}, nil, {}
    for _, entry in ipairs(entries) do
        local definition = entry.definition or ''
        phonetic = phonetic or definition:match '%*?%[([^%]]+)%]'
        vim.list_extend(translation, collect_lines(definition, seen))
    end

    if #translation == 0 then
        data.result.offline = false
        return
    end

    data.result.offline = {
        title = { word = data.str, phonetic = phonetic },
        [data.from == 'zh' and 'definition' or 'translation'] = translation,
    }
end

return M
