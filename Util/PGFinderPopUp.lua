local addon = ...
local L = PGFinderLocals

<<<<<<< HEAD
PGF_popup = CreateFrame("Frame", nil, nil, BackdropTemplateMixin and "BackdropTemplate")
PGF_popup:SetWidth(150)
PGF_popup:SetHeight(50)
PGF_popup:SetPoint("CENTER")
PGF_popup:SetMovable(true)
PGF_popup:EnableMouse(true)
PGF_popup:RegisterForDrag("LeftButton")
PGF_popup:SetFrameLevel(3)
PGF_popup:SetScript("OnDragStart", PGF_popup.StartMoving)
PGF_popup:SetScript("OnDragStop", function(self)
	local point, relativeTo, relativePoint, xOffset, yOffset = self:GetPoint(1)
	PGF_popupPoint = {}
	PGF_popupPoint.point = point
	PGF_popupPoint.relativeTo = relativeTo
	PGF_popupPoint.relativePoint = relativePoint
	PGF_popupPoint.xOffset = xOffset
	PGF_popupPoint.yOffset = yOffset
	self:StopMovingOrSizing()
end)
PGF_popup:SetBackdropColor(1, 1, 1, 1)
PGF_popup:Hide()

--[[
local button = CreateFrame("Button", "OkButton", PGF_popup, "UIPanelButtonTemplate")
=======
popup = CreateFrame("Frame")
popup:SetWidth(150)
popup:SetHeight(50)
popup:SetPoint("CENTER")
popup:SetMovable(true)
popup:EnableMouse(true)
popup:RegisterForDrag("LeftButton")
popup:SetScript("OnDragStart", popup.StartMoving)
popup:SetScript("OnDragStop", function(self)
	local point, relativeTo, relativePoint, xOffset, yOffset = self:GetPoint(1)
	POPUPPOINT = {}
	POPUPPOINT.point = point
	POPUPPOINT.relativeTo = relativeTo
	POPUPPOINT.relativePoint = relativePoint
	POPUPPOINT.xOffset = xOffset
	POPUPPOINT.yOffset = yOffset
	self:StopMovingOrSizing()
end)
popup:SetBackdropColor(1, 1, 1, 1)
popup:Hide()

--[[
local button = CreateFrame("Button", "OkButton", popup, "UIPanelButtonTemplate")
>>>>>>> 599b4e149a82ab29a1d101bb621be17c2562fc30
button:SetHeight(24)
button:SetWidth(60)
button:SetPoint("BOTTOM", 0, 10)
button:SetText("OK")
<<<<<<< HEAD
button:SetScript("OnClick", function(self) PlaySound(852) self:GetParent():Hide() end)


local title = PGF_popup:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
title:SetPoint("TOP", 0, -15)
title:SetText(L.OPTIONS_TITLE)
--]]
local info = PGF_popup:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
=======
button:SetScript("OnClick", function(self) PlaySound("igMainMenuOption") self:GetParent():Hide() end)


local title = popup:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
title:SetPoint("TOP", 0, -15)
title:SetText(L.OPTIONS_TITLE)
--]]
local info = popup:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
>>>>>>> 599b4e149a82ab29a1d101bb621be17c2562fc30
info:ClearAllPoints()
info:SetPoint("CENTER")
info:SetText(L.NOTIFICATION_POPUP)

<<<<<<< HEAD
function PGF_SetInfoText(text)
	info:SetText(L.NOTIFICATION_POPUP .. text)
end

function PGF_SetPopUpPoint(point, relativeTo, relativePoint, xOffset, yOffset)
	PGF_popup:ClearAllPoints()
	PGF_popup:SetPoint(point, relativeTo, relativePoint, xOffset, yOffset)
=======
function setInfoText(text)
	info:SetText(L.NOTIFICATION_POPUP .. text)
end

function setPopUpPoint(point, relativeTo, relativePoint, xOffset, yOffset)
	popup:ClearAllPoints()
	popup:SetPoint(point, relativeTo, relativePoint, xOffset, yOffset)
>>>>>>> 599b4e149a82ab29a1d101bb621be17c2562fc30
end
