#include <WinApi.au3>

Func SFX_FileOpen(Const $sPath)
	Local $aResult = DllCall("kernel32.dll", "ptr", "BeginUpdateResourceW", "wstr", $sPath, "int", 0)
	If Not @error And IsArray($aResult) Then Return $aResult[0]
EndFunc

Func SFX_FileClose(Const $hFile)
	Local $aResult = DllCall("kernel32.dll", "int", "EndUpdateResourceW", "ptr", $hFile, "int", 0)
	If Not @error And IsArray($aResult) Then Return $aResult[0]
EndFunc

Func SFX_UpdateIcon(Const $hFile, Const $sIconPath)
	Local $hIcon = _WinAPI_CreateFile($sIconPath, 2, 2)
	If Not $hIcon Then Return SetError(1, 0, 1)

	Local $tSize = FileGetSize($sIconPath), $iRead
	Local $tI_Input_Header = DllStructCreate("word Res;word Type;word ImageCount;byte rest[" & $tSize - 6 & "]") ; Create the buffer
	_WinAPI_ReadFile($hIcon, DllStructGetPtr($tI_Input_Header), $tSize, $iRead, 0)
	If $hIcon Then _WinAPI_CloseHandle($hIcon)

	Local $iIconType = DllStructGetData($tI_Input_Header, "Type")
	Local $iIconCount = DllStructGetData($tI_Input_Header, "ImageCount")

	Local $tB_IconGroupHeader = DllStructCreate("align 2;word res;word type;word ImageCount;byte rest[" & $iIconCount * 14 & "]") ; Create the buffer.
	Local $pB_IconGroupHeader = DllStructGetPtr($tB_IconGroupHeader)
	DllStructSetData($tB_IconGroupHeader, "Res", 0)
	DllStructSetData($tB_IconGroupHeader, "Type", $iIconType)
	DllStructSetData($tB_IconGroupHeader, "ImageCount", $iIconCount)

	For $x = 1 To $iIconCount
		Local $pB_Input_IconHeader = DllStructGetPtr($tI_Input_Header, "rest") + ($x - 1) * 16
		Local $tB_Input_IconHeader = DllStructCreate("byte Width;byte Height;byte Colors;byte res;word Planes;word BitsPerPixel;dword ImageSize;dword ImageOffset", $pB_Input_IconHeader) ; Create the buffer.
		Local $IconWidth = DllStructGetData($tB_Input_IconHeader, "Width")
		Local $IconHeight = DllStructGetData($tB_Input_IconHeader, "Height")
		Local $IconColors = DllStructGetData($tB_Input_IconHeader, "Colors")
		Local $IconPlanes = DllStructGetData($tB_Input_IconHeader, "Planes")
		Local $IconBitsPerPixel = DllStructGetData($tB_Input_IconHeader, "BitsPerPixel")
		Local $IconImageSize = DllStructGetData($tB_Input_IconHeader, "ImageSize")
		Local $IconImageOffset = DllStructGetData($tB_Input_IconHeader, "ImageOffset")
		$pB_IconGroupHeader = DllStructGetPtr($tB_IconGroupHeader, "rest") + ($x - 1) * 14
		Local $tB_GroupIcon = DllStructCreate("align 2;byte Width;byte Height;byte Colors;byte res;word Planes;word BitsPerPixel;dword ImageSize;word ResourceID", $pB_IconGroupHeader) ; Create the buffer.
		DllStructSetData($tB_GroupIcon, "Width", $IconWidth)
		DllStructSetData($tB_GroupIcon, "Height", $IconHeight)
		DllStructSetData($tB_GroupIcon, "Colors", $IconColors)
		DllStructSetData($tB_GroupIcon, "Res", 0)
		DllStructSetData($tB_GroupIcon, "Planes", $IconPlanes)
		DllStructSetData($tB_GroupIcon, "BitsPerPixel", $IconBitsPerPixel)
		DllStructSetData($tB_GroupIcon, "ImageSize", $IconImageSize)
		DllStructSetData($tB_GroupIcon, "ResourceID", 1)
		Local $pB_IconData = DllStructGetPtr($tI_Input_Header) + $IconImageOffset
		DllCall("kernel32.dll", "int", "UpdateResourceW", "ptr", $hFile, "long", 3, "long", 1, "ushort", 1033, "ptr", $pB_IconData, "dword", $IconImageSize)
	Next

	$pB_IconGroupHeader = DllStructGetPtr($tB_IconGroupHeader)
	DllCall("kernel32.dll", "int", "UpdateResourceW", "ptr", $hFile, "long", 14, "long", 1, "ushort", 1033, "ptr", $pB_IconGroupHeader, "dword", DllStructGetSize($tB_IconGroupHeader))
EndFunc

Func SFX_UpdateModDirName(Const $hFile, $sDirectoryName)
	$sDirectoryName = '"' & $sDirectoryName & '"'
	Local $sStruct = StringFormat("word;wchar[%i];word;word;word;word;word;word;word;word;word;word;word;word;word;word;word;", StringLen($sDirectoryName))
	Local $oStruct = DllStructCreate($sStruct)
	DllStructSetData($oStruct, 1, StringLen($sDirectoryName))
	DllStructSetData($oStruct, 2, $sDirectoryName)
	For $i = 3 To 3 + 14
		DllStructSetData($oStruct, $i, 0)
	Next

	Local $tSize = DllStructGetSize($oStruct)
	Local $pBuffer = DllStructGetPtr($oStruct)

	DllCall("kernel32.dll", "int", "UpdateResourceW", "ptr", $hFile, "long", 6, "long", 251, "ushort", 1033, "ptr", $pBuffer, "dword", $tSize)
EndFunc
