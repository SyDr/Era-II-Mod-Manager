; Author:         Aliaksei SyDr Karalenka

#include-once

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

Func MapTo2DArray(ByRef $Map)
	Local $Keys = MapKeys($Map)
	Local $Length = UBound($Keys)

	Local $Array[$Length + 1][2]
	$Array[0][0] = $Length
	$Array[0][1] = ''

	For $i = 1 To $Length
		Local $Key = $Keys[$i - 1]
		Local $Value = $Map[$Key]

		$Array[$i][0] = VarGetType($Key) & ":" & $Key
		$Array[$i][1] = VarGetType($Value) & ":" & IsKeyword($Value) & ":" & $Value
	Next
	Return $Array
EndFunc