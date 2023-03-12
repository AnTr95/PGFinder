local addon = ...
local L = PGFinderLocals

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
button:SetHeight(24)
button:SetWidth(60)
button:SetPoint("BOTTOM", 0, 10)
button:SetText("OK")
button:SetScript("OnClick", function(self) PlaySound(852) self:GetParent():Hide() end)


local title = PGF_popup:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
title:SetPoint("TOP", 0, -15)
title:SetText(L.OPTIONS_TITLE)
--]]
local info = PGF_popup:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
info:ClearAllPoints()
info:SetPoint("CENTER")
info:SetText(L.NOTIFICATION_POPUP)

function PGF_SetInfoText(text)
	info:SetText(L.NOTIFICATION_POPUP .. text)
end

function PGF_SetPopUpPoint(point, relativeTo, relativePoint, xOffset, yOffset)
	PGF_popup:ClearAllPoints()
	PGF_popup:SetPoint(point, relativeTo, relativePoint, xOffset, yOffset)
end
