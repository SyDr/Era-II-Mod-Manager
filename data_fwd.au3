#AutoIt3Wrapper_Version=Beta
#include-once
#include <File.au3>
#include "const.au3"

Global $MM_GAME_NO_DIR = False
Global $MM_GAME_DIR = _PathFull(@ScriptDir & "\..\..")
Global $MM_GAME_EXE = "h3era.exe"

Global $MM_LIST_DIR_PATH = $MM_GAME_DIR & "\Mods"
Global $MM_LIST_FILE_PATH = $MM_LIST_DIR_PATH & "\list.txt"

Global $MM_DATA_DIRECTORY = $MM_PORTABLE ? @ScriptDir : @AppDataCommonDir & "\RAMM"
Global $MM_SETTINGS_PATH = $MM_DATA_DIRECTORY & "\settings.json"

Global $MM_SETTINGS_LANGUAGE = "english.json"
Global $MM_LANGUAGE_CODE = "en_US"

Global $MM_WINDOW_WIDTH = $MM_WINDOW_MIN_WIDTH
Global $MM_WINDOW_HEIGHT = $MM_WINDOW_MIN_HEIGHT
Global $MM_WINDOW_MAXIMIZED = False
Global $MM_WINDOW_MIN_WIDTH_FULL
Global $MM_WINDOW_MIN_HEIGHT_FULL
Global $MM_WINDOW_CLIENT_WIDTH, $MM_WINDOW_CLIENT_HEIGHT

Global $MM_LNG_LIST[1][$MM_LNG_TOTAL] ; filename, lang code, lang full name

Global $MM_VIEW_CURRENT, $MM_SUBVIEW_CURRENT, $MM_VIEW_PREV, $MM_SUBVIEW_PREV

Global $MM_LIST_FILE_CONTENT ; folder_mods.au3
Global $MM_LIST_CONTENT[1][$MOD_TOTAL] ; a loaded list of mods
Global $MM_LIST_MAP ; a list with mapped data
Global $MM_LIST_CANT_WORK = False

Global $MM_PLUGINS_CONTENT[1][$PLUGIN_TOTAL] ; a loaded list of plugins
Global $MM_PLUGINS_PART_PRESENT[3] ; state if a plugins from some group exist

Global $MM_LIST_COMPATIBILITY[]
Global $MM_COMPATIBILITY_MESSAGE = ""

Global $MM_UI_MAIN

Global $MM_UPDATE[2] ; type (0 - none/wait for update, 1 - info, 2 - setup, 3 - complete), download handle
