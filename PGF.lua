local addon = ...; -- The name of the addon folder
local L = PGFinderLocals; -- Strings

--[[
	Documentation: Creating the main frame that is always showed regardless of category
]]

local f = CreateFrame("Frame", nil, PVEFrame);
f:SetFrameStrata("HIGH");
f:SetPoint("RIGHT", LFGListFrame.SearchPanel.ResultsInset, "RIGHT", 395, 55);
f:SetFrameLevel(800);
f:SetSize(400, 300);
f:Hide();

--[[
	Documentation: Lets cache all of the global functions that are heavily used to improve perforrmance
]]

local LFGListFrame = LFGListFrame;
local PVEFrame = PVEFrame;

local LFGListSearchPanel_UpdateResults = LFGListSearchPanel_UpdateResults;
local LFGListGroupDataDisplay_Update = LFGListGroupDataDisplay_Update;
local GetAchievementInfo = GetAchievementInfo;
local GetAchievementLink = GetAchievementLink;
local IsInGroup = IsInGroup;
local UnitIsGroupLeader = UnitIsGroupLeader;
local UnitGroupRolesAssigned = UnitGroupRolesAssigned;
local GetSpecialization = GetSpecialization;
local GetSpecializationRole = GetSpecializationRole;
local GetSpecializationInfoByID = GetSpecializationInfoByID;
local GetNumGroupMembers = GetNumGroupMembers;
local GetTimePreciseSec = GetTimePreciseSec;
local ClearAllPoints = ClearAllPoints;
local SetSize = SetSize;
local SetPoint = SetPoint;
local SetText = SetText;
local SetScript = SetScript;
local SetTexture = SetTexture;
local SetJustifyH = SetJustifyH;
local SetAtlas = SetAtlas;
local SetTextColor = SetTextColor;
local SetAlpha = SetAlpha;
local GetParent = GetParent
local SetDesaturated = SetDesaturated;
local SetTexture = SetTexture;
local SetTexCoord = SetTexCoord;
local SetShown = SetShown;
local GetWidth = GetWidth;
local GetHeight = GetHeight;
local GetPoint = GetPoint;
local Show = Show;
local Hide = Hide;
local format = format;
local unpack = unpack;
local next = next; 
local math = math;
local table = table;
local string = string;
local strlower = strlower;
local refreshButtonClick = LFGListFrame.SearchPanel.RefreshButton:GetScript("OnClick"); --save the OnClick functionality to be able to temporarily move it and put it back when needed

--[[
	Documentation: Creating all local variables.
	To add a new raid:
	Update the dropdownMenuStates
	Add the activityID to the raidStateMap
	Add the abbreviated version of the raid name to the bossNameMap and all of the bosses long and short names
	Add the abbreviated version of the raid name to the bossOrderMap and all long names of the bosses in the prefered order
	Add the boss paths to the PATHs graph
	Add the abbreviated name of the raid to the raidAbbrerviations
	Add all achievement IDs to the achievementID array using the generic raid name (without difficulty)
	Update isNextBoss function to cover first boss and post multiple wing bosses i.e Broodkeeper
	Add the activityIDs of all difficulties to PGF_allRaidsActivityIDs

	To add a new dungeon:
	Add the abbreviated name of the dungeon to the dungeonAbbrerviations
	Add the activityIDs of all difficulties to PGF_allDungeonsActivityIDs
]]

local lastCat = nil;
local slowSearch = false;
local slowResults = {};
local slowCount = 0;
local slowTotal = 0;
local originalUI = {};
local ticks = 0;
local refreshTimeReset = 3; --defines the time that must pass between searches
local searchAvailable = true;
local dungeonStates = {"Normal", "Heroic", "Mythic", "Mythic+ (Keystone)"}; --visible states for the dropdown
local raidStates = {"VOTI Normal", "VOTI Heroic", "VOTI Mythic", "VOTI All"}; --visible states for the dropdown
local sortingStates = {[1] = "Time", [2] = "Score"};
local lastSelectedDungeonState = "";
local lastSelectedRaidState = "";
local performanceTimeStamp = 0;
local version = GetAddOnMetadata(addon, "Version");
local recievedOutOfDateMessage = false;
local FRIEND_ONLINE = ERR_FRIEND_ONLINE_SS:match("%s(.+)") -- Converts "[%s] has come online". to "has come online".
--[[
	Documentation: These maps changes the visible state that the user selects and converts it to match the dungeon/raids actual difficulty name/activityID
]]
local dungeonStateMap = {
	["Normal"] = "(Normal)",
	["Heroic"] = "(Heroic)",
	["Mythic"] = "(Mythic)",
	["Mythic+ (Keystone)"] = "(Mythic Keystone)",
};
local raidStateMap = {
	["VOTI Normal"] = 1189,
	["VOTI Heroic"] = 1190,
	["VOTI Mythic"] = 1191,
	["VOTI All"] = 1191, --no activity ID for this so lets take the boss data from mythic
};
--[[
	Documentation: This sets the order of that the bosses will show in the UI
]]
local bossOrderMap = {
	["VOTI"] = {
		"Eranog",
		"The Primal Council",
		"Dathea, Ascended",
		"Terros",
		"Sennarth, The Cold Breath",
		"Kurog Grimtotem",
		"Broodkeeper Diurna",
		"Raszageth the Storm-Eater",
		"Fresh"
	};
};
--[[
	Documentation: This converts the names used in the GUIs for the user to see with the actual names in the code.
]]
local bossNameMap = {
	["VOTI"] = {
		["Eranog"] = "Eranog",
		["Terros"] = "Terros",
		["The Primal Council"] = "Council",
		["Dathea, Ascended"] = "Dathea",
		["Sennarth, The Cold Breath"] = "Sennarth",
		["Kurog Grimtotem"] = "Kurog",
		["Broodkeeper Diurna"] = "Broodkeeper",
		["Raszageth the Storm-Eater"] = "Raszageth",
		["Fresh"] = "Fresh Run",
	},
};
local dungeonAbbreviations = {
	["The Nokhud Offensive"] = "NO",
	["Court of Stars"] = "COS",
	["Halls of Valor"] = "HOV",
	["Algeth'ar Academy"] = "AA",
	["Shadowmoon Burial Grounds"] = "SBG",
	["The Azure Vault"] = "AV",
	["Ruby Life Pools"] = "RLP",
	["Temple of the Jade Serpent"] = "TJS",
	["Brackenhide Hollow"] = "BH",
	["Halls of Infusion"] = "HOI",
	["Uldaman: Legacy of Tyr"] = "ULT",
	["Neltharus"] = "NEL",
	["Neltharion's Lair"] = "NL",
	["Freehold"] = "FH",
	["Temple of Sethraliss"] = "TOS",
	["The Vortex Pinnacle"] = "VP",
};

local raidAbbreviations = {
	["Vault of the Incarnates"] = "VOTI",
};
--[[
	Documentation: This is DAG that defines which bosses are after and which are before the selected boss and is used for figuring out what boss is next based on the raid lockout
]]
local VOTI_Path = {
	["Eranog"] = {
		["children_paths"] = {
			{"Terros", "Sennarth", "Kurog", "Council", "Dathea", "Broodkeeper", "Raszageth"},
			{"Council", "Dathea", "Terros", "Sennarth", "Kurog", "Broodkeeper", "Raszageth"},
			{"Broodkeeper", "Raszageth"}
		},
		["parent_paths"] = {},
	},
	["Terros"] = {
		["children_paths"] = {
			{"Sennarth", "Kurog", "Council", "Dathea", "Broodkeeper", "Raszageth"},
			{"Dathea", "Broodkeeper", "Raszageth"}
		},
		["parent_paths"] = {
			{"Eranog"},
			{"Dathea", "Council", "Eranog"},
		},
	},
	["Sennarth"] = {
		["children_paths"] = {
			{"Kurog", "Council", "Dathea", "Broodkeeper", "Raszageth"},
			{"Kurog", "Broodkeeper", "Raszageth"}
		},
		["parent_paths"] = {
			{"Terros", "Eranog"},
			{"Terros", "Dathea", "Council", "Eranog"},
		},
	},
	["Kurog"] = {
		["children_paths"] = {
			{"Council", "Dathea", "Broodkeeper", "Raszageth"},
			{"Broodkeeper", "Raszageth"}
		},
		["parent_paths"] = {
			{"Sennarth", "Terros", "Eranog"},
			{"Sennarth", "Terros", "Dathea", "Council", "Eranog"},
		},
	},
	["Council"] = {
		["children_paths"] = {
			{"Dathea", "Broodkeeper", "Raszageth"},
			{"Terros", "Sennarth", "Kurog", "Broodkeeper", "Raszageth"},
		},
		["parent_paths"] = {
			{"Eranog"},
			{"Kurog", "Sennarth", "Terros", "Eranog"},
		},
	},
	["Dathea"] = {
		["children_paths"] = {
			{"Terros", "Broodkeeper", "Raszageth"},
			{"Broodkeeper", "Raszageth"}
		},
		["parent_paths"] = {
			{"Council", "Eranog"},
			{"Council", "Kurog", "Sennarth", "Terros", "Eranog"},
		},
	},
	["Broodkeeper"] = {
		["children_paths"] = {
			{"Raszageth"}
		},
		["parent_paths"] = {
			{"Eranog"},
			{"Dathea", "Council", "Kurog", "Sennarth", "Terros", "Eranog"},
			{"Kurog", "Sennarth", "Terros", "Dathea", "Council", "Eranog"},
		},
	},
	["Raszageth"] = {
		["children_paths"] = {},
		["parent_paths"] = {
			{"Broodkeeper", "Eranog"},
			{"Broodkeeper", "Dathea", "Council", "Kurog", "Sennarth", "Terros", "Eranog"},
			{"Broodkeeper", "Kurog", "Sennarth", "Terros", "Dathea", "Council", "Eranog"},
		},
	}
};

--[[
	Documentation: This is a blizzard variable that is used in the HasRemainingSlotsForLocalPlayerRole function
]]
local roleRemainingKeyLookup = {
	["TANK"] = "TANK_REMAINING",
	["HEALER"] = "HEALER_REMAINING",
	["DAMAGER"] = "DAMAGER_REMAINING",
};

--[[
	Documentation: This is an array that converts a class name and specilization name to an ID used to fetch the textures for that spec
]]

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

local roleIndex = {["TANK"] = 1, ["HEALER"] = 2, ["DAMAGER"] = 3}; --Syncs the order of displayData to ensure tanks are always most left etc

--[[
	Documentation:
		dungeons(arr) - saves which dungeons are selected
		levels(arr) - saves which levels are selected
		score(arr) - saves which score is required from the leader
		eligible(arr) - saves if the search should check for if the current roles in the players group is eligible with the slots left in the listed groups 
		description(string) - saves the description used when applying to groups
		leaderScore(int) - saves the lowest allowed score of the leader in dungeon groups
		raids(arr) - saves which raids are selected
		bosses(arr) - saves which bosses are selected
]]
local selectedInfo = {
	["dungeons"] = {},
	["levels"] = {},
	["score"] = {},
	["eligible"] = {},
	["description"] = "",
	["leaderScore"] = 0,
	["raids"] = {},
	["bosses"] = {},
};

--[[
	Documentation: All of the achievementIDs for CE, Mythic Boss, AOTC, Normal Clear. Order decides which one is best, lower key = better
]]
local achievementIDs = {
	["Vault of the Incarnates"] = {17108, 16352, 16350, 16351, 16349, 16347, 16346, 16348, 16346, 17107, 16343},
};

--[[
	Documentation: All of the red, green, blue values for the leader score. The score must be equal or above the key to use the r, g, b value
]]
local scoreColors = {
	[3450] = {1.00, 0.50, 0.00},
	[3385] = {1.00, 0.49, 0.08},
	[3365] = {0.99, 0.49, 0.13},
	[3340] = {0.99, 0.48, 0.17},
	[3315] = {0.98, 0.47, 0.20},
	[3290] = {0.98, 0.46, 0.23},
	[3265] = {0.97, 0.45, 0.25},
	[3245] = {0.97, 0.45, 0.28},
	[3220] = {0.96, 0.44, 0.31},
	[3195] = {0.96, 0.43, 0.33},
	[3170] = {0.95, 0.42, 0.35},
	[3145] = {0.95, 0.41, 0.38},
	[3125] = {0.94, 0.40, 0.40},
	[3100] = {0.93, 0.40, 0.42},
	[3075] = {0.93, 0.39, 0.44},
	[3050] = {0.92, 0.38, 0.46},
	[3025] = {0.91, 0.37, 0.48},
	[3005] = {0.91, 0.36, 0.50},
	[2980] = {0.90, 0.36, 0.52},
	[2955] = {0.89, 0.35, 0.55},
	[2930] = {0.88, 0.34, 0.56},
	[2905] = {0.87, 0.33, 0.58},
	[2885] = {0.86, 0.33, 0.60},
	[2860] = {0.85, 0.32, 0.62},
	[2835] = {0.84, 0.31, 0.64},
	[2810] = {0.83, 0.30, 0.66},
	[2785] = {0.82, 0.29, 0.68},
	[2765] = {0.81, 0.28, 0.70},
	[2740] = {0.80, 0.28, 0.72},
	[2715] = {0.79, 0.27, 0.74},
	[2690] = {0.78, 0.26, 0.76},
	[2665] = {0.77, 0.25, 0.78},
	[2645] = {0.76, 0.24, 0.80},
	[2620] = {0.75, 0.23, 0.82},
	[2595] = {0.74, 0.22, 0.84},
	[2570] = {0.70, 0.23, 0.87},
    [2545] = {0.68, 0.22, 0.89},
    [2525] = {0.66, 0.22, 0.91},
    [2500] = {0.64, 0.21, 0.93},
    [2455] = {0.62, 0.23, 0.93},
    [2430] = {0.60, 0.25, 0.93},
    [2405] = {0.58, 0.27, 0.92},
    [2385] = {0.57, 0.28, 0.92},
    [2360] = {0.55, 0.29, 0.92},
    [2335] = {0.53, 0.31, 0.91},
    [2310] = {0.51, 0.32, 0.91},
    [2285] = {0.49, 0.33, 0.91},
    [2265] = {0.47, 0.35, 0.90},
    [2240] = {0.44, 0.36, 0.90},
    [2215] = {0.42, 0.36, 0.90},
    [2190] = {0.40, 0.38, 0.89},
    [2165] = {0.37, 0.38, 0.89},
    [2145] = {0.34, 0.39, 0.89},
    [2120] = {0.31, 0.40, 0.88},
    [2095] = {0.28, 0.41, 0.88},
    [2070] = {0.24, 0.42, 0.88},
    [2045] = {0.19, 0.42, 0.87},
    [2025] = {0.13, 0.43, 0.87},
    [2000] = {0.00, 0.44, 0.87},
    [1930] = {0.09, 0.45, 0.85},
	[1905] = {0.14, 0.46, 0.84},
	[1880] = {0.18, 0.47, 0.83},
	[1855] = {0.20, 0.49, 0.82},
	[1830] = {0.23, 0.49, 0.81},
	[1810] = {0.25, 0.51, 0.80},
	[1785] = {0.26, 0.52, 0.78},
	[1760] = {0.28, 0.53, 0.77},
	[1735] = {0.29, 0.54, 0.76},
	[1710] = {0.30, 0.55, 0.75},
	[1690] = {0.31, 0.56, 0.73},
	[1665] = {0.32, 0.58, 0.72},
	[1640] = {0.33, 0.59, 0.71},
	[1615] = {0.34, 0.60, 0.69},
	[1590] = {0.35, 0.61, 0.68},
	[1570] = {0.35, 0.62, 0.67},
	[1545] = {0.36, 0.64, 0.66},
	[1520] = {0.36, 0.65, 0.65},
	[1495] = {0.36, 0.66, 0.63},
	[1470] = {0.37, 0.67, 0.62},
	[1450] = {0.37, 0.68, 0.61},
	[1425] = {0.37, 0.69, 0.59},
	[1400] = {0.37, 0.71, 0.58},
	[1375] = {0.37, 0.72, 0.56},
	[1350] = {0.37, 0.73, 0.55},
	[1330] = {0.37, 0.74, 0.54},
	[1305] = {0.37, 0.76, 0.52},
	[1280] = {0.37, 0.77, 0.51},
	[1255] = {0.37, 0.78, 0.49},
	[1230] = {0.36, 0.79, 0.48},
	[1210] = {0.36, 0.80, 0.46},
	[1185] = {0.36, 0.82, 0.45},
	[1160] = {0.35, 0.83, 0.43},
	[1135] = {0.35, 0.84, 0.42},
	[1110] = {0.34, 0.85, 0.40},
	[1090] = {0.33, 0.86, 0.38},
	[1065] = {0.32, 0.87, 0.36},
	[1040] = {0.31, 0.89, 0.34},
	[1015] = {0.30, 0.90, 0.32},
	[990] = {0.29, 0.91, 0.30},
	[970] = {0.27, 0.93, 0.28},
	[945] = {0.26, 0.94, 0.25},
	[920] = {0.24, 0.95, 0.22},
	[895] = {0.22, 0.96, 0.19},
	[870] = {0.19, 0.98, 0.15},
	[850] = {0.16, 0.99, 0.10},
	[825] = {0.12, 1.00, 0.00},
	[800] = {0.23, 1.00, 0.13 },
	[775] = {0.30, 1.00, 0.20 },
	[750] = {0.36, 1.00, 0.25 },
	[725] = {0.41, 1.00, 0.30 },
	[700] = {0.45, 1.00, 0.34 },
	[675] = {0.49, 1.00, 0.38 },
	[650] = {0.53, 1.00, 0.42 },
	[625] = {0.56, 1.00, 0.45 },
	[600] = {0.60, 1.00, 0.49 },
	[575] = {0.63, 1.00, 0.52 },
	[550] = {0.66, 1.00, 0.56 },
	[525] = {0.69, 1.00, 0.59 },
	[500] = {0.71, 1.00, 0.62 },
	[475] = {0.74, 1.00, 0.65 },
	[450] = {0.77, 1.00, 0.69 },
	[425] = {0.79, 1.00, 0.72 },
	[400] = {0.82, 1.00, 0.75 },
	[375] = {0.84, 1.00, 0.78 },
	[350] = {0.87, 1.00, 0.81 },
	[325] = {0.89, 1.00, 0.84 },
	[300] = {0.91, 1.00, 0.87 },
	[275] = {0.93, 1.00, 0.91 },
	[250] = {0.96, 1.00, 0.94 },
	[225] = {0.98, 1.00, 0.97 },
	[200] = {1.00, 1.00, 1.00 },
	[0] = {0.62, 0.62, 0.62},
};

