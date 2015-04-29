#include-once
#cs
; this allow easy file data overwrite via simple IniWrite
[Data]
#ce

Global Const $MM_PORTABLE = False
Global Const $MM_VERSION_NUMBER = "0.93.3.0"

Global Const $MM_VERSION_SUBTYPE = "beta"
Global Const $MM_VERSION_NAME = "Siege Engine"
Global Const $MM_VERSION = $MM_VERSION_SUBTYPE == "release" ? $MM_VERSION_NUMBER : ($MM_VERSION_NUMBER & "." & $MM_VERSION_SUBTYPE)

Global Const $MM_UPDATE_URL = "http://wakeofgods.org/mm"

Global Const $MM_TITLE = StringFormat("Era II Mod Manager [%s - %s]%s", $MM_VERSION, $MM_VERSION_NAME, $MM_PORTABLE ? "{Portable}" : "")
Global Const $MM_WINDOW_MIN_WIDTH = 800
Global Const $MM_WINDOW_MIN_HEIGHT = 494

Global Const $MM_WOG_OPTIONS_FILE = "WoGSetupMM.dat"

Global Enum $MM_VIEW_MODS, $MM_VIEW_PLUGINS, $MM_VIEW_INSTALL, $MM_VIEW_BIG_SCREEN, $MM_VIEW_SCN, $MM_VIEW_TOTAL
Global Enum $MM_SUBVIEW_DESC, $MM_SUBVIEW_INFO, $MM_SUBVIEW_SCREENS, $MM_SUBVIEW_BLANK, $MM_SUBVIEW_TOTAL

Global Enum $PLUGIN_GROUP_GLOBAL, $PLUGIN_GROUP_BEFORE, $PLUGIN_GROUP_AFTER
Global Enum $PLUGIN_FILENAME, $PLUGIN_PATH, $PLUGIN_GROUP, $PLUGIN_CAPTION, $PLUGIN_DESCRIPTION, $PLUGIN_STATE, $PLUGIN_DEFAULT_STATE, $PLUGIN_TOTAL

Global Enum $MOD_ID, $MOD_CAPTION, $MOD_IS_ENABLED, $MOD_IS_EXIST, $MOD_ITEM_ID, $MOD_PARENT_ID, $MOD_TOTAL

Global Enum $MM_LNG_FILE, $MM_LNG_CODE, $MM_LNG_NAME, $MM_LNG_MENU_ID, $MM_LNG_TOTAL
Global Enum $SCN_LIST
