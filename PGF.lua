local addon = ... -- The name of the addon folder
local f = CreateFrame("Frame", nil, nil, BackdropTemplateMixin and "BackdropTemplate");
local L = PGFinderLocals -- Strings
local lastCat = nil;
local slowSearch = false;
local slowResults = {};
local slowCount = 0;
local slowTotal = 0;
local originalUI = {};
local ticks = 0;
local refreshTimeReset = 3;
local searchAvailable = true;
local signUpRoles = PGF_roles or {
	["TANK"] = false,
	["HEALER"] = false,
	["DPS"] = false,
};
local dungeonAbbrevations = {
	["The Nokhud Offensive"] = "NO",
	["Court of Stars"] = "COS",
	["Halls of Valor"] = "HOV",
	["Algeth'ar Academy"] = "AA",
	["Shadowmoon Burial Grounds"] = "SBG",
	["The Azure Vault"] = "AV",
	["Ruby Life Pools"] = "RLP",
	["Temple of the Jade Serpent"] = "TJS",
};

local roleRemainingKeyLookup = {
	["TANK"] = "TANK_REMAINING",
	["HEALER"] = "HEALER_REMAINING",
	["DAMAGER"] = "DAMAGER_REMAINING",
};

local classSpecilizationMap = {
    ["DEATHKNIGHT"] = {
        ["Blood"] = 250,
        ["Frost"] = 251,
        ["Unholy"] = 252,
        ["Initial"] = 1455
    },
    ["DEMONHUNTER"] = {
        ["Havoc"] = 577,
        ["Vengeance"] = 581,
        ["Initial"] = 1456
    },
    ["DRUID"] = {
        ["Balance"] = 102,
        ["Feral"] = 103,
        ["Guardian"] = 104,
        ["Restoration"] = 105,
        ["Initial"] = 1447
    },
    ["EVOKER"] = {
        ["Devastation"] = 1467,
        ["Preservation"] = 1468,
        ["Initial"] = 1465
    },
    ["HUNTER"] = {
        ["Beast Mastery"] = 253,
        ["Marksmanship"] = 254,
        ["Survival"] = 255,
        ["Initial"] = 1448
    },
    ["MAGE"] = {
        ["Arcane"] = 62,
        ["Fire"] = 63,
        ["Frost"] = 64,
        ["Initial"] = 1449
    },
    ["MONK"] = {
        ["Brewmaster"] = 268,
        ["Windwalker"] = 269,
        ["Mistweaver"] = 270,
        ["Initial"] = 1450
    },
    ["PALADIN"] = {
        ["Holy"] = 65,
        ["Protection"] = 66,
        ["Retribution"] = 70,
        ["Initial"] = 1451
    },
    ["PRIEST"] = {
        ["Discipline"] = 256,
        ["Holy"] = 257,
        ["Shadow"] = 258,
        ["Initial"] = 1452
    },
    ["ROGUE"] = {
        ["Assassination"] = 259,
        ["Outlaw"] = 260,
        ["Subtlety"] = 261,
        ["Initial"] = 1453
    },
    ["SHAMAN"] = {
        ["Elemental"] = 262,
        ["Enhancement"] = 263,
        ["Restoration"] = 264,
        ["Initial"] = 1444
    },
    ["WARLOCK"] = {
        ["Affliction"] = 265,
        ["Demonology"] = 266,
        ["Destruction"] = 267,
        ["Initial"] = 1454
    },
    ["WARRIOR"] = {
        ["Arms"] = 71,
        ["Fury"] = 72,
        ["Protection"] = 73,
        ["Initial"] = 1446
    }
};

--[[
SelectedInfo
	dungeons - saves which dungeons are selected
	levels - saves which levels are selected
	score - saves which score is required from the leader
	eligible - saves if the search should check for if the current roles in the players group is eligible with the slots left in the listed groups 
]]--
local selectedInfo = {
	["dungeons"] = {},
	["levels"] = {},
	["score"] = {},
	["eligible"] = {},
	["description"] = "",
};


local dungeonTextures = {};
f:SetFrameStrata("HIGH");
--[[
f:SetBackdrop({bgFile = "Interface/Tooltips/UI-Tooltip-Background", --Set the background and border textures
	edgeFile = "Interface/Tooltips/UI-Tooltip-Border", 
	tile = true, tileSize = 16, edgeSize = 16, 
	insets = { left = 4, right = 4, top = 4, bottom = 4 }
});
f:SetBackdropColor(0.3,0.3,0.3,0.6);
]]
f:SetPoint("RIGHT", LFGListFrame, "RIGHT", 600, 0);
f:SetSize(400, 300);
f:Hide();

--C_LFGList.GetSearchResultMemberInfo(resultID, playerIndex); returns: [1] = role, [2] = classUNIVERSAL, [3] = classLocal, [4] = spec

f:RegisterEvent("PLAYER_LOGIN");

