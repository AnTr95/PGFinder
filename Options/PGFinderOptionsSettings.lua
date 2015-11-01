local addon = ...
local L = PGFinderLocals

optionsSettings = CreateFrame("Frame", addon .. "SettingsFrame", InterefaceOPtionsFramePanelContainer)
optionsSettings.name = "Settings"
optionsSettings.parent = "Premade Group Finder"
optionsSettings:Hide()

local title = optionsSettings:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
	title:SetPoint("TOP", 0, -16)
	title:SetText(L.OPTIONS_TITLE)
	
local tabinfo = optionsSettings:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
	tabinfo:SetPoint("TOPLEFT", 16, -16)
	tabinfo:SetText(L.OPTIONS_INFO_SETTINGS)
	
	local author = optionsSettings:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	author:SetPoint("TOPLEFT", 450, -20)
	author:SetText(L.OPTIONS_AUTHOR)
	
	local version = optionsSettings:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	version:SetPoint("TOPLEFT", author, "BOTTOMLEFT", 0, -10)
	version:SetText(L.OPTIONS_VERSION)

	local enabledButton = CreateFrame("CheckButton", "EnabledCheckButton", optionsSettings, "OptionsCheckButtonTemplate")
	enabledButton:SetSize(26, 26)
	enabledButton:SetPoint("TOPLEFT", 30, -90)
	enabledButton:HookScript("OnClick", function(frame)
		if frame:GetChecked() then
			ENABLED = true
			PlaySound("igMainMenuOptionCheckBoxOn")
			DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00" .. L.WARNING_ENABLED_TEXT)
		else
			ENABLED = false
			PlaySound("igMainMenuOptionCheckBoxOff")
			DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000" .. L.WARNING_DISABLED_TEXT)
		end
	end)
	
	local enabledText = optionsSettings:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	enabledText:SetPoint("TOPLEFT", enabledButton, "TOPLEFT", 30, -7)
	enabledText:SetText(L.OPTIONS_ENABLED)
	
	local auto_signButton = CreateFrame("CheckButton", "Auto_SignCheckButton", optionsSettings, "OptionsCheckButtonTemplate")
	auto_signButton:SetSize(26, 26)
	auto_signButton:SetPoint("TOPLEFT", 30, -120)
	auto_signButton:HookScript("OnClick", function(frame)
		if frame:GetChecked() then
			AUTO_SIGN = true
			if not SOUND_NOTIFICATION and not WHISPER_NOTIFICATION and not GUILD_NOTIFICATION and not POPUP_NOTIFICATION and not ENABLED then
				ENABLED = true
				enabledButton:SetChecked(ENABLED)
				DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00" .. L.WARNING_ENABLED_TEXT)
			end
			PlaySound("igMainMenuOptionCheckBoxOn")
		else
			AUTO_SIGN = false
			if not SOUND_NOTIFICATION and not WHISPER_NOTIFICATION and not GUILD_NOTIFICATION and not POPUP_NOTIFICATION and ENABLED then
				ENABLED = false
				enabledButton:SetChecked(ENABLED)
				DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000" .. L.WARNING_DISABLED_TEXT)
			end
			PlaySound("igMainMenuOptionCheckBoxOff")
		end
	end)
	
	local auto_signText = optionsSettings:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	auto_signText:SetPoint("TOPLEFT", auto_signButton, "TOPLEFT", 30, -7)
	auto_signText:SetText(L.OPTIONS_AUTO_SIGN)
	
	local search_loginButton = CreateFrame("CheckButton", "search_loginCheckButton", optionsSettings, "OptionsCheckButtonTemplate")
	search_loginButton:SetSize(26, 26)
	search_loginButton:SetPoint("TOPLEFT", 30, -150)
	search_loginButton:HookScript("OnClick", function(frame)
		if frame:GetChecked() then
			SEARCH_LOGIN = true
			PlaySound("igMainMenuOptionCheckBoxOn")
		else
			SEARCH_LOGIN = false
			PlaySound("igMainMenuOptionCheckBoxOff")
		end
	end)
	
	local search_loginText = optionsSettings:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	search_loginText:SetPoint("TOPLEFT", search_loginButton, "TOPLEFT", 30, -7)
	search_loginText:SetText(L.OPTIONS_SEARCH_LOGIN_TEXT)
	
	local notificationText = optionsSettings:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
	notificationText:SetPoint("TOPLEFT", 200, -75)
	notificationText:SetText(L.OPTIONS_NOTIFICATIONS)
	
	local whisperButton = CreateFrame("CheckButton", "WhisperCheckButton", optionsSettings, "OptionsCheckButtonTemplate")
	whisperButton:SetSize(26, 26)
	whisperButton:SetPoint("TOPLEFT", 200, -90)
	whisperButton:HookScript("OnClick", function(frame)
		if frame:GetChecked() then
			WHISPER_NOTIFICATION = true
			if not AUTO_SIGN and not SOUND_NOTIFICATION and not GUILD_NOTIFICATION and not POPUP_NOTIFICATION and not ENABLED then
				ENABLED = true
				enabledButton:SetChecked(ENABLED)
				DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00" .. L.WARNING_ENABLED_TEXT)
			end
			PlaySound("igMainMenuOptionCheckBoxOn")
		else
			WHISPER_NOTIFICATION = false
			if not SOUND_NOTIFICATION and not AUTO_SIGN and not GUILD_NOTIFICATION and not POPUP_NOTIFICATION and ENABLED then
				ENABLED = false
				enabledButton:SetChecked(ENABLED)
				DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000" .. L.WARNING_DISABLED_TEXT)
			end
			PlaySound("igMainMenuOptionCheckBoxOff")
		end
	end)
	
	local whisperText = optionsSettings:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	whisperText:SetPoint("TOPLEFT", whisperButton, "TOPLEFT", 30, -7)
	whisperText:SetText(L.OPTIONS_WHISPER_NOTIFICATION)
	
	local soundButton = CreateFrame("CheckButton", "SoundCheckButton", optionsSettings, "OptionsCheckButtonTemplate")
	soundButton:SetSize(26, 26)
	soundButton:SetPoint("TOPLEFT", 200, -120)
	soundButton:HookScript("OnClick", function(frame)
		if frame:GetChecked() then
			SOUND_NOTIFICATION = true
			if not AUTO_SIGN and not WHISPER_NOTIFICATION and not GUILD_NOTIFICATION and not POPUP_NOTIFICATION and not ENABLED then
				ENABLED = true
				enabledButton:SetChecked(ENABLED)
				DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00" .. L.WARNING_ENABLED_TEXT)
			end
			PlaySound("igMainMenuOptionCheckBoxOn")
		else
			SOUND_NOTIFICATION = false
			if not AUTO_SIGN and not WHISPER_NOTIFICATION and not GUILD_NOTIFICATION and not POPUP_NOTIFICATION and ENABLED then
				ENABLED = false
				enabledButton:SetChecked(ENABLED)
				DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000" .. L.WARNING_DISABLED_TEXT)
			end
			PlaySound("igMainMenuOptionCheckBoxOff")
		end
	end)
	
	local soundText = optionsSettings:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	soundText:SetPoint("TOPLEFT", soundButton, "TOPLEFT", 30, -7)
	soundText:SetText(L.OPTIONS_SOUND_NOTIFICATION)
	
	local guildButton = CreateFrame("CheckButton", "guildCheckButton", optionsSettings, "OptionsCheckButtonTemplate")
	guildButton:SetSize(26, 26)
	guildButton:SetPoint("TOPLEFT", 200, -150)
	guildButton:HookScript("OnClick", function(frame)
		if frame:GetChecked() then
			GUILD_NOTIFICATION = true
			if not AUTO_SIGN and not WHISPER_NOTIFICATION and not SOUND_NOTIFICATION and not POPUP_NOTIFICATION and not ENABLED then
				ENABLED = true
				enabledButton:SetChecked(ENABLED)
				DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00" .. L.WARNING_ENABLED_TEXT)
			end
			PlaySound("igMainMenuOptionCheckBoxOn")
		else
			GUILD_NOTIFICATION = false
			if not AUTO_SIGN and not WHISPER_NOTIFICATION and not SOUND_NOTIFICATION and not POPUP_NOTIFICATION and ENABLED then
				ENABLED = false
				enabledButton:SetChecked(ENABLED)
				DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000" .. L.WARNING_DISABLED_TEXT)
			end
			PlaySound("igMainMenuOptionCheckBoxOff")
		end
	end)
	
	guildText = optionsSettings:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	guildText:SetPoint("TOPLEFT", guildButton, "TOPLEFT", 30, -7)
	guildText:SetText(L.OPTIONS_GUILD_NOTIFICATION_TEXT)
	
	local popupButton = CreateFrame("CheckButton", "popupCheckButton", optionsSettings, "OptionsCheckButtonTemplate")
	popupButton:SetSize(26, 26)
	popupButton:SetPoint("TOPLEFT", 200, -180)
	popupButton:HookScript("OnClick", function(frame)
		if frame:GetChecked() then
			POPUP_NOTIFICATION = true
			if not AUTO_SIGN and not WHISPER_NOTIFICATION and not SOUND_NOTIFICATION and not GUILD_NOTIFICATION and not ENABLED then
				ENABLED = true
				enabledButton:SetChecked(ENABLED)
				DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00" .. L.WARNING_ENABLED_TEXT)
			end
			PlaySound("igMainMenuOptionCheckBoxOn")
		else
			POPUP_NOTIFICATION = false
			if not AUTO_SIGN and not WHISPER_NOTIFICATION and not SOUND_NOTIFICATION and not GUILD_NOTIFICATION and ENABLED then
				ENABLED = false
				enabledButton:SetChecked(ENABLED)
				DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000" .. L.WARNING_DISABLED_TEXT)
			end
			PlaySound("igMainMenuOptionCheckBoxOff")
		end
		
	end)
	local popupText = optionsSettings:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	popupText:SetPoint("TOPLEFT", popupButton, "TOPLEFT", 30, -7)
	popupText:SetText(L.OPTIONS_POPUP)
	
	local configText = optionsSettings:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
	configText:SetPoint("TOPLEFT", 380, -75)
	configText:SetText(L.OPTIONS_CONFIG)
	
	local intervalText = optionsSettings:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	intervalText:SetPoint("TOPLEFT", 380, -90)
	intervalText:SetText(L.OPTIONS_INTERVAL)
	
	local intervalEdit = CreateFrame("EditBox", "IntervalEditBox", optionsSettings, "InputBoxTemplate")
	intervalEdit:SetPoint("TOPLEFT", intervalText, "TOPLEFT", 5, -15)
	intervalEdit:SetAutoFocus(false)
	intervalEdit:EnableMouse(true)
	intervalEdit:SetSize(50, 20)
	intervalEdit:SetMaxLetters(4)
	intervalEdit:SetScript("OnEscapePressed", function(frame)
		frame:ClearFocus()
	end)
	intervalEdit:SetScript("OnEnterPressed", function(frame)
		local value = frame:GetNumber()
		if value > 0 then
			INTERVAL = value
		end
		frame:ClearFocus()
	end)
	
	local roleText = optionsSettings:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
	roleText:SetPoint("TOPLEFT", intervalText, "TOPLEFT", 0, -45)
	roleText:SetText(L.OPTIONS_ROLE)
	
	local dpsText = optionsSettings:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	dpsText:SetPoint("TOPLEFT", roleText, "TOPLEFT", 0, -15)
	dpsText:SetText("DPS")
	
	local dpsButton = CreateFrame("CheckButton", "DPSCheckButton", optionsSettings, "OptionsCheckButtonTemplate")
	dpsButton:SetSize(20, 20)
	dpsButton:SetPoint("TOPLEFT", dpsText, "TOPLEFT", 45, 5)
	dpsButton:HookScript("OnClick", function(frame)
		if frame:GetChecked() then
			ROLES.DPS = true
			PlaySound("igMainMenuOptionCheckBoxOn")
		else
			ROLES.DPS = false
			PlaySound("igMainMenuOptionCheckBoxOff")
		end
	end)
	
	local healerText = optionsSettings:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	healerText:SetPoint("TOPLEFT", dpsText, "TOPLEFT", 0, -20)
	healerText:SetText("Healer")
	
	local healerButton = CreateFrame("CheckButton", "HealerCheckButton", optionsSettings, "OptionsCheckButtonTemplate")
	healerButton:SetSize(20, 20)
	healerButton:SetPoint("TOPLEFT", healerText, "TOPLEFT", 45, 5)
	healerButton:HookScript("OnClick", function(frame)
		if frame:GetChecked() then
			ROLES.HEALER = true
			PlaySound("igMainMenuOptionCheckBoxOn")
		else
			ROLES.HEALER = false
			PlaySound("igMainMenuOptionCheckBoxOff")
		end
	end)
	
	local tankText = optionsSettings:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	tankText:SetPoint("TOPLEFT", healerText, "TOPLEFT", 0, -20)
	tankText:SetText("Tank")
	
	local tankButton = CreateFrame("CheckButton", "TankCheckButton", optionsSettings, "OptionsCheckButtonTemplate")
	tankButton:SetSize(20, 20)
	tankButton:SetPoint("TOPLEFT", tankText, "TOPLEFT", 45, 5)
	tankButton:HookScript("OnClick", function(frame)
		if frame:GetChecked() then
			ROLES.TANK = true
			PlaySound("igMainMenuOptionCheckBoxOn")
		else
			ROLES.TANK = false
			PlaySound("igMainMenuOptionCheckBoxOff")
		end
	end)
	
	optionsSettings:SetScript("OnShow", function(options)
		intervalEdit:SetText(INTERVAL)
		soundButton:SetChecked(SOUND_NOTIFICATION)
		enabledButton:SetChecked(ENABLED)
		auto_signButton:SetChecked(AUTO_SIGN)
		whisperButton:SetChecked(WHISPER_NOTIFICATION)
		search_loginButton:SetChecked(SEARCH_LOGIN)
		guildButton:SetChecked(GUILD_NOTIFICATION)
		dpsButton:SetChecked(ROLES.DPS)
		healerButton:SetChecked(ROLES.HEALER)
		tankButton:SetChecked(ROLES.TANK)
		popupButton:SetChecked(POPUP_NOTIFICATION)
	end)

InterfaceOptions_AddCategory(optionsSettings)