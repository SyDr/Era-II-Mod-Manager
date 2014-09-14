; Author:         Aliaksei SyDr Karalenka

#include <File.au3>
#include <GUIConstantsEx.au3>

#include "lng.au3"

#include-once


Func Settings_GUI($hParentGUI)
	Local $iTotalCheck = 4
	Local $hRememberPos, $hVersion, $hIcons, $hAssoc, $hSync
	Local $iBaseOffset = 8
	Local $hGUI, $msg
	Local $bVersion = False, $bIcons = False

	$hGUI = GUICreate(Lng_Get("settings.title"), 300, $iBaseOffset + $iTotalCheck*17+8, Default, Default, Default, Default, $hParentGUI)
	GUISetState(@SW_SHOW)

	$hRememberPos = GUICtrlCreateCheckbox(Lng_Get("settings.checkbox.save_win_pos"), $iBaseOffset+1, $iBaseOffset+1+(0)*17)
	If Settings_Get("RememberSizePos") Then GUICtrlSetState($hRememberPos, $GUI_CHECKED)

	$hVersion = GUICtrlCreateCheckbox(Lng_Get("settings.checkbox.display_version"), $iBaseOffset+1, $iBaseOffset+1+(1)*17)
	If Settings_Get("DisplayVersion") Then GUICtrlSetState($hVersion, $GUI_CHECKED)

	$hIcons = GUICtrlCreateCheckbox(Lng_Get("settings.checkbox.display_icons"), $iBaseOffset+1, $iBaseOffset+1+(2)*17)
	If Settings_Get("IconSize")>0 Then GUICtrlSetState($hIcons, $GUI_CHECKED)

	$hSync = GUICtrlCreateCheckbox(Lng_Get("settings.checkbox.sync_preset"), $iBaseOffset+1, $iBaseOffset+1+(3)*17)
	GUICtrlSetTip($hSync, StringFormat(Lng_Get("settings.checkbox.sync_preset.hint"), "0_O"))
	If Settings_Get("SyncPresetWithWS") Then GUICtrlSetState($hSync, $GUI_CHECKED)

	While True
		Sleep(30)
		$msg = GUIGetMsg()
		If $msg = 0 Then
			ContinueLoop
		ElseIf $msg = $GUI_EVENT_CLOSE Then
			ExitLoop
		ElseIf $msg = $hRememberPos Then
			If BitAND(GUICtrlRead($hRememberPos), $GUI_CHECKED) Then
				Settings_Set("RememberSizePos", True)
			Else
				Settings_Set("RememberSizePos", "")
			EndIf
		ElseIf $msg = $hVersion Then
			$bVersion = Not $bVersion
			If BitAND(GUICtrlRead($hVersion), $GUI_CHECKED) Then
				Settings_Set("DisplayVersion", True)
			Else
				Settings_Set("DisplayVersion", "")
			EndIf
		ElseIf $msg = $hIcons Then
			$bIcons = Not $bIcons
			If BitAND(GUICtrlRead($hIcons), $GUI_CHECKED) Then
				Settings_Set("IconSize", True)
			Else
				Settings_Set("IconSize", False)
			EndIf
		ElseIf $msg = $hAssoc Then
			If BitAND(GUICtrlRead($hAssoc), $GUI_CHECKED) Then
				Settings_Set("Assoc", True)
			Else
				Settings_Set("Assoc", "")
			EndIf
		ElseIf $msg = $hSync Then
			If BitAND(GUICtrlRead($hSync), $GUI_CHECKED) Then
				Settings_Set("SyncPresetWithWS", True)
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
EndFunc

Func Settings_Get($sName)
	Switch $sName
		Case "Language"
			Local $sLanguage = IniRead($MM_SETTINGS_PATH, "settings", "language", "english.ini")
			If $sLanguage = "" Then $sLanguage = "english.ini"
			Return $sLanguage
		Case "Exe"
			Local $sExe = IniRead($MM_SETTINGS_PATH, "settings", "exe", "h3era.exe")
			If $sExe = "" Then $sExe = "h3era.exe"
			Return $sExe
		Case "Left"
			Local $iLeft = IniRead($MM_SETTINGS_PATH, "settings", "left", 192)
			If $iLeft<0 Then $iLeft = 0
			If $iLeft>@DesktopWidth Then $iLeft = @DesktopWidth-100
			Return $iLeft
		Case "Top"
			Local $iTop = IniRead($MM_SETTINGS_PATH, "settings", "top", 152)
			If $iTop<0 Then $iTop = 0
			If $iTop>@DesktopWidth Then $iTop = @DesktopWidth-100
			Return $iTop
		Case "Width"
			Local $iWidth = IniRead($MM_SETTINGS_PATH, "settings", "Width", 800)
			If $iWidth<800 Then $iWidth = 800
			Return $iWidth
		Case "Height"
			Local $iHeight = IniRead($MM_SETTINGS_PATH, "settings", "Height", 475)
			If $iHeight<475 Then $iHeight = 475
			Return $iHeight
		Case "Explorer"
			Return IniRead($MM_SETTINGS_PATH, "settings", "Explorer", "")
		Case "Browser"
			Local $sBrowser = IniRead($MM_SETTINGS_PATH, "settings", "Browser", "")
			If $sBrowser = "" Then $sBrowser = RegRead("HKCR\http\shell\open\command", "")
			If $sBrowser = "" Then $sBrowser = '"C:\Program Files\Internet Explorer\iexplore.exe" "%1"'
		Case "SyncPresetWithWS"
			Return IniRead($MM_SETTINGS_PATH, "settings", "SyncPresetWithWS", "")
		Case "RememberSizePos"
			Return IniRead($MM_SETTINGS_PATH, "settings", "RememberSizePos", True)
		Case "DisplayVersion"
			Return IniRead($MM_SETTINGS_PATH, "settings", "DisplayVersion", True)
		Case "IconSize"
			Return IniRead($MM_SETTINGS_PATH, "settings", "IconSize", 16)
	EndSwitch
EndFunc

Func Settings_Set($sName, $vValue)
	Switch $sName
		Case "SyncPresetWithWS"
			Return IniWrite($MM_SETTINGS_PATH, "settings", "SyncPresetWithWS", $vValue)
		Case "RememberSizePos"
			Return IniWrite($MM_SETTINGS_PATH, "settings", "RememberSizePos", $vValue)
		Case "DisplayVersion"
			Return IniWrite($MM_SETTINGS_PATH, "settings", "DisplayVersion", $vValue)
		Case "Language"
			Return IniWrite($MM_SETTINGS_PATH, "settings", "language", $vValue)
		Case "Exe"
			Return IniWrite($MM_SETTINGS_PATH, "settings", "exe", $vValue)
		Case "Left"
			Return IniWrite($MM_SETTINGS_PATH, "settings", "left", $vValue)
		Case "Top"
			Return IniWrite($MM_SETTINGS_PATH, "settings", "top", $vValue)
		Case "Width"
			Return IniWrite($MM_SETTINGS_PATH, "settings", "Width", $vValue)
		Case "Height"
			Return IniWrite($MM_SETTINGS_PATH, "settings", "Height", $vValue)
		Case "IconSize"
			Local $iSize = Settings_Get("IconSize")
			If $vValue Then
				$iSize = Abs($iSize)
				If $iSize = 0 Then $iSize = 16
			Else
				$iSize = -Abs($iSize)
			EndIf
			IniWrite($MM_SETTINGS_PATH, "settings", "IconSize", $iSize)
	EndSwitch
EndFunc
