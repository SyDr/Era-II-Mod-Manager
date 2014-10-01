; Author:         Aliaksei SyDr Karalenka

#include <Array.au3>
#include <File.au3>

#include "include\JSMN.au3"
#include "data_fwd.au3"

#include-once

Func Lng_Load()
	Local $sText = FileRead(@ScriptDir & "\lng\" & $MM_SETTINGS_LANGUAGE)
	If @error Then Return SetError(1, @extended, "Can't read " & @ScriptDir & "\lng\" & $MM_SETTINGS_LANGUAGE)

	$MM_LNG_CACHE = Jsmn_Decode($sText)

	Return SetError(0, 0, "") ; everething ok
EndFunc   ;==>Lng_Load

Func Lng_LoadList()
	Local $asTemp = _FileListToArray(@ScriptDir & "\lng\", "*.json", 1)
	Local $asReturn[UBound($asTemp, $UBOUND_ROWS)][2] = [[$asTemp[0]]]
	Local $sText, $vDecoded

	For $i = 1 To $asTemp[0]
		$asReturn[$i][1] = $asTemp[$i]
		$sText = FileRead(@ScriptDir & "\lng\" & $asTemp[$i])

		If @error Then
			$asReturn[$i][1] = "Can't read file " & @ScriptDir & "\lng\" & $asTemp[$i]
		Else
			$vDecoded = Jsmn_Decode($sText)
			If @error Then
				$asReturn[$i][0] = "1 Error when parsing " & @ScriptDir & "\lng\" & $asTemp[$i]
			Else
				If Not IsObj($vDecoded) Then
					$asReturn[$i][0] = "2 Error when parsing " & @ScriptDir & "\lng\" & $asTemp[$i]
				ElseIf Not IsObj($vDecoded.Item("lang")) Then
					$asReturn[$i][0] = "3 Error when parsing " & @ScriptDir & "\lng\" & $asTemp[$i]
				Else
					$asReturn[$i][0] = $vDecoded.Item("lang").Item("name")
				EndIf
			EndIf
		EndIf
	Next

	Return $asReturn
EndFunc

Func Lng_Get(Const ByRef $sKeyName)
	If Not IsObj($MM_LNG_CACHE) Then Lng_Load()
	If Not IsObj($MM_LNG_CACHE) Then Return $sKeyName

	Local $sReturn
	Local $aParts = StringSplit($sKeyName, ".")

	Switch $aParts[0]
		Case 1
			$sReturn = $MM_LNG_CACHE.Item($aParts[1])
		Case 2
			$sReturn = $MM_LNG_CACHE.Item($aParts[1]).Item($aParts[2])
		Case 3
			$sReturn = $MM_LNG_CACHE.Item($aParts[1]).Item($aParts[2]).Item($aParts[3])
		Case 4
			$sReturn = $MM_LNG_CACHE.Item($aParts[1]).Item($aParts[2]).Item($aParts[3]).Item($aParts[4])
	EndSwitch

	Return $sReturn ? $sReturn : $sKeyName
EndFunc   ;==>Lng_Get

Func Lng_GetF(Const ByRef $sKeyName, $vParam1, $vParam2 = Default)
	If IsKeyword($vParam2) == $KEYWORD_DEFAULT Then
		Return StringFormat(Lng_Get($sKeyName), $vParam1)
	Else
		Return StringFormat(Lng_Get($sKeyName), $vParam1, $vParam2)
	EndIf
EndFunc
