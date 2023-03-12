local addon = ...
local L = PGFinderLocals

PGF_options = CreateFrame("Frame", "PGF_optionsFrame", InterefaceOptionsFramePanelContainer)
PGF_options.name = "Premade Group Finder"
PGF_options:Hide()
PGF_options:SetScript("OnShow", function(PGF_options)
	InterfaceOptionsFrame_OpenToCategory(PGF_optionsSettings)
end)

InterfaceOptions_AddCategory(PGF_options)