--[[
	Documentation: Lets precompute the scoreColor table to a lookup table to reduce the time complexity to O(1) as this is called extremly frequently.
	Creates a table from 0-3450 as keys with the r,g,b value of the scoreTable for each score that is between 2 scoreTable keys
]]
local colorLookup = {};
local lastScore = 0;
for i = 0, 3450 do
	if (scoreColors[i]) then
		colorLookup[i] = scoreColors[i];
		lastScore = i;
	else
		colorLookup[i] = scoreColors[lastScore];
	end
end

--[[
	Documentation: Looks up the r, g, b values from the coreLookup table or sends a default value if it is out of range. O(1)
]] 
local function getColorForScoreLookup(score)
	return colorLookup[score] or {0.62, 0.62, 0.62};
end

--[[
	Deprecated
]]
local function getScoreColor(score)
	local minDiff = math.huge;
	local closestColor = nil;
	for k, v in pairs(scoreColors) do
		local diff = math.abs(score - k);
		if (diff < minDiff) then
			minDiff = diff;
			closestColor = v;
		end
	end
	return closestColor;
end

--[[
	Documentation: Get the best achievement by looping through the list of achievementIDs lower key is more prestigeous

	Payload:
	raid param(string) - the generic name of the raid without difficulty
	
	Returr:
	CASE no completed achievement: nil
	CASE 1 >= completed achievements: string AchievementLink colored and clickable
]]
local function getBestAchievement(raid)
	for i, achievementIDs in ipairs(achievementIDs[raid]) do
		if (select(4, GetAchievementInfo(achievementIDs))) then
			return GetAchievementLink(achievementIDs);
		end
	end
	return nil;
end

--[[
	Documentation: A blizzard value used in LFGListUtil_GetSearchEntryMenu that is called when right clicking on a group in premade groups.
	This version overwrites it and adds a new button in position 5 in the dropdown.
	text (string) that is shown in the dropdown
	func - onClick function that takes custom parrams and are passed form the LFGListUtil_GetSearchEntryMenu function
	disable - if the button is disabled
]]
local LFG_LIST_SEARCH_ENTRY_MENU = {
	{
		text = nil,	--Group name goes here
		isTitle = true,
		notCheckable = true,
	},
	{
		text = WHISPER_LEADER,
		func = function(_, name) ChatFrame_SendTell(name); end,
		notCheckable = true,
		arg1 = nil, --Leader name goes here
		disabled = nil, --Disabled if we don't have a leader name yet or you haven't applied
		tooltipWhileDisabled = 1,
		tooltipOnButton = 1,
		tooltipTitle = nil, --The title to display on mouseover
		tooltipText = nil, --The text to display on mouseover
	},
	{
		text = LFG_LIST_REPORT_GROUP_FOR,
		notCheckable = true,
		func = function(_, id, name) 
			LFGList_ReportListing(id, name); 
			LFGListSearchPanel_UpdateResultList(LFGListFrame.SearchPanel); 
		end;
	},
	{
		text = REPORT_GROUP_FINDER_ADVERTISEMENT,
		notCheckable = true,
		func = function(_, id, name) 
			LFGList_ReportAdvertisement(id, name); 
			LFGListSearchPanel_UpdateResultList(LFGListFrame.SearchPanel); 
		end;
	},
	{
		text = "Send Best Achievement",
		func = function(_, activityShortName, leaderName) SendChatMessage(getBestAchievement(activityShortName), "WHISPER", nil, leaderName); end,
		notCheckable = true,
		arg1 = nil, --Leader name goes here
		disabled = nil, --Disabled if we don't have a leader name yet or you haven't applied
		tooltipWhileDisabled = 1,
		tooltipOnButton = 1,
		tooltipTitle = nil, --The title to display on mouseover
		tooltipText = nil, --The text to display on mouseover
	},
	{
		text = CANCEL,
		notCheckable = true,
	},
};
--[[
	Documentation: Prefills arrays to improve performance as we know they will be filled later on
]]
local dungeonTextures = {true, true, true, true, true, true, true, true, true, true};
local raidTextures = {true, true, true, true};
local GUI = {}; -- array to store all generic widgets
local dGUI = {}; -- array to store all widgets for dungeons
local rGUI = {}; -- array to store all widgets for raids

local currentDungeonsActivityIDs = {["(Mythic Keystone)"] = {}, ["(Mythic)"] = {}, ["(Heroic)"] = {}, ["(Normal)"] = {}}; --dungeons dropdown is using difficulties to show dungeons for that difficulty as the first filter
local currentRaidsActivityIDs = {}; --raids dropdown is using the specific raid + difficulty which in form of activityID to show bosses in the first filter

--[[
	Checking if a table PGF_Contains a given value and if it does, what index is the value located at
	param(arr) table
	param(value) T - value to check exists
	return boolean or integer / returns false if the table does not contain the value otherwise it returns the index of where the value is locatedd
]]
local function PGF_Contains(arr, value)
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
local function PGF_GetSize(arr)
	local count = 0
	for k, v in pairs(arr) do
		count = count + 1
	end
	return count
end
--[[
	Documentation: A function to figure out if the boss param is the next boss based on the raid lockout and graph for that raid
	CASE post all wings boss: If it is a boss that unlocks after 2 or more wings or there is a skip to the boss we need to check for all 3 scenarios. In the case it is a skip only check if first boss is defeated and not the 2nd boss as they are probably not skipping then 
	CASE any other case: check if the boss just before the current boss is defeated

	Payload:
	graph parram(table/graph) - a graph that contains all of the bosses and the orders they can be reached
	boss parram(string) - the boss we are checking if it is next
	bosses parram(table) - a table with all of the bosses that are defeated key is bossName, value is true and if it is not defeated the key will be nill for that boss

	Returns:
	bool - true if it is the next boss
	bool - false if it is not
]]
local function isNextBoss(graph, boss, bosses)
	if (boss and graph) then
		if (boss == "Broodkeeper") then
			if (bosses[graph[boss]["parent_paths"][1][1]] and PGF_GetSize(bosses) == 1) then
				return true;
			elseif (bosses[graph[boss]["parent_paths"][1][1]] and bosses[graph[boss]["parent_paths"][2][1]] and bosses[graph[boss]["parent_paths"][3][1]]) then
				return true;
			end
		elseif (bosses[graph[boss]["parent_paths"][1][1]]) then
			return true;
		end
	end
	return false
end
--[[
	Documentation: Create the dungeonFrame shown only in category 2
]]
local dungeonFrame = CreateFrame("Frame", nil, f);
dungeonFrame:Hide();
dungeonFrame:SetPoint("TOPLEFT", 0, 0);
dungeonFrame:SetSize(f:GetWidth(), f:GetHeight());

local dungeonOptionsFrame = CreateFrame("Frame", nil, dungeonFrame, BackdropTemplateMixin and "BackdropTemplate");
dungeonOptionsFrame:SetPoint("BOTTOMRIGHT", PVEFrame, "BOTTOMRIGHT", -1,-80);
dungeonOptionsFrame:SetSize(242,80);

--[[
	Documentation: Create the raidFrame shown only in category 3
]]
local raidFrame = CreateFrame("Frame", nil, f);
raidFrame:SetPoint("TOPLEFT", 0, 0);
raidFrame:SetSize(f:GetWidth(), f:GetHeight());
raidFrame:Hide();

--C_LFGList.GetSearchResultMemberInfo(resultID, playerIndex); returns: [1] = role, [2] = classUNIVERSAL, [3] = classLocal, [4] = spec

f:RegisterEvent("PLAYER_LOGIN");
f:RegisterEvent("PLAYER_ENTERING_WORLD");
f:RegisterEvent("CHAT_MSG_ADDON");
f:RegisterEvent("GROUP_ROSTER_UPDATE");
f:RegisterEvent("CHAT_MSG_SYSTEM");
C_ChatInfo.RegisterAddonMessagePrefix("PGF_VERSIONCHECK")
--[[
	Documentation: Save all of the Blizzard UI elements that we move for when no PGF frame is shown
]]
local function saveOriginalUI()
	originalUI = {
		["PVEFrame"] = {["width"] = 0, ["height"] = 0}, 
		["LFGListFrame"] = {["position"] = {}, ["position2"] = {}},
		["LFGListFrame.SearchPanel.SearchBox"] = {["position"] = {}}, 
		["LFGListFrame.SearchPanel.FilterButton"] = {["position"] = {}}, 
		["LFGListFrame.SearchPanel.ResultsInset"] = {["position"] = {}}, 
		["LFGListFrame.SearchPanel.RefreshButton"] = {["position"] = {}},
		["LFGListFrame.SearchPanel.CategoryName"] = {["position"] = {}};
		["LFGListApplicationDialog.Description"] = {["position"] = {}, ["size"] = {}};
		["LFGListApplicationDialog.Description.EditBox"] = {["size"] = {}};
	};
	originalUI["PVEFrame"].width = PVEFrame:GetWidth();
	originalUI["PVEFrame"].height = PVEFrame:GetHeight();
	originalUI["LFGListFrame"].position[1], originalUI["LFGListFrame"].position[2], originalUI["LFGListFrame"].position[3], originalUI["LFGListFrame"].position[4], originalUI["LFGListFrame"].position[5] = LFGListFrame:GetPoint(1);
	originalUI["LFGListFrame"].position2[1], originalUI["LFGListFrame"].position2[2], originalUI["LFGListFrame"].position2[3], originalUI["LFGListFrame"].position2[4], originalUI["LFGListFrame"].position2[5] = LFGListFrame:GetPoint(2);
	originalUI["LFGListFrame.SearchPanel.SearchBox"].size = LFGListFrame.SearchPanel.SearchBox:GetSize();
	originalUI["LFGListFrame.SearchPanel.SearchBox"].position[1], originalUI["LFGListFrame.SearchPanel.SearchBox"].position[2], originalUI["LFGListFrame.SearchPanel.SearchBox"].position[3], originalUI["LFGListFrame.SearchPanel.SearchBox"].position[4], originalUI["LFGListFrame.SearchPanel.SearchBox"].position[5] = LFGListFrame.SearchPanel.SearchBox:GetPoint();
	originalUI["LFGListFrame.SearchPanel.FilterButton"].size = LFGListFrame.SearchPanel.FilterButton:GetSize();
	originalUI["LFGListFrame.SearchPanel.FilterButton"].position[1], originalUI["LFGListFrame.SearchPanel.FilterButton"].position[2], originalUI["LFGListFrame.SearchPanel.FilterButton"].position[3], originalUI["LFGListFrame.SearchPanel.FilterButton"].position[4], originalUI["LFGListFrame.SearchPanel.FilterButton"].position[5] = LFGListFrame.SearchPanel.FilterButton:GetPoint();
	originalUI["LFGListFrame.SearchPanel.ResultsInset"].size = LFGListFrame.SearchPanel.ResultsInset:GetSize();
	originalUI["LFGListFrame.SearchPanel.ResultsInset"].position[1], originalUI["LFGListFrame.SearchPanel.ResultsInset"].position[2], originalUI["LFGListFrame.SearchPanel.ResultsInset"].position[3], originalUI["LFGListFrame.SearchPanel.ResultsInset"].position[4], originalUI["LFGListFrame.SearchPanel.ResultsInset"].position[5] = LFGListFrame.SearchPanel.ResultsInset:GetPoint();
	originalUI["LFGListFrame.SearchPanel.RefreshButton"].size = LFGListFrame.SearchPanel.RefreshButton:GetSize();
	originalUI["LFGListFrame.SearchPanel.RefreshButton"].position[1], originalUI["LFGListFrame.SearchPanel.RefreshButton"].position[2], originalUI["LFGListFrame.SearchPanel.RefreshButton"].position[3], originalUI["LFGListFrame.SearchPanel.RefreshButton"].position[4], originalUI["LFGListFrame.SearchPanel.RefreshButton"].position[5] = LFGListFrame.SearchPanel.RefreshButton:GetPoint();
	originalUI["LFGListFrame.SearchPanel.CategoryName"].position[1], originalUI["LFGListFrame.SearchPanel.CategoryName"].position[2], originalUI["LFGListFrame.SearchPanel.CategoryName"].position[3], originalUI["LFGListFrame.SearchPanel.CategoryName"].position[4], originalUI["LFGListFrame.SearchPanel.CategoryName"].position[5] = LFGListFrame.SearchPanel.CategoryName:GetPoint();
	originalUI["LFGListApplicationDialog.Description"].parent = LFGListApplicationDialog.Description:GetParent();
	originalUI["LFGListApplicationDialog.Description"].position[1], originalUI["LFGListApplicationDialog.Description"].position[2], originalUI["LFGListApplicationDialog.Description"].position[3], originalUI["LFGListApplicationDialog.Description"].position[4], originalUI["LFGListApplicationDialog.Description"].position[5] = LFGListApplicationDialog.Description:GetPoint();
	originalUI["LFGListApplicationDialog.Description"].size[1], originalUI["LFGListApplicationDialog.Description"].size[2] = LFGListApplicationDialog.Description:GetSize();
	originalUI["LFGListApplicationDialog.Description.EditBox"].size[1], originalUI["LFGListApplicationDialog.Description.EditBox"].size[2] = LFGListApplicationDialog.Description.EditBox:GetSize();
