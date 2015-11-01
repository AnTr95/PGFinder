local addon = ...
local L = PGFinderLocals

options = CreateFrame("Frame", addon .. "OptionFrame", InterefaceOPtionsFramePanelContainer)
options.name = "Premade Group Finder"
options:Hide()
options:SetScript("OnShow", function(options)
	InterfaceOptionsFrame_OpenToCategory(optionsSettings)
end)

InterfaceOptions_AddCategory(options)
