if GetLocale() ~= "deDE" then return end
PGFinderLocals = {}
local L = PGFinderLocals
local addon = ...

SLASH_PREMADEGROUPFINDER1 = "/pgf"
SLASH_PREMADEGROUPFINDER2 = "/premadefinder"
SLASH_PREMADEGROUPFINDER3 = "/premadegroupfinder"

L.OPTIONS_TITLE = "Premade Group Finder"
L.OPTIONS_AUTHOR = "Autor: " .. GetAddOnMetadata(addon, "Author") 
L.OPTIONS_VERSION = "Version: " .. GetAddOnMetadata(addon, "Version")
L.OPTIONS_FRIENDS = "Freundesliste"
L.OPTIONS_KEYWORDS = "Suchbegriff"
L.OPTIONS_ENABLED = "Aktivierung"
L.OPTIONS_AUTO_SIGN = "automatische Anmeldung"
L.OPTIONS_SEARCH_LOGIN_TEXT = "automatische suche nach dem Einloggen."
L.OPTIONS_NOTIFICATIONS = "Mitteilung: "
L.OPTIONS_WHISPER_NOTIFICATION = "Mitteilung flüstern "
L.OPTIONS_SOUND_NOTIFICATION = "Musik Mitteilung "
L.OPTIONS_GUILD_NOTIFICATION_TEXT = "Gilden Mitteilung"
L.OPTIONS_INTERVAL = "Wiederholraten (in Sekunden): "
L.OPTIONS_BUTTON_TEXT = "Hinzufügen/Löschen"
L.OPTIONS_ROLE = "Sign up as:"
L.OPTIONS_POPUP = "Visual notification"

L.NOTIFICATION_YOU = "PGF: Eine Gruppe wurde gefunden: "
L.NOTIFICATION_FRIENDS_1 = "PGF: Eine Premade Gruppe, welche  "
L.NOTIFICATION_FRIENDS_2 = " verfolgt, ist gefunden worden. Bitte stellen Sie sicher, dass Ihre Freunde in Kenntnis genommen werden. "
L.NOTIFICATION_GUILD = "PGF: hat eine Gruppe gefunden: "
L.NOTIFICATION_POPUP = "A group has been found!"

L.WARNING_ENABLED_TEXT = "PGF: ist aktiviert!"
L.WARNING_DISABLED_TEXT = "PGF: ist deaktiviert!"
L.WARNING_UNELIGIBLE_TEXT = "PGF: PGF kann Sie nicht anmelden, da Sie nicht der Anführer dieser Gruppe oder Raid sind."
L.WARNING_SEARCH_LOGIN_TEXT = " PGF: hat angefangen eine Premade Gruppe, mit ihrem letzten Suchbegriff, zu suchen."
L.WARNING_LOGIN_TEXT = "Premade Group Finder " .. GetAddOnMetadata(addon, "Version") .. " wurde geladen!"
L.WARNING_CHANGED_CATEGORY = "PGF: sucht im: "