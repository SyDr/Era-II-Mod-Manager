; Author:         Aliaksei SyDr Karalenka

#include <Array.au3>
#include <File.au3>
#include <StringConstants.au3>

#include "data_fwd.au3"
#include "lng.au3"

#include-once

Func Mod_ListLoad()
	Local Const $iListSize = 10
	Local $aModList_Dir, $aModList_File, $aModList[1][$iListSize]	; [][0] - dir name, [][1] - state (enabled/disabled) [][2] - do not exist,	[][3] - localized name,
																	; [][4] - author,   [][5] - description, 			 [][6] - link, 			[][8] - icon
																	; [][9] - version,	[][10] - priority

	$aModList[0][1] = "Enabled/Disabled"
	$aModList[0][2] = "True, if not exist"
	$aModList[0][3] = "Displayed Name"
	$aModList[0][4] = "Author"
	$aModList[0][5] = "Description"
	$aModList[0][6] = "Link"
	$aModList[0][7] = "Icon"
	$aModList[0][8] = "Version"
	$aModList[0][9] = "Priority"

	$MM_LIST_FILE_CONTENT = FileRead($MM_LIST_FILE_PATH)
	$aModList_File = StringSplit($MM_LIST_FILE_CONTENT, @CRLF, $STR_ENTIRESPLIT)

	_ArrayReverse($aModList_File, 1)
	If Not IsArray($aModList_File) Then	Dim $aModList_File[1] = [0]
	$aModList_Dir = _FileListToArray($MM_LIST_DIR_PATH, "*", 2)
	If Not IsArray($aModList_Dir) Then Dim $aModList_Dir[1] = [0]
	ReDim $aModList[1+$aModList_File[0]+$aModList_Dir[0]][$iListSize]

	Local $jCount = 1
	For $iCount = 1 To $aModList_File[0]
		Local $iIndex = _ArraySearch($aModList, $aModList_File[$iCount], 1, 0, 0, 0, 0, 0)
		If $iIndex <> -1 Then ContinueLoop ;$aModList[$jCount][3] = $iIndex
		$aModList[$jCount][0] = $aModList_File[$iCount]
		$aModList[$jCount][1] = "Enabled"
		If Not FileExists($MM_LIST_DIR_PATH & "\" & $aModList_File[$iCount] & "\") Then $aModList[$jCount][2] = True
		$aModList[$jCount][3] = IniRead($MM_LIST_DIR_PATH & "\" & $aModList_File[$iCount] & "\mod_info.ini", "info", "Caption." & Lng_Get("lang.code"), IniRead($MM_LIST_DIR_PATH & "\" & $aModList_File[$iCount] & "\mod_info.ini", "info", "Caption", $aModList[$jCount][0]))
		$aModList[$jCount][4] = IniRead($MM_LIST_DIR_PATH & "\" & $aModList_File[$iCount] & "\mod_info.ini", "info", "Author", "")
		$aModList[$jCount][5] = IniRead($MM_LIST_DIR_PATH & "\" & $aModList_File[$iCount] & "\mod_info.ini", "info", "Description File." & Lng_Get("lang.code"), IniRead($MM_LIST_DIR_PATH & "\" & $aModList_File[$iCount] & "\mod_info.ini", "info", "Description File", ""))
		$aModList[$jCount][6] = IniRead($MM_LIST_DIR_PATH & "\" & $aModList_File[$iCount] & "\mod_info.ini", "info", "Homepage", "")
		$aModList[$jCount][7] = IniRead($MM_LIST_DIR_PATH & "\" & $aModList_File[$iCount] & "\mod_info.ini", "info", "Icon File", "")
		$aModList[$jCount][8] = IniRead($MM_LIST_DIR_PATH & "\" & $aModList_File[$iCount] & "\mod_info.ini", "info", "Version", "0.0")
		$aModList[$jCount][9] = Int(IniRead($MM_LIST_DIR_PATH & "\" & $aModList_File[$iCount] & "\mod_info.ini", "info", "Priority", 0))
		$jCount += 1
	Next

	For $iCount = 1 To $aModList_Dir[0]
		_ArraySearch($aModList, $aModList_Dir[$iCount], 1, 0, 0, 0, 0, 0)
		If @error = 6 Then
			$aModList[$jCount][0] = $aModList_Dir[$iCount]
			$aModList[$jCount][1] = "Disabled"
			$aModList[$jCount][3] = IniRead($MM_LIST_DIR_PATH & "\" & $aModList_Dir[$iCount] & "\mod_info.ini", "info", "Caption." & Lng_Get("lang.code"), IniRead($MM_LIST_DIR_PATH & "\" & $aModList_Dir[$iCount] & "\mod_info.ini", "info", "Caption", $aModList[$jCount][0]))
			$aModList[$jCount][4] = IniRead($MM_LIST_DIR_PATH & "\" & $aModList_Dir[$iCount] & "\mod_info.ini", "info", "Author", "")
			$aModList[$jCount][5] = IniRead($MM_LIST_DIR_PATH & "\" & $aModList_Dir[$iCount] & "\mod_info.ini", "info", "Description File."  & Lng_Get("lang.code"), IniRead($MM_LIST_DIR_PATH & "\" & $aModList_Dir[$iCount] & "\mod_info.ini", "info", "Description File", ""))
			$aModList[$jCount][6] = IniRead($MM_LIST_DIR_PATH & "\" & $aModList_Dir[$iCount] & "\mod_info.ini", "info", "Homepage", "")
			$aModList[$jCount][7] = IniRead($MM_LIST_DIR_PATH & "\" & $aModList_Dir[$iCount] & "\mod_info.ini", "info", "Icon File", "")
			$aModList[$jCount][8] = IniRead($MM_LIST_DIR_PATH & "\" & $aModList_Dir[$iCount] & "\mod_info.ini", "info", "Version", "0.0")
			$aModList[$jCount][9] = Int(IniRead($MM_LIST_DIR_PATH & "\" & $aModList_Dir[$iCount] & "\mod_info.ini", "info", "Priority", 0))
			$jCount += 1
		EndIf
	Next

	ReDim $aModList[$jCount][$iListSize]
	$aModList[0][0] = $jCount - 1
	;Settings_Global("Set", "ModList", $aModList)
	Return $aModList
EndFunc

Func Mod_ReEnable($aModList, $sModID)
	Local $iModIndex = Mod_GetIndexByID($aModList, $sModID)
	If $iModIndex <> -1 Then
		Mod_Disable($iModIndex, $aModList)
		$aModList = Mod_ListLoad()
	EndIf

	$iModIndex = Mod_GetIndexByID($aModList, $sModID)
	If $iModIndex <> -1 Then
		Mod_Enable($iModIndex, $aModList)
	Else
		FileWriteLine($MM_LIST_FILE_PATH, $sModID)
	EndIf
EndFunc

Func Mod_CompatibilityMapLoad($aModList)
	Local $aAnswer[UBound($aModList, 1)][UBound($aModList, 1)]
	$aAnswer[0][0] = UBound($aModList, 1) - 1
	For $iCount = 1 To $aAnswer[0][0]
		For $jCount = 1 To $aAnswer[0][0]
			If $iCount = $jCount Then ContinueLoop
			If $aModList[$iCount][1] = "Disabled" Or $aModList[$jCount][1] = "Disabled" Then
				$aAnswer[$iCount][$jCount] = True
				ContinueLoop
			EndIf

			Local $sType1 = IniRead($MM_LIST_DIR_PATH & "\" & $aModList[$iCount][0] & "\mod_info.ini", "info", "Compatibility Class", "Default")
			Local $sType2 = IniRead($MM_LIST_DIR_PATH & "\" & $aModList[$jCount][0] & "\mod_info.ini", "info", "Compatibility Class", "Default")
			Local $i1To2  = IniRead($MM_LIST_DIR_PATH & "\" & $aModList[$iCount][0] & "\mod_info.ini", "Compatibility", $aModList[$jCount][0], 0)
			Local $i2To1  = IniRead($MM_LIST_DIR_PATH & "\" & $aModList[$jCount][0] & "\mod_info.ini", "Compatibility", $aModList[$iCount][0], 0)
			If $i1To2 == 1 Then
				$aAnswer[$iCount][$jCount] = True
			ElseIf $i1To2 == -1 Then
				$aAnswer[$iCount][$jCount] = False
			ElseIf $i2To1 == 1 Then
				$aAnswer[$iCount][$jCount] = True
			ElseIf $i2To1 == -1 Then
				$aAnswer[$iCount][$jCount] = False
			ElseIf ($sType1 = "None" And ($sType2 = "None" Or $sType2 = "Default")) Or ($sType2 = "None" And ($sType1 = "None" Or $sType1 = "Default")) Then
				$aAnswer[$iCount][$jCount] = False
			Else
				$aAnswer[$iCount][$jCount] = True
			EndIf
		Next
	Next
	Return $aAnswer
EndFunc

Func Mod_ListSave($aModList)
	If Not FileDelete($MM_LIST_FILE_PATH) And FileExists($MM_LIST_FILE_PATH) Then
		MsgBox(4096, "", "Press CTRL+C to copy this message" & @CRLF & @CRLF & _
		StringFormat(Lng_Get("list.txt"), StringFormat("FileDelete(%s)", $MM_LIST_FILE_PATH)))
		Return False
	EndIf
	Local $sWrite = ""
	For $iCount = UBound($aModList, 1) -1 To 0 Step -1
		If $aModList[$iCount][1] = "Enabled" Then
			$sWrite &= $aModList[$iCount][0] & @CRLF
		EndIf
	Next
	If Not FileWrite($MM_LIST_FILE_PATH, $sWrite) Then
		MsgBox(4096, "", "Press CTRL+C to copy this message" & @CRLF & @CRLF & _
		StringFormat(Lng_Get("list.txt"), StringFormat("FileWrite(%s, %s", $MM_LIST_FILE_PATH, $sWrite)))
		Return False
	EndIf
EndFunc

Func Mod_ListSwap($iModIndex1, $iModIndex2, ByRef $aModList, $sUpdate = True)
	Local $vTemp

	For $jCount = 0 To UBound($aModList, 2) - 1
		$vTemp = $aModList[$iModIndex1][$jCount]
		$aModList[$iModIndex1][$jCount] = $aModList[$iModIndex2][$jCount]
		$aModList[$iModIndex2][$jCount] = $vTemp
	Next

	If $sUpdate Then Mod_ListSave($aModList)
EndFunc

Func Mod_CompatibilitySwap($iModIndex1, $iModIndex2, ByRef $abModCompatibilityMap)
	Local $vTemp

	For $iCount = 1 To $abModCompatibilityMap[0][0]
		$vTemp = $abModCompatibilityMap[$iModIndex1][$iCount]
		$abModCompatibilityMap[$iModIndex1][$iCount] = $abModCompatibilityMap[$iModIndex2][$iCount]
		$abModCompatibilityMap[$iModIndex2][$iCount] = $vTemp
	Next

	For $iCount = 1 To $abModCompatibilityMap[0][0]
		$vTemp = $abModCompatibilityMap[$iCount][$iModIndex1]
		$abModCompatibilityMap[$iCount][$iModIndex1] = $abModCompatibilityMap[$iCount][$iModIndex2]
		$abModCompatibilityMap[$iCount][$iModIndex2] = $vTemp
	Next

EndFunc

Func Mod_Disable($iModIndex, ByRef $aModList)
	If $aModList[$iModIndex][1] = "Disabled" Then Return 0
	$aModList[$iModIndex][1] = "Disabled"
	Mod_ListSave($aModList)
	Return 1
EndFunc

Func Mod_Delete($iModIndex, ByRef $aModList)
	FileRecycle($MM_LIST_DIR_PATH & "\" & $aModList[$iModIndex][0])
	Mod_Disable($iModIndex, $aModList)
EndFunc

Func Mod_Enable($iModIndex, ByRef $aModList)
	If $aModList[$iModIndex][1] = "Enabled" Then Return False
	$aModList[$iModIndex][1] = "Enabled"
	For $iIndex = $iModIndex To 2 Step -1
		If $aModList[$iIndex-1][1] = "Enabled" And $aModList[$iIndex-1][9] > $aModList[$iIndex][9] Then ExitLoop
		Mod_ListSwap($iIndex, $iIndex-1, $aModList, False)
	Next
	Mod_ListSave($aModList)
EndFunc

Func Mod_ModIsInstalled($sModName, ByRef $aModList)
	For $iCount = 1 To $aModList[0][0]
		If $aModList[$iCount][0]=$sModName Then Return $iCount
	Next
	Return 0
EndFunc

Func Mod_ModIsEnabled($sModName, ByRef $aModList)
	For $iCount = 1 To $aModList[0][0]
		If $aModList[$iCount][0]=$sModName And $aModList[$iCount][1]="Enabled" Then Return $iCount
	Next
	Return 0
EndFunc

Func Mod_InfoLoad($sModName, $sPreferFile = "")
	Local $sReturn
	If $sPreferFile <> "" Then $sReturn = FileRead($MM_LIST_DIR_PATH & "\" & $sModName & "\" & $sPreferFile)
	If $sPreferFile = "" Or @error Then $sReturn = FileRead($MM_LIST_DIR_PATH & "\" & $sModName & "\Readme.txt")
	If @error Then $sReturn = FileRead($MM_LIST_DIR_PATH & "\" & $sModName & "\Info.txt")
	If @error Or $sReturn = "" Then $sReturn = Lng_Get("group.modinfo.no_info")
	Return $sReturn
EndFunc

Func Mod_GetVersion($sModName)
	Return IniRead($MM_LIST_DIR_PATH & "\" & $sModName & "\mod_info.ini", "info", "Version", "0.0")
EndFunc

Func Mod_MakeDisplayName($sName, $bDNE, $sVersion, $bDisplayVersion = True)
	Local $sReturn = ""
	If $bDNE Then
		$sReturn = $sName & " " & Lng_Get("group.modlist.missing_mod")
	Else
		$sReturn = $sName
	EndIf

	If $bDisplayVersion And $sVersion <> "0.0" And $sVersion <> "" Then $sReturn &= StringFormat(" [%s]", $sVersion)
	Return $sReturn
EndFunc

Func Mod_GetIndexByID($aModList, $sModID)
	For $iCount = 1 To $aModList[0][0]
		If $aModList[$iCount][0] = $sModID Then Return $iCount
	Next

	Return -1
EndFunc