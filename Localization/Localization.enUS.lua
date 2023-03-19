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
L.OPTIONS_DUNGEON_DIFFICULTY = "Dungeon Difficulty";
L.OPTIONS_RAID_SELECT = "Select Raid";
L.OPTIONS_BLIZZARD_SEARCH_INFO = "Blizzard caps all search results to ~100 so the more specific you can be in the search the more results you will get.\n\n For example adding key levels, selecting 1 dungeon/raid because then it searches for only that activity. This cap exists even in their own version without addons.";
L.OPTIONS_REFRESH_BUTTON_DISABLED = "New Refresh Available In: ";

L.ADDON = "PGF: ";