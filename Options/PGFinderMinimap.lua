--DEPRECATED Interface\\addons\\PGFinder\\Res\\minimap.tga BLUE BELL

local addon = ...
local L = PGFinderLocals
local minimapButton = CreateFrame("Button", "PGF_minimapButton", Minimap)
minimapButton:SetPoint("TOPLEFT")
minimapButton:SetSize(33, 33)
minimapButton:SetMovable(true)
minimapButton:EnableMouse(true)
minimapButton:SetFrameStrata("HIGH")
minimapButton:SetFrameLevel(8)
minimapButton:SetClampedToScreen(true)
minimapButton:SetDontSavePosition(true)
minimapButton:RegisterForClicks("LeftButtonUp", "RightButtonUp")
minimapButton:RegisterForDrag("LeftButton", "RightButton")
minimapButton:EnableDrawLayer("BACKGROUND")
minimapButton:EnableDrawLayer("OVERLAY")

local normalTexture = minimapButton:CreateTexture("PGF_minimapButton_BackgroundTexture", "BACKGROUND")
normalTexture:SetDrawLayer("BACKGROUND", 0)
normalTexture:SetTexture("Interface\\addons\\PGFinder\\Res\\minimap.tga")
normalTexture:SetSize(21,21)
normalTexture:SetPoint("TOPLEFT", 6, -5)

local highlightTexture = minimapButton:CreateTexture("PGF_minimapButton_OverlayTexture", "OVERLAY")
highlightTexture:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
highlightTexture:SetSize(56,56)
highlightTexture:SetPoint("TOPLEFT")

--[[minimapButton:SetScript("OnHide", function(self)
	if self.dragging then
		self:SetScript("OnUpdate", nil)
	end
end)

minimapButton:SetScript("OnMouseUp", function(self)
	if self.dragging then
		self:SetScript("Onupdate", nil)
	end
end)]]
minimapButton:SetScript("OnClick", function(self)
	if self.dragging then
		self:SetScript("OnUpdate", nil)
	end
	local button = GetMouseButtonClicked()
	if IsShiftKeyDown() and button == "RightButton" then
		PGF_MinimapButton_Profiles()
	elseif IsShiftKeyDown() and button == "LeftButton" then
		InterfaceOptionsFrame_OpenToCategory(PGF_optionsKeywords)
		if not PGF_optionsKeywords:IsVisible() then
			InterfaceOptionsFrame_OpenToCategory(PGF_optionsKeywords)
		end
	elseif button == "LeftButton" then
		PGF_Search()
	elseif button == "RightButton" then
		if PGF_enabled then
			PGF_enabled = false
			DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000" .. L.WARNING_DISABLED_TEXT)
			if PGF_changeMinimapColor then
				PGF_MinimapButton_SetRed(self)
			end
		else
			PGF_enabled = true
			DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00" .. L.WARNING_ENABLED_TEXT)
			if PGF_changeMinimapColor then
				PGF_MinimapButton_SetGreen(self)
			end
		end
	end
end)
minimapButton:SetScript("OnDragStart", function(self)
	self:LockHighlight()
	self.dragging = true
	self:SetScript("OnUpdate", function(self)
		if not IsMouseButtonDown() then
			self:SetScript("OnUpdate", nil)
			self.dragging = false
		end
		local xpos,ypos = GetCursorPosition()
		local xmin,xmax,ymin,ymax = Minimap:GetLeft(), Minimap:GetRight(), Minimap:GetBottom(), Minimap:GetTop()
		local xLen = xmax-xmin
		local yLen = ymax-ymin

		xpos = xmin-xpos/UIParent:GetScale()+(xLen/2) -- get coordinates as differences from the center of the minimap
		ypos = ypos/UIParent:GetScale()-ymin-(yLen/2)

		PGF_minimapDegree = math.deg(math.atan2(ypos,xpos)) -- save the degrees we are relative to the minimap center
		PGF_SetMinimapPoint(PGF_minimapDegree)
	end)
end)
minimapButton:SetScript("OnDragStop", function(self)
	self:LockHighlight()
	self.dragging = false
	self:SetScript("OnUpdate", nil)
end)
minimapButton:SetScript("OnEnter", function(self)
	GameTooltip:SetOwner(self, "ANCHOR_BOTTOMLEFT")
	GameTooltip:SetText(L.OPTIONS_TITLE)
	GameTooltip:AddLine(L.INFO_MINIMAP_CLICK)
	GameTooltip:AddLine(L.INFO_MINIMAP_RIGHTCLICK)
	GameTooltip:AddLine(L.INFO_MINIMAP_SHIFTRIGHTCLICK)
	GameTooltip:AddLine(L.INFO_MINIMAP_SHIFTLEFTCLICK)
	GameTooltip:Show()
	if PGF_minimapButtonMode == "On Hover" then
		PGF_minimapButton:Show()
	end
end)
minimapButton:SetScript("OnLeave", function(self)
	GameTooltip:Hide()
	if PGF_minimapButtonMode == "On Hover" and not self.dragging then
		if not MouseIsOver(Minimap) and not MouseIsOver(PGF_minimapButton) then
			PGF_minimapButton:Hide()
		end
	end
end)
function PGF_MinimapButton_SetGreen(self)
	normalTexture:SetTexture("Interface\\addons\\PGFinder\\Res\\greenbell.tga")
