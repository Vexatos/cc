for n, fn in pairs(fs.list("rom/apis")) do
    local file = fs.combine("rom/apis", fn)
    if not fs.isDir(file) then
        if fn == "peripheral" then
            local oldPeripheral = peripheral
            os.loadAPI(file)
            peripheral.getNames = oldPeripheral.getNames
        else
            os.loadAPI(file)
        end
    end
end