end

--[[
	Documentation: Restore all of the Blizzard UI elements that was moved by PGF to its original position when no PGF frame is shown
]]
local function restoreOriginalUI()
	PVE_FRAME_BASE_WIDTH = 600;
	PVEFrame:SetSize(600, originalUI["PVEFrame"].height);
	LFGListFrame.SearchPanel.SearchBox:ClearAllPoints();
	LFGListFrame.SearchPanel.RefreshButton:ClearAllPoints();
	LFGListFrame.SearchPanel.FilterButton:ClearAllPoints();
	LFGListFrame.SearchPanel.CategoryName:ClearAllPoints();
	LFGListApplicationDialog.Description:ClearAllPoints();
	LFGListFrame:ClearAllPoints();
	LFGListFrame:SetPoint(originalUI["LFGListFrame"].position[1], originalUI["LFGListFrame"].position[2], originalUI["LFGListFrame"].position[3], originalUI["LFGListFrame"].position[4], originalUI["LFGListFrame"].position[5]);
	LFGListFrame:SetPoint(originalUI["LFGListFrame"].position2[1], originalUI["LFGListFrame"].position2[2], originalUI["LFGListFrame"].position2[3], originalUI["LFGListFrame"].position2[4], originalUI["LFGListFrame"].position2[5]);
	LFGListFrame.SearchPanel.SearchBox:SetPoint(originalUI["LFGListFrame.SearchPanel.SearchBox"].position[1], originalUI["LFGListFrame.SearchPanel.SearchBox"].position[2], originalUI["LFGListFrame.SearchPanel.SearchBox"].position[3], originalUI["LFGListFrame.SearchPanel.SearchBox"].position[4], originalUI["LFGListFrame.SearchPanel.SearchBox"].position[5]);
	LFGListFrame.SearchPanel.FilterButton:SetPoint(originalUI["LFGListFrame.SearchPanel.FilterButton"].position[1], originalUI["LFGListFrame.SearchPanel.FilterButton"].position[2], originalUI["LFGListFrame.SearchPanel.FilterButton"].position[3], originalUI["LFGListFrame.SearchPanel.FilterButton"].position[4], originalUI["LFGListFrame.SearchPanel.FilterButton"].position[5]);
	LFGListFrame.SearchPanel.RefreshButton:SetPoint(originalUI["LFGListFrame.SearchPanel.RefreshButton"].position[1], originalUI["LFGListFrame.SearchPanel.RefreshButton"].position[2], originalUI["LFGListFrame.SearchPanel.RefreshButton"].position[3], originalUI["LFGListFrame.SearchPanel.RefreshButton"].position[4], originalUI["LFGListFrame.SearchPanel.RefreshButton"].position[5]);
	LFGListFrame.SearchPanel.CategoryName:SetPoint(originalUI["LFGListFrame.SearchPanel.CategoryName"].position[1], originalUI["LFGListFrame.SearchPanel.CategoryName"].position[2], originalUI["LFGListFrame.SearchPanel.CategoryName"].position[3], originalUI["LFGListFrame.SearchPanel.CategoryName"].position[4], originalUI["LFGListFrame.SearchPanel.CategoryName"].position[5]);
	LFGListFrame.SearchPanel.ResultsInset:SetPoint(originalUI["LFGListFrame.SearchPanel.ResultsInset"].position[1], originalUI["LFGListFrame.SearchPanel.ResultsInset"].position[2], originalUI["LFGListFrame.SearchPanel.ResultsInset"].position[3], originalUI["LFGListFrame.SearchPanel.ResultsInset"].position[4], originalUI["LFGListFrame.SearchPanel.ResultsInset"].position[5]);
	LFGListApplicationDialog.Description:SetPoint(originalUI["LFGListApplicationDialog.Description"].position[1], originalUI["LFGListApplicationDialog.Description"].position[2], originalUI["LFGListApplicationDialog.Description"].position[3], originalUI["LFGListApplicationDialog.Description"].position[4], originalUI["LFGListApplicationDialog.Description"].position[5]);
	LFGListApplicationDialog.Description:SetSize(originalUI["LFGListApplicationDialog.Description"].size[1], originalUI["LFGListApplicationDialog.Description"].size[2]);
	LFGListApplicationDialog.Description.EditBox:SetSize(originalUI["LFGListApplicationDialog.Description.EditBox"].size[1], originalUI["LFGListApplicationDialog.Description.EditBox"].size[2]);
	LFGListFrame:ClearAllPoints(); 
	LFGListFrame:SetPoint(originalUI["LFGListFrame"].position[1], originalUI["LFGListFrame"].position[2], originalUI["LFGListFrame"].position[3], originalUI["LFGListFrame"].position[4], originalUI["LFGListFrame"].position[5]);
	LFGListFrame:SetSize(368, LFGListFrame:GetHeight());
end


--[[
	Documentation: A blizzard function used to perform C_LFGList.Search and C_LFGList.GetAvailableActivities
	The function takes the categoryID and if a filter should be applied or not which depends on the category. For raids 0 is for all raids including legacy while 1 is only current raids. For dungeons 

	Payload:
	categoryID parram(int) - the categoryID of LFGListFrame.SearchPanel.categoryID or the categoryID of the activity
	filters parram(int) - if a filter for recommended groups should be applied or not

	Returns:
	filters (int)
]]
local function ResolveCategoryFilters(categoryID, filters)
	-- Dungeons ONLY display recommended groups.
	if categoryID == GROUP_FINDER_CATEGORY_ID_DUNGEONS then
		return bit.band(bit.bnot(Enum.LFGListFilter.NotRecommended), bit.bor(filters, Enum.LFGListFilter.Recommended));
	end

	return filters;
end

--[[
	Documentation: This function performs all of the searches for PGF and makes sure that there has been enough time between searches before making a new one.
]]
local function updateSearch()
	if (searchAvailable) then
		performanceTimeStamp = GetTimePreciseSec(); 
		searchAvailable = false;
		LFGListFrame.SearchPanel.RefreshButton:SetScript("OnClick", function() end);
		LFGListFrame.SearchPanel.RefreshButton.Icon:SetTexture("Interface\\AddOns\\PGFinder\\Res\\RedRefresh.tga");
		C_LFGList.ClearSearchResults();
		local dungeonsSelected = PGF_GetSize(selectedInfo.dungeons);
		local count = 0;
		if (slowSearch == false) then
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
end

--[[
	Documentation: This is a Blizzard function used when sorting groups to determine if the player is eligible for each listed group.
	This version extends it to also work for groups (multiple players) to see if the group as a whole is eliglbe for each listed group.

	Payload:
	lfgSearchResultID parram(int) - the resultID from GetSearchResult or self

	Returns:
	bool - that is true if the group/player is eligible and otherwise false
]]
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
	Documentation: This scrript will keep track of enough time has passed between the searches to allow for searches again and reset the refresh button texture.
	While it is disabled the OnClick function is also removed but is readded here when searching is available again.

	Payload:
	self parram(table/object) - PVEFrame
	elapsed param(int) - How much time has passed since last call
]]
PVEFrame:HookScript("OnUpdate", function(self, elapsed)
	ticks = ticks + elapsed;
	if (ticks >= refreshTimeReset and not searchAvailable) then
		LFGListFrame.SearchPanel.RefreshButton:SetScript("OnClick", refreshButtonClick);
		LFGListFrame.SearchPanel.RefreshButton.Icon:SetTexture(851904);
		searchAvailable = true;
		LFGListFrame.SearchPanel.RefreshButton:HookScript("OnClick", function(self)
			self:SetScript("OnClick", function() end);
			self.Icon:SetTexture("Interface\\AddOns\\PGFinder\\Res\\RedRefresh.tga");
			searchAvailable = false;
		end);

		ticks = 0;
	end
end);
--[[
	Documentation: Based on isSameCat all elements will either be hidden because they are no longer relevant as a new category is opened or everything is restored as it is the same category. 
	First all elements are hidden to force a reset, then all of the generic elements within the dungeonframe and all generic elements for all frames are shown.
	
	Payload:
	isSameCat param(bool) if false we should pass a long to hide all of the old UI
]]
local function updateDungeonDifficulty(isSameCat)
	if (not isSameCat) then
		raidFrame:Hide();
		--Hide all
		LFGListSearchPanel_Clear(LFGListFrame.SearchPanel);
		for index, widgets in pairs(dGUI) do
			local text = widgets.text;
			local checkbox = widgets.checkbox;
			local texture = widgets.texture;
			local editBox = widgets.editBox;
			local dropDown = widgets.dropDown;
			if (text) then
				text:Hide();
			end
			if (checkbox) then
				checkbox:Hide();
			end
			if (texture) then
				texture:Hide();
			end
			if (editBox) then
				editBox:Hide();
			end
			if (dropDown) then
				dropDown:Hide();
			end
			if (selectedInfo.dungeons[index]) then
				selectedInfo.dungeons[index] = nil;
				checkbox:SetChecked(false);
			elseif (PGF_roles[index]) then
				checkbox:SetChecked(true);
			elseif (index == "FilterRoles") then
				checkbox:SetChecked(PGF_FilterRemaningRoles);
			end
		end
		for index, widgets in pairs(dGUI) do
			if (type(index) ~= "number") then
				local text = widgets.text;
				local checkbox = widgets.checkbox;
				local texture = widgets.texture;
				local editBox = widgets.editBox;
				local dropDown = widgets.dropDown;
				if (text) then
					text:Show();
				end
				if (checkbox) then
					checkbox:Show();
				end
				if (texture) then
					texture:Show();
				end
				if (editBox) then
					editBox:Show();
				end
				if (dropDown) then
					dropDown:Show();
						if (lastSelectedDungeonState == "") then --addon just loaded
							lastSelectedDungeonState = dungeonStates[4];
						end
				end
				if (PGF_roles[index]) then
					checkbox:SetChecked(true);
				end
			end
		end
	end
	for aID, name in pairs(currentDungeonsActivityIDs[dungeonStateMap[lastSelectedDungeonState]]) do
		local text = dGUI[aID].text;
		local checkbox = dGUI[aID].checkbox;
		local texture = dGUI[aID].texture;
		if (text) then
			text:Show();
		end
		if (checkbox) then
			checkbox:Show();
		end
		if (texture) then
			texture:Show();
		end
		if (selectedInfo.dungeons[aID]) then
			checkbox:SetChecked(true);
		end
	end
	updateSearch();
end
--[[
	Documentation: Based on isSameCat all elements will either be hidden because they are no longer relevant as a new category is opened or everything is restored as it is the same category. 
	First all elements are hidden to force a reset, then all of the generic elements within the raid frame are shown and then all generic elements for all frames are shown and lastly all raidFrame specific elements are shown.
	
	Payload:
	isSameCat param(bool) if false we should pass a long to hide all of the old UI
]]
local function updateRaidDifficulty(isSameCat)
	--Hide all
	if (not isSameCat) then
		dungeonFrame:Hide();
		LFGListSearchPanel_Clear(LFGListFrame.SearchPanel);
		for aID, names in pairs(rGUI) do
			for name, widgets in pairs(rGUI[aID]) do
				local text = widgets.text;
				local checkbox = widgets.checkbox;
				local texture = widgets.texture;
				local editBox = widgets.editBox;
				local dropDown = widgets.dropDown;
				if (text) then
					text:Hide();
				end
				if (checkbox) then
					checkbox:Hide();
				end
				if (texture) then
					texture:Hide();
				end
				if (editBox) then
					editBox:Hide();
				end
				if (dropDown) then
					dropDown:Hide();
				end
				if (selectedInfo.bosses[name]) then
					selectedInfo.bosses[name] = nil;
					checkbox:SetChecked(false);
				end
			end
		end
		for index, widgets in pairs(rGUI) do
			if (type(index) ~= "number") then
				local text = widgets.text;
				local checkbox = widgets.checkbox;
				local texture = widgets.texture;
				local editBox = widgets.editBox;
				local dropDown = widgets.dropDown;
				if (text) then
					text:Show();
				end
				if (checkbox) then
					checkbox:Show();
				end
				if (texture) then
					texture:Show();
				end
				if (editBox) then
					editBox:Show();
				end
				if (dropDown) then
					dropDown:Show();
					if (lastSelectedRaidState == "") then --addon just loaded
						lastSelectedRaidState = raidStates[4];
					end
				end
			end
		end
		for index, widgets in pairs(dGUI) do
			if (type(index) ~= "number") then
				local checkbox = widgets.checkbox;
				if (PGF_roles[index]) then
					checkbox:SetChecked(true);
				end
			end
		end
		for index, name in pairs(currentRaidsActivityIDs[raidStateMap[lastSelectedRaidState]]) do
			local aID = raidStateMap[lastSelectedRaidState];
			local text = rGUI[aID][name].text;
			local checkbox = rGUI[aID][name].checkbox;
			local texture = rGUI[aID][name].texture;
			if (text) then
				text:Show();
			end
			if (checkbox) then
				checkbox:Show();
			end
			if (texture) then
				texture:Show();
			end
			if (selectedInfo.bosses[name]) then
				checkbox:SetChecked(true);
			end
		end
	end
	updateSearch();
