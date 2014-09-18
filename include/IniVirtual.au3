#include-once
#include <Array.au3>

; верси¤ 0.6 от 2013.07.21
; http://www.autoitscript.com/forum/topic/147373-inivirtual

; ‘ормат возвращаемых значений и ошибок максимально приближен к нативным функци¤м (например ошибки записи быть не может, так как данные пишутс¤ в пам¤ти).

; =======================================
; Title .........: IniVirtual
; AutoIt Version : 3.3.8.1
; Language ......: English + –усский
; Description ....: ќперации с ini-файлом в пам¤ти
; Author(s) .......: AZJIO
; =======================================

; #CURRENT# =============================
; _IniVirtual_Delete
; _IniVirtual_Initial
; _IniVirtual_Read
; _IniVirtual_ReadSection
; _IniVirtual_ReadSectionNames
; _IniVirtual_RenameSection
; _IniVirtual_Write
; _IniVirtual_WriteSection
; _IniVirtual_Save
; _IniVirtual_IsDuplicateKeys
; _IniVirtual_IsDuplicateSection
; __IniVirtual_GetKeysVal
; =======================================

Func _IniVirtual_Initial($s_INI_Text)
	Local $aSection, $d, $u
	$s_INI_Text = StringRegExpReplace($s_INI_Text, '(*LF)\h+\r\n\h*|\r\n\h+|\s+\z', @CRLF) ; ”даление пробельных символов в начале и в конце каждой строки. (упрощает слудующее рег.выр. и в параметрах лишнее)
	$s_INI_Text = StringRegExpReplace($s_INI_Text, '(*LF)\](?=\r\n\[|\z)', ']' & @CRLF) ;
	; $aSection = StringRegExp($s_INI_Text, '(?s)(?:\r\n|\A)\h*\[\h*(.*?)\h*\]\h*\r\n(.*?)(?=\r\n\h*\[\h*.*?\h*\]\h*\r\n|\z)', 3)
	; $aSection = StringRegExp($s_INI_Text, '(?s)(?:\r\n|\A)\[\h*(.*?)\h*\]\r\n(.*?)(?=\r\n\[\h*.*?\h*\]\r\n|\z)', 3)
	; $aSection = StringRegExp($s_INI_Text, '(?s)(?:\r\n|\A)\[\h*(.*?)\h*\]\r\n(.*?)(?=\r\n\[|\z)', 3)
	; $aSection = StringRegExp($s_INI_Text, '(?ms)^\h*\[\h*([^\v]*?)\h*\]\h*\r\n(.*?)(?=\r\n\h*\[|\z)', 3)
	$aSection = StringRegExp($s_INI_Text, '(*LF)(?ms)^\[\h*([^\v]*?)\h*\]\r\n(.*?)(?=\r\n\[|\z)', 3)
	$u = UBound($aSection)
	Local $a_Ini_Virtual2D[$u / 2 + 1][2] = [[$u / 2]]
	$d = 0
	For $i = 0 To $u - 1 Step 2
		$d += 1
		$a_Ini_Virtual2D[$d][0] = $aSection[$i]
		$a_Ini_Virtual2D[$d][1] = __IniVirtual_GetKeysVal($aSection[$i + 1]) ; массив массивов
	Next
	Return $a_Ini_Virtual2D
EndFunc   ;==>_IniVirtual_Initial

Func __IniVirtual_GetKeysVal($vData)
	$vData = StringRegExp($vData, '(*LF)(?m)^([^;].*?)\h*=\h*(["'']?)(.*?)\2\r?$', 3) ; учитывает пробелы между элементами и обрамление кавычками
	Local $d, $u = UBound($vData) ; 0 как индикатор ошибки
	Local $aData2D[$u / 3 + 1][2] = [[$u / 3]]
	For $i = 0 To $u - 1 Step 3
		$d = Int($i / 3) + 1
		$aData2D[$d][0] = $vData[$i]
		$aData2D[$d][1] = $vData[$i + 2]
	Next
	Return $aData2D
EndFunc   ;==>__IniVirtual_GetKeysVal

Func _IniVirtual_ReadSectionNames($a_Ini_Virtual2D)
	Local $aSection[$a_Ini_Virtual2D[0][0] + 1] = [$a_Ini_Virtual2D[0][0]]
	For $i = 1 To $a_Ini_Virtual2D[0][0]
		$aSection[$i] = $a_Ini_Virtual2D[$i][0]
	Next
	If $aSection[0] = 0 Then Return SetError(1, 0, 0)
	Return $aSection
EndFunc   ;==>_IniVirtual_ReadSectionNames

