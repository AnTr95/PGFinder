--[[
	This addon is made for finding premade groups accordingly to the demand of the user.
	Author: Anton Ronsjö / Ant-Kazzak
	Version: 3.6
]]
-- SAVEDVARIABLES:
-- PGF_activeKeywords Storing all PGF_activeKeywords
-- PGF_friends Storing all PGF_friends
-- PGF_interval Interval between the searches
-- PGF_enabled Checks if addon is enabled
-- SAVEDVARIABLESPERCHARACTER
-- playerName Name of the player
-- PROFILES
local addon = ... -- The name of the addon folder
local version = GetAddOnMetadata(addon, "Version")
local recievedOutOfDateMessage = false
local L = PGFinderLocals -- Strings
local f = CreateFrame("Frame") -- Addon Frame
local ticks = 0 -- Time elapsed since last search
local C_LFGList = C_LFGList -- The C_LFGList
local foundGroups = {} -- Groups that the player and its PGF_friends has been notified about
local popped = 0 -- time left of visual notification
local paused = false -- addon is paused because of user action (used the searchbox)
local apps = {}
local FRIEND_ONLINE = ERR_FRIEND_ONLINE_SS:match("%s(.+)") -- Converts "[%s] has come online". to "has come online".
--SetBinding("SHIFT-G", "CLICK StaticPopup3Button1")
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
	local arg = string.lower(PGF_GetArg(msg))
	local cmd = string.lower(PGF_GetCmd(msg))
	if cmd ~= "" then
		if arg ~= "" then
			if cmd == "add" then
				arg = PGF_TrimTail(arg)
				if PGF_Contains(PGF_activeKeywords, arg) or PGF_Contains(PGF_inactiveKeywords, arg) then
					DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000" .. L.ADDON .. arg .. L.WARNING_KEYWORD_EXISTS)
					return
				else
					PGF_UpdateList(PGF_activeKeywords, arg, true)
					PGF_CreateActiveKeywordFrame(arg)
					DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00" .. L.ADDON .. arg .. L.WARNING_KEYWORD_ADDED)
					return
				end
			elseif cmd == "remove" then
				arg = PGF_TrimTail(arg)
				if not PGF_Contains(PGF_activeKeywords, arg) and not PGF_Contains(PGF_inactiveKeywords, arg) then
					DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000" .. L.ADDON .. arg .. L.WARNING_KEYWORD_NOT_EXISTS)
					return
				else
					local existsActive = PGF_Contains(PGF_activeKeywords, arg)
					local existsInactive = PGF_Contains(PGF_inactiveKeywords, arg)
					if existsActive then
						PGF_UpdateList(PGF_activeKeywords, arg, false)
						PGF_UpdateActiveKeywordList(existsActive)
					elseif existsInactive then
						PGF_UpdateList(PGF_inactiveKeywords, arg, false)
						PGF_UpdateInactiveKeywordList(existsInactive)
					end
					DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00" .. L.ADDON .. arg .. L.WARNING_KEYWORD_REMOVED)
					return
				end
			end
		end
		if cmd == "enable" then
			PGF_enabled = true
			if PGF_changeMinimapColor then
				PGF_MinimapButton_SetGreen(PGF_minimapButton)
			end
			DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00" .. L.WARNING_ENABLED_TEXT)
			return
		elseif cmd == "disable" then
			PGF_enabled = false
			if PGF_changeMinimapColor then
				PGF_MinimapButton_SetRed(PGF_minimapButton)
			end
			DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000" .. L.WARNING_DISABLED_TEXT)
			return
		else
			InterfaceOptionsFrame_OpenToCategory(PGF_optionsKeywords)
			if not PGF_optionsKeywords:IsVisible() then
				InterfaceOptionsFrame_OpenToCategory(PGF_optionsKeywords)
			end
		end
	else
		InterfaceOptionsFrame_OpenToCategory(PGF_optionsKeywords)
		if not PGF_optionsKeywords:IsVisible() then
			InterfaceOptionsFrame_OpenToCategory(PGF_optionsKeywords)
		end
	end
