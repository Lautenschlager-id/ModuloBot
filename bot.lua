--[[ Discordia ]]--
local discordia = require("discordia")
discordia.extensions()

local client = discordia.Client({
	cacheAllMembers = true
})
client._options.routeDelay = 50

local clock = discordia.Clock()
local minutes = 0

--[[ Lib ]]--
local http = require("coro-http")
local json = require("json")
local timer = require("timer")

local base64 = { encode = true, decode = true }
do
	local chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
	--[[Doc
		"Encodes a string in Base64."
		@code string
		>string
	]]
	base64.encode = function(code)
		if not code then return end
		code = string.gsub(code, "\r\n", "\n")

		return (string.gsub((string.gsub(code, '.', function(x)
			local r, b = '', string.byte(x)

			for i = 8, 1, -1 do
				r = r .. (b%2^i - b%2^(i-1) > 0 and '1' or '0')
			end

			return r
		end) .. '0000'), '%d%d%d?%d?%d?%d?', function(x)
			if (#x < 6) then
				return ''
			end

			local c = 0

			for i = 1, 6 do
				c = c + (string.sub(x, i,i)=='1' and 2^(6-i) or 0)
			end

			return string.sub(chars, c+1, c+1)
		end) .. ({'', '==', '='})[#code%3 + 1])
	end
	--[[Doc
		"Decodes a Base64-crypted string."
		@code string
		>string
	]]
	base64.decode = function(code)
		if not code then return end

		code = string.gsub(code, "[^" .. chars .. "=]", '')

		return (string.gsub(string.gsub(code, '.', function(x)
			if (x == '=') then
				return ''
			end

			local r, f = '', (string.find(chars, x) - 1)

			for i = 6, 1, -1 do
				r = r .. (f%2^i - f%2^(i-1) > 0 and '1' or '0')
			end

			return r
		end), '%d%d%d?%d?%d?%d?%d?%d?', function(x)
			if (#x ~= 8) then
				return ''
			end

			local c = 0

			for i = 1, 8 do
				c = c + (string.sub(x, i, i) == '1' and 2^(8-i) or 0)
			end

			return string.char(c)
		end))
	end
end

local binBase64 = require("Content/binBase64")
local imageHandler = require("Content/imageHandler")

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
	["bridge"] = "499635964503785533"
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
	sys = 0x4F545C,
	lua = 0x272792,
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
local permissions = {
	public = 0,
	has_power = 1,
	is_module = 2,
	is_dev = 3,
	is_art = 4,
	is_map = 5,
	is_tran = 6,
	is_staff = 7,
	is_owner = 8
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
			allowed = {
				"readMessages",
				"sendMessages",
				"sendTextToSpeech",
				"embedLinks",
				"attachFiles",
				"readMessageHistory",
				"useExternalEmojis",
				"addReactions",
				"connect",
				"speak",
				"moveMembers",
				"useVoiceActivity"
			},
			denied = {
				"createInstantInvite",
				"manageChannels",
				"manageMessages"
			}
		}

		permissionOverwrites.module.owner = {
			allowed = table.sum(permissionOverwrites.module.staff.allowed, {
				"manageMessages",
				"mentionEveryone",
				"muteMembers",
				"deafenMembers"
			}),
			denied = {
				"createInstantInvite",
				"manageChannels"
			}
		}
	end
	-- #module.#announcements
	do
		permissionOverwrites.announcements = { public = { }, staff = { }, module = { } }

		permissionOverwrites.announcements.public = {
			allowed = {
				"readMessages"
			},
			denied = {
				"sendMessages"
			}
		}

		permissionOverwrites.announcements.staff = permissionOverwrites.announcements.public
	end
	-- #module.@public-#module
	do
		permissionOverwrites.public = { public = { } }

		permissionOverwrites.public.public.allowed = {
			"readMessages",
			"sendMessages",
			"embedLinks",
			"attachFiles",
			"readMessageHistory",
			"useExternalEmojis",
			"addReactions",
			"connect",
			"speak",
			"useVoiceActivity"
		}
	end
	-- community
	do
		permissionOverwrites.community = { everyone = { }, speaker = { } }

		permissionOverwrites.community.everyone.denied = { "readMessages" }

		permissionOverwrites.community.speaker.allowed = permissionOverwrites.public.public.allowed
	end
end
--[[Doc
	"Flags of the colors for some specific role types in the server."
	!table
]]
local roleColor = {
	owner = 0x9B59B6,
	staff = 0x2ECC71,
	community = 0x1ABC9C
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
	["map reviewer"] = "462329326600192010",
	["translator"] = "494665355327832064",
	["fashionista"] = "465631506489016321",
	["event manager"] = "481189370448314369"
}
for name, id in next, roles do roles[id] = name end
--[[Doc
	"The staff role names by User-Friendly IDs.
	*[Indexing the name returns the User-Friendly ID]"
	!table
]]
local roleFlags = {
	[1] = "module member",
	[2] = "developer",
	[3] = "artist",
	[4] = "map reviewer",
	[5] = "translator",
	[6] = "fashionista",
	[7] = "event manager"
}
for i, name in next, roleFlags do roleFlags[name] = i end
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
			disableTimerLog = emptyFunction
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
	mice_clan = os.readFile("Content/db_token.txt", "*l"),
	fixer = os.readFile("Content/fixer_token.txt", "*l"),
}

--[[ System ]]--
--[[Doc
	~
	"All the bot commands."
	!table
]]
local commands = {}

local devENV, moduleENV = {}, {}
--[[Doc
	"The restrictions for the admin's environment in **!lua**."
	!table
]]
local devRestrictions = { "_G", "error", "getfenv", "setfenv" }
--[[Doc
	"The restrictions for the developers' environment in **!lua**."
	!table
]]
local moduleRestrictions = { "debug", "dofile", "io", "load", "loadfile", "loadstring", "jit", "module", "p", "package", "process", "require", "os" }

--[[Doc
	"Global metamethods used in many parts of the system.
	1. **__add(a, b)** ~> Adds two tables."
	!table
]]
local meta = {
	__add = function(this, new)
		if type(new) ~= "table" then return this end
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
	"The activity channels control."
	!table
]]
local activeChannels = {}
local lastMemberTexting = {}
--[[Doc
	~
	"Flags of the country currency codes used in the command **!coin**."
	!table
]]
local currency = {}

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

--[[ Functions ]]--
--[[Doc
	"Encodes a string in the HTML format. Escapes all the characters."
	@url string
	>string
]]
local encodeUrl = function(url)
	local out = {}

	string.gsub(url, '.', function(letter)
		out[#out + 1] = string.upper(string.format("%x", string.byte(letter)))
	end)

	return '%' .. table.concat(out, '%')
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

	local embed = {
		title = title and base64.encode(title) or nil,
		description = content and base64.encode(string.trim(content)) or nil
	}

	local image = message.attachment and message.attachment.url
	if image then
		embed.image = { url = base64.encode(image) }
	else
		if (not embed.title or embed.title == '') and (not embed.description or embed.description == '') and (not script or #script < 4) then
			return "You cannot create an empty command."
		end
	end

	return {
		desc = description and base64.encode(string.trim(description)) or nil,
		embed = embed,
		script = script and base64.encode(script) or nil,
	}
end
--[[Doc
	~
	"Gets a database content."
	@fileName string
	@raw boolean*
	>table|string
]]
local getDatabase = function(fileName, raw)
	local head, body = http.request("GET", "http://miceclan.com/translators/get?k=" .. tokens.mice_clan .. "&f=" .. fileName)
	body = body:gsub("%(%(12%)%)", "+")

	local out = (raw and body or json.decode(body))

	if not body or not out then
		error("Database issue -> " .. tostring(fileName))
	end

	return out
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
	return string.format("`[%s%s] %.3f%%`", string.rep('|', rate), string.rep(' ', max - rate), (value / of * 100))
end

--[[Doc
	"Verifies if an user has permission over a specific permission flag."
	@permission int
	@member Discordia.Member
	@message Discordia.Message*
	>boolean|nil
]]
local hasPermission = function(permission, member, message)
	local auth = false
	if not permission or not member then return auth end

	if permission == permissions.public then
		return true
	elseif permission == permissions.has_power then
		return not not roles[member.highestRole.id]
	elseif permission == permissions.is_module then
		return member:hasRole(roles["module member"])
	elseif permission == permissions.is_dev then
		return member:hasRole(roles["developer"])
	elseif permission == permissions.is_art then
		return member:hasRole(roles["artist"])
	elseif permission == permissions.is_map then
		return member:hasRole(roles["map reviewer"])
	elseif permission == permissions.is_tran then
		return member:hasRole(roles["translator"])
	elseif permission == permissions.is_staff or permission == permissions.is_owner then
		if not message then return auth end

		local module = message.channel.category and string.lower(message.channel.category.name) or nil
		if not module then return auth end

		local c = (permission == permissions.is_owner and "★ " or "[★ ]*")

		return not not member.roles:find(function(role)
			return string.find(string.lower(role.name), "^" .. c .. module .. "$")
		end)
	end
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

local messageCreate = function(message, skipChannelActivity)
	-- Skips bot messages
	if message.author.bot then return end

	-- Doesn't allow private messages
	if message.channel.type == 1 then return end

	-- Bridge system
	if message.channel.id == channels["map"] then
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
					description = "Some categories you requested are unavailable. The available categories are: **P" .. concat(permMaps, "** - **P", tostring) .. "**\nConsider try sending the following maps again: `" .. table.concat(wrongPerm, "`, `") .. "`"
				}
			})
		end

		if #wrongPerm < (counter - 1) then
			message:addReaction("p41:463508055577985024")
		end
		return
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
		if string.find(message.content, "L%.?U%.?A%.?") then
			message:reply("Lua *, it's not an acronym. Noob!")
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

			if can < 3 then
				if not activeChannels[message.channel.id] then
					activeChannels[message.channel.id] = 1
				else
					activeChannels[message.channel.id] = activeChannels[message.channel.id] + 1
				end
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
		message.channel:broadcastTyping()

		if not (authIds[message.author.id] or hasPermission(cmd.auth, message.member, message)) then
			toDelete[message.id] = message:reply({
				content = "<@!" .. message.author.id .. ">",
				embed = {
					color = color.err,
					title = "Authorization denied.",
					description = "You do not have access to the command `" .. (moduleCommand and (category .. ".") or '') .. command .. "`!"
				}
			})
			return
		end

		local success, err
		if botCommand then
			success, err = pcall(cmd.f, message, parameters, category)
		else
			success, err = pcall(function()
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

				local embed = table.copy(cmd.embed)

				embed.title = base64.decode(embed.title)
				embed.description = base64.decode(embed.description)
				if embed.image then
					embed.image.url = base64.decode(embed.image.url)
				end

				local msg
				if embed.title or embed.description or embed.image then
					msg = message:reply({
						embed = embed
					})
				end

				local msgs
				if cmd.script then
					msgs = commands["lua"].f(message, (parameters and "`\nlocal parameters = \"" .. (string.gsub(tostring(parameters), "\"", "\\\"")) .. "\"\n" or "`") .. base64.decode(cmd.script) .. "`", nil, debugAction.cmd)
				end

				if msgs then
					if msg then
						msgs[#msgs + 1] = msg
					end
					toDelete[message.id] = msgs
				elseif msg then
					toDelete[message.id] = msg
				end
			end)
		end

		if not success then
			toDelete[message.id] = message:reply({
				embed = {
					color = color.lua_err,
					title = "Command [" .. string.upper(command) .. "] => Fatal Error!",
					description = "```\n" .. err .. "```"
				}
			})
		end
	end
end
local messageDelete = function(message, skipChannelActivity)
	if toDelete[message.id] then
		local msg
		for id = 1, #toDelete[message.id] do
			msg = message.channel:getMessage(toDelete[message.id][id])
			if msg then
				msg:delete()
			end
		end

		toDelete[message.id] = nil
	elseif not skipChannelActivity then
		if (os.time() - 60) < discordia.Date.fromISO(message.timestamp):toSeconds() then
			if activeChannels[message.channel.id] and activeChannels[message.channel.id] > 0 then
				activeChannels[message.channel.id] = activeChannels[message.channel.id] - 1
			end
		end
	end
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

local printf = function(...)
	local out = { }
	for arg = 1, select('#', ...) do
		out[arg] = tostring(select(arg, ...))
	end
	return table.concat(out, "\t")
end

local reactionAdd = function(cached, channel, messageId, hash, userId)
	if userId == client.user.id then return end

	local message = channel:getMessage(messageId)
	if channel.id == channels["modules"] then
		local module = message and message.embed.title

		if module then
			local member = channel.guild:getMember(userId)

			if member then
				local role = channel.guild.roles:find(function(role)
					return role.name == "public-" .. module
				end)

				if role then
					if not member:hasRole(role) then
						member:addRole(role)
					end
				end
			end
		end
	elseif channel.id == channels["commu"] then
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
	elseif channel.id == channels["map"] then
		local member = message.channel.guild:getMember(userId)

		if hasPermission(permissions.is_module, member) then
			local maps = { }
			for line in string.gmatch(message.content, "[^\n]+") do
				local cat, code = string.match(line, "^[Pp](%d+) *%- *(@%d+)$")
				if not cat then
					cat = "41"
					code = string.match(line, "^(@%d+)$")
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

			message:delete()
			for k, v in next, maps do
				client:getChannel(channels["bridge"]):send("%p" .. k .. " " .. table.concat(v, " "))
			end
		end
	elseif not cached then
		if polls[messageId] then
			local found, answer = table.find(polls.__REACTIONS, hash)
			if found then
				polls[messageId].votes[answer] = polls[messageId].votes[answer] + 1
				message:removeReaction(polls.__REACTIONS[(answer % 2) + 1], userId)
			else
				message:removeReaction(hash, userId)
			end
		end
	end
end
local reactionRemove = function(cached, channel, messageId, hash, userId)
	if userId == client.user.id then return end

	if channel.id == channels["modules"] then
		local message = channel:getMessage(messageId)
		local module = message and message.embed.title

		if module then
			local member = channel.guild:getMember(userId)

			if member then
				local role = channel.guild.roles:find(function(role)
					return role.name == "public-" .. module
				end)

				if role then
					if member:hasRole(role) then
						member:removeRole(role)
					end
				end
			end
		end
	elseif channel.id == channels["commu"] then
		for flag, flagHash in next, countryFlags do
			if not countryFlags_Aliases[flag] and flagHash == hash then
				local role = channel.guild.roles:find(function(role)
					return role.name == flag
				end)

				if role then
					channel.guild:getMember(userId):removeRole(role)
				end
				return
			end
		end
	elseif not cached then
		if polls[messageId] then
			local found, answer = table.find(polls.__REACTIONS, hash)
			if found then
				polls[messageId].votes[answer] = polls[messageId].votes[answer] - 1
			end
		end
	end
end

--[[Doc
	~
	"Saves a database."
	@fileName string
	@db table|string
	@append boolean*
	>boolean
]]
local save = function(fileName, db, append)
	local http, body = http.request("PUT", "http://miceclan.com/translators/set?k=" .. tokens.mice_clan .. "&f=" .. fileName .. (append and "&a=a" or ''), nil, "d=" .. (append and tostring(db) or json.encode(db)):gsub("%+", "((12))"))

	return body == "true"
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
		authIds = table.copy(authIds),
		
		base64 = table.copy(base64),
		binBase64 = table.copy(binBase64),
		bit32 = table.copy(bit),

		channels = table.copy(channels),
		color = table.copy(color),
		concat = concat,
		countryFlags = table.copy(countryFlags),
		countryFlags_Aliases = table.copy(countryFlags_Aliases),

		debugAction = table.copy(debugAction),
		devRestrictions = table.copy(devRestrictions),

		envTfm = table.deepcopy(envTfm),

		getCommandFormat = getCommandFormat,
		getCommandTable = getCommandTable,
		getRate = getRate,
		globalCommands = table.deepcopy(globalCommands),

		hasPermission = hasPermission,

		logColor = table.copy(logColor),

		math = table.copy(math),
		meta = table.copy(meta),
		moduleRestrictions = table.copy(moduleRestrictions),
		modules = table.deepcopy(modules),

		normalizeDiscriminator = normalizeDiscriminator,

		pairsByIndexes = pairsByIndexes,
		permissions = table.copy(permissions),
		permissionOverwrites = table.deepcopy(permissionOverwrites),
		permMaps = table.copy(permMaps),

		roleColor = table.copy(roleColor),
		roleFlags = table.copy(roleFlags),
		roles = table.copy(roles),

		splitByChar = splitByChar,
		splitByLine = splitByLine,
		string = table.copy(string),

		table = table.copy(table),

		validPattern = validPattern,		
	}
end

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
			local head, body = http.request("GET", href)

			if body then
				if string.find(body, "La requête contient un ou plusieurs paramètres invalides") then
					toDelete[message.id] = message:reply({
						embed = {
							color = color.atelier801,
							title = "<:atelier:458403092417740824> Player not found",
							description = "The player **" .. parameters .. "** does not exist."
						}
					})
				else
					local gender = ''
					if string.find(body, "Féminin") then
						gender = "<:female:456193579308679169> "
					elseif string.find(body, "Masculin") then
						gender = "<:male:456193580155928588> "
					end

					local avatar = string.match(body, "http://avatars%.atelier801%.com/%d+/%d+%.jpg")
					if not avatar then
						-- Invisible image
						avatar = "https://i.imgur.com/dkhvbrg.png"
					end

					local community = string.match(body, "Communauté :</span> <img src=\"/img/pays/(.-)%.png\"")
					if not community or community == "xx" then
						community = "<:international:458411936892190720>"
					else
						community = ":flag_" .. community .. ":"
					end

					local fields = {
						[1] = {
							name = "Registration Date",
							value = ":calendar: " .. tostring(string.match(body, "Date d'inscription</span> : (.-)</span>")),
							inline = true,
						},
						[2] = {
							name = "Community",
							value = community,
							inline = true,
						},
						[3] = {
							name = "Messages",
							value = ":speech_balloon: " .. tostring(string.match(body, "Messages : </span>(%d+)")),
							inline = true,
						},
						[4] = {
							name = "Prestige",
							value = ":hearts: " .. tostring(string.match(body, "Prestige : </span>(%d+)")),
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
			sendError(message, "A801", "Missing or invalid parameters.", "Use `!a801 player_name`.")
		end
	end
}
commands["adoc"] = {
	auth = permissions.public,
	description = "Gets information about a specific tfm api function.",
	f = function(message, parameters)
		if parameters and #parameters > 0 then
			local head, body = http.request("GET", "https://atelier801.com/topic?f=826122&t=924910")

			if body then
				body = string.gsub(string.gsub(body, "<br />", "\n"), " ", '')
				local _, init = string.find(body, "id=\"message_19463601\">•")
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
					description = string.gsub(description, "&#(%d+)", function(dec) return string.char(dec) end)

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
			sendError(message, "ADOC", "Missing or invalid parameters.", "Use `!adoc function_name`.")
		end
	end
}
commands["avatar"] = {
	auth = permissions.public,
	description = "Displays someone's avatar.",
	f = function(message, parameters)
		parameters = not parameters and message.author.id or string.match(parameters, "<@!?(%d+)>")
		parameters = parameters and client:getUser(parameters)

		if parameters then
			local url = parameters.avatarURL .. "?size=2048"

			toDelete[message.id] = message:reply({
				embed = {
					color = color.sys,
					description = "**" .. parameters.fullname .. "'s avatar: [here](" .. url .. ")**",
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

				to = string.match(parameters, "^...")
				if to then
					to = string.upper(to)
					if not currency[to] then
						sendError(message, "COIN", ":fire: | Invalid to_currency '" .. to .. "'!", available_currencies)
						return
					end
				end

				from = string.match(parameters, "[ \n]+(...)[ \n]*")
				if from then
					from = string.upper(from)
					if not currency[from] then
						sendError(message, "COIN", ":fire: | Invalid from_currency '" .. from .. "'!", available_currencies)
						return
					end
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
						description = string.format("$ %.2f", amount)
					}
				})
			else
				sendError(message, "COIN", "Missing or invalid parameters.", syntax)
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
					parameters = nil
				end
			else
				parameters = hex
			end

			if not parameters then
				sendError(message, "COLOR", "Invalid hexadecimal or RGB code.")
				return
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
			sendError(message, "COLOR", "Missing or invalid parameters.", "Use `!color #hex_code` or `!color rgb(r, g, b)`.")
		end
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
						return "```LUA¨" .. (string.gsub(string.gsub(code, "\n", "¨"), "¨     ", "¨")) .. "```"
					end)

					description = string.gsub(description, "&sect;", "§")
					description = string.gsub(description, "&middot;", ".")
					description = string.gsub(description, "&nbsp;", " ")
					description = string.gsub(description, "&gt;", ">")
					description = string.gsub(description, "&lt;", "<")
					description = string.gsub(description, "&pi;", "π")

					description = string.gsub(description, "<a href=\"(#.-)\">(.-)</a>", "[%2](https://www.lua.org/manual/5.2/manual.html%1)")

					description = string.gsub(description, "\n", " ")
					description = string.gsub(description, "¨", "\n")
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
			sendError(message, "DOC", "Missing or invalid parameters.", "Use `!doc function_name`.")
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
			table.sort(modules[category].commands, function(c1, c2) return c1.auth < c2.auth end)

			toDelete[message.id] = message:reply({
				content = "<@!" .. message.author.id .. ">",
				embed = {
					color = color.sys,
					title = category .. " commands",
					description = concat(modules[category].commands, "\n", function(cmd, data)
						return ":small_" .. (data.auth == 0 and "orange" or "blue") .. "_diamond: **" .. (modules[category].prefix or "!") .. cmd .. "** " .. (data.desc or '')
					end)
				}
			})
		else
			local cmds = {}
			for cmd, data in next, (cmdSrc or commands) do
				local ret = ''
				if not data.category or data.category == (message.channel.category and message.channel.category.id or nil) then
					if not data.channel or data.channel == message.channel.id then
						if (data.auth and hasPermission(data.auth, message.member, message) or authIds[message.author.id]) then
							if not data.auth then
								ret = ":gear: "
							elseif data.auth > permissions.public then
								ret = ":small_blue_diamond: "
							else
								ret = ":small_orange_diamond: "
							end

							local description = data.description
							if not description then
								description = data.desc and base64.decode(data.desc) or nil
							end

							cmds[#cmds + 1] = {
								str = ret .. "**!" .. cmd .. "** " .. (description and ("- " .. description) or ''),
								auth = data.auth
							}
						end
					end
				end
			end
			table.sort(cmds, function(a, b)
				local x, y = a.auth or 999, b.auth or 999
				return x < y
			end)

			local lines = splitByLine(concat(cmds, "\n", function(index, value)
				return value.str
			end))

			local msg = { }
			for line = 1, #lines do
				msg[line] = message:reply({
					content = (line == 1 and "<@!" .. message.author.id .. ">" or nil),
					embed = {
						color = color.sys,
						title = (line == 1 and "Commands" or nil),
						description = lines[line]
					}
				})
			end
			toDelete[message.id] = msg
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
		local syntax = "Use `!list role_name/flag`.\n\nThe available roles are:" .. concat(roleFlags, '', function(id, name)
			return tonumber(id) and "\n\t• [" .. id .. "] " .. name or ''
		end)

		if parameters and #parameters > 0 then
			local numP = tonumber(parameters)
			parameters = numP and tostring(roleFlags[numP]) or string.lower(string.gsub(parameters, "%s+", " "))

			local role = message.guild.roles:find(function(role)
				return string.lower(role.name) == parameters
			end)

			if not role then
				sendError(message, "LIST", "The role '" .. parameters .. "' does not exist.", syntax)
				return
			end

			local members = { }
			for member in message.guild.members:findAll(function(member) return member:hasRole(role.id) end) do
				members[#members + 1] = member.name
			end

			toDelete[message.id] = message:reply({
				embed = {
					color = color.sys,
					title = "<:wheel:456198795768889344> Members with the role " .. string.upper(parameters) .. " ( " .. #members .. " )",
					description = ":small_blue_diamond:" .. table.concat(members, "\n:small_blue_diamond:")
				}
			})
		else
			sendError(message, "LIST", "Missing or invalid parameters.", syntax)
		end
	end
}
commands["modules"] = {
	auth = permissions.public,
	description = "Lists the current modules available in Transformice. [by name | from community | level 1/2 | #pattern]",
	f = function(message, parameters)
		local head, body = http.request("GET", "https://atelier801.com/topic?f=826122&t=926606")

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
commands["quote"] = {
	auth = permissions.public,
	description = "Quotes an old message.",
	f = function(message, parameters)
		if parameters and #parameters > 0 then
			local quotedChannel, quotedMessage = string.match(parameters, "(%d+)%-(%d+)")
			quotedMessage = quotedMessage or string.match(parameters, "%d+")

			if quotedMessage then
				local msg = client:getChannel(quotedChannel or message.channel)
				if msg then
					msg = msg:getMessage(quotedMessage)

					if msg then
						message:delete()

						local memberName = message.guild:getMember(msg.author.id)
						memberName = memberName and memberName.name or msg.author.fullname

						local embed = {
							color = color.sys,

							author = {
								name = memberName,
								icon_url = msg.author.avatarURL
							},
							description = (msg.embed and msg.embed.description) or msg.content,

							fields = {
								{
									name = "Link",
									value = "[Click here](https://discordapp.com/channels/" .. msg.guild.id .. "/" .. msg.channel.id .. "/" .. msg.id .. ")"
								}
							},

							footer = {
								text = "In " .. (msg.channel.category and (msg.channel.category.name .. ".#") or "#") .. msg.channel.name,
							},
							timestamp = string.gsub(msg.timestamp, " ", ""),
						}

						local img = (msg.attachment and msg.attachment.url) or (msg.embed and msg.embed.image and msg.embed.image.url)
						if img then embed.image = { url = img } end

						message:reply({ content = "_Quote from **" .. (message.member or message.author).name .. "**_", embed = embed })
					end
				end
			end
		else
			sendError(message, "QUOTE", "Missing or invalid parameters.", "Use `!quote [channel_id-]message_id`.")
		end
	end
}
commands["serverinfo"] = {
	auth = permissions.public,
	description = "Displays fun info about the server.",
	f = function(message)
		local members = message.guild.members

		local bots = members:count(function(member) return member.bot end)

		local loggedMessages, channels, counter = 0, { }, 0
		for k, v in next, table.copy(activeChannels) do
			if not client:getChannel(k) or v < 1 then
				activeChannels[k] = nil
			else
				counter = counter + 1
				channels[counter] = { k, v }
				loggedMessages = loggedMessages + v
			end
		end
		table.sort(channels, function(c1, c2) return c1[2] > c2[2] end)

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
						name = ":family_mmgb: Members",
						value = string.format("<:online:456197711356755980> Online: %s | <:idle:456197711830581249> Away: %s | <:dnd:456197711251636235> Busy: %s | <:offline:456197711457419276> Offline: %s\n\n:raising_hand: **Total:** %s\n\n<:wheel:456198795768889344> **Module Members**: %s\n<:lua:468936022248390687> **Developers**: %s\n<:p5:468937377981923339> **Artists**: %s\n<:p41:463508055577985024> **Map Reviewers**: %s\n:earth_americas: **Translators**: %s\n<:dance:468937918115741718> **Fashionistas**: %s\n<:idea:463505036564234270> **Event Managers**: %s\n\n:robot: **Bots**: %s", members:count(function(member)
							return member.status == "online"
						end), members:count(function(member)
							return member.status == "idle"
						end), members:count(function(member)
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
							return member:hasRole(roles["map reviewer"])
						end), members:count(function(member)
							return member:hasRole(roles["translator"])
						end), members:count(function(member)
							return member:hasRole(roles["fashionista"])
						end), members:count(function(member)
							return member:hasRole(roles["event manager"])
						end), bots),
						inline = false
					},
					[6] = {
						name = ":chart_with_upwards_trend: Active channels",
						value = concat(channels, "\n", function(index, value)
							local channel = client:getChannel(value[1])
							return (index > 3 and ":medal: " or ":" .. (index == 1 and "first" or index == 2 and "second" or "third") .. "_place: ") .. (channel.category and (channel.category.name .. ".#") or "#") .. channel.name .. "\n" .. getRate(value[2], loggedMessages, 30) .. " [" .. value[2] .. "]"
						end, 1, 5),
						inline = false
					}
				},
			}
		})
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
	-- Not public
