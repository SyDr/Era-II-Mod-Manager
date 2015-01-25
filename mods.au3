; Author:         Aliaksei SyDr Karalenka

#AutoIt3Wrapper_Version=Beta
#include-once
#include "include_fwd.au3"
#include "lng.au3"
#include "settings.au3"
#include "utils.au3"

Global $MM_SELECTED_MOD = -1

Func Mod_ListLoad()
	_TraceStart("ModList: Load")
	Local $aModList_Dir, $aModList_File, $iFirstDisabled = -1

	ReDim $MM_LIST_CONTENT[1][$MOD_TOTAL]
	$MM_LIST_CONTENT[0][0] = 0
	$MM_LIST_MAP = MapEmpty()

    $MM_LIST_CONTENT[0][$MOD_IS_ENABLED] = "$MOD_IS_ENABLED"
    $MM_LIST_CONTENT[0][$MOD_IS_EXIST] = "$MOD_IS_EXIST"
    $MM_LIST_CONTENT[0][$MOD_CAPTION] = "$MOD_CAPTION"
    $MM_LIST_CONTENT[0][$MOD_ITEM_ID] = "$MOD_ITEM_ID"
    $MM_LIST_CONTENT[0][$MOD_PARENT_ID] = "$MOD_PARENT_ID"
    $MM_LIST_CONTENT[0][$MOD_DESCRIPTION_CACHE] = "$MOD_DESCRIPTION_CACHE"
    $MM_LIST_CONTENT[0][$MOD_PLUGIN_CACHE] = "$MOD_PLUGIN_CACHE"

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
			__Mod_LoadInfo($MM_LIST_CONTENT[0][0], $aModList_File[$i], True)
		EndIf
	Next

	For $i = 1 To $aModList_Dir[0]
		_ArraySearch($MM_LIST_CONTENT, $aModList_Dir[$i], 1, Default, Default, Default, Default, 0)
		If @error Then
			$MM_LIST_CONTENT[0][0] += 1
			__Mod_LoadInfo($MM_LIST_CONTENT[0][0], $aModList_Dir[$i], False)
			If $iFirstDisabled < 1 Then $iFirstDisabled = $MM_LIST_CONTENT[0][0]
		EndIf
	Next

	_TracePoint("ModList: Sort")
	ReDim $MM_LIST_CONTENT[1 + $MM_LIST_CONTENT[0][0]][$MOD_TOTAL]
	If $iFirstDisabled > 0 Then _ArraySort($MM_LIST_CONTENT, Default, $iFirstDisabled, Default, $MOD_CAPTION)
	_TraceEnd()
EndFunc   ;==>Mod_ListLoad

