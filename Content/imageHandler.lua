local imageHandler = {
	methodFlags = {
	
	}
}
local meta = {
	__index = { },
	__tostring = function(self)
		return self._path
	end,
	__gc = function(self)
		return os.remove(self._path)
	end,
	fromAlbum = false
}
local ImageMethods = meta.__index

--[[Doc
	~
	"Downloads an image using a linux command"
	@url string
	>Image
]]
imageHandler.fromUrl = function(url)
	local path = os.tmpname() .. (string.find(url, ".jpe?g") and ".jpg" or ".png")
	local img = { _path = path, _flags = { } }

	os.execute(string.format("curl -s %q -o %s", url, path))

	return setmetatable(img, meta)
end

local addFlag = function(self, flag, param)
	self._flags[#self._flags + 1] = flag .. (param and (" " .. param) or "")
	return self
end

local addMethod = function(name, flag, hasParam)
	imageHandler.methodFlags[name] = hasParam and 1 or 0
	ImageMethods[name] = function(self, param)
		if hasParam and not param then
			return self, "'" .. tostring(name) .. "' missing parameter."
		end
		return addFlag(self, flag, param)
	end
end

addMethod("hflip", "-flop")
addMethod("negative", "-negate")
addMethod("resize", "-resize", true)
addMethod("rotate", "-rotate", true)
addMethod("vflip", "-flip")

--[[Doc
	~
	"Applies all the Image settings in an image object"
]]
ImageMethods.apply = function(self)
	return os.execute("convert " .. self._path .. " " .. table.concat(self._flags, ' ') .. " " .. self._path)
end

return imageHandler