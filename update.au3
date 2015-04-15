; Author:         Aliaksei SyDr Karalenka

#AutoIt3Wrapper_Version=Beta
#include-once

#include "include_fwd.au3"

#include "lng.au3"
#include "settings.au3"
#include "utils.au3"


Global $__MM_UPDATE[2] ; type (0 - none/wait for update, 1 - info, 2 - setup, 3 - complete), download handle

Func Update_CheckNewPorgram()
	Local Const $iOptionGUIOnEventMode = AutoItSetOption("GUIOnEventMode", 0)
	Local Const $iOptionGUICoordMode = AutoItSetOption("GUICoordMode", 0)

	GUISetState(@SW_DISABLE, $MM_UI_MAIN)
	Local Const $iMinWidth = 400
	Local Const $iItemSpacing = 4

	Local $hGUI = MapEmpty()
	$hGUI.Info = MapEmpty()
	$hGUI.Info.Download = True
	$hGUI.Setup = MapEmpty()
	$hGUI.Setup.Version = ""
	$hGUI.Close = False
	Local $bIsSuccess, $nMsg, $aSize, $iAnswer

	$hGUI.Form = GUICreate(Lng_Get("update.caption"), $iMinWidth + Round(Random(0, (@DesktopWidth - $iMinWidth)/10, 1)), 173, Default, Default, Default, Default, $MM_UI_MAIN)
	If Not @Compiled Then GUISetIcon(@ScriptDir & "\icons\preferences-system.ico")
	$aSize = WinGetClientSize($hGUI.Form)

	$hGUI.GroupParam = GUICtrlCreateGroup(Lng_Get("update.caption"), $iItemSpacing, $iItemSpacing, $aSize[0] - 2 * $iItemSpacing, 62)
	$hGUI.LabelCurVersion = GUICtrlCreateLabel(Lng_GetF("update.current_version", $MM_VERSION), 2 * $iItemSpacing, 4 * $iItemSpacing, Default, 17, $SS_CENTERIMAGE)
	$hGUI.LabelAvaVersion = GUICtrlCreateLabel(Lng_Get("update.available_versions"), 0, GUICtrlGetPos($hGUI.LabelCurVersion).Height + $iItemSpacing, Default, 17, $SS_CENTERIMAGE)
	$hGUI.ComboAvaVersion = GUICtrlCreateCombo(Lng_Get("update.wait"), GUICtrlGetPos($hGUI.LabelAvaVersion).Width, 0, $aSize[0] - GUICtrlGetPos($hGUI.LabelAvaVersion).Width - 50 - 6 * $iItemSpacing + 3, 17, BitOR($CBS_DROPDOWNLIST, $CBS_AUTOHSCROLL))
	$hGUI.PathRefresh = GUICtrlCreateButton("", GUICtrlGetPos($hGUI.ComboAvaVersion).Width + 0, -2, 25, 25, $BS_ICON)
	$hGUI.PathFromClip = GUICtrlCreateButton("", GUICtrlGetPos($hGUI.PathRefresh).Width + 0, 0, 25, 25, $BS_ICON)
	GUISetCoord(0, GUICtrlGetPos($hGUI.GroupParam).Top)

	$hGUI.GroupUpdate = GUICtrlCreateGroup(Lng_Get("update.update_group"), $iItemSpacing, GUICtrlGetPos($hGUI.GroupParam).Height, $aSize[0] - 2 * $iItemSpacing, 104)
	$hGUI.RadioDownloadAndInstall = GUICtrlCreateRadio(Lng_Get("update.download_and_install"), 2 * $iItemSpacing, 4 * $iItemSpacing, Default, 17, $BS_VCENTER)
	$hGUI.RadioOnlyDownload = GUICtrlCreateRadio(Lng_Get("update.only_download"), 0, GUICtrlGetPos($hGUI.RadioDownloadAndInstall).Height, Default, 17)
	$hGUI.InputSaveTo = GUICtrlCreateInput(@DesktopDir, 17, GUICtrlGetPos($hGUI.RadioOnlyDownload).Height, $aSize[0] - 75 - 10 * $iItemSpacing, 21)
	GUICtrlSetState($hGUI.InputSaveTo, $GUI_DISABLE)
	$hGUI.ButtonSaveChangePath = GUICtrlCreateButton(Lng_Get("update.change_dir"), GUICtrlGetPos($hGUI.InputSaveTo).Width + $iItemSpacing, -2, 75, 25)
	GUISetCoord(0, GUICtrlGetPos($hGUI.InputSaveTo).Top)

	$hGUI.ProgressDownload = GUICtrlCreateProgress(2 * $iItemSpacing, GUICtrlGetPos($hGUI.InputSaveTo).Height + $iItemSpacing, $aSize[0] - 6 * $iItemSpacing - 150 + 1, 21)
	$hGUI.ButtonStart = GUICtrlCreateButton(Lng_Get("update.start"), GUICtrlGetPos($hGUI.ProgressDownload).Width + $iItemSpacing, -2, 75, 25)
	$hGUI.ButtonCancel = GUICtrlCreateButton(Lng_Get("update.close"), GUICtrlGetPos($hGUI.ButtonStart).Width + $iItemSpacing, 0, 75, 25)

	GUICtrlSetImage($hGUI.PathRefresh, @ScriptDir & "\icons\view-refresh.ico")
	GUICtrlSetImage($hGUI.PathFromClip, @ScriptDir & "\icons\edit-copy.ico")
	GUICtrlSetState($MM_PORTABLE ? $hGUI.RadioOnlyDownload : $hGUI.RadioDownloadAndInstall, $GUI_CHECKED)
	$hGUI.Setup.OnlyDownloadSetup = $MM_PORTABLE ? True : False
	$hGUI.Setup.OnlyPortable = $MM_PORTABLE

	GUISetState(@SW_SHOW)

	While Not $hGUI.Close
		If $hGUI.Info.InProgress Then
			If InetGetInfo($hGUI.Info.Handle, $INET_DOWNLOADCOMPLETE) Then
				$hGUI.Info.InProgress = False

				$bIsSuccess = InetGetInfo($hGUI.Info.Handle, $INET_DOWNLOADSUCCESS)
				InetClose($hGUI.Info.Handle)

				If $bIsSuccess Then
					__Update_InfoFileProcess($hGUI, FileRead($hGUI.Info.Location))
				Else
					$hGUI.Info.Valid = False
					$iAnswer = MsgBox($MB_YESNO + $MB_ICONQUESTION + $MB_TASKMODAL, "", Lng_Get("update.cant_check"), Default, $hGUI.Form)
					If $iAnswer = $IDYES Then Utils_LaunchInBrowser($MM_UPDATE_URL & "/mm.html")
				EndIf
				__Update_GUIUpdateInfoView($hGUI)
				__Update_GUIUpdateAccessibility($hGUI)
			EndIf
		EndIf

		If $hGUI.Info.Download Then
			$hGUI.Info.Download = False
			$hGUI.Info.Location = _TempFile()
			$hGUI.Info.Handle = InetGet($MM_UPDATE_URL & "/mm.json", $hGUI.Info.Location, $INET_FORCERELOAD, $INET_DOWNLOADBACKGROUND)
			$hGUI.Info.InProgress = True
			$hGUI.Info.Valid = False
			__Update_GUIUpdateInfoView($hGUI)
			__Update_GUIUpdateAccessibility($hGUI)
		EndIf

		If $hGUI.Info.FromClipboard Then
			$hGUI.Info.FromClipboard = False
			__Update_InfoFileProcess($hGUI, ClipGet())
			__Update_GUIUpdateInfoView($hGUI)
			__Update_GUIUpdateAccessibility($hGUI)
		EndIf

		If $hGUI.ChangeDownloadSelected Then
			$hGUI.ChangeDownloadSelected = False
			__Update_SetupSelectionChanged($hGUI, GUICtrlRead($hGUI.ComboAvaVersion))
			__Update_GUIUpdateAccessibility($hGUI)
		EndIf

		If $hGUI.ChangeSetupType Then
			$hGUI.ChangeSetupType = False
			If ($hGUI.Setup.OnlyDownloadSetup And BitAND(GUICtrlRead($hGUI.RadioDownloadAndInstall), $GUI_CHECKED) = $GUI_CHECKED) Or _
				(Not $hGUI.Setup.OnlyDownloadSetup  And BitAND(GUICtrlRead($hGUI.RadioOnlyDownload), $GUI_CHECKED) = $GUI_CHECKED) Then
				$hGUI.Setup.OnlyDownloadSetup = Not $hGUI.Setup.OnlyDownloadSetup
				__Update_GUIUpdateAccessibility($hGUI)
				EndIf
		EndIf

		If $hGUI.ChangeDownloadPath Then
			$hGUI.ChangeDownloadPath = False
			Local $sPath = FileSelectFolder(Lng_Get("update.select_dir"), "", Default, "", $hGUI.Form)
			If Not @error And $sPath <> "" Then GUICtrlSetData($hGUI.InputSaveTo, $sPath)
		EndIf

		If $hGUI.Setup.Download Then
			$hGUI.Setup.Download = False
			Local $sType = $MM_PORTABLE ? "portable" : "setup"
			Local $sFile = $hGUI.Info.Parsed[$hGUI.Setup.Version][$sType]

			$hGUI.Setup.Location = __Update_GetSaveToFile(GUICtrlRead($hGUI.InputSaveTo), $sFile, Not $hGUI.Setup.OnlyDownloadSetup)
			$hGUI.Setup.Handle = InetGet($hGUI.Info.Parsed["base_path"] & $sFile, $hGUI.Setup.Location, Default, $INET_DOWNLOADBACKGROUND)
			$hGUI.Setup.InProgress = True
			__Update_GUIUpdateInfoView($hGUI, True)
			__Update_GUIUpdateAccessibility($hGUI)
		EndIf

		If $hGUI.Setup.InProgress Then
			GUICtrlSetData($hGUI.ProgressDownload, InetGetInfo($hGUI.Setup.Handle, $INET_DOWNLOADREAD) / InetGetInfo($hGUI.Setup.Handle, $INET_DOWNLOADSIZE) * 100)

			If InetGetInfo($hGUI.Setup.Handle, $INET_DOWNLOADCOMPLETE) Or $hGUI.Cancel Then
				$hGUI.Setup.InProgress = False

				$bIsSuccess = InetGetInfo($hGUI.Setup.Handle, $INET_DOWNLOADSUCCESS)
				InetClose($hGUI.Setup.Handle)

				If $hGUI.Cancel Or Not $bIsSuccess Then
					FileDelete($hGUI.Setup.Location)
					GUICtrlSetData($hGUI.ProgressDownload, 0)
				EndIf

				If Not $hGUI.Cancel Then
					If Not $bIsSuccess Then
						$iAnswer = MsgBox($MB_YESNO + $MB_ICONQUESTION + $MB_TASKMODAL, "", Lng_Get("update.cant_download"), Default, $hGUI.Form)
						If $iAnswer = $IDYES Then Utils_LaunchInBrowser($hGUI.Info.Parsed["base_path"] & $sFile)
					ElseIf Not $hGUI.Setup.OnlyDownloadSetup Then
						ShellExecute($hGUI.Setup.Location, "/SILENT")
						If @OSVersion = "WIN_XP" Then
							Exit
						Else
							$hGUI.Close = True
						EndIf
					EndIf
				EndIf

				$hGUI.Cancel = False

				__Update_GUIUpdateInfoView($hGUI, True)
				__Update_GUIUpdateAccessibility($hGUI)
			EndIf
		EndIf

		$nMsg = GUIGetMsg()
		Switch $nMsg
			Case $GUI_EVENT_CLOSE, $hGUI.ButtonCancel
				If $hGUI.Setup.InProgress Then
					$hGUI.Cancel = True
				Else
					$hGUI.Close = True
				EndIf
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
	WEnd

	InetClose($hGUI.Info.Handle)
	GUIDelete($hGUI.Form)

	AutoItSetOption("GUIOnEventMode", $iOptionGUIOnEventMode)
	AutoItSetOption("GUICoordMode", $iOptionGUICoordMode)

	GUISetState(@SW_ENABLE, $MM_UI_MAIN)
	GUISetState(@SW_RESTORE, $MM_UI_MAIN)
