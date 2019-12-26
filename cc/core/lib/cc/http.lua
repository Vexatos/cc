local component = require "component"
local internet = require "internet"
local buffer = require "buffer"

local cchttp = {}

function cchttp.checkURL()
    return true
end

function cchttp.request(url, post, headers)
    if not component.list("internet")() then
        return nil
    end
    internet.request(url, post, headers)
end

local streamBase = {}
function streamBase:read()
    return self.reader()
end

function streamBase:close()
    self.reader = nil --Hope sangar implemented GC
end

function cchttp.get(url, headers)
    checkArg(1, url, "string")
    
    if type(headers) == "string" or type(headers) == "number" or type(headers) == "boolean" then
        --io.stderr:write("Ignoring invalid headers")
        headers = nil
    end
    
    local reader = internet.request(url, nil, headers)
    
    local stream = setmetatable({reader = reader}, {__index = streamBase})
    local buf = buffer.new("r", stream)
    
    return {
        getResponseCode = function()return 200 end, --doable?
        readLine = function()return buf:read("*l")end,
        readAll = function()local a = buf:read("*a") buf:close() return a:gsub("[\r\n]+$", "") end,
        read = function()return buf:read(1)end,
        close = function()return buf:close()end,
    }
end

function cchttp.post(url, post, headers)
    local reader = internet.request(url, post, headers)
    
    local stream = setmetatable({reader = reader}, {__index = streamBase})
    local buf = buffer.new("r", stream)
    
    return {
        getResponseCode = function()return 200 end, --doable?
        readLine = function()return buf:read("*l")end,
        readAll = function()local a = buf:read("*a") buf:close() return a:gsub("[\r\n]+$", "") end,
        read = function()return buf:read(1)end,
        close = function()return buf:close()end,
    }
end

return cchttp
