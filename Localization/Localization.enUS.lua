PGFinderLocals = {};
local L = PGFinderLocals;
local addon = ...;

SLASH_PREMADEGROUPFINDER1 = "/pgf"
SLASH_PREMADEGROUPFINDER2 = "/premadefinder"
SLASH_PREMADEGROUPFINDER3 = "/premadegroupfinder"

L.OPTIONS_TITLE = "Premade Group Finder";
L.OPTIONS_AUTHOR = "Author: " .. GetAddOnMetadata(addon, "Author");
L.OPTIONS_VERSION = "Version: " .. GetAddOnMetadata(addon, "Version");
L.OPTIONS_ROLE = "Sign up as:";
L.OPTIONS_MIN_LEADER_SCORE = "Min. Leader Score:";
L.OPTIONS_DUNGEON_DIFFICULTY = "Difficulty";
L.OPTIONS_RAID_SELECT = "Select Raid";
L.OPTIONS_BLIZZARD_SEARCH_INFO = "Blizzard caps all search results to ~100 so the more specific you can be in the search the more results you will get.\n\n For example adding key levels, selecting 1 dungeon/raid because then it searches for only that activity. This cap exists even in their own version without addons.";
L.OPTIONS_REFRESH_BUTTON_DISABLED = "New Refresh Available In: ";

L.SPEC_BLOOD = "Blood";
L.SPEC_FROST = "Frost";
L.SPEC_UNHOLY = "Unholy";
L.SPEC_HAVOC = "Havoc";
L.SPEC_VENGENACE = "Vengeance";
L.SPEC_BALANCE = "Balance";
L.SPEC_FERAL = "Feral";
L.SPEC_GUARDIAN = "Guardian";
L.SPEC_RESTORATION = "Restoration";
L.SPEC_DEVASTATION = "Devastation";
L.SPEC_PRESERVATION = "Preservation";
L.SPEC_BEASTMASTERY = "Beast Mastery";
L.SPEC_MARKSMANSHIP = "Marksmanship";
L.SPEC_SURVIVAL = "Survival";
L.SPEC_ARCANE = "Arcane";
L.SPEC_FIRE = "Fire";
L.SPEC_BREWMASTER = "Brewmaster";
L.SPEC_WINDWALKER = "Windwalker";
L.SPEC_MISTWEAVER = "Mistweaver";
L.SPEC_HOLY = "Holy";
L.SPEC_PROTECTION = "Protection";
L.SPEC_RETRIBUTION = "Retribution";
L.SPEC_DISCIPLINE = "Discipline";
L.SPEC_SHADOW = "Shadow";
L.SPEC_ASSASSINATION = "Assassination";
L.SPEC_OUTLAW = "Outlaw";
L.SPEC_SUBTLETY = "Subtlety";
L.SPEC_ELEMENTAL = "Elemental";
L.SPEC_ENHANCEMENT = "Enhancement";
L.SPEC_AFFLICTION = "Affliction";
L.SPEC_DEMONOLOGY = "Demonology";
L.SPEC_DESTRUCTION = "Destruction";
L.SPEC_ARMS = "Arms";
L.SPEC_FURY = "Fury";

L.WARNING_OUTOFDATEMESSAGE = "There is a newer version of Premade Group Finder available on curse!";

L.ADDON = "PGF: ";

L.FORTIFIED = "Fortified";
L.TYRANNICAL = "Tyrannical";
