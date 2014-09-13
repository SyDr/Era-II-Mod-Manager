; Author:         Aliaksei SyDr Karalenka

#include <Misc.au3>

#include "data_fwd.au3"
#include "folder_mods.au3"

#include-once


Func StartUp_CheckRunningInstance($sTitle)
	Local $hSingleton = _Singleton("EMMat." & Hex(StringToBinary(@ScriptDir)), 1)

	If $hSingleton = 0 Then
		If WinActivate($sTitle) Then Exit
	EndIf
EndFunc

Func StartUp_WorkAsInstallmod()
	Local $bUseWorkDir = FileExists(@ScriptDir & "\im_use_work_dir")
	If $CMDLine[0] <> 1 Then
		MsgBox(4096, "", "Usage:" & @CRLF & "installmod.exe <Mod Directory>" & @CRLF & ($bUseWorkDir ? "@WorkingDir will be used as root" : "@ScriptDir will be used as root"))
		Exit
	EndIf

	Local $sBasePath = $bUseWorkDir ? (@WorkingDir & "\Mods") : (@ScriptDir & "\..\Mods")
	Local $sDefaultList = $sBasePath & "\list.txt"

	$MM_LIST_FILE_PATH = $sDefaultList
	$MM_LIST_DIR_PATH = $sBasePath

	Local $auModList = Mod_ListLoad()
	Mod_ReEnable($auModList, $CMDLine[1])
	Exit
EndFunc
