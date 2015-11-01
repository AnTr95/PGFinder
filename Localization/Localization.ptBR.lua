if GetLocale() ~= "ptBR" then return end
PGFinderLocals = {}
local L = PGFinderLocals
local addon = ...

SLASH_PREMADEGROUPFINDER1 = "/pgf"
SLASH_PREMADEGROUPFINDER2 = "/premadefinder"
SLASH_PREMADEGROUPFINDER3 = "/premadegroupfinder"

L.OPTIONS_TITLE = "Premade Group Finder"
L.OPTIONS_AUTHOR = "Autor: " .. GetAddOnMetadata(addon, "Author") 
L.OPTIONS_VERSION = "Vers�o: " .. GetAddOnMetadata(addon, "Version")
L.OPTIONS_FRIENDS = "Os teus amigos"
L.OPTIONS_KEYWORDS = "As tuas palavras-chave"
L.OPTIONS_ENABLED = "Activado"
L.OPTIONS_AUTO_SIGN = "Inscrever automaticamente"
L.OPTIONS_SEARCH_LOGIN_TEXT = "Start searching on login"
L.OPTIONS_NOTIFICATIONS = "Notifica��es: "
L.OPTIONS_WHISPER_NOTIFICATION = "Notifica��es privadas"
L.OPTIONS_SOUND_NOTIFICATION = "Notifica��o Sonora"
L.OPTIONS_INTERVAL = "Taxa de refresh (em segundos):"
L.OPTIONS_BUTTON_TEXT = "Adicionar/Remover"

L.NOTIFICATION_YOU_1 = "PGF: foi encontrado um grupo com a tua palavra-chave: "
L.NOTIFICATION_YOU_2 = " Nome do grupo: "
L.NOTIFICATION_FRIENDS_1 = "PGF: um grupo personalizado que "
L.NOTIFICATION_FRIENDS_2 = " est� � procura foi encontrado. Por favor confirma com o teu/tua amigo/a que receberam a mensagem. Nome do grupo: "

L.WARNING_ENABLED_TEXT = "PGF: foi activado!"
L.WARNING_DISABLED_TEXT = "PGF: foi desactivado!"
L.WARNING_UNELIGIBLE_TEXT = "PGF: n�o foi possivel inscrever-te j� que n�o �s o lider do grupo/raid."