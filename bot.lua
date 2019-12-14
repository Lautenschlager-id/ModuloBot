math.randomseed(os.time())

-- Avoid memory spam
do
	local rep = string.rep
	string.rep = function(str, n)
		return rep(str, math.min(n, 5000))
	end
end

--[[ Discordia ]]--
local discordia = require("discordia")
discordia.extensions()

local client = discordia.Client({
	cacheAllMembers = true
})
client._options.routeDelay = 0

local clock = discordia.Clock()
local minutes = 0

--[[ Lib ]]--
local http = require("coro-http")
local json = require("json")
local timer = require("timer")

local base64 = require("Content/base64")
local binBase64 = require("Content/binBase64")
local imageHandler = require("Content/imageHandler")
local utf8 = require("Content/utf8")

local miniz = require("miniz")

require("Content/functions")

--[[Doc
	"table.concat with a function that affects all the itered values."
	@tbl table
	@sep string*
	@f function*
	@i int*
	@j int*
	@iter function*
	>string
]]
local concat = function(tbl, sep, f, i, j, iter)
	local out = {}

	sep = sep or ''

	i, j = (i or 1), (j or #tbl)

	local counter = 1
	for k, v in (iter or pairs)(tbl) do
		if type(k) ~= "number" or (k >= i and k <= j) then
			if f then
				out[counter] = f(k, v)
			else
				out[counter] = tostring(v)
			end
			counter = counter + 1
		end
	end

	return table.concat(out, sep)
end
--[[Doc
	"Iters over a table in a sorted order."
	@list table
	@f function*
	>function|nil
]]
local pairsByIndexes = function(list, f)
	local out = {}
	for index in next, list do
		out[#out + 1] = index
	end
	table.sort(out, f)

	local i = 0
	return function()
		i = i + 1
		if out[i] ~= nil then
			return out[i], list[out[i]]
		end
    end
end

--[[ Enums ]]--
--[[Doc
	"User IDs with permission to access any command, anywhere.
	*[Uses Hash]"
	!table
]]
local authIds = {
	['285878295759814656'] = true
}
--[[Doc
	"Flags of the important channels that are used for specific behaviors in the bot."
	!table
]]
local channels = {
	["modules"] = "462295886857502730",
	["logs"] = "465639994690895896",
	["commu"] = "494667707510161418",
	["image"] = "462279141551636500",
	["map"] = "462279117866401792",
	["bridge"] = "499635964503785533",
	["flood"] = "465583146071490560",
	["guild"] = "462275923354451970",
	["report"] = "510448208800120842",
	["chat-log"] = "520231441985175572",
	["role-color"] = "530752494717108224",
	["top-activity"] = "530793741909491753",
	["priv-channels"] = "543094720382107659",
	["suggestions"] = "582605483836440606",
	["mod-logs"] = "586271889467506727",
	["region"] = "585174371774103582",
	["code-test"] = "474253217421721600",
	["polls"] = "595364384566673413",
	["role-log"] = "598894097419337755",
	["greetings"] = "598898246500483072"
}

local botIds = {
	["moon"] = "484182969926418434",
}
--[[Doc
	"Flags of the staff categories."
	!table
]]
local categories = {
	["467791436163842048"] = true, -- mt
	["462335892162478080"] = true, -- dev
	["462336028233957396"] = true, -- art
	["462336076476841986"] = true, -- trad
	["494665803107401748"] = true, -- map
	["465632638284201984"] = true, -- evt
	["481191678410227732"] = true, -- shelper
	["514914341380816906"] = true, -- fc
	["514914924825411586"] = true, -- math
	["526829154650554368"] = true, -- fashion
	["544935544975786014"] = true -- writer
}
--[[Doc
	"Flags of the channels that are used to list the nickname of the members."
	!table
]]
local nickList = {
	["mt"] = "560458100885291038",
	["td"] = "569606722059108392",
	["sh"] = "544936174544748587",
	["fc"] = "556869027893477376",
}
--[[Doc
	"Flags for the embed colors used in the bot."
	!table
]]
local color = {
	atelier801 = 0x2E565F,
	err = 0xE74C3C,
	interaction = 0x7DC5B6,
	lua_err = 0xC45273,
	sys = 0x36393F,
	lua = 0x272792,
	moderation = 0x9C3AAF
}
--[[Doc
	"Table of reactions used in the bot."
	!table
]]
local reactions = {
	p41 = "p41:463508055577985024",
	camera = "\xF0\x9F\x93\xB7",
	x = "\xE2\x9D\x8C",
	hand = "\xF0\x9F\x99\x8B",
	bomb = "\xF0\x9F\x92\xA3",
	boot = "\xF0\x9F\x91\xA2",
	wave = "\xF0\x9F\x91\x8B",
	star = "\xE2\xAD\x90",
	skull = "\xF0\x9F\x92\x80",
	bug = "\xF0\x9F\x90\x9B",
	eyes2 = "eyes2:499367166299340820",
	online = "online:456197711356755980",
	idle = "idle:456197711830581249",
	dnd = "dnd:456197711251636235",
	offline = "offline:456197711457419276",
	p5 = "p5:468937377981923339",
	yes = "\xE2\x9C\x85",
	arrowUp = "\xE2\x8F\xAB",
	thumbsup = "\xF0\x9F\x91\x8D",
	thumbsdown = "\xF0\x9F\x91\x8E"
}
--[[Doc
	"Flags of the bytes of the flag emojis of each community in Transformice."
	!table
]]
local countryFlags = {
	AR = "\xF0\x9F\x87\xB8\xF0\x9F\x87\xA6",
	BR = "\xF0\x9F\x87\xA7\xF0\x9F\x87\xB7",
	BG = "\xF0\x9F\x87\xA7\xF0\x9F\x87\xAC",
	CN = "\xF0\x9F\x87\xA8\xF0\x9F\x87\xB3",
	CZ = "\xF0\x9F\x87\xA8\xF0\x9F\x87\xBF",
	DE = "\xF0\x9F\x87\xA9\xF0\x9F\x87\xAA",
	EE = "\xF0\x9F\x87\xAA\xF0\x9F\x87\xAA",
	EN = "\xF0\x9F\x87\xAC\xF0\x9F\x87\xA7",
	ES = "\xF0\x9F\x87\xAA\xF0\x9F\x87\xB8",
	FI = "\xF0\x9F\x87\xAB\xF0\x9F\x87\xAE",
	FR = "\xF0\x9F\x87\xAB\xF0\x9F\x87\xB7",
	GR = "\xF0\x9F\x87\xAC\xF0\x9F\x87\xB7",
	HE = "\xF0\x9F\x87\xAE\xF0\x9F\x87\xB1",
	HR = "\xF0\x9F\x87\xAD\xF0\x9F\x87\xB7",
	HU = "\xF0\x9F\x87\xAD\xF0\x9F\x87\xBA",
	ID = "\xF0\x9F\x87\xAE\xF0\x9F\x87\xA9",
	IT = "\xF0\x9F\x87\xAE\xF0\x9F\x87\xB9",
	JP = "\xF0\x9F\x87\xAF\xF0\x9F\x87\xB5",
	KR = "\xF0\x9F\x87\xB0\xF0\x9F\x87\xB7",
	LT = "\xF0\x9F\x87\xB1\xF0\x9F\x87\xB9",
	LV = "\xF0\x9F\x87\xB1\xF0\x9F\x87\xBB",
	NL = "\xF0\x9F\x87\xB3\xF0\x9F\x87\xB1",
	NO = "\xF0\x9F\x87\xB3\xF0\x9F\x87\xB4",
	PH = "\xF0\x9F\x87\xB5\xF0\x9F\x87\xAD",
	PL = "\xF0\x9F\x87\xB5\xF0\x9F\x87\xB1",
	RO = "\xF0\x9F\x87\xB7\xF0\x9F\x87\xB4",
	RU = "\xF0\x9F\x87\xB7\xF0\x9F\x87\xBA",
	TR = "\xF0\x9F\x87\xB9\xF0\x9F\x87\xB7"
}
countryFlags.PT = countryFlags.BR
countryFlags.GB = countryFlags.EN
countryFlags.IL = countryFlags.HE
countryFlags.JA = countryFlags.JP
countryFlags.SA = countryFlags.AR
--[[Doc
	"Flags of aliases of country codes for **countryFlags**' reference."
	!table
]]
local countryFlags_Aliases = { PT = "BR", JA = "JP", IL = "HE", GB = "EN", SA = "AR" }
-- Sorry please
local communities = {
	["br"] = "\xF0\x9F\x87\xA7\xF0\x9F\x87\xB7",
	["es"] = "\xF0\x9F\x87\xAA\xF0\x9F\x87\xB8",
	["fr"] = "\xF0\x9F\x87\xAB\xF0\x9F\x87\xB7",
	["gb"] = "\xF0\x9F\x87\xAC\xF0\x9F\x87\xA7",
	["nl"] = "\xF0\x9F\x87\xB3\xF0\x9F\x87\xB1",
	["ro"] = "\xF0\x9F\x87\xB7\xF0\x9F\x87\xB4",
	["ru"] = "\xF0\x9F\x87\xB7\xF0\x9F\x87\xBA",
	["sa"] = "\xF0\x9F\x87\xB8\xF0\x9F\x87\xA6",
	["tr"] = "\xF0\x9F\x87\xB9\xF0\x9F\x87\xB7",
	["pt"] = "br",
	["en"] = "gb",
	["ar"] = "sa",
}
--[[Doc
	"Flags for **!lua** behavior, where `test` removes the logs and `cmd` executes for non-developers"
	!table
]]
local debugAction = {
	test = 0,
	cmd = 1
}
--[[Doc
	"Flags of Luvit terminal colors."
	!table
]]
local logColor = {
	gray = 40,
	red = 31,
	green = 32,
}
--[[Doc
	"The category numbers that the bot is allowed to perm.
	*[Uses Hash]"
	!table
]]
local permMaps = {
	["20"] = true,
	["21"] = true,
	["22"] = true,
	["32"] = true,
	["41"] = true,
	["42"] = true
}
--[[Doc
	"Flags of the permission levels of the commands in the bot."
	!table
]]
local permissions = discordia.enums.enum {
	public = 0, -- Never change
	has_power = 1,
	is_module = 2, -- Never change
	is_dev = 3, -- Never change
	is_art = 4,
	is_map = 5,
	is_trad = 6,
	is_fash = 7,
	is_evt = 8,
	is_writer = 9,
	is_math = 10,
	is_fc = 11,
	is_shades = 12,
	is_staff = 13,  -- Never change
	is_owner = 14,
	is_mod = 15
}

local permIcons = {
	public = ":small_orange_diamond:",
	has_power = ":small_blue_diamond:",
	is_module = "<:wheel:456198795768889344>",
	is_dev = "<:lua:468936022248390687>",
	is_art = "<:p5:468937377981923339>",
	is_map = "<:p41:463508055577985024>",
	is_trad = ":earth_americas:",
	is_fash = "<:dance:468937918115741718>",
	is_evt = "<:idea:559070151278854155>",
	is_writer = ":pencil:",
	is_math = ":triangular_ruler:",
	is_fc = "<:fun:559069782469771264>",
	is_shades = "<:illuminati:542115872328646666>",
	is_staff = ":star:",
	is_owner = ":star2:",
	is_mod = ":hammer_pick:"
}

--[[Doc
	"Permissions for specific roles that are auto-generated by the bot."
	!table
]]
local permissionOverwrites = { }
do
	-- #module
	do
		permissionOverwrites.module = { everyone = { }, staff = { }, owner = { }, module = { } }

		permissionOverwrites.module.everyone.denied = { "readMessages" }

		permissionOverwrites.module.staff = {
			allowed = { "readMessages" },
			denied = { }
		}

		permissionOverwrites.module.owner = {
			allowed = table.sum(permissionOverwrites.module.staff.allowed, {
				"sendMessages",
				"manageMessages",
				"mentionEveryone"
			}),
			denied = { }
		}
	end
	-- #module.#announcements
	do
		permissionOverwrites.announcements = { public = { }, staff = { }, module = { } }

		permissionOverwrites.announcements.public.allowed = { "readMessages" }

		permissionOverwrites.announcements.public.denied = { "sendMessages" }

		permissionOverwrites.announcements.staff = permissionOverwrites.announcements.public
	end
	-- #module.@#module
	do
		permissionOverwrites.public = { public = { } }

		permissionOverwrites.public.public.allowed = { "readMessages" }
	end
	-- community
	do
		permissionOverwrites.community = { everyone = { }, speaker = { } }

		permissionOverwrites.community.everyone.denied = { "readMessages" }

		permissionOverwrites.community.speaker.allowed = { "readMessages" }
	end
	-- tutorial channel
	do
		permissionOverwrites.tutorial = { }

		permissionOverwrites.tutorial.allowed = { "readMessages" }

		permissionOverwrites.tutorial.denied = { "sendMessages", "addReactions"	}
	end
	-- module owners and staffs cat
	do
		permissionOverwrites.owners_staffs = { }

		permissionOverwrites.owners_staffs.allowed = { "readMessages" }
	end
	-- muted
	do
		permissionOverwrites.muted = { }

		permissionOverwrites.muted.denied = { "readMessages" }
	end
	-- prj
	do
		permissionOverwrites.prj = { }

		permissionOverwrites.prj.allowed = {
			"readMessages",
			"mentionEveryone"
		}

		permissionOverwrites.prj.denied = permissionOverwrites.community.everyone.denied
	end
	-- mod
	do
		permissionOverwrites.mod = { }

		permissionOverwrites.mod.allowed = {
			"readMessages",
			"manageMessages"
		}
	end
end
--[[Doc
	"Flags of the colors for some specific role types in the server."
	!table
]]
local roleColor = {
	owner = 0x7AC9C4,
	community = 0x1ABC9C
}
--[[Doc
	"Enumeration of the special color roles."
	!table
]]
local specialRoleColor = discordia.enums.enum {
	--["462279926532276225"] = "530765845480210462", -- mt
	["462281046566895636"] = "530765846470066186", -- dev
	["462285151595003914"] = "530765853340467210", -- art
	["494665355327832064"] = "530765852296085524", -- trad
	["462329326600192010"] = "530765854174871553", -- map
	["481189370448314369"] = "530765850186219550", -- evt
	["544202727216119860"] = "544204980706476053", -- sh
	["526822896987930625"] = "530765847816568832", -- fc
	["514913541627838464"] = "530765851314356236", -- math
	["465631506489016321"] = "530765844406599680", -- fashion
	["514913155437035551"] = "530765848823201792" -- write
}
--[[Doc
	"Flags for the IDs of the important roles in the server.
	*[Indexing the ID returns the name of the role]"
	!table
]]
local roles = {
	["module member"] = "462279926532276225",
	["developer"] = "462281046566895636",
	["artist"] = "462285151595003914",
	["translator"] = "494665355327832064",
	["mapper"] = "462329326600192010",
	["event manager"] = "481189370448314369",
	["shades helper"] = "544202727216119860",
	["funcorp"] = "526822896987930625",
	["mathematician"] = "514913541627838464",
	["fashionista"] = "465631506489016321",
	["writer"] = "514913155437035551",
}
for name, id in next, table.copy(roles) do roles[id] = name end
--[[Doc
	"The staff role names by User-Friendly IDs.
	*[Indexing the name returns the User-Friendly ID]"
	!table
]]
local roleFlags = {
	[1] = "module member",
	[2] = "developer",
	[3] = "artist",
	[4] = "translator",
	[5] = "mapper",
	[6] = "event manager",
	[7] = "shades helper",
	[8] = "funcorp",
	[9] = "mathematician",
	[10] = "fashionista",
	[11] = "writer",
}
for i, name in next, table.copy(roleFlags) do roleFlags[name] = i end
--[[Doc
	"Transformice's Environment with empty functions"
	!table
]]
local envTfm = nil
do
	local trim = function(n)
		return bit.band(n, 0xFFFFFFFF)
	end

	local mask = function(width)
		return bit.bnot(bit.lshift(0xFFFFFFFF, width))
	end

	local fieldArgs = function(field, width)
		width = width or 1
		assert(field >= 0, "field cannot be negative")
		assert(width > 0, "width must be positive")
		assert(field + width <= 32, "trying to access non-existent bits")
		return field, width
	end

	local emptyFunction = function() end
	envTfm = {
		-- API
		assert = assert,
		bit32 = {
			arshift = function(x, disp)
				return math.floor(x / (2 ^ disp))
			end,
			band = bit.band,
			bnot = bit.bnot,
			bor = bit.bor,
			btest = function(...)
				return bit.band(...) ~= 0
			end,
			bxor = bit.bxor,
			extract = function(n, field, width)
				field, width = fieldArgs(field, width)
				return bit.band(bit.rshift(n, field), mask(width))
			end,
			lshift = bit.lsfhit,
			replace = function(n, v, field, width)
				field, width = fieldArgs(field, width)
				width = mask(width)
				return bit.bor(bit.band(n, bit.bnot(bit.lshift(m, f))), bit.lshift(bit.band(v, m), f))
			end,
			rshift = bit.rshift
		},
		coroutine = coroutine,
		debug = {
			disableEventLog = emptyFunction,
			disableTimerLog = emptyFunction,
			traceback = debug.traceback
		},
		error = emptyFunction,
		getmetatable = getmetatable,
		ipairs = ipairs,
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
			tan = math.tan,
			tanh = math.tanh
		},
		next = next,
		os = {
			date = os.date,
			difftime = os.difftime,
			time = os.time
		},
		pairs = pairs,
		pcall = pcall,
		print = print,
		rawequal = rawequal,
		rawget = rawget,
		rawlen = rawlen,
		rawset = rawset,
		select = select,
		setmetatable = setmetatable,
		string = {
			byte = string.byte,
			char = string.char,
			dump = string.dump,
			find = string.find,
			format = string.format,
			gmatch = string.gmatch,
			gsub = string.gsub,
			len = string.len,
			lower = string.lower,
			match = string.match,
			rep = string.rep,
			reverse = string.reverse,
			sub = string.sub,
			upper = string.upper
		},
		system = {
			bindKeyboard = emptyFunction,
			bindMouse = emptyFunction,
			disableChatCommandDisplay = emptyFunction,
			exit = emptyFunction,
			giveEventGift = emptyFunction,
			loadFile = emptyFunction,
			loadPlayerData = emptyFunction,
			newTimer = emptyFunction,
			removeTimer = emptyFunction,
			saveFile = emptyFunction,
			savePlayerData = emptyFunction
		},
		table = {
			concat = table.concat,
			foreach = table.foreach,
			foreachi = table.foreachi,
			insert = table.insert,
			pack = table.pack,
			remove = table.remove,
			sort = table.sort,
			unpack = table.unpack
		},
		tfm = {
			enum = {
				emote = {
					dance = 0,
					laugh = 1,
					cry = 2,
					kiss = 3,
					angry = 4,
					clap = 5,
					sleep = 6,
					facepaw = 7,
					sit = 8,
					confetti = 9,
					flag = 10,
					marshmallow = 11,
					selfie = 12,
					highfive = 13,
					highfive_1 = 14,
					highfive_2 = 15,
					partyhorn = 16,
					hug = 17,
					hug_1 = 18,
					hug_2 = 19,
					jigglypuff = 20,
					kissing = 21,
					kissing_1 = 22,
					kissing_2 = 23,
					carnaval = 24,
					rockpaperscissors = 25,
					rockpaperscissors_1 = 26,
					rockpaperscissor_2 = 27
				},
				ground = {
					wood = 0,
					ice = 1,
					trampoline = 2,
					lava = 3,
					chocolate = 4,
					earth = 5,
					grass = 6,
					sand = 7,
					cloud = 8,
					water = 9,
					stone = 10,
					snow = 11,
					rectangle = 12,
					circle = 13,
					invisible = 14,
					web = 15,
				},
				particle = {
					whiteGlitter = 0,
					blueGlitter = 1,
					orangeGlitter = 2,
					cloud = 3,
					dullWhiteGlitter = 4,
					heart = 5,
					bubble = 6,
					tealGlitter = 9,
					spirit = 10,
					yellowGlitter = 11,
					ghostSpirit = 12,
					redGlitter = 13,
					waterBubble = 14,
					plus1 = 15,
					plus10 = 16,
					plus12 = 17,
					plus14 = 18,
					plus16 = 19,
					meep = 20,
					redConfetti = 21,
					greenConfetti = 22,
					blueConfetti = 23,
					yellowConfetti = 24,
					diagonalRain = 25,
					curlyWind = 26,
					wind = 27,
					rain = 28,
					star = 29,
					littleRedHeart = 30,
					littlePinkHeart = 31,
					daisy = 32,
					bell = 33,
					egg = 34,
					projection = 35,
					mouseTeleportation = 36,
					shamanTeleportation = 37,
					lollipopConfetti = 38,
					yellowCandyConfetti = 39,
					pinkCandyConfetti = 40
				},
				shamanObject = {
					arrow = 0,
					littleBox = 1,
					box = 2,
					littleBoard = 3,
					board = 4,
					ball = 6,
					trampoline = 7,
					anvil = 10,
					cannon = 17,
					bomb = 23,
					orangePortal = 26,
					bluePortal = 26,
					balloon = 28,
					blueBalloon = 28,
					redBalloon = 29,
					greenBalloon = 30,
					yellowBalloon = 31,
					rune = 32,
					chicken = 33,
					snowBall = 34,
					cupidonArrow = 35,
					apple = 39,
					sheep = 40,
					littleBoardIce = 45,
					littleBoardChocolate = 46,
					iceCube = 54,
					cloud = 57,
					bubble = 59,
					tinyBoard = 60,
					companionCube = 61,
					stableRune = 62,
					balloonFish = 65,
					longBoard = 67,
					triangle = 68,
					sBoard = 69,
					paperPlane = 80,
					rock = 85,
					pumpkinBall = 89,
					tombstone = 90,
					paperBall = 95
				}
			},
			exec = {
				addConjuration = emptyFunction,
				addImage = emptyFunction,
				addJoint = emptyFunction,
				addPhysicObject = emptyFunction,
				addShamanObject = emptyFunction,
				bindKeyboard = emptyFunction,
				changePlayerSize = emptyFunction,
				chatMessage = emptyFunction,
				disableAfkDeath = emptyFunction,
				disableAllShamanSkills = emptyFunction,
				disableAutoNewGame = emptyFunction,
				disableAutoScore = emptyFunction,
				disableAutoShaman = emptyFunction,
				disableAutoTimeLeft = emptyFunction,
				disableDebugCommand = emptyFunction,
				disableMinimalistMode = emptyFunction,
				disableMortCommand = emptyFunction,
				disablePhysicalConsumables = emptyFunction,
				disablePrespawnPreview = emptyFunction,
				disableWatchCommand = emptyFunction,
				displayParticle = emptyFunction,
				explosion = emptyFunction,
				giveCheese = emptyFunction,
				giveConsumables = emptyFunction,
				giveMeep = emptyFunction,
				giveTransformations = emptyFunction,
				killPlayer = emptyFunction,
				linkMice = emptyFunction,
				lowerSyncDelay = emptyFunction,
				moveObject = emptyFunction,
				movePlayer = emptyFunction,
				newGame = emptyFunction,
				playEmote = emptyFunction,
				playerVictory = emptyFunction,
				removeCheese = emptyFunction,
				removeImage = emptyFunction,
				removeJoint = emptyFunction,
				removeObject = emptyFunction,
				removePhysicObject = emptyFunction,
				respawnPlayer = emptyFunction,
				setAutoMapFlipMode = emptyFunction,
				setGameTime = emptyFunction,
				setNameColor = emptyFunction,
				setPlayerScore = emptyFunction,
				setRoomMaxPlayers = emptyFunction,
				setRoomPassword = emptyFunction,
				setShaman = emptyFunction,
				setShamanMode = emptyFunction,
				setUIMapName = emptyFunction,
				setUIShamanName = emptyFunction,
				setVampirePlayer = emptyFunction,
				snow = emptyFunction
			},
			get = {
				misc = {
					apiVersion = 0.27,
					transformiceVersion = 5.86
				},
				room = {
					community = "en",
					currentMap = 0,
					maxPlayers = 50,
					mirroredMap = false,
					name = "en-#lua",
					objectList = {
						[1] = {
							angle = 0,
							baseType = 2,
							colors = {
								0xFF0000,
								0xFF00,
								0xFF
							},
							ghost = false,
							id = 1,
							type = 203,
							vx = 0,
							vy = 0,
							x = 400,
							y = 200
						}
					},
					passwordProtected = false,
					playerList = {
						["Tigrounette#0001"] = {
							community = "en",
							gender = 0,
							hasCheese = false,
							id = 0,
							inHardMode = 0,
							isDead = true,
							isFacingRight = true,
							isInvoking = false,
							isJumping = false,
							isShaman = false,
							isVampire = false,
							look = "1;0,0,0,0,0,0,0,0,0",
							movingLeft = false,
							movingRight = false,
							playerName = "Tigrounette#0001",
							registrationDate = 0,
							score = 0,
							shamanMode = 0,
							spouseId = 0,
							spouseName = "Melibelulle#0001",
							title = 0,
							tribeId = 0,
							tribeName = "Les Populaires",
							vx = 0,
							vy = 0,
							x = 0,
							y = 0
						}
					},
					uniquePlayers = 2,
					xmlMapInfo = {
						author = "Tigrounette#0001",
						mapCode = 184924,
						permCode = 1,
						xml = "<C><P /><Z><S /><D /><O /></Z></C>"
					}
				}
			}
		},
		tonumber = tonumber,
		tostring = tostring,
		type = type,
		ui = {
			addPopup = emptyFunction,
			addTextArea = emptyFunction,
			removeTextArea = emptyFunction,
			setMapName = emptyFunction,
			setShamanName = emptyFunction,
			showColorPicker = emptyFunction,
			updateTextArea = emptyFunction
		},
		xpcall = xpcall,

		-- Events
		eventChatCommand = emptyFunction,
		eventChatMessage = emptyFunction,
		eventEmotePlayed = emptyFunction,
		eventFileLoaded = emptyFunction,
		eventFileSaved = emptyFunction,
		eventKeyboard = emptyFunction,
		eventMouse = emptyFunction,
		eventLoop = emptyFunction,
		eventNewGame = emptyFunction,
		eventNewPlayer = emptyFunction,
		eventPlayerDataLoaded = emptyFunction,
		eventPlayerDied = emptyFunction,
		eventPlayerGetCheese = emptyFunction,
		eventPlayerLeft = emptyFunction,
		eventPlayerMeep = emptyFunction,
		eventPlayerVampire = emptyFunction,
		eventPlayerWon = emptyFunction,
		eventPlayerRespawn = emptyFunction,
		eventPopupAnswer = emptyFunction,
		eventSummoningStart = emptyFunction,
		eventSummoningCancel = emptyFunction,
		eventSummoningEnd = emptyFunction,
		eventTextAreaCallback = emptyFunction,
		eventColorPicked = emptyFunction
	}

	envTfm.bit32.lrotate = function(x, disp)
		if disp == 0 then
			return x
		elseif disp < 0 then
			return bit.rrotate(x, -disp)
		else
			disp = bit.band(disp, 31)
			x = trim(x)
			return trim(bit.bor(bit.lshift(x, disp), bit.rshift(x, (32 - disp))))
		end
	end
	envTfm.bit32.rrotate = function(x, disp)
		if disp == 0 then
			return x
		elseif disp < 0 then
			return bit.lrotate(x, -disp)
		else
			disp = bit.band(disp, 31)
			x = trim(x)
			return trim(bit.bor(bit.rshift(x, disp), bit.lshift(x, (32 - disp))))
		end
	end
	envTfm.tfm.get.room.playerList["Pikashu#0001"] = envTfm.tfm.get.room.playerList["Tigrounette#0001"]
	envTfm._G = envTfm
end
--[[Doc
	~
	"Flags for API tokens that the bot uses."
	!table
]]
local tokens = {
	discdb = os.readFile("Content/db_token.txt", "*l"),
	fixer = os.readFile("Content/fixer_token.txt", "*l"),
	mashape = os.readFile("Content/mashape_token.txt", "*l"),
	openweather = os.readFile("Content/openweathermap_token.txt", "*l"),
	imgur = os.readFile("Content/imgur_token.txt", "*l")
}
local token_whitelist = {
	discdb = "http://discbotdb%.000webhostapp%.com",
	fixer = "http://data%.fixer%.io/",
	mashape = "https://.-%.p%.mashape%.com",
	openweather = "http://api%.openweathermap%.org/",
	imgur = "https://i?%.?imgur.com/",
	math = "https://math%.p%.mashape%.com/image"
}
--[[Doc

]]
local currentAvatar
local botAvatars = { }

local MOD_ROLE = "585148219395276801"
local MYCITY_INVITE_OBJECT

--[[ System ]]--
--[[Doc
	~
	"All the bot commands."
	!table
]]
local commands = {}
--[[Doc
	~
	"Bot behavior in specific channels. (IO)"
	!table
]]
local channelBehavior = {}
--[[Doc
	~
	"Bot behavior in specific channels when an reaction is added or removed."
	!table
]]
local channelReactionBehavior = {}

local devENV, moduleENV = {}, {}
--[[Doc
	"The restrictions for the admin's environment in **!lua**."
	!table
]]
local devRestrictions = { "_G", "getfenv", "setfenv" }
--[[Doc
	"The restrictions for the developers' environment in **!lua**."
	!table
]]
local moduleRestrictions = { "debug", "dofile", "io", "load", "loadfile", "loadstring", "jit", "module", "p", "package", "process", "require", "os" }

--[[Doc
	"Global metamethods used in many parts of the system.
	1. **__add(tbl, new)** ~> Adds two tables."
	!table
]]
local meta = {
	__add = function(this, new)
		if type(new) ~= "table" then return this end
		--[[
		local tbl = table.deepcopy(this)
		for k, v in next, new do
			tbl[k] = v
		end

		local metatatable = getmetatable(this)
		if type(metatatable) ~= "table" then
			metatatable = { }
		end
		metatatable.__add = meta.__add
		return setmetatable(tbl, metatatable)
		]]
		for k, v in next, new do
			this[k] = v
		end
		return this
	end
}

--[[Doc
	"The data of the modules in the server."
	!table
]]
local modules = {}
--[[Doc
	"The global commands made by users in the server."
	!table
]]
local globalCommands = {}
--[[Doc
	"The channel activity control."
	!table
]]
local activeChannels = {}
local lastMemberTexting = {}
--[[Doc
	"The member activity control."
	!table
]]
local activeMembers = {}
local memberTimers = {}
--[[Doc
	"The profile data of the members in the server."
	!table
]]
local memberProfiles = {}
--[[
	"Profile structure for the **!edit** command."
	!table
]]
local profileStruct = { }
do
	profileStruct = {
		since = {
			index = 1,
			type = "string",
			format = { "^%d?%d/%d?%d/%d%d%d%d$", "^%d?%d/%d?%d$" },
			valid = function(date)
				local day, month, year = string.match(date, "^(%d+)/(%d+)/(%d+)$")
				if not year then
					day, month = string.match(date, "^(%d+)/(%d+)$")
				end
				if not day then
					return false
				end

				local nDay, nMonth = tonumber(day), tonumber(month)
				return (nDay > 0 and nDay < 32 and nMonth > 0 and nMonth < 13), string.format("%02d/%02d" .. (year and "/%04d" or ""), nDay, nMonth, tonumber(year))
			end,
			description = "The date since you joined the Module Team (dd/mm[/yyyy])."
		},
		hosting = {
			index = 1,
			type = "number",
			min = 0,
			max = 20,
			description = "The quantity of modules you currently host."
		},
		modules = {
			index = 2,
			type = "number",
			min = 0,
			max = 50,
			description = "The quantity of modules you developed."
		},
		github = {
			index = 2,
			type = "string",
			min = 3,
			valid = function(x)
				return string.find(x, "^[%w%-]+$") and (http.request("GET", "https://github.com/" .. x)).reason == "OK"
			end,
			description = "The name of your GitHub account."
		},
		deviantart = {
			index = 3,
			type = "string",
			min = 3,
			valid = function(x)
				return string.find(x, "^[%w%-]+$") and (http.request("GET", "https://www.deviantart.com/" .. x, {
					{ "user-agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/70.0.3538.77 Safari/537.36" }
				})).reason == "OK"
			end,
			description = "The name of your DeviantArt account."
		},
		perms = {
			index = 5,
			type = "number",
			min = 0,
			max = 200,
			description = "The quantity of high permed maps you currently have."
		},
		trad = {
			index = 4,
			type = "number",
			min = 0,
			max = 200,
			description = "The approximate amount of modules and Lua projects you have helped to translate."
		},
		evt = {
			index = 6,
			type = "number",
			min = 0,
			max = 20,
			description = "The quantity of Lua Events you have developed or participated significantly."
		},
		status = {
			type = "string",
			min = 3,
			max = 125,
			description = "A phrase."
		},
		gender = {
			type = "number",
			min = 0,
			max = 1,
			description = "Your gender (0 = Male, 1 = Female)."
		},
		nickname = {
			type = "string",
			min = 3,
			max = 25,
			valid = function(x)
				x = string.gsub(string.lower(x), "%a", string.upper, 1)

				local pattern = "^[%+%a][%w_]+#%d%d%d%d$"
				if not string.find(x, '#') then
					x = x .. "#0000"
				end

				for k, v in next, memberProfiles do
					if v.nickname == x then
						return false
					end
				end

				return string.find(x, pattern), x
			end,
			description = "Your nickname on Transformice."
		},
		wattpad = {
			index = 11,
			type = "string",
			min = 6,
			max = 20,
			valid = function(x)
				return string.find(x, "^%w+$") and (http.request("GET", "https://www.wattpad.com/user/" .. x)).reason == "OK"
			end,
			description = "The name of your Wattpad account."
		},
		time = {
			type = "string",
			valid = function(code, msg)
				local index
				code, index = string.match(code, "^(%a%a) *(%d*)$")
				if not code then
					return false
				end
				index = tonumber(index) or 1

				local data = commands["timezone"].f(msg, code, nil, true)
				if not data then
					return false
				end

				if #data == 1 then
					return true
				end

				return true, code .. (data[index] and index or 1)
			end,
			description = "Your timezone (country_code [index]). `index can be a number associated to the index number displayed in !timezone code`"
		},
		insta = {
			type = "string",
			valid = function(x)
				return string.find(x, "^%S+$") and (http.request("GET", "https://www.instagram.com/" .. x .. "/")).reason == "OK"
			end,
			description = "The name of your Instagram account."
		},
	}
	profileStruct.bday = {
		type = "string",
		format = profileStruct.since.format,
		valid = profileStruct.since.valid,
		description = "Your birthday date (dd/mm[/yyyy])."
	}
end
--[[Doc
	~
	"Flags of the country currency codes used in the command **!coin**."
	!table
]]
local currency = {}

local playingAkinator = {
	__REACTIONS = {"\x31\xE2\x83\xA3", "\x32\xE2\x83\xA3", "\x33\xE2\x83\xA3", "\x34\xE2\x83\xA3", "\x35\xE2\x83\xA3", "\xE2\x8F\xAA", ok = "\xF0\x9F\x86\x97"}
}
--[[Doc
	~
	"Modulo form-data request boundaries"
	!table
]]
local boundaries = { }
do
	boundaries[1] = "ModuloBot_" .. os.time()
	boundaries[2] = "--" .. boundaries[1]
	boundaries[3] = boundaries[2] .. "--"

end

local polls = {
	__REACTIONS = { "\x31\xE2\x83\xA3", "\x32\xE2\x83\xA3" }
}

local toDelete = setmetatable({}, {
	__newindex = function(list, index, value)
		if value then
			if value.channel then value = { value } end

			value = table.map(value, function(l) return l.id end)
			rawset(list, index, value)
		end
	end,
})

--[[@
	~
	"The dev data to be used in !gcmd"
	!table
]]
local cmdData = { }

--[[@
	~
	"The server activity used in !serveractivity"
	!table
]]
local serverActivity = { }

local title = { _id = { } }

--[[ Functions ]]--
local buildMessage = function(msg, message)
	local memberName
	if message then
		memberName = message.guild:getMember(msg.author.id)
		memberName = memberName and memberName.name or msg.author.tag
	end

	local embed = {
		color = color.sys,

		author = memberName and {
			name = memberName,
			icon_url = msg.author.avatarURL
		} or nil,
		description = (msg.embed and msg.embed.description) or msg.content,

		fields = {
			{
				name = "Link",
				value = "[Click here](" .. tostring(msg.link) .. ")"
			}
		},

		footer = {
			text = "In " .. (msg.channel.category and (msg.channel.category.name .. ".#") or "#") .. msg.channel.name,
		},
		timestamp = string.gsub(msg.timestamp, ' ', ''),
	}

	local img = (msg.attachment and msg.attachment.url) or (msg.embed and msg.embed.image and msg.embed.image.url)
	if img then embed.image = { url = img } end

	return embed
end

--[[Doc
	"Encodes a string in the HTML format. Escapes all the characters."
	@url string
	>string
]]
local encodeUrl = function(url)
	local out, counter = {}, 0

	for letter in string.gmatch(url, '.') do
		counter = counter + 1
		out[counter] = string.upper(string.format("%02x", string.byte(letter)))
	end

	return '%' .. table.concat(out, '%')
end
--[[Doc
	"Transforms Shaman Experience into Level, also the remaining experience and how many is needed for the next level."
	@xp string
	>int, int, int
]]
local expToLvl = function(xp)
	local last, total, level, remain, need = 30, 0, 0, 0, 0
	for i = 1, 200 do
		local nlast = last + (i - 1) * ((i >= 1 and i <= 30) and 2 or (i <= 60 and 10 or (i <= 200 and 15 or 15)))
		local ntotal = total + nlast

		if ntotal >= xp then
			level, remain, need = i - 1, xp - total, ntotal - xp
			break
		else
			last, total = nlast, ntotal
		end
	end

	return level, remain, need
end

local fixHtml
fixHtml = function(str, link)
	link = link or ''
	str = str:gsub("<(.-)>(.-)</%1>", function(html, content)
		if html == 'b' then
        	return "**" .. fixHtml(content, link) .. "**"
        elseif html == 'i' then
        	return "*" .. fixHtml(content, link) .. "*"
        elseif html == 'u' then
        	return "__" .. fixHtml(content, link) .. "__"
		end
		return fixHtml(content, link)
	end)
	str = str:gsub("<a href=\"(.-)\".->(.-)</a>", function(href, content)
		if string.sub(href, 1, 1) == '/' then
			href = link .. href
		end
		return "[" .. content .. "](" .. string.gsub(href, "%)", "\\)") .. ")"
	end)
	str = str:gsub("&amp;", '&')
	str = str:gsub("&lt;", '<')
	str = str:gsub("&quot;", '\"')
	str = str:gsub("&#(%d+);", string.char)
	str = str:gsub("<br ?/?>", '\n')

	return str
end

--[[Doc
	"Returns the years between the current date and another date."
	@date string
	>int
]]
local getAge = function(date)
	local day, month, year = string.match(date, "(%d+)/(%d+)/(%d+)")
	day, month, year = tonumber(day), tonumber(month), tonumber(year)

	local cDay, cMonth, cYear = tonumber(os.date("%d")), tonumber(os.date("%m")), tonumber(os.date("%Y"))

	return (year <= cYear and (((month > cMonth or month == cMonth and day > cDay) and (cYear - year - 1) or (month == cMonth and day <= cDay or month < cMonth) and (cYear - year))) or 0)
end
--[[Doc
	"Splits a string in a command-generator format (script, content, title, and description)."
	@str string
	>string|nil, string|nil, string|nil, string|nil
]]
local getCommandFormat = function(str)
	local script = string.match(str, "script ?(`.+`+)")
	local content = string.match(str, "value ?%[%[(.-)%]%]")
	local title = string.match(str, "title ?%[%[(.-)%]%]")
	local description = string.match(str, "description ?%[%[(.-)%]%]")
	return script, content, title, description
end
--[[Doc
	"Creates the executable function given by the command-generator format (script, content, title, and description)."
	@message Discordia.Message
	@script string*
	@content string*
	@title string*
	@description string*
	>table { [desc], [embed], [script] }
]]
local getCommandTable = function(message, script, content, title, description)
	if script then
		script = commands["lua"].f(message, script, nil, debugAction.test)
		if not script then
			return "Invalid lua code."
		end
	end

	title = ((title and title ~= '') and string.trim(title) or nil)
	description = ((description and description ~= '') and string.trim(description) or nil)
	content = ((content and content ~= '') and string.trim(content) or nil)
	local url = ((message.attachment and message.attachment.url) and message.attachment.url or nil)
	if not url then
		if not title and not description and (script and #script < 4) then
			return "You cannot create an empty command."
		end
	end

	return {
		info = description, -- About the command
		script = (script or nil), -- To be executed during the command call
		title = title, -- Embed title
		desc = content, -- Embed description
		url = url -- Embed image
	}	
end
--[[Doc
	~
	"Gets a database content."
	@fileName string
	@raw boolean*
	>table|string
]]
local getDatabase = function(fileName, raw, decodeBase64)
	local head, body = http.request("GET", "http://discbotdb.000webhostapp.com/get?k=" .. tokens.discdb .. "&f=" .. fileName)
	body = string.gsub(body, "%(%(12%)%)", '+')

	if decodeBase64 then
		body = base64.decode(body)
	end
	local out = (raw and body or json.decode(body))

	if not body or not out then
		error("Database issue -> " .. tostring(fileName))
	end

	return out
end
--[[Doc
	"Gets the Transformice nickname of a member based on its Discord id"
	@list int
	@member int
	>string|nil
]]
local getNick = function(list, member)
	local channel = client:getChannel(list)
	if tonumber(member) then
		member = channel.guild:getMember(member)
	end

	for msg in channel:getMessages():iter() do
		if string.find(msg.content, "^<@!?" .. member.id .. ">") then
			return string.match(msg.content, "= (%S+)")
		end
	end
	return member.name
end
--[[Doc
	"Gets the Discord nickname of a transformice player based on its nickname"
	@list int
	@name string
	>table|nil
]]
local getDiscMember = function(list, name)
	local channel = client:getChannel(list)
	name = string.nickname(name)
	if string.find(name, "#0000", -6, -1, true) then
		name = string.sub(name, 1, -6)
	end

	for msg in channel:getMessages():iter() do
		if string.find(msg.content, "= " .. name) then
			local id = string.match(msg.content, "^<@!?(%d+)>")
			return channel.guild:getMember(id)
		end
	end
end
--[[Doc
	"Generates a string to represent a rate in the format `[| ] 50%`"
	@value number
	@of number*
	@max number*
	>string
]]
local getRate = function(value, of, max)
	of = of or 10
	max = max or 10

	local rate = math.min(max, (value * (max / of)))
	return string.format("`[%s%s] %.2f%%`", string.rep('|', rate), string.rep(' ', max - rate), math.percent(value, of))
end

local getRoleOrder = function(member)
	local roles = member.roles:toArray("position")
	return roles, #roles
end

local getMycityInviteObject = function()
	local invites = { }
	for invite in client:getGuild(channels["guild"]):getInvites():iter() do
		if invite.code == "QPyBwUh" then
			return invite
		end
	end
end

--[[Doc
	"Verifies if an user has permission over a specific permission flag."
	@permission int
	@member Discordia.Guild.Member
	@message Discordia.Message*
	>boolean|nil
]]
local hasPermission = function(permission, member, message)
	local auth = false
	if not permission or not member then return auth end

	if permission == permissions.public then
		return true
	elseif permission == permissions.has_power then
		local highest, len = getRoleOrder(member)
		if len == 0 then
			highest = { member.guild.defaultRole }
			len = 1
		end

		if highest[len].id == MOD_ROLE.id then
			len = len - 1
		end
		highest = highest[len].id
		return not not (specialRoleColor(highest) or roles[highest])
	elseif permission == permissions.is_module then
		return member:hasRole(roles["module member"])
	elseif permission == permissions.is_dev then
		return member:hasRole(roles["developer"])
	elseif permission == permissions.is_art then
		return member:hasRole(roles["artist"])
	elseif permission == permissions.is_map then
		return member:hasRole(roles["mapper"])
	elseif permission == permissions.is_trad then
		return member:hasRole(roles["translator"])
	elseif permission == permissions.is_fash then
		return member:hasRole(roles["fashionista"])
	elseif permission == permissions.is_evt then
		return member:hasRole(roles["event manager"])
	elseif permission == permissions.is_writer then
		return member:hasRole(roles["writer"])
	elseif permission == permissions.is_math then
		return member:hasRole(roles["mathematician"])
	elseif permission == permissions.is_fc then
		return member:hasRole(roles["funcorp"])
	elseif permission == permissions.is_shades then
		return member:hasRole(roles["shades helper"])
	elseif permission == permissions.is_mod then
		return member:hasRole(MOD_ROLE.id)
	elseif permission == permissions.is_staff or permission == permissions.is_owner then
		if not message then return auth end

		local module = message.channel.category and string.lower(message.channel.category.name) or nil
		if not module then return auth end

		local c = (permission == permissions.is_owner and "★ " or "⚙ ")

		return not not member.roles:find(function(role)
			return string.find(string.lower(role.name), "^" .. c .. module .. "$")
		end)
	end
end
--[[Doc
	"Converts HTML to Discord Markdown"
	@str string
	>string
]]
local htmlToMarkdown = function(str)
    str = string.gsub(str, "&#(%d+);", function(dec) return string.char(dec) end)
    str = string.gsub(str, '<span style="(.-);">(.-)</span>', function(x, content)
        local markdown = ""
        if x == "font-weight:bold" then
            markdown = "**"
        elseif x == "font-style:italic" then
            markdown = '_'
        elseif x == "text-decoration:underline" then
            markdown = "__"
        elseif x == "text-decoration:line-through" then
            markdown = "~~"
        end
        return markdown .. content .. markdown
    end)
    str = string.gsub(str, '<p style="text-align:.-;">(.-)</p>', "%1")
    str = string.gsub(str, '<blockquote.->(.-)<div>(.-)</div></blockquote>', function(name, content)
		local m = string.match(name, "<small>(.-)</small>")
        return (m and ("`" .. m .. "`\n") or "") .. "```\n" .. (#content > 50 and string.sub(content, 1, 50) .. "..." or content) .. "```"
    end)
    str = string.gsub(str, '<a href="(.-)".->(.-)</a>', "[%2](%1)")
    str = string.gsub(str, "<br ?/?>", "\n")
    str = string.gsub(str, "&gt;", '>')
    str = string.gsub(str, "&lt;", '<')
    str = string.gsub(str, "&quot;", "\"")
    str = string.gsub(str, "&laquo;", '«')
    str = string.gsub(str, "&raquo;", '»')
	str = string.gsub(str, '<div class="cadre cadre%-code">(.-)<div class="contenu.-<pre class="colonne%-lignes%-code">(.-)</pre></div></div>', function(language, code)
		language = string.match(language, '<div class="indication%-langage%-code">(.-) code</div><hr/>') or ''
		code = string.gsub(code, "<span .->(.-)</span>", "%1")
		return "```" .. language .. "\n" .. code .. "```"
	end)
    return str
end

--[[Doc
	~
	"Sends a console log."
	@category string|number
	@text string|number
	@color int
]]
local log = function(category, text, color)
	print(os.date("%Y-%m-%d %H:%M:%S") .. " | \27[1;" .. color .. "m[" .. category .. "]\27[0m\t| " .. text)
end

--[[Doc
	"Gets the current moon phase"
	>int
]]
local moonPhase = function()
	-- http://jivebay.com/calculating-the-moon-phase/
	local day, month, year = tonumber(os.date("%d")), tonumber(os.date("%m")), tonumber(os.date("%Y"))

	if month < 3 then
		year = year - 1
		month = month + 12
	end
	month = month + 1

	local Y = 365.25 * year
	local M = 30.6 * month
	local daysElapsed = (Y + M + day - 694039.09) / 29.5305882
	daysElapsed = math.floor(((daysElapsed % 1) * 8) + .5)

	return bit.band(daysElapsed, 7) + 1
end

local normalizeDiscriminator
--[[Doc
	"Normalizes a Transformice's nickname's discriminator, removing the `#0000` and highlighting `#xxxx`."
	@discriminator string
	>string
]]
normalizeDiscriminator = function(discriminator)
	return #discriminator > 5 and (string.gsub(discriminator, "#%d%d%d%d", normalizeDiscriminator, 1)) or (discriminator == "#0000" and '' or "`" .. discriminator .. "`")
end

local addServerActivity = function(x, sub)
	local today = os.date("%d/%m/%Y")
	if not serverActivity[today] then
		serverActivity[today] = {
			l = { }, -- Member logs
			c = { 0, 0 }, -- Counter
			b = { 0, 0 }, -- Commands
			m = { 0, 0 } -- Members flow (Joined, left)
		}
	end

	sub = (sub and -1 or 1)

	local tx = type(x)
	if tx == "boolean" then -- Command [true = bot, false = global]
		local id = (x and 1 or 2)
		serverActivity[today].b[id] = serverActivity[today].b[id] + sub
	elseif tx == "number" then -- New/Leave Members
		serverActivity[today].m[x] = serverActivity[today].m[x] + sub
	elseif x then -- Tbl
		serverActivity[today].l[x.id] = true -- Thinking
		local id = (hasPermission(permissions.has_power, x) and 2 or 1)
		serverActivity[today].c[id] = serverActivity[today].c[id] + sub
	end
end

local printf = function(...)
	local out = { }
	for arg = 1, select('#', ...) do
		out[arg] = tostring(select(arg, ...))
	end
	return table.concat(out, "\t")
end

local removeAccents
do
	local letters = {
		["a"] = "áàâäãå",
		["e"] = "éèêë",
		["i"] = "íìîï",
		["o"] = "óòôöõ",
		["u"] = "úùûü",
		["c"] = 'ç',
		["n"] = 'ñ',
		["y"] = "ýÿ"
	}
	--[[Doc
		"Removes the accents in the string"
		@str string
		>stirng
	]]
	removeAccents = function(str)
		for s = 1, 2 do
			local f = (s == 1 and string.lower or string.upper)
			for letter, repl in next, letters do
				str = string.gsub(str, "[" .. f(repl) .. "]", f(letter))
			end
		end
		return str
	end
end

--[[Doc
	~
	"Saves a database."
	@fileName string
	@db table|string
	>boolean
]]
local save = function(fileName, db, raw, encodeBase64)
	db = (raw and tostring(db) or json.encode(db))
	if encodeBase64 then
		db = base64.encode(db)
	end
	db = string.gsub(db, "%+", "((12))")

	local head, body = http.request("POST", "http://discbotdb.000webhostapp.com/set?k=" .. tokens.discdb .. "&f=" .. fileName, {
		{ "Content-Type", "application/x-www-form-urlencoded" }
	}, "d=" .. db)

	return body == "true"
end

local saveGlobalCommands = function()
	local toJson = base64.encode(json.encode(globalCommands))
	local _1 = save("b_gcommands", string.sub(toJson, 1, 70000), true)
	local _2 = save("b_gcommands_2", string.sub(toJson, 70001), true)
	return _1, _2
end
--[[Doc
	~
	"Sends a message error in the channel."
	@message Discordia.Message
	@command string
	@err stirng
	@description string*
]]
local sendError = function(message, command, err, description)
	toDelete[message.id] = message:reply({
		content = "<@!" .. message.author.id .. ">",
		embed = {
			color = color.err,
			title = "Command [" .. command .. "] => " .. err,
			description = description
		}
	})
end
--[[Doc
	~
	"Sends allowed and denied permissions at the same time to the server."
	@permission Discordia.Permissions
	@allowed table
	@denied table
]]
local setPermissions = function(permission, allowed, denied)
	local o_allowed = discordia.Permissions()
	local o_denied = discordia.Permissions()

	o_allowed:enable(table.unpack(allowed))
	o_denied:enable(table.unpack(denied))

	permission:setPermissions(o_allowed, o_denied)
end
--[[Doc
	"Sorts and returns an activity table (channel, member) in decrescent order { id, value } and the sum of values of all the indexes"
	@list table
	@f function*
	>table, int
]]
local sortActivityTable = function(list, f)
	local total, out, counter = 0, { }, 0
	for k, v in next, table.copy(list) do
		if (f and f(k, v)) or v < 1 then
			list[k] = nil
		else
			counter = counter + 1
			out[counter] = { k, v }
			total = total + v
		end
	end
	table.sort(out, function(c1, c2) return c1[2] > c2[2] end)
	return out, total
end
--[[Doc
	"Splits a string by characters until it reaches the max size."
	@content string
	@max int*
	>table
]]
local splitByChar = function(content, max)
	max = max or 1900

	local data = {}

	if content == '' or content == "\n" then return end

	local current = 0
	while #content > current do
		current = current + (max + 1)
		data[#data + 1] = string.sub(content, current - max, current)
	end

	return data
end
--[[Doc
	"Splits a string by lines until it reaches the max size."
	@content string
	@max int*
	>table
]]
local splitByLine = function(content, max)
	max = max or 1850

	local data = {}

	if content == '' or content == "\n" then return data end

	local current, tmp = 1, ''
	for line in string.gmatch(content, "([^\n]*)[\n]?") do
		tmp = tmp .. line .. "\n"

		if #tmp > max then
			data[current] = tmp
			tmp = ''
			current = current + 1
		end
	end
	if #tmp > 0 then data[current] = tmp end

	return data
end

local test
do
	local clock = os.clock
	test = function(fList, rate)
		local lenF = #fList

		local avg, t, f = { }
		for i = 1, lenF do
			avg[i] = 0
			for _ = 1, rate do
				f = fList[i]

				t = os.clock()
				f()
				t = clock() - t

				avg[i] = avg[i] + t
			end
			avg[i] = avg[i] * rate * 100
		end

		for i = 1, lenF do
			avg[i] = { i = i, avg = avg[i] }
		end
		table.sort(avg, function(f1, f2)
			return f1.avg < f2.avg
		end)

		for i = 1, lenF do
			avg[i] = ("#" .. i .. ". Test [" .. avg[i].i .. "] AVG: " .. avg[i].avg .. "s")
		end
		return avg, lenF
	end
end

--[[Doc
	~
	"Throws an error if a function doesn't load properly"
	@message Discordia.Message
	@errName string|table
	@fn function
	@... *
]]
local throwError = function(message, errName, fn, ...)
	local success, err = pcall(fn, ...)
	if not success then
		local content = {
			content = "<@" .. client.owner.id .. ">",
			embed = {
				color = color.lua_err,
				title = (type(errName) == "string" and  ("evt@" .. errName) or errName[1]) .. " => Fatal Error!",
				description = "```\n" .. err .. "```\n```\n" .. debug.traceback() .. "```"
			}
		}

		if message then
			toDelete[message.id] = message:reply(content)
		else
			content.content = "<@" .. client.owner.id  .. ">"
			client:getChannel(channels["code-test"]):send(content)
		end
	end
end

--[[Doc
	~
	"Updates the currency table."
]]
local updateCurrency = function()
	local head, body = http.request("GET", "http://data.fixer.io/api/latest?access_key=" .. tokens.fixer) -- Free plan = http
	body = json.decode(tostring(body))

	if body and body.rates then
		-- base will always be EUR (Free plan)
		currency = table.map(body.rates, function(value)
			-- curreny from EUR to USD
			return value * (body.rates.USD or 0)
		end)
	end
end

--[[Doc
	"Verifies if a pattern is valid and sends a message if not."
	@message Discordia.Message
	@src string
	@pattern string
	>boolean
]]
local validPattern = function(message, src, pattern)
	local success, err = pcall(string.find, src, pattern)
	if not success then
		toDelete[message.id] = message:reply({
			content = "<@!" .. message.author.id .. ">",
			embed = {
				color = color.err,
				title = "<:atelier:458403092417740824> Invalid pattern.",
				description = "```\n" .. tostring(err) .. "```"
			}
		})
		return false
	end
	return true
end

--[[Doc
	~
	"Gets the Lua environment that is shared between Admins and Developers."
	>table
]]
local getLuaEnv = function()
	return {
		activeChannels = table.copy(activeChannels),
		activeMembers = table.copy(activeMembers),
		authIds = table.copy(authIds),

		base64 = table.copy(base64),
		binBase64 = table.copy(binBase64),
		bit32 = table.copy(bit),
		buildMessage = buildMessage,

		categories = table.copy(categories),

		channels = table.copy(channels),
		color = table.copy(color),
		concat = concat,
		countryFlags = table.copy(countryFlags),
		countryFlags_Aliases = table.copy(countryFlags_Aliases),

		debugAction = table.copy(debugAction),
		devRestrictions = table.copy(devRestrictions),

		encodeUrl = encodeUrl,
		envTfm = table.deepcopy(envTfm),
		expToLvl = expToLvl,

		fixHtml = fixHtml,

		getAge = getAge,
		getCommandFormat = getCommandFormat,
		getCommandTable = getCommandTable,
		getDiscMember = getDiscMember,
		getNick = getNick,
		getRate = getRate,
		globalCommands = table.deepcopy(globalCommands),

		hasPermission = hasPermission,
		htmlToMarkdown = htmlToMarkdown,

		logColor = table.copy(logColor),

		memberProfiles = table.deepcopy(memberProfiles),
		math = table.copy(math),
		meta = table.copy(meta),
		moduleRestrictions = table.copy(moduleRestrictions),
		modules = table.deepcopy(modules),
		moonPhase = moonPhase,

		nickList = table.copy(nickList),
		normalizeDiscriminator = normalizeDiscriminator,

		pairsByIndexes = pairsByIndexes,
		permIcons = table.copy(permIcons),
		permissions = table.copy(permissions),
		permissionOverwrites = table.deepcopy(permissionOverwrites),
		permMaps = table.copy(permMaps),
		profileStruct = table.deepcopy(profileStruct),

		reactions = table.copy(reactions),
		removeAccents = removeAccents,
		roleColor = table.copy(roleColor),
		roleFlags = table.copy(roleFlags),
		roles = table.copy(roles),

		sortActivityTable = sortActivityTable,
		specialRoleColor = table.copy(specialRoleColor),
		splitByChar = splitByChar,
		splitByLine = splitByLine,
		string = table.copy(string),

		table = table.copy(table),
		title = table.deepcopy(title),

		utf8 = table.copy(utf8),

		validPattern = validPattern,
	}
end

local addRuntimeLimit = function(parameters, message)
	local errname = string.sub(os.tmpname(), 9)
	local errmsg = string.sub(os.tmpname(), 9)
	local s = (hasPermission(permissions.is_module, message.member) and 10 or 5)
	local runtime = os.time() + s
	local snippet = "if os.time()>" .. runtime .. " then " .. errname .. "(tostring(" .. errmsg .. "),2) end "

	local loads = { }
	for posini, posend in string.gmatch(parameters, "discord%.load[\n\r ]*%(().*()%)") do
		loads[#loads + 1] = { posini, posend }
	end
	
	local hasChanged, change = false
	for _, pattern in next, { "()(while.-do[\n\r ]+)", "()(repeat[\n\r ]+)", "()(for .-=.- do[\n\r ]+)", "()(for .- in .- do[\n\r ]+)", "()(function[\n\r ]*%S-[\n\r ]-%(.-%)[\n\r ]+)" } do
		parameters, change = string.gsub(parameters, pattern, function(pos, chunk)
			for i = 1, #loads do
				if not (loads[i][1] > pos and loads[i][2] < pos) then
					return chunk
				end
			end
			return chunk .. " " .. snippet
		end)
		if (change and change > 0) and not hasChanged then
			hasChanged = true
		end
	end

	if hasChanged then
		parameters = "local " .. errname .. "=error local " .. errmsg .. "=\"Your code has exceeded the runtime limit of " .. s .. "s.\"" .. parameters
	end

	return parameters
end

local messageCreate, messageDelete

--[[ Commands ]]--
	-- Public
commands["a801"] = {
	auth = permissions.public,
	description = "Displays your profile on Atelier801.",
	f = function(message, parameters)
		if parameters and #parameters > 2 then
			local role = ''

			local tag = string.match(parameters, "#(%d+)")
			if not tag then
				parameters = parameters .. "#0000"
			else
				tag = tonumber(tag)
				if tag == 95 then
					role = "```Python\n#Ex-staff```\n"
				elseif tag == 1 then
					role = "```Haskell\n#Administrator```\n"
				elseif tag == 10 then
					role = "```CSS\n\"Moderator\"```\n"
				elseif tag == 15 then
					role = "```C\n\"Sentinel\"```\n"
				elseif tag == 20 then
					role = "```HTML\n<Mapcrew>```\n"
				end
			end

			parameters = string.gsub(string.lower(parameters), '%a', string.upper, 1)

			local href = "https://atelier801.com/profile?pr=" .. encodeUrl(parameters)
			local head, body = http.request("GET", href, {
				{ "Accept-Language", "en-US,en;q=0.9" }
			})

			if body then
				if string.find(body, "The request contains one or more invalid parameters") then
					toDelete[message.id] = message:reply({
						embed = {
							color = color.atelier801,
							title = "<:atelier:458403092417740824> Player not found",
							description = "The player **" .. parameters .. "** does not exist."
						}
					})
				else
					local gender = ''
					if string.find(body, "Female") then
						gender = "<:female:456193579308679169> "
					elseif string.find(body, "Male") then
						gender = "<:male:456193580155928588> "
					end

					local avatar = string.match(body, "http://avatars%.atelier801%.com/%d+/%d+%.jpg")
					if not avatar then
						-- Invisible image
						avatar = "https://i.imgur.com/dkhvbrg.png"
					end

					local community = string.match(body, "Community :</span> <img src=\"/img/pays/(.-)%.png\"")
					if not community or community == "xx" then
						community = "<:international:458411936892190720>"
					else
						community = ":flag_" .. community .. ":"
					end

					local fields = {
						[1] = {
							name = "Registration Date",
							value = ":calendar: " .. tostring(string.match(body, "Registration date</span> : (.-)</span>")),
							inline = true,
						},
						[2] = {
							name = "Community",
							value = community,
							inline = true,
						},
						[3] = {
							name = "Messages",
							value = ":speech_balloon: " .. tostring(string.match(body, "Messages: </span>(%d+)")),
							inline = true,
						},
						[4] = {
							name = "Prestige",
							value = ":hearts: " .. tostring(string.match(body, "Prestige: </span>(%d+)")),
							inline = true,
						},
						[5] = {
							name = "Title",
							value = "« " .. tostring(string.match(body, "&laquo; (.-) &raquo;")) .. " »",
							inline = true,
						}
					}

					local tribe = string.match(body, "cadre%-tribu%-nom\">(.-)</span>")
					if tribe then
						tribe = string.gsub(tribe, "&#(%d+);", string.char)

						local tribeId = string.match(body, "tribe%?tr=%d+")

						fields[#fields + 1] = {
							name = "Tribe",
							value = "<:tribe:458407729736974357> [" .. tribe .. "](https://atelier801.com/" .. tostring(tribeId) .. ")",
							inline = true,
						}
					end

					local soulmate, id = string.match(body, "alt=\"\">  ([%w+_]+)<span class=\"font%-s couleur%-hashtag%-pseudo\"> (#%d+)</span>")
					if soulmate and id then
						soulmate = soulmate .. id

						fields[#fields + 1] = {
							name = "Soulmate",
							value = ":revolving_hearts: [" .. soulmate .. "](https://atelier801.com/profile?pr=" .. encodeUrl(soulmate) .. ")",
							inline = true
						}
					end

					toDelete[message.id] = message:reply({
						embed = {
							color = color.atelier801,
							title = "<:atelier:458403092417740824> " .. gender .. parameters,
							description = role .. "<:tfm_cheese:458404666926039053> [Visit Profile](" .. href .. ")",
							thumbnail = { url = avatar },
							fields = fields,
						}
					})
				end
			else
				sendError(message, "A801", "Fatal error")
			end
		else
			sendError(message, "A801", "Invalid or missing parameters.", "Use `!a801 player_name`.")
		end
	end
}
commands["activity"] = {
	auth = permissions.public,
	description = "Displays the channels' and members' activity.",
	f = function(message, _, __, ___, get)
		local cachedChannels, loggedMessages = sortActivityTable(activeChannels, function(id) return not client:getChannel(id) end)
		local cachedMembers, loggedMemberMessages = sortActivityTable(activeMembers, function(id) return not message.guild:getMember(id) end)

		local members = concat(cachedMembers, "\n", function(index, value)
			local member = message.guild:getMember(value[1])
			return (index > 3 and ":medal: " or ":" .. (index == 1 and "first" or index == 2 and "second" or "third") .. "_place: ") .. "<@" .. member.id .. "> `" .. member.name .. (get and "` " or "`\n") .. getRate(value[2], loggedMemberMessages, 30) .. " [" .. value[2] .. "]"
		end, 1, (get and 3 or 10))

		local achannels = concat(cachedChannels, "\n", function(index, value)
			local channel = client:getChannel(value[1])
			return (index > 3 and ":medal: " or ":" .. (index == 1 and "first" or index == 2 and "second" or "third") .. "_place: ") .. (channel.category and (channel.category.name .. ".<#") or "<#") .. channel.id .. (get and "> " or ">\n") .. getRate(value[2], loggedMessages, 30) .. " [" .. value[2] .. "]"
		end, 1, (get and 3 or 5))

		if get then
			return members, achannels
		end

		toDelete[message.id] = message:reply({
			content = "<@" .. message.author.id .. ">",
			embed = {
				color = color.interaction,

				fields = {
					[1] = {
						name = ":bar_chart: " .. os.date("%B") .. "'s active members",
						value = members,
						inline = false
					},
					[2] = {
						name = ":chart_with_upwards_trend: " .. os.date("%B") .. "'s active channels",
						value = achannels,
						inline = false
					}
				}
			}
		})
	end
}
commands["adoc"] = {
	auth = permissions.public,
	description = "Gets information about a specific tfm api function.",
	f = function(message, parameters)
		if parameters and #parameters > 0 then
			local head, body = http.request("GET", "https://atelier801.com/topic?f=612619&t=934783")

			if body then
				body = string.gsub(string.gsub(body, "<br />", "\n"), " ", '')
				local _, init = string.find(body, "id=\"message_19532184\">•")
				body = string.sub(body, init)

				local syntax, description = string.match(body, "•  (" .. parameters .. " .-)\n(.-)\n\n\n\n")

				if syntax then
					description = string.gsub(description, "&sect;", "§")
					description = string.gsub(description, "&middot;", ".")
					description = string.gsub(description, "&gt;", ">")
					description = string.gsub(description, "&lt;", "<")
					description = string.gsub(description, "&quot;", "\"")
					description = string.gsub(description, "&amp;", "&")
					description = string.gsub(description, "&pi;", "π")
					description = string.gsub(description, "&#(%d+);", function(dec) return string.char(dec) end)

					local info = {
						desc = { },
						param = { },
						ret = nil
					}

					for line in string.gmatch(description, "[^\n]+") do
						if not string.find(line, "^Parameters") and not string.find(line, "^Arguments") then
							local i, e = string.find(line, "^[%-~] ")
							if i then
								local param = string.sub(line, e + 1)

								local list, desc = string.match(param, "(.-) ?: (.+)")

								if list then
									local params = { }
									for name, type in string.gmatch(list, "(%w+) %((.-)%)") do
										params[#params + 1] = "`" .. type .. "` **" .. name .. "**"
									end

									if #params > 0 and desc then
										param = table.concat(params, ", ") .. " ~> " .. desc
									end
								end

								info.param[#info.param + 1] = (string.sub(line, 1, 1) == "~" and "- " or '') .. param
							else
								i, e = string.find(line, "^Returns: ")
								if i then
									local param = string.sub(line, e + 1)
									local type, desc = string.match(param, "^%((.-)%) (.+)")

									if type then
										param = "`" .. type .. "` : " .. desc
									end

									info.ret = param
								else
									info.desc[#info.desc + 1] = line
								end
							end
						end
					end

					toDelete[message.id] = message:reply({
						content = "<@!" .. message.author.id .. ">",
						embed = {
							color = color.lua,
							title = "<:atelier:458403092417740824> " .. syntax,
							description = table.concat(info.desc, "\n") .. (#info.param > 0 and ("\n\n**Arguments / Parameters**\n" .. table.concat(info.param, "\n")) or '') .. (info.ret and ("\n\n**Returns**\n" .. info.ret) or ''),
							footer = { text = "TFM API Documentation" },
						}
					})
				else
					toDelete[message.id] = message:reply({
						content = "<@!" .. message.author.id .. ">",
						embed = {
							color = color.lua,
							title = "<:atelier:458403092417740824> TFM API Documentation",
							description = "The function **" .. parameters .. "** was not found in the documentation."
						}
					})
				end
			else
				sendError(message, "ADOC", "Fatal error")
			end
		else
			sendError(message, "ADOC", "Invalid or missing parameters.", "Use `!adoc function_name`.")
		end
	end
}
--[[commands["akinator"] = {
	auth = permissions.public,
	description = "Starts an Akinator game.",
	f = function(message, parameters)
		local langs = {
			ar = "https://srv2.akinator.com:9155",
			br = "https://srv2.akinator.com:9161",
			en = "https://srv2.akinator.com:9157",
			es = "https://srv6.akinator.com:9127",
			fr = "https://srv3.akinator.com:9217",
			he = "https://srv12.akinator.com:9189",
			it = "https://srv9.akinator.com:9214",
			jp = "https://srv11.akinator.com:9172",
			pl = "https://srv12.akinator.com:9188",
			ru = "https://srv12.akinator.com:9190",
			tr = "https://srv3.akinator.com:9211",
		}

		local lang = langs[string.lower(tostring(parameters))] or langs[string.lower(message.channel.name)] or langs.en

		local _, body = http.request("GET", lang .. "/ws/new_session?base=0&partner=410&premium=0&player=Android-Phone&uid=6fe3a92130c49446&do_geoloc=1&prio=0&constraint=ETAT%3C%3E'AV'&channel=0&only_minibase=0")
		body = json.decode(body)

		if body then
			local numbers = { "one", "two", "three", "four", "five" }

			local cmds = concat(body.parameters.step_information.answers, "\n", function(index, value)
				return ":" .. tostring(numbers[index]) .. ": " .. tostring(value.answer)
			end)

			local msg = message:reply({
				content = "<@" .. message.author.id .. ">",
				embed = {
					color = color.interaction,
					title =  "<:akinator:456196251743027200> Akinator vs. " .. message.member.name,
					thumbnail = { url = "https://loritta.website/assets/img/akinator_embed.png" },
					description = string.format("```\n%s```\n%s", body.parameters.step_information.question, cmds),
					footer = {
						text = "Question 1"
					}
				}
			})

			if msg then
				for i = 1, #playingAkinator.__REACTIONS - 1 do
					msg:addReaction(playingAkinator.__REACTIONS[i])
				end

				toDelete[message.id] = msg
			end

			playingAkinator[message.author.id] = {
				canExe = true,
				message = msg,
				cmds = cmds,
				ratio = 80,
				currentRatio = nil,
				lang = lang,
				data = {
					channel = body.parameters.identification.channel,
					session = body.parameters.identification.session,
					signature = body.parameters.identification.signature,
					step = body.parameters.step_information.step,
				},
				lastBody = body
			}
		end
	end
}
]]
commands["avatar"] = {
	auth = permissions.public,
	description = "Displays someone's avatar.",
	f = function(message, parameters)
		parameters = not parameters and message.author.id or string.match(parameters, "(%d+)")
		parameters = parameters and client:getUser(parameters)

		if parameters then
			local url = parameters.avatarURL .. "?size=2048"

			toDelete[message.id] = message:reply({
				embed = {
					color = color.sys,
					description = "**" .. parameters.tag .. "'s avatar: [here](" .. url .. ")**",
					image = { url = url }
				}
			})
		end
	end
}
commands["coin"] = {
	auth = permissions.public,
	description = "Converts a value between currencies.",
	f = function(message, parameters)
		if currency.USD then
			local syntax = "Use `!coin to_currency from_currency amount`."

			if parameters and #parameters > 2 then
				local available_currencies = "The available currencies are:\n```\n" .. concat(currency, ", ", tostring, nil, nil, pairsByIndexes) .. "```"

				local from, to, amount

				from = string.match(parameters, "^...")
				if from then
					from = string.upper(from)
					if not currency[from] then
						return sendError(message, "COIN", ":fire: | Invalid from_currency '" .. from .. "'!", available_currencies)
					end
				end

				to = string.match(parameters, "[ \n]+(...)[ \n]*")
				if to then
					to = string.upper(to)
					if not currency[to] then
						return sendError(message, "COIN", ":fire: | Invalid to_currency '" .. to .. "'!", available_currencies)
					end
				else
					to = from
					from = nil
				end

				local randomEmoji = ":" .. table.random({ "money_mouth", "money_with_wings", "moneybag" }) .. ":"

				amount = string.match(parameters, "(%d+[%.,]?%d*)$")
				amount = amount and tonumber((string.gsub(amount, ',', '.', 1))) or 1
				amount = (amount * currency[to]) / (currency[from] or currency.USD)

				toDelete[message.id] = message:reply({
					content = "<@!" .. message.author.id .. ">",
					embed = {
						color = color.sys,
						title = randomEmoji .. " " .. (from or "USD") .. " -> " .. to,
						description = string.format("¤ %.2f", amount)
					}
				})
			else
				sendError(message, "COIN", "Invalid or missing parameters.", syntax)
			end
		else
			sendError(message, "COIN", "Currency table is loading. Try again later.")
		end
	end
}
commands["color"] = {
	auth = permissions.public,
	description = "Displays a color.",
	f = function(message, parameters)
		if parameters and #parameters > 0 then
			local hex = string.match(parameters, "^0x(%x+)$") or string.match(parameters, "^#?(%x+)$")
			if tonumber(hex) and #hex > 6 then
				hex = nil
			end
			if not hex then
				if string.find(parameters, ',') then
					local m = "(%d+), *(%d+), *(%d+)"
					local r, g, b = string.match(parameters, "rgb%(" .. m .. "%)")
					if not r then
						r, g, b = string.match(parameters, m)
					end
					r, g, b = tonumber(r), tonumber(g), tonumber(b)

					parameters = nil
					if r then
						r, g, b = math.clamp(r, 0, 255), math.clamp(g, 0, 255), math.clamp(b, 0, 255)
						parameters = string.format("%02x%02x%02x", r, g, b)
					end
				else
					parameters = string.match(parameters, "^(%d+)$")
					if parameters then
						parameters = string.format("%06x", parameters)
					end
				end
			else
				parameters = hex
			end

			if not parameters then
				return sendError(message, "COLOR", "Invalid hexadecimal or RGB code.")
			end

			local dec = tonumber(parameters, 16)

			local image = "https://www.colorhexa.com/" .. string.format("%06x", dec) .. ".png"

			toDelete[message.id] = message:reply({
				embed = {
					color = dec,
					author = {
						name = "#" .. string.upper(parameters) .. " <" .. dec .. ">",
						icon_url = image
					},
					image = {
						url = image
					}
				}
			})
		else
			sendError(message, "COLOR", "Invalid or missing parameters.", "Use `!color #hex_code` or `!color rgb(r, g, b)`.")
		end
	end
}
commands["conn"] = {
	auth = permissions.public,
	description = "Checks the BOT ping.",
	f = function(message, parameters)
		local m = message:reply("pong")
		m:setContent("**Ping** : " .. string.format("%.3f", ((m.createdAt - message.createdAt) * 1000)) .. " ms.")
	end
}
commands["doc"] = {
	auth = permissions.public,
	description = "Gets information about a specific lua function.",
	f = function(message, parameters)
		if parameters and #parameters > 0 then
			local head, body = http.request("GET", "http://www.lua.org/work/doc/manual.html")

			if body then
				local syntax, description = string.match(body, "<a name=\"pdf%-" .. parameters .. "\"><code>(.-)</code></a></h3>[\n<p>]*(.-)<h[r2]>")

				if syntax then
					-- Normalizing tags
					syntax = string.gsub(syntax, "&middot;", ".")

					description = string.gsub(description, "<b>(.-)</b>", "**%1**")
					description = string.gsub(description, "<em>(.-)</em>", "_%1_")
					description = string.gsub(description, "<li>(.-)</li>", "\n- %1")

					description = string.gsub(description, "<code>(.-)</code>", "`%1`")
					description = string.gsub(description, "<pre>(.-)</pre>", function(code)
						return "```Lua¨" .. (string.gsub(string.gsub(code, "\n", "¨"), "¨     ", "¨")) .. "```"
					end)

					description = string.gsub(description, "&sect;", '§')
					description = string.gsub(description, "&middot;", '.')
					description = string.gsub(description, "&nbsp;", ' ')
					description = string.gsub(description, "&gt;", '>')
					description = string.gsub(description, "&lt;", '<')
					description = string.gsub(description, "&pi;", 'π')

					description = string.gsub(description, "<a href=\"(#.-)\">(.-)</a>", "[%2](https://www.lua.org/manual/5.2/manual.html%1)")

					description = string.gsub(description, "\n", ' ')
					description = string.gsub(description, "¨", '\n')
					description = string.gsub(description, "<p>", "\n\n")

					description = string.gsub(description, "<(.-)>(.-)</%1>", "%2")

					local lines = splitByChar(description)

					local toRem = { }
					for i = 1, #lines do
						toRem[i] = message:reply({
							content = (i == 1 and "<@!" .. message.author.id .. ">" or nil),
							embed = {
								color = color.lua,
								title = (i == 1 and ("<:lua:468936022248390687> " .. syntax) or nil),
								description = lines[i],
								footer = { text = "Lua Documentation" }
							}
						})
					end
					toDelete[message.id] = toRem
				else
					toDelete[message.id] = message:reply({
						content = "<@!" .. message.author.id .. ">",
						embed = {
							color = color.lua,
							title = "<:lua:468936022248390687> Lua Documentation",
							description = "The function **" .. parameters .. "** was not found in the documentation."
						}
					})
				end
			else
				sendError(message, "DOC", "Fatal error")
			end
		else
			sendError(message, "DOC", "Invalid or missing parameters.", "Use `!doc function_name`.")
		end
	end
}
commands["edit"] = {
	auth = permissions.public,
	description = "Edits the data of your profile.",
	f = function(message, parameters)
		local syntax = "Use `!edit field value` or `!edit field` to remove the value.\nThe available fields are:\n" .. concat(profileStruct, '', function(index, value)
			if not value.index then
				return "**" .. index .. "** - " .. value.description .. "\n"
			else
				if message.member:hasRole(roles[roleFlags[value.index]]) then
					return "**" .. index .. "** - " .. value.description .. "\n"
				end
				return ''
			end
		end)

		if parameters and #parameters > 0 then
			local field, value = string.match(parameters, "^(%S+)[\n ]+(.+)$")

			if field and profileStruct[field] then
				if profileStruct[field].index and not message.member:hasRole(roles[roleFlags[profileStruct[field].index]]) then
					return sendError(message, "EDIT", "Field authorization denied.", "You can not update this field because you do not have the role `" .. string.upper(roleFlags[profileStruct[field].index]) .. "`.")
				end

				local isNumber = profileStruct[field].type == "number"
				if isNumber then
					value = tonumber(value)
					if not value then
						return sendError(message, "EDIT", "The value must be a number.")
					end
					value = math.floor(value)
				end

				if profileStruct[field].min and (isNumber and value or #value) < profileStruct[field].min then
					return sendError(message, "EDIT", "Invalid value.", "The value or value length must be greater than or equal to **" .. profileStruct[field].min .. "**.")
				end
				if profileStruct[field].max and (isNumber and value or #value) > profileStruct[field].max then
					return sendError(message, "EDIT", "Invalid value.", "The value or value length must be less than or equal to **" .. profileStruct[field].max .. "**.")
				end

				if profileStruct[field].format then
					local ok = true
					if type(profileStruct[field].format) == "table" then
						for k, v in next, profileStruct[field].format do
							if not string.format(value, v) then
								ok = false
								break
							end
						end
					else
						ok = not not string.format(value, profileStruct[field].format)
					end

					if not ok then
						return sendError(message, "EDIT", "Invalid value.", "The format of this field requires another value format.")
					end
				end

				if profileStruct[field].valid then
					local success, fix = profileStruct[field].valid(value, message)
					if not success then
						return sendError(message, "EDIT", "Invalid value.", "This value is invalid or does not exist.")
					elseif fix then
						value = fix
					end
				end

				if not memberProfiles[message.author.id] then
					memberProfiles[message.author.id] = { }
				end
				local old_value
				if profileStruct[field].index then
					if not memberProfiles[message.author.id][profileStruct[field].index] then
						memberProfiles[message.author.id][profileStruct[field].index] = { }
					end
					old_value = memberProfiles[message.author.id][profileStruct[field].index][field]
					memberProfiles[message.author.id][profileStruct[field].index][field] = value
				else
					old_value = memberProfiles[message.author.id][field]
					memberProfiles[message.author.id][field] = value
				end

				message.author:send({
					embed = {
						color = color.interaction,
						title = "Profile Data Updated!",
						description = "You updated the field `" .. field .. "` with the value `" .. value .. "`" .. (old_value and ("\nIts value was, previously, `" .. old_value .. "`") or "")
					}
				})
				message:delete()
			else
				if profileStruct[parameters] then
					local old_value
					if profileStruct[parameters].index then
						old_value = memberProfiles[message.author.id][profileStruct[parameters].index]
						if old_value then
							old_value = old_value[parameters]
						end

						memberProfiles[message.author.id][profileStruct[parameters].index][parameters] = nil
					else
						old_value = memberProfiles[message.author.id][parameters]
						memberProfiles[message.author.id][parameters] = nil
					end

					message.author:send({
						embed = {
							color = color.interaction,
							title = "Profile Data Updated!",
							description = "You removed the field `" .. parameters .. "`" .. (old_value and (" that had the value `" .. old_value .. "`") or "")
						}
					})
					message:delete()
				else
					sendError(message, "EDIT", "Invalid field.", syntax)
				end
			end
		else
			sendError(message, "EDIT", "Invalid or missing parameters.", syntax)
		end
	end
}
commands["ghelp"] = {
	auth = permissions.public,
	f = function(message)
		commands["help"].f(message, nil, nil, globalCommands)
	end
}
commands["help"] = {
	auth = permissions.public,
	f = function(message, _, category, cmdSrc)
		if category and string.sub(category, 1, 1) == "#" then
			local keys = { } -- auths cuz the system is fkd
			local cmds = { }
			for cmd, data in next, modules[category].commands do
				if not cmds[data.auth] then
					cmds[data.auth] = { }
					keys[#keys + 1] = data.auth
				end
				cmds[data.auth][#cmds[data.auth] + 1] = { cmd = cmd, data = data }
			end
			table.sort(keys)

			local prefix = "**" .. (modules[category].prefix or "!")

			for k, v in next, keys do
				local icon = permIcons[permissions(v)]--((v > permissions.public) and ":small_blue_diamond:" or ":small_orange_diamond:")
				table.sort(cmds[v], function(c1, c2) return c1.cmd < c2.cmd end)
				for j = 1, #cmds[v] do
					cmds[v][j] = icon .. prefix .. cmds[v][j].cmd .. "** " .. (cmds[v][j].data.info or '')
				end
				keys[k] = table.concat(cmds[v], '\n')
			end
			cmds = table.concat(keys, '\n')

			toDelete[message.id] = message:reply({
				content = "<@!" .. message.author.id .. ">",
				embed = {
					color = color.sys,
					title = category .. " commands",
					description = cmds
				}
			})
		else
			local keys = { } -- auths cuz the system is fkd
			local cmds, icon, description, index = { }
			for cmd, data in next, (cmdSrc or commands) do
				if not data.category or (message.channel.category and data.category == message.channel.category.id) then
					if not data.channel or data.channel == message.channel.id then
						if authIds[message.author.id] or (data.auth and hasPermission(data.auth, message.member, message)) then
							icon = (not data.auth and ":gear:" or permIcons[permissions(data.auth)]) .. " "--(not data.auth and ":gear: " or (data.auth > permissions.public) and ":small_blue_diamond: " or ":small_orange_diamond: ")

							description = data.description or data.info
							description = description and ("- " .. description) or ''

							index = data.auth or 666
							if not cmds[index] then
								cmds[index] = { }
								keys[#keys + 1] = index
							end
							cmds[index][#cmds[index] + 1] = { cmd = cmd, data = icon .. "**!" .. cmd .. "** " .. description }
						end
					end
				end
			end
			table.sort(keys)

			for k, v in next, keys do
				table.sort(cmds[v], function(c1, c2) return c1.cmd < c2.cmd end)
				for j = 1, #cmds[v] do
					cmds[v][j] = cmds[v][j].data
				end
				keys[k] = table.concat(cmds[v], '\n')
			end
			cmds = table.concat(keys, '\n')

			local lines = splitByLine(cmds)

			local msg = { }
			for line = 1, #lines do
				msg[line] = message:reply({
					content = (line == 1 and "<@!" .. message.author.id .. ">" or nil),
					embed = {
						color = color.sys,
						title = (line == 1 and (cmdSrc and "Global " or "") .. "Commands" or nil),
						description = lines[line]
					}
				})
			end
			toDelete[message.id] = msg

			timer.setTimeout(1.25 * 60 * 1000, coroutine.wrap(function(msg)
				if toDelete[message.id] then
					messageDelete(message)
				end
			end), message)
		end
	end
}
commands["invite"] = {
	auth = permissions.public,
	description = "The invite link for this server.",
	f = function(message)
		toDelete[message.id] = message:reply("Invite link: **<https://discord.gg/quch83R>**")
	end
}
commands["list"] = {
	auth = permissions.public,
	description = "Lists the users with a specific role.",
	f = function(message, parameters)
		local syntax = "Use `!list [-]role_name/flag[, ...]`.\n\nThe available roles are:" .. concat(roleFlags, '', function(id, name)
			return tonumber(id) and "\n\t• [" .. id .. "] " .. name or ''
		end)

		if parameters and #parameters > 0 then
			parameters = string.lower(parameters)

			local counterRoles, counterNonRoles = 0, 0
			local roles, nonRoles = { }, { }
			local non, value, isId
			for role in string.gmatch(parameters, "[^,]+") do
				role = string.trim(role)

				non = string.sub(role, 1, 1) == '-'
				if non then
					counterNonRoles = counterNonRoles + 1
					role = string.sub(role, 2)
				else
					counterRoles = counterRoles + 1
				end

				isId = tonumber(role)
				if isId then
					role = roleFlags[isId] or role
				end
				value = message.guild.roles:find(function(r)
					return string.lower(r.name) == role
				end)

				if not value then
					return sendError(message, "LIST", "The role '" .. role .. "' does not exist.", syntax)
				end

				if non then
					nonRoles[counterNonRoles] = value
				else
					roles[counterRoles] = value
				end
			end

			local toSort, counter = { }, 0
			for member in message.guild.members:findAll(function(member)
				for i = 1, #roles do
					if not member:hasRole(roles[i]) then
						return false
					end
				end

				for i = 1, #nonRoles do
					if member:hasRole(nonRoles[i]) then
						return false
					end
				end

				return true
			end) do
				counter = counter + 1
				toSort[counter] = member
			end
			table.sort(toSort, function(m1, m2) return m1.name < m2.name end)

			local members = { }
			for m = 1, counter do
				members[m] = "<:" .. (reactions[toSort[m].status] or ':') .. "> <@" .. toSort[m].id .. "> " .. toSort[m].name
			end

			local lines, msgs = splitByLine(table.concat(members, "\n")), { }
			for i = 1, #lines do
				msgs[i] = message:reply({
					embed = {
						color = color.sys,
						title = (i == 1 and ("<:wheel:456198795768889344> Members " .. (roles and ("+(" .. concat(roles, ", ", function(index, value) return string.upper(value.name) end) .. ")") or "") .. (nonRoles and ("-(" .. concat(nonRoles, ", ", function(index, value) return string.upper(value.name) end) .. ")") or "") .. " (#" .. #members .. ")") or nil),
						description = lines[i]
					}
				})
			end
			toDelete[message.id] = msgs
		else
			sendError(message, "LIST", "Invalid or missing parameters.", syntax)
		end
	end
}
commands["mobile"] = {
	auth = permissions.public,
	description = "Sends a private message with the embed in a text format.",
	f = function(message, parameters)
		parameters = parameters and string.match(parameters, "%d+")

		if parameters then
			local msg = message.channel:getMessage(parameters)

			if msg then
				if msg.embed then
					local content = { }

					if msg.content and #msg.content > 3 then
						content[#content + 1] = "`" .. msg.content .. "`"
					end

					if msg.embed.title then
						content[#content + 1] = "**" .. msg.embed.title .. "**"
					end
					if msg.embed.description then
						content[#content + 1] = msg.embed.description
					end

					local footerText = msg.embed.footer and msg.embed.footer.text
					if footerText then
						content[#content + 1] = "`" .. footerText .. "`"
					end

					local len = #content
					content[len + (footerText and 0 or 1)] = (footerText and (content[len] .. " | ") or "") .. "`" .. os.date("%c", os.time(discordia.Date().fromISO(msg.timestamp):toTableUTC())) .. "`"

					local img = (msg.attachment and msg.attachment.url) or (msg.embed and msg.embed.image and msg.embed.image.url)
					message.author:send({
						content = string.sub(table.concat(content, "\n"), 1, 2000),
						embed = {
							image = (img and { url = img } or nil)
						}
					})
				else
					message.author:send(msg.content)
				end
				message:delete()
			end
		end
	end
}
commands["modules"] = {
	auth = permissions.public,
	description = "Lists the current modules available in Transformice. [by name | from community | level 0/1 | #pattern]",
	f = function(message, parameters)
		local head, body = http.request("GET", "https://atelier801.com/topic?f=612619&t=933743")

		local search = {
			a_commu = false, -- alias
			commu = false,
			player = false,
			type = false,
			pattern = false
		}
		if parameters then
			if not validPattern(message, body, parameters) then return end

			string.gsub(string.lower(parameters), "(%S+)[\n ]+(%S+)", function(keyword, value)
				if keyword then
					if keyword == "from" and not search.player then
						search.commu = tonumber(value)
						if #value == 2 then
							search.commu = #tostring(communities[value]) == 2 and communities[value] or value
						else
							search.commu = table.search(communities, value) or value
						end
					elseif keyword == "by" and not search.commu then
						if not validPattern(message, body, value) then return end
						search.player = value
					elseif keyword == "level" then
						search.type = tonumber(value)
					end
				end
			end)

			local filter = search.commu or search.player or search.type

			search.pattern = string.match(" " .. parameters, "[\n ]+#(.+)$")

			if not search.pattern and not filter then
				search.pattern = parameters
			end
			if search.pattern and not validPattern(message, body, search.pattern) then return end
		end

		local list, counter = { }, 0

		string.gsub(body, '<tr><td><img src="https://atelier801%.com/img/pays/(..)%.png" alt="https://atelier801%.com/img/pays/%1%.png" class="inline%-block img%-ext" style="float:;" /></td><td>     </td><td><span .->(#%S+)</span>.-</td><td>     </td><td><span .->(%S+)</span></td><td>     </td><td><span .->(%S+)</span></td> 	</tr>', function(community, module, level, hoster)
			local check = (not parameters or parameters == '')
			if not check then
				check = true

				if search.commu then
					check = community == search.commu
				end
				if search.type then
					check = check and ((search.type == 0 and level == "semi-official") or (search.type == 1 and level == "official"))
				end
				if search.player then
					check = check and not not string.find(string.lower(hoster), search.player)
				end
				if search.pattern then
					check = check and not not string.find(module, search.pattern)
				end
			end

			if check then
				counter = counter + 1
				list[counter] = { community, module, level, normalizeDiscriminator(hoster) }
			end
		end)

		if #list == 0 then
			toDelete[message.id] = message:reply({
				content = "<@!" .. message.author.id .. ">",
				embed = {
					color = color.err,
					title = "<:wheel:456198795768889344> Modules",
					description = "There are no modules " .. (search.commu and ("made by a(n) [:flag_" .. string.lower(search.commu) .. ":] **" .. string.upper(search.commu) .. "** ") or '') .. (search.player and ("made by **" .. search.player .. "** ") or '') .. (search.type and ("that are [" .. (search.type == 0 and "semi-official" or "official") .. "]") or '') .. (search.pattern and (" with the pattern **`" .. tostring(search.pattern) .. "`**.") or ".")
				}
			})
		else
			local out = concat(list, "\n", function(index, value)
				return communities[value[1]] .. " `" .. value[3] .. "` **" .. value[2] .. "** ~> **" .. value[4] .. "**"
			end)

			local lines, msgs = splitByLine(out), { }
			for line = 1, #lines do
				msgs[line] =  message:reply({
					content = (line == 1 and "<@!" .. message.author.id .. ">" or nil),
					embed = {
						color = color.sys,
						title = (line == 1 and "<:wheel:456198795768889344> [" .. #list .. "] Modules found" or nil),
						description = lines[line]
					}
				})
			end

			toDelete[message.id] = msgs
		end
	end
}
commands["nick"] = {
	auth = permissions.public,
	description = "Changes your nickname in the server. (Blessed command for mobile users)",
	f = function(message, parameters)
		if parameters and #parameters > 0 then
			message.member:setNickname(parameters)
			message:delete()
		end
	end
}
commands["profile"] = {
	auth = permissions.public,
	description = "Displays the profile of a member.",
	f = function(message, parameters)
		local found, p = true
		parameters = (parameters and (string.match(parameters, "<@!?(%d+)>") or string.lower(parameters)) or message.author.id)
		if not tonumber(parameters) then
			local p = string.lower(parameters)
			p = message.guild.members:find(function(member)
				return string.lower(member.name) == p
			end)

			if p then
				parameters = p.id
			else
				found = false
			end
		end

		local member
		if found then
			member = message.guild:getMember(parameters)
			if member then
				if not memberProfiles[member.id] then
					memberProfiles[member.id] = { }
				end
				p = {
					discord = member,
					data = memberProfiles[member.id]
				}
			end
		end
		if not found or not member then
			return sendError(message, "PROFILE", "User '" .. parameters .. "' not found.", "Use `!profile member_name/@member`")
		end

		local role, len = getRoleOrder(member)
		if len == 0 then
			role = { member.guild.defaultRole }
			len = 1
		end
		if role[len].id == MOD_ROLE.id then
			len = len - 1
		end
		role = role[len]

		if specialRoleColor(role.id) then
			role = message.guild:getRole(specialRoleColor(role.id))
		end

		local fields = { }

		local icon = " "
		fields[#fields + 1] = p.data.nickname and {
			name = "<:atelier:458403092417740824> TFM Nickname",
			value = "[" .. string.gsub(p.data.nickname, "#0000", '', 1) .. "](https://atelier801.com/profile?pr=" .. encodeUrl(p.data.nickname) .. ")",
			inline = true
		} or nil

		if p.discord.bot then
			icon = icon .. ":robot: "
		end
		if hasPermission(permissions.is_mod, p.discord) then
			icon = icon .. permIcons.is_mod
		end
		if hasPermission(permissions.has_power, p.discord) then	
			if hasPermission(permissions.is_module, p.discord) then
				icon = icon .. permIcons.is_module
				if p.data[1] and table.count(p.data[1]) > 0 then
					fields[#fields + 1] = p.data[1].since and {
						name = ":calendar: MT Member since",
						value = p.data[1].since,
						inline = true
					} or nil

					fields[#fields + 1] = p.data[1].hosting and {
						name = ":house: Hosted modules",
						value = p.data[1].hosting,
						inline = true
					} or nil
				end
			end
			if hasPermission(permissions.is_dev, p.discord) then
				icon = icon .. permIcons.is_dev
				if p.data[2] and table.count(p.data[2]) > 0 then
					fields[#fields + 1] = p.data[2].modules and {
						name = ":gear: Modules",
						value = p.data[2].modules,
						inline = true
					} or nil

					fields[#fields + 1] = p.data[2].github and {
						name = "<:github:506473892689215518> GitHub",
						value = "[" .. p.data[2].github .. "](https://github.com/" .. p.data[2].github .. ")",
						inline = true
					} or nil
				end
			end
			if hasPermission(permissions.is_art, p.discord) then
				icon = icon .. permIcons.is_art
				if p.data[3] and table.count(p.data[3]) > 0 then
					fields[#fields + 1] = p.data[3].deviantart and {
						name = "<:deviantart:506475600416866324> DeviantArt",
						value = "[" .. p.data[3].deviantart .. "](https://www.deviantart.com/" .. p.data[3].deviantart .. ")",
						inline = true
					} or nil
				end
			end
			if hasPermission(permissions.is_trad, p.discord) then
				icon = icon .. permIcons.is_trad
				if p.data[4] and table.count(p.data[4]) > 0 then
					fields[#fields + 1] = p.data[4].trad and {
						name = ":globe_with_meridians: Modules Translated",
						value = p.data[4].trad,
						inline = true
					} or nil
				end
			end
			if hasPermission(permissions.is_map, p.discord) then
				icon = icon .. permIcons.is_map
				if p.data[5] and table.count(p.data[5]) > 0 then
					fields[#fields + 1] = p.data[5].perms and {
						name = "<:ground:506477349966053386> HighPerm Maps",
						value = p.data[5].perms,
						inline = true
					} or nil
				end
			end
			if hasPermission(permissions.is_evt, p.discord) then
				icon = icon .. permIcons.is_evt
				if p.data[6] and table.count(p.data[6]) > 0 then
					fields[#fields + 1] = p.data[6].evt and {
						name = "<:thug:472922464083640320> Events Created",
						value = p.data[6].evt,
						inline = true
					} or nil
				end
			end
			if hasPermission(permissions.is_shades, p.discord) then
				icon = icon .. permIcons.is_shades
				if p.data[7] and table.count(p.data[7]) > 0 then

				end
			end
			if hasPermission(permissions.is_fc, p.discord) then
				icon = icon .. permIcons.is_fc
				if p.data[8] and table.count(p.data[8]) > 0 then

				end
			end
			if hasPermission(permissions.is_math, p.discord) then
				icon = icon .. permIcons.is_math
				if p.data[9] and table.count(p.data[9]) > 0 then

				end
			end
			if hasPermission(permissions.is_fash, p.discord) then
				icon = icon .. permIcons.is_fash
				if p.data[10] and table.count(p.data[10]) > 0 then

				end
			end
			if hasPermission(permissions.is_writer, p.discord) then
				icon = icon .. permIcons.is_writer
				if p.data[11] and table.count(p.data[11]) > 0 then
					fields[#fields + 1] = p.data[11].wattpad and {
						name = "<:wattpad:517697014541058049> Wattpad",
						value = "[" .. p.data[11].wattpad .. "](https://www.wattpad.com/user/" .. p.data[11].wattpad .. ")",
						inline = true
					} or nil
				end
			end
		end

		if p.data.bday then
			fields[#fields + 1] = {
				name = ":tada: Birthday",
				value = p.data.bday .. (#p.data.bday == 10 and (" - " .. getAge(p.data.bday)) or ""),
				inline = true
			}
		end

		if p.data.insta then
			fields[#fields + 1] = {
				name = "<:insta:605096338140430396> Instagram",
				value = "[" .. string.gsub(p.data.insta, '_', "\\_") .. "](https://instagram.com/" .. p.data.insta .. "/)",
				inline = true
			}
		end
		
		if p.data.time then
			local code, index = string.match(p.data.time, "^(..)(.*)")
			code = string.upper(code)
			index = tonumber(index) or 1
			local timezone = commands["timezone"].f(message, code, nil, true)
			timezone = timezone[index]

			fields[#fields + 1] = {
				name = ":clock10: Timezone",
				value = "**" .. (timezone.zone or '?') .. "** @ **" .. (timezone.country or '?')  .. "** (" .. code .. ")\n[GMT" .. (not timezone.utc and '' or ((timezone.utc > 0 and '+' or '') .. timezone.utc)) .. "] " .. os.date("%H:%M:%S `%d/%m/%Y`", os.time() + ((timezone.utc or 0) * 3600)),
				inline = true
			}
		end

		if not not activeMembers[p.discord.id] then
			local cachedMembers, loggedMemberMessages = sortActivityTable(activeMembers, function(id) return not message.guild:getMember(id) end)
			local _, o = table.find(cachedMembers, p.discord.id, 1)

			if o then
				fields[#fields + 1] = {
					name = (o > 3 and ":medal: " or ":" .. (o == 1 and "first" or o == 2 and "second" or "third") .. "_place: ") .. "Activity" .. (o > 3 and " [#" .. o .. "]" or ""),
					value = getRate(cachedMembers[o][2], loggedMemberMessages, 10) .. " [" .. cachedMembers[o][2] .. "]",
					inline = true
				}
			end
		end

		toDelete[message.id] = message:reply({
			embed = {
				color = (role.color > 0 and role.color or color.sys),

				thumbnail = { url = p.discord.avatarURL },

				title = (p.data.gender and (p.data.gender == 0 and "<:male:456193580155928588> " or "<:female:456193579308679169> ") or "") .. p.discord.name .. icon,

				description = (p.data.status and "`“" .. p.data.status .. "”` - " or "") .. "<@" .. p.discord.id .. ">",

				fields = fields
			}
		})
	end
}
commands["quote"] = {
	auth = permissions.public,
	description = "Quotes an old message.",
	f = function(message, parameters)
		if parameters and #parameters > 0 then
			local quotedChannel, quotedMessage = string.match(parameters, "<?#?(%d+)>? *%-(%d+)")
			quotedMessage = quotedMessage or string.match(parameters, "%d+")

			if quotedMessage then
				local msg = client:getChannel(quotedChannel or message.channel)
				if msg then
					msg = msg:getMessage(quotedMessage)

					if msg then
						message:delete()
						message:reply({ content = "_Quote from **" .. (message.member or message.author).name .. "**_", embed = buildMessage(msg, message) })
					end
				end
			end
		else
			sendError(message, "QUOTE", "Invalid or missing parameters.", "Use `!quote [channel_id-]message_id`.")
		end
	end
}
commands["remind"] = {
	auth = permissions.public,
	description = "Sets a reminder. Bot will remind you.",
	f = function(message, parameters)
		if parameters and #parameters > 2 then
			local time, order, text = string.match(parameters, "^(%d+%.?%d*)(%a+)[\n ]+(.-)$")
			if time and order and text and #text > 0 then
				time = tonumber(time)
				if order == "ms" then
					time = math.clamp(time, 6e4, 216e5)
				elseif order == 's' then
					time = math.clamp(time, 60, 21600) * 1000
				elseif order == 'm' then
					time = math.clamp(time, 1, 360) * 6e4
				elseif order == 'h' then
					time = math.clamp(time, .017, 6) * 3.6e6
				else
					toDelete[message.id] = message:reply({
						content = "<@!" .. message.author.id .. ">",
						embed = {
							color = color.err,
							title = ":timer: Invalid time magnitude order '" .. order .. "'",
							description = "The available time magnitude orders are **ms**, **s**, **m**, **h**."
						}
					})
					return
				end

				timer.setTimeout(time, coroutine.wrap(function(channel, text, userId, cTime)
					cTime = os.time() - cTime
					local h, m, s = math.floor(cTime / 3600), math.floor(cTime % 3600 / 60), math.floor(cTime % 3600 % 60)
					local info = (((h > 0 and (h .. " hour") .. (h > 1 and "s" or '') .. (((s > 0 and m > 0) and ", ") or (m > 0 and " and ") or '')) or '') .. ((m > 0 and (m .. " minute") .. (m > 1 and "s" or '')) or '') .. ((s > 0 and (" and " .. s .. " second" .. (s > 1 and "s" or ''))) or ''))

					channel:send({
						embed = {
							color = color.sys,
							title = ":bulb: Reminder",
							description = info .. " ago you asked to be reminded about ```\n" .. text .. "```"
						}
					})
				end), message.author, text, message.author.id, os.time())

				local ok = message:reply(":thumbsup:")
				timer.setTimeout(1e4, coroutine.wrap(function(ok)
					ok:delete()
				end), ok)
				message:delete()
			end
		else
			sendError(message, "REMIND", "Invalid or missing parameters.", "Use `!remind time_and_order text`.")
		end
	end
}
commands["report"] = {
	auth = permissions.public,
	description = "Reports a message.",
	f = function(message, parameters)
		local syntax = "To report a message, please make sure that your developer mode on discord is enabled. Use the command `!report message_id report_reason`"

		message:delete()
		if parameters and #parameters > 0 then
			local msg, reason = string.match(parameters, "^(%d+)[\n ]+(.+)$")

			if msg and reason then
				msg = message.channel:getMessage(msg)

				if msg and not msg.embed then
					local embed = buildMessage(msg, message)
					embed.color = color.err
					embed.author = nil
					embed.fields = nil

					local report = client:getChannel(channels["report"]):send({
						content = "Message from **" .. (msg.member or msg.author).name .. "** <@" .. msg.author.id .. ">\nReported by: **" .. message.member.name .. "** <@" .. message.member.id .. ">\n\nSource: <" .. msg.link .. "> | Reason:\n```\n" .. tostring(reason) .. "```",
						embed = embed
					})

					report:addReaction(reactions.wave)
					report:addReaction(reactions.bomb)
					report:addReaction(reactions.boot)
					report:addReaction(reactions.x)
				else
					message.author:send({ embed = { color = color.err, title = "<:ban:504779866919403520> Report", description = "Invalid message. " .. syntax } })
				end
			else
				message.author:send({ embed = { color = color.err, title = "<:ban:504779866919403520> Report", description = syntax } })
			end
		else
			message.author:send({ embed = { color = color.err, title = "<:ban:504779866919403520> Report", description = "Invalid or missing parameters. " .. syntax } })
		end
	end
}
commands["rule"] = {
	auth = permissions.public,
	description = "Quotes a server rule.",
	f = function(message, parameters)
		-- Command by Tocutoeltuco
		local sec, rule = string.match(tostring(parameters), "\xC2?\xA7?(%d-)%.(%d-%.?%d*)")
		if not parameters or not sec then
			return sendError(message, "RULE", "Invalid or missing parameters", "Use `!rule section.rule` or `!rule section.rule.subrule`.")
		end

		local rules = client:getChannel("491723107728621578"):getMessage("575849365608857600").content .. "\n\n" -- Rules
		local sec_name, content = string.match(rules, "§" .. sec .. " __(.-)__ %- [`*]+[^`]+[`*\n]+(.-)\n\n")

		if not sec_name then
			return sendError(message, "RULE", "Invalid section", "The section **" .. sec .. "** does not exist.")
		end

		local _rule_content = string.match(content, rule .. "%) (.+)")

		if not _rule_content then
			return sendError(message, "RULE", "Invalid rule", "The rule **" .. sec .. "." .. rule .. "** does not exist.")
		end

		local rule_content = string.match(_rule_content, "(.+)[\n ]-" .. (math.floor(tonumber(rule)) + 1) .. "%)")

		toDelete[message.id] = message:reply({
			embed = {
				color = color.moderation ,
				title = "<:rule:586043498537418757> " .. sec_name .. " - §" .. sec .. "." .. rule,
				description = (rule_content or _rule_content)
			}
		})
	end
}
commands["serverinfo"] = {
	auth = permissions.public,
	description = "Displays fun info about the server.",
	f = function(message)
		local members = message.guild.members

		local bots = members:count(function(member) return member.bot end)

		local moduleCommands = 0
		for k, v in next, modules do
			if v.commands then
				moduleCommands = moduleCommands + table.count(v.commands)
			end
		end

		local tcommands = table.count(commands)
		local tgcommands = table.count(globalCommands)

		toDelete[message.id] = message:reply({
			content = "<@" .. message.author.id .. ">",
			embed = {
				color = color.interaction,

				author = {
					name = message.guild.name,
					icon_url = message.guild.iconURL
				},

				thumbnail = { url = "https://i.imgur.com/Lvlrhot.png" },

				fields = {
					[1] = {
						name = ":computer: ID",
						value = message.guild.id,
						inline = true
					},
					[2] = {
						name = ":crown: Owner",
						value = "<@" .. message.guild.ownerId .. ">",
						inline = true
					},
					[3] = {
						name = ":speech_balloon: Channels",
						value = ":pencil2: Text: " .. #message.guild.textChannels .. "\n:speaker: Voice: " .. #message.guild.voiceChannels .. "\n:card_box: Category: " .. #message.guild.categories,
						inline = true
					},
					[4] = {
						name = ":calendar: Created at",
						value = os.date("%Y-%m-%d %I:%M%p", message.guild.createdAt),
						inline = true
					},
					[5] = {
						name = ":necktie: Roles",
						value = #message.guild.roles,
						inline = true
					},
					[6] = {
						name = ":robot: Bots",
						value = bots,
						inline = true
					},
					[7] = {
						name = ":family_mmgb: Members",
						value = string.format("<:%s> Online: %s | <:%s> Away: %s | <:%s> Busy: %s | <:offline:456197711457419276> Offline: %s\n\n:raising_hand: **Total:** %s\n\n<:wheel:456198795768889344> **Module Members**: %s\n<:lua:468936022248390687> **Developers**: %s\n<:p5:468937377981923339> **Artists**: %s\n:earth_americas: **Translators**: %s\n<:p41:463508055577985024> **Mappers**: %s\n<:idea:559070151278854155> **Event Managers**: %s\n<:illuminati:542115872328646666> **Shades Helpers**: %s\n<:fun:559069782469771264> **Funcorps**: %s\n:triangular_ruler: **Mathematicians**: %s\n<:dance:468937918115741718> **Fashionistas**: %s\n:pencil: **Writers**: %s", reactions.online, members:count(function(member)
							return member.status == "online"
						end), reactions.idle, members:count(function(member)
							return member.status == "idle"
						end), reactions.dnd, members:count(function(member)
							return member.status == "dnd"
						end), members:count(function(member)
							return member.status == "offline"
						end), message.guild.totalMemberCount - bots, members:count(function(member)
							return member:hasRole(roles["module member"])
						end), members:count(function(member)
							return member:hasRole(roles["developer"])
						end), message.guild.members:count(function(member)
							return member:hasRole(roles["artist"])
						end), members:count(function(member)
							return member:hasRole(roles["translator"])
						end), members:count(function(member)
							return member:hasRole(roles["mapper"])
						end), members:count(function(member)
							return member:hasRole(roles["event manager"])
						end), members:count(function(member)
							return member:hasRole(roles["shades helper"])
						end), members:count(function(member)
							return member:hasRole(roles["funcorp"])
						end), members:count(function(member)
							return member:hasRole(roles["mathematician"])
						end), members:count(function(member)
							return member:hasRole(roles["fashionista"])
						end), members:count(function(member)
							return member:hasRole(roles["writer"])
						end)), 
						inline = false
					},
					[8] = {
						name = ":exclamation: Commands",
						value = "**Total**: " .. (tcommands + tgcommands + moduleCommands) .. "\n\n**Bot commands**: " .. tcommands .. "\n**Global Commands**: " .. tgcommands .. "\n**Module Commands**: " .. moduleCommands,
						inline = false
					},
				},
			}
		})
	end
}
commands["tex"] = {
	auth = permissions.public,
	description = "Displays a mathematical formula using LaTex syntax.",
	f = function(message, parameters)
		if parameters and #parameters > 0 then
			local head, body = http.request("POST", "https://quicklatex.com/latex3.f", nil, "formula=" .. encodeUrl("\\displaystyle " .. parameters) .. "&fsize=21px&fcolor=c2c2c2&out=1&preamble=\\usepackage{amsmath}\n\\usepackage{amsfonts}\n\\usepackage{amssymb}")
			body = string.match(body, "(http%S+)")
			if body then
				body = string.gsub(body, "http:", "https:", 1)
				toDelete[message.id] = message:reply({ file = tostring(imageHandler.fromUrl(body)) })
			else
				sendError(message, "TEX", "Internal Error.", "Try again later.")
			end
		else
			sendError(message, "TEX", "Invalid or missing parameters.", "Use `!tex latex_formula`.")
		end
	end
}
commands["tfmprofile"] = {
	auth = permissions.public,
	description = "Displays your profile on Transformice.",
	f = function(message, parameters)
		if parameters and #parameters > 2 then
			parameters = string.nickname(parameters)
			local head, body = http.request("GET", "https://api.club-mice.com/mouse.php?name=" .. encodeUrl(parameters))
			body = json.decode(body)

			if body then
				if not body.id then 
					return sendError(message, "TFMPROFILE", "Player '" .. parameters .. "' not found.")
				end

				if not body.title_id then
					body.title_id = "«Little Mouse»"
				else
					body.title_id = string.gsub(body.title_id, "&amp;", '&')
					body.title_id = string.gsub(body.title_id, "\\u00ab", '«')
					body.title_id = string.gsub(body.title_id, "\\u00bb", '»')
				end

				local level, remain, need = expToLvl(tonumber(body.experience))

				local tribe
				if body.id_tribe then
					local _
					_, tribe = http.request("GET", "https://api.club-mice.com/tribe.php?tribe=" .. body.id_tribe)
					tribe = json.decode(tribe)
					if tribe then
						tribe = tribe.name
					end
				end

				local soulmate
				if body.id_spouse then
					local _
					_, soulmate = http.request("GET", "https://api.club-mice.com/mouse.php?name=" .. body.id_spouse)
					soulmate = json.decode(soulmate)
					if soulmate then
						soulmate = soulmate.name
					end
				end

				toDelete[message.id] = message:reply({
					embed = {
						color = color.atelier801,
						title = "<:tfm_cheese:458404666926039053> Transformice Profile - " .. parameters .. (body.gender == "2" and " <:male:456193580155928588>" or body.gende == "1" and " <:female:456193579308679169>" or ""),
						description = --[[(body.registration_date == "" and "" or (":calendar: " .. body.registration_date .. "\n\n")) .. ]]"**Level " .. level .. "** " .. getRate(math.percent(remain, (remain + need)), 100, 5) .. "\n" .. (tribe and ("\n<:tribe:458407729736974357> **Tribe :** " .. tribe) or "") .. --[["\n```\n" .. body.title_id .. "```"]]"\n<:shaman:512015935989612544> " .. body.saved_mice .. " / " .. body.saved_mice_hard .. " / " .. body.saved_mice_divine .. "\n<:tfm_cheese:458404666926039053> **Shaman cheese :** " .. body.shaman_cheese .. "\n\n<:racing:512016668038266890> **Firsts :** " .. body.first .. " " .. getRate(math.percent(body.first, body.round_played, 100), 100, 5) .. "\n<:tfm_cheese:458404666926039053> **Cheese: ** " .. body.cheese_gathered .. " " .. getRate(math.percent(body.cheese_gathered, body.round_played, 100), 100, 5) .. "\n\n<:bootcamp:512017071031451654> **Bootcamps :** " .. body.bootcamp .. (soulmate and("\n\n:revolving_hearts: **" .. normalizeDiscriminator(soulmate) .. (body.marriage_date and ("** since **" .. body.marriage_date .. "**") or "**")) or ""),
						thumbnail = { url = "http://avatars.atelier801.com/" .. (body.id % 10000) .. "/" .. body.id .. ".jpg" }
					}
				})
			else 
				return sendError(message, "TFMPROFILE", "Internal Error.", "Try again later.")
			end
		else 
			return sendError(message, "TFMPROFILE", "Invalid or missing parameters.", "Use `!tfmprofile Playername`")
		end
	end
}
commands["timezone"] = {
	auth = permissions.public,
	description = "Displays the timezone of a country.",
	f = function(message, parameters, _, toReturn)
		if parameters and #parameters == 2 then
			parameters = string.upper(parameters)

			local head, body = http.request("GET", "https://pastebin.com/raw/di8TMeeG") -- https://pastebin.com/raw/zJYbD25i
			if body then
				body = load("return " .. body)()
				if not body[parameters] then
					return sendError(message, "TIMEZONE", "Country code not found", "Couldn't find '" .. parameters .. "'")
				end

				if toReturn then
					return body[parameters]
				end
				toDelete[message.id] = message:reply({
					embed = {
						color = color.sys,
						title = body[parameters][1].country,
						description = concat(body[parameters], "\n", function(index, value)
							return index .. " - **" .. value.zone .. "** - " .. os.date("%H:%M:%S `%d/%m/%Y`", os.time() + ((value.utc or 0) * 3600))
						end, nil, nil, ipairs)
					}
				})
			end
		else
			sendError(message, "TIMEZONE", "Invalid or missing parameters.", "Use `!timezone country_code`.")
		end
	end
}
commands["topic"] = {
	auth = permissions.public,
	description = "Displays a forum message.",
	f = function(message, parameters)
		local syntax = "Use `!topic https://atelier801.com/topic`"

		if parameters and #parameters > 0 then
			parameters = string.gsub(parameters, "http:", "https:", 1)
			if not string.find(parameters, "https://atelier801%.com/topic") then
				return sendError(message, "TOPIC", "Invalid parameters.", "You must insert an atelier801's url as parameter.\n" .. syntax)
			end

			local code = string.match(parameters, "(%d+)$")
			if code then
				local head, body = http.request("GET", parameters, {
					{ "Accept-Language", "en-US,en;q=0.9" }
				})
				if body then
					-- Two matches because Lua sucks
					local commu, section, title = string.match(body, '<a href="section%?f=%d+&s=%d+" class=" ">.-<img src="/img/pays/(..)%.png".-/> (.-) +</a>.-class=" active">(.-) </a> +</li> +</ul> +<div')

					local avatarImg = '.-<img src="(http://avatars%.atelier801%.com/.-)"'
					local toMatch = { '<div id="m' .. code .. '"', '.-data%-afficher%-secondes="false">(%d+)</span>.-<img src="/img/pays/(..)%.png".-(%S+)<span class="nav%-header%-hashtag">(#%d+).-#' .. code .. '</a>.-<span class="coeur".-(%d+).-id="message_%d+">(.-)</div> +</div>' }

					local avatar, timestamp, playerCommu, playerName, playerDiscriminator, heart, msg = string.match(body, toMatch[1] .. avatarImg .. toMatch[2])
					if not avatar then
						avatar = "https://i.imgur.com/Lvlrhot.png"
						timestamp, playerCommu, playerName, playerDiscriminator, heart, msg = string.match(body, toMatch[1] .. toMatch[2])
					end

					if commu then
						local internationalFlag = "<:international:458411936892190720>"
						playerName = playerName .. playerDiscriminator

						msg = string.sub(htmlToMarkdown(msg), 1, 1000)
						local fields = {
							[1] = {
								name = "Author",
								value = (countryFlags[string.upper(playerCommu)] or internationalFlag) .. " [" .. normalizeDiscriminator(playerName) .. "](https://atelier801.com/profile?pr=" .. encodeUrl(playerName) .. ")",
								inline = true
							},
							[2] = {
								name = "Message #" .. code,
								value = msg .. (string.count(msg, "```") % 2 ~= 0 and "```" or ""),
								inline = false
							},
						}
						if heart ~= '0' then
							fields[3] = fields[2]
							fields[2] = {
								name = "Prestige",
								value = ":heart: " .. heart,
								inline = true
							}
						end

						toDelete[message.id] = message:reply({
							embed = {
								color = color.interaction,
								title = (countryFlags[string.upper(commu)] or internationalFlag) .. " " .. section .. " / " .. string.gsub(title, "<.->", ''),
								fields = fields,
								thumbnail = { url = avatar },
								timestamp = discordia.Date().fromMilliseconds(timestamp):toISO()
							}
						})
					end
				else
					return sendError(message, "TOPIC", "Internal Error", "Try again later.")
				end
			else
				return sendError(message, "TOPIC", "Message code not found.", "You must insert an atelier801's url as parameter, with section, page, topic and message. Example: `topic?f=0&t=000000&p=000#m0000`.\n" .. syntax)
			end
		else
			return sendError(message, "TOPIC", "Invalid or missing parameters.", syntax)
		end
	end
}
commands["tree"] = {
	auth = permissions.public,
	description = "Displays the Lua tree.",
	f = function(message, parameters)
		local src, pathExists = envTfm, true
		local indexName

		if parameters and #parameters > 0 then
			for p in string.gmatch(parameters, "[^%.]+") do
				if type(src) ~= "table" then
					pathExists = false
					break
				end

				p = tonumber(p) or p
				src = src[p]

				if not src then
					pathExists = false
					break
				elseif type(src) ~= "table" then
					indexName = p
				end
			end

			if not pathExists then
				toDelete[message.id] = message:reply({
					content = "<@!" .. message.author.id .. ">",
					embed = {
						color = color.err,
						title = "<:wheel:456198795768889344> Invalid path",
						description = "The path **`" .. parameters .. "`** doesn't exist"
					}
				})
				return
			end
		end

		local sortedSrc = { }

		if type(src) == "table" then
			local counter = 0
			for k, v in next, src do
				counter = counter + 1
				sortedSrc[counter] = { k, tostring(v), type(v) }
			end
		else
			sortedSrc[1] = { tostring(indexName), tostring(src), type(src) }
		end
		table.sort(sortedSrc, function(value1, value2)
			if value1[3] == "number" and value2[3] == "number" then
				value1 = tonumber(value1[2])
				value2 = tonumber(value2[2])
			else
				value1 = value1[1]
				value2 = value2[1]
			end

			return value1 < value2
		end)

		local lines = splitByLine(concat(sortedSrc, "\n", function(index, value)
			return "`" .. value[3] .. "` **" .. value[1] .. "** : `" .. value[2] .. "`" 
		end))

		local msgs = { }
		for line = 1, #lines do
			msgs[line] = message:reply({
				content = (line == 1 and "<@!" .. message.author.id .. ">" or nil),
				embed = {
					color = color.atelier801,
					title = (line == 1 and "<:wheel:456198795768889344> " .. (parameters and ("'" .. parameters .. "' ") or '') .. "Tree" or nil),
					description = lines[line]
				}
			})
		end

		toDelete[message.id] = msgs
	end
}
commands["translate"] = {
	auth = permissions.public,
	description = "Translates a sentence using Google Translate. Professional translations: <@&494665355327832064>",
	f = function(message, parameters)
		local syntax = "Use `!translate [from_language-]to_language sentence`."

		if parameters and #parameters > 0 then
			local language, content = string.match(parameters, "(%S+)[ \n]+(.+)$")
			if language and content and #content > 0 then
				language = string.lower(language)
				local sourceLanguage, targetLanguage = string.match(language, "^(..)[%-~]>?(..)$")
				if not sourceLanguage then
					sourceLanguage = "auto"
					targetLanguage = language
				end

				content = string.sub(content, 1, 250)
				local head, body = http.request("GET", "https://translate.googleapis.com/translate_a/single?client=gtx&sl=" .. sourceLanguage .. "&tl=" .. targetLanguage .. "&dt=t&q=" .. encodeUrl(content), { { "User-Agent","Mozilla/5.0" } })
				body = json.decode(tostring(body))

				if body and #body > 0 then
					sourceLanguage = string.upper((sourceLanguage == "auto" and tostring(body[3]) or sourceLanguage))
					targetLanguage = string.upper(targetLanguage)

					sourceLanguage = countryFlags_Aliases[sourceLanguage] or sourceLanguage
					targetLanguage = countryFlags_Aliases[targetLanguage] or targetLanguage

					toDelete[message.id] = message:reply({
						embed = {
							color = color.interaction,
							title = ":earth_americas: Quick Translation",
							description = (countryFlags[countryFlags_Aliases[sourceLanguage] or sourceLanguage] or "") .. "@**" .. sourceLanguage .. "**\n```\n" .. content .. "```" .. (countryFlags[countryFlags_Aliases[targetLanguage] or targetLanguage] or "") .. "@**" .. string.upper(targetLanguage) .. "**\n```\n" .. concat(body[1], ' ', function(index, value)
								return value[1]
							end) .. "```"
						}
					})
				else
					sendError(message, "TRANSLATE", "Internal Error.", "Couldn't translate ```\n" .. parameters .. "```")
				end
			else
				sendError(message, "TRANSLATE", "Invalid parameters.", syntax)
			end
		else
			sendError(message, "TRANSLATE", "Missing parameters.", syntax)
		end
	end
}
commands["xml"] = {
	auth = permissions.public,
	description = "Displays a map based on the XML.",
	f = function(message, parameters)
		if parameters and #parameters > 0 then
			if string.find(parameters, "pastebin.com/raw/") then
				local head, body = http.request("GET", parameters)

				if body then
					parameters = "```\n" .. body .. "```"
				else
					return sendError(message, "XML", "Invalid pastebin link.")
				end
			end

			local _
			_, parameters = string.match(parameters, "`(`?`?)(.*)%1`")

			if not parameters then
				return sendError(message, "XML", "Invalid syntax.", "Use `!xml ``` XML ```.`")
			end

			if string.find(parameters, "<C>") then
				local head, body = http.request("POST", "https://xml-drawer.herokuapp.com/", { { "content-type", "application/x-www-form-urlencoded" } }, "xml=" .. encodeUrl(parameters))

				if head.code == 200 then
					local file = io.open(message.author.id .. ".png", 'w')
					file:write(body)
					file:flush()
					file:close()

					toDelete[message.id] = message:reply({
						content = "<@!" .. message.author.id .. "> | XML ~> " .. (#parameters / 1000) .. "kb",
						file = message.author.id .. ".png"
					})

					os.remove(message.author.id .. ".png")
				else
					sendError(message, "XML", "Fatal error. Try again later.")
				end
			else
				sendError(message, "XML", "Invalid xml.")
			end
		else
			sendError(message, "XML", "Invalid or missing parameters.", "Use `!xml ``` XML ``` ` or `!xml pastebin_link`.")
		end
	end,
}
	-- Not public
commands["pin"] = {
	auth = permissions.has_power,
	description = "Pins or Unpins a message in an #prj channel.",
	f = function(message, parameters, category)
		if not string.find(string.lower(message.channel.name), "^prj_") then
			return sendError(message, "PIN", "This command cannot be used in this channel.")
		end

		local syntax = "Use `!pin message_id`."

		if parameters and #parameters > 0 then
			local msg = message.channel:getMessage(parameters)
			if msg then
				if msg.pinned then
					msg:unpin()
				else
					msg:pin()
				end
				message:delete()
			else
				sendError(message, "PIN", "Message not found.", "Use a valid message id on this channel.\n" .. syntax)
			end
		else
			sendError(message, "PIN", "Invalid or missing parameters.", syntax)
		end
	end
}
commands["poll"] = {
	auth = permissions.has_power,
	description = "Creates a poll.",
	f = function(message, parameters)
		if table.find(polls, message.author.id, "authorID") then
			return sendError(message, "POLL", "Poll limit", "There is already a poll made by <@!" .. message.author.id .. ">.")
		end

		if parameters and #parameters > 0 then
			local time, option, question = 10, { "Yes", "No" }

			local custom = string.find(parameters, '`')

			if custom then
				local output, options
				output, question, time, options = string.match(parameters, "`(`?`?)(.*)%1`[ \n]+(%d+)[ \n]+(.+)")

				if not question then return end
				time = math.clamp(tonumber(time), 5, 60)
				if not time then return end

				option = string.split(options, (string.find(options, "`") and "`(.-)`" or "%S+"))
				if not option[2] then return end
			else
				question = string.sub(parameters, 1, 250)
			end

			local img = message.attachment and message.attachment.url

			local poll = message:reply({
				embed = {
					color = color.interaction,
					author = {
						name = message.member.name .. " - Poll",
						icon_url = message.author.avatarURL
					},
					description = "```\n" .. question .. "```\n:one: " .. option[1] .. "\n:two: " .. option[2],
					image = (img and { url = img } or nil),
					footer = {
						text = "Ends in " .. time .. " minutes."
					}
				}
			})
			if not poll then
				return sendError(message, "POLL", "Fatal Error", "Try this command again later.")
			end

			for i = 1, #polls.__REACTIONS do
				poll:addReaction(polls.__REACTIONS[i])
			end

			polls[poll.id] = {
				channel = message.channel.id,
				authorID = message.author.id,
				votes = {0, 0},
				time = os.time() + (time * 60),
				option = option
			}

			message:delete()
		else
			sendError(message, "POLL", "Invalid or missing parameters.", "Use `!poll question` or `!poll ```question``` poll_time` ` `poll_option_1` ` ` ` ` `poll_option_2` ` ` `.")
		end
	end
}
commands["prj"] = {
	auth = permissions.has_power,
	description = "Creates a new channel to discuss about a new project. [- means delete]",
	f = function(message, parameters)
		if not categories[message.channel.category.id] then
			return sendError(message, "PRJ", "This command cannot be used in this category.")
		end

		local syntax = "Use `!prj project_name(3+ characters) @member @member ...` or `!prj @member @member ...` or `!prj - [@member ...]`."

		if parameters and #parameters > 0 then
			local p = string.split(parameters, "[^\n ]+")
			local isPrj = string.find(string.lower(message.channel.name), "^prj_")

			if p[1] then
				local del = p[1] == '-'
				local addUser = ((string.find(p[1], "^<") or isPrj) and not del) and 1 or 2

				local members, counter, selfAdded = { }, 0, false
				if p[addUser] then
					for i = addUser, #p do
						local member = string.match(p[i], "<@!?(%d+)>")
						if member then
							counter = counter + 1
							if member ~= message.member.id then
								members[counter] = message.guild:getMember(member)
							else
								members[counter] = message.member
								selfAdded = true
							end
						else
							return sendError(message, "PRJ", "Invalid parameter.", "`" .. tostring(p[i]) .. "` is not a member.")
						end
					end
				end
				if not del and not selfAdded then
					counter = counter + 1
					members[counter] = message.member
				end

				if del or addUser == 1 then
					if not isPrj then
						return sendError(message, "PRJ", "This command cannot be used in this channel.")
					end

					if del then
						if p[2] then -- Del user(s)
							for member = 1, counter do
								message.channel:getPermissionOverwriteFor(members[member]):delete()
							end
						else -- Del channel
							message.channel:delete()
						end
					else -- Add user(s)
						for member = 1, counter do
							message.channel:getPermissionOverwriteFor(members[member]):allowPermissions(table.unpack(permissionOverwrites.prj.allowed))
						end
					end
				else
					if #p[1] < 3 then
						return sendError(message, "PRJ", "Invalid event name.", "A project name must have 3 characters or more.")
					end

					local channel = message.guild:createTextChannel("prj_" .. p[1])
					channel:setCategory(message.channel.category.id)

					-- Can't read
					channel:getPermissionOverwriteFor(message.guild.defaultRole):denyPermissions(table.unpack(permissionOverwrites.prj.denied))

					for member = 1, counter do
						-- Can read
						channel:getPermissionOverwriteFor(members[member]):allowPermissions(table.unpack(permissionOverwrites.prj.allowed))
					end
					message:delete()
				end
			else
				sendError(message, "PRJ", "Missing parameters.", syntax)
			end
		else
			sendError(message, "PRJ", "Invalid or missing parameters.", syntax)
		end
	end
}
commands["resign"] = {
	auth = permissions.has_power,
	description = "Leaves a team/role.",
	f = function(message, parameters)
		if not categories[message.channel.category.id] then
			return sendError(message, "RESIGN", "This command cannot be used in this category.")
		end

		if parameters and authIds[message.author.id] then
			local syntax = "Use `!resign @role_member_name`"

			local member = string.match(parameters, "%d+")
			if not member then
				return sendError(message, "RESIGN", "Invalid or missing parameters.", syntax)
			end

			member = message.guild:getMember(member)
			if not member then
				return sendError(message, "RESIGN", "Member doesn't exist.")
			end

			parameters = member
		else
			parameters = message.guild:getMember(message.author.id)
		end

		local role = message.channel.category.permissionOverwrites:find(function(role)
			return roles[role.id]
		end)
		role = role and message.guild:getRole(role.id)

		if not role then
			return sendError(message, "RESIGN", "Role not found.", "Report it to <@285878295759814656>")
		end

		if not parameters:hasRole(role.id) then
			return sendError(message, "RESIGN", "You cannot resign from a role you do not have.", "You don't have the role '" .. role.name .. "'.")
		end

		parameters:removeRole(role.id)
		if specialRoleColor[role.id] then
			parameters:removeRole(specialRoleColor[role.id])
		end

		local msg = {
			embed = {
				color = role.color,
				title = "Demotion :(",
				thumbnail = { url = parameters.user.avatarURL },
				description = "**" .. parameters.name .. "** is not a(n) `" .. string.upper(role.name) .. "` anymore.",
				footer = { text = "Unset by " .. message.member.name }
			}
		}
		message:reply(msg)
		client:getChannel(channels["role-log"]):send(msg)
		message:delete()
	end
}
	-- Module staff
commands["cmd"] = {
	auth = permissions.is_staff,
	description = "Creates a command for the #module category.",
	f = function(message, parameters, category)
		if not (category and string.sub(category, 1, 1) == "#") then
			return sendError(message, "CMD", "This command cannot be used in this category.")
		end

		local syntax = "Use `!cmd 0|1 command_name [ script ``` script ``` ] [ value[[command_content]] ] [ title[[command_title]] ] [ description[[command_description]] ]`."

		if parameters and #parameters > 0 then
			local script, content, title, description = getCommandFormat(parameters)
			local authLevel, command = string.match(parameters, "^(%d)[\n ]+([%a][%w_%-]+)[\n ]+")

			if authLevel then
				authLevel = tonumber(authLevel)
				if authLevel < 2 then
					if command then
						command = string.lower(command)

						if authLevel == 1 and modules[category].commands[command] then
							return sendError(message, "CMD", "This command already exists.")
						end

						local cmd = getCommandTable(message, script, content, title, description)
						if type(cmd) == "string" then
							return sendError(message, "CMD", cmd)
						end
						cmd.auth = (authLevel == 0 and permissions.public or permissions.is_staff)

						modules[category].commands[command] = cmd

						save("b_modules", modules, false, true)

						message:reply({
							embed = {
								color = color.sys,
								description = "Command `" .. category .. "." .. command .. "` created successfully!",
								footer = { text = "By " .. message.member.name }
							}
						})
					else
						sendError(message, "CMD", "Invalid syntax.", syntax)
					end
				else
					sendError(message, "CMD", "Invalid level flag.", "The authorization level must be 0 (Users) or 1 (Staff).")
				end
			else
				sendError(message, "CMD", "Invalid syntax.", syntax)
			end
		else
			sendError(message, "CMD", "Invalid or missing parameters.", syntax)
		end
	end
}
	-- Developer
commands["lua"] = {
	auth = permissions.is_dev,
	description = "Loads a Lua code.",
	f = function(message, parameters, _, isTest, compEnv)
		local syntax = "Use `!lua ```code``` `."

		if parameters and #parameters > 2 then
			local foo
			foo, parameters = string.match(parameters, "`(`?`?)(.*)%1`")

			if not parameters or #parameters == 0 then
				return sendError(message, "Lua", "Invalid syntax.", syntax)
			end

			local lua_tag, final = string.find(string.lower(parameters), "^lua\n+")
			if lua_tag then
				parameters = string.sub(parameters, final + 1)
			end

			local hasAuth = authIds[message.author.id] and not isTest

			local dataLines = {}
			local repliedMessages = {}

			local _ENV = getLuaEnv()
			local ENV = (hasAuth and devENV or moduleENV) + _ENV
			if compEnv then
				-- parameters
				if not compEnv.parameters then
					ENV.parameters = nil
				else
					ENV = ENV + compEnv
				end
			end
			ENV.discord = { }

			--[[Doc
				"The id of the user that ran **!lua**."
				!string|int
			]]
			ENV.discord.authorId = message.author.id
			--[[Doc
				"The name and discriminator of the user that ran **!lua**."
				!string
			]]
			ENV.discord.authorName = message.author.tag
			--[[Doc
				"The id of the script message from **!lua**."
				!string|int
			]]
			ENV.discord.messageId = message.id

			local getMessage = function(message)
				return {
					createdAt = message.createdAt,
					id = message.id,
					timestamp = message.timestamp,
					attachment = message.attachment,
					attachments = message.attachments,
					author = {
						createdAt = message.author.createdAt,
						id = message.author.id,
						timestamp = message.author.timestamp,
						avatar = message.author.avatar,
						avatarURL = message.author.avatarURL,
						defaultAvatar = message.author.defaultAvatar,
						defaultAvatarURL = message.author.defaultAvatarURL,
						discriminator = message.author.discriminator,
						mentionString = message.author.mentionString,
						name = message.author.name,
						tag = message.author.tag,
						fullname = message.author.tag,
						username = message.author.username
					},
					cleanContent = message.cleanContent,
					content = message.content,
					editedTimestamp = message.editedTimestamp,
					link = message.link,
					member = message.member and ({
						status = message.member.status,
						deafened = message.member.deafened,
						highestRole = message.member.highestRole.id,
						joinedAt = message.member.joinedAt,
						muted = message.member.muted,
						name = message.member.name,
						nickname = message.member.nickname
					}) or nil,
					mentionsEveryone = message.mentionsEveryone,
					oldContent = message.oldContent
				}
			end

			ENV.discord.message = getMessage(message)

			ENV.discord.messageContent = message.content
			--[[Doc
				"Gets the last message sent before the command. (content, authorId, authorName)"
				>table
			]]
			ENV.discord.lastMessage = function()
				local lastMessage = message.channel:getMessagesBefore(message.id, 1):random()
				if lastMessage then
					return {
						content = lastMessage.content,
						authorId = lastMessage.author.id,
						authorName = lastMessage.author.tag
					}
				end
				return { }
			end
			--[[Doc
				"Deletes a message sent by the bot. (3 minutes tolerance)"
				@msgId string|int
			]]
			ENV.discord.delete = function(msgId)
				assert(msgId, "Missing parameters in discord.delete")

				local msg = message.channel:getMessage(msgId)
				assert(msg, "Message not found")

				assert((msg.channel.id ~= channels["commu"] and msg.channel.id ~= channels["modules"]), "Message deletion denied.")

				assert((os.time() - (60 * 3)) < discordia.Date.fromISO(msg.timestamp):toSeconds(), "The message cannot be deleted after 5 minutes.")

				local canDelete = msg.author.id == message.author.id
				if not canDelete then
					for i = 1, #repliedMessages do
						if repliedMessages[i].id == msgId then
							canDelete = true
							break
						end
					end
				end

				if canDelete then
					msg:delete()
				end
			end
			--[[Doc
				"Performs a GET HTTP request."
				@url string
				@header table*
				@body string*
				@token string|table*
				>table, string
			]]
			ENV.discord.http = function(url, header, body, token)
				assert(url, "Missing url link in discord.http")

				if token then
					if type(token) == "string" then
						if (tokens[token] and string.find(url, "^" .. token_whitelist[token])) then
							url = url .. tokens[token]
						end
					else
						if (token[2] and tokens[token[2]] and string.find(url, "^" .. token_whitelist[token[2]])) then
							if not header then
								header = { }
							end
							header[#header + 1] = { token[1], tokens[token[2]] }
						end
					end
				end

				local isPost = not not string.find(url, "^!")
				if isPost then
					url = string.sub(url, 2)
				end
				return http.request((isPost and "POST" or "GET"), url, header, body)
			end
			--[[Doc
				"Sends a message in the channel."
				@text string|table
				>string|int|boolean
			]]
			ENV.discord.reply = function(text)
				if #repliedMessages < (hasAuth and 50 or 30) then
					assert(text, "Missing parameter in discord.reply")

					if type(text) == "table" then
						if text.content then
							text.content = string.gsub(text.content, "[@!]*<[@!]+(%d+)>", function(id)
								return "<" .. (id == message.author.id and '' or "\\") .. "@" .. id .. ">"
							end)
							text.content = string.gsub(text.content, "@here", "@ here")
							text.content = string.gsub(text.content, "@everyone", "@ everyone")
						end
					else
						text = string.gsub(text, "[@!]*<[@!&]+(%d+)>", function(id)
							return "<" .. (id == message.author.id and '' or "\\") .. "@" .. id .. ">"
						end)
						text = string.gsub(text, "@here", "@ here")
						text = string.gsub(text, "@everyone", "@ everyone")
					end

					local msg = message:reply(text)
					assert(msg, "Missing content in discord.reply")

					repliedMessages[#repliedMessages + 1] = msg
					return msg.id
				end
				return false
			end
			--[[Doc
				"Sends an error message in the channel."
				@command string
				@err string
				@description string*
			]]
			ENV.discord.sendError = function(command, err, description)
				assert(err, "Missing error title in discord.sendError")

				sendError(message, command, err, description)
			end
			--[[Doc
				"Loads a Lua code given in a string."
				@src string
				>function
			]]
			ENV.discord.load = function(src)
				assert(src, "Source can't be nil in discord.load")

				return load(addRuntimeLimit(src, message), '', 't', ENV)
			end
			--[[Doc
				"The time, in minutes, since the last bot reboot"
				>int
			]]
			ENV.getTime = function()
				return minutes
			end
			--[[Doc
				"Prints a string in the channel."
				@... *
			]]
			ENV.print = function(...)
				local r = printf(...)
				dataLines[#dataLines + 1] = r == '' and ' ' or r
			end

			ENV.printt = function(s, ...)
				s = table.tostring(s, true, true, ...)
				return ENV.print((#s < 1900 and ("```Lua\n" .. s .. "```") or s))
			end

			if hasAuth then
				--[[Doc
					~
					"The channel where the message was sent."
					!Discordia.GuildTextChannel
				]]
				ENV.channel = message.channel
				--[[Doc
					~
					"The message that was sent."
					!Discordia.Message
				]]
				ENV.message = message
				--[[Doc
					~
					"The guild that got the new message."
					!Discordia.Guild
				]]
				ENV.guild = message.guild
			else
				if not isTest then
					parameters = addRuntimeLimit(parameters, message)
				end
			end

			local getOwner = function(message, name)
				local owner
				if isTest == debugAction.cmd then
					local cmd = string.match(message.content, "!(%S+)")
					cmd = string.lower(tostring(cmd))
					assert(globalCommands[cmd], "Source command not found (" .. name .. ").")

					owner = globalCommands[cmd].author
				else
					owner = message.author.id
					assert(hasPermission(permissions.is_module, message.guild:getMember(owner)), "You cannot use this function (" .. name .. ").")
				end
				return owner
			end

			ENV.discord.getData = function(userId)
				assert(userId, "User id can't be nil in discord.getData")

				local owner = getOwner(message, "getData")

				return ((cmdData[owner] and cmdData[owner][userId]) and base64.decode(cmdData[owner][userId]) or '')
			end
			ENV.discord.saveData = function(userId, data)
				assert(userId, "User id can't be nil in discord.saveData")
				userId = tostring(userId)
				assert(data, "Data can't be nil in discord.saveData")
				data = tostring(data)
				assert(#data <= 8000, "Data can't exceed 8000 characters")

				local owner = getOwner(message, "saveData")

				if not cmdData[owner] then
					cmdData[owner] = { }
				end
				cmdData[owner][userId] = (data ~= '' and base64.encode(data) or nil)
				return true
			end

			ENV.getImage = function(url)
				assert(url, "Url can't be nil in getImage")

				local owner = getOwner(message, "getImage")

				return tostring(imageHandler.fromUrl(url))
			end

			ENV.discord.addReaction = function(messageId, reaction)
				assert(messageId, "Message id can't be nil in discord.addReaction")
				assert(reaction, "Reaction can't be nil in discord.addReaction")

				messageId = tostring(messageId)
				local msg = message.channel:getMessage(messageId)
				assert(msg, "Message '" .. tostring(messageId) .. "' not found.")
				assert((os.time() - (60 * 5)) < discordia.Date.fromISO(msg.timestamp):toSeconds(), "You can't add a reaction to a message that has been sent for longer than 5 minutes.")

				return not not msg:addReaction(reaction)
			end

			ENV.discord.retrieveReactions = function(messageId)
				messageId = tostring(messageId)
				local msg = message.channel:getMessage(messageId)
				assert(msg, "Message '" .. tostring(messageId) .. "' not found.")

				local reactions, counter = { }, 0
				for reaction in msg.reactions:iter() do
					reactions[reaction.emojiHash] = { }
					counter = 0
					for member in reaction:getUsers():iter() do
						counter = counter + 1
						reactions[reaction.emojiHash][counter] = member.id
					end
				end

				return reactions
			end

			ENV.discord.getMemberId = function(memberName)
				assert(memberName, "Member name can't be nil in discord.getMemberId")
				memberName = tostring(memberName)

				local member = message.guild.members:find(function(m)
					return m.tag == memberName or m.nickname == memberName or m.name == memberName
				end)

				return member and member.id
			end

			ENV.discord.isMember = function(userId)
				assert(userId, "Member id cannot be nil in discord.isMember")
				return message.guild:getMember(userId) ~= nil
			end

			ENV.discord.sendPrivateMessage = function(content)
				assert(content, "Content cannot be nil in discord.sendPrivateMessage")
				if type(content) ~= "table" then
					content = tostring(content)
				end

				local msg = message.author:send(content)
				return msg and msg.id
			end

			ENV.discord.getMessage = function(channelId, messageId)
				assert(channelId, "Channel id cannot be nil in discord.getMessage")
				assert(messageId, "Message id cannot be nil in discord.getMessage")
				channelId, messageId = tostring(channelId), tostring(messageId)

				local msg = client:getChannel(channelId):getMessage(messageId)
				return msg and getMessage(msg) or nil
			end

			ENV.getmetatable = function(x)
				if type(x) == "string" then
					return "gtfo"
				end
				return getmetatable(x)
			end

			ENV.setmetatable = function(x, m)
				if x == string or x == math or x == table or type(x) == "string" or x == ENV or x == _G then
					return "gtfo"
				end
				return setmetatable(x, m)
			end

			ENV.test = function(...)
				local t, l = test(...)
				for i = 1, l do
					ENV.print(t[i])
				end
			end
			
			local func, syntaxErr = load(parameters, '', 't', ENV)
			if not func then
				toDelete[message.id] = message:reply({
					embed = {
						color = color.lua_err,
						title = "[" .. message.member.name .. ".Lua] Error : SyntaxError",
						description = "```\n" .. syntaxErr .. "```"
					}
				})
				return
			end

			if isTest == debugAction.test then
				return parameters
			end

			-- Runs the code
			local ms = os.clock()
			local success, runtimeErr = pcall(func)
			ms = (os.clock() - ms) * 1000

			if not success then
				toDelete[message.id] = message:reply({
					embed = {
						color = color.lua_err,
						title = "[" .. message.member.name .. ".Lua] Error : RuntimeError",
						description = "```\n" .. tostring(runtimeErr) .. "```"
					}
				})
				return
			end

			local result
			if isTest ~= debugAction.cmd then
				result = message:reply({
					embed = {
						color = color.sys,
						footer = {
							text = "[" .. message.member.name .. ".Lua] Loaded successfully! (Ran in " .. ms .. "ms)"
						}
					}
				})
			end

			local lines = splitByLine(table.concat(dataLines, "\n"))

			local messages = { }
			for id = 1, math.min(#lines, (hasAuth and 5 or 3)) do
				messages[#messages + 1] = message:reply({
					embed = {
						color = color.sys,
						description = lines[id]
					}
				})
			end

			for id = 1, #repliedMessages do
				messages[#messages + 1] = repliedMessages[id]
			end

			if isTest ~= debugAction.cmd then
				messages[#messages + 1] = result
			end

			if #messages > 0 then
				if isTest == debugAction.cmd then
					return messages
				else
					toDelete[message.id] = messages
				end
			end
		else
			sendError(message, message.member.name .. ".Lua", "Invalid or missing parameters.", syntax)
		end
	end
}
	-- Module owner
commands["delcmd"] = {
	auth = permissions.is_owner,
	description = "Deletes a created command for the #module category.",
	f = function(message, parameters, category)
		local syntax = "Use `!delcmd command_name`."

		if parameters and #parameters > 0 then 
			local command = string.match(parameters, "(%a[%w_%-]+)")

			if command and modules[category] then
				command = string.lower(command)
				if modules[category].commands[command] then
					modules[category].commands[command] = nil

					save("b_modules", modules, false, true)

					message:reply({
						embed = {
							color = color.sys,
							description = "Command `" .. category .. "." .. command .. "` deleted successfully!",
							footer = { text = "By " .. message.member.name }
						}
					})

					message:delete()
				else
					sendError(message, "DELCMD", "This command doesn't exist or you don't have permission to remove it.")
				end
			else
				sendError(message, "DELCMD", "Invalid syntax.", syntax)
			end
		else
			sendError(message, "DELCMD", "Invalid or missing parameters.", syntax)
		end
	end
}
commands["prefix"] = {
	auth = permissions.is_owner,
	description = "Sets the prefix used for the commands of the #module category.",
	f = function(message, parameters, category)
		local syntax = "Use `!prefix prefix(1|2 characters)`."

		if parameters and #parameters > 0 and #parameters < 3 then 
			modules[category].prefix = (parameters):gsub("[%(%)%.%%%+%-%*%?%[%]%^%$]", "%%%0")

			save("b_modules", modules, false, true)

			message:reply({
				embed = {
					color = color.sys,
					description = "The prefix in the module `" .. category .. "` was set to `" .. parameters .. "` successfully!"
				}
			})

			message:delete()
		else
			sendError(message, "PREFIX", "Invalid or missing parameters.", syntax)
		end
	end
}
commands["public"] = {
	auth = permissions.is_owner,
	description = "Creates a public role and a public channel for the #module.",
	f = function(message, parameters, category)
		local edition = modules[category].hasPublicChannel

		local syntax = "Use `!public module_description`."

		if parameters and #parameters > 0 then
			if not edition then
				local public_role = message.guild:createRole(category)

				local announcements_channel = message.channel.category.textChannels:find(function(c)
					return c.name == "announcements"
				end)

				if announcements_channel then
					setPermissions(announcements_channel:getPermissionOverwriteFor(public_role), permissionOverwrites.announcements.public.allowed, permissionOverwrites.announcements.public.denied)
				end

				local public_channel = message.guild:createTextChannel("chat")
				public_channel:setCategory(message.channel.category.id)

				public_channel:getPermissionOverwriteFor(message.guild.defaultRole):denyPermissions(table.unpack(permissionOverwrites.module.everyone.denied))
				public_channel:getPermissionOverwriteFor(public_role):allowPermissions(table.unpack(permissionOverwrites.public.public.allowed))
				-- Muted
				public_channel:getPermissionOverwriteFor(message.guild:getRole("565703024136421406")):denyPermissions(table.unpack(permissionOverwrites.muted.denied))
				-- Mod
				public_channel:getPermissionOverwriteFor(MOD_ROLE):allowPermissions(table.unpack(permissionOverwrites.mod.allowed))

				local staff_roles = { }
				message.guild.roles:find(function(role)
					if role.name == "★ " .. category or role.name == "⚙ " .. category then
						staff_roles[string.sub(role.name, 1, 1) == "⚙" and "staff" or "owner"] = role
					end
					return false
				end)

				for k, v in next, staff_roles do
					setPermissions(public_channel:getPermissionOverwriteFor(v), permissionOverwrites.module[k].allowed, permissionOverwrites.module[k].denied)
				end

				modules[category].hasPublicChannel = true

				save("b_modules", modules, false, true)

				message:reply({
					embed = {
						color = color.sys,
						title = "<:wheel:456198795768889344> " .. category,
						description = "The module **" .. category .. "** has now a public channel!"
					}
				})

				local m_channel = client:getChannel(channels["modules"])

				m_channel:send({
					embed = {
						color = color.interaction,
						title = category,
						description = parameters,
						footer = { text = "React to access the public channel of this module" }
					}
				}):addReaction(reactions.hand)
			else
				local modified = false
				for msg in client:getChannel(channels["modules"]):getMessages():iter() do
					if msg.embed.title == category then
						msg.embed.description = parameters

						msg:setEmbed(msg.embed)

						modified = true
						break
					end
				end

				if modified then
					message:reply({
						content = "<@!" .. message.author.id .. ">",
						embed = {
							color = color.sys,
							title = "<:wheel:456198795768889344> " .. category,
							description = "Description edited!"
						}
					})
				else
					sendError(message, "PUBLIC", "Something went wrong during the public message edition. Contact Bolodefchoco [Lautenschlager#2555].")
				end
			end

			message:delete()
		else
			if edition then
				sendError(message, "PUBLIC", "The module '" .. category .. "' has already a public channel.")
			else
				sendError(message, "PUBLIC", "Invalid or missing parameters.", syntax)
			end
		end
	end
}
commands["staff"] = {
	auth = permissions.is_owner,
	description = "Sets a member as a staff in the #module category.",
	f = function(message, parameters, category)
		local syntax = "Use `!staff @member_name`."

		if parameters and #parameters > 0 then
			local member = string.match(parameters, "<@!?(%d+)>")
			member = member and message.guild:getMember(member)

			if member then
				if hasPermission(permissions.is_owner, member, message) then
					return sendError(message, "STAFF", "Module owners already already are staff of their modules.")
				end

				local role = message.guild.roles:find(function(role)
					return role.name == "⚙ " .. category
				end)

				if role then
					if not member:hasRole(role.id) then
						member:addRole(role)

						message:reply({
							content = parameters .. ", <@!" .. message.author.id .. ">",
							embed = {
								color = color.sys,
								title = "Promotion!",
								thumbnail = { url = member.user.avatarURL },
								description = "**" .. member.name .. "** is now part of the " .. category .. " staff!"
							}
						})
					else
						member:removeRole(role)

						message:reply({
							content = parameters .. ", <@!" .. message.author.id .. ">",
							embed = {
								color = color.sys,
								title = "Fire!",
								thumbnail = { url = member.user.avatarURL },
								description = "**" .. member.name .. "** is not part of the " .. category .. " staff anymore!"
							}
						})
					end

					message:delete()
				else
					sendError(message, "STAFF", "Role not found for this category", "Private message **" .. client.owner.tag .. "**")
				end
			else
				sendError(message, "STAFF", "Invalid syntax, user or member.", syntax)
			end
		else
			sendError(message, "STAFF", "Invalid or missing parameters.", syntax)
		end
	end
}
	-- Module team
commands["delgcmd"] = {
	auth = permissions.is_module,
	description = "Deletes a global command created by you.",
	f = function(message, parameters, category)
		local syntax = "Use `!delgcmd command_name`."

		if parameters and #parameters > 0 then 
			local command = string.match(parameters, "(%a[%w_%-]+)")

			if command then
				command = string.lower(command)
				if globalCommands[command] and (globalCommands[command].author == message.author.id or authIds[message.author.id]) then
					globalCommands[command] = nil

					saveGlobalCommands()

					message:reply({
						embed = {
							color = color.sys,
							description = "Command `" .. command .. "` deleted successfully!",
							footer = { text = "By " .. message.member.name }
						}
					})

					message:delete()
				else
					sendError(message, "DELGCMD", "This command doesn't exist or you don't have permission to remove it.")
				end
			else
				sendError(message, "DELGCMD", "Invalid syntax.", syntax)
			end
		else
			sendError(message, "DELGCMD", "Invalid or missing parameters.", syntax)
		end
	end
}
commands["emoji"] = {
	auth = permissions.is_module,
	description = "Creates an emoji in the server.",
	f = function(message, parameters)
		if parameters and #parameters > 0 then
			parameters = string.lower(parameters)

			local image = message.attachment and message.attachment.url or nil
			if image then
				local head, body = http.request("GET", image)

				if body then
					image = "data:image/png;base64," .. binBase64.encode(body)

					local emoji = message.guild:createEmoji(parameters, image)
					if emoji then
						message:reply({
							embed = {
								color = color.interaction,
								title = "New Emoji!",
								description = "Emoji **:" .. parameters .. ":** added successfully",
								image = {
									url = emoji.url
								},
								footer = { text = "By " .. message.member.name }
							}
						})

						message:delete()
					else
						sendError(message, "EMOJI", "Internal error.", "Try again later.")
					end
				else
					sendError(message, "EMOJI", "Invalid image or internal error.", "Try again later.")
				end
			else
				sendError(message, "EMOJI", "Invalid or missing image attachment.")
			end
		else
			sendError(message, "EMOJI", "Invalid or missing parameters.", "Use `!emoji name` attached to an image.")
		end
	end
}
commands["galias"] = {
	auth = permissions.is_module,
	description = "Creates an alias for a global command.",
	f = function(message, parameters)
		if parameters and #parameters > 0 then
			local cmd, alias = string.match(parameters, "([%a][%w_%-]+)[\n ]+([%a][%w_%-]+)")
			if not cmd then
				cmd = string.lower(parameters)
				if globalCommands[cmd] and globalCommands[cmd].ref then
					globalCommands[cmd] = nil
					toDelete[message.id] = message:reply({
						embed = {
							color = color.sys,
							title = "Alias GCMD",
							description = "Alias **" .. cmd .. "** deleted successfully."
						}
					})
					saveGlobalCommands()
				else
					sendError(message, "GALIAS", "Invalid command.", "The command **" .. cmd .. "** doesn't exist or is not an alias.")
				end
				return
			end
			cmd, alias = string.lower(cmd), string.lower(alias)

			if globalCommands[cmd] and not globalCommands[cmd].ref then
				globalCommands[alias] = { ref = cmd }
				toDelete[message.id] = message:reply({
					embed = {
						color = color.sys,
						title = "Alias GCMD",
						description = "Alias **" .. alias .. "** created successfully."
					}
				})
				saveGlobalCommands()
			else
				sendError(message, "GALIAS", "Invalid command.", "The command **" .. cmd .. "** doesn't exist or already is an alias.")
			end
		else
			sendError(message, "GALIAS", "Invalid or missing parameters.", "Use `!alias command alias`")
		end
	end
}
commands["gcmd"] = {
	auth = permissions.is_module,
	description = "Creates a command in the global categories.",
	f = function(message, parameters)
		local category = message.channel.category and string.lower(message.channel.category.name) or nil

		if category and string.sub(category, 1, 1) == "#" then
			return sendError(message, "GCMD", "This command cannot be used for #modules. Use the command `!cmd` instead.")
		end

		local syntax = "Use `!gcmd 0|1|2 0|1|2 command_name [ script ``` script ``` ] [ value[[command_content]] ] [ title[[command_title]] ] [ description[[command_description]] ]`.\n\n[Click here to open the command generator](https://fiftysol.github.io/gcmd-generator/)"

		if parameters and #parameters > 0 then
			local script, content, title, description = getCommandFormat(parameters)
			local channelLevel, authLevel, command = string.match(parameters, "^(%d)[\n ]+(%d)[\n ]+([%a][%w_%-]+)[\n ]+")

			if channelLevel then
				channelLevel = tonumber(channelLevel)
				if channelLevel < 3 then
					if authLevel then
						authLevel = tonumber(authLevel)
						if authLevel < 3 then
							if command and #command > 1 and #command < 21 then
								command = string.lower(command)

								if commands[command] then
									return sendError(message, "GCMD", "This command already exists and is not global.")
								end
								if globalCommands[command] and (globalCommands[command].author ~= message.author.id and not authIds[message.author.id]) then
									return sendError(message, "GCMD", "This command already exists.", "Ask the owner, <@" .. globalCommands[command].author .. ">, for an edition.")
								end

								local cmd = getCommandTable(message, script, content, title, description)
								if type(cmd) == "string" then
									return sendError(message, "GCMD", cmd)
								end

								cmd.author = ((globalCommands[command] and globalCommands[command].author) or message.author.id)
								cmd.auth = (authLevel == 0 and permissions.public or authLevel == 1 and permissions.is_dev or permissions.is_module)
								if channelLevel == 1 then
									cmd.category = message.channel.category.id
								elseif channelLevel == 2 then
									cmd.channel = message.channel.id
								end

								globalCommands[command] = cmd

								saveGlobalCommands()

								message:reply({
									embed = {
										color = color.sys,
										description = "Command `" .. command .. "` created successfully!",
										footer = { text = "By " .. message.member.name }
									}
								})
							else
								sendError(message, "GCMD", "Invalid syntax.", syntax)
							end
						else
							sendError(message, "GCMD", "Invalid level flag.", "The authorization level must be 0 (Users), 1 (Developers) or 2 (Module Member).")
						end
					else
						sendError(message, "GCMD", "Invalid syntax.", syntax)
					end
				else
					sendError(message, "GCMD", "Invalid level flag.", "The channel authorization level must be 0 (Global), 1 (Category) or 2 (Channel).")
				end
			else
				sendError(message, "GCMD", "Invalid syntax.", syntax)
			end
		else
			sendError(message, "GCMD", "Invalid or missing parameters.", syntax)
		end
	end
}
commands["module"] = {
	auth = permissions.is_module,
	description = "Creates a module category",
	f = function(message, parameters)
		local syntax = "Use `!module #module_name(4+ characters) @owner_name`."

		if parameters and #parameters > 0 then
			local module, owner = string.match(parameters, "(#[%w_]+)[\n ]+<@!?(%d+)>")

			if module and #module > 4 and owner then -- 4 because of the #
				owner = message.guild:getMember(owner)
				if owner then
					module = string.lower(module)

					local c = not not message.guild.categories:find(function(category)
						return category.name == module
					end)

					if not c then
						--[[
							- #module -> @★ #module; @⚙ #module
								~announcements
								~discussion

							[ May have ]
							@#module
							~chat
						]]

						-- Count public channels
						local publicChannels, totalModules = 0, 0
						for k, v in next, modules do
							totalModules = totalModules + 1
							if v.hasPublicChannel then
								publicChannels = publicChannels + 1
							end
						end

						-- Creation
						local category = message.guild:createCategory(module)

						local announcements_channel = message.guild:createTextChannel("announcements")
						announcements_channel:setCategory(category.id)

						local discussion_channel = message.guild:createTextChannel("discussion")
						discussion_channel:setCategory(category.id)

						local owner_role = message.guild:createRole("★ " .. module)
						owner_role:setColor(roleColor.owner)
						owner_role:moveUp(publicChannels + totalModules - 1)

						local staff_role = message.guild:createRole("⚙ " .. module)
						staff_role:moveUp(publicChannels - 1)

						-- Permissions
						category:getPermissionOverwriteFor(message.guild.defaultRole):denyPermissions(table.unpack(permissionOverwrites.module.everyone.denied))

						setPermissions(category:getPermissionOverwriteFor(owner_role), permissionOverwrites.module.owner.allowed, permissionOverwrites.module.owner.denied)

						setPermissions(category:getPermissionOverwriteFor(staff_role), permissionOverwrites.module.staff.allowed, permissionOverwrites.module.staff.denied)

						-- Announcements
						setPermissions(announcements_channel:getPermissionOverwriteFor(staff_role), permissionOverwrites.announcements.staff.allowed, permissionOverwrites.announcements.staff.denied)

						-- Commands
						local tutorial = client:getChannel("462277184288063540")
						setPermissions(tutorial:getPermissionOverwriteFor(owner_role), permissionOverwrites.tutorial.allowed, permissionOverwrites.tutorial.denied)
						setPermissions(tutorial:getPermissionOverwriteFor(staff_role), permissionOverwrites.tutorial.allowed, permissionOverwrites.tutorial.denied)

						-- Owners
						local owners = client:getChannel("560901122349465611")
						owners:getPermissionOverwriteFor(owner_role):allowPermissions(table.unpack(permissionOverwrites.owners_staffs.allowed))

						-- Staffs
						local staffs = client:getChannel("560901441632469028")
						staffs:getPermissionOverwriteFor(owner_role):allowPermissions(table.unpack(permissionOverwrites.owners_staffs.allowed))
						staffs:getPermissionOverwriteFor(staff_role):allowPermissions(table.unpack(permissionOverwrites.owners_staffs.allowed))

						owner:addRole(owner_role)

						modules[module] = { commands = { } }

						save("b_modules", modules, false, true)

						message:reply({
							embed = {
								color = color.sys,
								title = "<:wheel:456198795768889344> " .. module,
								description = "The module **" .. module .. "** was created successfully!"
							}
						})
						message:delete()
					else
						sendError(message, "MODULE", "The module '" .. module .. "' already exists.")
					end
				else
					sendError(message, "MODULE", "The module owner is not in this server.")
				end
			else
				sendError(message, "MODULE", "Invalid syntax.", syntax)
			end
		else
			sendError(message, "MODULE", "Invalid or missing parameters.", syntax)
		end
	end
}
	-- Mod
commands["mute"] = {
	auth = permissions.is_mod,
	description = "Mutes a member.",
	f = function(message, parameters)
		local syntax = "Use `!mute @user time_in_minutes"

		if parameters and #parameters > 0 then
			local user, time = string.match(parameters, "<@!?(%d+)>[\n ]+(%d+)$")

			local member = user and message.guild:getMember(user)
			time = tonumber(time)

			if member and time then
				message:delete()

				member:addRole("565703024136421406")
				timer.setTimeout(time * 6e4, coroutine.wrap(function(member)
					member:removeRole("565703024136421406")
				end), member)

				local description = "<@" .. user .. "> has been muted for " .. time .. " minutes!"
				message:reply({
					embed = {
						color = color.moderation,
						title = ":alarm_clock: Moderation",
						description = description
					}
				})
				client:getChannel(channels["mod-logs"]):send({
					embed = {
						color = color.moderation,
						title = ":alarm_clock: Mute",
						description = description  .. ("\n\nBy <@" .. message.member.id .. "> [" .. message.member.name .. "]"),
						timestamp = message.timestamp:gsub(" ", '')
					}
				})
			else
				sendError(message, "MUTE", "Invalid parameters.", syntax)
			end
		else
			sendError(message, "MUTE", "Invalid or missing parameters.", syntax)
		end
	end
}
commands["set"] = {
	auth = permissions.is_mod,
	description = "Gives a role to a member.",
	f = function(message, parameters)
		local syntax = "Use `!set @member_name/member_id role_name/role_flag`."

		if parameters and #parameters > 0 then
			local member, role = string.match(parameters, "<@!?(%d+)>[\n ]+(.+)")

			if not member then
				member, role = string.match(parameters, "(%d+)[\n ]+(.+)")
			end

			if member and role then
				if message.member.id == member and not authIds[member] then
					return sendError(message, "SET", "You can not assign yourself a role.")
				end
				member = message.guild:getMember(member)
				if member then
					local numR = tonumber(role)
					local role_id = roles[numR and roleFlags[numR] or string.lower(role)]
					if role_id then
						if not member:hasRole(role_id) then
							member:addRole(role_id)

							role = message.guild:getRole(role_id)

							local msg = {
								embed = {
									color = role.color,
									title = "Promotion!",
									thumbnail = { url = member.user.avatarURL },
									description = "**" .. member.name .. "** is now " .. (string.find(role.name, "^[AEIOUaeiou]") and "a" or "an") .. " `" .. string.upper(role.name) .. "`.",
									footer = { text = "Set by " .. message.member.name }
								}
							}
							message:reply(msg)
							client:getChannel(channels["role-log"]):send(msg)
							message:delete()
						else
							sendError(message, "SET", "Member already have the role.")
						end
					else
						sendError(message, "SET", "Invalid role.", "The available roles are:" .. concat(roleFlags, '', function(id, name)
							return tonumber(id) and "\n\t• [" .. id .. "] " .. name or ''
						end))
					end
				else
					sendError(message, "SET", "Member doesn't exist.")
				end
			else
				sendError(message, "SET", "Invalid syntax.", syntax)
			end
		else
			sendError(message, "SET", "Invalid or missing parameters.", syntax)
		end
	end
}
	-- Freeaccess
commands["commu"] = {
	description = "Creates a new community role.",
	f = function(message, parameters)
		local syntax = "Use `!commu community_code`."

		if parameters and #parameters == 2 then
			parameters = string.upper(parameters)

			local exists = message.guild.roles:find(function(role)
				return role.name == parameters
			end)

			if not exists then
				local role = message.guild:createRole(parameters)

				local botRole = message.guild:getRole(roles["module member"]) -- MT
				role:moveUp(botRole.position - #roleFlags - 1)

				local channel = message.guild:createTextChannel(parameters)
				channel:setCategory("472948887230087178") -- category Community

				channel:getPermissionOverwriteFor(message.guild.defaultRole):denyPermissions(table.unpack(permissionOverwrites.community.everyone.denied))
				channel:getPermissionOverwriteFor(role):allowPermissions(table.unpack(permissionOverwrites.community.speaker.allowed))
				-- Muted
				channel:getPermissionOverwriteFor(message.guild:getRole("565703024136421406")):denyPermissions(table.unpack(permissionOverwrites.muted.denied))
				-- Mod
				channel:getPermissionOverwriteFor(MOD_ROLE):allowPermissions(table.unpack(permissionOverwrites.mod.allowed))

				message:reply({
					content = "<@!" .. message.author.id .. ">",
					embed = {
						color = roleColor.community,
						title = "Community!",
						description = (countryFlags[parameters] or (":flag_" .. string.lower(parameters) .. ":")) .. " Community **" .. parameters .. "** created!"
					}
				})

				if countryFlags[parameters] then
					local commu_flag = message.guild:getChannel(channels["commu"]):getLastMessage()
					commu_flag:setContent(commu_flag.content .. "\t" .. countryFlags[parameters] .. " `" .. parameters .. "`")
					commu_flag:addReaction(countryFlags[parameters])
				end

				message:delete()
			else
				sendError(message, "COMMU", "The community '" .. parameters .. "' already exists.")
			end
		else
			sendError(message, "COMMU", "Invalid or missing parameters.", syntax)
		end
	end
}
commands["del"] = {
	description = "Delete messages.",
	f = function(message, parameters)
		local syntax = "Use `!del from_message_id [total_maps(1:100)]`."

		if parameters and #parameters > 0 then
			local messageId = string.match(parameters, "^(%d+)")
			local limit = string.match(parameters, "[\n ]+(%d+)$")
			if limit then limit = math.clamp(limit, 1, 100) end

			if message.channel:getMessage(messageId) then
				for msg in message.channel:getMessagesAfter(messageId, limit):iter() do
					msg:delete()
				end
			else
				sendError(message, "DEL", "Message id not found.", syntax)
			end
		else
			sendError(message, "DEL", "Invalid or missing parameters.", syntax)
		end
	end
}
commands["exit"] = {
	description = "Ends the bot process.",
	f = function(message)
		save("b_modules", modules, false, true)

		saveGlobalCommands()

		save("b_activechannels", activeChannels)
		save("b_activemembers", activeMembers)
		save("b_cmddata", cmdData)
		save("b_serveractivity", serverActivity)

		message:delete()
		log("INFO", "Disconnected from '" .. client.user.name .. "'", logColor.red)
		os.exit()
	end
}
commands["ping"] = {
	description = "Lets a role be pingable or not.",
	f = function(message, parameters)
		local syntax = "Use `!ping role_name/role_id`"

		if parameters and #parameters > 0 then
			local index = (tonumber(parameters) and "id" or "name")
			parameters = string.lower(parameters)

			for role in message.guild.roles:iter() do
				if string.lower(role[index]) == parameters then
					parameters = role
					break
				end
			end

			if type(parameters) ~= "table" then
				return sendError(message, "PING", "Role '" .. tostring(parameters) .. "' not found.", syntax)
			end

			message.channel:broadcastTyping()
			if parameters.mentionable then
				parameters:disableMentioning()
			else
				parameters:enableMentioning()
			end
			message:delete()
		else
			sendError(message, "PING", "Invalid or missing parameters.", syntax)
		end
	end
}
commands["refresh"] = {
	description = "Refreshes the bot.",
	f = function(message)
		if table.count(activeChannels) > 0 then
			save("b_activechannels", activeChannels)
		end
		if table.count(activeMembers) > 0 then
			save("b_activemembers", activeMembers)
		end
		if table.count(memberProfiles) > 0 then
			save("b_memberprofiles", memberProfiles)
		end
		if table.count(cmdData) > 0 then
			save("b_cmddata", cmdData)
		end
		if table.count(serverActivity) > 0 then
			save("b_serveractivity", serverActivity)
		end

		message:delete()
		os.execute("luvit bot.lua")
		os.exit()
	end
}
commands["remmodule"] = {
	description = "Removes a module category.",
	f = function(message, parameters)
		local syntax = "Use `!remmodule #module_name(4+ characters)"

		if parameters and #parameters > 0 then
			parameters = string.lower(parameters)
			if string.find(parameters, "^#[%w_]+$") then
				if modules[parameters] then
					-- Roles
					local owner_role = message.guild.roles:find(function(role)
						return role.name == "★ " .. parameters
					end)

					local staff_role = message.guild.roles:find(function(role)
						return role.name == "⚙ " .. parameters
					end)

					local public_role = message.guild.roles:find(function(role)
						return role.name == parameters
					end)

					if owner_role then
						owner_role:delete()
					end
					if staff_role then
						staff_role:delete()
					end
					if public_role then
						public_role:delete()
					end

					-- Channels
					local category
					for channel in message.guild.textChannels:iter() do
						if channel.category and channel.category.name == parameters then
							channel:delete()
							if not category then
								category = channel.category
							end
						end
					end

					category:delete()

					-- Message
					for msg in client:getChannel(channels["modules"]):getMessages():iter() do
						if msg.embed and msg.embed.title == parameters then
							msg:delete()
							break
						end
					end

					modules[parameters] = nil
					save("b_modules", modules, false, true)

					message:reply({
						embed = {
							color = color.sys,
							title = "<:wheel:456198795768889344> " .. parameters,
							description = "The module `" .. parameters .. "` was removed from this server!"
						}
					})
					message:delete()
				else
					sendError(message, "REMMODULE", "The module '" .. parameters .. "' doesn't exist.", "The current modules in this server are: ```\n" .. concat(modules, ", ", tostring) .. "```")
				end
			else
				sendError(message, "REMMODULE", "Invalid syntax.", syntax)
			end
		else
			sendError(message, "REMMODULE", "Invalid or missing parameters.", syntax)
		end
	end
}
commands["resetactivity"] = {
	description = "Resets the monthly activity.",
	f = function(message, parameters)
		-- logs the activity before, just in case it's lost
		messageCreate(client:getChannel("474253217421721600"):getMessage("551753598477008919"), true)

		local m, c = commands["activity"].f(message, nil, nil, nil, true)
		local content = "**Activity Podium** - " .. (parameters or os.date("%m/%y")) .. "\n" .. m .. "\n\n" .. c
		client:getChannel(channels["top-activity"]):send(content)

		activeChannels, activeMembers = { }, { }
		save("b_activechannels", activeChannels)
		save("b_activemembers", activeMembers)

		message:delete()
	end
}

--[[ Channel Behaviors ]]--
channelBehavior["bridge"] = {
	output = true,
	f = function(message)
		if not message.content or message.content == "" then return end

		local user, sep, who, member = string.match(message.content, "(%d+)([|&])(.*)%2(%d+)")
		local by = "Hosted by <@" .. member .. "> **" .. who .. "** " .. (sep == "&" and "[Funcorp]" or '')

		local private_message = client:getUser(user):send({ content = by, embed = message.embed })
		if not private_message then
			local channel = client:getChannel(channels["flood"])
			channel:send("Hi <@" .. user .. ">, to get your hosted image via Private Message, please allow members of this server to message you! To do so, follow these steps:\nRight-click the server, go in `Privacy Settings` (https://i.imgur.com/utxsBcH.png)\n\nEnable it! (https://i.imgur.com/mep2kIQ.png).\n\nThank you. ~<@" .. client.user.id .. ">")
			channel:send({
				content = "<@" .. user .. ">\n" .. by,
				embed = message.embed
			})
		end
		return message:delete()
	end
}
channelBehavior["map"] = {
	f = function(message)
		if not message.content or message.content == "" then return end

		local lines, wrongPerm, counter = { }, { }, 0
		for line in string.gmatch(message.content, "[^\n]+") do
			line = string.trim(line)

			counter = counter + 1
			if counter == 1 then
				if string.sub(line, 1, 1) ~= "#" then
					message.author:send({
						embed = {
							color = color.err,
							title = "#map-perm",
							description = "Your map request must start with the #module_name."
						}
					})
					return message:delete()
				end
			else
				local cat, code = string.match(line, "^[Pp](%d+) *%- *(@%d+)$")
				if not cat then
					cat = "41"
					code = string.match(line, "^(@%d+)$")
				end

				if cat and code then
					if not permMaps[cat] then
						wrongPerm[#wrongPerm + 1] = code
					end
				else
					message.author:send({
						embed = {
							color = color.err,
							title = "#map-perm",
							description = "Wrong submission format. Use:\n\n#module_name\nPCategory - @code\n@code\n@code"
						}
					})
					return message:delete()
				end
			end
		end

		if #wrongPerm > 0 then
			message.author:send({
				embed = {
					color = color.err,
					title = "#map-perm",
					description = "Some categories you requested are unavailable. The available categories are: **P" .. concat(permMaps, "** - **P", tostring) .. "**\nConsider fixing the categories of the following maps: `" .. table.concat(wrongPerm, "`, `") .. "`"
				}
			})
		end

		if #wrongPerm < (counter - 1) then
			message:addReaction(reactions.p41)
			message:addReaction(reactions.x)
		end
	end
}
channelBehavior["image"] = {
	f = function(message)
		local iniSettings, _, __, settings = string.find(message.content, "`(`?`?)\n*(.-)%1`$")

		local content = string.sub(message.content, 1, (iniSettings or 0) - 1)
		local img = (message.attachment and message.attachment.url or nil)
		if img then
			content = img .. "\n" .. content
		end

		if not string.find(content, "https?://") then
			message.author:send({
				embed = {
					color = color.err,
					title = "#image-host",
					description = "Wrong image submissions format. Use:\n\nurl\nurl\n..." .. (settings and "\n\\`\\`\\`\nSettings\n\\`\\`\\`" or "")
				}
			})
			return message:delete()
		end

		local wrongLinks, counter = { }, 0

		for line in string.gmatch(content, "[^\n]+") do
			local success = pcall(http.request, "GET", line)
			if not success then
				counter = counter + 1
				wrongLinks[counter] = line
			end
		end

		counter = 0
		local missingParameters, wrongSettings = { }, { }, { }, { }
		if settings then
			string.gsub(settings, "[^\n]+", function(setting)
				setting = string.trim(setting)
				local setting_wo_param = string.match(setting, "^%S+") or setting
				if imageHandler.methodFlags[setting_wo_param] then
					if imageHandler.methodFlags[setting_wo_param] == 1 and not string.find(setting, " .") then
						missingParameters[#missingParameters + 1] = setting_wo_param
					end
				else
					wrongSettings[#wrongSettings + 1] = setting_wo_param
				end
			end)
		end

		local can = true
		if #wrongLinks > 0 then
			can = false
			message.author:send({
				embed = {
					color = color.err,
					title = "#image-host",
					description = "Some links you sent are invalid.\nConsider fixing them: <" .. table.concat(wrongLinks, ">\n<") .. ">"
				}
			})
		end
		if #missingParameters > 0 then
			can = false
			message.author:send({
				embed = {
					color = color.err,
					title = "#image-host",
					description = "Some image settings you requested are missing parameters.\nConsider adding parameters in the following settings: `" .. table.concat(missingParameters, "`, `") .. "`"
				}
			})
		end
		if #wrongSettings > 0 then
			can = false
			message.author:send({
				embed = {
					color = color.err,
					title = "#image-host",
					description = "Some image settings you requested are unavailable. The available settings are: **" .. concat(imageHandler.methodFlags, "** - **", tostring) .. "**\nConsider removing them: `" .. table.concat(wrongSettings, "`, `") .. "`"
				}
			})
		end

		if can then
			message:addReaction(reactions.camera)
			message:addReaction(reactions.x)
		end
	end
}
channelBehavior["role-color"] = {
	f = function(message)
		message:addReaction(reactions.p5)
	end
}
channelBehavior["priv-channels"] = {
	f = function(message)
		message:addReaction(reactions.arrowUp)
	end
}
channelBehavior["suggestions"] = {
	f = function(message)
		if string.sub(message.content, 1, 22) == "<#" .. channels["suggestions"] .. "> " then
			if (os.time() - 60) < discordia.Date.fromISO(message.timestamp):toSeconds() then
				message:addReaction(reactions.thumbsup)
				message:addReaction(reactions.thumbsdown)
				message:pin()
			end
		end
	end
}
channelBehavior["polls"] = {
	f = function(message)
		message:addReaction(reactions.thumbsup)
		message:addReaction(reactions.thumbsdown)
	end
}
channelBehavior["greetings"] = {
	f = function(message)
		message.channel:setTopic("Messages: " .. message.channel:getMessages(100):count() .. " / 100")
	end
}

--[[ Channel Reaction Behaviors ]]--
channelReactionBehavior["modules"] = {
	f_Add = function(message, channel, hash, userId)
		local module = message and message.embed.title

		if module then
			local member = channel.guild:getMember(userId)

			if member then
				local role = channel.guild.roles:find(function(role)
					return role.name == module
				end)

				if role then
					if not member:hasRole(role) then
						member:addRole(role)
					end
				end
			end
		end
	end,
	f_Rem = function(channel, message, hash, userId)
		local module = message and message.embed.title

		if module then
			local member = channel.guild:getMember(userId)

			if member then
				local role = channel.guild.roles:find(function(role)
					return role.name == module
				end)

				if role then
					if member:hasRole(role) then
						member:removeRole(role)
					end
				end
			end
		end
	end
}
channelReactionBehavior["commu"] = {
	f_Add = function(message, channel, hash, userId)
		for flag, flagHash in next, countryFlags do
			if not countryFlags_Aliases[flag] and flagHash == hash then
				local role = channel.guild.roles:find(function(role)
					return role.name == flag
				end)

				if role then
					channel.guild:getMember(userId):addRole(role)
				end
				return
			end
		end
	end,
	f_Rem = function(channel, message, hash, userId)
		for flag, flagHash in next, countryFlags do
			if not countryFlags_Aliases[flag] and flagHash == hash then
				local role = channel.guild.roles:find(function(role)
					return role.name == flag
				end)

				if role then
					local m = channel.guild:getMember(userId)
					if m then
						m:removeRole(role)
					end
				end
				return
			end
		end
	end
}
channelReactionBehavior["map"] = {
	f_Add = function(message, channel, hash, userId)
		local member = channel.guild:getMember(userId)

		if hasPermission(permissions.is_module, member) then
			--@MoonBot
			if hash ~= reactions.x and client:getChannel(channels["bridge"]).guild:getMember(botIds["moon"]).status == "offline" then
				return message:removeReaction(hash, userId)
			end

			local who = getNick(nickList.mt, member)

			if hash == reactions.x then
				message.author:send("Hello, unfortunately your <#462279117866401792> request has been rejected by [<@" .. member.id .. ">] **" .. who .. "**. It may be inappropriate or may have something wrong.\n\nOriginal post:\n\n" .. message.content)
				return message:delete()
			end

			local maps = { }
			for line in string.gmatch(message.content, "[^\n]+") do
				local cat, code = string.match(line, "^ *[Pp](%d+) *%- *(@%d+) *$")
				if not cat then
					cat = "41"
					code = string.match(line, "^ *(@%d+) *$")
				end

				if cat and code then
					if permMaps[cat] then
						if not maps[cat] then
							maps[cat] = { }
						end
						maps[cat][#maps[cat] + 1] = code
					end
				end
			end

			local count = 0
			for k, v in next, maps do
				count = count + (#v * 6)
				client:getChannel(channels["bridge"]):send("%p" .. k .. " " .. table.concat(v, ' '))
			end

			message.author:send("Hello, your <#462279117866401792> request has been accepted by [<@" .. member.id .. ">] **" .. who .. "**. The map list must be permed/depermed in _approximately_ " .. count .. " seconds.\n\nOriginal post:\n\n" .. message.content)
			message:delete()
		end
	end
}
channelReactionBehavior["image"] = {
	f_Add = function(message, channel, hash, userId)
		local member = channel.guild:getMember(userId)

		local isMt, isFc = hasPermission(permissions.is_module, member), hasPermission(permissions.is_fc, member)
		if isMt or isFc then
			--@MoonBot
			if hash ~= reactions.x and client:getChannel(channels["bridge"]).guild:getMember(botIds["moon"]).status == "offline" then
				return message:removeReaction(hash, userId)
			end

			local sep = (isMt and "|" or "&")
			local who = getNick(nickList[isMt and "mt" or "fc"], member)

			local img = (message.attachment and message.attachment.url or nil)

			if hash == reactions.x then
				message.author:send("Hello, unfortunately your <#462279141551636500> request has been rejected by [<@" .. member.id .. ">] **" .. who .. "**. It may be inappropriate, may have copyrights or may have something wrong.\n\nOriginal post:\n\n" .. message.content .. "\n" .. (img or ""))
				return message:delete()
			end

			local iniSettings, _, __, settings = string.find(message.content, "`(`?`?)\n*(.-)%1`$")

			local content = string.sub(message.content, 1, (iniSettings or 0) - 1)
			if img then
				img = imageHandler.fromUrl(img)
			end

			message:delete()
			if settings then
				local s = { }
				string.gsub(settings, "[^\n]+", function(setting)
					setting = string.trim(setting)
					local setting_wo_param = string.match(setting, "^%S+") or setting
					s[setting_wo_param] = imageHandler.methodFlags[setting_wo_param] == 0 and "" or string.match(setting, " (.-)$")
				end)

				local imgurAuth = { "Authorization", "Client-ID " .. tokens.imgur }
				local images = { img }
				for link in string.gmatch(content, "[^\n]+") do
					if string.sub(link, 1, 20) == "https://imgur.com/a/" then
						local header, body = http.request("GET", "https://api.imgur.com/3/album/" .. string.sub(link, 21) .. "/images", { imgurAuth })
						body = json.decode(body)

						local len
						for image = 1, (body.data and #body.data or 0) do
							len = #images + 1
							images[len] = imageHandler.fromUrl(body.data[image].link)
							images[len].fromAlbum = true
						end
					else
						images[#images + 1] = imageHandler.fromUrl(link)
					end
				end

				local album = { }
				for i = 1, #images do
					for setting, param in next, s do
						images[i][setting](images[i], param)
					end
					images[i]:apply()

					if images[i].fromAlbum then
						album[#album + 1] = images[i]
					else
						client:getChannel(channels["bridge"]):send({
							content = "!upload `" .. userId .. sep .. who .. sep .. message.author.id .. "`",
							file = tostring(images[i])
						})
					end
				end

				if #album > 0 then
					local _, body = http.request("POST", "https://api.imgur.com/3/album", { imgurAuth })
					local albumCode, albumHash = string.match(body, '"id":"(.-)","deletehash":"(.-)"')

					local file, bin
					for image = 1, #album do
						file = io.open(tostring(album[image]), "rb")
						bin = file:read("*a")
						file:close()

						_, body = http.request("POST", "https://api.imgur.com/3/image", {
							imgurAuth,
							{ "Content-Type", "multipart/form-data; boundary=" .. boundaries[1] }
						}, boundaries[2] .. '\r\nContent-Disposition: form-data; name="image"\r\n\r\n' .. bin .. '\r\n' .. boundaries[2] .. '\r\nContent-Disposition: form-data; name="album"\r\n\r\n' .. albumHash .. '\r\n' .. boundaries[3])
					end

					if body then
						client:getChannel(channels["bridge"]):send("!upload `" .. userId .. sep .. who .. sep .. message.author.id .. "` https://imgur.com/a/" .. albumCode)
					end
				end
			else
				local cmd = "!upload `" .. userId .. sep .. who .. sep .. message.author.id .. "` "
				for link in string.gmatch(content, "[^\n]+") do
					client:getChannel(channels["bridge"]):send(cmd .. link)
				end
				if img then
					client:getChannel(channels["bridge"]):send({
						content = cmd,
						file = tostring(img)
					})
				end
			end
		end
	end
}
channelReactionBehavior["report"] = {
	f_Add = function(message, channel, hash, userId)
		if hash == reactions.x then
			message:delete()
		else
			local r_channel, r_message = string.match(message.content, "discordapp%.com/channels/%d+/(%d+)/(%d+)")

			local msg = client:getChannel(r_channel):getMessage(r_message)
			if msg then
				local reason = string.match(message.content, "```\n(.-)```")
				local embed = {
					color = color.err,
					description = message.embed.description,
					image = message.embed.image,
					footer = message.embed.footer,
					timestamp = message.embed.timestamp
				}
				local user = "**" .. (msg.member or msg.author).name .. "** <@" .. msg.author.id .. ">"
				local who = "<@" .. userId .. "> "

				message:setContent("") -- Bug?
				if hash == reactions.wave then
					msg.author:send({
						content = "Your message was removed due to a report. Stop breaking the rules or you may be kicked/banned in the future.",
						embed = embed
					})

					msg:delete()
					message:setContent(who .. "deleted the message sent by the user " .. user .. ". Reason:\n```\n" .. reason .. "```")
				else
					msg:delete()
					if hash == reactions.boot then
						msg.author:send({
							content = "You got kicked from **Fifty Shades of Lua** due to a report / breaking rules excessively. You can join again when you improve your behavior.",
							embed = embed
						})
						if msg.member then
							msg.member:kick(reason)
						end

						message:setContent(who .. "kicked " .. user .. ". Reason:\n```\n" .. reason .. "```")
					elseif hash == reactions.bomb then
						msg.author:send({
							content = "You got banned from **Fifty Shades of Lua** due to a report / breaking rules excessively. Contact <@" .. client.owner.id .. "> to appeal if you consider necessary.",
							embed = embed
						})
						if msg.member then
							msg.member:ban(reason, 1)
						end

						message:setContent(who .. "banned " .. user .. ". Reason:\n```\n" .. reason .. "```")
					end
				end
				message:clearReactions()
			end
		end
	end
}
channelReactionBehavior["role-color"] = {
	f_Add = function(message, _, _, userId)
		local id = string.match(message.content, "<@&(%d+)>")
		local member = message.guild:getMember(userId)
		if id and member and specialRoleColor[id] and member:hasRole(id) then
			local remove = false

			local _highest, len = getRoleOrder(member)
			if _highest[len].id == MOD_ROLE.id then
				len = len - 1
			end
			local highest = _highest[len].id

			if specialRoleColor(highest) then
				member:removeRole(highest)
				removed = true
				highest = _highest[len - 1].id
			end

			if id ~= highest then
				member:addRole(specialRoleColor[id])
			else
				if removed then
					member:addRole(_highest[len].id)
				end
			end
		end
	end,
	f_Rem = function(channel, message, hash, userId)
		local member = message.guild:getMember(userId)

		local highest, len = getRoleOrder(member)
		if highest[len].id == MOD_ROLE.id then
			len = len - 1
		end
		highest = highest[len].id

		if member and specialRoleColor(highest) then
			member:removeRole(highest)
		end
	end
}
channelReactionBehavior["priv-channels"] = {
	f_Add = function(message, _, _, userId)
		local member = message.guild:getMember(userId)

		local channel
		for id, allowed, denied in string.gmatch(message.content, "<#(%d+)> +`%((.-),(.-)%)`") do
			channel = client:getChannel(id)
			channel:getPermissionOverwriteFor(member):setPermissions(tonumber(allowed), tonumber(denied))
		end
	end,
	f_Rem = function(_, message, _, userId)
		local member = message.guild:getMember(userId)

		local channel
		for id in string.gmatch(message.content, "<#(%d+)>") do
			channel = client:getChannel(id)
			channel:getPermissionOverwriteFor(member):delete()
		end
	end
}
channelReactionBehavior["suggestions"] = {
	f_Add = function(message, _, hash, userId)
		if authIds[userId] and hash ~= reactions.thumbsup and hash ~= reactions.thumbsdown then
			message:clearReactions()
			message:addReaction(hash)
		end
	end
}
channelReactionBehavior["region"] = {
	f_Add = function(message)
		message.guild:setRegion(message.content)
	end
}

-- Audit logs --
local auditLogs
do
	local actionIcon = {
		guildUpdate = ":speaker: Server region - ",
		memberKick = ":boot: ",
		memberBanAdd = ":skull: ",
		memberBanRemove = ":rainbow: ",
		webhookCreate = ":robot: ",
		webhookUpdate = ":robot: ",
		webhookDelete = ":robot: ",
		emojiCreate = ":star: ",
		emojiUpdate = ":star: ",
		emojiDelete = ":star: ",
		messageDelete = ":x: "
	}

	local actionFunc = { -- For verifications only
		guildUpdate = function(log) return log.changes and log.changes.region end
	}
	local actionField = { -- Extra field with param
		messageDelete = function(msg)
			local embed = buildMessage(msg)
			embed.fields = nil
			return embed
		end
	}

	local getLogResponse = function(log, param)
		local icon = discordia.enums.actionType(log.actionType)

		if not actionIcon[icon] then return end
		if actionFunc[icon] and not actionFunc[icon](log) then return end

		local object
		if log.targetId then
			object = log:getTarget()
			if not object or object.id == client.user.id then return end
		end

		local fields = { }
		if log.changes then
			fields[1] = {
				name = "Changes",
				value = "```Lua\n" .. table.tostring(log.changes, true, true) .. "```"
			}
		end
		if log.options then
			fields[#fields + 1] = {
				name = "Options",
				value = "```Lua\n" .. table.tostring(log.options, true, true) .. "```"
			}
		end
		if log.reason then
			fields[#fields + 1] = {
				name = "Reason",
				value = "```Lua\n" .. reason .. "```"
			}
		end
		if object then
			fields[#fields + 1] = {
				name = "Target",
				value = tostring(object) .. " | " .. tostring(object.tag or object.name)
			}
		end

		local extra
		if actionField[icon] then
			extra = actionField[icon](param)
		end

		icon = actionIcon[icon] .. string.gsub(string.gsub(icon, "%u", " %1"), "%a", string.upper, 1)

		return icon, fields, extra
	end

	auditLogs = function(msg)
		local guild = client:getGuild(channels["guild"])

		local lastLogs = guild:getAuditLogs({
			limit = 1
		}):iter()

		local log = lastLogs()

		if math.abs(os.time() - log.createdAt) > 666 then return end

		local member = log:getMember()
		if msg then
			if log.actionType ~= discordia.enums.actionType.messageDelete then return end
			if member.id == client.user.id then return end
		end
		member = (member and member.id ~= client.user.id) and member

		local title, fields, extra = getLogResponse(log, msg)
		if title then
			local channel = client:getChannel(channels["mod-logs"])
			if channel:send({
				embed = {
					color = color.moderation,
					title = title,
					description = (member and ("\n\nBy <@" .. member.id .. "> [" .. member.name .. "]") or nil),
					fields = fields,
					timestamp = log.timestamp:gsub(" ", '')
				}
			}) and extra then
				channel:send({ embed = extra })
			end
		end
	end
end

--[[ Events ]]--
client:on("ready", function()
	modules = getDatabase("b_modules", false, true)
	globalCommands = json.decode(base64.decode(getDatabase("b_gcommands", true) .. getDatabase("b_gcommands_2", true)))
	activeChannels = getDatabase("b_activechannels")
	activeMembers = getDatabase("b_activemembers")
	memberProfiles = getDatabase("b_memberprofiles")
	cmdData = getDatabase("b_cmddata")
	serverActivity = getDatabase("b_serveractivity")
	-- Normalize string indexes ^
	for k, v in next, table.copy(memberProfiles) do
		for i, j in next, v do
			local m = tonumber(i)
			if m then
				memberProfiles[k][m] = j
				memberProfiles[k][i] = j
			end
		end
	end

	MOD_ROLE = client:getGuild(channels["guild"]):getRole(MOD_ROLE)
	MYCITY_INVITE_OBJECT = getMycityInviteObject()

	-- Imageshack
	--if not io.popen("convert"):read() then
	--	os.execute("sudo apt install imagemagic -y")
	--end

	-- Env Limits
	local restricted_G = table.clone(_G, devRestrictions)
	local restricted_Gmodule = table.clone(restricted_G, moduleRestrictions)

	restricted_G._G = restricted_G
	restricted_Gmodule._G = restricted_Gmodule

	moduleENV = setmetatable({}, {
		__index = setmetatable({
			json = { encode = json.encode, decode = json.decode },

			os = { clock = os.clock, date = os.date, difftime = os.difftime, time = os.time }
		}, {
			__index = restricted_Gmodule
		}),
		__add = meta.__add
	})

	devENV = setmetatable({}, {
		__index = setmetatable({
			botIds = botIds,
			boundaries = boundaries,

			channelBehavior = channelBehavior,
			channelReactionBehavior = channelReactionBehavior,
			client = client,
			cmdData = cmdData,
			commands = commands,
			currency = currency,

			discordia = discordia,

			getDatabase = getDatabase,
			getLuaEnv = getLuaEnv,
			getRoleOrder = getRoleOrder,

			http = http,

			imageHandler = imageHandler,

			json = json,

			log = log,

			memberProfiles = memberProfiles,

			--[[Doc
				~
				"Prints a string in the console."
				@... *
			]]
			printf = function(...)
				return print(...)
			end,

			save = save,
			saveGlobalCommands = saveGlobalCommands,
			sendError = sendError,
			serverActivity = serverActivity,
			setPermissions = setPermissions,

			throwError = throwError,
			tokens = tokens,

			updateCurrency = updateCurrency
		}, {
			__index = restricted_G
		}),
		__add = meta.__add
	})

	clock:start()

	-- Check for new messages in the bridge
	for message in client:getChannel(channels["bridge"]):getMessages():iter() do
		client:emit("messageCreate", message)
	end

	-- Avatar
	local moons = io.open("Content/avatars.txt", 'r')
	local counter = 0
	for avatar in moons:lines() do
		counter = counter + 1
		botAvatars[counter] = avatar
	end
	moons:close()

	-- Get title list
	local counter, male, female = 0
	local _, body = http.request("GET", "http://transformice.com/langues/tfz_en")
	body = require("miniz").inflate(body, 1) -- Decompress
	for titleId, titleName in string.gmatch(body, "¤T_(%d+)=([^¤]+)") do
		titleId = tonumber(titleId)

		titleName = string.gsub(titleName, "<.->", '') -- Removes HTML
		titleName = string.gsub(titleName, "[%*%_~]", "\\%1") -- Escape special characters
		if string.find(titleName, '|', nil, true) then -- Male / Female
			-- Male version
			male = string.gsub(titleName, "%((.-)|.-%)", function(s) return s end)
			-- Female version
			female = string.gsub(titleName, "%(.-|(.-)%)", function(s) return s end)

			titleName = { male, female } -- id % 2 + 1
		end
		counter = counter + 1
		title[counter] = { id = titleId, name = titleName }
		title._id[titleId] = counter
	end

	currentAvatar = moonPhase()
	client:setAvatar(botAvatars[currentAvatar])
	client:setGame("Prefix !")

	log("INFO", "Running as '" .. client.user.name .. "'", logColor.green)
end)

local globalCommandCall = function(cmd, message, parameters)
	if cmd.category then
		if cmd.category ~= (message.channel.category and message.channel.category.id or nil) then
			toDelete[message.id] = message:reply({
				content = "<@!" .. message.author.id .. ">",
				embed = {
					color = color.err,
					title = "Authorization denied.",
					description = "You can't use this command in this category."
				}
			})
			return
		end
	elseif cmd.channel then
		if cmd.channel ~= message.channel.id then
			toDelete[message.id] = message:reply({
				content = "<@!" .. message.author.id .. ">",
				embed = {
					color = color.err,
					title = "Authorization denied.",
					description = "You can't use this command in this channel."
				}
			})
			return
		end
	end

	local msg
	if cmd.title or cmd.desc or cmd.url then
		msg = message:reply({
			embed = {
				title = (cmd.title or nil),
				description = (cmd.desc or nil),
				image = (cmd.url and { url = cmd.url } or nil)
			}
		})
	end

	local msgs
	if cmd.script then
		msgs = commands["lua"].f(message, "`" .. cmd.script .. "`", nil, debugAction.cmd, { parameters = parameters })
	end

	if msgs then
		if msg then
			msgs[#msgs + 1] = msg
		end
		toDelete[message.id] = msgs
	elseif msg then
		toDelete[message.id] = msg
	end
end
messageCreate = function(message, skipChannelActivity)
	-- Ignore its own messages
	if message.author.id == client.user.id then return end
	
	-- Channel behavior system (Output)
	for k, v in next, channelBehavior do
		if v.output and channels[k] and message.channel.id == channels[k] then
			throwError(message, { "Command Behavior [" .. k .. "]" }, v.f, message)
			return
		end
	end

	-- Skips bot messages
	if message.author.bot then return end

	-- Doesn't allow private messages
	if message.channel.type == 1 then return end

	-- Channel behavior system (Input)
	for k, v in next, channelBehavior do
		if not v.output and channels[k] and message.channel.id == channels[k] then
			throwError(message, { "Command Behavior [" .. k .. "]" }, v.f, message)
			return
		end
	end

	-- Detect prefix
	local prefix = "!"
	local category = message.channel.category and string.lower(message.channel.category.name) or nil
	if category and string.sub(category, 1, 1) == "#" and modules[category].prefix then
		prefix = modules[category].prefix
	end

	-- Detect command and parameters
	local command, parameters = string.match(message.content, "^" .. prefix .. "(.-)[\n ]+(.*)")
	command = command or string.match(message.content, "^" .. prefix .. "(.+)")

	if not command then
		if string.find(message.content, "gZPygkN0kqM") then
			return message:delete()
		end
		if string.find(message.content, "L%.?U%.?A%.?") then
			message:reply("Lua *, it's not an acronym. Noob!")
		end
		if string.find(message.content, "[Dd][Ee][Vv][Ee][Ll][Ee][Pp][Ee][Rr]") then
			message:reply("Developer *, noob.")
		end
		if string.find(message.content, "[Dd][Ee][Vv][Ee][Ll][Oo][Pp][Ee][Rr][Ee][Ss]") then
			message:reply("Developers *, noob.")
		end

		if not skipChannelActivity then
			if not lastMemberTexting[message.channel.id] or #lastMemberTexting[message.channel.id] > 100 then
				lastMemberTexting[message.channel.id] = { message.author.id }
			else
				table.insert(lastMemberTexting[message.channel.id], 1, message.author.id)
			end

			local can = 0
			for p = 1, 3 do -- Can only message 3 times
				if lastMemberTexting[message.channel.id][p] and lastMemberTexting[message.channel.id][p] == message.author.id then
					can = can + 1
				end
			end

			if can < 3 and not string.find(message.channel.name, "^prj_") then
				if not activeChannels[message.channel.id] then
					activeChannels[message.channel.id] = 1
				else
					activeChannels[message.channel.id] = activeChannels[message.channel.id] + 1
				end
			end

			if not memberTimers[message.author.id] then
				memberTimers[message.author.id] = 0
			end
			if os.time() > memberTimers[message.author.id] then
				memberTimers[message.author.id] = os.time() + 3
				if not activeMembers[message.author.id] then
					activeMembers[message.author.id] = 1
				else
					activeMembers[message.author.id] = activeMembers[message.author.id] + 1
				end

				addServerActivity(message.member)
			end
		end
		return
	end

	command = string.lower(command)
	parameters = (parameters and parameters ~= '') and string.trim(parameters) or nil

	-- Function call
	local botCommand, moduleCommand, cmd = true, false, commands[command]
	if not cmd then
		botCommand = false
		moduleCommand = true
		cmd = modules[category] and modules[category].commands[command] or nil
		if not cmd then
			moduleCommand = false
			cmd = globalCommands[command] or nil
		end
	end

	if cmd then
		if cmd.ref then
			cmd = globalCommands[cmd.ref]
		end

		if not (authIds[message.author.id] or hasPermission(cmd.auth, message.member, message)) then
			toDelete[message.id] = message:reply({
				content = "<@!" .. message.author.id .. ">",
				embed = {
					color = color.err,
					title = "Authorization denied.",
					description = "You do not have access to the command **" .. (moduleCommand and (category .. ".") or '') .. command .. "**!"
				}
			})
			return
		end

		if botCommand then
			addServerActivity(true)
			throwError(message, { "Command [" .. string.upper(command) .. "]" }, cmd.f, message, parameters, category)
		else
			addServerActivity(false)
			throwError(message, { "Global Command [" .. string.upper(command) .. "]" }, globalCommandCall, cmd, message, parameters)
		end
	end
end
messageDelete = function(message, skipChannelActivity)
	if not message.guild or message.guild.id ~= channels["guild"] then return end
	
	if toDelete[message.id] then
		local msg
		for id = 1, #toDelete[message.id] do
			msg = message.channel:getMessage(toDelete[message.id][id])
			if msg then
				msg:delete()
			end
		end

		toDelete[message.id] = nil
	elseif not skipChannelActivity and message.author.id ~= client.user.id then
		local t = discordia.Date.fromISO(message.timestamp):toSeconds()
		-- Less than 1 minute = remove activity
		if (os.time() - 60) < t then
			if activeChannels[message.channel.id] and activeChannels[message.channel.id] > 0 then
				activeChannels[message.channel.id] = activeChannels[message.channel.id] - 1
			end
			if activeMembers[message.author.id] and activeMembers[message.author.id] > 0 then
				activeMembers[message.author.id] = activeMembers[message.author.id] - 1
				addServerActivity(message.member, true)
			end
		end
		-- Less than 20 seconds = log
		--if (os.time() - 20) < t then
			if message.content then
				local d = string.match(message.content, "^!?(%S+)")
				if d then
					if commands[string.lower(d)] then return end
				end
			end
			if message.author.bot then return end
			local _, k = table.find(channels, tostring(message.channel.id))
			if channelReactionBehavior[tostring(k)] then return end

			client:getChannel(channels["chat-log"]):send({
				content = "Message from " .. (message.member and message.member:hasRole(MOD_ROLE.id) and message.author.tag or ("<@" .. message.author.id .. ">")),
				embed = {
					color = color.sys,
					description = message.content,
					image =  ((message.attachment and message.attachment.url) and { url = message.attachment.url } or nil),
					footer = {
						text = "In " .. (message.channel.category and (message.channel.category.name .. ".#") or "#") .. message.channel.name,
					},
					timestamp = string.gsub(message.timestamp, ' ', '')
				}
			})
		--end
	end
	if message.channel.id == channels["greetings"] then
		channelBehavior["greetings"].f(message)
	end
end
local messageUpdate = function(message)
	if message.channel.id == channels["bridge"] then return end

	messageDelete(message, true)
	messageCreate(message, true)
end
client:on("messageCreate", function(message)
	if not modules then return end

	throwError(message, "MessageCreate", messageCreate, message)
end)
client:on("messageUpdate", function(message)
	if not modules then return end

	throwError(message, "MessageUpdate", messageUpdate, message)
end)
client:on("messageDelete", function(message)
	throwError(message, "MessageDelete", messageDelete, message)
	if message.channel.id == channels["mod-logs"] then return end
	throwError(nil, "MessageDeleteLogs", auditLogs, message)
end)

local memberJoin = function(member)
	local isBot = member.bot
	local isMycity = false
	if isBot then
		local code_test = client:getChannel(channels["code-test"])
		local devPerms = code_test:getPermissionOverwriteFor(code_test.guild:getRole(roles["developer"]))
		code_test:getPermissionOverwriteFor(member):setPermissions(devPerms.allowedPermissions, devPerms.deniedPermissions)
		client:getChannel("472958910475665409"):send(":robot: beep boop")
	else
		local invite = getMycityInviteObject()
		if MYCITY_INVITE_OBJECT.uses ~= invite.uses then -- used mycity's invite link
			MYCITY_INVITE_OBJECT = invite

			member:addRole("465523096380506113") -- #mycity role
			isMycity = true
		end
	end
	client:getChannel(channels["logs"]):send("<@!" .. member.id .. "> [" .. member.name .. "] just joined!" .. (isBot and " :robot:" or isMycity and " :house:" or ''))
	if not isMycity and not isBot then
		--client:getChannel("472958910475665409"):send(string.format(client:getChannel(channels["greetings"]):getMessages(100):random().content, "<@" .. member.id .. ">"))
	end
	addServerActivity(1)
end
local memberLeave = function(member)
	client:getChannel(channels["logs"]):send("<@" .. member.id .. "> [" .. member.name .. "] just left!\nRoles: " .. tostring(concat(member.roles:toArray(), ", ", function(_, role) return "<@&" .. role.id .. ">" end)))

	if activeMembers[member.id] then
		activeMembers[member.id] = nil
	end
	if memberProfiles[member.id] then
		memberProfiles[member.id] = nil
	end
	addServerActivity(2)
end
client:on("memberJoin", function(member)
	if member.guild.id ~= channels["guild"] then return end
	throwError(nil, "MemberJoin", memberJoin, member)
end)
client:on("memberLeave", function(member)
	if member.guild.id ~= channels["guild"] then return end
	throwError(nil, "MemberLeaveLogs", auditLogs, member.guild)
	throwError(nil, "MemberLeave", memberLeave, member)
end)

local reactionAdd = function(cached, channel, messageId, hash, userId)
	if userId == client.user.id then return end

	local message = channel:getMessage(messageId)
	for k, v in next, channelReactionBehavior do
		if v.f_Add and channels[k] and channels[k] == channel.id then
			return throwError(message, { "ReactionAdd Behavior [" .. k .. "]" }, v.f_Add, message, channel, hash, userId)
		end
	end

	if not cached then -- last one because the above ^ can be uncached too
		if polls[messageId] then
			local found, answer = table.find(polls.__REACTIONS, hash)
			if found then
				polls[messageId].votes[answer] = polls[messageId].votes[answer] + 1
				message:removeReaction(polls.__REACTIONS[(answer % 2) + 1], userId)
			else
				message:removeReaction(hash, userId)
			end
		--[[elseif playingAkinator[userId] then
			if playingAkinator[userId].message.id == messageId then
				if playingAkinator[userId].canExe then
					playingAkinator[userId].canExe = false

					local found, answer = table.find(playingAkinator.__REACTIONS, hash)
					if found then
						local update, addResultReaction, query, _, body = false, true, "base=0&channel=" .. playingAkinator[userId].data.channel .. "&session=" .. playingAkinator[userId].data.session .. "&signature=" .. playingAkinator[userId].data.signature
						local subquery = query .. "&step=" .. playingAkinator[userId].data.step

						local checkAnswer = answer == "ok"
						if checkAnswer then
							body = playingAkinator[userId].lastBody
						else
							if answer == #playingAkinator.__REACTIONS then
								_, body = http.request("GET", playingAkinator[userId].lang .. "/ws/cancel_answer?" .. subquery)
							else
								_, body = http.request("GET", playingAkinator[userId].lang .. "/ws/answer?" .. subquery .. "&answer=" .. (answer - 1))
							end
							body = json.decode(body)
						end

						if body and body.RESULT then
							playingAkinator[userId].data.step = body.parameters.step

							if playingAkinator[userId].data.step == 79 then
								checkAnswer = checkAnswer or (playingAkinator[userId].currentRatio and playingAkinator[userId].currentRatio >= 75)
							else
								playingAkinator[userId].currentRatio = (playingAkinator[userId].data.step == 78) and body.parameters.progression
							end

							local msg = channel:getMessage(messageId)

							if body.completion == "KO - TIMEOUT" then
								msg.embed.description = ":x: **TIMEOUT**\n\nUnfortunately you took too much time to answer :confused:"
								addResultReaction = false
							elseif not checkAnswer and body.completion == "WARN - NO QUESTION" then
								msg.embed.description = ":x: **Ugh, you won!**\n\nI did not figure out who your character is :( I dare you to try again!"
								msg.embed.image = { url = "https://a.ppy.sh/5790113_1464841858.png" }
							else
								if body.completion == "OK" and not checkAnswer and body.parameters.progression < playingAkinator[userId].ratio then
									msg.embed.description = string.format("```\n%s```\n%s\n\n%s", body.parameters.question, playingAkinator[userId].cmds, getRate(body.parameters.progression / 10))
									msg.embed.footer.text = "Question " .. ((playingAkinator[userId].data.step or 0) + 1)
									update = true
								else
									_, body = http.request("GET", playingAkinator[userId].lang .. "/ws/list?" .. query .. "&step=" .. playingAkinator[userId].data.step .. "&size=1&max_pic_width=360&max_pic_height=640&mode_question=0")
									body = json.decode(body)

									if not body then
										channel:send({
											embed = {
												color = color.err,
												description = ":x: | Akinator Error. :( Try again later.\n```\n" .. tostring(body.completion) .. "```"
											}
										})
										playingAkinator[userId] = nil
										return
									end

									msg.embed.author = {
										name = body.parameters.elements.element.name,
										icon_url = msg.author.icon_url
									}
									msg.embed.title = string.format((checkAnswer and "I bet my hunch is correct... after %s questions!" or "I figured out in the %sth question!"), (playingAkinator[userId].data.step or 0) + (checkAnswer and 1 or 0))
									msg.embed.image = {
										url = body.parameters.elements.element.absolute_picture_path
									}
									msg.embed.description = body.parameters.elements.element.description
									msg.embed.footer = nil
								end
							end

							msg:setEmbed(msg.embed)
							if update then
								if playingAkinator[userId].data.step == 0 then
									msg:removeReaction(playingAkinator.__REACTIONS[#playingAkinator.__REACTIONS])
								elseif playingAkinator[userId].data.step == 1 then 
									msg:addReaction(playingAkinator.__REACTIONS[#playingAkinator.__REACTIONS])
								end

								if playingAkinator[userId].data.step == 8 then
									msg:removeReaction(playingAkinator.__REACTIONS.ok)
								elseif playingAkinator[userId].data.step == 9 then
									msg:addReaction(playingAkinator.__REACTIONS.ok)
								end

								msg:removeReaction(hash, userId)

								playingAkinator[userId].lastBody = body
							else
								msg:clearReactions()
								if addResultReaction then
									msg:addReaction(reactions.yes) -- Correct
									msg:addReaction(reactions.x) -- Incorrect
								end

								playingAkinator[userId] = nil
							end
						end
					end

					if playingAkinator[userId] then
						playingAkinator[userId].canExe = true
					end
				end
			end]]
		end
	end
end
client:on("reactionAddUncached", function(channel, messageId, hash, userId)
	throwError(channel:getMessage(messageId), "ReactionAdd", reactionAdd, true, channel, messageId, hash, userId)
end)
client:on("reactionAdd", function(reaction, userId)
	throwError(reaction.message, "ReactionAdd", reactionAdd, false, reaction.message.channel, reaction.message.id, reaction.emojiName, userId)
end)

local reactionRemove = function(cached, channel, messageId, hash, userId)
	if userId == client.user.id then return end

	local message = channel:getMessage(messageId)
	for k, v in next, channelReactionBehavior do
		if v.f_Rem and channels[k] and channels[k] == channel.id then
			return throwError(message, { "ReactionRem Behavior [" .. k .. "]" }, v.f_Rem, channel, message, hash, userId)
		end
	end

	if not cached then
		if polls[messageId] then
			local found, answer = table.find(polls.__REACTIONS, hash)
			if found then
				polls[messageId].votes[answer] = polls[messageId].votes[answer] - 1
			end
		end
	end
end
client:on("reactionRemoveUncached", function(channel, messageId, hash, userId)
	throwError(channel:getMessage(messageId), "ReactionRemove", reactionRemove, true, channel, messageId, hash, userId)
end)
client:on("reactionRemove", function(reaction, userId)
	throwError(reaction.message, "ReactionRemove", reactionRemove, false, reaction.message.channel, reaction.message.id, reaction.emojiName, userId)
end)

local channelDelete = function(channel)
	if activeChannels[channel.id] then
		activeChannels[channel.id] = nil
	end
end
client:on("channelDelete", function(channel)
	throwError(nil, "ChannelDelete", channelDelete, channel)
end)

client:on("guildUpdate", function(guild)
	if guild.id ~= channels["guild"] then return end
	throwError(nil, "GuildUpdateLogs", auditLogs)
end)
client:on("userBan", function(user, guild)
	if guild.id ~= channels["guild"] then return end
	throwError(nil, "UserBanLogs", auditLogs)
end)
client:on("userUnban", function(user, guild)
	if guild.id ~= channels["guild"] then return end
	throwError(nil, "UserUnbanLogs", auditLogs)
end)
client:on("emojisUpdate", function(guild)
	if guild.id ~= channels["guild"] then return end
	throwError(nil, "EmojisUpdateLogs", auditLogs)
end)
client:on("webhooksUpdate", function(channel)
	if channel.guild.id ~= channels["guild"] then return end
	throwError(nil, "WebhooksUpdateLogs", auditLogs)
end)

local clockMin = function()
	xpcall(function()

	if not modules then return end
	minutes = minutes + 1

	if minutes == 1 then
		updateCurrency()
	end

	if minutes % 5 == 0 then
		save("b_activechannels", activeChannels)
		save("b_activemembers", activeMembers)
		save("b_memberprofiles", memberProfiles)
		save("b_cmddata", cmdData)
		save("b_serveractivity", serverActivity)
	end

	for k, v in next, table.deepcopy(polls) do
		local poll = client:getChannel(v.channel)
		if poll then
			poll = poll:getMessage(k)
			if poll then
				if os.time() > v.time then
					local totalVotes = v.votes[1] + v.votes[2]

					local totalStr = ''
					for i = 1, 2 do
						totalStr = totalStr .. "Total of `\"" .. v.option[i] .. "\"`: " .. v.votes[i] .. " (" .. math.ceil(math.percent(v.votes[i], totalVotes)) .. "%)" .. "\n"
					end
					poll.embed.description = string.match(poll.embed.description, "```.*```\n") .. totalStr

					local results = {{ 1, v.votes[1] }, { 2, v.votes[2] }}
					table.sort(results, function(a, b) return a[2] > b[2] end)

					poll.embed.author.name = poll.embed.author.name .. " - Results"
					poll.embed.footer.text = "Final Decision: \"" .. (results[1][2] == results[2][2] and "Tie" or v.option[results[1][1]]) .. "\""

					poll:clearReactions()

					polls[k] = nil
				else
					poll.embed.footer.text = "Ends in " .. math.floor((v.time - os.time()) / 60) .. " minutes."
				end

				poll:setEmbed(poll.embed)
			end
		end
	end

	end, function()
		client:getChannel("465583146071490560"):reply("<@285878295759814656>\n```\n" .. debug.traceback() .. "```")
	end)
end
clock:on("min", function()
	throwError(nil, "ClockMinute", clockMin)
end)
local clockHour = function()
	if not modules then return end
	updateCurrency()
	local moon = moonPhase()
	if currentAvatar ~= moon then
		currentAvatar = moon
		client:setAvatar(botAvatars[currentAvatar])
	end
end
clock:on("hour", function()
	throwError(nil, "ClockHour", clockHour)
end)

client:run(os.readFile("Content/token.txt", "*l"))
