; Author:         Aliaksei SyDr Karalenka

#include-once

#include "include_fwd.au3"

#include "lng.au3"
#include "settings.au3"
#include "utils.au3"


Func Update_CheckNewPorgram(Const $bIsPortable, Const $hParent)
	Local Const $iOptionGUIOnEventMode = AutoItSetOption("GUIOnEventMode", 0)
	Local Const $iOptionGUICoordMode = AutoItSetOption("GUICoordMode", 0)
	GUISetState(@SW_DISABLE, $hParent)
	Local Const $iMinWidth = 400
	Local Const $iItemSpacing = 4

	Local $hGUI = MapEmpty()
	$hGUI.Info = MapEmpty()
	$hGUI.Info.RemotePath = "https://dl.dropboxusercontent.com/u/24541426"
	$hGUI.Setup = MapEmpty()
	$hGUI.Access = MapEmpty()
	$hGUI.Close = False

	$hGUI.Form = GUICreate(Lng_Get("update.caption"), $iMinWidth + Round(Random(0, (@DesktopWidth - $iMinWidth)/10, 1)), 200, Default, Default, Default, Default, $hParent)
	GUISetIcon(@ScriptDir & "\icons\preferences-system.ico")
	Local $aSize = WinGetClientSize($hGUI.Form)

	$hGUI.GroupParam = GUICtrlCreateGroup(Lng_Get("update.caption"), $iItemSpacing, $iItemSpacing, $aSize[0] - 2 * $iItemSpacing, 88)
	$hGUI.LabelCurVersion = GUICtrlCreateLabel(Lng_GetF("update.current_version", $MM_VERSION), 2 * $iItemSpacing, 4 * $iItemSpacing, Default, 17, $SS_CENTERIMAGE)
	$hGUI.LabelAvaVersion = GUICtrlCreateLabel(Lng_Get("update.available_versions"), 0, GUICtrlGetPos($hGUI.LabelCurVersion)[3] + $iItemSpacing, Default, 17, $SS_CENTERIMAGE)
	$hGUI.ComboAvaVersion = GUICtrlCreateCombo(Lng_Get("update.wait"), GUICtrlGetPos($hGUI.LabelAvaVersion)[2], 0, $aSize[0] - GUICtrlGetPos($hGUI.LabelAvaVersion)[2] - 6 * $iItemSpacing + 3, 17, BitOR($CBS_DROPDOWNLIST, $CBS_AUTOHSCROLL))
	GUISetCoord(GUICtrlGetPos($hGUI.LabelAvaVersion)[0], GUICtrlGetPos($hGUI.LabelAvaVersion)[1])

	$hGUI.LabelCheckPath = GUICtrlCreateLabel(Lng_Get("update.check_path"), 0, GUICtrlGetPos($hGUI.LabelAvaVersion)[3] + 2 * $iItemSpacing, Default, 17, $SS_CENTERIMAGE)
	$hGUI.InputCheckPath = GUICtrlCreateInput($hGUI.Info.RemotePath, GUICtrlGetPos($hGUI.LabelCheckPath)[2], 0, $aSize[0] - GUICtrlGetPos($hGUI.LabelCheckPath)[2] - 21*2 - 7 * $iItemSpacing, 21)
	$hGUI.PathRefresh = GUICtrlCreateButton("", GUICtrlGetPos($hGUI.InputCheckPath)[2] + 0, -2, 25, 25, $BS_ICON)
	$hGUI.PathFromClip = GUICtrlCreateButton("", GUICtrlGetPos($hGUI.PathRefresh)[2] + 0, 0, 25, 25, $BS_ICON)
	GUISetCoord(0, GUICtrlGetPos($hGUI.GroupParam)[1])

	$hGUI.GroupUpdate = GUICtrlCreateGroup(Lng_Get("update.update_group"), $iItemSpacing, GUICtrlGetPos($hGUI.GroupParam)[3], $aSize[0] - 2 * $iItemSpacing, 104)
	$hGUI.RadioDownloadAndInstall = GUICtrlCreateRadio(Lng_Get("update.download_and_install"), 2 * $iItemSpacing, 4 * $iItemSpacing, Default, 17, $BS_VCENTER)
	$hGUI.RadioOnlyDownload = GUICtrlCreateRadio(Lng_Get("update.only_download"), 0, GUICtrlGetPos($hGUI.RadioDownloadAndInstall)[3], Default, 17)
	$hGUI.InputSaveTo = GUICtrlCreateInput(@DesktopDir, 17, GUICtrlGetPos($hGUI.RadioOnlyDownload)[3], $aSize[0] - 75 - 10 * $iItemSpacing, 21)
	$hGUI.ButtonSaveChangePath = GUICtrlCreateButton(Lng_Get("update.change_dir"), GUICtrlGetPos($hGUI.InputSaveTo)[2] + $iItemSpacing, -2, 75, 25)
	GUISetCoord(0, GUICtrlGetPos($hGUI.InputSaveTo)[1])

	$hGUI.ProgressDownload = GUICtrlCreateProgress(2 * $iItemSpacing, GUICtrlGetPos($hGUI.InputSaveTo)[3] + $iItemSpacing, $aSize[0] - 6 * $iItemSpacing - 150 + 1, 21)
	$hGUI.ButtonStart = GUICtrlCreateButton(Lng_Get("update.start"), GUICtrlGetPos($hGUI.ProgressDownload)[2] + $iItemSpacing, -2, 75, 25)
	$hGUI.ButtonCancel = GUICtrlCreateButton(Lng_Get("update.close"), GUICtrlGetPos($hGUI.ButtonStart)[2] + $iItemSpacing, 0, 75, 25)

	GUICtrlSetStateStateful($hGUI.ComboAvaVersion, $GUI_DISABLE)
	GUICtrlSetStateStateful($hGUI.InputCheckPath, $GUI_DISABLE)
	GUICtrlSetImage($hGUI.PathRefresh, @ScriptDir & "\icons\view-refresh.ico")
	GUICtrlSetImage($hGUI.PathFromClip, @ScriptDir & "\icons\edit-copy.ico")
	GUICtrlSetStateStateful($hGUI.PathRefresh, $GUI_DISABLE)
	GUICtrlSetStateStateful($hGUI.PathFromClip, $GUI_DISABLE)
	GUICtrlSetState($bIsPortable ? $hGUI.RadioOnlyDownload : $hGUI.RadioDownloadAndInstall, $GUI_CHECKED)
	$hGUI.Setup.IsPortable = $bIsPortable ? True : False
	If $bIsPortable Then GUICtrlSetStateStateful($hGUI.RadioDownloadAndInstall, $GUI_DISABLE)
	If Not $bIsPortable Then GUICtrlSetStateStateful($hGUI.ButtonSaveChangePath, $GUI_DISABLE)
	GUICtrlSetStateStateful($hGUI.InputSaveTo, $GUI_DISABLE)
	GUICtrlSetStateStateful($hGUI.ButtonStart, $GUI_DISABLE)
	GUICtrlSetData($hGUI.ProgressDownload, 0)

	GUISetState(@SW_SHOW)

	__Update_InfoDownload($hGUI)

	While Not $hGUI.Close
		If $hGUI.Info.InProgress Then
			If InetGetInfo($hGUI.Info.Handle, $INET_DOWNLOADCOMPLETE) Then
				Local $bIsSuccess = InetGetInfo($hGUI.Info.Handle, $INET_DOWNLOADSUCCESS)
				InetClose($hGUI.Info.Handle)
				GUICtrlSetColor($hGUI.InputCheckPath, $bIsSuccess ? Default : $COLOR_RED)
				$hGUI.Info.InProgress = False
				__Update_InfoLock($hGUI, False)

				If $bIsSuccess Then
					__Update_InfoFileProcess($hGUI, FileRead($hGUI.Info.Location))
					GUICtrlSetState($hGUI.PathFromClip, $GUI_DISABLE)
				Else
					GUICtrlSetState($hGUI.ComboAvaVersion, $GUI_DISABLE)
					GUICtrlSetState($hGUI.PathFromClip, $GUI_ENABLE)
					Local $iAnswer = MsgBox($MB_YESNO + $MB_ICONQUESTION + $MB_TASKMODAL, "", Lng_Get("update.cant_check"), Default, $hGUI.Form)
					If $iAnswer = $IDYES Then Utils_LaunchInBrowser($hGUI.Info.RemotePath & "/ramm.html")
				EndIf
			EndIf
		EndIf

		If $hGUI.Info.FromClipboard Then
			$hGUI.Info.FromClipboard = False
			__Update_InfoFileProcess($hGUI, ClipGet())
		EndIf

		If $hGUI.Info.Download Then
			__Update_InfoLock($hGUI, True)
			$hGUI.Info.RemotePath = GUICtrlRead($hGUI.InputCheckPath)
			__Update_InfoDownload($hGUI)
		EndIf

		If $hGUI.ChangeSetupType Then
			If ($hGUI.Setup.IsPortable And BitAND(GUICtrlRead($hGUI.RadioDownloadAndInstall), $GUI_CHECKED) = $GUI_CHECKED) Or _
				(Not $hGUI.Setup.IsPortable  And BitAND(GUICtrlRead($hGUI.RadioOnlyDownload), $GUI_CHECKED) = $GUI_CHECKED) Then
				__Update_SetupTypeChange($hGUI)
				$hGUI.ChangeSetupType = False
				EndIf
		EndIf

		If $hGUI.ChangeDownloadPath Then
			$hGUI.ChangeDownloadPath = False
			Local $sPath = FileSelectFolder(Lng_Get("update.select_dir"), "", Default, "", $hGUI.Form)
			If Not @error And $sPath <> "" Then GUICtrlSetData($hGUI.InputSaveTo, $sPath)
		EndIf

		If $hGUI.ChangeDownloadSelected Then
			$hGUI.ChangeDownloadSelected = False
			__Update_DownloadSelectionChanged($hGUI, GUICtrlRead($hGUI.ComboAvaVersion))
		EndIf

		If $hGUI.Setup.Download Then
			$hGUI.Setup.Download = False
			Local $sType = $bIsPortable ? "portable" : "setup"
			Local $sFile = $hGUI.Info.Parsed["items"][$hGUI.Setup.Version][$sType]

			Local $sSaveTo = __Update_GetSaveToFile(GUICtrlRead($hGUI.InputSaveTo), $sFile, Not $hGUI.Setup.IsPortable)

			__Update_AllLock($hGUI, True)
			$hGUI.Setup.Handle = InetGet($hGUI.Info.RemotePath & $sFile, $sSaveTo, Default, $INET_DOWNLOADBACKGROUND)
			While Not InetGetInfo($hGUI.Setup.Handle, $INET_DOWNLOADCOMPLETE)
				GUICtrlSetData($hGUI.ProgressDownload, InetGetInfo($hGUI.Setup.Handle, $INET_DOWNLOADREAD)/InetGetInfo($hGUI.Setup.Handle, $INET_DOWNLOADSIZE)*100)
			WEnd

			GUICtrlSetData($hGUI.ProgressDownload, 100)
			Local $bCloseUI = InetGetInfo($hGUI.Setup.Handle, $INET_DOWNLOADSUCCESS)
			InetClose($hGUI.Setup.Handle)

			$hGUI.Close = $bCloseUI

			If $bCloseUI And Not $hGUI.Setup.IsPortable Then
				ShellExecute($sSaveTo, "/SILENT")
				If @OSVersion = "WIN_XP" Then Exit
			ElseIf Not $bCloseUI Then
				__Update_AllLock($hGUI, False)
				$iAnswer = MsgBox($MB_YESNO + $MB_ICONQUESTION + $MB_TASKMODAL, "", Lng_Get("update.cant_download"), Default, $hGUI.Form)
				If $iAnswer = $IDYES Then Utils_LaunchInBrowser($hGUI.Info.RemotePath & $sFile)
			EndIf
		EndIf

		__Update_ProcessUserInput($hGUI)
	WEnd

	InetClose($hGUI.Info.Handle)
	GUIDelete($hGUI.Form)

	AutoItSetOption("GUIOnEventMode", $iOptionGUIOnEventMode)
	AutoItSetOption("GUICoordMode", $iOptionGUICoordMode)

	GUISetState(@SW_ENABLE, $hParent)
	GUISetState(@SW_RESTORE, $hParent)
