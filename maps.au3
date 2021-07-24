#include-once

#include <Array.au3>

; #INDEX# =======================================================================================================================
; Title .........: Maps
; AutoIt Version : 3.3.13.19
; Language ......: English
; Description ...: Functions for manipulating maps.
; Author(s) .....: Aliaksei SyDr Karalenka
; ===============================================================================================================================

; #CURRENT# =====================================================================================================================
; _MapDisplay
; _MapEmpty
; _MapFrom2DArray
; _MapItems
; _MapTo2DArray
; ===============================================================================================================================

Func _MapDisplay(Const ByRef $Map, $sTitle = Default, $iFlags = Default, $vUser_Separator = Default, $sHeader = Default, $iMax_ColWidth = Default)
	If Not IsMap($Map) Then Return SetError(1, 0, "")
	If UBound($Map) = 0 Then Return SetError(2, 0, "")

	If $sTitle = Default Then $sTitle = "MapDisplay"
	If $iFlags = Default Then $iFlags = 64
	If $sHeader = Default Then $sHeader = "Key" & Opt("GUIDataSeparatorChar") & "Value"

	Local $aKeys = MapKeys($Map)
	Local $Array[UBound($aKeys)][2]
	For $i = 0 To UBound($aKeys) - 1
		$Array[$i][0] = $aKeys[$i]
		$Array[$i][1] = VarGetType($Map[$aKeys[$i]]) & ":" & $Map[$aKeys[$i]]
	Next

	Return _ArrayDisplay($Array, $sTitle, Default, $iFlags, $vUser_Separator, $sHeader, $iMax_ColWidth)
EndFunc

Func _MapEmpty()
	Local $Map[]
	Return $Map
EndFunc

Func _MapItems(Const ByRef $Map)
	If Not IsMap($Map) Then Return SetError(1, 0, "")
	If UBound($Map) = 0 Then Return SetError(2, 0, "")

	Local $aKeys = MapKeys($Map)
	Local $Array[UBound($aKeys)]
	For $i = 0 To UBound($aKeys) - 1
		$Array[$i] = $Map[$aKeys[$i]]
	Next

	Return $Array
EndFunc

Func _MapTo2DArray(Const ByRef $Map, $iFlag = Default)
	If Not IsMap($Map) Then Return SetError(1, 0, "")
	If UBound($Map) = 0 Then Return SetError(2, 0, "")

	If $iFlag = Default Then $iFlag = 0

	Local $aKeys = MapKeys($Map)
	Local $iCount = BitAND($iFlag, 1)
	Local $Array[UBound($aKeys) + $iCount][2]
	For $i = 0 To UBound($aKeys) - 1
		$Array[$i + $iCount][0] = $aKeys[$i]
		$Array[$i + $iCount][1] = $Map[$aKeys[$i]]
	Next

	If $iCount Then $Array[0][0] = UBound($aKeys)

	Return $Array
EndFunc

Func _MapFrom2DArray(Const ByRef $Array, $iStart = Default, $iEnd = Default)
	If Not IsArray($Array) Then Return SetError(1, 0, _MapEmpty())
	If Not UBound($Array, 0) = 2 Then Return SetError(2, 0, _MapEmpty())
	If UBound($Array, 2) <> 2 Then Return SetError(3, 0, _MapEmpty())

	If $iStart = Default Or $iStart < 0 Then $iStart = 0
	If $iEnd = Default Or $iEnd >= UBound($Array, 1) Then $iEnd = UBound($Array, 1) - 1

	If $iStart > $iEnd Then Return SetError(4, 0, _MapEmpty())

	Local $Map[]
	For $i = $iStart To $iEnd
		$Map[$Array[$i][0]] = $Array[$i][1]
	Next

	Return $Map
EndFunc
