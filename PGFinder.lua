--[[
	This addon is made for finding premade groups accordingly to the demand of the user.
	Author: Anton Ronsjö / Ant-Kazzak
	Version: 2.0
]]
-- SAVEDVARIABLES:
-- keywords Storing all keywords
-- friends Storing all friends
-- INTERVAL Interval between the searches
-- ENABLED Checks if addon is enabled
-- SAVEDVARIABLESPERCHARACTER
-- playerName Name of the player
-- PROFILES
local addon = ... -- The name of the addon folder
local L = PGFinderLocals -- Strings
local f = CreateFrame("Frame") -- Addon Frame
local ticks = 0 -- Time elapsed since last search
local C_LFGList = C_LFGList -- The C_LFGList
local foundGroups = {} -- Groups that the player and its friends has been notified about
local popped = 0 -- time left of visual notification
-- All Blizzard Premade Group categories
local categories = {
	"Questing", 
	"Dungeons", 
	"Raids", 
	"Arenas", 
	nil, 
	"Custom", 
	"Arena Skirmishes", 
	"Battlegrounds", 
	"Rated Battlegrounds", 
	"Ashran"
}

--[[
	Reads all commands with the prefix SLASH-PREMADEGROUPFINDER and responds accordingly
	@param(msg) string / The message sent by the user
	@param(editbox)
]]
local function handler(msg, editbox)
	local arg = string.lower(getArg(msg))
	local cmd = string.lower(getCmd(msg))
	if cmd ~= "" then
		if arg ~= "" then
			if cmd == "add" then
				if contains(keywords, arg) then
					DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000" .. L.ADDON .. arg .. L.WARNING_KEYWORD_EXISTS)
					return
				else
					DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00" .. L.ADDON .. arg .. L.WARNING_KEYWORD_ADDED)
					updateList(keywords, arg, true)
					updateKeywordList()
					return
				end
			elseif cmd == "remove" then
				if not contains(keywords, arg) then
					DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000" .. L.ADDON .. arg .. L.WARNING_KEYWORD_NOT_EXISTS)
					return
				else
					updateList(keywords, arg, false)
					updateKeywordList()
					DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00" .. L.ADDON .. arg .. L.WARNING_KEYWORD_REMOVED)
					return
				end
			end
		end
		if cmd == "enable" then
			ENABLED = true
			DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00" .. L.WARNING_ENABLED_TEXT)
			return
		elseif cmd == "disable" then
			ENABLED = false
			DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000" .. L.WARNING_DISABLED_TEXT)
			return
		else
			InterfaceOptionsFrame_OpenToCategory(optionsLists)
		end
	else
		InterfaceOptionsFrame_OpenToCategory(optionsLists)
	end
