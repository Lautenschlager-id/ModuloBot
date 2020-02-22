-- Consts
local CHAR_LIM = 255
local CHAT_MSG_LIM = 2
local WHISPER_MSG_LIM = 3
local ANTI_SPAM_TIME = 8
local DATA = { }
do
	local counter = 0
	for line in io.lines("acc") do
		counter = counter + 1
		DATA[counter] = line
	end
end

-- Deps
local timer = require("timer")
local http = require("coro-http")
local json = require("json")

-- Libs
local discordia = require("discordia")
local transfromage = require("Transfromage")

-- Init
local disc = discordia.Client({
	cacheAllMembers = true
})
disc._options.routeDelay = 0
local tfm = transfromage.client:new()
tfm:processXml()

-- Init methods
string.trim = function(str)
	return (string.gsub(tostring(str), "^ *(.*) *$", "%1"))
end

table.map = function(list, f)
	local newList, counter = { }, 0
	for k, v in next, list do
		counter = counter + 1
		newList[counter] = f(v, k)
	end
	return newList
end

table.keys = function(list, f)
	local out, counter = { }, 0
	for k, v in next, list do
		if not f or f(k, v) then
			counter = counter + 1
			out[counter] = k
		end
	end
	return out
end

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

-- Data
local object = { }
local channel = transfromage.enum({
	-- Message
	help = "544935946290987009",
	lua = "544936074237968434",
	mapcrew = "565716126814830612",
	shadestest = "546429085451288577",
	whisper = "547882749348806673",
	teamTool = "663181550891958295"
})
local settingchannel = {
	discussion = "544935729508253717",
	memberList = "544936174544748587"
}
local miscChannel = {
	transfromage_tokens = "579687024219389954"
}
local categoryId = "544935544975786014"

local helper = { _commu = { } }
local isConnected = false
local isWorking = false
local lastServerPing, lastUserReply, lastUserWhispered

local dressroom = { }
local onlinePlayer = { }
local modList, mapcrewList = { }, { }
local timeCmd = { }
local modulesCmd = { }
local xml = { queue = { } }
local userCache = { }
local profile = { }
local checkTitles = { }
local friendRemoval
local displayBlacklist = { }
local checkAvailableRewards = { }

local mapCategory = require("data/mapCategory")
local roleColors = require("data/roleColors")
local countryFlags = require("data/countryFlags")

local titleRequirements = require("data/titleRequirements")

local titleFields = { "cheeses", "firsts", "savesNormal", "savesHard", "savesDivine", "bootcamps" }
local titleFieldsKeys = { "$cheese", "$first", "$svnormal", "$svhard", "$svdiv", "$boot" }

local unavailableTitles = require("data/unavailableTitles")

local translate
do
	local normalizeTitles = function(titleName)
		titleName = string.gsub(titleName, "<.->", '') -- Removes HTML
		titleName = string.gsub(titleName, "[%*%_~]", "\\%1") -- Escape special characters
		return titleName
	end

	local meta
	meta = {
		__newindex = function(this, index, value)
			local lang = transfromage.enum.language[index]

			local downloaded
			os.log("↑info↓[TRANSLATION]↑ Downloading the language ↑highlight↓" .. lang .. "↑")
			transfromage.translation.download(lang, function()
				downloaded = true
				os.log("↑success↓[TRANSLATION]↑ Downloaded the language ↑highlight↓" .. lang .. "↑")
				-- Fix titles
				transfromage.translation.free(lang, nil, "^T_%d+")
				transfromage.translation.set(lang, "^T_%d+", normalizeTitles)
			end)

			timer.setTimeout(2500, function()
				if not downloaded then
					meta.__newindex(this, index, value)
				end
			end)

			rawset(this, index, require("data/lang/" .. index))
		end,
		__call = function(this, community, str, ...)
			community = community and this[community] or this.en

			str = string.gsub(str, "%$(%w+)", function(line)
				return community[line] or this.en[line] or ("$" .. line)
			end)
			return string.format(str, ...)
		end
	}

	translate = setmetatable({ }, meta)
end

translate.en = true
translate.br = true
translate.es = true

local teamListAbbreviated = {
	mt = "ModuleTeam",
	fs = "FashionSquad",
	fc = "Funcorp",
	sent = "Sentinel",
	sh = "ShadesHelpers",
	st = "ShadesTranslators"
}

local specialHeaders = {
	english = { { "Accept-Language", "en-US,en;q=0.9" } },
	json = { { "Content-Type", "application/json" } },
	urlencoded = { { "Content-Type", "application/x-www-form-urlencoded" } }
}

local countryCodeConverted = {
	AR = "SA",
	EN = "GB",
	HE = "IL",
	VK = "NO"
}

local cachedTeamListDisplay = { }

local teamList = { }
local teamListHasBeenChanged = false
local teamListFileTimer = 0

local githubWebhook = {
	id = "649659668913717270",
	name = "Lautenschlager-id",
	actionName = "github-actions[bot]",
	embedType = "rich",
	waitingAction = false
}

local ENV
local toDelete = setmetatable({}, {
	__newindex = function(list, index, value)
		if value then
			if value.channel then
				value = { value.id }
			else
				value = table.map(value, function(c)
					return c.id
				end)
			end

			rawset(list, index, value)
		end
	end
})

-- Functions
do
	_G.error = function(msg, lvl)
		coroutine.wrap(function(msg, lvl)
			if lvl == transfromage.enum.errorLevel.low then
				if disc then
					disc:getChannel(channel.shadestest):send("<@" .. disc.owner.id .. ">, low level error.\n```\n" .. msg .. "```")
				else
					p(msg, lvl)
				end
			else
				if disc then
					disc:getChannel(channel.shadestest):send("<@" .. disc.owner.id .. ">, high level error.\n```\n" .. msg .. "```")
				end
				os.exit(p(msg, lvl))
			end
		end)(msg, lvl)
	end
end

timer.setIntervalCoro = function(t, f, ...)
	return timer.setInterval(t, coroutine.wrap(f), ...)
end

timer.setTimeoutCoro = function(t, f, ...)
	return timer.setTimeout(t, coroutine.wrap(f), ...)
end

local protect = function(f)
	return function(...)
		local success, err = pcall(f, ...)
		if not success then
			object.shadestest:send({
				content = "<@" .. disc.owner.id .. ">",
				embed = {
					color = 0xFFAA00,
					title = "Error",
					description = "```\n" .. err .. "```",
					fields = {
						[1] = {
							name = "Traceback",
							value = "```\n" .. debug.traceback() .. "```",
							inline = false
						}
					},
					timestamp = discordia.Date():toISO()
				}
			})
			return false
		end
		return true
	end
end

local setHelper, remHelper
do
	local parse = function(line)
		local id, nick, tag, commu = string.match(line, "^<@!?(%d+)> += +([^#]+)(#?%d*) += +(..)")
		tag = (tag == '' and "#0000" or tag)

		return id, nick, tag, commu
	end

	setHelper = function(line)
		local id, nick, tag, commu = parse(line)

		helper[nick] = id
		if tag ~= "#0000" then
			nick = nick .. tag
		end
		helper[id] = nick
		helper[nick] = id

		helper._commu[id] = commu
	end

	remHelper = function(line)
		local id, nick, tag, commu = parse(line)

		helper[id] = nil
		helper[nick] = nil
		helper[nick .. tag] = nil

		helper._commu[id] = nil
	end
end

local removeSpaces = function(str)
	str = string.trim(tostring(str))
	str = string.gsub(str, " +", ' ')
	return str
end

local formatReceiveText = function(str)
	str = string.gsub(tostring(str), '`', '\'')

	str = string.gsub(str, "%S+", function(word)
		if #word > 1 then
			local value
			if string.sub(word, 1, 1) == '@' then
				value = string.match(string.sub(word, 2), "(.-)%p*$")
				value = string.toNickname(value)
				if helper[value] then
					return "<@" .. (tonumber(helper[value]) and helper[value] or value) .. ">"
				else
					value = string.lower(value)
					value = settingchannel.discussion.members:find(function(member)
						return string.lower(member.name) == value or string.lower(member.username) == value or (member.nickname and string.lower(member.nickname) == value) or string.lower(member.fullname) == value
					end)
					if value then
						return "<@" .. value.id .. ">"
					end
				end
			else
				value = string.match(word, "<@%d+>")
				if value then
					return value
				end
				value = string.match(word, "^https?://[%w]+%..+")
				if value then
					--if http.request("GET", value) then
					return value
					--end
				end
			end
		end
		return "`" .. word .. "`"
	end)

	return str
end

local formatSendText = function(str)
	str = string.gsub(tostring(str), "<(.)!?(%d+)>", function(t, id)
		if t == '#' then
			local channel = disc:getChannel(id)
			if channel then
				return "#" .. channel.name
			else
				return "#deleted-channel"
			end
		elseif t == '@' then
			if helper[id] then
				return "@" .. helper[id]
			else
				local user = disc:getUser(id)
				if user then
					return "@" .. tostring(user.fullname)
				end
			end
			return "@invalid-user"
		end
	end)
	str = string.gsub(str, "<(:.-:)%d+>", "%1")

	return str
end

local formatServerMemberList = function(str, role, requester)
	local title, data = string.match(str, "(.-): (.*)")
	title = title or str

	if data then
		data = string.gsub(data, "#%d+", "`%1`")
		data = string.gsub(data, "%[.-%]", "`%1`")
		data = string.gsub(data, "| ?", "\n")
	end

	return {
		embed = {
			color = (role and roleColors[role] or 0x36393F),
			title = title,
			description = data,
			footer = {
				text = "Requested by " .. requester
			}
		}
	}
end

