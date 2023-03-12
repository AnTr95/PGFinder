local addon = ...
local L = PGFinderLocals
local activeKeywordFrames = nil
local inactiveKeywordFrames = nil
local markedKeywords = {}

PGF_optionsKeywords = CreateFrame("Frame", "PGF_optionsKeyword", InterfaceOptionsFramePanelContainer)
PGF_optionsKeywords.name = "Keywords"
PGF_optionsKeywords.parent = "Premade Group Finder"
PGF_optionsKeywords:Hide()

local ticker = nil
local title = PGF_optionsKeywords:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
title:SetPoint("TOP", 0, -16)
title:SetText(L.OPTIONS_TITLE)

local tabinfo = PGF_optionsKeywords:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
tabinfo:SetPoint("TOPLEFT", 16, -16)
tabinfo:SetText(L.OPTIONS_INFO_LISTS)

local author = PGF_optionsKeywords:CreateFontString(nil, "ARTWORK", "GameFontNormal")
author:SetPoint("TOPLEFT", 450, -20)
author:SetText(L.OPTIONS_AUTHOR)

local version = PGF_optionsKeywords:CreateFontString(nil, "ARTWORK", "GameFontNormal")
version:SetPoint("TOPLEFT", author, "BOTTOMLEFT", 0, -10)
version:SetText(L.OPTIONS_VERSION)

local activeText = PGF_optionsKeywords:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
activeText:SetPoint("TOPLEFT", 40, -80)
activeText:SetText("Active Keywords")

local activeFrameScrollFrame = CreateFrame("ScrollFrame", "PGF_activeFrameScrollFrame", PGF_optionsKeywords, "UIPanelScrollFrameTemplate")
activeFrameScrollFrame:SetSize(210, 320)
activeFrameScrollFrame:SetPoint("TOPLEFT", activeText, "TOPLEFT", -35, -25)

local activeFrame = CreateFrame("Frame")
activeFrame:SetSize(210, 320)
activeFrame:SetPoint("TOPLEFT", activeText, "TOPLEFT", -30, 0)

local activeFrameBackdrop = CreateFrame("Frame", "PGF_activeFrameBackdrop", PGF_optionsKeywords, BackdropTemplateMixin and "BackdropTemplate")
activeFrameBackdrop:SetBackdrop({
	bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
	edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
	tile = true, tileSize = 16, edgeSize = 16,
	insets = {left = 3, right = 3, top = 3, bottom = 3}
})
activeFrameBackdrop:SetBackdropColor(0, 0, 0, 1)
activeFrameBackdrop:SetSize(210, 335)
activeFrameBackdrop:SetPoint("TOPLEFT", activeText, "TOPLEFT", -30, -20)

activeFrameScrollFrame:SetScrollChild(activeFrame)

local toInactiveButton = CreateFrame("Button", "PGF_toInactiveButton", PGF_optionsKeywords, "UIPanelButtonTemplate")
toInactiveButton:SetSize(100, 25)
toInactiveButton:SetPoint("TOPLEFT", 250, -210)
toInactiveButton:SetText("---------->")
toInactiveButton:HookScript("OnClick", function(self)
	local leftOvers = {}
	for i = 1, PGF_GetSize(markedKeywords) do
		local keyword = markedKeywords[i]
		local exists = PGF_Contains(PGF_activeKeywords, keyword)
		if exists then
			PGF_UpdateList(PGF_activeKeywords, keyword, false)
			PGF_UpdateList(PGF_inactiveKeywords, keyword, true)
			PGF_UpdateActiveKeywordList(exists)
			PGF_CreateInactiveKeywordFrame(keyword)
		else
			leftOvers[PGF_GetSize(leftOvers)+1] = keyword
		end
	end
	markedKeywords = leftOvers
end)

local toActiveButton = CreateFrame("Button", "PGF_toActiveButton", PGF_optionsKeywords, "UIPanelButtonTemplate")
toActiveButton:SetSize(100, 25)
toActiveButton:SetPoint("TOPLEFT", 250, -240)
toActiveButton:SetText("<----------")
toActiveButton:HookScript("OnClick", function(self)
	local leftOvers = {}
	local size = PGF_GetSize(markedKeywords)
	for i = 1, size do
		local keyword = markedKeywords[i]
		local exists = PGF_Contains(PGF_inactiveKeywords, keyword)
		if exists then
			PGF_UpdateList(PGF_inactiveKeywords, keyword, false)
			PGF_UpdateList(PGF_activeKeywords, keyword, true)
			PGF_UpdateInactiveKeywordList(exists)
			PGF_CreateActiveKeywordFrame(keyword)
		else
			leftOvers[PGF_GetSize(leftOvers)+1] = keyword
		end
	end
	markedKeywords = leftOvers
end)