end
SlashCmdList["PREMADEGROUPFINDER"] = handler
C_ChatInfo.RegisterAddonMessagePrefix("PGF_VERSIONCHECK")
f:RegisterEvent("LFG_LIST_SEARCH_RESULTS_RECEIVED")
f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("PLAYER_LOGIN")
f:RegisterEvent("LFG_LIST_SEARCH_RESULT_UPDATED")
f:RegisterEvent("CHAT_MSG_ADDON")
f:RegisterEvent("CHAT_MSG_SYSTEM")
f:RegisterEvent("GROUP_ROSTER_UPDATE")
f:RegisterEvent("LFG_LIST_SEARCH_FAILED")
--[[
	Refreshes the LFGList after a given interval
]]
f:SetScript("OnUpdate", function(self, elapsed)
	--[[
	if PGF_enabled then
		ticks = ticks + elapsed
		if ticks >= PGF_interval then
			local search = LFGListFrame.SearchPanel
			local searchText = LFGListFrame.SearchPanel.SearchBox:GetText() -- Not used, takes the text in the searchbox
			if search.categoryID == nil and PGF_latestCategory ~= nil and PGF_latestCategory ~= "" then
				search.categoryID = PGF_latestCategory
			end
			if search.categoryID ~= nil then
				if LFGListFrame:IsVisible() then -- window open
					if LFGListApplicationDialog:IsShown() then
						if not paused then
							paused = true
							DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000" .. L.WARNING_PAUSED_TEXT)
						end
					elseif searchText ~= "" and searchText ~= nil then
						if not paused then
							paused = true
							DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000" .. L.WARNING_PAUSED_TEXT)
						end
					else
						if paused then
							paused = false
							DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00" .. L.WARNING_UNPAUSED_TEXT)
						end
						--hooksecurefunc("C_LFGList.Search")
						--C_LFGList.Search(search.categoryID, LFGListSearchPanel_ParseSearchTerms(""), search.filters, search.preferredFilters, C_LFGList.GetLanguageSearchFilter())
					end
				else -- window closed
					if paused then
						paused = false
						DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00" .. L.WARNING_UNPAUSED_TEXT)
					end
					--C_LFGList.ClearSearchResults()
					--C_LFGList.Search(search.categoryID, LFGListSearchPanel_ParseSearchTerms(""), search.filters, search.preferredFilters, C_LFGList.GetLanguageSearchFilter())
				end
				if PGF_latestCategory == nil or PGF_latestCategory == "" or PGF_latestCategory ~= search.categoryID then
					PGF_latestCategory = search.categoryID
					DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00" .. L.WARNING_CHANGED_CATEGORY .. categories[PGF_latestCategory])
				end
			end
			ticks = 0
		end
	end]]
	if popped <= 0 and PGF_popup:IsShown() then
		PGF_popup:Hide()
		popped = 0
	elseif PGF_popup:IsShown() then
		popped = popped - elapsed
	end
end)
--[[
	Tracks LFG_LIST_SEARCH_RESULTS_RECIEVED, ADDON_LOADED and LFG_LIST_SEARCH_RESULT_UPDATED events
	Case LFG_LIST_SEARCH_RESULTS_RECIEVED: Searches through the results in LFGList for group names that matches any of the PGF_activeKeywords and then notifying the player about its findings
	CASE ADDON_LOADED: Initiates saved variables and gets current online BN PGF_friends
	CASE LFG_LIST_SEARCH_RESULT_UPDATED: Removes the group from found groups if delisted
	CASE PLAYER_LOGIN: Starts searching for groups if search_loginButton is checked
]]
f:SetScript("OnEvent", function(self, event, ...)
	local unit = ...
	if event == "ADDON_LOADED" and unit == "PGFinder" then
		--if PGF_interval == nil then PGF_interval = 10 end
		if PGF_friends == nil then PGF_friends = {} end
		if PGF_activeKeywords == nil then PGF_activeKeywords = {} end
		if PGF_inactiveKeywords == nil then PGF_inactiveKeywords = {} end
		if PGF_enabled == nil then PGF_enabled = true end
		if PGF_enabled == true and PGF_changeMinimapColor then
			PGF_MinimapButton_SetGreen(PGF_minimapButton)
		elseif PGF_enabled  == false and PGF_changeMinimapColor then
			PGF_MinimapButton_SetRed(PGF_minimapButton)
		end
		if PGF_notification_sound == nil then PGF_notification_sound = true end
		if PGF_autoSign == nil then PGF_autoSign = true end
		if PGF_autoSignState == nil then 
			PGF_autoSignState = "While not in a group"
			PGF_autoSign = true
		end
		if PGF_blacklist == nil then 
			PGF_blacklist = {} 
			PGF_blacklist.Players = {}
			PGF_blacklist.Keywords = {}
			PGF_blacklist.Servers = {}
		end
		--if PGF_searchLogin == nil then PGF_searchLogin = true end
		if PGF_minimapButtonMode == nil then PGF_minimapButtonMode = "Always" end
		if PGF_notification_guild == nil then PGF_notification_guild = true end
		if PGF_latestCategory == nil then PGF_latestCategory = "" end
		if PGF_notification_popup == nil then PGF_notification_popup = true end
		if PGF_notification_flashTaskbar == nil then PGF_notification_flashTaskbar = true end
		if PGF_minimapDegree == nil then PGF_minimapDegree = 30 end
		if PGF_popupPoint ~= nil then PGF_SetPopUpPoint(PGF_popupPoint.point, PGF_popupPoint.relativeTo, PGF_popupPoint.relativePoint, PGF_popupPoint.xOffset, PGF_popupPoint.yOffset) end
		if PGF_minimapDegree ~= nil then PGF_SetMinimapPoint(PGF_minimapDegree) end
		--[[
		if PGF_roles == nil then
			PGF_roles = {}
			PGF_roles.TANK = false
			PGF_roles.HEALER = false
			PGF_roles.DPS = false
			PGF_RoleEligibility()
		end
		]]
		if PGF_changeMinimapColor == nil then PGF_changeMinimapColor = true end
		if PGF_latestProfile == nil then PGF_latestProfile = "" end
		if TROLL_PROTECTION == nil then TROLL_PROTECTION = true end
		if PGF_profiles == nil then
			PGF_profiles = {}
			for k,v in pairs(PGF_standardProfiles) do
				PGF_profiles[k] = {}
				for i, j in pairs(v) do
					PGF_UpdateList(PGF_profiles[k], j, true)
				end
			end
		end
		if PGF_SearchBinding then PGF_SetSearchBinding() end
	elseif event == "PLAYER_LOGIN" then
		DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00" .. L.WARNING_LOGIN_TEXT)
		PGF_ConfirmLowerCase()
		--PGF_RoleEligibility()
		if PGF_minimapButtonMode == "Always" then
			PGF_minimapButton:Show()
		else
			PGF_minimapButton:Hide()
		end
		if not IsInGuild() and PGF_notification_guild then
			PGF_notification_guild = false
		end
		--[[
		if PGF_searchLogin and PGF_enabled and PGF_latestCategory ~= "" and PGF_latestCategory ~= nil then
			DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00" .. L.WARNING_SEARCH_LOGIN_TEXT)
			C_LFGList.Search(PGF_latestCategory, "", LFGListFrame.SearchPanel.filters, LFGListFrame.SearchPanel.preferredFilters, C_LFGList.GetLanguageSearchFilter())
		end
		]]
		if IsInGuild() then
			C_ChatInfo.SendAddonMessage("PGF_VERSIONCHECK", version, "GUILD")
		end
	elseif event == "CHAT_MSG_SYSTEM" then
		local msg = ...
		local sender = msg
		msg = msg:match("%s(.+)")
		if msg == FRIEND_ONLINE then
			sender = sender:match("%[(.+)%]")
			if sender ~= UnitName("player") then
				C_Timer.After(5, function() 
					if sender ~= nil and UnitIsConnected(sender) then
						C_ChatInfo.SendAddonMessage("PGF_VERSIONCHECK", version, "WHISPER", sender)
					end
				end)
			end
		end
	elseif event == "GROUP_ROSTER_UPDATE" then
		if IsInRaid(LE_PARTY_CATEGORY_INSTANCE) or IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then
			C_ChatInfo.SendAddonMessage("PGF_VERSIONCHECK", version, "INSTANCE_CHAT")
		elseif IsInRaid(LE_PARTY_CATEGORY_HOME) then
			C_ChatInfo.SendAddonMessage("PGF_VERSIONCHECK", version, "RAID")
		elseif IsInGroup(LE_PARTY_CATEGORY_HOME) then
			C_ChatInfo.SendAddonMessage("PGF_VERSIONCHECK", version, "PARTY")
		end
	elseif event == "CHAT_MSG_ADDON" then
		local prefix, msg, channel, sender = ...
		local fullName = select(1, UnitFullName("player")) .. "-" .. select(2, UnitFullName("player"))
		if prefix == "PGF_VERSIONCHECK" and not recievedOutOfDateMessage and fullName ~= sender then
			if tonumber(msg) ~= nil then
				if tonumber(msg) > tonumber(version) then
					DEFAULT_CHAT_FRAME:AddMessage("\124T|cFFFFFF00\124t" .. L.WARNING_OUTOFDATEMESSAGE)
					recievedOutOfDateMessage = true
				end
			end
		end
	elseif event == "LFG_LIST_SEARCH_FAILED" then
		if PGF_enabled then
			--Added say it failed
		end
	elseif event == "LFG_LIST_SEARCH_RESULT_UPDATED" and PGF_enabled then
		--local numResults, results = C_LFGList.GetSearchResults()
		--local searchResults = C_LFGList.GetSearchResultInfo(results[k])
		--local name = searchResults.name;
		--local leaderName = searchResults.leaderName;
		--local age = searchResults.age
		--local isDelisted = searchResults.isDelisted		
		if name ~= nil then
			name = string.lower(name) -- CASE INSENSITIVE
		end
		if leaderName ~= nil then
			leaderName = string.lower(leaderName)
		end
		if age ~= nil then
			local time = time() - age
			for k, v in pairs(foundGroups) do
				if name == foundGroups[k].Name and leaderName ~= foundGroups[k].Leader and PGF_IsWithinReasonableTime(foundGroups[k].Age, time, 1) then --Leader has changed
					foundGroups[k].Leader = leaderName
				elseif name ~= foundGroups[k].Name and leaderName == foundGroups[k].Leader and not foundGroups[k].Blacklisted then
					foundGroups[k] = nil
				elseif name ~= foundGroups[k].Name and leaderName == foundGroups[k].Leader and foundGroups[k].Blacklisted then
					foundGroups[k].Name = name
				elseif isDelisted and name == foundGroups[k].Name and leaderName == foundGroups[k].Leader then
					foundGroups[k] = nil
				end
			end
		end
		--if PGF_HasBeenSignedUpBefore()
		--if isDelisted and PGF_HasBeenSignedUpBefore(foundGroups, unit) then
			--foundGroups[PGF_HasBeenSignedUpBefore(foundGroups, unit)] = nil
		--end
	elseif event == "LFG_LIST_SEARCH_RESULTS_RECEIVED" and PGF_enabled then -- Received reults of a search in LFGList
		local numResults, results = C_LFGList.GetSearchResults()
		LFGListUtil_SortSearchResults(results)
		for k, v in pairs(results) do
			local searchResults = C_LFGList.GetSearchResultInfo(results[k])
			local name = searchResults.name;
			local leaderName = searchResults.leaderName;
			local age = searchResults.age
			local isDelisted = searchResults.isDelisted
			if name ~= nil then
			end
			if leaderName ~= nil then
				leaderName = string.lower(leaderName)
			end
			if not isDelisted and not PGF_HasBeenSignedUpBefore(foundGroups, results[k]) then
				if PGF_IsMatch2(name, PGF_activeKeywords) and not PGF_IsBlacklisted(name, leaderName, age) then
					if PGF_notification_flashTaskbar then
						FlashClientIcon()
					end
					local index = PGF_FirstEmptyIndex(foundGroups)
					foundGroups[index] = {}
					foundGroups[index].Name = name
					foundGroups[index].Leader = leaderName
					foundGroups[index].Age = time() - age
					foundGroups[index].Blacklisted = false
					DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000" .. L.NOTIFICATION_YOU .. name)
					if PGF_autoSignState == "Always" and PGF_IsEligibleToSign() then
						apps[#apps+1] = v
						--LFGListApplicationDialog_Show(LFGListApplicationDialog, v)
						--[[
						if not PGF_roles.TANK and not PGF_roles.HEALER and not PGF_roles.DPS then
							LFGListApplicationDialog_Show(LFGListApplicationDialog, v)
						else
							C_LFGList.ApplyToGroup(id, "", PGF_roles.TANK, PGF_roles.HEALER, PGF_roles.DPS) -- SIGN UP AS CHOSEN ROLE
						end
						]]
					elseif PGF_autoSignState == "While not in a group" and not IsInGroup() then
						apps[#apps+1] = v
						--LFGListApplicationDialog_Show(LFGListApplicationDialog, v)
						--[[
						if not PGF_roles.TANK and not PGF_roles.HEALER and not PGF_roles.DPS then
							LFGListApplicationDialog_Show(LFGListApplicationDialog, v)
						else
							C_LFGList.ApplyToGroup(id, "", PGF_roles.TANK, PGF_roles.HEALER, PGF_roles.DPS) -- SIGN UP AS CHOSEN ROLE
						end
						]]
					end
					if PGF_notification_sound then
						PlaySound(8960)
					end
					if PGF_notification_guild and IsInGuild() then
						SendChatMessage(L.NOTIFICATION_GUILD .. name, "GUILD", nil, nil)
					end
					--[[if PGF_notification_whisper then
						for a, b in pairs(PGF_friends) do
							PGF_PMFriend(PGF_friends[a], name)
						end
					end]]
					if PGF_notification_popup then
						PGF_SetInfoText(name)
						PGF_popup:Show()
						popped = 4
					end
				end
			end
		end
		if apps[1] then
			LFGListApplicationDialog_Show(LFGListApplicationDialog, apps[1])
			apps[1] = nil
		end
	end
end)

local applicationDialogText = LFGListApplicationDialog:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
applicationDialogText:SetPoint("TOP")

LFGListApplicationDialog:HookScript("OnShow", function(self)
	for k, v in pairs(apps) do
		if v then
			local id, activityID, name = C_LFGList.GetSearchResultInfo(v)
			applicationDialogText:SetText(name)
		end
		break
	end
end)

LFGListApplicationDialog:HookScript("OnHide", function(self)
	applicationDialogText:SetText("")
end)

LFGListApplicationDialog.SignUpButton:HookScript("OnClick", function(self)
	for k, v in pairs(apps) do
		if v then
			LFGListApplicationDialog_Show(LFGListApplicationDialog, v)
			apps[k] = nil
		end
		break
	end
end)
LFGListApplicationDialog.CancelButton:HookScript("OnClick", function(self)
	for k, v in pairs(apps) do
		if v then
			LFGListApplicationDialog_Show(LFGListApplicationDialog, v)
			apps[k] = nil
		end
		break
	end
end)

function PGF_BlacklistLeader(name, leader, age)
	local index = PGF_FirstEmptyIndex(foundGroups)
	foundGroups[index] = {}
	foundGroups[index].Name = name
	foundGroups[index].Leader = leader
	foundGroups[index].Age = time() - age
	foundGroups[index].BlacklistedLeader = leader
	foundGroups[index].Blacklisted = true
end

function PGF_Search()
	local search = LFGListFrame.SearchPanel
	local searchText = LFGListFrame.SearchPanel.SearchBox:GetText() -- Not used, takes the text in the searchbox
	if search.categoryID == nil and PGF_latestCategory ~= nil and PGF_latestCategory ~= "" then
		search.categoryID = PGF_latestCategory
	end
	if search.categoryID ~= nil then
		if LFGListFrame:IsVisible() then -- window open
			if LFGListApplicationDialog:IsShown() then
				if not paused then
					paused = true
					DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000" .. L.WARNING_PAUSED_TEXT)
				end
			elseif searchText ~= "" and searchText ~= nil then
				if not paused then
					paused = true
					DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000" .. L.WARNING_PAUSED_TEXT)
				end
			else
				if paused then
					paused = false
					DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00" .. L.WARNING_UNPAUSED_TEXT)
				end
				StaticPopup_Show("PGF_TEST")
				--hooksecurefunc("C_LFGList.Search")
				C_LFGList.Search(search.categoryID, search.filters, search.preferredFilters, C_LFGList.GetLanguageSearchFilter())
			end
		else -- window closed
			if paused then
				paused = false
				DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00" .. L.WARNING_UNPAUSED_TEXT)
			end
			C_LFGList.ClearSearchResults()
			C_LFGList.Search(search.categoryID, search.filters, search.preferredFilters, C_LFGList.GetLanguageSearchFilter())
		end
		if PGF_latestCategory == nil or PGF_latestCategory == "" or PGF_latestCategory ~= search.categoryID then
			PGF_latestCategory = search.categoryID
			DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00" .. L.WARNING_CHANGED_CATEGORY .. categories[PGF_latestCategory])
		end
	end
end

function PGF_RemoveBlacklistLeader(leader)
	if leader ~= nil then
		leader = string.lower(leader)
	end
	for k, v in pairs(foundGroups) do
		if leader == foundGroups[k].BlacklistedLeader and foundGroups[k].Blacklisted then
			foundGroups[k] = nil
			return
		end
	end
end

local function hook_SetText(self, ...)
	local line = _G[self:GetName() .. "TextLeft1"] -- First line
	local text = string.lower(line:GetText() or "")
	for k, v in pairs(foundGroups) do
		if text == foundGroups[k].Name and foundGroups[k].Blacklisted then --Leader has changed
			self:AddLine(L.WARNING_LFGLISTSEARCHENTRYTOOLTIP, 1, 0, 0)
			self:Show()
		end
	end
end

hooksecurefunc(GameTooltip, "SetText", hook_SetText)

--------------------------
------Blizzard Taint------
--------------------------
if ((UIDROPDOWNMENU_OPEN_PATCH_VERSION or 0) < 1) then 
	UIDROPDOWNMENU_OPEN_PATCH_VERSION = 1;
	hooksecurefunc("UIDropDownMenu_InitializeHelper", function(frame) 
		if (UIDROPDOWNMENU_OPEN_PATCH_VERSION ~= 1) then 
			return; 
		end 
		if (UIDROPDOWNMENU_OPEN_MENU and UIDROPDOWNMENU_OPEN_MENU ~= frame and not issecurevariable(UIDROPDOWNMENU_OPEN_MENU, "displayMode")) then 
			UIDROPDOWNMENU_OPEN_MENU = nil;
			local t, f, prefix, i = _G, issecurevariable, " \0", 1;
			repeat 
				i, t[prefix .. i] = i + 1;
			until f("UIDROPDOWNMENU_OPEN_MENU")
		end 
	end) 
end
if ((UIDROPDOWNMENU_VALUE_PATCH_VERSION or 0) < 2) then 
	UIDROPDOWNMENU_VALUE_PATCH_VERSION = 2;
	hooksecurefunc("UIDropDownMenu_InitializeHelper", function() 
		if (UIDROPDOWNMENU_VALUE_PATCH_VERSION ~= 2) then 
			return;
		end 
		for i=1, UIDROPDOWNMENU_MAXLEVELS do 
			for j=1, UIDROPDOWNMENU_MAXBUTTONS do 
				local b = _G["DropDownList" .. i .. "Button" .. j];
				if (not (issecurevariable(b, "value") or b:IsShown())) then 
					b.value = nil;
					repeat 
						j, b["fx" .. j] = j+1;
					until issecurevariable(b, "value") 
				end 
			end 
		end 
	end) 
end