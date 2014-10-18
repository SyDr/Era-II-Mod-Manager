; Author:         Aliaksei SyDr Karalenka

#include-once
#include "include_fwd.au3"
#include "lng.au3"
#include "settings.au3"

Func Mod_ListLoad()
	Local $aModList_Dir, $aModList_File

	ReDim $MM_LIST_CONTENT[1][$MOD_TOTAL]
	$MM_LIST_CONTENT[0][0] = 0

    $MM_LIST_CONTENT[0][$MOD_IS_ENABLED] = "$MOD_IS_ENABLED"
    $MM_LIST_CONTENT[0][$MOD_IS_EXIST] = "$MOD_IS_EXIST"
    $MM_LIST_CONTENT[0][$MOD_INFO_FILE] = "$MOD_INFO_FILE"
    $MM_LIST_CONTENT[0][$MOD_INFO_PARSED] = "$MOD_INFO_PARSED"
    $MM_LIST_CONTENT[0][$MOD_ITEM_ID] = "$MOD_ITEM_ID"
    $MM_LIST_CONTENT[0][$MOD_PARENT_ID] = "$MOD_PARENT_ID"

	$MM_LIST_FILE_CONTENT = FileRead($MM_LIST_FILE_PATH)
    _FileReadToArray($MM_LIST_FILE_PATH, $aModList_File)
	_ArrayReverse($aModList_File, 1)
	If Not IsArray($aModList_File) Then Dim $aModList_File[1] = [0]

	$aModList_Dir = _FileListToArray($MM_LIST_DIR_PATH, "*", $FLTA_FOLDERS)
	If Not IsArray($aModList_Dir) Then Dim $aModList_Dir[1] = [0]

	ReDim $MM_LIST_CONTENT[1 + $aModList_File[0] + $aModList_Dir[0]][$MOD_TOTAL]

	For $i = 1 To $aModList_File[0]
		_ArraySearch($MM_LIST_CONTENT, $aModList_File[$i], 1, Default, Default, Default, Default, 0)
		If @error Then
			$MM_LIST_CONTENT[0][0] += 1

			$MM_LIST_CONTENT[$MM_LIST_CONTENT[0][0]][$MOD_ID] = $aModList_File[$i]
			$MM_LIST_CONTENT[$MM_LIST_CONTENT[0][0]][$MOD_IS_ENABLED] = True
			$MM_LIST_CONTENT[$MM_LIST_CONTENT[0][0]][$MOD_IS_EXIST] = FileExists($MM_LIST_DIR_PATH & "\" & $aModList_File[$i] & "\") ? True : False
			$MM_LIST_CONTENT[$MM_LIST_CONTENT[0][0]][$MOD_INFO_FILE] = FileRead($MM_LIST_DIR_PATH & "\" & $aModList_File[$i] & "\mod_info.json")
			$MM_LIST_CONTENT[$MM_LIST_CONTENT[0][0]][$MOD_INFO_PARSED] = Jsmn_Decode($MM_LIST_CONTENT[$MM_LIST_CONTENT[0][0]][$MOD_INFO_FILE])
			_ModInfoNormalize($MM_LIST_CONTENT[$MM_LIST_CONTENT[0][0]][$MOD_INFO_PARSED], $MM_LIST_DIR_PATH & "\" & $aModList_File[$i])
		EndIf
	Next

	For $i = 1 To $aModList_Dir[0]
		_ArraySearch($MM_LIST_CONTENT, $aModList_Dir[$i], 1, Default, Default, Default, Default, 0)
		If @error Then
			$MM_LIST_CONTENT[0][0] += 1

			$MM_LIST_CONTENT[$MM_LIST_CONTENT[0][0]][$MOD_ID] = $aModList_Dir[$i]
			$MM_LIST_CONTENT[$MM_LIST_CONTENT[0][0]][$MOD_IS_ENABLED] = False
			$MM_LIST_CONTENT[$MM_LIST_CONTENT[0][0]][$MOD_IS_EXIST] = True
			$MM_LIST_CONTENT[$MM_LIST_CONTENT[0][0]][$MOD_INFO_FILE] = FileRead($MM_LIST_DIR_PATH & "\" & $aModList_Dir[$i] & "\mod_info.json")
			$MM_LIST_CONTENT[$MM_LIST_CONTENT[0][0]][$MOD_INFO_PARSED] = Jsmn_Decode($MM_LIST_CONTENT[$MM_LIST_CONTENT[0][0]][$MOD_INFO_FILE])
			_ModInfoNormalize($MM_LIST_CONTENT[$MM_LIST_CONTENT[0][0]][$MOD_INFO_PARSED], $MM_LIST_DIR_PATH & "\" & $aModList_Dir[$i])
		EndIf
	Next

	ReDim $MM_LIST_CONTENT[1 + $MM_LIST_CONTENT[0][0]][$MOD_TOTAL]
EndFunc   ;==>Mod_ListLoad

Func _ModInfoNormalize(ByRef $Map, Const $sDir)
	If Not IsMap($Map) Then _ModLoadInfoFromINI($Map, $sDir)
	If Not IsMap($Map) Then $Map = MapEmpty()
	If Not MapExists($Map, "platform") Then $Map["platform"] = "era"
	If Not MapExists($Map, "info_version") Then $Map["info_version"] = "1.0"
	If Not MapExists($Map, "version") Then $Map["version"] = MapEmpty()
	If Not MapExists($Map["version"], "mod") Then $Map["version"]["mod"] = "0.0"
	If Not MapExists($Map["version"], "platform") Then $Map["version"]["platform"] = "0.0"
	If Not MapExists($Map["version"], "manager") Then $Map["version"]["manager"] = "0.0"
	If Not MapExists($Map, "caption") Then $Map["caption"] = MapEmpty()
	If Not MapExists($Map, "description") Then $Map["description"] = MapEmpty()
	If Not MapExists($Map["description"], "short") Then $Map["description"]["short"] = MapEmpty()
	If Not MapExists($Map["description"], "full") Then $Map["description"]["full"] = MapEmpty()
	For $i = 1 To $MM_LNG_LIST[0][0]
		If Not MapExists($Map["caption"], $MM_LNG_LIST[$i][$MM_LNG_CODE]) Then $Map["caption"][$MM_LNG_LIST[$i][$MM_LNG_CODE]] = ""
		If Not MapExists($Map["description"]["short"], $MM_LNG_LIST[$i][$MM_LNG_CODE]) Then $Map["description"]["short"][$MM_LNG_LIST[$i][$MM_LNG_CODE]] = ""
		If Not MapExists($Map["description"]["full"], $MM_LNG_LIST[$i][$MM_LNG_CODE])  Then $Map["description"]["full"][$MM_LNG_LIST[$i][$MM_LNG_CODE]] = ""
	Next
	If Not MapExists($Map, "author") Then $Map["author"] = ""
	If Not MapExists($Map, "homepage") Then $Map["homepage"] = ""
	If Not MapExists($Map, "icon") Then $Map["icon"] = MapEmpty()
	If Not MapExists($Map["icon"], "file") Then $Map["icon"]["file"] = ""
	If Not MapExists($Map["icon"], "index") Then $Map["icon"]["index"] = 0
	$Map["icon"]["index"] = Int($Map["icon"]["index"])
	If Not MapExists($Map, "priority") Then $Map["priority"] = 0
	$Map["priority"] = Int($Map["priority"])
	If $Map["priority"] < -100 Then $Map["priority"] = -100
	If $Map["priority"] > 100 Then $Map["priority"] = 100
EndFunc

Func _ModLoadInfoFromINI(ByRef $Map, Const $sDir)
	If Not IsMap($Map) Then $Map = MapEmpty()
	$Map["caption"] = MapEmpty()
	$Map["description"] = MapEmpty()
	$Map["description"]["full"] = MapEmpty()
	For $i = 1 To $MM_LNG_LIST[0][0]
		$Map["caption"][$MM_LNG_LIST[$i][$MM_LNG_CODE]] = IniRead($sDir & "\mod_info.ini", "info", "Caption." & $MM_LNG_LIST[$i][$MM_LNG_CODE], IniRead($sDir & "\mod_info.ini", "info", "Caption", ""))
		$Map["description"]["full"][$MM_LNG_LIST[$i][$MM_LNG_CODE]] = IniRead($sDir & "\mod_info.ini", "info", "Description File." & $MM_LNG_LIST[$i][$MM_LNG_CODE], IniRead($sDir & "\mod_info.ini", "info", "Description File", ""))
	Next
	$Map["author"] = IniRead($sDir & "\mod_info.ini", "info", "Author", "")
	$Map["homepage"] = IniRead($sDir & "\mod_info.ini", "info", "Homepage", "")
	$Map["icon"] = MapEmpty()
	$Map["icon"]["file"] = IniRead($sDir & "\mod_info.ini", "info", "Icon File", "")
	$Map["icon"]["index"] = IniRead($sDir & "\mod_info.ini", "info", "Icon Index", "")
	$Map["version"] = MapEmpty()
	$Map["version"]["mod"] = IniRead($sDir & "\mod_info.ini", "info", "Version", "0.0")
	$Map["priority"] = IniRead($sDir & "\mod_info.ini", "info", "Priority", 0)
EndFunc

Func Mod_Get(Const $sPath, Const $iModIndex = -1)
	Local $vReturn = ""
	Local $aParts = StringSplit($sPath, "\")

	If $sPath = "id" Then
		$vReturn = $MM_LIST_CONTENT[$iModIndex][$MOD_ID]
	ElseIf $sPath = "caption" Then
		$vReturn = ($MM_LIST_CONTENT[$iModIndex][$MOD_INFO_PARSED])["caption"][$MM_LANGUAGE_CODE]
		If $vReturn = "" Then $vReturn = ($MM_LIST_CONTENT[$iModIndex][$MOD_INFO_PARSED])["caption"]["en_US"]
		If $vReturn = "" Then $vReturn = $MM_LIST_CONTENT[$iModIndex][$MOD_ID]
	ElseIf $aParts[1] = "description" Then
		$vReturn = ($MM_LIST_CONTENT[$iModIndex][$MOD_INFO_PARSED])["description"][$aParts[2]][$MM_LANGUAGE_CODE]
		If $vReturn = "" Then $vReturn = ($MM_LIST_CONTENT[$iModIndex][$MOD_INFO_PARSED])["description"][$aParts[2]]["en_US"]
		If $vReturn = "" Then $vReturn = Lng_Get("info_group.no_info")
	Else
		Switch $aParts[0]
			Case 1
				$vReturn = ($MM_LIST_CONTENT[$iModIndex][$MOD_INFO_PARSED])[$aParts[1]]
			Case 2
				$vReturn = ($MM_LIST_CONTENT[$iModIndex][$MOD_INFO_PARSED])[$aParts[1]][$aParts[2]]
			Case 3
				$vReturn = ($MM_LIST_CONTENT[$iModIndex][$MOD_INFO_PARSED])[$aParts[1]][$aParts[2]][$aParts[3]]
		EndSwitch
	EndIf

	Return $vReturn
EndFunc

Func Mod_IsCompatible(Const $iModIndex1, Const $iModIndex2)
	Return $MM_LIST_COMPATIBILITY[Mod_Get("id", $iModIndex1)][Mod_Get("id", $iModIndex2)]
EndFunc

Func Mod_ListIsActual()
	Local $bActual = True
	Local $sListFile = $MM_LIST_FILE_CONTENT
	Local $aModList = $MM_LIST_CONTENT

	Mod_ListLoad()
	If $aModList[0][0] <> $MM_LIST_CONTENT[0][0] Then
		$bActual = False
	Else
		For $iCount = 1 To $aModList[0][0]
			If $aModList[$iCount][$MOD_ID] <> $MM_LIST_CONTENT[$iCount][$MOD_ID] Then
				$bActual = False
				ExitLoop
			EndIf
		Next
	EndIf

	$MM_LIST_FILE_CONTENT = $sListFile
	$MM_LIST_CONTENT = $aModList
	Return $bActual
EndFunc

Func Mod_ReEnable($sModID)
	Local $iModIndex = Mod_GetIndexByID($sModID)
	If $iModIndex <> -1 Then
		Mod_Disable($iModIndex)
		Mod_ListLoad()
	EndIf

	$iModIndex = Mod_GetIndexByID($sModID)
	If $iModIndex <> -1 Then
		Mod_Enable($iModIndex)
	Else
		FileWriteLine($MM_LIST_FILE_PATH, $sModID)
	EndIf
EndFunc   ;==>Mod_ReEnable

Func Mod_CompatibilityMapLoad()
	Local $sModID1, $sModID2

	For $iCount = 1 To $MM_LIST_CONTENT[0][0]
		$sModID1 = $MM_LIST_CONTENT[$iCount][$MOD_ID]
		If IsKeyword($MM_LIST_COMPATIBILITY[$sModID1]) = $KEYWORD_NULL Then $MM_LIST_COMPATIBILITY[$sModID1] = MapEmpty()

		For $jCount = 1 To $MM_LIST_CONTENT[0][0]
			$sModID2 = $MM_LIST_CONTENT[$jCount][$MOD_ID]
            If IsKeyword($MM_LIST_COMPATIBILITY[$sModID2]) = $KEYWORD_NULL Then $MM_LIST_COMPATIBILITY[$sModID2] = MapEmpty()

			If Not $MM_LIST_CONTENT[$iCount][$MOD_IS_ENABLED] Or Not $MM_LIST_CONTENT[$jCount][$MOD_IS_ENABLED] Then
				$MM_LIST_COMPATIBILITY[$sModID1][$sModID2] = True
			Else
				Local $sType1 = IniRead($MM_LIST_DIR_PATH & "\" & $MM_LIST_CONTENT[$iCount][0] & "\mod_info.ini", "info", "Compatibility Class", "Default")
				Local $sType2 = IniRead($MM_LIST_DIR_PATH & "\" & $MM_LIST_CONTENT[$jCount][0] & "\mod_info.ini", "info", "Compatibility Class", "Default")
				Local $i1To2 = IniRead($MM_LIST_DIR_PATH & "\" & $MM_LIST_CONTENT[$iCount][0] & "\mod_info.ini", "Compatibility", $MM_LIST_CONTENT[$jCount][0], 0)
				Local $i2To1 = IniRead($MM_LIST_DIR_PATH & "\" & $MM_LIST_CONTENT[$jCount][0] & "\mod_info.ini", "Compatibility", $MM_LIST_CONTENT[$iCount][0], 0)
				If $i1To2 == 1 Then
					$MM_LIST_COMPATIBILITY[$sModID1][$sModID2] = True
				ElseIf $i1To2 == -1 Then
					$MM_LIST_COMPATIBILITY[$sModID1][$sModID2] = False
				ElseIf $i2To1 == 1 Then
					$MM_LIST_COMPATIBILITY[$sModID1][$sModID2] = True
				ElseIf $i2To1 == -1 Then
					$MM_LIST_COMPATIBILITY[$sModID1][$sModID2] = False
				ElseIf ($sType1 = "None" And ($sType2 = "None" Or $sType2 = "Default")) Or ($sType2 = "None" And ($sType1 = "None" Or $sType1 = "Default")) Then
					$MM_LIST_COMPATIBILITY[$sModID1][$sModID2] = False
				Else
					$MM_LIST_COMPATIBILITY[$sModID1][$sModID2] = True
				EndIf
			EndIf
		Next
	Next
EndFunc   ;==>Mod_CompatibilityMapLoad

Func Mod_ListSave()
	If Not FileDelete($MM_LIST_FILE_PATH) And FileExists($MM_LIST_FILE_PATH) Then
		MsgBox($MB_SYSTEMMODAL, "", "Press CTRL+C to copy this message" & @CRLF & @CRLF & _
				StringFormat(Lng_Get("list.txt"), StringFormat("FileDelete(%s)", $MM_LIST_FILE_PATH)))
		Return False
	EndIf
	Local $sWrite = ""
	For $iCount = $MM_LIST_CONTENT[0][0] To 1 Step -1
		If $MM_LIST_CONTENT[$iCount][$MOD_IS_ENABLED] Then
			$sWrite &= $MM_LIST_CONTENT[$iCount][0] & @CRLF
		EndIf
	Next
	If Not FileWrite($MM_LIST_FILE_PATH, $sWrite) Then
		MsgBox($MB_SYSTEMMODAL, "", "Press CTRL+C to copy this message" & @CRLF & @CRLF & _
				StringFormat(Lng_Get("list.txt"), StringFormat("FileWrite(%s, %s", $MM_LIST_FILE_PATH, $sWrite)))
		Return False
	EndIf
EndFunc   ;==>Mod_ListSave

Func Mod_ListSwap($iModIndex1, $iModIndex2, $sUpdate = True)
	Local $vTemp

	For $jCount = 0 To $MOD_TOTAL - 1
		If $jCount = $MOD_ITEM_ID Or $jCount = $MOD_PARENT_ID Then ContinueLoop
		$vTemp = $MM_LIST_CONTENT[$iModIndex1][$jCount]
		$MM_LIST_CONTENT[$iModIndex1][$jCount] = $MM_LIST_CONTENT[$iModIndex2][$jCount]
		$MM_LIST_CONTENT[$iModIndex2][$jCount] = $vTemp
	Next

	If $sUpdate Then Mod_ListSave()
EndFunc   ;==>Mod_ListSwap

Func Mod_Disable($iModIndex)
	If Not $MM_LIST_CONTENT[$iModIndex][$MOD_IS_ENABLED] Then Return
	$MM_LIST_CONTENT[$iModIndex][$MOD_IS_ENABLED] = False

	Mod_ListSave()
EndFunc   ;==>Mod_Disable

Func Mod_Delete($iModIndex)
	FileRecycle($MM_LIST_DIR_PATH & "\" & $MM_LIST_CONTENT[$iModIndex][0])
	Mod_Disable($iModIndex)
EndFunc   ;==>Mod_Delete

Func Mod_Enable($iModIndex)
	If $MM_LIST_CONTENT[$iModIndex][$MOD_IS_ENABLED] Then Return
	$MM_LIST_CONTENT[$iModIndex][$MOD_IS_ENABLED] = True

	For $iIndex = $iModIndex To 2 Step -1
		If $MM_LIST_CONTENT[$iIndex - 1][$MOD_IS_ENABLED] And Mod_Get("priority", $iIndex - 1) > Mod_Get("priority", $iIndex) Then ExitLoop
		Mod_ListSwap($iIndex, $iIndex - 1, False)
	Next

	Mod_ListSave()
EndFunc   ;==>Mod_Enable

Func Mod_ModIsInstalled($sModName)
	For $iCount = 1 To $MM_LIST_CONTENT[0][0]
		If $MM_LIST_CONTENT[$iCount][$MOD_ID] = $sModName Then Return $iCount
	Next
EndFunc   ;==>Mod_ModIsInstalled

Func Mod_InfoLoad(Const $sModName, Const $sFile)
	Local $sReturn = FileRead($MM_LIST_DIR_PATH & "\" & $sModName & "\" & $sFile)
	If @error Or $sReturn = "" Then $sReturn = Lng_Get("info_group.no_info")
	Return $sReturn
EndFunc   ;==>Mod_InfoLoad

Func Mod_GetVersion($sModName)
	Return IniRead($MM_LIST_DIR_PATH & "\" & $sModName & "\mod_info.ini", "info", "Version", "0.0")
EndFunc   ;==>Mod_GetVersion

Func Mod_GetIndexByID($sModID)
	For $iCount = 1 To $MM_LIST_CONTENT[0][0]
		If $MM_LIST_CONTENT[$iCount][0] = $sModID Then Return $iCount
	Next

	Return -1
EndFunc   ;==>Mod_GetIndexByID