local removeButton = CreateFrame("Button", "PGF_removeButton", PGF_optionsKeywords, "UIPanelButtonTemplate")
removeButton:SetSize(100, 20)
removeButton:SetPoint("TOPLEFT", 250, -275)
removeButton:SetText("Remove")
removeButton:HookScript("OnClick", function(self)
	for i = 1, #markedKeywords do
		local keyword = markedKeywords[i]
		local existsActive = PGF_Contains(PGF_activeKeywords, keyword)
		local existsInactive = PGF_Contains(PGF_inactiveKeywords, keyword)
		if existsActive then
			PGF_UpdateList(PGF_activeKeywords, markedKeywords[i], false)
			PGF_UpdateActiveKeywordList(existsActive)
		elseif existsInactive then
			PGF_UpdateList(PGF_inactiveKeywords, markedKeywords[i], false)
			PGF_UpdateInactiveKeywordList(existsInactive)
		end
	end
	markedKeywords = {}
end)

local lastInput = ""
local lastKey = ""
local addEditBox = CreateFrame("EditBox", "PGF_addEditBox", PGF_optionsKeywords, "InputBoxTemplate")
addEditBox:SetPoint("TOPLEFT", 25, -435)
addEditBox:SetAutoFocus(false)
addEditBox:SetSize(180, 20)
addEditBox:SetText("")
addEditBox:SetScript("OnEscapePressed", function (self)
	self:SetText("")
	self:ClearFocus()
end)
addEditBox:SetScript("OnEnterPressed", function(self)
	PGF_addButton:Click()
end)
addEditBox:SetScript("OnTextChanged", function(self, userInput)
	local input = addEditBox:GetText()
	if input ~= nil and input ~= "" and userInput and lastInput ~= input and lastKey ~= "BACKSPACE" then
		local from = input:len()
		lastInput = input
		for profileName, data in pairs(PGF_standardProfiles) do
			for index, keywordName in pairs(data) do
				local suggestion = keywordName:match("^" .. input .."(.*)")
				if suggestion ~= nil then
					addEditBox:SetText(input .. suggestion)
					addEditBox:HighlightText(from)
					return
				end
			end
		end 
	end
end)

addEditBox:SetScript("OnKeyDown", function(self, key)
	lastKey = key
end)

local addButton = CreateFrame("Button", "PGF_addButton", PGF_optionsKeywords, "UIPanelButtonTemplate")
addButton:SetSize(100, 20)
addButton:SetPoint("TOPLEFT", addEditBox, "TOPLEFT", 35, -25)
addButton:SetText("Add")
addButton:HookScript("OnClick", function(self)
	local keyword = string.lower(PGF_addEditBox:GetText())
	keyword = PGF_TrimTail(keyword)
	local existsActive = PGF_Contains(PGF_activeKeywords, keyword)
	local existsInactive = PGF_Contains(PGF_inactiveKeywords, keyword)
	if not existsInactive and not existsActive and keyword ~= nil and keyword ~= "" then
		PGF_UpdateList(PGF_activeKeywords, keyword, true)
		PGF_CreateActiveKeywordFrame(keyword)
		PGF_addEditBox:SetText("")
	end
end)

local inactiveText = PGF_optionsKeywords:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
inactiveText:SetPoint("TOPLEFT", 415, -80)
inactiveText:SetText("Inactive Keywords")

local inactiveFrameScrollFrame = CreateFrame("ScrollFrame", "PGF_inactiveFrameScrollFrame", PGF_optionsKeywords, "UIPanelScrollFrameTemplate")
inactiveFrameScrollFrame:SetSize(210, 320)
inactiveFrameScrollFrame:SetPoint("TOPLEFT", inactiveText, "TOPLEFT", -35, -25)

local inactiveFrame = CreateFrame("Frame")
inactiveFrame:SetSize(210, 320)
inactiveFrame:SetPoint("TOPLEFT", inactiveText, "TOPLEFT", -30, 0)

local inactiveFrameBackdrop = CreateFrame("Frame", "PGF_inactiveFrameBackdrop", PGF_optionsKeywords, BackdropTemplateMixin and "BackdropTemplate")
inactiveFrameBackdrop:SetBackdrop({
	bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
	edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
	tile = true, tileSize = 16, edgeSize = 16,
	insets = {left = 3, right = 3, top = 3, bottom = 3}
})
inactiveFrameBackdrop:SetBackdropColor(0, 0, 0, 1)
inactiveFrameBackdrop:SetSize(210, 335)
inactiveFrameBackdrop:SetPoint("TOPLEFT", inactiveText, "TOPLEFT", -30, -20)

inactiveFrameScrollFrame:SetScrollChild(inactiveFrame)

