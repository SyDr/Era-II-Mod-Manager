; Author:         Aliaksei SyDr Karalenka

#AutoIt3Wrapper_Version=Beta
#include-once
#include "include_fwd.au3"
#include "lng.au3"
#include "utils.au3"

Global $MM_SETTINGS_CACHE, $MM_SETTINGS_INIT = False

Func Settings_Save()
	If Not $MM_SETTINGS_INIT Then __Settings_Init()
	FileDelete($MM_SETTINGS_PATH)
	FileWrite($MM_SETTINGS_PATH, Jsmn_Encode($MM_SETTINGS_CACHE, $JSMN_PRETTY_PRINT + $JSMN_UNESCAPED_UNICODE))
EndFunc

Func __Settings_Validate()
	Local $aItems, $i
	If Not IsMap($MM_SETTINGS_CACHE) Then $MM_SETTINGS_CACHE = MapEmpty()
	If Not MapExists($MM_SETTINGS_CACHE, "version") Or Not IsString($MM_SETTINGS_CACHE["version"]) Then $MM_SETTINGS_CACHE["version"] = $MM_VERSION_NUMBER
	If Not MapExists($MM_SETTINGS_CACHE, "language") Or Not IsString($MM_SETTINGS_CACHE["language"]) Then $MM_SETTINGS_CACHE["language"] = "english.json"
	If Not MapExists($MM_SETTINGS_CACHE, "window") Or Not IsMap($MM_SETTINGS_CACHE["window"]) Then $MM_SETTINGS_CACHE["window"] = MapEmpty()
	If Not MapExists($MM_SETTINGS_CACHE["window"], "width") Or Not IsInt($MM_SETTINGS_CACHE["window"]["width"]) Or _
		$MM_SETTINGS_CACHE["window"]["width"] < $MM_WINDOW_MIN_WIDTH Then $MM_SETTINGS_CACHE["window"]["width"] = $MM_WINDOW_MIN_WIDTH
	If Not MapExists($MM_SETTINGS_CACHE["window"], "height") Or Not IsInt($MM_SETTINGS_CACHE["window"]["height"]) Or _
		$MM_SETTINGS_CACHE["window"]["height"] < $MM_WINDOW_MIN_HEIGHT Then $MM_SETTINGS_CACHE["window"]["height"] = $MM_WINDOW_MIN_HEIGHT
	If Not MapExists($MM_SETTINGS_CACHE["window"], "maximized") Or Not IsBool($MM_SETTINGS_CACHE["window"]["maximized"]) Then $MM_SETTINGS_CACHE["window"]["maximized"] = False
	If Not MapExists($MM_SETTINGS_CACHE, "game") Or Not IsMap($MM_SETTINGS_CACHE["game"]) Then $MM_SETTINGS_CACHE["game"] = MapEmpty()
	If Not $MM_PORTABLE Then
		If Not MapExists($MM_SETTINGS_CACHE["game"], "selected") Or Not IsString($MM_SETTINGS_CACHE["game"]["selected"]) Then $MM_SETTINGS_CACHE["game"]["selected"] = ""
		If Not MapExists($MM_SETTINGS_CACHE["game"], "items") Or Not IsMap($MM_SETTINGS_CACHE["game"]["items"]) Then $MM_SETTINGS_CACHE["game"]["items"] = MapEmpty()

		$aItems = MapKeys($MM_SETTINGS_CACHE["game"]["items"])
		For $sItem In $aItems
			If Not IsMap($MM_SETTINGS_CACHE["game"]["items"][$sItem]) Then $MM_SETTINGS_CACHE["game"]["items"][$sItem] = MapEmpty()
			If Not MapExists($MM_SETTINGS_CACHE["game"]["items"][$sItem], "exe") Or Not IsString($MM_SETTINGS_CACHE["game"]["items"][$sItem]["exe"]) Then $MM_SETTINGS_CACHE["game"]["items"][$sItem]["exe"] = ""
		Next

		Local $sSelected = $MM_SETTINGS_CACHE["game"]["selected"]
		If $MM_SETTINGS_CACHE["game"]["selected"] <> "" Then
			If Not IsMap($MM_SETTINGS_CACHE["game"]["items"][$sSelected]) Then $MM_SETTINGS_CACHE["game"]["items"][$sSelected] = MapEmpty()
			If Not MapExists($MM_SETTINGS_CACHE["game"]["items"][$sSelected], "exe") Or Not IsString($MM_SETTINGS_CACHE["game"]["items"][$sSelected]["exe"]) Then $MM_SETTINGS_CACHE["game"]["items"][$sSelected]["exe"] = ""
		EndIf
	Else
		If Not MapExists($MM_SETTINGS_CACHE["game"], "exe") Or Not IsString($MM_SETTINGS_CACHE["game"]["exe"]) Then $MM_SETTINGS_CACHE["game"]["exe"] = ""
	EndIf

	; 0.90.4.2
	If Not MapExists($MM_SETTINGS_CACHE["game"], "blacklist") Or Not IsArray($MM_SETTINGS_CACHE["game"]["blacklist"]) Then
		$aItems = StringSplit(".*?cmp.*?###.*?map.*?###.*?back.*?###.*?int.*?###.*?upd.*?###.*?unin.*?", "###", $STR_ENTIRESPLIT + $STR_NOCOUNT)
		$MM_SETTINGS_CACHE["game"]["blacklist"] = $aItems
	Else
		$aItems = $MM_SETTINGS_CACHE["game"]["blacklist"]
	EndIf

	$i = 0
	While $i < UBound($aItems) - 1
		If Not IsString($aItems[$i]) Or $aItems[$i] = "" Then _ArrayDelete($aItems, $i)
		$i += 1
	WEnd
	$MM_SETTINGS_CACHE["game"]["blacklist"] = $aItems

	; 0.91.5.0
	If Not MapExists($MM_SETTINGS_CACHE, "update") Or Not IsMap($MM_SETTINGS_CACHE["update"]) Then $MM_SETTINGS_CACHE["update"] = MapEmpty()
	If Not MapExists($MM_SETTINGS_CACHE["update"], "interval") Or Not IsInt($MM_SETTINGS_CACHE["update"]["interval"]) Then $MM_SETTINGS_CACHE["update"]["interval"] = 28
	If Not $MM_PORTABLE Then
		If Not MapExists($MM_SETTINGS_CACHE["update"], "auto") Or Not IsBool($MM_SETTINGS_CACHE["update"]["auto"]) Then $MM_SETTINGS_CACHE["update"]["auto"] = False
	EndIf
	If Not MapExists($MM_SETTINGS_CACHE["update"], "last_check") Or Not IsString($MM_SETTINGS_CACHE["update"]["last_check"]) Or _
		Not _DateIsValid($MM_SETTINGS_CACHE["update"]["last_check"]) Then $MM_SETTINGS_CACHE["update"]["last_check"] = _NowCalc()

	; 0.93.0.0
	If Not MapExists($MM_SETTINGS_CACHE, "list") Or Not IsMap($MM_SETTINGS_CACHE["list"]) Then $MM_SETTINGS_CACHE["list"] = MapEmpty()
	If Not MapExists($MM_SETTINGS_CACHE["list"], "not_again") Or Not IsBool($MM_SETTINGS_CACHE["list"]["not_again"]) Then $MM_SETTINGS_CACHE["list"]["not_again"] = False
	If Not MapExists($MM_SETTINGS_CACHE["list"], "exe") Or Not IsBool($MM_SETTINGS_CACHE["list"]["exe"]) Then $MM_SETTINGS_CACHE["list"]["exe"] = False
	If Not MapExists($MM_SETTINGS_CACHE["list"], "wog_settings") Or Not IsBool($MM_SETTINGS_CACHE["list"]["wog_settings"]) Then $MM_SETTINGS_CACHE["list"]["wog_settings"] = False
	If Not MapExists($MM_SETTINGS_CACHE["list"], "only_load") Or Not IsBool($MM_SETTINGS_CACHE["list"]["only_load"]) Then $MM_SETTINGS_CACHE["list"]["only_load"] = False

	If VersionCompare($MM_SETTINGS_CACHE["version"], $MM_VERSION_NUMBER) < 0 Then $MM_SETTINGS_CACHE["version"] = $MM_VERSION_NUMBER
