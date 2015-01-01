; Author:         Aliaksei SyDr Karalenka

#AutoIt3Wrapper_Version=Beta
#include-once
#include "include_fwd.au3"

#include "utils.au3"

Global $MM_LNG_CACHE

Func Lng_Load()
	Local $sText = FileRead(@ScriptDir & "\lng\" & $MM_SETTINGS_LANGUAGE)
	If @error Then Return SetError(1, @extended, "Can't read .\lng\" & $MM_SETTINGS_LANGUAGE)

	$MM_LNG_CACHE = Jsmn_Decode($sText)
	__Lng_Validate()
	$MM_LANGUAGE_CODE = IsMap($MM_LNG_CACHE) ? (IsMap($MM_LNG_CACHE["lang"]) ? $MM_LNG_CACHE["lang"]["code"] : "fail") : "fail"

	Return SetError(0, 0, "") ; everething ok
EndFunc   ;==>Lng_Load

Func __Lng_Validate()
	#include "lng_auto.au3"
EndFunc

Func Lng_LoadList()
	Local $asTemp = _FileListToArray(@ScriptDir & "\lng\", "*.json", 1)
	Local $asReturn[UBound($asTemp, $UBOUND_ROWS)][$MM_LNG_TOTAL] = [[$asTemp[0]]]
	Local $sText, $vDecoded

	For $i = 1 To $asTemp[0]
		$asReturn[$i][$MM_LNG_FILE] = $asTemp[$i]
		$sText = FileRead(@ScriptDir & "\lng\" & $asTemp[$i])

		If @error Then
			$asReturn[$i][1] = "Can't read .\lng\" & $asTemp[$i]
		Else
			$vDecoded = Jsmn_Decode($sText)
			$asReturn[$i][$MM_LNG_CODE] = "fail"
			$asReturn[$i][$MM_LNG_MENU_ID] = 0

			If @error Then
				$asReturn[$i][$MM_LNG_NAME] = StringFormat("Error '%s' when parsing .\lng\%s", @error, $asTemp[$i])
			Else
				If Not IsMap($vDecoded) Then
					$asReturn[$i][$MM_LNG_NAME] = StringFormat("Error '%s' when parsing .\lng\%s", '$vDecoded is not map', $asTemp[$i])
				ElseIf Not IsMap($vDecoded["lang"]) Then
					$asReturn[$i][$MM_LNG_NAME] = StringFormat("Error '%s' when parsing .\lng\%s", '$vDecoded["lang"] is not map', $asTemp[$i])
				Else
					$asReturn[$i][$MM_LNG_NAME] = $vDecoded["lang"]["name"]
					$asReturn[$i][$MM_LNG_CODE] = $vDecoded["lang"]["code"]
				EndIf
			EndIf
		EndIf
	Next

	$MM_LNG_LIST = $asReturn
EndFunc

Func Lng_GetCodeByName(Const $sName)
	For $i = 1 To $MM_LNG_LIST[0][0]
		If $MM_LNG_LIST[$i][$MM_LNG_NAME] = $sName Then Return $MM_LNG_LIST[$i][$MM_LNG_CODE]
	Next

	Return "en_US"
EndFunc

Func Lng_GetCategoryList()
	Return MapKeys($MM_LNG_CACHE["category"])
EndFunc

Func Lng_Get(Const ByRef $sKeyName)
	If Not IsMap($MM_LNG_CACHE) Then Lng_Load()
	If Not IsMap($MM_LNG_CACHE) Then Return $sKeyName

	Local $sReturn
	Local $aPartsLower = StringSplit(StringLower($sKeyName), ".")
	Local $aParts = StringSplit($sKeyName, ".")

	If $aParts[0] > 0 And Not IsMap($MM_LNG_CACHE) Then Return $sKeyName
	If $aParts[0] > 1 And Not IsMap($MM_LNG_CACHE[$aPartsLower[1]]) Then Return $sKeyName
	If $aParts[0] > 2 And Not IsMap($MM_LNG_CACHE[$aPartsLower[1]][$aPartsLower[2]]) Then Return $sKeyName
	If $aParts[0] > 3 And Not IsMap($MM_LNG_CACHE[$aPartsLower[1]][$aPartsLower[2]][$aPartsLower[3]]) Then Return $sKeyName

	Switch $aParts[0]
		Case 1
			$sReturn = $MM_LNG_CACHE[$aPartsLower[1]]
		Case 2
			$sReturn = $MM_LNG_CACHE[$aPartsLower[1]][$aPartsLower[2]]
			If IsKeyword($sReturn) And $aPartsLower[1] = "category" Then $sReturn = $aParts[2]
		Case 3
			$sReturn = $MM_LNG_CACHE[$aPartsLower[1]][$aPartsLower[2]][$aPartsLower[3]]
		Case 4
			$sReturn = $MM_LNG_CACHE[$aPartsLower[1]][$aPartsLower[2]][$aPartsLower[3]][$aPartsLower[4]] ; who need recursion anyway? :)
	EndSwitch

	Return Not IsKeyword($sReturn) ? $sReturn : $sKeyName
EndFunc   ;==>Lng_Get

Func Lng_GetF(Const ByRef $sKeyName, Const $vParam1, Const $vParam2 = Default)
	If IsKeyword($vParam2) == $KEYWORD_DEFAULT Then
		Return StringFormat(Lng_Get($sKeyName), $vParam1)
	Else
		Return StringFormat(Lng_Get($sKeyName), $vParam1, $vParam2)
	EndIf
EndFunc
