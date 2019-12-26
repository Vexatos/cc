local ccore = require "cc.core"
local fs = require "filesystem"

local modules = {}
for file in fs.list("/etc/cc.d") do
    local path = "/etc/cc.d/" .. file
    table.insert(modules, {path = path, file = file})
end

table.sort(modules, function(a, b) return a.file < b.file end)

for i = 1, #modules do
    loadfile(modules[i].path, nil, ccore.userspace)()
end

local craft = {}

function craft.run(file, ...)
    ccore.run(loadfile(file, nil, ccore.userspace), ...)
end

return craft