EndFunc

Func __Update_InfoFileProcess(ByRef $hGUI, Const $sFile)
	$hGUI.Info.Parsed = Jsmn_Decode($sFile)
	Local $iValidated = __Update_ValidateInfoFile($hGUI.Info.Parsed)

	If $iValidated = 0 Then
		Local $aKeys = MapKeys($hGUI.Info.Parsed["items"])
		For $i = 0 To UBound($aKeys) - 1
			$aKeys[$i] &= $hGUI.Info.Parsed["items"][$aKeys[$i]]["type"] <> "release" ? "." & $hGUI.Info.Parsed["items"][$aKeys[$i]]["type"] : ""
		Next
		GUICtrlSetData($hGUI.ComboAvaVersion, "|" & Lng_Get("update.select_from_list") & "|" & _ArrayToString($aKeys), Lng_Get("update.select_from_list"))
		GUICtrlSetState($hGUI.ComboAvaVersion, $GUI_ENABLE)
	ElseIf $iValidated = 1 Then
		GUICtrlSetData($hGUI.ComboAvaVersion, "|" & Lng_Get("update.info_invalid"), Lng_Get("update.info_invalid"))
		GUICtrlSetState($hGUI.ComboAvaVersion, $GUI_DISABLE)
	EndIf
EndFunc

