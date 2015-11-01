local addon = ...
local L = PGFinderLocals

optionsProfiles = CreateFrame("Frame", addon .. "ProfileFrame", InterefaceOPtionsFramePanelContainer)
optionsProfiles.name = "Profiles"
optionsProfiles.parent = "Premade Group Finder"
optionsProfiles:Hide()

local title = optionsProfiles:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
	title:SetPoint("TOP", 0, -16)
	title:SetText(L.OPTIONS_TITLE)
	
local tabinfo = optionsProfiles:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
	tabinfo:SetPoint("TOPLEFT", 16, -16)
	tabinfo:SetText(L.OPTIONS_INFO_PROFILES)
	local author = optionsProfiles:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	author:SetPoint("TOPLEFT", 450, -20)
	author:SetText(L.OPTIONS_AUTHOR)
	
	local version = optionsProfiles:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	version:SetPoint("TOPLEFT", author, "BOTTOMLEFT", 0, -10)
	version:SetText(L.OPTIONS_VERSION)
local newProfileInfoText = optionsProfiles:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	newProfileInfoText:SetPoint("TOPLEFT", 25, -70)
	newProfileInfoText:SetSize(550, 50)
	newProfileInfoText:SetText(L.INFO_PROFILES)
	newProfileInfoText:SetWordWrap(true)
	
local newProfileText = optionsProfiles:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	newProfileText:SetPoint("TOPLEFT", 50, -140)
	newProfileText:SetText(L.OPTIONS_NEW_PROFILE_TEXT)

local newProfileEdit = CreateFrame("EditBox", "NewProfileEditBox", optionsProfiles, "InputBoxTemplate")
	newProfileEdit:SetPoint("TOPLEFT", newProfileText, "TOPLEFT", 0, -2)
	newProfileEdit:SetAutoFocus(false)
	newProfileEdit:SetSize(120, 45)
	newProfileEdit:SetText("")
	newProfileEdit:SetScript("OnEscapePressed", function(frame)
		frame:SetText("")
		frame:ClearFocus()
	end)
	newProfileEdit:SetScript("OnEnterPressed", function(frame)
		NewProfileButton:Click()
	end)
	newProfileEdit:SetScript("OnTextChanged", function(frame, text)
		if newProfileEdit:GetText() ~= "" then
			NewProfileButton:Enable()
		else
			NewProfileButton:Disable()
		end
	end)
local newProfileButton = CreateFrame("Button", "NewProfileButton", optionsProfiles, "UIPanelButtonTemplate")
	newProfileButton:SetSize(40, 20)
	newProfileButton:SetPoint("TOPLEFT", newProfileEdit, "TOPLEFT", 120, -11)
	newProfileButton:SetText(L.OPTIONS_NEW_PROFILE_BUTTON)
	newProfileButton:HookScript("OnClick", function(frame)
		newProfileButton:Disable()
		createProfile(newProfileEdit:GetText())
		newProfileEdit:SetText("")
		optionsProfiles:Hide()
		optionsProfiles:Show()
	end)
	local deleteInfoText = optionsProfiles:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
		deleteInfoText:SetPoint("TOPLEFT", 50, -205)
		deleteInfoText:SetText(L.INFO_DELETE_PROFILE)
	local deleteProfileText = optionsProfiles:CreateFontString(nil, "ARTWORK", "GameFontNormal")
		deleteProfileText:SetPoint("TOPLEFT", 50, -225)
		deleteProfileText:SetText(L.OPTIONS_DELETE_PROFILE_TEXT)

local existingProfileText = optionsProfiles:CreateFontString(nil, "ARTWORK", "GameFontNormal")
		existingProfileText:SetPoint("TOPLEFT", 235, -140)
		existingProfileText:SetText(L.OPTIONS_EXISTING_PROFILE_TEXT)
		
local profiles = CreateFrame("Button", "ProfilesDropDownMenu", optionsProfiles, "UIDropDownMenuTemplate")
profiles:SetPoint("TOPLEFT", existingProfileText, "TOPLEFT", -20, -15)
local pfs = {}
local deletion = CreateFrame("Button", "DeletionDropDownMenu", optionsProfiles, "UIDropDownMenuTemplate")
deletion:SetPoint("TOPLEFT", deleteProfileText, "TOPLEFT", -20, -15)
local function Deletion_OnClick(frame)
	StaticPopupDialogs["PGF_CONFIRMATION"] = {
	  text = "Are you sure you want to delete this profile?",
	  button1 = "Yes",
	  button2 = "No",
	  OnAccept = function()
		  Profiles[frame:GetText()] = nil
		  UIDropDownMenu_SetSelectedID(deletion, 1)
		  optionsProfiles:Hide()
		  optionsProfiles:Show()
	  end,
	  OnCancel = function()
		UIDropDownMenu_SetSelectedID(deletion, 1)
	  end,
	  timeout = 0,
	  whileDead = true,
	  hideOnEscape = true,
	  preferredIndex = 3,  -- avoid some UI taint, see http://www.wowace.com/announcements/how-to-avoid-some-ui-taint/
	}
	UIDropDownMenu_SetSelectedID(deletion, frame:GetID())
	StaticPopup_Show ("PGF_CONFIRMATION")
end
optionsProfiles:SetScript("OnShow", function(optionsProfiles)
	pfs = {}
	for k, v in pairs(Profiles) do
		updateList(pfs, k, true)
	end
end)
local function Profiles_OnClick(frame)
	UIDropDownMenu_SetSelectedID(profiles, frame:GetID())
	loadProfile(frame:GetText())
	LATEST_PROFILE = frame:GetText()
end
local function initialize_P(self, level)
   local info = UIDropDownMenu_CreateInfo()
   for k,v in pairs(pfs) do
      info = UIDropDownMenu_CreateInfo()
      info.text = v
      info.value = v
      info.func = Profiles_OnClick
      UIDropDownMenu_AddButton(info, level)
   end
end
local function initialize_D(self, level)
   local info = UIDropDownMenu_CreateInfo()
   info.text = " "
   info.value = " "
   UIDropDownMenu_AddButton(info, level)
   for k,v in pairs(pfs) do
      info = UIDropDownMenu_CreateInfo()
      info.text = v
      info.value = v
      info.func = Deletion_OnClick
      UIDropDownMenu_AddButton(info, level)
   end
end
 
UIDropDownMenu_Initialize(profiles, initialize_P)
UIDropDownMenu_Initialize(deletion, initialize_D)
UIDropDownMenu_SetWidth(profiles, 150);
UIDropDownMenu_SetWidth(deletion, 150);
UIDropDownMenu_SetButtonWidth(profiles, 170)
UIDropDownMenu_SetButtonWidth(deletion, 170)
UIDropDownMenu_JustifyText(profiles, "LEFT")
UIDropDownMenu_JustifyText(deletion, "LEFT")
InterfaceOptions_AddCategory(optionsProfiles)