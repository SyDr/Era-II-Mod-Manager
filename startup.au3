; Author:         Aliaksei SyDr Karalenka

#AutoIt3Wrapper_Version=Beta
#include-once
#include "include_fwd.au3"
#include "mods.au3"

Func StartUp_CheckRunningInstance()
	Local $hSingleton = _Singleton("ERAIIMM {{C3125006-CAFE-4F97-B2A5-B287236A9DC6}", 1)

	If $hSingleton = 0 Then
		If WinActivate($MM_TITLE) Then Exit
	EndIf
EndFunc   ;==>StartUp_CheckRunningInstance

Func StartUp_WorkAsInstallmod()
	Local $bUseWorkDir = FileExists(@ScriptDir & "\im_use_work_dir")
	If $CMDLine[0] <> 1 Then
		MsgBox($MB_SYSTEMMODAL, "", "Usage:" & @CRLF & "installmod.exe <Mod Directory>" & @CRLF & ($bUseWorkDir ? "@WorkingDir will be used as root" : "@ScriptDir will be used as root"))
		Exit
	EndIf

	$MM_LIST_DIR_PATH = $bUseWorkDir ? (@WorkingDir & "\Mods") : (@ScriptDir & "\..\Mods")
	$MM_LIST_FILE_PATH = $MM_LIST_DIR_PATH & "\list.txt"

	Mod_ListLoad()
	Mod_ReEnable($CMDLine[1])
	Exit
EndFunc   ;==>StartUp_WorkAsInstallmod
