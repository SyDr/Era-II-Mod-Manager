#include <FileConstants.au3>

#include "include\JSMN.au3"
#include "const.au3"

Global $sPath = @UserProfileDir & "\Dropbox\Public\RAMM"
Global $sVersionPath = $sPath & "\version.json"
Global $oVersion = Jsmn_Decode(FileRead($sVersionPath))

FileCopy(@ScriptDir & "\Publish\RAMM_" & $MM_VERSION & ".exe", $sPath & "\" & $MM_VERSION_SUBTYPE & "\RAMM_" & $MM_VERSION & ".exe", $FC_OVERWRITE + $FC_CREATEPATH)
FileCopy(@ScriptDir & "\Publish\RAMM_" & $MM_VERSION & ".zip", $sPath & "\" & $MM_VERSION_SUBTYPE & "\RAMM_" & $MM_VERSION & ".zip", $FC_OVERWRITE + $FC_CREATEPATH)

$oVersion.Item($MM_VERSION_SUBTYPE) = $MM_VERSION_NUMBER
FileDelete($sVersionPath)
FileWriteLine($sVersionPath, Jsmn_Encode($oVersion, $JSMN_PRETTY_PRINT))
