local addon = ...
local L = PGFinderLocals

optionsLists = CreateFrame("Frame", addon .. "KeywordsFrame", InterefaceOPtionsFramePanelContainer)
optionsLists.name = "Lists"
optionsLists.parent = "Premade Group Finder"
optionsLists:Hide()

local title = optionsLists:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
	title:SetPoint("TOP", 0, -16)
	title:SetText(L.OPTIONS_TITLE)
	
local tabinfo = optionsLists:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
	tabinfo:SetPoint("TOPLEFT", 16, -16)
	tabinfo:SetText(L.OPTIONS_INFO_LISTS)
	
	local author = optionsLists:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	author:SetPoint("TOPLEFT", 450, -20)
	author:SetText(L.OPTIONS_AUTHOR)
	
	local version = optionsLists:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	version:SetPoint("TOPLEFT", author, "BOTTOMLEFT", 0, -10)
	version:SetText(L.OPTIONS_VERSION)
	
	local keywordText = optionsLists:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
	keywordText:SetPoint("TOPLEFT", 50, -100)
	keywordText:SetText(L.OPTIONS_KEYWORDS)
	
	local keywordList = CreateFrame("EditBox", "KeywordEditBoxListFrame", optionsLists)
	keywordList:SetAutoFocus(false)
	keywordList:SetMultiLine(true)
	keywordList:EnableMouse(false)
	keywordList:SetFontObject(GameFontNormal)
	keywordList:SetMaxLetters(999999)
	keywordList:SetHeight(250)
	keywordList:SetWidth(165)
	keywordList:SetJustifyV("TOP")
	keywordList:SetJustifyH("LEFT")
	keywordList:Show()
	
	local keywordScroll = CreateFrame("ScrollFrame", "KeywordScrollFrame", optionsLists, "UIPanelScrollFrameTemplate")
	keywordScroll:SetSize(165, 280)
	keywordScroll:SetPoint("TOPLEFT", keywordText, "TOPLEFT", -20, -30)
	keywordScroll:SetScrollChild(keywordList)
	
	local keywordListBackdrop = CreateFrame("Frame", "KeywordListBackdrop", optionsLists)
	keywordListBackdrop:SetBackdrop({
		bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
		edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
		tile = true, tileSize = 16, edgeSize = 16,
		insets = {left = 3, right = 3, top = 3, bottom = 3}
	})
	keywordListBackdrop:SetBackdropColor(0, 0, 0, 1)
	keywordListBackdrop:SetSize(180, 300)
	keywordListBackdrop:SetPoint("TOPLEFT", keywordText, "TOPLEFT", -30, -20)
	
	local keywordEdit = CreateFrame("EditBox", "KeywordEditBox", optionsLists, "InputBoxTemplate")
	keywordEdit:SetPoint("TOPLEFT", keywordText, "BOTTOMLEFT", -15, -320)
	keywordEdit:SetAutoFocus(false)
	keywordEdit:SetSize(150, 20)
	keywordEdit:SetText("")
	keywordEdit:SetScript("OnEscapePressed", function (frame)
		frame:SetText("")
		frame:ClearFocus()
	end)
	keywordEdit:SetScript("OnEnterPressed", function(frame)
		KeywordButton:Click()
	end)
	
	local keywordButton = CreateFrame("Button", "KeywordButton", optionsLists, "UIPanelButtonTemplate")
	keywordButton:SetSize(155, 20)
	keywordButton:SetPoint("TOPLEFT", keywordEdit, "TOPLEFT", -5, -25)
	keywordButton:SetText(L.OPTIONS_BUTTON_TEXT)
	keywordButton:HookScript("OnClick", function(frame)
		if keywordEdit:GetText() ~= nil then
			local keyword = string.lower(keywordEdit:GetText())
			local exists = contains(keywords, keyword)
			if keyword ~= nil and keyword ~= "" and not exists then
				updateList(keywords, keyword, true)
				keywordList:SetText(toString(keywords))
			elseif keyword ~= nil and keyword ~= "" and exists then
				updateList(keywords, keyword, false)
				keywordList:SetText(toString(keywords))
			end
			keywordEdit:SetText("")
		end
	end)
	
	local friendText = optionsLists:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
	friendText:SetPoint("TOPLEFT", 290, -100)
	friendText:SetText(L.OPTIONS_FRIENDS)
	
	local friendList = CreateFrame("EditBox", "FriendEditBoxListFrame", optionsLists)
	friendList:SetAutoFocus(false)
	friendList:SetMultiLine(true)
	friendList:EnableMouse(false)
	friendList:SetFontObject(GameFontNormal)
	friendList:SetMaxLetters(999999)
	friendList:SetHeight(250)
	friendList:SetWidth(165)
	friendList:SetJustifyV("TOP")
	friendList:SetJustifyH("LEFT")
	friendList:Show()
	
	local friendScroll = CreateFrame("ScrollFrame", "FriendScrollFrame", optionsLists, "UIPanelScrollFrameTemplate")
	friendScroll:SetSize(165, 280)
	friendScroll:SetPoint("TOPLEFT", friendText, "TOPLEFT", -35, -30)
	friendScroll:SetScrollChild(friendList)
	
	local friendListBackdrop = CreateFrame("Frame", "FriendListBackdrop", optionsLists)
	friendListBackdrop:SetBackdrop({
		bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
		edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
		tile = true, tileSize = 16, edgeSize = 16,
		insets = {left = 3, right = 3, top = 5, bottom = 3}
	})
	friendListBackdrop:SetBackdropColor(0, 0, 0, 1)
	friendListBackdrop:SetSize(180, 300)
	friendListBackdrop:SetPoint("TOPLEFT", friendText, "TOPLEFT", -45, -20)
	
	local friendEdit = CreateFrame("EditBox", "FriendEditBox", optionsLists, "InputBoxTemplate")
	friendEdit:SetPoint("TOPLEFT", friendText, "BOTTOMLEFT", -25, -320)
	friendEdit:SetAutoFocus(false)
	friendEdit:SetSize(150, 20)
	friendEdit:SetText("")
	friendEdit:SetScript("OnEscapePressed", function (frame)
		frame:SetText("")
		frame:ClearFocus()
	end)
	friendEdit:SetScript("OnEnterPressed", function(frame)
		FriendButton:Click()
	end)
	
	local friendButton = CreateFrame("Button", "FriendButton", optionsLists, "UIPanelButtonTemplate")
	friendButton:SetSize(155, 20)
	friendButton:SetPoint("TOPLEFT", friendEdit, "TOPLEFT", -5, -25)
	friendButton:SetText(L.OPTIONS_BUTTON_TEXT)
	friendButton:HookScript("OnClick", function(frame)
		if friendEdit:GetText() ~= nil then
			local friend = string.lower(friendEdit:GetText())
			local exists = contains(friends, friend)
			if friend ~= nil and friend ~= "" and not exists then
				updateList(friends, friend, true)
				friendList:SetText(toString(friends))
			elseif friend ~= nil and friend ~= "" and exists then
				updateList(friends, friend, false)
				friendList:SetText(toString(friends))
			end
			friendEdit:SetText("")
		end
	end)
	local listInfoText = optionsLists:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
		listInfoText:SetPoint("TOPLEFT", 20, -490)
		listInfoText:SetSize(500, 50)
		listInfoText:SetWordWrap(true)
		listInfoText:SetText(L.INFO_LISTS)
function updateKeywordList()
	keywordList:SetText(toString(keywords))
end
function updateFriendList()
	friendList:SetText(toString(friends))
end
	optionsLists:SetScript("OnShow", function(optionsLists)
		updateKeywordList()
		updateFriendList()
	end)

InterfaceOptions_AddCategory(optionsLists)