local function saveOriginalUI()
	originalUI = {
		["PVEFrame"] = {}, 
		["LFGListFrame.SearchPanel.SearchBox"] = {["position"] = {}}, 
		["LFGListFrame.SearchPanel.FilterButton"] = {["position"] = {}}, 
		["LFGListFrame.SearchPanel.ResultsInset"] = {["position"] = {}}, 
		["LFGListFrame.SearchPanel.RefreshButton"] = {["position"] = {}},
		["LFGListFrame.SearchPanel.CategoryName"] = {["position"] = {}};
	};
	originalUI["PVEFrame"].width = PVEFrame:GetWidth();
	originalUI["PVEFrame"].height = PVEFrame:GetHeight();
	originalUI["LFGListFrame.SearchPanel.SearchBox"].size = LFGListFrame.SearchPanel.SearchBox:GetSize();
	originalUI["LFGListFrame.SearchPanel.SearchBox"].position[1], originalUI["LFGListFrame.SearchPanel.SearchBox"].position[2], originalUI["LFGListFrame.SearchPanel.SearchBox"].position[3], originalUI["LFGListFrame.SearchPanel.SearchBox"].position[4], originalUI["LFGListFrame.SearchPanel.SearchBox"].position[5] = LFGListFrame.SearchPanel.SearchBox:GetPoint();
	originalUI["LFGListFrame.SearchPanel.FilterButton"].size = LFGListFrame.SearchPanel.FilterButton:GetSize();
	originalUI["LFGListFrame.SearchPanel.FilterButton"].position[1], originalUI["LFGListFrame.SearchPanel.FilterButton"].position[2], originalUI["LFGListFrame.SearchPanel.FilterButton"].position[3], originalUI["LFGListFrame.SearchPanel.FilterButton"].position[4], originalUI["LFGListFrame.SearchPanel.FilterButton"].position[5] = LFGListFrame.SearchPanel.FilterButton:GetPoint();
	originalUI["LFGListFrame.SearchPanel.ResultsInset"].size = LFGListFrame.SearchPanel.ResultsInset:GetSize();
	originalUI["LFGListFrame.SearchPanel.ResultsInset"].position[1], originalUI["LFGListFrame.SearchPanel.ResultsInset"].position[2], originalUI["LFGListFrame.SearchPanel.ResultsInset"].position[3], originalUI["LFGListFrame.SearchPanel.ResultsInset"].position[4], originalUI["LFGListFrame.SearchPanel.ResultsInset"].position[5] = LFGListFrame.SearchPanel.ResultsInset:GetPoint();
	originalUI["LFGListFrame.SearchPanel.RefreshButton"].size = LFGListFrame.SearchPanel.RefreshButton:GetSize();
	originalUI["LFGListFrame.SearchPanel.RefreshButton"].position[1], originalUI["LFGListFrame.SearchPanel.RefreshButton"].position[2], originalUI["LFGListFrame.SearchPanel.RefreshButton"].position[3], originalUI["LFGListFrame.SearchPanel.RefreshButton"].position[4], originalUI["LFGListFrame.SearchPanel.RefreshButton"].position[5] = LFGListFrame.SearchPanel.RefreshButton:GetPoint();
	originalUI["LFGListFrame.SearchPanel.CategoryName"].position[1], originalUI["LFGListFrame.SearchPanel.CategoryName"].position[2], originalUI["LFGListFrame.SearchPanel.CategoryName"].position[3], originalUI["LFGListFrame.SearchPanel.CategoryName"].position[4], originalUI["LFGListFrame.SearchPanel.CategoryName"].position[5] = LFGListFrame.SearchPanel.CategoryName:GetPoint();
end

local function restoreOriginalUI()
	PVE_FRAME_BASE_WIDTH = 563;
	PVEFrame:SetSize(originalUI["PVEFrame"].width, originalUI["PVEFrame"].height);
	LFGListFrame.SearchPanel.SearchBox:ClearAllPoints();
	LFGListFrame.SearchPanel.RefreshButton:ClearAllPoints();
	LFGListFrame.SearchPanel.FilterButton:ClearAllPoints();
	LFGListFrame.SearchPanel.CategoryName:ClearAllPoints();
	LFGListFrame.SearchPanel.SearchBox:SetPoint(originalUI["LFGListFrame.SearchPanel.SearchBox"].position[1], originalUI["LFGListFrame.SearchPanel.SearchBox"].position[2], originalUI["LFGListFrame.SearchPanel.SearchBox"].position[3], originalUI["LFGListFrame.SearchPanel.SearchBox"].position[4], originalUI["LFGListFrame.SearchPanel.SearchBox"].position[5]);
	LFGListFrame.SearchPanel.FilterButton:SetPoint(originalUI["LFGListFrame.SearchPanel.FilterButton"].position[1], originalUI["LFGListFrame.SearchPanel.FilterButton"].position[2], originalUI["LFGListFrame.SearchPanel.FilterButton"].position[3], originalUI["LFGListFrame.SearchPanel.FilterButton"].position[4], originalUI["LFGListFrame.SearchPanel.FilterButton"].position[5]);
	LFGListFrame.SearchPanel.RefreshButton:SetPoint(originalUI["LFGListFrame.SearchPanel.RefreshButton"].position[1], originalUI["LFGListFrame.SearchPanel.RefreshButton"].position[2], originalUI["LFGListFrame.SearchPanel.RefreshButton"].position[3], originalUI["LFGListFrame.SearchPanel.RefreshButton"].position[4], originalUI["LFGListFrame.SearchPanel.RefreshButton"].position[5]);
	LFGListFrame.SearchPanel.CategoryName:SetPoint(originalUI["LFGListFrame.SearchPanel.CategoryName"].position[1], originalUI["LFGListFrame.SearchPanel.CategoryName"].position[2], originalUI["LFGListFrame.SearchPanel.CategoryName"].position[3], originalUI["LFGListFrame.SearchPanel.CategoryName"].position[4], originalUI["LFGListFrame.SearchPanel.CategoryName"].position[5]);
	LFGListFrame.SearchPanel.ResultsInset:SetPoint(originalUI["LFGListFrame.SearchPanel.ResultsInset"].position[1], originalUI["LFGListFrame.SearchPanel.ResultsInset"].position[2], originalUI["LFGListFrame.SearchPanel.ResultsInset"].position[3], originalUI["LFGListFrame.SearchPanel.ResultsInset"].position[4], originalUI["LFGListFrame.SearchPanel.ResultsInset"].position[5]);
