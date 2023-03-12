local addon = ...
local L = PGFinderLocals
local blacklistVarFrames = nil
local markedVars = {}

PGF_optionsBlacklist = CreateFrame("Frame", "PGF_optionsBlacklist", InterfaceOptionsFramePanelContainer)
PGF_optionsBlacklist.name = "Blacklist"
PGF_optionsBlacklist.parent = "Premade Group Finder"
PGF_optionsBlacklist:Hide()

local title = PGF_optionsBlacklist:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
title:SetPoint("TOP", 0, -16)
title:SetText(L.OPTIONS_TITLE)

local tabinfo = PGF_optionsBlacklist:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
tabinfo:SetPoint("TOPLEFT", 16, -16)
tabinfo:SetText(L.OPTIONS_INFO_BLACKLIST)

local author = PGF_optionsBlacklist:CreateFontString(nil, "ARTWORK", "GameFontNormal")
author:SetPoint("TOPLEFT", 450, -20)
author:SetText(L.OPTIONS_AUTHOR)

local version = PGF_optionsBlacklist:CreateFontString(nil, "ARTWORK", "GameFontNormal")
version:SetPoint("TOPLEFT", author, "BOTTOMLEFT", 0, -10)
version:SetText(L.OPTIONS_VERSION)

local blacklistText = PGF_optionsBlacklist:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
blacklistText:SetPoint("TOPLEFT", 150, -80)
blacklistText:SetText("Blacklist")

local blacklistFrameScrollFrame = CreateFrame("ScrollFrame", "PGF_blacklistFrameScrollFrame", PGF_optionsBlacklist, "UIPanelScrollFrameTemplate")
blacklistFrameScrollFrame:SetSize(300, 320)
blacklistFrameScrollFrame:SetPoint("TOPLEFT", blacklistText, "TOPLEFT", -110, -25)

local blacklistFrame = CreateFrame("Frame")
blacklistFrame:SetSize(300, 320)
blacklistFrame:SetPoint("TOPLEFT", blacklistText, "TOPLEFT", -105, 0)

local blacklistFrameBackdrop = CreateFrame("Frame", "PGF_blacklistFrameBackdrop", PGF_optionsBlacklist, BackdropTemplateMixin and "BackdropTemplate")
blacklistFrameBackdrop:SetBackdrop({
	bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
	edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
	tile = true, tileSize = 16, edgeSize = 16,
	insets = {left = 3, right = 3, top = 3, bottom = 3}
})
blacklistFrameBackdrop:SetBackdropColor(0, 0, 0, 1)
blacklistFrameBackdrop:SetSize(300, 335)
blacklistFrameBackdrop:SetPoint("TOPLEFT", blacklistText, "TOPLEFT", -105, -20)

blacklistFrameScrollFrame:SetScrollChild(blacklistFrame)

local blacklistAddEditBox = CreateFrame("EditBox", "PGF_blacklistAddEditBox", PGF_optionsBlacklist, "InputBoxTemplate")
blacklistAddEditBox:SetPoint("TOPLEFT", 100, -445)
blacklistAddEditBox:SetAutoFocus(false)
blacklistAddEditBox:SetSize(200, 15)
blacklistAddEditBox:SetText("")
blacklistAddEditBox:SetScript("OnEscapePressed", function (self)
	self:SetText("")
	self:ClearFocus()
end)
blacklistAddEditBox:SetScript("OnEnterPressed", function(self)
	PGF_blacklistAddButton:Click()
end)


local blacklistAddPlayerButton = CreateFrame("CheckButton", "PGF_blacklistAddPlayerButton", PGF_optionsBlacklist, "UICheckButtonTemplate")
blacklistAddPlayerButton:SetSize(25, 25)
blacklistAddPlayerButton:SetPoint("TOPLEFT", blacklistAddEditBox, "TOPLEFT", 0, -20)
blacklistAddPlayerButton:SetScript("OnClick", function() 
	if PGF_blacklistAddServerButton:GetChecked() then
		PGF_blacklistAddServerButton:SetChecked(false)
	elseif PGF_blacklistAddKeywordButton:GetChecked() then
		PGF_blacklistAddKeywordButton:SetChecked(false)
	end
end)

