local addon = ...
local L = PGFinderLocals
local init = false
local groupTexts = {}
local rareTexts = {}

PGF_optionsRareInfo = CreateFrame("Frame", "PGF_optionsRareInfo", InterfaceOptionsFramePanelContainer)
PGF_optionsRareInfo.name = "Rare Info"
PGF_optionsRareInfo.parent = "Premade Group Finder"
PGF_optionsRareInfo:Hide()

local COMPLETE_COLOR = "|cFF00FF00"
local INCOMPLETE_COLOR = "|cFFFF0000"

local title = PGF_optionsRareInfo:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
title:SetPoint("TOP", 0, -16)
title:SetText(L.OPTIONS_TITLE)
	
local tabinfo = PGF_optionsRareInfo:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
tabinfo:SetPoint("TOPLEFT", 16, -16)
tabinfo:SetText(L.OPTIONS_INFO_RAREINFO)

local author = PGF_optionsRareInfo:CreateFontString(nil, "ARTWORK", "GameFontNormal")
author:SetPoint("TOPLEFT", 450, -20)
author:SetText(L.OPTIONS_AUTHOR)

local version = PGF_optionsRareInfo:CreateFontString(nil, "ARTWORK", "GameFontNormal")
version:SetPoint("TOPLEFT", author, "BOTTOMLEFT", 0, -10)
version:SetText(L.OPTIONS_VERSION)

local explanationText = PGF_optionsRareInfo:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
explanationText:SetPoint("BOTTOMLEFT", 30, 16)
explanationText:SetText(L.INFO_RAREINFO_INFO)

PGF_optionsRareInfo:HookScript("OnShow", function()
	if not init then 
		PGF_RareInfoInit()
	else
		for index, groupName in pairs(groupTexts) do
			for qID, text in pairs(rareTexts[groupName]) do
				local questCompleted = C_QuestLog.IsQuestFlaggedCompleted(qID)
				text:SetText((questCompleted and COMPLETE_COLOR or INCOMPLETE_COLOR) .. PGF_RareQuestIDs[groupName][qID])
			end
		end
	end
end)

--[[
function PGF_RareInfoInit()
	init = true
	local groupCount = 0
	for groupName, data in pairs(PGF_RareQuestIDs) do
		local rareCount = 0
		local groupNameText = PGF_optionsRareInfo:CreateFontString("PGF_"..groupName.."GroupText", "ARTWORK", "GameFontNormalLarge")
		groupNameText:SetPoint("TOPLEFT",30+(100*groupCount), -80)
		groupNameText:SetText(groupName)
		rareTexts[groupName] = {}
		groupTexts[#groupTexts+1] = groupName
		for qID, rareName in pairs(data) do
			local questCompleted = IsQuestFlaggedCompleted(qID)
			local rareNameText = PGF_optionsRareInfo:CreateFontString("PGF_"..qID.."RareText", "ARTWORK", "GameFontNormal")
			rareNameText:SetPoint("TOPLEFT", groupNameText, "TOPLEFT", 0, -20-(20*rareCount))
			rareNameText:SetFont("Fonts\\FRIZQT__.TTF", 16)
			rareNameText:SetText((questCompleted and COMPLETE_COLOR or INCOMPLETE_COLOR) .. rareName)
			rareTexts[groupName][qID] = rareNameText
			rareCount = rareCount + 1
		end
		groupCount = groupCount + 1
	end
end
]]
function PGF_RareInfoInit()
	init = true
	local groupCount = 0
	for groupName, data in pairs(PGF_RareQuestIDs) do
		local rareCount = 0
		local groupNameText = PGF_optionsRareInfo:CreateFontString("PGF_"..groupName.."GroupText", "ARTWORK", "GameFontNormalLarge")
		groupNameText:SetPoint("TOPLEFT",30+(100*groupCount), -80)
		groupNameText:SetText(groupName)
		rareTexts[groupName] = {}
		groupTexts[#groupTexts+1] = groupName
		for qID, rareName in pairs(data) do
			if PGF_IsMatch3(rareName, PGF_activeKeywords) then
				local rareName = data[qID]
				local questCompleted = C_QuestLog.IsQuestFlaggedCompleted(qID)
				local rareNameText = PGF_optionsRareInfo:CreateFontString("PGF_"..qID.."RareText", "ARTWORK", "GameFontNormal")
				rareNameText:SetPoint("TOPLEFT", groupNameText, "TOPLEFT", 0, -20-(20*rareCount))
				rareNameText:SetFont("Fonts\\FRIZQT__.TTF", 16)
				rareNameText:SetText((questCompleted and COMPLETE_COLOR or INCOMPLETE_COLOR) .. rareName)
				rareTexts[groupName][qID] = rareNameText
				rareCount = rareCount + 1
			end
		end
		groupCount = groupCount + 1
	end
end

InterfaceOptions_AddCategory(PGF_optionsRareInfo)