end

local function ResolveCategoryFilters(categoryID, filters)
	-- Dungeons ONLY display recommended groups.
	if categoryID == GROUP_FINDER_CATEGORY_ID_DUNGEONS then
		return bit.band(bit.bnot(Enum.LFGListFilter.NotRecommended), bit.bor(filters, Enum.LFGListFilter.Recommended));
	end

	return filters;
end

local function updateSearch()
	LFGListFrame.SearchPanel.RefreshButton:Disable();
	C_LFGList.ClearSearchResults();
	local dungeonsSelected = PGF_GetSize(selectedInfo.dungeons);
	local count = 0;
	if (slowSearch == false) then
		if (selectedInfo.levels[1]) then
			searchBox:SetText(selectedInfo.levels[1]);
		end
		C_LFGList.Search(LFGListFrame.SearchPanel.categoryID, ResolveCategoryFilters(LFGListFrame.SearchPanel.categoryID, LFGListFrame.SearchPanel.filters), LFGListFrame.SearchPanel.preferredFilters, C_LFGList.GetLanguageSearchFilter());
	else
		slowTotal = dungeonsSelected;
		for k, v in ipairs(selectedInfo.dungeons) do
			C_Timer.After(3*count, function()
				print(v);
				print("starting search");
				C_LFGList.SetSearchToActivity(k);
				C_LFGList.Search(LFGListFrame.SearchPanel.categoryID, ResolveCategoryFilters(LFGListFrame.SearchPanel.categoryID, LFGListFrame.SearchPanel.filters), LFGListFrame.SearchPanel.preferredFilters, C_LFGList.GetLanguageSearchFilter());
			end);
			count = count + 1;
		end
		print("slow count is: " .. slowTotal);
	end
end

f:SetScript("OnUpdate", function(self, elapsed)
	ticks = ticks + elapsed;
	if (ticks >= refreshTimeReset) then
		LFGListFrame.SearchPanel.RefreshButton:Enable();
		searchAvailable = true;
		ticks = 0;
	end
end);

f:SetScript("OnEvent", function(self, event, ...) 
	if (event == "PLAYER_LOGIN") then
		if (PGF_roles == nil) then 
			local playerRole = GetSpecializationRole(GetSpecialization());
			PGF_roles = {["TANK"] = false, ["HEALER"] = false, ["DAMAGER"] = false};
			PGF_roles[playerRole] = true;
		end
	end
end);

f:SetScript("OnShow", function() 
	if (LFGListFrame.SearchPanel.categoryID) then
	end
end);

LFGListFrame.SearchPanel:HookScript("OnShow", function(self)
	local search = LFGListFrame.SearchPanel;
	search.SearchBox:SetFrameStrata("TOOLTIP");
	local cat = search.categoryID;
	if (cat and cat == GROUP_FINDER_CATEGORY_ID_DUNGEONS) then
		f:Show();
		PGF_ShowDungeonFrame();
		if (next(selectedInfo.dungeons)) then
			updateSearch();
		end
	end
end);

LFGListFrame.SearchPanel.RefreshButton:HookScript("OnClick", function(self)
	self:Disable();
end);

LFGListFrame.SearchPanel:HookScript("OnHide", function(self)
	f:Hide();
	restoreOriginalUI();
end);

local dungeonFrame = CreateFrame("Frame", nil, f);
local GUI = {};
local currentDungeonsActivityIDs = {};
--super expensive function
for index, challengeID in ipairs(C_ChallengeMode.GetMapTable()) do
	local name, id, timeLimit, texture, backgroundTexture = C_ChallengeMode.GetMapUIInfo(challengeID);
	local ogName = name;
	name = name .. " (Mythic Keystone)";
	for aID, aName in pairs(PGF_allDungeonsActivityIDs) do
		if (name == aName) then
			aName = dungeonAbbrevations[ogName] .. " (Keystone)";
			currentDungeonsActivityIDs[aID] = aName;
			dungeonTextures[aID] = texture;
			break;
		end
	end