end
--[[
	Documentation: Blizzard overwrites the frame size of the PVEFrame with PVE_FRAME_BASE_WIDTH so that is changed. Also moving all of blizzards UI elements to fit the new UI. Certain elements size are based on 2 anchor points TOPLEFT and BOTTOMRIGHT to fix that we need to clear all points and just set the TOPLEFT.
	
	Payload:
	isSameCat param(bool) if false we should pass a long to hide all of the old UI
]]
local function PGF_ShowDungeonFrame(isSameCat)
	dungeonFrame:Show();
	if (next(originalUI) == nil) then
		saveOriginalUI();
	end
	PVEFrame:SetSize(830,428);
	PVE_FRAME_BASE_WIDTH = 830; -- blizz is always trying to resize the pveframe based on this value
	LFGListFrame.SearchPanel.SearchBox:ClearAllPoints();
	LFGListFrame.SearchPanel.RefreshButton:ClearAllPoints();
	LFGListFrame.SearchPanel.FilterButton:ClearAllPoints();
	LFGListFrame.SearchPanel.CategoryName:ClearAllPoints();
	LFGListFrame.SearchPanel.SearchBox:SetPoint("TOPLEFT", dungeonFrame, "TOPLEFT", 28, -10);
	LFGListFrame.SearchPanel.RefreshButton:SetPoint("TOPLEFT", LFGListFrame.SearchPanel.SearchBox, "TOPLEFT", -50, 7);
	LFGListFrame.SearchPanel.FilterButton:SetPoint("BOTTOMRIGHT", PVEFrame, "BOTTOMRIGHT", -20, 45);
	LFGListFrame.SearchPanel.FilterButton:SetSize(80, LFGListFrame.SearchPanel.FilterButton:GetHeight());
	LFGListFrame.SearchPanel.CategoryName:SetPoint("TOP", 125, -17);
	LFGListFrame.SearchPanel.CategoryName:SetFont(PVEFrameTitleText:GetFont(), 11);
	LFGListFrame.SearchPanel.ResultsInset:SetPoint("TOPLEFT", LFGListFrame, "TOPLEFT", -5, -50);
	LFGListApplicationDialog.Description:ClearAllPoints();
	LFGListApplicationDialog.Description:SetParent(dungeonFrame);
	LFGListApplicationDialog.Description:SetPoint("BOTTOMRIGHT", PVEFrame, "BOTTOMRIGHT", -10, 15);
	LFGListApplicationDialog.Description:SetSize(210, 20);
	LFGListApplicationDialog.Description.EditBox:SetMaxLetters(50);
	LFGListApplicationDialog.Description.EditBox:SetSize(LFGListApplicationDialog.Description:GetWidth(), LFGListApplicationDialog.Description:GetHeight());
	LFGListApplicationDialog.Description.EditBox:SetTextColor(1,1,1,1);
	LFGListFrame:ClearAllPoints(); 
	LFGListFrame:SetPoint(originalUI["LFGListFrame"].position[1], originalUI["LFGListFrame"].position[2], originalUI["LFGListFrame"].position[3], originalUI["LFGListFrame"].position[4], originalUI["LFGListFrame"].position[5]);
	LFGListFrame:SetSize(368, LFGListFrame:GetHeight());
	updateDungeonDifficulty(isSameCat);
end
--[[
	Documentation: Blizzard overwrites the frame size of the PVEFrame with PVE_FRAME_BASE_WIDTH so that is changed. Also moving all of blizzards UI elements to fit the new UI. Certain elements size are based on 2 anchor points TOPLEFT and BOTTOMRIGHT to fix that we need to clear all points and just set the TOPLEFT.
	
	Payload:
	isSameCat param(bool) if false we should pass a long to hide all of the old UI
]]
local function PGF_ShowRaidFrame(isSameCat)
	raidFrame:Show();
	if (next(originalUI) == nil) then
		saveOriginalUI();
	end
	PVEFrame:SetSize(830,428);
	PVE_FRAME_BASE_WIDTH = 830; -- blizz is always trying to resize the pveframe based on this value
	LFGListFrame.SearchPanel.SearchBox:ClearAllPoints();
	LFGListFrame.SearchPanel.RefreshButton:ClearAllPoints();
	LFGListFrame.SearchPanel.FilterButton:ClearAllPoints();
	LFGListFrame.SearchPanel.CategoryName:ClearAllPoints();
	LFGListFrame.SearchPanel.SearchBox:SetPoint("TOPLEFT", raidFrame, "TOPLEFT", 28, -10);
	LFGListFrame.SearchPanel.RefreshButton:SetPoint("TOPLEFT", LFGListFrame.SearchPanel.SearchBox, "TOPLEFT", -50, 7);
	LFGListFrame.SearchPanel.FilterButton:SetPoint("BOTTOMRIGHT", PVEFrame, "BOTTOMRIGHT", -20, 45);
	LFGListFrame.SearchPanel.FilterButton:SetSize(80, LFGListFrame.SearchPanel.FilterButton:GetHeight());
	LFGListFrame.SearchPanel.CategoryName:SetPoint("TOP", 125, -17);
	LFGListFrame.SearchPanel.CategoryName:SetFont(PVEFrameTitleText:GetFont(), 11);
	LFGListFrame.SearchPanel.ResultsInset:SetPoint("TOPLEFT", LFGListFrame, "TOPLEFT", -5, -50);
	LFGListApplicationDialog.Description:ClearAllPoints();
	LFGListApplicationDialog.Description:SetParent(raidFrame);
	LFGListApplicationDialog.Description:SetPoint("BOTTOMRIGHT", PVEFrame, "BOTTOMRIGHT", -10, 15);
	LFGListApplicationDialog.Description:SetSize(210, 20);
	LFGListApplicationDialog.Description.EditBox:SetMaxLetters(50);
	LFGListApplicationDialog.Description.EditBox:SetSize(LFGListApplicationDialog.Description:GetWidth(), LFGListApplicationDialog.Description:GetHeight());
	LFGListApplicationDialog.Description.EditBox:SetTextColor(1,1,1,1);
	LFGListFrame:ClearAllPoints(); 
	LFGListFrame:SetPoint(originalUI["LFGListFrame"].position[1], originalUI["LFGListFrame"].position[2], originalUI["LFGListFrame"].position[3], originalUI["LFGListFrame"].position[4], originalUI["LFGListFrame"].position[5]);
	LFGListFrame:SetSize(368, LFGListFrame:GetHeight());
	updateRaidDifficulty(isSameCat);
end

