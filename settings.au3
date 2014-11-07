; Author:         Aliaksei SyDr Karalenka

#AutoIt3Wrapper_Version=Beta
#include-once
#include "include_fwd.au3"
#include "lng.au3"

Func Settings_Get($sName)
	Switch $sName
		Case "Language"
			Local $sLanguage = IniRead($MM_SETTINGS_PATH, "settings", "Language", $MM_SETTINGS_LANGUAGE)
			If $sLanguage = "" Then $sLanguage = $MM_SETTINGS_LANGUAGE
			Return $sLanguage
		Case "Width"
			Local $iWidth = Int(IniRead($MM_SETTINGS_PATH, "settings", "Width", $MM_WINDOW_MIN_WIDTH))
			If $iWidth < $MM_WINDOW_MIN_WIDTH Then $iWidth = $MM_WINDOW_MIN_WIDTH
			Return $iWidth
		Case "Height"
			Local $iHeight = Int(IniRead($MM_SETTINGS_PATH, "settings", "Height", $MM_WINDOW_MIN_HEIGHT))
			If $iHeight < $MM_WINDOW_MIN_HEIGHT Then $iHeight = $MM_WINDOW_MIN_HEIGHT
			Return $iHeight
		Case "Maximized"
			Return Int(IniRead($MM_SETTINGS_PATH, "settings", "Maximized", "")) <> 0
		Case "Portable"
			Return Int(IniRead($MM_SETTINGS_PATH, "settings", "Portable", "")) <> 0
		Case "Path"
			Return Settings_Get("Portable") ? _PathFull(@ScriptDir & "\..\..") : IniRead($MM_SETTINGS_PATH, "settings", "Path", "")
	EndSwitch
EndFunc   ;==>Settings_Get

Func Settings_Set($sName, $vValue)
	Switch $sName
		Case "Language"
			Return IniWrite($MM_SETTINGS_PATH, "settings", "Language", $vValue)
		Case "Width"
			Return IniWrite($MM_SETTINGS_PATH, "settings", "Width", $vValue)
		Case "Height"
			Return IniWrite($MM_SETTINGS_PATH, "settings", "Height", $vValue)
		Case "Maximized"
			Return IniWrite($MM_SETTINGS_PATH, "settings", "Maximized", $vValue)
		Case "Path"
			Return IniWrite($MM_SETTINGS_PATH, "settings", "Path", $vValue)
	EndSwitch
EndFunc   ;==>Settings_Set

Func Settings_DefineWorkDir()
	If Not Settings_Get("Portable") Then
		$MM_SETTINGS_PATH = @AppDataCommonDir & "\RAMM\settings.ini"
		FileClose(FileOpen($MM_SETTINGS_PATH, $FO_APPEND + $FO_CREATEPATH))
	EndIf

	If Settings_Get("Path") = "" Then
		$MM_SETTINGS_LANGUAGE = Settings_Get("Language")
		Setting_AskForGameDir(True)
	Else
		$MM_GAME_DIR = Settings_Get("Path")
		$MM_LIST_DIR_PATH = $MM_GAME_DIR & "\Mods"
		$MM_LIST_FILE_PATH = $MM_LIST_DIR_PATH & "\list.txt"
	EndIf
EndFunc

Func Setting_AskForGameDir($bExitOnCancel = False, $hParent = Default)
	Local $sPath = FileSelectFolder(Lng_Get("settings.game_dir.caption"), "", Default, Settings_Get("Path"), $hParent)
	If @error Then
		If $bExitOnCancel Then Exit
		Return 0
	Else
		$MM_GAME_DIR = $sPath
		Settings_Set("Path", $sPath)
		$MM_LIST_DIR_PATH = $MM_GAME_DIR & "\Mods"
		$MM_LIST_FILE_PATH = $MM_LIST_DIR_PATH & "\list.txt"
	EndIf

	Return 1
EndFunc

