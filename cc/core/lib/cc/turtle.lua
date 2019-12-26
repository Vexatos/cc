local component = require "component"
local computer = require "computer"
local robot = component.robot

local ccturtle = {}

local function todo(...)
    local a = {...}
    return function() return table.unpack(a) end
end

ccturtle.craft = todo(false)

ccturtle.forward = function() return robot.move(3) end
ccturtle.back = function() return robot.move(2) end
ccturtle.up = function() return robot.move(1) end
ccturtle.down = function() return robot.move(0) end

ccturtle.turnLeft = function() return robot.turn(false) end
ccturtle.turnRight = function() return robot.turn(true) end

ccturtle.select = function(slot)
    local newSlot = robot.select(slot)
    return slot == newSlot
end
ccturtle.getSelectedSlot = function() return robot.select() end
ccturtle.getItemCount = robot.count
ccturtle.getItemSpace = robot.space
ccturtle.getItemDetail = function(slot)
    if not component.isAvailable("inventory_controller") then
        return {}
    end
    local data = component.inventory_controller.getStackInInternalSlot(slot)
    return {
        name = data.name,
        damage = data.damage,
        count = data.size,
    }
end

ccturtle.equipLeft = todo(false) -- Is it just me or is it just not possible?
ccturtle.equipRight = todo(false) -- As above
ccturtle.attack = robot.swing
ccturtle.attackUp = robot.swingUp
ccturtle.attackDown = robot.swingDown
ccturtle.dig = robot.swing
ccturtle.digUp = robot.swingUp
ccturtle.digDown = robot.swingDown

-- TODO: sign text
ccturtle.place = function()
    return robot.place()
end

ccturtle.placeUp = function()
    return robot.placeUp()
end
ccturtle.placeDown = function()
    return robot.placeDown()
end

ccturtle.detect = function()
    local blocked, typ = robot.detect()
    return blocked and typ ~= "entity"
end
ccturtle.detectUp = function()
    local blocked, typ = robot.detectUp()
    return blocked and typ ~= "entity"
end
ccturtle.detectDown = function()
    local blocked, typ = robot.detectDown()
    return blocked and typ ~= "entity"
end

ccturtle.inspect = todo({name = "minecraft:air", metadata = 0})
ccturtle.inspectUp = todo({name = "minecraft:air", metadata = 0})
ccturtle.inspectDown = todo({name = "minecraft:air", metadata = 0})
ccturtle.compare = robot.compare
ccturtle.compareUp = robot.compareUp
ccturtle.compareDown = robot.compareDown
ccturtle.suck = robot.suck
ccturtle.suckUp = robot.suckUp
ccturtle.suckDown = robot.suckDown
ccturtle.refuel = todo(false) --http://ocdoc.cil.li/component:generator
ccturtle.getFuelLevel = computer.energy
ccturtle.getFuelLimit = computer.maxEnergy()
ccturtle.transferTo = robot.transferTo

return ccturtle