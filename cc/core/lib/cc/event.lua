local ccevent = {}
local hnd = {}

ccevent.softqueue = {}
ccevent.handlers = hnd

function ccevent.registerEventHandler(name, handler)
    hnd[name] = handler
end

function ccmouse(i)
    if i == 0 then return 1 end
    if i == 1 then return 2 end
    return -1
end

function ccevent.process(filter, signal)
    if hnd[signal[1]] then
        return hnd[signal[1]](filter, table.unpack(signal, 2))
    end
    return false
end

function matches(filt, target)
    return filt == nil or filt == target
end

ccevent.validateFilter = matches

function hnd.redstone_changed(filt, address, side, oldValue, newValue)
    return matches(filt, "redstone"), {{"redstone"}}
end

function hnd.key_down(filt, address, chr, code, player)
    if chr ~= nil and ((chr >= 32 and chr <= 126) or (chr >= 161 and chr <= 255)) then
        return matches(filt, "key"), {{"key", code, false}, {"char", string.char(chr)}}
    else
        return matches(filt, "key"), {{"key", code, false}}
    end
end

function hnd.key_up(filt, address, chr, code, player)
    return matches(filt, "key_up"), {{"key_up", code}}
end

function hnd.clipboard(filt, address, value, player)
    return matches(filt, "paste"), {{"paste", value}}
end

function hnd.touch(filt, address, x, y, button, player)
    return matches(filt, "mouse_click"), {{"mouse_click", ccmouse(button), x, y}}
end

function hnd.scroll(filt, address, x, y, button, player)
    return matches(filt, "mouse_scroll"), {{"mouse_scroll", 0 - button, x, y}}
end

function hnd.drag(filt, address, x, y, button, player)
    return matches(filt, "mouse_drag"), {{"mouse_drag", ccmouse(button), x, y}}
end

function hnd.drop(filt, address, x, y, button, player)
    return matches(filt, "mouse_up"), {{"mouse_up", ccmouse(button), x, y}}
end

function hnd.interrupted(filt, sig)
    return matches(filt, "terminate"), {{"terminate"}}
end

function hnd.cc(filt, n)
    local sig = ccevent.softqueue[n]
    ccevent.softqueue[n] = nil
    return matches(filt, sig[1]), {sig}
end


return ccevent