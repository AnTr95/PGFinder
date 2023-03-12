local addon = ...
local L = PGFinderLocals

PGF_optionsSettings = CreateFrame("Frame", "PGF_optionsSettings", InterfaceOptionsFramePanelContainer)
PGF_optionsSettings.name = "Settings"
PGF_optionsSettings.parent = "Premade Group Finder"
PGF_optionsSettings:Hide()

local title = PGF_optionsSettings:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
title:SetPoint("TOP", 0, -16)
title:SetText(L.OPTIONS_TITLE)
	
local tabinfo = PGF_optionsSettings:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
tabinfo:SetPoint("TOPLEFT", 16, -16)
tabinfo:SetText(L.OPTIONS_INFO_SETTINGS)

local author = PGF_optionsSettings:CreateFontString(nil, "ARTWORK", "GameFontNormal")
author:SetPoint("TOPLEFT", 450, -20)
author:SetText(L.OPTIONS_AUTHOR)

local version = PGF_optionsSettings:CreateFontString(nil, "ARTWORK", "GameFontNormal")
version:SetPoint("TOPLEFT", author, "BOTTOMLEFT", 0, -10)
version:SetText(L.OPTIONS_VERSION)

local enabledButton = CreateFrame("CheckButton", "PGF_settingsEnabledCheckButton", PGF_optionsSettings, "UICheckButtonTemplate")
enabledButton:SetSize(26, 26)
enabledButton:SetPoint("TOPLEFT", 30, -90)
enabledButton:HookScript("OnClick", function(self)
	if self:GetChecked() then
		PGF_enabled = true
		if PGF_changeMinimapColor then
			PGF_MinimapButton_SetGreen(PGF_minimapButton)
		end
		PlaySound(856)
		DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00" .. L.WARNING_ENABLED_TEXT)
	else
		PGF_enabled = false
		if PGF_changeMinimapColor then
			PGF_MinimapButton_SetRed(PGF_minimapButton)
		end
		PlaySound(857)
		DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000" .. L.WARNING_DISABLED_TEXT)
	end
end)

local enabledText = PGF_optionsSettings:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
enabledText:SetPoint("TOPLEFT", enabledButton, "TOPLEFT", 30, -7)
enabledText:SetText(L.OPTIONS_ENABLED)

	--[[local auto_signButton = CreateFrame("CheckButton", "Auto_SignCheckButton", PGF_optionsSettings, "UICheckButtonTemplate")
	auto_signButton:SetSize(26, 26)
	auto_signButton:SetPoint("TOPLEFT", 30, -120)
	auto_signButton:HookScript("OnClick", function(self)
		if self:GetChecked() then
			PGF_autoSign = true
			if not PGF_notification_sound and not PGF_notification_whisper and not PGF_notification_guild and not PGF_notification_popup and not PGF_notification_flashTaskbar and not PGF_enabled then
				PGF_enabled = true
				enabledButton:SetChecked(PGF_enabled)
				DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00" .. L.WARNING_ENABLED_TEXT)
			end
			PlaySound(856)
		else
			PGF_autoSign = false
			if not PGF_notification_sound and not PGF_notification_whisper and not PGF_notification_guild and not PGF_notification_popup and not PGF_notification_flashTaskbar and PGF_enabled then
				PGF_enabled = false
				enabledButton:SetChecked(PGF_enabled)
				DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000" .. L.WARNING_DISABLED_TEXT)
			end
			PlaySound(857)
		end
	end)]]
	
local auto_signText = PGF_optionsSettings:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
auto_signText:SetPoint("TOPLEFT", 32, -157)
auto_signText:SetText(L.OPTIONS_AUTO_SIGN)

local auto_signStateMenu = CreateFrame("Button", "PGF_options_autoSignDropDownMenu", PGF_optionsSettings, "UIDropDownMenuTemplate")
auto_signStateMenu:SetPoint("TOPLEFT", auto_signText, "TOPLEFT", -18, -20)
local autoSignStates = {"Always", "While not in a group", "Never"}
local function Initialize_AutoSignState(self, level)
	local info = UIDropDownMenu_CreateInfo()
	for k,v in pairs(autoSignStates) do
	  info = UIDropDownMenu_CreateInfo()
	  info.text = v
	  info.value = v
	  info.func = PGF_AutoSignState_OnClick
	  UIDropDownMenu_AddButton(info, level)
	end