end

dungeonFrame:SetPoint("TOPLEFT", PVEFrame, "TOPLEFT", 340, -10);
dungeonFrame:SetSize(f:GetWidth(), f:GetHeight());

do
	local count = 0;
	for index, dungeonName in pairs(currentDungeonsActivityIDs) do
		count = count + 1;
		local texture = dungeonFrame:CreateTexture(nil, "OVERLAY");
		texture:SetTexture(dungeonTextures[index]);
		texture:SetPoint("TOPLEFT", 18,-30-((count-1)*17));
		texture:SetSize(11, 11);
		local checkbox = CreateFrame("CheckButton", nil, dungeonFrame, "UICheckButtonTemplate");
		checkbox:SetSize(14,14);
		checkbox:SetPoint("TOPLEFT", texture, "TOPLEFT", 12, 2);
		checkbox:SetScript("OnClick", function(self)
			if (self:GetChecked()) then
				selectedInfo.dungeons[index] = true;
				local dungeonsSelected = PGF_GetSize(selectedInfo.dungeons);
				if (dungeonsSelected == 1) then
					local key, value = next(selectedInfo.dungeons);
					C_LFGList.SetSearchToActivity(key);
				else
					C_LFGList.ClearSearchTextFields();
				end
				updateSearch();
			else
				selectedInfo.dungeons[index] = nil;
				local dungeonsSelected = PGF_GetSize(selectedInfo.dungeons);
				if (dungeonsSelected == 1) then
					local key, value = next(selectedInfo.dungeons);
					C_LFGList.SetSearchToActivity(key);
				else
					C_LFGList.ClearSearchTextFields();
				end
				updateSearch();
			end
		end);
		local text = dungeonFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalTiny2");
		text:SetPoint("TOPLEFT", checkbox, "TOPLEFT", 12, -3);
		text:SetJustifyV("TOP");
		text:SetJustifyH("LEFT");
		text:SetText(dungeonName);
		text:SetFont(text:GetFont(), 8);
		text:SetTextColor(1,1,1,1);
		GUI[index] = {};
		GUI[index].text = text;
		GUI[index].checkbox = checkbox;
		GUI[index].texture = texture;
		text:Hide();
		checkbox:Hide();
	end
	count = count + 1;
	local slowSearchCheckBox = CreateFrame("CheckButton", nil, dungeonFrame, "UICheckButtonTemplate");
	slowSearchCheckBox:SetSize(14,14);
	slowSearchCheckBox:SetPoint("TOPLEFT", 30,-30-((count-1)*17));
	slowSearchCheckBox:SetScript("OnClick", function(self)
		if (self:GetChecked()) then
			slowSearch = true;
			updateSearch();
		else
			slowSearch = false;
			updateSearch();
		end
	end);
	local slowSearchtext = dungeonFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalTiny2");
	slowSearchtext:SetPoint("TOPLEFT", slowSearchCheckBox, "TOPLEFT", 12, -3);
	slowSearchtext:SetJustifyV("TOP");
	slowSearchtext:SetJustifyH("LEFT");
	slowSearchtext:SetText("Advanced Search");
	slowSearchtext:SetFont(slowSearchtext:GetFont(), 8);
	slowSearchtext:SetTextColor(1,1,1,1);
	local roleText = f:CreateFontString(nil, "ARTWORK", "GameFontNormalTiny2");
	roleText:SetFont(roleText:GetFont(), 7);
	roleText:SetPoint("TOPLEFT", slowSearchtext, "TOPLEFT", -15, -70);
	roleText:SetText(L.OPTIONS_ROLE);
	local canBeTank, canBeHealer, canBeDPS = UnitGetAvailableRoles("player");
	local dpsTexture = f:CreateTexture(nil, "OVERLAY");
	dpsTexture:SetTexture("Interface\\LFGFrame\\UI-LFG-ICON-ROLES");
	dpsTexture:SetPoint("TOPLEFT", roleText, 40, 1);
	dpsTexture:SetSize(11, 11);
	dpsTexture:SetTexCoord(GetTexCoordsForRole("DAMAGER"));
	local dpsButton = CreateFrame("CheckButton", nil, f, "UICheckButtonTemplate");
	dpsButton:SetSize(12, 12);
	dpsButton:SetPoint("TOPLEFT", dpsTexture, "TOPLEFT", 0, -12);
	if (canBeDPS == false) then
		dpsButton:Disable();
	end
	dpsButton:HookScript("OnClick", function(self)
		if (self:GetChecked()) then
			PGF_roles["DAMAGER"] = true;
			PlaySound(856);
		else
			PGF_roles["DAMAGER"] = false;
			PlaySound(857);
		end
	end);

	local healerTexture = f:CreateTexture(nil, "OVERLAY");
	healerTexture:SetTexture("Interface\\LFGFrame\\UI-LFG-ICON-ROLES");
	healerTexture:SetPoint("TOPLEFT", dpsTexture, 12, 0);
	healerTexture:SetSize(11, 11);
	healerTexture:SetTexCoord(GetTexCoordsForRole("HEALER"));
	local healerButon = CreateFrame("CheckButton", nil, f, "UICheckButtonTemplate");
	healerButon:SetSize(12, 12);
	healerButon:SetPoint("TOPLEFT", healerTexture, "TOPLEFT", 0, -12);
	if (canBeHealer == false) then
		healerButon:Disable();
	end
	healerButon:HookScript("OnClick", function(self)
		if (self:GetChecked()) then
			PGF_roles["HEALER"] = true;
			PlaySound(856);
		else
			PGF_roles["HEALER"] = false;
			PlaySound(857);
		end
	end);
	local tankTexture = f:CreateTexture(nil, "OVERLAY");
	tankTexture:SetTexture("Interface\\LFGFrame\\UI-LFG-ICON-ROLES");
	tankTexture:SetPoint("TOPLEFT", healerTexture, 12, 0);
	tankTexture:SetSize(11, 11);
	tankTexture:SetTexCoord(GetTexCoordsForRole("TANK"));
	local tankButton = CreateFrame("CheckButton", nil, f, "UICheckButtonTemplate");
	tankButton:SetSize(12, 12);
	tankButton:SetPoint("TOPLEFT", tankTexture, "TOPLEFT", 0, -12);
	if (canBeTank == false) then
		tankButton:Disable();
	end
	tankButton:HookScript("OnClick", function(self)
		if (self:GetChecked()) then
			PGF_roles["TANK"] = true;
			PlaySound(856);
		else
			PGF_roles["TANK"] = false;
			PlaySound(857);
		end
	end);
	GUI["DAMAGER"] = {["texture"] = dpsTexture, ["checkbox"] = dpsButton};
	GUI["HEALER"] = {["texture"] = healerTexture, ["checkbox"] = healerButon};
	GUI["TANK"] = {["texture"] = tankTexture, ["checkbox"] = tankButton};
