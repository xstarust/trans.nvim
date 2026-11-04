local Trans = require 'Trans'
local health = vim.health

local function check_sdcv()
    local cmd = (Trans.conf.backends.sdcv or {}).cmd or 'sdcv'
    if vim.fn.executable(cmd) == 0 then
        health.error(('sdcv executable [%s] not found'):format(cmd))
        return
    end
    health.ok(('sdcv executable [%s] found'):format(cmd))

    local output = vim.fn.system { cmd, '-l' }
    if vim.v.shell_error == 0 and output ~= '' then
        health.ok('Dictionaries:\n' .. output)
    else
        health.warn 'No StarDict dictionaries found; add them to ~/.stardict/dic'
    end
end

local function check_curl()
    if vim.fn.executable 'curl' == 1 then
        health.ok 'curl found'
    else
        health.error 'curl not found'
    end
end

local function check_providers()
    local checks = {
        { name = 'llm', fields = { 'api_key' } },
        { name = 'google', fields = { 'api_key' } },
        { name = 'azure', fields = { 'api_key' } },
        { name = 'youdao', fields = { 'app_id', 'app_passwd' } },
    }

    for _, spec in ipairs(checks) do
        local conf = (Trans.conf.backends or {})[spec.name] or {}
        local configured = true
        for _, field in ipairs(spec.fields) do
            local value = conf[field]
            if value == nil or value == '' then
                configured = false
            end
        end

        if configured then
            health.ok(('%s configured'):format(spec.name))
        else
            health.info(('%s not configured'):format(spec.name))
        end
    end

    health.ok 'mymemory enabled'
end

local function check()
    health.start 'trans.nvim'
    check_sdcv()
    check_curl()
    check_providers()
end

return { check = check }