end

function PGF_AutoSignState_OnClick(self)
	UIDropDownMenu_SetSelectedID(auto_signStateMenu, self:GetID())
	PGF_autoSignState = self:GetText()
	if PGF_autoSignState == "Always" or PGF_autoSignState == "While not in a group" then
		PGF_autoSign = true
		if not PGF_notification_whisper and not PGF_notification_sound and not PGF_notification_guild and not PGF_notification_popup and not PGF_notification_flashTaskbar and not PGF_enabled then
			PGF_enabled = true
			enabledButton:SetChecked(PGF_enabled)
			DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00" .. L.WARNING_ENABLED_TEXT)
		end
	else
		PGF_autoSign = false
		if not PGF_notification_sound and not PGF_notification_whisper and not PGF_notification_guild and not PGF_notification_popup and not PGF_notification_flashTaskbar and PGF_enabled then
			PGF_enabled = false
			enabledButton:SetChecked(PGF_enabled)
			DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000" .. L.WARNING_DISABLED_TEXT)
		end
	end
end

UIDropDownMenu_SetWidth(auto_signStateMenu, 130)
UIDropDownMenu_SetButtonWidth(auto_signStateMenu, 130)
UIDropDownMenu_JustifyText(auto_signStateMenu, "CENTER")
UIDropDownMenu_Initialize(auto_signStateMenu, Initialize_AutoSignState)

--[[
local search_loginButton = CreateFrame("CheckButton", "PGF_settingsSearchLoginCheckButton", PGF_optionsSettings, "UICheckButtonTemplate")
search_loginButton:SetSize(26, 26)
search_loginButton:SetPoint("TOPLEFT", 30, -120)
search_loginButton:HookScript("OnClick", function(self)
	if self:GetChecked() then
		PGF_searchLogin = true
		PlaySound(856)
	else
		PGF_searchLogin = false
		PlaySound(857)
	end
end)

local search_loginText = PGF_optionsSettings:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
search_loginText:SetPoint("TOPLEFT", search_loginButton, "TOPLEFT", 30, -7)
search_loginText:SetText(L.OPTIONS_SEARCH_LOGIN_TEXT)
]]
	--[[local minimapButton = CreateFrame("CheckButton", "PGF_options_minimapCheckButton", PGF_optionsSettings, "UICheckButtonTemplate")
	minimapButton:SetSize(26, 26)
	minimapButton:SetPoint("TOPLEFT", 30, -180)
	minimapButton:HookScript("OnClick", function(self)
		if self:GetChecked() then
			PGF_minimapButtonMode = true
			PGF_minimapButton:Show()
			PlaySound(856)
		else
			PGF_minimapButtonMode = false
			PGF_minimapButton:Hide()
			PlaySound(857)
		end
	end) ]]

local minimapText = PGF_optionsSettings:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
minimapText:SetPoint("TOPLEFT", 32, -217)
minimapText:SetText(L.OPTIONS_MINIMAP_TEXT)
local minimapStateMenu = CreateFrame("Button", "PGF_options_minimapDropDownMenu", PGF_optionsSettings, "UIDropDownMenuTemplate")
minimapStateMenu:SetPoint("TOPLEFT", minimapText, "TOPLEFT", -18, -15)
local minimapStates = {"Always", "On Hover", "Never"}
local function Initialize_MinimapState(self, level)
	local info = UIDropDownMenu_CreateInfo()
	for k,v in pairs(minimapStates) do
	  info = UIDropDownMenu_CreateInfo()
	  info.text = v
	  info.value = v
	  info.func = PGF_MinimapState_OnClick
	  UIDropDownMenu_AddButton(info, level)
	end
end
function PGF_MinimapState_OnClick(self)
	UIDropDownMenu_SetSelectedID(minimapStateMenu, self:GetID())
	PGF_minimapButtonMode = self:GetText()
	if PGF_minimapButtonMode == "Always" then
		PGF_minimapButton:Show()
	else
		PGF_minimapButton:Hide()
	end
