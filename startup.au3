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

Func StartUp_Assoc_Delete()
	If Not IsAdmin() Then
		Exit ShellExecuteWait(@ScriptFullPath, '/assocdel', @WorkingDir, "runas", @SW_SHOWNORMAL)
	EndIf

	RegDelete("HKCR\.emp")
	RegDelete("HKCR\Era.ModManager.Package")
	__StartUp_Assoc_Notify_System()
	Exit
EndFunc   ;==>StartUp_Assoc_Delete

Func __StartUp_Assoc_Notify_System()
	Local Const $SHCNE_ASSOCCHANGED = 0x8000000
	Local Const $SHCNF_IDLIST = 0

	DllCall("shell32.dll", "none", "SHChangeNotify", "long", $SHCNE_ASSOCCHANGED, "int", $SHCNF_IDLIST, "ptr", Null, "ptr", Null)
EndFunc   ;==>__StartUp_Assoc_Notify_System
