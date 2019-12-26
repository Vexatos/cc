local component = occ.component
local serialization = occ.serialization
local todo = occ.todo


occ.peripheral.registerMapper("glasses", function(addr)
    return "openperipheral_glassesbridge", {
        addIcon = todo(),
        getUsers = function()return component.invoke(addr, "getBindPlayers")end,
        listSources = todo({}),
        getById = todo({}),
        getObjectById = todo({}),
        listMethods = todo({"addIcon","getUsers","listSources","getById","getObjectById","listMethods","getGuid","addFluid","getSurfaceByName",
                            "addBox","clear","addText","getSurfaceByUUID","sync","getAllObjects","addGradientBox","getAdvancedMethodsData",
                            "getCaptureControl","addLiquid","gotAllIds","doc",}),
        getGuid = function()return addr end,
        addFluid = todo(),
        getSurfaceByName = todo(),
        addBox = todo(),
        clear = function()return component.invoke(addr, "removeAll")end,
        addText = todo(),
        getSurfaceByUUID = todo(),
        sync = todo(),
        getAllObjects = todo(),
        addGradientBox = todo(),
        getAdvancedMethodsData = todo({}),
        getCaptureControl = todo(),
        addLiquid = todo(),
        gotAllIds = todo(),
        doc = todo(""),
    }
end)