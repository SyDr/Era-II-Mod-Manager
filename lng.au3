; Author:         Aliaksei SyDr Karalenka

#include <Array.au3>

#include "data_fwd.au3"

#include-once


Func Lng_Load()
	Local $aSections = IniReadSectionNames(@ScriptDir & "\lng\" & $MM_SETTINGS_LANGUAGE)
	If @error Then Return SetError(1, @extended, "Can't read " & @ScriptDir & "\lng\" & $MM_SETTINGS_LANGUAGE)

	Local $aResult[1][2] = [[0, 0]]

	For $iCount = 1 To $aSections[0]
		Local $aTmp = IniReadSection(@ScriptDir & "\lng\" & $MM_SETTINGS_LANGUAGE, $aSections[$iCount])
		If @error Then Return SetError(2, @extended, "Can't read " & @ScriptDir & "\lng\" & $MM_SETTINGS_LANGUAGE)

		ReDim $aResult[UBound($aResult, $UBOUND_ROWS) + $aTmp[0][0]][2]

		For $jCount = 1 To $aTmp[0][0]
			$aResult[$aResult[0][0] + $jCount][0] = $aTmp[$jCount][0]
			$aResult[$aResult[0][0] + $jCount][1] = $aTmp[$jCount][1]
		Next

		$aResult[0][0] += $aTmp[0][0]
	Next

	_ArraySort($aResult, 0, 1, $aResult[0][0])

	$MM_LNG_CACHE = $aResult

	Return SetError(0, 0, "") ; everething ok
EndFunc   ;==>Lng_Load

Func Lng_Get($sKeyName)
	If Not IsArray($MM_LNG_CACHE) Then
		Lng_Load()
	EndIf

	If Not IsArray($MM_LNG_CACHE) Then
		Return $sKeyName
	EndIf

	Local $iLeft = 1, $iRight = $MM_LNG_CACHE[0][0], $iIndex

	While $iLeft <= $iRight
		$iIndex = Floor(($iLeft + $iRight) / 2)

		If $sKeyName < $MM_LNG_CACHE[$iIndex][0] Then
			$iRight = $iIndex - 1
		ElseIf $sKeyName > $MM_LNG_CACHE[$iIndex][0] Then
			$iLeft = $iIndex + 1
		Else
			$iLeft = $iRight + 1
		EndIf
	WEnd

	If $iIndex > $MM_LNG_CACHE[0][0] Or $MM_LNG_CACHE[$iIndex][0] <> $sKeyName Then
		Return $sKeyName ; not found
	Else
		Return $MM_LNG_CACHE[$iIndex][1]
	EndIf
EndFunc   ;==>Lng_Get
