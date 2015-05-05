; Author:         Aliaksei SyDr Karalenka

#AutoIt3Wrapper_Version=Beta
#include-once

#include "include_fwd.au3"

#include "mods.au3"
#include "presets.au3"

Global Const $WO_CAT = 8, $WO_GRP = 4, $WO_OPT = 20
Global $MM_WO_CAT[$WO_CAT] ; text, hint, popup, handle
Global $MM_WO_GROUPS[$WO_CAT][$WO_GRP] ; text, hint, popup, type, handle
Global $MM_WO_ITEMS[1] ; Comment, Script, Page, Group, Item, State, MP, ERM, Text, Hint, PopUp, Handle
Global $MM_WO_MAP[$WO_CAT][$WO_GRP][$WO_OPT + 1] ; page / group / item [1 based, 0 - count] : index in $MM_WO_ITEMS
Global $MM_WO_UI_OPTIONS, $MM_WO_SHOW_POPUP, $MM_WO_FILTER_REQUESTED
Global $mPages = MapEmpty() ; handle : page num (0 based)
Global $mGroups = MapEmpty() ; handle : page, group (both 0 based)
Global $mItems = MapEmpty() ; handle : page, group, item (item is 1 based, other 0 based)
Global $MM_WO_CURRENT_PAGE = -1, $MM_WO_PREV_PAGE = -1
Global $MM_WO_FILTER = "", $WO_UI, $__WO_INPUT

Func WO_ClearData()
	For $p = 0 To $WO_CAT - 1
		$MM_WO_CAT[$p] = Null
		For $g = 0 To $WO_GRP - 1
			$MM_WO_GROUPS[$p][$g] = Null
			For $i = 1 To $MM_WO_MAP[$p][$g][0]
				$MM_WO_MAP[$p][$g][$i] = Null
			Next
			$MM_WO_MAP[$p][$g][0] = 0
		Next
	Next

	$MM_WO_ITEMS[0] = 0
	ReDim $MM_WO_ITEMS[1]

	$MM_WO_PREV_PAGE = -1
	$MM_WO_PREV_PAGE = -1
	$MM_WO_FILTER = ""
EndFunc

