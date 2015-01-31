; Author:         Aliaksei SyDr Karalenka

#AutoIt3Wrapper_Version=Beta
#include-once

#include "include_fwd.au3"

#include "lng.au3"
#include "settings.au3"
#include "utils.au3"

Global $__UI_EVENT = False, $__UI_LIST

Func UI_GameExeLaunch()
	If $MM_COMPATIBILITY_MESSAGE <> "" Then
		Local $iAnswer = MsgBox($MB_SYSTEMMODAL + $MB_YESNO, "", $MM_COMPATIBILITY_MESSAGE & @CRLF & Lng_Get("compatibility.launch_anyway"), Default, $MM_UI_MAIN)
		If $iAnswer <> $IDYES Then Return
	EndIf

	Run($MM_GAME_DIR & "\" & $MM_GAME_EXE, $MM_GAME_DIR)
EndFunc

Func UI_Settings()
	GUISetState(@SW_DISABLE, $MM_UI_MAIN)
	Local Const $iOptionGUIOnEventMode = AutoItSetOption("GUIOnEventMode", 0)
	Local Const $iItemSpacing = 4
	Local $bClose = False
	Local $bSave = False

	Local $hGUI = GUICreate(Lng_Get("settings.menu.settings"), 370, 100, Default, Default, Default, Default, $MM_UI_MAIN)
	Local $aSize = WinGetClientSize($hGUI)
	If Not @Compiled Then GUISetIcon(@ScriptDir & "\icons\preferences-system.ico")
	GUIRegisterMsgStateful($WM_NOTIFY, "__UI_WM_NOTIFY_SETTINGS")

	GUICtrlCreateGroup(Lng_Get("settings.auto_update.group"), $iItemSpacing, $iItemSpacing, $aSize[0] - 2 * $iItemSpacing, $aSize[1] - 3 * $iItemSpacing - 25)
	Local $hLabelAuto = GUICtrlCreateLabel(Lng_Get("settings.auto_update.label"), 2 * $iItemSpacing, 5 * $iItemSpacing, Default, 17, $SS_CENTERIMAGE)
	Local $hComboAuto = GUICtrlCreateCombo("", GUICtrlGetPos($hLabelAuto).NextX, 5 * $iItemSpacing, $aSize[0] - GUICtrlGetPos($hLabelAuto).NextX - 2 * $iItemSpacing, 25, $CBS_DROPDOWNLIST)
	GUICtrlSetData($hComboAuto, Lng_Get("settings.auto_update.day") & "|" & Lng_Get("settings.auto_update.week") & "|" & Lng_Get("settings.auto_update.month") & "|" & Lng_Get("settings.auto_update.never"), _
		UI_IntervalToItem(Settings_Get("update_interval")))

	Local $hCheckboxAuto = GUICtrlCreateCheckbox(Lng_Get("settings.auto_update.auto"), 6 * $iItemSpacing, GUICtrlGetPos($hLabelAuto).NextY + 2 * $iItemSpacing, Default, 17)
	GUICtrlSetState($hCheckboxAuto, Settings_Get("update_auto") ? $GUI_CHECKED : $GUI_UNCHECKED)
	GUICtrlSetState($hCheckboxAuto, (UI_ItemToInterval(GUICtrlRead($hComboAuto)) = 0 Or $MM_PORTABLE) ? $GUI_DISABLE : $GUI_ENABLE)
	Local $hOk = GUICtrlCreateButton("OK", $aSize[0] - $iItemSpacing - 75, $aSize[1] - $iItemSpacing - 25, 75, 25)

	GUISetState(@SW_SHOW)

	While Not $bClose And Not $bSave
		Switch GUIGetMsg()
			Case $GUI_EVENT_CLOSE
				$bClose = True
			Case $hOk
				$bSave = True
			Case $hComboAuto
				GUICtrlSetState($hCheckboxAuto, (UI_ItemToInterval(GUICtrlRead($hComboAuto)) = 0 Or $MM_PORTABLE) ? $GUI_DISABLE : $GUI_ENABLE)
		EndSwitch
	WEnd

	If $bSave Then
		Settings_Set("update_interval", UI_ItemToInterval(GUICtrlRead($hComboAuto)))
		Settings_Set("update_auto", GUICtrlRead($hCheckboxAuto) = $GUI_CHECKED)
		Settings_Save()
	EndIf

	GUIDelete($hGUI)

	AutoItSetOption("GUIOnEventMode", $iOptionGUIOnEventMode)
	GUISetState(@SW_ENABLE, $MM_UI_MAIN)
	GUISetState(@SW_RESTORE, $MM_UI_MAIN)
EndFunc

Func UI_IntervalToItem(Const $iInterval)
	Switch $iInterval
		Case 1
			Return Lng_Get("settings.auto_update.day")
		Case 7
			Return Lng_Get("settings.auto_update.week")
		Case 28
			Return Lng_Get("settings.auto_update.month")
		Case Else
			Return Lng_Get("settings.auto_update.never")
	EndSwitch
EndFunc

Func UI_ItemToInterval(Const $sItem)
	Switch $sItem
		Case Lng_Get("settings.auto_update.day")
			Return 1
		Case Lng_Get("settings.auto_update.week")
			Return 7
		Case Lng_Get("settings.auto_update.month")
			Return 28
		Case Else
			Return 0
	EndSwitch
EndFunc

Func UI_SelectGameDir()
	Local $aList = UI_GetSuggestedGameDirList()
	GUISetState(@SW_DISABLE, $MM_UI_MAIN)

	Local Const $iOptionGUIOnEventMode = AutoItSetOption("GUIOnEventMode", 0)
	Local Const $iItemSpacing = 4
	Local $bClose = False
	Local $bSelected = False
	Local $sPath
	Local $iAnswer

	Local $hGUI = GUICreate(Lng_Get("settings.game_dir.caption"), 420, $iItemSpacing + 50, Default, Default, Default, Default, $MM_UI_MAIN)
	Local $aSize = WinGetClientSize($hGUI)
	If Not @Compiled Then GUISetIcon(@ScriptDir & "\icons\preferences-system.ico")

	Local $hCombo = GUICtrlCreateCombo("", $iItemSpacing, $iItemSpacing, $aSize[0] - 3 * $iItemSpacing - 35, 25, BitOR($CBS_DROPDOWNLIST, $CBS_AUTOHSCROLL))
	GUICtrlSetData($hCombo, _ArrayToString($aList, Default, 1), Settings_Get("path"))
	Local $hDir = GUICtrlCreateButton("...", GUICtrlGetPos($hCombo).NextX + $iItemSpacing, $iItemSpacing - 2, 35, 25)
	Local $hOk = GUICtrlCreateButton("OK", $aSize[0] - $iItemSpacing - 75, GUICtrlGetPos($hDir).NextY, 75, 25)

	GUISetState(@SW_SHOW)

	While Not $bClose And Not $bSelected
		Switch GUIGetMsg()
			Case $GUI_EVENT_CLOSE
				$bClose = True
			Case $hOk
				$sPath = GUICtrlRead($hCombo)
				If Not FileExists($sPath & "\h3era.exe") Then
					$iAnswer = MsgBox($MB_YESNO + $MB_ICONQUESTION + $MB_DEFBUTTON2 + $MB_SYSTEMMODAL, "", Lng_Get("settings.game_dir.incorrect_dir"), Default, $hGUI)
				Else
					$iAnswer = $IDYES
				EndIf

				If $iAnswer = $IDYES Then $bSelected = True
			Case $hDir
				$sPath = FileSelectFolder(Lng_Get("settings.game_dir.caption"), "", Default, GUICtrlRead($hCombo), $hGUI)
				If Not @error Then GUICtrlSetData($hCombo, $sPath, $sPath)
		EndSwitch
	WEnd

	GUIDelete($hGUI)

	AutoItSetOption("GUIOnEventMode", $iOptionGUIOnEventMode)
	GUISetState(@SW_ENABLE, $MM_UI_MAIN)
	GUISetState(@SW_RESTORE, $MM_UI_MAIN)

	If Not $bSelected Or Not $sPath Then
		Return False
	Else
		$MM_GAME_DIR = $sPath
		$MM_GAME_NO_DIR = $MM_GAME_DIR = ""
		Settings_Set("path", $sPath)
		$MM_LIST_DIR_PATH = $MM_GAME_DIR & "\Mods"
		$MM_LIST_FILE_PATH = $MM_LIST_DIR_PATH & "\list.txt"
		$MM_GAME_EXE = Settings_Get("exe")
		Return True
	EndIf
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
	GUISetState(@SW_DISABLE, $MM_UI_MAIN)

	Local Const $iItemSpacing = 4
	Local $bClose = False
	Local $bSelected = False
	Local $sReturn = $MM_GAME_EXE
	Local $bAllowName, $sSelected

	Local $hGUI = GUICreate("", 200, 324, Default, Default, Default, Default, $MM_UI_MAIN)
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
	GUIDelete($hGUI)

	AutoItSetOption("GUIOnEventMode", $iOptionGUIOnEventMode)
	GUISetState(@SW_ENABLE, $MM_UI_MAIN)
	GUISetState(@SW_RESTORE, $MM_UI_MAIN)
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

