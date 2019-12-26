local component = occ.component
local serialization = occ.serialization
local todo = occ.todo

occ.peripheral.registerMapper("modem", function(addr)
    return "modem", {
        isWireless = function() return component.invoke(addr, "isWireless") end,
        isOpen = function(port) return component.invoke(addr, "isOpen", port) end,
        open = function(port) return component.invoke(addr, "open", port) end,
        close = function(port) return component.invoke(addr, "close", port) end,
        closeAll = function() return component.invoke(addr, "close") end,
        transmit = function(channel, replyChannel, message)
            return component.invoke(addr, "broadcast", channel, replyChannel, serialization.serialize(message, false))
        end,
        getNamesRemote = todo({}),
        getTypeRemote = todo(nil),
        isPresentRemote = todo(false),
        getMethodsRemote = todo({}),
        callRemote = todo(nil)
    }
end)

occ.event.registerHandler("modem_message", function(filt, localAddress, remoteAddress, port, distance, replyChannel, message)
    return occ.event.matches(filt, "modem_message"), {{
        "modem_message",
        occ.peripheral.getCCName(localAddress),
        port, replyChannel, serialization.unserialize(message), distance
    }}
end)
