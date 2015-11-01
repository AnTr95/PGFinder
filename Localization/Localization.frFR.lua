if GetLocale() ~= "frFR" then return end
PGFinderLocals = {}
local L = PGFinderLocals
local addon = ...

SLASH_PREMADEGROUPFINDER1 = "/pgf"
SLASH_PREMADEGROUPFINDER2 = "/premadefinder"
SLASH_PREMADEGROUPFINDER3 = "/premadegroupfinder"

L.OPTIONS_TITLE = "Premade Group Finder"
L.OPTIONS_AUTHOR = "Auteur: " .. GetAddOnMetadata(addon, "Author")
L.OPTIONS_VERSION = "Version: " .. GetAddOnMetadata(addon, "Version")
L.OPTIONS_FRIENDS = "Vos amis"
L.OPTIONS_KEYWORDS = "Vos mots-clefs"
L.OPTIONS_ENABLED = "Activ�"
L.OPTIONS_AUTO_SIGN = "Inscription automatique"
L.OPTIONS_NOTIFICATIONS = "Notifications:"
L.OPTIONS_WHISPER_NOTIFICATION = "Notification par chuchotement"
L.OPTIONS_SOUND_NOTIFICATION = "Notification sonore"
L.OPTIONS_INTERVAL = "Taux de rafra�chissement (en secondes):"
L.OPTIONS_BUTTON_TEXT = "Ajouter/Retirer"

L.NOTIFICATION_YOU_1 = "PGF : Un groupe correspondant � votre mot-clef a �t� trouv�"
L.NOTIFICATION_YOU_2 = "Nom du groupe: "
L.NOTIFICATION_FRIENDS_1 = "Un groupe que "
L.NOTIFICATION_FRIENDS_2 = " recherche a �t� trouv�. Veuillez notifier votre ami. Nom du groupe: "

L.WARNING_ENABLED_TEXT = "PGF : a �t� activ�!"
L.WARNING_DISABLED_TEXT = "PGF : a �t� d�sactiv�!"
L.WARNING_UNELIGIBLE_TEXT = "Impossible de vous inscrire car vous n��tes pas le chef du groupe/raid"