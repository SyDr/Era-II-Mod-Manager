; Author:         Aliaksei SyDr Karalenka

#include-once

#include "include_fwd.au3"

#include "lng.au3"

Func Utils_LaunchInBrowser($sLink)
	Local Const $http = "http://"
	Local Const $https = "https://"

	If StringLeft($sLink, StringLen($http)) == $http Or StringLeft($sLink, StringLen($https)) == $https Then
		ShellExecute($sLink)
	Else
		ShellExecute($http & $sLink)
	EndIf
EndFunc

Func MapEmpty()
	Local $mMap[]
	Return $mMap
EndFunc

Func ArrayEmpty(Const $iDim = 1)
	Switch $iDim
		Case 1
			Local $Array[1] = [0]
		Case 2
			Local $Array[1][1] = [[0]]
	EndSwitch

	Return $Array
EndFunc

Func VersionCompare(Const $s1, Const $s2)
	Local $aVersion1 = StringSplit($s1, ".", 2)
	Local $aVersion2 = StringSplit($s2, ".", 2)

	Local $iSize = UBound($aVersion1) > UBound($aVersion2) ? UBound($aVersion1) : UBound($aVersion2)
	ReDim $aVersion1[$iSize]
	ReDim $aVersion2[$iSize]
	; 1.0.0 and 1.0 is same version

	For $i = 0 To $iSize - 1
		If Number($aVersion1[$i]) > Number($aVersion2[$i]) Then
			Return $i+1
		ElseIf Number($aVersion1[$i]) < Number($aVersion2[$i]) Then
			Return -($i+1)
		EndIf
	Next

	Return 0
EndFunc

Func GUICtrlGetPos(Const $idControl)
	If IsHWnd($idControl) Then
		Return ControlGetPos($idControl, '', 0)
	Else
		Return ControlGetPos(GUICtrlGetHandle($idControl), '', 0)
	EndIf
EndFunc

Func GUICtrlSetStateStateful(Const $idControl, Const $iState = -1)
	Local Static $mDataEn = MapEmpty()
	Local Static $mDataSh = MapEmpty()

	If $iState = -1 Then
		MapRemove($mDataSh, $idControl)
		MapRemove($mDataEn, $idControl)
	ElseIf BitAND($iState, $GUI_SHOW) = $GUI_SHOW Or BitAND($iState, $GUI_HIDE) = $GUI_HIDE Then
		If Not MapExists($mDataSh, $idControl) Then $mDataSh[$idControl] = 1
		$mDataSh[$idControl] += $iState = $GUI_SHOW ? 1 : -1
		If $mDataSh[$idControl] > 0 And $iState = $GUI_SHOW And Not BitAND(GUICtrlGetState($idControl), $GUI_SHOW) = $GUI_SHOW Then GUICtrlSetState($idControl, $GUI_SHOW)
		If $mDataSh[$idControl] < 1 And $iState = $GUI_HIDE And Not BitAND(GUICtrlGetState($idControl), $GUI_HIDE) = $GUI_HIDE Then GUICtrlSetState($idControl, $GUI_HIDE)
	ElseIf BitAND($iState, $GUI_ENABLE) = $GUI_ENABLE Or BitAND($iState, $GUI_DISABLE) = $GUI_DISABLE Then
		If Not MapExists($mDataEn, $idControl) Then $mDataEn[$idControl] = 1
		$mDataEn[$idControl] += $iState = $GUI_ENABLE ? 1 : -1
		If $mDataEn[$idControl] > 0 And $iState = $GUI_ENABLE  And Not BitAND(GUICtrlGetState($idControl), $GUI_ENABLE ) = $GUI_ENABLE  Then GUICtrlSetState($idControl, $GUI_ENABLE )
		If $mDataEn[$idControl] < 1 And $iState = $GUI_DISABLE And Not BitAND(GUICtrlGetState($idControl), $GUI_DISABLE) = $GUI_DISABLE Then GUICtrlSetState($idControl, $GUI_DISABLE)
	EndIf
EndFunc

Func Utils_SelectFromListUI(ByRef $aList, Const $hParent = 0, Const $iSelected = 1)
	Local Const $iOptionGUIOnEventMode = AutoItSetOption("GUIOnEventMode", 0)
	Local Const $iOptionGUICoordMode = AutoItSetOption("GUICoordMode", 0)
	GUISetState(@SW_DISABLE, $hParent)
	Local Const $iItemSpacing = 4
	Local $bClose = False

	Local $hGUI = GUICreate("", 200, 324, Default, Default, Default, Default, $hParent)
	GUISetIcon(@ScriptDir & "\icons\preferences-system.ico")
	Local $aSize = WinGetClientSize($hGUI)
	Local $hList = GUICtrlCreateTreeView($iItemSpacing, $iItemSpacing, _ ; left, top
			$aSize[0] - 2 * $iItemSpacing, $aSize[1] - 3 * $iItemSpacing - 25, _
			BitOR($TVS_FULLROWSELECT, $TVS_DISABLEDRAGDROP, $TVS_SHOWSELALWAYS), $WS_EX_CLIENTEDGE)
	Local $hOk = GUICtrlCreateButton("OK", $aSize[0] - 2 * $iItemSpacing - 75, GUICtrlGetPos($hList)[3] + $iItemSpacing, 75, 25)
	Local $hListItems = $aList
	For $i = 1 To $aList[0]
		$hListItems[$i] = GUICtrlCreateTreeViewItem($aList[$i], $hList)
		If $iSelected = $i Then GUICtrlSetState($hListItems[$i], $GUI_FOCUS)
	Next

	GUISetState(@SW_SHOW)

	While Not $bClose
		Switch GUIGetMsg()
			Case $GUI_EVENT_CLOSE, $hOk
				$bClose = True
		EndSwitch
	WEnd

	GUIDelete($hGUI)

	AutoItSetOption("GUIOnEventMode", $iOptionGUIOnEventMode)
	AutoItSetOption("GUICoordMode", $iOptionGUICoordMode)
	GUISetState(@SW_ENABLE, $hParent)
	GUISetState(@SW_RESTORE, $hParent)
EndFunc
