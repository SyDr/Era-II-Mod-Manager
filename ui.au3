; Author:         Aliaksei SyDr Karalenka

#AutoIt3Wrapper_Version=Beta
#include-once

#include "include_fwd.au3"

#include "lng.au3"
#include "settings.au3"
#include "utils.au3"

Global $__UI_DBLCLK = False, $__UI_LIST

Func UI_GameExeLaunch()
	If $MM_COMPATIBILITY_MESSAGE <> "" Then
		Local $iAnswer = MsgBox($MB_SYSTEMMODAL + $MB_YESNO, "", $MM_COMPATIBILITY_MESSAGE & @CRLF & Lng_Get("compatibility.launch_anyway"), Default, $MM_UI_MAIN)
		If $iAnswer <> $IDYES Then Return
	EndIf

	Run($MM_GAME_DIR & "\" & $MM_GAME_EXE, $MM_GAME_DIR)
EndFunc

Func UI_SelectGameDir()
	Local $sPath = FileSelectFolder(Lng_Get("settings.game_dir.caption"), "", Default, Settings_Get("path"), $MM_UI_MAIN)
	If @error Then
		Return False
	Else
		$MM_GAME_DIR = $sPath
		$MM_GAME_NO_DIR = $MM_GAME_DIR = ""
		Settings_Set("path", $sPath)
		$MM_LIST_DIR_PATH = $MM_GAME_DIR & "\Mods"
		$MM_LIST_FILE_PATH = $MM_LIST_DIR_PATH & "\list.txt"
		$MM_GAME_EXE = Settings_Get("exe")
	EndIf

	Return True
EndFunc

Func UI_SelectGameExe()
	Local $aList = _FileListToArray($MM_GAME_DIR, "*.exe", $FLTA_FILES)
	If Not IsArray($aList) Then Local $aList[1] = [0]
	Local Const $iOptionGUIOnEventMode = AutoItSetOption("GUIOnEventMode", 0)
	Local Const $iOptionGUICoordMode = AutoItSetOption("GUICoordMode", 0)
	Local Const $aBlacklist = Settings_Get("game.blacklist")
	GUISetState(@SW_DISABLE, $MM_UI_MAIN)

	Local Const $iItemSpacing = 4
	Local $bClose = False
	Local $bSelected = False
	Local $sReturn = $MM_GAME_EXE
	Local $bAllowName, $sSelected

	Local $hGUI = GUICreate("", 200, 324, Default, Default, Default, Default, $MM_UI_MAIN)
	Local $aSize = WinGetClientSize($hGUI)
	GUISetIcon(@ScriptDir & "\icons\preferences-system.ico")
	GUIRegisterMsgStateful($WM_NOTIFY, "__UI_WM_NOTIFY")
	$__UI_LIST = GUICtrlCreateTreeView($iItemSpacing, $iItemSpacing, _ ; left, top
			$aSize[0] - 2 * $iItemSpacing, $aSize[1] - 3 * $iItemSpacing - 25, _
			BitOR($TVS_FULLROWSELECT, $TVS_DISABLEDRAGDROP, $TVS_SHOWSELALWAYS), $WS_EX_CLIENTEDGE)
	Local $hShowAll = GUICtrlCreateCheckbox(Lng_Get("settings.game_exe.show_all"), 0, GUICtrlGetPos($__UI_LIST)[3] + $iItemSpacing, Default, 25)
	GUISetCoord(GUICtrlGetPos($__UI_LIST)[0], GUICtrlGetPos($__UI_LIST)[1])
	Local $hOk = GUICtrlCreateButton("OK", $aSize[0] - 2 * $iItemSpacing - 75, GUICtrlGetPos($__UI_LIST)[3] + $iItemSpacing, 75, 25)
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
		If $__UI_DBLCLK Then
			$bSelected = True
			$__UI_DBLCLK = False
		EndIf
	WEnd

	If $bSelected Then
		$sSelected = GUICtrlRead($__UI_LIST, 1)
		If $sSelected <> "" Then $sReturn = $sSelected
	EndIf

	GUIRegisterMsgStateful($WM_NOTIFY, "")
	GUIDelete($hGUI)

	AutoItSetOption("GUIOnEventMode", $iOptionGUIOnEventMode)
	AutoItSetOption("GUICoordMode", $iOptionGUICoordMode)
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
					$__UI_DBLCLK = True
			EndSwitch
	EndSwitch

	Return $GUI_RUNDEFMSG
EndFunc   ;==>WM_NOTIFY