end

UIDropDownMenu_SetWidth(minimapStateMenu, 130)
UIDropDownMenu_SetButtonWidth(minimapStateMenu, 130)
UIDropDownMenu_JustifyText(minimapStateMenu, "CENTER")
UIDropDownMenu_Initialize(minimapStateMenu, Initialize_MinimapState)

local changeColorButton = CreateFrame("CheckButton", "PGF_settingsChangeColorButton", PGF_optionsSettings, "UICheckButtonTemplate")
changeColorButton:SetSize(26, 26)
changeColorButton:SetPoint("TOPLEFT", 30, -270)
changeColorButton:HookScript("OnClick", function(self)
	if self:GetChecked() then
		PGF_changeMinimapColor = true 
		if PGF_enabled then
			PGF_MinimapButton_SetGreen()
		else
			PGF_MinimapButton_SetRed()
		end
		PlaySound(856)
	else
		PGF_changeMinimapColor = false
		PGF_MinimapButton_SetBlue()
		PlaySound(857)
	end
end)

local changeColorText = PGF_optionsSettings:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
changeColorText:SetPoint("TOPLEFT", changeColorButton, "TOPLEFT", 30, -7)
changeColorText:SetText(L.OPTIONS_MINIMAP_COLOR_TEXT)

local searchBindingText = PGF_optionsSettings:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
searchBindingText:SetPoint("TOPLEFT", 30, -310)
searchBindingText:SetText(L.OPTIONS_SEARCH_BINDING_TEXT)
local detectingKeypress = false
local searchBindingButton = CreateFrame("Button", "PGF_settingsSearchBindingButton", PGF_optionsSettings, "UIPanelButtonTemplate")
searchBindingButton:SetSize(130, 30)
searchBindingButton:SetPoint("TOPLEFT", searchBindingText, "TOPLEFT", 0, -20)
searchBindingButton:SetText(L.OPTIONS_SEARCH_BINDING_DEFAULT)
searchBindingButton:HookScript("OnClick", function(self)
	searchBindingButton:SetText("Press a key")
	detectingKeypress = true
end)
searchBindingButton:SetScript("OnKeyDown", function(self, key)
	if detectingKeypress then
		if key == "ESCAPE" then
			detectingKeypress = false
			searchBindingButton:SetText(PGF_SearchBinding and PGF_SearchBinding or L.OPTIONS_SEARCH_BINDING_DEFAULT)
		elseif key ~= "LSHIFT" and key ~= "RSHIFT" and key ~= "LCTRL" and key ~= "RCTRL" and key ~= "LALT" and key ~= "RALT" then
			local bind = ""
			if IsShiftKeyDown() then
				bind = "SHIFT-"
			end
			if IsControlKeyDown() then
				bind = "CTRL-"
			end
			if IsAltKeyDown() then
				bind = "ALT-"
			end
			bind = bind .. key
			detectingKeypress = false
			if PGF_SearchBinding then
				SetBinding(PGF_SearchBinding) --Unbind
			end
			PGF_SearchBinding = bind
			searchBindingButton:SetText(bind)
			PGF_SetSearchBinding()
		end
	end
end)
searchBindingButton:SetPropagateKeyboardInput(true)
searchBindingButton:EnableKeyboard(true)

	--[[local minimapText = PGF_optionsSettings:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	minimapText:SetPoint("TOPLEFT", minimapButton, "TOPLEFT", 30, -7)
	minimapText:SetText(L.OPTIONS_MINIMAP_TEXT)]]

local minimapReset = CreateFrame("Button", "PGF_options_minimapResetCheckButton", PGF_optionsSettings, "UIPanelButtonTemplate")
minimapReset:SetSize(160, 25)
minimapReset:SetPoint("TOPLEFT", 30, -530)
minimapReset:SetText(L.OPTIONS_MINIMAP_RESET)
minimapReset:HookScript("OnClick", function(self)
	PGF_minimapDegree = 30
	PGF_SetMinimapPoint(PGF_minimapDegree)
end)