commands["poll"] = {
	auth = permissions.has_power,
	description = "Creates a poll.",
	f = function(message, parameters)
		if table.find(polls, message.author.id, "authorID") then
			sendError(message, "POLL", "Poll limit", "There is already a poll made by <@!" .. message.author.id .. ">.")
			return
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
				sendError(message, "POLL", "Fatal Error", "Try this command again later.")
				return
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
			sendError(message, "POLL", "Missing or invalid parameters.", "Use `!poll question` or `!poll ```question``` poll_time` ` `poll_option_1` ` ` ` ` `poll_option_2` ` ` `.")
		end
	end
}
commands["remind"] = {
	auth = permissions.has_power,
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
			sendError(message, "REMIND", "Missing or invalid parameters.", "Use `!remind time_and_order text`.")
		end
	end
}
commands["word"] = {
	auth = permissions.has_power,
	description = "Translates a sentence using Google Translate. Professional translations: https://discord.gg/mMre2Dz",
	f = function(message, parameters)
		local syntax = "Use `!word from_language-to_language ``` sentence ``` `."

		if parameters and #parameters > 0 then
			local language, _, content = string.match(parameters, "(.-)[ \n]+`(`?`?)(.*)%2`")
			if language and content and #content > 0 then
				language = string.lower(language)
				content = string.sub(content, 1, 100)

				local head, body = http.request("GET", "https://translate.yandex.net/api/v1.5/tr.json/translate?key=trnsl.1.1.20180406T014324Z.87adf2b8b3335e7c.212f70178f4e714754506277683f3b2cf308c272&text=" .. encodeUrl(content) .. "&lang=" .. language .. (string.find(language, "%-") and '' or "&options=1"))
				body = json.decode(tostring(body))

				if body and body.text then
					body.lang = string.lower(body.lang)
					local from, to = string.match(body.lang, "(.-)%-(.+)")

					from, to = string.upper(from), string.upper(to)

					toDelete[message.id] = message:reply({
						embed = {
							color = color.interaction,
							title = ":earth_americas: Quick Translation",
							description = (countryFlags[from] or '') .. "@**" .. from .. "**\n```\n" .. content .. "```" .. (countryFlags[to] or '') .. "@**" .. to .. "**\n```\n" .. table.concat(body.text, "\n") .. "```"
						}
					})
				end
			else
				sendError(message, "WORD", "Invalid parameters.", syntax)
			end
		else
			sendError(message, "WORD", "Missing parameters.", syntax)
		end
	end,
}
commands["xml"] = {
	auth = permissions.has_power,
	description = "Displays a map based on the XML.",
	f = function(message, parameters)
		if parameters and #parameters > 0 then
			if string.find(parameters, "pastebin.com/raw/") then
				local head, body = http.request("GET", parameters)

				if body then
					parameters = "```\n" .. body .. "```"
				else
					sendError(message, "XML", "Invalid pastebin link.")
					return
				end
			end

			local _
			_, parameters = string.match(parameters, "`(`?`?)(.*)%1`")

			if not parameters then
				sendError(message, "XML", "Invalid syntax.", "Use `!xml ``` XML ```.")
				return
			end

			if string.find(parameters, "<C>") then
				local head, body = http.request("POST", "http://tfmmap.hunyan.dx.am/map.php", { { "content-type", "application/x-www-form-urlencoded" } }, "xml=" .. encodeUrl(parameters))

				if body then
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
			sendError(message, "XML", "Missing or invalid parameters.", "Use `!xml ``` XML ``` ` or `!xml pastebin_link`.")
		end
	end,
}
	-- Module staff