end

--[[
	Splits the given keyword on each whitespace and stores it in a table
]]
function PGF_Split(keyword)
	local words = {}
	local count = 1
	for word in keyword:gmatch("%S+") do
		words[count] = word
		count = count + 1
	end
	return words
end

function PGF_ShowDungeonFrame()
	dungeonFrame:Show();
	if (next(originalUI) == nil) then
		saveOriginalUI();
	end
	PVEFrame:SetSize(800,428);
	PVE_FRAME_BASE_WIDTH = 800;
	LFGListFrame.SearchPanel.SearchBox:ClearAllPoints();
	LFGListFrame.SearchPanel.RefreshButton:ClearAllPoints();
	LFGListFrame.SearchPanel.FilterButton:ClearAllPoints();
	LFGListFrame.SearchPanel.CategoryName:ClearAllPoints();
	LFGListFrame.SearchPanel.SearchBox:SetPoint("TOPLEFT", dungeonFrame, "TOPLEFT", 25, -5);
	LFGListFrame.SearchPanel.RefreshButton:SetPoint("TOPLEFT", LFGListFrame.SearchPanel.SearchBox, "TOPLEFT", -50, 0);
	LFGListFrame.SearchPanel.FilterButton:SetPoint("BOTTOMRIGHT", PVEFrame, "BOTTOMRIGHT", -10, 5);
	LFGListFrame.SearchPanel.CategoryName:SetPoint("TOP", 135, -20);
	LFGListFrame.SearchPanel.ResultsInset:SetPoint("TOPLEFT", LFGListFrame, "TOPLEFT", -5, -40);
	for index, widgets in pairs(GUI) do
		local text = widgets.text;
		local checkbox = widgets.checkbox;
		local texture = widgets.texture;
		if (text) then
			text:Show();
		end
		if (checkbox) then
			checkbox:Show();
		end
		if (texture) then
			texture:Show();
		end
		if (selectedInfo.dungeons[index]) then
			checkbox:SetChecked(true);
		elseif (PGF_roles[index]) then
			checkbox:SetChecked(true);
		end
	end
end

--[[
	Checking if a table PGF_Contains a given value and if it does, what index is the value located at
	param(arr) table
	param(value) T - value to check exists
	return boolean or integer / returns false if the table does not contain the value otherwise it returns the index of where the value is locatedd
]]
function PGF_Contains(arr, value)
	if value == nil then
		return false
	end
	if arr == nil then
		return false
	end
	for k, v in pairs(arr) do
		if v == value then
			return k
		end
	end
	return false
end

--[[
	Returns the size of a table
	param(arr) table
	returns integer / The size of the table
]]
function PGF_GetSize(arr)
	local count = 0
	for k, v in pairs(arr) do
		count = count + 1
	end
	return count
end

local function PGF_LFGListSearchPanel_UpdateButtonStatus(self)
	--Update the SignUpButton
	local resultID = self.selectedResult;

	local isPartyLeader = UnitIsGroupLeader("player", LE_PARTY_CATEGORY_HOME);
	local canBrowseWhileQueued = C_LFGList.HasActiveEntryInfo();
	self.BackButton:SetShown(not canBrowseWhileQueued); 
	self.BackToGroupButton:SetShown(canBrowseWhileQueued)