local blacklistAddPlayerText = blacklistAddPlayerButton:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
blacklistAddPlayerText:SetText("Player: ")
blacklistAddPlayerText:SetPoint("TOPLEFT", blacklistAddEditBox, "TOPLEFT", -55, -24)

local blacklistAddKeywordButton = CreateFrame("CheckButton", "PGF_blacklistAddKeywordButton", PGF_optionsBlacklist, "UICheckButtonTemplate")
blacklistAddKeywordButton:SetSize(25, 25)
blacklistAddKeywordButton:SetPoint("TOPLEFT", blacklistAddEditBox, "TOPLEFT", 125, -20)
blacklistAddKeywordButton:SetScript("OnClick", function() 
	if PGF_blacklistAddServerButton:GetChecked() then
		PGF_blacklistAddServerButton:SetChecked(false)
	elseif PGF_blacklistAddPlayerButton:GetChecked() then
		PGF_blacklistAddPlayerButton:SetChecked(false)
	end
end)

local blacklistAddKeywordText = blacklistAddKeywordButton:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
blacklistAddKeywordText:SetText("Keyword: ")
blacklistAddKeywordText:SetPoint("TOPLEFT", blacklistAddEditBox, "TOPLEFT",  50, -24)

local blacklistAddServerButton = CreateFrame("CheckButton", "PGF_blacklistAddServerButton", PGF_optionsBlacklist, "UICheckButtonTemplate")
blacklistAddServerButton:SetSize(25, 25)
blacklistAddServerButton:SetPoint("TOPLEFT", blacklistAddEditBox, "TOPLEFT", 245, -20)
blacklistAddServerButton:SetScript("OnClick", function ()
	if PGF_blacklistAddKeywordButton:GetChecked() then
		PGF_blacklistAddKeywordButton:SetChecked(false)
	elseif PGF_blacklistAddPlayerButton:GetChecked() then
		PGF_blacklistAddPlayerButton:SetChecked(false)
	end
end)

local blacklistAddServerText = blacklistAddServerButton:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
blacklistAddServerText:SetPoint("TOPLEFT", blacklistAddEditBox, "TOPLEFT", 185, -24)
blacklistAddServerText:SetText("Server: ")

local function blacklistAddButton_OnClick(self, var)
	StaticPopupDialogs["PGF_BLACKLIST"] = {
	  text = "Are you sure this player is behind the troll group?",
	  button1 = "Yes",
	  button2 = "No",
	  OnAccept = function()
			PGF_UpdateList(PGF_blacklist.Players, var, true)
			PGF_blacklistAddEditBox:SetText("")
			PGF_blacklistAddPlayerButton:SetChecked(false)
			PGF_optionsBlacklist:Hide()
			blacklistVarFrames = nil
			PGF_optionsBlacklist:Show()
	  end,
	  OnCancel = function()
	  		PGF_blacklistAddEditBox:SetText("")
			PGF_blacklistAddPlayerButton:SetChecked(false)
	  end,
	  timeout = 0,
	  whileDead = true,
	  hideOnEscape = true,
	  preferredIndex = 3,  -- avoid some UI taint, see http://www.wowace.com/announcements/how-to-avoid-some-ui-taint/
	}
	StaticPopup_Show ("PGF_BLACKLIST")
end

