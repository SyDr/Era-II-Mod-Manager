; Author:         Aliaksei SyDr Karalenka

#include <File.au3>
#include <GUIConstantsEx.au3>

#include "lng.au3"

#include-once


Func Settings_GUI($hParentGUI)
	Local $iTotalCheck = 2
	Local $hVersion, $hSync
	Local $iBaseOffset = 8
	Local $hGUI, $msg
	Local $bVersion = False, $bIcons = False

	$hGUI = GUICreate(Lng_Get("settings.title"), 300, $iBaseOffset + $iTotalCheck * 17 + 8, Default, Default, Default, Default, $hParentGUI)
	GUISetState(@SW_SHOW)

	$hVersion = GUICtrlCreateCheckbox(Lng_Get("settings.checkbox.display_version"), $iBaseOffset + 1, $iBaseOffset + 1 + (0) * 17)
	If Settings_Get("DisplayVersion") Then GUICtrlSetState($hVersion, $GUI_CHECKED)

	$hSync = GUICtrlCreateCheckbox(Lng_Get("settings.checkbox.sync_preset"), $iBaseOffset + 1, $iBaseOffset + 1 + (1) * 17)
	GUICtrlSetTip($hSync, StringFormat(Lng_Get("settings.checkbox.sync_preset.hint"), "0_O"))
	If Settings_Get("SyncPresetWithWS") Then GUICtrlSetState($hSync, $GUI_CHECKED)

	While True
		Sleep(30)
		$msg = GUIGetMsg()
		If $msg = 0 Then
			ContinueLoop
		ElseIf $msg = $GUI_EVENT_CLOSE Then
			ExitLoop
		ElseIf $msg = $hVersion Then
			$bVersion = Not $bVersion
			If BitAND(GUICtrlRead($hVersion), $GUI_CHECKED) Then
				Settings_Set("DisplayVersion", "1")
			Else
				Settings_Set("DisplayVersion", "")
			EndIf
		ElseIf $msg = $hSync Then
			If BitAND(GUICtrlRead($hSync), $GUI_CHECKED) Then
				Settings_Set("SyncPresetWithWS", "1")
			Else
				Settings_Set("SyncPresetWithWS", "")
			EndIf
		EndIf
	WEnd

	GUIDelete($hGUI)

	If $bIcons Then
		Return 1
	ElseIf $bVersion Then
		Return 2
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
			Local $iWidth = IniRead($MM_SETTINGS_PATH, "settings", "Width", 800)
			If $iWidth < 800 Then $iWidth = 800
			Return $iWidth
		Case "Height"
			Local $iHeight = IniRead($MM_SETTINGS_PATH, "settings", "Height", 475)
			If $iHeight < 475 Then $iHeight = 475
			Return $iHeight
		Case "Maximized"
			Return Int(IniRead($MM_SETTINGS_PATH, "settings", "Maximized", "")) <> 0
		Case "Explorer"
			Return IniRead($MM_SETTINGS_PATH, "settings", "Explorer", "")
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