end
hooksecurefunc("LFGListSearchPanel_UpdateButtonStatus", PGF_LFGListSearchPanel_UpdateButtonStatus);

local function PGF_LFGListApplicationViewer_UpdateInfo(self)
	self.BrowseGroupsButton:SetShown(true);
	self.RemoveEntryButton:SetPoint("LEFT", self.BrowseGroupsButton, "RIGHT", 15, 0);
end

hooksecurefunc("LFGListApplicationViewer_UpdateInfo", PGF_LFGListApplicationViewer_UpdateInfo);

local roleIndex = {["TANK"] = 1, ["HEALER"] = 2, ["DAMAGER"] = 3};

local function sortRoles(pl1, pl2)
	return roleIndex[pl1.role] < roleIndex[pl2.role];
end

--[[
	@self -
	@numPlayers - always 5 (max groupSize?)
	@displayData - keeps the amount of each roles, remaining roles and amount of each classes in the group example ["DAMAGER"] = 1, ["DAMAGER_REMAINING"] = 2, ["MAGE"] = 1
	@disabled - group is delisted
	@iconOrder - [1] = TANK, [2] = HEALER, [3] = DAMAGER
]]
local function PGF_LFGListGroupDataDisplayEnumerate_Update(self, numPlayers, displayData, disabled, iconOrder)
	local players = {};
	for i=1, #self.Icons do
		if (i > numPlayers) then
			self.Icons[i]:Show();
			self.Icons[i]:SetDesaturated(disabled);
			self.Icons[i]:SetAlpha(disabled and 0.5 or 1.0);
		end
	end
	local resultID = self:GetParent():GetParent().resultID;
	if (not resultID) then 
		return;
	end
	local searchResults = C_LFGList.GetSearchResultInfo(resultID);
	--Note that icons are numbered from right to left
	for i = 1, searchResults.numMembers do
		local role, classUniversal, classLocal, spec = C_LFGList.GetSearchResultMemberInfo(resultID, i);
		--spec = spec:gsub("%s","");
		table.insert(players, {["role"] = role, ["class"] = classUniversal, ["spec"] = spec});
	end
	table.sort(players, sortRoles);
	--Another imp
	for i = 1, searchResults.numMembers do
		if (true or players[i].class == "EVOKER") then
			self.Icons[6-i]:SetTexture(select(4, GetSpecializationInfoByID(classSpecilizationMap[players[i].class][players[i].spec])));
			self.Icons[6-i]:SetTexCoord(0,1,0,1);
		else
			self.Icons[6-i]:SetAtlas("GarrMission_ClassIcon-"..strlower(players[i].class).."-"..players[i].spec, false);
		end
	end
	local count = 1;
	for i = 3, 1, -1 do
		for j = 1, displayData[roleRemainingKeyLookup[iconOrder[i]]] do
			self.Icons[count]:SetTexture("Interface\\addons\\PGFinder\\Res\\" .. roleRemainingKeyLookup[iconOrder[i]]);
			self.Icons[count]:SetTexCoord(0,1,0,1);
			count = count + 1;
		end
	end
end

hooksecurefunc("LFGListGroupDataDisplayEnumerate_Update", PGF_LFGListGroupDataDisplayEnumerate_Update);