local notificationText = PGF_optionsSettings:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
notificationText:SetPoint("TOPLEFT", 200, -75)
notificationText:SetText(L.OPTIONS_NOTIFICATIONS)

	--[[local whisperButton = CreateFrame("CheckButton", "PGF_settingsWhisperCheckButton", PGF_optionsSettings, "UICheckButtonTemplate")
	whisperButton:SetSize(26, 26)
	whisperButton:SetPoint("TOPLEFT", 200, -90)
	whisperButton:HookScript("OnClick", function(self)
		if self:GetChecked() then
			PGF_notification_whisper = true
			if not PGF_autoSign and not PGF_notification_sound and not PGF_notification_guild and not PGF_notification_popup and not PGF_notification_flashTaskbar and not PGF_enabled then
				PGF_enabled = true
				enabledButton:SetChecked(PGF_enabled)
				DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00" .. L.WARNING_ENABLED_TEXT)
			end
			PlaySound(856)
		else
			PGF_notification_whisper = false
			if not PGF_notification_sound and not PGF_autoSign and not PGF_notification_guild and not PGF_notification_popup and not PGF_notification_flashTaskbar and PGF_enabled then
				PGF_enabled = false
				enabledButton:SetChecked(PGF_enabled)
				DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000" .. L.WARNING_DISABLED_TEXT)
			end
			PlaySound(857)
		end
	end)
	
	local whisperText = PGF_optionsSettings:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	whisperText:SetPoint("TOPLEFT", whisperButton, "TOPLEFT", 30, -7)
	whisperText:SetText(L.OPTIONS_WHISPER_NOTIFICATION)
	]]
local soundButton = CreateFrame("CheckButton", "PGF_settingsSoundCheckButton", PGF_optionsSettings, "UICheckButtonTemplate")
soundButton:SetSize(26, 26)
soundButton:SetPoint("TOPLEFT", 200, -90)
soundButton:HookScript("OnClick", function(self)
	if self:GetChecked() then
		PGF_notification_sound = true
		if not PGF_autoSign and not PGF_notification_guild and not PGF_notification_popup and not PGF_notification_flashTaskbar and not PGF_enabled then
			PGF_enabled = true
			enabledButton:SetChecked(PGF_enabled)
			DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00" .. L.WARNING_ENABLED_TEXT)
		end
		PlaySound(856)
	else
		PGF_notification_sound = false
		if not PGF_autoSign and not PGF_notification_guild and not PGF_notification_popup and not PGF_notification_flashTaskbar and PGF_enabled then
			PGF_enabled = false
			enabledButton:SetChecked(PGF_enabled)
			DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000" .. L.WARNING_DISABLED_TEXT)
		end
		PlaySound(857)
	end
end)

local soundText = PGF_optionsSettings:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
soundText:SetPoint("TOPLEFT", soundButton, "TOPLEFT", 30, -7)
soundText:SetText(L.OPTIONS_SOUND_NOTIFICATION)

local guildButton = CreateFrame("CheckButton", "PGF_settingsGuildCheckButton", PGF_optionsSettings, "UICheckButtonTemplate")
guildButton:SetSize(26, 26)
guildButton:SetPoint("TOPLEFT", 200, -120)
guildButton:HookScript("OnClick", function(self)
	if self:GetChecked() then
		PGF_notification_guild = true
		if not PGF_autoSign and not PGF_notification_sound and not PGF_notification_popup and not PGF_notification_flashTaskbar and not PGF_enabled then
			PGF_enabled = true
			enabledButton:SetChecked(PGF_enabled)
			DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00" .. L.WARNING_ENABLED_TEXT)
		end
		PlaySound(856)
	else
		PGF_notification_guild = false
		if not PGF_autoSign and not PGF_notification_sound and not PGF_notification_popup and not PGF_notification_flashTaskbar and PGF_enabled then
			PGF_enabled = false
			enabledButton:SetChecked(PGF_enabled)
			DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000" .. L.WARNING_DISABLED_TEXT)
		end
		PlaySound(857)
	end
end)

