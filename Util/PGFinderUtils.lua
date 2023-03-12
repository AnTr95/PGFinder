local addon = ...
local L = PGFinderLocals

--[[
	Finds an index in a table that is not used
	param(arr) table / Table that needs to get empty indexes
]]
function PGF_FirstEmptyIndex(arr)
	local size = PGF_GetSize(arr)
	for i = 1, size+1 do
		if arr[i] == nil then
			return i
		end
	end
	return size
end
--[[
	Prints the containings of a table
	param(arr) table / Values to print
	param(str) string / Information about the values held by arr
]]
function PGF_ToString(arr)
	local i = 0
	local sb = ""
	for k, v in pairs(arr) do
		i = i + 1
		sb = sb .. i .. ". " .. v .. "\n"
	end
	return sb
end

function PGF_IsBlacklisted(name, leader, age)
	local server = nil
	if name ~= nil then
		name = string.lower(name)
	end
	if leader ~= nil then
		leader = string.lower(leader)
		server = leader:match("%-(.*)")
	end
	if leader ~= nil and PGF_Contains(PGF_blacklist.Players, leader) then
		PGF_BlacklistLeader(name, leader, age)
		return true
	elseif server ~= nil and PGF_Contains(PGF_blacklist.Servers, server) then
		return true
	elseif PGF_IsMatch2(name, PGF_blacklist.Keywords) then
		return true
	end
	return false
end

function PGF_IsWithinReasonableTime(time1, time2, diff)
	if time1 == time2 or (time1 >= (time2-diff) and time1 <= (time2+diff)) then
		return true
	end
	return false
end

function PGF_HasBeenSignedUpBefore(prevGroups, resultID)
	local searchResults = C_LFGList.GetSearchResultInfo(resultID);
	local name = searchResults.name;
	local leaderName = searchResults.leaderName;
	local age = searchResults.age;
	if name ~= nil then
		name = string.lower(name) -- CASE INSENSITIVE
	end
	if leaderName ~= nil then
		leaderName = string.lower(leaderName)
	end
	local time = time() - age
	for k, v in pairs(prevGroups) do
		if prevGroups[k].Name == name and (prevGroups[k].Leader == leaderName or PGF_IsWithinReasonableTime(prevGroups[k].Age, time, 2)) then
			return k
		end
	end
	return false
end

function PGF_IsMatch2(name, keywords)
	local match = false
	for i = 1, PGF_GetSize(keywords) do
		local keyword = keywords[i]
		local matchedName = name
		local splitKeyword = PGF_Split(keywords[i])
		for j = 1, PGF_GetSize(splitKeyword) do
			local s = matchedName:match(splitKeyword[j].."(.*)")
			if not s or s == nil then
				match = false
				break
			end
			match = true
		end
		if match then
			return true
		end
	end
	return false
end

function PGF_IsMatch3(name, keywords)
	local match = false
	name = string.lower(name)
	for index, keyword in pairs(keywords) do
		local matchedName = name
		local splitKeyword = PGF_Split(keyword)
		for i = 1, PGF_GetSize(splitKeyword) do
			local s = matchedName:match(splitKeyword[i].."(.*)")
			if not s or s == nil then
				match = false
				break
			end
			match = true
		end
		if match then
			return index
		end
	end
	return false
end

--[[
	Checking if a table PGF_Contains a given value and if it does, what index is the value located at
	param(arr) table
	param(value) T - value to check exists
	return boolean or integer / returns false if the table does not contain the value otherwise it returns the index of where the value is locatedd
]]
function PGF_Contains(arr, value)
	if value == nil then
		return false
	end
	if arr == nil then
		return false
	end
	for k, v in pairs(arr) do
		if v == value then
			return k
		end
	end
	return false
end
--[[
	Returns the size of a table
	param(arr) table
	returns integer / The size of the table
]]
function PGF_GetSize(arr)
	local count = 0
	for k, v in pairs(arr) do
		count = count + 1
	end
	return count