end
function PGF_MinimapButton_SetRed(self)
	normalTexture:SetTexture("Interface\\addons\\PGFinder\\Res\\redbell.tga")
end
function PGF_MinimapButton_SetBlue(self)
	normalTexture:SetTexture("Interface\\addons\\PGFinder\\Res\\minimap.tga")
end
local mmProfiles = CreateFrame("Button", "PGF_minimapProfilesDropDownMenu", PGF_minimapButton, "UIDropDownMenuTemplate")
mmProfiles:SetPoint("TOPLEFT", PGF_minimapButton, "BOTTOM", -204, 32)
mmProfiles:Hide()
mmProfiles:SetFrameStrata("HIGH") --top most
mmProfiles:SetFrameLevel(10)
local pfs = {}
mmProfiles:SetScript("OnShow", function(self)
	pfs = {}
	for k, v in pairs(PGF_profiles) do
		PGF_UpdateList(pfs, k, true)
	end
end)
local function Profiles_OnClick(self)
	UIDropDownMenu_SetSelectedID(mmProfiles, self:GetID())
	if PGF_optionsKeywords:IsShown() then
		PGF_optionsKeywords:Hide()
		PGF_LoadProfile(self:GetText())
		PGF_ResetKeywordFrames()
		PGF_optionsKeywords:Show()
	else
		PGF_LoadProfile(self:GetText())
		PGF_ResetKeywordFrames()
	end
	PGF_latestProfile = self:GetText()
	PGF_CorrectOptionProfile()
	mmProfiles:Hide()
end
local function initialize_PGF(self, level)
	local info = UIDropDownMenu_CreateInfo()
	for k,v in pairs(pfs) do
	  info = UIDropDownMenu_CreateInfo()
	  info.text = v
	  info.value = v
	  info.func = Profiles_OnClick
	  UIDropDownMenu_AddButton(info, level)
	end
end
function PGF_MinimapButton_Profiles()
	if mmProfiles:IsShown() then
		mmProfiles:Hide()
	else
		mmProfiles:Show()
	end
end
function PGF_CorrectMinimapProfile()
	UIDropDownMenu_SetSelectedName(mmProfiles, PGF_latestProfile) 
end
function PGF_RefreshMinimapProfiles()
	if mmProfiles:IsShown() then
		mmProfiles:Hide()
		mmProfiles:Show()
	end
end
Minimap:HookScript("OnEnter", function(self)
	if PGF_minimapButtonMode == "On Hover" then
		PGF_minimapButton:Show()
	end
end)
Minimap:HookScript("OnLeave", function(self)
	if PGF_minimapButtonMode == "On Hover" then
		if not MouseIsOver(PGF_minimapButton) then
			PGF_minimapButton:Hide()
		end
	end

end)
function PGF_SetMinimapPoint(degree)
	PGF_minimapButton:ClearAllPoints()
	PGF_minimapButton:SetPoint("TOPLEFT", "Minimap","TOPLEFT",52-(80*cos(degree)),(80*sin(degree))-52)
end
function PGF_SetSearchBinding()
	SetBindingClick(PGF_SearchBinding, minimapButton:GetName(), "LeftButton")
end
UIDropDownMenu_SetWidth(mmProfiles, 150)
UIDropDownMenu_SetButtonWidth(mmProfiles, 160)
UIDropDownMenu_JustifyText(mmProfiles, "LEFT")
UIDropDownMenu_Initialize(mmProfiles, initialize_PGF)