local guildText = PGF_optionsSettings:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
guildText:SetPoint("TOPLEFT", guildButton, "TOPLEFT", 30, -7)
guildText:SetText(L.OPTIONS_GUILD_NOTIFICATION_TEXT)

local popupButton = CreateFrame("CheckButton", "PGF_settingsPopupCheckButton", PGF_optionsSettings, "UICheckButtonTemplate")
popupButton:SetSize(26, 26)
popupButton:SetPoint("TOPLEFT", 200, -150)
popupButton:HookScript("OnClick", function(self)
	if self:GetChecked() then
		PGF_notification_popup = true
		if not PGF_autoSig and not PGF_notification_sound and not PGF_notification_guild and not PGF_notification_flashTaskbar and not PGF_enabled then
			PGF_enabled = true
			enabledButton:SetChecked(PGF_enabled)
			DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00" .. L.WARNING_ENABLED_TEXT)
		end
		PlaySound(856)
	else
		PGF_notification_popup = false
		if not PGF_autoSign and not PGF_notification_sound and not PGF_notification_guild and not PGF_notification_flashTaskbar and PGF_enabled then
			PGF_enabled = false
			enabledButton:SetChecked(PGF_enabled)
			DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000" .. L.WARNING_DISABLED_TEXT)
		end
		PlaySound(857)
	end
	
end)
local popupText = PGF_optionsSettings:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
popupText:SetPoint("TOPLEFT", popupButton, "TOPLEFT", 30, -7)
popupText:SetText(L.OPTIONS_POPUP)

local flashButton = CreateFrame("CheckButton", "PGF_settingsFlashCheckButton", PGF_optionsSettings, "UICheckButtonTemplate")
flashButton:SetSize(26, 26)
flashButton:SetPoint("TOPLEFT", 200, -180)
flashButton:HookScript("OnClick", function(self)
	if self:GetChecked() then
		PGF_notification_flashTaskbar = true
		if not PGF_autoSign and not PGF_notification_sound and not PGF_notification_guild and not PGF_notification_popup and not PGF_enabled then
			PGF_enabled = true
			enabledButton:SetChecked(PGF_enabled)
			DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00" .. L.WARNING_ENABLED_TEXT)
		end
		PlaySound(856)
	else
		PGF_notification_flashTaskbar = false
		if not PGF_autoSign and not PGF_notification_sound and not PGF_notification_guild and not PGF_notification_popup and PGF_enabled then
			PGF_enabled = false
			enabledButton:SetChecked(PGF_enabled)
			DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000" .. L.WARNING_DISABLED_TEXT)
		end
		PlaySound(857)
	end
end)

