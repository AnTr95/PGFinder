if GetLocale() ~= "esES" then return end
PGFinderLocals = {}
local L = PGFinderLocals
local addon = ...

SLASH_PREMADEGROUPFINDER1 = "/pgf"
SLASH_PREMADEGROUPFINDER2 = "/premadefinder"
SLASH_PREMADEGROUPFINDER3 = "/premadegroupfinder"

L.OPTIONS_TITLE = "Premade Group Finder"
L.OPTIONS_AUTHOR = "Autor: " .. GetAddOnMetadata(addon, "Author") 
L.OPTIONS_VERSION = "Versión: " .. GetAddOnMetadata(addon, "Version")
L.OPTIONS_FRIENDS = "Tus amigos"
L.OPTIONS_KEYWORDS = "Tus palabras clave"
L.OPTIONS_ENABLED = "Activado"
L.OPTIONS_AUTO_SIGN = "Inscribirse automáticamente" 
L.OPTIONS_NOTIFICATIONS = "Notificaciones: "
L.OPTIONS_WHISPER_NOTIFICATION = "Notificaciones con susurros" -- Much better in the given context. :)
L.OPTIONS_SOUND_NOTIFICATION = "Notificaciones con sonidos" -- Much better in the given context. :)
L.OPTIONS_INTERVAL = "Frecuencia de actualización (en segundos): "
L.OPTIONS_BUTTON_TEXT = "Añadir/Eliminar"

L.NOTIFICATION_YOU_1 = "PGF: Ha sido encontrado un grupo con tu palabra clave: "
L.NOTIFICATION_YOU_2 = " Nombre del grupo: "
L.NOTIFICATION_FRIENDS_1 = "PGF: Un grupo personalizado que "
L.NOTIFICATION_FRIENDS_2 = " está siguiendo ha sido encontrado. Por favor, confirma que tu amigo/a ha visto este mensaje. Nombre del grupo: "

L.WARNING_ENABLED_TEXT = "PGF: Se ha activado PGF."
L.WARNING_DISABLED_TEXT = "PGF: Se ha desactivado PGF."
L.WARNING_UNELIGIBLE_TEXT = "PGF: No ha sido posible inscribirte porque no eres el lider de un grupo."