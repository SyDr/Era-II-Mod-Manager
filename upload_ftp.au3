; Author:         Aliaksei SyDr Karalenka

#AutoIt3Wrapper_Version=Beta
#include "include_fwd.au3"
#include "utils.au3"

#include <FTPEx.au3>

Global $hFTP = _FTP_Open('wakeofgods.org ftp')
Global $hConnection = _FTP_Connect($hFTP, "wakeofgods.org", "ramm@wakeofgods.org", FileRead("ftp_pass.txt"), True)

_FTP_DirSetCurrent($hConnection, "/beta")
_FTP_FileDelete($hConnection, "RAMM_" & $MM_VERSION & ".exe")
_FTP_FileDelete($hConnection, "RAMM_" & $MM_VERSION & ".zip")
_FTP_ProgressUpload($hConnection, @ScriptDir & "\Publish\RAMM_" & $MM_VERSION & ".exe", "RAMM_" & $MM_VERSION & ".exe")
_FTP_ProgressUpload($hConnection, @ScriptDir & "\Publish\RAMM_" & $MM_VERSION & ".zip", "RAMM_" & $MM_VERSION & ".zip")

_FTP_FileDelete($hConnection, "RAMM_latest.exe")
_FTP_FileDelete($hConnection, "RAMM_latest.zip")
_FTP_ProgressUpload($hConnection, @ScriptDir & "\Publish\RAMM_" & $MM_VERSION & ".exe", "RAMM_latest.exe")
_FTP_ProgressUpload($hConnection, @ScriptDir & "\Publish\RAMM_" & $MM_VERSION & ".zip", "RAMM_latest.zip")
_FTP_DirSetCurrent($hConnection, "../")

Global $mVersion = Jsmn_Decode(FileRead(@ScriptDir & "\update_ftp.json"))
$mVersion["items"][$MM_VERSION_NUMBER] = MapEmpty()
$mVersion["items"][$MM_VERSION_NUMBER]["type"] = $MM_VERSION_SUBTYPE
$mVersion["items"][$MM_VERSION_NUMBER]["setup"] = "/" & $MM_VERSION_SUBTYPE & "/RAMM_" & $MM_VERSION & ".exe"
$mVersion["items"][$MM_VERSION_NUMBER]["portable"] = "/" & $MM_VERSION_SUBTYPE & "/RAMM_" & $MM_VERSION & ".zip"

FileDelete(@ScriptDir & "\update_ftp.json")
FileWriteLine(@ScriptDir & "\update_ftp.json", Jsmn_Encode($mVersion, $JSMN_PRETTY_PRINT + $JSMN_UNESCAPED_UNICODE + $JSMN_UNESCAPED_SLASHES))

_FTP_FileDelete($hConnection, "ramm.json")
_FTP_ProgressUpload($hConnection, @ScriptDir & "\update_ftp.json", "ramm.json")

_FTP_Close($hConnection)
_FTP_Close($hFTP)

Func OnError()
	Local $iError, $sMessage
	_FTP_GetLastResponseInfo($iError, $sMessage)
	MsgBox(0, $iError, $sMessage)
	Exit
EndFunc
