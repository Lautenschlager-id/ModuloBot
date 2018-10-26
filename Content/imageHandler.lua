local imageHandler = { }
local meta = {
	__name = "image",
	__index = { }
}
local ImageMethods = meta.__index

--[[Doc
	~
	"Downloads an image using a linux command"
	@url string
	>Image
]]
imageHandler.fromURL = function(url)
	local path = os.tmpname()
	local img = { _path = path, _flags = { } }

	os.execute(string.format("curl %q -o %s", url, path))

	return setmetatable(img, meta)
end

meta.__gc = function(self)
	return os.remove(self._path)
end

local addFlag = function(self, flag, param)
	self._flags[#self._flags + 1] = flag .. (param and (" " .. param) or "")
	return self
end

local addMethod = function(name, flag, hasParam)
	ImageMethods[name] = function(self, param)
		if hasParam and not param then
			return self, "'" .. tostring(name) .. "' missing parameter."
		end
		return addFlag(self, flag, param)
	end
end

addMethod("antialias", "-antialias")
addMethod("bgcolor", "-background", true)
addMethod("border", "-border", true)
addMethod("hflip", "-flop")
addMethod("negative", "-negate")
addMethod("resize", "-resize", true)
addMethod("rotate", "-rotate", true)
addMethod("scale", "-scale", true)
addMethod("vflip", "-flip")

--[[Doc
	~
	"Applies all the Image settings in an image object"
]]
ImageMethods.apply = function(self)
	return os.execute("convert " .. self._path .. " " .. table.concat(self._flags, ' ') .. " " .. self._path)
end

return imageHandler