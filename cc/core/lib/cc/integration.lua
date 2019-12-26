local ccintegration = {}

setmetatable(ccintegration, {__index = function(t, k)
    local lib = require(k)
    t[k] = lib
    return lib
end})

return ccintegration
