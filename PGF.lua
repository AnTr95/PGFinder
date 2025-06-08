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
	To add a new raid:
	Update the raidStates
	Add the activityID to the raidStateMap
	Add the abbreviated version of the raid name to the bossNameMap and all of the bosses long and short names
	Add the abbreviated version of the raid name to the bossOrderMap and all long names of the bosses in the prefered order
	Add the boss paths to the PATHs graph (use short names)
	Add the abbreviated name of the raid to the raidAbbreviations
	Add all achievement IDs to the achievementID array using the generic raid name (without difficulty)
	Update isNextBoss function to cover first boss and post multiple wing bosses i.e Broodkeeper
	Add the activityIDs of all difficulties to PGF_allRaidActivityIDs
	Change lastSelectedRaidState to match the new raids "All" AFTER it has been released

	To add a new dungeon:
	Add the abbreviated name of the dungeon to the dungeonAbbreviations
	Add the activityIDs of all difficulties to PGF_allDungeonsActivityIDs

	Documentation: Creating all local variables.
]]

local lastCat = nil;
local playerClass = nil;
local slowSearch = false;
local slowResults = {};
local slowCount = 0;
local slowTotal = 0;
local originalUI = {};
local originalRoleCountUI = {};
local ticks = 0;
local addonIndex = 0;
local debugTicks = 0;
local debugPerformanceReset = 5;
local currentSearchTime = 0;
local prevSearchTime = 0;
local refreshTimeReset = 3; --defines the time that must pass between searches
local searchAvailable = true;
local dungeonStates = {"Normal", "Heroic", "Mythic", "Mythic+ (Keystone)"}; --visible states for the dropdown
local raidStates = {"All", "LOU Normal", "LOU Heroic", "LOU Mythic", "LOU All", "NP Normal", "NP Heroic", "NP Mythic", "NP All",}; --visible states for the dropdown
local sortingStates = {[1] = "Time", [2] = "Score"};
local sortingRaidStates = {[1] = "Time", [2] = "Few of your class", [3] = "Many of your class", [4] = "Few of your tier", [5] = "Many of your tier"};
local lastSelectedDungeonState = "";
local lastSelectedRaidState = "";
local performanceTimeStamp = 0;
local declineResetTimer = 1200;
local declinedGroups = {}; -- IN TESTING ADD LOCAL
local newGroups = {};
local playerRole = nil;
local version = C_AddOns.GetAddOnMetadata(addon, "Version");
local recievedOutOfDateMessage = false;
local FRIEND_ONLINE = ERR_FRIEND_ONLINE_SS:match("%s(.+)") -- Converts "[%s] has come online". to "has come online".
local locale = GetLocale();
local debugMode = false;
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
	["All"] = 0,
	["NP Normal"] = 1505,
	["NP Heroic"] = 1506,
	["NP Mythic"] = 1504,
	["NP All"] = 1506, --no activity ID for this so lets take the boss data from normal
	["LOU Normal"] = 1601,
	["LOU Heroic"] = 1600,
	["LOU Mythic"] = 1602,
	["LOU All"] = 1602, --no activity ID for this so lets take the boss data from normal
};
local tierSetsMap = {
	["DEATHKNIGHT"] = "Dreadful",
    ["DEMONHUNTER"] = "Dreadful",
    ["DRUID"] = "Mystic",
    ["EVOKER"] = "Zenith",
    ["HUNTER"] = "Mystic",
    ["MAGE"] = "Mystic",
    ["MONK"] = "Zenith",
    ["PALADIN"] = "Venerated",
    ["PRIEST"] = "Venerated",
    ["ROGUE"] = "Zenith",
    ["SHAMAN"] = "Venerated",
    ["WARLOCK"] = "Dreadful",
    ["WARRIOR"] = "Zenith"
};
--local bestLevelPerDungeonMap = {};
--local challengeIDMap = {};
--[[
	Documentation: This sets the order of that the bosses will show in the UI
]]
local bossOrderMap = {
	["NP"] = {
		"Ulgrax the Devourer",
		"The Bloodbound Horror",
		"Sikran, Captain of Sureki",
		"Rasha'nan",
		"Broodtwister Ovi'nax",
		"Nexus-Princess Ky'veza",
		"The Silken Court",
		"Queen Ansurek",
		"Fresh",
	},
	["LOU"] = {
		"Vexie and the Geargrinders",
		"Cauldron of Carnage",
		"Rik Reverb",
		"Stix Bunkjunker",
		"Sprocketmonger Lockenstock",
		"One-Armed Bandit",
		"Mug'Zee, Heads of Security",
		"Chrome King Gallywix",
		"Fresh",
	},
};
--[[
	Documentation: This converts the names used in the GUIs for the user to see with the actual names in the code.
]]
local bossNameMap = {
	["NP"] = {
		["Ulgrax the Devourer"] = "Ulgrax",
		["The Bloodbound Horror"] = "Bloodbound",
		["Sikran, Captain of Sureki"] = "Sikran",
		["Rasha'nan"] = "Rasha'nan",
		["Broodtwister Ovi'nax"] = "Broodtwister",
		["Nexus-Princess Ky'veza"] = "Ky'veza",
		["The Silken Court"] = "Silken Court",
		["Queen Ansurek"] = "Ansurek",
		["Fresh"] = "Fresh Run",
	},
	["LOU"] = {
		["Vexie and the Geargrinders"] = "Vexie",
		["Cauldron of Carnage"] = "Cauldron of Carnage",
		["Rik Reverb"] = "Rik Reverb",
		["Stix Bunkjunker"] = "Stix Bunkjunker",
		["Sprocketmonger Lockenstock"] = "Sprocketmonger Lockenstock",
		["One-Armed Bandit"] = "One-Armed Bandit",
		["Mug'Zee, Heads of Security"] = "Mug'Zee",
		["Chrome King Gallywix"] = "Gallywix",
		["Fresh"] = "Fresh run",
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
	["Uldaman: Legacy of Tyr"] = "UL",
	["Neltharus"] = "NELT",
	["Neltharion's Lair"] = "NL",
	["Freehold"] = "FH",
	["The Underrot"] = "UNDR",
	["The Vortex Pinnacle"] = "VP",
	["Dawn of the Infinite"] = "DI",
	["Dawn of the Infinite: Galakrond's Fall"] = "FALL",
	["Dawn of the Infinite: Murozond's Rise"] = "RISE",
	["Black Rook Hold"] = "BRH",
	["Darkheart Thicket"] = "DHT",
	["Throne of the Tides"] = "TOTT",
	["Atal'Dazar"] = "AD",
	["Waycrest Manor"] = "WM",
	["The Everbloom"] = "EB",
	["Siege of Boralus"] = "SIEGE",
	["Grim Batol"] = "GB",
	["The Necrotic Wake"] = "NW",
	["Mists of Tirna Scithe"] = "MISTS",
	["The Stonevault"] = "SV",
	["The Dawnbreaker"] = "DAWN",
	["City of Threads"] = "COT",
	["Ara-Kara, City of Echoes"] = "ARAK",
	["The Rookery"] = "ROOK",
	["Cinderbrew Meadery"] = "BREW",
	["Darkflame Cleft"] = "DFC",
	["Priory of the Sacred Flame"] = "PSF",
	["Operation: Floodgate"] = "FLOOD",
	["The MOTHERLODE!!"] = "ML",
	["THE MOTHERLODE"] = "ML",
	["Theater of Pain"] = "TOP",
	["Operation: Mechagon"] = "MECHA",
	["Mechagon Workshop"] = "WORK",
};

local raidAbbreviations = {
	["Liberation of Undermine"] = "LOU",
	["Nerub-ar Palace"] = "NP",
};
--[[
	Documentation: This is DAG that defines which bosses are after and which are before the selected boss and is used for figuring out what boss is next based on the raid lockout
]]
local boss_Paths = {
	["NP"] = {
		["Ulgrax"] = {
			["children_paths"] = {
				{"Bloodbound Horror", "Sikran", "Rasha'nan", "Broodtwister", "Ky'veza", "Silken Court", "Ansurek"},
				{"Bloodbound Horror", "Sikran", "Rasha'nan", "Ky'veza", "Broodtwister", "Silken Court", "Ansurek"},
				{"Silken Court", "Ansurek"},
			},
			["parent_paths"] = {},
		},
		["Bloodbound Horror"] = {
			["children_paths"] = {
				{"Sikran", "Rasha'nan", "Broodtwister", "Ky'veza", "Silken Court", "Ansurek"},
				{"Sikran", "Rasha'nan", "Ky'veza", "Broodtwister", "Silken Court", "Ansurek"},
			},
			["parent_paths"] = {
				{"Ulgrax"},
			},
		},
		["Sikran"] = {
			["children_paths"] = {
				{"Rasha'nan", "Broodtwister", "Ky'veza", "Silken Court", "Ansurek"},
				{"Rasha'nan", "Ky'veza", "Broodtwister", "Silken Court", "Ansurek"},
			},
			["parent_paths"] = {
				{"Bloodbound Horror", "Ulgrax"},
			},
		},
		["Rasha'nan"] = {
			["children_paths"] = {
				{"Broodtwister", "Ky'veza", "Silken Court", "Ansurek"},
				{"Ky'veza", "Broodtwister", "Silken Court", "Ansurek"},
			},
			["parent_paths"] = {
				{"Sikran", "Bloodbound Horror", "Ulgrax"},
			},
		},
		["Broodtwister"] = {
			["children_paths"] = {
				{"Ky'veza", "Silken Court", "Ansurek"},
				{"Silken Court", "Ansurek"},
			},
			["parent_paths"] = {
				{"Rasha'nan", "Sikran", "Bloodbound Horror", "Ulgrax"},
				{"Ky'veza", "Rasha'nan", "Sikran", "Bloodbound Horror", "Ulgrax"},
			},
		},
		["Ky'veza"] = {
			["children_paths"] = {
				{"Broodtwister", "Silken Court", "Ansurek"},
				{"Silken Court", "Ansurek"},
			},
			["parent_paths"] = {
				{"Rasha'nan", "Sikran", "Bloodbound Horror", "Ulgrax"},
				{"Broodtwister", "Rasha'nan", "Sikran", "Bloodbound Horror", "Ulgrax"},
			},
		},
		["Silken Court"] = {
			["children_paths"] = {
				{"Ansurek",}
			},
			["parent_paths"] = {
				{"Broodtwister", "Ky'veza", "Rasha'nan", "Sikran", "Bloodbound Horror", "Ulgrax"},
				{"Ky'veza", "Broodtwister", "Rasha'nan", "Sikran", "Bloodbound Horror", "Ulgrax"},
				{"Ulgrax"},
			},
		},
		["Ansurek"] = {
			["children_paths"] = {},
			["parent_paths"] = {
				{"Ulgrax", "Silken Court"},
				{"Silken Court", "Broodtwister", "Ky'veza", "Rasha'nan", "Sikran", "Bloodbound Horror", "Ulgrax"},
				{"Silken Court", "Ky'veza", "Broodtwister", "Rasha'nan", "Sikran", "Bloodbound Horror", "Ulgrax"},
			}
		},
	},
	["LOU"] = {
		["Vexie"] = {
			["children_paths"] = {
				{"Cauldron of Carnage", "Rik Reverb", "Stix Bunkjunker", "Sprocketmonger Lockenstock", "One-Armed Bandit", "Mug'Zee", "Gallywix"}
			},
			["parent_paths"] = {},
		},
		["Cauldron of Carnage"] = {
			["children_paths"] = {
				{"Rik Reverb", "Stix Bunkjunker", "Sprocketmonger Lockenstock", "One-Armed Bandit", "Mug'Zee", "Gallywix"}
			},
			["parent_paths"] = {
				{"Vexie"},
				{"Rik Reverb", "Vexie"},
				{"Stix Bunkjunker", "Vexie"},
				{"Stix Bunkjunker", "Rik Reverb", "Vexie"},
			},
		},
		["Rik Reverb"] = {
			["children_paths"] = {
				{"Stix Bunkjunker", "Sprocketmonger Lockenstock", "One-Armed Bandit", "Mug'Zee", "Gallywix"}
			},
			["parent_paths"] = {
				{"Vexie"},
				{"Cauldron of Carnage", "Vexie"},
				{"Stix Bunkjunker", "Vexie"},
				{"Stix Bunkjunker", "Cauldron of Carnage", "Vexie"},
			},
		},
		["Stix Bunkjunker"] = {
			["children_paths"] = {
				{"Sprocketmonger Lockenstock", "One-Armed Bandit", "Mug'Zee", "Gallywix"}
			},
			["parent_paths"] = {
				{"Vexie"},
				{"Cauldron of Carnage", "Vexie"},
				{"Rik Reverb", "Vexie"},
				{"Rik Reverb", "Cauldron of Carnage", "Vexie"},
			},
		},
		["Sprocketmonger Lockenstock"] = {
			["children_paths"] = {
				{"One-Armed Bandit", "Mug'Zee", "Gallywix"}
			},
			["parent_paths"] = {
				{"Stix Bunkjunker", "Rik Reverb", "Cauldron of Carnage", "Vexie"},
			},
		},
		["One-Armed Bandit"] = {
			["children_paths"] = {
				{"Mug'Zee", "Gallywix"}
			},
			["parent_paths"] = {
				{"Sprocketmonger Lockenstock", "Stix Bunkjunker", "Rik Reverb", "Cauldron of Carnage", "Vexie"},
			},
		},
		["Mug'Zee"] = {
			["children_paths"] = {
				{"Gallywix"}
			},
			["parent_paths"] = {
				{"One-Armed Bandit", "Sprocketmonger Lockenstock", "Stix Bunkjunker", "Rik Reverb", "Cauldron of Carnage", "Vexie"},
				{"Vexie"},
			},
		},
		["Gallywix"] = {
			["children_paths"] = {},
			["parent_paths"] = {
				{"Mug'Zee", "One-Armed Bandit", "Sprocketmonger Lockenstock", "Stix Bunkjunker", "Rik Reverb", "Cauldron of Carnage", "Vexie"},
				{"Vexie", "Mug'Zee"}
			}
		},
	},
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
        ["Augmentation"] = 1473,
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
	["showMyClass"] = false,
};

--[[
	Documentation: All of the achievementIDs for CE, Mythic Boss, AOTC, Normal Clear. Order decides which one is best, lower key = better
]]
local achievementIDs = {
	["Liberation of Undermine"] = {41297, 41235, 41234, 41233, 41232, 41231, 41230, 41229, 41298, 41222},
	["Nerub-ar Palace"] = {40254, 40242, 40241, 40240, 40239, 40238, 40237, 40236, 40253, 40244},
};

--[[
	Documentation: All of the red, green, blue values for the leader score. The score must be equal or above the key to use the r, g, b value
]]
local scoreColors = {
	[3650] = {1.00, 0.50, 0.00},
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
do
	for i = 0, 3650 do
		if (scoreColors[i]) then
			colorLookup[i] = scoreColors[i];
			lastScore = i;
		else
			colorLookup[i] = scoreColors[lastScore];
		end
	end
end

--[[
	Documentation: Slash command handler
]]
local function handler(msg, editbox)
	local arg = string.lower(msg);
	if (arg == "debug") then
		if (not debugMode) then
			debugMode = true;
			for i = 1, GetNumAddOns() do
				local name = GetAddOnInfo(i);
				if (name == "PGFinder") then
					addonIndex = i;
				end
			end
		else
			debugMode = false;
		end
	end
end
SlashCmdList["PREMADEGROUPFINDER"] = handler;

function PGF_GetTexCoordsForRole(role)
	local textureHeight, textureWidth = 256, 256;
	local roleHeight, roleWidth = 67, 67;
	if ( role == "GUIDE" ) then
		return GetTexCoordsByGrid(1, 1, textureWidth, textureHeight, roleWidth, roleHeight);
	elseif ( role == "TANK" ) then
		return GetTexCoordsByGrid(1, 2, textureWidth, textureHeight, roleWidth, roleHeight);
	elseif ( role == "HEALER" ) then
		return GetTexCoordsByGrid(2, 1, textureWidth, textureHeight, roleWidth, roleHeight);
	elseif ( role == "DAMAGER" ) then
		return GetTexCoordsByGrid(2, 2, textureWidth, textureHeight, roleWidth, roleHeight);
	else
		error("Unknown role: "..tostring(role));
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
	for i, achievementId in ipairs(achievementIDs[raid]) do
		if (select(4, GetAchievementInfo(achievementId))) then
			return GetAchievementLink(achievementId);
		end
	end
	return nil;
end

--[[
	Documentation: A blizzard value used in LFGListUtil_GetSearchEntryMenu that is called when right clicking on a group in premade groups.
	This version overwrites it and adds a new button in position 5 in the dropdown.
	text (string) that is shown in the dropdown
	func - onClick function that takes custom params and are passed form the LFGListUtil_GetSearchEntryMenu function
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
			LFGList_ReportListing(id, name);
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

local function isAnyValueTrue(array)
	for k, v in pairs(array) do
		if (v == true) then
			return true;
		end
	end
	return false;
end
--[[
	Documentation: A function to figure out if the boss param is the next boss based on the raid lockout and graph for that raid
	CASE post all wings boss: If it is a boss that unlocks after 2 or more wings or there is a skip to the boss we need to check for all 3 scenarios. In the case it is a skip only check if first boss is defeated and not the 2nd boss as they are probably not skipping then
	CASE any other case: check if the boss just before the current boss is defeated

	Payload:
	graph param(table/graph) - a graph that contains all of the bosses and the orders they can be reached
	boss param(string) - the boss we are checking if it is next
	bosses param(table) - a table with all of the bosses that are defeated key is bossName, value is true and if it is not defeated the key will be nill for that boss

	Returns:
	bool - true if it is the next boss
	bool - false if it is not
]]
local function isNextBoss(graph, boss, bosses)
	if (boss and graph) then
		if (boss == "Silken Court" or boss == "Mug'Zee") then -- or boss XX
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
dungeonOptionsFrame:SetSize(242,150);


--[[
	Documentation: Create the raidFrame shown only in category 3
]]
local raidFrame = CreateFrame("Frame", nil, f);
raidFrame:SetPoint("TOPLEFT", 0, 0);
raidFrame:SetSize(f:GetWidth(), f:GetHeight());
raidFrame:Hide();

local raidOptionsFrame = CreateFrame("Frame", nil, raidFrame, BackdropTemplateMixin and "BackdropTemplate");
raidOptionsFrame:SetSize(242,140);

--C_LFGList.GetSearchResultMemberInfo(resultID, playerIndex); returns: [1] = role, [2] = classUNIVERSAL, [3] = classLocal, [4] = spec

f:RegisterEvent("PLAYER_LOGIN");
f:RegisterEvent("PLAYER_ENTERING_WORLD");
f:RegisterEvent("CHAT_MSG_ADDON");
f:RegisterEvent("GROUP_ROSTER_UPDATE");
f:RegisterEvent("CHAT_MSG_SYSTEM");
f:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED");
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
		["LFGListFrame.SearchPanel.ResultsInset"] = {["position"] = {}, ["size"] = {}, ["position2"] = {}},
		["LFGListFrame.SearchPanel.RefreshButton"] = {["position"] = {}},
		["LFGListFrame.SearchPanel.CategoryName"] = {["position"] = {}},
		["LFGListFrame.SearchPanel.SignUpButton"] = {["position"] = {}},
		["LFGListFrame.SearchPanel.BackButton"] = {["position"] = {}},
		["LFGListFrame.SearchPanel.BackToGroupButton"] = {["position"] = {}},
		["LFGListFrame.SearchPanel.ScrollBox"] = {["size"] = {}},
		["LFGListApplicationDialog.Description"] = {["position"] = {}, ["size"] = {}},
		["LFGListApplicationDialog.Description.EditBox"] = {["size"] = {}},
	};
	originalUI["PVEFrame"].width = PVEFrame:GetWidth();
	originalUI["PVEFrame"].height = PVEFrame:GetHeight();
	originalUI["LFGListFrame"].position[1], originalUI["LFGListFrame"].position[2], originalUI["LFGListFrame"].position[3], originalUI["LFGListFrame"].position[4], originalUI["LFGListFrame"].position[5] = LFGListFrame:GetPoint(1);
	originalUI["LFGListFrame"].position2[1], originalUI["LFGListFrame"].position2[2], originalUI["LFGListFrame"].position2[3], originalUI["LFGListFrame"].position2[4], originalUI["LFGListFrame"].position2[5] = LFGListFrame:GetPoint(2);
	originalUI["LFGListFrame.SearchPanel.SearchBox"].size = LFGListFrame.SearchPanel.SearchBox:GetSize();
	originalUI["LFGListFrame.SearchPanel.SearchBox"].position[1], originalUI["LFGListFrame.SearchPanel.SearchBox"].position[2], originalUI["LFGListFrame.SearchPanel.SearchBox"].position[3], originalUI["LFGListFrame.SearchPanel.SearchBox"].position[4], originalUI["LFGListFrame.SearchPanel.SearchBox"].position[5] = LFGListFrame.SearchPanel.SearchBox:GetPoint();
	originalUI["LFGListFrame.SearchPanel.FilterButton"].size = LFGListFrame.SearchPanel.FilterButton:GetSize();
	originalUI["LFGListFrame.SearchPanel.FilterButton"].position[1], originalUI["LFGListFrame.SearchPanel.FilterButton"].position[2], originalUI["LFGListFrame.SearchPanel.FilterButton"].position[3], originalUI["LFGListFrame.SearchPanel.FilterButton"].position[4], originalUI["LFGListFrame.SearchPanel.FilterButton"].position[5] = LFGListFrame.SearchPanel.FilterButton:GetPoint();
	originalUI["LFGListFrame.SearchPanel.ResultsInset"].size[1], originalUI["LFGListFrame.SearchPanel.ResultsInset"].size[2] = LFGListFrame.SearchPanel.ResultsInset:GetSize();
	originalUI["LFGListFrame.SearchPanel.ResultsInset"].position[1], originalUI["LFGListFrame.SearchPanel.ResultsInset"].position[2], originalUI["LFGListFrame.SearchPanel.ResultsInset"].position[3], originalUI["LFGListFrame.SearchPanel.ResultsInset"].position[4], originalUI["LFGListFrame.SearchPanel.ResultsInset"].position[5] = LFGListFrame.SearchPanel.ResultsInset:GetPoint();
	originalUI["LFGListFrame.SearchPanel.ResultsInset"].position2[1], originalUI["LFGListFrame.SearchPanel.ResultsInset"].position2[2], originalUI["LFGListFrame.SearchPanel.ResultsInset"].position2[3], originalUI["LFGListFrame.SearchPanel.ResultsInset"].position2[4], originalUI["LFGListFrame.SearchPanel.ResultsInset"].position2[5] = LFGListFrame.SearchPanel.ResultsInset:GetPoint(2);
	originalUI["LFGListFrame.SearchPanel.SignUpButton"].position[1], originalUI["LFGListFrame.SearchPanel.SignUpButton"].position[2], originalUI["LFGListFrame.SearchPanel.SignUpButton"].position[3], originalUI["LFGListFrame.SearchPanel.SignUpButton"].position[4], originalUI["LFGListFrame.SearchPanel.SignUpButton"].position[5] = LFGListFrame.SearchPanel.SignUpButton:GetPoint();
	originalUI["LFGListFrame.SearchPanel.BackButton"].position[1], originalUI["LFGListFrame.SearchPanel.BackButton"].position[2], originalUI["LFGListFrame.SearchPanel.BackButton"].position[3], originalUI["LFGListFrame.SearchPanel.BackButton"].position[4], originalUI["LFGListFrame.SearchPanel.BackButton"].position[5] = LFGListFrame.SearchPanel.BackButton:GetPoint();
	originalUI["LFGListFrame.SearchPanel.BackToGroupButton"].position[1], originalUI["LFGListFrame.SearchPanel.BackToGroupButton"].position[2], originalUI["LFGListFrame.SearchPanel.BackToGroupButton"].position[3], originalUI["LFGListFrame.SearchPanel.BackToGroupButton"].position[4], originalUI["LFGListFrame.SearchPanel.BackToGroupButton"].position[5] = LFGListFrame.SearchPanel.BackToGroupButton:GetPoint();
	originalUI["LFGListFrame.SearchPanel.ScrollBox"].size[1], originalUI["LFGListFrame.SearchPanel.ScrollBox"].size[2] = LFGListFrame.SearchPanel.ScrollBox:GetSize();
	originalUI["LFGListFrame.SearchPanel.RefreshButton"].size = LFGListFrame.SearchPanel.RefreshButton:GetSize();
	originalUI["LFGListFrame.SearchPanel.RefreshButton"].position[1], originalUI["LFGListFrame.SearchPanel.RefreshButton"].position[2], originalUI["LFGListFrame.SearchPanel.RefreshButton"].position[3], originalUI["LFGListFrame.SearchPanel.RefreshButton"].position[4], originalUI["LFGListFrame.SearchPanel.RefreshButton"].position[5] = LFGListFrame.SearchPanel.RefreshButton:GetPoint();
	originalUI["LFGListFrame.SearchPanel.CategoryName"].position[1], originalUI["LFGListFrame.SearchPanel.CategoryName"].position[2], originalUI["LFGListFrame.SearchPanel.CategoryName"].position[3], originalUI["LFGListFrame.SearchPanel.CategoryName"].position[4], originalUI["LFGListFrame.SearchPanel.CategoryName"].position[5] = LFGListFrame.SearchPanel.CategoryName:GetPoint();
	originalUI["LFGListApplicationDialog.Description"].parent = LFGListApplicationDialog.Description:GetParent();
	originalUI["LFGListApplicationDialog.Description"].position[1], originalUI["LFGListApplicationDialog.Description"].position[2], originalUI["LFGListApplicationDialog.Description"].position[3], originalUI["LFGListApplicationDialog.Description"].position[4], originalUI["LFGListApplicationDialog.Description"].position[5] = LFGListApplicationDialog.Description:GetPoint();
	originalUI["LFGListApplicationDialog.Description"].size[1], originalUI["LFGListApplicationDialog.Description"].size[2] = LFGListApplicationDialog.Description:GetSize();
	originalUI["LFGListApplicationDialog.Description.EditBox"].size[1], originalUI["LFGListApplicationDialog.Description.EditBox"].size[2] = LFGListApplicationDialog.Description.EditBox:GetSize();
end

local function updateRaidFrameWidth()
	local x = 338;
	local x2 = 800;
	if (PGF_ShowYourClassAmount) then
		x = x + 50;
		x2 = x2 + 50;
	end
	if (PGF_ShowYourTierAmount) then
		x = x + 50;
		x2 = x2 + 50;
	end
	PVEFrame:SetSize(x2,428);
	PVE_FRAME_BASE_WIDTH = x2; -- blizz is always trying to resize the pveframe based on this value
	LFGListFrame:ClearAllPoints();
	LFGListFrame:SetPoint(originalUI["LFGListFrame"].position[1], originalUI["LFGListFrame"].position[2], originalUI["LFGListFrame"].position[3], originalUI["LFGListFrame"].position[4], originalUI["LFGListFrame"].position[5]);
	LFGListFrame:SetSize(x, LFGListFrame:GetHeight());
	LFGListSearchPanel_UpdateResults(LFGListFrame.SearchPanel);
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
	LFGListFrame.SearchPanel.ResultsInset:ClearAllPoints();
	LFGListFrame.SearchPanel.ResultsInset:SetPoint(originalUI["LFGListFrame.SearchPanel.ResultsInset"].position[1], originalUI["LFGListFrame.SearchPanel.ResultsInset"].position[2], originalUI["LFGListFrame.SearchPanel.ResultsInset"].position[3], originalUI["LFGListFrame.SearchPanel.ResultsInset"].position[4], originalUI["LFGListFrame.SearchPanel.ResultsInset"].position[5]);
	LFGListFrame.SearchPanel.ResultsInset:SetPoint(originalUI["LFGListFrame.SearchPanel.ResultsInset"].position2[1], originalUI["LFGListFrame.SearchPanel.ResultsInset"].position2[2], originalUI["LFGListFrame.SearchPanel.ResultsInset"].position2[3], originalUI["LFGListFrame.SearchPanel.ResultsInset"].position2[4], originalUI["LFGListFrame.SearchPanel.ResultsInset"].position2[5]);
	LFGListFrame.SearchPanel.ResultsInset:SetSize(originalUI["LFGListFrame.SearchPanel.ResultsInset"].size[1], originalUI["LFGListFrame.SearchPanel.ResultsInset"].size[2]);
	LFGListFrame.SearchPanel.SignUpButton:ClearAllPoints();
	LFGListFrame.SearchPanel.SignUpButton:SetPoint(originalUI["LFGListFrame.SearchPanel.SignUpButton"].position[1], originalUI["LFGListFrame.SearchPanel.SignUpButton"].position[2], originalUI["LFGListFrame.SearchPanel.SignUpButton"].position[3], originalUI["LFGListFrame.SearchPanel.SignUpButton"].position[4], originalUI["LFGListFrame.SearchPanel.SignUpButton"].position[5]);
	LFGListFrame.SearchPanel.BackButton:ClearAllPoints();
	LFGListFrame.SearchPanel.BackButton:SetPoint(originalUI["LFGListFrame.SearchPanel.BackButton"].position[1], originalUI["LFGListFrame.SearchPanel.BackButton"].position[2], originalUI["LFGListFrame.SearchPanel.BackButton"].position[3], originalUI["LFGListFrame.SearchPanel.BackButton"].position[4], originalUI["LFGListFrame.SearchPanel.BackButton"].position[5]);
	LFGListFrame.SearchPanel.BackToGroupButton:ClearAllPoints();
	LFGListFrame.SearchPanel.BackToGroupButton:SetPoint(originalUI["LFGListFrame.SearchPanel.BackToGroupButton"].position[1], originalUI["LFGListFrame.SearchPanel.BackToGroupButton"].position[2], originalUI["LFGListFrame.SearchPanel.BackToGroupButton"].position[3], originalUI["LFGListFrame.SearchPanel.BackToGroupButton"].position[4], originalUI["LFGListFrame.SearchPanel.BackToGroupButton"].position[5]);
	LFGListFrame.SearchPanel.ScrollBox:SetSize(originalUI["LFGListFrame.SearchPanel.ScrollBox"].size[1], originalUI["LFGListFrame.SearchPanel.ScrollBox"].size[2]);
	LFGListApplicationDialog.Description:SetPoint(originalUI["LFGListApplicationDialog.Description"].position[1], originalUI["LFGListApplicationDialog.Description"].position[2], originalUI["LFGListApplicationDialog.Description"].position[3], originalUI["LFGListApplicationDialog.Description"].position[4], originalUI["LFGListApplicationDialog.Description"].position[5]);
	LFGListApplicationDialog.Description:SetSize(originalUI["LFGListApplicationDialog.Description"].size[1], originalUI["LFGListApplicationDialog.Description"].size[2]);
	LFGListApplicationDialog.Description.EditBox:SetSize(originalUI["LFGListApplicationDialog.Description.EditBox"].size[1], originalUI["LFGListApplicationDialog.Description.EditBox"].size[2]);
	LFGListFrame:ClearAllPoints();
	LFGListFrame:SetPoint(originalUI["LFGListFrame"].position[1], originalUI["LFGListFrame"].position[2], originalUI["LFGListFrame"].position[3], originalUI["LFGListFrame"].position[4], originalUI["LFGListFrame"].position[5]);
	LFGListFrame:SetSize(338, LFGListFrame:GetHeight());
	if (LFGListFrame.SearchPanel:IsShown()) then
		LFGListFrame.SearchPanel.BackButton:SetShown(not C_LFGList.HasActiveEntryInfo());
		LFGListFrame.SearchPanel.BackToGroupButton:SetShown(C_LFGList.HasActiveEntryInfo());
		LFGListFrame.SearchPanel.SignUpButton:SetShown(true);
	end
end


--[[
	Documentation: A blizzard function used to perform C_LFGList.Search and C_LFGList.GetAvailableActivities
	The function takes the categoryID and if a filter should be applied or not which depends on the category. For raids 0 is for all raids including legacy while 1 is only current raids. For dungeons

	Payload:
	categoryID param int - the categoryID of LFGListFrame.SearchPanel.categoryID or the categoryID of the activity
	filters param ?int - if a filter for recommended groups should be applied or not

	Returns:
	filters ?integer
]]
local function ResolveCategoryFilters(categoryID, filters)
	-- Dungeons ONLY display recommended groups.
	if categoryID == GROUP_FINDER_CATEGORY_ID_DUNGEONS then
		return bit.band(bit.bnot(Enum.LFGListFilter.NotRecommended), bit.bor(filters, Enum.LFGListFilter.Recommended));
	end

	return filters;
end

local function isNewGroup(leaderName, activityID, previousSearchTime)
	if (leaderName == nil or activityID == nil or leaderName == nil) then
		return true;
	end
	if (newGroups[leaderName] and newGroups[leaderName].ActivityID == activityID and previousSearchTime ~= newGroups[leaderName].PrevSearchTime) then
		return false;
	elseif (newGroups[leaderName] == nil or newGroups[leaderName].ActivityID ~= activityID) then
		newGroups[leaderName] = {["ActivityID"] = activityID, ["PrevSearchTime"] = previousSearchTime};
	end
	return true;
end

--[[
	Documentation: This function returns the amount of players in a raid that is using the same tier set as the defined unit, defaults to player if nil. Since displayData contains all sorts of information we have to make sure it is a class first.
	The we can add the value as the key holds the amount of that class which should reduce the time complexity for larger groups.

	Payload:
	tier param(int) - which tier set name to count
	displayData param(int) - contains information about how many of each class are in the group but also how many remaining roles are available and such

	Returns:
	count (int) - amount of players using the tier set named
]]
local function getTierCount(class, displayData)
	class = class or select(1, UnitClassBase("player"));
	local tier = tierSetsMap[class];
	local tierCount = 0;
	local classCount = 0;
	local tierText = tier .. " Tier: ";
	for k, v in pairs(displayData) do
		if (tierSetsMap[k] and tierSetsMap[k] == tier) then
			tierCount = tierCount + v;
			if (k == class) then
				classCount = v;
			end
		end
	end
	return tierCount, classCount, tierText;
end

local function getTierCountBySearchResult(class, searchResult, resultID)
	class = class or select(1, UnitClassBase("player"));
	local tier = tierSetsMap[class];
	local tierCount = 0;
	if (searchResult == nil) then
		searchResult = C_LFGList.GetSearchResultInfo(resultID);
	end
	for i = 1, searchResult.numMembers do
		local role, classUniversal, classLocal, spec = C_LFGList.GetSearchResultMemberInfo(resultID, i);
		if (tierSetsMap[classUniversal] == tier) then
			tierCount = tierCount + 1;
		end
	end
	return tierCount;
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
			C_LFGList.Search(LFGListFrame.SearchPanel.categoryID, ResolveCategoryFilters(LFGListFrame.SearchPanel.categoryID, LFGListFrame.SearchPanel.filters), LFGListFrame.SearchPanel.preferredFilters, C_LFGList.GetLanguageSearchFilter(), nil, C_LFGList.GetAdvancedFilter());
		else
			slowTotal = dungeonsSelected;
			for k, v in ipairs(selectedInfo.dungeons) do
				C_Timer.After(3*count, function()
					C_LFGList.SetSearchToActivity(k);
					C_LFGList.Search(LFGListFrame.SearchPanel.categoryID, ResolveCategoryFilters(LFGListFrame.SearchPanel.categoryID, LFGListFrame.SearchPanel.filters), LFGListFrame.SearchPanel.preferredFilters, C_LFGList.GetLanguageSearchFilter(), nil, C_LFGList.GetAdvancedFilter());
				end);
				count = count + 1;
			end
		end
	else
		LFGListSearchPanel_UpdateResults(LFGListFrame.SearchPanel);
	end
end

--[[
	Documentation: This is a Blizzard function used when sorting groups to determine if the player is eligible for each listed group.
	This version extends it to also work for groups (multiple players) to see if the group as a whole is eliglbe for each listed group.

	Payload:
	lfgSearchResultID param(int) - the resultID from GetSearchResult or self

	Returns:
	bool - that is true if the group/player is eligible and otherwise false
]]
local function HasRemainingSlotsForLocalPlayerRole(lfgSearchResultID, isFiltering)
	local roles = C_LFGList.GetSearchResultMemberCounts(lfgSearchResultID);
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
		if (isAnyValueTrue(PGF_OnlyShowMyRole2)) then
			for role, bool in pairs(PGF_OnlyShowMyRole2) do
				if (bool) then
					if (role == "DAMAGER") then
						if (roles[roleRemainingKeyLookup[role]] >= 3) then
							return false;
						end
					else
						if (roles[roleRemainingKeyLookup[role]] > 0) then
							return false;
						end
					end
				end
			end
		end
		if (PGF_FilterRemainingRoles or not isFiltering) then
			return roles[roleRemainingKeyLookup[playerRole]] > 0;
		end
		return true;
	end
end

--[[
	Documentation: This script will keep track of enough time has passed between the searches to allow for searches again and reset the refresh button texture.
	While it is disabled the OnClick function is also removed but is readded here when searching is available again.

	Payload:
	self param(table/object) - PVEFrame
	elapsed param(int) - How much time has passed since last call
]]
PVEFrame:HookScript("OnUpdate", function(self, elapsed)
	ticks = ticks + elapsed;
	if (debugMode) then
		debugTicks = debugTicks + elapsed;
		if (debugTicks >= debugPerformanceReset) then
			UpdateAddOnMemoryUsage();
			print("PGF: " .. math.floor(C_AddOns.GetAddOnMemoryUsage(addonIndex)) .. "kb in use");
			debugTicks = 0;
		end
	end
	if (ticks >= refreshTimeReset and not searchAvailable) then
		LFGListFrame.SearchPanel.RefreshButton:SetScript("OnClick", refreshButtonClick);
		LFGListFrame.SearchPanel.RefreshButton.Icon:SetTexture(851904);
		searchAvailable = true;
		LFGListFrame.SearchPanel.RefreshButton:HookScript("OnClick", function()
			LFGListFrame.SearchPanel.RefreshButton:SetScript("OnClick", function() end);
			LFGListFrame.SearchPanel.RefreshButton.Icon:SetTexture("Interface\\AddOns\\PGFinder\\Res\\RedRefresh.tga");
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
		currentSearchTime = 0;
		prevSearchTime = 0;
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
				checkbox:SetChecked(PGF_FilterRemainingRoles);
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
local function updateRaidDifficulty(isSameCat, isSameActivity)
	--Hide all
	if (not isSameCat or not isSameActivity) then
		prevSearchTime = 0;
		currentSearchTime = 0;
		dungeonFrame:Hide();
		if (not isSameCat) then
			LFGListSearchPanel_Clear(LFGListFrame.SearchPanel);
		end
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
						lastSelectedRaidState = raidStates[1];
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
		if (raidStateMap[lastSelectedRaidState] ~= 0 and currentRaidsActivityIDs[raidStateMap[lastSelectedRaidState]]) then
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
	PVEFrame:SetSize(840,428);
	PVE_FRAME_BASE_WIDTH = 840; -- blizz is always trying to resize the pveframe based on this value
	LFGListFrame.SearchPanel.SearchBox:ClearAllPoints();
	LFGListFrame.SearchPanel.RefreshButton:ClearAllPoints();
	LFGListFrame.SearchPanel.FilterButton:ClearAllPoints();
	LFGListFrame.SearchPanel.CategoryName:ClearAllPoints();
	LFGListFrame.SearchPanel.SearchBox:SetPoint("TOPLEFT", dungeonFrame, "TOPLEFT", 28, -10);
	LFGListFrame.SearchPanel.SearchBox:SetPoint("RIGHT", PVEFrame.NineSlice, "RIGHT", -15, 0);
	LFGListFrame.SearchPanel.RefreshButton:SetPoint("TOPLEFT", LFGListFrame.SearchPanel.SearchBox, "TOPLEFT", -50, 7);
	LFGListFrame.SearchPanel.FilterButton:SetPoint("BOTTOMRIGHT", PVEFrame, "BOTTOMRIGHT", -20, 45);
	LFGListFrame.SearchPanel.FilterButton:SetSize(80, LFGListFrame.SearchPanel.FilterButton:GetHeight());
	LFGListFrame.SearchPanel.SearchBox:SetSize(235, LFGListFrame.SearchPanel.SearchBox:GetHeight());
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
	PVEFrame:SetSize(900,428);
	PVE_FRAME_BASE_WIDTH = 900; -- blizz is always trying to resize the pveframe based on this value
	LFGListFrame.SearchPanel.SearchBox:ClearAllPoints();
	LFGListFrame.SearchPanel.RefreshButton:ClearAllPoints();
	LFGListFrame.SearchPanel.FilterButton:ClearAllPoints();
	LFGListFrame.SearchPanel.CategoryName:ClearAllPoints();
	LFGListFrame.SearchPanel.SearchBox:SetPoint("TOPLEFT", raidFrame, "TOPLEFT", 28, -10);
	LFGListFrame.SearchPanel.SearchBox:SetPoint("RIGHT", PVEFrame.NineSlice, "RIGHT", -15, 0);
	LFGListFrame.SearchPanel.RefreshButton:SetPoint("TOPLEFT", LFGListFrame.SearchPanel.SearchBox, "TOPLEFT", -50, 7);
	LFGListFrame.SearchPanel.FilterButton:SetPoint("BOTTOMRIGHT", PVEFrame, "BOTTOMRIGHT", -20, 45);
	LFGListFrame.SearchPanel.FilterButton:SetSize(80, LFGListFrame.SearchPanel.FilterButton:GetHeight());
	LFGListFrame.SearchPanel.SearchBox:SetSize(235, LFGListFrame.SearchPanel.SearchBox:GetHeight());
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
	updateRaidFrameWidth();
	--[[
	LFGListFrame:ClearAllPoints();
	LFGListFrame:SetPoint(originalUI["LFGListFrame"].position[1], originalUI["LFGListFrame"].position[2], originalUI["LFGListFrame"].position[3], originalUI["LFGListFrame"].position[4], originalUI["LFGListFrame"].position[5]);
	LFGListFrame:SetSize(438, LFGListFrame:GetHeight());
	]]
	updateRaidDifficulty(isSameCat, true);
end

local function updateDungeonFilter(difficultyID, aIDToAdd, aIDToRemove, minimumRating, showGroupsWithoutMyClass, hasTank, hasHealer, hasDPS)
	local enabled = C_LFGList.GetAdvancedFilter();
	if(difficultyID) then
		if (difficultyID == 1) then
			enabled.difficultyNormal = true;
			enabled.difficultyHeroic = false;
			enabled.difficultyMythic = false;
			enabled.difficultyMythicPlus = false;
		end
		if (difficultyID == 2) then
			enabled.difficultyNormal = false;
			enabled.difficultyHeroic = true;
			enabled.difficultyMythic = false;
			enabled.difficultyMythicPlus = false;
		end
		if (difficultyID == 3) then
			enabled.difficultyNormal = false;
			enabled.difficultyHeroic = false;
			enabled.difficultyMythic = true;
			enabled.difficultyMythicPlus = false;
		end
		if (difficultyID == 4) then
			enabled.difficultyNormal = false;
			enabled.difficultyHeroic = false;
			enabled.difficultyMythic = false;
			enabled.difficultyMythicPlus = true;
		end
	end
	if (aIDToAdd) then
		local groupID = C_LFGList.GetActivityInfoTable(aIDToAdd).groupFinderActivityGroupID;
		if (groupID and PGF_Contains(enabled.activities, groupID)) then
			enabled.activities = {};
			table.insert(enabled.activities, groupID);
		elseif (groupID) then
			table.insert(enabled.activities, groupID);
		end
	end
	if (aIDToRemove) then
		local groupID = C_LFGList.GetActivityInfoTable(aIDToRemove).groupFinderActivityGroupID;
		if (groupID) then
			local index = PGF_Contains(enabled.activities, groupID);
			if (index) then
				table.remove(enabled.activities, index);
			end
			if (next(enabled.activities) == nil) then
				--LFGListAdvancedFiltersCheckAllDungeons
				local seasonGroups = C_LFGList.GetAvailableActivityGroups(GROUP_FINDER_CATEGORY_ID_DUNGEONS, bit.bor(Enum.LFGListFilter.CurrentSeason, Enum.LFGListFilter.PvE));
				local expansionGroups = C_LFGList.GetAvailableActivityGroups(GROUP_FINDER_CATEGORY_ID_DUNGEONS, bit.bor(Enum.LFGListFilter.CurrentExpansion, Enum.LFGListFilter.NotCurrentSeason, Enum.LFGListFilter.PvE));
				local allDungeons = {};
				tAppendAll(allDungeons, seasonGroups);
				tAppendAll(allDungeons, expansionGroups);
				enabled.activities = allDungeons;
			end
		end
		updateSearch();
	end
	if (minimumRating) then
		enabled.minimumRating = minimumRating;
	end
	if (showGroupsWithoutMyClass == true) then
		enabled.needsMyClass = true;
	elseif (showGroupsWithoutMyClass == false) then
		enabled.needsMyClass = false;
	end
	if (hasTank == true) then
		enabled.hasTank = true;
	elseif (hasTank == false) then
		enabled.hasTank = false;
	end
	if (hasHealer == true) then
		enabled.hasHealer = true;
	elseif (hasHealer == false) then
		enabled.hasHealer = false;
	end
	if (hasDPS == true) then
		enabled.hasDPS = true;
	elseif (hasDPS == false) then
		enabled.hasDPS = false;
	end
	C_LFGList.SaveAdvancedFilter(enabled);
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
		dungeonOptionsFrame:SetPoint("BOTTOMRIGHT", PVEFrame, "BOTTOMRIGHT", -1,-150);
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
		dungeonOptionsFrame:SetPoint("BOTTOMRIGHT", PVEFrame, "BOTTOMRIGHT", -1,-148);
	end
	local dungeonDifficultyText = dungeonFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalTiny2");
	dungeonDifficultyText:SetFont(dungeonDifficultyText:GetFont(), 10);
	dungeonDifficultyText:SetPoint("TOPLEFT", 30, -40);
	local dungeonDifficultyDropDown = CreateFrame("Button", nil, dungeonFrame, "UIDropDownMenuTemplate");
	dungeonDifficultyDropDown:SetPoint("LEFT", dungeonDifficultyText, "RIGHT", -12, -2);
	local function Initialize_DungeonStates(self, level)
		for k,v in pairs(dungeonStates) do
			local info = UIDropDownMenu_CreateInfo();
			info.text = v;
			info.value = v;
			info.func = PGF_DungeonState_OnClick;
			UIDropDownMenu_AddButton(info, level);
		end
	end

	function PGF_DungeonState_OnClick(self)
		UIDropDownMenu_SetSelectedID(dungeonDifficultyDropDown, self:GetID());
		lastSelectedDungeonState = self:GetText();
		updateDungeonFilter(self:GetID());
		updateDungeonDifficulty();
	end

	UIDropDownMenu_SetWidth(dungeonDifficultyDropDown, 130);
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
	if (GetLocale() == "enGB" or GetLocale() == "enUS") then
		for index, challengeID in ipairs(C_ChallengeMode.GetMapTable()) do
			local name, id, timeLimit, texture, backgroundTexture = C_ChallengeMode.GetMapUIInfo(challengeID);
			local shortName = name:gsub("%s%(.*", "");
			if (name == "The MOTHERLODE!!") then
				name = "THE MOTHERLODE";
			elseif (name == "Operation: Mechagon - Workshop") then
				name = "Mechagon Workshop";
			end
			dungeonTextures[dungeonAbbreviations[name] .. " (Mythic Keystone)"] = texture;
		end
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
			if (difficulty == "(Mythic Keystone)" and (GetLocale() == "enGB" or GetLocale() == "enUS")) then
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
					updateDungeonFilter(nil, aID);
					updateSearch();
				else
					selectedInfo.dungeons[aID] = nil;
					updateDungeonFilter(nil, nil, aID);
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
	filterRolesText:SetPoint("TOPLEFT", 48, -301);
	filterRolesText:SetText("Hide incompatible(role) groups");
	local filterRolesCheckButton = CreateFrame("CheckButton", nil, dungeonFrame, "UICheckButtonTemplate");
	filterRolesCheckButton:SetSize(20, 20);
	filterRolesCheckButton:SetPoint("RIGHT", filterRolesText, "RIGHT", 25, 0);
	filterRolesCheckButton:HookScript("OnClick", function(self)
		if (self:GetChecked()) then
			PGF_FilterRemainingRoles = true;
			updateSearch();
			PlaySound(856);
		else
			PGF_FilterRemainingRoles = false;
			updateSearch();
			PlaySound(857);
		end
	end);
	local minLeaderScoreText = dungeonFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalTiny2");
	minLeaderScoreText:SetFont(minLeaderScoreText:GetFont(), 10);
	minLeaderScoreText:SetPoint("TOPLEFT", filterRolesText, "TOPLEFT", 0, -20);
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
			MinRatingFrame.MinRating:SetNumber(tonumber(self:GetText()));
			updateDungeonFilter(nil, nil, nil, tonumber(self:GetText()));
			updateSearch();
		elseif (self:GetText() == nil or self:GetText() == "") then
			selectedInfo["leaderScore"] = 0;
			updateDungeonFilter(nil, nil, nil, 0);
			MinRatingFrame.MinRating:SetNumber(0);
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
	roleText:SetPoint("TOPLEFT", minLeaderScoreText, "TOPLEFT", 0, -20);
	roleText:SetText(L.OPTIONS_ROLE);
	local canBeTank, canBeHealer, canBeDPS = UnitGetAvailableRoles("player");
	local dpsTexture = f:CreateTexture(nil, "OVERLAY");
	dpsTexture:SetTexture("Interface\\LFGFrame\\UI-LFG-ICON-ROLES");
	dpsTexture:SetPoint("TOPLEFT", roleText, 58, 1);
	dpsTexture:SetSize(16, 16);
	dpsTexture:SetTexCoord(PGF_GetTexCoordsForRole("DAMAGER"));
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
	healerTexture:SetTexCoord(PGF_GetTexCoordsForRole("HEALER"));
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
	tankTexture:SetTexCoord(PGF_GetTexCoordsForRole("TANK"));
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
	showMoreText:SetText(PGF_ShowDungeonOptionsFrame and "Show Less" or "Show More");
	local showMoreButton = CreateFrame("Button", nil, dungeonFrame);
	if (PGF_ShowDungeonOptionsFrame) then
		showMoreButton:SetNormalTexture("Interface\\Buttons\\Arrow-Up-Up.PNG");
		showMoreButton:SetPoint("BOTTOMRIGHT", PVEFrame, "BOTTOMRIGHT", 0, 0);
	else
		showMoreButton:SetNormalTexture("Interface\\Buttons\\Arrow-Down-Down.PNG");
		showMoreButton:SetPoint("BOTTOMRIGHT", PVEFrame, "BOTTOMRIGHT", 0, -7);
	end
	showMoreButton:SetSize(18,18);
	showMoreButton:SetScript("OnClick", function(self)
		if (dungeonOptionsFrame:IsShown()) then
			PGF_ShowDungeonOptionsFrame = false;
			dungeonOptionsFrame:Hide();
			showMoreButton:SetNormalTexture("Interface\\Buttons\\Arrow-Down-Down.PNG");
			showMoreButton:SetPoint("BOTTOMRIGHT", PVEFrame, "BOTTOMRIGHT", 0, -7);
			showMoreText:SetText("Show More");
		else
			PGF_ShowDungeonOptionsFrame = true;
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
	local showDetailedDataText = nil;
	local showDetailedDataButton = nil;
	if (locale == "enGB" or locale == "enUS") then
		showDetailedDataText = dungeonOptionsFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalTiny2");
		showDetailedDataText:SetFont(showDetailedDataText:GetFont(), 10);
		showDetailedDataText:SetPoint("TOPLEFT", showLeaderScoreForDungeonText, "TOPLEFT", 0, -18);
		showDetailedDataText:SetText("Show Detailed Roles");
		showDetailedDataButton = CreateFrame("CheckButton", nil, dungeonOptionsFrame, "UICheckButtonTemplate");
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
	end
	local showGroupsForYourRoleText = dungeonOptionsFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalTiny2");
	showGroupsForYourRoleText:SetFont(showGroupsForYourRoleText:GetFont(), 10);
	showGroupsForYourRoleText:SetPoint("TOPLEFT", showLeaderScoreForDungeonText, "TOPLEFT", 0, -36);
	showGroupsForYourRoleText:SetText("Show groups that has atleast 1:");
	local showGroupsForYourRoleButtonTank = CreateFrame("CheckButton", nil, dungeonOptionsFrame, "UICheckButtonTemplate");
	showGroupsForYourRoleButtonTank:SetSize(20, 20);
	showGroupsForYourRoleButtonTank:SetPoint("RIGHT", showGroupsForYourRoleText, "RIGHT", 20, -1);
	showGroupsForYourRoleButtonTank:SetChecked(PGF_OnlyShowMyRole2["TANK"]);
	showGroupsForYourRoleButtonTank:HookScript("OnClick", function(self)
		if (self:GetChecked()) then
			PGF_OnlyShowMyRole2["TANK"] = true;
			updateDungeonFilter(nil, nil, nil, nil, nil, true);
			updateSearch();
			PlaySound(856);
		else
			PGF_OnlyShowMyRole2["TANK"] = false;
			updateDungeonFilter(nil, nil, nil, nil, nil, false);
			updateSearch();
			PlaySound(857);
		end
	end);
	local tankTexture2 = dungeonOptionsFrame:CreateTexture(nil, "OVERLAY");
	tankTexture2:SetTexture("Interface\\LFGFrame\\UI-LFG-ICON-ROLES");
	tankTexture2:SetPoint("TOP", showGroupsForYourRoleButtonTank, "TOP", 0, 15);
	tankTexture2:SetSize(16, 16);
	tankTexture2:SetTexCoord(PGF_GetTexCoordsForRole("TANK"));
	local showGroupsForYourRoleButtonHealer = CreateFrame("CheckButton", nil, dungeonOptionsFrame, "UICheckButtonTemplate");
	showGroupsForYourRoleButtonHealer:SetSize(20, 20);
	showGroupsForYourRoleButtonHealer:SetPoint("RIGHT", showGroupsForYourRoleButtonTank, "RIGHT", 20, 0);
	showGroupsForYourRoleButtonHealer:SetChecked(PGF_OnlyShowMyRole2["HEALER"]);
	showGroupsForYourRoleButtonHealer:HookScript("OnClick", function(self)
		if (self:GetChecked()) then
			PGF_OnlyShowMyRole2["HEALER"] = true;
			updateDungeonFilter(nil, nil, nil, nil, nil, nil, true);
			updateSearch();
			PlaySound(856);
		else
			PGF_OnlyShowMyRole2["HEALER"] = false;
			updateDungeonFilter(nil, nil, nil, nil, nil, nil, false);
			updateSearch();
			PlaySound(857);
		end
	end);
	local healerTexture2 = dungeonOptionsFrame:CreateTexture(nil, "OVERLAY");
	healerTexture2:SetTexture("Interface\\LFGFrame\\UI-LFG-ICON-ROLES");
	healerTexture2:SetPoint("TOP", showGroupsForYourRoleButtonHealer, "TOP", 0, 15);
	healerTexture2:SetSize(16, 16);
	healerTexture2:SetTexCoord(PGF_GetTexCoordsForRole("HEALER"));
	local showGroupsForYourRoleButtonDPS = CreateFrame("CheckButton", nil, dungeonOptionsFrame, "UICheckButtonTemplate");
	showGroupsForYourRoleButtonDPS:SetSize(20, 20);
	showGroupsForYourRoleButtonDPS:SetPoint("RIGHT", showGroupsForYourRoleButtonHealer, "RIGHT", 20, 0);
	showGroupsForYourRoleButtonDPS:SetChecked(PGF_OnlyShowMyRole2["DAMAGER"]);
	showGroupsForYourRoleButtonDPS:HookScript("OnClick", function(self)
		if (self:GetChecked()) then
			PGF_OnlyShowMyRole2["DAMAGER"] = true;
			updateDungeonFilter(nil, nil, nil, nil, nil, nil, nil, true);
			updateSearch();
			PlaySound(856);
		else
			PGF_OnlyShowMyRole2["DAMAGER"] = false;
			updateDungeonFilter(nil, nil, nil, nil, nil, nil, nil, false);
			updateSearch();
			PlaySound(857);
		end
	end);
	local dpsTexture2 = dungeonOptionsFrame:CreateTexture(nil, "OVERLAY");
	dpsTexture2:SetTexture("Interface\\LFGFrame\\UI-LFG-ICON-ROLES");
	dpsTexture2:SetPoint("TOP", showGroupsForYourRoleButtonDPS, "TOP", 0, 15);
	dpsTexture2:SetSize(16, 16);
	dpsTexture2:SetTexCoord(PGF_GetTexCoordsForRole("DAMAGER"));
	local showGroupsWithoutMyClassText = dungeonOptionsFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalTiny2");
	showGroupsWithoutMyClassText:SetFont(showGroupsWithoutMyClassText:GetFont(), 10);
	showGroupsWithoutMyClassText:SetPoint("TOPLEFT", showGroupsForYourRoleText, "TOPLEFT", 0, -18);
	showGroupsWithoutMyClassText:SetText("Hide groups with " .. strlower(playerClass));
	local showGroupsWithoutMyClassButton = CreateFrame("CheckButton", nil, dungeonOptionsFrame, "UICheckButtonTemplate");
	showGroupsWithoutMyClassButton:SetSize(20, 20);
	showGroupsWithoutMyClassButton:SetPoint("RIGHT", showGroupsWithoutMyClassText, "RIGHT", 20, -1);
	showGroupsWithoutMyClassButton:SetChecked(PGF_DontShowMyClass);
	showGroupsWithoutMyClassButton:HookScript("OnClick", function(self)
		if (self:GetChecked()) then
			updateDungeonFilter(nil, nil, nil, nil, true);
			PGF_DontShowMyClass = true;
			updateSearch();
			PlaySound(856);
		else
			PGF_DontShowMyClass = false;
			updateDungeonFilter(nil, nil, nil, nil, false);
			updateSearch();
			PlaySound(857);
		end
	end);
	local showDeclinedGroupsText = dungeonOptionsFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalTiny2");
	showDeclinedGroupsText:SetFont(showDeclinedGroupsText:GetFont(), 10);
	showDeclinedGroupsText:SetPoint("TOPLEFT", showGroupsWithoutMyClassText, "TOPLEFT", 0, -18);
	showDeclinedGroupsText:SetText("Hide groups you got declined from");
	local showDeclinedGroupsButton = CreateFrame("CheckButton", nil, dungeonOptionsFrame, "UICheckButtonTemplate");
	showDeclinedGroupsButton:SetSize(20, 20);
	showDeclinedGroupsButton:SetPoint("RIGHT", showDeclinedGroupsText, "RIGHT", 20, -1);
	showDeclinedGroupsButton:SetChecked(PGF_DontShowDeclinedGroups);
	showDeclinedGroupsButton:HookScript("OnClick", function(self)
		if (self:GetChecked()) then
			PGF_DontShowDeclinedGroups = true;
			updateSearch();
			PlaySound(856);
		else
			PGF_DontShowDeclinedGroups = false;
			updateSearch();
			PlaySound(857);
		end
	end);
	local showLeaderIconText = dungeonOptionsFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalTiny2");
	showLeaderIconText:SetFont(showLeaderIconText:GetFont(), 10);
	showLeaderIconText:SetPoint("TOPLEFT", showDeclinedGroupsText, "TOPLEFT", 0, -18);
	showLeaderIconText:SetText("Show who is leader");
	local showLeaderIconButton = CreateFrame("CheckButton", nil, dungeonOptionsFrame, "UICheckButtonTemplate");
	showLeaderIconButton:SetSize(20, 20);
	showLeaderIconButton:SetPoint("RIGHT", showLeaderIconText, "RIGHT", 20, -1);
	showLeaderIconButton:SetChecked(PGF_ShowLeaderIcon);
	showLeaderIconButton:HookScript("OnClick", function(self)
		if (self:GetChecked()) then
			PGF_ShowLeaderIcon = true;
			LFGListSearchPanel_UpdateResults(LFGListFrame.SearchPanel);
			PlaySound(856);
		else
			PGF_ShowLeaderIcon = false;
			LFGListSearchPanel_UpdateResults(LFGListFrame.SearchPanel);
			PlaySound(857);
		end
	end);
	local sortingText = dungeonOptionsFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalTiny2");
	sortingText:SetFont(sortingText:GetFont(), 10);
	sortingText:SetPoint("TOPLEFT", showLeaderIconText, "TOPLEFT", 0, -28);
	sortingText:SetText("Sort by:");
	local sortingDropdown = CreateFrame("Button", nil, dungeonOptionsFrame, "UIDropDownMenuTemplate");
	sortingDropdown:SetPoint("LEFT", sortingText, "RIGHT", -12, -2);
	local function Initialize_SortingStates(self, level)
		for k,v in ipairs(sortingStates) do
			local info = UIDropDownMenu_CreateInfo();
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
	dGUI["DetailedData"] = {["text"] = showDetailedDataText, ["checkbox"] = showDetailedDataButton};
	dGUI["OnlyMyRole"]= {["text"] = showGroupsForYourRoleText, ["checkbox"] = showGroupsForYourRoleButtonTank};
end
--[[
	Documentation: Creates all of the UI elements related to the raidFrame including:
	Difficulty and Raid Dropdown
	Text, checkbox and texture for each boss
	The raids that will show up are the ones we get from recommended activities (same as in the autocomplete in search). All of the bosses will be stored in the currentRaidsActivityIDs[abbrevatedRaidName][abbrevatedBossName]
]]
local function initRaid()
	if (PVEFrame.GetBackdrop) then
		raidOptionsFrame:SetBackdrop(PVEFrame:GetBackdrop());
		local r,g,b,a = PVEFrame:GetBackdropColor();
		raidOptionsFrame:SetBackdropColor(r,g,b,a);
		r,g,b,a = PVEFrame:GetBackdropBorderColor();
		raidOptionsFrame:SetBackdropBorderColor(r,g,b,a);
		raidOptionsFrame:SetPoint("BOTTOMRIGHT", PVEFrame, "BOTTOMRIGHT", -1,-140);
	elseif (PVEFrameBg:GetTexture()) then
		local texture = raidOptionsFrame:CreateTexture(nil, "BACKGROUND");
		raidOptionsFrame:SetBackdrop({
			bgFile = "",
			edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
			edgeSize = 16,
			insets = { left = 4, right = 4, top = 4, bottom = 4 },
		});
		texture:SetTexture(PVEFrameBg:GetTexture());
		texture:SetAllPoints();
		raidOptionsFrame:SetBackdropBorderColor(0.1,0.1,0.1,1);
		raidOptionsFrame:SetPoint("BOTTOMRIGHT", PVEFrame, "BOTTOMRIGHT", -1,-138);
	end
	local raidDifficultyText = raidFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalTiny2");
	raidDifficultyText:SetFont(raidDifficultyText:GetFont(), 10);
	raidDifficultyText:SetPoint("TOPLEFT", 30, -40);
	local raidDifficultyDropDown = CreateFrame("Button", nil, raidFrame, "UIDropDownMenuTemplate");
	raidDifficultyDropDown:SetPoint("LEFT", raidDifficultyText, "RIGHT", -12, -2);
	local function Initialize_RaidStates(self, level)
		for k,v in pairs(raidStates) do
			local info = UIDropDownMenu_CreateInfo();
			info.text = v;
			info.value = v;
			info.func = PGF_RaidState_OnClick;
			UIDropDownMenu_AddButton(info, level);
		end
	end

	function PGF_RaidState_OnClick(self)
		UIDropDownMenu_SetSelectedID(raidDifficultyDropDown, self:GetID());
		lastSelectedRaidState = self:GetText();
		if (self:GetText():match("All")) then --there is no activity for All so if there is a previous activity set in the searchbox it needs to be cleared
			C_LFGList.ClearSearchTextFields();
		elseif (PGF_allRaidActivityIDs[raidStateMap[lastSelectedRaidState]]) then
			C_LFGList.SetSearchToActivity(raidStateMap[lastSelectedRaidState]);
		end
		updateRaidDifficulty(true, false);
	end

	UIDropDownMenu_SetWidth(raidDifficultyDropDown, 100);
	UIDropDownMenu_SetButtonWidth(raidDifficultyDropDown, 100);
	UIDropDownMenu_JustifyText(raidDifficultyDropDown, "CENTER");
	UIDropDownMenu_Initialize(raidDifficultyDropDown, Initialize_RaidStates);
	UIDropDownMenu_SetSelectedID(raidDifficultyDropDown, 1);
	local matchingActivities = C_LFGList.GetAvailableActivities(3, nil, ResolveCategoryFilters(3, 1), ""); --3 == raid category 0 is to set there arent any language filters
	for i = 1, #matchingActivities do
		local name = PGF_allRaidActivityIDs[matchingActivities[i]];
		local shortName = name:gsub("%s%(.*", "");
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
			local trimedName = bossOrderMap[raidAbbreviations[raidNameShort]][index];
			if (raidNameShort == "") then --try Interface\\ENCOUNTERJOURNAL\\UI-EJ-BOSS-IgiratheCruel
				trimedName = bossOrderMap[raidAbbreviations[raidNameShort]][index]:gsub("(%s)","");
				texture:SetTexture("Interface\\ENCOUNTERJOURNAL\\UI-EJ-BOSS-" .. trimedName ..".PNG");
			end
			if (texture:GetTextureFileID() == nil) then --try Interface\\ENCOUNTERJOURNAL\\UI-EJ-BOSS-Igira the Cruel
				trimedName = bossOrderMap[raidAbbreviations[raidNameShort]][index]:gsub(",","");
				texture:SetTexture("Interface\\ENCOUNTERJOURNAL\\UI-EJ-BOSS-" .. trimedName ..".PNG");
			end
			if (texture:GetTextureFileID() == nil) then --try Interface\\ENCOUNTERJOURNAL\\UI-EJ-BOSS-Ovinax
				trimedName = bossOrderMap[raidAbbreviations[raidNameShort]][index]:gsub("'","");
				texture:SetTexture("Interface\\ENCOUNTERJOURNAL\\UI-EJ-BOSS-" .. trimedName ..".PNG");
			end
			if (texture:GetTextureFileID() == nil) then --try Interface\\ENCOUNTERJOURNAL\\UI-EJ-BOSS-Ovinax
				trimedName = bossOrderMap[raidAbbreviations[raidNameShort]][index]:gsub("[',]","");
				texture:SetTexture("Interface\\ENCOUNTERJOURNAL\\UI-EJ-BOSS-" .. trimedName ..".PNG");
			end
			if (texture:GetTextureFileID() == nil) then --try Interface\\ENCOUNTERJOURNAL\\UI-EJ-BOSS-Igira
				trimedName = bossOrderMap[raidAbbreviations[raidNameShort]][index]:gsub("%-"," ");
				texture:SetTexture("Interface\\ENCOUNTERJOURNAL\\UI-EJ-BOSS-" .. trimedName ..".PNG");
			end
			if (texture:GetTextureFileID() == nil) then --try Interface\\ENCOUNTERJOURNAL\\UI-EJ-BOSS-Igira
				trimedName = bossOrderMap[raidAbbreviations[raidNameShort]][index]:gsub(",?%s.*","");
				texture:SetTexture("Interface\\ENCOUNTERJOURNAL\\UI-EJ-BOSS-" .. trimedName ..".PNG");
			end
			if (texture:GetTextureFileID() == nil) then --fallback to Boss Name instead of just BossName
				texture:SetTexture("Interface\\ENCOUNTERJOURNAL\\UI-EJ-BOSS-" .. bossOrderMap[raidAbbreviations[raidNameShort]][index] ..".PNG");
				if (bossOrderMap[raidAbbreviations[raidNameShort]][index] == "Nexus-Princess Ky'veza") then
					texture:SetTexture("Interface\\ENCOUNTERJOURNAL\\UI-EJ-BOSS-Kyveza.PNG");
				elseif (bossOrderMap[raidAbbreviations[raidNameShort]][index] == "Sprocketmonger Lockenstock") then
					texture:SetTexture("Interface\\ENCOUNTERJOURNAL\\UI-EJ-BOSS-Sprocketmonger Locknstock.PNG");
				elseif (bossOrderMap[raidAbbreviations[raidNameShort]][index] == "The One-Armed Bandit") then
					texture:SetTexture("Interface\\ENCOUNTERJOURNAL\\UI-EJ-BOSS-One Armed Bandit.PNG");
				elseif (bossOrderMap[raidAbbreviations[raidNameShort]][index] == "Tindral Sageswift, Seer of the Flame") then
					texture:SetTexture("Interface\\ENCOUNTERJOURNAL\\UI-EJ-BOSS-Tindral Sageswift Seer of Flame.PNG");
				end
			end
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
	local showMoreText = raidFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalTiny2");
	showMoreText:SetFont(showMoreText:GetFont(), 10);
	showMoreText:SetPoint("BOTTOMRIGHT", PVEFrame, "BOTTOMRIGHT", -20, 2);
	showMoreText:SetText(PGF_ShowRaidOptionsFrame and "Show Less" or "Show More");
	local showMoreButton = CreateFrame("Button", nil, raidFrame);
	if (PGF_ShowRaidOptionsFrame) then
		showMoreButton:SetNormalTexture("Interface\\Buttons\\Arrow-Up-Up.PNG");
		showMoreButton:SetPoint("BOTTOMRIGHT", PVEFrame, "BOTTOMRIGHT", 0, 0);
	else
		showMoreButton:SetNormalTexture("Interface\\Buttons\\Arrow-Down-Down.PNG");
		showMoreButton:SetPoint("BOTTOMRIGHT", PVEFrame, "BOTTOMRIGHT", 0, -7);
	end
	showMoreButton:SetSize(18,18);
	showMoreButton:SetScript("OnClick", function(self)
		if (raidOptionsFrame:IsShown()) then
			raidOptionsFrame:Hide();
			PGF_ShowRaidOptionsFrame = false;
			showMoreButton:SetNormalTexture("Interface\\Buttons\\Arrow-Down-Down.PNG");
			showMoreButton:SetPoint("BOTTOMRIGHT", PVEFrame, "BOTTOMRIGHT", 0, -7);
			showMoreText:SetText("Show More");
		else
			PGF_ShowRaidOptionsFrame = true;
			raidOptionsFrame:Show();
			showMoreButton:SetNormalTexture("Interface\\Buttons\\Arrow-Up-Up.PNG");
			showMoreButton:SetPoint("BOTTOMRIGHT", PVEFrame, "BOTTOMRIGHT", 0, 0);
			showMoreText:SetText("Show Less");
		end
	end);
	local showYourClassAmountText = raidOptionsFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalTiny2");
	showYourClassAmountText:SetFont(showYourClassAmountText:GetFont(), 10);
	showYourClassAmountText:SetPoint("TOPLEFT", 15, -5);
	showYourClassAmountText:SetText("Show amount of " .. string.lower(playerClass) .. "s");
	local showYourClassAmountButton = CreateFrame("CheckButton", nil, raidOptionsFrame, "UICheckButtonTemplate");
	showYourClassAmountButton:SetSize(20, 20);
	showYourClassAmountButton:SetPoint("RIGHT", showYourClassAmountText, "RIGHT", 20, -1);
	showYourClassAmountButton:SetChecked(PGF_ShowYourClassAmount);
	showYourClassAmountButton:HookScript("OnClick", function(self)
		if (self:GetChecked()) then
			PGF_ShowYourClassAmount = true;
			updateRaidFrameWidth();
			LFGListSearchPanel_UpdateResults(LFGListFrame.SearchPanel);
			PlaySound(856);
		else
			PGF_ShowYourClassAmount = false;
			updateRaidFrameWidth();
			LFGListSearchPanel_UpdateResults(LFGListFrame.SearchPanel);
			PlaySound(857);
		end
	end);
	local showYourTierAmountText = raidOptionsFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalTiny2");
	showYourTierAmountText:SetFont(showYourTierAmountText:GetFont(), 10);
	showYourTierAmountText:SetPoint("TOPLEFT", showYourClassAmountText, "TOPLEFT", 0, -18);
	showYourTierAmountText:SetText("Show amount of " .. tierSetsMap[playerClass] .. " tier players");
	local sowYourTierAmountButton = CreateFrame("CheckButton", nil, raidOptionsFrame, "UICheckButtonTemplate");
	sowYourTierAmountButton:SetSize(20, 20);
	sowYourTierAmountButton:SetPoint("RIGHT", showYourTierAmountText, "RIGHT", 20, -1);
	sowYourTierAmountButton:SetChecked(PGF_ShowYourTierAmount);
	sowYourTierAmountButton:HookScript("OnClick", function(self)
		if (self:GetChecked()) then
			PGF_ShowYourTierAmount = true;
			updateRaidFrameWidth();
			LFGListSearchPanel_UpdateResults(LFGListFrame.SearchPanel);
			PlaySound(856);
		else
			PGF_ShowYourTierAmount = false;
			updateRaidFrameWidth();
			LFGListSearchPanel_UpdateResults(LFGListFrame.SearchPanel);
			PlaySound(857);
		end
	end);
	local sortingText = raidOptionsFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalTiny2");
	sortingText:SetFont(sortingText:GetFont(), 10);
	sortingText:SetPoint("TOPLEFT", showYourTierAmountText, "TOPLEFT", 0, -28);
	sortingText:SetText("Sort by:");
	local sortingDropdown = CreateFrame("Button", nil, raidOptionsFrame, "UIDropDownMenuTemplate");
	sortingDropdown:SetPoint("LEFT", sortingText, "RIGHT", -12, -2);
	local function Initialize_SortingStates(self, level)
		for k,v in ipairs(sortingRaidStates) do
			local info = UIDropDownMenu_CreateInfo();
			info.text = v;
			info.value = v;
			info.func = PGF_SortingRaidState_OnClick;
			UIDropDownMenu_AddButton(info, level);
		end
	end

	function PGF_SortingRaidState_OnClick(self)
		UIDropDownMenu_SetSelectedID(sortingDropdown, self:GetID());
		PGF_RaidSortingVariable = self:GetID();
		updateSearch();
	end

	UIDropDownMenu_SetWidth(sortingDropdown, 120);
	UIDropDownMenu_SetButtonWidth(sortingDropdown, 120);
	UIDropDownMenu_JustifyText(sortingDropdown, "CENTER");
	UIDropDownMenu_Initialize(sortingDropdown, Initialize_SortingStates);
	UIDropDownMenu_SetSelectedID(sortingDropdown, PGF_RaidSortingVariable);

	rGUI["Sorting"] = {["text"]= sortingText, ["dropDown"] = sortingDropdown};
end
--[[
	local function initChallengeMap()
		for index, challengeID in ipairs(C_ChallengeMode.GetMapTable()) do
			local name, id, timeLimit, texture, backgroundTexture = C_ChallengeMode.GetMapUIInfo(challengeID);
			local shortName = name:gsub("%s%(.*", "");
			for aID, aName in pairs(PGF_allDungeonsActivityIDs) do
				if (aName == shortName .. " (Mythic Keystone)") then
					challengeIDMap[challengeID] = aID;
					break;
				end
			end
		end
	end
]]
-- 9 is tyrannical, 10 is fortified as of 10.0.7, unsure if [1] is always fortified
--[[

	local function initBestScores()
		local weeklyMainAffix = C_MythicPlus.GetCurrentAffixes()[1].id;
		local isFortifiedWeek = false;
		if (weeklyMainAffix == 10) then
			isFortifiedWeek = true;
		end
		for index, challengeID in ipairs(C_ChallengeMode.GetMapTable()) do
			local runs = C_MythicPlus.GetSeasonBestAffixScoreInfoForMap(challengeID);
			local activityID = challengeIDMap[challengeID];
			if (runs == nil) then
				bestLevelPerDungeonMap[activityID] = 0;
			else
				if (runs[1] and runs[1].name == L.FORTIFIED and isFortifiedWeek) then
					bestLevelPerDungeonMap[activityID] = runs[1].level;
				elseif (runs[1] and runs[1].name == L.TYRANNICAL and not isFortifiedWeek) then
					bestLevelPerDungeonMap[activityID] = runs[1].level;
				elseif (runs[2] and runs[2].name == L.TYRANNICAL and not isFortifiedWeek) then
					bestLevelPerDungeonMap[activityID] = runs[2].level;
				elseif (runs[2] and runs[2].name == L.FORTIFIED and isFortifiedWeek) then
					bestLevelPerDungeonMap[activityID] = runs[2].level;
				else
					bestLevelPerDungeonMap[activityID] = 0;
				end
			end
		end
	end
]]
--[[
	Documentation: Initiate the UI if it has not been done before.
]]
PVEFrame:HookScript("OnShow", function(self)
	if(next(dGUI) == nil) then
		--initChallengeMap();
		--initBestScores();
		initDungeon();
		initRaid();
	end
	LFGListFrame.SearchPanel.FilterButton.ResetButton:Hide();
end);

LFGListFrame.SearchPanel.FilterButton.ResetButton:HookScript("OnShow", function(self)
	LFGListFrame.SearchPanel.FilterButton.ResetButton:Hide();
end);

local function restoreDungeonFilter(enabled)
	enabled.needsTank = false;
	enabled.needsHealer = false;
	enabled.needsDamage = false;
	enabled.needsMyClass = PGF_DontShowMyClass;
	enabled.hasTank = PGF_OnlyShowMyRole2["TANK"];
	enabled.hasHealer = PGF_OnlyShowMyRole2["HEALER"];
	enabled.hasDPS = PGF_OnlyShowMyRole2["DAMAGER"];
	enabled.minimumRating = 0;
	enabled.activities = {};
	enabled.difficultyNormal = false;
	enabled.difficultyHeroic = false;
	enabled.difficultyMythic = false;
	enabled.difficultyMythicPlus = true;
	local seasonGroups = C_LFGList.GetAvailableActivityGroups(GROUP_FINDER_CATEGORY_ID_DUNGEONS, bit.bor(Enum.LFGListFilter.CurrentSeason, Enum.LFGListFilter.PvE));
	local expansionGroups = C_LFGList.GetAvailableActivityGroups(GROUP_FINDER_CATEGORY_ID_DUNGEONS, bit.bor(Enum.LFGListFilter.CurrentExpansion, Enum.LFGListFilter.NotCurrentSeason, Enum.LFGListFilter.PvE));
	local allDungeons = {};
	tAppendAll(allDungeons, seasonGroups);
	tAppendAll(allDungeons, expansionGroups);
	enabled.activities = allDungeons;
	C_LFGList.SaveAdvancedFilter(enabled);
end


f:SetScript("OnEvent", function(self, event, ...)
	if (event == "PLAYER_LOGIN") then
		C_MythicPlus.RequestMapInfo();
		playerRole = GetSpecializationRole(GetSpecialization());
		if (PGF_roles == nil) then
			PGF_roles = {["TANK"] = false, ["HEALER"] = false, ["DAMAGER"] = false};
			PGF_roles[playerRole] = true;
		else
			local canBeTank, canBeHealer, canBeDPS = UnitGetAvailableRoles("player");
			if (not canBeDPS) then
				PGF_roles["DAMAGER"] = false;
			end
			if (not canBeHealer) then
				PGF_roles["HEALER"] = false;
			end
			if (not canBeTank) then
				PGF_roles["TANK"] = false;
			end
		end
		if (PGF_ShowDungeonOptionsFrame == nil) then PGF_ShowDungeonOptionsFrame = true; end
		if (PGF_ShowRaidOptionsFrame == nil) then PGF_ShowRaidOptionsFrame = true; end
		if (PGF_RaidSortingVariable == nil) then PGF_RaidSortingVariable = 1; end
		if (PGF_DontShowDeclinedGroups == nil) then PGF_DontShowDeclinedGroups = false; end
		if (PGF_DontShowMyClass == nil) then PGF_DontShowMyClass = false; end
		if (PGF_ShowYourTierAmount == nil) then PGF_ShowYourTierAmount = false; end
		if (PGF_FilterRemainingRoles == nil) then PGF_FilterRemainingRoles = true; end
		if (PGF_DetailedDataDisplay == nil) then PGF_DetailedDataDisplay = false; end
		if (PGF_ShowLeaderIcon == nil) then PGF_ShowLeaderIcon = false; end
		if (locale ~= "enGB" and locale ~= "enUS") then
			PGF_DetailedDataDisplay = false;
		end
		if (PGF_ShowYourClassAmount == nil) then PGF_ShowYourClassAmount = true; end
		if (PGF_ShowLeaderDungeonKey == nil) then PGF_ShowLeaderDungeonKey = false; end
		if (PGF_SortingVariable == nil) then PGF_SortingVariable = 1; end
		if (PGF_OnlyShowMyRole2 == nil) then PGF_OnlyShowMyRole2 = {["TANK"] = false, ["HEALER"] = false, ["DAMAGER"] = false}; end
		if IsInGuild() then
			C_ChatInfo.SendAddonMessage("PGF_VERSIONCHECK", version, "GUILD");
		end
		if (not PGF_ShowDungeonOptionsFrame) then
			dungeonOptionsFrame:Hide();
		end
		if (not PGF_ShowRaidOptionsFrame) then
			raidOptionsFrame:Hide();
		end
		playerClass = select(1, UnitClassBase("player"));
		local enabled = C_LFGList.GetAdvancedFilter();
		restoreDungeonFilter(enabled);
	elseif (event == "PLAYER_SPECIALIZATION_CHANGED") then
		local unit = ...;
		if (UnitIsUnit(unit, "player")) then
			playerRole = GetSpecializationRole(GetSpecialization());
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
		msg = msg:match("%s(.+)");
		local sender = ...;
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
		sender = Ambiguate(sender, "none");
		if (prefix == "PGF_VERSIONCHECK" and not recievedOutOfDateMessage and not UnitIsUnit(UnitName("player"), sender)) then
			if (tonumber(msg) ~= nil) then
				if (tonumber(msg) > tonumber(version)) then
					DEFAULT_CHAT_FRAME:AddMessage("\124T|cFFFFFF00\124t" .. L.WARNING_OUTOFDATEMESSAGE);
					recievedOutOfDateMessage = true;
				end
			end
		end
	elseif (event == "LFG_LIST_APPLICATION_STATUS_UPDATED") then
		local searchResultID, newStatus, oldStatus, groupName = ...;
		if (newStatus == "applied") then
			LFGListUtil_SortSearchResults(LFGListFrame.SearchPanel.results);
			LFGListSearchPanel_UpdateResults(LFGListFrame.SearchPanel);
		end
	end
	--[[
	elseif (event == "PLAYER_ENTERING_WORLD") then
		if (next(GUI) == nil) then
		end
	end
	]]
end);
--[[
	f:SetScript("OnShow", function()
		if (LFGListFrame.SearchPanel.categoryID) then
		end
	end);
]]

--[[
	Documentation: LFGListFrame is automatically setting all points every time it is opened through pressing "I" and not selecting a category. So select a category then hide with "I" and then open again with "I" and it will change size.
	So to prevent this the size will be changed every time blizzard changes it and they are slow to change it so cant do it on show for some reason. Also this causes the resultlist to break so to fix that we do an updateresults to refresh the list
	Also need to check for if LFGListFrame.SearchPanel is visible because the categoryID is cached even when going back to the category selector which causes funky UI
]]
LFGListFrame:HookScript("OnSizeChanged", function(self)
	self:Show();
	if (LFGListFrame.SearchPanel.categoryID == GROUP_FINDER_CATEGORY_ID_DUNGEONS and LFGListFrame.SearchPanel:IsVisible()) then
		LFGListFrame:ClearAllPoints();
		LFGListFrame:SetPoint(originalUI["LFGListFrame"].position[1], originalUI["LFGListFrame"].position[2], originalUI["LFGListFrame"].position[3], originalUI["LFGListFrame"].position[4], originalUI["LFGListFrame"].position[5]);
		LFGListFrame:SetSize(368, LFGListFrame:GetHeight());
		C_Timer.After(0.05, function()
			LFGListSearchPanel_UpdateResults(LFGListFrame.SearchPanel);
		end);
	elseif (LFGListFrame.SearchPanel.categoryID == 3 and LFGListFrame.SearchPanel:IsVisible()) then
		updateRaidFrameWidth();
		C_Timer.After(0.05, function()
			LFGListSearchPanel_UpdateResults(LFGListFrame.SearchPanel);
		end);
	elseif (LFGListFrame.SearchPanel:IsVisible()) then
		restoreOriginalUI();
		LFGListSearchPanel_UpdateButtonStatus(LFGListFrame.SearchPanel);
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
	questID param(int) - the questID if there is one
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

local function PGF_LFGListSearchPanel_DoSearch(self)
	prevSearchTime = currentSearchTime;
	currentSearchTime = GetTime();
end

hooksecurefunc("LFGListSearchPanel_DoSearch", PGF_LFGListSearchPanel_DoSearch);
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
	local activityID = searchResults.activityIDs[1];
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
local function realTimeApplication(self)
	local _, appStatus, pendingStatus, appDuration = C_LFGList.GetApplicationInfo(self.resultID);
	local isApplication = (appStatus ~= "none" or pendingStatus);
	return isApplication;
end
local function searchEntry_OnUpdate(self, texture)
	if (texture:IsMouseOver() and texture:IsShown()) then
		GameTooltip:SetOwner(texture, "ANCHOR_TOPLEFT");
		GameTooltip:SetText("New Group");
		GameTooltip:Show();
	elseif (texture:IsShown() and not texture:IsMouseOver()) then
		GameTooltip:Hide();
		LFGListSearchEntry_OnEnter(self);
	end
end

--C_LFGList.GetSearchResultEncounterInfo(self.resultID) returns a table [1 to n] = Boss Name or Encounter Name?

--[[
	Documentation: The function is a blizzard function that decides in which way the displayData should be shown, if it is a raid group it should show roles numerically for example. It also determines when the displayData should be shown and all of the application widgets such as pending texts, cancel buttons etc. It also contains the text name of the groups.
	The hooked version changes it so that displayData is always shown and moves the pending text, expiration text and the cancel button. While also adding the leaders m+ score to the name of the group if it is a dungeon group.

	Payload:
	param(arr/object) - the entryFrame that contains all of the elements with information of the group
]]
local function PGF_LFGListSearchEntry_Update(self)
	local resultID = self.resultID;
	if not C_LFGList.HasSearchResultInfo(resultID) then
		return;
	end

	local _, appStatus, pendingStatus, appDuration = C_LFGList.GetApplicationInfo(resultID);

	local isApplication = (appStatus ~= "none" or pendingStatus);
	local searchResultInfo = C_LFGList.GetSearchResultInfo(resultID);
	--group no longer compatible
	if(self.IncompatibleBG) then
		self.IncompatibleBG:Hide();
	else
		local texture = self:CreateTexture(nil, "OVERLAY");
		texture:SetColorTexture(0.5,0,0,0.5);
		texture:SetPoint("TOPLEFT", 0, 0);
		texture:SetSize(self:GetWidth(), self:GetHeight());
		texture:Hide();
		self.IncompatibleBG = texture;
	end
	--group no longer compatible
	if(self.NewIcon) then
		self.NewIcon:Hide();
	else
		local texture = self:CreateTexture(nil, "OVERLAY");
		texture:SetPoint("TOPLEFT", 0, 0);
		texture:SetSize(10, 10);
		--texture:SetTexture("Interface\\AddOns\\PGFinder\\Res\\NewGroup.tga");
		self:HookScript("OnEnter", function()
			self:HookScript("OnUpdate", function() searchEntry_OnUpdate(self, texture); end);
		end);
		self:HookScript("OnLeave", function()
			self:SetScript("OnUpdate", nil);
			if (realTimeApplication(self)) then
				self:SetScript("OnUpdate", LFGListSearchEntry_UpdateExpiration);
				LFGListSearchEntry_UpdateExpiration(self);
			end
		end);
		texture:SetAtlas("groupfinder-eye-highlight");
		texture:Hide();
		self.NewIcon = texture;
	end
	if ((isNewGroup(searchResultInfo.leaderName, searchResultInfo.activityID, prevSearchTime) or GetTime()-searchResultInfo.age > prevSearchTime or searchResultInfo.leaderName == nil or searchResultInfo.leaderName == "") and (prevSearchTime ~= 0 and currentSearchTime ~= 0)) then
		self.NewIcon:Show();
	end
	--[[
	if (searchResultInfo.leaderName == nil or searchResultInfo.leaderName == "" or isNewGroup(searchResultInfo.leaderName, searchResultInfo.activityID)) then -- could add prevSearchTime to each entry in the array of isNewGroup and compare prevSearchTime with that field to see if its a new search or not  because currently this will return true every time you scroll in the list
		self.NewIcon:Show();
	end
	]]
	if (appStatus == "applied" and not HasRemainingSlotsForLocalPlayerRole(resultID) and LFGListFrame.SearchPanel.categoryID == GROUP_FINDER_CATEGORY_ID_DUNGEONS) then
		self.IncompatibleBG:Show(); --add debuging
	end

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
			if (searchResultInfo.leaderName and searchResultInfo.leaderName ~= "") then
				declinedGroups[searchResultInfo.leaderName] = {["activityID"] = searchResultInfo.activityID, ["timeout"] = GetTime()+declineResetTimer};
			end
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
		if (searchResultInfo.leaderName and searchResultInfo.leaderName ~= "") then
			declinedGroups[searchResultInfo.leaderName] = {["activityID"] = searchResultInfo.activityID, ["timeout"] = GetTime()+declineResetTimer};
		end
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
		elseif (LFGListFrame.SearchPanel.categoryID == 3) then
			local x = -35;
			if (PGF_ShowYourClassAmount) then
				x = x - 60;
			elseif (PGF_ShowYourTierAmount) then
				x = x - 30;
			end
			self.ExpirationTime:SetPoint("LEFT", self.DataDisplay, "LEFT", x, 0);
		else
			self.ExpirationTime:SetPoint("LEFT", self.DataDisplay, "LEFT", -35, 0);
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
	self.PendingLabel:SetPoint("LEFT", self.DataDisplay, "LEFT", -200, 8);
	self.PendingLabel:SetJustifyH("Center");


	--possible to take the name here and filter it out here if no match?
	self.resultID = resultID;
	if (LFGListFrame.SearchPanel.categoryID == GROUP_FINDER_CATEGORY_ID_DUNGEONS) then
		local leaderOverallDungeonScore = searchResultInfo.leaderOverallDungeonScore;
		local leaderDungeonScoreInfo = searchResultInfo.leaderDungeonScoreInfo;
		local dungeonScoreText = "|cffaaaaaa+0|r";
		--
		if (leaderDungeonScoreInfo and leaderDungeonScoreInfo[1] and leaderDungeonScoreInfo[1].bestRunLevel and leaderDungeonScoreInfo.mapScore ~= 0 and not leaderDungeonScoreInfo[1].finishedSuccess) then
			dungeonScoreText = "|cffaaaaaa+" .. leaderDungeonScoreInfo[1].bestRunLevel .. "|r";
		elseif (leaderDungeonScoreInfo and leaderDungeonScoreInfo[1] and leaderDungeonScoreInfo[1].bestRunLevel and leaderDungeonScoreInfo.mapScore ~= 0) then
			dungeonScoreText = "|cff00aa00+" .. leaderDungeonScoreInfo[1].bestRunLevel .. "|r";
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
	LFGListGroupDataDisplay_Update(self.DataDisplay, searchResultInfo.activityIDs[1], displayData, searchResultInfo.isDelisted);
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
		local applicantDungeonScoreInfo = C_LFGList.GetApplicantDungeonScoreForListing(appID, memberIdx, activeEntryInfo.activityIDs[1]);
		local dungeonScoreText = "|cffaaaaaa[+0]|r";
		if (applicantDungeonScoreInfo and applicantDungeonScoreInfo.mapScore ~= 0 and not applicantDungeonScoreInfo.finishedSuccess) then
			dungeonScoreText = "|cffaaaaaa[+" .. applicantDungeonScoreInfo.bestRunLevel .. "]|r";
		elseif (applicantDungeonScoreInfo and applicantDungeonScoreInfo.mapScore ~= 0) then
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
	if (LFGListFrame.SearchPanel.categoryID == GROUP_FINDER_CATEGORY_ID_DUNGEONS) then
		local players = {};
		self:SetSize(125, 24);
		local p1, p2, p3, p4, p5 = self:GetPoint(1);
		self:ClearAllPoints();
		self:SetPoint(p1, p2, p3, -25, p5);
		if (self.LeaderIcon) then
			self.LeaderIcon:Hide();
			self.LeaderIcon:ClearAllPoints();
		else
			local texture = self:CreateTexture(nil, "OVERLAY");
			texture:SetAtlas("groupfinder-icon-leader", false);
			texture:SetSize(self.Icons[1]:GetWidth()-4, 6);
			texture:Hide();
			self.LeaderIcon = texture;
		end
		for i = 1, #self.Icons do
			if (i > numPlayers) then
				self.Icons[i]:Show();
				for _, texture in ipairs(self.Icons[i].Textures) do
					texture:SetDesaturated(disabled);
					texture:SetAlpha(disabled and 0.5 or 1.0);
				end
				self.Icons[i].RoleIcon:SetDesaturated(disabled);
				self.Icons[i].RoleIcon:SetAlpha(disabled and 0.5 or 1.0);
				self.Icons[i].RoleIcon:Hide();
				self.LeaderIcon:SetDesaturated(disabled);
				self.LeaderIcon:SetAlpha(disabled and 0.5 or 1.0);
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
			local isLeader = false;
			if (i == 1) then
				isLeader = true;
			end
			--spec = spec:gsub("%s","");
			table.insert(players, {["role"] = role, ["class"] = classUniversal, ["spec"] = spec, ["isLeader"] = isLeader});
		end
		table.sort(players, sortRoles);
		--Another implementation for evokers
		for i = 1, searchResults.numMembers do
			if (self.LeaderIcon and players[i].isLeader and PGF_ShowLeaderIcon) then
				self.LeaderIcon:SetPoint("TOP", self.Icons[6-i], "TOP", -1, 7);
				self.LeaderIcon:Show();
			end
			if (true or players[i].class == "EVOKER") then
				if (PGF_DetailedDataDisplay) then
					self.Icons[6-i].Textures[3]:SetTexture(select(4, GetSpecializationInfoByID(classSpecilizationMap[players[i].class][players[i].spec])));
					self.Icons[6-i].Textures[3]:SetTexCoord(0,1,0,1);
					self.Icons[6-i].Textures[3]:Show();
					--spec-thumbnail-evoker-preservation?
				else
					self.Icons[6-i].Textures[3]:SetTexture("Interface\\AddOns\\PGFinder\\Res\\" .. players[i].class .. "_" .. players[i].role .. ".tga");
					self.Icons[6-i].Textures[3]:Show();
				end
			else
				self.Icons[6-i].Textures[3]:SetAtlas("GarrMission_ClassIcon-"..strlower(players[i].class).."-"..players[i].spec, false);
				self.Icons[6-i].Textures[3]:Show();
			end
		end
		local count = 1;
		for i = 3, 1, -1 do
			for j = 1, displayData[roleRemainingKeyLookup[iconOrder[i]]] do
				if (PGF_DetailedDataDisplay) then
					self.Icons[count].Textures[3]:SetTexture("Interface\\addons\\PGFinder\\Res\\" .. roleRemainingKeyLookup[iconOrder[i]]);
					self.Icons[count].Textures[3]:SetTexCoord(0,1,0,1);
					self.Icons[count].Textures[3]:Show();
				else
					self.Icons[count].Textures[3]:SetAtlas("groupfinder-icon-emptyslot", false);
					self.Icons[count].Textures[3]:Show();
				end
				count = count + 1;
			end
		end
	end
end

hooksecurefunc("LFGListGroupDataDisplayEnumerate_Update", PGF_LFGListGroupDataDisplayEnumerate_Update);

local function restoreOriginalRoleCountUI(self)
	self:ClearAllPoints();
	self.TankIcon:ClearAllPoints();
	self.HealerIcon:ClearAllPoints();
	self.DamagerIcon:ClearAllPoints();
	self.TankCount:ClearAllPoints();
	self.HealerCount:ClearAllPoints();
	self.DamagerCount:ClearAllPoints();
	self:SetPoint(originalRoleCountUI[self].main[1], originalRoleCountUI[self].main[2], originalRoleCountUI[self].main[3], originalRoleCountUI[self].main[4], originalRoleCountUI[self].main[5]);
	self.TankIcon:SetPoint(originalRoleCountUI[self].tankIcon[1], originalRoleCountUI[self].tankIcon[2], originalRoleCountUI[self].tankIcon[3], originalRoleCountUI[self].tankIcon[4], originalRoleCountUI[self].tankIcon[5]);
	self.HealerIcon:SetPoint(originalRoleCountUI[self].healerIcon[1], originalRoleCountUI[self].healerIcon[2], originalRoleCountUI[self].healerIcon[3], originalRoleCountUI[self].healerIcon[4], originalRoleCountUI[self].healerIcon[5]);
	self.DamagerIcon:SetPoint(originalRoleCountUI[self].damagerIcon[1], originalRoleCountUI[self].damagerIcon[2], originalRoleCountUI[self].damagerIcon[3], originalRoleCountUI[self].damagerIcon[4], originalRoleCountUI[self].damagerIcon[5]);
	self.TankCount:SetPoint(originalRoleCountUI[self].tankCount[1], originalRoleCountUI[self].tankCount[2], originalRoleCountUI[self].tankCount[3], originalRoleCountUI[self].tankCount[4], originalRoleCountUI[self].tankCount[5]);
	self.HealerCount:SetPoint(originalRoleCountUI[self].healerCount[1], originalRoleCountUI[self].healerCount[2], originalRoleCountUI[self].healerCount[3], originalRoleCountUI[self].healerCount[4], originalRoleCountUI[self].healerCount[5]);
	self.DamagerCount:SetPoint(originalRoleCountUI[self].damagerCount[1], originalRoleCountUI[self].damagerCount[2], originalRoleCountUI[self].damagerCount[3], originalRoleCountUI[self].damagerCount[4], originalRoleCountUI[self].damagerCount[5]);
end

--[[
	Documentation: The function is a blizzard function that decides how to display the displayData for groups just showing how many of each role there are numerically (i.e raid groups)
	The hooked version moves the displayData to the left to fit a cancel button to the right of it.

	param(arr/object) - the resultsInset nine slice that contains the information of the group
	param(arr) - keeps the amount of each roles, remaining roles and amount of each classes in the group example ["DAMAGER"] = 1, ["DAMAGER_REMAINING"] = 2, ["MAGE"] = 1
	param(bool) - if the group is delisted
]]

local function PGF_LFGListGroupDataDisplayRoleCount_Update(self, displayData, disabled)
	if (originalRoleCountUI[self] == nil) then
		local tAnchor, tParent, tOffsetAnchor, tOffsetX, tOffsetY = self.TankIcon:GetPoint();
		local hAnchor, hParent, hOffsetAnchor, hOffsetX, hOffsetY = self.HealerIcon:GetPoint();
		local dAnchor, dParent, dOffsetAnchor, dOffsetX, dOffsetY = self.DamagerIcon:GetPoint();
		local tCAnchor, tCParent, tCOffsetAnchor, tCOffsetX, tCOffsetY = self.TankCount:GetPoint();
		local hCAnchor, hCParent, hCOffsetAnchor, hCOffsetX, hCOffsetY = self.HealerCount:GetPoint();
		local dCAnchor, dCParent, dCOffsetAnchor, dCOffsetX, dCOffsetY = self.DamagerCount:GetPoint();
		local anchor, parent, offsetAnchor, offsetX, offsetY = self:GetPoint();
		originalRoleCountUI[self] = {
			["tankIcon"] = {tAnchor, tParent, tOffsetAnchor, tOffsetX, tOffsetY},
			["healerIcon"] = {hAnchor, hParent, hOffsetAnchor, hOffsetX, hOffsetY},
			["damagerIcon"] = {dAnchor, dParent, dOffsetAnchor, dOffsetX, dOffsetY},
			["tankCount"] = {tCAnchor, tCParent, tCOffsetAnchor, tCOffsetX, tCOffsetY},
			["healerCount"] = {hCAnchor, hCParent, hCOffsetAnchor, hCOffsetX, hCOffsetY},
			["damagerCount"] = {dCAnchor, dCParent, dCOffsetAnchor, dCOffsetX, dCOffsetY},
			["main"] = {anchor, parent, offsetAnchor, offsetX-15, offsetY},
		};
	end
	if (LFGListFrame.SearchPanel.categoryID == 3 and (PGF_ShowYourClassAmount or PGF_ShowYourTierAmount)) then
	--	self:SetSize(165, 24);
		local p1, p2, p3, p4, p5 = self:GetPoint(1);
		self:ClearAllPoints();
		self:SetPoint(p1, p2, p3, -75, p5);
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

		self.TankIcon:ClearAllPoints();
		self.TankIcon:SetPoint("LEFT", 50, 0);
		self.HealerIcon:ClearAllPoints();
		self.HealerIcon:SetPoint("RIGHT", self.TankIcon, "RIGHT", 35, 0);
		self.DamagerIcon:ClearAllPoints();
		self.DamagerIcon:SetPoint("RIGHT", self.HealerIcon, "RIGHT", 35, 0);
		self.TankCount:ClearAllPoints();
		self.TankCount:SetPoint("LEFT", self.TankIcon, "LEFT", -14, 0);
		self.HealerCount:ClearAllPoints();
		self.HealerCount:SetPoint("LEFT", self.HealerIcon, "LEFT", -14, 0);
		self.DamagerCount:ClearAllPoints();
		self.DamagerCount:SetPoint("LEFT", self.DamagerIcon, "LEFT", -14, 0);

		local tierCount, classCount, tierText = getTierCount(nil, displayData);
		if (self.ClassIcon) then
			self.TierText:SetTextColor(r, g, b);
			self.ClassIcon:SetDesaturated(disabled);
			self.TierIcon:SetDesaturated(disabled);
			self.ClassIcon:SetAlpha(disabled and 0.5 or 0.70);
			self.TierIcon:SetAlpha(disabled and 0.5 or 0.70);
			if (disabled or RAID_CLASS_COLORS[playerClass] == nil) then
				self.ClassText:SetTextColor(LFG_LIST_DELISTED_FONT_COLOR.r, LFG_LIST_DELISTED_FONT_COLOR.g, LFG_LIST_DELISTED_FONT_COLOR.b);
				self.ClassText:SetText(classCount);
			else
				self.ClassText:SetText(RAID_CLASS_COLORS[playerClass]:WrapTextInColorCode(classCount));
			end
			if (PGF_ShowYourClassAmount) then
				self.ClassText:ClearAllPoints();
				self.ClassText:SetPoint("LEFT", self.TankIcon, "LEFT", -40, 0);
				self.ClassText:Show();

				self.ClassIcon:ClearAllPoints();
				self.ClassIcon:SetPoint("RIGHT", self.ClassText, "RIGHT", 18, 0);
				self.ClassIcon:Show();
			else
				self.ClassText:Hide();
				self.ClassIcon:Hide();
			end

			if (PGF_ShowYourTierAmount) then
				self.TierText:ClearAllPoints();
				self.TierText:SetPoint("RIGHT", self.DamagerIcon, "RIGHT", 14, 0);
				self.TierText:SetText(tierCount);
				self.TierText:Show();

				self.TierIcon:ClearAllPoints();
				self.TierIcon:SetPoint("RIGHT", self.TierText, "RIGHT", 18, 0);
				self.TierIcon:Show();

				self.TierTextInfo:ClearAllPoints();
				self.TierTextInfo:SetPoint("TOP", self.TierIcon, "TOP", 0, 8);
				self.TierTextInfo:SetText(tierText);
				--self.TierTextInfo:Show();
			else
				self.TierText:Hide();
				self.TierIcon:Hide();
				self.TierTextInfo:Hide();
			end

		else
			local fontName, fontHeight, fontFlags = self.DamagerCount:GetFont()
			local classTexture = self:CreateTexture(nil, "OVERLAY");
			local atlas = C_Texture.GetAtlasInfo("classicon-"..playerClass);
			classTexture:SetSize(self.TankIcon:GetWidth(), self.TankIcon:GetHeight());
			classTexture:SetAtlas("groupfinder-icon-class-"..playerClass, false);
			if (playerClass == "EVOKER") then
				classTexture:SetAtlas("classicon-evoker", false);
			end
			classTexture:Hide();
			self.ClassIcon = classTexture;

			local classText = self:CreateFontString(nil, "ARTWORK", "GameFontNormalTiny2");
			classText:SetFont(fontName, fontHeight, fontFlags);
			classText:Hide();
			self.ClassText = classText;

			local tierAmountText= self:CreateFontString(nil, "ARTWORK", "GameFontNormalTiny2");
			tierAmountText:SetFont(fontName, fontHeight, fontFlags);
			tierAmountText:SetTextColor(1,1,1,1);
			tierAmountText:Hide();
			self.TierText = tierAmountText;

			local tierTextInfo = self:CreateFontString(nil, "ARTWORK", "GameFontNormalTiny2");
			tierTextInfo:SetFont(tierAmountText:GetFont(), 8);
			--tierAmountText:SetTextColor(1,1,1,1);
			tierTextInfo:Hide();
			self.TierTextInfo = tierTextInfo;

			local tierTexture = self:CreateTexture(nil, "OVERLAY");
			--tierTexture:SetTexture("Interface\\Icons\\inv_10_jewelcrafting_gem3primal_fire_cut_blue");
			SetPortraitToTexture(tierTexture, "Interface\\Icons\\inv_10_jewelcrafting_gem3primal_fire_cut_blue");
			tierTexture:SetSize(self.DamagerIcon:GetWidth(), self.DamagerIcon:GetHeight());
			tierTexture:Hide();
			self.TierIcon = tierTexture;
		end
	else
		if (self.ClassIcon) then
			self.ClassText:Hide();
			self.ClassIcon:Hide();
			self.TierText:Hide();
			self.TierIcon:Hide();
			self.TierTextInfo:Hide();
		end
		local p1, p2, p3, p4, p5 = self:GetPoint(1);
		self:ClearAllPoints();
		self:SetPoint(p1, p2, p3, p4, p5);
		restoreOriginalRoleCountUI(self);
	end

	local resultID = self:GetParent():GetParent().resultID;
	--[[
		if (not disabled) then
		end
	]]
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
	numResults param(int) - how many results were found after filtering
	time param(int) - the current time of when the filtering was completed
]]
local function updatePerformanceText(numResults, time)
	local calc = string.format("%.3fs", time - performanceTimeStamp);
	if (PGF_SetPerformanceText) then
		PGF_SetPerformanceText("[PGF] Found " .. numResults .. " results in " .. calc);
	end
	performanceTimeStamp = time;
end

--[[
	Documentation: Checks if there are others of the same class in your group

	Payload:
	class param(int) - the class to compare against
	searchResults param(arr) - the searchResults data of the group
	resultID param(int) - the resultID of the group to look up

	Returns (int) - the amount players in the group playing the class "class"
]]
local function getClassCount(class, searchResult, resultID)
	local count = 0;
	if (searchResult == nil) then
		searchResult = C_LFGList.GetSearchResultInfo(resultID);
	end
	for i = 1, searchResult.numMembers do
		local role, classUniversal, classLocal, spec = C_LFGList.GetSearchResultMemberInfo(resultID, i);
		if (class == classUniversal) then
			count = count + 1;
		end
	end
	return count;
end

--[[
	Documentation: This is a blizzard function that decides which results that should be shown by adding them to self as well as how many results there are. Blizzard has a cap on ~100 results so not all results are available here.
	This function overrides the blizzard function and sorts out groups based on the users config. User can filter out groups based on dungeons, bosses, leaderScore and if the group is eligible based on the roles of the player/current group

	Payload:
	self param(table/object) - the LFGListFrame.SearchPanel
	Return:
	bool - true if there are results
]]
function LFGListSearchPanel_UpdateResultList(self)
	if (LFGListFrame.SearchPanel.categoryID == GROUP_FINDER_CATEGORY_ID_DUNGEONS) then
		if(not PGF_FilterRemainingRoles and not PGF_DontShowDeclinedGroups) then
			LFGListFrame.SearchPanel.RefreshButton:SetScript("OnClick", function() end);
			LFGListFrame.SearchPanel.RefreshButton.Icon:SetTexture("Interface\\AddOns\\PGFinder\\Res\\RedRefresh.tga");
			searchAvailable = false;
			self.totalResults, self.results = C_LFGList.GetFilteredSearchResults();
			self.applications = C_LFGList.GetApplications();
			--[[
				for i = 1, #self.results do
					local searchResults = C_LFGList.GetSearchResultInfo(self.results[i]);
					local leaderOverallDungeonScore = searchResults.leaderOverallDungeonScore;
					if (leaderOverallDungeonScore == nil) then
						leaderOverallDungeonScore = 0;
					end
					self.results[i].searchResults.name = name .. " (" .. leaderOverallDungeonScore .. ")";
				end
			]]
			if (self.totalResults > 0) then
				LFGListUtil_SortSearchResults(self.results);
			end
			LFGListSearchPanel_UpdateResults(self);
			updatePerformanceText(self.totalResults, GetTimePreciseSec());
			--declinedGroups = {};
		else
			LFGListFrame.SearchPanel.RefreshButton:SetScript("OnClick", function() end);
			LFGListFrame.SearchPanel.RefreshButton.Icon:SetTexture("Interface\\AddOns\\PGFinder\\Res\\RedRefresh.tga");
			searchAvailable = false;
			self.totalResults, self.results = C_LFGList.GetFilteredSearchResults();
			local newResults = {};
			for i = 1, self.totalResults do
				local searchResults = C_LFGList.GetSearchResultInfo(self.results[i]);
				local activityID = searchResults.activityIDs[1];
				local activityInfo = C_LFGList.GetActivityInfoTable(activityID);
				local activityFullName = activityInfo.fullName;
				local isMythicPlusActivity = activityInfo.isMythicPlusActivity;
				local leaderName = searchResults.leaderName;
				local name = searchResults.name;
				local isDelisted = searchResults.isDelisted;
				local age = searchResults.age;
				local leaderOverallDungeonScore = searchResults.leaderOverallDungeonScore;
				local leaderDungeonScoreInfo = searchResults.leaderDungeonScoreInfo;
				local requiredDungeonScore = searchResults.requiredDungeonScore;
				local _, appStatus, pendingStatus, appDuration = C_LFGList.GetApplicationInfo(self.results[i]);
				if (leaderName == nil) then
					leaderName = "";
				end
				if (declinedGroups[leaderName] and declinedGroups[leaderName].timeout <= GetTime()) then
					declinedGroups[leaderName] = nil;
				end
				if (appStatus == "applied") then
					table.insert(newResults, self.results[i]);
				elseif (PGF_DontShowDeclinedGroups) then
					if ((declinedGroups[leaderName] == nil or declinedGroups[leaderName].activityID ~= activityID) and (requiredDungeonScore == nil or C_ChallengeMode.GetOverallDungeonScore() >= requiredDungeonScore) and (not PGF_FilterRemainingRoles or HasRemainingSlotsForLocalPlayerRole(self.results[i], true))) then
						table.insert(newResults, self.results[i]);
					end
				elseif (PGF_FilterRemainingRoles) then
					if ((requiredDungeonScore == nil or C_ChallengeMode.GetOverallDungeonScore() >= requiredDungeonScore) and HasRemainingSlotsForLocalPlayerRole(self.results[i], true)) then
						table.insert(newResults, self.results[i]);
					end
				end
			end
			self.totalResults = #newResults;
			self.results = newResults;
			if (self.totalResults > 0) then
				LFGListUtil_SortSearchResults(newResults);
			end
			self.applications = C_LFGList.GetApplications();
			LFGListSearchPanel_UpdateResults(self);
			updatePerformanceText(self.totalResults, GetTimePreciseSec());
			return true;
		end
	elseif (LFGListFrame.SearchPanel.categoryID == 3) then
		if((next(selectedInfo.bosses) == nil and raidStateMap[lastSelectedRaidState] ~= 0 and not lastSelectedRaidState:match(" All")) or raidStateMap[lastSelectedRaidState] == 0) then
			LFGListFrame.SearchPanel.RefreshButton:SetScript("OnClick", function() end);
			LFGListFrame.SearchPanel.RefreshButton.Icon:SetTexture("Interface\\AddOns\\PGFinder\\Res\\RedRefresh.tga");
			searchAvailable = false;
			self.totalResults, self.results = C_LFGList.GetFilteredSearchResults();
			self.applications = C_LFGList.GetApplications();
			if (self.totalResults > 0) then
				LFGListUtil_SortSearchResults(self.results);
			end
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
				local activityID = searchResults.activityIDs[1];
				local activityInfo = C_LFGList.GetActivityInfoTable(activityID);
				local activityFullName = activityInfo.fullName;
				local activityShortName = activityFullName:gsub("%s%(.*", "");
				local isMythicPlusActivity = activityInfo.isMythicPlusActivity;
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
				if (lastSelectedRaidState:match(" All")) then
					if (raidStateMap[lastSelectedRaidState] == activityID or raidStateMap[lastSelectedRaidState]-1 == activityID or raidStateMap[lastSelectedRaidState]-2 == activityID) then --raidStateMap[lastSelectedRaidState] is always mythicID, and heroic and normal are also accepted when the user is looking for ANY raid and their aIDs are -1 and -2 from mythic always
						if (next(selectedInfo.bosses) == nil) then
							table.insert(newResults, self.results[i]);
						else
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
											if (isNextBoss(boss_Paths[raidAbbreviations[activityShortName]], bossName, bossesDefeated) and not bossesDefeated[bossName]) then
												table.insert(newResults, self.results[i]);
												break;
											end
										end
									end
								end
							end
						end
					end
				else
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
									if (isNextBoss(boss_Paths[raidAbbreviations[activityShortName]], bossName, bossesDefeated) and not bossesDefeated[bossName]) then
										table.insert(newResults, self.results[i]);
										break;
									end
								end
							end
						end
					end
				end
			end
			self.totalResults = #newResults;
			self.results = newResults;
			if (self.totalResults > 0) then
				LFGListUtil_SortSearchResults(newResults);
			end
			self.applications = C_LFGList.GetApplications();
			LFGListSearchPanel_UpdateResults(self);
			updatePerformanceText(self.totalResults, GetTimePreciseSec());
			return true;
		else
			slowCount = slowCount + 1;
			self.totalResults, self.results = C_LFGList.GetFilteredSearchResults();
			for i = 1, #self.results do
				local searchResults = C_LFGList.GetSearchResultInfo(self.results[i]);
				local activityID = searchResults.activityIDs[1];
				local activityInfo = C_LFGList.GetActivityInfoTable(activityID);
				local activityFullName = activityInfo.fullName;
				local isMythicPlusActivity = activityInfo.isMythicPlusActivity;
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
				self.totalResults = #slowResults;
				self.results = slowResults;
				if (self.totalResults > 0) then
					LFGListUtil_SortSearchResults(slowResults);
				end
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
		if (self.totalResults > 0) then
			LFGListUtil_SortSearchResults(self.results);
		end
		LFGListSearchPanel_UpdateResults(self);
		updatePerformanceText(self.totalResults, GetTimePreciseSec());
		return true;
	end
end
--only goes up to 1400 dungeons currently at 1200 as of 10.1
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
	for i = 1, 2000 do
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

	self param(table/object) -- the resultInset
	resultID param(int) -- the resultID
]]
function LFGListSearchPanel_SelectResult(self, resultID)
	self.selectedResult = resultID;
	LFGListSearchPanel_UpdateResults(self);
	if ((true or PGF_autoSign) and (IsInGroup() == false or UnitIsGroupLeader("player"))) then
		C_LFGList.ApplyToGroup(LFGListFrame.SearchPanel.selectedResult, PGF_roles["TANK"], PGF_roles["HEALER"], PGF_roles["DAMAGER"]);
	end
end
function LFGListUtil_SortSearchResults(results)
	if (results and #results > 0) then
		table.sort(results, LFGListUtil_SortSearchResultsCB);
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
LFDRoleCheckPopup:HookScript("OnShow", function(self)
	local apps = C_LFGList.GetApplications();
	if(IsInGroup(2) or (IsInGroup(1) and not UnitIsGroupLeader("player"))) then
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
			LFDRoleCheckPopupRoleButtonDPS.checkButton:SetChecked(false);
		end
		LFDRoleCheckPopupAcceptButton:Enable();
		LFDRoleCheckPopupAcceptButton:Click();
	else
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
	id1 param(int) - the resultID of the first group
	id2 param(int) - the resutltID of the second group

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
	local hasRemainingRole1 = HasRemainingSlotsForLocalPlayerRole(id1, false);
	local hasRemainingRole2 = HasRemainingSlotsForLocalPlayerRole(id2, false);

	-- Groups with your current role available are preferred
	if (hasRemainingRole1 ~= hasRemainingRole2) then
		return hasRemainingRole1;
	end
	if (LFGListFrame.SearchPanel.categoryID == GROUP_FINDER_CATEGORY_ID_DUNGEONS) then
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
	elseif (LFGListFrame.SearchPanel.categoryID == 3) then
		if (PGF_RaidSortingVariable == 1) then
			if (result1.age ~= result2.age) then
				return result1.age < result2.age;
			end
		elseif (PGF_RaidSortingVariable == 2) then
			local classes1 = getClassCount(playerClass, result1, id1);
			local classes2 = getClassCount(playerClass, result2, id2);
			if (classes1 ~= classes2) then
				return classes1 < classes2;
			end
		elseif (PGF_RaidSortingVariable == 3) then
			local classes1 = getClassCount(playerClass, result1, id1);
			local classes2 = getClassCount(playerClass, result2, id2);
			if (classes1 ~= classes2) then
				return classes1 > classes2;
			end
		elseif (PGF_RaidSortingVariable == 4) then
			local tierClasses1 = getTierCountBySearchResult(playerClass, result1, id1);
			local tierClasses2 = getTierCountBySearchResult(playerClass, result2, id2);
			if (tierClasses1 ~= tierClasses2) then
				return tierClasses1 < tierClasses2;
			end
		elseif (PGF_RaidSortingVariable == 5) then
			local tierClasses1 = getTierCountBySearchResult(playerClass, result1, id1);
			local tierClasses2 = getTierCountBySearchResult(playerClass, result2, id2);
			if (tierClasses1 ~= tierClasses2) then
				return tierClasses1 > tierClasses2;
			end
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