end
--[[
	Sends notifications to chosen online PGF_friends that a group containing a given keyword has been created through whispers and battle net
	param(name) string / Name of the friend to notified
	NEW:
	bnetIDAccount = select(17, BNGetGameAccountInfo(bnetIDGameAccount));
	You can find a player’s active bnetIDGameAccount from a bnetIDAccount as follows:
	bnetIDGameAccount = select(6, BNGetFriendInfoByID(bnetIDAccount));
	OLD:
	BNGetFriendInfoByID(pID)
	pID = GetAutoCompletePresenceID(BNName)
	local nameStart, nameEnd = name:find("#")
	local BNName = name:sub(0, nameEnd-1)
	name = Ant(#2336)
]]
function PGF_PMFriend(name, groupName)
	if name:find("#") and BNConnected() then
		local nameStart, nameEnd = name:find("#")
		local BNName = name:sub(0, nameEnd-1)
		local pID = GetAutoCompletePresenceID(BNName)
		local presenceID, presenceName, battleTag, isBattleTagPresence, toonName, toonID, client, isOnline, lastOnline, isAFK, isDND, messageText, noteText, isRIDFriend, broadcastTime, canSoR = BNGetFriendInfoByID(pID)
		if isOnline then
			--BNSendWhisper(presenceID, L.NOTIFICATION_FRIENDS_1 .. playerName .. L.NOTIFICATION_FRIENDS_2 .. groupName)
		end
	elseif name:find(" ") and BNConnected() then
		local pID = GetAutoCompletePresenceID(name)
		if pID ~= nil then
			local presenceID, presenceName, battleTag, isBattleTagPresence, toonName, toonID, client, isOnline, lastOnline, isAFK, isDND, messageText, noteText, isRIDFriend, broadcastTime, canSoR = BNGetFriendInfoByID(pID)
			if isOnline then
				--BNSendWhisper(presenceID, L.NOTIFICATION_FRIENDS_1 .. playerName .. L.NOTIFICATION_FRIENDS_2 .. groupName)
			end
		end
	else
		if UnitIsConnected(name) ~= nil then
			--SendChatMessage(L.NOTIFICATION_FRIENDS_1 .. playerName .. L.NOTIFICATION_FRIENDS_2 .. groupName, "WHISPER", nil, name)
		end
	end
end
--[[
	Checks if the player is eligible to sign up for a premade group.
	returns false if person is in a group and is not a leader and true if person is not in a group or is in a group but is leader
]]
function PGF_IsEligibleToSign()
	if IsInGroup() and not UnitIsGroupLeader("player") then
		DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000" .. L.WARNING_UNELIGIBLE_TEXT)
		return false
	else
		return true
	end
end
--[[
	Splits the given keyword on each whitespace and stores it in a table
]]
function PGF_Split(keyword)
	local words = {}
	local count = 1
	for word in keyword:gmatch("%S+") do
		words[count] = word
		count = count + 1
	end
	return words
end
function PGF_IsMatch(name, PGF_activeKeywords)
	local splitName = PGF_Split(name) -- Name of the group
	local matched = false
	local skip = false
	for i, j in pairs(PGF_activeKeywords) do --  for each keyword
		local splitKey = PGF_Split(j) -- current keyword
		skip = false
		if not matched then
			for a, b in pairs(splitKey) do -- for each word in current keyword
				if not skip then
					for c, d in pairs(splitName) do -- for each word in the name of the group
						if d:find(b) then 
							matched = true
							skip = false
							break
						end
						skip = true
						matched = false
					end
				else
					break
				end	
			end
		else
			break
		end
	end
	return matched
end
function PGF_ToggleGUI()
	PGF_options:Show()
end
--[[
	Returns the argument entered by the player
	param(cmd) string / message sent by the player
	return string / Returns the second argument
]]
function PGF_GetArg(cmd)
	if cmd == nil then
		return ""
	end
	local command, rest = cmd:match("^(%S*)%s*(.-)$")
	return rest
end
--[[
	Returns the command entered by the player
	param(cmd) string / message sent by the player
	return string / Returns the first argument
]]
function PGF_GetCmd(cmd)
	if cmd == nil then
		return ""
	end
	local command, rest = cmd:match("^(%S*)%s*(.-)$")
	return command
end
--[[
	Overrides Blizzards function, sorting by date rather than ID
--]]
function LFGListUtil_SortSearchResultsCB(id1, id2)
	local result1 = C_LFGList.GetSearchResultInfo(id1)
	local result2 = C_LFGList.GetSearchResultInfo(id2)
	local _, appStatus, pendingStatus, appDuration = C_LFGList.GetApplicationInfo(id1)
	if (pendingStatus == "applied") then
		return id1;
	end
	if result1.numBNetFriends ~= result2.numBNetFriends then
		return result1.numBNetFriends > result2.numBNetFriends
	end
	if result1.numCharFriends ~= result2.numCharFriends then
		return result1.numCharFriends > result2.numCharFriends
	end
	if result1.numGuildMates ~= result2.numGuildMates then
		return result1.numGuildMates > result2.numGuildMates
	end
	--local hasRemainingRole1 = HasRemainingSlotsForLocalPlayerRole(id1);
	--local hasRemainingRole2 = HasRemainingSlotsForLocalPlayerRole(id2);
	--[[
	-- Groups with your current role available are preferred
	if (hasRemainingRole1 ~= hasRemainingRole2) then
		return hasRemainingRole1;
	end
	]]
	if result1.age ~= result2.age then
		return result1.age < result2.age
	end
	return id1 < id2
end
--[[
	Analyzes the chance of the leader being a troll and prevents you from wasting time
--]]
function PGF_IsTroll(age)
	if age < 10 then
		return true
	end
	return false
end
function PGF_LoadProfile(profile)
	PGF_activeKeywords = {}
	PGF_inactiveKeywords = {}
	if PGF_profiles[profile] ~= nil then
		for k, v in pairs(PGF_profiles[profile]) do
			PGF_UpdateList(PGF_activeKeywords, v, true)
		end
	end
	DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00" .. L.ADDON .. profile .. L.WARNING_PROFILE_LOADED)
end
function PGF_CreateProfile(profileName)
	if not PGF_Contains(PGF_profiles, profileName) then
		PGF_profiles[profileName] = {}
		for k, v in pairs(PGF_activeKeywords) do
			PGF_UpdateList(PGF_profiles[profileName], v, true)
		end
	end
end
function PGF_UpdateList(arr, value, add)
	local exists = PGF_Contains(arr, value)
	if value ~= nil and add ~= nil then
		if add and not exists then
			arr[PGF_FirstEmptyIndex(arr)] = value
		elseif not add and exists then
			for i = exists, PGF_GetSize(arr)-1 do
				arr[i] = arr[i+1]
			end
			arr[PGF_GetSize(arr)] = nil
		end
	end
end
function PGF_GetGroupCreation(age)
	return GetTime() - age
end
function PGF_Disable()
	PGF_enabled = false
	DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000" .. L.WARNING_DISABLED_TEXT)
end
function PGF_Enable()
	PGF_enabled = true
	DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00" .. L.WARNING_ENABLED_TEXT)
end
function PGF_OpenSettings()
	InterfaceOptionsFrame_OpenToCategory(PGF_optionsKeywords)
end
--[[
function PGF_RoleEligibility()
	local canBeTank, canBeHealer, canBeDPS = UnitGetAvailableRoles("player")
	PGF_EnableRoleTank(canBeTank)
	PGF_EnableRoleHealer(canBeHealer)
	PGF_EnableRoleDPS(canBeDPS)
end
]]
function PGF_ConfirmLowerCase()
	--Check profiles on login and make sure they are all lower
end
function PGF_TrimTail(keyword)
	return keyword:match("(.-)%s*$")
end
function PGF_InsertionSort(arr)
	for j = 2, #arr do
		local current = arr[j]
		local i = j - 1
		while i > 0 and arr[i].age > current.age do
			arr[i+1] = arr[i]
			i = i -1
		end
		arr[i+1] = current
	end
end