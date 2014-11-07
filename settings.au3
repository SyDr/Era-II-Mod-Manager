; Author:         Aliaksei SyDr Karalenka

#AutoIt3Wrapper_Version=Beta
#include-once
#include "include_fwd.au3"
#include "lng.au3"
#include "utils.au3"

Global $MM_SETTINGS_CACHE

Func Settings_Load(Const $bForceAppData = False)
	$MM_SETTINGS_CACHE = Jsmn_Decode(FileRead($MM_SETTINGS_PATH))
	__Settings_Validate()
	If $bForceAppData Then $MM_SETTINGS_CACHE["portable"] = False
	If Not $MM_SETTINGS_CACHE["portable"] And Not $bForceAppData Then
		$MM_SETTINGS_PATH = @AppDataCommonDir & "\RAMM\settings.json"
		Return Settings_Load(True)
	EndIf

	$MM_SETTINGS_LANGUAGE = Settings_Get("language")
	$MM_GAME_EXE = Settings_Get("exe")
EndFunc

Func Settings_Save()
	FileDelete($MM_SETTINGS_PATH)
	FileWrite($MM_SETTINGS_PATH, Jsmn_Encode($MM_SETTINGS_CACHE, $JSMN_PRETTY_PRINT + $JSMN_UNESCAPED_UNICODE))
EndFunc

Func __Settings_Validate()
	If Not IsMap($MM_SETTINGS_CACHE) Then $MM_SETTINGS_CACHE = MapEmpty()
	If Not MapExists($MM_SETTINGS_CACHE, "version") Or Not IsString($MM_SETTINGS_CACHE["version"]) Then $MM_SETTINGS_CACHE["version"] = $MM_VERSION_NUMBER
	If Not MapExists($MM_SETTINGS_CACHE, "portable") Or Not IsBool($MM_SETTINGS_CACHE["portable"]) Then $MM_SETTINGS_CACHE["portable"] = False
	If Not MapExists($MM_SETTINGS_CACHE, "language") Or Not IsString($MM_SETTINGS_CACHE["language"]) Then $MM_SETTINGS_CACHE["language"] = "english.json"
	If Not MapExists($MM_SETTINGS_CACHE, "window") Or Not IsMap($MM_SETTINGS_CACHE["window"]) Then $MM_SETTINGS_CACHE["window"] = MapEmpty()
	If Not MapExists($MM_SETTINGS_CACHE["window"], "width") Or Not IsInt($MM_SETTINGS_CACHE["window"]["width"]) Or _
		$MM_SETTINGS_CACHE["window"]["width"] < $MM_WINDOW_MIN_WIDTH Then $MM_SETTINGS_CACHE["window"]["width"] = $MM_WINDOW_MIN_WIDTH
	If Not MapExists($MM_SETTINGS_CACHE["window"], "height") Or Not IsInt($MM_SETTINGS_CACHE["window"]["height"]) Or _
		$MM_SETTINGS_CACHE["window"]["height"] < $MM_WINDOW_MIN_HEIGHT Then $MM_SETTINGS_CACHE["window"]["height"] = $MM_WINDOW_MIN_HEIGHT
	If Not MapExists($MM_SETTINGS_CACHE["window"], "maximized") Or Not IsBool($MM_SETTINGS_CACHE["window"]["maximized"]) Then $MM_SETTINGS_CACHE["window"]["maximized"] = False
	If Not MapExists($MM_SETTINGS_CACHE, "game") Or Not IsMap($MM_SETTINGS_CACHE["game"]) Then $MM_SETTINGS_CACHE["game"] = MapEmpty()
	If Not $MM_SETTINGS_CACHE["portable"] Then
		If Not MapExists($MM_SETTINGS_CACHE["game"], "selected") Or Not IsString($MM_SETTINGS_CACHE["game"]["selected"]) Then $MM_SETTINGS_CACHE["game"]["selected"] = ""
		If Not MapExists($MM_SETTINGS_CACHE["game"], "items") Or Not IsMap($MM_SETTINGS_CACHE["game"]["items"]) Then $MM_SETTINGS_CACHE["game"]["items"] = MapEmpty()

		Local $aItems = MapKeys($MM_SETTINGS_CACHE["game"]["items"])
		For $sItem In $aItems
			If Not IsMap($MM_SETTINGS_CACHE["game"]["items"][$sItem]) Then $MM_SETTINGS_CACHE["game"]["items"][$sItem] = MapEmpty()
			If Not MapExists($MM_SETTINGS_CACHE["game"]["items"][$sItem], "exe") Or Not IsString($MM_SETTINGS_CACHE["game"]["items"][$sItem]["exe"]) Then $MM_SETTINGS_CACHE["game"]["items"][$sItem]["exe"] = "h3era.exe"
		Next

		Local $sSelected = $MM_SETTINGS_CACHE["game"]["selected"]
		If $MM_SETTINGS_CACHE["game"]["selected"] <> "" Then
			If Not IsMap($MM_SETTINGS_CACHE["game"]["items"][$sSelected]) Then $MM_SETTINGS_CACHE["game"]["items"][$sSelected] = MapEmpty()
			If Not MapExists($MM_SETTINGS_CACHE["game"]["items"][$sSelected], "exe") Or Not IsString($MM_SETTINGS_CACHE["game"]["items"][$sSelected]["exe"]) Then $MM_SETTINGS_CACHE["game"]["items"][$sSelected]["exe"] = "h3era.exe"
		EndIf
	Else
		If Not MapExists($MM_SETTINGS_CACHE["game"], "exe") Or Not IsString($MM_SETTINGS_CACHE["game"]["exe"]) Then $MM_SETTINGS_CACHE["game"]["exe"] = "h3era.exe"
	EndIf

	If VersionCompare($MM_SETTINGS_CACHE["version"], $MM_VERSION_NUMBER) < 0 Then $MM_SETTINGS_CACHE["version"] = $MM_VERSION_NUMBER
