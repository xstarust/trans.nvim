---@diagnostic disable: param-type-mismatch
require 'test.setup'

local util = Trans.util

describe('util.display_height', function()
    it('can calculate the height of lines when window with wrap option', function()
        local lines = {
            '1234567890',
            '1234567890',
            '1234567890',
            '1234567890',
            '1234567890',
            '1234567890',
            '1234567890',
            '1234567890',
            '1234567890',
        }

        assert.are.equal(#lines, util.display_height(lines, 10))
        assert.are.equal(#lines, util.display_height(lines, 11))
        assert.are.equal(2 * #lines, util.display_height(lines, 9))

        -- Unicode width test
        local u_lines = {
            '12345678👍', -- 10
            'あうえお', -- 8
            '𠮷野い𠮷家野家家', -- 16
            '👍👍👍お家', -- 10
        }

        assert.are.equal(4, util.display_height(u_lines, 20))
        assert.are.equal(4, util.display_height(u_lines, 16))
        assert.are.equal(5, util.display_height(u_lines, 10))
        assert.are.equal(7, util.display_height(u_lines, 8))
        assert.are.equal(9, util.display_height(u_lines, 7))
    end)
end)

describe('util.display_width', function()
    it('can calculate the max width of lines', function()
        local lines = {
            '1234567890',
            '123456789',
            '12345678',
            '1234567',
            '123456',
            '12345',
            '1234',
            '123',
            '12',
            '1',
        }

        assert.are.equal(10, util.display_width(lines))
        -- Unicode width test
        local u_lines = {
            '12345678👍', -- 10
            'あうえお', -- 8
            '𠮷野い𠮷家野家家', -- 16
            '👍👍👍お家', -- 10
        }

        assert.are.equal(16, util.display_width(u_lines))
    end)
end)

describe('util.center', function()
    it('will return the node if its width more than width', function()
        local node = i { '1234567890' }
        assert.are.same(node, util.center(node, 9))
    end)

    it('will auto padding space', function()
        local node = i { '1234567890' }
        assert.are.same(i { (' '):rep(2) .. '1234567890' }, util.center(node, 15))
    end)
end)

describe('util.is_word', function()
    it('can detect word', function()
        for test, value in pairs {
            ['あうえお'] = false,
            ['hello']        = true,
            [' hello']       = false,
            ['hello world']  = false,
            ['test_cool']    = false,
        } do
            assert.are.same(util.is_word(test), value)
        end
    end)
end)

describe('util.is_paragraph', function()
    it('detects whitespace separated text', function()
        for test, value in pairs {
            ['hello']         = false,
            ['你好']          = false,
            ['hello world']   = true,
            ['hello\nworld']  = true,
            ['one two three'] = true,
        } do
            assert.are.same(util.is_paragraph(test), value)
        end
    end)
end)

describe('util.normalize_identifier', function()
    it('splits identifiers into words for provider queries', function()
        for test, value in pairs {
            ['hello']                = 'hello',
            ['extend_mini_files']    = 'extend mini files',
            ['extendMiniFiles']      = 'extend Mini Files',
            ['LazyExtras']            = 'Lazy Extras',
            ['HTTPServer']           = 'HTTP Server',
            ['__init__']             = 'init',
            ['extend_mini_files.lua'] = 'extend mini files lua',
            ['already spaced text']  = 'already spaced text',
            ['__']                   = '__',
        } do
            assert.are.same(value, util.normalize_identifier(test))
        end
    end)
end)

describe('util.word_at', function()
    it('extracts the sub-word under a byte column', function()
        local line = 'extend_mini_files.lua'
        assert.are.equal('extend', util.word_at(line, 0))
        assert.are.equal('extend', util.word_at(line, 5))
        assert.are.equal('mini', util.word_at(line, 7))
        assert.are.equal('files', util.word_at(line, 14))
        assert.are.equal('', util.word_at(line, 17))
        assert.are.equal('lua', util.word_at(line, 18))
        assert.are.equal('hello', util.word_at('hello world', 0))
        assert.are.equal('world', util.word_at('hello world', 6))
        assert.are.equal('你好世界', util.word_at('你好世界', 0))
        assert.are.equal('', util.word_at('', 0))
    end)

    it('splits camelCase and acronyms at case boundaries', function()
        local lazy = 'LazyExtras'
        assert.are.equal('Lazy', util.word_at(lazy, 0))
        assert.are.equal('Lazy', util.word_at(lazy, 3))
        assert.are.equal('Extras', util.word_at(lazy, 4))
        assert.are.equal('Extras', util.word_at(lazy, 9))

        local http = 'HTTPServer'
        assert.are.equal('HTTP', util.word_at(http, 0))
        assert.are.equal('HTTP', util.word_at(http, 3))
        assert.are.equal('Server', util.word_at(http, 4))

        local mixed = 'getHTTPResponse'
        assert.are.equal('get', util.word_at(mixed, 1))
        assert.are.equal('HTTP', util.word_at(mixed, 4))
        assert.are.equal('Response', util.word_at(mixed, 8))

        local digits = 'v2Server'
        assert.are.equal('v2', util.word_at(digits, 1))
        assert.are.equal('Server', util.word_at(digits, 2))
        assert.are.equal('hello', util.word_at('hello', 2))
    end)
end)

describe('util.replace_chinese_punctuation', function()
    it('replaces Chinese punctuation with English punctuation', function()
        local input = '你好，世界。欢迎！你在这里吗？'
        local expected = '你好,世界.欢迎!你在这里吗?'
        assert.are.equal(expected, util.replace_chinese_punctuation(input))
    end)
end)