local flashText = PGF_optionsSettings:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
flashText:SetPoint("TOPLEFT", flashButton, "TOPLEFT", 30, -7)
flashText:SetText(L.OPTIONS_FLASH_NOTIFICATION)
--[[
local configText = PGF_optionsSettings:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
configText:SetPoint("TOPLEFT", 380, -75)
configText:SetText(L.OPTIONS_CONFIG)

local intervalText = PGF_optionsSettings:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
intervalText:SetPoint("TOPLEFT", 380, -90)
intervalText:SetText(L.OPTIONS_INTERVAL)

local intervalEdit = CreateFrame("EditBox", "PGF_settingsIntervalEditBox", PGF_optionsSettings, "InputBoxTemplate")
intervalEdit:SetPoint("TOPLEFT", intervalText, "TOPLEFT", 5, -15)
intervalEdit:SetAutoFocus(false)
intervalEdit:EnableMouse(true)
intervalEdit:SetSize(50, 20)
intervalEdit:SetMaxLetters(4)
intervalEdit:SetScript("OnEscapePressed", function(self)
	self:ClearFocus()
end)
intervalEdit:SetScript("OnEnterPressed", function(self)
	local value = self:GetNumber()
	if value > 0 then
		PGF_interval = value
	end
	self:ClearFocus()
end)
intervalEdit:SetScript("OnTextChanged", function(self)
	local value = self:GetNumber()
	if value > 0 then
		PGF_interval = value
	end
end)

local roleText = PGF_optionsSettings:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
roleText:SetPoint("TOPLEFT", intervalText, "TOPLEFT", 0, -45)
roleText:SetText(L.OPTIONS_ROLE)

local dpsText = PGF_optionsSettings:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
dpsText:SetPoint("TOPLEFT", roleText, "TOPLEFT", 0, -15)
dpsText:SetText("DPS")

local dpsButton = CreateFrame("CheckButton", "PGF_settingsDPSCheckButton", PGF_optionsSettings, "UICheckButtonTemplate")
dpsButton:SetSize(20, 20)
dpsButton:SetPoint("TOPLEFT", dpsText, "TOPLEFT", 45, 5)
dpsButton:HookScript("OnClick", function(self)
	if self:GetChecked() then
		PGF_roles.DPS = true
		PlaySound(856)
	else
		PGF_roles.DPS = false
		PlaySound(857)
	end
end)

local healerText = PGF_optionsSettings:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
healerText:SetPoint("TOPLEFT", dpsText, "TOPLEFT", 0, -20)
healerText:SetText("Healer")

local healerButton = CreateFrame("CheckButton", "PGF_settingsHealerCheckButton", PGF_optionsSettings, "UICheckButtonTemplate")
healerButton:SetSize(20, 20)
healerButton:SetPoint("TOPLEFT", healerText, "TOPLEFT", 45, 5)
healerButton:HookScript("OnClick", function(self)
	if self:GetChecked() then
		PGF_roles.HEALER = true
		PlaySound(856)
	else
		PGF_roles.HEALER = false
		PlaySound(857)
	end
end)

local tankText = PGF_optionsSettings:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
tankText:SetPoint("TOPLEFT", healerText, "TOPLEFT", 0, -20)
tankText:SetText("Tank")

local tankButton = CreateFrame("CheckButton", "PGF_settingsTankCheckButton", PGF_optionsSettings, "UICheckButtonTemplate")
tankButton:SetSize(20, 20)
tankButton:SetPoint("TOPLEFT", tankText, "TOPLEFT", 45, 5)
tankButton:HookScript("OnClick", function(self)
	if self:GetChecked() then
		PGF_roles.TANK = true
		PlaySound(856)
	else
		PGF_roles.TANK = false
		PlaySound(857)
	end
end)

function PGF_EnableRoleTank(eligible)
	if not eligible then
		tankButton:Disable()
		PGF_roles.TANK = false
		tankButton:SetChecked(eligible)
	end
end
function PGF_EnableRoleHealer(eligible)
	if not eligible then
		healerButton:Disable()
		PGF_roles.HEALER = false
		healerButton:SetChecked(eligible)
	end
end
function PGF_EnableRoleDPS(eligible)
	if not eligible then
		dpsButton:Disable()
		PGF_roles.DPS = false
		dpsButton:SetChecked(eligible)
	end
end
]]
PGF_optionsSettings:SetScript("OnShow", function(PGF_options)
	--intervalEdit:SetText(PGF_interval)
	soundButton:SetChecked(PGF_notification_sound)
	enabledButton:SetChecked(PGF_enabled)
	--auto_signButton:SetChecked(PGF_autoSign)
	Initialize_AutoSignState()
	--whisperButton:SetChecked(PGF_notification_whisper)
	changeColorButton:SetChecked(PGF_changeMinimapColor)
	--search_loginButton:SetChecked(PGF_searchLogin)
	guildButton:SetChecked(PGF_notification_guild)
	--dpsButton:SetChecked(PGF_roles.DPS)
	--healerButton:SetChecked(PGF_roles.HEALER)
	--tankButton:SetChecked(PGF_roles.TANK)
	popupButton:SetChecked(PGF_notification_popup)
	flashButton:SetChecked(PGF_notification_flashTaskbar)
	Initialize_MinimapState()
	UIDropDownMenu_SetSelectedName(minimapStateMenu, PGF_minimapButtonMode)
	UIDropDownMenu_SetSelectedName(auto_signStateMenu, PGF_autoSignState)
	if PGF_SearchBinding then searchBindingButton:SetText(PGF_SearchBinding) end
end)

InterfaceOptions_AddCategory(PGF_optionsSettings)