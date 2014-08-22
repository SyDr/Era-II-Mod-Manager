; AutoIt Version: 3.3.9.4 (beta)
; Author:         SyDr

#include <Array.au3>
#include-once
;~ MsgBox(4096, Default, Lng_LoadFile("lng\russian.ini"))
;~ MsgBox(4096, Default, Lng_Get("add_new"))

Func Lng_LoadFile($sLanguage)
	Local $aSections = IniReadSectionNames(@ScriptDir & "\lng\" & $sLanguage)
	If @error Then Return SetError(1, @extended, "Can't read " & @ScriptDir & "\lng\" & $sLanguage)

	Local $aResult[1][2] = [[0, "<- Total Lines, KeyCode=Value"]]
	For $iCount = 1 To $aSections[0]
		Local $aTmp = IniReadSection(@ScriptDir & "\lng\" & $sLanguage, $aSections[$iCount])
		If @error Then Return SetError(2, @extended, "Can't read " & @ScriptDir & "\lng\" & $sLanguage)

		ReDim $aResult[UBound($aResult, 1) + $aTmp[0][0]][2]

		For $jCount = 1 To $aTmp[0][0]
			$aResult[$aResult[0][0] + $jCount][0] = $aTmp[$jCount][0]
			$aResult[$aResult[0][0] + $jCount][1] = $aTmp[$jCount][1]
		Next
		$aResult[0][0] += $aTmp[0][0]
	Next
	_ArraySort($aResult, 0, 1, $aResult[0][0])
;~ 	For $iCount = 2 To $aResult[0][0]
;~ 		If $aResult[$iCount][0] = $aResult[$iCount-1][0] Then Return SetError(3, @extended, StringFormat("KeyCode: %s, value1=%s, value2=%s", $aResult[$iCount][0], $aResult[$iCount-1][1], $aResult[$iCount][1]))
;~ 	Next
;~ 	_ArrayDisplay($aResult)
	__Lng_Store("Set", $aResult)
	Return 0
EndFunc

Func __Lng_Store($sAction = "Get", $vValue = "")
	Local Static $aLngFile = ""
	Switch $sAction
		Case "Get"
			Return $aLngFile
		Case "Set"
			$aLngFile = $vValue
			Return True
		Case Else
			Return False
	EndSwitch
EndFunc

Func Lng_Get($sValue)
	Local $asLng = __Lng_Store("Get")
	If Not IsArray($asLng) Then Return $sValue
	Local $iLeft = 1, $iRight = $asLng[0][0], $iIndex

	While $iLeft <= $iRight
		$iIndex = Floor(($iLeft+$iRight)/2)
;~ 		MsgBox(4096, Default, $iLeft & " " & $iRight & " " & $iIndex & " " & $asLng[$iIndex][0])
		If $sValue < $asLng[$iIndex][0] Then
			$iRight = $iIndex - 1
		ElseIf $sValue > $asLng[$iIndex][0] Then
			$iLeft = $iIndex + 1
		Else
			$iLeft = $iRight + 1
		EndIf
	WEnd

	If $iIndex>$asLng[0][0] Or $asLng[$iIndex][0]<>$sValue Then
		Return $sValue
	Else
		If $sValue = "main.title" And Lng_Get("lang.author")<>"SyDr" Then Return $asLng[$iIndex][1] & " [translation: " & Lng_Get("lang.author") & "]"
		Return $asLng[$iIndex][1]
	EndIf
EndFunc
