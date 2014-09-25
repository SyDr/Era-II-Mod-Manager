; Author:         Aliaksei SyDr Karalenka

;~ #include <File.au3>
#include <GUIConstantsEx.au3>

#include "lng.au3"

#include-once


Func Settings_Get($sName)
	Switch $sName
		Case "Language"
			Local $sLanguage = IniRead($MM_SETTINGS_PATH, "settings", "Language", "english.ini")
			If $sLanguage = "" Then $sLanguage = "english.ini"
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
	EndSwitch
EndFunc   ;==>Settings_Set
