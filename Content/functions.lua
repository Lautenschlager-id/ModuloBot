math.percent = function(x, y, v)
	v = v or 100
	local m = x/y * v
	return math.min(m, v)
end

os.readFile = function(file, format)
	file = io.open(file, "r")
	
	format = format or "*a"
	local _file = file:read(format)
	file:close()		
	
	return _file
end

string.nickname = function(s)
	return (string.gsub(string.lower(s), "%a", string.upper, 1))
end
string.split = function(str, pat, f)
	local out = {}

	string.gsub(str, pat, function(v)
		out[#out + 1] = (not f and v or f(v))
	end)

	return out
end
string.superTrim = function(s)
	return string.match((string.gsub((string.gsub(s, "\n+", "\n")), " +", " ")), "^\n?(.*)\n?$")
end

table.clone = function(list, ignoreList)
	local out = {}

	for k, v in next, list do
		if not table.find(ignoreList, k) then
			out[k] = v
		end
	end

	return out
end
table.find = function(list, value, index, f)
	for k, v in next, list do
		local i = (type(v) == "table" and index) and v[index] or v
		if (not f and i or f(i, index)) == value then
			return true, k
		end
	end
	return false
end
table.map = function(list, f)
	local out = {}
	
	for k, v in next, list do
		out[k] = f(v)
	end
	
	return out
end
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
table.random = function(list)
	return list[math.random(#list)]
end
