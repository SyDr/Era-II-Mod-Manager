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
