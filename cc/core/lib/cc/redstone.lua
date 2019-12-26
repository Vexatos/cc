local ccside = {}
local component = require "component"

local function getRedstone()
    if component.isAvailable("redstone") then return component.redstone else return nil end
end

ccside["top"] = 1
ccside["bottom"] = 0
ccside["left"] = 4
ccside["right"] = 5
ccside["front"] = 3
ccside["back"] = 2

local function cc2oc(side) return ccside[side] end

local function todo(...)
    local a = {...}
    return function() return table.unpack(a) end
end

local ccredstone = {
    getSides = function() return {"top", "bottom", "left", "right", "front", "back"} end,
}

ccredstone.getInput = function(side)
    local redstone = getRedstone()
    if redstone ~= nil then return redstone.getInput(cc2oc(side)) > 0 else return false end
end

ccredstone.getOutput = function(side)
    local redstone = getRedstone()
    if redstone ~= nil then return redstone.getOutput(cc2oc(side)) > 0 else return false end
end

ccredstone.setOutput = function(side, value)
    local redstone = getRedstone()
    if redstone ~= nil then
        if value then
            redstone.setOutput(cc2oc(side), 15)
        else
           redstone.setOutput(cc2oc(side), 0)
        end
    end
end

ccredstone.getAnalogInput = function(side)
    local redstone = getRedstone()
    if redstone ~= nil then return redstone.getInput(cc2oc(side)) else return 0 end
end

ccredstone.getAnalogOutput = function(side)
    local redstone = getRedstone()
    if redstone ~= nil then return math.min(redstone.getOutput(cc2oc(side)), 15) else return 0 end
end

ccredstone.setAnalogOutput = function(side, value)
    local redstone = getRedstone()
    if redstone ~= nil then
        redstone.setOutput(cc2oc(side), value)
    end
end

ccredstone.getBundledInput = todo(0)
ccredstone.getBundledOutput = todo(0)
ccredstone.setBundledOutput = todo(nil)
ccredstone.testBundledInput = todo(false)

return ccredstone