Func __Update_ValidateInfoFile($Map)
	If Not IsMap($Map) Then Return 1
	If Not MapExists($Map, "info_version") Then Return 1
	If Not IsMap($Map["items"]) Then Return 1
	Local $aKeys = MapKeys($Map["items"])
	For $i = 0 To UBound($aKeys) - 1
		If Not IsMap($Map["items"][$aKeys[$i]]) Then Return 1
		If Not MapExists($Map["items"][$aKeys[$i]], "type") Then Return 1
		If Not MapExists($Map["items"][$aKeys[$i]], "setup") Then Return 1
		If Not MapExists($Map["items"][$aKeys[$i]], "portable") Then Return 1
	Next
	Return 0
EndFunc

Func __Update_ProcessUserInput(ByRef $hGUI)
	Local $nMsg = GUIGetMsg()
	Switch $nMsg
		Case $GUI_EVENT_CLOSE, $hGUI.ButtonCancel
			$hGUI.Close = True
		Case $hGUI.PathRefresh
			$hGUI.Info.Download = True
		Case $hGUI.PathFromClip
			$hGUI.Info.FromClipboard = True
		Case $hGUI.ButtonStart
			$hGUI.Setup.Download = True
		Case $hGUI.RadioDownloadAndInstall, $hGUI.RadioOnlyDownload
			$hGUI.ChangeSetupType = True
		Case $hGUI.ButtonSaveChangePath
			$hGUI.ChangeDownloadPath = True
		Case $hGUI.ComboAvaVersion
			$hGUI.ChangeDownloadSelected = True
	EndSwitch
