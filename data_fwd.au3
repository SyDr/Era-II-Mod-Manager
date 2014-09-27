#include "const.au3"

#include-once

Global $MM_LIST_DIR_PATH = @ScriptDir & "\..\..\Mods"
Global $MM_LIST_FILE_PATH = $MM_LIST_DIR_PATH & "\list.txt"

Global $MM_SETTINGS_PATH = @ScriptDir & "\settings.ini"
Global $MM_SETTINGS_LANGUAGE = "english.ini"

Global $MM_WINDOW_WIDTH = $MM_WINDOW_MIN_WIDTH
Global $MM_WINDOW_HEIGHT = $MM_WINDOW_MIN_HEIGHT
Global $MM_WINDOW_MAXIMIZED = False
Global $MM_WINDOW_MIN_WIDTH_FULL
Global $MM_WINDOW_MIN_HEIGHT_FULL

Global $MM_LNG_CACHE ; lng.au3

Global $MM_VIEW_CURRENT

Global $MM_LIST_FILE_CONTENT ; folder_mods.au3
Global $MM_LIST_CONTENT[1][10] ; a loaded list of mods

Global $MM_PLUGINS_CONTENT[1][$PLUGIN_TOTAL] ; a loaded list of plugins
Global $MM_PLUGINS_PART_PRESENT[3] ; state if a plugins from some group exist