local blacklistAdd = CreateFrame("Button", "PGF_blacklistAddButton", PGF_optionsBlacklist, "UIPanelButtonTemplate")
blacklistAdd:SetSize(120, 30)
blacklistAdd:SetPoint("TOPLEFT", blacklistAddEditBox, "TOPLEFT", 40, -50)
blacklistAdd:SetText("Blacklist!")
blacklistAdd:SetScript("OnClick", function() 
	local server = PGF_blacklistAddServerButton:GetChecked()
	local keyword = PGF_blacklistAddKeywordButton:GetChecked()
	local player = PGF_blacklistAddPlayerButton:GetChecked()
	local var = string.lower(PGF_blacklistAddEditBox:GetText())
	var = PGF_TrimTail(var)
	if (player or keyword or server) and var ~= nil and var ~= "" then
		if player then
			blacklistAddButton_OnClick(self, var)
		elseif keyword then
			PGF_UpdateList(PGF_blacklist.Keywords, var, true)
			PGF_blacklistAddEditBox:SetText("")
			PGF_blacklistAddKeywordButton:SetChecked(false)
			PGF_optionsBlacklist:Hide()
			blacklistVarFrames = nil
			PGF_optionsBlacklist:Show()
		elseif server then
			PGF_UpdateList(PGF_blacklist.Servers, var, true)
			PGF_blacklistAddEditBox:SetText("")
			PGF_blacklistAddServerButton:SetChecked(false)
			PGF_optionsBlacklist:Hide()
			blacklistVarFrames = nil
			PGF_optionsBlacklist:Show()
		end
	end
end)

local blacklistRemove = CreateFrame("Button", "PGF_blacklistRemoveButton", PGF_optionsBlacklist, "UIPanelButtonTemplate")
blacklistRemove:SetSize(100, 25)
blacklistRemove:SetPoint("TOPLEFT", blacklistFrame, "TOPLEFT", 340, -120)
blacklistRemove:SetText("Remove")
blacklistRemove:SetScript("OnClick", function()
	for i = 1, PGF_GetSize(markedVars) do
		local var = markedVars[i]
		local existsPlayer = PGF_Contains(PGF_blacklist["Players"], var)
		local existsKeywords = PGF_Contains(PGF_blacklist["Keywords"], var)
		local existsServers = PGF_Contains(PGF_blacklist["Servers"], var)
		if existsPlayer then
			existsPlayer = existsPlayer + 1
			PGF_UpdateList(PGF_blacklist.Players, markedVars[i], false)
			PGF_UpdateBlacklist(existsPlayer, false)
			PGF_RemoveBlacklistLeader(var)
		elseif existsKeywords then
			existsKeywords = existsKeywords + PGF_GetSize(PGF_blacklist.Players) + 2
			PGF_UpdateList(PGF_blacklist.Keywords, markedVars[i], false)
			PGF_UpdateBlacklist(existsKeywords, false)
		elseif existsServers then
			existsServers = existsServers + PGF_GetSize(PGF_blacklist.Players) + PGF_GetSize(PGF_blacklist.Keywords) + 3
			PGF_UpdateList(PGF_blacklist.Servers, markedVars[i], false)
			PGF_UpdateBlacklist(existsServers, false)
		end
	end
	markedKeywords = {}
end)

