#include <AutoItConstants.au3>
#include <FileConstants.au3>

Clear()
Global $sVersion = IniRead(@ScriptDir & "\props.ini", "version", "version", "0.0")
Global $sType = IniRead(@ScriptDir & "\props.ini", "version", "type", "")
Global $sFull = $sType ? ($sVersion & "." & $sType) : $sVersion

DirCreate(@ScriptDir & "\Mod Manager\")
DirCreate(@ScriptDir & "\Output\")
DirCreate(@ScriptDir & "\Publish\")

ShellExecuteWait(@ProgramFilesDir & "\AutoIt3\SciTE\AutoIt3Wrapper\Autoit3wrapper.exe", "/in ramm.au3", @ScriptDir)

FileCopy("ramm.exe", "Mod Manager\")
FileCopy("License.txt", "Mod Manager\")
DirCopy("7z", "Mod Manager\7z", 1)
DirCopy("icons", "Mod Manager\icons", 1)
FileDelete("Mod Manager\icons\preferences-system.ico")
DirCopy("lng", "Mod Manager\lng", 1)

FileChangeDir(@ScriptDir)
ShellExecuteWait(@ProgramFilesDir & "\Inno Setup 5\ISCC.exe", "setup.iss", @ScriptDir)

IniWrite(@ScriptDir & "\Mod Manager\settings.ini", "settings", "Portable", 1)
ShellExecuteWait(@ScriptDir & '\7z\7z.exe', 'a "RAMM.zip" "Mod Manager\*"', @ScriptDir)

FileMove(@ScriptDir & "\RAMM.zip", @ScriptDir & "\Publish\RAMM_" & $sFull & ".zip", $FC_OVERWRITE)
FileMove(@ScriptDir & "\Output\setup.exe", @ScriptDir & "\Publish\RAMM_" & $sFull & ".exe", $FC_OVERWRITE)
Clear()

Func Clear()
	FileDelete(@ScriptDir & "ramm.exe")
	DirRemove(@ScriptDir & "\Mod Manager\", 1)
	DirRemove(@ScriptDir & "\Output\", 1)
EndFunc