Func WO_ManageOptions(Const $aOptions)
	_TraceStart("WO_Manage")
	GUISetState(@SW_DISABLE, MM_GetCurrentWindow())
	ProgressOn(Lng_Get("wog_options.caption"), Lng_Get("wog_options.loading"), Lng_Get("wog_options.loading_text"), Default, Default, $DLG_MOVEABLE + $DLG_NOTONTOP)
	Local $mAnswer = MapEmpty()
	$mAnswer["selected"] = False

	Local Const $iOptionGUIOnEventMode = AutoItSetOption("GUIOnEventMode", 0)
	$MM_WO_UI_OPTIONS = $aOptions
	WO_LoadOverralInfo()
	WO_LoadOptionsInfo()
	_Trace("WO_DataLoaded")

	If Not IsMap($MM_WO_CAT[0]) Then
		ProgressOff()
		MsgBox($MB_SYSTEMMODAL, "", Lng_Get("wog_options.bad_data"), MM_GetCurrentWindow())
		WO_ClearData()
		AutoItSetOption("GUIOnEventMode", $iOptionGUIOnEventMode)
		GUISetState(@SW_ENABLE, MM_GetCurrentWindow())
		GUISetState(@SW_RESTORE, MM_GetCurrentWindow())
		Return $mAnswer
	EndIf

	Local Const $iWidth = 180, $iHeight = 50, $iBaseWidth = 350
	Local Const $iButtonWidth = 90
	Local Const $iItemSpacing = 4
	Local Const $iGroupWidth = $iBaseWidth - 1.5 * $iItemSpacing
	Local $bClose, $bSelected, $iMessage, $aCursoInfo
	Local $hCloseButton, $hSaveButton, $hLoadButton, $hRestoreDefaultButton, $hUncheckAllButton, $hCheckAllButton
	Local $hFilterLabel, $hFilterClearButton, $sPath
	$WO_UI = MM_GUICreate(Lng_Get("wog_options.caption"), $iWidth + $iBaseWidth * 2, 500)
	Local $aSize = WinGetClientSize($WO_UI)
	If Not @Compiled Then GUISetIcon(@ScriptDir & "\icons\preferences-system.ico")
	GUIRegisterMsgStateful($WM_COMMAND, "__WO_WM_COMMAND")
	GUIRegisterMsgStateful($WM_CONTEXTMENU, "__WO_WM_CONTEXTMENU")

	Local $iLeft, $iTop, $hItemFunc, $iIndex, $iIndex2, $sPopup

	For $p = 0 To $WO_CAT - 1
		$MM_WO_CAT[$p].Handle = GUICtrlCreateRadio($MM_WO_CAT[$p].Text, 0, $p * $iHeight, $iWidth, $iHeight, BitOR($BS_MULTILINE, $BS_PUSHLIKE))
		GUICtrlSetTip($MM_WO_CAT[$p].Handle, $MM_WO_CAT[$p].Hint)
		$mPages[$MM_WO_CAT[$p].Handle] = $p
	Next


	For $p = 0 To $WO_CAT - 1
		For $g = 0 To $WO_GRP - 1
			$iLeft = $iWidth + Floor(($g / 2) + 1) * $iItemSpacing + Floor(($g / 2)) * $iGroupWidth
			$iTop = ($g = 1 Or $g = 3) ? GUICtrlGetPos($MM_WO_GROUPS[$p][$g - (($p = 4 And $g = 3) ? 3 : 1)].Handle).NextY : 0

			If $MM_WO_MAP[$p][$g][0] > 0 Then
				$MM_WO_GROUPS[$p][$g].Handle = GUICtrlCreateGroup($MM_WO_GROUPS[$p][$g].Text, $iLeft, $iTop, ($p = 4 And $g = 0) ? (2 * $iGroupWidth + $iItemSpacing) : $iGroupWidth, 19 * $MM_WO_MAP[$p][$g][0] + 5 * $iItemSpacing)
				GUICtrlSetTip($MM_WO_GROUPS[$p][$g].Handle, $MM_WO_GROUPS[$p][$g].Hint)
				$mGroups[$MM_WO_GROUPS[$p][$g].Handle] = ArraySimple($p, $g)
				GUICtrlSetState(-1, $GUI_HIDE)

				$MM_WO_GROUPS[$p][$g].Type = WO_IsCheckboxGroup($p, $g)
				$hItemFunc = $MM_WO_GROUPS[$p][$g].Type ? GUICtrlCreateCheckbox : GUICtrlCreateRadio
				For $i = 1 To $MM_WO_MAP[$p][$g][0]
					$iIndex = $MM_WO_MAP[$p][$g][$i]
					$iIndex2 = $MM_WO_MAP[$p][$g][$i-1] ; invalid if $i = 1
					$MM_WO_ITEMS[$iIndex].Handle = $hItemFunc($MM_WO_ITEMS[$iIndex].Text, _
						$iLeft + $iItemSpacing, $i = 1 ? GUICtrlGetPos($MM_WO_GROUPS[$p][$g].Handle).Top + 3 * $iItemSpacing : GUICtrlGetPos($MM_WO_ITEMS[$iIndex2].Handle).NextY - 2, _
						(($p = 4 And $g = 0) ? 2 : 1) * $iGroupWidth - 2 * $iItemSpacing)
					GUICtrlSetTip($MM_WO_ITEMS[$iIndex].Handle, $MM_WO_ITEMS[$iIndex].Hint)
					$mItems[$MM_WO_ITEMS[$iIndex].Handle] = ArraySimple($p, $g, $i)
					GUICtrlSetState(-1, $GUI_HIDE)
				Next
			EndIf
		Next

		_Trace("WO_PageCreated")
		ProgressSet($p/$WO_CAT*100)
	Next

	GUICtrlCreateLabel("", $iItemSpacing, $aSize[1] - 25 - 2 * $iItemSpacing, $aSize[0] - 2 * $iItemSpacing, 1, $SS_BLACKFRAME)

	$hFilterLabel = GUICtrlCreateLabel(Lng_Get("wog_options.filter"), 2 * $iItemSpacing, $aSize[1] - 25 - $iItemSpacing, Default, Default, $SS_CENTERIMAGE)
	$__WO_INPUT = GUICtrlCreateInput("", GUICtrlGetPos($hFilterLabel).NextX + $iItemSpacing, GUICtrlGetPos($hFilterLabel).Top + 2, 150)
;~ 	$hFilterApplyButton = GUICtrlCreateButton("", GUICtrlGetPos($hFilterInput).NextX + $iItemSpacing, GUICtrlGetPos($hFilterLabel).Top, 25, 25, $BS_ICON)
	$hFilterClearButton = GUICtrlCreateButton("", GUICtrlGetPos($__WO_INPUT).NextX + $iItemSpacing, GUICtrlGetPos($hFilterLabel).Top, 25, 25, $BS_ICON)

;~ 	GUICtrlSetImage($hFilterApplyButton, @ScriptDir & "\icons\view-filter.ico")
	GUICtrlSetImage($hFilterClearButton, @ScriptDir & "\icons\edit-clear-locationbar-rtl.ico")

	$hCheckAllButton = GUICtrlCreateButton(Lng_Get("wog_options.check"), $aSize[0] - 6 * $iButtonWidth  - 7 * $iItemSpacing, $aSize[1] - 25 - $iItemSpacing, $iButtonWidth, 25)
	$hUncheckAllButton = GUICtrlCreateButton(Lng_Get("wog_options.uncheck"), GUICtrlGetPos($hCheckAllButton).NextX + $iItemSpacing, GUICtrlGetPos($hCheckAllButton).Top, $iButtonWidth, 25)
	$hRestoreDefaultButton = GUICtrlCreateButton(Lng_Get("wog_options.default"),GUICtrlGetPos($hUncheckAllButton).NextX + $iItemSpacing, GUICtrlGetPos($hUncheckAllButton).Top, $iButtonWidth, 25)
	$hLoadButton = GUICtrlCreateButton(Lng_Get("wog_options.load"), GUICtrlGetPos($hRestoreDefaultButton).NextX + $iItemSpacing, GUICtrlGetPos($hRestoreDefaultButton).Top, $iButtonWidth, 25)
	$hSaveButton = GUICtrlCreateButton(Lng_Get("wog_options.save"), GUICtrlGetPos($hLoadButton).NextX + $iItemSpacing, GUICtrlGetPos($hLoadButton).Top, $iButtonWidth, 25)
	$hCloseButton = GUICtrlCreateButton("OK", GUICtrlGetPos($hSaveButton).NextX + $iItemSpacing, GUICtrlGetPos($hSaveButton).Top, $iButtonWidth, 25)