EndFunc

Func Settings_Get(Const ByRef $sName)
	If Not $MM_SETTINGS_INIT Then __Settings_Init()

	Local $vReturn

	Switch $sName
		Case "language", "version"
			$vReturn = $MM_SETTINGS_CACHE[StringLower($sName)]
		Case "width", "height", "maximized"
			$vReturn = $MM_SETTINGS_CACHE["window"][StringLower($sName)]
		Case "path"
			$vReturn = $MM_PORTABLE ? $MM_GAME_DIR : $MM_SETTINGS_CACHE["game"]["selected"]
		Case "exe"
			$vReturn = $MM_PORTABLE ? $MM_SETTINGS_CACHE["game"]["exe"] : ($MM_SETTINGS_CACHE["game"]["exe"] ? $MM_SETTINGS_CACHE["game"]["items"][$MM_SETTINGS_CACHE["game"]["exe"]]["exe"] : "")
			If Not $vReturn And FileExists(Settings_Get("path") & "\h3era.exe") Then $vReturn = "h3era.exe"
		Case "game.blacklist"
			$vReturn = $MM_SETTINGS_CACHE["game"]["blacklist"]
		Case "available_path_list"
			$vReturn = MapKeys($MM_SETTINGS_CACHE["game"]["items"])
		Case "update_interval"
			$vReturn = $MM_SETTINGS_CACHE["update"]["interval"]
		Case "update_auto"
			$vReturn = Not $MM_PORTABLE ? $MM_SETTINGS_CACHE["update"]["auto"] : False
		Case "update_last_check"
			$vReturn = $MM_SETTINGS_CACHE["update"]["last_check"]
		Case "list_no_ask"
			$vReturn = $MM_SETTINGS_CACHE["list"]["not_again"]
		Case "list_exe"
			$vReturn = $MM_SETTINGS_CACHE["list"]["exe"]
		Case "list_wog_settings"
			$vReturn = $MM_SETTINGS_CACHE["list"]["wog_settings"]
		Case "list_only_load"
			$vReturn = $MM_SETTINGS_CACHE["list"]["only_load"]
	EndSwitch

	Return $vReturn
