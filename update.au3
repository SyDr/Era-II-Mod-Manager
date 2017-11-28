; Author:         Aliaksei SyDr Karalenka

#cs
this allows easy overwrite #AutoIt3Wrapper_Res_Fileversion via simple IniWrite
[Version]
#ce
#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Version=Beta
#AutoIt3Wrapper_Icon=icons\preferences-system.ico
#AutoIt3Wrapper_Outfile=update.exe
#AutoIt3Wrapper_Compression=4
#AutoIt3Wrapper_UseUpx=y
#AutoIt3Wrapper_Res_Description=A mod manager for Era II (update)
#AutoIt3Wrapper_Res_Fileversion=0.93.6.2
#AutoIt3Wrapper_Res_LegalCopyright=Aliaksei SyDr Karalenka
#AutoIt3Wrapper_Res_requestedExecutionLevel=asInvoker
#AutoIt3Wrapper_AU3Check_Parameters=-d -w 1 -w 2 -w 3 -w 4 -w 5 -w 6 -w 7
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
#include-once

#include "include_fwd.au3"

#include "lng.au3"
#include "settings.au3"
#include "utils.au3"


Global $__MM_UPDATE_HANDLE
Global $MM_UPDATE_IS_READY

If Not IsDeclared("__MAIN") Then
	Lng_LoadList()
	Settings_Get("")
	Update_CheckNewPorgram()
EndIf

Func Update_CheckNewPorgram()
	Local Const $iOptionGUIOnEventMode = AutoItSetOption("GUIOnEventMode", 0)
	Local Const $iOptionGUICoordMode = AutoItSetOption("GUICoordMode", 0)

	GUISetState(@SW_DISABLE, MM_GetCurrentWindow())
	Local Const $iMinWidth = 400
	Local Const $iItemSpacing = 4

	Local $hGUI = MapEmpty()
	$hGUI.Info = MapEmpty()
	$hGUI.Info.Download = True
	$hGUI.Setup = MapEmpty()
	$hGUI.Setup.Version = ""
	$hGUI.Close = False
	Local $bIsSuccess, $nMsg, $aSize, $iAnswer

	$hGUI.Form = MM_GUICreate(Lng_Get("update.caption"), $iMinWidth + Round(Random(0, (@DesktopWidth - $iMinWidth)/10, 1)), 173)
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
	GUICtrlSetState($hGUI.RadioOnlyDownload, $GUI_CHECKED)
	$hGUI.Setup.OnlyDownloadSetup = True

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
			Local $sFile = $hGUI.Info.Parsed[$hGUI.Setup.Version]["file"]

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
						Update_InstallUpdate($hGUI.Setup.Location)
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
	MM_GUIDelete()

	AutoItSetOption("GUIOnEventMode", $iOptionGUIOnEventMode)
	AutoItSetOption("GUICoordMode", $iOptionGUICoordMode)

	GUISetState(@SW_ENABLE, MM_GetCurrentWindow())
	GUISetState(@SW_RESTORE, MM_GetCurrentWindow())
EndFunc

