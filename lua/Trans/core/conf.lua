---@class Trans
---@field conf TransConf

---@class TransConf
return {
    debug = false,
    ---@type 'default' | 'dracula' | 'tokyonight' global Trans theme [see lua/Trans/style/theme.lua]
    theme = 'default', -- default | tokyonight | dracula
    ---@type string? Offline backend name, set false to disable
    offline = 'sdcv',
    ---@type string[] Online backends in fallback order
    order = { 'llm', 'google', 'azure', 'youdao', 'mymemory' },
    ---@type table<string, table> Per-backend settings; secrets default to environment variables
    backends = {
        sdcv = {
            cmd = 'sdcv',
            args = { '-n', '-j', '-0', '-1', '-e' },
        },
        llm = {
            base_url = vim.env.OPENAI_BASE_URL or 'https://api.openai.com/v1', -- any OpenAI-compatible endpoint
            model = vim.env.OPENAI_MODEL or 'gpt-4o-mini',
            api_key = vim.env.OPENAI_API_KEY,
            temperature = 0.2,
            timeout = 25,
        },
        google = {
            api_key = vim.env.GOOGLE_TRANSLATE_API_KEY,
            timeout = 25,
        },
        azure = {
            api_key = vim.env.AZURE_TRANSLATOR_KEY,
            region = vim.env.AZURE_TRANSLATOR_REGION,
            timeout = 25,
        },
        youdao = {
            app_id = vim.env.YOUDAO_APP_ID,
            app_passwd = vim.env.YOUDAO_APP_SECRET,
            timeout = 25,
        },
        mymemory = {
            email = vim.env.MYMEMORY_EMAIL,
            timeout = 25,
        },
    },
    strategy = {
        default = {
            frontend = 'hover',
        },
    },
    ---@type table frontend options
    frontend = {
        ---@class TransFrontendOpts
        ---@field keymaps table<string, string>
        default = {
            query = 'fallback',
            border = 'rounded',
            title = vim.fn.has 'nvim-0.9' == 1 and {
                { '', 'TransTitleRound' },
                { '󰊿 Trans', 'TransTitle' },
                { '', 'TransTitleRound' },
            } or nil, -- need nvim-0.9+
            auto_play = true, -- speak single words only; paragraph results are never auto-played
            ---@type {open: string | boolean, close: string | boolean, interval: integer} Hover Window Animation
            animation = {
                open = 'slid', -- 'fold', 'slid'
                close = 'slid',
                interval = 12,
            },
            timeout = 30000,
        },
        ---@class TransHoverOpts : TransFrontendOpts
        hover = {
            ---@type integer Max Width of Hover Window
            width = 37,
            ---@type integer Max Height of Hover Window
            height = 27,
            ---@type string -- see: /lua/Trans/style/spinner
            spinner = 'dots',
            ---@type string
            fallback_message = '{{notfound}} 翻译超时或没有找到相关的翻译',
            auto_resize = true,
            split_width = 60,
            padding = 10, -- padding for hover window width
            keymaps = {
                -- pageup       = '<C-u>',
                -- pagedown     = '<C-d>',
                -- pin          = '<leader>[',
                -- close        = '<leader>]',
                -- toggle_entry = '<leader>;',

                -- play         = '_', -- Deprecated
            },
            ---@type string[] auto close events
            auto_close_events = {
                'InsertEnter',
                'CursorMoved',
                'BufLeave',
            },
            ---@type table<string, string[]> order to display translate result
            order = {
                default = {
                    'str',
                    'translation',
                    'definition',
                },
                offline = {
                    'title',
                    'tag',
                    'pos',
                    'exchange',
                    'translation',
                    'definition',
                },
                youdao = {
                    'title',
                    'translation',
                    'definition',
                    'web',
                },
            },
            icon = {
                -- or use emoji
                list = '●', -- ● | ○ | ◉ | ◯ | ◇ | ◆ | ▪ | ▫ | ⬤ | 🟢 | 🟡 | 🟣 | 🟤 | 🟠| 🟦 | 🟨 | 🟧 | 🟥 | 🟪 | 🟫 | 🟩 | 🟦
                star = '', -- ⭐ | ✴ | ✳ | ✲ | ✱ | ✰ | ★ | ☆ | 🌟 | 🌠 | 🌙 | 🌛 | 🌜 | 🌟 | 🌠 | 🌌 | 🌙 |
                notfound = '󰆆 ', --❔ | ❓ | ❗ | ❕|
                yes = '✔', -- ✅ | ✔️ | ☑
                no = '', -- ❌ | ❎ | ✖ | ✘ | ✗ |
                cell = '■', -- ■  | □ | ▇ | ▏ ▎ ▍ ▌ ▋ ▊ ▉
                web = '󰖟', --🌍 | 🌎 | 🌏 | 🌐 |
                tag = '',
                pos = '',
                exchange = '',
                definition = '󰗊',
                translation = '󰊿',
            },
        },
    },
}

-- TODO :
-- float = {
--     width = 0.8,
--     height = 0.8,
--     border = 'rounded',
--     keymap = {
--         quit = 'q',
--     },
--     animation = {
--         open = 'fold',
--         close = 'fold',
--         interval = 10,
--     },
--     tag = {
--         wait = '#519aba',
--         fail = '#e46876',
--         success = '#10b981',
--     },
-- },

-- local title = {
--     "████████╗██████╗  █████╗ ███╗   ██╗███████╗",
--     "╚══██╔══╝██╔══██╗██╔══██╗████╗  ██║██╔════╝",
--     "   ██║   ██████╔╝███████║██╔██╗ ██║███████╗",
--     "   ██║   ██╔══██╗██╔══██║██║╚██╗██║╚════██║",
--     "   ██║   ██║  ██║██║  ██║██║ ╚████║███████║",
--     "   ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝╚══════╝",
--}
