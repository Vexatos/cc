local arg = {...}
parallel.waitForAny(function()
        os.run({}, table.unpack(arg))
    end, rednet and function()
        rednet.run()
    end or nil
)

print("Bios quit")
