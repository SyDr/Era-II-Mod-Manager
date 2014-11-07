; Author:         Aliaksei SyDr Karalenka

#AutoIt3Wrapper_Version=Beta
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

Func GUIRegisterMsgStateful(Const $iMessage, Const ByRef $sFuncName)
	Local Static $mRegistered = MapEmpty()
	If Not MapExists($mRegistered, $iMessage) And $sFuncName == "" Then Return
	If Not MapExists($mRegistered, $iMessage) And $sFuncName <> "" Then $mRegistered[$iMessage] = ArrayEmpty()

	Local $aList = $mRegistered[$iMessage]
	GUIRegisterMsg($iMessage, $sFuncName)

	If $sFuncName <> "" Then
		$aList[0] += 1
		If UBound($aList) <= $aList[0] Then ReDim $aList[$aList[0] + 1]
		$aList[$aList[0]] = $sFuncName
	Else
		$aList[0] -= 1
		If $aList[0] <> 0 Then GUIRegisterMsg($iMessage, $aList[$aList[0]])
	EndIf

	If $aList[0] <> 0 Then
		$mRegistered[$iMessage] = $aList
	Else
		MapRemove($mRegistered, $iMessage)
	EndIf

EndFunc

