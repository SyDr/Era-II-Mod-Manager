; Author:         Aliaksei SyDr Karalenka

#AutoIt3Wrapper_Version=Beta
#include "include_fwd.au3"
#include "utils.au3"

Global $sPath = @UserProfileDir & "\Dropbox\Public\"
Global $sVersionPath = $sPath & "\ramm.json"
Global $mVersion = Jsmn_Decode(FileRead($sVersionPath))

FileCopy(@ScriptDir & "\Publish\RAMM_" & $MM_VERSION & ".exe", $sPath & "\RAMM\" & $MM_VERSION_SUBTYPE & "\RAMM_" & $MM_VERSION & ".exe", $FC_OVERWRITE + $FC_CREATEPATH)
FileCopy(@ScriptDir & "\Publish\RAMM_" & $MM_VERSION & ".zip", $sPath & "\RAMM\" & $MM_VERSION_SUBTYPE & "\RAMM_" & $MM_VERSION & ".zip", $FC_OVERWRITE + $FC_CREATEPATH)

$mVersion["items"][$MM_VERSION_NUMBER] = MapEmpty()
$mVersion["items"][$MM_VERSION_NUMBER]["type"] = $MM_VERSION_SUBTYPE
$mVersion["items"][$MM_VERSION_NUMBER]["setup"] = "/RAMM/" & $MM_VERSION_SUBTYPE & "/RAMM_" & $MM_VERSION & ".exe"
$mVersion["items"][$MM_VERSION_NUMBER]["portable"] = "/RAMM/" & $MM_VERSION_SUBTYPE & "/RAMM_" & $MM_VERSION & ".zip"

FileDelete($sVersionPath)
FileWriteLine($sVersionPath, Jsmn_Encode($mVersion, $JSMN_PRETTY_PRINT + $JSMN_UNESCAPED_UNICODE + $JSMN_UNESCAPED_SLASHES))
