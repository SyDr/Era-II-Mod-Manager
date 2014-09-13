; Author:         Aliaksei SyDr Karalenka

#include <File.au3>
#include <GUIConstantsEx.au3>

#include "lng.au3"

#include-once


Func Settings_GUI($hParentGUI)
	Local $iTotalCheck = 5
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

	$hAssoc = GUICtrlCreateCheckbox(Lng_Get("settings.checkbox.assoc"), $iBaseOffset+1, $iBaseOffset+1+(3)*17)
	If Settings_Get("Assoc") Then GUICtrlSetState($hAssoc, $GUI_CHECKED)
	If Not @Compiled Then GUICtrlSetState($hAssoc, $GUI_DISABLE)

	$hSync = GUICtrlCreateCheckbox(Lng_Get("settings.checkbox.sync_preset"), $iBaseOffset+1, $iBaseOffset+1+(4)*17)
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
			Return IniRead($MM_SETTINGS_PATH, "settings", "language", "english.ini")
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
		Case "Assoc"
			Return IniRead($MM_SETTINGS_PATH, "settings", "Assoc", False)
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
		Case "Assoc"
			Return IniWrite($MM_SETTINGS_PATH, "settings", "Assoc", $vValue)
	EndSwitch
EndFunc

Func Settings_Assoc_Create()
	If Not IsAdmin() Then
		Return ShellExecuteWait(@ScriptFullPath, '/assocset', @WorkingDir , "runas", @SW_SHOWNORMAL)
	EndIf

	RegWrite("HKCR\.emp", "", "REG_SZ", "Era.ModManager.Package")
	RegWrite("HKCR\Era.ModManager.Package", "", "REG_SZ", "Era II Mod Manager Package File")
	RegWrite("HKCR\Era.ModManager.Package\shell\open\command", "", "REG_SZ", '"' & @ScriptFullPath & '" "%1"')
	RegWrite("HKCR\Era.ModManager.Package\DefaultIcon", "", "REG_SZ", @ScriptDir & "\icons\package.ico,0")
	__Settings_Assoc_Notify_System()
EndFunc

Func Settings_Assoc_Delete()
	If Not IsAdmin() Then
		Return ShellExecuteWait(@ScriptFullPath, '/assocdel', @WorkingDir , "runas", @SW_SHOWNORMAL)
	EndIf

	RegDelete("HKCR\.emp")
	RegDelete("HKCR\Era.ModManager.Package")
	__Settings_Assoc_Notify_System()
EndFunc

Func __Settings_Assoc_Notify_System()
	Local Const $SHCNE_ASSOCCHANGED = 0x8000000
	Local Const $SHCNF_IDLIST = 0
	Local Const $NULL = 0

	DllCall("shell32.dll", "none", "SHChangeNotify", "long", $SHCNE_ASSOCCHANGED, "int", $SHCNF_IDLIST, "ptr", $NULL, "ptr", $NULL)
EndFunc
