; Author:         Aliaksei SyDr Karalenka

#include <Array.au3>
#include-once

Global Static $__LNG_CACHED

Func Lng_LoadFile($sLanguage)
	Local $aSections = IniReadSectionNames(@ScriptDir & "\lng\" & $sLanguage)
	If @error Then Return SetError(1, @extended, "Can't read " & @ScriptDir & "\lng\" & $sLanguage)

	Local $aResult[1][2] = [[0, 0]]

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

	$__LNG_CACHED = $aResult

	Return 0
EndFunc

Func Lng_Get($sKeyName)
	If Not IsArray($__LNG_CACHED) Then Return $sKeyName
	Local $iLeft = 1, $iRight = $__LNG_CACHED[0][0], $iIndex

	While $iLeft <= $iRight
		$iIndex = Floor(($iLeft + $iRight) / 2)

		If $sKeyName < $__LNG_CACHED[$iIndex][0] Then
			$iRight = $iIndex - 1
		ElseIf $sKeyName > $__LNG_CACHED[$iIndex][0] Then
			$iLeft = $iIndex + 1
		Else
			$iLeft = $iRight + 1
		EndIf
	WEnd

	If $iIndex > $__LNG_CACHED[0][0] Or $__LNG_CACHED[$iIndex][0] <> $sKeyName Then
		Return $sKeyName ; not found
	Else
		Return $__LNG_CACHED[$iIndex][1]
	EndIf
EndFunc
