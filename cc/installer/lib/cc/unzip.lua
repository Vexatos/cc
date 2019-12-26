--[[
ocunzip: unzip zip files in opencomputers
Copyright (c) 2015-16 GreaseMonkey

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
of the Software, and to permit persons to whom the Software is furnished to do
so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
]]

--[[
works on Lua 5.2
data card not supported at the moment
]]

local fname = ...

local outdir = "/cc/"

-- detect if we're running on OC or a native system
local sysnative = not not package.loadlib

local bit32 = bit32 or load([[return {
    band = function(a, b) return a & b end,
    bor = function(a, b) return a | b end,
    bxor = function(a, b) return a ~ b end,
    bnot = function(a) return ~a end,
    rshift = function(a, n) return a >> n end,
    lshift = function(a, n) return a << n end,
}]])()

-- readers
function readu8(fp)
	return fp:read(1):byte()
end
function readu16(fp)
	local v1 = readu8(fp)
	local v2 = readu8(fp)
	return v1 + (v2*256)
end
function readu32(fp)
	local v1 = readu16(fp)
	local v2 = readu16(fp)
	return v1 + (v2*65536)
end

-- CRC32 implementation
-- standard table lookup version
do
	local crctab = {}

	local i
	for i=0,256-1 do
		local j
		local v = i

		for j=1,8 do
			if bit32.band(v,1) == 0 then
				v = bit32.rshift(v, 1)
			else
				v = bit32.rshift(v, 1)
				v = bit32.bxor(v, 0xEDB88320)
			end
		end
		crctab[i+1] = v
	end

	function crc32(str, v)
		v = v or 0
		v = bit32.bxor(v, 0xFFFFFFFF)

		local i
		for i=1,#str do
			--print(str:byte(i))
			v = bit32.bxor(bit32.rshift(v, 8),
				crctab[bit32.bxor(bit32.band(v, 0xFF),
					str:byte(i))+1])
		end

		v = bit32.bxor(v, 0xFFFFFFFF)
		return v
	end
end