--[[
	Documentation: Creates all of the UI elements related to the dungeonFrame including:
	Difficulty Dropdown
	Text, checkbox and texture for each boss
	The dungeons that will show up are the ones we get from recommended activities for that difficulty (same as in the autocomplete in search). All of the bosses will be stored in the dungeonAbbreviations[abbrevatedDungeonName]

	All of the generic frames are also stored and created here including:
	performanceText
	slowSearch
	leaderScore
	blizzSearchInfo
	filterOutIneligible groups
	roles config
]]
local function initDungeon()
	if (PVEFrame.GetBackdrop) then
		dungeonOptionsFrame:SetBackdrop(PVEFrame:GetBackdrop());
		local r,g,b,a = PVEFrame:GetBackdropColor();
		dungeonOptionsFrame:SetBackdropColor(r,g,b,a);
		r,g,b,a = PVEFrame:GetBackdropBorderColor();
		dungeonOptionsFrame:SetBackdropBorderColor(r,g,b,a);
	elseif (PVEFrameBg:GetTexture()) then
		local texture = dungeonOptionsFrame:CreateTexture(nil, "BACKGROUND");
		dungeonOptionsFrame:SetBackdrop({
			bgFile = "",
			edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
			edgeSize = 16,
			insets = { left = 4, right = 4, top = 4, bottom = 4 },
		});
		texture:SetTexture(PVEFrameBg:GetTexture());
		texture:SetAllPoints();
		dungeonOptionsFrame:SetBackdropBorderColor(0.1,0.1,0.1,1);
		dungeonOptionsFrame:SetPoint("BOTTOMRIGHT", PVEFrame, "BOTTOMRIGHT", -1,-78);
	end
	local dungeonDifficultyText = dungeonFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalTiny2");
	dungeonDifficultyText:SetFont(dungeonDifficultyText:GetFont(), 10);
	dungeonDifficultyText:SetPoint("TOPLEFT", 30, -40);
	local dungeonDifficultyDropDown = CreateFrame("Button", nil, dungeonFrame, "UIDropDownMenuTemplate");
	dungeonDifficultyDropDown:SetPoint("LEFT", dungeonDifficultyText, "RIGHT", -12, -2);
	local function Initialize_DungeonStates(self, level)
		local info = UIDropDownMenu_CreateInfo();
		for k,v in pairs(dungeonStates) do
			info = UIDropDownMenu_CreateInfo();
			info.text = v;
			info.value = v;
			info.func = PGF_DungeonState_OnClick;
			UIDropDownMenu_AddButton(info, level);
		end
	end

	function PGF_DungeonState_OnClick(self)
		UIDropDownMenu_SetSelectedID(dungeonDifficultyDropDown, self:GetID());
		lastSelectedDungeonState = self:GetText();
		updateDungeonDifficulty();
	end

	UIDropDownMenu_SetWidth(dungeonDifficultyDropDown, 100);
	UIDropDownMenu_SetButtonWidth(dungeonDifficultyDropDown, 100);
	UIDropDownMenu_JustifyText(dungeonDifficultyDropDown, "CENTER");
	UIDropDownMenu_Initialize(dungeonDifficultyDropDown, Initialize_DungeonStates);
	UIDropDownMenu_SetSelectedID(dungeonDifficultyDropDown, 4);
	local matchingActivities = C_LFGList.GetAvailableActivities(GROUP_FINDER_CATEGORY_ID_DUNGEONS, nil, ResolveCategoryFilters(GROUP_FINDER_CATEGORY_ID_DUNGEONS, 0), "");
	for i = 1, #matchingActivities do
		local name = PGF_allDungeonsActivityIDs[matchingActivities[i]];
		local shortName = name:gsub("%s%(.*", "")
		local difficulty = name:match("%(.*%)");
		if (dungeonAbbreviations[shortName]) then
			shortName = dungeonAbbreviations[shortName];
		end
		if (name:match("(Mythic Keystone)")) then
			currentDungeonsActivityIDs["(Mythic Keystone)"][matchingActivities[i]] = shortName .. " " .. difficulty;
		elseif (name:match("(Mythic)")) then
			currentDungeonsActivityIDs["(Mythic)"][matchingActivities[i]] = shortName .. " " .. difficulty;
		elseif (name:match("(Heroic)")) then
			currentDungeonsActivityIDs["(Heroic)"][matchingActivities[i]] = shortName .. " " .. difficulty;
		elseif (name:match("(Normal)")) then
			currentDungeonsActivityIDs["(Normal)"][matchingActivities[i]] = shortName .. " " .. difficulty;
		end
	end
	--create all buttons, have updateDifficulty display different buttons
	--super expensive function, made cheaper
	for index, challengeID in ipairs(C_ChallengeMode.GetMapTable()) do
		local name, id, timeLimit, texture, backgroundTexture = C_ChallengeMode.GetMapUIInfo(challengeID);
		local shortName = name:gsub("%s%(.*", "");
		dungeonTextures[dungeonAbbreviations[name] .. " (Mythic Keystone)"] = texture;
	end
	for i = 1, 2500 do
		local name, typeID, subtypeID, minLevel, maxLevel, recLevel, minRecLevel, maxRecLevel, expansionLevel, groupID, textureFilename, difficulty, maxPlayers, description, isHoliday, bonusRepAmount, minPlayers, isTimeWalker, name2, minGearLevel, isScalingDungeon, lfgMapID = GetLFGDungeonInfo(i);
		if (name) then
			local shortName = name:gsub("%s%(.*", "");
			if (dungeonAbbreviations[shortName]) then
				dungeonTextures[dungeonAbbreviations[shortName]] = textureFilename;
			end
		end
	end
	for difficulty, dungeonData in pairs(currentDungeonsActivityIDs) do
		local count = 0;
		for aID, name in pairs(currentDungeonsActivityIDs[difficulty]) do
			count = count + 1;
			local texture = dungeonFrame:CreateTexture(nil, "OVERLAY");
			local shortName = name:gsub("%s%(.*", ""); 
			texture:SetTexture(dungeonTextures[shortName]);
			if (difficulty == "(Mythic Keystone)") then
				texture:SetTexture(dungeonTextures[name]);
			end
			texture:SetPoint("TOPLEFT", 30,-65-((count-1)*24));
			texture:SetSize(18, 18);
			local checkbox = CreateFrame("CheckButton", nil, dungeonFrame, "UICheckButtonTemplate");
			checkbox:SetSize(20, 20);
			checkbox:SetPoint("TOPLEFT", texture, "TOPLEFT", 19, 2);
			checkbox:SetScript("OnClick", function(self)
				if (self:GetChecked()) then
					selectedInfo.dungeons[aID] = true;
					local dungeonsSelected = PGF_GetSize(selectedInfo.dungeons);
					if (dungeonsSelected == 1) then
						local key, value = next(selectedInfo.dungeons);
						C_LFGList.SetSearchToActivity(key);
					elseif (LFGListFrame.SearchPanel.SearchBox:GetText():match("(Mythic Keystone)")) then
						C_LFGList.ClearSearchTextFields();
					end
					updateSearch();
				else
					selectedInfo.dungeons[aID] = nil;
					local dungeonsSelected = PGF_GetSize(selectedInfo.dungeons);
					if (dungeonsSelected == 1) then
						local key, value = next(selectedInfo.dungeons);
						C_LFGList.SetSearchToActivity(key);
					elseif (LFGListFrame.SearchPanel.SearchBox:GetText():match("(Mythic Keystone)")) then
						C_LFGList.ClearSearchTextFields();
					end
					updateSearch();
				end
			end);
			local text = dungeonFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalTiny2");
			text:SetPoint("TOPLEFT", checkbox, "TOPLEFT", 19, -3);
			text:SetJustifyV("TOP");
			text:SetJustifyH("LEFT");
			text:SetText(name);
			text:SetFont(text:GetFont(), 12);
			text:SetTextColor(1,1,1,1);
			dGUI[aID] = {};
			dGUI[aID].text = text;
			dGUI[aID].checkbox = checkbox;
			dGUI[aID].texture = texture;
			text:Hide();
			checkbox:Hide();
		end
	end
	local slowSearchCheckBox = CreateFrame("CheckButton", nil, dungeonFrame, "UICheckButtonTemplate");
	slowSearchCheckBox:SetSize(20, 20);
	slowSearchCheckBox:SetPoint("TOPLEFT", 49,-253);
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
	slowSearchtext:SetPoint("TOPLEFT", slowSearchCheckBox, "TOPLEFT", 19, -3);
	slowSearchtext:SetJustifyV("TOP");
	slowSearchtext:SetJustifyH("LEFT");
	slowSearchtext:SetText("Advanced Search");
	slowSearchtext:SetFont(slowSearchtext:GetFont(), 12);
	slowSearchtext:SetTextColor(1,1,1,1);
	slowSearchtext:Hide();
	slowSearchCheckBox:Hide();
	local performanceText = f:CreateFontString(nil, "ARTWORK", "GameFontNormalTiny2");
	performanceText:SetPoint("TOPLEFT", LFGListFrame.SearchPanel.ResultsInset, "TOPLEFT", 3, 15);
	performanceText:SetJustifyV("TOP");
	performanceText:SetJustifyH("LEFT");
	performanceText:SetText("");
	performanceText:SetFont(performanceText:GetFont(), 10);
	performanceText:SetTextColor(1,1,1,1);
	function PGF_SetPerformanceText(input)
		performanceText:SetText(input);
	end
	local blizzSearchInfo = CreateFrame("Button", nil, f, "UIPanelInfoButton");
	blizzSearchInfo:SetPoint("TOPRIGHT", LFGListFrame.SearchPanel.ResultsInset, "TOPRIGHT", -28, 19);
	blizzSearchInfo:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self);
		GameTooltip:SetText(L.OPTIONS_BLIZZARD_SEARCH_INFO, 1, 1, 1, 1, true);
		GameTooltip:Show();
	end);
	blizzSearchInfo:SetScript("OnLeave", function(self)
		GameTooltip:Hide();
	end);
	--LFGListApplicationDialog.Description.EditBox:SetFont(LFGListApplicationDialog.Description.EditBox:GetFont(), 7);
	dGUI["dungeonDifficulty"] = {["dropDown"] = dungeonDifficultyDropDown, ["text"] = dungeonDifficultyText};
	dungeonDifficultyText:SetText(L.OPTIONS_DUNGEON_DIFFICULTY);
	local filterRolesText = dungeonFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalTiny2");
	filterRolesText:SetFont(filterRolesText:GetFont(), 10);
	filterRolesText:SetPoint("TOPLEFT", slowSearchtext, "TOPLEFT", -20, -30);
	filterRolesText:SetText("Hide incompatible(role) groups");
	local filterRolesCheckButton = CreateFrame("CheckButton", nil, dungeonFrame, "UICheckButtonTemplate");
	filterRolesCheckButton:SetSize(20, 20);
	filterRolesCheckButton:SetPoint("RIGHT", filterRolesText, "RIGHT", 25, 0);
	filterRolesCheckButton:HookScript("OnClick", function(self)
		if (self:GetChecked()) then
			PGF_FilterRemaningRoles = true;
			updateSearch();
			PlaySound(856);
		else
			PGF_FilterRemaningRoles = false;
			updateSearch();
			PlaySound(857);
		end
	end);
	local minLeaderScoreText = dungeonFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalTiny2");
	minLeaderScoreText:SetFont(minLeaderScoreText:GetFont(), 10);
	minLeaderScoreText:SetPoint("TOPLEFT", filterRolesText, "TOPLEFT", 0, -25);
	minLeaderScoreText:SetText(L.OPTIONS_MIN_LEADER_SCORE);
	local minLeaderScoreEditBox = CreateFrame("EditBox", nil, dungeonFrame, "InputBoxTemplate");
	minLeaderScoreEditBox:SetPoint("RIGHT", minLeaderScoreText, "RIGHT", 100, 0);
	minLeaderScoreEditBox:SetAutoFocus(false);
	minLeaderScoreEditBox:SetMultiLine(false);
	minLeaderScoreEditBox:SetFontObject(GameFontNormalTiny2);
	minLeaderScoreEditBox:SetTextColor(1,1,1,1);
	minLeaderScoreEditBox:SetTextInsets(1,5,2,5);
	minLeaderScoreEditBox:SetMaxLetters(4);
	minLeaderScoreEditBox:SetSize(85, 10);
	minLeaderScoreEditBox:SetText("");
	minLeaderScoreEditBox:SetScript("OnEscapePressed", function (self)
		self:ClearFocus();
	end);
	--Use input:GetNumber() to ensure its a number, returns 0 if not a number which is fine in this case
	minLeaderScoreEditBox:SetScript("OnEnterPressed", function(self)
		if (tonumber(self:GetText())) then
			selectedInfo["leaderScore"] = tonumber(self:GetText());
			updateSearch();
		elseif (self:GetText() == nil or self:GetText() == "") then
			selectedInfo["leaderScore"] = 0;
			updateSearch();
		end
	end);
	minLeaderScoreEditBox:SetScript("OnTextChanged", function(self, userInput)
		local input = self:GetText();
		if (input ~= nil and input ~= "" and tonumber(input)) then
			selectedInfo["leaderScore"] = tonumber(input);
		elseif (input ~= nil and input ~= "") then
			self:SetText(input:gsub("[^%d]", ""));
		elseif (input == nil or input == "") then
			selectedInfo["leaderScore"] = 0;
		end
	end);
	local roleText = f:CreateFontString(nil, "ARTWORK", "GameFontNormalTiny2");
	roleText:SetFont(roleText:GetFont(), 10);
	roleText:SetPoint("TOPLEFT", minLeaderScoreText, "TOPLEFT", 0, -25);
	roleText:SetText(L.OPTIONS_ROLE);
	local canBeTank, canBeHealer, canBeDPS = UnitGetAvailableRoles("player");
	local dpsTexture = f:CreateTexture(nil, "OVERLAY");
	dpsTexture:SetTexture("Interface\\LFGFrame\\UI-LFG-ICON-ROLES");
	dpsTexture:SetPoint("TOPLEFT", roleText, 58, 1);
	dpsTexture:SetSize(16, 16);
	dpsTexture:SetTexCoord(GetTexCoordsForRole("DAMAGER"));
	local dpsButton = CreateFrame("CheckButton", nil, f, "UICheckButtonTemplate");
	dpsButton:SetSize(20, 20);
	dpsButton:SetPoint("TOPLEFT", dpsTexture, "TOPLEFT", 0, -15);
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
	healerTexture:SetPoint("TOPLEFT", dpsTexture, 18, 0);
	healerTexture:SetSize(16, 16);
	healerTexture:SetTexCoord(GetTexCoordsForRole("HEALER"));
	local healerButon = CreateFrame("CheckButton", nil, f, "UICheckButtonTemplate");
	healerButon:SetSize(20, 20);
	healerButon:SetPoint("TOPLEFT", healerTexture, "TOPLEFT", 0, -15);
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
	tankTexture:SetPoint("TOPLEFT", healerTexture, 18, 0);
	tankTexture:SetSize(16, 16);
	tankTexture:SetTexCoord(GetTexCoordsForRole("TANK"));
	local tankButton = CreateFrame("CheckButton", nil, f, "UICheckButtonTemplate");
	tankButton:SetSize(20, 20);
	tankButton:SetPoint("TOPLEFT", tankTexture, "TOPLEFT", 0, -15);
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
	local showMoreText = dungeonFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalTiny2");
	showMoreText:SetFont(showMoreText:GetFont(), 10);
	showMoreText:SetPoint("BOTTOMRIGHT", PVEFrame, "BOTTOMRIGHT", -20, 2);
	showMoreText:SetText("Show Less");
	local showMoreButton = CreateFrame("Button", nil, dungeonFrame);
	showMoreButton:SetNormalTexture("Interface\\Buttons\\Arrow-Up-Up.PNG");
	showMoreButton:SetPoint("BOTTOMRIGHT", PVEFrame, "BOTTOMRIGHT", 0, 0);
	showMoreButton:SetSize(18,18);
	showMoreButton:SetScript("OnClick", function(self)
		if (dungeonOptionsFrame:IsShown()) then
			dungeonOptionsFrame:Hide();
			showMoreButton:SetNormalTexture("Interface\\Buttons\\Arrow-Down-Down.PNG");
			showMoreButton:SetPoint("BOTTOMRIGHT", PVEFrame, "BOTTOMRIGHT", 0, -7);
			showMoreText:SetText("Show More");
		else
			dungeonOptionsFrame:Show();
			showMoreButton:SetNormalTexture("Interface\\Buttons\\Arrow-Up-Up.PNG");
			showMoreButton:SetPoint("BOTTOMRIGHT", PVEFrame, "BOTTOMRIGHT", 0, 0);
			showMoreText:SetText("Show Less");
		end
	end);
	local showLeaderScoreForDungeonText = dungeonOptionsFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalTiny2");
	showLeaderScoreForDungeonText:SetFont(showLeaderScoreForDungeonText:GetFont(), 10);
	showLeaderScoreForDungeonText:SetPoint("TOPLEFT", 15, -5);
	showLeaderScoreForDungeonText:SetText("Show Best Key");
	local showLeaderScoreForDungeonButton = CreateFrame("CheckButton", nil, dungeonOptionsFrame, "UICheckButtonTemplate");
	showLeaderScoreForDungeonButton:SetSize(20, 20);
	showLeaderScoreForDungeonButton:SetPoint("RIGHT", showLeaderScoreForDungeonText, "RIGHT", 20, -1);
	showLeaderScoreForDungeonButton:SetChecked(PGF_ShowLeaderDungeonKey);
	showLeaderScoreForDungeonButton:HookScript("OnClick", function(self)
		if (self:GetChecked()) then
			PGF_ShowLeaderDungeonKey = true;
			updateSearch();
			PlaySound(856);
		else
			PGF_ShowLeaderDungeonKey = false;
			updateSearch();
			PlaySound(857);
		end
	end);
	local showDetailedDataText = dungeonOptionsFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalTiny2");
	showDetailedDataText:SetFont(showDetailedDataText:GetFont(), 10);
	showDetailedDataText:SetPoint("TOPLEFT", showLeaderScoreForDungeonText, "TOPLEFT", 0, -18);
	showDetailedDataText:SetText("Show Detailed Roles");
	local showDetailedDataButton = CreateFrame("CheckButton", nil, dungeonOptionsFrame, "UICheckButtonTemplate");
	showDetailedDataButton:SetSize(20, 20);
	showDetailedDataButton:SetPoint("RIGHT", showDetailedDataText, "RIGHT", 20, -1);
	showDetailedDataButton:SetChecked(PGF_DetailedDataDisplay);
	showDetailedDataButton:HookScript("OnClick", function(self)
		if (self:GetChecked()) then
			PGF_DetailedDataDisplay = true;
			updateSearch();
			PlaySound(856);
		else
			PGF_DetailedDataDisplay = false;
			updateSearch();
			PlaySound(857);
		end
	end);
	local sortingText = dungeonOptionsFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalTiny2");
	sortingText:SetFont(sortingText:GetFont(), 10);
	sortingText:SetPoint("TOPLEFT", showDetailedDataText, "TOPLEFT", 0, -28);
	sortingText:SetText("Sort by:");
	local sortingDropdown = CreateFrame("Button", nil, dungeonOptionsFrame, "UIDropDownMenuTemplate");
	sortingDropdown:SetPoint("LEFT", sortingText, "RIGHT", -12, -2);
	local function Initialize_SortingStates(self, level)
		local info = UIDropDownMenu_CreateInfo();
		for k,v in pairs(sortingStates) do
			info = UIDropDownMenu_CreateInfo();
			info.text = v;
			info.value = v;
			info.func = PGF_SortingState_OnClick;
			UIDropDownMenu_AddButton(info, level);
		end
	end

	function PGF_SortingState_OnClick(self)
		UIDropDownMenu_SetSelectedID(sortingDropdown, self:GetID());
		PGF_SortingVariable = self:GetID();
		updateSearch();
	end

	UIDropDownMenu_SetWidth(sortingDropdown, 100);
	UIDropDownMenu_SetButtonWidth(sortingDropdown, 100);
	UIDropDownMenu_JustifyText(sortingDropdown, "CENTER");
	UIDropDownMenu_Initialize(sortingDropdown, Initialize_SortingStates);
	UIDropDownMenu_SetSelectedID(sortingDropdown, PGF_SortingVariable);
	
	dGUI["DAMAGER"] = {["texture"] = dpsTexture, ["checkbox"] = dpsButton};
	dGUI["HEALER"] = {["texture"] = healerTexture, ["checkbox"] = healerButon};
	dGUI["TANK"] = {["texture"] = tankTexture, ["checkbox"] = tankButton};
	dGUI["FilterRoles"] = {["text"] = filterRolesText, ["checkbox"] = filterRolesCheckButton};
	dGUI["MoreOptions"] = {["text"] = showMoreText, ["button"] = showMoreButton};
	dGUI["Sorting"] = {["text"]= sortingText, ["dropDown"] = sortingDropdown};
	dGUI["LeaderScore"] = {["text"] = showLeaderScoreForDungeonText, ["checkbox"] = showLeaderScoreForDungeonButton};
	dGUI["DetailedData"] = {["text"] = showDetailedDataText, ["checkbox"] = showDetailedDataText};
