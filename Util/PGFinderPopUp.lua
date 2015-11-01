local addon = ...
local L = PGFinderLocals

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
button:SetHeight(24)
button:SetWidth(60)
button:SetPoint("BOTTOM", 0, 10)
button:SetText("OK")
button:SetScript("OnClick", function(self) PlaySound("igMainMenuOption") self:GetParent():Hide() end)


local title = popup:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
title:SetPoint("TOP", 0, -15)
title:SetText(L.OPTIONS_TITLE)
--]]
local info = popup:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
info:ClearAllPoints()
info:SetPoint("CENTER")
info:SetText(L.NOTIFICATION_POPUP)

function setInfoText(text)
	info:SetText(L.NOTIFICATION_POPUP .. text)
end

function setPopUpPoint(point, relativeTo, relativePoint, xOffset, yOffset)
	popup:ClearAllPoints()
	popup:SetPoint(point, relativeTo, relativePoint, xOffset, yOffset)
end
