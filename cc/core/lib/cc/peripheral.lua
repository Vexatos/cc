local component = require "component"
local ccevent = require("cc.integration")["cc.event"]
local ccperipheral = {}
local exports = {}
local serialization = require("serialization")

local function todo(...)
    local a = {...}
    return function() return table.unpack(a) end
end

ccperipheral.exports = exports

local mappers = {}
local mapAddrName = {}
local mapNameResult = {}
local mapNameType = {}
local mapNameAddr = {}
local countName = {}

local function ccname(addr, ctype)
    if ctype ~= nil and mapAddrName[addr] == nil and mappers[ctype] ~= nil then
        local cttype, result = mappers[ctype](addr)
        if result ~= nil then
            if countName[cttype] == nil then
                countName[cttype] = 1
            else
                countName[cttype] = countName[cttype] + 1
            end
            local name = cttype .. "_" .. countName[cttype]
            if name == "modem_1" then name = "right" end
            mapAddrName[addr] = name
            mapNameResult[name] = result
            mapNameType[name] = cttype
            mapNameAddr[name] = addr
        end
    end
    return mapAddrName[addr]
end

local function wrapped(name)
    return mapNameResult[name]
end

local function cctype(name)
    return mapNameType[name]
end

local function ocaddr(name)
    return mapNameAddr[name]
end

local function refresh()
    for addr, ctype in component.list() do
        ccname(addr, ctype)
    end
end

ccperipheral.getCCPeripheralName = ccname
ccperipheral.getOCPeripheralAddr = ocaddr

ccperipheral.registerPassthrough = function(name, newName)
    if newName == nil then newName = name end
    mappers[name] = function(addr)
        local funcs = {}
        for fn,v in pairs(component.methods(addr)) do
            funcs[fn] = function(...) return component.invoke(addr, fn, ...) end 
        end
        return newName, funcs
    end
end

function exports.getNames()
    local list = {}
    for addr, ctype in component.list() do
        local name = ccname(addr, ctype)
        if name ~= nil then
            list[#list + 1] = name
        end
    end
    return list
end

function exports.isPresent(name)
    refresh()
    if ocaddr(name) == nil then
        return false
    else
        return component.get(ocaddr(name)) ~= nil 
    end
end

function exports.getType(side)
    return mapNameType[side]
end

function exports.getMethods(name)
    refresh()
    local list = {}
    if ocaddr(name) ~= nil then
        for k, v in pairs(wrapped(name)) do
            list[#list + 1] = k
        end
    end
    return list
end

function exports.call(name, method, ...)
    refresh()
    if ocaddr(name) == nil then
        return nil
    else
        return wrapped(name)[method](...)
    end
end

function ccperipheral.registerMapper(octype, constructor)
    mappers[octype] = constructor
end

return ccperipheral