end
--[[
	Documentation: Creates all of the UI elements related to the raidFrame including:
	Difficulty and Raid Dropdown
	Text, checkbox and texture for each boss
	The raids that will show up are the ones we get from recommended activities (same as in the autocomplete in search). All of the bosses will be stored in the currentRaidsActivityIDs[abbrevatedRaidName][abbrevatedBossName]
]]
local function initRaid()
	local raidDifficultyText = raidFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalTiny2");
	raidDifficultyText:SetFont(raidDifficultyText:GetFont(), 10);
	raidDifficultyText:SetPoint("TOPLEFT", 30, -40);
	local raidDifficultyDropDown = CreateFrame("Button", nil, raidFrame, "UIDropDownMenuTemplate");
	raidDifficultyDropDown:SetPoint("LEFT", raidDifficultyText, "RIGHT", -12, -2);
	local function Initialize_RaidStates(self, level)
		local info = UIDropDownMenu_CreateInfo();
		for k,v in pairs(raidStates) do
			info = UIDropDownMenu_CreateInfo();
			info.text = v;
			info.value = v;
			info.func = PGF_RaidState_OnClick;
			UIDropDownMenu_AddButton(info, level);
		end
	end

	function PGF_RaidState_OnClick(self)
		UIDropDownMenu_SetSelectedID(raidDifficultyDropDown, self:GetID());
		lastSelectedRaidState = self:GetText();
		if (self:GetText():match(" All")) then --there is no activity for All so if there is a previous activity set in the searchbox it needs to be cleared
			C_LFGList.ClearSearchTextFields();
		elseif (PGF_allRaidActivityIDs[raidStateMap[lastSelectedRaidState]]) then
			C_LFGList.SetSearchToActivity(raidStateMap[lastSelectedRaidState]);
		end
		updateRaidDifficulty(true);
	end

	UIDropDownMenu_SetWidth(raidDifficultyDropDown, 100);
	UIDropDownMenu_SetButtonWidth(raidDifficultyDropDown, 100);
	UIDropDownMenu_JustifyText(raidDifficultyDropDown, "CENTER");
	UIDropDownMenu_Initialize(raidDifficultyDropDown, Initialize_RaidStates);
	UIDropDownMenu_SetSelectedID(raidDifficultyDropDown, 4);
	local matchingActivities = C_LFGList.GetAvailableActivities(3, nil, ResolveCategoryFilters(3, 1), ""); --3 == raid category 0 is to set there arent any language filters
	for i = 1, #matchingActivities do
		local name = PGF_allRaidActivityIDs[matchingActivities[i]];
		local shortName = name:gsub("%s%(.*", "")
		local difficulty = name:match("%(.*%)");
		if (raidAbbreviations[shortName]) then
			shortName = raidAbbreviations[shortName];
			currentRaidsActivityIDs[matchingActivities[i]] = {};
			for j = 1, #bossOrderMap[shortName] do
				currentRaidsActivityIDs[matchingActivities[i]][j] = bossNameMap[shortName][bossOrderMap[shortName][j]];
			end
		end
	end
	--create all buttons, have updateDifficulty display different buttons
	--super expensive function, made cheaper
	--EJ_GetCreatureInfo(1, eID) returns the boss icon
	for aID, bossNames in pairs(currentRaidsActivityIDs) do
		local count = 0;
		rGUI[aID] = {};
		for index, name in pairs(currentRaidsActivityIDs[aID]) do
			count = count + 1;
			local texture = raidFrame:CreateTexture(nil, "OVERLAY");
			texture:SetTexCoord(0.15, 0.85, 0, 0.7)
			local shortName = name:gsub("%s%(.*", "");
			local raidNameShort = PGF_allRaidActivityIDs[aID]:gsub("%s%(.*", "");
			local trimedName = bossOrderMap[raidAbbreviations[raidNameShort]][index]:gsub("(%s)","");
			trimedName = trimedName:gsub(",","");
			texture:SetTexture("Interface\\ENCOUNTERJOURNAL\\UI-EJ-BOSS-" .. trimedName ..".PNG");
			texture:SetPoint("TOPLEFT", 30,-65-((count-1)*24));
			texture:SetSize(18, 18);
			local checkbox = CreateFrame("CheckButton", nil, raidFrame, "UICheckButtonTemplate");
			checkbox:SetSize(20, 20);
			checkbox:SetPoint("TOPLEFT", texture, "TOPLEFT", 19, 2);
			checkbox:SetScript("OnClick", function(self)
				if (self:GetChecked()) then
					selectedInfo.bosses[name] = true;
					updateSearch();
				else
					selectedInfo.bosses[name] = nil;
					updateSearch();
				end
			end);
			local text = raidFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalTiny2");
			text:SetPoint("TOPLEFT", checkbox, "TOPLEFT", 19, -3);
			text:SetJustifyV("TOP");
			text:SetJustifyH("LEFT");
			text:SetText(name);
			text:SetFont(text:GetFont(), 12);
			text:SetTextColor(1,1,1,1);
			rGUI[aID][name] = {};
			rGUI[aID][name].text = text;
			rGUI[aID][name].checkbox = checkbox;
			rGUI[aID][name].texture = texture;
			text:Hide();
			checkbox:Hide();
		end
	end
	--[[
	local slowSearchCheckBox = CreateFrame("CheckButton", nil, raidFrame, "UICheckButtonTemplate");
	slowSearchCheckBox:SetSize(20, 20);
	slowSearchCheckBox:SetPoint("TOPLEFT", 49,-283);
	slowSearchCheckBox:SetScript("OnClick", function(self)
		if (self:GetChecked()) then
			slowSearch = true;
			updateSearch();
		else
			slowSearch = false;
			updateSearch();
		end
	end);
	local slowSearchtext = raidFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalTiny2");
	slowSearchtext:SetPoint("TOPLEFT", slowSearchCheckBox, "TOPLEFT", 19, -3);
	slowSearchtext:SetJustifyV("TOP");
	slowSearchtext:SetJustifyH("LEFT");
	slowSearchtext:SetText("Advanced Search");
	slowSearchtext:SetFont(slowSearchtext:GetFont(), 12);
	slowSearchtext:SetTextColor(1,1,1,1);
	]]
	--LFGListApplicationDialog.Description.EditBox:SetFont(LFGListApplicationDialog.Description.EditBox:GetFont(), 7);
	rGUI["raidDifficulty"] = {["dropDown"] = raidDifficultyDropDown, ["text"] = raidDifficultyText};
	raidDifficultyText:SetText(L.OPTIONS_RAID_SELECT);
	--Use input:GetNumber() to ensure its a number, returns 0 if not a number which is fine in this case
end
--[[
	Documentation: Initiate the UI if it has not been done before.
]]
PVEFrame:HookScript("OnShow", function(self)
	if(next(dGUI) == nil) then
		initDungeon();
		initRaid();
	end
end);

f:SetScript("OnEvent", function(self, event, ...) 
	if (event == "PLAYER_LOGIN") then
		if (PGF_roles == nil) then 
			local playerRole = GetSpecializationRole(GetSpecialization());
			PGF_roles = {["TANK"] = false, ["HEALER"] = false, ["DAMAGER"] = false};
			PGF_roles[playerRole] = true;
		end
		if (PGF_FilterRemaningRoles == nil) then PGF_FilterRemaningRoles = true; end
		if (PGF_DetailedDataDisplay == nil) then PGF_DetailedDataDisplay = true; end
		if (PGF_ShowLeaderDungeonKey == nil) then PGF_ShowLeaderDungeonKey = false; end
		if (PGF_SortingVariable == nil) then PGF_SortingVariable = 1; end
		if IsInGuild() then
			C_ChatInfo.SendAddonMessage("PGF_VERSIONCHECK", version, "GUILD");
		end
	elseif (event == "GROUP_ROSTER_UPDATE") then
		if (IsInRaid(LE_PARTY_CATEGORY_INSTANCE) or IsInGroup(LE_PARTY_CATEGORY_INSTANCE)) then
			C_ChatInfo.SendAddonMessage("PGF_VERSIONCHECK", version, "INSTANCE_CHAT");
		elseif (IsInRaid(LE_PARTY_CATEGORY_HOME)) then
			C_ChatInfo.SendAddonMessage("PGF_VERSIONCHECK", version, "RAID");
		elseif (IsInGroup(LE_PARTY_CATEGORY_HOME)) then
			C_ChatInfo.SendAddonMessage("PGF_VERSIONCHECK", version, "PARTY");
		end
	elseif (event == "CHAT_MSG_SYSTEM") then
		local msg = ...;
		local sender = msg;
		msg = msg:match("%s(.+)")
		if (msg == FRIEND_ONLINE) then
			sender = sender:match("%[(.+)%]");
			if (sender ~= UnitName("player")) then
				C_Timer.After(5, function() 
					if (sender ~= nil and UnitIsConnected(sender)) then
						C_ChatInfo.SendAddonMessage("PGF_VERSIONCHECK", version, "WHISPER", sender);
					end
				end);
			end
		end
	elseif (event == "CHAT_MSG_ADDON") then
		local prefix, msg, channel, sender = ...;
		local sender = Ambiguate(sender, "none");
		if (prefix == "PGF_VERSIONCHECK" and not recievedOutOfDateMessage and not UnitIsUnit(UnitName("player"), sender)) then
			if (tonumber(msg) ~= nil) then
				if (tonumber(msg) > tonumber(version)) then
					DEFAULT_CHAT_FRAME:AddMessage("\124T|cFFFFFF00\124t" .. L.WARNING_OUTOFDATEMESSAGE);
					recievedOutOfDateMessage = true;
				end
			end
		end
	elseif (event == "PLAYER_ENTERING_WORLD") then
		if (next(GUI) == nil) then
			
		end
	end
end);

f:SetScript("OnShow", function() 
	if (LFGListFrame.SearchPanel.categoryID) then
	end
end);
--[[
	Documentation: Based on which category is selected different frames are shown. If the category is different from last time all widgets are first hidden and the selectedInfo is reset for that category otherwise we restore all the options from before.
]]
LFGListFrame.SearchPanel:HookScript("OnShow", function(self)
	local search = LFGListFrame.SearchPanel;
	search.AutoCompleteFrame:SetFrameStrata("TOOLTIP");
	local cat = search.categoryID;
	if (cat and cat == GROUP_FINDER_CATEGORY_ID_DUNGEONS) then
		if (cat ~= lastCat) then
			PGF_ShowDungeonFrame(false);
			lastCat = cat;
		else
			PGF_ShowDungeonFrame(true);
		end
		f:Show();
		if (next(selectedInfo.dungeons)) then
			updateSearch();
		end
	elseif (cat and cat == 3) then
		if (cat ~= lastCat) then
			lastCat = cat;
			PGF_ShowRaidFrame(false);
		else
			PGF_ShowRaidFrame(true);
		end
		f:Show();
		if(next(selectedInfo.bosses)) then
			updateSearch();
		end
	else
		LFGListSearchPanel_Clear(LFGListFrame.SearchPanel);
		if (cat ~= lastCat) then
			lastCat = cat;
		else
		end
		if (next(originalUI) == nil) then
			saveOriginalUI();
		end
		restoreOriginalUI();
	end
end);
--[[
	Documentation: Change the texture of the refresh button to show searching is unavailable
]]
LFGListFrame.SearchPanel.RefreshButton:HookScript("OnClick", function(self)
	self:SetScript("OnClick", function() end);
	self.Icon:SetTexture("Interface\\AddOns\\PGFinder\\Res\\RedRefresh.tga");
	searchAvailable = false;
end);
--[[
	Documentation: This script hooks the OnEnter for the Refresh button to show different tooltips based on if a search is available or not. If a search is unavailable it shows how much time remains until the next search can be done.
]]
LFGListFrame.SearchPanel.RefreshButton:HookScript("OnEnter", function(self)
	if (searchAvailable) then
		GameTooltip:SetOwner(self);
		GameTooltip:SetText("Search Available");
		GameTooltip:Show();
	else
		GameTooltip:SetOwner(self);
		local calc = string.format("%.2fs", refreshTimeReset-ticks);
		GameTooltip:SetText(L.OPTIONS_REFRESH_BUTTON_DISABLED .. calc, 1, 1, 1, 1, true);
		GameTooltip:Show();
	end
end);

LFGListFrame.SearchPanel.RefreshButton:HookScript("OnLeave", function(self)
	GameTooltip:Hide();
end);

LFGListFrame.SearchPanel:HookScript("OnHide", function(self)
	f:Hide();
	restoreOriginalUI();
end);

LFGListFrame.SearchPanel.SearchBox:SetScript("OnEnterPressed", LFGListSearchPanelSearchBox_OnEnterPressed);

--[[
	Documentation: The function is a blizzard function that is called enter is pressed in the search box.
	This version overwrites it to prevent it from searching before enough time has passed for a new search to be available.

	Payload:
	self param(table/object) - LFGListFrame.SearchPanel.SearchBox
]]

function LFGListSearchPanelSearchBox_OnEnterPressed(self)
	local parent = self:GetParent();
	if ( parent.AutoCompleteFrame:IsShown() and parent.AutoCompleteFrame.selected ) then
		C_LFGList.SetSearchToActivity(parent.AutoCompleteFrame.selected);
	end
	if (searchAvailable) then
		searchAvailable = false;
		LFGListFrame.SearchPanel.RefreshButton:SetScript("OnClick", function() end);
		LFGListFrame.SearchPanel.RefreshButton.Icon:SetTexture("Interface\\AddOns\\PGFinder\\Res\\RedRefresh.tga");
		LFGListSearchPanel_DoSearch(self:GetParent());
		self:ClearFocus();
	end
end

--[[
	Documentation: The function is a blizzard function that is called every time the user presses the Find a Group button.
	This version overwrites it to prevent it from clearing the searchbox every time the frame is opened. Instead we clear it when a category is changed in the frames own Show function.

	Payload:
	self param(table/object) - LFGListFrame
	questID parram(int) - the questID if there is one
]]

function LFGListCategorySelection_StartFindGroup(self, questID)
	local baseFilters = self:GetParent().baseFilters;

	local searchPanel = self:GetParent().SearchPanel;
	if (questID) then
		C_LFGList.SetSearchToQuestID(questID);
	end
	LFGListSearchPanel_SetCategory(searchPanel, self.selectedCategory, self.selectedFilters, baseFilters);
	LFGListSearchPanel_DoSearch(searchPanel);
	LFGListFrame_SetActivePanel(self:GetParent(), searchPanel);
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

--[[
	Documentation: The function is a blizzard function that is called every time you are inside a premade group already and new applicants show up.
	This hooked version allows everyone in the group to browse groups rather than just the leader.

	Payload:
	param(arr/object) - the application viewer
]]

local function PGF_LFGListApplicationViewer_UpdateInfo(self)
	self.BrowseGroupsButton:SetShown(true);
end

hooksecurefunc("LFGListApplicationViewer_UpdateInfo", PGF_LFGListApplicationViewer_UpdateInfo);

--[[
	Documentation: The function is a blizzard function that decides all of possible actions when right clicking a group. The function also defines the arguments used in the function defined in the payload. So arg1 is sent to the function as a param.
	This version overwrites the original because it needs to do a return. So this function changes it so that if it is a raid group you have the option to send your best raiding achievement.

	Payload:
	param(int) - the resultID from GetSearchResults for that specific group

	Returns(arr) - an array with all of the information and arguments to the necessairy functions and text fields of the right click dropdown.
]]

function LFGListUtil_GetSearchEntryMenu(resultID)
	local searchResults = C_LFGList.GetSearchResultInfo(resultID);
	local _, appStatus, pendingStatus, appDuration = C_LFGList.GetApplicationInfo(resultID);
	local activityID = searchResults.activityID;
	local activityInfo = C_LFGList.GetActivityInfoTable(activityID);
	local activityFullName = activityInfo.fullName;
	local categoryID = activityInfo.categoryID;
	local activityShortName = activityFullName:gsub("%s%(.*", "");
	LFG_LIST_SEARCH_ENTRY_MENU[1].text = searchResults.name;
	LFG_LIST_SEARCH_ENTRY_MENU[2].arg1 = searchResults.leaderName;
	local applied = (appStatus == "applied" or appStatus == "invited");
	LFG_LIST_SEARCH_ENTRY_MENU[2].disabled = not searchResults.leaderName;
	LFG_LIST_SEARCH_ENTRY_MENU[2].tooltipTitle = (not applied) and WHISPER;
	LFG_LIST_SEARCH_ENTRY_MENU[2].tooltipText = (not applied) and LFG_LIST_MUST_SIGN_UP_TO_WHISPER;
	LFG_LIST_SEARCH_ENTRY_MENU[3].arg1 = resultID;
	LFG_LIST_SEARCH_ENTRY_MENU[3].arg2 = searchResults.leaderName;
	LFG_LIST_SEARCH_ENTRY_MENU[4].arg1 = resultID;
	LFG_LIST_SEARCH_ENTRY_MENU[4].arg2 = searchResults.leaderName;
	LFG_LIST_SEARCH_ENTRY_MENU[5].arg1 = activityShortName;
	LFG_LIST_SEARCH_ENTRY_MENU[5].arg2 = searchResults.leaderName;
	LFG_LIST_SEARCH_ENTRY_MENU[5].tooltipTitle = (not applied) and WHISPER;
	if (categoryID == 3) then
		LFG_LIST_SEARCH_ENTRY_MENU[5].disabled = not searchResults.leaderName;
		LFG_LIST_SEARCH_ENTRY_MENU[5].tooltipText = (not applied) and LFG_LIST_MUST_SIGN_UP_TO_WHISPER;
	else
		LFG_LIST_SEARCH_ENTRY_MENU[5].disabled = true;
		LFG_LIST_SEARCH_ENTRY_MENU[5].tooltipText = "Only applicable for raid groups";
	end
	return LFG_LIST_SEARCH_ENTRY_MENU;
end

--C_LFGList.GetSearchResultEncounterInfo(self.resultID) returns a table [1 to n] = Boss Name or Encounter Name?

--[[
	Documentation: The function is a blizzard function that decides in which way the displayData should be shown, if it is a raid group it should show roles numerically for example. It also determines when the displayData should be shown and all of the application widgets such as pending texts, cancel buttons etc. It also contains the text name of the groups.
	The hooked version changes it so that displayData is always shown and moves the pending text, expiration text and the cancel button. While also adding the leaders m+ score to the name of the group if it is a dungeon group.

	Payload:
	param(arr/object) - the resultsInset nine slice that contains the information of the group
]]

