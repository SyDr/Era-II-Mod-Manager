; Author:         Aliaksei SyDr Karalenka

#AutoIt3Wrapper_Version=Beta
#include-once

#include "include_fwd.au3"

#include "lng.au3"
#include "presets.au3"
#include "settings.au3"
#include "utils.au3"

Global $__UI_EVENT = False, $__UI_LIST, $__UI_INPUT

Func UI_GameExeLaunch()
	If $MM_COMPATIBILITY_MESSAGE <> "" Then
		Local $iAnswer = MsgBox($MB_SYSTEMMODAL + $MB_YESNO, "", $MM_COMPATIBILITY_MESSAGE & @CRLF & Lng_Get("compatibility.launch_anyway"), Default, MM_GetCurrentWindow())
		If $iAnswer <> $IDYES Then Return
	EndIf

	Run($MM_GAME_DIR & "\" & $MM_GAME_EXE, $MM_GAME_DIR)
EndFunc

Func UI_Settings()
	GUISetState(@SW_DISABLE, MM_GetCurrentWindow())
	Local Const $iOptionGUIOnEventMode = AutoItSetOption("GUIOnEventMode", 0)
	Local Const $iItemSpacing = 4
	Local $bClose = False
	Local $bSave = False

	Local $hGUI = MM_GUICreate(Lng_Get("settings.menu.settings"), 370, 130)
	Local $aSize = WinGetClientSize($hGUI)
	If Not @Compiled Then GUISetIcon(@ScriptDir & "\icons\preferences-system.ico")

	Local $hGroupListLoad = GUICtrlCreateGroup(Lng_Get("settings.list_load_options.group"), $iItemSpacing, $iItemSpacing + $iItemSpacing, _
		$aSize[0] - 2 * $iItemSpacing, $aSize[1] - 3 * $iItemSpacing - 25)
	Local $hCheckboxExe = GUICtrlCreateCheckbox(Lng_Get("settings.list_load_options.exe"), 2 * $iItemSpacing, GUICtrlGetPos($hGroupListLoad).Top + 5 * $iItemSpacing, Default, 17)
	Local $hCheckboxSet = GUICtrlCreateCheckbox(Lng_Get("settings.list_load_options.wog_settings"), 2 * $iItemSpacing, GUICtrlGetPos($hCheckboxExe).NextY + $iItemSpacing, Default, 17)
	Local $hCheckboxDontAsk = GUICtrlCreateCheckbox(Lng_Get("settings.list_load_options.dont_ask"), 2 * $iItemSpacing, GUICtrlGetPos($hCheckboxSet).NextY + $iItemSpacing, Default, 17)

	GUICtrlSetState($hCheckboxExe, Settings_Get("list_exe") ? $GUI_CHECKED : $GUI_UNCHECKED)
	GUICtrlSetState($hCheckboxSet, Settings_Get("list_wog_settings") ? $GUI_CHECKED : $GUI_UNCHECKED)
	GUICtrlSetState($hCheckboxDontAsk, Settings_Get("list_no_ask") ? $GUI_CHECKED : $GUI_UNCHECKED)

	Local $hOk = GUICtrlCreateButton("OK", $aSize[0] - $iItemSpacing - 75, $aSize[1] - $iItemSpacing - 25, 75, 25)

	GUISetState(@SW_SHOW)

	While Not $bClose And Not $bSave
		Switch GUIGetMsg()
			Case $GUI_EVENT_CLOSE
				$bClose = True
			Case $hOk
				$bSave = True
		EndSwitch
	WEnd

	If $bSave Then
		Settings_Set("list_exe", GUICtrlRead($hCheckboxExe) = $GUI_CHECKED)
		Settings_Set("list_wog_settings", GUICtrlRead($hCheckboxSet) = $GUI_CHECKED)
		Settings_Set("list_no_ask", GUICtrlRead($hCheckboxDontAsk) = $GUI_CHECKED)
	EndIf

	MM_GUIDelete()

	AutoItSetOption("GUIOnEventMode", $iOptionGUIOnEventMode)
	GUISetState(@SW_ENABLE, MM_GetCurrentWindow())
	GUISetState(@SW_RESTORE, MM_GetCurrentWindow())
EndFunc

Func UI_Import_Scn()
	Local $mAnswer = MapEmpty()
	$mAnswer["selected"] = False
	$mAnswer["only_load"] = Settings_Get("list_only_load")

	Local $bClose = False, $bSelected = False, $mParsed, $iUserChoice

	GUISetState(@SW_DISABLE, MM_GetCurrentWindow())

	Local Const $iOptionGUIOnEventMode = AutoItSetOption("GUIOnEventMode", 0)
	Local Const $iItemSpacing = 4

	Local $hGUI = MM_GUICreate(Lng_Get("scenarios.import.caption"), 460, 436)
	Local $aSize = WinGetClientSize($hGUI)
	If Not @Compiled Then GUISetIcon(@ScriptDir & "\icons\preferences-system.ico")

	Local $hEdit = GUICtrlCreateEdit("", $iItemSpacing, $iItemSpacing, $aSize[0] - 2 * $iItemSpacing, 400, $ES_MULTILINE)
	GUICtrlSetData($hEdit, ClipGet())

	Local $hCheckOnlyLoad = GUICtrlCreateCheckbox(Lng_Get("scenarios.import.only_load"), $iItemSpacing, GUICtrlGetPos($hEdit).NextY + $iItemSpacing, Default, 17)
	Local $hOk = GUICtrlCreateButton("OK", $aSize[0] - $iItemSpacing - 75, GUICtrlGetPos($hEdit).NextY + $iItemSpacing, 75, 25)
	GUICtrlSetState($hCheckOnlyLoad, $mAnswer["only_load"] ? $GUI_CHECKED : $GUI_UNCHECKED)

	GUISetState(@SW_SHOW)

	While Not $bClose And Not $bSelected
		Switch GUIGetMsg()
			Case $GUI_EVENT_CLOSE
				$bClose = True
			Case $hOk
				$mAnswer["only_load"] = GUICtrlRead($hCheckOnlyLoad) = $GUI_CHECKED
				$mParsed = Scn_LoadData(GUICtrlRead($hEdit))
				If Not $mAnswer["only_load"] And Not $mParsed["name"] Then
					MsgBox($MB_OK + $MB_ICONINFORMATION + $MB_TASKMODAL, "", Lng_Get("scenarios.import.not_valid"))
					ContinueLoop
				ElseIf Not $mAnswer["only_load"] And Scn_Exist($mParsed["name"]) Then
					$iUserChoice = MsgBox($MB_YESNO + $MB_ICONQUESTION + $MB_DEFBUTTON2 + $MB_TASKMODAL, "", Lng_Get("scenarios.import.replace"))
					If $iUserChoice <> $IDYES Then ContinueLoop
				EndIf

				$mAnswer = UI_SelectScnLoadOptions($mParsed)
				If $mAnswer["selected"] Then $bSelected = True
		EndSwitch
	WEnd

	If $bSelected Then
		$mAnswer["selected"] = True
		$mAnswer["only_load"] = GUICtrlRead($hCheckOnlyLoad) = $GUI_CHECKED
		$mAnswer["data"] = $mParsed
		$mAnswer["name"] = $mAnswer["data"]["name"]
		Settings_Set("list_only_load", $mAnswer["only_load"])
	EndIf

	MM_GUIDelete()

	AutoItSetOption("GUIOnEventMode", $iOptionGUIOnEventMode)
	GUISetState(@SW_ENABLE, MM_GetCurrentWindow())
	GUISetState(@SW_RESTORE, MM_GetCurrentWindow())

	Return $mAnswer
EndFunc

Func __UI_ScnSetCurrentData(ByRef $mMap)
	$mMap["current_data"] = $mMap["export_data"]
	$mMap["current_data"]["name"] = $mMap["name"]
	$mMap["current_data"]["exe"] = $mMap["exe"] ? $mMap["export_data"]["exe"] : ""
	$mMap["current_data"]["wog_settings"] = $mMap["wog_settings"] ? $mMap["export_data"]["wog_settings"] : ""
EndFunc

Func UI_ScnExport(Const $mData = "")
	Local $mAnswer = MapEmpty()
	If Not IsMap($mData) Then
		$mAnswer["name"] = Lng_Get("scenarios.export.name")
		$mAnswer["exe"] = True
		$mAnswer["wog_settings"] = True
		$mAnswer["export_data"] = Scn_GetCurrentState($mAnswer)
	Else
		$mAnswer["export_data"] = $mData
		$mAnswer["name"] = $mData["name"]
	EndIf

	$mAnswer["exe"] = $mAnswer["export_data"]["exe"] And Settings_Get("list_exe")
    $mAnswer["wog_settings"] = $mAnswer["export_data"]["wog_settings"] And Settings_Get("list_wog_settings")
	__UI_ScnSetCurrentData($mAnswer)

	Local $bClose = False

	GUISetState(@SW_DISABLE, MM_GetCurrentWindow())

	Local Const $iOptionGUIOnEventMode = AutoItSetOption("GUIOnEventMode", 0)
	Local Const $iItemSpacing = 4

	Local $hGUI = MM_GUICreate(Lng_Get("scenarios.export.caption"), 460, 486)
	Local $aSize = WinGetClientSize($hGUI)
	If Not @Compiled Then GUISetIcon(@ScriptDir & "\icons\preferences-system.ico")
	GUIRegisterMsgStateful($WM_COMMAND, "__UI_WM_COMMAND")

	Local $hEdit = GUICtrlCreateEdit("", $iItemSpacing, $iItemSpacing, $aSize[0] - 2 * $iItemSpacing, 400, BitOR($ES_MULTILINE, $ES_READONLY))
	GUICtrlSetData($hEdit, Jsmn_Encode($mAnswer["current_data"], $JSMN_PRETTY_PRINT + $JSMN_UNESCAPED_UNICODE))
	Local $hCheckExe = GUICtrlCreateCheckbox(Lng_Get("scenarios.save_options.exe"), $iItemSpacing, GUICtrlGetPos($hEdit).NextY + $iItemSpacing, Default, 17)
	$__UI_INPUT = GUICtrlCreateInput($mAnswer["name"], $aSize[0] - $iItemSpacing - 150, GUICtrlGetPos($hEdit).NextY + $iItemSpacing, 150, 21)
	Local $hCheckSet = GUICtrlCreateCheckbox(Lng_Get("scenarios.save_options.wog_settings"), $iItemSpacing, GUICtrlGetPos($hCheckExe).NextY + $iItemSpacing, Default, 17)
	Local $hLine = GUICtrlCreateGraphic($iItemSpacing, GUICtrlGetPos($hCheckSet).NextY + $iItemSpacing, $aSize[0] - 2 * $iItemSpacing, 1)
	GUICtrlSetGraphic($hLine, $GUI_GR_LINE, $aSize[0] - 2 * $iItemSpacing, 0)

	Local $hCopy = GUICtrlCreateButton(Lng_Get("scenarios.export.copy"), $iItemSpacing, GUICtrlGetPos($hLine).NextY + $iItemSpacing, 100, 25)
	Local $hOk = GUICtrlCreateButton("OK", $aSize[0] - $iItemSpacing - 75, GUICtrlGetPos($hLine).NextY + $iItemSpacing, 75, 25)
	GUICtrlSetImage($hCopy, @ScriptDir & "\icons\edit-copy.ico")

	GUICtrlSetState($hCheckExe, $mAnswer["export_data"]["exe"] And $mAnswer["exe"] ? $GUI_CHECKED : $GUI_UNCHECKED)
	GUICtrlSetState($hCheckExe, $mAnswer["export_data"]["exe"] ? $GUI_ENABLE : $GUI_DISABLE)
	GUICtrlSetState($hCheckSet, $mAnswer["export_data"]["wog_settings"] And $mAnswer["wog_settings"] ? $GUI_CHECKED : $GUI_UNCHECKED)
	GUICtrlSetState($hCheckSet, $mAnswer["export_data"]["wog_settings"] ? $GUI_ENABLE : $GUI_DISABLE)

	GUISetState(@SW_SHOW)

	While Not $bClose
		Switch GUIGetMsg()
			Case $GUI_EVENT_CLOSE, $hOk
				$bClose = True
			Case $hCheckExe, $hCheckSet
				$mAnswer["exe"] = GUICtrlRead($hCheckExe) = $GUI_CHECKED
				$mAnswer["wog_settings"] = GUICtrlRead($hCheckSet) = $GUI_CHECKED
				__UI_ScnSetCurrentData($mAnswer)
				GUICtrlSetData($hEdit, Jsmn_Encode($mAnswer["current_data"], $JSMN_PRETTY_PRINT + $JSMN_UNESCAPED_UNICODE))
			Case $hCopy
				ClipPut(GUICtrlRead($hEdit))
		EndSwitch

		If $__UI_EVENT Then
			$__UI_EVENT = False
			$mAnswer["name"] = GUICtrlRead($__UI_INPUT)
			__UI_ScnSetCurrentData($mAnswer)
			GUICtrlSetData($hEdit, Jsmn_Encode($mAnswer["current_data"], $JSMN_PRETTY_PRINT + $JSMN_UNESCAPED_UNICODE))
		EndIf
	WEnd

	GUIRegisterMsgStateful($WM_COMMAND, "")
	MM_GUIDelete()

	AutoItSetOption("GUIOnEventMode", $iOptionGUIOnEventMode)
	GUISetState(@SW_ENABLE, $MM_UI_MAIN)
	GUISetState(@SW_RESTORE, $MM_UI_MAIN)
EndFunc

Func UI_SelectScnLoadOptions(Const ByRef $mData)
	Local $mAnswer = MapEmpty(), $bSkip = Settings_Get("list_no_ask")
	$mAnswer["selected"] = False
	$mAnswer["exe"] = $mData["exe"] And Settings_Get("list_exe")
	$mAnswer["wog_settings"] = $mData["wog_settings"] And Settings_Get("list_wog_settings")

	If ($bSkip And Not _IsPressed("10")) Or (Not $mData["exe"] And Not $mData["wog_settings"]) Then
		$mAnswer["selected"] = True
		Return $mAnswer
	EndIf

	GUISetState(@SW_DISABLE, MM_GetCurrentWindow())

	Local Const $iOptionGUIOnEventMode = AutoItSetOption("GUIOnEventMode", 0)
	Local Const $iItemSpacing = 4
	Local $bClose = False, $bSelected = False

	Local $hGUI = MM_GUICreate(Lng_Get("scenarios.load_options.caption"), 420, 80)
	Local $aSize = WinGetClientSize($hGUI)
	If Not @Compiled Then GUISetIcon(@ScriptDir & "\icons\preferences-system.ico")

	Local $hCheckExe = GUICtrlCreateCheckbox(Lng_GetF("scenarios.load_options.exe", $mData["exe"]), $iItemSpacing, $iItemSpacing, Default, 17)
	Local $hCheckSet = GUICtrlCreateCheckbox(Lng_Get("scenarios.load_options.wog_settings"), $iItemSpacing, GUICtrlGetPos($hCheckExe).NextY + $iItemSpacing, Default, 17)
	Local $hLine = GUICtrlCreateGraphic($iItemSpacing, GUICtrlGetPos($hCheckSet).NextY + $iItemSpacing, $aSize[0] - 2 * $iItemSpacing, 1)
	GUICtrlSetGraphic($hLine, $GUI_GR_LINE, $aSize[0] - 2 * $iItemSpacing, 0)

	Local $hCheckNotAgain = GUICtrlCreateCheckbox(Lng_Get("scenarios.load_options.not_again"), $iItemSpacing, GUICtrlGetPos($hLine).NextY + $iItemSpacing, Default, 17)
	Local $hOk = GUICtrlCreateButton("OK", $aSize[0] - $iItemSpacing - 75, GUICtrlGetPos($hCheckNotAgain).Top, 75, 25)

	GUICtrlSetState($hCheckExe, $mAnswer["exe"] ? $GUI_CHECKED : $GUI_UNCHECKED)
	GUICtrlSetState($hCheckExe, $mData["exe"] ? $GUI_ENABLE : $GUI_DISABLE)
	GUICtrlSetState($hCheckSet, $mAnswer["wog_settings"] ? $GUI_CHECKED : $GUI_UNCHECKED)
	GUICtrlSetState($hCheckSet, $mData["wog_settings"] ? $GUI_ENABLE : $GUI_DISABLE)
	GUICtrlSetState($hCheckNotAgain, $bSkip ? $GUI_CHECKED : $GUI_UNCHECKED)

	GUISetState(@SW_SHOW)

	While Not $bClose And Not $bSelected
		Switch GUIGetMsg()
			Case $GUI_EVENT_CLOSE
				$bClose = True
			Case $hOk
				$bSelected = True
		EndSwitch
	WEnd

	If $bSelected Then
		$mAnswer["selected"] = True
		If $mData["exe"] Then Settings_Set("list_exe", GUICtrlRead($hCheckExe) = $GUI_CHECKED)
		If $mData["wog_settings"] Then Settings_Set("list_wog_settings", GUICtrlRead($hCheckSet) = $GUI_CHECKED)
		Settings_Set("list_no_ask", GUICtrlRead($hCheckNotAgain) = $GUI_CHECKED)
		$mAnswer["exe"] = $mData["exe"] And Settings_Get("list_exe")
		$mAnswer["wog_settings"] = $mData["wog_settings"] And Settings_Get("list_wog_settings")
	EndIf

	MM_GUIDelete()

	AutoItSetOption("GUIOnEventMode", $iOptionGUIOnEventMode)
	GUISetState(@SW_ENABLE, MM_GetCurrentWindow())
	GUISetState(@SW_RESTORE, MM_GetCurrentWindow())

	Return $mAnswer
EndFunc

Func UI_SelectScnSaveOptions($sDefaultName)
	Local $mAnswer = MapEmpty()
	$mAnswer["selected"] = False
	$mAnswer["name"] = ""
	$mAnswer["exe"] = Settings_Get("list_exe")
	$mAnswer["wog_settings"] = Settings_Get("list_wog_settings")

	Local $bClose = False, $bSelected = False, $sPath

	If $sDefaultName = "" Then
		$sPath = __UI_SelectSavePath()
		If Not @error Then
			$sDefaultName = $sPath
		Else
			Return $mAnswer
		EndIf
	EndIf

	GUISetState(@SW_DISABLE, MM_GetCurrentWindow())

	Local Const $iOptionGUIOnEventMode = AutoItSetOption("GUIOnEventMode", 0)
	Local Const $iItemSpacing = 4


	Local $hGUI = MM_GUICreate(Lng_Get("scenarios.save_options.caption"), 420, 104)
	Local $aSize = WinGetClientSize($hGUI)
	If Not @Compiled Then GUISetIcon(@ScriptDir & "\icons\preferences-system.ico")

	Local $hCombo = GUICtrlCreateCombo("", $iItemSpacing, $iItemSpacing, $aSize[0] - 3 * $iItemSpacing - 35, 25, BitOR($CBS_DROPDOWNLIST, $CBS_AUTOHSCROLL))
	GUICtrlSetData($hCombo, _ArrayToString($MM_SCN_LIST, Default, 1))
	If $sDefaultName <> "" Then GUICtrlSetData($hCombo, $sDefaultName, $sDefaultName)

	Local $hDir = GUICtrlCreateButton("...", GUICtrlGetPos($hCombo).NextX + $iItemSpacing, $iItemSpacing - 2, 35, 25)
	Local $hCheckExe = GUICtrlCreateCheckbox(Lng_Get("scenarios.save_options.exe"), $iItemSpacing, GUICtrlGetPos($hCombo).NextY + $iItemSpacing, Default, 17)
	Local $hCheckSet = GUICtrlCreateCheckbox(Lng_Get("scenarios.save_options.wog_settings"), $iItemSpacing, GUICtrlGetPos($hCheckExe).NextY + $iItemSpacing, Default, 17)
	Local $hLine = GUICtrlCreateGraphic($iItemSpacing, GUICtrlGetPos($hCheckSet).NextY + $iItemSpacing, $aSize[0] - 2 * $iItemSpacing, 1)
	GUICtrlSetGraphic($hLine, $GUI_GR_LINE, $aSize[0] - 2 * $iItemSpacing, 0)

	Local $hOk = GUICtrlCreateButton("OK", $aSize[0] - $iItemSpacing - 75, GUICtrlGetPos($hLine).NextY + $iItemSpacing, 75, 25)

	GUICtrlSetState($hCheckExe, $mAnswer["exe"] ? $GUI_CHECKED : $GUI_UNCHECKED)
	GUICtrlSetState($hCheckSet, $mAnswer["wog_settings"] ? $GUI_CHECKED : $GUI_UNCHECKED)

	GUISetState(@SW_SHOW)

	While Not $bClose And Not $bSelected
		Switch GUIGetMsg()
			Case $GUI_EVENT_CLOSE
				$bClose = True
			Case $hOk
				$bSelected = True
			Case $hDir
				$sPath = __UI_SelectSavePath(GUICtrlRead($hCombo) & ".json")
				If Not @error Then
					GUICtrlSetData($hCombo, $sPath, $sPath)
				EndIf
		EndSwitch
	WEnd

	If $bSelected Then
		$mAnswer["selected"] = True
		$mAnswer["name"] = GUICtrlRead($hCombo)
		$mAnswer["exe"] = GUICtrlRead($hCheckExe) = $GUI_CHECKED
		$mAnswer["wog_settings"] = GUICtrlRead($hCheckSet) = $GUI_CHECKED
	EndIf

	MM_GUIDelete()

	AutoItSetOption("GUIOnEventMode", $iOptionGUIOnEventMode)
	GUISetState(@SW_ENABLE, MM_GetCurrentWindow())
	GUISetState(@SW_RESTORE, MM_GetCurrentWindow())

	Return $mAnswer
EndFunc

Func __UI_SelectSavePath(Const $sName = "")
	Local $sDrive, $sDir, $sFileName, $sExtension
	Local $sPath = FileSaveDialog(Lng_Get("scenarios.save_options.select_file"), $MM_SCN_DIRECTORY, Lng_Get("scenarios.save_options.select_filter"), Default, $sName, MM_GetCurrentWindow())
	If @error Then Return SetError(@error, @extended, "")
	_PathSplit($sPath, $sDrive, $sDir, $sFileName, $sExtension)
	Return SetError(0, 0, $sFileName)
EndFunc

Func UI_GetSuggestedGameDirList()
	Local $aSettings = Settings_Get("available_path_list")
	Local $aList[1]

	For $i = 0 To UBound($aSettings) - 1
		If FileExists($aSettings[$i] & "\h3era.exe") Or Settings_Get("path") = $aSettings[$i] Then
			ReDim $aList[$aList[0] + 2]
			$aList[0] += 1
			$aList[$aList[0]] = $aSettings[$i]
		EndIf
	Next

	Return $aList
EndFunc

Func UI_SelectGameExe()
	Local $aList = _FileListToArray($MM_GAME_DIR, "*.exe", $FLTA_FILES)
	If Not IsArray($aList) Then Local $aList[1] = [0]
	Local Const $iOptionGUIOnEventMode = AutoItSetOption("GUIOnEventMode", 0)
	Local Const $aBlacklist = Settings_Get("game.blacklist")
	GUISetState(@SW_DISABLE, MM_GetCurrentWindow())

	Local Const $iItemSpacing = 4
	Local $bClose = False
	Local $bSelected = False
	Local $sReturn = $MM_GAME_EXE
	Local $bAllowName, $sSelected

	Local $hGUI = MM_GUICreate("", 200, 324)
	Local $aSize = WinGetClientSize($hGUI)
	If Not @Compiled Then GUISetIcon(@ScriptDir & "\icons\preferences-system.ico")
	GUIRegisterMsgStateful($WM_NOTIFY, "__UI_WM_NOTIFY")
	$__UI_LIST = GUICtrlCreateTreeView($iItemSpacing, $iItemSpacing, _ ; left, top
			$aSize[0] - 2 * $iItemSpacing, $aSize[1] - 3 * $iItemSpacing - 25, _
			BitOR($TVS_FULLROWSELECT, $TVS_DISABLEDRAGDROP, $TVS_SHOWSELALWAYS), $WS_EX_CLIENTEDGE)
	Local $hShowAll = GUICtrlCreateCheckbox(Lng_Get("settings.game_exe.show_all"), $iItemSpacing, GUICtrlGetPos($__UI_LIST).Height + $iItemSpacing, Default, 25)
	Local $hOk = GUICtrlCreateButton("OK", $aSize[0] - $iItemSpacing - 75, GUICtrlGetPos($hShowAll).Top + $iItemSpacing, 75, 25)
	Local $hListItems = $aList
	For $i = 1 To $aList[0]
		$bAllowName = True
		For $j = 0 To UBound($aBlacklist) - 1
			If StringRegExp($aList[$i], "(?i)" & $aBlacklist[$j]) Then $bAllowName = False
			If Not $bAllowName Then ExitLoop
		Next

		If $bAllowName Or $aList[$i] = $MM_GAME_EXE Then
			$hListItems[$i] = GUICtrlCreateTreeViewItem($aList[$i], $__UI_LIST)
			If $aList[$i] = $MM_GAME_EXE Then GUICtrlSetState($hListItems[$i], $GUI_FOCUS)
			If Not _GUICtrlTreeView_SetIcon($__UI_LIST, $hListItems[$i], $MM_GAME_DIR & "\" & $aList[$i], 0, 6) Then
				 _GUICtrlTreeView_SetIcon($__UI_LIST, $hListItems[$i], "shell32.dll", -3, 6)
			EndIf
		EndIf
	Next

	GUISetState(@SW_SHOW)

	While Not $bClose And Not $bSelected
		Switch GUIGetMsg()
			Case $GUI_EVENT_CLOSE
				$bClose = True
			Case $hOk
				$bSelected = True
			Case $hShowAll
				$sSelected = GUICtrlRead($__UI_LIST, 1)
				GUICtrlSetState($hShowAll, $GUI_DISABLE)
				_GUICtrlTreeView_BeginUpdate($__UI_LIST)
				_GUICtrlTreeView_DeleteAll($__UI_LIST)
				For $i = 1 To $aList[0]
					$hListItems[$i] = GUICtrlCreateTreeViewItem($aList[$i], $__UI_LIST)
					If $aList[$i] = $sSelected Then GUICtrlSetState($hListItems[$i], $GUI_FOCUS)
					If Not _GUICtrlTreeView_SetIcon($__UI_LIST, $hListItems[$i], $MM_GAME_DIR & "\" & $aList[$i], 0, 6) Then
						 _GUICtrlTreeView_SetIcon($__UI_LIST, $hListItems[$i], "shell32.dll", -3, 6)
					EndIf
				Next
				_GUICtrlTreeView_EndUpdate($__UI_LIST)
		EndSwitch
		If $__UI_EVENT Then
			$bSelected = True
			$__UI_EVENT = False
		EndIf
	WEnd

	If $bSelected Then
		$sSelected = GUICtrlRead($__UI_LIST, 1)
		If $sSelected <> "" Then $sReturn = $sSelected
	EndIf

	GUIRegisterMsgStateful($WM_NOTIFY, "")
	MM_GUIDelete()

	AutoItSetOption("GUIOnEventMode", $iOptionGUIOnEventMode)
	GUISetState(@SW_ENABLE, MM_GetCurrentWindow())
	GUISetState(@SW_RESTORE, MM_GetCurrentWindow())
	Return $sReturn
EndFunc

Func __UI_WM_NOTIFY($hwnd, $iMsg, $iwParam, $ilParam)
	#forceref $hWnd, $iMsg, $iwParam, $ilParam
	Local $hWndFrom, $iCode, $tNMHDR

	$tNMHDR = DllStructCreate($tagNMHDR, $ilParam)
	$hWndFrom = HWnd(DllStructGetData($tNMHDR, "hWndFrom"))
	$iCode = DllStructGetData($tNMHDR, "Code")

	Switch $hWndFrom
		Case GUICtrlGetHandle($__UI_LIST)
			Switch $iCode
				Case $NM_DBLCLK
					$__UI_EVENT = True
			EndSwitch
	EndSwitch

	Return $GUI_RUNDEFMSG
EndFunc   ;==>WM_NOTIFY

Func __UI_WM_COMMAND($hWnd, $iMsg, $wParam, $lParam)
	#forceref $hWnd, $iMsg
	Local $hWndFrom, $iCode
	$hWndFrom = $lParam

	$iCode = _WinAPI_HiWord($wParam)

	Switch $hWndFrom
		Case GUICtrlGetHandle($__UI_INPUT)
			Switch $iCode
				Case $EN_CHANGE
					$__UI_EVENT = True
			EndSwitch
	EndSwitch

	Return $GUI_RUNDEFMSG
EndFunc   ;==>WM_COMMAND