Func Update_InstallUpdate(Const $sFilePath)
	Local $sDir
	If @Compiled Then
		__Update_ShowProgress()
		$sDir = _TempFile()
		DirCreate($sDir)
		RunWait(@ScriptDir & '\7z\7z.exe x "' & $sFilePath & '" -o' & '"' & $sDir & '" -aoa', @ScriptDir & "\7z\", @SW_HIDE)
		FileDelete($sFilePath)
		ShellExecute($sDir & "\Mod Manager\mmanager.exe", '/install "' & @ScriptDir & '"')
		Exit
	EndIf
EndFunc

Func Update_CopySelfTo(Const $sPath)
	;DirCopy(@ScriptDir, $sPath, $FC_OVERWRITE)
	Local $aFiles = _FileListToArrayRec(@ScriptDir, Default, Default, $FLTAR_RECUR)

	__Update_ShowProgress(True)
	For $i = 1 To $aFiles[0]
		FileCopy(@ScriptDir & "\" & $aFiles[$i], $sPath & "\" & $aFiles[$i], $FC_CREATEPATH +  $FC_OVERWRITE)
		ProgressSet($i/$aFiles[0]*100)
	Next

	ShellExecute($sPath & "\mmanager.exe")
	Exit
EndFunc

Func __Update_ShowProgress(Const $bSecond = False)
	ProgressOn(Lng_Get("update.progress.caption"), $bSecond ? Lng_Get("update.progress.unpack") : Lng_Get("update.progress.copy"))
EndFunc

Func __Update_SetupSelectionChanged(ByRef $hGUI, Const $sNewVersion)
	$hGUI.Setup.Version = StringTrimRight(StringMid($sNewVersion, StringInStr($sNewVersion, "(") + 1), 1)
EndFunc

Func __Update_GUIUpdateAccessibility(ByRef $hGUI)
	GUICtrlSetState($hGUI.ButtonStart, (Not $hGUI.Setup.InProgress And $hGUI.Setup.Version <> "") ? $GUI_ENABLE : $GUI_DISABLE)
	GUICtrlSetState($hGUI.ComboAvaVersion, (Not $hGUI.Setup.InProgress And $hGUI.Info.Valid) ? $GUI_ENABLE : $GUI_DISABLE)
	GUICtrlSetState($hGUI.PathRefresh, (Not $hGUI.Setup.InProgress And Not $hGUI.Info.InProgress) ? $GUI_ENABLE : $GUI_DISABLE)
	GUICtrlSetState($hGUI.RadioDownloadAndInstall, Not $hGUI.Setup.InProgress ? $GUI_ENABLE : $GUI_DISABLE)
	GUICtrlSetState($hGUI.RadioOnlyDownload, Not $hGUI.Setup.InProgress ? $GUI_ENABLE : $GUI_DISABLE)
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
		If Not MapExists($Map[$sItem], "file") Or Not IsString($Map[$sItem]["file"]) Then Return False
	Next

	Return True
EndFunc

Func AutoUpdate_Init()
	Local Const $sComplete = $MM_UPDATE_DIRECTORY & "\update.zip"

	If FileExists($sComplete) Then
		Settings_Set("update_last_check", _NowCalc())
		Update_InstallUpdate($sComplete)
	EndIf

	DirRemove($MM_UPDATE_DIRECTORY, 1)
	DirCreate($MM_UPDATE_DIRECTORY)
	AutoUpdate_Check()
EndFunc

Func AutoUpdate_Check()
	Local Const $sDowloadFrom = $MM_UPDATE_URL & "/mm.json"
	Local Const $sDowloadTo = $MM_UPDATE_DIRECTORY & "\update.json"

	If AutoUpdate_UpdateIsNeeded() Then
		AdlibUnRegister("AutoUpdate_Check")
		_Trace("Update, auto: download info")
		$__MM_UPDATE_HANDLE = InetGet($sDowloadFrom, $sDowloadTo, $INET_FORCERELOAD, $INET_DOWNLOADBACKGROUND)
		AutoUpdate_InfoCheck()
	Else
		AdlibRegister("AutoUpdate_Check", 4 * 60 * 60 * 1000)
	EndIf
EndFunc

Func AutoUpdate_UpdateIsNeeded()
	Local Const $iInterval = Settings_Get("update_interval")
	If $iInterval = 0 Then Return False

	Local Const $iDiff = _DateDiff("s", _NowCalc(), _DateAdd("D", $iInterval, Settings_Get("update_last_check")))
	_Trace(StringFormat("Update, auto: next update in %s seconds", $iDiff))

	Return $iDiff < 0
EndFunc

Func AutoUpdate_InfoCheck()
	If Not InetGetInfo($__MM_UPDATE_HANDLE, $INET_DOWNLOADCOMPLETE) Then
		AdlibRegister("AutoUpdate_InfoCheck", 4 * 1000)
		Return
	EndIf

	_Trace("Update, auto: info downloaded")
	AdlibUnRegister("AutoUpdate_InfoCheck")

	Local $bError = False
	If Not $bError Then
		$bError = Not InetGetInfo($__MM_UPDATE_HANDLE, $INET_DOWNLOADSUCCESS)
		If $bError Then _Trace(StringFormat("Update, auto: can't download info file (%s error)", InetGetInfo($__MM_UPDATE_HANDLE, $INET_DOWNLOADERROR)))
	EndIf

	InetClose($__MM_UPDATE_HANDLE)

	Local $sFileData, $mParsedInfo
	If Not $bError Then
		$sFileData = FileRead($MM_UPDATE_DIRECTORY & "\update.json")
		$bError = @error
		If $bError Then _Trace("Update, auto: can't read info file")
	EndIf

	If Not $bError Then
		$mParsedInfo = Jsmn_Decode($sFileData)
		$bError = @error
		If $bError Then _Trace("Update, auto: can't decode info file")
	EndIf

	If Not $bError Then
		$bError = Not __Update_InfoFileValidate($mParsedInfo)
		If $bError Then _Trace("Update, auto: bad info file")
	EndIf

	If Not $bError Then
;~ 		$bError = VersionCompare($mParsedInfo["info_version"], "1.4")
		If $bError Then _Trace("Update, auto: incorrect info file version")
	EndIf

	If Not $bError Then
		$bError = VersionCompare($mParsedInfo[$MM_VERSION_SUBTYPE]["version"], $MM_VERSION_NUMBER) <= 0
		If $bError Then _Trace("Update, auto: newest version installed")
		Settings_Set("update_last_check", _NowCalc())
	EndIf

	If Not $bError Then
		_Trace("Update, auto: new version detected")
		If Settings_Get("update_auto") Then
			$__MM_UPDATE_HANDLE = InetGet($MM_UPDATE_URL & $mParsedInfo[$MM_VERSION_SUBTYPE]["file"], $MM_UPDATE_DIRECTORY & "\update.partial", $INET_FORCERELOAD, $INET_DOWNLOADBACKGROUND)
			AutoUpdate_MainCheck()
		Else
			$MM_UPDATE_IS_READY = True
		EndIf
	Else
		AdlibRegister("AutoUpdate_Check", 4 * 60 * 60 * 1000)
	EndIf
EndFunc

Func AutoUpdate_MainCheck()
	If Not InetGetInfo($__MM_UPDATE_HANDLE, $INET_DOWNLOADCOMPLETE) Then
		AdlibRegister("AutoUpdate_MainCheck", 4 * 1000)
		Return
	EndIf

	_Trace("Update, auto: update downloaded")
	AdlibUnRegister("AutoUpdate_MainCheck")

	Local $bError = False
	If Not $bError Then
		$bError = Not InetGetInfo($__MM_UPDATE_HANDLE, $INET_DOWNLOADSUCCESS)
		If $bError Then _Trace("Update, auto: can't download update file")
	EndIf

	InetClose($__MM_UPDATE_HANDLE)

	If Not $bError Then
		_Trace("Update: new version downloaded")
		FileMove($MM_UPDATE_DIRECTORY & "\update.partial", $MM_UPDATE_DIRECTORY & "\update.zip", $FC_OVERWRITE)
	Else
		AdlibRegister("AutoUpdate_Check", 4 * 60 * 60 * 1000)
	EndIf
EndFunc


