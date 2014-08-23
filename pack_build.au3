#include <AutoItConstants.au3>

DirRemove("Mod Manager\", 1)
DirCreate("Mod Manager\")
FileCopy("modsmann.exe", "Mod Manager\")
DirCopy("7z", "Mod Manager\7z", 1)
DirCopy("icons", "Mod Manager\icons", 1)
DirCopy("lng", "Mod Manager\lng", 1)
FileChangeDir(@ScriptDir)
Run('"' & @ScriptDir & '\7z\7z.exe" a "Mod Manager_' & @MON & @MDAY & @HOUR & '.zip" "Mod Manager\*"', @ScriptDir, @SW_HIDE, $STDERR_CHILD + $STDOUT_CHILD)
