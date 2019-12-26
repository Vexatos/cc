local term = require "term"
local event = require "event"

local cbmap = {
    [0x1] = 0xF0F0F0,
    [0x2] = 0xF2B233,
    [0x4] = 0xE57FD8,
    [0x8] = 0x99B2F2,
    [0x10] = 0xDEDE6C,
    [0x20] = 0x7FCC19,
    [0x40] = 0xF2B2CC,
    [0x80] = 0x4C4C4C,
    [0x100] = 0x999999,
    [0x200] = 0x4C99B2,
    [0x400] = 0xB266E5,
    [0x800] = 0x3366CC,
    [0x1000] = 0x7F664C,
    [0x2000] = 0x57A64E,
    [0x4000] = 0xCC4C4C,
    [0x8000] = 0x000000,
}

local cfmap = {
    [0x1] = 0xF0F0F0,
    [0x2] = 0xF2B233,
    [0x4] = 0xE57FD8,
    [0x8] = 0x99B2F2,
    [0x10] = 0xDEDE6C,
    [0x20] = 0x7FCC19,
    [0x40] = 0xF2B2CC,
    [0x80] = 0x4C4C4C,
    [0x100] = 0x999999,
    [0x200] = 0x4C99B2,
    [0x400] = 0xB266E5,
    [0x800] = 0x3366CC,
    [0x1000] = 0x7F664C,
    [0x2000] = 0x57A64E,
    [0x4000] = 0xCC4C4C,
    [0x8000] = 0x1F1F1F
}

local bit32 = bit32 or load([[return {
    band = function(a, b) return a & b end,
    bor = function(a, b) return a | b end,
    bxor = function(a, b) return a ~ b end,
    bnot = function(a) return ~a end,
    rshift = function(a, n) return a >> n end,
    lshift = function(a, n) return a << n end,
}]])()

local function todo(...)
    local a = {...}
    return function() return table.unpack(a) end
end

if term.gpu().maxDepth() >= 4 then
  local i = 0
  for k,v in pairs(cfmap) do
      term.gpu().setPaletteColor(i, v)
      i = i + 1
  end
end

local ctext = 0x8000
local cback = 0x1

local ccterm = {}

local currf = -1
local currb = -1

function setBG(c)
    if currb ~= c then
        currb = c
        term.gpu().setBackground(c)
    end
end

function setFG(c)
    if currf ~= c then
        currf = c
        term.gpu().setForeground(c)
    end
end

ccterm.clear = term.clear
ccterm.clearLine = term.clearLine
ccterm.getCursorPos = term.getCursor
ccterm.setCursorPos = term.setCursor
ccterm.setCursorBlink = term.setCursorBlink
ccterm.isColor = function()return term.gpu().maxDepth() >= 4 end
ccterm.getSize = function()return term.gpu().getResolution() end
-- TODO: add negative scroll
ccterm.scroll = function(n)term.write(("\n"):rep(n))end
ccterm.redirect = function()return ccterm end
ccterm.current = function()return ccterm end
ccterm.native = function()return ccterm end
ccterm.setTextColor = function(c)ctext = c setFG(cfmap[c])end
ccterm.getTextColor = function()return ctext end
ccterm.setBackgroundColor = function(c)cback = c setBG(cbmap[c])end
ccterm.getBackgroundColor = function()return cback end

ccterm.isColour = ccterm.isColor
ccterm.setTextColour = ccterm.setTextColor
ccterm.getTextColour = ccterm.getTextColor
ccterm.setBackgroundColour = ccterm.setBackgroundColor
ccterm.getBackgroundColour = ccterm.getBackgroundColor

local cco = {}
cco.term = ccterm

local chartable = require("cc.core-char")
local unicode = require("unicode")

ccterm.setVisible = todo(nil)
ccterm.redraw = todo(nil)
ccterm.restoreCursor = todo(nil)
ccterm.getPosition = todo(0, 0)
ccterm.reposition = todo(nil)
ccterm.setTextScale = todo(nil)

function cctext(s)
    if type(s) == "string" then
        local t = ""
        for i=1,#s do
            local sc = s:sub(i, i)
            local sb = sc:byte()
            if (sb + 1) <= #chartable then
               sc = unicode.char(chartable[sb + 1])
            end
            t = t .. sc
        end
        return t
    else
        return s
    end
end

ccterm.blit = function(s, fg, bg)
    if #s ~= #fg or #s ~= #bg or #fg ~= #bg then
        error("Blit string length mismatch!")
        return
    end
    local t = ""
    for i=1,#s do
        local cbg = bg:sub(i, i)
        local cfg = fg:sub(i, i)
        if cbg == " " then cbg = 15 else cbg = tonumber(cbg, 16) end
        if cfg == " " then cfg = 0 else cfg = tonumber(cfg, 16) end
        cfg = cfmap[bit32.lshift(1, cfg)]
        cbg = cbmap[bit32.lshift(1, cbg)]
        local ch = s:sub(i, i)
        local useCctext = true
        if currb == cfg and currf == cbg then
            local cn = ch:byte()
            local x = false
            if cn == 0 or cn == 128 or cn == 160 or cn == 32 then
                x = true
                useCctext = false
                ch = unicode.char(0x2588)
            elseif cn == 7 or cn == 8 then
                x = true
                ch = string.char(bit32.bxor(cn, 1))
            elseif cn > 128 and cn < 160 then
                x = true
                useCctext = false
                ch = unicode.char(bit32.bxor(chartable[cn + 1], 0x3F))
            end
            if x == true then
                x = cfg
                cfg = cbg
                cbg = x
            end
        end
        if currb ~= cbg or currf ~= cfg then
            if #t > 0 then
                term.write(t)
                t = ""
            end
            setFG(cfg)
            setBG(cbg)
        end
        if useCctext == true then
            ch = cctext(ch)
        end
        t = t .. ch
    end
    if #t > 0 then
        term.write(t)
    end
    setFG(cfmap[ctext])
    setBG(cbmap[cback])
end

-- no wordwrap, no scroll
ccterm.write = function(text)
    term.write(cctext(text), false)
end
-- wordwrap, scroll
cco.print = function(text)
    local x, y = term.getCursor()
    if text == nil then
        print()
    else
        print(cctext(text))
    end
    local nx, ny = term.getCursor()
    return ny - y
end
-- wordwrap, no scroll (TODO)
-- TODO: Verify if return is lines changed
cco.write = function(text)
    local x, y = term.getCursor()
    io.write(cctext(text))
    local nx, ny = term.getCursor()
    return ny - y
end
cco.printError = function(t)io.stderr:write(tostring(t) .. "\n")end
cco.read = function()
    local s = term.read()
    event.pull("key_up")
    if type(s) ~= "string" then return nil else return s:sub(1, -2) end
end

return cco
