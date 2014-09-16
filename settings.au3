; Author:         Aliaksei SyDr Karalenka

;~ #include <File.au3>
#include <GUIConstantsEx.au3>

#include "lng.au3"

#include-once


Func Settings_GUI($hParentGUI)
	Local $iTotalCheck = 2
	Local $iBaseOffset = 8
	Local $bVersion = False

	Local $hGUI = GUICreate(Lng_Get("settings.title"), 300, 2 * $iBaseOffset + $iTotalCheck * 17, Default, Default, Default, Default, $hParentGUI)

	Local $hVersion = GUICtrlCreateCheckbox(Lng_Get("settings.checkbox.display_version"), $iBaseOffset + 1, $iBaseOffset + 1 + (0) * 17)
	If Settings_Get("DisplayVersion") Then GUICtrlSetState($hVersion, $GUI_CHECKED)

	Local $hSync = GUICtrlCreateCheckbox(Lng_Get("settings.checkbox.sync_preset"), $iBaseOffset + 1, $iBaseOffset + 1 + (1) * 17)
	GUICtrlSetTip($hSync, StringFormat(Lng_Get("settings.checkbox.sync_preset.hint"), "0_O"))
	If Settings_Get("SyncPresetWithWS") Then GUICtrlSetState($hSync, $GUI_CHECKED)

	GUISetState(@SW_SHOW)


	While True
		Sleep(50)

        Switch GUIGetMsg()
            Case $GUI_EVENT_CLOSE
                ExitLoop
			Case $hVersion
				$bVersion = Not $bVersion

				If BitAND(GUICtrlRead($hVersion), $GUI_CHECKED) Then
					Settings_Set("DisplayVersion", "1")
				Else
					Settings_Set("DisplayVersion", "")
				EndIf
			Case $hSync
				If BitAND(GUICtrlRead($hSync), $GUI_CHECKED) Then
					Settings_Set("SyncPresetWithWS", "1")
				Else
					Settings_Set("SyncPresetWithWS", "")
				EndIf
        EndSwitch
	WEnd

	GUIDelete($hGUI)

	If $bVersion Then
		Return 1
	Else
		Return 0
	EndIf
EndFunc   ;==>Settings_GUI

Func Settings_Get($sName)
	Switch $sName
		Case "Language"
			Local $sLanguage = IniRead($MM_SETTINGS_PATH, "settings", "Language", "english.ini")
			If $sLanguage = "" Then $sLanguage = "english.ini"
			Return $sLanguage
		Case "Exe"
			Local $sExe = IniRead($MM_SETTINGS_PATH, "settings", "Exe", "h3era.exe")
			If $sExe = "" Then $sExe = "h3era.exe"
			Return $sExe
		Case "Width"
			Local $iWidth = IniRead($MM_SETTINGS_PATH, "settings", "Width", $MM_WINDOW_MIN_WIDTH)
			If $iWidth < $MM_WINDOW_MIN_WIDTH Then $iWidth = $MM_WINDOW_MIN_WIDTH
			Return $iWidth
		Case "Height"
			Local $iHeight = IniRead($MM_SETTINGS_PATH, "settings", "Height", $MM_WINDOW_MIN_HEIGHT)
			If $iHeight < $MM_WINDOW_MIN_HEIGHT Then $iHeight = $MM_WINDOW_MIN_HEIGHT
			Return $iHeight
		Case "Maximized"
			Return Int(IniRead($MM_SETTINGS_PATH, "settings", "Maximized", "")) <> 0
		Case "SyncPresetWithWS"
			Return IniRead($MM_SETTINGS_PATH, "settings", "SyncPresetWithWS", "")
		Case "DisplayVersion"
			Return IniRead($MM_SETTINGS_PATH, "settings", "DisplayVersion", True)
	EndSwitch
EndFunc   ;==>Settings_Get

Func Settings_Set($sName, $vValue)
	Switch $sName
		Case "SyncPresetWithWS"
			Return IniWrite($MM_SETTINGS_PATH, "settings", "SyncPresetWithWS", $vValue)
		Case "DisplayVersion"
			Return IniWrite($MM_SETTINGS_PATH, "settings", "DisplayVersion", $vValue)
		Case "Language"
			Return IniWrite($MM_SETTINGS_PATH, "settings", "Language", $vValue)
		Case "Exe"
			Return IniWrite($MM_SETTINGS_PATH, "settings", "Exe", $vValue)
		Case "Width"
			Return IniWrite($MM_SETTINGS_PATH, "settings", "Width", $vValue)
		Case "Height"
			Return IniWrite($MM_SETTINGS_PATH, "settings", "Height", $vValue)
		Case "Maximized"
			Return IniWrite($MM_SETTINGS_PATH, "settings", "Maximized", $vValue)
	EndSwitch
EndFunc   ;==>Settings_Set