end
SlashCmdList["PREMADEGROUPFINDER"] = handler
f:RegisterEvent("LFG_LIST_SEARCH_RESULTS_RECEIVED")
f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("PLAYER_LOGIN")
f:RegisterEvent("LFG_LIST_SEARCH_RESULT_UPDATED")
--[[
	Refreshes the LFGList after a given interval
]]
f:SetScript("OnUpdate", function(self, elapsed)
	if ENABLED then
		ticks = ticks + elapsed
		if ticks >= INTERVAL then
			local search = LFGListFrame.SearchPanel
			if search.categoryID == nil and LATEST_CATEGORY ~= nil and LATEST_CATEGORY ~= "" then
				search.categoryID = LATEST_CATEGORY
			end
			if search.categoryID ~= nil then
				C_LFGList.Search(search.categoryID, "", search.filters, search.preferredFilters, C_LFGList.GetLanguageSearchFilter())
				if LATEST_CATEGORY == nil or LATEST_CATEGORY == "" or LATEST_CATEGORY ~= search.categoryID then
					LATEST_CATEGORY = search.categoryID
					DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00" .. L.WARNING_CHANGED_CATEGORY .. categories[LATEST_CATEGORY])
				end
			end
			ticks = 0
		end
	end
	if popped <= 0 and popup:IsShown() then
		popup:Hide()
		popped = 0
	elseif popup:IsShown() then
		popped = popped - elapsed
	end
end)
--[[
	Tracks LFG_LIST_SEARCH_RESULTS_RECIEVED, ADDON_LOADED and LFG_LIST_SEARCH_RESULT_UPDATED events
	Case LFG_LIST_SEARCH_RESULTS_RECIEVED: Searches through the results in LFGList for group names that matches any of the keywords and then notifying the player about its findings
	CASE ADDON_LOADED: Initiates saved variables and gets current online BN friends
	CASE LFG_LIST_SEARCH_RESULT_UPDATED: Removes the group from found groups if delisted
	CASE PLAYER_LOGIN: Starts searching for groups if search_loginButton is checked
]]
f:SetScript("OnEvent", function(self, event, ...)
	local unit = ...
	if event == "ADDON_LOADED" and unit == "PGFinder" then
		if INTERVAL == nil then INTERVAL = 30 end
		if friends == nil then friends = {} end
		if keywords == nil then keywords = {} end
		if ENABLED == nil then ENABLED = true end
		if playerName == nil then playerName = UnitName("player") end
		if SOUND_NOTIFICATION == nil then SOUND_NOTIFICATION = true end
		if AUTO_SIGN == nil then AUTO_SIGN = true end
		if WHISPER_NOTIFICATION == nil then WHISPER_NOTIFICATION = true end
		if SEARCH_LOGIN == nil then SEARCH_LOGIN = true end
		if GUILD_NOTIFICATION == nil then GUILD_NOTIFICATION = true end
		if LATEST_CATEGORY == nil then LATEST_CATEGORY = "" end
		if POPUP_NOTIFICATION == nil then POPUP_NOTIFICATION = true end
		if POPUPPOINT ~= nil then setPopUpPoint(POPUPPOINT.point, POPUPPOINT.relativeTo, POPUPPOINT.relativePoint, POPUPPOINT.xOffset, POPUPPOINT.yOffset) end
		if ROLES == nil then
			ROLES = {}
			ROLES.TANK = false
			ROLES.HEALER = false
			ROLES.DPS = false
		end
		if LATEST_PROFILE == nil then LATEST_PROFILE = "" end
		if TROLL_PROTECTION == nil then TROLL_PROTECTION = true end
		if Profiles == nil then
			Profiles = {}
			for k,v in pairs(standardProfiles) do
				Profiles[k] = {}
				for i, j in pairs(v) do
					updateList(Profiles[k], j, true)
				end
			end
		end
	elseif event == "PLAYER_LOGIN" then
		DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00" .. L.WARNING_LOGIN_TEXT)
		if not IsInGuild() and GUILD_NOTIFICATION then
			GUILD_NOTIFICATION = false
		end
		if SEARCH_LOGIN and ENABLED and LATEST_CATEGORY ~= "" and LATEST_CATEGORY ~= nil then
			DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00" .. L.WARNING_SEARCH_LOGIN_TEXT)
			C_LFGList.Search(LATEST_CATEGORY, "", LFGListFrame.SearchPanel.filters, LFGListFrame.SearchPanel.preferredFilters, C_LFGList.GetLanguageSearchFilter())
		end
	elseif event == "LFG_LIST_SEARCH_RESULT_UPDATED" and ENABLED then
		local numResults, results = C_LFGList.GetSearchResults()
		local id, activityID, name, comment, voiceChat, iLvl, age, numBNetFriends, numCharFriends, numGuildMates, isDelisted = C_LFGList.GetSearchResultInfo(unit)
		if name ~= nil then
			name = string.lower(name) -- CASE INSENSITIVE
		end
		if isDelisted and contains(foundGroups, math.floor(GetTime() - age)) ~= false then
			print("Removed " .. math.floor(GetTime()) - age .. " from group " .. name)
			foundGroups[contains(foundGroups, math.floor(GetTime() - age))] = nil
		end
	elseif event == "LFG_LIST_SEARCH_RESULTS_RECEIVED" and ENABLED then -- Received reults of a search in LFGList
		local numResults, results = C_LFGList.GetSearchResults()
		LFGListUtil_SortSearchResults(results)
		for k, v in pairs(results) do
			local id, activityID, name, comment, voiceChat, iLvl, age, numBNetFriends, numCharFriends, numGuildMates, isDelisted, leaderName, numMembers = C_LFGList.GetSearchResultInfo(results[k])
			if name ~= nil then
				name = string.lower(name) -- CASE INSENSITIVE
			end
			--print(name .. " " .. leaderName .. " " .. age .. " " .. id)
			if not isDelisted and not contains(foundGroups, math.floor(GetTime() - age)) then
				print("Checking " .. math.floor(GetTime()) - age .. " on group " .. name)
				if isMatch(name, keywords) then
					foundGroups[findIndex(foundGroups)] = math.floor(GetTime() - age)
					print("Added " .. math.floor(GetTime()) - age .. " to group " .. name)
					DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000" .. L.NOTIFICATION_YOU .. name)
					if AUTO_SIGN and isEligibleToSign() then
						if not ROLES.TANK and not ROLES.HEALER and not ROLES.DPS then
							LFGListApplicationDialog_Show(LFGListApplicationDialog, v)
						else
							C_LFGList.ApplyToGroup(id, "", ROLES.TANK, ROLES.HEALER, ROLES.DPS) -- SIGN UP AS CHOSEN ROLE
						end
					end
					if SOUND_NOTIFICATION then
						PlaySound("ReadyCheck", "master")
					end
					if GUILD_NOTIFICATION and IsInGuild() then
						SendChatMessage(L.NOTIFICATION_GUILD .. name, "GUILD", nil, nil)
					end
					if WHISPER_NOTIFICATION then
						for a, b in pairs(friends) do
							pmFriend(friends[a], name)
						end
					end
					if POPUP_NOTIFICATION then
						setInfoText(name)
						popup:Show()
						popped = 4
					end
				end
			end
		end
	end
end)