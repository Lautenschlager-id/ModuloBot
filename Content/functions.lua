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
	local out = {}

	string.gsub(str, pat, function(v)
		out[#out + 1] = (not f and v or f(v))
	end)

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
		out[k] = f(v)
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
table.tostring = function(list, depth, stop)
	depth = depth or 1
	stop = stop or 0

	local out = {}
	
	for k, v in next, list do
		out[#out + 1] = string.rep("\t", depth) .. ("["..(type(k) == "number" and k or "'" .. k .. "'").."]") .. "="
		local t = type(v)
		if t == "table" then
			out[#out] = out[#out] .. ((stop > 0 and depth > stop) and tostring(v) or table.tostring(v, depth + 1, stop - 1))
		elseif t == "number" or t == "boolean" then
			out[#out] = out[#out] .. tostring(v)
		elseif t == "string" then
			out[#out] = out[#out] .. string.format("%q", v)
		else
			out[#out] = out[#out] .. "nil"
		end
	end
	
	return "{\r\n" .. table.concat(out, ",\r\n") .. "\r\n" .. string.rep("\t", depth - 1) .. "}"
end