EndFunc   ;==>Settings_Get

Func Settings_Set(Const ByRef $sName, Const $vValue)
	If Not $MM_SETTINGS_INIT Then __Settings_Init()

	Switch $sName
		Case "language"
			$MM_SETTINGS_CACHE["language"] = $vValue
			$MM_SETTINGS_LANGUAGE = $vValue
		Case "version"
			$MM_SETTINGS_CACHE[StringLower($sName)] = $vValue
		Case "width", "height", "maximized"
			$MM_SETTINGS_CACHE["window"][StringLower($sName)] = $vValue
		Case "path"
			$MM_SETTINGS_CACHE["game"]["selected"] = $vValue
			__Settings_Validate()
		Case "exe"
			If Not $MM_PORTABLE Then
				Local $sSelected = $MM_SETTINGS_CACHE["game"]["selected"]
				$MM_SETTINGS_CACHE["game"]["items"][$sSelected]["exe"] = $vValue
			Else
				$MM_SETTINGS_CACHE["game"]["exe"] = $vValue
			EndIf
		Case "update_interval"
			$MM_SETTINGS_CACHE["update"]["interval"] = $vValue
		Case "update_auto"
			If Not $MM_PORTABLE Then $MM_SETTINGS_CACHE["update"]["auto"] = $vValue
		Case "update_last_check"
			$MM_SETTINGS_CACHE["update"]["last_check"] = $vValue
		Case "list_no_ask"
			$MM_SETTINGS_CACHE["list"]["not_again"] = $vValue
		Case "list_exe"
			$MM_SETTINGS_CACHE["list"]["exe"] = $vValue
		Case "list_wog_settings"
			$MM_SETTINGS_CACHE["list"]["wog_settings"] = $vValue
		Case "list_only_load"
			$MM_SETTINGS_CACHE["list"]["only_load"] = $vValue
	EndSwitch
EndFunc   ;==>Settings_Set

Func __Settings_Init()
	$MM_SETTINGS_INIT = True
	__Settings_Load()
EndFunc

Func __Settings_Load()
	$MM_SETTINGS_CACHE = Jsmn_Decode(FileRead($MM_SETTINGS_PATH))
	__Settings_Validate()

	$MM_SETTINGS_LANGUAGE = $MM_SETTINGS_CACHE["language"]

	If Not $MM_PORTABLE Then
		$MM_GAME_DIR = Settings_Get("path")
		$MM_GAME_NO_DIR = $MM_GAME_DIR = ""
		If Not $MM_GAME_NO_DIR Then
			$MM_LIST_DIR_PATH = $MM_GAME_DIR & "\Mods"
			$MM_LIST_FILE_PATH = $MM_LIST_DIR_PATH & "\list.txt"
		EndIf
	EndIf

	$MM_GAME_EXE = Settings_Get("exe")
EndFunc