Func __Mod_LoadInfo(Const $iIndex, Const ByRef $sId, Const $bIsEnabled)
	$MM_LIST_CONTENT[$iIndex][$MOD_ID] = $sId
	$MM_LIST_CONTENT[$iIndex][$MOD_IS_ENABLED] = $bIsEnabled
	$MM_LIST_CONTENT[$iIndex][$MOD_IS_EXIST] = FileExists($MM_LIST_DIR_PATH & "\" & $sId & "\") ? True : False
	$MM_LIST_MAP[$sId] = Jsmn_Decode(FileRead($MM_LIST_DIR_PATH & "\" & $sId & "\mod.json"))
	__Mod_Validate($MM_LIST_MAP[$sId], $MM_LIST_DIR_PATH & "\" & $sId)
	$MM_LIST_CONTENT[$iIndex][$MOD_CAPTION] = Mod_Get("caption", $iIndex)
EndFunc

Func __Mod_Validate(ByRef $Map, Const $sDir)
	If Not IsMap($Map) Then __Mod_LoadInfoFromINI($Map, $sDir)
	If Not IsMap($Map) Then $Map = MapEmpty()

	Local $aItems
	If Not MapExists($Map, "platform") Or Not IsString($Map["platform"]) Then $Map["platform"] = "era"
	If Not MapExists($Map, "info_version") Or Not IsString($Map["info_version"]) Then $Map["info_version"] = "1.0"
	If Not MapExists($Map, "mod_version") Or Not IsString($Map["mod_version"]) Then $Map["mod_version"] = "0.0"

	If Not MapExists($Map, "caption") Or Not IsMap($Map["caption"]) Then $Map["caption"] = MapEmpty()
	If Not MapExists($Map, "description") Or Not IsMap($Map["description"]) Then $Map["description"] = MapEmpty()
	If Not MapExists($Map["description"], "short") Or Not IsMap($Map["description"]["short"]) Then $Map["description"]["short"] = MapEmpty()
	If Not MapExists($Map["description"], "full") Or Not IsMap($Map["description"]["full"]) Then $Map["description"]["full"] = MapEmpty()
	For $i = 1 To $MM_LNG_LIST[0][0]
		If Not MapExists($Map["caption"], $MM_LNG_LIST[$i][$MM_LNG_CODE]) Or Not IsString($Map["caption"][$MM_LNG_LIST[$i][$MM_LNG_CODE]]) Then $Map["caption"][$MM_LNG_LIST[$i][$MM_LNG_CODE]] = ""
		If Not MapExists($Map["description"]["short"], $MM_LNG_LIST[$i][$MM_LNG_CODE]) Or Not IsString($Map["description"]["short"][$MM_LNG_LIST[$i][$MM_LNG_CODE]]) Then $Map["description"]["short"][$MM_LNG_LIST[$i][$MM_LNG_CODE]] = ""
		If Not MapExists($Map["description"]["full"], $MM_LNG_LIST[$i][$MM_LNG_CODE]) Or Not IsString($Map["description"]["full"][$MM_LNG_LIST[$i][$MM_LNG_CODE]]) Then $Map["description"]["full"][$MM_LNG_LIST[$i][$MM_LNG_CODE]] = ""
	Next

	If Not MapExists($Map, "author") Or Not IsString($Map["author"]) Then $Map["author"] = ""
	If Not MapExists($Map, "homepage") Or Not IsString($Map["homepage"])  Then $Map["homepage"] = ""
	If Not MapExists($Map, "icon") Or Not IsMap($Map["icon"]) Then $Map["icon"] = MapEmpty()
	If Not MapExists($Map["icon"], "file") Or Not IsString($Map["icon"]["file"]) Then $Map["icon"]["file"] = ""
	If Not MapExists($Map["icon"], "index") Then $Map["icon"]["index"] = 0
	$Map["icon"]["index"] = Int($Map["icon"]["index"])
	If Not MapExists($Map, "priority") Then $Map["priority"] = 0
	$Map["priority"] = Int($Map["priority"])
	If $Map["priority"] < -100 Then $Map["priority"] = -100
	If $Map["priority"] > 100 Then $Map["priority"] = 100

	If Not MapExists($Map, "compatibility") Or Not IsMap($Map["compatibility"]) Then $Map["compatibility"] = MapEmpty()
	If Not MapExists($Map["compatibility"], "class") Or Not IsString($Map["compatibility"]["class"]) Then $Map["compatibility"]["class"] = "default"
	$Map["compatibility"]["class"] = StringLower($Map["compatibility"]["class"])
	If $Map["compatibility"]["class"] <> "default" And $Map["compatibility"]["class"] <> "all" And $Map["compatibility"]["class"] <> "none" Then $Map["compatibility"]["class"] = "default"

	If Not MapExists($Map["compatibility"], "entries") Then $Map["compatibility"]["entries"] = MapEmpty()
	$aItems = MapKeys($Map["compatibility"]["entries"])
	For $i = 0 To UBound($aItems) - 1
		If Not IsBool($Map["compatibility"]["entries"][$aItems[$i]]) Then $Map["compatibility"]["entries"][$aItems[$i]] = $Map["compatibility"]["entries"][$aItems[$i]] ? True : False
	Next

	If Not MapExists($Map, "plugins") Then $Map["plugins"] = MapEmpty()
	$aItems = MapKeys($Map["plugins"])
	For $i = 0 To UBound($aItems) - 1
		If Not IsMap($Map["plugins"][$aItems[$i]]) Then $Map["plugins"][$aItems[$i]] = MapEmpty()
		If Not MapExists($Map["plugins"][$aItems[$i]], "default") Or Not IsBool($Map["plugins"][$aItems[$i]]["default"]) Then $Map["plugins"][$aItems[$i]]["default"] = True
		For $i = 1 To $MM_LNG_LIST[0][0]
			If Not MapExists($Map["plugins"][$aItems[$i]]["caption"], $MM_LNG_LIST[$i][$MM_LNG_CODE]) Or Not IsString($Map["plugins"][$aItems[$i]]["caption"][$MM_LNG_LIST[$i][$MM_LNG_CODE]]) Then $Map["plugins"][$aItems[$i]]["caption"][$MM_LNG_LIST[$i][$MM_LNG_CODE]] = ""
			If Not MapExists($Map["plugins"][$aItems[$i]]["description"], $MM_LNG_LIST[$i][$MM_LNG_CODE]) Or Not IsString($Map["plugins"][$aItems[$i]]["description"][$MM_LNG_LIST[$i][$MM_LNG_CODE]]) Then $Map["plugins"][$aItems[$i]]["description"][$MM_LNG_LIST[$i][$MM_LNG_CODE]] = ""
		Next
	Next
	If Not MapExists($Map, "category") Or Not IsString($Map["category"]) Then $Map["category"] = ""
EndFunc

Func __Mod_LoadInfoFromINI(ByRef $Map, Const $sDir)
	If Not IsMap($Map) Then $Map = MapEmpty()
	$Map["caption"] = MapEmpty()
	$Map["description"] = MapEmpty()
	$Map["description"]["full"] = MapEmpty()
	For $i = 1 To $MM_LNG_LIST[0][0]
		$Map["caption"][$MM_LNG_LIST[$i][$MM_LNG_CODE]] = IniRead($sDir & "\mod_info.ini", "info", "Caption." & $MM_LNG_LIST[$i][$MM_LNG_CODE], "")
		$Map["description"]["full"][$MM_LNG_LIST[$i][$MM_LNG_CODE]] = IniRead($sDir & "\mod_info.ini", "info", "Description File." & $MM_LNG_LIST[$i][$MM_LNG_CODE], "")
	Next
	$Map["caption"]["en_US"] = IniRead($sDir & "\mod_info.ini", "info", "Caption", "")
	$Map["description"]["full"]["en_US"] = IniRead($sDir & "\mod_info.ini", "info", "Description File", "")
	$Map["author"] = IniRead($sDir & "\mod_info.ini", "info", "Author", "")
	$Map["homepage"] = IniRead($sDir & "\mod_info.ini", "info", "Homepage", "")
	$Map["icon"] = MapEmpty()
	$Map["icon"]["file"] = IniRead($sDir & "\mod_info.ini", "info", "Icon File", "")
	$Map["icon"]["index"] = IniRead($sDir & "\mod_info.ini", "info", "Icon Index", "")
	$Map["mod_version"] = IniRead($sDir & "\mod_info.ini", "info", "Version", "0.0")
	$Map["priority"] = IniRead($sDir & "\mod_info.ini", "info", "Priority", 0)
	$Map["compatibility"] = MapEmpty()
	$Map["compatibility"]["class"] = IniRead($sDir & "\mod_info.ini", "info", "Compatibility Class", "Default")
	$Map["compatibility"]["entries"] = MapEmpty()
	Local $aTemp = IniReadSection($sDir & "\mod_info.ini", "Compatibility")
	If Not @error Then
		For $i = 1 To $aTemp[0][0]
			$Map["compatibility"]["entries"][$aTemp[$i][0]] = Int($aTemp[$i][1]) > 0 ? True : False
		Next
	EndIf
EndFunc

Func Mod_SetSelectedMod(Const $iMod)
	$MM_SELECTED_MOD = $iMod
EndFunc

Func Mod_GetSelectedMod()
	Return $MM_SELECTED_MOD
EndFunc

Func Mod_Get(Const $sPath, $iModIndex = -1)
	Local $vReturn = ""
	Local $aParts = StringSplit($sPath, "\")
	If $iModIndex = -1 Then $iModIndex = Mod_GetSelectedMod()
	Local $sModId = $MM_LIST_CONTENT[$iModIndex][$MOD_ID]

	If $sPath = "id" Then
		$vReturn = $sModId
	ElseIf $sPath = "dir" Then
		$vReturn = $MM_LIST_DIR_PATH & "\" & $MM_LIST_CONTENT[$iModIndex][$MOD_ID]
	ElseIf $sPath = "dir\" Then
		$vReturn = $MM_LIST_DIR_PATH & "\" & $MM_LIST_CONTENT[$iModIndex][$MOD_ID] & "\"
	ElseIf $sPath = "info_file" Then
		$vReturn = $MM_LIST_DIR_PATH & "\" & $MM_LIST_CONTENT[$iModIndex][$MOD_ID] & "\mod.json"
	ElseIf $sPath = "caption" Then
		$vReturn = ($MM_LIST_MAP[$sModId])["caption"][$MM_LANGUAGE_CODE]
		If $vReturn = "" Then $vReturn = ($MM_LIST_MAP[$sModId])["caption"]["en_US"]
		If $vReturn = "" Then $vReturn = $MM_LIST_CONTENT[$iModIndex][$MOD_ID]
	ElseIf $aParts[1] = "caption" And $aParts[2] = "formatted" Then
		$vReturn = Mod_Get("caption", $iModIndex)
		Local $sCategory = ($MM_LIST_MAP[$sModId])["category"]
		If $sCategory <> "" Then $vReturn = StringFormat("[%s] %s", ($aParts[0] > 2 And $aParts[3] = "caps") ? StringUpper(Lng_GetCategory($sCategory)) : Lng_GetCategory($sCategory), $vReturn)
	ElseIf $aParts[1] = "description" Then
		$vReturn = ($MM_LIST_MAP[$sModId])["description"][$aParts[2]][$MM_LANGUAGE_CODE]
		If $vReturn = "" Then $vReturn = ($MM_LIST_MAP[$sModId])["description"][$aParts[2]]["en_US"]
		If $vReturn = "" Then $vReturn = Lng_Get("info_group.no_info")
	ElseIf $aParts[1] = "plugins" And Not MapExists(($MM_LIST_MAP[$sModId])["plugins"], $aParts[2]) Then
		Switch $aParts[3]
			Case "caption"
				$vReturn = $aParts[2]
			Case "description"
				$vReturn = Lng_Get("info_group.no_info")
			Case "default"
				$vReturn = False
			Case "hidden"
				$vReturn = False
		EndSwitch
	ElseIf $aParts[1] = "plugins" And $aParts[3] = "caption" Then
		$vReturn = ($MM_LIST_MAP[$sModId])["plugins"][$aParts[2]]["caption"][$MM_LANGUAGE_CODE]
		If $vReturn = "" Then $vReturn = ($MM_LIST_MAP[$sModId])["plugins"][$aParts[2]]["caption"]["en_US"]
		If $vReturn = "" Then $vReturn = $aParts[2]
	ElseIf $aParts[1] = "plugins" And $aParts[3] = "description" Then
		$vReturn = ($MM_LIST_MAP[$sModId])["plugins"][$aParts[2]]["description"][$MM_LANGUAGE_CODE]
		If $vReturn = "" Then $vReturn = ($MM_LIST_MAP[$sModId])["plugins"][$aParts[2]]["description"]["en_US"]
		If $vReturn = "" Then $vReturn = Lng_Get("info_group.no_info")
	Else
		Switch $aParts[0]
			Case 1
				$vReturn = ($MM_LIST_MAP[$sModId])[$aParts[1]]
			Case 2
				$vReturn = ($MM_LIST_MAP[$sModId])[$aParts[1]][$aParts[2]]
			Case 3
				$vReturn = ($MM_LIST_MAP[$sModId])[$aParts[1]][$aParts[2]][$aParts[3]]
		EndSwitch
	EndIf

	Return $vReturn
EndFunc

Func Mod_Save(Const $iModIndex, Const $mModData)
	Local $sSaveTo = Mod_Get("info_file", $iModIndex)
	Local $sText = Jsmn_Encode($mModData, $JSMN_PRETTY_PRINT + $JSMN_UNESCAPED_UNICODE + $JSMN_UNESCAPED_SLASHES)
	If Not @error Then
		FileDelete($sSaveTo)
		FileWrite($sSaveTo, $sText)
	EndIf
EndFunc

Func Mod_CreatePackage(Const $iModIndex, Const $sSavePath)
	Local $s7zTempDir = _TempFile()
	DirCreate($s7zTempDir)

	FileCopy(@ScriptDir & '\7z\7z.*', $s7zTempDir & '\7z\7z.*', $FC_OVERWRITE + $FC_CREATEPATH)

	Local $hFile = SFX_FileOpen($s7zTempDir & '\7z\7z.sfx')
	If Mod_Get("icon\file", $iModIndex) <> "" Then SFX_UpdateIcon($hFile, Mod_Get("dir\", $iModIndex) & Mod_Get("icon\file", $iModIndex))
	SFX_UpdateModDirName($hFile, Mod_Get("id", $iModIndex))
	SFX_FileClose($hFile)

	Local $sCommand = StringFormat('%s a %s "Mods\%s" -sfx7z.sfx', '"' & $s7zTempDir & '\7z\7z.exe"', '"' & $sSavePath & '"', Mod_Get("id", $iModIndex))
	Run($sCommand, $MM_GAME_DIR, @SW_MINIMIZE)
	_WinAPI_ShellChangeNotify($SHCNE_ASSOCCHANGED, $SHCNF_FLUSH)
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
				Local $sType1 = Mod_Get("compatibility\class", $iCount)
				Local $sType2 = Mod_Get("compatibility\class", $jCount)
				Local $i1To2 = Mod_Get("compatibility\entries" & Mod_Get("id", $jCount), $iCount)
				Local $i2To1 = Mod_Get("compatibility\entries" & Mod_Get("id", $iCount), $jCount)
				If $i1To2 > 0 Then
					$MM_LIST_COMPATIBILITY[$sModID1][$sModID2] = True
				ElseIf $i1To2 < 0 Then
					$MM_LIST_COMPATIBILITY[$sModID1][$sModID2] = False
				ElseIf $i2To1 > 0 Then
					$MM_LIST_COMPATIBILITY[$sModID1][$sModID2] = True
				ElseIf $i2To1 < 0 Then
					$MM_LIST_COMPATIBILITY[$sModID1][$sModID2] = False
				ElseIf ($sType1 = "none" And ($sType2 = "none" Or $sType2 = "default")) Or ($sType2 = "none" And ($sType1 = "none" Or $sType1 = "default")) Then
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
		$MM_LIST_CANT_WORK = True
	EndIf

	Local $sWrite = ""
	For $iCount = $MM_LIST_CONTENT[0][0] To 1 Step -1
		If $MM_LIST_CONTENT[$iCount][$MOD_IS_ENABLED] Then
			$sWrite &= $MM_LIST_CONTENT[$iCount][0] & @CRLF
		EndIf
	Next

	If Not FileWrite($MM_LIST_FILE_PATH, $sWrite) Then
		$MM_LIST_CANT_WORK = True
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

Func Mod_ScreenListLoad(Const $sModName)
	Local $aReturn = _FileListToArray($MM_LIST_DIR_PATH & "\" & $sModName & "\Screens\", Default, $FLTA_FILES, True)
	If @error Then Dim $aReturn[1]

	Return $aReturn
EndFunc

Func Mod_GetVersion($sModName)
	Return IniRead($MM_LIST_DIR_PATH & "\" & $sModName & "\mod_info.ini", "info", "Version", "0.0")
EndFunc   ;==>Mod_GetVersion

Func Mod_GetIndexByID($sModID)
	For $iCount = 1 To $MM_LIST_CONTENT[0][0]
		If $MM_LIST_CONTENT[$iCount][0] = $sModID Then Return $iCount
	Next

	Return -1
EndFunc   ;==>Mod_GetIndexByID