local function PGF_LFGListSearchEntry_Update(self)
	local resultID = self.resultID;
	if not C_LFGList.HasSearchResultInfo(resultID) then
		return;
	end

	local _, appStatus, pendingStatus, appDuration = C_LFGList.GetApplicationInfo(resultID);

	local isApplication = (appStatus ~= "none" or pendingStatus);

	--Update visibility based on whether we're an application or not
	self.DataDisplay:SetShown(true);
	if (pendingStatus == "applied" and C_LFGList.GetRoleCheckInfo()) then
		self.PendingLabel:SetText(LFG_LIST_ROLE_CHECK);
		self.PendingLabel:SetTextColor(NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b);
		self.PendingLabel:Show();
		self.ExpirationTime:Hide();
		self.CancelButton:Hide();
	elseif (pendingStatus == "cancelled" or appStatus == "cancelled" or appStatus == "failed") then
		self.PendingLabel:SetText(LFG_LIST_APP_CANCELLED);
		self.PendingLabel:SetTextColor(RED_FONT_COLOR.r, RED_FONT_COLOR.g, RED_FONT_COLOR.b);
		self.PendingLabel:Show();
		self.ExpirationTime:Hide();
		self.CancelButton:Hide();
	elseif (appStatus == "declined" or appStatus == "declined_full" or appStatus == "declined_delisted") then
		if (appStatus == "declined_delisted") then
			self.PendingLabel:SetText("Delisted");
		elseif (appStatus == "declined_full") then
			self.PendingLabel:SetText(LFG_LIST_APP_FULL);
		elseif (appStatus == "declined") then
			self.PendingLabel:SetText(LFG_LIST_APP_DECLINED);
		end
		self.PendingLabel:SetTextColor(RED_FONT_COLOR.r, RED_FONT_COLOR.g, RED_FONT_COLOR.b);
		self.PendingLabel:Show();
		self.ExpirationTime:Hide();
		self.CancelButton:Hide();
	elseif (appStatus == "timedout") then
		self.PendingLabel:SetText(LFG_LIST_APP_TIMED_OUT);
		self.PendingLabel:SetTextColor(RED_FONT_COLOR.r, RED_FONT_COLOR.g, RED_FONT_COLOR.b);
		self.PendingLabel:Show();
		self.ExpirationTime:Hide();
		self.CancelButton:Hide();
	elseif (appStatus == "invited") then
		self.PendingLabel:SetText(LFG_LIST_APP_INVITED);
		self.PendingLabel:SetTextColor(GREEN_FONT_COLOR.r, GREEN_FONT_COLOR.g, GREEN_FONT_COLOR.b);
		self.PendingLabel:Show();
		self.ExpirationTime:Hide();
		self.CancelButton:Hide();
	elseif (appStatus == "inviteaccepted") then
		self.PendingLabel:SetText(LFG_LIST_APP_INVITE_ACCEPTED);
		self.PendingLabel:SetTextColor(GREEN_FONT_COLOR.r, GREEN_FONT_COLOR.g, GREEN_FONT_COLOR.b);
		self.PendingLabel:Show();
		self.ExpirationTime:Hide();
		self.CancelButton:Hide();
	elseif (appStatus == "invitedeclined") then
		self.PendingLabel:SetText(LFG_LIST_APP_INVITE_DECLINED);
		self.PendingLabel:SetTextColor(RED_FONT_COLOR.r, RED_FONT_COLOR.g, RED_FONT_COLOR.b);
		self.PendingLabel:Show();
		self.ExpirationTime:Hide();
		self.CancelButton:Hide();
	elseif (isApplication and pendingStatus ~= "applied") then
		self.PendingLabel:SetText(LFG_LIST_PENDING);
		self.PendingLabel:SetTextColor(GREEN_FONT_COLOR.r, GREEN_FONT_COLOR.g, GREEN_FONT_COLOR.b);
		self.PendingLabel:SetSize(self:GetWidth()-30, self:GetHeight())
		self.PendingLabel:Hide();
		self.ExpirationTime:Show();
		if (LFGListFrame.SearchPanel.categoryID == GROUP_FINDER_CATEGORY_ID_DUNGEONS) then
			self.ExpirationTime:SetPoint("LEFT", self.DataDisplay, "LEFT", -30, 0);
		else
			self.ExpirationTime:SetPoint("LEFT", self.DataDisplay, "LEFT", -50, 0);
		end
		self.CancelButton:Show();
		self.CancelButton:ClearAllPoints();
		self.CancelButton:SetPoint("RIGHT", self.DataDisplay, "RIGHT", -10, 0);
		self.CancelButton:SetSize(19,19);
	else
		self.PendingLabel:Hide();
		self.ExpirationTime:Hide();
		self.CancelButton:Hide();
	end


	--Change the anchor of the label depending on whether we have the expiration time
	self.PendingLabel:SetPoint("LEFT", self.DataDisplay, "LEFT", -200, 5);
	self.PendingLabel:SetJustifyH("Center");


	local searchResultInfo = C_LFGList.GetSearchResultInfo(resultID);
	--possible to take the name here and filter it out here if no match?
	self.resultID = resultID;
	if (LFGListFrame.SearchPanel.categoryID == GROUP_FINDER_CATEGORY_ID_DUNGEONS) then
		local leaderOverallDungeonScore = searchResultInfo.leaderOverallDungeonScore;
		local leaderDungeonScoreInfo = searchResultInfo.leaderDungeonScoreInfo;
		local dungeonScoreText = "";
		--
		if (leaderDungeonScoreInfo == nil or leaderDungeonScoreInfo.mapScore == 0) then
			--leaderDungeonScoreInfo.bestRunLevel = 0;
			--leaderOverallDungeonScore.finishedSuccess = false;
			dungeonScoreText = "|cffaaaaaa+0|r"
		elseif (not leaderDungeonScoreInfo.finishedSuccess) then
			dungeonScoreText = "|cffaaaaaa+" .. leaderDungeonScoreInfo.bestRunLevel .. "|r";
		else
			dungeonScoreText = "|cff00aa00+" .. leaderDungeonScoreInfo.bestRunLevel .. "|r";
		end
		if (leaderOverallDungeonScore == nil) then
			leaderOverallDungeonScore = 0;
		end
		local r, g, b = unpack(getColorForScoreLookup(leaderOverallDungeonScore));
	    local color = format("%02x%02x%02x", r*255,g*255,b*255);
	    local scoreText = format("|cFF%s%s|r", color, leaderOverallDungeonScore);
	    if (PGF_ShowLeaderDungeonKey) then
			self.Name:SetText(searchResultInfo.name .. " (" .. scoreText .. ")" .. "[" .. dungeonScoreText .. "]");
		else
			self.Name:SetText(searchResultInfo.name .. " (" .. scoreText .. ")");
		end
	end

	local displayData = C_LFGList.GetSearchResultMemberCounts(resultID);
	LFGListGroupDataDisplay_Update(self.DataDisplay, searchResultInfo.activityID, displayData, searchResultInfo.isDelisted);
end

hooksecurefunc("LFGListSearchEntry_Update", PGF_LFGListSearchEntry_Update);
--[[
	Documentation: This is a Blizzard function that is triggered whenever someone applies to the group and controls all of the information displayed about each applicant
	This hooked version will change the coloring system when the categoryID is dungeons
]]
function PGF_LFGListApplicationViewer_UpdateApplicantMember(member, appID, memberIdx, status, pendingStatus)
	local grayedOut = not pendingStatus and (status == "failed" or status == "cancelled" or status == "declined" or status == "declined_full" or status == "declined_delisted" or status == "invitedeclined" or status == "timedout" or status == "inviteaccepted" or status == "invitedeclined");
	local name, class, localizedClass, level, itemLevel, honorLevel, tank, healer, damage, assignedRole, relationship, dungeonScore, pvpItemLevel = C_LFGList.GetApplicantMemberInfo(appID, memberIdx);
	if (not grayedOut and LFGApplicationViewerRatingColumnHeader:IsShown() and dungeonScore) then
		if (dungeonScore == nil) then
			dungeonScore = 0;
		end
		local r, g, b = unpack(getColorForScoreLookup(dungeonScore));
		local color = CreateColorFromBytes(r*255,g*255,b*255,1):GenerateHexColor();
		local activeEntryInfo = C_LFGList.GetActiveEntryInfo();
		local applicantDungeonScoreInfo = C_LFGList.GetApplicantDungeonScoreForListing(appID, memberIdx, activeEntryInfo.activityID);
		local dungeonScoreText = "";
		if (applicantDungeonScoreInfo == nil or applicantDungeonScoreInfo.mapScore == 0) then
			--leaderDungeonScoreInfo.bestRunLevel = 0;
			--leaderOverallDungeonScore.finishedSuccess = false;
			dungeonScoreText = "|cffaaaaaa[+0]|r"
		elseif (not applicantDungeonScoreInfo.finishedSuccess) then
			dungeonScoreText = "|cffaaaaaa[+" .. applicantDungeonScoreInfo.bestRunLevel .. "]|r";
		else
			dungeonScoreText = "|cff00aa00[+" .. applicantDungeonScoreInfo.bestRunLevel .. "]|r";
		end
		member.Rating:SetText(WrapTextInColorCode(dungeonScore, color) .. dungeonScoreText);
		member.Rating:Show();
	end
end

hooksecurefunc("LFGListApplicationViewer_UpdateApplicantMember", PGF_LFGListApplicationViewer_UpdateApplicantMember);

--[[
	Documentation: This is a sort function for returning a table that is sorted by role putting tanks first, then healers and lastly DPS defined in the roleIndex array.

	Payload:
	param(arr) - contains the name, spec and class of the player to be used post sort of the first player.
	param(arr) - contains the name, spec and class of the player to be used post sort of the 2nd player.
]]

local function sortRoles(pl1, pl2)
	return roleIndex[pl1.role] < roleIndex[pl2.role];
end

--[[
	Documentation: The function is a blizzard function that decides how to display the displayData for groups just showing how many of roles there are in the group but it displays it by showing 1 icon per player in group (i.e dungeon groups).
	The hooked version moves the displayData to the left to fit a cancel button to the right of it but also iterates through the specs in the group and sorts them by iconOrder (tank, healer, dps from left to right) and shows their spec icons.
	The loops is backwards because icon[1] is mosts right and we want to show available slots at the right side. Once iterating over all the players in the group we fill the remaning slots with custom tank/healer/dps icons showing which spots are still available.

	Payload:
	param(arr/object) - the resultsInset nine slice that contains the information of the group
	param(arr) - keeps the amount of each roles, remaining roles and amount of each classes in the group example ["DAMAGER"] = 1, ["DAMAGER_REMAINING"] = 2, ["MAGE"] = 1
	param(bool) - if the group is delisted
	param(arr) - keeps track of the order it should display the icons, [1] = TANK, [2] = HEALER, [3] = DAMAGER
]]
local function PGF_LFGListGroupDataDisplayEnumerate_Update(self, numPlayers, displayData, disabled, iconOrder)
	local players = {};
	self:SetSize(125, 24);
	local p1, p2, p3, p4, p5 = self:GetPoint(1);
	self:ClearAllPoints();
	self:SetPoint(p1, p2, p3, -25, p5);
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
	--Another implementation for evokers
	for i = 1, searchResults.numMembers do
		if (true or players[i].class == "EVOKER") then
			if (PGF_DetailedDataDisplay) then
				self.Icons[6-i]:SetTexture(select(4, GetSpecializationInfoByID(classSpecilizationMap[players[i].class][players[i].spec])));
				self.Icons[6-i]:SetTexCoord(0,1,0,1);
			else
				self.Icons[6-i]:SetTexture("Interface\\AddOns\\PGFinder\\Res\\" .. players[i].class .. "_" .. players[i].role .. ".tga");
			end
		else
			self.Icons[6-i]:SetAtlas("GarrMission_ClassIcon-"..strlower(players[i].class).."-"..players[i].spec, false);
		end
	end
	local count = 1;
	for i = 3, 1, -1 do
		for j = 1, displayData[roleRemainingKeyLookup[iconOrder[i]]] do
			if (PGF_DetailedDataDisplay) then
				self.Icons[count]:SetTexture("Interface\\addons\\PGFinder\\Res\\" .. roleRemainingKeyLookup[iconOrder[i]]);
				self.Icons[count]:SetTexCoord(0,1,0,1);
			else
				self.Icons[count]:SetAtlas("groupfinder-icon-emptyslot", false);
			end
			count = count + 1;
		end
	end
end

hooksecurefunc("LFGListGroupDataDisplayEnumerate_Update", PGF_LFGListGroupDataDisplayEnumerate_Update);

--[[
	Documentation: The function is a blizzard function that decides how to display the displayData for groups just showing how many of each role there are numerically (i.e raid groups)
	The hooked version moves the displayData to the left to fit a cancel button to the right of it.

	param(arr/object) - the resultsInset nine slice that contains the information of the group
	param(arr) - keeps the amount of each roles, remaining roles and amount of each classes in the group example ["DAMAGER"] = 1, ["DAMAGER_REMAINING"] = 2, ["MAGE"] = 1
	param(bool) - if the group is delisted
]]

local function PGF_LFGListGroupDataDisplayRoleCount_Update(self, displayData, disabled)
	self:SetSize(125, 24);
	local p1, p2, p3, p4, p5 = self:GetPoint(1);
	self:ClearAllPoints();
	self:SetPoint(p1, p2, p3, -25, p5);
	self.TankCount:SetText(displayData.TANK);
	self.HealerCount:SetText(displayData.HEALER);
	self.DamagerCount:SetText(displayData.DAMAGER);

	--Update for the disabled state
	local r = disabled and LFG_LIST_DELISTED_FONT_COLOR.r or HIGHLIGHT_FONT_COLOR.r;
	local g = disabled and LFG_LIST_DELISTED_FONT_COLOR.g or HIGHLIGHT_FONT_COLOR.g;
	local b = disabled and LFG_LIST_DELISTED_FONT_COLOR.b or HIGHLIGHT_FONT_COLOR.b;
	self.TankCount:SetTextColor(r, g, b);
	self.HealerCount:SetTextColor(r, g, b);
	self.DamagerCount:SetTextColor(r, g, b);
	self.TankIcon:SetDesaturated(disabled);
	self.HealerIcon:SetDesaturated(disabled);
	self.DamagerIcon:SetDesaturated(disabled);
	self.TankIcon:SetAlpha(disabled and 0.5 or 0.70);
	self.HealerIcon:SetAlpha(disabled and 0.5 or 0.70);
	self.DamagerIcon:SetAlpha(disabled and 0.5 or 0.70);
end

hooksecurefunc("LFGListGroupDataDisplayRoleCount_Update", PGF_LFGListGroupDataDisplayRoleCount_Update);


