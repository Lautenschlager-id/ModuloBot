--[[Doc
	"Returns the percentage of a number with another number as base."
	@x number
	@y number
	@v number*
	>number
]]
math.percent = function(x, y, v)
	v = v or 100
	local m = x/y * v
	return math.min(m, v)
end

--[[Doc
	~
	"Returns the percentage of a number with another number as base."
	@x number
	@y number
	@v number*
	>number
]]
os.readFile = function(file, format)
	file = io.open(file, "r")
	
	format = format or "*a"
	local _file = file:read(format)
	file:close()		
	
	return _file
end

--[[Doc
	"Counts how many ocurrencies of a pattern or string appears in another string."
	@str string
	@s string
	>int
]]
string.count = function(str, s)
	local _, count = string.gsub(str, s, '')
	return count
end
--[[Doc
	"Normalizes a Transformice's nickname (Xxxx)."
	@s string
	>string
]]
string.nickname = function(s)
	return (string.gsub(string.lower(s), "%a", string.upper, 1))
end
--[[Doc
	"Splits a string according to a given pattern."
	@str string
	@pat string
	@f function*
	>table
]]
string.split = function(str, pat, f)
	local out, counter = { }, 0

	for v in string.gmatch(str, pat) do
		counter = counter + 1
		out[counter] = (not f and v or f(v))
	end

	return out
end
--[[Doc
	"Trims spaces and breaklines between words."
	@s string
	>string
]]
string.superTrim = function(s)
	return string.match((string.gsub((string.gsub(s, "\n+", "\n")), " +", " ")), "^\n?(.*)\n?$")
end

--[[Doc
	"Copies a table (not deeply) ignoring given indexes."
	@list table
	@ignoreList table
	>table
]]
table.clone = function(list, ignoreList)
	local out = {}

	for k, v in next, list do
		if not table.find(ignoreList, k) then
			out[k] = v
		end
	end

	return out
end
--[[Doc
	"Verifies if a certain value exists in a table and returns the index."
	@list table
	@value string|int|boolean
	@index string|int*
	@f function*
	>boolean, string|int|nil
]]
table.find = function(list, value, index, f)
	for k, v in next, list do
		local i = (type(v) == "table" and index) and v[index] or v
		if (not f and i or f(i, index)) == value then
			return true, k
		end
	end
	return false
end
--[[Doc
	"Iters over the table inserting the value modified with a given function."
	@list table
	@f function
	>table
]]
table.map = function(list, f)
	local out = {}
	
	for k, v in next, list do
		out[k] = f(v, k)
	end
	
	return out
end
--[[Doc
	"Returns a new table containing all the values of `src` and `add`."
	@src table
	@add table
	>table
]]
table.sum = function(src, add)
	local out = { }
	
	for i = 1, #src do
		out[i] = src[i]
	end
	
	local len = #out
	for i = 1, #add do
		out[len + i] = add[i]
	end
	
	return out
end
--[[Doc
	"Returns a random value of the given table."
	@list table
	>*
]]
table.random = function(list)
	return list[math.random(#list)]
end
--[[Doc
	"Transforms a table into a string."
	@list table
	>string
]]
table.tostring = function(tbl, indent, numIndex, stop, _depth, _ref)
	if type(tbl) ~= "table" then
		return tostring(tbl)
	end

	if _depth and _depth > 1 and _ref == tbl then
		return tostring(_ref)
	end

	_depth = _depth or 1
	stop = stop or 0

	local out = { }
	local counter = 0

	local t
	for k, v in next, tbl do
		counter = counter + 1
		out[counter] = (indent and string.rep("\t", _depth) or '') .. ((type(k) ~= "number" and (string.find(k, "^[%w_]") and (k .. " = ") or ("[" .. string.format("%q", k) .. "] = ")) or numIndex and ("[" .. k .. "] = ") or ''))

		t = type(v)
		if t == "table" and not (stop > 0 and _depth >= stop) then
			out[counter] = out[counter] .. table.tostring(v, indent, numIndex, stop - 1, _depth + 1, (_ref or tbl))
		elseif t == "number" or t == "boolean" then
			out[counter] = out[counter] .. tostring(v)
		elseif t == "string" then
			out[counter] = out[counter] .. string.format("%q", v)
		else
			out[counter] = out[counter] .. "type_" .. t
		end
	end

	return "{" .. (indent and ("\n" .. table.concat(out, ",\n") .. "\n") or table.concat(out, ',')) .. (indent and string.rep("\t", _depth - 1) or '') .. "}"
end

table.createSet = function(list)
	local out = { }
	for _, v in next, list do
		out[v] = true
	end
	return out
end