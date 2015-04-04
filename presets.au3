;Author:			Aliaksei SyDr Karalenka

#AutoIt3Wrapper_Version=Beta
#include-once
#include "include_fwd.au3"

#include "mods.au3"
#include "utils.au3"

Global $MM_SCN_LIST[1] ; scenario list
Global $MM_SCN_SPECIAL[1][1] ; special items

Func Scn_ListLoad()
	Local $aScnList = _FileListToArray($MM_SCN_DIRECTORY, "*.json", $FLTA_FILES)
	If @error Then
		$aScnList = ArrayEmpty()
		$aScnList[0] = 0
	EndIf

	For $i = 1 To $aScnList[0]
		$aScnList[$i] = StringTrimRight($aScnList[$i], 5)
	Next

	$MM_SCN_LIST = $aScnList
EndFunc

Func Scn_Exist(Const $sName)
	_ArraySearch($MM_SCN_LIST, $sName, 1)
	Return Not @error
EndFunc

Func Scn_Delete(Const $iItemIndex)
	If $iItemIndex < 1 Or $iItemIndex > $MM_SCN_LIST[0] Then Return
	FileRecycle($MM_SCN_DIRECTORY & "\" & $MM_SCN_LIST[$iItemIndex] & ".json")
EndFunc

Func Scn_Apply(Const ByRef $mData)
	Local $aData = $mData["list"]
	Mod_ListLoadFromMemory($aData)
EndFunc

Func Scn_Load(Const $iItemIndex)
	If $iItemIndex >= 1 And $iItemIndex <= $MM_SCN_LIST[0] Then
		Return Scn_LoadData(FileRead($MM_SCN_DIRECTORY & "\" & $MM_SCN_LIST[$iItemIndex] & ".json"))
	Else
		Return Scn_LoadData("")
	EndIf
EndFunc

Func Scn_LoadData(Const $sData)
	Local $mScenario = Jsmn_Decode($sData)
	__Scn_Validate($mScenario)
	Return $mScenario
EndFunc

Func Scn_GetCurrentState(Const $mOptions)
	Local $mData
	__Scn_Validate($mData)

	$mData["name"] = $mOptions["name"]
	$mData["mm_version"] = $MM_VERSION_NUMBER
	If $mOptions["exe"] Then $mData["exe"] = $MM_GAME_EXE
	If $mOptions["wog_settings"] Then $mData["wog_settings"] = Scn_LoadWogSettings()
	$mData["list"] = Mod_ListGetAsArray()

	Return $mData
EndFunc

Func Scn_Save(Const $mOptions)
	Const $sFileName = $MM_SCN_DIRECTORY & "\" & $mOptions["name"] & ".json"
	FileDelete($sFileName)
	FileWrite($sFileName, Jsmn_Encode(Scn_GetCurrentState($mOptions), $JSMN_PRETTY_PRINT + $JSMN_UNESCAPED_UNICODE))
EndFunc

Func __Scn_Validate(ByRef $mData)
	If Not IsMap($mData) Then $mData = MapEmpty()
	If Not MapExists($mData, "version") Or Not IsString($mData["version"]) Then $mData["mm_version"] = $MM_VERSION_NUMBER
	If Not MapExists($mData, "name") Or Not IsString($mData["name"]) Then $mData["name"] = ""
	If Not MapExists($mData, "exe") Or Not IsString($mData["exe"]) Then $mData["exe"] = ""
	If Not MapExists($mData, "wog_settings") Or Not IsString($mData["wog_settings"]) Then $mData["wog_settings"] = ""
	If Not MapExists($mData, "list") Or Not IsArray($mData["list"]) Then $mData["list"] = ArrayEmpty()
	Local $aItems = $mData["list"]
	For $i = 0 To UBound($aItems) - 1
		If Not IsString($aItems[$i]) Then $aItems[$i] = ""
	Next
	$mData["list"] = $aItems
EndFunc

Func Scn_ApplyWogSettings(Const $sString)
	Local Const $sFileName = "MM_PresetSettings.dat"
	Local $aData = Scn_StringToWS($sString)
	Local $aSection[3][2] = [[2, ""],["Options_File_Path", ".\"],["Options_File_Name", $sFileName]]
	IniWriteSection($MM_GAME_DIR & "\wog.ini", "WoGification", $aSection)

	Local $hFile = FileOpen($MM_GAME_DIR & "\" & $sFileName, $FO_BINARY + $FO_OVERWRITE)
	For $i = 0 To UBound($aData) - 1
		FileWrite($hFile, $aData[$i])
	Next

	FileClose($hFile)
EndFunc

Func Scn_LoadWogSettings()
	Local $sFilePath = _PathFull(IniRead($MM_GAME_DIR & "\wog.ini", "WoGification", "Options_File_Path", ".\"), $MM_GAME_DIR) & _
		IniRead($MM_GAME_DIR & "\wog.ini", "WoGification", "Options_File_Name", "MM_PresetSettings.dat")

	Return Scn_LoadWogSettingsFromFile($sFilePath)
EndFunc

Func Scn_LoadWogSettingsFromFile(Const $sFilePath)
	Local Const $MAX = 1000

	Local $aData[$MAX], $bData
	Local $hFile = FileOpen($sFilePath, $FO_BINARY)
	For $i = 0 To $MAX - 1
		$bData = FileRead($hFile, 4)
		If @error Then
			$aData[$i] = 0
		Else
			$aData[$i] = Int($bData)
		EndIf
	Next

	Return Scn_WSToString($aData)
EndFunc

Func Scn_WSToString(Const ByRef $aData)
	Local $sAnswer

	Local $iCurrentItem = "", $iCurrentCount = 0, $iItem
	For $i = 0 To UBound($aData)
		$iItem = $i <> UBound($aData) ? $aData[$i] : -1

		If $iItem = $iCurrentItem Then
			$iCurrentCount += 1
		Else
			If Not IsString($iCurrentItem) Then
				If $iCurrentItem = 0 Then
					$sAnswer &= $iCurrentCount
				ElseIf $iCurrentItem = 1 And $iCurrentCount > 1 Then
					$sAnswer &= ":" & $iCurrentCount
				ElseIf $iCurrentItem > 1 Then
					$sAnswer &= $iCurrentItem & ":" & ($iCurrentCount > 1 ? $iCurrentCount : "")
				EndIf

				$sAnswer &= ";"
			EndIf
			$iCurrentItem = $iItem
			$iCurrentCount = 1
		EndIf
	Next

	Return $sAnswer
EndFunc

Func Scn_StringToWS(Const ByRef $sData)
	Local Const $MAX = 1000
	Local $aReturn[$MAX], $iCurrent = 0, $aItem
	Local $aTemp = StringSplit($sData, ";")

	For $i = 1 To $aTemp[0] - 1
		$aItem = StringSplit($aTemp[$i], ":")
		If StringLen($aTemp[$i]) = 0 Then
			$aReturn[$iCurrent] = 1
			$iCurrent += 1 ; "" empty place -> place 1
			If $iCurrent >= $MAX Then ExitLoop
		ElseIf $aItem[0] = 1 Then
			For $j = 1 To Int($aItem[1])
				$aReturn[$iCurrent] = 0 ; "y" -> "0:y" format -> place y of 0
				$iCurrent += 1
				If $iCurrent >= $MAX Then ExitLoop
			Next
		ElseIf $aItem[0] = 2 And StringLen($aItem[1]) = 0 Then
			For $j = 1 To Int($aItem[2])
				$aReturn[$iCurrent] = 1 ; ":y" -> "1:y" format -> place y of 1
				$iCurrent += 1
				If $iCurrent >= $MAX Then ExitLoop
			Next
		ElseIf $aItem[0] = 2 And StringLen($aItem[2]) = 0 Then
			$aReturn[$iCurrent] = Int($aItem[1]) ; "x:" -> "x:1" format -> place one x
			$iCurrent += 1
			If $iCurrent >= $MAX Then ExitLoop
		ElseIf $aItem[0] = 2 Then
			For $j = 1 To Int($aItem[2])
				$aReturn[$iCurrent] = Int($aItem[1]) ; ":y" -> "x:y" format -> place y of x
				$iCurrent += 1
				If $iCurrent >= $MAX Then ExitLoop
			Next
		Else
			ExitLoop ; wrong format or only 0 remains
		EndIf
	Next

	For $i = 0 To $MAX - 1
		If Not $aReturn[$i] Then $aReturn[$i] = 0
	Next

	Return $aReturn
EndFunc