EndFunc

Func Settings_Get(Const ByRef $sName)
	If Not IsMap($MM_SETTINGS_CACHE) Then Settings_Load()

	Switch $sName
		Case "language", "portable", "version"
			Return $MM_SETTINGS_CACHE[StringLower($sName)]
		Case "width", "height", "maximized"
			Return $MM_SETTINGS_CACHE["window"][StringLower($sName)]
		Case "path"
			Return Settings_Get("portable") ? _PathFull(@ScriptDir & "\..\..") : $MM_SETTINGS_CACHE["game"]["selected"]
		Case "exe"
			Return Settings_Get("portable") ? $MM_SETTINGS_CACHE["game"]["exe"] : $MM_SETTINGS_CACHE["game"]["items"][$MM_SETTINGS_CACHE["game"]["selected"]]["exe"]
	EndSwitch
EndFunc   ;==>Settings_Get

Func Settings_Set(Const ByRef $sName, Const ByRef $vValue)
	Switch $sName
		Case "language", "portable", "version"
			$MM_SETTINGS_CACHE[StringLower($sName)] = $vValue
		Case "width", "height", "maximized"
			$MM_SETTINGS_CACHE["window"][StringLower($sName)] = $vValue
		Case "path"
			$MM_SETTINGS_CACHE["game"]["selected"] = $vValue
			__Settings_Validate()
		Case "exe"
			If Not Settings_Get("portable") Then
				$MM_SETTINGS_CACHE["game"]["items"][$MM_SETTINGS_CACHE["game"]["selected"]]["exe"] = $vValue
			Else
				$MM_SETTINGS_CACHE["game"]["exe"] = $vValue
			EndIf
	EndSwitch
EndFunc   ;==>Settings_Set

Func Settings_DefineWorkDir()
	If Not Settings_Get("portable") Then
		$MM_SETTINGS_PATH = @AppDataCommonDir & "\RAMM\settings.json"
		FileClose(FileOpen($MM_SETTINGS_PATH, $FO_APPEND + $FO_CREATEPATH))
	EndIf

	If Settings_Get("path") = "" Then
		$MM_SETTINGS_LANGUAGE = Settings_Get("Language")
		Setting_AskForGameDir(True)
	Else
		$MM_GAME_DIR = Settings_Get("path")
		$MM_LIST_DIR_PATH = $MM_GAME_DIR & "\Mods"
		$MM_LIST_FILE_PATH = $MM_LIST_DIR_PATH & "\list.txt"
	EndIf
EndFunc

Func Setting_AskForGameDir($bExitOnCancel = False, $hParent = Default)
	Local $sPath = FileSelectFolder(Lng_Get("settings.game_dir.caption"), "", Default, Settings_Get("path"), $hParent)
	If @error Then
		If $bExitOnCancel Then Exit
		Return False
	Else
		$MM_GAME_DIR = $sPath
		Settings_Set("path", $sPath)
		$MM_LIST_DIR_PATH = $MM_GAME_DIR & "\Mods"
		$MM_LIST_FILE_PATH = $MM_LIST_DIR_PATH & "\list.txt"
		$MM_GAME_EXE = Settings_Get("exe")
	EndIf

	Return True
EndFunc

