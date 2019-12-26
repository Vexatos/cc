local term = require "term"
local fs = require "filesystem"
local shell = require "shell"
local component = require "component"

local romfn = "ComputerCraft1.80pr0.jar"
local romsrc = "https://addons-origin.cursecdn.com/files/2311/39/" .. romfn

local mode = ...
mode = mode or "computer"

local init = "/rom/programs/shell"
local exec = {}

function exec.help()
    print("craftos [help|computer|turtle|pocket|multishell]")
    os.exit()
end

function exec.computer()
    pcall(loadfile("/bin/resolution.lua"), "51", "19")
end

function exec.turtle()
    pcall(loadfile("/bin/resolution.lua"), "39", "13")
end

function exec.pocket()
    pcall(loadfile("/bin/resolution.lua"), "26", "20")
end

function exec.multishell()
    pcall(loadfile("/bin/resolution.lua"), "51", "19")
    init = "/rom/programs/advanced/multishell"
end

function exec.install()
    if not component.list("internet")() then
        print("Error: An Internet Card is required for installation!")
        os.exit()
    end
    print("Warning: This will wipe all data in /cc!")
    print("You may want to mount external storage under /cc.")
    io.write("Continue? [y/N]: ")
    if term.read():sub(1,1):lower() ~= "y" then
        os.exit()
    end
    io.write("* Wiping old install")
    fs.remove("/cc")
    fs.makeDirectory("/cc/.install")
    shell.setWorkingDirectory("/cc/.install")
    print(" [DONE]")
    print("")
    print("ComputerCraft will now be downloaded in order to extract CraftOS.")
    print("However, you must first agree with all the licensing provisions listed on http://computercraft.info.")
    io.write("Do you agree with ComputerCraft's terms of use? [y/N]: ")
    if term.read():sub(1,1):lower() ~= "y" then
        os.exit()
    end
    print("")
    io.write("* Downloading " .. romfn)
    shell.execute("wget", nil, "-fq", romsrc)
    print(" [DONE]")
    io.write("* Unpacking ROM from " .. romfn)
    shell.execute("/usr/lib/cc/unzip", nil, romfn)
    print(" [DONE]")
    io.write("* Cleaning up")
    fs.remove("/cc/.install")
    print(" [DONE]")
    print("")
    print("Installation complete. Run 'craftos' to use CraftOS.")
    os.exit()
end

if exec[mode] then
    exec[mode]()
else
    exec.help()
end

if not fs.exists("/cc/rom") then
    print("ROM not found! Please call 'craftos install' first.")
    return
end

term.clear()

local craft = require "cc.craft"
craft.run("/usr/lib/cc/bios.lua", init)