;~ 	GUICtrlSetImage($hCloseButton, @ScriptDir & "\icons\dialog-ok-apply.ico")

	WO_SettingsToView($MM_WO_UI_OPTIONS)
	WO_UpdateAccessibility()
	WO_UpdateVisibility()
	ProgressOff()
	GUISetState(@SW_SHOW)

	While Not $bClose And Not $bSelected
		$iMessage = GUIGetMsg()
		Select
			Case $iMessage = $hFilterClearButton
				GUICtrlSetData($__WO_INPUT, "")
			Case $iMessage = $hSaveButton
				$sPath = FileSaveDialog("", _PathFull(IniRead($MM_GAME_DIR & "\wog.ini", "WoGification", "Options_File_Path", ".\"), $MM_GAME_DIR), Lng_Get("wog_options.select_filter"), _
					Default, IniRead($MM_GAME_DIR & "\wog.ini", "WoGification", "Options_File_Name", $MM_WOG_OPTIONS_FILE), MM_GetCurrentWindow())
				If Not @error Then Scn_SaveWogSettings(WO_ViewToSettings($MM_WO_UI_OPTIONS), $sPath)
			Case $iMessage = $hLoadButton
				$sPath = FileOpenDialog("", _PathFull(IniRead($MM_GAME_DIR & "\wog.ini", "WoGification", "Options_File_Path", ".\"), $MM_GAME_DIR), Lng_Get("wog_options.select_filter"), _
					$FD_FILEMUSTEXIST + $FD_PATHMUSTEXIST, IniRead($MM_GAME_DIR & "\wog.ini", "WoGification", "Options_File_Name", $MM_WOG_OPTIONS_FILE), MM_GetCurrentWindow())
				If Not @error Then
					WO_SettingsToView(Scn_LoadWogSettingsAsArray($sPath))
					WO_UpdateAccessibility()
				EndIf
			Case $iMessage = $hRestoreDefaultButton
				WO_SetState()
			Case $iMessage = $hUncheckAllButton
				WO_SetState(0)
			Case $iMessage = $hCheckAllButton
				WO_SetState(1)
			Case $iMessage = $GUI_EVENT_CLOSE
				$bClose = True
			Case $iMessage = $hCloseButton
				$bSelected = True
			Case MapExists($mPages, $iMessage)
				WO_OnPageChange($mPages[$iMessage])
			Case MapExists($mItems, $iMessage)
				WO_UpdateAccessibility($iMessage)
			Case $MM_WO_SHOW_POPUP
				$MM_WO_SHOW_POPUP = False
				$aCursoInfo = GUIGetCursorInfo($WO_UI)
				If Not @error And $aCursoInfo[4] <> 0 Then
					$sPopup = WO_GetItemInfoByHandle($aCursoInfo[4])
					If $sPopup Then MsgBox($MB_SYSTEMMODAL, "",  $sPopup, Default, MM_GetCurrentWindow())
				EndIf
			Case $MM_WO_FILTER_REQUESTED
				$MM_WO_FILTER_REQUESTED = False
				$MM_WO_FILTER = GUICtrlRead($__WO_INPUT)
				WO_UpdateVisibility()
		EndSelect
	WEnd

	If $bSelected Then
		$mAnswer["selected"] = True
		$mAnswer["wog_options"] = WO_ViewToSettings($MM_WO_UI_OPTIONS)
	EndIf

	GUIRegisterMsgStateful($WM_COMMAND, "")
	GUIRegisterMsgStateful($WM_CONTEXTMENU, "")
	MM_GUIDelete()
	WO_ClearData()

	AutoItSetOption("GUIOnEventMode", $iOptionGUIOnEventMode)
	GUISetState(@SW_ENABLE, MM_GetCurrentWindow())
	GUISetState(@SW_RESTORE, MM_GetCurrentWindow())

	_TraceEnd()
	Return $mAnswer
EndFunc

Func WO_UpdateVisibility()
	GUISetState(@SW_LOCK)
	Local $iFirstAvailablePage = -1
	Local $bPageAvailble
	Local $bGroupVisible, $iIndex, $bItemVisible

	For $p = 0 To $WO_CAT - 1
		$bPageAvailble = False

		For $g = 0 To $WO_GRP - 1
			$bGroupVisible = False

			If $MM_WO_MAP[$p][$g][0] > 0 Then
				For $i = 1 To $MM_WO_MAP[$p][$g][0]
					$iIndex = $MM_WO_MAP[$p][$g][$i]
					$bItemVisible = $MM_WO_CURRENT_PAGE = $p And __WO_IsItemPassFilter($iIndex)
					$bPageAvailble = $bPageAvailble Or __WO_IsItemPassFilter($iIndex)
					GUICtrlSetState($MM_WO_ITEMS[$iIndex].Handle, $bItemVisible ? $GUI_SHOW : $GUI_HIDE)
					If $bItemVisible Then $bGroupVisible = True
				Next
			EndIf

			GUICtrlSetState($MM_WO_GROUPS[$p][$g].Handle, $bGroupVisible ? $GUI_SHOW : $GUI_HIDE)
		Next

		GUICtrlSetState($MM_WO_CAT[$p].Handle, $bPageAvailble ? $GUI_SHOW : $GUI_HIDE)
		If $iFirstAvailablePage = -1 And $bPageAvailble Then $iFirstAvailablePage = $p
	Next

	GUISetState(@SW_UNLOCK)
	If $iFirstAvailablePage <> - 1 And ($MM_WO_CURRENT_PAGE = -1 Or ($MM_WO_CURRENT_PAGE <> -1 And BitAnd(GUICtrlGetState($MM_WO_CAT[$MM_WO_CURRENT_PAGE].Handle), $GUI_HIDE))) Then
		GUICtrlSetState($MM_WO_CAT[$iFirstAvailablePage].Handle, $GUI_CHECKED)
		WO_OnPageChange($iFirstAvailablePage)
	EndIf
EndFunc

Func __WO_IsItemPassFilter(Const $iIndex)
	Return $MM_WO_FILTER = "" Or StringInStr($MM_WO_ITEMS[$iIndex].Text, $MM_WO_FILTER) Or StringInStr($MM_WO_ITEMS[$iIndex].Hint, $MM_WO_FILTER) Or StringInStr($MM_WO_ITEMS[$iIndex].PopUp, $MM_WO_FILTER)
EndFunc

Func WO_SetState(Const $iType = -1)
	; -1 is default, 0 - disable, 1 - enable
	If $MM_WO_CURRENT_PAGE <> - 1 Then
		Local $iIndex, $iState
		For $g = 0 To $WO_GRP - 1
			For $i = 1 To $MM_WO_MAP[$MM_WO_CURRENT_PAGE][$g][0]
				$iIndex = $MM_WO_MAP[$MM_WO_CURRENT_PAGE][$g][$i]
				$iState = $iType <> -1 ? $iType : $MM_WO_ITEMS[$iIndex].State

				If BitAND(GUICtrlGetState($MM_WO_ITEMS[$iIndex].Handle), $GUI_SHOW) Then
					If $MM_WO_GROUPS[$MM_WO_CURRENT_PAGE][$g].Type Then
						GUICtrlSetState($MM_WO_ITEMS[$iIndex].Handle, $iState = 1 ? $GUI_CHECKED : $GUI_UNCHECKED)
					ElseIf $iType = -1 Then
						GUICtrlSetState($MM_WO_ITEMS[$iIndex].Handle, $iState ? $GUI_CHECKED : $GUI_UNCHECKED)
					EndIf
				EndIf
			Next
		Next
		WO_UpdateAccessibility()
	EndIf
EndFunc

Func WO_GetItemInfoByHandle(Const $hHandle)
	Local $aCoords
	If MapExists($mPages, $hHandle) Then
		Return $MM_WO_CAT[$mPages[$hHandle]].PopUp
	ElseIf MapExists($mGroups, $hHandle) Then
		$aCoords = $mGroups[$hHandle]
		Return $MM_WO_GROUPS[$aCoords[0]][$aCoords[1]].PopUp
	ElseIf MapExists($mItems, $hHandle) Then
		$aCoords = $mItems[$hHandle]
		Return $MM_WO_ITEMS[$MM_WO_MAP[$aCoords[0]][$aCoords[1]][$aCoords[2]]].PopUp
	Else
		Return ""
	EndIf
EndFunc

Func __WO_WM_CONTEXTMENU($hWnd, $iMsg, $wParam, $lParam)
	#forceref $hWnd, $iMsg, $wParam, $lParam
	$MM_WO_SHOW_POPUP = True
	Return $GUI_RUNDEFMSG
EndFunc

Func __WO_WM_COMMAND($hWnd, $iMsg, $wParam, $lParam)
	#forceref $hWnd, $iMsg
	Local $hWndFrom, $iCode
	$hWndFrom = $lParam

	$iCode = _WinAPI_HiWord($wParam)

	Switch $hWndFrom
		Case GUICtrlGetHandle($__WO_INPUT)
			Switch $iCode
				Case $EN_CHANGE
					_Timer_KillAllTimers($WO_UI)
					_Timer_SetTimer($WO_UI, 250, "__WO_FilterData") ; create timer
			EndSwitch
	EndSwitch

	Return $GUI_RUNDEFMSG
EndFunc   ;==>WM_COMMAND

Func __WO_FilterData($hWnd, $iMsg, $iIDTimer, $iTime)
    #forceref $hWnd, $iMsg, $iIDTimer, $iTime
    _Timer_KillAllTimers($WO_UI)
	$MM_WO_FILTER_REQUESTED = True
EndFunc   ;==>_UpdateStatusBarClock


Func WO_IsCheckboxGroup(Const $iPage, Const $iGroup)
	Return Not (($iPage = 0 And ($iGroup = 0 Or $iGroup = 3)) Or ($iPage = 4 And $iGroup = 0))
EndFunc

Func WO_SettingsToView(Const ByRef $aOptions)
	GUISetState(@SW_LOCK)
	Local $iIndex, $iIndex2

	For $p = 0 To $WO_CAT - 1
		For $g = 0 To $WO_GRP - 1
			For $i = 1 To $MM_WO_MAP[$p][$g][0]
				$iIndex = $MM_WO_MAP[$p][$g][$i]
				$iIndex2 = $MM_WO_ITEMS[$iIndex].ERM
				If $MM_WO_GROUPS[$p][$g].Type Then
					GUICtrlSetState($MM_WO_ITEMS[$iIndex].Handle, (($iIndex2 > 0 And $iIndex2 < 5) ? (Not $aOptions[$iIndex2]) : $aOptions[$iIndex2]) = 1 ? $GUI_CHECKED : $GUI_UNCHECKED)
				Else
					GUICtrlSetState($MM_WO_ITEMS[$iIndex].Handle, ($aOptions[$iIndex2] = $i - 1) ? $GUI_CHECKED : $GUI_UNCHECKED)
				EndIf
			Next
		Next
	Next
	GUISetState(@SW_UNLOCK)
EndFunc

Func WO_ViewToSettings($aResult)
	ReDim $aResult[1000]
	Local $iIndex, $iIndex2, $iState

	For $p = 0 To $WO_CAT - 1
		For $g = 0 To $WO_GRP - 1
			For $i = 1 To $MM_WO_MAP[$p][$g][0]
				$iIndex = $MM_WO_MAP[$p][$g][$i]
				$iIndex2 = $MM_WO_ITEMS[$iIndex].ERM
				$iState = BitAND(GUICtrlRead($MM_WO_ITEMS[$iIndex].Handle), $GUI_CHECKED) ? 1 : 0

				If $MM_WO_GROUPS[$p][$g].Type Then
					$aResult[$iIndex2] = Int(($iIndex2 > 0 And $iIndex2 < 5) ? Not $iState : $iState)
				Else
					If $iState = 1 Then $aResult[$iIndex2] = $i - 1
				EndIf
			Next
		Next
	Next

	Return $aResult
EndFunc

Func WO_OnPageChange(Const $iIndex)
	If $MM_WO_CURRENT_PAGE <> $iIndex Then
		$MM_WO_CURRENT_PAGE = $iIndex
		WO_UpdateVisibility()
	EndIf
EndFunc

Func WO_CheckItemAvailability(Const $iPage, Const $iGroup, Const $iItem)
	If $MM_WO_MAP[$iPage][$iGroup][$iItem] < 1 Then Return False
	If Not IsMap($MM_WO_ITEMS[$MM_WO_MAP[$iPage][$iGroup][$iItem]]) Then Return False
	Return True
EndFunc

Func WO_UpdateAccessibility(Const $hControl = 0)
	If WO_CheckItemAvailability(0, 2, 3) And WO_CheckItemAvailability(0, 2, 4) Then
		If $hControl = $MM_WO_ITEMS[$MM_WO_MAP[0][2][3]].Handle Or $hControl = 0 Then
			GUICtrlSetState($MM_WO_ITEMS[$MM_WO_MAP[0][2][4]].Handle, BitAND(GUICtrlRead($MM_WO_ITEMS[$MM_WO_MAP[0][2][3]].Handle), $GUI_CHECKED) ? $GUI_ENABLE : BitOR($GUI_DISABLE, $GUI_UNCHECKED))
		EndIf
	EndIf

	If WO_CheckItemAvailability(0, 2, 5) And WO_CheckItemAvailability(0, 2, 6) Then
		If $hControl = $MM_WO_ITEMS[$MM_WO_MAP[0][2][5]].Handle Or $hControl = 0 Then
			GUICtrlSetState($MM_WO_ITEMS[$MM_WO_MAP[0][2][6]].Handle, BitAND(GUICtrlRead($MM_WO_ITEMS[$MM_WO_MAP[0][2][5]].Handle), $GUI_CHECKED) ? $GUI_ENABLE : BitOR($GUI_DISABLE, $GUI_UNCHECKED))
		EndIf
	EndIf

	If WO_CheckItemAvailability(0, 2, 11) And WO_CheckItemAvailability(0, 3, 1) Then
		If $hControl = $MM_WO_ITEMS[$MM_WO_MAP[0][2][11]].Handle Or $hControl = 0 Then
			GUICtrlSetState($MM_WO_ITEMS[$MM_WO_MAP[0][3][1]].Handle, BitAND(GUICtrlRead($MM_WO_ITEMS[$MM_WO_MAP[0][2][11]].Handle), $GUI_CHECKED) ? $GUI_ENABLE : $GUI_DISABLE)
			For $i = 2 To $MM_WO_MAP[0][3][0]
				GUICtrlSetState($MM_WO_ITEMS[$MM_WO_MAP[0][3][$i]].Handle, BitAND(GUICtrlRead($MM_WO_ITEMS[$MM_WO_MAP[0][2][11]].Handle), $GUI_CHECKED) ? $GUI_ENABLE : BitOR($GUI_DISABLE, $GUI_UNCHECKED))
			Next
		EndIf

		Local $bIsSomethingChecked = False
		For $i = 2 To $MM_WO_MAP[0][3][0]
			$bIsSomethingChecked = $bIsSomethingChecked Or BitAND(GUICtrlRead($MM_WO_ITEMS[$MM_WO_MAP[0][3][$i]].Handle), $GUI_CHECKED)
		Next
		If Not $bIsSomethingChecked Then GUICtrlSetState($MM_WO_ITEMS[$MM_WO_MAP[0][3][1]].Handle, $GUI_CHECKED)
	EndIf

	If WO_CheckItemAvailability(1, 0, 1) And WO_CheckItemAvailability(1, 0, 2) Then
		If $hControl = $MM_WO_ITEMS[$MM_WO_MAP[1][0][1]].Handle Or $hControl = 0 Then
			GUICtrlSetState($MM_WO_ITEMS[$MM_WO_MAP[1][0][2]].Handle, BitAND(GUICtrlRead($MM_WO_ITEMS[$MM_WO_MAP[1][0][1]].Handle), $GUI_CHECKED) ? $GUI_ENABLE : BitOR($GUI_DISABLE, $GUI_UNCHECKED))
		EndIf
	EndIf

	If WO_CheckItemAvailability(1, 1, 1) And WO_CheckItemAvailability(1, 1, 2) And WO_CheckItemAvailability(1, 1, 3) And WO_CheckItemAvailability(1, 1, 4) And WO_CheckItemAvailability(1, 1, 5) Then
		If $hControl = $MM_WO_ITEMS[$MM_WO_MAP[1][1][1]].Handle Or $hControl = 0 Then
			GUICtrlSetState($MM_WO_ITEMS[$MM_WO_MAP[1][1][2]].Handle, BitAND(GUICtrlRead($MM_WO_ITEMS[$MM_WO_MAP[1][1][1]].Handle), $GUI_CHECKED) ? $GUI_ENABLE : BitOR($GUI_DISABLE, $GUI_UNCHECKED))
			GUICtrlSetState($MM_WO_ITEMS[$MM_WO_MAP[1][1][3]].Handle, BitAND(GUICtrlRead($MM_WO_ITEMS[$MM_WO_MAP[1][1][1]].Handle), $GUI_CHECKED) ? $GUI_ENABLE : BitOR($GUI_DISABLE, $GUI_UNCHECKED))
			GUICtrlSetState($MM_WO_ITEMS[$MM_WO_MAP[1][1][4]].Handle, BitAND(GUICtrlRead($MM_WO_ITEMS[$MM_WO_MAP[1][1][1]].Handle), $GUI_CHECKED) ? $GUI_ENABLE : BitOR($GUI_DISABLE, $GUI_UNCHECKED))
			GUICtrlSetState($MM_WO_ITEMS[$MM_WO_MAP[1][1][5]].Handle, BitAND(GUICtrlRead($MM_WO_ITEMS[$MM_WO_MAP[1][1][1]].Handle), $GUI_CHECKED) ? $GUI_ENABLE : BitOR($GUI_DISABLE, $GUI_UNCHECKED))
		EndIf

		If $hControl = $MM_WO_ITEMS[$MM_WO_MAP[1][1][3]].Handle Then GUICtrlSetState($MM_WO_ITEMS[$MM_WO_MAP[1][1][4]].Handle, $GUI_UNCHECKED)
		If $hControl = $MM_WO_ITEMS[$MM_WO_MAP[1][1][4]].Handle Then GUICtrlSetState($MM_WO_ITEMS[$MM_WO_MAP[1][1][3]].Handle, $GUI_UNCHECKED)

		If BitAND(GUICtrlRead($MM_WO_ITEMS[$MM_WO_MAP[1][1][3]].Handle), $GUI_CHECKED) Then GUICtrlSetState($MM_WO_ITEMS[$MM_WO_MAP[1][1][4]].Handle, $GUI_UNCHECKED)
	EndIf

	If WO_CheckItemAvailability(1, 1, 6) And WO_CheckItemAvailability(1, 1, 7) Then
		If $hControl = $MM_WO_ITEMS[$MM_WO_MAP[1][1][6]].Handle Then GUICtrlSetState($MM_WO_ITEMS[$MM_WO_MAP[1][1][7]].Handle, GUICtrlRead($MM_WO_ITEMS[$MM_WO_MAP[1][1][6]].Handle))
		If $hControl = $MM_WO_ITEMS[$MM_WO_MAP[1][1][7]].Handle Then GUICtrlSetState($MM_WO_ITEMS[$MM_WO_MAP[1][1][6]].Handle, GUICtrlRead($MM_WO_ITEMS[$MM_WO_MAP[1][1][7]].Handle))

		If $hControl = 0 Then GUICtrlSetState($MM_WO_ITEMS[$MM_WO_MAP[1][1][7]].Handle, GUICtrlRead($MM_WO_ITEMS[$MM_WO_MAP[1][1][6]].Handle))
	EndIf

	If WO_CheckItemAvailability(2, 0, 7) And WO_CheckItemAvailability(2, 0, 8) And WO_CheckItemAvailability(2, 0, 9) Then
		If $hControl = $MM_WO_ITEMS[$MM_WO_MAP[2][0][7]].Handle Then
			GUICtrlSetState($MM_WO_ITEMS[$MM_WO_MAP[2][0][8]].Handle, $GUI_UNCHECKED)
			GUICtrlSetState($MM_WO_ITEMS[$MM_WO_MAP[2][0][9]].Handle, $GUI_UNCHECKED)
		EndIf

		If $hControl = $MM_WO_ITEMS[$MM_WO_MAP[2][0][8]].Handle Then
			GUICtrlSetState($MM_WO_ITEMS[$MM_WO_MAP[2][0][7]].Handle, $GUI_UNCHECKED)
			GUICtrlSetState($MM_WO_ITEMS[$MM_WO_MAP[2][0][9]].Handle, $GUI_UNCHECKED)
		EndIf

		If $hControl = $MM_WO_ITEMS[$MM_WO_MAP[2][0][9]].Handle Then
			GUICtrlSetState($MM_WO_ITEMS[$MM_WO_MAP[2][0][7]].Handle, $GUI_UNCHECKED)
			GUICtrlSetState($MM_WO_ITEMS[$MM_WO_MAP[2][0][8]].Handle, $GUI_UNCHECKED)
		EndIf

		If BitAND(GUICtrlRead($MM_WO_ITEMS[$MM_WO_MAP[2][0][7]].Handle), $GUI_CHECKED) Then
			GUICtrlSetState($MM_WO_ITEMS[$MM_WO_MAP[2][0][8]].Handle, $GUI_UNCHECKED)
			GUICtrlSetState($MM_WO_ITEMS[$MM_WO_MAP[2][0][9]].Handle, $GUI_UNCHECKED)
		ElseIf BitAND(GUICtrlRead($MM_WO_ITEMS[$MM_WO_MAP[2][0][7]].Handle), $GUI_CHECKED) Then
			GUICtrlSetState($MM_WO_ITEMS[$MM_WO_MAP[2][0][9]].Handle, $GUI_UNCHECKED)
		EndIf
	EndIf
EndFunc

Func WO_LoadOverralInfo()
	Local Const $sFileName = "zsetup00.txt"
	Local $sData
	Local $aFiles

	For $i = 1 To $MM_LIST_CONTENT[0][0]
		If Not $MM_LIST_CONTENT[$i][$MOD_IS_ENABLED] Then ContinueLoop
		If FileExists(Mod_Get("dir\", $i) & "Data\" & $sFileName) Then
			$sData = FileRead(Mod_Get("dir\", $i) & "Data\" & $sFileName)
		Else
			$aFiles = _FileListToArray(Mod_Get("dir\", $i) & "Data\", "*.pac", $FLTA_FILES, True)
			If Not @error Then
				For $j = 1 To $aFiles[0]
					$sData = WO_GetFileData($aFiles[$j], $sFileName)
					If $sData Then ExitLoop
				Next
			EndIf
		EndIf

		If $sData Then ExitLoop
	Next

	If $sData Then WO_ParseCategoriesData($sData)
EndFunc

Func WO_LoadOptionsInfo()
	Local Const $sFileName = "zsetup01.txt"
	Local $sData
	Local $aFiles

	For $i = 1 To $MM_LIST_CONTENT[0][0]
		If Not $MM_LIST_CONTENT[$i][$MOD_IS_ENABLED] Then ContinueLoop
		If FileExists(Mod_Get("dir\", $i) & "Data\" & $sFileName) Then
			$sData = FileRead(Mod_Get("dir\", $i) & "Data\" & $sFileName)
		Else
			$aFiles = _FileListToArray(Mod_Get("dir\", $i) & "Data\", "*.pac", $FLTA_FILES, True)
			If Not @error Then
				For $j = 1 To $aFiles[0]
					$sData = WO_GetFileData($aFiles[$j], $sFileName)
					If $sData Then ExitLoop
				Next
			EndIf
		EndIf

		If $sData Then ExitLoop
	Next

	Local $mAlreadyLoaded = MapEmpty()

	For $i = 1 To $MM_LIST_CONTENT[0][0]
		If Not $MM_LIST_CONTENT[$i][$MOD_IS_ENABLED] Then ContinueLoop

		$aFiles = _FileListToArray(Mod_Get("dir\", $i) & "Data\s\", "*.ers", $FLTA_FILES, False)
		If Not @error Then
			For $j = 1 To $aFiles[0]
				If MapExists($mAlreadyLoaded, $aFiles[$j]) Then ContinueLoop
				$mAlreadyLoaded[$aFiles[$j]] = True
				$sData &= FileRead(Mod_Get("dir\", $i) & "Data\s\" & $aFiles[$j])
			Next
		EndIf
	Next

	If $sData Then WO_ParseItemsData($sData)
EndFunc

Func WO_ParseItemsData(Const ByRef $sData)
	Local $aData = StringSplit($sData, @CRLF, $STR_ENTIRESPLIT)
	Local $aToParse, $iPage, $iGroup, $iItem

	$MM_WO_ITEMS[0] = $aData[0]
	Local $iCount = 0
	For $i = 1 To $aData[0]
		$aToParse = StringSplit($aData[$i], @TAB, $STR_ENTIRESPLIT)
		If $aToParse[0] < 11 Then ContinueLoop
		if Not $aToParse[8] Then ContinueLoop

		_ArrayAdd($MM_WO_ITEMS, MapEmpty())
		$iCount += 1
		$MM_WO_ITEMS[$iCount].Comment = $aToParse[1]
		$MM_WO_ITEMS[$iCount].Script = Int($aToParse[2])
		$MM_WO_ITEMS[$iCount].Page = Int($aToParse[3])
		$MM_WO_ITEMS[$iCount].Group = Int($aToParse[4])
		$MM_WO_ITEMS[$iCount].Item = Int($aToParse[5])
		$MM_WO_ITEMS[$iCount].State = Int($aToParse[6])
		$MM_WO_ITEMS[$iCount].MP = Int($aToParse[7])
		$MM_WO_ITEMS[$iCount].ERM = Int($aToParse[8])
		$MM_WO_ITEMS[$iCount].Text = $aToParse[9]
		$MM_WO_ITEMS[$iCount].Hint = $aToParse[10]
		$MM_WO_ITEMS[$iCount].PopUp = $aToParse[11]

;~ 		_MapDisplay($MM_WO_ITEMS[$i], $MM_WO_ITEMS[$i].Page & @TAB & $MM_WO_ITEMS[$i].Group & @TAB & $MM_WO_ITEMS[$i].Item)

		$iPage = Int($aToParse[3])
		$iGroup = Int($aToParse[4])
		$iItem = Int($aToParse[5]) + 1

		If $iItem <> 0 Then
			$MM_WO_MAP[$iPage][$iGroup][$iItem] = $iCount
			If $MM_WO_MAP[$iPage][$iGroup][0] < $iItem Then $MM_WO_MAP[$iPage][$iGroup][0] = $iItem
		ElseIf $MM_WO_MAP[$iPage][$iGroup][0] < 20 Then
			$MM_WO_MAP[$iPage][$iGroup][0] += 1
			$MM_WO_MAP[$iPage][$iGroup][$MM_WO_MAP[$iPage][$iGroup][0]] = $iCount
		EndIf
	Next

EndFunc

Func WO_ParseCategoriesData(Const ByRef $sCategoriesData)
	Local $aData = StringSplit($sCategoriesData, @CRLF, $STR_ENTIRESPLIT)
	Local $aToParse, $sData, $iValue, $iPage, $iGroup

	For $i = 1 To $aData[0]
		$aToParse = StringSplit($aData[$i], @TAB, $STR_ENTIRESPLIT)
		If $aToParse[0] <> 2 Then ContinueLoop
		$iValue = Number($aToParse[1])
		$sData = $aToParse[2]

		Switch $iValue
			Case 0, 1 To 4
				; Nothing
			Case 5 To 28
				$iValue -= 5
				$iPage = Floor($iValue / 3)

				If Not IsMap($MM_WO_CAT[$iPage]) Then $MM_WO_CAT[$iPage] = MapEmpty()
				Switch Mod($iValue, 3)
					Case 0
						$MM_WO_CAT[$iPage].Text = $sData
					Case 1
						$MM_WO_CAT[$iPage].Hint = $sData
					Case 2
						$MM_WO_CAT[$iPage].PopUp = $sData
				EndSwitch
			Case 29 To 124
				$iValue -= 29
				$iPage = Floor($iValue / 12)
				$iGroup = Floor(Mod($iValue, 12) / 3)

				If Not IsMap($MM_WO_GROUPS[$iPage][$iGroup]) Then $MM_WO_GROUPS[$iPage][$iGroup] = MapEmpty()
				Switch Mod(Mod($iValue, 12), 3)
					Case 0
						$MM_WO_GROUPS[$iPage][$iGroup].Text = $sData
					Case 1
						$MM_WO_GROUPS[$iPage][$iGroup].Hint = $sData
					Case 2
						$MM_WO_GROUPS[$iPage][$iGroup].PopUp = $sData
				EndSwitch
		EndSwitch
	Next
EndFunc

Func WO_GetFileData(Const $sLODPath, Const $sFileName)
	Local $hFile = FileOpen($sLODPath, $FO_BINARY)
	Local $sData, $iTotalFiles, $iOffset, $iSizeOrg, $iSizeCompressed
;~ 	Local $iError

	If BinaryToString(FileRead($hFile, 4)) = "LOD" Then
		Int(FileRead($hFile, 4)) ; skip this
		$iTotalFiles = Int(FileRead($hFile, 4))

		For $i = 1 To $iTotalFiles
			FileSetPos($hFile, 92 + 32 * ($i - 1), $FILE_BEGIN)
			Local $sName = FileRead($hFile, 16)
			If Not StringInStr($sName, Binary($sFileName)) Then ContinueLoop

			$iOffset = Int(FileRead($hFile, 4))
			$iSizeOrg = Int(FileRead($hFile, 4))
			Int(FileRead($hFile, 4)) ; skip this
			$iSizeCompressed = Int(FileRead($hFile, 4))

			FileSetPos($hFile, $iOffset, $FILE_BEGIN)
			If $iSizeCompressed Then
				$sData = BinaryToString(_ZLIB_Uncompress(FileRead($hFile, $iSizeCompressed)))
			Else
				$sData = BinaryToString(FileRead($hFile, $iSizeOrg))
			EndIf

			ExitLoop
		Next
	EndIf

	FileClose($hFile)
	Return $sData
EndFunc