Func _IniVirtual_Read($a_Ini_Virtual2D, $sSection, $sKey, $sDefault = '')
	Local $i = _ArraySearch($a_Ini_Virtual2D, $sSection, 1, 0, 0, 2, 1, 0)
	If @error Then Return $sDefault
	Local $aKey = $a_Ini_Virtual2D[$i][1]
	$i = _ArraySearch($aKey, $sKey, 1, 0, 0, 2, 1, 0)
	If @error Then Return $sDefault
	Return $aKey[$i][1]
EndFunc   ;==>_IniVirtual_Read

Func _IniVirtual_Write(ByRef $a_Ini_Virtual2D, $sSection, $sKey, $sValue)
	Local $i = _ArraySearch($a_Ini_Virtual2D, $sSection, 1, 0, 0, 2, 1, 0)
	If @error Then ; создаЄт, если не существует
		$a_Ini_Virtual2D[0][0] += 1
		ReDim $a_Ini_Virtual2D[$a_Ini_Virtual2D[0][0] + 1][2]
		$i = $a_Ini_Virtual2D[0][0]
		$a_Ini_Virtual2D[$i][0] = $sSection
		Local $aKeyF[2][2] = [[1],[$sKey, $sValue]]
		$a_Ini_Virtual2D[$i][1] = $aKeyF
	Else
		Local $aKey = $a_Ini_Virtual2D[$i][1]
		Local $j = _ArraySearch($aKey, $sKey, 1, 0, 0, 2, 1, 0)
		If @error Then
			ReDim $aKey[$aKey[0][0] + 2][2]
			$aKey[0][0] += 1
			$aKey[$aKey[0][0]][0] = $sKey
			$aKey[$aKey[0][0]][1] = $sValue
		Else
			$aKey[$j][1] = $sValue
		EndIf
		$a_Ini_Virtual2D[$i][1] = $aKey
	EndIf

	Return 1
EndFunc   ;==>_IniVirtual_Write

Func _IniVirtual_WriteSection(ByRef $a_Ini_Virtual2D, $sSection, $vData, $iIndex = 1)
	Local $u = 0
	If IsArray($vData) Then
		If UBound($vData, 0) <> 2 Then Return SetError(1, 0, 0)
		$u = UBound($vData)
		If $iIndex > $u - 1 Or $iIndex < 0 Or Not StringIsDigit($iIndex) Then Return SetError(2, 0, 0)
	EndIf
	Local $i = _ArraySearch($a_Ini_Virtual2D, $sSection, 1, 0, 0, 2, 1, 0)
	If @error Then ; ≈сли секци¤ не существует, выдел¤ем ¤чеку дл¤ неЄ
		$a_Ini_Virtual2D[0][0] += 1
		ReDim $a_Ini_Virtual2D[$a_Ini_Virtual2D[0][0] + 1][2]
		$i = $a_Ini_Virtual2D[0][0] ; индекс новой ¤чейки
	EndIf
	$a_Ini_Virtual2D[$i][0] = $sSection
	If $u Then
		If $iIndex = 1 Then
			$vData[0][0] = $u - 1
		ElseIf $iIndex = 0 Then
			ReDim $vData[$u + 1][2]
			For $j = $u To 1 Step -1
				$vData[$j][0] = $vData[$j - 1][0]
				$vData[$j][1] = $vData[$j - 1][1]
			Next
			$vData[0][0] = $u
		Else
			$vData[0][0] = $u - $iIndex
			For $j = 1 To $vData[0][0]
				$vData[$j][0] = $vData[$iIndex + $j - 1][0]
				$vData[$j][1] = $vData[$iIndex + $j - 1][1]
			Next
			ReDim $vData[$j][2]
		EndIf
		$a_Ini_Virtual2D[$i][1] = $vData
	Else
		$a_Ini_Virtual2D[$i][1] = __IniVirtual_GetKeysVal(StringRegExpReplace($vData, '(*LF)(?<!\r)\n', @CRLF))
	EndIf
	Return 1
EndFunc   ;==>_IniVirtual_WriteSection

Func _IniVirtual_Delete(ByRef $a_Ini_Virtual2D, $sSection, $sKey = Default)
	Local $i = _ArraySearch($a_Ini_Virtual2D, $sSection, 1, 0, 0, 2, 1, 0)
	If @error Then Return SetError(0, 1, 1) ; отсутствие раздела/ключа не ¤вл¤етс¤ ошибкой, но устанавливаем @extended
	If $sKey = Default Then
		__IniVirtual_Delete2D($a_Ini_Virtual2D, $i)
	Else
		Local $aKey = $a_Ini_Virtual2D[$i][1]
		Local $j = _ArraySearch($aKey, $sKey, 1, 0, 0, 2, 1, 0)
		If @error Then Return SetError(0, 2, 1)
		__IniVirtual_Delete2D($aKey, $j)
		$a_Ini_Virtual2D[$i][1] = $aKey
	EndIf
	Return 1
