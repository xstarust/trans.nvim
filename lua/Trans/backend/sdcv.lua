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
    cmd[#cmd + 1] = data.str

    local output = vim.fn.system(cmd)
    if vim.v.shell_error ~= 0 then
        data.result.offline = false
        return
    end

    local ok, entries = pcall(vim.json.decode, output)
    if not ok or type(entries) ~= 'table' or #entries == 0 then
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
