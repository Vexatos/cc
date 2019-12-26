local ocfs = require "filesystem"
local term = require "term"

local fsBase = "/cc/"

local function ccpath(path)
    return ocfs.concat(fsBase, ocfs.canonical(path))
end

local function todo(...)
    local a = {...}
    return function() return table.unpack(a) end
end

local ccfs = {}

ccfs.ccpath = ccpath

ccfs.disk = { --TODO
    isPresent = todo(false),
    hasData = todo(false),
    getMountPath = todo(nil),
    setLabel = todo(),
    getId = todo(),
    hasAudio = todo(false),
    getAudioTitle = todo(nil),
    playAudio = todo(),
    stopAudio = todo(),
    eject = todo(),
}

ccfs.io = {
    close = io.close,
    flush = io.flush,
    input = function(f)
        if type(f) == "string" then
            f = ccpath(f)
        end
        return io.input(f)
    end,
    lines = function(path)
        return io.lines(ccpath(path))
    end,
    open = function(path, mode)
        local s = ocfs.segments(ccpath(path))
        local parent = table.concat(s, "/", 1, #s - 1)
        if not ocfs.exists(parent) then
            ocfs.makeDirectory(parent)
        end
        
        return io.open(ccpath(path), mode)
    end,
    output = function(f)
        if type(f) == "string" then
            f = ccpath(f)
        end
        return io.output(f)
    end,
    write = io.write, --TODO: use cc term or sth.
    read = function(fmt)
        if fmt ~= "*l" then
            return nil, "Error Code 200"
        end
        return term.read()
    end,
    type = io.type
}

ccfs.fs = {
    list = function(path)
        local files = {}
        for f in ocfs.list(ccpath(path)) do
            if f:sub(-1) == "/" then
                f = f:sub(1, -2)
            end
            files[#files + 1] = f
        end
        return files
    end,
    exists = function(path)
        return ocfs.exists(ccpath(path))
    end,
    isDir = function(path)
        return ocfs.isDirectory(ccpath(path))
    end,
    isReadOnly = todo(false),
    getName = function(path)
        local s = ocfs.segments(path)
        return s[#s] or nil
    end,
    getDrive = todo(nil),
    getSize = function(path)
        return ocfs.size(ccpath(path))
    end,
    getFreeSpace = todo(1024 * 1024 * 4),
    makeDir = function(path)
        return ocfs.makeDirectory(ccpath(path))
    end,
    move = function(p1, p2)
        local s = ocfs.segments(ccpath(p2))
        local parent = table.concat(s, "/", 1, #s - 1)
        if not ocfs.exists(parent) then
            ocfs.makeDirectory(parent)
        end
        
        return ocfs.rename(ccpath(p1), ccpath(p2))
    end,
    copy = function(p1, p2)
        local s = ocfs.segments(ccpath(p2))
        local parent = table.concat(s, "/", 1, #s - 1)
        if not ocfs.exists(parent) then
            ocfs.makeDirectory(parent)
        end
        
        return ocfs.copy(ccpath(p1), ccpath(p2))
    end,
    delete = function(path)
        return ocfs.remove(ccpath(path))
    end,
    combine = ocfs.concat,
    -- TODO: Create directories on write
    open = function(path, mode)
        local s = ocfs.segments(ccpath(path))
        local parent = table.concat(s, "/", 1, #s - 1)
        if not ocfs.exists(parent) then
            ocfs.makeDirectory(parent)
        end
        
        local h, err = io.open(ccpath(path), mode)
        if not h then
            return nil, err
        end
        return {
            close = function() return h:close() end,
            readLine = function() return h:read("*l") end,
            readAll = function() return h:read("*a"):gsub("[\r\n]+$", "") end,
            read = function() return h:read(1):byte() end,
            write = function(data) h:write(data) end,
            writeLine = function(data) h:write(data .. "\n") end,
            flush = function() h:flush() end,
        }
    end,
    find = todo({}),
    getDir = function(path)
        local s = ocfs.segments(path)
        return table.concat(s, "/", 1, #s - 1)
    end,
    complete = todo({})
}

ccfs.dofile = function(f, ...) return dofile(ccpath(f), ...) end
ccfs.loadfile = function(f, ...) return loadfile(ccpath(f), ...) end

return ccfs