EndFunc

Func Update_Init()
	Local Const $sUpdateFile = $MM_DATA_DIRECTORY & "\update\complete.txt"
	Local Const $sExeName = $MM_DATA_DIRECTORY & "\update\setup.exe"

	If FileExists($sExeName) And FileExists($sUpdateFile) Then
		FileDelete($sUpdateFile)
		ShellExecute($sExeName, "/SILENT")
		Exit
	EndIf

	DirRemove($MM_DATA_DIRECTORY & "\update\", 1)

	If Update_UpdateNeeded() Then
		DirCreate($MM_DATA_DIRECTORY & "\update")
		_TracePoint("Update: download info")
		$__MM_UPDATE[0] = 1
		$__MM_UPDATE[1] = InetGet($MM_UPDATE_URL & "/mm.json", $MM_DATA_DIRECTORY & "\update\setup.json", $INET_FORCERELOAD, $INET_DOWNLOADBACKGROUND)
		AdlibRegister("__Update_AutoCycle", 3000)
	EndIf
EndFunc

Func Update_UpdateNeeded()
	Local Const $sLastUpdateCheck = Settings_Get("update_last_check")
	Local Const $iInterval = Settings_Get("update_interval")
	Local Const $sNow = _NowCalc()

	If $iInterval = 0 Then Return False
	Local Const $iDiff = _DateDiff("s", $sNow, _DateAdd("D", $iInterval, $sLastUpdateCheck))
	_TracePoint(StringFormat("Update: next update in %s seconds", $iDiff))

	Return $iDiff < 0
EndFunc

Func __Update_AutoCycle()
	If $__MM_UPDATE[0] = 0 Then
		AdlibUnRegister("__Update_AutoCycle")
		Return
	EndIf

	If $__MM_UPDATE[0] = 1 Or $__MM_UPDATE[0] = 2 Then
		If Not InetGetInfo($__MM_UPDATE[1], $INET_DOWNLOADCOMPLETE) Then Return
		If Not InetGetInfo($__MM_UPDATE[1], $INET_DOWNLOADSUCCESS) Then
			$__MM_UPDATE[0] = 0 ; will unregister itself on next function run
			Return
		EndIf
	EndIf

	Local $hParsedInfo

	If $__MM_UPDATE[0] = 1 Then
		_TracePoint("Update: info loaded")
		InetClose($__MM_UPDATE[1])
		$hParsedInfo = Jsmn_Decode(FileRead($MM_DATA_DIRECTORY & "\update\setup.json"))

		If Not __Update_InfoFileValidate($hParsedInfo) Then
			$__MM_UPDATE[0] = 0
		ElseIf VersionCompare($hParsedInfo[$MM_VERSION_SUBTYPE]["version"], $MM_VERSION_NUMBER) = 0 Then
			_TracePoint("Update: same version detected")
			$__MM_UPDATE[0] = 0
			Settings_Set("update_last_check", _NowCalc())
		ElseIf VersionCompare($hParsedInfo[$MM_VERSION_SUBTYPE]["version"], $MM_VERSION_NUMBER) < 0 Then
			_TracePoint("Update: installed version is newer >_<")
			$__MM_UPDATE[0] = 0
			Settings_Set("update_last_check", _NowCalc())
		ElseIf Settings_Get("update_auto") Then
			_TracePoint("Update: new version detected")
			$__MM_UPDATE[0] = 2
			$__MM_UPDATE[1] = InetGet($MM_UPDATE_URL & $hParsedInfo[$MM_VERSION_SUBTYPE]["setup"], $MM_DATA_DIRECTORY & "\update\setup.exe", $INET_FORCERELOAD, $INET_DOWNLOADBACKGROUND)
		Else
			$__MM_UPDATE[0] = 3
		EndIf

	ElseIf $__MM_UPDATE[0] = 2 Then
		$__MM_UPDATE[0] = 0
		_TracePoint("Update: new version downloaded")
		FileClose(FileOpen($MM_DATA_DIRECTORY & "\update\complete.txt", $FO_OVERWRITE))
		Settings_Set("update_last_check", _NowCalc())
	ElseIf $__MM_UPDATE[0] = 3 Then
		$__MM_UPDATE[0] = 0
		Settings_Set("update_last_check", _NowCalc())
		If MsgBox($MB_YESNO + $MB_ICONQUESTION + $MB_SYSTEMMODAL, "", Lng_Get("update.new_version_available"), Default, $MM_UI_MAIN) = $IDYES Then Update_CheckNewPorgram()
	EndIf
EndFunc

Func __Update_SetupSelectionChanged(ByRef $hGUI, Const $sNewVersion)
	$hGUI.Setup.Version = StringTrimRight(StringMid($sNewVersion, StringInStr($sNewVersion, "(") + 1), 1)
EndFunc

Func __Update_GUIUpdateAccessibility(ByRef $hGUI)
	GUICtrlSetState($hGUI.ButtonStart, (Not $hGUI.Setup.InProgress And $hGUI.Setup.Version <> "") ? $GUI_ENABLE : $GUI_DISABLE)
	GUICtrlSetState($hGUI.ComboAvaVersion, (Not $hGUI.Setup.InProgress And $hGUI.Info.Valid) ? $GUI_ENABLE : $GUI_DISABLE)
	GUICtrlSetState($hGUI.PathRefresh, (Not $hGUI.Setup.InProgress And Not $hGUI.Info.InProgress) ? $GUI_ENABLE : $GUI_DISABLE)
	GUICtrlSetState($hGUI.RadioDownloadAndInstall, (Not $hGUI.Setup.InProgress And Not $hGUI.Setup.OnlyPortable) ? $GUI_ENABLE : $GUI_DISABLE)
	GUICtrlSetState($hGUI.RadioOnlyDownload, (Not $hGUI.Setup.InProgress And Not $hGUI.Setup.OnlyPortable) ? $GUI_ENABLE : $GUI_DISABLE)
	GUICtrlSetState($hGUI.PathFromClip, (Not $hGUI.Setup.InProgress And Not $hGUI.Info.InProgress And Not $hGUI.Info.Valid) ? $GUI_ENABLE : $GUI_DISABLE)
	GUICtrlSetState($hGUI.ButtonSaveChangePath, (Not $hGUI.Setup.InProgress And $hGUI.Setup.OnlyDownloadSetup) ? $GUI_ENABLE : $GUI_DISABLE)
EndFunc

Func __Update_GUIUpdateInfoView(ByRef $hGUI, Const $bOnlyCancelButton = False)
	If Not $bOnlyCancelButton Then
		If $hGUI.Info.InProgress Then
			GUICtrlSetData($hGUI.ComboAvaVersion, "|" & Lng_Get("update.wait"), Lng_Get("update.wait"))
		ElseIf Not $hGUI.Info.Valid Then
			GUICtrlSetData($hGUI.ComboAvaVersion, "|" & Lng_Get("update.info_invalid"), Lng_Get("update.info_invalid"))
		Else
			GUICtrlSetData($hGUI.ComboAvaVersion, "|" & $hGUI.Info.ParsedKeys, _
				$hGUI.Info.Parsed[$MM_VERSION_SUBTYPE]["version"] & " (" & $MM_VERSION_SUBTYPE & ")")
			__Update_SetupSelectionChanged($hGUI, GUICtrlRead($hGUI.ComboAvaVersion))
		EndIf
	EndIf

	GUICtrlSetData($hGUI.ButtonCancel, $hGUI.Setup.InProgress ? Lng_Get("update.cancel") : Lng_Get("update.close"))
EndFunc

Func __Update_GetSaveToFile($sDir, $sFile, $bSaveToTemp)
	If $bSaveToTemp Then
		$sDir = _TempFile(@TempDir)
		DirCreate($sDir)
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

Func __Update_InfoFileProcess(ByRef $hGUI, Const $sFile)
	$hGUI.Info.Parsed = Jsmn_Decode($sFile)
	$hGUI.Info.Valid = __Update_InfoFileValidate($hGUI.Info.Parsed)
	$hGUI.Setup.Version = ""

	If $hGUI.Info.Valid Then
		$hGUI.Info.ParsedKeys = $hGUI.Info.Parsed["release"]["version"] & " (release)|" & $hGUI.Info.Parsed["beta"]["version"] & " (beta)"
	EndIf
EndFunc

Func __Update_InfoFileValidate($Map)
	If Not IsMap($Map) Then Return False
	If Not MapExists($Map, "info_version") Or Not IsString($Map["info_version"]) Then Return False
	If Not MapExists($Map, "base_path") Or Not IsString($Map["base_path"]) Then Return False

	Local $sSetupTypes = ["release", "beta"]
	For $sItem In $sSetupTypes
		If Not MapExists($Map, $sItem) Or Not IsMap($Map[$sItem]) Then Return False
		If Not MapExists($Map[$sItem], "version") Or Not IsString($Map[$sItem]["version"]) Then Return False
		If Not MapExists($Map[$sItem], "setup") Or Not IsString($Map[$sItem]["setup"]) Then Return False
		If Not MapExists($Map[$sItem], "portable") Or Not IsString($Map[$sItem]["portable"]) Then Return False
	Next

	Return True
EndFunc
