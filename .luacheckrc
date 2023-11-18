std = "lua51"
max_line_length = false
codes = true
exclude_files = {
	".luacheckrc",
	"CHANGELOG.md",
}
ignore = {
	"11./SLASH_.*",
	"211",
	"212",
	"213",
}
not_globals = {
	"arg"
}
globals = {
	--LUA
    "bit",
    "strlower",
	"table.insert",
	"table.remove",

	--WoW API
    "Ambiguate",
    "C_ChallengeMode",
    "C_ChatInfo",
    "C_LFGList",
    "C_Texture",
    "C_Timer",
    "ClearAllPoints",
    "CreateFrame",
    "GetAchievementLink",
    "GetAchievementInfo",
    "GetAddOnMetadata",
    "GetHeight",
    "GetLFGDungeonInfo",
    "GetLocale",
    "GetNumGroupMembers",
    "GetParent",
    "GetPoint",
    "GetSpecialization",
    "GetSpecializationInfoByID",
    "GetSpecializationRole",
    "GetTexCoordsForRole",
    "GetTimePreciseSec",
    "GetWidth",
    "Hide",
    "hooksecurefunc",
    "IsInGroup",
    "LFGListEntryCreation_SetTitleFromActivityInfo",
    "LFGListGroupDataDisplay_Update",
    "LFGListSearchPanel_Clear",
    "LFGListSearchPanel_SelectResult",
    "LFGListSearchPanel_UpdateButtonStatus",
    "LFGListSearchPanel_UpdateResults",
    "LFGListSearchPanel_UpdateResultList",
    "LFGListUtil_SortSearchResults",
    "LFGListUtil_SortSearchResultsCB",
    "SetAlpha",
    "SetAtlas",
    "SetDesaturated",
    "SetJustifyH",
    "SetPoint",
    "SetPortraitToTexture",
    "SetScript",
    "SetShown",
    "SetSize",
    "SetTexCoord",
    "SetText",
    "SetTextColor",
    "SetTexture",
    "Show",
    "UnitIsConnected",
    "UnitIsGroupLeader",
    "UnitGroupRolesAssigned",
    "UnitName",

	--WoW UI
    "GameFontNormalTiny2",
    "GameTooltip",
    "LFDRoleCheckPopupAcceptButton",
    "LFDRoleCheckPopupRoleButtonDPS",
    "LFDRoleCheckPopupRoleButtonHealer",
    "LFDRoleCheckPopupRoleButtonTank",
    "LFGListApplicationDialog",
    "LFGListFrame",
    "PVEFrame",
    "PVEFrameBg",
    "PVEFrameTitleText",

	--WoW ENUMs
    "Enum",
    "ERR_FRIEND_ONLINE_SS",
    "GROUP_FINDER_CATEGORY_ID_DUNGEONS",
	"HIGHLIGHT_FONT_COLOR",
	"LFG_LIST_DELISTED_FONT_COLOR",
    "LFG_LIST_MUST_SIGN_UP_TO_WHISPER",
    "PVE_FRAME_BASE_WIDTH",

    --PGF Functions
    "PGF_DevGenerateAllActivityIDs",
    "PGF_DontShowDeclinedGroups",
    "PGF_DontShowMyClass",
    "PGF_DungeonState_OnClick",
    "PGF_FilterRemainingRoles",
    "PGF_GetPlaystyleString",
    "PGF_LFGListGroupDataDisplayPlayerCount_Update",
    "PGF_OnlyShowMyRole2",
    "PGF_RaidSortingVariable",
    "PGF_SetPerformanceText",
    "PGF_ShowLeaderDungeonKey",
    "PGF_ShowYourClassAmount",
    "PGF_ShowYourTierAmount",

    --PGF SavedVariables
    "PGF_autoSign",
    "PGF_roles",

    --PGF Variables
    "PGF_allDungeonsActivityIDs",
    "PGF_allRaidActivityIDs",
    "PGF_DevAllActivityIDs",
    "PGF_DevDungeonsActivityIDs",
    "PGF_DevRaidActivityIDs",
    "PGFinderLocals",
}