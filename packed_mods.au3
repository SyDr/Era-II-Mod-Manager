; Author:         Aliaksei SyDr Karalenka

#include <ButtonConstants.au3>
#include <Constants.au3>
#include <EditConstants.au3>
#include <File.au3>
#include <GUIConstantsEx.au3>
#include <StaticConstants.au3>
#include <WindowsConstants.au3>

#include "folder_mods.au3"
#include "lng.au3"
#include "settings.au3"

#include-once

Func PackedMod_IsPackedMod($sFilePath)
	Local $sModName = PackedMod_GetPackedName($sFilePath)
	If $sModName<>"" Then
		Return $sModName
	Else
		Return False
	EndIf
EndFunc

Func PackedMod_GetPackedName($sFilePath)
	If StringInStr(FileGetAttrib($sFilePath), "D") Then Return ""
	Local $sStdOut, $aRegExp, $sModName = ""

	Local $h7z = Run(@ScriptDir & '\7z\7z.exe l "' & $sFilePath & '"', @ScriptDir & "\7z\", @SW_HIDE, $STDERR_CHILD + $STDOUT_CHILD)

	While True
		$sStdOut = StdoutRead($h7z)
		If @error Then ExitLoop
		$aRegExp = StringRegExp($sStdOut, "Mods\\(.*?)\\", 1)
		If IsArray($aRegExp) Then $sModName = $aRegExp[0]
	WEnd

	Return $sModName
EndFunc

Func PackedMod_LoadInfo($sFilePath, ByRef $sLocalName, ByRef $sLocalDesc, ByRef $sVersion, ByRef $sMinVersion, ByRef $sAuthor, ByRef $sWebSite)
	Local $sModName = PackedMod_GetPackedName($sFilePath)
	If $sModName = "" Then Return ""

	Local $sTempDir = _TempFile()
	DirCreate($sTempDir)

	RunWait(@ScriptDir & '\7z\7z.exe e "' & $sFilePath & '" -o"' & $sTempDir & '\" "Mods\' & $sModName & '\mod_info.ini"', @ScriptDir & "\7z\", @SW_HIDE)
	$sLocalName = IniRead($sTempDir & "\mod_info.ini", "info", "Caption." & Lng_Get("lang.code"), IniRead($sTempDir & "\mod_info.ini", "info", "Caption", ""))
	Local $sDescriptonFile = IniRead($sTempDir & "\mod_info.ini", "info", "Description File." & Lng_Get("lang.code"), IniRead($sTempDir & "\mod_info.ini", "info", "Description File", "Readme.txt"))
	If $sDescriptonFile Then
		RunWait(@ScriptDir & '\7z\7z.exe e "' & $sFilePath & '" -o"' & $sTempDir & '\" "Mods\' & $sModName & '\' & $sDescriptonFile &'"', @ScriptDir & "\7z\", @SW_HIDE)
		$sLocalDesc = FileRead($sTempDir & "\" & $sDescriptonFile)
	EndIf

	$sVersion = IniRead($sTempDir & "\mod_info.ini", "info", "Version", "0.0")
	$sMinVersion = IniRead($sTempDir & "\mod_info.ini", "upgrade", "MinVersion", "0.0")
	$sAuthor = IniRead($sTempDir & "\mod_info.ini", "info", "Author", "")
	$sWebSite = IniRead($sTempDir & "\mod_info.ini", "info", "Homepage", "")

	Return True
EndFunc

Func PackedMod_Deploy($sFilePath, $sAction)
	Local $sTargetPath  = Settings_Global("Get", "Path") & "\.."
	; Actions are Install (delete if exist, then unpack) and Upgrade (just unpack with overwrite)
	Local $sModName = PackedMod_GetPackedName($sFilePath)
	If $sModName = "" Then Return SetError(1, 0, False)

	Local $sOverwrite = ""
	If $sAction = "Install" Then
		DirRemove($sTargetPath & "\Mods\" & $sModName & "\", 1)
		If @error Then Return SetError(2, 0, False)
	Else
		$sOverwrite = " -aoa"
	EndIf

	RunWait(@ScriptDir & '\7z\7z.exe x "' & $sFilePath & '"' & $sOverwrite & ' -o"' & $sTargetPath & '\', @ScriptDir & "\7z\", @SW_HIDE)

	If $sAction = "Install" Then
		ShellExecuteWait(@ScriptDir & '\..\installmod.exe', '"' & $sModName & '"', $sTargetPath & "\", "open")
		If @error Then ShellExecuteWait(@ScriptDir & '\..\installmod.exe', '"' & $sModName & '"', $sTargetPath & "\", "runas")
		If @error Then Return SetError(3, 0, False)
	EndIf
	Return True
EndFunc

Func PackedMod_InstallGUI_Simple($aModList, ByRef $auModList, $hFormParent = 0)
	Local $hDesc ; Name, Author, Desc
	Local $hButtonInstall, $hButtonCancel, $hButtonClose
	Local $hGUI, $msg
	Local $bInstall, $bClose = False
	Local $sAction

	$hGUI = GUICreate(Lng_Get("add_new.title"), 450, 370, Default, Default, Default, Default, $hFormParent)
	GUISetState(@SW_SHOW)

	$hDesc = GUICtrlCreateEdit("", 8, 8, 450-8, 300, $ES_READONLY)
	$hButtonInstall = GUICtrlCreateButton(Lng_Get("add_new.install"), 8, 340, 136, 25)
	$hButtonCancel = GUICtrlCreateButton(Lng_Get("add_new.next_mod"), 158, 340, 136, 25)
	$hButtonClose = GUICtrlCreateButton(Lng_Get("add_new.close"), 308, 340, 136, 25)
	If $hFormParent = 0 Then GUICtrlSetData($hButtonClose, Lng_Get("add_new.exit"))

	For $iCount = 1 To $aModList[0][0]
		WinSetTitle($hGUI, "", StringFormat(Lng_Get("add_new.title"), $iCount, $aModList[0][0]))
		Local $sDispName = $aModList[$iCount][1]
		If $aModList[$iCount][2] <> "" And $aModList[$iCount][2] <> $aModList[$iCount][1] Then $sDispName = $aModList[$iCount][2] & " (" & $aModList[$iCount][1] & ")"

		Local $sHelpMessage = ""

		If Mod_ModIsInstalled($aModList[$iCount][1], $auModList) Then
			$sHelpMessage &= StringFormat(Lng_Get("add_new.version_installed"), $aModList[$iCount][6]) & @CRLF
		EndIf

		$sAction = "Install"
		$sHelpMessage &= StringFormat(Lng_Get("add_new.package.install"), $aModList[$iCount][4]) & @CRLF
		If Mod_ModIsInstalled($aModList[$iCount][1], $auModList) Then ;Mod is installed
			If $aModList[$iCount][6]>=$aModList[$iCount][4] Then ;Installed version is latest
				If $aModList[$iCount][6]=$aModList[$iCount][4] Then
					GUICtrlSetData($hButtonInstall, Lng_Get("add_new.reinstall")) ; reinstall
					GUICtrlSetState($hButtonInstall, $GUI_ENABLE)
					GUICtrlSetData($hButtonCancel,  Lng_Get("add_new.next_mod"))
				Else
					GUICtrlSetData($hButtonInstall, Lng_Get("add_new.install")) ; install old
					GUICtrlSetState($hButtonInstall, $GUI_ENABLE)
					GUICtrlSetData($hButtonCancel, Lng_Get("add_new.next_mod"))
				EndIf
			ElseIf $aModList[$iCount][6]<$aModList[$iCount][4] Then ;Old version installed
				GUICtrlSetData($hButtonInstall, Lng_Get("add_new.install"))
				GUICtrlSetState($hButtonInstall, $GUI_ENABLE)
				GUICtrlSetData($hButtonCancel, Lng_Get("add_new.dont_install"))
			EndIf
		Else  ;None installed
			GUICtrlSetData($hButtonInstall, Lng_Get("add_new.install"))
			GUICtrlSetState($hButtonInstall, $GUI_ENABLE)
			GUICtrlSetData($hButtonCancel, Lng_Get("add_new.dont_install"))
		EndIf

		GUICtrlSetData($hDesc, $sDispName & @CRLF & $aModList[$iCount][3] & @CRLF & @CRLF & $sHelpMessage)

		If $iCount = $aModList[0][0] Then
			If $hFormParent = 0 Then
				GUICtrlSetData($hButtonCancel, Lng_Get("add_new.close"))
			Else
				GUICtrlSetState($hButtonCancel, $GUI_DISABLE)
			EndIf
		EndIf

		$bInstall = False

		While Not $bInstall And Not $bClose
			Sleep(10)
			$msg = GUIGetMsg()
			If $msg = 0 Then ContinueLoop
			If $msg = $GUI_EVENT_CLOSE Then ExitLoop
			If $msg = $hButtonCancel Then ExitLoop
			If $msg = $hButtonClose Then $bClose = True
			If $msg = $hButtonInstall Then $bInstall = True
		WEnd

		If $bInstall Then
			SplashTextOn("", Lng_Get("add_new.installed"), 400, 200)
			If $sAction = "Install" Then
				Mod_Delete(Mod_ModIsInstalled($aModList[$iCount][1], $auModList), $auModList)
				PackedMod_Deploy($aModList[$iCount][0], "Install")
			ElseIf $sAction = "Upgrade" Then
				PackedMod_Deploy($aModList[$iCount][0], "Upgrade")
			EndIf
			SplashOff()
		EndIf

		If $bClose Then ExitLoop
	Next

	GUIDelete($hGUI)
	Return Not $bClose
EndFunc