local db_url = "http://127.0.0.1/"--"https://d-modulo-b-2.000webhostapp.com/"

math.randomseed(os.time())
local DB_COOKIES_N_BLAME_INFINITYFREE

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

function table.deepcopy(tbl)
	local ret, isCircular = { }, false
	for k, v in pairs(tbl) do
		if k == "_G" then
			isCircular = true
		else
			ret[k] = type(v) == "table" and table.deepcopy(v) or v
		end
	end
	if isCircular then
		ret._G = ret
	end
	return ret
end

local client = discordia.Client({
	cacheAllMembers = true
})
client._options.routeDelay = 0
client:enableAllIntents()

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
	["greetings"] = "598898246500483072",
	["breach"] = "718659508980809758"
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

local luaDoc

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
	["pt"] = "\xF0\x9F\x87\xA7\xF0\x9F\x87\xB7",
	["en"] = "\xF0\x9F\x87\xAC\xF0\x9F\x87\xA7",
	["ar"] = "\xF0\x9F\x87\xB8\xF0\x9F\x87\xA6",
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
	["34"] = true,
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
	--is_map = 5,
	is_trad = 6,
	--is_fash = 7,
	--is_evt = 8,
	is_writer = 9,
	is_math = 10,
	--is_fc = 11,
	--is_shades = 12,
	--is_staff = 13, -- Never change
	--is_owner = 14,
	is_mod = 15
}

local permIcons = {
	public = ":small_orange_diamond:",
	has_power = ":small_blue_diamond:",
	is_module = "<:wheel:456198795768889344>",
	is_dev = "<:lua:468936022248390687>",
	is_art = "<:p5:468937377981923339>",
	--is_map = "<:p41:463508055577985024>",
	is_trad = ":earth_americas:",
	--is_fash = "<:dance:468937918115741718>",
	--is_evt = "<:idea:559070151278854155>",
	is_writer = ":pencil:",
	is_math = ":triangular_ruler:",
	--is_fc = "<:fun:559069782469771264>",
	--is_shades = "<:illuminati:542115872328646666>",
	--is_staff = ":star:",
	--is_owner = ":star2:",
	is_mod = ":hammer_pick:"
}

