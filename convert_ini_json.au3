#AutoIt3Wrapper_Version=Beta

Dim $__MM_NO_UI
#include "ramm.au3"

Mod_ListLoad()

For $i = 1 To $MM_LIST_CONTENT[0][0]
	If Not FileExists($MM_LIST_DIR_PATH & "\" & $MM_LIST_CONTENT[$i][$MOD_ID] & "\mod_info.json") And FileExists($MM_LIST_DIR_PATH & "\" & $MM_LIST_CONTENT[$i][$MOD_ID] & "\mod_info.ini") Then
		Local $sText = Jsmn_Encode($MM_LIST_CONTENT[$i][$MOD_INFO_PARSED], $JSMN_PRETTY_PRINT + $JSMN_UNESCAPED_UNICODE + $JSMN_UNESCAPED_SLASHES)
		FileWrite($MM_LIST_DIR_PATH & "\" & $MM_LIST_CONTENT[$i][$MOD_ID] & "\mod_info.json", $sText)
	EndIf
Next
