local addon = ...
local L = PGFinderLocals

PGF_optionsProfiles = CreateFrame("Frame", "PGF_optionsProfiles", InterefaceOptionsFramePanelContainer)
PGF_optionsProfiles.name = "Profiles"
PGF_optionsProfiles.parent = "Premade Group Finder"
PGF_optionsProfiles:Hide()

local title = PGF_optionsProfiles:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
title:SetPoint("TOP", 0, -16)
title:SetText(L.OPTIONS_TITLE)

local tabinfo = PGF_optionsProfiles:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
tabinfo:SetPoint("TOPLEFT", 16, -16)
tabinfo:SetText(L.OPTIONS_INFO_PROFILES)
local author = PGF_optionsProfiles:CreateFontString(nil, "ARTWORK", "GameFontNormal")
author:SetPoint("TOPLEFT", 450, -20)
author:SetText(L.OPTIONS_AUTHOR)

local version = PGF_optionsProfiles:CreateFontString(nil, "ARTWORK", "GameFontNormal")
version:SetPoint("TOPLEFT", author, "BOTTOMLEFT", 0, -10)
version:SetText(L.OPTIONS_VERSION)
local newProfileInfoText = PGF_optionsProfiles:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
newProfileInfoText:SetPoint("TOPLEFT", 25, -70)
newProfileInfoText:SetSize(550, 50)
newProfileInfoText:SetText(L.INFO_PROFILES)
newProfileInfoText:SetWordWrap(true)

local newProfileText = PGF_optionsProfiles:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	newProfileText:SetPoint("TOPLEFT", 50, -140)
	newProfileText:SetText(L.OPTIONS_NEW_PROFILE_TEXT)

local newProfileEdit = CreateFrame("EditBox", "PGF_profilesNewProfileEditBox", PGF_optionsProfiles, "InputBoxTemplate")
newProfileEdit:SetPoint("TOPLEFT", newProfileText, "TOPLEFT", 0, -2)
newProfileEdit:SetAutoFocus(false)
newProfileEdit:SetSize(120, 45)
newProfileEdit:SetText("")
newProfileEdit:SetScript("OnEscapePressed", function(self)
	self:SetText("")
	self:ClearFocus()
end)
newProfileEdit:SetScript("OnEnterPressed", function(self)
	PGF_profilesNewProfileButton:Click()
end)
newProfileEdit:SetScript("OnTextChanged", function(self, text)
	if newProfileEdit:GetText() ~= "" then
		PGF_profilesNewProfileButton:Enable()
	else
		PGF_profilesNewProfileButton:Disable()
	end
end)
local newProfileButton = CreateFrame("Button", "PGF_profilesNewProfileButton", PGF_optionsProfiles, "UIPanelButtonTemplate")
newProfileButton:SetSize(40, 20)
newProfileButton:SetPoint("TOPLEFT", newProfileEdit, "TOPLEFT", 120, -11)
newProfileButton:SetText(L.OPTIONS_NEW_PROFILE_BUTTON)
newProfileButton:HookScript("OnClick", function(self)
	newProfileButton:Disable()
	PGF_CreateProfile(newProfileEdit:GetText())
	newProfileEdit:SetText("")
	PGF_optionsProfiles:Hide()
	PGF_optionsProfiles:Show()
end)
local deleteInfoText = PGF_optionsProfiles:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
deleteInfoText:SetPoint("TOPLEFT", 50, -205)
deleteInfoText:SetText(L.INFO_DELETE_PROFILE)
local deleteProfileText = PGF_optionsProfiles:CreateFontString(nil, "ARTWORK", "GameFontNormal")
deleteProfileText:SetPoint("TOPLEFT", 50, -225)
deleteProfileText:SetText(L.OPTIONS_DELETE_PROFILE_TEXT)

local existingProfileText = PGF_optionsProfiles:CreateFontString(nil, "ARTWORK", "GameFontNormal")
existingProfileText:SetPoint("TOPLEFT", 235, -140)
existingProfileText:SetText(L.OPTIONS_EXISTING_PROFILE_TEXT)
		
local profiles = CreateFrame("Button", "PGF_profilesProfilesDropDownMenu", PGF_optionsProfiles, "UIDropDownMenuTemplate")
profiles:SetPoint("TOPLEFT", existingProfileText, "TOPLEFT", -20, -15)
local pfs = {}
local deletion = CreateFrame("Button", "PGF_profilesDeletionDropDownMenu", PGF_optionsProfiles, "UIDropDownMenuTemplate")
deletion:SetPoint("TOPLEFT", deleteProfileText, "TOPLEFT", -20, -15)
local function Deletion_OnClick(self)
	StaticPopupDialogs["PGF_CONFIRMATION"] = {
	  text = "Are you sure you want to delete this profile?",
	  button1 = "Yes",
	  button2 = "No",
	  OnAccept = function()
		  PGF_profiles[self:GetText()] = nil
		  UIDropDownMenu_SetSelectedID(deletion, 1)
		  PGF_optionsProfiles:Hide()
		  PGF_optionsProfiles:Show()
		  PGF_RefreshMinimapProfiles()
	  end,
	  OnCancel = function()
		UIDropDownMenu_SetSelectedID(deletion, 1)
	  end,
	  timeout = 0,
	  whileDead = true,
	  hideOnEscape = true,
	  preferredIndex = 3,  -- avoid some UI taint, see http://www.wowace.com/announcements/how-to-avoid-some-ui-taint/
	}
	UIDropDownMenu_SetSelectedID(deletion, self:GetID())
	StaticPopup_Show ("PGF_CONFIRMATION")
end
PGF_optionsProfiles:SetScript("OnShow", function(PGF_optionsProfiles)
	pfs = {}
	for k, v in pairs(PGF_profiles) do
		PGF_UpdateList(pfs, k, true)
	end
end)
local function Profiles_OnClick(self)
	UIDropDownMenu_SetSelectedID(profiles, self:GetID())
	PGF_LoadProfile(self:GetText())
	PGF_latestProfile = self:GetText()
	PGF_CorrectMinimapProfile()
	PGF_ResetKeywordFrames()
end
local function Initialize_Profiles(self, level)
   local info = UIDropDownMenu_CreateInfo()
   for k,v in pairs(pfs) do
      info = UIDropDownMenu_CreateInfo()
      info.text = v
      info.value = v
      info.func = Profiles_OnClick
      UIDropDownMenu_AddButton(info, level)
   end
end
local function Initialize_Deletion(self, level)
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
function PGF_CorrectOptionProfile()
	UIDropDownMenu_SetSelectedName(profiles, PGF_latestProfile) 
end
UIDropDownMenu_Initialize(profiles, Initialize_Profiles)
UIDropDownMenu_Initialize(deletion, Initialize_Deletion)
UIDropDownMenu_SetWidth(profiles, 150);
UIDropDownMenu_SetWidth(deletion, 150);
UIDropDownMenu_SetButtonWidth(profiles, 170)
UIDropDownMenu_SetButtonWidth(deletion, 170)
UIDropDownMenu_JustifyText(profiles, "LEFT")
UIDropDownMenu_JustifyText(deletion, "LEFT")
InterfaceOptions_AddCategory(PGF_optionsProfiles)