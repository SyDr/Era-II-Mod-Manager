;AutoIt Version:	3.3.9.0 (beta)
;Author:			SyDr

#include <File.au3>
#include <Constants.au3>
#include <ButtonConstants.au3>
#include <EditConstants.au3>
#include <GUIConstantsEx.au3>
#include <StaticConstants.au3>
#include <WindowsConstants.au3>
#include "folder_mods.au3"
#include "settings.au3"
#include "lng.au3"
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

;~ 	RunWait(@ScriptDir & '\7z\7z.exe x "' & $sFilePath & '"' & $sOverwrite & ' -o"' & $sTargetPath & '\', @ScriptDir & "\7z\");, @SW_HIDE)
	RunWait(@ScriptDir & '\7z\7z.exe x "' & $sFilePath & '"' & $sOverwrite & ' -o"' & $sTargetPath & '\', @ScriptDir & "\7z\", @SW_HIDE)
;~ 	MsgBox(4096, Default, @ScriptDir & '\7z\7z.exe x "' & $sFilePath & '"' & $sOverwrite & ' -o"' & $sTargetPath & '\')
	If $sAction = "Install" Then
		ShellExecuteWait(@ScriptDir & '\..\installmod.exe', '"' & $sModName & '"', $sTargetPath & "\", "open")
		If @error Then ShellExecuteWait(@ScriptDir & '\..\installmod.exe', '"' & $sModName & '"', $sTargetPath & "\", "runas")
		If @error Then Return SetError(3, 0, False)
	EndIf
	Return True
EndFunc

Func PackedMod_InstallGUI($aModList, ByRef $auModList, $hFormParent = 0)
	Local $sTargetPath  = Settings_Global("Get", "Path")
	Local $hRadio[$aModList[0][0]+1][3][3] ; Install/Reinstall/Nothing (Handle, IsDisabled?, IsDefaultAction?)
	Local $hAllowAll, $hButtonOK, $hButtonCancel
	Local $iBaseOffset = 8
	Local $hGUI, $msg
	Local $bInstall = False

	$hGUI = GUICreate(Lng_Get("add_new.title"), 600, $iBaseOffset + $aModList[0][0]*17+25 + 2*$iBaseOffset + 25, Default, Default, Default, Default, $hFormParent)
	GUISetState(@SW_SHOW)

	For $iCount = 1 To $aModList[0][0]  ; FilePath, ModName, ModLocalizedName, ModLocalizedDescription, Version, MinVersion, InstalledVersion
		GUIStartGroup()
		Local $sDispName = $aModList[$iCount][1]
		If $aModList[$iCount][2] <> "" And $aModList[$iCount][2] <> $aModList[$iCount][1] Then $sDispName = $aModList[$iCount][2] & " (" & $aModList[$iCount][1] & ")"
		GUICtrlCreateLabel($sDispName, $iBaseOffset+1, $iBaseOffset+1+1+($iCount-1)*17, 200)
		GUICtrlSetTip(-1, $aModList[$iCount][3])
		$hRadio[$iCount][0][0] = GUICtrlCreateRadio(Lng_Get("add_new.install"), $iBaseOffset+1+200, $iBaseOffset+1+($iCount-1)*17, 110)
		$hRadio[$iCount][1][0] = GUICtrlCreateRadio(Lng_Get("add_new.upgrade"), $iBaseOffset+1+315, $iBaseOffset+1+($iCount-1)*17, 110)
		$hRadio[$iCount][2][0] = GUICtrlCreateRadio(Lng_Get("add_new.nothing"), $iBaseOffset+1+430, $iBaseOffset+1+($iCount-1)*17, 110)
		If $aModList[$iCount][5]>0 Then ;This is a good upgrade package
			GUICtrlSetState($hRadio[$iCount][0][0], $GUI_DISABLE)
			$hRadio[$iCount][0][1] = True
			GUICtrlSetTip($hRadio[$iCount][0][0], Lng_Get("add_new.package.upgrade.cant_install"), Lng_Get("add_new.package.upgrade.title"))
			If Mod_ModIsInstalled($aModList[$iCount][1], $auModList) Then ;Mod is installed
				GUICtrlSetData($hRadio[$iCount][0][0], Lng_Get("add_new.reinstall"))
				If $aModList[$iCount][6]<>-1 And ($aModList[$iCount][6]<$aModList[$iCount][5] Or $aModList[$iCount][6]>=$aModList[$iCount][4]) Then ;Can't upgrade from this version or Not need to upgrade to this version
					GUICtrlSetState($hRadio[$iCount][1][0], $GUI_DISABLE)
					$hRadio[$iCount][1][1] = True
					GUICtrlSetState($hRadio[$iCount][2][0], $GUI_CHECKED)
					$hRadio[$iCount][2][2] = True
					GUICtrlSetTip($hRadio[$iCount][2][0], Lng_Get("add_new.package.upgrade.nothing_is_only_avail"), Lng_Get("add_new.package.upgrade.title"))
					If $aModList[$iCount][6]<$aModList[$iCount][5] Then
						GUICtrlSetTip($hRadio[$iCount][1][0], StringFormat(Lng_Get("add_new.package.upgrade.cant_upgrade_min_version"), $aModList[$iCount][6], $aModList[$iCount][5]), Lng_Get("add_new.package.upgrade.title"))
					Else
						GUICtrlSetTip($hRadio[$iCount][1][0], StringFormat(Lng_Get("add_new.package.upgrade.cant_upgrade_not_need"), $aModList[$iCount][6], $aModList[$iCount][4]), Lng_Get("add_new.package.upgrade.title"))
					EndIf
				ElseIf $aModList[$iCount][6]>0 Then  ;Normal version installed
					GUICtrlSetState($hRadio[$iCount][1][0], $GUI_CHECKED)
					$hRadio[$iCount][1][2] = True
					GUICtrlSetTip($hRadio[$iCount][1][0], Lng_Get("add_new.rec_ac") & @LF & StringFormat(Lng_Get("add_new.package.upgrade.from_old_to_new"), $aModList[$iCount][6], $aModList[$iCount][4]), Lng_Get("add_new.package.upgrade.title"))
					GUICtrlSetTip($hRadio[$iCount][2][0], Lng_Get("add_new.not_rec_ac") & @LF & Lng_Get("add_new.package.upgrade.dont_upgrade"), Lng_Get("add_new.package.upgrade.title"))
				Else
					GUICtrlSetState($hRadio[$iCount][2][0], $GUI_CHECKED)
					$hRadio[$iCount][2][2] = True
					GUICtrlSetTip($hRadio[$iCount][1][0], Lng_Get("add_new.not_rec_ac") & @LF & StringFormat(Lng_Get("add_new.package.upgrade.from_unk_to_new"), $aModList[$iCount][4]), Lng_Get("add_new.package.upgrade.title"))
					GUICtrlSetTip($hRadio[$iCount][2][0], Lng_Get("add_new.rec_ac") & @LF & Lng_Get("add_new.package.upgrade.dont_upgrade"), Lng_Get("add_new.package.upgrade.title"))
				EndIf
			Else  ;None installed
				GUICtrlSetState($hRadio[$iCount][1][0], $GUI_DISABLE) ;None
				$hRadio[$iCount][1][1] = True
				GUICtrlSetState($hRadio[$iCount][2][0], $GUI_CHECKED)
				$hRadio[$iCount][2][2] = True
				GUICtrlSetTip($hRadio[$iCount][1][0], Lng_Get("add_new.package.upgrade.cant_upgrade_not_installed"), Lng_Get("add_new.package.upgrade.title"))
				GUICtrlSetTip($hRadio[$iCount][2][0], Lng_Get("add_new.package.upgrade.nothing_is_only_avail"), Lng_Get("add_new.package.upgrade.title"))
			EndIf
		ElseIf $aModList[$iCount][4]>0 Then ;This is a good install package
			GUICtrlSetState($hRadio[$iCount][1][0], $GUI_DISABLE)
			$hRadio[$iCount][1][1] = True
			GUICtrlSetTip($hRadio[$iCount][1][0], Lng_Get("add_new.package.install.cant_upgrade"), Lng_Get("add_new.package.install.title"))
			If Mod_ModIsInstalled($aModList[$iCount][1], $auModList) Then ;Mod is installed
				GUICtrlSetData($hRadio[$iCount][0][0], Lng_Get("add_new.reinstall"))
				If $aModList[$iCount][6]>=$aModList[$iCount][4] Then ;Installed version is latest
					GUICtrlSetState($hRadio[$iCount][2][0], $GUI_CHECKED)
					$hRadio[$iCount][2][2] = True
					GUICtrlSetTip($hRadio[$iCount][2][0], Lng_Get("add_new.rec_ac"), Lng_Get("add_new.package.install.title"))
					If $aModList[$iCount][6]=$aModList[$iCount][4] Then
						GUICtrlSetTip($hRadio[$iCount][0][0], StringFormat(Lng_Get("add_new.package.install.from_cur_to_cur"), $aModList[$iCount][6]), Lng_Get("add_new.package.install.title"))
					Else
						GUICtrlSetTip($hRadio[$iCount][0][0], Lng_Get("add_new.not_rec_ac") & @LF & StringFormat(Lng_Get("add_new.package.install.from_new_to_old"), $aModList[$iCount][4], $aModList[$iCount][6]), Lng_Get("add_new.package.install.title"))
					EndIf
				ElseIf $aModList[$iCount][6]<$aModList[$iCount][4] Then ;Old version installed
					GUICtrlSetState($hRadio[$iCount][0][0], $GUI_CHECKED)
					$hRadio[$iCount][0][2] = True
					GUICtrlSetTip($hRadio[$iCount][0][0], Lng_Get("add_new.rec_ac") & @LF & StringFormat(Lng_Get("add_new.package.install.from_old_to_new"), $aModList[$iCount][6], $aModList[$iCount][4]), Lng_Get("add_new.package.install.title"))
					GUICtrlSetTip($hRadio[$iCount][2][0], Lng_Get("add_new.not_rec_ac"), Lng_Get("add_new.package.install.title"))
				EndIf
			Else  ;None installed
				GUICtrlSetState($hRadio[$iCount][0][0], $GUI_CHECKED)
				$hRadio[$iCount][0][2] = True
				GUICtrlSetTip($hRadio[$iCount][0][0], StringFormat(Lng_Get("add_new.package.install.from_none_to_new"), $aModList[$iCount][4]), Lng_Get("add_new.package.install.title"))
				GUICtrlSetTip($hRadio[$iCount][1][0], Lng_Get("add_new.package.upgrade.cant_upgrade_not_installed"), Lng_Get("add_new.package.install.title"))
				GUICtrlSetTip($hRadio[$iCount][2][0], Lng_Get("add_new.package.install.dont_install"), Lng_Get("add_new.package.install.title"))
			EndIf
		Else ;A bad install package
			GUICtrlSetState($hRadio[$iCount][2][0], $GUI_CHECKED)
			$hRadio[$iCount][2][2] = True
			GUICtrlSetTip($hRadio[$iCount][2][0], Lng_Get("add_new.rec_ac") & @LF & Lng_Get("add_new.package.install.dont_install"), Lng_Get("add_new.package.bad.title"))
			If Not Mod_ModIsInstalled($aModList[$iCount][1], $auModList) Then ;No normal mod there
				GUICtrlSetState($hRadio[$iCount][1][0], $GUI_DISABLE)
				$hRadio[$iCount][1][1] = True
				GUICtrlSetTip($hRadio[$iCount][0][0], Lng_Get("add_new.not_rec_ac") & @LF & Lng_Get("add_new.package.install.from_none_to_unk"), Lng_Get("add_new.package.bad.title"))
				GUICtrlSetTip($hRadio[$iCount][1][0], Lng_Get("add_new.not_rec_ac") & @LF & Lng_Get("add_new.package.upgrade.cant_upgrade_not_installed"), Lng_Get("add_new.package.bad.title"))
			ElseIf $aModList[$iCount][6]>0 Then
				GUICtrlSetData($hRadio[$iCount][0][0], Lng_Get("add_new.reinstall"))
				GUICtrlSetTip($hRadio[$iCount][0][0], Lng_Get("add_new.not_rec_ac") & @LF & StringFormat(Lng_Get("add_new.package.install.from_new_to_unk"), $aModList[$iCount][6]), Lng_Get("add_new.package.bad.title"))
				GUICtrlSetTip($hRadio[$iCount][1][0], Lng_Get("add_new.not_rec_ac") & @LF & StringFormat(Lng_Get("add_new.package.upgrade.from_new_to_unk"), $aModList[$iCount][6]), Lng_Get("add_new.package.bad.title"))
			Else
				GUICtrlSetData($hRadio[$iCount][0][0], Lng_Get("add_new.reinstall"))
				GUICtrlSetTip($hRadio[$iCount][0][0], Lng_Get("add_new.not_rec_ac") & @LF & Lng_Get("add_new.package.install.from_unk_to_unk"), Lng_Get("add_new.package.bad.title"))
				GUICtrlSetTip($hRadio[$iCount][1][0], Lng_Get("add_new.not_rec_ac") & @LF & Lng_Get("add_new.package.upgrade.from_unk_to_unk"), Lng_Get("add_new.package.bad.title"))

			EndIf
		EndIf
	Next

	$hAllowAll = GUICtrlCreateCheckbox(Lng_Get("add_new.allow_all"), 15+11, 2*$iBaseOffset+1+$aModList[0][0]*17, 500)
	$hButtonOK = GUICtrlCreateButton(Lng_Get("add_new.ok"), 15+11, 2*$iBaseOffset+1+$aModList[0][0]*17+25, 250)
	$hButtonCancel = GUICtrlCreateButton(Lng_Get("add_new.cancel"), 300+1, 2*$iBaseOffset+1+$aModList[0][0]*17+25, 250)

	While Not $bInstall
		Sleep(10)
		$msg = GUIGetMsg()
		If $msg = 0 Then ContinueLoop
		If $msg = $GUI_EVENT_CLOSE Then ExitLoop
		If $msg = $hButtonCancel Then ExitLoop
		If $msg = $hButtonOK Then $bInstall = True
		If $msg = $hAllowAll Then
			If BitAND(GUICtrlRead($hAllowAll), $GUI_CHECKED) Then
				For $iCount = 1 To $aModList[0][0]
					GUICtrlSetState($hRadio[$iCount][0][0], $GUI_ENABLE)
					GUICtrlSetState($hRadio[$iCount][1][0], $GUI_ENABLE)
					GUICtrlSetState($hRadio[$iCount][2][0], $GUI_ENABLE)
				Next
			Else
				For $iCount = 1 To $aModList[0][0]
					Local $bSwitch = False
					If $hRadio[$iCount][0][1] Then
						GUICtrlSetState($hRadio[$iCount][0][0], $GUI_DISABLE)
						If BitAND(GUICtrlRead($hRadio[$iCount][0][0]), $GUI_CHECKED) Then $bSwitch = True
					EndIf
					If $hRadio[$iCount][1][1] Then
						GUICtrlSetState($hRadio[$iCount][1][0], $GUI_DISABLE)
						If BitAND(GUICtrlRead($hRadio[$iCount][1][0]), $GUI_CHECKED) Then $bSwitch = True
					EndIf
					If $hRadio[$iCount][2][1] Then
						GUICtrlSetState($hRadio[$iCount][2][0], $GUI_DISABLE)
						If BitAND(GUICtrlRead($hRadio[$iCount][2][0]), $GUI_CHECKED) Then $bSwitch = True
					EndIf
					If $bSwitch Then
						If $hRadio[$iCount][0][2] Then GUICtrlSetState($hRadio[$iCount][0][0], $GUI_CHECKED)
						If $hRadio[$iCount][1][2] Then GUICtrlSetState($hRadio[$iCount][1][0], $GUI_CHECKED)
						If $hRadio[$iCount][2][2] Then GUICtrlSetState($hRadio[$iCount][2][0], $GUI_CHECKED)
					EndIf
				Next
			EndIf
		EndIf
	WEnd

	If $bInstall Then
		SplashTextOn("", Lng_Get("add_new.installed"), 400, 200)
		For $iCount = 1 To $aModList[0][0]
			;MsgBox(4096, "",  BitAND(GUICtrlRead($hRadio[$iCount][0][0]), $GUI_CHECKED) & @CRLF & BitAND(GUICtrlRead($hRadio[$iCount][1][0]), $GUI_CHECKED))
			If BitAND(GUICtrlRead($hRadio[$iCount][0][0]), $GUI_CHECKED) Then
				Mod_Delete(Mod_ModIsInstalled($aModList[$iCount][1], $auModList), $auModList)
				PackedMod_Deploy($aModList[$iCount][0], "Install")
			ElseIf BitAND(GUICtrlRead($hRadio[$iCount][1][0]), $GUI_CHECKED) Then
				PackedMod_Deploy($aModList[$iCount][0], "Upgrade")
			EndIf
		Next
		SplashOff()
	EndIf

	GUIDelete($hGUI)
	Return $bInstall
EndFunc

Func PackedMod_InstallGUI_Simple($aModList, ByRef $auModList, $hFormParent = 0)
	Local $sTargetPath  = Settings_Global("Get", "Path")
	Local $hDesc ; Name, Author, Desc
	;Local $hTechInfo ; Installed version, Package version, Actions
	Local $hButtonInstall, $hButtonCancel, $hButtonClose
	Local $iBaseOffset = 8
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

	For $iCount = 1 To $aModList[0][0]  ; FilePath, ModName, ModLocalizedName, ModLocalizedDescription, Version, MinVersion, InstalledVersion
		WinSetTitle($hGUI, "", StringFormat(Lng_Get("add_new.title"), $iCount, $aModList[0][0]))
		Local $sDispName = $aModList[$iCount][1]
		If $aModList[$iCount][2] <> "" And $aModList[$iCount][2] <> $aModList[$iCount][1] Then $sDispName = $aModList[$iCount][2] & " (" & $aModList[$iCount][1] & ")"

		;GUICtrlSetData($hDesc, $sDispName & @CRLF & $aModList[$iCount][3])
		Local $sHelpMessage = ""

		If Mod_ModIsInstalled($aModList[$iCount][1], $auModList) Then
			$sHelpMessage &= StringFormat(Lng_Get("add_new.version_installed"), $aModList[$iCount][6]) & @CRLF
		EndIf

;~ 		If $aModList[$iCount][5]>0 Then ;This is a upgrade package
;~ 			$sAction = "Upgrade"
;~ 			$sHelpMessage &= StringFormat(Lng_Get("add_new.package.upgrade"), $aModList[$iCount][5], $aModList[$iCount][4]) & @CRLF
;~ 			If Mod_ModIsInstalled($aModList[$iCount][1], $auModList) Then ;Mod is installed
;~ 				If $aModList[$iCount][6]<=0 Then ;Unknow installed
;~ 					GUICtrlSetData($hButtonInstall, Lng_Get("add_new.cant_upgrade"))
;~ 					GUICtrlSetState($hButtonInstall, $GUI_ENABLE)
;~ 					GUICtrlSetData($hButtonCancel, Lng_Get("add_new.next_mod"))
;~ 					$sHelpMessage &= StringFormat(Lng_Get("add_new.package.upgrade.from_unk"), "") & @CRLF
;~ 				ElseIf $aModList[$iCount][6]<$aModList[$iCount][5] Then
;~ 					GUICtrlSetData($hButtonInstall, Lng_Get("add_new.cant_upgrade"))
;~ 					GUICtrlSetState($hButtonInstall, $GUI_ENABLE)
;~ 					GUICtrlSetData($hButtonCancel, Lng_Get("add_new.next_mod"))
;~ 					$sHelpMessage &= StringFormat(Lng_Get("add_new.package.upgrade.from_old"), "") & @CRLF
;~ 				ElseIf $aModList[$iCount][6]>=$aModList[$iCount][4] Then
;~ 					GUICtrlSetData($hButtonInstall, Lng_Get("add_new.cant_upgrade"))
;~ 					GUICtrlSetState($hButtonInstall, $GUI_ENABLE)
;~ 					GUICtrlSetData($hButtonCancel, Lng_Get("add_new.next_mod"))
;~ 					$sHelpMessage &= StringFormat(Lng_Get("add_new.package.upgrade.from_same"), "") & @CRLF
;~ 				Else; from old to new or from unk to new
;~ 					GUICtrlSetData($hButtonInstall, Lng_Get("add_new.upgrade"))
;~ 					GUICtrlSetState($hButtonInstall, $GUI_ENABLE)
;~ 					GUICtrlSetData($hButtonCancel,  Lng_Get("add_new.dont_upgrade"))
;~ 				EndIf
;~ 			Else  ; None installed
;~ 				GUICtrlSetData($hButtonInstall, Lng_Get("add_new.cant_upgrade"))
;~ 				GUICtrlSetState($hButtonInstall, $GUI_ENABLE)
;~ 				GUICtrlSetData($hButtonCancel, Lng_Get("add_new.next_mod"))
;~ 				$sHelpMessage &= StringFormat(Lng_Get("add_new.package.upgrade.from_none"), "") & @CRLF
;~ 			EndIf
;~ 		Else
;~ 		If $aModList[$iCount][4]>0 Then ;This is a install package
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
;~ 		Else ;A bad install package / allow install anyway
;~ 			$sAction = "Install"
;~ 			GUICtrlSetData($hButtonInstall, Lng_Get("add_new.install"))
;~ 			GUICtrlSetState($hButtonInstall, $GUI_ENABLE)
;~ 			GUICtrlSetData($hButtonCancel, Lng_Get("add_new.dont_install"))
;~ 			$sHelpMessage &= StringFormat(Lng_Get("add_new.package.bad"), "") & @CRLF
;~ 		EndIf

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