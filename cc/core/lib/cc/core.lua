local ccfs = require "cc.fs"
local ccevent = require "cc.event"
local ccperipheral = require "cc.peripheral"
local ccterm = require "cc.term"
local event = require "event"
local computer = require "computer"
local term = require "term"
local component = require "component"
local serialization = require "serialization"

local function todo(...)
    local a = {...}
    return function() return table.unpack(a) end
end

local _OSVERSION = "OCraftOS(" .. _OSVERSION .. ")/0.1"
local _settings = {}

local userspace
userspace = {
    assert = assert,
    error = error,
    getmetatable = getmetatable,
    ipairs = ipairs,
    next = next,
    pairs = pairs,
    pcall = pcall,
    rawequal = rawequal,
    rawget = rawget,
    rawlen = rawlen,
    rawset = rawset,
    select = select,
    setmetatable = setmetatable,
    tonumber = tonumber,
    tostring = tostring,
    type = type,
    xpcall = xpcall,
    _HOST = "OpenComputers", --TODO: verify
    _OSVERSION = _OSVERSION,
    _VERSION = _VERSION,
    dofile = ccfs.dofile,
    -- Lua 5.1 compat
    unpack = table.unpack,
    -- CC APIs
    colors = { --Done
        white = 0x1,
        orange = 0x2,
        magenta = 0x4,
        lightBlue = 0x8,
        yellow = 0x10,
        lime = 0x20,
        pink = 0x40,
        gray = 0x80,
        lightGray = 0x100,
        cyan = 0x200,
        purple = 0x400,
        blue = 0x800,
        brown = 0x1000,
        green = 0x2000,
        red = 0x4000,
        black = 0x8000,
        
        combine = function(...)
            local r = 0
            for _, c in ipairs(...) do
                if type(c) ~= "number" then
                    error("Not a number!")
                end
                r = bit.bor(r, c)
            end
            return r
        end,
        subtract = function(s, ...)
            local mask = 0
            for _, c in ipairs(...) do
                if type(c) ~= "number" then
                    error("Not a number!")
                end
                mask = bit.bor(mask, c)
            end
            return bit.band(s, bit.bnot(mask))
        end,
        test = function(set, c) return bit.band(set, c) > 0 end
    },
    --Commands if debug card
    coroutine = { --Done
        create = coroutine.create,
        resume = coroutine.resume,
        running = coroutine.running,
        status = coroutine.status,
        wrap = coroutine.wrap,
        yield = coroutine.yield,
    },
    disk = ccfs.disk, --TODO
    fs = ccfs.fs, --Done
    gps = { --TODO
        locate = todo(nil),
    },
    http = require("cc.http"),
    io = ccfs.io, --DONE
    help = {
        path = todo("/rom/help"),
        setPath = todo(),
        lookup = todo(),
        topics = todo({}),
        completeTopic = todo({}),
    },
    keys = require("cc.keys"),
    math = {
        abs = math.abs,
        acos = math.acos,
        asin = math.asin,
        atan = math.atan,
        atan2 = math.atan2,
        ceil = math.ceil,
        cos = math.cos,
        cosh = math.cosh,
        deg = math.deg,
        exp = math.exp,
        floor = math.floor,
        fmod = math.fmod,
        frexp = math.frexp,
        huge = math.huge,
        ldexp = math.ldexp,
        log = math.log,
        log10 = function(v) return math.log(v, 10) end,
        max = math.max,
        min = math.min,
        modf = math.modf,
        pi = math.pi,
        pow = math.pow,
        rad = math.rad,
        random = math.random,
        randomseed = math.randomseed,
        sin = math.sin,
        sinh = math.sinh,
        sqrt = math.sqrt,
        tan = math.tanh,
        tanh = math.tanh,
    },
    table = {
        pack = table.pack,
        unpack = table.unpack,
        concat = table.concat,
        insert = table.insert,
        maxn = function(t)return #t end,
        remove = table.remove,
        sort = table.sort,
    },
-- The tostring wrappers are related to OpenComputers#1999
    string = {
        byte = string.byte,
        char = string.char,
        dump = string.dump,
        find = function(s, pattern, index, plain) return string.find(tostring(s), tostring(pattern), index, plain) end,
        format = string.format,
        gmatch = function(s, pattern) return string.gmatch(tostring(s), tostring(pattern)) end,
        gsub = function(s, pattern, replace, n)
            if type(replace) ~= "string" and type(replace) ~= "function" then replace = tostring(replace) end
            return string.gsub(tostring(s), tostring(pattern), replace, n)
        end,
        len = string.len,
        lower = string.lower,
        match = function(s, pattern, index) return string.match(tostring(s), tostring(pattern), index) end,
        rep = string.rep,
        reverse = string.reverse,
        sub = string.sub,
        upper = string.upper,
    },
    multishell = {
        getCurrent = todo(1),
        getCount = todo(1),
        launch = todo(-1),
        setFocus = todo(false),
        setTitle = todo(),
        getTitle = todo(""),
        getFocus = todo(1),
    },
    settings = {
        set = function(key, value)
            checkArg(1, key, "string")
            local safeData = serialization.unserialize(serialization.serialize(value))
            _settings[key] = safeData
        end,
        get = function(key)
            return _settings[key]
        end,
        unset = function(key)
            checkArg(1, key, "string")
            _settings[key] = nil
        end,
        cleat = function()
            _settings = {}
        end,
        getNames = function()
            local l = {}
            for k in pairs(_settings) do
                l[#l + 1] = k
            end
            return l
        end,
        load = function(path)
            local h = io.open(ccfs.ccpath(path), "r")
            if not h then return false end
            local data = h:read("*a")
            h:close()
            _settings = serialization.unserialize(data)
            return true
        end,
        save = function(path)
            local h = io.open(ccfs.ccpath(path), "w")
            if not h then return false end
            local data = h:write(serialization.serialize(_settings))
            h:close()
            return true
        end,
    },
    os = {
        version = function()return _OSVERSION end,
        getComputerID = function()
            local h = io.open("/home/ccid", "r")
            if not h then return 1 end
            local code = h:read("*l")
            h:close()
            return tonumber(code)
        end,
        getComputerLabel = todo(),
        setComputerLabel = todo(),
        run = function(env, path, ...)
            local h = io.open(ccfs.ccpath(path), "r")
            if not h then
                userspace.printError("File not found")
            end
            local code = h:read("*a")
            h:close()
            
            local f, err = load(code, nil, "=" .. path, setmetatable(env, {__index = userspace}))
            if not f then
                userspace.printError(tostring(err))
                return false
            end
            local r, err = pcall(f, ...)
            if not r then
                userspace.printError(tostring(err))
            end
            return r
        end,
        sleep = os.sleep,
        clock = computer.uptime,
        setAlarm = todo({}),
        cancelAlarm = todo(),
        shutdown = function() computer.shutdown(false) end,
        reboot = function() computer.shutdown(true) end,
    },
    sleep = os.sleep,
    redstone = require("cc.redstone"),
    peripheral = ccperipheral.exports,
    commands = require("cc.commands").exports,

    term = ccterm.term,
    print = ccterm.print,
    printError = ccterm.printError,
    write = ccterm.write,
    read = ccterm.read,
    
    occ = {
        component = component,
        serialization = serialization,
        todo = todo,
        
        event = {
            registerHandler = ccevent.registerEventHandler,
            matches = ccevent.validateFilter
        },
        
        peripheral = {
            registerMapper = ccperipheral.registerMapper,
            registerPassthrough = ccperipheral.registerPassthrough,
            getCCName = ccperipheral.getCCPeripheralName,
            getOCAddr = ccperipheral.getOCPeripheralAddr
        }
    }
}

userspace.getfenv = function(func)
    if type(func) == "function" then return userspace end
    if type(func) == "number" then return userspace end
    if type(func) == "nil" then return userspace end
    checkArg(1, func, "table")
    checkArg(2, env, "table")
    local mt = getmetatable(func)
    if not mt then
        error("Invalid argument #1")
    end
    if not mt.env then
        return userspace
    end
    return mt.env
end

userspace.setfenv = function(func, env)
    if type(func) == "function" then 
        return load(string.dump(func), nil, nil, env)
    end
    if type(func) == "number" then error("Hax not implemented") end
    
    checkArg(1, func, "table")
    checkArg(2, env, "table")
    local mt = getmetatable(func)
    if not mt then
        error("Invalid argument #1")
    end
    if mt.f then
        error("Hax not implemented")
    end
    mt.env = env
    
    return func
end

userspace.load = function(src, chunkname, mode, env)
    do
        if type(src) == "function" or (type(src) == "table" and getmetatable(src).__call) then
            local s = ""
            for c in src do
                if c == "" then break end
                s = s .. c
            end
            src = s
        end
        
        local f, err = load(src, "=" .. (chunkname or "load"), mode, env or userspace)
        if not f then
            return nil, err
        end
    end
    
    return setmetatable({}, {
        env = env or userspace,
        __call = function(t, ...)
            local mt = getmetatable(t)
            if mt.f then return mt.f(...) end
            local f, wut = load(src, "=" .. (chunkname or "load"), mode, mt.env or userspace)
            if not f then
                error(wut)
            end
            mt.f = f
            return mt.f(...)
        end,
        tostring = function(t, ...)
            local mt = getmetatable(t)
            return mt.f and tostring(mt.f) or "function: 0x00000000"
        end,
        __newindex = function() error("attmpted to set index of a function") end,
        __index = function() error("attmpted to index a function") end
    })
end

userspace.loadstring = function(str, chunkname)
    return userspace.load(str, "=" .. (chunkname or "string"))
end

userspace.loadfile = function(f, ...)
    local h, err = io.open(ccfs.ccpath(f), "r")
    if not h then
        return nil, err
    end
    local src = h:read("*a")
    h:close()
    return load(src, f)
end

if component.isAvailable("robot") then
    userspace.turtle = require("cc.turtle")
end

userspace.rs = userspace.redstone

local bit32 = bit32 or load([[return {
    band = function(a, b) return a & b end,
    bor = function(a, b) return a | b end,
    bxor = function(a, b) return a ~ b end,
    bnot = function(a) return ~a end,
    rshift = function(a, n) return a >> n end,
    lshift = function(a, n) return a << n end,
}]])()

userspace.bit = { --Done
    blshift = bit32.lshift,
    brshift = bit32.arshift,
    blogic_rshift = bit32.rshift,
    bxor = bit32.bxor,
    bor = bit32.bor,
    bnot = bit32.bnot,
    band = bit32.band
}

userspace.colours = userspace.colors
userspace._G = userspace

local loading = {}
userspace.os.loadAPI = function(file)
    local name = ccfs.fs.getName(file):gsub("%.lua$", "")
    if loading[name] then
        io.stderr:write("API " .. name .. " is already being loaded")
        return false
    end
    
    local h = io.open(ccfs.ccpath(file), "r")
    if not h then
        io.stderr:write("No such API " .. file)
        return false
    end
    
    loading[name] = true
    
    local code = h:read("*a")
    h:close()
    local env = setmetatable({}, {__index = userspace})
    local f, err = load(code, nil, "=" .. file, env)
    if not f then
        loading[name] = nil
        io.stderr:write(err)
        return false
    end
    local r, err = pcall(f)
    if not r then
        loading[name] = nil
        io.stderr:write(err)
        return false
    end
    local api = {}
    for k, v in pairs(env) do
        if k ~= "_ENV" then
            api[k] =  v
        end
    end
    userspace[name] = api
    loading[name] = nil
    return true
end

userspace.os.unloadAPI = function(name)
    if name ~= "_G" and type(userspace[name]) == "table" then
        userspace[name] = nil
    end
end

userspace.os.pullEventRaw = function(filter)
    return coroutine.yield(filter)
end

userspace.os.pullEvent = function(filter)
    local event = {userspace.os.pullEventRaw(filter)}
    if event[1] == "terminate" then
        error("Terminated")
    end
    return table.unpack(event)
end

userspace.os.queueEvent = function(...)
    local n = #ccevent.softqueue + 1
    ccevent.softqueue[n] = {...}
    computer.pushSignal("cc", n)
end

userspace.os.startTimer = function(timeout)
    local t = 0
    t = event.timer(timeout, function()
        local n = #ccevent.softqueue + 1
        ccevent.softqueue[n] = {"timer", t}
        computer.pushSignal("cc", n)
    end, 1)
    return t
end

userspace.os.cancelTimer = function(timer)
    return event.cancel(timer)
end

userspace.os.time = function()
    return (os.time() / 3600) % 24
end

userspace.os.day = function()
    return math.floor(os.time() / 86400)
end

local function run(fn, ...)
    local rt = coroutine.create(fn)
    local state, filter
    state, filter = coroutine.resume(rt, ...)
    while coroutine.status(rt) ~= "dead" do
        while true do
            local sig = {event.pull()}
            local matches, translated = ccevent.process(filter, sig)
            --print("S: " .. sig[1] .. " M: " .. tostring(matches))
            if matches then
                for k,v in pairs(translated) do
                  state, filter = coroutine.resume(rt, table.unpack(v))
                end
                --print("st: " .. tostring(state) .. " F: " .. tostring(filter))
                break
            end
        end
    end
    if not state then
        print("Error detected: " .. tostring(filter))
    else
        print("Quit without errors.")
    end
end

return {userspace = userspace, run = run}
