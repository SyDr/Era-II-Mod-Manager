#AutoIt3Wrapper_Version=prod
#include "include_fwd.au3"

; update mm version in main file
IniWrite(@ScriptDir & "\mmanager.au3", "Version", "#AutoIt3Wrapper_Res_Fileversion", $MM_VERSION_NUMBER)

Global Const $sBuildDir = @ScriptDir & "\Build"

Clear()
DirCreate($sBuildDir & "\Output\")
DirCreate(@ScriptDir & "\Publish\")
CopyToBuildDir()

; ShellExecuteWait(@ProgramFilesDir & "\AutoIt3\SciTE\AutoIt3Wrapper\Autoit3wrapper.exe", "/in mmanager.au3", $sBuildDir)
ShellExecuteWait(@ProgramFilesDir & "\AutoIt3\SciTE\au3Stripper\AU3Stripper", '"' & $sBuildDir & "\mmanager.au3"" /so /tl /debug", $sBuildDir)
CopyForOutput()
ShellExecuteWait(@ScriptDir & '\7z\7z.exe', 'a "MM.zip" "Mod Manager\*"', $sBuildDir)

FileMove($sBuildDir & "\MM.zip", @ScriptDir & "\Publish\MM_" & $MM_VERSION & ".zip", $FC_OVERWRITE)
Clear()

Func Clear()
	DirRemove($sBuildDir, 1)
EndFunc

Func CopyToBuildDir()
	FileCopy(@ScriptDir & "\*.au3", $sBuildDir & "\")
	DirCopy(@ScriptDir & "\7z", $sBuildDir & "\7z", 1)
	DirCopy(@ScriptDir & "\icons", $sBuildDir & "\icons", 1)
	DirCopy(@ScriptDir & "\lng", $sBuildDir & "\lng", 1)
	DirCopy(@ScriptDir & "\doc", $sBuildDir & "\doc", 1)
	DirCopy(@ScriptDir & "\include", $sBuildDir & "\include", 1)
EndFunc

Func CopyForOutput()
	DirCreate($sBuildDir & "\Mod Manager\")
	FileCopy($sBuildDir & "\mmanager_stripped.au3", $sBuildDir & "\Mod Manager\mmanager.au3", 1)
	FileCopy(@ScriptDir & "\License.txt", $sBuildDir & "\Mod Manager\")
	DirCopy($sBuildDir & "\7z", $sBuildDir & "\Mod Manager\7z", 1)
	DirCopy($sBuildDir & "\icons", $sBuildDir & "\Mod Manager\icons", 1)
	DirCopy($sBuildDir & "\lng", $sBuildDir & "\Mod Manager\lng", 1)
	DirCopy($sBuildDir & "\doc", $sBuildDir & "\Mod Manager\doc", 1)
	FileCopy(@ScriptDir & "\mmanager.cmd", $sBuildDir & "\Mod Manager\")
	FileCopy(@ScriptDir & "\mmanager.exe", $sBuildDir & "\Mod Manager\")
	FileCopy(@ScriptDir & "\autoit_license.txt", $sBuildDir & "\Mod Manager\")
	FileCopy(@ProgramFilesDir & "\AutoIt3\AutoIt3.exe", $sBuildDir  & "\Mod Manager\", 1)
EndFunc