commands["cmd"] = {
	auth = permissions.is_staff,
	description = "Creates a command for the #module category.",
	f = function(message, parameters)
		local category = message.channel.category and string.lower(message.channel.category.name) or nil

		if not (category and string.sub(category, 1, 1) == "#") then
			sendError(message, "CMD", "This command cannot be used in this category.")
			return
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
							sendError(message, "CMD", "This command already exists.")
							return
						end

						local cmd = getCommandTable(message, script, content, title, description)
						if type(cmd) == "string" then
							sendError(message, "CMD", cmd)
							return
						end
						cmd.auth = (authLevel == 0 and permissions.public or permissions.is_staff)

						modules[category].commands[command] = cmd

						save("b_modules", modules)

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
			sendError(message, "CMD", "Missing or invalid parameters.", syntax)
		end
	end
}
	-- Developer
commands["lua"] = {
	auth = permissions.is_dev,
	description = "Runs Lua.",
	f = function(message, parameters, _, isTest)
		local syntax = "Use `!lua ```code``` `."

		if parameters and #parameters > 2 then
			local foo
			foo, parameters = string.match(parameters, "`(`?`?)(.*)%1`")

			if not parameters or #parameters == 0 then
				sendError(message, "LUA", "Invalid syntax.", syntax)
				return
			end

			local lua_tag, final = string.find(string.lower(parameters), "^lua\n+")
			if lua_tag then
				parameters = string.sub(parameters, final + 1)
			end

			local hasAuth = authIds[message.author.id] and not isTest

			local dataLines = {}
			local repliedMessages = {}

			local ENV = (hasAuth and devENV or moduleENV) + getLuaEnv()
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
			ENV.discord.authorName = message.author.fullname
			--[[Doc
				"The id of the script message from **!lua**."
				!string|int
			]]
			ENV.discord.messageId = message.id
			--[[Doc
				"Deletes a message sent by the bot."
				@msgId string|int
			]]
			ENV.discord.delete = function(msgId)
				assert(msgId, "Missing parameters in discord.delete")

				local msg = message.channel:getMessage(msgId)
				assert(msg, "Message not found")

				assert((msg.channel.id ~= channels["commu"] and msg.channel.id ~= channels["modules"]), "Message deletion denied.")

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
				>table, string
			]]
			ENV.discord.http = function(url, header, body)
				assert(url, "Missing url link in discord.http")

				return http.request("GET", url, header, body)
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
							text.content = string.gsub(text.content, "<[@!&]+(%d+)>", "%1")
							text.content = string.gsub(text.content, "@here", "@ here")
							text.content = string.gsub(text.content, "@everyone", "@ everyone")
						end
						if isTest ~= debugAction.cmd and text.embed and text.embed.description then
							text.embed.description = string.gsub(text.embed.description, "<[@!&]+(%d+)>", "%1")
							text.embed.description = string.gsub(text.embed.description, "@here", "@ here")
							text.embed.description = string.gsub(text.embed.description, "@everyone", "@ everyone")
						end
					else
						text = string.gsub(text, "<[@!&]+(%d+)>", "%1")
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

				return load(src, '', 't', ENV)
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
				dataLines[#dataLines + 1] = r == '' and " " or r
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
			end

			local func, syntaxErr = load(parameters, '', 't', ENV)
			if not func then
				toDelete[message.id] = message:reply({
					embed = {
						color = color.luaerr,
						title = "[Lua] Error : SyntaxError",
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
						color = color.luaerr,
						title = "[Lua] Error : RuntimeError",
						description = "```\n" .. runtimeErr .. "```"
					}
				})
				return
			end

			local result
			if isTest ~= debugAction.cmd then
				result = message:reply({
					embed = {
						title = "[" .. message.member.name .. ".Lua] Loaded successfully!",
						description = "  ",
						footer = {
							text = "Script ran in " .. ms .. "ms."
						},
					}
				})
			end

			local lines = splitByLine(table.concat(dataLines, "\n"))

			local messages = { }
			for id = 1, math.min(#lines, (hasAuth and 5 or 3)) do
				messages[#messages + 1] = message:reply({
					embed = {
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
			sendError(message, "LUA", "Missing or invalid parameters.", syntax)
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

			if command then
				command = string.lower(command)
				if modules[category].commands[command] then
					modules[category].commands[command] = nil

					save("b_modules", modules)

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
			sendError(message, "DELCMD", "Missing or invalid parameters.", syntax)
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

			save("b_modules", modules)

			message:reply({
				content = "@here",
				embed = {
					color = color.sys,
					description = "The prefix in the module `" .. category .. "` was set to `" .. parameters .. "` successfully!"
				}
			})

			message:delete()
		else
			sendError(message, "PREFIX", "Missing or invalid parameters.", syntax)
		end
	end
}
commands["public"] = {
	auth = permissions.is_owner,
	description = "Creates a public role and a public channel for the #module.",
	f = function(message, parameters, category)
		local edition = false

		if not string.find(category, "#") then
			sendError(message, "PUBLIC", "You can not use this command in a category that is not a module.")
			return
		else
			edition = modules[category].hasPublicChannel
		end

		local syntax = "Use `!public module_description`."

		if parameters and #parameters > 0 then
			if not edition then
				local public_role = message.guild:createRole("public-" .. category)

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

				local staff_roles = { }
				message.guild.roles:find(function(role)
					if role.name == "★ " .. category or role.name == category then
						staff_roles[string.sub(role.name, 1, 1) == "#" and "staff" or "owner"] = role
					end
					return false
				end)

				for k, v in next, staff_roles do
					setPermissions(public_channel:getPermissionOverwriteFor(v), permissionOverwrites.module[k].allowed, permissionOverwrites.module[k].denied)
				end

				modules[category].hasPublicChannel = true

				save("b_modules", modules)

				message:reply({
					content = "@here",
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
				}):addReaction("\xF0\x9F\x99\x8B")

				local del_msg = m_channel:send("@here")
				del_msg:delete()
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
				sendError(message, "PUBLIC", "Missing or invalid parameters.", syntax)
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
					sendError(message, "STAFF", "Module owners already are staff of their modules.")
					return
				end

				local role = message.guild.roles:find(function(role)
					return role.name == category
				end)

				if role then
					if not member:hasRole(role.id) then
						member:addRole(role)

						message:reply({
							content = parameters .. ", <@!" .. message.author.id .. ">",
							embed = {
								color = role.color,
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
								color = role.color,
								title = "Fire!",
								thumbnail = { url = member.user.avatarURL },
								description = "**" .. member.name .. "** is not part of the " .. category .. " staff anymore!"
							}
						})
					end

					message:delete()
				else
					sendError(message, "STAFF", "Role not found for this category", "Private message **" .. client.owner.fullname .. "**")
				end
			else
				sendError(message, "STAFF", "Invalid syntax, user or member.", syntax)
			end
		else
			sendError(message, "STAFF", "Missing or invalid parameters.", syntax)
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
				if globalCommands[command] and globalCommands[command].author == message.author.id then
					globalCommands[command] = nil

					save("b_gcommands", globalCommands)

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
			sendError(message, "DELGCMD", "Missing or invalid parameters.", syntax)
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

					local file = io.open("test.txt", "w")
					file:write(image)
					file:flush()
					file:close()

					local emoji = message.channel.guild:createEmoji(parameters, image)
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
				sendError(message, "EMOJI", "Missing or invalid image attachment.")
			end
		else
			sendError(message, "EMOJI", "Missing or invalid parameters.", "Use `!emoji name` attached to an image.")
		end
	end
}
commands["gcmd"] = {
	auth = permissions.is_module,
	description = "Creates a command in the global categories.",
	f = function(message, parameters)
		local category = message.channel.category and string.lower(message.channel.category.name) or nil

		if category and string.sub(category, 1, 1) == "#" then
			sendError(message, "GCMD", "This command cannot be used in for #modules. Use the command `!cmd` instead.")
			return
		end

		local syntax = "Use `!gcmd 0|1|2 0|1|2 command_name [ script ``` script ``` ] [ value[[command_content]] ] [ title[[command_title]] ] [ description[[command_description]] ]`."

		if parameters and #parameters > 0 then
			local script, content, title, description = getCommandFormat(parameters)
			local channelLevel, authLevel, command = string.match(parameters, "^(%d)[\n ]+(%d)[\n ]+([%a][%w_%-]+)[\n ]+")

			if channelLevel then
				channelLevel = tonumber(channelLevel)
				if channelLevel < 3 then
					if authLevel then
						authLevel = tonumber(authLevel)
						if authLevel < 3 then
							if command then
								command = string.lower(command)

								if globalCommands[command] and globalCommands[command].author ~= message.author.id then
									sendError(message, "GCMD", "This command already exists. Ask <@" .. globalCommands[command].author .. "> for an edition.")
									return
								end

								local cmd = getCommandTable(message, script, content, title, description)
								if type(cmd) == "string" then
									sendError(message, "GCMD", cmd)
									return
								end

								cmd.author = message.author.id
								cmd.auth = (authLevel == 0 and permissions.public or authLevel == 1 and permissions.is_dev or permissions.is_module)
								if channelLevel == 1 then
									cmd.category = message.channel.category.id
								elseif channelLevel == 2 then
									cmd.channel = message.channel.id
								end

								globalCommands[command] = cmd

								save("b_gcommands", globalCommands)

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
			sendError(message, "GCMD", "Missing or invalid parameters.", syntax)
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
							- #module -> @★ #module; #module
								~discussion

							[ May have ]
							@public-#module
							~chat
							~maps
							~images
							~translations
							~talk
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

						local staff_role = message.guild:createRole(module)
						staff_role:setColor(roleColor.staff)
						staff_role:moveUp(publicChannels - 1)

						-- Permissions
						category:getPermissionOverwriteFor(message.guild.defaultRole):denyPermissions(table.unpack(permissionOverwrites.module.everyone.denied))

						setPermissions(category:getPermissionOverwriteFor(owner_role), permissionOverwrites.module.owner.allowed, permissionOverwrites.module.owner.denied)

						setPermissions(category:getPermissionOverwriteFor(staff_role), permissionOverwrites.module.staff.allowed, permissionOverwrites.module.staff.denied)

						-- Announcements
						setPermissions(announcements_channel:getPermissionOverwriteFor(staff_role), permissionOverwrites.announcements.staff.allowed, permissionOverwrites.announcements.staff.denied)

						owner:addRole(owner_role)

						modules[module] = { commands = { } }

						save("b_modules", modules)

						message:reply({
							embed = {
								color = color.sys,
								title = "<:wheel:456198795768889344> " .. module,
								description = "The module **" .. module .. "** was created successfully!"
							}
						})
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
			sendError(message, "MODULE", "Missing or invalid parameters.", syntax)
		end
	end
}
commands["set"] = {
	auth = permissions.is_module,
	description = "Gives a role to a member.",
	f = function(message, parameters)
		local syntax = "Use `!set @member_name/member_id role_name/role_flag`."

		if parameters and #parameters > 0 then
			local member, role = string.match(parameters, "<@!?(%d+)>[\n ]+(.+)")

			if not member then
				member, role = string.match(parameters, "(%d+)[\n ]+(.+)")
			end

			if member and role then
				member = message.guild:getMember(member)
				if member then
					local numR = tonumber(role)
					local role_id = roles[numR and roleFlags[numR] or string.lower(role)]
					if role_id then
						if message.member:hasRole(role_id) or authIds[message.author.id] then
							if not member:hasRole(role_id) then
								member:addRole(role_id)

								role = message.guild:getRole(role_id)

								local footer = { text = "Set by " .. message.member.name }
								if string.lower(role.name) == "event manager" then
									message:reply({
										embed = {
											color = role.color,
											description = ":eyes: <@!" .. member.id .. ">",
											footer = footer
										}
									})
								else
									message:reply({
										embed = {
											color = role.color,
											title = "Promotion!",
											thumbnail = { url = member.user.avatarURL },
											description = "**" .. member.name .. "** is now a `" .. string.upper(role.name) .. "`.",
											footer = footer
										}
									})
								end
								message:delete()
							else
								sendError(message, "SET", "Member already have the role.")
							end
						else
							sendError(message, "SET", "You cannot assign a role you don't have.")
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
			return
		end
		sendError(message, "SET", "Missing or invalid parameters.", syntax)
	end
}
	-- Freeaccess
commands["cleareact"] = {
	description = "Refreshes the #modules reactions.",
	f = function(message)
		local channel = client:getChannel(channels["modules"])

		for member in message.guild.members:iter() do
			for role in message.guild.roles:findAll(function(role) return string.find(role.name, "public") end) do
				if member:hasRole(role.id) then
					local module = string.match(role.name, "#(.+)")

					local msg = client:getChannel(channels["modules"]):getMessages():find(function(msg)
						return msg.embed and (msg.embed.title == module)
					end)

					if msg then
						local reaction = msg.reactions:get("\xF0\x9F\x99\x8B")

						if reaction and not reaction:getUsers(100):get(member.id) then
							member:removeRole(role.id)
						end
					end
				end
			end
		end

		for msg in channel:getMessages():iter() do
			if msg.reactions and msg.embed then
				for reaction in msg.reactions:iter() do
					for user in reaction:getUsers(100):iter() do
						if not user.bot then
							local member = msg.guild:getMember(user.id)

							if not member then
								msg:removeReaction(reaction.emojiName, user.id)
							else
								local role_name = "public-" .. msg.embed.title
								local role = (msg.guild.roles:find(function(role)
									return role_name == role.name
								end)).id

								if not member:hasRole(role) then
									member:addRole(role)
								end
							end
						end
					end
				end
			end
		end

		message:reply({
			embed = {
				color = color.sys,
				description = "The reactions were refreshed!"
			}
		})
		message:delete()
	end
}
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
				role:moveUp(botRole.position - 8)

				local channel = message.guild:createTextChannel(parameters)
				channel:setCategory("472948887230087178") -- category Community

				channel:getPermissionOverwriteFor(message.guild.defaultRole):denyPermissions(table.unpack(permissionOverwrites.community.everyone.denied))
				channel:getPermissionOverwriteFor(role):allowPermissions(table.unpack(permissionOverwrites.community.speaker.allowed))

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
			sendError(message, "COMMU", "Missing or invalid parameters.", syntax)
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
			sendError(message, "DEL", "Missing or invalid parameters.", syntax)
		end
	end
}
commands["exit"] = {
	description = "Ends the bot process.",
	f = function(message)
		save("b_modules", modules)
		save("b_gcommands", globalCommands)
		save("b_activechannels", activeChannels)
		message:delete()
		log("INFO", "Disconnected from '" .. client.user.name .. "'", logColor.red)
		os.exit()
	end
}
commands["refresh"] = {
	description = "Refreshes the bot.",
	f = function(message)
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
						return role.name == parameters
					end)

					local public_role = message.guild.roles:find(function(role)
						return role.name == "public-" .. parameters
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
					save("b_modules", modules)

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
			sendError(message, "REMMODULE", "Missing or invalid parameters.", syntax)
		end
	end
}

--[[ Events ]]--
client:on("ready", function()
	modules = getDatabase("b_modules")
	globalCommands = getDatabase("b_gcommands")
	activeChannels = getDatabase("b_activechannels")

	-- Imageshack
	if not io.popen("convert"):read() then
		os.execute("sudo apt install imagemagic -y")
	end

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
			client = table.copy(client),
			commands = table.deepcopy(commands),
			currency = table.copy(currency),

			discordia = table.copy(discordia),

			getDatabase = getDatabase,
			getLuaEnv = getLuaEnv,

			http = table.copy(http),

			imageHandler = imageHandler,

			json = table.copy(json),

			log = log,

			--[[Doc
				~
				"Prints a string in the console."
				@... *
			]]
			printf = function(...)
				return print(...)
			end,

			save = save,
			sendError = sendError,
			setPermissions = setPermissions,

			updateCurrency = updateCurrency
		}, {
			__index = restricted_G
		}),
		__add = meta.__add
	})

	clock:start()

	log("INFO", "Running as '" .. client.user.name .. "'", logColor.green)
