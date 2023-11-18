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
	"table.insert",
	"table.remove",
    
	--WoW API
    "C_ChallengeMode",
    "C_LFGList",
    "C_Texture",
    "GetLFGDungeonInfo",
    "GetLocale",
    "GetTexCoordsForRole",
    "hooksecurefunc",
    "LFGListEntryCreation_SetTitleFromActivityInfo",
    "LFGListSearchPanel_Clear",
    "LFGListSearchPanel_SelectResult",
    "LFGListSearchPanel_UpdateResultList",
    "LFGListUtil_SortSearchResults",
    "LFGListUtil_SortSearchResultsCB",
    "SetPortraitToTexture",
    
	--WoW UI
    "GameFontNormalTiny2",
    "LFDRoleCheckPopupAcceptButton",
    "LFDRoleCheckPopupRoleButtonDPS",
    "LFDRoleCheckPopupRoleButtonHealer",
    "LFDRoleCheckPopupRoleButtonTank",
    "LFGListApplicationDialog",
    "PVEFrameBg",
    "PVEFrameTitleText",
    
	--WoW ENUMs
    "Enum",
    "GROUP_FINDER_CATEGORY_ID_DUNGEONS",
	"HIGHLIGHT_FONT_COLOR",
	"LFG_LIST_DELISTED_FONT_COLOR",
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
    "PGF_DevAllActivityIDs",
    "PGF_DevDungeonsActivityIDs",
    "PGF_DevRaidActivityIDs",
}