function PGF_CreateActiveKeywordFrame(keyword)
	local keywordFrame = CreateFrame("Frame", "PGF_KeywordFrame_"..keyword, activeFrame)
	keywordFrame:SetSize(250, 30)
	keywordFrame:SetPoint("TOPLEFT", activeFrame, "TOPLEFT", 0, -(20*(PGF_GetSize(activeKeywordFrames))))

	local keywordFrameCheckButton = CreateFrame("CheckButton", "PGF_KeywordFrameCheckButton_"..keyword, keywordFrame, "UICheckButtonTemplate")
	keywordFrameCheckButton:SetPoint("TOPLEFT", keywordFrame, "TOPLEFT", 10, 0)
	keywordFrameCheckButton:SetSize(20, 20)
	keywordFrameCheckButton:SetScript("OnClick", function(self)
		if self:GetChecked() then
			markedKeywords[#markedKeywords+1] = keyword
		else
			if PGF_Contains(markedKeywords, keyword) then
				PGF_UpdateList(markedKeywords, keyword, false)
			end
		end
	end)
	local keywordFrameText = keywordFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	keywordFrameText:SetPoint("TOPLEFT", keywordFrameCheckButton, "TOPLEFT", 23, -2)
	keywordFrameText:SetText(keyword)
	keywordFrameText:SetWordWrap(true)
	activeKeywordFrames[PGF_GetSize(activeKeywordFrames)+1] = keywordFrame
	keywordFrame:Show()
end

function PGF_CreateInactiveKeywordFrame(keyword)
	local keywordFrame = CreateFrame("Frame", "PGF_KeywordFrame_"..keyword, inactiveFrame)
	keywordFrame:SetSize(250, 30)
	keywordFrame:SetPoint("TOPLEFT", inactiveFrame, "TOPLEFT", 0, -(20*(PGF_GetSize(inactiveKeywordFrames))))

	local keywordFrameCheckButton = CreateFrame("CheckButton", "PGF_KeywordFrameCheckButton_"..keyword, keywordFrame, "UICheckButtonTemplate")
	keywordFrameCheckButton:SetPoint("TOPLEFT", keywordFrame, "TOPLEFT", 10, 0)
	keywordFrameCheckButton:SetSize(20, 20)
	keywordFrameCheckButton:SetScript("OnClick", function(self)
		if self:GetChecked() then
			markedKeywords[#markedKeywords+1] = keyword
		else
			if PGF_Contains(markedKeywords, keyword) then
				PGF_UpdateList(markedKeywords, keyword, false)
			end
		end
	end)
	local keywordFrameText = keywordFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	keywordFrameText:SetPoint("TOPLEFT", keywordFrameCheckButton, "TOPLEFT", 23, -2)
	keywordFrameText:SetText(keyword)
	keywordFrameText:SetWordWrap(true)
	inactiveKeywordFrames[PGF_GetSize(inactiveKeywordFrames)+1] = keywordFrame
	keywordFrame:Show()
end

function PGF_UpdateActiveKeywordList(index)
	for i = index+1, PGF_GetSize(activeKeywordFrames) do
		local keywordFrame = activeKeywordFrames[i]
		keywordFrame:SetPoint("TOPLEFT", activeFrame, "TOPLEFT", 0, -(20*(i-2)))
	end
	activeKeywordFrames[index]:Hide()
	PGF_UpdateList(activeKeywordFrames, activeKeywordFrames[index], false)
end

function PGF_UpdateInactiveKeywordList(index)
	for i = index+1, PGF_GetSize(inactiveKeywordFrames) do
		local keywordFrame = inactiveKeywordFrames[i]
		keywordFrame:SetPoint("TOPLEFT", inactiveFrame, "TOPLEFT", 0, -(20*(i-2)))
	end
	inactiveKeywordFrames[index]:Hide()
	PGF_UpdateList(inactiveKeywordFrames, inactiveKeywordFrames[index], false)
end

PGF_optionsKeywords:SetScript("OnShow", function(self)
	if activeKeywordFrames == nil then
		activeKeywordFrames = {}
		for i = 1, PGF_GetSize(PGF_activeKeywords) do
			PGF_CreateActiveKeywordFrame(PGF_activeKeywords[i])
		end
	else
		for i = 1, PGF_GetSize(PGF_activeKeywords) do
			activeKeywordFrames[i]:Show()
		end
	end
	if inactiveKeywordFrames == nil then
		inactiveKeywordFrames = {}
		for i = 1, PGF_GetSize(PGF_inactiveKeywords) do
			PGF_CreateInactiveKeywordFrame(PGF_inactiveKeywords[i])
		end
	else
		for i = 1, PGF_GetSize(PGF_inactiveKeywords) do
			inactiveKeywordFrames[i]:Show()
		end
	end
end)

local listInfoText = PGF_optionsKeywords:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
listInfoText:SetPoint("TOPLEFT", 20, -490)
listInfoText:SetSize(500, 50)
listInfoText:SetWordWrap(true)
listInfoText:SetText(L.INFO_KEYWORDS_INFO)

PGF_optionsKeywords:SetScript("OnHide", function(self)
	for i = 1, PGF_GetSize(PGF_activeKeywords) do
		activeKeywordFrames[i]:Hide()
	end
	for i = 1, PGF_GetSize(PGF_inactiveKeywords) do
		inactiveKeywordFrames[i]:Hide()
	end
	lastKey = ""
	lastInput = ""
end)

function PGF_ResetKeywordFrames()
	inactiveKeywordFrames = nil
	activeKeywordFrames = nil
end

function PGF_HideActiveKeywordFrames()
	for i = 1, PGF_GetSize(PGF_activeKeywords) do
		activeKeywordFrames[i]:Hide()
	end
end

InterfaceOptions_AddCategory(PGF_optionsKeywords)