--[[Doc
	"Permissions for specific roles that are auto-generated by the bot."
	!table
]]
--[[local permissionOverwrites = { }
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
				"mentionEveryone",
				"manageWebhooks"
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
end]]
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
	--["462329326600192010"] = "530765854174871553", -- map
	--["481189370448314369"] = "530765850186219550", -- evt
	--["544202727216119860"] = "544204980706476053", -- sh
	--["526822896987930625"] = "530765847816568832", -- fc
	["514913541627838464"] = "530765851314356236", -- math
	--["465631506489016321"] = "530765844406599680", -- fashion
	["514913155437035551"] = "530765848823201792" -- write
}
--[[Doc
	"Flags for the IDs of the important roles in the server.
	*[Indexing the ID returns the name of the role]"
	!table
]]
local roles = {
	["tech guru"] = "462279926532276225",
	["developer"] = "462281046566895636",
	["artist"] = "462285151595003914",
	["translator"] = "494665355327832064",
	--["mapper"] = "462329326600192010",
	--["event manager"] = "481189370448314369",
	--["shades helper"] = "544202727216119860",
	--["funcorp"] = "526822896987930625",
	["mathematician"] = "514913541627838464",
	--["fashionista"] = "465631506489016321",
	["writer"] = "514913155437035551",
}
for name, id in next, table.copy(roles) do roles[id] = name end
--[[Doc
	"The staff role names by User-Friendly IDs.
	*[Indexing the name returns the User-Friendly ID]"
	!table
]]
local roleFlags = {
	[1] = "tech guru",
	[2] = "developer",
	[3] = "artist",
	[4] = "translator",
	--[5] = "mapper",
	--[6] = "event manager",
	--[7] = "shades helper",
	--[8] = "funcorp",
	[5] = "mathematician",
	--[10] = "fashionista",
	[6] = "writer",
}
for i, name in next, table.copy(roleFlags) do roleFlags[name] = i end
--[[Doc
	"Transformice's Environment with empty functions"
	!table
]]
--[=[local envTfm = nil
do
	local emptyFunction = function() end
	envTfm = {
		-- API
		assert = assert,
		bit32 = {
			arshift = emptyFunction,
			band = emptyFunction,
			bnot = emptyFunction,
			bor = emptyFunction,
			btest = emptyFunction,
			bxor = emptyFunction,
			extract = emptyFunction,
			lshift = emptyFunction,
			replace = emptyFunction,
			rshift = emptyFunction
		},
		coroutine = {
			create = emptyFunction,
			yield = emptyFunction,
			resume = emptyFunction,
			wrap = emptyFunction,
			status = emptyFunction,
			running = emptyFunction
		},
		debug = {
			disableEventLog = emptyFunction,
			disableTimerLog = emptyFunction,
			traceback = emptyFunction
		},
		error = emptyFunction,
		getmetatable = emptyFunction,
		ipairs = emptyFunction,
		math = {
			abs = emptyFunction,
			acos = emptyFunction,
			asin = emptyFunction,
			atan = emptyFunction,
			atan2 = emptyFunction,
			ceil = emptyFunction,
			cos = emptyFunction,
			cosh = emptyFunction,
			deg = emptyFunction,
			exp = emptyFunction,
			floor = emptyFunction,
			fmod = emptyFunction,
			frexp = emptyFunction,
			huge = emptyFunction,
			ldexp = emptyFunction,
			log = emptyFunction,
			max = emptyFunction,
			min = emptyFunction,
			modf = emptyFunction,
			pi = emptyFunction,
			pow = emptyFunction,
			rad = emptyFunction,
			random = emptyFunction,
			randomseed = emptyFunction,
			sin = emptyFunction,
			sinh = emptyFunction,
			sqrt = emptyFunction,
			tan = emptyFunction,
			tanh = emptyFunction
		},
		next = next,
		os = {
			date = emptyFunction,
			difftime = emptyFunction,
			time = emptyFunction
		},
		pairs = emptyFunction,
		pcall = emptyFunction,
		print = emptyFunction,
		rawequal = emptyFunction,
		rawget = emptyFunction,
		rawlen = emptyFunction,
		rawset = emptyFunction,
		select = emptyFunction,
		setmetatable = emptyFunction,
		string = {
			byte = emptyFunction,
			char = emptyFunction,
			dump = emptyFunction,
			find = emptyFunction,
			format = emptyFunction,
			gmatch = emptyFunction,
			gsub = emptyFunction,
			len = emptyFunction,
			lower = emptyFunction,
			match = emptyFunction,
			rep = emptyFunction,
			reverse = emptyFunction,
			sub = emptyFunction,
			upper = emptyFunction
		},
		system = {
			bindKeyboard = emptyFunction,
			bindMouse = emptyFunction,
			disableChatCommandDisplay = emptyFunction,
			exit = emptyFunction,
			giveEventGift = emptyFunction,
			loadFile = emptyFunction,
			loadPlayerData = emptyFunction,
			luaEventLaunchInterval = emptyFunction,
			newTimer = emptyFunction,
			removeTimer = emptyFunction,
			saveFile = emptyFunction,
			savePlayerData = emptyFunction
		},
		table = {
			concat = emptyFunction,
			foreach = emptyFunction,
			foreachi = emptyFunction,
			insert = emptyFunction,
			pack = emptyFunction,
			remove = emptyFunction,
			sort = emptyFunction,
			unpack = emptyFunction
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
					yellowGrass = 17,
					pinkGrass = 18,
					acid = 19
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
				},
				bonus = {
					point = 0,
					speed = 1,
					death = 2,
					spring = 3,
					booster = 5,
					electricArc = 6
				}
			},
			exec = {
				addBonus = emptyFunction,
				addConjuration = emptyFunction,
				addImage = emptyFunction,
				addJoint = emptyFunction,
				addPhysicObject = emptyFunction,
				addShamanObject = emptyFunction,
				attachBalloon = emptyFunction,
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
				freezePlayer = emptyFunction,
				getPlayerSync = emptyFunction,
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
				removeBonus = emptyFunction,
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
				setPlayerSync = emptyFunction,
				setRoomMaxPlayers = emptyFunction,
				setRoomPassword = emptyFunction,
				setShaman = emptyFunction,
				setShamanMode = emptyFunction,
				setUIMapName = emptyFunction,
				setUIShamanName = emptyFunction,
				setVampirePlayer = emptyFunction,
				setWorldGravity = emptyFunction,
				snow = emptyFunction
			},
			get = {
				misc = {
					apiVersion = 0.28,
					transformiceVersion = 5.86
				},
				room = {
					community = "en",
					currentMap = 0,
					isTribeHouse = false,
					language = "en",
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
							cheeses = 0,
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
							language = "en",
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
		tonumber = emptyFunction,
		tostring = emptyFunction,
		type = emptyFunction,
		ui = {
			addPopup = emptyFunction,
			addTextArea = emptyFunction,
			removeTextArea = emptyFunction,
			setBackgroundColor = emptyFunction,
			setMapName = emptyFunction,
			setShamanName = emptyFunction,
			showColorPicker = emptyFunction,
			updateTextArea = emptyFunction
		},
		xpcall = emptyFunction,

		-- Events
		eventChatCommand = emptyFunction,
		eventChatMessage = emptyFunction,
		eventContactListener = emptyFunction,
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
		eventPlayerBonusGrabbed  = emptyFunction,
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

	envTfm.bit32.lrotate = emptyFunction
	envTfm.bit32.rrotate = emptyFunction
	envTfm.tfm.get.room.playerList["Pikashu#0095"] = envTfm.tfm.get.room.playerList["Tigrounette#0001"]
	envTfm._G = envTfm
end]=]
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
	discdb = "http://discorddb%.000webhostapp%.com",
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

local specialInvites = {
	mycity = {
		code = "QPyBwUh",
		uses = 0,
		icon = " :house:",
		callback = function(member)
			member:addRole("465523096380506113") -- #mycity role
		end
	},
	transfromage = {
		code = "qmdryEB",
		uses = 0,
		icon = " <:p6:563096586394140682>",
		callback = function(member)
			channelReactionBehavior["priv-channels"].f_Add({
				content = "<#531108640208191508> `(0x400,0x840)` <#545284327362002944> `(0x400,0)` → TransFromage API 🧀"
			}, nil, nil, nil, member)
		end
	}
}

local db_teamList
local db_modules

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
			--index = 1,
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
			--index = 1,
			type = "number",
			min = 0,
			max = 50,
			description = "The quantity of modules you currently host."
		},
		modules = {
			--index = 2,
			type = "number",
			min = 0,
			max = 100,
			description = "The quantity of modules you developed."
		},
		github = {
			--index = 2,
			type = "string",
			min = 3,
			valid = function(x)
				return string.find(x, "^[%w%-]+$") and (http.request("GET", "https://github.com/" .. x)).reason == "OK"
			end,
			description = "The name of your GitHub account."
		},
		deviantart = {
			--index = 3,
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
			--index = 5,
			type = "number",
			min = 0,
			max = 200,
			description = "The quantity of high permed maps you currently have."
		},
		trad = {
			--index = 4,
			type = "number",
			min = 0,
			max = 200,
			description = "The approximate amount of modules and Lua projects you have helped to translate."
		},
		evt = {
			--index = 6,
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
			--index = 11,
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
		twt = {
			type = "string",
			valid = function(x)
				return string.find(x, "^%S+$") and (http.request("GET", "https://twitter.com/" .. x)).reason == "OK"
			end,
			description = "The name of your Twitter account."
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

--[=[local playingAkinator = {
	__REACTIONS = {"\x31\xE2\x83\xA3", "\x32\xE2\x83\xA3", "\x33\xE2\x83\xA3", "\x34\xE2\x83\xA3", "\x35\xE2\x83\xA3", "\xE2\x8F\xAA", ok = "\xF0\x9F\x86\x97"}
}]=]
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

local timeNames = { } -- 1 name per id

--[[ Functions ]]--
local buildMessage = function(msg, message)
	local memberName
	if message then
		memberName = message.guild:getMember(msg.author.id)
		memberName = memberName and memberName.name or msg.author.name
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
local getDatabase = function(fileName, raw, decodeBase64, ignoreDbErr)
	--do return {} end
	local head, body = http.request("GET", db_url .. "get.php?k=" .. tokens.discdb .. "&e=json&f=" .. fileName, DB_COOKIES_N_BLAME_INFINITYFREE)
	--body = string.gsub(body, "%(%(12%)%)", '+')

	--if decodeBase64 then
	--	body = base64.decode(body)
	--end
	local out = body
	if not raw then
		out = json.decode(body)
	end

	if not ignoreDbErr and not body or not out then
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
	return string.format("`[%s%s] %.2f%%`", string.rep('|', rate), string.rep(' ', max - rate), math.percent(value, of))
end

local getRoleOrder = function(member)
	local roles = member.roles:toArray("position")
	return roles, #roles
end

local getInviteUses = function(i)
	local invites = { }
	for invite in client:getGuild(channels["guild"]):getInvites():iter() do
		if invite.code == i then
			return invite.uses
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
		local memberRoles, len = getRoleOrder(member)
		if len == 0 then
			return false
		end

		for i = 1, len do
			if roles[memberRoles[i].id] then
				return true
			end
		end
		return false
	elseif permission == permissions.is_module then
		return member:hasRole(roles["tech guru"]) or (member.guild.id == "897638804750471169" and
			member:hasRole("897640614387134534"))
	elseif permission == permissions.is_dev then
		return member:hasRole(roles["developer"])
	elseif permission == permissions.is_art then
		return member:hasRole(roles["artist"])
	--elseif permission == permissions.is_map then
	--	return member:hasRole(roles["mapper"])
	elseif permission == permissions.is_trad then
		return member:hasRole(roles["translator"])
	--elseif permission == permissions.is_fash then
	--	return member:hasRole(roles["fashionista"])
	--elseif permission == permissions.is_evt then
	--	return member:hasRole(roles["event manager"])
	elseif permission == permissions.is_writer then
		return member:hasRole(roles["writer"])
	elseif permission == permissions.is_math then
		return member:hasRole(roles["mathematician"])
	--elseif permission == permissions.is_fc then
	--	return member:hasRole(roles["funcorp"])
	--elseif permission == permissions.is_shades then
	--	return member:hasRole(roles["shades helper"])
	elseif permission == permissions.is_mod then
		return member:hasRole(MOD_ROLE.id)
	--[[elseif permission == permissions.is_staff or permission == permissions.is_owner then
		if not message or not message.channel then return auth end

		local module = message.channel.category and string.lower(message.channel.category.name) or nil
		if not module then return auth end

		local c = (permission == permissions.is_owner and "★ " or "[★⚙]+ ")

		return not not member.roles:find(function(role)
			return string.find(string.lower(role.name), "^" .. c .. module .. "$")
		end)]]
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

local addServerActivity = function(x, sub, guild)
	local activity = serverActivity[guild]
	if not activity then
		serverActivity[guild] = { }
		activity = serverActivity[guild]
	end

	local today = os.date("%d/%m/%Y")
	if not activity[today] then
		activity[today] = {
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
		activity[today].b[id] = activity[today].b[id] + sub
	elseif tx == "number" then -- New/Leave Members
		activity[today].m[x] = activity[today].m[x] + sub
	elseif x then -- Tbl
		activity[today].l[x.id] = true -- Thinking
		local id = (hasPermission(permissions.has_power, x) and 2 or 1)
		activity[today].c[id] = activity[today].c[id] + sub
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
				str = string.gsub(str, "[" .. f(repl) .. "]+", f(letter))
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
	--do return true end
	db = (raw and tostring(db) or json.encode(db))
	--if encodeBase64 then
	--	db = base64.encode(db)
	--end
	--db = string.gsub(db, "%+", "((12))")

	local head, body = http.request("POST", db_url .. "set.php?k=" .. tokens.discdb .. "&e=json&f=" .. fileName, DB_COOKIES_N_BLAME_INFINITYFREE--[[{sa
		{ "Content-Type", "application/x-www-form-urlencoded" }
	}]], db)

	return body == "true"
end

local saveGlobalCommands = function()
	--local toJson = base64.encode(json.encode(globalCommands))
	local _1 = save("serverGlobalCommands", globalCommands)
	--local _2 = save("serverGlobalCommands_2", string.sub(toJson, 70001), true)
	return _1--, _2
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
			collectgarbage()
			for r = 1, rate do
				f = fList[i]

				t = clock()
				f(r)
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
			avg[i] = ("#" .. i .. ". Test [" .. avg[i].i .. "] AVG: " .. avg[i].avg .. "ms")
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
				title = (type(errName) == "string" and ("evt@" .. errName) or errName[1]) .. " => Fatal Error!",
				description = "```\n" .. err .. "```\n```\n" .. debug.traceback() .. "```"
			}
		}

		if message then
			toDelete[message.id] = message:reply(content)
		else
			content.content = "<@" .. client.owner.id .. ">"
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
local getLuaEnv = function(extra)
	local env = {
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
		--envTfm = table.deepcopy(envTfm),
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
		memoryLimitByMember = memoryLimitByMember,
		meta = table.copy(meta),
		moduleRestrictions = table.copy(moduleRestrictions),
		modules = table.deepcopy(modules),
		moonPhase = moonPhase,

		nickList = table.copy(nickList),
		normalizeDiscriminator = normalizeDiscriminator,

		pairsByIndexes = pairsByIndexes,
		permIcons = table.copy(permIcons),
		permissions = table.copy(permissions),
		--permissionOverwrites = table.deepcopy(permissionOverwrites),
		permMaps = table.copy(permMaps),
		profileStruct = table.deepcopy(profileStruct),

		reactions = table.copy(reactions),
		removeAccents = removeAccents,
		roleColor = table.copy(roleColor),
		roleFlags = table.copy(roleFlags),
		roles = table.copy(roles),
		runtimeLimitByMember = runtimeLimitByMember,

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

	if extra then
		env.coroutine = { wrap = coroutine.wrap, running = coroutine.running, status = coroutine.status, create = coroutine.create, resume = coroutine.resume }
		env.json = { encode = json.encode, decode = json.decode }
		env.os = { clock = os.clock, date = os.date, difftime = os.difftime, time = os.time }
		env.getImageDimensions = imageHandler.getDimensions
	end

	return env
end

local getRandomTmpName = function()
	-- linux
	--return string.sub(os.tmpname(), -9)
	-- windows
	return "_" .. math.random(99999)
end

local getTimerName = function(id)
	if not timeNames[id] then
		timeNames[id] = getRandomTmpName()
	end
	return timeNames[id]
end

local runtimeLimitByMember = function(member)
	return ((member.id == client.owner.id and 100) or (hasPermission(permissions.is_module, member) and 60) or 50)
end

local memoryLimitByMember = function(member)
	return 1024 * ((member.id == client.owner.id and 150) or (hasPermission(permissions.is_module, member) and 80) or 40) -- mb
end

local addRuntimeLimit = function(parameters, message, timerNameUserId, maximumMemoryUsage)
	local func = getRandomTmpName()
	local snippet = func .. "() "

	local loads = { }
	--for posini, posend in string.gmatch(parameters, "discord[\n\r ]*%.[\n\r ]*load[\n\r ]*()%b()()") do -- It's ignored so that the function can be called in discord.load itself
	--	loads[#loads + 1] = { posini + 1, posend - 1 }
	--end

	-- Remove comments
	--parameters = string.gsub(parameters, "%-%-%[(=*)%[.-%]%1%]", '')
	--parameters = string.gsub(parameters, "%-%-[^\n]*", '')

	-- Unescape strings
	--local escapeStrings = {
	--	["\\\""] = "\\\\34",
	--	["\\'"] = "\\\\39",
	--}
	--for escaped, unescaped in next, escapeStrings do
	--	parameters = string.gsub(parameters, escaped, unescaped)
	--end

	---escapeStrings["%["] = "\\\\91"
	---escapeStrings["%]"] = "\\\\93"
	---local expect = "["
	---parameters = string.gsub(parameters, "(([%[%]])(=*)%2)", function(raw, char, eq)
	---	if char == expect then
	---		expect = expect == "[" and "]" or "["
	---		return raw
	---	else
	---		local this = escapeStrings["%" .. char]
	---		return this .. eq .. this
	---	end
	---end)

	--local strings = { }
	--for _, pattern in next, {
	--	"%b\"\"",
	--	"%b''",
	--	"(%[(=*)%[.-%]%2%])",
	--} do
	--	parameters = string.gsub(parameters, pattern, function(str)
	--		local name = getRandomTmpName()
	--		strings[name] = str:gsub("[%(%)%.%%%+%-%*%?%[%]%^%$]", "%%%0")
	--		return name
	--	end)
	--end

	local hasChanged, change = false
	for _, pattern in next, {
		"()(%f[%w%p]while.-do[\n\r ]+)",
		"()(%f[%w%p]repeat[\n\r ]+)",
		"()(%f[%w%p]for .-=.- do[\n\r ]+)",
		"()(%f[%w%p]for .- in .- do[\n\r ]+)",
		"()(%f[%w%p]function[\n\r ]*%S-[\n\r ]-%(.-%)[\n\r ]+)"
	} do
		parameters, change = string.gsub(parameters, pattern, function(pos, chunk)
			for i = 1, #loads do
				if (loads[i][1] < pos and loads[i][2] > pos) then
					return chunk
				end
			end
			return chunk .. " " .. snippet
		end)
		if not hasChanged and (change and change > 0) then
			hasChanged = true
		end
	end

	-- Escape strings
	--for escaped, unescaped in next, escapeStrings do
	--	parameters = string.gsub(parameters, unescaped, escaped)
	--end
	--for k, v in next, strings do
	--	parameters = string.gsub(parameters, k, v)
	--end

	if hasChanged then
		local member = message.member or client:getGuild(channels["guild"]):getMember(message.author.id)
		local s = runtimeLimitByMember(member)
		parameters = "local " .. func .. " do local t,e,g,s,m=os.time,error,collectgarbage,tostring,\"Your code has exceeded the runtime limit of " .. s .. "s or the memory usage has exceeded (" .. maximumMemoryUsage .. ").\"" ..
			func .. "=function() if t()>" .. getTimerName(timerNameUserId or message.author.id) .. " or g(\"count\")>" .. maximumMemoryUsage .. " then g() e(s(m),2) end end end " .. parameters
		return parameters, s
	end

	return parameters
end

local postNewBreaches = function()
	local breach = client:getChannel(channels["breach"])
	assert(breach, tostring(breach))

	local lastBreaches = { }
	local ten, err = breach:getMessages(10)
	assert(ten, tostring(err))

	for msg in ten:iter() do
		lastBreaches[msg.embed.thumbnail.url] = true
	end

	local today = os.date("%Y-%m-%d")

	local head, body = http.request("GET", "https://haveibeenpwned.com/api/v2/breaches")
	body = json.decode(body)

	local new, j = { }, 0
	for i = 1, #body do
		i = body[i]

		if (
			--i.AddedDate > '2024-08-24'
			i.AddedDate:sub(1, 10) == today
			and not lastBreaches[i.LogoPath]
		) then
			j = j + 1
			new[j] = i
		end
	end

	if j == 0 then return end

	for i = 1, j do
		i = new[i]

		breach:send({
			embed = {
				color = 0x962529,
				thumbnail = { url = i.LogoPath },
				title = "**" .. i.Name .. " HAS BEEN PWNED!**",
				description = "**" .. i.Title .. " | " .. i.Domain .. "**\n\nVerified: " .. tostring(i.IsVerified),
				fields = {
					[1] = {
						name = "What has been compromised?",
						value = "• " .. table.concat(i.DataClasses, "\n• "),
						inline = true
					},
					[2] = {
						name = "Affected accounts",
						value = i.PwnCount .. "+",
						inline = true
					},
					[3] = {
						name = "Is Sensitive",
						value = tostring(i.IsSensitive),
						inline = true
					},
					[4] = {
						name = "Happened in",
						value = tostring(i.BreachDate),
						inline = true
					},
					[5] = {
						name = "Detected in",
						value = tostring(i.AddedDate),
						inline = true
					}
				}
			}
		})
	end
end

local messageCreate, messageDelete, globalCommandCall

--[[ Commands ]]--
	-- Public
--[[commands["a801"] = {
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
}]]
commands["activity"] = {
	auth = permissions.public,
	description = "Displays the channels' and members' activity.",
	f = function(message, _, __, ___, get)
		local cachedChannels, loggedMessages = sortActivityTable(activeChannels[message.guild.id], function(id) return not client:getChannel(id) end)
		local cachedMembers, loggedMemberMessages = sortActivityTable(activeMembers[message.guild.id], function(id) return not message.guild:getMember(id) end)

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
--[[commands["adoc"] = {
	auth = permissions.public,
	description = "Gets information about a specific tfm api function.",
	f = function(message, parameters)
		--[==[
		if parameters and #parameters > 0 then
			local head, body = http.request("GET", "https://atelier801.com/topic?f=612619&t=934783")

			if body then
				body = string.gsub(string.gsub(body, "<br />", "\n"), " ", '')
				local _, init = string.find(body, "id=\"message_19532184\">•")
				body = string.sub(body, init)

				local syntax, description = string.match(body, "•%s+(%S*" .. parameters .. "%S* .-)\n(.-)\n\n\n\n")

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
									local params, counter = { }, 0
									for name, type in string.gmatch(list, "(%w+) %((.-)%)") do
										counter = counter + 1
										params[counter] = "`" .. type .. "` **" .. name .. "**"
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
		]==]

		parameters = tostring(parameters)

		local object
		for name, data in next, luaDoc do
			if name:find(parameters, 1, true) then
				object = data
				break
			end
		end
		if not object then
			toDelete[message.id] = message:reply({
				content = "<@!" .. message.author.id .. ">",
				embed = {
					color = color.lua,
					title = "<:atelier:458403092417740824> TFM API Documentation",
					description = "The function **" .. parameters .. "** was not found in the documentation."
				}
			})
			return
		end

		local parameter = { }
		if object.parameters then
			local parameters = object.description.parameters
			local tmp, subParameters, subCounter = { }
			for i = 1, #parameters do
				tmp = parameters[i]

				subCounter = 0
				subParameters = { }

				for t = 1, #tmp do
					subCounter = subCounter + 1
					subParameters[subCounter] = string.format("`%s` **%s**", tmp[t].type, tmp[t].name)
				end

				parameter[i] = string.format("%s → %s%s", table.concat(subParameters, ", "), tmp.description,
					(tmp.default and ( " (default value = " .. tmp.default .. ")" ) or ""))
			end
			parameter = table.concat(parameter, "\n")
		end

		toDelete[message.id] = message:reply({
			embed = {
				color = color.lua,
				title = string.format("<:atelier:458403092417740824> %s ( %s )", object.name, (object.parameters and table.concat(object.parameters, ", ") or '')),
				description = object.description.content ..
					(object.parameters and
						("\n\n**Arguments / Parameters**\n" .. parameter)
					or "") ..
					(object.description.returns and
						string.format("\n\n**Returns**\n`%s` : %s", object.description.returns.type, object.description.returns.description)
					or ""),
				footer = {
					text = "TFM API Documentation"
				}
			}
		})
	end
}
commands["akinator"] = {
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
					description = "**" .. parameters.name .. "'s avatar: [here](" .. url .. ")**",
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
			local head, body = http.request("GET", "http://www.lua.org/manual/5.2/manual.html")

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
						return "```Lua¨" .. (string.gsub(string.gsub(code, "\n", "¨"), "¨	 ", "¨")) .. "```"
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

			timer.setTimeout(3 * 60 * 1000, coroutine.wrap(function(msg)
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
--[=[commands["modules"] = {
	auth = permissions.public,
	description = "Lists the current modules available in Transformice. [by name | from community | level 0/1/2 | #pattern]",
	f = function(message, parameters)
		local search = {
			a_commu = false, -- alias
			commu = false,
			player = false,
			type = false,
			pattern = false
		}
		if parameters then
			if not validPattern(message, '', parameters) then return end

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
						if not validPattern(message, '', value) then return end
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
			if search.pattern and not validPattern(message, '', search.pattern) then return end
		end

		local list, counter = { }, 0

		local moduleData, moduleCommunity
		for i = 1, #db_modules do
			moduleData = db_modules[i]
			if not moduleData.isPrivate then
				moduleCommunity = (db_teamList.mt[moduleData.hoster] or "xx")
				moduleCommunity = string.lower(moduleCommunity)

				local check = (not parameters or parameters == '')
				if not check then
					check = true

					if search.commu then
						check = moduleCommunity == search.commu
					end
					if search.type then
						check = check and ((search.type == 0 and not moduleData.isOfficial) or (search.type == 1 and moduleData.isOfficial) or (search.type == 2 and moduleData.isDisabled))
					end
					if search.player then
						check = check and not not string.find(string.lower(moduleData.hoster), search.player)
					end
					if search.pattern then
						check = check and not not string.find(moduleData.name, search.pattern)
					end
				end

				if check then
					counter = counter + 1
					list[counter] = { moduleCommunity, moduleData.name, (moduleData.isDisabled and "disabled" or moduleData.isOfficial and "official" or "semi-official"), (moduleCommunity == "xx" and '-' or moduleData.hoster) }
				end
			end
		end

		if #list == 0 then
			toDelete[message.id] = message:reply({
				content = "<@!" .. message.author.id .. ">",
				embed = {
					color = color.err,
					title = "<:wheel:456198795768889344> Modules",
					description = "There are no modules " .. (search.commu and ("made by [:flag_" .. string.lower(search.commu) .. ":] **" .. string.upper(search.commu) .. "** ") or '') .. (search.player and ("made by **" .. search.player .. "** ") or '') .. (search.type and ("that are [" .. (search.type == 0 and "semi-official" or search.type == 1 and "official" or search.type == 2 and "disabled") .. "]") or '') .. (search.pattern and (" with the pattern **`" .. tostring(search.pattern) .. "`**.") or ".")
				}
			})
		else
			local out = concat(list, "\n", function(index, value)
				return (communities[value[1]] or value[1]) .. " `" .. value[3] .. "` **#" .. value[2] .. "** ~> **" .. normalizeDiscriminator(value[4]) .. "**"
			end)

			local lines, msgs = splitByLine(out), { }
			for line = 1, #lines do
				msgs[line] = message:reply({
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
}]=]
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
			if hasPermission(permissions.is_math, p.discord) then
				icon = icon .. permIcons.is_math
				if p.data[9] and table.count(p.data[9]) > 0 then

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

		if p.data.twt then
			fields[#fields + 1] = {
				name = "<:twitter:717130502447956059> Twitter",
				value = "[" .. string.gsub(p.data.twt, '_', "\\_") .. "](https://twitter.com/" .. p.data.twt .. "/)",
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
				value = "**" .. (timezone.zone or '?') .. "** @ **" .. (timezone.country or '?') .. "** (" .. code .. ")\n[GMT" .. (not timezone.utc and '' or ((timezone.utc > 0 and '+' or '') .. timezone.utc)) .. "] " .. os.date("%H:%M:%S `%d/%m/%Y`", os.time() + ((timezone.utc or 0) * 3600)),
				inline = true
			}
		end

		local activity = activeMembers[message.guild.id]
		if activity and activity[p.discord.id] then
			local cachedMembers, loggedMemberMessages = sortActivityTable(activity, function(id) return not message.guild:getMember(id) end)
			local _, o = table.find(cachedMembers, p.discord.id, 1)

			if o then
				fields[#fields + 1] = {
					name = (o > 3 and ":medal: " or ":" .. (o == 1 and "first" or o == 2 and "second" or "third") .. "_place: ") .. "Activity" .. (o > 3 and " [#" .. o .. "]" or ""),
					value = getRate(cachedMembers[o][2], loggedMemberMessages, 10) .. " [" .. cachedMembers[o][2] .. "]",
					inline = true
				}
			end
		end

		local memberRoles, len = getRoleOrder(member)

		local roleColor = member.guild.defaultRole.color
		if len > 0 then
			for i = 1, len do
				if memberRoles[i].color > 0 then
					roleColor = memberRoles[i].color
				end
			end
		end

		toDelete[message.id] = message:reply({
			embed = {
				color = (roleColor > 0 and roleColor or color.sys),

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
			local quotedChannel, quotedMessage
			quotedChannel, quotedMessage = string.match(parameters, "^https://discordapp.com/channels/%d+/(%d+)/(%d+)$")
			if not quotedChannel then
				quotedChannel, quotedMessage = string.match(parameters, "<?#?(%d+)>? *%-(%d+)")
				quotedMessage = quotedMessage or string.match(parameters, "%d+")
			end

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
						value = string.format("<:%s> Online: %s | <:%s> Away: %s | <:%s> Busy: %s | <:offline:456197711457419276> Offline: %s\n\n:raising_hand: **Total:** %s\n\n<:wheel:456198795768889344> **Tech Guru**: %s\n<:lua:468936022248390687> **Developers**: %s\n<:p5:468937377981923339> **Artists**: %s\n:earth_americas: **Translators**: %s\n:triangular_ruler: **Mathematicians**: %s\n:pencil: **Writers**: %s", reactions.online, members:count(function(member)
							return member.status == "online"
						end), reactions.idle, members:count(function(member)
							return member.status == "idle"
						end), reactions.dnd, members:count(function(member)
							return member.status == "dnd"
						end), members:count(function(member)
							return member.status == "offline"
						end), message.guild.totalMemberCount - bots, members:count(function(member)
							return member:hasRole(roles["tech guru"])
						end), members:count(function(member)
							return member:hasRole(roles["developer"])
						end), message.guild.members:count(function(member)
							return member:hasRole(roles["artist"])
						end), members:count(function(member)
							return member:hasRole(roles["translator"])
						end), members:count(function(member)
							return member:hasRole(roles["mathematician"])
						end), members:count(function(member)
							return member:hasRole(roles["writer"])
						end)),
						inline = false
					},
					[8] = {
						name = ":exclamation: Commands",
						value = "**Total**: " .. (tcommands + tgcommands --[[+ moduleCommands]]) .. "\n\n**Bot commands**: " .. tcommands .. "\n**Global Commands**: " .. tgcommands,
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
--[=[commands["tfmprofile"] = {
	auth = permissions.public,
	description = "Displays your profile on Transformice.",
	f = function(message, parameters)
		if parameters and #parameters > 2 then
			parameters = string.nickname(parameters, true)
			local head, body = http.request("GET", "https://cheese.formice.com/api/players/" .. parameters:gsub('#', '-', 1))
			body = json.decode(body)

			if body then
				if not body.id then
					return sendError(message, "TFMPROFILE", "Player '" .. parameters .. "' not found.")
				end

				local level, remain, need = expToLvl(tonumber(body.stats.shaman.experience))

				local soulmate
				if body.soulmate then
					local _
					_, soulmate = http.request("GET", "https://cheese.formice.com/api/players/" .. body.soulmate.name:gsub('#', '-', 1))
					soulmate = json.decode(soulmate)
					if soulmate then
						soulmate = soulmate.name
					end
				end

				body.id_gender = body.gender == "female" and 1 or 2

				local playerTitle = title[title._id[body.title * 1]].name
				if type(playerTitle) == "table" then
					playerTitle = playerTitle[(body.id_gender % 2 + 1)]
				end

				toDelete[message.id] = message:reply({
					embed = {
						color = color.atelier801,
						title = "<:tfm_cheese:458404666926039053> Transformice Profile - " .. parameters .. (body.id_gender == 2 and " <:male:456193580155928588>" or body.id_gender == 1 and " <:female:456193579308679169>" or ""),
						description = --[[(body.registration_date == "" and "" or (":calendar: " .. body.registration_date .. "\n\n")) .. ]]
							"**Level " .. level .. "** " .. getRate(math.percent(remain, (remain + need)), 100, 5) .. "\n"
							.. (body.tribe and body.tribe.name and ("\n<:tribe:458407729736974357> **Tribe :** " .. body.tribe.name) or "")
							.. "\n:star: «" .. playerTitle .. "»\n<:shaman:512015935989612544> "
							.. body.stats.shaman.saves_normal .. " / " .. body.stats.shaman.saves_hard .. " / " .. body.stats.shaman.saves_divine
							.. "\n<:tfm_cheese:458404666926039053> **Shaman cheese :** " .. body.stats.shaman.cheese
							.. "\n\n<:racing:512016668038266890> **Firsts :** " .. body.stats.mouse.first .. " " .. getRate(math.percent(body.stats.mouse.first, body.stats.mouse.rounds, 100), 100, 5)
							.. "\n<:tfm_cheese:458404666926039053> **Cheese: ** " .. body.stats.mouse.cheese .. " " .. getRate(math.percent(body.stats.mouse.cheese, body.stats.mouse.rounds, 100), 100, 5)
							.. "\n\n<:bootcamp:512017071031451654> **Bootcamps :** " .. body.stats.mouse.bootcamp
							.. (soulmate and ("\n\n:revolving_hearts: **" .. normalizeDiscriminator(soulmate) .. --[[(body.marriage_date and ("** since **" .. os.date("%x %X", body.marriage_date) .. "**") or]] "**"--[[)]]) or ""),
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
}]=]
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
--[=[commands["tree"] = {
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
}]=]
commands["translate"] = {
	auth = permissions.public,
	description = "Translates a sentence using Google Translate. Professional translations: <@&494665355327832064>",
	f = function(message, parameters)
		local syntax = "Use `!translate [from_language-]to_language sentence`."

		if parameters and #parameters > 0 then
			local language, content = string.match(parameters, "(%S+)[ \n]+(.+)$")
			if language and content and #content > 0 then
				if #content == 18 and tonumber(content) then
					local msgContent = message.channel:getMessage(content)
					if msgContent then
						msgContent = msgContent.content or (msgContent.embed and msgContent.embed.description)
						content = (msgContent and (string.gsub(msgContent, '`', '')) or content)
					end
				end

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
--[=[commands["xml"] = {
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
				local head, body = http.request("POST", "https://miceditor-map-preview.herokuapp.com/", { { "Content-Type", "application/json" } }, json.encode({ xml = parameters, raw =  false }))

				if head.code == 200 then
					toDelete[message.id] = message:reply({
						content = "<@!" .. message.author.id .. "> | XML ~> " .. (#parameters / 1000) .. "kb",
						embed = {
							image = { url = body }
						}
					})
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
	-- Not public]=]
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
--[[commands["prj"] = {
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
}]]
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
			return sendError(message, "RESIGN", "Role not found.", "Report it to <@" .. client.owner.id .. ">")
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
				description = "**" .. parameters.name .. "** is not a `" .. string.upper(role.name) .. "` anymore.",
				footer = { text = "Unset by " .. message.member.name }
			}
		}
		message:reply(msg)
		client:getChannel(channels["role-log"]):send(msg)
		message:delete()
	end
}
	-- Module staff
--[=[commands["cmd"] = {
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

						save("serverModulesData", modules, false, true)

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
}]=]

local wrapMessageObject = function(message)
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
			tag = message.author.name,
			fullname = message.author.name,
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
		isDM = message.channel.type == 1,
		mentionsEveryone = message.mentionsEveryone,
		oldContent = message.oldContent,
		channel = {
			id = message.channel.id,
			name = message.channel.name,
		},
	}
end
	-- Developer
commands["lua"] = {
	auth = permissions.is_dev,
	description = "Loads a Lua code.",
	f = function(message, parameters, _, isTest, compEnv, command)
		local syntax = "Use `!lua ```code``` `."
		local message_author = message.member or message.author

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

			local guild = message.guild or client:getGuild(channels["guild"])
			local _ENV = getLuaEnv(not hasAuth)
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
			ENV.discord.authorName = message.author.name
			--[[Doc
				"The id of the script message from **!lua**."
				!string|int
			]]
			ENV.discord.messageId = message.id



			ENV.discord.message = wrapMessageObject(message)

			ENV.discord.messageContent = message.content:gsub("^!%s*(%S)", "!%1") -- remove later

			ENV.discord.channel = ENV.discord.message.channel

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
						authorName = lastMessage.author.name
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

				if message.channel.type == 1 then -- dms
					msg:delete()
					return
				end

				assert((os.time() - (60 * 3)) < discordia.Date.fromISO(msg.timestamp):toSeconds(), "The message cannot be deleted after 3 minutes.")

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

				local method = string.sub(url, 1, 1)
				if method == "!" or method == "*" or method == "@" then -- POST, DELETE, PATCH
					url = string.sub(url, 2)
					method = (method == "!" and "POST" or method == "*" and "DELETE" or method == "@" and "PATCH")
				else
					method = nil
				end
				return http.request((method or "GET"), url, header, body)
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

			ENV.discord.editMessage = function(messageId, content)
				assert(messageId, "Missing parameter 'messageId' in discord.editMessage")
				assert(content, "Missing parameter 'content' in discord.editMessage")
				assert(type(content) == "table", "Parameter 'content' should be a table in discord.editMessage")

				if content.content then
					content.content = string.gsub(content.content, "[@!]*<[@!]+(%d+)>", function(id)
						return "<" .. (id == message.author.id and '' or "\\") .. "@" .. id .. ">"
					end)
					content.content = string.gsub(content.content, "@here", "@ here")
					content.content = string.gsub(content.content, "@everyone", "@ everyone")
				end

				local msg = message.channel:getMessage(messageId)
				assert(msg, "Could not find message '" .. messageId .. "'")

				assert((os.time() - (60 * 3)) < discordia.Date.fromISO(msg.timestamp):toSeconds(), "The message cannot be updated after 3 minutes.")

				msg:update(content)

				return msg.id
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
			local maximumMemoryUsage = memoryLimitByMember(message.member or guild:getMember(message.author.id))
			ENV.discord.load = function(src)
				assert(src, "Source can't be nil in discord.load")

				return load(addRuntimeLimit(src, message, nil, maximumMemoryUsage), '', 't', ENV)
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

			ENV.printt = function(s, stop, ...)
				stop = stop or 1
				s = table.tostring(s, true, true, stop, ...)
				return ENV.print((#s < 1900 and ("```Lua\n" .. s .. "```") or s))
			end

			local getOwner = function(message, name)
				local owner
				if isTest == debugAction.cmd then
					command = tostring(command)
					--local cmd = string.match(message.content, "!(%S+)")
					--cmd = string.lower(tostring(cmd))
					assert(globalCommands[command], "Source command not found (" .. (name or command) .. ").")

					owner = globalCommands[command].author

					assert(hasPermission(permissions.is_module, guild:getMember(owner)), "<@" .. owner .. "> You cannot use this function (" .. (name or '') .. ").")
				else
					owner = message.author.id
					assert(hasPermission(permissions.is_module, guild:getMember(owner)), "You cannot use this function (" .. (name or '') .. ").")
				end
				return owner
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

				ENV.load = function(src, env)
					return load(src, '', 't', (ENV or env))
				end
			end

			local timerName
			if isTest ~= debugAction.test then
				local timerNameUserId, limSeconds = message.author.id--(isTest == debugAction.cmd and getOwner(message) or message.author.id)
				if not hasAuth then
					parameters, limSeconds = addRuntimeLimit(parameters, message, timerNameUserId, maximumMemoryUsage)
				end

				timerName = getTimerName(timerNameUserId)
				ENV[timerName] = function() return os.time() + (limSeconds or runtimeLimitByMember(message.member or guild:getMember(message.author.id))) end
			end

			ENV.discord.getData = function(userId)
				assert(userId, "User id can't be nil in discord.getData")

				local owner = getOwner(message, "getData")

				return (cmdData[owner] and cmdData[owner][userId] or '')
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
				cmdData[owner][userId] = (data ~= '' and data or nil)
				return true
			end

			ENV.discord.getAllMembers = function(f)
				assert(f, "f can't be nil in discord.getAllMembers")
				assert(type(f) == "function", "f must be a function(member) in discord.getAllMembers")

				getOwner(message, "getAllMembers")

				local names, index = { }, 0
				guild.members:findAll(function(member)
					if f(member.id) then
						index = index + 1
						names[index] = member.id
					end
				end)()
				return names, index
			end

			ENV.getImage = function(url)
				assert(url, "Url can't be nil in getImage")

				getOwner(message, "getImage")

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
				memberName = tostring(memberName):lower()

				local member = guild.members:find(function(m)
					return m.name:lower() == memberName or m.user.name:lower() == memberName
				end)

				return member and member.id
			end

			ENV.discord.getMemberName = function(memberId)
				assert(memberId, "Member ID can't be nil in discord.getMemberName")
				memberId = tostring(memberId)

				local member = guild:getMember(memberId)
				return member and member.name
			end

			ENV.discord.getMemberRoles = function(memberId)
				assert(memberId, "Member ID can't be nil in discord.getMemberRoles")
				memberId = tostring(memberId)

				local member = guild:getMember(memberId)
				if not member then return end

				return table.createSet(member.roles[1])
			end

			ENV.discord.getNicknamesFromMemberNamesChannel = function(channelId)
				assert(channelId, "Channel ID can't be nil in discord.getNicknamesFromMemberNamesChannel")
				channelId = tostring(channelId)

				local channel = message.guild:getChannel(channelId)
				if not channel then return end

				assert(channel.name == "member_names", "discord.getNicknamesFromMemberNamesChannel can only look for channels named member_names")

				local messages = channel:getMessages(100)
				local names = { }

				local tmpId, tmpNickname
				for message in messages:iter() do
					tmpId, tmpNickname = message.content:match("^<@!?(%d+)> *= *(%S+)")
					if tmpId then
						names[tmpId] = message.content:match(tmpNickname)
					end
				end

				return names
			end

			ENV.discord.isMember = function(userId)
				assert(userId, "Member id cannot be nil in discord.isMember")
				return guild:getMember(userId) ~= nil
			end

			ENV.discord.sendPrivateMessage = function(content, id)
				assert(content, "Content cannot be nil in discord.sendPrivateMessage")

				if type(content) ~= "table" then
					content = tostring(content)
				end

				local sendTo = message.author
				if id and getOwner(message, "sendPrivateMessage") then
					sendTo = client:getUser(id)
					assert(sendTo, "Cannot retrieve target user in discord.sendPrivateMessage")
				end

				local msg = sendTo:send(content)
				return msg and msg.id
			end

			ENV.discord.getMessage = function(channelId, messageId)
				assert(channelId, "Channel id cannot be nil in discord.getMessage")
				assert(messageId, "Message id cannot be nil in discord.getMessage")
				channelId, messageId = tostring(channelId), tostring(messageId)

				local msg = client:getChannel(channelId):getMessage(messageId)
				return msg and wrapMessageObject(msg) or nil
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

			ENV.discord.getPinnedMessages = function(channelId)
				assert(channelId, "Channel id cannot be nil in discord.getPinnedMessages")
				channelId = tostring(channelId)

				local messages, index = { }, 0
				for message in client:getChannel(channelId):getPinnedMessages():iter() do
					index = index + 1
					messages[index] = wrapMessageObject(message)
				end

				return messages
			end

			local mainCoro = coroutine.running()
			ENV.discord.yield = function(...)
				if coroutine.running() ~= mainCoro then
					return coroutine.yield(...)
				end
				error("Can not yield main thread.", 2)
			end

			ENV.discord.waitForEvent = function(eventName, timeout)
				assert(eventName, "Event name cannot be nil in discord.waitForEvent")
				timeout = timeout or 5000

				getOwner(message, "waitForEvent")

				if eventName == "interactionCreate" then
					local success, message, member, interactionData = client:waitFor(eventName, timeout)
					return success, wrapMessageObject(message), member.user.id, interactionData
				else
					assert(false, "Event '" .. eventName .. "' is not mapped in discord.waitForEvent")
				end
			end

			ENV._G = ENV

			if timerName then
				ENV[timerName] = ENV[timerName]()
			end
			collectgarbage()
			local func, syntaxErr = load(parameters, '', 't', ENV)
			if not func then
				toDelete[message.id] = message:reply({
					embed = {
						color = color.lua_err,
						title = "[" .. message_author.name .. ".Lua] Error : SyntaxError",
						description = "```\n" .. syntaxErr .. "```"
					}
				})
				return
			end
			collectgarbage()

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
						title = "[" .. message_author.name .. ".Lua] Error : RuntimeError",
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
							text = "[" .. message_author.name .. ".Lua] Loaded successfully! (Ran in " .. ms .. "ms)"
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
			sendError(message, message_author.name .. ".Lua", "Invalid or missing parameters.", syntax)
		end
	end
}
	-- Module owner
--[[commands["delcmd"] = {
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

					save("serverModulesData", modules, false, true)

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

			save("serverModulesData", modules, false, true)

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

				save("serverModulesData", modules, false, true)

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
					sendError(message, "PUBLIC", "Something went wrong during the public message edition. Contact <@" .. client.owner.id .. ">.")
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
	-- Module team]]
commands["delgcmd"] = {
	auth = permissions.is_dev,
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
		local invalid
		if not parameters or #parameters < 3 then
			invalid = true
		end

		local emojiName, url
		if not invalid then
			emojiName, url = string.match(parameters, "^([%w_]+)[\n ]*(%S*)")
			if not emojiName then
				invalid = true
			end
		end

		if invalid then
			sendError(message, "EMOJI", "Invalid or missing parameters.", "Use `!emoji name` attached to an image or `!emoji name url`.")
			return
		end
		emojiName = string.lower(emojiName)

		local image = ((url and url ~= '') and url or (message.attachment and message.attachment.url))
		if image then
			local head, body = http.request("GET", image)

			if body then
				image = "data:image/png;base64," .. binBase64.encode(body)

				local emoji = message.guild:createEmoji(emojiName, image)
				if emoji then
					message:reply({
						embed = {
							color = color.interaction,
							title = "New Emoji!",
							description = "Emoji **:" .. emojiName .. ":** added successfully",
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

			if globalCommands[cmd] and not globalCommands[cmd].ref and not globalCommands[alias] then
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
				sendError(message, "GALIAS", "Invalid command.", "The command **" .. cmd .. "** doesn't exist, already is an alias or can't be overwritten.")
			end
		else
			sendError(message, "GALIAS", "Invalid or missing parameters.", "Use `!galias command alias`")
		end
	end
}
commands["gcmd"] = {
	auth = permissions.is_dev,
	description = "Creates a command in the global categories.",
	f = function(message, parameters)
		local category = message.channel.category and string.lower(message.channel.category.name) or nil

		if category and string.sub(category, 1, 1) == "#" then
			return sendError(message, "GCMD", "This command cannot be used for #modules. Use the command `!cmd` instead.")
		end

		local syntax = "Use `!gcmd 0|1|2 0|1|2 0|1 command_name [ script ``` script ``` ] [ value[[command_content]] ] [ title[[command_title]] ] [ description[[command_description]] ]`.\n\n[Click here to open the command generator](https://fiftysol.github.io/gcmd-generator/)"

		if parameters and #parameters > 0 then
			local script, content, title, description = getCommandFormat(parameters)
			local channelLevel, authLevel, allowDM, command = string.match(parameters, "^(%d)[\n ]+(%d)[\n ]+(%d)[\n ]+([%a][%w_%-]+)[\n ]+")

			if channelLevel then
				channelLevel = tonumber(channelLevel)
				if channelLevel < 3 then
					if authLevel then
						authLevel = tonumber(authLevel)
						if authLevel < 3 then
							if allowDM then
								allowDM = tonumber(allowDM)
								if allowDM < 2 then
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
										cmd.dm = allowDM == 1
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
									sendError(message, "GCMD", "Invalid level flag.", "The DM authorization level must be 0 (Disallowed) or 1 (Allowed).")
								end
							else
								sendError(message, "GCMD", "Invalid syntax.", syntax)
							end
						else
							sendError(message, "GCMD", "Invalid level flag.", "The authorization level must be 0 (Users), 1 (Developers) or 2 (Module Team).")
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
--[=[commands["module"] = {
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
						--local owners = client:getChannel("560901122349465611")
						--owners:getPermissionOverwriteFor(owner_role):allowPermissions(table.unpack(permissionOverwrites.owners_staffs.allowed))

						-- Staffs
						--local staffs = client:getChannel("560901441632469028")
						--staffs:getPermissionOverwriteFor(owner_role):allowPermissions(table.unpack(permissionOverwrites.owners_staffs.allowed))
						--staffs:getPermissionOverwriteFor(staff_role):allowPermissions(table.unpack(permissionOverwrites.owners_staffs.allowed))

						owner:addRole(owner_role)

						modules[module] = { commands = { } }

						save("serverModulesData", modules, false, true)

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
	-- Mod]=]
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
						description = description .. ("\n\nBy <@" .. message.member.id .. "> [" .. message.member.name .. "]"),
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
									description = "**" .. member.name .. "** is now " .. (string.find(role.name, "^[^AEIOUaeiou]") and "a" or "an") .. " `" .. string.upper(role.name) .. "`.",
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
commands["here"] = {
	auth = permissions.is_mod,
	description = "Pings @here.",
	f = function(message, parameters)
		if not parameters or #parameters < 1 then
			return sendError(message, "HERE", "Invalid or missing parameters.", "Use `!here message`.")
		end

		message:reply("@here\n<@" .. message.author.id .. "> says... " .. tostring(parameters))
		message:delete()
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

				local botRole = message.guild:getRole(roles["tech guru"]) -- MT
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
				message.channel:bulkDelete(message.channel:getMessagesAfter(messageId, limit))
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
		save("serverModulesData", modules, false, true)

		saveGlobalCommands()

		save("serverActiveChannels", activeChannels)
		save("serverActiveMembers", activeMembers)
		save("serverCommandsData", cmdData)
		save("serverActivity", serverActivity)

		message:delete()
		log("INFO", "Disconnected from '" .. client.user.name .. "'", logColor.red)
		os.exit()
	end
}
commands["refresh"] = {
	description = "Refreshes the bot.",
	f = function(message)
		if table.count(activeChannels) > 0 then
			save("serverActiveChannels", activeChannels)
		end
		if table.count(activeMembers) > 0 then
			save("serverActiveMembers", activeMembers)
		end
		if table.count(memberProfiles) > 0 then
			save("serverMemberProfiles", memberProfiles)
		end
		if table.count(cmdData) > 0 then
			save("serverCommandsData", cmdData)
		end
		if table.count(serverActivity) > 0 then
			save("serverActivity", serverActivity)
		end

		message:delete()
		os.execute("luvit bot.lua")
		os.exit()
	end
}
--[=[commands["remmodule"] = {
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
					save("serverModulesData", modules, false, true)

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
}]=]
commands["resetactivity"] = {
	description = "Resets the monthly activity.",
	f = function(message, parameters)
		-- logs the activity before, just in case it's lost
		messageCreate(client:getChannel("474253217421721600"):getMessage("551753598477008919"), true)

		local m, c = commands["activity"].f(message, nil, nil, nil, true)
		local content = "**Activity Podium** - " .. (parameters or os.date("%m/%y")) .. "\n" .. m .. "\n\n" .. c
		client:getChannel(channels["top-activity"]):send(content)

		activeChannels, activeMembers = { }, { }
		save("serverActiveChannels", activeChannels)
		save("serverActiveMembers", activeMembers)

		message:delete()
	end
}

commands["lu"]=commands["lua"]

--[[ Channel Behaviors ]]--
--[==[
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
}]==]
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
--[=[channelReactionBehavior["modules"] = {
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
}]=]
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
--[=[channelReactionBehavior["map"] = {
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
}]=]
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
	f_Add = function(message, _, _, userId, _member)
		local member = _member or message.guild:getMember(userId)

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
				value = tostring(object) .. " | " .. tostring(object.name)
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

local TRY_REQUEST = function(db, arg1, arg2)
	local tentatives, content = 0
	repeat
		tentatives = tentatives + 1
		content = getDatabase(db, arg1, arg2, true)
	until content or tentatives > 10

	if not content then
		os.execute("luvit bot.lua")
		error("Database issue -> " .. db)
	end

	return content
end

local wrapF = function(f)
	return function(...)
		return f(...)
	end
end


--[[ Events ]]--
client:on("ready", function()
	modules = {}--TRY_REQUEST("serverModulesData", false, true)
	globalCommands = TRY_REQUEST("serverGlobalCommands")--json.decode(base64.decode(getDatabase("serverGlobalCommands", true) .. getDatabase("serverGlobalCommands_2", true)))
	activeChannels = TRY_REQUEST("serverActiveChannels")
	activeMembers = TRY_REQUEST("serverActiveMembers")
	memberProfiles = TRY_REQUEST("serverMemberProfiles")
	cmdData = TRY_REQUEST("serverCommandsData")
	serverActivity = TRY_REQUEST("serverActivity")
	db_teamList = {}--TRY_REQUEST("teamList")
	db_modules = {}--TRY_REQUEST("modules")
	luaDoc = {}--TRY_REQUEST("luaDoc")
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
	--for k, v in next, table.copy(luaDoc) do
	--	if v.description.parameters then
	--		for m, n in next, v.description.parameters do
	--			for i, j in next, n do
	--				if tonumber(i) then
	--					luaDoc[k].description.parameters[m][i] = nil
	--					luaDoc[k].description.parameters[m][tonumber(i)] = j
	--				end
	--			end
	--		end
	--	end
	--end

	MOD_ROLE = client:getGuild(channels["guild"]):getRole(MOD_ROLE)

	for k, v in next, specialInvites do
		v.uses = getInviteUses(v.code)
	end

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

		}, {
			__index = restricted_Gmodule
		}),
		__add = meta.__add
	})

	devENV = setmetatable({}, {
		__index = setmetatable({
			addRuntimeLimit = addRuntimeLimit,
			addAuthId = function(id)
				authIds[id] = true
			end,

			botIds = botIds,
			boundaries = boundaries,

			channelBehavior = channelBehavior,
			channelReactionBehavior = channelReactionBehavior,
			client = client,
			cmdData = cmdData,
			commands = commands,
			coroutine = coroutine,
			currency = currency,

			discordia = discordia,

			getDatabase = getDatabase,
			getLuaEnv = getLuaEnv,
			getRoleOrder = getRoleOrder,
			getTimerName = getTimerName,
			globalCommandCall = globalCommandCall,
			globalCommands = globalCommands,

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
			specialInvites = specialInvites,

			throwError = throwError,
			timeNames = timeNames,
			timer = timer,
			tokens = tokens,

			updateCurrency = updateCurrency,

			db_teamList = db_teamList,
			db_modules = db_modules,

			postNewBreaches = postNewBreaches,

			db_url = db_url,

			getImageDimensions = imageHandler.getDimensions,

			luaDoc = luaDoc,

			fromage = require("fromage"),
		}, {
			__index = restricted_G
		}),
		__add = meta.__add
	})

	clock:start()

	-- Check for new messages in the bridge
	--for message in client:getChannel(channels["bridge"]):getMessages():iter() do
	--	client:emit("messageCreate", message)
	--end

	-- Avatar
	local moons = io.open("Content/avatars.txt", 'r')
	local counter = 0
	for avatar in moons:lines() do
		counter = counter + 1
		botAvatars[counter] = avatar
	end
	moons:close()

	-- Get title list
	--local counter, male, female = 0
	--local _, body = http.request("GET", "http://transformice.com/langues/tfm-en.gz")
	--body = require("miniz").inflate(body, 1) -- Decompress
	--for titleId, titleName in string.gmatch(body, "\n%-\nT_(%d+)=([^\n]+)") do
	--	titleId = tonumber(titleId)
	--	titleName = string.gsub(titleName, "<.->", '') -- Removes HTML
	--	titleName = string.gsub(titleName, "[%*%_~]", "\\%1") -- Escape special characters
	--	if string.find(titleName, '|', nil, true) then -- Male / Female
	--		titleName = {
	--			(string.gsub(titleName, "%((.-)|.-%)", "%1")),
	--			(string.gsub(titleName, "%(.-|(.-)%)", "%1")),
	--		} -- id % 2 + 1
	--	end
	--	counter = counter + 1
	--	title[counter] = { id = titleId, name = titleName }
	--	title._id[titleId] = counter
	--end

	currentAvatar = moonPhase()
	client:setAvatar(botAvatars[currentAvatar])
	client:setActivity("Prefix !")

	log("INFO", "Running as '" .. client.user.name .. "'", logColor.green)
end)

globalCommandCall = function(cmd, message, parameters, command)
	if message.channel.type ~= 1 then -- not a DM
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
		msgs = commands["lua"].f(message, "`" .. cmd.script .. "`", nil, debugAction.cmd, { parameters = parameters }, command)
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
	local command, parameters = string.match(message.content, "^" .. prefix .. "%s*(%S+)[\n ]+(.*)")
	command = command or string.match(message.content, "^" .. prefix .. "%s*(%S+)")

	if not command then
		if message.channel.type == 1 then return end -- dms

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
				local activity = activeChannels[message.guild.id]
				if not activity then
					activeChannels[message.guild.id] = { }
					activity = activeChannels[message.guild.id]
				end

				activity[message.channel.id] = (activity[message.channel.id] or 0) + 1
			end

			if not memberTimers[message.author.id] then
				memberTimers[message.author.id] = 0
			end
			if os.time() > memberTimers[message.author.id] then
				memberTimers[message.author.id] = os.time() + 3

				local activity = activeMembers[message.guild.id]
				if not activity then
					activeMembers[message.guild.id] = { }
					activity = activeMembers[message.guild.id]
				end

				activity[message.author.id] = (activity[message.author.id] or 0) + 1

				addServerActivity(message.member, nil, message.guild.id)
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
		if category then
			moduleCommand = true
			cmd = modules[category] and modules[category].commands[command] or nil
		end
		if not cmd then
			moduleCommand = false
			cmd = globalCommands[command] or nil
		end
	end

	if cmd then
		if cmd.ref then
			cmd = globalCommands[cmd.ref]
		end

		if message.channel.type == 1 and not cmd.dm then return end

		local member = message.member
		if not member then
			local guild = client:getGuild(channels["guild"])
			member = guild:getMember(message.author.id)
		end

		if not (authIds[message.author.id] or hasPermission(cmd.auth, member, message)) then
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

		if message.channel.type ~= 1 then
			addServerActivity(not not botCommand, nil, message.guild.id)
		end

		if botCommand then
			throwError(message, { "Command [" .. string.upper(command) .. "]" }, cmd.f, message, parameters, category)
		else
			throwError(message, { "Global Command [" .. string.upper(command) .. "]" }, globalCommandCall, cmd, message, parameters, command)
		end
	end
end
messageDelete = function(message, skipChannelActivity)
	if not message.guild or (message.guild.id ~= channels["guild"] and message.guild.id ~= '897638804750471169') then return end

	if toDelete[message.id] then
		message.channel:bulkDelete(toDelete[message.id])

		toDelete[message.id] = nil
	elseif not skipChannelActivity and message.author.id ~= client.user.id then
		local t = discordia.Date.fromISO(message.timestamp):toSeconds()
		-- Less than 1 minute = remove activity
		if (os.time() - 60) < t then
			local activity = activeChannels[message.guild.id]
			if activity and activity[message.channel.id] and activity[message.channel.id] > 0 then
				activity[message.channel.id] = activity[message.channel.id] - 1
			end

			local activity = activeMembers[message.guild.id]
			if activity and activity[message.author.id] and activity[message.author.id] > 0 then
				activity[message.author.id] = activity[message.author.id] - 1
				addServerActivity(message.member, true, message.guild.id)
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
				content = "Message from " .. (message.member and message.member:hasRole(MOD_ROLE.id) and message.author.name or ("<@" .. message.author.id .. ">")),
				embed = {
					color = color.sys,
					description = message.content,
					image = ((message.attachment and message.attachment.url) and { url = message.attachment.url } or nil),
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
	if message.channel.id == channels["bridge"] or message.embed then return end

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
	local inviteIcon = ''

	if isBot then
		local code_test = client:getChannel(channels["code-test"])
		local devPerms = code_test:getPermissionOverwriteFor(code_test.guild:getRole(roles["developer"]))
		code_test:getPermissionOverwriteFor(member):setPermissions(devPerms.allowedPermissions, devPerms.deniedPermissions)
		client:getChannel("472958910475665409"):send(":robot: beep boop")
		inviteIcon = " :robot:"
	else
		local uses
		for name, invite in next, specialInvites do
			uses = getInviteUses(invite.code)
			if invite.uses ~= uses then
				invite.uses = uses
				if invite.callback then
					invite.callback(member)
				end
				inviteIcon = invite.icon
				break
			end
		end
	end
	client:getChannel(channels["logs"]):send("<@!" .. member.id .. "> [" .. member.name .. "] just joined!" .. inviteIcon)

	if (os.time() - member.createdAt) < (60 * 60 * 24 * 15) then
		member:send("Hello, " .. member.user.fullname .. ".\n\nAccounts that have been created recently, such as alts, spy or that simply are new to Discord will not be tolerated in our server. Please, try joining at a later time.\n\nAu Revoir! <:tig:511652017819746345>")
		member:kick()
		return
	end
	if inviteIcon == '' then
		client:getChannel("472958910475665409"):send(string.format(client:getChannel(channels["greetings"]):getMessages(100):random().content, "<@" .. member.id .. ">"))
	end

	addServerActivity(1, nil, member.guild.id)
end
local memberLeave = function(member)
	client:getChannel(channels["logs"]):send({
		content = "<@" .. member.id .. "> [" .. member.name .. "] just left!\nRoles: " .. tostring(concat(member.roles:toArray(), ", ", function(_, role) return "<@&" .. role.id .. ">" end)),
		allowed_mentions = { parse = { "users" } }
	})

	local activity = activeMembers[member.guild]
	if activity and activity[member.id] then
		activeMembers[member.id] = nil
	end
	if memberProfiles[member.id] then
		memberProfiles[member.id] = nil
	end
	addServerActivity(2, nil, member.guild.id)
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
	local activity = activeChannels[channel.guild.id]
	if activity[channel.id] then
		activity[channel.id] = nil
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
		save("serverActiveChannels", activeChannels)
		save("serverActiveMembers", activeMembers)
		save("serverMemberProfiles", memberProfiles)
		save("serverCommandsData", cmdData)
		save("serverActivity", serverActivity)
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

	postNewBreaches()

	http.request("GET", db_url .. "backup.php?k=" .. tokens.discdb, DB_COOKIES_N_BLAME_INFINITYFREE)
end
clock:on("hour", function()
	throwError(nil, "ClockHour", clockHour)
end)

client:run(os.readFile("Content/token.txt", "*l"))