local splitMsgByWord = function(user, msg, maxMsgs, countByByte)
	user = (user and ("[" .. user .. "] ") or '')

	local maxLen = CHAR_LIM - #user

	msg = string.trim(msg)
	local len
	if countByByte then
		len = #msg
	end
	msg = string.utf8(msg)
	local contentLen = #msg
	if len then
		maxLen = maxLen - (len - contentLen)
	end

	local messages, outputCounter = { }, 0

	local current = 1
	while current <= contentLen do
		if msg[current] == ' ' then -- Ignores the first space of the message
			current = current + 1
		end

		outputCounter = outputCounter + 1
		messages[outputCounter] = user .. table.concat(msg, nil, current, math.min(contentLen, current + (maxLen - 1)))

		current = current + maxLen
		if outputCounter == maxMsgs then break end
	end

	return messages, (contentLen >= current and table.concat(msg, nil, current) or nil) -- Messages, Missing
end

local encodeUrl = function(url)
	local out, counter = {}, 0

	for letter in string.gmatch(url, '.') do
		counter = counter + 1
		out[counter] = string.upper(string.format("%02x", string.byte(letter)))
	end

	return '%' .. table.concat(out, '%')
end

local srcMemberListCmd = {}
local createListCommand = function(code)
	local name = string.gsub(code, "[%s_](%l)", string.upper)
	local src = {
		_loading = '',
		_timer = 0,
		_onlineMembers = setmetatable({ state = 0, data = '', team = '' }, {
			__call = function(this, language)
				if this.state == 0 then
					return translate(language, "$noteam", this.team)
				elseif this.state == 1 then
					return translate(language, "$onteam", this.team, this.data)
				else
					return "$ERROR State=" .. tostring(this.state)
				end
			end
		}),
		_queue = { }
	}
	srcMemberListCmd[name] = src

	return function(playerCommunity, isDebugging, playerName, param)
		local isServerCmd = type(playerCommunity) == "table"
		if isServerCmd then
			playerCommunity, isDebugging, playerName, param = "en", playerCommunity, isDebugging, playerName
		end

		local request = false
		if src._loading == '' then
			if src._timer > os.time() then
				if isServerCmd then
					return isDebugging:reply(formatServerMemberList(src._onlineMembers(playerCommunity), name, isDebugging.author.fullname))
				else
					return src._onlineMembers(playerCommunity)
				end
			else
				request = true
			end
		end

		if isServerCmd then
			param = playerName
			playerName = nil
		end
		src._queue[#src._queue + 1] = { playerName = playerName, isDebugging = isDebugging, param = param, isServerCmd = isServerCmd, language = playerCommunity }

		if request then
			tfm:sendRoomMessage(name .. " get_team" .. code)
		end
	end
end

local getCommunityCode = function(playerCommunity)
	local commu = transfromage.enum.chatCommunity(playerCommunity)
	return (commu ~= "az" and commu ~= "ch" and commu ~= "sk") and commu or "int"
end

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

local printf = function(...)
	local out = { }
	for arg = 1, select('#', ...) do
		out[arg] = tostring(select(arg, ...))
	end
	return table.concat(out, "\t")
end

local getDatabase = function(fileName, isRaw)
	local _, body = http.request("GET", "http://discbotdb.000webhostapp.com/get?k=" .. DATA[9] .. "&e=json&f=" .. fileName)
	body = (not isRaw and json.decode(body) or body)

	if not body then
		return false, error("[Database] Failed to get data.", transfromage.enum.errorLevel.low)
	end

	return body
end

local saveDatabase = function(fileName, data, isRaw)
	if not isRaw then
		data = json.encode(data)
	end

	local _, body = http.request("POST", "http://discbotdb.000webhostapp.com/set?k=" .. DATA[9] .. "&e=json&f=" .. fileName, specialHeaders.json, data)

	return body == "true"
end

-- Command Functions
do
	local sendWhisper = tfm.sendWhisper
	tfm.sendWhisper = function(self, playerName, message, appendMsg, countByByte)
		lastUserWhispered = playerName

		local messages, cutSlice = splitMsgByWord(appendMsg, message, WHISPER_MSG_LIM, countByByte)
		for m = 1, #messages do
			sendWhisper(self, playerName, messages[m])
		end
		return cutSlice
	end

	local sendChatMessage = tfm.sendChatMessage
	tfm.sendChatMessage = function(self, playerName, message, appendMsg, countByByte)
		local messages, cutSlice = splitMsgByWord(appendMsg, message, CHAT_MSG_LIM, countByByte)
		for m = 1, #messages do
			sendChatMessage(self, playerName, messages[m])
		end
		return cutSlice
	end
end

local dressroomLink
do
	local getLook = function(look)
		local fur, items = string.match(look, "(%d+)(.+)")

		local out = { tonumber(fur) }

		local counter, colorCounter = 1, 0
		for item, colors in string.gmatch(items, "[;,](%d+)([_+%x]*)") do
			local tmp = { id = tonumber(item), colors = { } }

			colorCounter = 0
			for c in string.gmatch(colors, "[_+](%x+)") do
				colorCounter = colorCounter + 1
				tmp.colors[colorCounter] = c
			end
			counter = counter + 1
			out[counter] = tmp
		end

		return out
	end

	local dressRoomTags = { 's', 'h', 'y', 'e', 'm', 'n', 'd', 't', 'c', "hd" }
	dressroomLink = function(look)
		look = getLook(look)
		local url = "https://projects.fewfre.com/a801/transformice/dressroom/?"

		local data, uri = {
			{ dressRoomTags[1], look[1] }
		}, { }
		for i = 2, #dressRoomTags do
			data[i] = { dressRoomTags[i], look[i].id, look[i].colors }
		end

		local counter, colors = 0
		for i = 1, #data do
			if data[i][2] > 0 then
				if data[i][3] and #data[i][3] > 0 then
					colors = ";" .. table.concat(data[i][3], ';')
				else
					colors = ''
				end
				counter = counter + 1
				uri[counter] = data[i][1] .. "=" .. data[i][2] .. colors
			end
		end
		url = url .. table.concat(uri, '&')

		return url
	end
end

local secToDate = function(s)
	local m = (s / 60) % 60
	local h = (s / 3600) % 24
	local d = s / 86400
	s = s % 60

	return string.format("%02dd%02dh%02dm%02ds", d, h, m, s)
end

local remDefaultDiscriminator = function(playerName, _ignoreLimit)
	return string.gsub(playerName, "#0000", '', (not _ignoreLimit and 1 or nil))
end

local loadXmlQueue
do
	local failEmbed = {
		color = 0x36393F,
		title = "Fail"
	}
	local fail = function(mapCode)
		failEmbed.description = "Map **" .. mapCode .. "** doesn't exist or can't be loaded."
		xml[mapCode].message:reply({
			content = "<@" .. xml[mapCode].message.author.id .. ">",
			embed = failEmbed
		})

		if xml[mapCode].reply then
			xml[mapCode].reply:delete()
		end

		table.remove(xml.queue, 1)
		xml[mapCode] = nil

		loadXmlQueue()
	end

	loadXmlQueue = function()
		if #xml.queue > 0 then
			xml[xml.queue[1]].timer = timer.setTimeoutCoro(1500, fail, xml.queue[1])

			tfm:sendCommand("np " .. xml.queue[1])
		end
	end
end

local serverCommand
local hostRanking = protect(function(data, pages, indexes, msg)
	local head, body
	local ranking, counter, semicounter = { { } }, 1, 0

	for i = 1, pages do
		head, body = http.request("GET", "https://cheese.formice.com/transformice/ranking/" .. data.uri .. "/?p=" .. i)

		for value in string.gmatch(body, "<td>(.-)</td>") do
			semicounter = semicounter + 1

			ranking[counter][semicounter] = string.gsub(string.gsub(string.gsub(value, " *<.->", ''), ',', ''), "&#(%d+);", string.char)

			if semicounter == indexes then
				ranking[counter] = table.concat(ranking[counter], '\001', 2)

				semicounter = 0
				counter = counter + 1
				ranking[counter] = { }
			end
		end
	end

	ranking = os.time() .. table.concat(ranking, '\002', 1, pages * 100)

	local len, reply = #ranking
	if len > 30000 then
		reply = msg:reply("Cannot save '#" .. data.name .. "' because the space has been exceeded.")
	else
		-- player]values[player2]values
		tfm.bulle:send({ 29, 21 }, transfromage.byteArray:new():write32(data.id):writeUTF(ranking)) -- Calls eventTextAreaCallback

		reply = msg:reply("'#" .. data.name .. "' leaderboard updated!")
	end
	reply:setContent(reply.content .. " (" .. len .. "/30000)")
end)

local hostModule = protect(function(message, module, script)
	local moduleRoom = "*#" .. module

	local tentative = 0

	local updater = transfromage.client:new()
	updater:on("ready", protect(function()
			message:reply("#" .. module .. ": Connecting...")
			updater:connect(DATA[6], DATA[7], moduleRoom)
	end))

	updater:on("connectionFailed", protect(function()
		tentative = tentative + 1
		if tentative < 4 then
			message:reply("#" .. module .. ": Trying to connect...")
			updater:start(DATA[3], DATA[4])
		else
			message:reply("#" .. module .. ": Can't connect now. Try again later.")
			updater = nil
		end
	end))

	local triggered = false
	updater:once("connection", protect(function()
		message:reply("#" .. module .. ": Connected. Loading module.")
		updater:loadLua(script)

		timer.setTimeout(15000, function()
			if not triggered then
				updater:emit("lua", "<V>[" .. moduleRoom .. "] Lua script loaded")
			end
		end)
	end))

	updater:on("lua", function(log)
		if not string.find(log, "<V>[" .. moduleRoom .. "]", 1, true) then return end

		triggered = true
		message:reply("#" .. module .. ": " .. log)

		if string.find(log, "Lua script loaded") then
			message:reply("#" .. module .. ": Hosting module")
			updater:sendCommand(DATA[8] .. " " .. module)
		end

		timer.setTimeout(5000, coroutine.wrap(function()
			message:reply("#" .. module .. ": Disconnecting")
			updater:disconnect()
		end))
	end)

	updater:emit("connectionFailed")
end)