function PGF_CreateBlacklistVarFrame(var)
	local blacklistVarFrame = CreateFrame("Frame", "PGF_BlacklistVarFrame_"..var, blacklistFrame)
	blacklistVarFrame:SetSize(280, 30)
	blacklistVarFrame:SetPoint("TOPLEFT", blacklistFrame, "TOPLEFT", 0, -(20*(PGF_GetSize(blacklistVarFrames))))
	if var:find("Seperator_") then
		local text = var:match("Seperator_(.*)")
		local blacklistVarFrameText = blacklistVarFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
		blacklistVarFrameText:SetPoint("TOPLEFT", blacklistVarFrame, "TOPLEFT", 15, -3)
		blacklistVarFrameText:SetText(text)
		blacklistVarFrames[PGF_GetSize(blacklistVarFrames)+1] = blacklistVarFrame
		blacklistVarFrame:Show()
		return
	end
	local blacklistVarFrameCheckButton = CreateFrame("CheckButton", "PGF_blacklistVarFrameCheckButton_"..var, blacklistVarFrame, "UICheckButtonTemplate")
	blacklistVarFrameCheckButton:SetPoint("TOPLEFT", blacklistVarFrame, "TOPLEFT", 10, 0)
	blacklistVarFrameCheckButton:SetSize(20, 20)
	blacklistVarFrameCheckButton:SetScript("OnClick", function(self)
		if self:GetChecked() then
			markedVars[PGF_GetSize(markedVars)+1] = var
		end
	end)
	local blacklistVarFrameText = blacklistVarFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	blacklistVarFrameText:SetPoint("TOPLEFT", blacklistVarFrameCheckButton, "TOPLEFT", 23, -2)
	blacklistVarFrameText:SetText(var)
	blacklistVarFrameText:SetWordWrap(true)
	blacklistVarFrames[PGF_GetSize(blacklistVarFrames)+1] = blacklistVarFrame
	blacklistVarFrame:Show()
end

function PGF_UpdateBlacklist(index, add)
	if not add then
		for i = index+1, PGF_GetSize(blacklistVarFrames) do
			local blacklistVarFrame = blacklistVarFrames[i]
			blacklistVarFrame:SetPoint("TOPLEFT", blacklistFrame, "TOPLEFT", 0, -(20*(i-2)))
		end
		blacklistVarFrames[index]:Hide()
		PGF_UpdateList(blacklistVarFrames, blacklistVarFrames[index], false)
	--[[else
		local newBlacklistVarFrame = blacklistVarFrames[PGF_GetSize(blacklistVarFrames)]
		for i = index+1, PGF_GetSize(blacklistVarFrames)-1 do
			local blacklistVarFrame = blacklistVarFrames[i]
			if i == PGF_GetSize(blacklistVarFrames)-1 then
				blacklistVarFrame:SetPoint("TOPLEFT", blacklistFrame, "TOPLEFT", 0, (20*(i)))
				blacklistVarFrames[i+1] = blacklistVarFrame
			end
			newBlacklistVarFrame:SetPoint(blacklistVarFrame:GetPoint())
			blacklistVarFrames[i] = newBlacklistVarFrame
			blacklistVarFrame:SetPoint("TOPLEFT", blacklistFrame, "TOPLEFT", 0, (20*(i)))
			newBlacklistVarFrame = blacklistVarFrame
		end]]
	end
end

local infoText = PGF_optionsBlacklist:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
infoText:SetPoint("TOPLEFT", 20, -520)
infoText:SetWordWrap(true)
infoText:SetSize(550, 50)
infoText:SetTextColor(1, 0, 0)
infoText:SetText(L.INFO_BLACKLIST_INFO)

PGF_optionsBlacklist:SetScript("OnHide", function(self)
	for i = 1, PGF_GetSize(blacklistVarFrames) do
		blacklistVarFrames[i]:Hide()
	end
	StaticPopup_Hide("PGF_BLACKLIST")
	PGF_blacklistAddEditBox:SetText("")
	PGF_blacklistAddPlayerButton:SetChecked(false)
	PGF_blacklistAddServerButton:SetChecked(false)
	PGF_blacklistAddKeywordButton:SetChecked(false)
end)

PGF_optionsBlacklist:SetScript("OnShow", function(self)
	if blacklistVarFrames == nil then
		blacklistVarFrames = {}
		for k, v in pairs(PGF_blacklist) do
			PGF_CreateBlacklistVarFrame("Seperator_"..k)
			for i = 1, PGF_GetSize(PGF_blacklist[k]) do
				PGF_CreateBlacklistVarFrame(PGF_blacklist[k][i])
			end
		end
	else
		for i = 1, PGF_GetSize(blacklistVarFrames) do
			blacklistVarFrames[i]:Show()
		end
	end
end)

InterfaceOptions_AddCategory(PGF_optionsBlacklist)