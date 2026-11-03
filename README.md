# trans.nvim

An independently maintained Neovim translation plugin, built with reference to two projects:

- [JuanZoran/Trans.nvim](https://github.com/JuanZoran/Trans.nvim) (MIT) for the hover float
  UI and interaction model.
- [IC-killer/transdog.nvim](https://github.com/IC-killer/transdog.nvim) (MIT) for the sdcv
  offline dictionary plus LLM translation approach.

The data layer calls [sdcv](https://github.com/Dushistov/sdcv) directly and keeps online
providers as thin adapters over `curl`/`vim.system`.

## Features

- Offline word lookup through `sdcv` and StarDict dictionaries, no SQLite or 1.1GB ECDICT database.
- Whole-paragraph translation through any configured provider:
  - OpenAI-compatible LLM APIs (DeepSeek, Moonshot, Zhipu, Qwen, SiliconFlow, OpenRouter, Ollama `/v1`, ...)
  - Google Cloud Translation v2
  - Microsoft Azure Translator
  - Youdao
  - MyMemory (no key, free fallback)
- Hover UI: cursor-follow float, pin, page up/down, auto resize, cache.
- All configuration lives in Lua; secrets come from environment variables.
- No `Trans.json`, no `ultimate.db`, no install step.

## Requirements

- Neovim 0.10 or newer
- `sdcv` plus at least one StarDict dictionary
- `curl`
- Provider credentials only if you enable that provider

```bash
brew install sdcv
sdcv -l   # list loaded dictionaries
```

Dictionaries are loaded from `~/.stardict/dic/` (recommended) or the system StarDict
directories. Install both an English-Chinese and a Chinese-English dictionary if you want
offline lookup in both directions.

## Install

Keep the checkout anywhere and point lazy.nvim at it:

```lua
local env = vim.env

return {
  dir = vim.fn.expand "~/workspace/trans.nvim",
  main = "Trans",
  lazy = false,
  keys = {
    { "mm", mode = { "n", "x" }, "<Cmd>Translate<CR>", desc = "Translate" },
    { "mk", mode = { "n", "x" }, "<Cmd>TransPlay<CR>", desc = "Auto Play" },
    { "mi", "<Cmd>TranslateInput<CR>", desc = "Translate From Input" },
  },
  opts = {
    theme = "dracula",
    offline = "sdcv",
    order = { "llm", "google", "azure", "youdao", "mymemory" },
    backends = {
      sdcv = {
        cmd = "sdcv",
        args = { "-n", "-j", "-0", "-1", "-e" },
      },
      llm = {
        base_url = env.OPENAI_BASE_URL, -- default: https://api.openai.com/v1
        model = env.OPENAI_MODEL, -- default: gpt-4o-mini
        api_key = env.OPENAI_API_KEY,
      },
      google = { api_key = env.GOOGLE_TRANSLATE_API_KEY },
      azure = {
        api_key = env.AZURE_TRANSLATOR_KEY,
        region = env.AZURE_TRANSLATOR_REGION,
      },
      youdao = {
        app_id = env.YOUDAO_APP_ID,
        app_passwd = env.YOUDAO_APP_SECRET,
      },
      mymemory = { email = env.MYMEMORY_EMAIL },
    },
    frontend = {
      default = { query = "fallback", auto_play = true },
      hover = {
        keymaps = {
          pageup = "<c-b>",
          pagedown = "<c-f>",
          close = "<esc>",
          toggle_entry = "<c-c>",
        },
      },
    },
  },
}
```

## Behavior

1. `sdcv` runs first for the current word or selection. A hit renders through the offline
   UI (phonetic, merged part-of-speech lines).
2. If `sdcv` has no entry, providers in `order` are tried in sequence. A provider whose
   required credentials are missing is skipped.
3. The first successful provider result is cached and rendered in the hover window.

## Providers

| Provider | Backend | Configuration |
| --- | --- | --- |
| LLM | OpenAI-compatible `/chat/completions` | `base_url` (default `https://api.openai.com/v1`), `model` (default `gpt-4o-mini`), `api_key` |
| Google | Cloud Translation v2 | `api_key` (billing account required) |
| Azure | Translator v3 | `api_key`, optional `region` (F0: 2M chars/month) |
| Youdao | OpenAPI v3 | `app_id`, `app_passwd` |
| MyMemory | Public API | optional `email`; 500 bytes/request |

Environment variables used by the default config:

```text
OPENAI_API_KEY
OPENAI_BASE_URL
OPENAI_MODEL
GOOGLE_TRANSLATE_API_KEY
AZURE_TRANSLATOR_KEY
AZURE_TRANSLATOR_REGION
YOUDAO_APP_ID
YOUDAO_APP_SECRET
MYMEMORY_EMAIL
```

You can pass literal values in `opts.backends` instead of environment variables.

## Commands and keymaps

| Command | Description |
| --- | --- |
| `:Translate` | Translate the cursor word or visual selection |
| `:TranslateInput` | Translate text typed at a prompt |
| `:TransPlay` | Read English text with the system TTS |

Keymaps are yours to define; the example above uses `mm`, `mk`, `mi`.

## Health

```vim
:checkhealth Trans
```

Checks `sdcv`, loaded dictionaries, `curl`, and which providers are configured.

## Notes

- `sdcv` is called with exact search (`-e`). Misspellings and sentences fall through to
  online providers.
- Provider calls use `vim.system` with argument lists, so buffer text is never passed
  through a shell.
- The LLM backend speaks the OpenAI `/chat/completions` protocol. Point `OPENAI_BASE_URL` at
  any compatible gateway (DeepSeek, Moonshot, Zhipu, Qwen, OpenRouter, or a local
  `http://localhost:11434/v1` for Ollama) and set `OPENAI_MODEL` to a model it serves.
- MIT licensed; see `LICENCE`. The referenced projects are credited at the end of this file.

## Credits

- Hover UI and interaction: [JuanZoran/Trans.nvim](https://github.com/JuanZoran/Trans.nvim)
- Offline dictionary + LLM translation approach: [IC-killer/transdog.nvim](https://github.com/IC-killer/transdog.nvim)
- Offline dictionaries: [StarDict](http://stardict-4.sourceforge.net/) / [sdcv](https://github.com/Dushistov/sdcv)
