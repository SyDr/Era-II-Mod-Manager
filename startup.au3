; Author:         Aliaksei SyDr Karalenka

#include <Misc.au3>

Func StartUp_CheckRunningInstance($sTitle)
	Local $hSingleton = _Singleton("EMMat." & Hex(StringToBinary(@ScriptDir)), 1)

	If $hSingleton = 0 Then
		If WinActivate($sTitle) Then Exit
	EndIf
EndFunc
