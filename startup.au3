; Author:         Aliaksei SyDr Karalenka

#include <Misc.au3>
#include "lng.au3"

Func StartUp_CheckRunningInstance()

	Local $hSingleton = _Singleton("EMMat." & Hex(StringToBinary(@ScriptDir)), 1)

	If $hSingleton = 0 Then
		If WinActivate(StringFormat(Lng_Get("main.title"), $_VERSION)) Then Exit
	EndIf
EndFunc
