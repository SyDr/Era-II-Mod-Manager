; Author:         Aliaksei SyDr Karalenka

#include-once
#include "include_fwd.au3"

Global Const $mLng = Jsmn_Decode(FileRead(@ScriptDir & "\lng\english.json"))
Global $sValidate = "; this file is auto-generated" & @CRLF & "If Not IsMap($MM_LNG_CACHE) Then $MM_LNG_CACHE = MapEmpty()" & @CRLF
Global $aArray[1]

Generate($mLng)
FileDelete("lng_auto.au3")
FileWrite("lng_auto.au3", $sValidate)

Func Generate($mVar)
	Local $aItems = MapKeys($mVar)
	For $i = 0 To UBound($aItems) - 1
		_ArrayAdd($aArray, $aItems[$i])
		If Not IsMap($mVar[$aItems[$i]]) Then
			$sValidate &= StringFormat('If Not MapExists(%s) Or Not IsString($MM_LNG_CACHE%s) Then $MM_LNG_CACHE%s = ', FormatExistsKey(), FormatStringKey(), FormatStringKey()) & '"' & PrepareItem($mVar[$aItems[$i]]) &  '"' & @CRLF
		Else
			$sValidate &= StringFormat('If Not MapExists(%s) Or Not IsMap($MM_LNG_CACHE%s) Then $MM_LNG_CACHE%s = ', FormatExistsKey(), FormatStringKey(), FormatStringKey()) & 'MapEmpty()' & @CRLF
			Generate($mVar[$aItems[$i]])
		EndIf

		_ArrayDelete($aArray, UBound($aArray) - 1)
	Next
EndFunc

Func FormatExistsKey()
	Local $sReturn = "$MM_LNG_CACHE"
	For $i = 1 To UBound($aArray) - 2
		$sReturn &= StringFormat('["%s"]', $aArray[$i])
	Next

	$sReturn &= StringFormat(', "%s"', $aArray[UBound($aArray) - 1])

	Return $sReturn
EndFunc

Func FormatStringKey()
	Local $sReturn = ""
	For $i = 1 To UBound($aArray) - 1
		$sReturn &= StringFormat('["%s"]', $aArray[$i])
	Next

	Return $sReturn
EndFunc

Func PrepareItem(Const $sData)
	Local $sReturn = $sData
	$sReturn = StringReplace($sReturn, @CR, "\r")
	$sReturn = StringReplace($sReturn, @LF, "\n")
	$sReturn = StringReplace($sReturn, '"', '""')
	Return $sReturn
EndFunc
