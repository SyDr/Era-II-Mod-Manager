;Author:			Aliaksei SyDr Karalenka

#include-once
#include "include_fwd.au3"
#include "lng.au3"

Func Plugins_ModHavePlugins(Const ByRef $sModID)
	Local $iReturn
	Local $aData1 = $MM_PLUGINS_CONTENT
	Local $aData2 = $MM_PLUGINS_PART_PRESENT

	Plugins_ListLoad($sModID)
	$iReturn = $MM_PLUGINS_CONTENT[0][0]

	$MM_PLUGINS_CONTENT = $aData1
	$MM_PLUGINS_PART_PRESENT = $aData2
	Return $iReturn
EndFunc   ;==>Plugins_ModHavePlugins

Func Plugins_ListLoad(Const ByRef $sModID)
	Local $sPath = $MM_LIST_DIR_PATH & "\" & $sModID
	Local $aPluginList[1][$PLUGIN_TOTAL]

	Local $aGlobal = _FileListToArray($sPath & "\EraPlugins\", "*", 1)
	Local $aBeforeWog = _FileListToArray($sPath & "\EraPlugins\BeforeWoG\", "*", 1)
	Local $aAfterWog = _FileListToArray($sPath & "\EraPlugins\AfterWoG\", "*", 1)

	Local $iTotalPlugins = 0

	$MM_PLUGINS_PART_PRESENT[$PLUGIN_GROUP_GLOBAL] = False
	$MM_PLUGINS_PART_PRESENT[$PLUGIN_GROUP_BEFORE] = False
	$MM_PLUGINS_PART_PRESENT[$PLUGIN_GROUP_AFTER] = False

	__Plugins_ListLoadFromFolder($aPluginList, $aGlobal, $sPath & "\EraPlugins", $sModID, $PLUGIN_GROUP_GLOBAL, $iTotalPlugins)
	__Plugins_ListLoadFromFolder($aPluginList, $aBeforeWog, $sPath & "\EraPlugins\BeforeWoG", $sModID, $PLUGIN_GROUP_BEFORE, $iTotalPlugins)
	__Plugins_ListLoadFromFolder($aPluginList, $aAfterWog, $sPath & "\EraPlugins\AfterWoG", $sModID, $PLUGIN_GROUP_AFTER, $iTotalPlugins)

	$aPluginList[0][0] = $iTotalPlugins
	ReDim $aPluginList[$iTotalPlugins + 1][$PLUGIN_TOTAL]

	$aPluginList[0][$PLUGIN_PATH] = "Path"
	$aPluginList[0][$PLUGIN_GROUP] = "Group Enum"
	$aPluginList[0][$PLUGIN_CAPTION] = "Caption"
	$aPluginList[0][$PLUGIN_DESCRIPTION] = "Description"
	$aPluginList[0][$PLUGIN_STATE] = "State"
	$aPluginList[0][$PLUGIN_DEFAULT_STATE] = "Default state"
	$aPluginList[0][$PLUGIN_HIDDEN] = "Hidden"

	$MM_PLUGINS_CONTENT = $aPluginList
EndFunc

Func __Plugins_ListLoadFromFolder(ByRef $aPluginList, Const ByRef $aFileList, Const $sPath, Const ByRef $sModID, Const $iGroupId, ByRef $iPrevPos)
	Local $bIsEnabled, $sFileName
	If IsArray($aFileList) Then
		ReDim $aPluginList[UBound($aPluginList, $UBOUND_ROWS) + $aFileList[0]][$PLUGIN_TOTAL]
		For $iCount = 1 To $aFileList[0]
			If FileGetSize($sPath & "\" & $aFileList[$iCount]) <> 0 Then
				$MM_PLUGINS_PART_PRESENT[$iGroupId] = 1
				$iPrevPos += 1
				$bIsEnabled = StringRight($aFileList[$iCount], 4) <> ".off"
				$sFileName = ($bIsEnabled ? $aFileList[$iCount] : StringTrimRight($aFileList[$iCount], 4))
				$aPluginList[$iPrevPos][$PLUGIN_FILENAME] = $sFileName
				$aPluginList[$iPrevPos][$PLUGIN_PATH] = $sPath & "\" & $sFileName
				$aPluginList[$iPrevPos][$PLUGIN_GROUP] = $iGroupId
				$aPluginList[$iPrevPos][$PLUGIN_CAPTION] = IniRead($MM_LIST_DIR_PATH & "\" & $sModID & "\mod_info.ini", "Plugins", $sFileName & ".Caption." & Lng_Get("lang.code"), IniRead($MM_LIST_DIR_PATH & "\" & $sModID & "\mod_info.ini", "Plugins", $sFileName & ".Caption", $sFileName))
				$aPluginList[$iPrevPos][$PLUGIN_DESCRIPTION] = IniRead($MM_LIST_DIR_PATH & "\" & $sModID & "\mod_info.ini", "Plugins", $sFileName & ".Description." & Lng_Get("lang.code"), IniRead($MM_LIST_DIR_PATH & "\" & $sModID & "\mod_info.ini", "Plugins", $sFileName & ".Description", $sFileName))
				$aPluginList[$iPrevPos][$PLUGIN_STATE] = $bIsEnabled
				$aPluginList[$iPrevPos][$PLUGIN_DEFAULT_STATE] = Int(IniRead($MM_LIST_DIR_PATH & "\" & $sModID & "\mod_info.ini", "Plugins", $sFileName & ".Default", $bIsEnabled)) > 0
				$aPluginList[$iPrevPos][$PLUGIN_HIDDEN] = Int(IniRead($MM_LIST_DIR_PATH & "\" & $sModID & "\mod_info.ini", "Plugins", $sFileName & ".Hidden", 0)) > 0
			EndIf
		Next
	EndIf
EndFunc

Func Plugins_ChangeState($iPluginIndex)
	Local $sSourceFile = $MM_PLUGINS_CONTENT[$iPluginIndex][$PLUGIN_PATH] & ($MM_PLUGINS_CONTENT[$iPluginIndex][$PLUGIN_STATE] ? "" : ".off")
	Local $sTargetFile = $MM_PLUGINS_CONTENT[$iPluginIndex][$PLUGIN_PATH] & ($MM_PLUGINS_CONTENT[$iPluginIndex][$PLUGIN_STATE] ? ".off" : "")

	If FileMove($sSourceFile, $sTargetFile) Then
		$MM_PLUGINS_CONTENT[$iPluginIndex][$PLUGIN_STATE] = Not $MM_PLUGINS_CONTENT[$iPluginIndex][$PLUGIN_STATE]
	EndIf
EndFunc