local isPlayer = function(playerName)
	local _, body = http.request("GET", "https://atelier801.com/profile?pr=" .. encodeUrl(playerName), specialHeaders.english)

	return not string.find(body, "The request contains one or more invalid parameters")
end

local encodeTeamList = function()
	return table.concat(table.map(teamList, function(list, teamName)
		return teamName .. "{" .. table.concat(table.map(list, function(community, playerName)
			return playerName .. ";" .. community
		end), ';') .. "}"
	end))
end

local getTitle = function(titleId, gender, community, _ignoreGenderIndex)
	gender = (_ignoreGenderIndex and gender or (gender % 2 + 1))

	local title, hasGender = transfromage.translation.get(transfromage.enum.language[(community or "en")], "T_" .. titleId)
	title = (title and (hasGender and title[gender] or title) or titleId)

	return title, hasGender
end

local modTracker = { }
do
	modTracker.requested = false
	modTracker.data = nil

	local request = function()
		modTracker.requested = true
		tfm:sendCommand("mod")
	end

	modTracker.init = protect(function()
		repeat
			print("Getting mod tracker list")
			modTracker.data = getDatabase("modTracker")
		until modTracker.data

		request()
		timer.setInterval(60 * 5 * 1000, request)
	end)

	local normalize = function(data)
		data = string.gsub(data, "\n%[.-%] ", '')
		data = string.gsub(data, "<BV>(.-#)%d+</BV>,? ?", "%1")
		return data
	end

	modTracker.receive = protect(function(data)
		modTracker.requested = false

		data = normalize(data)

		local now = os.date("%d/%m/%Y")
		if not modTracker.data[now] then
			modTracker.data[now] = { data }
		else
			modTracker.data[now][#modTracker.data[now] + 1] = data
		end

		print("Saving mod tracker data")
		local tentative, hasSaved = 0
		repeat
			tentative = tentative + 1
			hasSaved = saveDatabase("modTracker", modTracker.data)
		until hasSaved or tentative > 5

		if tentative > 5 then
			disc:getChannel(channel.shadestest):send("<@" .. disc.owner.id .. ">, could not save modTracker data.")
		end
	end)
end

-- Commands
local chatHelpSource, whisperHelpSource, memberHelpSource
local commandWrapper, chatCommand, whisperCommand--, serverCommand
do
	local help = function(src, param, level, language, prefix)
		language = language or "en"
		prefix = prefix or ','

		if param then
			param = string.lower(param)
			if string.sub(param, 1, 1) == prefix then
				param = string.sub(param, 2)
			end

			local cmdList = (level == 0 and chatCommand or level == 1 and whisperCommand or (level == 2 or level == 3) and serverCommand)
			if commandWrapper[param] then
				return "'" .. prefix .. param .. "' → " .. translate(language, tostring(commandWrapper[param]))
			elseif cmdList[param] and (level ~= 3 or cmdList[param].pb) then
				return "'" .. prefix .. param .. "' → " .. (cmdList[param].auth and ("[<@&" .. cmdList[param].auth .. "> only] ") or cmdList[param].owner and ("[Bot owner only] ") or '') .. translate(language, tostring(cmdList[param]))
			end
			return translate(language, "$nocmd", prefix .. param)
		end
		return translate(language, "$hlist", prefix .. "help", prefix, prefix .. table.concat(src, (" | " .. prefix)))
	end

	local teams = {
		mt = { "Module Team", "https://goo.gl/ZJcnhZ" },
		--fs = { "Fashion Squad", "http://bit.ly/2I1FY4d" },
		sh = { "Shades Helper", "https://discord.gg/quch83R" },
		mc = { "Mapcrew", "https://goo.gl/forms/V11VIzC68yCMzKSH3" }
	}
	local teamAliases = { }
	-- MT
	teamAliases.moduleteam = "mt"
	teamAliases["module team"] = "mt"
	teamAliases.lua = "mt"
	teamAliases.luateam = "mt"
	teamAliases.luadev = "mt"
	teamAliases.dev = "mt"
	-- FS
	--teamAliases.fashionsquad = "fs"
	--teamAliases["fashion squad"] = "fs"
	--teamAliases.fashion = "fs"
	-- SH
	teamAliases.helper = "sh"
	teamAliases.shades = "sh"
	teamAliases.shelper = "sh"
	teamAliases["shades helper"] = "sh"
	teamAliases["shade helper"] = "sh"
	-- MC
	teamAliases.mapcrew = "mc"
	teamAliases.map = "mc"

	-- Whisper, Server
	local c_mt = {
		pb = true,
		h = "$mt",
		f = createListCommand(" module_team")
	}
	local c_fs = {
		pb = true,
		h = "$fs",
		f = createListCommand(" fashion_squad")
	}
	local c_fc = {
		pb = true,
		h = "$fc",
		f = createListCommand(" funcorp")
	}
	local c_sent = {
		pb = true,
		h = "$sent",
		f = createListCommand(" sentinel")
	}
	local c_sh = {
		pb = true,
		h = "$sh",
		f = createListCommand(" shades_helpers")
	}

	commandWrapper = { -- playerCommunity, param, target, isChatCommand
		["luadoc"] = {
			link = true,
			h = "$hdoc",
			f = function()
				return translate(playerCommunity, "$doc", "https://atelier801.com/topic?f=5&t=451587&p=1#m3")
			end
		},
		["apply"] = {
			link = true,
			h = "$happ ',apply $team'",
			f = function(playerCommunity, param)
				if param then
					param = string.lower(param)
					local d = teams[param] or (teamAliases[param] and teams[teamAliases[param]])
					return (d and translate(playerCommunity, "$app", d[1], d[2]) or translate(playerCommunity, "$noapp"))
				else
					return translate(playerCommunity, "$ateam", table.concat(table.map(teams, function(value)
						return value[1]
					end), " | "))
				end
			end
		}
	}
	chatCommand = { -- playerCommunity, target, playerName, param
		["help"] = {
			h = "$help",
			f = function(playerCommunity, channelName, _, parameters)
				tfm:sendChatMessage(channelName, translate(playerCommunity, "$nohelp", "help"))
			end
		}
	}
	whisperCommand = { -- playerCommunity, isDebugging(4 #shadestest), playerName, Param
		["help"] = {
			h = "$help",
			f = function(playerCommunity, isDebugging, playerName, parameters)
				local t = help(whisperHelpSource, parameters, 1, playerCommunity)
				if isDebugging then
					return t
				else
					tfm:sendWhisper(playerName, t)
				end
			end
		},
		["about"] = {
			h = "$info",
			f = function(playerCommunity, isDebugging, playerName)
				local t = translate(playerCommunity, "$about", "Fifty Shades of Lua", "discord.gg/quch83R", "Bolodefchoco#0000")
				if isDebugging then
					return t
				else
					tfm:sendWhisper(playerName, t)
				end
			end
		},
		["dischelpers"] = {
			h = "$helper",
			f = function(playerCommunity, isDebugging, playerName)
				local online, counter = { }, 0
				for member in settingchannel.discussion.members:findAll(function(member) return member.status ~= "offline" end) do
					if helper[member.id] then
						counter = counter + 1
						online[counter] = "[" .. helper._commu[member.id] .. "] " .. member.fullname .. " (" .. helper[member.id] .. ")"
					end
				end
				table.sort(online, function(m1, m2)
					return string.match(m1, "%b()$") < string.match(m2, "%b()$")
				end)

				local t = (#online == 0 and translate(playerCommunity, "$nohelper") or translate(playerCommunity, "$onhelper", table.concat(online, ", ")))
				if isDebugging then
					return t, true
				else
					tfm:sendWhisper(playerName, t, nil, true) -- Counts by bytes because of Blank's nickname that is handled wrong by TFM.
				end
			end
		},
		["dressroom"] = {
			link = true,
			h = "$dress",
			f = function(playerCommunity, isDebugging, playerName, parameters)
				if parameters and #parameters > 2 then
					parameters = string.toNickname(parameters, true)
				else
					parameters = playerName
				end

				dressroom[parameters] = { playerName = playerName, isDebugging = isDebugging, playerCommunity = playerCommunity }
				tfm:sendCommand("profile " .. parameters)
			end
		},
		["moduleteam"] = c_mt,
		["fashionsquad"] = c_fs,
		["funcorp"] = c_fc,
		["makebot"] = {
			link = true,
			h = "$make",
			f = function(playerCommunity, isDebugging, playerName)
				local t = translate(playerCommunity, "$dmake", "discord.gg/quch83R")
				if isDebugging then
					return t
				else
					tfm:sendWhisper(playerName, t)
				end
			end
		},
		["sentinel"] = c_sent,
		["shelpers"] = c_sh,
		["title"] = {
			h = "$title",
			f = function(playerCommunity, isDebugging, playerName, parameters)
				if parameters and #parameters > 2 then
					parameters = string.toNickname(parameters, true)
				else
					parameters = playerName
				end

				checkTitles[parameters] = { playerName = playerName, isDebugging = isDebugging, playerCommunity = playerCommunity }
				tfm:sendCommand("profile " .. parameters)
			end
		},
		["rank"] = {
			h = "$hrank",
			f = function(playerCommunity, isDebugging, playerName, parameters)
				if parameters and #parameters > 2 then
					parameters = string.toNickname(parameters, true)
				else
					parameters = playerName
				end

				local answer
				local head, body = http.request("GET", "https://cheese.formice.com/transformice/mouse/" .. encodeUrl(parameters))
				if head.code == 200 then
					body = string.match(body, "<b>Position</b>: (.-)<")
					if body then
						answer = translate(playerCommunity, "$rank", parameters, body)
					else
						answer = translate(playerCommunity, "$norank", parameters)
					end
				else
					answer = translate(playerCommunity, "$interr")
				end

				if isDebugging then
					return answer
				else
					tfm:sendWhisper(playerName, answer)
				end
			end
		},
		["inv"] = {
			h = "$inv",
			f = function(playerCommunity, isDebugging, playerName)
				local t = "'Fifty Shades of Lua' discord server link → discord.gg/quch83R"
				if isDebugging then
					return t
				else
					tfm:sendWhisper(playerName, t)
				end
			end
		},
		["rewards"] = {
			h = "$rewards",
			f = function(playerCommunity, isDebugging, playerName, parameters)
				if parameters and #parameters > 2 then
					parameters = string.toNickname(parameters, true)
				else
					parameters = playerName
				end

				checkAvailableRewards[parameters] = { playerName = playerName, isDebugging = isDebugging, playerCommunity = playerCommunity }
				tfm:sendCommand("profile " .. parameters)
			end
		}
	}
	serverCommand = { -- message, param
		["help"] = {
			pb = true,
			h = "Displays the available commands / the commands descriptions.",
			f = function(message, parameters)
				local isPb = (message.channel.category and message.channel.category.id ~= categoryId)
				toDelete[message.id] = message:reply((string.gsub(help((isPb and serverHelpSource or memberHelpSource), parameters, (isPb and 3 or 2), "en", '/'), '\'', '`')))
			end
		},
		["who"] = {
			h = "Displays a list of who is in the chat.",
			f = function(message)
				if message.channel.id == channel.whisper then
					toDelete[message.id] = message:reply(":warning: This is not a #channel, but the environment used to whisper players.")
				else
					tfm:chatWho(channel(message.channel.id))
				end
			end
		},
		["mod"] = {
			pb = true,
			h = "Displays the list of online Moderators.",
			f = function(message)
				modList[#modList + 1] = message
				tfm:sendCommand("mod")
			end
		},
		["mapcrew"] = {
			pb = true,
			h = "Displays the list of online Mapcrew.",
			f = function(message)
				mapcrewList[#mapcrewList + 1] = message
				tfm:sendCommand("mapcrew")
			end
		},
		["time"] = {
			h = "Displays the connection and account's time.",
			f = function(message)
				timeCmd[message.channel.id] = true
				tfm:sendCommand("time")
			end
		},
		["modules"] = {
			pb = true,
			h = "Displays the room list of official modules",
			f = function(message)
				modulesCmd[message.channel.id] = true
				tfm:requestRoomList(transfromage.enum.roomMode.module)
			end
		},
		["bolo"] = {
			auth = "585148219395276801",
			h = "Refreshes #bolodefchoco→\3*Editeur",
			f = function(message)
				message:reply("Refreshing #bolodefchoco→\3*Editeur")
				tfm:sendCommand("module bolodefchoco")
			end
		},
		["isonline"] = {
			pb = true,
			h = "Checks whether a player is online or not.",
			f = function(message, parameters)
				if not parameters then return end
				parameters = string.toNickname(parameters, true)
				tfm:sendRoomMessage(parameters .. " get_user " .. parameters)
				onlinePlayer[parameters] = message.channel.id
			end
		},
		["map"] = {
			pb = true,
			h = "Gets the image of the map specified.",
			f = function(message, parameters, _xmlOnly)
				if not parameters or not string.find(parameters, "^@%d%d%d") or string.find(parameters, "[^@%d]") then return end

				if xml[parameters] then
					toDelete[message.id] = message:reply("<@" .. message.author.id .. ">, the map **" .. parameters .. "** already is in the queue.")
					return
				end

				local len = #xml.queue + 1
				xml.queue[len] = parameters
				xml[parameters] = { message = message, _xmlOnly = _xmlOnly }

				if len == 1 then
					loadXmlQueue()
				else
					local time = 3 * (len - 1)
					xml[parameters].reply = message:reply("<@" .. message.author.id .. ">, your request is in the position #" .. len .. " and will be executed in ~" .. time .. "seconds!")
				end
			end
		},
		["xml"] = {
			auth = "462329326600192010",
			allowMember = true,
			pb = true,
			h = "Gets the XML of the map specified.",
			f = function(message, parameters)
				serverCommand["map"].f(message, parameters, true)
			end
		},
		["clear"] = {
			auth = "585148219395276801",
			h = "Clears the cache of the tables.",
			f = function(message)
				xml = { queue = { } }
				onlinePlayer = { }
				for k, v in next, srcMemberListCmd do
					v._loading = ''
					v._queue = { }
					v._timer = 0
				end
				cachedTeamListDisplay = { }
				message:reply("Cleared cache")
			end
		},
		["invth"] = {
			owner = true,
			h = "Invites Bolo to the tribe house.",
			f = function(message)
				message:reply("Inviting")
				tfm:sendCommand("inv Bolodefchoco#0000")
			end
		},
		["goto"] = {
			auth = "585148219395276801",
			h = "Changes the Bot room.",
			f = function(message, parameters)
				if not parameters then return end

				if parameters == "tribe" then
					tfm:joinTribeHouse()
					message:reply("Joined *\3Editeur!")
				else
					tfm:enterRoom(parameters)
					message:reply("Joined room **" .. parameters .. "**")
				end
			end
		},
		["moduleteam"] = c_mt,
		["fashionsquad"] = c_fs,
		["funcorp"] = c_fc,
		["tfmprofile"] = {
			pb = true,
			h = "Displays the profile of a user in real time. (User required to be online)",
			f = function(message, parameters)
				if parameters and #parameters > 2 then
					parameters = string.toNickname(parameters, true)
					profile[parameters] = message.channel.id
					tfm:sendCommand("profile " .. parameters)
				else
					toDelete[message.id] = message:reply("Invalid nickname '" .. tostring(parameters) .. "'")
				end
			end
		},
		["rank"] = {
			auth = "585148219395276801",
			h = "Updates the database of `#bolodefchoco0ranking` and `#bolodefchoco0triberanking`.",
			f = function(message, parameters)
				parameters = tonumber(parameters) or 2

				local msg = message:reply("Saving leaderboards")
				-- Updates the module #bolodefchoco.ranking
				if not hostRanking({
					uri = "mice",
					name = "ranking",
					id = 4
				}, parameters, 8, msg) then
					msg:reply("Failed to update '#ranking'")
				end

				timer.setTimeoutCoro(8000, tfm.sendCommand, tfm, "module bolodefchoco") -- resets to avoid the 1min limite

				-- Updates the module #bolodefchoco.ranking
				timer.setTimeoutCoro(12000, function(msg)
					if not hostRanking({
						uri = "tribes",
						name = "triberanking",
						id = 5
					}, parameters, 7, msg) then
						msg:reply("Failed to update '#triberanking'")
					end
				end, msg)
			end
		},
		["mem"] = {
			owner = true,
			h = "Checks the current memory usage.",
			f = function(message)
				message:reply(tostring(collectgarbage("count")))
				collectgarbage()
				message:reply(tostring(collectgarbage("count")))
			end
		},
		["sentinel"] = c_sent,
		["shelpers"] = c_sh,
		["friend"] = {
			auth = "585148219395276801",
			h = "Adds a player.",
			f = function(message, parameters)
				tfm:addFriend(string.toNickname(parameters, true))
			end
		},
		["unfriend"] = {
			auth = "585148219395276801",
			h = "Adds a player.",
			f = function(message, parameters)
				parameters = string.toNickname(parameters, true)

				friendRemoval = parameters
				tfm:removeFriend(parameters)
			end
		},
		["block"] = {
			auth = "585148219395276801",
			h = "Blacklists a player.",
			f = function(message, parameters)
				parameters = string.toNickname(parameters, true)

				tfm:blacklistPlayer(parameters)
				settingchannel.discussion:send("@here " .. parameters .. " blacklisted.")
			end
		},
		["unblock"] = {
			auth = "585148219395276801",
			h = "Whitelists a player.",
			f = function(message, parameters)
				parameters = string.toNickname(parameters, true)

				tfm:whitelistPlayer(parameters)
				settingchannel.discussion:send("@here " .. parameters .. " whitelisted.")
			end
		},
		["lua"] = {
			owner = true,
			h = "Executes lua using the bot environment.",
			f = function(message, parameters)
				-- Chunks from @Modulo
				if not parameters or #parameters < 3 then
					toDelete[message.id] = message:reply("Invalid syntax.")
					return
				end

				local foo
				foo, parameters = string.match(parameters, "`(`?`?)(.*)%1`")

				if not parameters or #parameters == 0 then
					toDelete[message.id] = message:reply("Invalid syntax.")
					return
				end

				local lua_tag, final = string.find(string.lower(parameters), "^lua\n+")
				if lua_tag then
					parameters = string.sub(parameters, final + 1)
				end

				local data = { }
				ENV.print = function(...)
					local content = printf(...)
					data[#data + 1] = (content ~= '' and content ~= ' ' and content ~= '\t' and content ~= '\n') and content or nil
				end
				ENV.message = message
				ENV.me = message.member
				ENV.channel = message.channel
				ENV.guild = message.guild

				local func, syntaxErr = load(parameters, '', 't', ENV)
				if syntaxErr then
					toDelete[message.id] = message:reply("Syntax error:\n```\n" .. tostring(syntaxErr) .. "```")
					return
				end

				local success, runtimeErr = pcall(func)
				if not success then
					toDelete[message.id] = message:reply("Runtime error:\n```\n" .. tostring(runtimeErr) .. "```")
					return
				end

				data = splitByLine(table.concat(data, "\n"))
				for line = 1, #data do
					toDelete[message.id] = message:reply({
						embed = {
							color = 0xFFAA00,
							description = data[line]
						}
					})
				end
			end
		},
		["blacklist"] = {
			h = "Displays the bot's blacklist.",
			f = function(message)
				displayBlacklist[#displayBlacklist + 1] = message
				tfm:requestBlackList()
			end
		},
		["host"] = {
			owner = true,
			h = "Hosts a module on Transformice. [#name github/rawsrc]",
			f = function(message, parameters)
				if not parameters then
					toDelete[message.id] = message:reply("Invalid syntax.")
					return
				end
				local module, source = string.match(parameters, "^#(%l+)[\n ]+(https://raw%.githubusercontent.+)$")
				if not module then
					toDelete[message.id] = message:reply("Invalid syntax.")
					return
				end

				local try, head, body = 0
				repeat
					try = try + 1
					head, body = http.request("GET", source)
				until head.code == 200 or try > 3

				if head.code ~= 200 then
					return message:reply("#" .. module .. ": Failed to retrieve data :(")
				end
				local success, syntaxErr = load(body)
				if not success then
					return message:reply("#" .. module .. ": " .. tostring(syntaxErr))
				end

				hostModule(message, module, body)
			end
		},
		["team"] = {
			owner = false,
			h = "Manages the #bolodefchoco's teams' lists.",
			f = function(message, parameters)
				if message.channel.id ~= channel.teamTool then
					toDelete[message.id] = message:reply("You can only use this command in the <#" .. channel.teamTool .. "> channel.")
					return
				end

				local action = (parameters and string.match(parameters, "^(%S+)$"))
				action = action and string.lower(action)

				if action == "save" then
					if not teamListHasBeenChanged and message.author.id ~= disc.owner.id then
						toDelete[message.id] = message:reply("Nothing has been edited in the teams' lists.")
						return
					end

					local time = os.time()
					if time < teamListFileTimer then
						toDelete[message.id] = message:reply("You can only save the teams' list once per minute. [" .. (time - teamListFileTimer) .. "].")
						return
					end

					local hasSaved = saveDatabase("teamList", teamList)
					message:reply("Saved in database: " .. tostring(hasSaved))

					if not hasSaved then
						teamListHasBeenChanged = true
						message:reply("<@" .. disc.owner.id .. "> ↑")
						return
					end

					local teamListEncoded = encodeTeamList()
					-- team{name;commu;name;commu}
					tfm.bulle:send({ 29, 21 }, transfromage.byteArray:new():write32(3):writeUTF(teamListEncoded)) -- Calls eventTextAreaCallback

					message:reply("Sending data to #bolodefchoco (" .. #teamListEncoded .. "/30000)")

					teamListHasBeenChanged = false
					teamListFileTimer = os.time() + 65
				else
					local teamName, method, names = string.match(tostring(parameters), "^(%S+)[\n ]+(...)[\n ]+(.+)")
					if not teamName then
						toDelete[message.id] = message:reply("Invalid syntax. Command syntax: `[team_name] [add] [name=community] [...]` | `[team_name] [rem] [name] [...]`")
						return
					end

					teamName = string.lower(teamName)
					if not teamList[teamName] then
						toDelete[message.id] = message:reply("Invalid syntax. Missing `teamName` (Should be `" .. table.concat(table.keys(teamList), "`, `") .. "`).")
						return
					end

					method = string.lower(method)
					local isAdd = method == "add"
					local isRem = method == "rem"

					if not (isAdd or isRem) then
						toDelete[message.id] = message:reply("Invalid syntax. Missing `method` (Should be `add`, `rem`).")
						return
					end

					if #names < 6 then
						toDelete[message.id] = message:reply("Invalid syntax. Missing `names`.")
						return
					end

					local isContinue, community = false
					names = string.split(names, "%S+")

					local validNames, counter = { }, 0

					for name = 1, #names do
						isContinue = true
						repeat
							if isRem then
								name = string.toNickname(names[name], true)

								if not teamList[teamName][name] then
									toDelete[message.id] = message:reply("The player `" .. name .. "` is not in the `" .. teamName .. "` members's list.")
									break
								end

								isContinue = false
								teamList[teamName][name] = nil

								message:reply("Player `" .. name .. "` removed from `" .. teamName .. "`.")
							else
								if string.sub(names[name], -3, -3) ~= '=' then
									toDelete[message.id] = message:reply("Invalid syntax. Player names should be followed by the community, as in `Bolo#0000=BR`.")
									break
								end

								community = string.upper(string.sub(names[name], -2))
								name = string.toNickname(string.sub(names[name], 1, -4), true)

								if not transfromage.enum.community[string.lower(community)] then
									toDelete[message.id] = message:reply("Invalid community `" .. community .. "` for the player `" .. name .. "`.")
									break
								end

								if teamList[teamName][name] then
									toDelete[message.id] = message:reply("The player `" .. name .. "` already is in the `" .. teamName .. "` members's list.")
									break
								end

								if not isPlayer(name) then
									toDelete[message.id] = message:reply("The player `" .. name .. "` could not be found.")
									break
								end

								isContinue = false
								teamList[teamName][name] = community

								message:reply("Player `" .. name .. " [" .. community .. "]` added to `" .. teamName .. "`.")
							end
						until true

						if not isContinue then
							counter = counter + 1

							if community then
								name = name .. " [" .. community .. "]"
							end

							validNames[counter] = name
						end
					end

					if counter > 0 then
						teamListHasBeenChanged = true
						cachedTeamListDisplay[teamName] = nil
						message:reply("**[Success]** " .. method .. " => `" .. table.concat(validNames, "`, `") .. "`")
					end
				end
			end
		},
		["ls"] = {
			pb = true,
			h = "Displays all members of a specific team. You can also add a flag and/or pattern in the command for filtering.",
			f = function(message, parameters)
				parameters = string.gsub(tostring(parameters), "[\n ]........", countryFlags, 1)
				parameters = string.lower(parameters)

				local teamName = tostring(string.match(parameters, "^(%S+)"))
				local commu = string.match(parameters, "[\n ]+:f?l?a?g?_?(%S+):[\n ]*")
				local pattern = string.match(parameters, "[\n ]+([^:]+)[\n ]*")

				if not teamList[teamName] then
					toDelete[message.id] = message:reply("Invalid team name. The available teams are: `" .. table.concat(table.keys(teamList), "`, `") .. "`")
					return
				end

				if not cachedTeamListDisplay[parameters] then -- uses commu and pattern, not the best solution but it's faster
					local fields, fieldCounter = { { } }, 1

					local totalCounter = 0

					commu = (commu and string.lower(commu))

					local nameCounter, formatCommu = 0
					for playerName, community in pairsByIndexes(teamList[teamName]) do
						formatCommu = countryCodeConverted[community]
						formatCommu = (formatCommu and string.lower(formatCommu))
						community = string.lower(community)

						if (not commu or commu == community or commu == formatCommu) and (not pattern or string.find(string.lower(playerName), pattern)) then
							nameCounter = nameCounter + 1

							totalCounter = totalCounter + 1
							fields[fieldCounter][nameCounter] = ":flag_" .. (formatCommu or community) .. ": " .. " " .. playerName

							if nameCounter == 26 then
								nameCounter = 0
								fieldCounter = fieldCounter + 1
								fields[fieldCounter] = { }
							end
						end
					end

					if totalCounter == 0 then
						fieldCounter = 1
						fields[1][1] = "N/A"
					end

					for i = 1, fieldCounter do
						if #fields[i] == 0 then break end
						fields[i] = {
							name = '‌',
							value = string.gsub(remDefaultDiscriminator(table.concat(fields[i], "\n"), true), "#%d+", "`%1`"),
							inline = true
						}
					end

					cachedTeamListDisplay[parameters] = { }
					local abvAction = teamListAbbreviated[teamName]
					local title = (string.gsub(abvAction, "%u", " %1") .. " [" .. totalCounter .. "]")
					local description = (commu or '') .. "; " .. (pattern or '')
					description = (description ~= "; " and description or nil)

					local counter = 0
					for i = 1, fieldCounter, 6 do
						counter = counter + 1
						cachedTeamListDisplay[parameters][counter] = {
							embed = {
								color = roleColors[abvAction],
								title = (counter == 1 and title or nil),
								description = (counter == 1 and description or nil),
								fields = table.arrayRange(fields, i, i + 5)
							}
						}
					end
				end

				local messages = { }
				for i = 1, #cachedTeamListDisplay[parameters] do
					messages[i] = message:reply(cachedTeamListDisplay[parameters][i])
				end
				toDelete[message.id] = messages
			end
		},
		["fix"] = {
			auth = "585148219395276801",
			h = "Fixes tribe house.",
			f = function(message, parameters)
				serverCommand["goto"](message, "hell")
				timer.setTimeoutCoro(4000, serverCommand["goto"].f, message, "tribe")
				timer.setTimeoutCoro(4000 + 2500, serverCommand["clear"].f, message)
				timer.setTimeoutCoro(4000 + 2500 + 500, serverCommand["bolo"].f, message, tribe)
				timer.setTimeoutCoro(4000 + 2500 + 500 + 500, message.reply, message, "Checking fix:")
				timer.setTimeoutCoro(4000 + 2500 + 500 + 500 + 2500, serverCommand["moduleteam"].f, message)
				timer.setTimeoutCoro(4000 + 2500 + 500 + 500 + 2500 + 2500, serverCommand["clear"].f, message)
			end
		},
	}
end

chatHelpSource = table.fuse(table.keys(chatCommand), table.keys(commandWrapper))
whisperHelpSource = table.fuse(table.keys(whisperCommand), table.keys(commandWrapper))
memberHelpSource = table.keys(serverCommand)
serverHelpSource = table.keys(serverCommand, function(k, v) return v.pb end)
table.sort(chatHelpSource)
table.sort(whisperHelpSource)
table.sort(memberHelpSource)
table.sort(serverHelpSource)
do
	local setMeta = function(src)
		for k, v in next, src do
			if type(v) == "table" then
				v = setmetatable(v, {
					__call = function(this, ...)
						return this.f(...)
					end,
					__tostring = function(this)
						return this.h
					end
				})
			end
		end
	end

	setMeta(commandWrapper)
	setMeta(chatCommand)
	setMeta(whisperCommand)
	setMeta(serverCommand)
end

local getCommandParameters = function(message, prefix)
	if #message < 2 then return end
	local command, parameters = string.match(message, "^" .. (prefix or ",?") .. "(%S+)[\n ]*(.*)")
	parameters = (parameters ~= '' and parameters or nil)
	return (command and string.lower(command)), parameters
end

local userAntiSpam = function(src, playerName, playerCommunity)
	if src.link then
		local time = os.time()
		if (userCache[playerName] and userCache[playerName] > time) then
			return translate(playerCommunity, "$spam", playerName)
		else
			userCache[playerName] = time + ANTI_SPAM_TIME
		end
	end
end

local executeCommand = function(isChatCommand, content, target, playerName, isDebugging, playerCommunity)
	local returnValue, countByByte
	local cmd, param = getCommandParameters(content)

	if param == '?' then
		param = cmd
		cmd = "help"
	end

	if commandWrapper[cmd] then
		returnValue = userAntiSpam(commandWrapper[cmd], target, playerCommunity)
		if not returnValue then -- if because "a, b = c() or d()" doesn't apply for multiple values. :s
			returnValue, countByByte = commandWrapper[cmd](playerCommunity, param, target, isChatCommand)
		end
		if returnValue then
			if isChatCommand or isDebugging then
				tfm:sendChatMessage(target, returnValue, nil, countByByte)
			else
				tfm:sendWhisper(target, returnValue, nil, countByByte)
			end
		end
		return true
	else
		if isChatCommand then
			if chatCommand[cmd] then
				returnValue = userAntiSpam(chatCommand[cmd], playerName, playerCommunity)
				if not returnValue then
					returnValue, countByByte = chatCommand[cmd](playerCommunity, target, playerName, param)
				end
				if returnValue then
					tfm:sendChatMessage(target, returnValue, nil, countByByte)
				end
				return true
			end
		else
			if whisperCommand[cmd] then
				returnValue = userAntiSpam(whisperCommand[cmd], playerName, playerCommunity)
				if not returnValue then
					if whisperCommand[cmd].maintenance then
						returnValue = translate(playerCommunity, "$maintenance")
					else
						returnValue, countByByte = whisperCommand[cmd](playerCommunity, isDebugging, playerName, param)
					end
				end
				if returnValue then
					if isDebugging then
						tfm:sendChatMessage(target, returnValue, nil, countByByte)
					else
						tfm:sendWhisper(target, returnValue, nil, countByByte)
					end
				end
				return true
			end
		end
	end
	return false
end

-- Discord emitters
disc:once("ready", function()
	for k, v in pairs(channel) do -- __pairs
		object[k] = disc:getChannel(v)
	end
	for k, v in next, settingchannel do
		settingchannel[k] = disc:getChannel(v)
	end

	for member in settingchannel.memberList:getMessages():iter() do
		setHelper(member.content)
	end

	disc:setGame("Prefix /")

	timer.setTimeout(25 * 1000, function()
		if isConnected then return end
		return error("[Heartbeat] Failed to connect.", transfromage.enum.errorLevel.high)
	end)
	tfm:emit("connectionFailed")
end)

disc:on("messageCreate", protect(function(message)
	if not isWorking then return end
	if message.author.bot then
		if (message.author and message.embed and message.embed.author and message.embed.description)
			and message.author.id == githubWebhook.id
			and message.channel.id == channel.shadestest and message.embed.type == githubWebhook.embedType
			and (message.embed.author.name == githubWebhook.name or message.embed.author.name == githubWebhook.actionName)
		then
			local module = string.match(message.embed.title, "^%[(.-):")
			if not module then return end

			local isBolodefchoco = (module == "bolodefchoco")
			local hasHost = string.find(message.embed.description, "[host]", 1, true)

			if message.embed.author.name == githubWebhook.actionName then
				if not githubWebhook.waitingAction then return end
			elseif isBolodefchoco then -- is not action, is bolo
				githubWebhook.waitingAction = not not (hasHost and string.find(message.embed.description, "[build]", 1, true))
				return
			end

			if hasHost or githubWebhook.waitingAction then
				local url = "https://raw.githubusercontent.com/a801-luadev/" .. module .. "/master/"
				if isBolodefchoco then -- Has builds
					url = url .. "builds/" .. os.date("%d_%m_%y") .. ".lua"
				else
					url = url .. "module.lua"
				end

				local parameters = "#" .. module .. " " .. url

				message:reply("/host " .. parameters)
				serverCommand["host"](message, parameters)
			end
		end
		return
	end

	if message.channel.id == settingchannel.memberList.id then
		return setHelper(message.content)
	end

	local isMember = channel(message.channel.id) and helper[message.author.id]

	local cmd, param = getCommandParameters(message.content, '/')
	if cmd then
		if param == '?' then
			param = cmd
			cmd = "help"
		end

		if serverCommand[cmd] then
			if serverCommand[cmd].pb or isMember then
				if message.author.id ~= disc.owner.id then
					if serverCommand[cmd].owner then
						toDelete[message.id] = message:reply("<@" .. message.author.id .. ">, you must be the bot owner in order to use this command!")
						return
					end
					if serverCommand[cmd].auth and not (serverCommand[cmd].allowMember and isMember) then
						if not message.member:hasRole(serverCommand[cmd].auth) then
							toDelete[message.id] = message:reply("<@" .. message.author.id .. ">, you must have the role <@&" .. serverCommand[cmd].auth .. "> in order to use this command!")
							return
						end
					end
				end

				return serverCommand[cmd](message, param)
			end
		end
	end

	if not isMember then return end

	local content = message.content
	if not string.find(content, "^,") then return end
	if message.attachment and message.attachment.url then
		content = content .. " " .. message.attachment.url
	end

	local cutSlice
	if (channel.whisper == message.channel.id) then -- on whisper
		local target, msgContent = string.match(content, "^,(.-) +(.+)")

		if target == 'r' then
			if not lastUserReply then
				toDelete[message.id] = message:reply({
					content = "<@" .. message.author.id .. ">, there's no `last_user_reply` definition yet.",
					embed = {
						color = 0xFFAA00,
						description = "Use `,target message` or `,r message` (← last_user_reply)"
					}
				})
				return
			else
				target = lastUserReply
			end
		else
			target = string.toNickname(target)
		end

		cutSlice = tfm:sendWhisper(target, formatSendText(msgContent), helper[message.author.id])
	else
		if message.channel.id == channel.shadestest then
			-- Whisper comes first because of ',help'
			local executed = executeCommand(false, content, channel(message.channel.id), helper[message.author.id], true)
			executed = executed or executeCommand(true, content, channel(message.channel.id), helper[message.author.id])
			if executed then return end
		end

		cutSlice = tfm:sendChatMessage(channel(message.channel.id), formatSendText(string.sub(content, 2)), helper[message.author.id])
	end
	if cutSlice then
		message:reply({
			content = "<@" .. message.author.id .. ">, the part of the message written below was not sent due to message size limits.",
			embed = {
				color = 0xFFAA00,
				description = cutSlice
			}
		})
	end
end))

disc:on("messageDelete", protect(function(message)
	if message.channel.id == settingchannel.memberList.id then
		return remHelper(message.content)
	elseif toDelete[message.id] then
		local msg
		for id = 1, #toDelete[message.id] do
			msg = message.channel:getMessage(toDelete[message.id][id])
			if msg then
				msg:delete()
			end
		end

		toDelete[message.id] = nil
	end
end))

disc:on("messageUpdate", protect(function(message)
	if message.channel.id == settingchannel.memberList.id then
		remHelper(message.content)
		setHelper(message.content)
	elseif toDelete[message.id] then
		disc:emit("messageDelete", message)
		disc:emit("messageCreate", message)
	end
end))

-- Transformice emitters
tfm:on("ready", protect(function()
	print("Connecting")
	tfm:connect(DATA[1], DATA[2])
end))

tfm:once("heartbeat", protect(function()
	isConnected = true
end))

tfm:on("ping", protect(function()
	if lastServerPing then
		timer.clearTimeout(lastServerPing)
	end
	lastServerPing = timer.setTimeout(25 * 1000, error, "[Ping] Lost connection.", transfromage.enum.errorLevel.high)
end))

tfm:on("connectionFailed", protect(function()
	tfm:start(DATA[3], DATA[4])
end))

tfm:on("disconnection", protect(function(connection)
	if tfm._isConnected and connection.name == "main" then
		tfm._isConnected = false
		error("[Connection] Disconnected from main.", transfromage.enum.errorLevel.high)
	end
end))

tfm:once("connection", protect(function()
	error("Connected to the game with port " .. transfromage.enum.setting.port[tfm.main.port], transfromage.enum.errorLevel.low)

	DATA[2] = nil

	print("Joining Tribe House")
	tfm:joinTribeHouse()

	print("Opening channels")
	for chat in pairs(channel) do
		if chat ~= "whisper" and chat ~= "teamTool" then
			tfm:joinChat(chat)
		end
	end

	repeat
		print("Getting team list")
		teamList = getDatabase("teamList")
	until teamList
	ENV.teamList = teamList

	modTracker.init()
end))

tfm:once("joinTribeHouse", protect(function()
	print("Joined Tribe House")
	print("Loading module")
	tfm:sendCommand("module bolodefchoco")
	timer.setInterval(60 * 60 * 1000 * 2, function()
		print("Reloading module")
		tfm:sendCommand("module bolodefchoco")
	end)

	timer.setTimeout(2500, function() -- Loading #bolodefchoco.*\3Editeur data.
		isWorking = true
		print("Working")
	end)
end))

tfm:on("chatMessage", protect(function(channelName, playerName, message, playerCommunity)
	if not channel[channelName] then return end
	if channelName == "whisper" then return end -- :P
	p(channelName, playerName, message, playerCommunity)

	playerName = string.toNickname(playerName)

	playerCommunity = getCommunityCode(playerCommunity)
	local content = string.format("[%s] [%s] [%s] %s", os.date("%H:%M"), playerCommunity, playerName, message)
	content = formatReceiveText(content)

	object[channelName]:send(content)

	executeCommand(true, message, channelName, playerName, nil, playerCommunity)
end))

tfm:on("whisperMessage", protect(function(playerName, message, playerCommunity)
	p(playerName, message, playerCommunity)

	playerName = string.toNickname(playerName)

	local isBot = playerName == DATA[1]
	if not isBot then
		lastUserReply = playerName
	end

	playerCommunity = getCommunityCode(playerCommunity)
	local content = string.format("%s [%s] [%s] [%s%s] %s", (isBot and '<' or '>'), os.date("%H:%M"), playerCommunity, playerName, ((isBot and lastUserWhispered) and (" → " .. lastUserWhispered) or ''), message)
	content = formatReceiveText(content)

	object.whisper:send(content)

	executeCommand(false, message, playerName, playerName, nil, playerCommunity)
end))

tfm:on("profileLoaded", protect(function(data)
	if dressroom[data.playerName] then
		local look = translate(dressroom[data.playerName].playerCommunity, "$outfit", data.playerName, dressroomLink(data.look))

		if dressroom[data.playerName].isDebugging then
			object.shadestest:send(formatReceiveText(look))
		else
			tfm:sendWhisper(dressroom[data.playerName].playerName, look)
		end

		dressroom[data.playerName] = nil
	elseif profile[data.playerName] then
		local title = getTitle(data.titleId, data.gender)

		disc:getChannel(profile[data.playerName]):send((profile[data.playerName] == miscChannel.transfromage_tokens and ("<:wheel:456198795768889344> **" .. data.playerName .. "'s ID :** " .. data.id) or ({
			embed = {
				color = 0x2E565F,
				title = "<:tfm_cheese:458404666926039053> Transformice Profile - " .. data.playerName .. (data.gender == 2 and " <:male:456193580155928588>" or data.gender == 1 and " <:female:456193579308679169>" or ''),
				description =
					(data.role > 0 and ("**Role :** " .. string.gsub(transfromage.enum.role(data.role), "%a", string.upper, 1) .. "\n\n") or '') ..

					((data.soulmate and data.soulmate ~= '') and (":revolving_hearts: **" .. data.soulmate .. "**\n") or '') ..
					":calendar: " .. os.date("%d/%m/%Y", data.registrationDate) ..
					((data.tribeName and data.tribeName ~= '') and ("\n<:tribe:458407729736974357> **Tribe :** " .. data.tribeName) or '') ..

					"\n\n**Level " .. data.level .. "**" ..
					"\n**Current Title :** «" .. title .. "»" ..
					"\n**Adventure points :** " .. data.adventurePoints ..

					"\n\n<:shaman:512015935989612544> " .. data.saves.normal .. " / " .. data.saves.hard .. " / " .. data.saves.divine ..
					"\n<:tfm_cheese:458404666926039053> **Shaman cheese :** " .. data.shamanCheese ..

					"\n\n<:racing:512016668038266890> **Firsts :** " .. data.firsts ..
					"\n<:tfm_cheese:458404666926039053> **Cheeses :** " .. data.cheeses ..
					"\n<:bootcamp:512017071031451654> **Bootcamps :** " .. data.bootcamps ..

					"\n\n<:dance:468937918115741718> **[Outfit](" .. dressroomLink(data.look) .. ")**\n\n" ..

					"<:wheel:456198795768889344> **Total titles :** " .. data.totalTitles ..
					"\n<:wheel:456198795768889344> **Total badges :** " .. data.totalBadges ..
					"\n<:wheel:456198795768889344> **Total cartouches :** " .. data.totalOrbs ..

					"\n\n<:wheel:456198795768889344> **ID :** " .. data.id
				,
				thumbnail = { url = "http://avatars.atelier801.com/" .. (data.id % 10000) .. "/" .. data.id .. ".jpg" }
			}
		})))
		profile[data.playerName] = nil
	elseif checkTitles[data.playerName] then
		local gender = (data.gender % 2 + 1)

		local commu = checkTitles[data.playerName].playerCommunity
		if not translate[commu] then
			commu = "en"
		end

		data.savesNormal, data.savesHard, data.savesDivine = data.saves.normal, data.saves.hard, data.saves.divine -- comp

		local out, counter = { }, 0
		local title, field, stars, skip
		for f = 1, #titleFields do
			field = titleFields[f]

			skip = false
			stars = ''
			if field == "bootcamps" and data[field] < 9001 then -- Handle stars
				local totalStars = ((data[field] - 1) / 1000)
				if totalStars >= 1 then
					stars = " " .. string.rep('★', totalStars)
					data[field] = data[field] % 1000
				end
			elseif (field == "savesHard" and data.savesNormal < 1000) or (field == "savesDivine" and data.savesHard < 2000) then
				skip = true
			end

			if not skip then
				local missing
				for i = 1, #titleRequirements[field] do
					if data[field] < titleRequirements[field][i][2] then
						title = getTitle(titleRequirements[field][i][1], gender, commu, true)
						missing = (titleRequirements[field][i][2] - data[field])

						counter = counter + 1
						out[counter] = translate(commu, titleFieldsKeys[f], (missing > 1 and 's' or ''))
						out[counter] = translate(commu, "$checktitle", missing, out[counter], title .. stars)
						break
					end
				end
			end
		end

		if #out == 0 then
			out = translate(commu, "$notitle")
		else
			out = table.concat(out, ", ")
		end
		out = "'" .. data.playerName .. "': " .. out

		if checkTitles[data.playerName].isDebugging then
			object.shadestest:send(formatReceiveText(out))
		else
			tfm:sendWhisper(checkTitles[data.playerName].playerName, out)
		end

		checkTitles[data.playerName] = nil
	elseif checkAvailableRewards[data.playerName] then
		-- Avoid json arrays
		data.badges._ignore = true
		data.orbs._ignore = true

		local rewards = {
			success = true,
			nickname = data.playerName,
			badges = data.badges,
			orbs = data.orbs
		}

		local titles, counter = { }, 0

		local title, hasGender
		for t = 0, 600 do -- Cannot know how many titles there are
			if not unavailableTitles[t] and not data.titles[t] then
				title = getTitle(t, data.gender)
				if title ~= t then
					counter = counter + 1
					titles[counter] = title
				end
			end
		end
		rewards.titles = titles
		rewards = json.encode(rewards)
		rewards = string.gsub(rewards, "\\", '') -- Some titles use it

		local playerData
		local code = string.match(os.tmpname(), "(%w+)$")

		local saved = saveDatabase(code .. "&folder=bottmp", rewards, true)
		if not saved then
			playerData = translate(checkAvailableRewards[data.playerName].playerCommunity, "$norewards")
		else
			playerData = translate(checkAvailableRewards[data.playerName].playerCommunity, "$rewardscode", code)
		end

		if checkAvailableRewards[data.playerName].isDebugging then
			object.shadestest:send(playerData)
		else
			tfm:sendWhisper(checkAvailableRewards[data.playerName].playerName, playerData)
		end

		checkAvailableRewards[data.playerName] = nil
	end
end))

tfm:insertPacketListener(6, 9, protect(function(self, packet, connection, C_CC) -- Chat message from #bolodefchoco.*\3Editeur
	local text = packet:readUTF()

	if string.find(text, "[shades_id]", 1, true) then
		object.shadestest:send("<@" .. disc.owner.id .. ">\n" .. text)
		return
	end

	local team, missing, content = string.match(text, "^(%S+) (%d) (.+)")
	missing = tonumber(missing)

	if team then
		if onlinePlayer[team] then
			local isOnline = json.decode(content).isOnline
			disc:getChannel(onlinePlayer[team]):send((isOnline and "<:online:456197711356755980>" or "<:offline:456197711457419276>") .. team .. " is " .. (isOnline and "on" or "off") .. "line!")
			onlinePlayer[team] = nil
			return
		end

		local l = srcMemberListCmd[team]
		if not l then return end

		l._loading = l._loading .. content

		if missing == 0 then
			local _team = team
			team = string.gsub(team, "%u", " %1")

			local commu, counter, commuList = { }, 0, { }
			for k, v in next, json.decode(l._loading).members do
				k = remDefaultDiscriminator(k)

				-- Adds each name to its respective community
				if not commuList[v] then
					counter = counter + 1
					commuList[v] = counter
					commu[commuList[v]] = { commu = v, list = { }, counter = 0 }
				end
				commu[commuList[v]].counter = commu[commuList[v]].counter + 1
				commu[commuList[v]].list[commu[commuList[v]].counter] = k
			end

			if counter > 0 then
				table.sort(commu, function(commu1, commu2)
					return commu1.commu < commu2.commu
				end)
				for i = 1, counter do
					table.sort(commu[i].list)
					commu[i] = "[" .. commu[i].commu .. "] " .. table.concat(commu[i].list, ", ")
				end

				l._onlineMembers.state = 1 -- Online
				l._onlineMembers.data = table.concat(commu, " | ") -- Data is sent together (text%data) because of %u→ %l
			else
				l._onlineMembers.state = 0 -- Offline
				l._onlineMembers.data = ''
			end
			l._onlineMembers.team = team
			l._loading = ''

			for i = 1, #l._queue do
				if l._queue[i].isDebugging then
					if l._queue[i].isServerCmd then
						l._queue[i].isDebugging:reply(formatServerMemberList(l._onlineMembers(), _team, l._queue[i].isDebugging.author.fullname))
					else
						object.shadestest:send(formatReceiveText(l._onlineMembers()))
					end
				else
					tfm:sendWhisper(l._queue[i].playerName, l._onlineMembers(l._queue[i].language))
				end
			end
			l._queue = { }
		end
		l._timer = os.time() + 60
	end
end))

tfm:on("chatWho", protect(function(chatName, data)
	if not chatName then return end

	local data = "**#" .. chatName .. "** : " .. #data .. "\n" .. table.concat(table.mapArray(data, function(user)
		return "`" .. user .. "`"
	end), ", ")

	for i = 0, #data, 2000 do
		object[chatName]:send(string.sub(data, i + 1, i + 2000))
	end
end))

tfm:on("staffList", protect(function(list)
	local isMod = false
	local hasOnline = true
	local title

	list = string.gsub(list, "%$(%S+)", function(line)
		if line == "ModoEnLigne" then
			isMod = true
			title = "Online Moderators"
		elseif line == "ModoPasEnLigne" then
			isMod = true
			hasOnline = false
			title = "No Moderators online :("
		elseif line == "MapcrewEnLigne" then
			title = "Online Mapcrew"
		elseif line == "MapcrewPasEnLigne" then
			hasOnline = false
			title = "No Mapcrew online :("
		else
			title = line
		end
		return ''
	end, 1)

	if hasOnline then
		if isMod and modTracker.requested then
			modTracker.receive(list)
		end

		list = string.gsub(list, "<.->", '')

		list = string.gsub(list, "%[..%]", function(commu)
			return "`" .. string.upper(commu) .. "`"
		end)

		list = string.gsub(list, "#%d+", "`%1`")
	end

	local embed = {
		embed = {
			color = roleColors[(isMod and "Moderator" or "Mapcrew")],
			title = tostring(title),
			description = list,
			footer = {

			}
		}
	}

	local listSrc = (isMod and modList or mapcrewList)
	for i = 1, #listSrc do
		embed.embed.footer.text = "Requested by " .. listSrc[i].author.fullname
		listSrc[i]:reply(embed)
	end

	if isMod then
		modList = { }
	else
		mapcrewList = { }
	end
end))

tfm:on("time", protect(function(time)
	local r = string.format("**Connection time:** %s\n**Account time:** %d days, %d hours, %d minutes, and %d seconds.", secToDate(tfm:connectionTime()), time.day, time.hour, time.minute, time.second)

	for channel in next, timeCmd do
		disc:getChannel(channel):send(r)
	end

	timeCmd = { }
end))

tfm:on("roomList", protect(function(roomMode, rooms, pinned)
	if roomMode ~= transfromage.enum.roomMode.module then return end

	local totalModules, f = #pinned
	local halfModules = math.ceil(totalModules / 2)

	table.sort(pinned, function(m1, m2) return m1.totalPlayers > m2.totalPlayers end)

	local fields = { { }, { } }
	for i = 1, totalModules do
		f = (i <= halfModules and 1 or 2)
		fields[f][#fields[f] + 1] = "**" .. pinned[i].name .. "**\t`" .. pinned[i].totalPlayers .. "`"
	end

	local message = {
		embed = {
			color = 0x36393F,
			title = "Total modules: **" .. totalModules .. "**",
			fields = {
				[1] = {
					name = '‌',
					value = table.concat(fields[1], '\n'),
					inline = true
				},
				[2] = {
					name = '‌',
					value = table.concat(fields[2], '\n'),
					inline = true
				}
			}
		}
	}

	for channel in next, modulesCmd do
		disc:getChannel(channel):send(message)
	end
	modulesCmd = { }
end))

tfm:on("newGame", protect(function(map)
	map.code = "@" .. map.code
	if map.xml and map.xml ~= '' and map.code and xml[map.code] then
		timer.clearTimeout(xml[map.code].timer)

		if #map.xml <= 23000 then
			local head, body
			if xml[map.code]._xmlOnly then
				local m = xml[map.code].message:reply({
					content = "<@" .. xml[map.code].message.author.id .. ">, the XML of the map is in the attached file.",
					file = { map.code .. ".xml", map.xml }
				})
				timer.setTimeout(20000, m.delete, m)
			else
				head, body = http.request("POST", "https://xml-drawer.herokuapp.com/", specialHeaders.urlencoded, "xml=" .. encodeUrl(map.xml))

				if head.code == 200 then
					local tmp = string.match(os.tmpname(), "([^/]+)$") .. ".png" -- Match needed so it doesn't glitch 'attachment://'
					local file = io.open(tmp, 'w')
					file:write(body)
					file:flush()
					file:close()

					local perm = (mapCategory[map.perm] or mapCategory.default)
					xml[map.code].message:reply({
						content = "<@" .. xml[map.code].message.author.id .. ">",
						embed = {
							color = perm[2],
							description = (perm[3] and ("`[" .. perm[3] .. "]` ") or '') .. perm[1] .. " - **P" .. map.perm .. "**\n" .. map.code .. " - **" .. remDefaultDiscriminator(map.author) .. "**",
							image = { url = "attachment://" .. tmp }
						},
						file = tmp
					})

					os.remove(tmp)
				else
					xml[map.code].message:reply({
						content = "<@" .. xml[map.code].message.author.id .. ">",
						embed = {
							color = 0x36393F,
							title = "Fail",
							description = "Internal error :( Try again later",
							fields = {
								[1] = {
								name = "Head code",
									value = tostring(head and head.code),
									inline = true
								},
								[2] = {
									name = "Body",
									value = tostring(body and string.sub(body, 1, 500)),
									inline = true
								},
							}
						}
					})
				end
			end
		else
			xml[map.code].message:reply({
				content = "<@" .. xml[map.code].message.author.id .. ">",
				embed = {
					color = 0x36393F,
					title = "Fail",
					description = "The map XML size is too big :( (" .. math.ceil(#map.xml / 1000) .. "kb)"
				}
			})
		end

		if xml[map.code].reply then
			xml[map.code].reply:delete()
		end

		table.remove(xml.queue, 1)
		xml[map.code] = nil

		timer.setTimeoutCoro(1000, loadXmlQueue)
	end
end))

tfm:on("newFriend", protect(function(friend)
	settingchannel.discussion:send("@here " .. friend.playerName .. " has been added to the friendlist.")
end))

tfm:on("removeFriend", protect(function(playerId)
	settingchannel.discussion:send("@here " .. tostring(friendRemoval) .. " (" .. playerId .. ") has been removed from the friendlist.")
	friendRemoval = nil
end))

tfm:on("blackList", protect(function(blacklist)
	local len = #blacklist
	local embed = {
		embed = {
			color = 0,
			description = "Total blacklisted players: **" .. len .. "**\n\n" .. (len > 0 and (":skull: **" .. table.concat(blacklist, "**\n:skull: **")) or "**None") .. "**"
		}
	}

	for i = 1, #displayBlacklist do
		embed.embed.timestamp = displayBlacklist[i].timestamp
		displayBlacklist[i]:reply(embed)
	end
	displayBlacklist = { }
end))

-- Initialize
tfm:setCommunity(transfromage.enum.community.sk)
disc:run(DATA[5])
DATA[5] = nil

-- Env
ENV = setmetatable({
	bit32 = bit,
	CHAR_LIM = CHAR_LIM,
	CHAT_MSG_LIM = CHAT_MSG_LIM,
	WHISPER_MSG_LIM = WHISPER_MSG_LIM,
	ANTI_SPAM_TIME = ANTI_SPAM_TIME,
	timer = timer,
	http = http,
	json = json,
	discordia = discordia,
	transfromage = transfromage,
	disc = disc,
	tfm = tfm,
	object = object,
	channels = channel,
	settingchannel = settingchannel,
	miscChannel = miscChannel,
	categoryId = categoryId,
	helper = helper,
	hostRanking = hostRanking,
	isConnected = isConnected,
	isWorking = isWorking,
	dressroom = dressroom,
	onlinePlayer = onlinePlayer,
	timeCmd = timeCmd,
	modulesCmd = modulesCmd,
	xml = xml,
	userCache = userCache,
	profile = profile,
	checkTitles = checkTitles,
	displayBlacklist = displayBlacklist,
	mapCategory = mapCategory,
	roleColors = roleColors,
	titleRequirements = titleRequirements,
	titleFields = titleFields,
	titleFieldsKeys = titleFieldsKeys,
	translate = translate,
	toDelete = toDelete,
	protect = protect,
	removeSpaces = removeSpaces,
	formatReceiveText = formatReceiveText,
	formatSendText = formatSendText,
	formatServerMemberList = formatServerMemberList,
	splitMsgByWord = splitMsgByWord,
	encodeUrl = encodeUrl,
	srcMemberListCmd = srcMemberListCmd,
	createListCommand = createListCommand,
	getCommunityCode = getCommunityCode,
	splitByLine = splitByLine,
	printf = print,
	secToDate = secToDate,
	remDefaultDiscriminator = remDefaultDiscriminator,
	getCommandParameters = getCommandParameters,
	userAntiSpam = userAntiSpam,
	executeCommand = executeCommand,
	setHelper = setHelper,
	remHelper = remHelper,
	dressroomLink = dressroomLink,
	loadXmlQueue = loadXmlQueue,
	chatHelpSource = chatHelpSource,
	whisperHelpSource = whisperHelpSource,
	memberHelpSource = memberHelpSource,
	commandWrapper = commandWrapper,
	chatCommand = chatCommand,
	whisperCommand = whisperCommand,
	serverCommand = serverCommand,
	specialHeaders = specialHeaders,
	teamList = teamList,
	teamListAbbreviated = teamListAbbreviated,
	countryCodeConverted = countryCodeConverted,
	cachedTeamListDisplay = cachedTeamListDisplay,
	teamListHasBeenChanged = function()
		return teamListHasBeenChanged
	end,
	teamListFileTimer = function()
		return teamListFileTimer
	end,
	getDatabase = getDatabase,
	saveDatabase = saveDatabase,
	githubWebhook = githubWebhook,
	hostModule = hostModule,
	unavailableTitles = unavailableTitles,
	modTracker = modTracker,
	pairsByIndexes = pairsByIndexes,
	countryFlags = countryFlags,
	isPlayer = isPlayer
}, {
	__index = _G
})