--[[
	Documentation: The function is a blizzard function that decides how to display the displayData for groups just showing how many players are in the groups (i.e quest groups)
	The hooked version moves the displayData to the left to fit a cancel button to the right of it.

	param(arr/object) - the resultsInset nine slice that contains the information of the group
	param(arr) - keeps the amount of each roles, remaining roles and amount of each classes in the group example ["DAMAGER"] = 1, ["DAMAGER_REMAINING"] = 2, ["MAGE"] = 1
	param(bool) - if the group is delisted
]]

function PGF_LFGListGroupDataDisplayPlayerCount_Update(self, displayData, disabled)
	self:SetSize(125, 24);
	local p1, p2, p3, p4, p5 = self:GetPoint(1);
	self:ClearAllPoints();
	self:SetPoint(p1, p2, p3, -25, p5);
	local numPlayers = displayData.TANK + displayData.HEALER + displayData.DAMAGER + displayData.NOROLE;
	local color = disabled and LFG_LIST_DELISTED_FONT_COLOR or HIGHLIGHT_FONT_COLOR;
	self.Count:SetText(numPlayers);
	self.Count:SetTextColor(color.r, color.g, color.b);
	self.Icon:SetDesaturated(disabled);
	self.Icon:SetAlpha(disabled and 0.5 or 1);
end

hooksecurefunc("LFGListGroupDataDisplayPlayerCount_Update", PGF_LFGListGroupDataDisplayPlayerCount_Update);

--[[
	Documentation: Calculates the time it took to start the search and when results are ready to be presented to the user as well as how many there are

	Payload:
	numResults parram(int) - how many results were found after filtering
	time parram(int) - the current time of when the filtering was completed
]]
local function updatePerformanceText(numResults, time)
	local calc = string.format("%.3fs", time - performanceTimeStamp);
	PGF_SetPerformanceText("[PGF] Found " .. numResults .. " results in " .. calc);
	performanceTimeStamp = time;
end


--[[
	Documentation: This is a blizzard function that decides which results that should be shown by adding them to self as well as how many results there are. Blizzard has a cap on ~100 results so not all results are available here.
	This function overrides the blizzard function and sorts out groups based on the users config. User can filter out groups based on dungeons, bosses, leaderScore and if the group is eligible based on the roles of the player/current group

	Payload:
	self parram(table/object) - the LFGListFrame.SearchPanel
	Return:
	bool - true if there are results
]]
function LFGListSearchPanel_UpdateResultList(self)
	if (LFGListFrame.SearchPanel.categoryID == GROUP_FINDER_CATEGORY_ID_DUNGEONS) then
		if(next(selectedInfo.dungeons) == nil and selectedInfo["leaderScore"] == 0 and not PGF_FilterRemaningRoles) then
			LFGListFrame.SearchPanel.RefreshButton:SetScript("OnClick", function() end);
			LFGListFrame.SearchPanel.RefreshButton.Icon:SetTexture("Interface\\AddOns\\PGFinder\\Res\\RedRefresh.tga");
			searchAvailable = false;
			self.totalResults, self.results = C_LFGList.GetFilteredSearchResults();
			self.applications = C_LFGList.GetApplications();
			for i = 1, #self.results do
				if (leaderOverallDungeonScore == nil) then
					leaderOverallDungeonScore = 0;
				end
				--self.results[i].searchResults.name = name .. " (" .. leaderOverallDungeonScore .. ")";
			end
			LFGListUtil_SortSearchResults(self.results);
			LFGListSearchPanel_UpdateResults(self);
			updatePerformanceText(self.totalResults, GetTimePreciseSec());
			return true;
		end
		if (slowSearch == false) then
			LFGListFrame.SearchPanel.RefreshButton:SetScript("OnClick", function() end);
			LFGListFrame.SearchPanel.RefreshButton.Icon:SetTexture("Interface\\AddOns\\PGFinder\\Res\\RedRefresh.tga");
			searchAvailable = false;
			self.totalResults, self.results = C_LFGList.GetFilteredSearchResults();
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
				if (leaderOverallDungeonScore == nil) then
					leaderOverallDungeonScore = 0;
				end
				if (next(selectedInfo.dungeons) ~= nil) then
					if (selectedInfo.dungeons[activityID] and (requiredDungeonScore == nil or C_ChallengeMode.GetOverallDungeonScore() >= requiredDungeonScore) and (selectedInfo["leaderScore"] == 0 or selectedInfo["leaderScore"] < leaderOverallDungeonScore) and (not PGF_FilterRemaningRoles or HasRemainingSlotsForLocalPlayerRole(self.results[i]))) then
						table.insert(newResults, self.results[i]);
					end
				elseif (selectedInfo["leaderScore"] > 0) then
					if ((requiredDungeonScore == nil or C_ChallengeMode.GetOverallDungeonScore() >= requiredDungeonScore) and selectedInfo["leaderScore"] < leaderOverallDungeonScore and (not HasRemainingSlotsForLocalPlayerRole or HasRemainingSlotsForLocalPlayerRole(self.results[i]))) then
						table.insert(newResults, self.results[i]);
					end
				elseif (PGF_FilterRemaningRoles) then
					if ((requiredDungeonScore == nil or C_ChallengeMode.GetOverallDungeonScore() >= requiredDungeonScore) and HasRemainingSlotsForLocalPlayerRole(self.results[i])) then
						table.insert(newResults, self.results[i]);
					end
				end
			end
			LFGListUtil_SortSearchResults(newResults);
			self.totalResults = #newResults;
			self.results = newResults;
			self.applications = C_LFGList.GetApplications();
			LFGListSearchPanel_UpdateResults(self);
			updatePerformanceText(self.totalResults, GetTimePreciseSec());
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
				updatePerformanceText(self.totalResults, GetTimePreciseSec());
				return true;
			end
		end
	elseif (LFGListFrame.SearchPanel.categoryID == 3) then
		if(next(selectedInfo.bosses) == nil) then
			LFGListFrame.SearchPanel.RefreshButton:SetScript("OnClick", function() end);
			LFGListFrame.SearchPanel.RefreshButton.Icon:SetTexture("Interface\\AddOns\\PGFinder\\Res\\RedRefresh.tga");
			searchAvailable = false;
			self.totalResults, self.results = C_LFGList.GetFilteredSearchResults();
			self.applications = C_LFGList.GetApplications();
			for i = 1, #self.results do
				if (leaderOverallDungeonScore == nil) then
					leaderOverallDungeonScore = 0;
				end
			end
			LFGListUtil_SortSearchResults(self.results);
			LFGListSearchPanel_UpdateResults(self);
			updatePerformanceText(self.totalResults, GetTimePreciseSec());
			return true;
		end
		if (slowSearch == false) then
			LFGListFrame.SearchPanel.RefreshButton:SetScript("OnClick", function() end);
			LFGListFrame.SearchPanel.RefreshButton.Icon:SetTexture("Interface\\AddOns\\PGFinder\\Res\\RedRefresh.tga");
			searchAvailable = false;
			self.totalResults, self.results = C_LFGList.GetFilteredSearchResults();
			local newResults = {};
			for i = 1, #self.results do
				local searchResults = C_LFGList.GetSearchResultInfo(self.results[i]);
				local activityID = searchResults.activityID;
				local activityInfo = C_LFGList.GetActivityInfoTable(activityID);
				local activityFullName = activityInfo.fullName;
				local activityShortName = activityFullName:gsub("%s%(.*", "");
				local isMythicPlusActivity = isMythicPlusActivity;
				local leaderName = searchResults.leaderName;
				local name = searchResults.name;
				local isDelisted = searchResults.isDelisted;
				local age = searchResults.age;
				local leaderOverallDungeonScore = searchResults.leaderOverallDungeonScore;
				local leaderDungeonScoreInfo = searchResults.leaderDungeonScoreInfo;
				local requiredDungeonScore = searchResults.requiredDungeonScore;
				local _, appStatus, pendingStatus, appDuration = C_LFGList.GetApplicationInfo(self.results[i]);
				local encounterInfo = C_LFGList.GetSearchResultEncounterInfo(self.results[i]);
				local bossesDefeated = {};
				if (raidAbbreviations[activityShortName]) then
					if (selectedInfo.bosses[bossNameMap[raidAbbreviations[activityShortName]][bossOrderMap[raidAbbreviations[activityShortName]][1]]]) then
						if (encounterInfo == nil or encounterInfo[1] ~= bossNameMap[raidAbbreviations[activityShortName]][bossOrderMap[raidAbbreviations[activityShortName]][1]]) then
							table.insert(newResults, self.results[i]);
						end
					elseif (selectedInfo.bosses["Fresh Run"] and encounterInfo == nil) then
						table.insert(newResults, self.results[i]);
					elseif (encounterInfo) then
						for index, boss in pairs(encounterInfo) do
							bossesDefeated[bossNameMap[raidAbbreviations[activityShortName]][boss]] = true;
						end
						for bossName, isWanted in pairs(selectedInfo.bosses) do
							if (bossName ~= "Fresh Run" and bossName ~= bossNameMap[raidAbbreviations[activityShortName]][bossOrderMap[raidAbbreviations[activityShortName]][1]]) then -- if its fresh or first boss wont have a parent, just skip
								if (isNextBoss(VOTI_Path, bossName, bossesDefeated) and not bossesDefeated[bossName]) then
									table.insert(newResults, self.results[i]);
									break;
								end
							end
						end
					end
				end
			end
			LFGListUtil_SortSearchResults(newResults);
			self.totalResults = #newResults;
			self.results = newResults;
			self.applications = C_LFGList.GetApplications();
			LFGListSearchPanel_UpdateResults(self);
			updatePerformanceText(self.totalResults, GetTimePreciseSec());
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
				updatePerformanceText(self.totalResults, GetTimePreciseSec());
				return true;
			end
		end
	else
		LFGListFrame.SearchPanel.RefreshButton:SetScript("OnClick", function() end);
		LFGListFrame.SearchPanel.RefreshButton.Icon:SetTexture("Interface\\AddOns\\PGFinder\\Res\\RedRefresh.tga");
		searchAvailable = false;
		self.totalResults, self.results = C_LFGList.GetFilteredSearchResults();
		self.applications = C_LFGList.GetApplications();
		LFGListUtil_SortSearchResults(self.results);
		LFGListSearchPanel_UpdateResults(self);
		updatePerformanceText(self.totalResults, GetTimePreciseSec());
		return true;
	end
end
--[[
	Documenation: A function to fetch all activity names from the activityIDs 1-1400 and stores them in the WTF that can be used to update the addon with new dungeons/raids.
]]
function PGF_DevGenerateAllActivityIDs()
	PGF_DevAllActivityIDs = {
		["dungeons"] = {},
		["raids"] = {},
		["other"] = {},
		["nil"] = {},
	};
	PGF_DevDungeonsActivityIDs = {};
	PGF_DevRaidActivityIDs = {};
	for i = 1, 1400 do
		local activityInfo = C_LFGList.GetActivityInfoTable(i);
		if (activityInfo) then
			local cat = activityInfo.categoryID;
			if (cat and cat == GROUP_FINDER_CATEGORY_ID_DUNGEONS) then
				PGF_DevAllActivityIDs["dungeons"][i] = activityInfo;
				PGF_DevDungeonsActivityIDs[i] = activityInfo.fullName;
			elseif (cat and cat == 3) then
				PGF_DevAllActivityIDs["raids"][i] = activityInfo;
				PGF_DevRaidActivityIDs[i] = activityInfo.fullName;
			else
				PGF_DevAllActivityIDs["other"][i] = activityInfo;
			end
		else
			PGF_DevAllActivityIDs["nil"][i] = "nil";
		end
	end
end
--hooksecurefunc("LFGListSearchPanel_UpdateResultList", PGF_Search);

--[[
	Documentation: This is a blizzard function for selecting a result of the resultsInsets and extends self with the resultID.
	This function overrides it and instead makes the user instantly apply to the group if they are the leader or not in a group.

	self parram(table/object) -- the resultInset
	resultID parram(int) -- the resultID
]]
function LFGListSearchPanel_SelectResult(self, resultID)
	self.selectedResult = resultID;
	LFGListSearchPanel_UpdateResults(self);
	if ((true or PGF_autoSign) and (IsInGroup() == false or UnitIsGroupLeader("player"))) then
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
--[[
	Documentation: This function automatically accepts the role sign up when you are in a party and not the leader by setting your role to the users selected role(s) in the UI. 
	If the user is not in a group or are is the leader this window closes isntantly as ApplyToGroup is used instead to initiate the sign up directly skipping this step.
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

--[[
	Documentation: Overrides Blizzards sort function, sorting by age rather than ID.
	Returns groups in the following order:
	Priority 1: Groups that the user applied to
	Priority 2: Battle.net friends
	Priority 3: Friends
	Priority 4: Guild mates
	Priority 5: Groups that the user/group is eligible to join
	Priority 6: Age of the group (lower is higher)
	Priority 7: Arbitrary ID

	Payload:
	id1 parram(int) - the resultID of the first group
	id2 parram(int) - the resutltID of the second group

	Return:
	bool - true priorities id1 and false priorities id2
]]

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
	if (PGF_SortingVariable == 1) then
		if (result1.age ~= result2.age) then
			return result1.age < result2.age;
		end
	elseif (PGF_SortingVariable == 2) then
		if (result1.leaderOverallDungeonScore == nil) then
			result1.leaderOverallDungeonScore = 0;
		end
		if (result2.leaderOverallDungeonScore == nil) then
			result2.leaderOverallDungeonScore = 0;
		end
		if (result1.leaderOverallDungeonScore ~= result2.leaderOverallDungeonScore) then
			return result1.leaderOverallDungeonScore > result2.leaderOverallDungeonScore;
		end
	end
	if (result1.age ~= result2.age) then
		return result1.age < result2.age;
	end
	return id1 < id2;
end

--[[
	Documentation: If a player does not have 2FA they will not be able to create a group if a playStyleString is returned so check if the player has the authenticatior connected before procceding. 
]]
function PGF_GetPlaystyleString(playstyle, activityInfo)
	local activityID = 1164;
	if (not C_LFGList.IsPlayerAuthenticatedForLFG(activityID)) then
		return;
	end
	if (activityInfo and playstyle and playstyle ~= 0 and C_LFGList.GetLfgCategoryInfo(activityInfo.categoryID).showPlaystyleDropdown) then
		local playStyleString;
		if (activityInfo.isMythicPlusActivity) then
			playStyleString = "GROUP_FINDER_PVE_PLAYSTYLE";
		elseif (activityInfo.isRatedPvpActivity) then
			playStyleString = "GROUP_FINDER_PVP_PLAYSTYLE";
		elseif (activityInfo.isCurrentRaidActivity) then
			playStyleString = "GROUP_FINDER_PVE_RAID_PLAYSTYLE";
		elseif (activityInfo.isMythicActivity) then
			playStyleString = "GROUP_FINDER_PVE_MYTHICZERO_PLAYSTYLE";
		end
		return playStyleString and _G[playStyleString .. tostring(playstyle)];
	else
		return nil;
	end
end
--[[
	Documentation: Override Blizzards function with the new one
]]
C_LFGList.GetPlaystyleString = function(playstyle,activityInfo)
	return PGF_GetPlaystyleString(playstyle, activityInfo);
end

-- Disable automatic group titles to prevent tainting errors
LFGListEntryCreation_SetTitleFromActivityInfo = function(_) end