function LFGListSearchPanel_UpdateResultList(self)
	if(next(selectedInfo.dungeons) == nil) then
		LFGListFrame.SearchPanel.RefreshButton:Disable();
		self.totalResults, self.results = C_LFGList.GetFilteredSearchResults();
		self.applications = C_LFGList.GetApplications();
		LFGListUtil_SortSearchResults(self.results);
		LFGListSearchPanel_UpdateResults(self);
		print("initial results: " .. self.totalResults);
		return true;
	end
	if (slowSearch == false) then
		LFGListFrame.SearchPanel.RefreshButton:Disable();
		self.totalResults, self.results = C_LFGList.GetFilteredSearchResults();
		print("total before filter: " .. self.totalResults);
		local newResults = {};
		for i = 1, #self.results do
			local searchResults = C_LFGList.GetSearchResultInfo(self.results[i]);
			local activityID = searchResults.activityID;
			local activityInfo = C_LFGList.GetActivityInfoTable(activityID);
			local activityFullName = activityInfo.fullName;
			local isMythicPlusActivity = isMythicPlusActivity;
			local leaderName = searchResults.leaderName;
			local name = searchResults.name;
			local isDelisted = searchResults.isDelisted;
			local age = searchResults.age;
			local leaderOverallDungeonScore = searchResults.leaderOverallDungeonScore;
			local leaderDungeonScoreInfo = searchResults.leaderDungeonScoreInfo;
			local requiredDungeonScore = searchResults.requiredDungeonScore;
			local _, appStatus, pendingStatus, appDuration = C_LFGList.GetApplicationInfo(self.results[i]);
			if (selectedInfo.dungeons[activityID]) then
				if (requiredDungeonScore == nil or C_ChallengeMode.GetOverallDungeonScore() >= requiredDungeonScore) then
					table.insert(newResults, self.results[i]);
				end
			end
		end
		LFGListUtil_SortSearchResults(newResults);
		self.totalResults = #newResults;
		self.results = newResults;
		self.applications = C_LFGList.GetApplications();
		LFGListSearchPanel_UpdateResults(self);
		print("total after filter: " .. self.totalResults);
		return true;
	else
		slowCount = slowCount + 1;
		print("count is " .. slowCount)
		self.totalResults, self.results = C_LFGList.GetFilteredSearchResults();
		print("found results: " .. self.totalResults)
		for i = 1, #self.results do
			local searchResults = C_LFGList.GetSearchResultInfo(self.results[i]);
			local activityID = searchResults.activityID;
			local activityInfo = C_LFGList.GetActivityInfoTable(activityID);
			local activityFullName = activityInfo.fullName;
			local isMythicPlusActivity = isMythicPlusActivity;
			local leaderName = searchResults.leaderName;
			local name = searchResults.name;
			local isDelisted = searchResults.isDelisted;
			local age = searchResults.age;
			local leaderOverallDungeonScore = searchResults.leaderOverallDungeonScore;
			local leaderDungeonScoreInfo = searchResults.leaderDungeonScoreInfo;
			local requiredDungeonScore = searchResults.requiredDungeonScore;
			local _, appStatus, pendingStatus, appDuration = C_LFGList.GetApplicationInfo(self.results[i]);
			if (selectedInfo.dungeons[activityID]) then
				if (requiredDungeonScore == nil or C_ChallengeMode.GetOverallDungeonScore() >= requiredDungeonScore) then
					table.insert(slowResults, self.results[i]);
				end
			end
		end
		if (slowCount == slowTotal) then
			print("slow total before filter: " .. self.totalResults);
			LFGListUtil_SortSearchResults(slowResults);
			self.totalResults = #slowResults;
			self.results = slowResults;
			self.applications = C_LFGList.GetApplications();
			LFGListSearchPanel_UpdateResults(self);
			print("slow total after filter: " .. self.totalResults);
			return true;
		end
	end
end

function PGF_DevGenerateAllActivityIDs()
	PGF_DevAllActivityIDs = {
		["dungeons"] = {},
		["raids"] = {},
		["other"] = {},
		["nil"] = {},
	};
	PGF_DevDungeonsActivityIDs = {};
	PGF_DevRaidDungeonsActivityIDs = {};
	for i = 1, 1400 do
		local activityInfo = C_LFGList.GetActivityInfoTable(i);
		if (activityInfo) then
			local cat = activityInfo.categoryID;
			if (cat and cat == GROUP_FINDER_CATEGORY_ID_DUNGEONS) then
				PGF_DevAllActivityIDs["dungeons"][i] = activityInfo;
				PGF_DevDungeonsActivityIDs[i] = activityInfo.fullName;
			elseif (cat and cat == 3) then
				PGF_DevAllActivityIDs["raids"][i] = activityInfo;
				PGF_DevRaidDungeonsActivityIDs[i] = activityInfo.fullName;
			else
				PGF_DevAllActivityIDs["other"][i] = activityInfo;
			end
		else
			PGF_DevAllActivityIDs["nil"][i] = "nil";
		end
	end
end

--hooksecurefunc("LFGListSearchPanel_UpdateResultList", PGF_Search);
function LFGListSearchPanel_SelectResult(self, resultID)
	self.selectedResult = resultID;
	LFGListSearchPanel_UpdateResults(self);
	if ((true or PGF_autoSign) and (IsInGroup() == false or UnitIsGroupLeader("player"))) then
		if (selectedInfo["description"]) then

		end
		C_LFGList.ApplyToGroup(LFGListFrame.SearchPanel.selectedResult, PGF_roles["TANK"], PGF_roles["HEALER"], PGF_roles["DAMAGER"]);
	end
end
--[[
LFGListSearchEntry:HookScript("OnClick", function(self)
	if (true or PGF_autoSign) then
		C_LFGList.ApplyToGroup(LFGListFrame.SearchPanel.selectedResult, false, false, true);
	end
end);
]]

LFGListApplicationDialog:HookScript("OnShow", function(self)
	local apps = C_LFGList.GetApplications();
	if(IsInGroup() and not UnitIsGroupLeader("player")) then
		if (PGF_roles["TANK"]) then
	    	LFDRoleCheckPopupRoleButtonTank.checkButton:SetChecked(true);
	    else
	   		LFDRoleCheckPopupRoleButtonTank.checkButton:SetChecked(false);
	    end
	    if (PGF_roles["HEALER"]) then
	    	LFDRoleCheckPopupRoleButtonHealer.checkButton:SetChecked(true);
	    else
	    	LFDRoleCheckPopupRoleButtonHealer.checkButton:SetChecked(false);
	    end
	    if (PGF_roles["DAMAGER"]) then
	        LFDRoleCheckPopupRoleButtonDPS.checkButton:SetChecked(true);
	    else
	    	LFDRoleCheckPopupRoleButtonHealer.checkButton:SetChecked(false);
	    end
		LFDRoleCheckPopupAcceptButton:Enable();
		LFDRoleCheckPopupAcceptButton:Click();
	elseif (true or PGF_autoSign) then
		LFGListApplicationDialog:Hide();
	end
end);

