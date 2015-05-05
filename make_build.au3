#AutoIt3Wrapper_Version=Beta
#include "include_fwd.au3"

; update mm version in main file
If IniRead(@ScriptDir & "\mmanager.au3", "Version", "#AutoIt3Wrapper_Res_Fileversion", "") <> $MM_VERSION_NUMBER Then
	IniWrite(@ScriptDir & "\mmanager.au3", "Version", "#AutoIt3Wrapper_Res_Fileversion", $MM_VERSION_NUMBER)
EndIf

Global Const $sBuildDir = @ScriptDir & "\Build"

Clear()
DirCreate($sBuildDir & "\Output\")
CopyToBuildDir()

ShellExecuteWait(@ProgramFilesDir & "\AutoIt3\SciTE\AutoIt3Wrapper\Autoit3wrapper.exe", "/in mmanager.au3", $sBuildDir)
CopyForOutput()
ShellExecuteWait(@ScriptDir & '\7z\7z.exe', 'a "MM.zip" "Mod Manager\*"', $sBuildDir)

FileMove($sBuildDir & "\MM.zip", @ScriptDir & "\Publish\MM_" & $MM_VERSION & ".zip", $FC_OVERWRITE)
Clear()

Func Clear()
	DirRemove($sBuildDir, 1)
EndFunc

Func CopyToBuildDir()
	FileCopy(@ScriptDir & "\*.au3", $sBuildDir & "\")
	FileCopy(@ScriptDir & "\License.txt", $sBuildDir & "\")
	FileCopy(@ScriptDir & "\setup.iss", $sBuildDir & "\")
	DirCopy(@ScriptDir & "\7z", $sBuildDir & "\7z", 1)
	DirCopy(@ScriptDir & "\icons", $sBuildDir & "\icons", 1)
	DirCopy(@ScriptDir & "\lng", $sBuildDir & "\lng", 1)
	DirCopy(@ScriptDir & "\doc", $sBuildDir & "\doc", 1)
	DirCopy(@ScriptDir & "\include", $sBuildDir & "\include", 1)
	FileDelete(@ScriptDir & "\Mod Manager\icons\preferences-system.ico")
EndFunc

Func CopyForOutput()
	DirCreate($sBuildDir & "\Mod Manager\")
	FileCopy($sBuildDir & "\mmanager.exe", $sBuildDir & "\Mod Manager\", 1)
	FileCopy($sBuildDir & "\License.txt", $sBuildDir & "\Mod Manager\")
	DirCopy($sBuildDir & "\7z", $sBuildDir & "\Mod Manager\7z", 1)
	DirCopy($sBuildDir & "\icons", $sBuildDir & "\Mod Manager\icons", 1)
	DirCopy($sBuildDir & "\lng", $sBuildDir & "\Mod Manager\lng", 1)
	DirCopy($sBuildDir & "\doc", $sBuildDir & "\Mod Manager\doc", 1)
	FileDelete($sBuildDir & "\Mod Manager\icons\preferences-system.ico")
EndFunc
