; Author:         Aliaksei SyDr Karalenka

#AutoIt3Wrapper_Version=Beta
#include "include_fwd.au3"
#include "utils.au3"

#include <FTPEx.au3>

Global $hFTP = _FTP_Open('wakeofgods.org ftp')
Global $hConnection = _FTP_Connect($hFTP, "wakeofgods.org", "mm@wakeofgods.org", FileRead("ftp_pass.txt"), True)

_FTP_DirSetCurrent($hConnection, "/" & $MM_VERSION_SUBTYPE)
_FTP_FileDelete($hConnection, "MM_" & $MM_VERSION & ".zip")
_FTP_ProgressUpload($hConnection, @ScriptDir & "\Publish\MM_" & $MM_VERSION & ".zip", "MM_" & $MM_VERSION & ".zip")
_FTP_DirSetCurrent($hConnection, "../")

If $MM_VERSION_SUBTYPE = "release" Then
	_FTP_FileDelete($hConnection, "MM_Latest.zip")
	_FTP_ProgressUpload($hConnection, @ScriptDir & "\Publish\MM_" & $MM_VERSION & ".zip", "MM_Latest.zip")
EndIf

Global $mVersion = Jsmn_Decode(FileRead(@ScriptDir & "\update_ftp.json"))
$mVersion[$MM_VERSION_SUBTYPE]["version"] = $MM_VERSION_NUMBER
$mVersion[$MM_VERSION_SUBTYPE]["file"] = "/" & $MM_VERSION_SUBTYPE & "/MM_" & $MM_VERSION & ".zip"

FileDelete(@ScriptDir & "\update_ftp.json")
FileWriteLine(@ScriptDir & "\update_ftp.json", Jsmn_Encode($mVersion, $JSMN_PRETTY_PRINT + $JSMN_UNESCAPED_UNICODE + $JSMN_UNESCAPED_SLASHES))

_FTP_FileDelete($hConnection, "mm.json")
_FTP_ProgressUpload($hConnection, @ScriptDir & "\update_ftp.json", "mm.json")

_FTP_Close($hConnection)
_FTP_Close($hFTP)

Func OnError()
	Local $iError, $sMessage
	_FTP_GetLastResponseInfo($iError, $sMessage)
	MsgBox(0, $iError, $sMessage)
	Exit
EndFunc
