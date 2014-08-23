; Author:         Aliaksei SyDr Karalenka

#include <Array.au3>
#include <File.au3>

#include "lng.au3"
#include "settings.au3"

#include-once

Func Mod_ListLoad()
	Local $sListFile    = Settings_Global("Get", "List")
	Local $sTargetPath  = Settings_Global("Get", "Path")
	If StringRight($sTargetPath, 1) = "\" Then $sTargetPath = StringTrimRight($sTargetPath, 1)
	$sTargetPath &= "\"
	Local Const $iListSize = 9
	Local $aModList_Dir, $aModList_File, $aModList[1][$iListSize]	; [][0] - dir name, [][1] - state (enabled/disabled) [][2] - do not exist,	[][3] - localized name,
																	; [][4] - author,   [][5] - description, 			 [][6] - link, 			[][8] - icon
																	; [][9] - version

	$aModList[0][1] = "Enabled/Disabled"
	$aModList[0][2] = "True, if not exist"
	$aModList[0][3] = "Displayed Name"
	$aModList[0][4] = "Author"
	$aModList[0][5] = "Description"
	$aModList[0][6] = "Link"
	$aModList[0][7] = "Icon"
	$aModList[0][8] = "Version"

	_FileReadToArray($sListFile, $aModList_File)
	_ArrayReverse($aModList_File, 1)
	If Not IsArray($aModList_File) Then	Dim $aModList_File[1] = [0]
	$aModList_Dir = _FileListToArray($sTargetPath, "*", 2)
	If Not IsArray($aModList_Dir) Then	Dim $aModList_Dir[1] = [0]
	ReDim $aModList[1+$aModList_File[0]+$aModList_Dir[0]][$iListSize]

	Local $jCount = 1
	For $iCount = 1 To $aModList_File[0]
		Local $iIndex = _ArraySearch($aModList, $aModList_File[$iCount], 1, 0, 0, 0, 0, 0)
		If $iIndex <> -1 Then ContinueLoop ;$aModList[$jCount][3] = $iIndex
		$aModList[$jCount][0] = $aModList_File[$iCount]
		$aModList[$jCount][1] = "Enabled"
		If Not FileExists($sTargetPath & "\" & $aModList_File[$iCount] & "\") Then $aModList[$jCount][2] = True
		$aModList[$jCount][3] = IniRead($sTargetPath & "\" & $aModList_File[$iCount] & "\mod_info.ini", "info", "Caption." & Lng_Get("lang.code"), IniRead($sTargetPath & "\" & $aModList_File[$iCount] & "\mod_info.ini", "info", "Caption", $aModList[$jCount][0]))
		$aModList[$jCount][4] = IniRead($sTargetPath & "\" & $aModList_File[$iCount] & "\mod_info.ini", "info", "Author", "")
		$aModList[$jCount][5] = IniRead($sTargetPath & "\" & $aModList_File[$iCount] & "\mod_info.ini", "info", "Description File." & Lng_Get("lang.code"), IniRead($sTargetPath & "\" & $aModList_File[$iCount] & "\mod_info.ini", "info", "Description File", ""))
		$aModList[$jCount][6] = IniRead($sTargetPath & "\" & $aModList_File[$iCount] & "\mod_info.ini", "info", "Homepage", "")
		$aModList[$jCount][7] = IniRead($sTargetPath & "\" & $aModList_File[$iCount] & "\mod_info.ini", "info", "Icon File", "")
		$aModList[$jCount][8] = IniRead($sTargetPath & "\" & $aModList_File[$iCount] & "\mod_info.ini", "info", "Version", "0.0")
		$jCount += 1
	Next

	For $iCount = 1 To $aModList_Dir[0]
		_ArraySearch($aModList, $aModList_Dir[$iCount], 1, 0, 0, 0, 0, 0)
		If @error = 6 Then
			$aModList[$jCount][0] = $aModList_Dir[$iCount]
			$aModList[$jCount][1] = "Disabled"
			$aModList[$jCount][3] = IniRead($sTargetPath & "\" & $aModList_Dir[$iCount] & "\mod_info.ini", "info", "Caption." & Lng_Get("lang.code"), IniRead($sTargetPath & "\" & $aModList_Dir[$iCount] & "\mod_info.ini", "info", "Caption", $aModList[$jCount][0]))
			$aModList[$jCount][4] = IniRead($sTargetPath & "\" & $aModList_Dir[$iCount] & "\mod_info.ini", "info", "Author", "")
			$aModList[$jCount][5] = IniRead($sTargetPath & "\" & $aModList_Dir[$iCount] & "\mod_info.ini", "info", "Description File."  & Lng_Get("lang.code"), IniRead($sTargetPath & "\" & $aModList_Dir[$iCount] & "\mod_info.ini", "info", "Description File", ""))
			$aModList[$jCount][6] = IniRead($sTargetPath & "\" & $aModList_Dir[$iCount] & "\mod_info.ini", "info", "Homepage", "")
			$aModList[$jCount][7] = IniRead($sTargetPath & "\" & $aModList_Dir[$iCount] & "\mod_info.ini", "info", "Icon File", "")
			$aModList[$jCount][8] = IniRead($sTargetPath & "\" & $aModList_Dir[$iCount] & "\mod_info.ini", "info", "Version", "0.0")
			$jCount += 1
		EndIf
	Next

	ReDim $aModList[$jCount][$iListSize]
	$aModList[0][0] = $jCount - 1
	;Settings_Global("Set", "ModList", $aModList)
	Return $aModList
EndFunc

Func Mod_CompatibilityMapLoad($aModList)
	Local $sTargetPath  = Settings_Global("Get", "Path")
	Local $aAnswer[UBound($aModList, 1)][UBound($aModList, 1)]
	$aAnswer[0][0] = UBound($aModList, 1) - 1
	For $iCount = 1 To $aAnswer[0][0]
		For $jCount = 1 To $aAnswer[0][0]
			If $iCount = $jCount Then ContinueLoop
			If $aModList[$iCount][1] = "Disabled" Or $aModList[$jCount][1] = "Disabled" Then
				$aAnswer[$iCount][$jCount] = True
				ContinueLoop
			EndIf

			Local $sType1 = IniRead($sTargetPath & "\" & $aModList[$iCount][0] & "\mod_info.ini", "info", "Compatibility Class", "Default")
			Local $sType2 = IniRead($sTargetPath & "\" & $aModList[$jCount][0] & "\mod_info.ini", "info", "Compatibility Class", "Default")
			Local $i1To2  = IniRead($sTargetPath & "\" & $aModList[$iCount][0] & "\mod_info.ini", "Compatibility", $aModList[$jCount][0], 0)
			Local $i2To1  = IniRead($sTargetPath & "\" & $aModList[$jCount][0] & "\mod_info.ini", "Compatibility", $aModList[$iCount][0], 0)
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
	Local $sTargetFile  = Settings_Global("Get", "List")
	If Not FileDelete($sTargetFile) And FileExists($sTargetFile) Then
		MsgBox(4096, "", "Press CTRL+C to copy this message" & @CRLF & @CRLF & _
		StringFormat(Lng_Get("list.txt"), StringFormat("FileDelete(%s)", $sTargetFile)))
		Return False
	EndIf
	Local $sWrite = ""
	For $iCount = UBound($aModList, 1) -1 To 0 Step -1
		If $aModList[$iCount][1] = "Enabled" Then
			$sWrite &= $aModList[$iCount][0] & @CRLF
		EndIf
	Next
	If Not FileWrite($sTargetFile, $sWrite) Then
		MsgBox(4096, "", "Press CTRL+C to copy this message" & @CRLF & @CRLF & _
		StringFormat(Lng_Get("list.txt"), StringFormat("FileWrite(%s, %s", $sTargetFile, $sWrite)))
		Return False
	EndIf
EndFunc

Func Mod_ListSwap($iModIndex1, $iModIndex2, ByRef $aModList, $sUpdate = True)
	Local $sTargetFile  = Settings_Global("Get", "List")
	Local $vTemp
;~ 	MsgBox(4096, Default, $iModIndex1 & @CRLF & $iModIndex2)
	$vTemp = $aModList[$iModIndex1][0]
	$aModList[$iModIndex1][0] = $aModList[$iModIndex2][0]
	$aModList[$iModIndex2][0] = $vTemp

	$vTemp = $aModList[$iModIndex1][1]
	$aModList[$iModIndex1][1] = $aModList[$iModIndex2][1]
	$aModList[$iModIndex2][1] = $vTemp
	If $sUpdate Then Mod_ListSave($aModList)
EndFunc

Func Mod_Disable($iModIndex, ByRef $aModList)
	Local $sTargetFile  = Settings_Global("Get", "List")
	If $aModList[$iModIndex][1]="Disabled" Then Return 0
	$aModList[$iModIndex][1]="Disabled"
	Mod_ListSave($aModList)
	Return 1
EndFunc

Func Mod_Delete($iModIndex, ByRef $aModList)
	Local $sTargetPath  = Settings_Global("Get", "Path")
	FileRecycle($sTargetPath & "\" & $aModList[$iModIndex][0])
	Mod_Disable($iModIndex, $aModList)
EndFunc

Func Mod_Enable($iModIndex, ByRef $aModList)
	If $aModList[$iModIndex][1]="Enabled" Then Return False
	$aModList[$iModIndex][1]="Enabled"
	For $iIndex = $iModIndex To 2 Step -1
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
	Local $sTargetPath  = Settings_Global("Get", "Path")
	Local $sReturn
	If $sPreferFile <> "" Then $sReturn = FileRead($sTargetPath & "\" & $sModName & "\" & $sPreferFile)
	If $sPreferFile = "" Or @error Then $sReturn = FileRead($sTargetPath & "\" & $sModName & "\Readme.txt")
	If @error Then $sReturn = FileRead($sTargetPath & "\" & $sModName & "\Info.txt")
	If @error Then $sReturn = Lng_Get("group.modinfo.no_info")
	If $sReturn = "" Then $sReturn = Lng_Get("group.modinfo.no_info")
	Return $sReturn
EndFunc

Func Mod_GetVersion($sModName)
	Local $sTargetPath  = Settings_Global("Get", "Path")
	Return IniRead($sTargetPath & "\" & $sModName & "\mod_info.ini", "info", "Version", "0.0")
EndFunc

Func Mod_MakeDisplayName($sName, $bDNE, $sDirName, $sAuthor, $bDisplayAuthorName = True)
	Local $sReturn = ""
	If $bDNE Then
		$sReturn = $sName & " " & Lng_Get("group.modlist.missing_mod")
	Else
		$sReturn = $sName
	EndIf

	If $bDisplayAuthorName And $sAuthor <> "0.0" Then $sReturn &= StringFormat(" [%s]", $sAuthor)
	Return $sReturn
EndFunc