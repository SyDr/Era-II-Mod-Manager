;Author:			Aliaksei SyDr Karalenka

#AutoIt3Wrapper_Version=Beta
#include-once
#include "include_fwd.au3"

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

Func Scn_Delete(Const $iItemIndex)
	If $iItemIndex < 1 Or $iItemIndex > $MM_SCN_LIST[0] Then Return
	FileRecycle($MM_SCN_DIRECTORY & "\" & $MM_SCN_LIST[$iItemIndex] & ".json")
EndFunc
