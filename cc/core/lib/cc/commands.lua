local component = require "component"

local cccommands = {}

if component.isAvailable("debug") then
    cccommands.exports = {}
    
    function cccommands.exports.exec(command)
        return component.debug.runCommand(command)
    end
    
    function cccommands.exports.execAsync(command)
        return component.debug.runCommand(command)
    end
    
    function cccommands.exports.list()
        return {} --TODO: better fallback
    end
    
    function cccommands.exports.getBlockPosition()
        return component.debug.getX(), component.debug.getY(), component.debug.getZ()
    end
    
    function cccommands.exports.getBlockInfo(x, y, z)
        checkArg(1, x, "number")
        checkArg(2, y, "number")
        checkArg(3, z, "number")
        
        return {
            name = tostring(component.debug.getWorld().getBlockId(x, y, z)),
            metadata = tostring(component.debug.getWorld().getMetadata(x, y, z)),
            state = component.debug.getTileNBT(x, y, z) --likely wrong, check?
        }
    end
    
    function cccommands.exports.getBlockInfos(x1, y1, z1, x2, y2, z2)
        
    end
end

return cccommands