EndFunc   ;==>_IniVirtual_Delete

Func __IniVirtual_Delete2D(ByRef $aArr2D, $ind)
	For $i = $ind To $aArr2D[0][0] - 1
		$aArr2D[$i][0] = $aArr2D[$i + 1][0]
		$aArr2D[$i][1] = $aArr2D[$i + 1][1]
	Next
	ReDim $aArr2D[$aArr2D[0][0]][2]
	$aArr2D[0][0] -= 1
EndFunc   ;==>__IniVirtual_Delete2D

Func _IniVirtual_RenameSection(ByRef $a_Ini_Virtual2D, $sSection, $sNewName, $flag = 0)
	If $sSection = $sNewName Then Return 1
	Local $i = _ArraySearch($a_Ini_Virtual2D, $sSection, 1, 0, 0, 2, 1, 0)
	If @error Then Return SetError(1, 0, 0) ; если секции дл¤ переименовани¤ не существует, то выход с @error
	Local $j = _ArraySearch($a_Ini_Virtual2D, $sNewName, 1, 0, 0, 2, 1, 0)
	If @error Then
		$a_Ini_Virtual2D[$i][0] = $sNewName ; если новый раздел не существует, то просто мен¤ем им¤ раздела
	Else
		If $flag Then
			$a_Ini_Virtual2D[$j][1] = $a_Ini_Virtual2D[$i][1] ; если перезапись, то копируем старый массив в позицию нового
			; _IniVirtual_Delete($a_Ini_Virtual2D, $sSection) ; а старый удал¤ем
			__IniVirtual_Delete2D($a_Ini_Virtual2D, $i)
		Else
			Return SetError(2, 0, 0)
		EndIf
	EndIf
	Return 1
EndFunc   ;==>_IniVirtual_RenameSection

Func _IniVirtual_ReadSection($a_Ini_Virtual2D, $sSection)
	Local $i = _ArraySearch($a_Ini_Virtual2D, $sSection, 1, 0, 0, 2, 1, 0)
	If @error Then Return SetError(1, 0, 0)
	Local $aKey = $a_Ini_Virtual2D[$i][1]
	If Not $aKey[0][0] Then SetError(1, 0, $a_Ini_Virtual2D[$i][1])
	Return $a_Ini_Virtual2D[$i][1]
EndFunc   ;==>_IniVirtual_ReadSection

Func _IniVirtual_Save($a_Ini_Virtual2D)
	Local $aKey, $sText = ''
	For $i = 1 To $a_Ini_Virtual2D[0][0]
		$sText &= '[' & $a_Ini_Virtual2D[$i][0] & ']' & @CRLF
		$aKey = $a_Ini_Virtual2D[$i][1]
		For $j = 1 To $aKey[0][0]
			$aKey[$j][1] = StringRegExpReplace($aKey[$j][1], '(*LF)^([''"]).*\1\z', '"\0"')
			; ≈сли значение содержит пробел справа или слева, то обрамл¤ем в кавычки
			If StringRegExp($aKey[$j][1], '^\h|\h\z') Then $aKey[$j][1] = '"' & $aKey[$j][1] & '"'
			$sText &= $aKey[$j][0] & '=' & $aKey[$j][1] & @CRLF
		Next
		$sText &= @CRLF
	Next
	Return StringTrimRight($sText, 2)
EndFunc   ;==>_IniVirtual_Save

Func _IniVirtual_IsDuplicateKeys($a_Ini_Virtual2D, $sSection)
	Local $i = _ArraySearch($a_Ini_Virtual2D, $sSection, 1, 0, 0, 2, 1, 0)
	If @error Then Return SetError(1, 0, 0)
	Local $aKey = $a_Ini_Virtual2D[$i][1]
	Local $sRes = _IniVirtual_IsDuplicateSection($aKey)
	Return SetError(@error, 0, $sRes)
EndFunc   ;==>_IniVirtual_IsDuplicateKeys

Func _IniVirtual_IsDuplicateSection($aArr2D)
	Local $s = Chr(1)
	Assign($s, 1, 1)
	For $i = 1 To $aArr2D[0][0]
		If IsDeclared($aArr2D[$i][0] & $s) Then
			If $aArr2D[$i][0] == '' Then Return SetError(1, 0, True) ; присутсвтует пустое им¤ секции
			Return SetError(2, 0, $aArr2D[$i][0]) ; присутсвтует дубликат секции
		Else
			Assign($aArr2D[$i][0] & $s, 1, 1)
		EndIf
	Next
	Return False
EndFunc   ;==>_IniVirtual_IsDuplicateSection