EndFunc

Func __Update_DownloadSelectionChanged(ByRef $hGUI, Const $sNewVersion)
	Local $aKeys = MapKeys($hGUI.Info.Parsed["items"])

	For $i = 0 To UBound($aKeys) - 1
		If $sNewVersion = $aKeys[$i] & ($hGUI.Info.Parsed["items"][$aKeys[$i]]["type"] <> "release" ? "." & $hGUI.Info.Parsed["items"][$aKeys[$i]]["type"] : "") Then
			$hGUI.Setup.Version = $aKeys[$i]
			GUICtrlSetState($hGUI.ButtonStart, $GUI_ENABLE)
			Return
		EndIf
	Next

	$hGUI.Setup.Version = ""
	GUICtrlSetState($hGUI.ButtonStart, $GUI_DISABLE)
EndFunc

Func __Update_GetSaveToFile($sDir, $sFile, $bSaveToTemp)
	If $bSaveToTemp Then
		Return _TempFile(@TempDir, Default, ".exe")
	EndIf

	Local $sTemp1 = "", $sTemp2 = "", $sFilename = "", $sExtension = ""
	Local $iTemp = 0, $bRename = False
	_PathSplit($sFile, $sTemp1, $sTemp2, $sFilename, $sExtension)

	If FileExists($sDir & "\" & $sFilename & $sExtension) Then
		$bRename = True
		While FileExists($sDir & "\" & $sFilename & "_" & $iTemp & $sExtension)
			$iTemp += 1
		WEnd
	EndIf

	Return $sDir & "\" & $sFilename & ($bRename ? "_" & $iTemp : "") & $sExtension
EndFunc

Func __Update_SetupTypeChange(ByRef $hGUI)
	$hGUI.Setup.IsPortable = Not $hGUI.Setup.IsPortable
	GUICtrlSetStateStateful($hGUI.ButtonSaveChangePath, $hGUI.Setup.IsPortable ? $GUI_ENABLE : $GUI_DISABLE)
EndFunc

Func __Update_InfoDownload(ByRef $hGUI)
	$hGUI.Info.Download = False
	$hGUI.Info.Location = _TempFile()
	$hGUI.Info.Handle = InetGet($hGUI.Info.RemotePath & "/ramm.json", $hGUI.Info.Location, $INET_FORCERELOAD, $INET_DOWNLOADBACKGROUND)
	$hGUI.Info.InProgress = True
	GUICtrlSetData($hGUI.ProgressDownload, 0)
	GUICtrlSetState($hGUI.ButtonStart, $GUI_DISABLE)
	GUICtrlSetData($hGUI.ComboAvaVersion, "|" & Lng_Get("update.wait"), Lng_Get("update.wait"))
	GUICtrlSetState($hGUI.ComboAvaVersion, $GUI_DISABLE)
EndFunc

Func __Update_InfoLock(ByRef $hGUI, Const $bLock)
	If Not $bLock Then
		GUICtrlSetStateStateful($hGUI.InputCheckPath, $GUI_ENABLE)
		GUICtrlSetStateStateful($hGUI.PathRefresh, $GUI_ENABLE)
		GUICtrlSetStateStateful($hGUI.PathFromClip, $GUI_ENABLE)
	Else
		GUICtrlSetStateStateful($hGUI.InputCheckPath, $GUI_DISABLE)
		GUICtrlSetStateStateful($hGUI.PathRefresh, $GUI_DISABLE)
		GUICtrlSetStateStateful($hGUI.PathFromClip, $GUI_DISABLE)
	EndIf
EndFunc

Func __Update_AllLock(ByRef $hGUI, Const $bLock)
	If Not $bLock Then
		GUICtrlSetStateStateful($hGUI.ComboAvaVersion, $GUI_ENABLE)
		GUICtrlSetStateStateful($hGUI.InputCheckPath, $GUI_ENABLE)
		GUICtrlSetStateStateful($hGUI.PathRefresh, $GUI_ENABLE)
		GUICtrlSetStateStateful($hGUI.PathFromClip, $GUI_ENABLE)
		GUICtrlSetState($hGUI.ComboAvaVersion, $GUI_ENABLE)
		GUICtrlSetStateStateful($hGUI.RadioDownloadAndInstall, $GUI_ENABLE)
		GUICtrlSetStateStateful($hGUI.RadioOnlyDownload, $GUI_ENABLE)
		GUICtrlSetStateStateful($hGUI.ButtonSaveChangePath, $GUI_ENABLE)
		GUICtrlSetStateStateful($hGUI.ButtonCancel, $GUI_ENABLE)
		GUICtrlSetState($hGUI.ButtonStart, $GUI_ENABLE)
	Else
		GUICtrlSetStateStateful($hGUI.ComboAvaVersion, $GUI_DISABLE)
		GUICtrlSetStateStateful($hGUI.InputCheckPath, $GUI_DISABLE)
		GUICtrlSetStateStateful($hGUI.PathRefresh, $GUI_DISABLE)
		GUICtrlSetStateStateful($hGUI.PathFromClip, $GUI_DISABLE)
		GUICtrlSetState($hGUI.ComboAvaVersion, $GUI_DISABLE)
		GUICtrlSetStateStateful($hGUI.RadioDownloadAndInstall, $GUI_DISABLE)
		GUICtrlSetStateStateful($hGUI.RadioOnlyDownload, $GUI_DISABLE)
		GUICtrlSetStateStateful($hGUI.ButtonSaveChangePath, $GUI_DISABLE)
		GUICtrlSetStateStateful($hGUI.ButtonCancel, $GUI_DISABLE)
		GUICtrlSetState($hGUI.ButtonStart, $GUI_DISABLE)
	EndIf
EndFunc