local function HasRemainingSlotsForLocalPlayerRole(lfgSearchResultID)
	local roles = C_LFGList.GetSearchResultMemberCounts(lfgSearchResultID);
	local playerRole = GetSpecializationRole(GetSpecialization());
	local groupRoles = {["TANK"] = 0, ["HEALER"] = 0, ["DAMAGER"] = 0};
	groupRoles[playerRole] = groupRoles[playerRole] + 1;
	if (IsInGroup()) then
		for i = 1, GetNumGroupMembers()-1 do --excludes the player
			local role = UnitGroupRolesAssigned("party"..i);
			if (role and role ~= "NONE") then
				groupRoles[role] = groupRoles[role] + 1;
			end
		end
		for role, amount in pairs(groupRoles) do
			if (roles[roleRemainingKeyLookup[role]] < amount) then
				return false;
			end
		end
		return true;
	else
		return roles[roleRemainingKeyLookup[playerRole]] > 0;
	end
end

--[[
	Overrides Blizzards function, sorting by date rather than ID
--]]
function LFGListUtil_SortSearchResultsCB(id1, id2)
	local result1 = C_LFGList.GetSearchResultInfo(id1);
	local result2 = C_LFGList.GetSearchResultInfo(id2);
	local _, appStatus1, pendingStatus1, appDuration1 = C_LFGList.GetApplicationInfo(id1);
	local _, appStatus2, pendingStatus2, appDuration2 = C_LFGList.GetApplicationInfo(id2);
	if (appStatus1 ~= appStatus2) then
		if (appStatus1 == "applied") then
			return true;
		elseif (appStatus2 == "applied") then
			return false;
		end
	end
	if (result1.numBNetFriends ~= result2.numBNetFriends) then
		return result1.numBNetFriends > result2.numBNetFriends;
	end
	if (result1.numCharFriends ~= result2.numCharFriends) then
		return result1.numCharFriends > result2.numCharFriends;
	end
	if (result1.numGuildMates ~= result2.numGuildMates) then
		return result1.numGuildMates > result2.numGuildMates;
	end
	local hasRemainingRole1 = HasRemainingSlotsForLocalPlayerRole(id1);
	local hasRemainingRole2 = HasRemainingSlotsForLocalPlayerRole(id2);

	-- Groups with your current role available are preferred
	if (hasRemainingRole1 ~= hasRemainingRole2) then
		return hasRemainingRole1;
	end
	
	if (result1.age ~= result2.age) then
		return result1.age < result2.age;
	end
	return id1 < id2;
end

function PGF_GetPlaystyleString()
    -- By overwriting C_LFGList.GetPlaystyleString, we taint the code writing the tooltip (which does not matter),
    -- and also code related to the dropdows where you can select the playstyle. The only relevant protected function
    -- here is C_LFGList.SetEntryTitle, which is only called from LFGListEntryCreation_SetTitleFromActivityInfo.
    -- Players that do not have an authenticator attached to their account cannot set the title or comment when creating
    -- groups. Instead, Blizzard sets the title programmatically. If we taint this function, these players can not create
    -- groups anymore, so we check on an arbitrary mythic plus dungeon if the player is authenticated to create a group.
    local activityIdOfArbitraryMythicPlusDungeon = 1160 -- Algeth'ar Academy
    if not C_LFGList.IsPlayerAuthenticatedForLFG(activityIdOfArbitraryMythicPlusDungeon) then
        return
    end

    -- Overwrite C_LFGList.GetPlaystyleString with a custom implementation because the original function is
    -- hardware protected, causing an error when a group tooltip is shown as we modify the search result list.
    -- Original code from https://github.com/ChrisKader/LFMPlus/blob/36bca68720c724bf26cdf739614d99589edb8f77/core.lua#L38
    -- but sligthly modified.
    C_LFGList.GetPlaystyleString = function(playstyle, activityInfo)
        if not ( activityInfo and playstyle and playstyle ~= 0
                and C_LFGList.GetLfgCategoryInfo(activityInfo.categoryID).showPlaystyleDropdown ) then
            return nil
        end
        local globalStringPrefix
        if activityInfo.isMythicPlusActivity then
            globalStringPrefix = "GROUP_FINDER_PVE_PLAYSTYLE"
        elseif activityInfo.isRatedPvpActivity then
            globalStringPrefix = "GROUP_FINDER_PVP_PLAYSTYLE"
        elseif activityInfo.isCurrentRaidActivity then
            globalStringPrefix = "GROUP_FINDER_PVE_RAID_PLAYSTYLE"
        elseif activityInfo.isMythicActivity then
            globalStringPrefix = "GROUP_FINDER_PVE_MYTHICZERO_PLAYSTYLE"
        end
        return globalStringPrefix and _G[globalStringPrefix .. tostring(playstyle)] or nil
    end

    -- Disable automatic group titles to prevent tainting errors
    LFGListEntryCreation_SetTitleFromActivityInfo = function(_) end
end

PGF_GetPlaystyleString();