end)

client:on("messageCreate", function(message)
	if not modules then return end

	local success, err = pcall(messageCreate, message)
	if not success then
		toDelete[message.id] = message:reply({
			embed = {
				color = color.lua_err,
				title = "evt@MessageCreate => Fatal Error!",
				description = "```\n" .. err .. "```"
			}
		})
	end
end)
client:on("messageUpdate", function(message)
	if not modules then return end

	messageDelete(message, true)
	messageCreate(message, true)
end)
client:on("messageDelete", function(message)
	local success, err = pcall(messageDelete, message)
	if not success then
		toDelete[message.id] = message:reply({
			embed = {
				color = color.lua_err,
				title = "evt@MessageDelete => Fatal Error!",
				description = "```\n" .. err .. "```"
			}
		})
	end
end)

client:on("memberJoin", function(member)
	client:getChannel(channels["logs"]):send("<@!" .. member.id .. "> [" .. member.name .. "] just joined!")
end)
client:on("memberLeave", function(member)
	client:getChannel(channels["logs"]):send("<@" .. member.id .. "> [" .. member.name .. "] just left!")
end)

client:on("reactionAddUncached", function(channel, messageId, hash, userId)
	local success, err = pcall(reactionAdd, true, channel, messageId, hash, userId)
	if not success then
		toDelete[messageId] = channel:send({
			embed = {
				color = color.lua_err,
				title = "evt@ReactionAdd => Fatal Error!",
				description = "```\n" .. err .. "```"
			}
		})
	end
end)
client:on("reactionAdd", function(reaction, userId)
	local success, err = pcall(reactionAdd, false, reaction.message.channel, reaction.message.id, reaction.emojiName, userId)
	if not success then
		toDelete[reaction.message.id] = reaction.message:reply({
			embed = {
				color = color.lua_err,
				title = "evt@ReactionAdd => Fatal Error!",
				description = "```\n" .. err .. "```"
			}
		})
	end
end)

client:on("reactionRemoveUncached", function(channel, messageId, hash, userId)
	local success, err = pcall(reactionRemove, true, channel, messageId, hash, userId)
	if not success then
		toDelete[messageId] = channel:send({
			embed = {
				color = color.lua_err,
				title = "evt@ReactionRemove => Fatal Error!",
				description = "```\n" .. err .. "```"
			}
		})
	end
end)
client:on("reactionRemove", function(reaction, userId)
	local success, err = pcall(reactionRemove, false, reaction.message.channel, reaction.message.id, reaction.emojiName, userId)
	if not success then
		toDelete[reaction.message.id] = reaction.message:reply({
			embed = {
				color = color.lua_err,
				title = "evt@ReactionRemove => Fatal Error!",
				description = "```\n" .. err .. "```"
			}
		})
	end
end)

clock:on("min", function()
	if not modules then return end
	minutes = minutes + 1

	if minutes == 1 then
		updateCurrency()
	end

	if minutes % 5 == 0 then
		save("b_activechannels", activeChannels)
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
end)

clock:on("hour", function()
	if not modules then return end
	updateCurrency()
end)

client:run(os.readFile("Content/token.txt", "*l"))