function inflate(data)
	-- we aren't using data cards here
	-- there is no zlib header in zip
	local pos = 0
	local ret = ""
	local retcomb = ""

	local function get(sz)
		local opos = pos
		assert(sz >= 1)
		if bit32.rshift(pos, 3) >= #data then error("unexpected EOF in deflate stream") end
		local v = bit32.rshift(data:byte(bit32.rshift(pos, 3)+1), bit32.band(pos, 7))
		local boffs = 0
		if sz < 8-bit32.band(pos,7) then
			pos = pos + sz
		else
			local boffs = (8-bit32.band(pos,7))
			local brem = sz - boffs
			pos = pos + boffs

			while brem > 8 do
				if bit32.rshift(pos,3) >= #data then error("unexpected EOF in deflate stream") end
				v = bit32.bor(v, bit32.lshift(
					data:byte(bit32.rshift(pos,3)+1), boffs))
				boffs = boffs + 8
				brem = brem - 8
				pos = pos + 8
			end

			if brem > 0 then
				if bit32.rshift(pos,3) >= #data then error("unexpected EOF in deflate stream") end
				v = bit32.bor(v, bit32.lshift(data:byte(bit32.rshift(pos,3)+1), boffs))
				pos = pos + brem
			end
		end
		assert(pos > opos)
		return bit32.band(v, (bit32.lshift(1,sz)-1))
	end

	local function buildhuff(tab, tablen)
		local i
		local lsort = {}

		-- categorise by length
		for i=1,15 do lsort[i] = {} end
		for i=1,tablen do
			if tab[i] ~= 0 then
				table.insert(lsort[tab[i]], i-1)
			end
		end

		-- sort each by index
		for i=1,15 do table.sort(lsort[i]) end

		-- build bit selection table
		local llim = {}
		local v = 0
		for i=1,15 do
			v = bit32.lshift(v, 1) + #lsort[i]
			--print(i, v)
			llim[i] = v
			assert(v <= bit32.lshift(1, i))
		end
		assert(v == bit32.lshift(1, 15))

		return function()
			local v = 0
			local i
			for i=1,15 do
				v = bit32.lshift(v, 1) + get(1)
				if v < llim[i] then
					return (lsort[i][1+(v-llim[i]+#lsort[i])] or
						error("lookup overflow"))
				end
			end

			error("we seem to have an issue with this huffman tree")
		end
	end

	local bfinal = false
	local btype

	local decoders = {}
	decoders[1+1] = function()
		local i

		-- literals
		local hltab = {}
		for i=0,143 do hltab[i+1] = 8 end
		for i=144,255 do hltab[i+1] = 9 end
		for i=256,279 do hltab[i+1] = 7 end
		for i=280,287 do hltab[i+1] = 8 end

		-- distances
		local hdtab = {}
		for i=0,32-1 do hdtab[i+1] = 5 end

		-- build and return
		local hltree = buildhuff(hltab, 288)
		local hdtree = buildhuff(hdtab, 32)

		return hltree, hdtree
	end
	decoders[2+1] = function()
		local i, j

		local hlit = get(5)+257
		local hdist = get(5)+1
		local hclen = get(4)+4
		--print(hlit, hdist, hclen)

		local HCMAP = {16, 17, 18, 0, 8, 7, 9, 6, 10, 5, 11, 4, 12, 3, 13, 2, 14, 1, 15}
		local hctab = {}

		-- code lengths
		for i=0,18 do hctab[i+1] = 0 end
		for i=1,hclen do
			hctab[HCMAP[i]+1] = get(3)
			--print(HCMAP[i], hctab[HCMAP[i]+1])
		end
		local hctree = buildhuff(hctab, 19)

		-- literals
		local hltab = {}
		i = 1
		while i <= hlit do
			local v = hctree()
			if v <= 15 then
				hltab[i] = v
				i = i + 1
			elseif v == 16 then
				assert(i >= 2)
				for j=1,get(2)+3 do
					hltab[i] = hltab[i-1]
					i = i + 1
				end
			elseif v == 17 then
				for j=1,get(3)+3 do
					hltab[i] = 0
					i = i + 1
				end
			elseif v == 18 then
				for j=1,get(7)+11 do
					hltab[i] = 0
					i = i + 1
				end
			else
				error("hctree decoding issue")
			end
		end
		assert(i == hlit+1)

		local hdtab = {}
		i = 1
		while i <= hdist do
			local v = hctree()
			if v <= 15 then
				hdtab[i] = v
				i = i + 1
			elseif v == 16 then
				assert(i >= 2)
				for j=1,get(2)+3 do
					hdtab[i] = hdtab[i-1]
					i = i + 1
				end
			elseif v == 17 then
				for j=1,get(3)+3 do
					hdtab[i] = 0
					i = i + 1
				end
			elseif v == 18 then
				for j=1,get(7)+11 do
					hdtab[i] = 0
					i = i + 1
				end
			else
				error("hctree decoding issue")
			end
		end
		assert(i == hdist+1)

		local hltree = buildhuff(hltab, hlit)
		local hdtree = buildhuff(hdtab, hdist)

		return hltree, hdtree
	end

	local function lzss(len, dist)
		if dist <= 3 then
			dist = dist + 1
		elseif dist <= 29 then
			-- i refuse to type this whole thing out
			local subdist = bit32.rshift((dist-4),1)
			--print(dist)
			local nd = get(subdist+1)
			dist = (1 + bit32.lshift(1,(subdist+2))
				+ bit32.lshift(bit32.band(dist,1),(subdist+1))
				+ nd)
			--print(dist, nd)
		else
			print(dist)
			error("invalid deflate distance table code")
		end

		-- TODO: optimise
		assert(dist >= 1)
		local i
		local idx = #ret-dist+1
		if idx < 1 then
			-- pull back from combined return
			ret = retcomb:sub(#retcomb+idx) .. ret
			retcomb = retcomb:sub(1,#retcomb+idx-1)
			idx = 1
		end
		assert(idx >= 1)
		assert(idx <= #ret)
		for i=1,len do
			ret = ret .. ret:sub(idx, idx)
			idx = idx + 1
		end
	end

	while not bfinal do
		ret = ""
		bfinal = (get(1) ~= 0)
		btype = get(2)
		if btype == 3 then error("invalid block mode") end
		--if sysnative then print("block", btype, bfinal) end

		if btype == 0 then
			pos = bit32.band((pos+7), bit32.bnot(7))
			local lpos = bit32.rshift(pos, 3)
			local len = data:byte(lpos+1)
			len = len + (data:byte(lpos+2)*256)
			local nlen = data:byte(lpos+3)
			nlen = nlen + (data:byte(lpos+4)*256)
			if bit32.bxor(len, nlen) ~= 0xFFFF then
				error("stored block complement check failed")
			end
			ret = data:sub(lpos+4+1, lpos+4+1+len-1)
			assert(#ret == len)
			pos = pos + 8*(4+len)
		else 

			local tfetch, tgetdist = decoders[btype+1]()

			while true do
				local v = tfetch()
				if v <= 255 then
					ret = ret .. string.char(v)
				elseif v == 256 then
					break
				elseif v >= 257 and v <= 264 then
					lzss(v-257 + 3, tgetdist())
				elseif v >= 265 and v <= 268 then
					lzss((v-265)*2 + 11 + get(1), tgetdist())
				elseif v >= 269 and v <= 272 then
					lzss((v-269)*4 + 19 + get(2), tgetdist())
				elseif v >= 273 and v <= 276 then
					lzss((v-273)*8 + 35 + get(3), tgetdist())
				elseif v >= 277 and v <= 280 then
					lzss((v-277)*16 + 67 + get(4), tgetdist())
				elseif v >= 281 and v <= 284 then
					lzss((v-281)*32 + 131 + get(5), tgetdist())
				elseif v >= 285 then
					lzss(258, tgetdist())
				else
					print(v)
					error("invalid deflate literal table code")
				end
			end
		end

		retcomb = retcomb .. ret
		if not sysnative then os.sleep(0.05) end
	end

	--print(#ret)
	return retcomb
end

assert(fname, "provide a filename as an argument")

-- check if we have a datacard
if not sysnative then
	pcall(function()
		local component = require("component")
		if component.data then
			--print("FOUND DATA CARD")
			--inflate = component.data.inflate
			print("TODO: data card support")
		end
	end)
end

infp = io.open(fname, "rb")
while true do
	-- ZIP file header (we unzip from file start here)
	local magic = infp:read(4)
	if magic ~= "PK\x03\x04" then
		-- check for central directory header
		if magic == "PK\x01\x02" then break end

		-- nope? ok, we've gone off the rails here
		error("invalid zip magic")
	end
	zver = readu16(infp)
	zflags = readu16(infp)
	zcm = readu16(infp)
	assert(zver <= 20, "we don't support features above zip 2.0")
	--print(zflags)
	assert(bit32.band(zflags, 0xF7F9) == 0, "zip relies on features we don't support (e.g. encraption)")
	--assert(bit32.band(zflags, 0xF7F1) == 0, "zip relies on features we don't support (e.g. encraption)")
	assert(zcm == 0 or zcm == 8, "we don't support stupid compression modes")
	readu32(infp) -- last modified time, date
	zcrc = readu32(infp)
	zcsize = readu32(infp)
	zusize = readu32(infp)
	zfnlen = readu16(infp)
	zeflen = readu16(infp)
	assert(zfnlen >= 1, "extracting empty file name")
	zfname = infp:read(zfnlen)
	assert(zfname:len() == zfnlen)
	zefield = infp:read(zeflen)
	assert(zefield:len() == zeflen)
	cmpdata = infp:read(zcsize)
	assert(cmpdata:len() == zcsize)

    local outfile = nil

	if zfname:find("assets/computercraft/lua/rom", 1, true) then
	    outfile = outdir..zfname:sub(string.len("assets/computercraft/lua/") + 1)
	end
	
	if outfile ~= nil then
	    ucmpdata = ((zcm == 8 and inflate(cmpdata)) or cmpdata)
	    assert(ucmpdata:len() == zusize)
	    assert(crc32(ucmpdata) == bit32.band(zcrc, 0xFFFFFFFF), "CRC mismatch")

	    if zfname:sub(-1) == "/" then
	    	os.execute("mkdir -p \""..outfile.."\"")
	    else
    		outfp = io.open(outfile, "wb")
	    	outfp:write(ucmpdata)
	    	outfp:close()
	    end
	end
end

