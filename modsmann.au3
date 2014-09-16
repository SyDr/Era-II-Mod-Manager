#NoTrayIcon
#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=icons\preferences-system.ico
#AutoIt3Wrapper_Outfile=modsmann.exe
#AutoIt3Wrapper_Compression=4
#AutoIt3Wrapper_UseUpx=y
#AutoIt3Wrapper_Res_requestedExecutionLevel=asInvoker
#AutoIt3Wrapper_AU3Check_Parameters=-d -w 1 -w 2 -w 3 -w 4 -w 5 -w 6 -w 7
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
; Author:         Aliaksei SyDr Karalenka

#include <Array.au3>
#include <ButtonConstants.au3>
#include <ComboConstants.au3>
#include <Constants.au3>
#include <Date.au3>
#include <EditConstants.au3>
#include <File.au3>
#include <GUIConstantsEx.au3>
#include <GuiDateTimePicker.au3>
#include <GuiImageList.au3>
#include <GuiMenu.au3>
#include <GuiTreeView.au3>
#include <StaticConstants.au3>
#include <TreeViewConstants.au3>
#include <WinAPI.au3>
#include <WindowsConstants.au3>

#include "folder_mods.au3"
#include "lng.au3"
#include "packed_mods.au3"
#include "plugins.au3"
#include "settings.au3"
#include "startup.au3"
#include "utils.au3"

AutoItSetOption("MustDeclareVars", 1)
AutoItSetOption("GUIOnEventMode", 1)
AutoItSetOption("GUICloseOnESC", 1)

#Region Variables
Global $hFormMain, $hTreeView
Global $auTreeView, $abModCompatibilityMap
Global $bGUINeedUpdate = False

Global $hGroupModList, $hGroupPresets, $hGroupGame, $hGroupModInfo, $hSettings, $hButtonChangeLanguage, $hChangeLanguageContextMenuID
Global $aLanguages[1][2]
Global $hModMoveUp, $hModMoveDown, $hModEnableDisable, $hModDelete, $hModAdd, $hModCompatibility
Global $hButtonPlugins, $hModWebsite, $hModOpenFolder, $hMoreActionsContextMenuID, $hButtonMoreActions
Global $hModReadmeC, $hModInfoC
Global $hLabelPreset, $hPreset, $hPresetSave, $hPresetLoad, $hPresetDelete
Global $hLabelExe, $hComboExe, $hButtonRun, $hButtonCSC
Global $hLabelWO, $hComboWO
Global $hModInfo
Global $sFollowMod = ""
Global $sCompatibilityMessage = ""
Global $hDummyF5
Global $bEnableDisable
Global $bInTrack = False
#EndRegion Variables

If @Compiled And @ScriptName = "installmod.exe" Then
	StartUp_WorkAsInstallmod()
EndIf

If $CMDLine[0] > 0 And $CMDLine[1] = '/assocdel' Then
	StartUp_Assoc_Delete()
EndIf

$MM_SETTINGS_LANGUAGE = Settings_Get("Language")

If $CMDLine[0] > 0 Then
	If Not SD_CLI_Mod_Add() Then Exit
EndIf

StartUp_CheckRunningInstance(StringFormat(Lng_Get("main.title"), $MM_VERSION))

Global $bSyncPresetWithWS = Settings_Get("SyncPresetWithWS")
Global $bDisplayVersion = Settings_Get("DisplayVersion")

SD_GUI_LoadSize()
SD_GUI_Create()

Global $aWindowSize, $sNewDate

While 1
	Sleep(50)
	If Not $bGUINeedUpdate And Not WinActive($hFormMain) Then
		$bGUINeedUpdate = True
	EndIf

	If $bGUINeedUpdate And WinActive($hFormMain) Then
		$bGUINeedUpdate = False
		If Not Mod_ListIsActual() Then SD_GUI_Update()
	EndIf

	If $bEnableDisable Then
		$bEnableDisable = False
		SD_GUI_Mod_EnableDisable()
	EndIf
WEnd

Func SD_GUI_Language_Change()
	Local $iIndex = -1
	For $iCount = 1 To $aLanguages[0][0]
		If @GUI_CtrlId = $aLanguages[$iCount][0] Then
			$iIndex = $iCount
			ExitLoop
		EndIf
	Next

	If $iIndex = -1 Then Return False
	$MM_SETTINGS_LANGUAGE = $aLanguages[$iIndex][1]

	Local $sIsLoaded = Lng_Load()
	If @error Then
		MsgBox(64 + 4096, "", $sIsLoaded, Default, $hFormMain)
	Else
		Settings_Set("Language", $MM_SETTINGS_LANGUAGE)
	EndIf

	SD_GUI_SetLng()
	SD_GUI_Update()
EndFunc   ;==>SD_GUI_Language_Change

Func SD_GUI_Create()
	$hFormMain = GUICreate(StringFormat(Lng_Get("main.title"), $MM_VERSION), $MM_WINDOW_MIN_WIDTH, $MM_WINDOW_MIN_HEIGHT - 20, Default, Default, BitOR($GUI_SS_DEFAULT_GUI, $WS_SIZEBOX, $WS_MAXIMIZEBOX), $WS_EX_ACCEPTFILES)
	GUISwitch($hFormMain)
	$hGroupModList = GUICtrlCreateGroup("Mod load order control", 8, 8, 473, 441)
;~ 	$hTreeView = 	GUICtrlCreateTreeView(16, 24, 361, 417, BitOR($TVS_HASBUTTONS, $TVS_HASLINES, $TVS_DISABLEDRAGDROP, $TVS_SHOWSELALWAYS), $WS_EX_CLIENTEDGE)
	TreeViewMain()
	$hModMoveUp = GUICtrlCreateButton("Up", 384, 24, 89, 25)
	$hModMoveDown = GUICtrlCreateButton("Down", 384, 56, 89, 25)
	$hModEnableDisable = GUICtrlCreateButton("Enable/Disable", 384, 88, 89, 25)
	GUICtrlSetData($hModEnableDisable, Lng_Get("group.modlist.disable"))

	$hButtonMoreActions = GUICtrlCreateButton("More actions", 384, 152, 89, 25)
	Local $hMoreActionsDummy = GUICtrlCreateDummy()
	$hDummyF5 = GUICtrlCreateDummy()
	$hMoreActionsContextMenuID = GUICtrlCreateContextMenu($hMoreActionsDummy)
	$hButtonPlugins = GUICtrlCreateMenuItem("Plugins", $hMoreActionsDummy)
	$hModWebsite = GUICtrlCreateMenuItem("Website", $hMoreActionsDummy)
	$hModCompatibility = GUICtrlCreateMenuItem("Compatibility", $hMoreActionsDummy)
	GUICtrlSetState($hModCompatibility, $sCompatibilityMessage <> "" ? $GUI_ENABLE : $GUI_DISABLE)
	$hModDelete = GUICtrlCreateMenuItem("Delete", $hMoreActionsDummy)
	GUICtrlCreateMenuItem("", $hMoreActionsDummy)
	$hModOpenFolder = GUICtrlCreateMenuItem("Open Folder", $hMoreActionsDummy)
	$hModInfoC = GUICtrlCreateMenuItem("mod_info.ini", $hMoreActionsDummy)
	$hModReadmeC = GUICtrlCreateMenuItem("Create Readme", $hMoreActionsDummy)
	GUICtrlCreateGroup("", -99, -99, 1, 1)

	$hModAdd = GUICtrlCreateButton("Add new", 384, 455 - 32 - 8 - 32, 89, 25)
	$hSettings = GUICtrlCreateButton("Settings", 384, 455 - 32 - 8, 89, 25)
	$hGroupPresets = GUICtrlCreateGroup("Presets", 488, 8, 308, 73)
	$hLabelPreset = GUICtrlCreateLabel("Current preset:", 496, 25, 97, 17)
	$hPreset = GUICtrlCreateInput("None", 600, 24, 193, 21, BitOR($GUI_SS_DEFAULT_INPUT, $ES_READONLY))
	$hPresetSave = GUICtrlCreateButton("Save", 496, 48, 97, 25)
	$hPresetLoad = GUICtrlCreateButton("Load", 600, 48, 97, 25)
	$hPresetDelete = GUICtrlCreateButton("Delete", 704, 48, 89, 25)
	GUICtrlCreateGroup("", -99, -99, 1, 1)
	$hGroupGame = GUICtrlCreateGroup("Game", 488, 84, 308, 80 + 32)
	$hLabelExe = GUICtrlCreateLabel("Game exe", 496, 108, 100, 17)
	$hComboExe = GUICtrlCreateCombo("h3era.exe", 608, 104, 169, 21)
	SD_GUI_FillComboExe(@ScriptDir & "\..\..", $hComboExe, Settings_Get("Exe"))
	$hLabelWO = GUICtrlCreateLabel("WoG options", 496, 130, 100, 17)
	$hComboWO = GUICtrlCreateCombo("settings.dat", 608, 130, 169, 21)
	SD_GUI_FillComboWo(@ScriptDir & "\..\..", $hComboWO, IniRead(@ScriptDir & "\..\..\wog.ini", "WoGification", "Options_File_Name", "settings.dat"))
	$hButtonRun = GUICtrlCreateButton("Run game", 496, 155, 140, 25)
	$hButtonCSC = GUICtrlCreateButton("Create shortcut", 496 + 160, 155, 136, 25)
	GUICtrlSetState($hButtonCSC, $GUI_DISABLE)
	GUICtrlCreateGroup("", -99, -99, 1, 1)
	$hGroupModInfo = GUICtrlCreateGroup("Mod info", 488, 180 + 15, 308, 250 - 32)
	$hModInfo = GUICtrlCreateEdit("", 496, 178 + 32, 294, 230 - 32, $ES_READONLY + $ES_AUTOVSCROLL + $WS_VSCROLL)
	GUICtrlCreateGroup("", -99, -99, 1, 1)
	$hButtonChangeLanguage = GUICtrlCreateButton("Language", 800 - 161 - 4, 420, 161, 25)
	Local $hChangeLanguageDummy = GUICtrlCreateDummy()
	$hChangeLanguageContextMenuID = GUICtrlCreateContextMenu($hChangeLanguageDummy)
	Local $asTemp = _FileListToArray(@ScriptDir & "\lng\", "*.ini", 1)

	For $iCount = 1 To $asTemp[0]
		$aLanguages[0][0] += 1
		ReDim $aLanguages[$aLanguages[0][0] + 1][2]
		$aLanguages[$iCount][0] = GUICtrlCreateMenuItem(IniRead(@ScriptDir & "\lng\" & $asTemp[$iCount], "lang.info", "lang.name", "Remove, please " & $asTemp[$iCount]), $hChangeLanguageDummy)
		$aLanguages[$iCount][1] = $asTemp[$iCount]
	Next

	SD_GUI_Mod_Controls_Disable()
	SD_GUI_SetResizing()
	SD_GUI_Events_Register()
	SD_GUI_SetLng()
	TreeViewTryFollow("")
	WinMove($hFormMain, '', (@DesktopWidth - $MM_WINDOW_WIDTH) / 2, (@DesktopHeight - $MM_WINDOW_HEIGHT) / 2, $MM_WINDOW_WIDTH, $MM_WINDOW_HEIGHT)
	If $MM_WINDOW_MAXIMIZED Then WinSetState($hFormMain, '', @SW_MAXIMIZE)
	Local $AccelKeys[1][2] = [["{F5}", $hDummyF5]]
	GUISetAccelerators($AccelKeys)
	GUISetState(@SW_SHOW)
EndFunc   ;==>SD_GUI_Create

Func SD_GUI_SetResizing()
	GUICtrlSetResizing($hTreeView, 2 + 32 + 64 + 256)
	GUICtrlSetResizing($hGroupModList, 2 + 32 + 64 + 256)
	GUICtrlSetResizing($hModMoveUp, 802)
	GUICtrlSetResizing($hModMoveDown, 802)
	GUICtrlSetResizing($hModEnableDisable, 802)
	GUICtrlSetResizing($hModCompatibility, 802)
	GUICtrlSetResizing($hButtonMoreActions, 802)
	GUICtrlSetResizing($hModAdd, 2 + 64 + 256 + 512)
	GUICtrlSetResizing($hModOpenFolder, 802)
	GUICtrlSetResizing($hModInfoC, 802)
	GUICtrlSetResizing($hModReadmeC, 802)
	GUICtrlSetResizing($hGroupPresets, 4 + 32 + 256 + 512)
	GUICtrlSetResizing($hLabelPreset, 4 + 32 + 256 + 512)
	GUICtrlSetResizing($hPreset, 4 + 32 + 256 + 512)
	GUICtrlSetResizing($hSettings, 2 + 64 + 256 + 512)
	GUICtrlSetResizing($hPresetSave, 4 + 32 + 256 + 512)
	GUICtrlSetResizing($hPresetLoad, 4 + 32 + 256 + 512)
	GUICtrlSetResizing($hPresetDelete, 4 + 32 + 256 + 512)
	GUICtrlSetResizing($hGroupGame, 4 + 32 + 256 + 512)
	GUICtrlSetResizing($hLabelExe, 4 + 32 + 256 + 512)
	GUICtrlSetResizing($hComboExe, 4 + 32 + 256 + 512)
	GUICtrlSetResizing($hLabelWO, 4 + 32 + 256 + 512)
	GUICtrlSetResizing($hComboWO, 4 + 32 + 256 + 512)
	GUICtrlSetResizing($hButtonRun, 4 + 32 + 256 + 512)
	GUICtrlSetResizing($hButtonCSC, 4 + 32 + 256 + 512)
	GUICtrlSetResizing($hGroupModInfo, 2 + 4 + 32 + 64)
	GUICtrlSetResizing($hModInfo, 2 + 4 + 32 + 64)
	GUICtrlSetResizing($hButtonChangeLanguage, 4 + 64 + 256 + 512)
EndFunc   ;==>SD_GUI_SetResizing


Func SD_GUI_Events_Register()
	GUISetOnEvent($GUI_EVENT_CLOSE, "SD_GUI_Close")
	GUIRegisterMsg($WM_GETMINMAXINFO, "WM_GETMINMAXINFO") ; Limit min size
	GUIRegisterMsg($WM_DROPFILES, "SD_GUI_Mod_AddByDnD") ; Input files
	GUIRegisterMsg($WM_NOTIFY, "WM_NOTIFY") ; DblClick in TreeView
	GUICtrlSetOnEvent($hModMoveUp, "SD_GUI_Mod_Move_Up")
	GUICtrlSetOnEvent($hModMoveDown, "SD_GUI_Mod_Move_Down")
	GUICtrlSetOnEvent($hModEnableDisable, "SD_GUI_Mod_EnableDisable")
	GUICtrlSetOnEvent($hModCompatibility, "SD_GUI_Mod_Compatibility")
	GUICtrlSetOnEvent($hButtonMoreActions, "SD_GUI_MoreActionsPopup")
	GUICtrlSetOnEvent($hButtonPlugins, "SD_GUI_Manage_Plugins")
	GUICtrlSetOnEvent($hModWebsite, "SD_GUI_Mod_Website")
	GUICtrlSetOnEvent($hModDelete, "SD_GUI_Mod_Delete")
	GUICtrlSetOnEvent($hModAdd, "SD_GUI_Mod_Add")
	GUICtrlSetOnEvent($hModOpenFolder, "SD_GUI_Mod_OpenFolder")
	GUICtrlSetOnEvent($hModInfoC, "SD_GUI_Mod_CreateModifyModInfo")
	GUICtrlSetOnEvent($hModReadmeC, "SD_GUI_Mod_CreateModifyReadme")
	GUICtrlSetOnEvent($hSettings, "SD_GUI_Settings")
	GUICtrlSetOnEvent($hPresetSave, "SD_GUI_Preset_Save")
	GUICtrlSetOnEvent($hPresetLoad, "SD_GUI_Preset_Load")
	GUICtrlSetOnEvent($hPresetDelete, "SD_GUI_Preset_Delete")
	GUICtrlSetOnEvent($hComboExe, "SD_GUI_Game_Exe_Change")
	GUICtrlSetOnEvent($hComboWO, "SD_GUI_Game_Wo_Change")
	GUICtrlSetOnEvent($hButtonRun, "SD_GUI_Game_Exe_Run")
	GUICtrlSetOnEvent($hButtonCSC, "SD_GUI_Game_Shortcut_Create")
	GUICtrlSetOnEvent($hButtonChangeLanguage, "SD_GUI_Language_Popup")
	GUICtrlSetOnEvent($hDummyF5, "SD_GUI_Update")
	For $iCount = 1 To $aLanguages[0][0]
		GUICtrlSetOnEvent($aLanguages[$iCount][0], "SD_GUI_Language_Change")
	Next
EndFunc   ;==>SD_GUI_Events_Register

Func SD_GUI_SetLng()
	GUICtrlSetData($hGroupModList, Lng_Get("group.modlist.title"))
	GUICtrlSetData($hModMoveUp, Lng_Get("group.modlist.move_up"))
	GUICtrlSetData($hModMoveDown, Lng_Get("group.modlist.move_down"))
	GUICtrlSetData($hModEnableDisable, Lng_Get("group.modlist.enable"))
	GUICtrlSetData($hModDelete, Lng_Get("group.modlist.delete"))
	GUICtrlSetData($hButtonPlugins, Lng_Get("group.modlist.plugins"))
	GUICtrlSetData($hModCompatibility, Lng_Get("group.modlist.compatibility"))
	GUICtrlSetData($hModAdd, Lng_Get("group.modlist.add_new"))
	GUICtrlSetData($hSettings, Lng_Get("group.modlist.settings"))
	GUICtrlSetData($hModWebsite, Lng_Get("group.modlist.website"))
	GUICtrlSetData($hButtonMoreActions, Lng_Get("group.modlist.button_more"))
	GUICtrlSetData($hModOpenFolder, Lng_Get("group.modlist.open_folder"))
	GUICtrlSetData($hModInfoC, Lng_Get("group.modlist.edit_modinfo"))
	GUICtrlSetData($hModReadmeC, Lng_Get("group.modlist.edit_readme"))
	GUICtrlSetData($hGroupPresets, Lng_Get("group.presets.title"))
	GUICtrlSetData($hLabelPreset, Lng_Get("group.presets.label_current"))
	GUICtrlSetData($hPreset, Lng_Get("group.presets.none"))
	GUICtrlSetData($hPresetSave, Lng_Get("group.presets.save"))
	GUICtrlSetData($hPresetLoad, Lng_Get("group.presets.load"))
	GUICtrlSetData($hPresetDelete, Lng_Get("group.presets.delete"))

	GUICtrlSetData($hGroupGame, Lng_Get("group.game.title"))
	GUICtrlSetData($hLabelExe, Lng_Get("group.game.label_launch"))
	GUICtrlSetData($hLabelWO, Lng_Get("group.game.label_wog_opt"))
	GUICtrlSetData($hButtonRun, Lng_Get("group.game.launch"))
	GUICtrlSetData($hButtonCSC, Lng_Get("group.game.create_csc"))

	GUICtrlSetData($hGroupModInfo, Lng_Get("group.modinfo.title"))
	GUICtrlSetData($hButtonChangeLanguage, StringFormat("Language (%s)", Lng_Get("lang.name")))
	WinSetTitle($hFormMain, "", StringFormat(Lng_Get("main.title"), $MM_VERSION))
EndFunc   ;==>SD_GUI_SetLng

Func SD_GUI_Mod_Compatibility()
	MsgBox(4096, "", $sCompatibilityMessage, Default, $hFormMain)
EndFunc   ;==>SD_GUI_Mod_Compatibility

Func SD_GUI_MoreActionsPopup()
	_GUICtrlMenu_TrackPopupMenu(GUICtrlGetHandle($hMoreActionsContextMenuID), $hFormMain, -1, -1, 1, 1, 1)
EndFunc   ;==>SD_GUI_MoreActionsPopup

Func SD_GUI_Language_Popup()
;~ 	_ArrayDisplay($aLanguages)
	_GUICtrlMenu_TrackPopupMenu(GUICtrlGetHandle($hChangeLanguageContextMenuID), $hFormMain, -1, -1, 1, 1, 1)
EndFunc   ;==>SD_GUI_Language_Popup

Func SD_GUI_Settings()
	GUISetState(@SW_DISABLE, $hFormMain)
	Local $iGUIOnEventModeState = AutoItSetOption("GUIOnEventMode", 0)
	Local $iResult = Settings_GUI($hFormMain)
	AutoItSetOption("GUIOnEventMode", $iGUIOnEventModeState)
	GUISetState(@SW_ENABLE, $hFormMain)
	GUISetState(@SW_RESTORE, $hFormMain)

	$bDisplayVersion = Settings_Get("DisplayVersion")
	$bSyncPresetWithWS = Settings_Get("SyncPresetWithWS")

	If $iResult = 1 Then ; Names
		SD_GUI_Update()
	EndIf
EndFunc   ;==>SD_GUI_Settings

Func SD_GUI_Mod_CreateModifyReadme()
	Local $iTreeViewIndex = TreeViewGetSelectedIndex()
	Local $iModIndex1 = $auTreeView[$iTreeViewIndex][2]
	If $iModIndex1 < 1 Or $iModIndex1 > $MM_LIST_CONTENT[0][0] Then Return -1 ; never
	Local $sPath = $MM_LIST_DIR_PATH & "\" & $MM_LIST_CONTENT[$iModIndex1][0] & '\Readme.txt'
	Local $hFile = FileOpen($sPath, 1)
	FileClose($hFile)
	ShellExecute($sPath)
EndFunc   ;==>SD_GUI_Mod_CreateModifyReadme

Func SD_GUI_Mod_CreateModifyModInfo()
	Local $iTreeViewIndex = TreeViewGetSelectedIndex()
	Local $iModIndex1 = $auTreeView[$iTreeViewIndex][2]
	If $iModIndex1 < 1 Or $iModIndex1 > $MM_LIST_CONTENT[0][0] Then Return -1 ; never
	Local $sPath = $MM_LIST_DIR_PATH & "\" & $MM_LIST_CONTENT[$iModIndex1][0] & '\mod_info.ini'
	Local $bAddInfo = Not FileExists($sPath)
	Local $hFile = FileOpen($sPath, 1 + 8 + 32)
	If $bAddInfo Then
		FileWriteLine($hFile, "[info]")
		FileWriteLine($hFile, "; this section contains various settings + default name/description (use English here, please) ")
		FileWriteLine($hFile, "Caption = " & $MM_LIST_CONTENT[$iModIndex1][0])
		FileWriteLine($hFile, "; if name not set -> MM will use directory name instead")
		FileWriteLine($hFile, "Description File = Readme.txt")
		FileWriteLine($hFile, "; file with mod description (please, don't use wall of text)")
		FileWriteLine($hFile, "Author = " & @UserName)
		FileWriteLine($hFile, "; author name")
		FileWriteLine($hFile, "Homepage = ")
		FileWriteLine($hFile, "; your webpage")
		FileWriteLine($hFile, "Version = ")
		FileWriteLine($hFile, "; version in form X.X[.X[.X]] -> 1.52	2.13.34	3.1324.324.234")
		FileWriteLine($hFile, "Icon File = ")
		FileWriteLine($hFile, "; path to icon file. Index is not supported now (MM will always use 0). Icon Index = X will be supported in future versions")
		FileWriteLine($hFile, "Compatibility Class = Default")
		FileWriteLine($hFile, "; this field determines MM behaviour when detecting mods compatibility. Vaild values are ('Default' -> compatible with all mods, " & _
				"except 'None' -> not compatible with any mod, 'All' (or any other value) -> compatible with all mods (override 'None')")
		FileWriteLine($hFile, "")
		FileWriteLine($hFile, "Caption." & Lng_Get("lang.code") & " = " & $MM_LIST_CONTENT[$iModIndex1][0])
		FileWriteLine($hFile, "Description File." & Lng_Get("lang.code") & " = Readme.txt")
		FileWriteLine($hFile, "")
		FileWriteLine($hFile, "[Compatibility]")
		FileWriteLine($hFile, "WoG = 1")
		FileWriteLine($hFile, "; usage: 'ModName = value', values are -1 (not compatible) and 1 (compatible) with this mod")
	EndIf

	FileClose($hFile)
	ShellExecute($sPath)
EndFunc   ;==>SD_GUI_Mod_CreateModifyModInfo

Func SD_GUI_Mod_OpenFolder()
	Local $iTreeViewIndex = TreeViewGetSelectedIndex()
	Local $iModIndex1 = $auTreeView[$iTreeViewIndex][2]
	If $iModIndex1 < 1 Or $iModIndex1 > $MM_LIST_CONTENT[0][0] Then Return -1 ; never
	Local $sPath = '"' & $MM_LIST_DIR_PATH & "\" & $MM_LIST_CONTENT[$iModIndex1][0] & '"'
	ShellExecute($sPath)
EndFunc   ;==>SD_GUI_Mod_OpenFolder

Func SD_GUI_FillComboExe($sPath, $hCombo, $sDefault = "h3era.exe")
	If StringRight($sPath, 1) = "\" Then $sPath = StringTrimRight($sPath, 1)

	Local $aFiles = _FileListToArray($sPath & "\", "*.exe", 1)

	If @error Then Return

	GUICtrlSetData($hCombo, "")

	For $iCount = 1 To $aFiles[0]
		GUICtrlSetData($hCombo, $aFiles[$iCount])
	Next

	If FileExists($sPath & "\" & $sDefault) Then
		GUICtrlSetData($hCombo, $sDefault)
	ElseIf Not FileExists($sPath & "\h3era.exe") Then
		; Can do nothing
	Else
		GUICtrlSetData($hCombo, "h3era.exe")
	EndIf
EndFunc   ;==>SD_GUI_FillComboExe

Func SD_GUI_FillComboWo($sPath, $hCombo, $sDefault = "settings.dat")
	If StringRight($sPath, 1) = "\" Then $sPath = StringTrimRight($sPath, 1)

	If $sDefault = "" Then $sDefault = "settings.dat"

	Local $aFiles = _FileListToArray($sPath & "\", "*.dat", 1)

	If @error Then Return

	GUICtrlSetData($hCombo, "")

	For $iCount = 1 To $aFiles[0]
		GUICtrlSetData($hCombo, $aFiles[$iCount])
	Next

	If FileExists($sPath & "\" & $sDefault) Then
		GUICtrlSetData($hCombo, $sDefault)
	ElseIf Not FileExists($sPath & "\settings.dat") Then
		; Can do nothing
	Else
		GUICtrlSetData($hCombo, "settings.dat")
	EndIf

	Return True
EndFunc   ;==>SD_GUI_FillComboWo

Func SD_GUI_Manage_Plugins()
	GUISetState(@SW_DISABLE, $hFormMain)
	Local $iGUIOnEventModeState = AutoItSetOption("GUIOnEventMode", 0)
	Plugins_Manage($MM_LIST_CONTENT[$auTreeView[TreeViewGetSelectedIndex()][2]][0], $hFormMain)
	AutoItSetOption("GUIOnEventMode", $iGUIOnEventModeState)
	GUISetState(@SW_ENABLE, $hFormMain)
	GUISetState(@SW_RESTORE, $hFormMain)
EndFunc   ;==>SD_GUI_Manage_Plugins

Func SD_GUI_Game_Shortcut_Create()
	Local $sPresetName = GUICtrlRead($hPreset)
	If StringLeft($sPresetName, 1) = "*" Then $sPresetName = StringTrimLeft($sPresetName, 1)
	If $sPresetName = Lng_Get("group.presets.none") Then $sPresetName = ""
	Local $sFile = FileSaveDialog("", @DesktopDir, Lng_Get("group.game.sc_filter"), 2 + 16, "Era II " & $sPresetName, $hFormMain)
	If @error Then Return
	FileCreateShortcut(@ScriptDir & "\..\..\" & GUICtrlRead($hComboExe), $sFile, @ScriptDir & "\..\..\", 'modlist="' & @ScriptDir & '\presets\' & $sPresetName & '.txt"', StringFormat(Lng_Get("group.game.sc_tip"), $sPresetName))
EndFunc   ;==>SD_GUI_Game_Shortcut_Create

Func SD_GUI_Mod_AddByDnD($hwnd, $msg, $wParam, $lParam)
	#forceref $hwnd, $Msg, $wParam, $lParam
	Local $aRet = DllCall("shell32.dll", "int", "DragQueryFile", "int", $wParam, "int", -1, "ptr", 0, "int", 0)
	If @error Then Return SetError(1, 0, 0)
	Local $aDroppedFiles[$aRet[0] + 1], $i, $tBuffer = DllStructCreate("char[256]")
	$aDroppedFiles[0] = $aRet[0]
	For $i = 0 To $aRet[0] - 1 ; цикл запрашивает все файлы и папки
		DllCall("shell32.dll", "int", "DragQueryFile", "int", $wParam, "int", $i, "ptr", DllStructGetPtr($tBuffer), "int", DllStructGetSize($tBuffer))
		$aDroppedFiles[$i + 1] = DllStructGetData($tBuffer, 1)
	Next
	DllCall("shell32.dll", "none", "DragFinish", "int", $wParam)
	$tBuffer = 0

	GUISetState(@SW_DISABLE, $hFormMain)

	Local $aModList = Mod_ListCheck($aDroppedFiles); FilePath, ModName, ModLocalizedName, ModLocalizedDescription, Version, MinVersion, InstalledVersion, AuthorName, ModWebSite

	GUISetState(@SW_ENABLE, $hFormMain)
	GUISetState(@SW_RESTORE, $hFormMain)

	If $aModList[0][0] = 0 Then
		MsgBox(4096, "", StringFormat(Lng_Get("add_new.no_mods"), "0_O"), Default, $hFormMain)
		Return "GUI_RUNDEFMSG"
	EndIf

	GUISetState(@SW_DISABLE, $hFormMain)
	Local $iGUIOnEventModeState = AutoItSetOption("GUIOnEventMode", 0)
	PackedMod_InstallGUI_Simple($aModList, $hFormMain)
	AutoItSetOption("GUIOnEventMode", $iGUIOnEventModeState)
	GUISetState(@SW_ENABLE, $hFormMain)
	GUISetState(@SW_RESTORE, $hFormMain)

	TreeViewMain()
	TreeViewTryFollow($sFollowMod)
	ControlFocus($hFormMain, "", $hButtonRun)

	Return "GUI_RUNDEFMSG"
EndFunc   ;==>SD_GUI_Mod_AddByDnD

Func Mod_ListCheck($aFileList, $sDir = "")
	Local $iTotalMods = 0
	Local $aModList[$aFileList[0] + 1][9] ; FilePath, ModName, ModLocalizedName, ModLocalizedDescription, Version, MinVersion, InstalledVersion
	ProgressOn(Lng_Get("add_new.progress.title"), "", "", Default, Default, 16)
	For $iCount = 1 To $aFileList[0]
		Local $sPackedPath = $sDir & $aFileList[$iCount]
		ProgressSet(Round($iCount / $aFileList[0] * 100) - 1, StringFormat(Lng_Get("add_new.progress.scanned"), $iCount - 1, $aFileList[0]) & @LF & $aFileList[$iCount] & @LF & StringFormat(Lng_Get("add_new.progress.found"), $iTotalMods))
		Local $sModName = PackedMod_IsPackedMod($sPackedPath)
		If $sModName Then
			$iTotalMods += 1
			$aModList[$iTotalMods][0] = $sPackedPath
			$aModList[$iTotalMods][1] = $sModName
			PackedMod_LoadInfo($sPackedPath, $aModList[$iTotalMods][2], $aModList[$iTotalMods][3], $aModList[$iTotalMods][4], $aModList[$iTotalMods][5], $aModList[$iTotalMods][7], $aModList[$iTotalMods][8])
			$aModList[$iTotalMods][6] = Mod_GetVersion($sModName)
		EndIf
	Next
	ProgressOff()
	$aModList[0][0] = $iTotalMods
	Return $aModList
EndFunc   ;==>Mod_ListCheck

Func SD_GUI_Mod_Add()
	Local $sFileList = FileOpenDialog("", "", Lng_Get("add_new.filter"), 1 + 4, "", $hFormMain)
	If @error Then Return False
	GUISetState(@SW_DISABLE, $hFormMain)

	Local $aFileList = StringSplit($sFileList, "|", 2)

	If UBound($aFileList, 1) = 1 Then
		ReDim $aFileList[2]
		Local $szDrive, $szDir, $szFName, $szExt
		_PathSplit($aFileList[0], $szDrive, $szDir, $szFName, $szExt)
		$aFileList[0] = $szDrive & $szDir
		$aFileList[1] = $szFName & $szExt
	EndIf

	Local $sDirPath = $aFileList[0]
	$aFileList[0] = UBound($aFileList, 1) - 1

	Local $aModList = Mod_ListCheck($aFileList, $sDirPath & "\"); FilePath, ModName, ModLocalizedName, ModLocalizedDescription, Version, MinVersion, InstalledVersion, AuthorName, ModWebSite

	GUISetState(@SW_ENABLE, $hFormMain)
	GUISetState(@SW_RESTORE, $hFormMain)

	If $aModList[0][0] = 0 Then
		MsgBox(4096, "", StringFormat(Lng_Get("add_new.no_mods"), "0_O"), Default, $hFormMain)
		Return False
	EndIf

	GUISetState(@SW_DISABLE, $hFormMain)
	Local $iGUIOnEventModeState = AutoItSetOption("GUIOnEventMode", 0)
	PackedMod_InstallGUI_Simple($aModList, $hFormMain)
	AutoItSetOption("GUIOnEventMode", $iGUIOnEventModeState)
	GUISetState(@SW_ENABLE, $hFormMain)
	GUISetState(@SW_RESTORE, $hFormMain)

	TreeViewMain()
	TreeViewTryFollow($sFollowMod)
	ControlFocus($hFormMain, "", $hButtonRun)
EndFunc   ;==>SD_GUI_Mod_Add

Func SD_CLI_Mod_Add()
	Mod_ListLoad()
	Mod_ListLoad()
	Local $aModList = Mod_ListCheck($CMDLine); FilePath, ModName, ModLocalizedName, ModLocalizedDescription, Version, MinVersion, InstalledVersion, AuthorName, ModWebSite

	If $aModList[0][0] = 0 Then
		MsgBox(4096, "", StringFormat(Lng_Get("add_new.no_mods"), "0_O"), Default)
		Return False
	EndIf

	Local $iGUIOnEventModeState = AutoItSetOption("GUIOnEventMode", 0)
	Local $bResult = PackedMod_InstallGUI_Simple($aModList)
	AutoItSetOption("GUIOnEventMode", $iGUIOnEventModeState)

	Return $bResult
EndFunc   ;==>SD_CLI_Mod_Add

Func SD_GUI_Game_Exe_Run()
	If $sCompatibilityMessage <> "" Then
		Local $iAnswer = MsgBox(4096 + 4, "", $sCompatibilityMessage & @CRLF & Lng_Get("message.compatibility.launch"), Default, $hFormMain)
		If $iAnswer <> 6 Then Return 0
	EndIf

	Run('"' & @ScriptDir & '\..\..\' & GUICtrlRead($hComboExe) & '"', @ScriptDir & "\..\..\")
	If @error Then Run('"' & GUICtrlRead($hComboExe) & '"', @ScriptDir & "\..\..\")
	Settings_Set("Exe", GUICtrlRead($hComboExe))
EndFunc   ;==>SD_GUI_Game_Exe_Run

Func SD_GUI_Game_Exe_Change()
	Settings_Set("Exe", GUICtrlRead($hComboExe))
EndFunc   ;==>SD_GUI_Game_Exe_Change

Func SD_GUI_Game_Wo_Change()
	IniWrite(@ScriptDir & "\..\..\wog.ini", "WoGification", "Options_File_Name", GUICtrlRead($hComboWO))
EndFunc   ;==>SD_GUI_Game_Wo_Change

Func SD_GUI_Preset_Load()
	Local $sSuggestName = GUICtrlRead($hPreset) & ".txt"
	If StringLeft($sSuggestName, 1) = "*" Then $sSuggestName = StringTrimLeft($sSuggestName, 1)
	If $sSuggestName = Lng_Get("group.presets.none") & ".txt" Then $sSuggestName = ""
	Local $sLoadPath = FileOpenDialog(Lng_Get("group.presets.dialog_load"), @ScriptDir & "\presets\", Lng_Get("group.presets.dialog_filter"), 1, $sSuggestName, $hFormMain)
	If @error Then
		Return False
	Else
		If StringLeft($sLoadPath, StringLen(@ScriptDir & "\presets\")) <> @ScriptDir & "\presets\" Then Return False
		Preset_Load($sLoadPath)
		If $bSyncPresetWithWS Then
			Local $sSettingsName = FileReadLine($sLoadPath & ".e2p", 1)
			Local $sExeName = FileReadLine($sLoadPath & ".e2p", 2)
			If $sSettingsName <> "" Then IniWrite(@ScriptDir & "\..\..\wog.ini", "WoGification", "Options_File_Name", $sSettingsName)
			If $sExeName <> "" Then Settings_Set("Exe", $sExeName)
			GUICtrlSetData($hComboExe, Settings_Get("Exe"))
			GUICtrlSetData($hComboWO, IniRead(@ScriptDir & "\..\..\wog.ini", "WoGification", "Options_File_Name", "settings.dat"))
		EndIf
		Local $sPresetName = StringTrimRight(StringRegExpReplace($sLoadPath, ".*\\", ""), 4)
		GUICtrlSetData($hPreset, $sPresetName)
		GUICtrlSetState($hButtonCSC, $GUI_ENABLE)

		TreeViewMain()
		TreeViewTryFollow($sFollowMod)
		ControlFocus($hFormMain, "", $hButtonRun)
	EndIf
EndFunc   ;==>SD_GUI_Preset_Load

Func Preset_Load($sLoadPath)
	Local $asPreset
	_FileReadToArray($sLoadPath, $asPreset)
	If @error = 2 Then
		Local $asPreset[1]
	ElseIf @error Then
		Return False
	EndIf

	Local $hList = FileOpen($MM_LIST_DIR_PATH & "\list.txt", 2)

	For $iCount = 1 To $asPreset[0]
		FileWriteLine($hList, $asPreset[$iCount])
	Next

	FileClose($hList)
EndFunc   ;==>Preset_Load

Func SD_GUI_Preset_Delete()
	Local $sSuggestName = GUICtrlRead($hPreset) & ".txt"
	If StringLeft($sSuggestName, 1) = "*" Then $sSuggestName = StringTrimLeft($sSuggestName, 1)
	If $sSuggestName = Lng_Get("group.presets.none") & ".txt" Then $sSuggestName = ""
	Local $sDeletePath = FileOpenDialog(Lng_Get("group.presets.dialog_delete"), @ScriptDir & "\presets\", Lng_Get("group.presets.dialog_filter"), 1, $sSuggestName, $hFormMain)
	If @error Then
		Return False
	Else
		If StringLeft($sDeletePath, StringLen(@ScriptDir & "\presets\")) <> @ScriptDir & "\presets\" Then Return False
		FileRecycle($sDeletePath) ; Preset_Delete
		Local $sPresetName = StringTrimRight(StringRegExpReplace($sDeletePath, ".*\\", ""), 4)
		If GUICtrlRead($hPreset) = $sPresetName Then
			GUICtrlSetData($hPreset, Lng_Get("group.presets.none"))
			GUICtrlSetState($hButtonCSC, $GUI_DISABLE)
		EndIf
	EndIf
EndFunc   ;==>SD_GUI_Preset_Delete

Func SD_GUI_Preset_Save()
	Local $sSuggestName = GUICtrlRead($hPreset)
	If StringLeft($sSuggestName, 1) = "*" Then $sSuggestName = StringTrimLeft($sSuggestName, 1)
	If $sSuggestName = Lng_Get("group.presets.none") Then $sSuggestName = $MM_LIST_CONTENT[1][0]
	Local $sSavePath = FileSaveDialog(Lng_Get("group.presets.dialog_save"), @ScriptDir & "\presets\", Lng_Get("group.presets.dialog_filter"), Default, $sSuggestName, $hFormMain)
	If @error Then
		Return False
	Else
		If StringLeft($sSavePath, StringLen(@ScriptDir & "\presets\")) <> @ScriptDir & "\presets\" Then Return False
		If StringRight($sSavePath, 4) <> ".txt" Then
			If StringLeft(StringRight($sSavePath, 4), 1) = "." Then
				$sSavePath = StringTrimRight($sSuggestName, 3) & "txt"
			Else
				$sSavePath &= ".txt"
			EndIf
		EndIf

		Preset_Save($sSavePath)
		If $bSyncPresetWithWS Then
			FileDelete($sSavePath & ".e2p")
			FileWriteLine($sSavePath & ".e2p", IniRead(@ScriptDir & "\..\..\wog.ini", "WoGification", "Options_File_Name", ""))
			FileWriteLine($sSavePath & ".e2p", GUICtrlRead($hComboExe))
		EndIf

		Local $sPresetName = StringTrimRight(StringRegExpReplace($sSavePath, ".*\\", ""), 4)
		GUICtrlSetData($hPreset, $sPresetName)
		GUICtrlSetState($hButtonCSC, $GUI_ENABLE)
	EndIf
EndFunc   ;==>SD_GUI_Preset_Save

Func Preset_Save($sSavePath)
	Local $sPrevPath = $MM_LIST_FILE_PATH
	$MM_LIST_FILE_PATH = $sSavePath
	Mod_ListSave()
	$MM_LIST_FILE_PATH = $sPrevPath
EndFunc   ;==>Preset_Save

Func SD_GUI_SaveSize()
	Local $aPos = WinGetPos($hFormMain)

	$MM_WINDOW_WIDTH = $aPos[2]
	$MM_WINDOW_HEIGHT = $aPos[3]
	$MM_WINDOW_MAXIMIZED = BitAND(WinGetState($hFormMain), 32)

	Settings_Set("Maximized", $MM_WINDOW_MAXIMIZED)
	If Not $MM_WINDOW_MAXIMIZED Then
		Settings_Set("Width", $MM_WINDOW_WIDTH)
		Settings_Set("Height", $MM_WINDOW_HEIGHT)
	EndIf
EndFunc   ;==>SD_GUI_SaveSize

Func SD_GUI_LoadSize()
	$MM_WINDOW_WIDTH = Settings_Get("Width")
	$MM_WINDOW_HEIGHT = Settings_Get("Height")
	$MM_WINDOW_MAXIMIZED = Settings_Get("Maximized")
EndFunc   ;==>SD_GUI_LoadSize

Func SD_GUI_Close()
	SD_GUI_SaveSize()
	Exit
EndFunc   ;==>SD_GUI_Close

Func SD_GUI_Mod_Website()
	Local $iTreeViewIndex = TreeViewGetSelectedIndex()
	Local $iModIndex1 = $auTreeView[$iTreeViewIndex][2]
	If $iModIndex1 < 1 Or $iModIndex1 > $MM_LIST_CONTENT[0][0] Then Return -1 ; never

	Utils_LaunchInBrowser($MM_LIST_CONTENT[$iModIndex1][6])
EndFunc   ;==>SD_GUI_Mod_Website

Func SD_GUI_PresetChange()
	If GUICtrlRead($hPreset) <> Lng_Get("group.presets.none") Then
		Local $sPresetName = GUICtrlRead($hPreset)
		If StringLeft($sPresetName, 1) <> "*" Then $sPresetName = "*" & $sPresetName
		GUICtrlSetData($hPreset, $sPresetName)
	EndIf
EndFunc   ;==>SD_GUI_PresetChange

Func SD_GUI_Mod_Move_Up()
	Local $iTreeViewIndex = TreeViewGetSelectedIndex()
	Local $iModIndex1 = $auTreeView[$iTreeViewIndex][2], $iModIndex2
	If $iModIndex1 < 2 Or $iModIndex1 > $MM_LIST_CONTENT[0][0] Then Return -1 ; never
	$iModIndex2 = $iModIndex1 - 1
	SD_GUI_Mod_Swap($iModIndex1, $iModIndex2)
EndFunc   ;==>SD_GUI_Mod_Move_Up

Func SD_GUI_Mod_Move_Down()
	Local $iTreeViewIndex = TreeViewGetSelectedIndex()
	Local $iModIndex1 = $auTreeView[$iTreeViewIndex][2], $iModIndex2
	If $iModIndex1 < 1 Or $iModIndex1 > $MM_LIST_CONTENT[0][0] - 1 Then Return -1 ; never
	$iModIndex2 = $iModIndex1 + 1
	SD_GUI_Mod_Swap($iModIndex1, $iModIndex2)
EndFunc   ;==>SD_GUI_Mod_Move_Down

Func SD_GUI_Mod_Swap($iModIndex1, $iModIndex2)
	Mod_ListSwap($iModIndex1, $iModIndex2)
	Mod_CompatibilitySwap($iModIndex1, $iModIndex2, $abModCompatibilityMap)
	TreeViewSwap($iModIndex1, $iModIndex2, $auTreeView)
	TreeViewTryFollow($sFollowMod)
	ControlFocus($hFormMain, "", @GUI_CtrlId)
	SD_GUI_PresetChange()
EndFunc   ;==>SD_GUI_Mod_Swap

Func SD_GUI_Mod_Delete()
	Local $iTreeViewIndex = TreeViewGetSelectedIndex()
	Local $iModIndex = $auTreeView[$iTreeViewIndex][2]
	Local $iAnswer = MsgBox(4 + 32 + 256 + 8192, "", StringFormat(Lng_Get("group.modlist.delete_confirm"), $MM_LIST_CONTENT[$iModIndex][0]), Default, $hFormMain)
	If $iAnswer = 7 Then Return False

	Mod_Delete($iModIndex)

	TreeViewMain()
	If $MM_LIST_CONTENT[0][0] < $iModIndex Then
		$iModIndex = $MM_LIST_CONTENT[0][0]
	EndIf

	If $iModIndex > 0 Then
		$sFollowMod = $MM_LIST_CONTENT[$iModIndex][0]
		TreeViewTryFollow($sFollowMod)
	EndIf
	SD_GUI_PresetChange()
EndFunc   ;==>SD_GUI_Mod_Delete

Func SD_GUI_Mod_EnableDisable()
	Local $iTreeViewIndex = TreeViewGetSelectedIndex()
	If $auTreeView[$iTreeViewIndex][1] == 0 Then Return
	Local $iModIndex = $auTreeView[$iTreeViewIndex][2]

	If $iModIndex < 1 Then Return

	Local $sState = $MM_LIST_CONTENT[$iModIndex][1]
	If $sState = "Disabled" Then
		Mod_Enable($iModIndex)
	Else
		Mod_Disable($iModIndex)
	EndIf

	TreeViewMain()
	If $sState = "Disabled" Then
		TreeViewTryFollow($sFollowMod)
	Else
		If $iModIndex <> 1 Then $iModIndex -= 1
		$sFollowMod = $MM_LIST_CONTENT[$iModIndex][0]
		TreeViewTryFollow($sFollowMod)
	EndIf


	ControlFocus($hFormMain, "", @GUI_CtrlId)
	SD_GUI_PresetChange()
EndFunc   ;==>SD_GUI_Mod_EnableDisable

Func SD_GUI_Update()
	GUISwitch($hFormMain)
	TreeViewMain()
	GUICtrlSetState($auTreeView[1][0], $GUI_FOCUS)
	GUICtrlSetData($hComboExe, Settings_Get("Exe"))
	GUICtrlSetData($hComboWO, IniRead(@ScriptDir & "\..\..\wog.ini", "WoGification", "Options_File_Name", "settings.dat"))
	TreeViewTryFollow($sFollowMod)
EndFunc   ;==>SD_GUI_Update

Func TreeViewMain()
	Mod_ListLoad()
	$abModCompatibilityMap = Mod_CompatibilityMapLoad()
	;If $hTreeView Then GUICtrlDelete($hTreeView)
	Local $aWindowSize = WinGetClientSize($hFormMain)
;~ 	If<492 Then WinMove($hFormMain, "", Default, Default, Default, 492+25)
	If Not $hTreeView Then
		$hTreeView = GUICtrlCreateTreeView(16, 24, 361, $aWindowSize[1] - 40, BitOR($TVS_HASBUTTONS, $TVS_HASLINES, $TVS_FULLROWSELECT, $TVS_DISABLEDRAGDROP, $TVS_SHOWSELALWAYS), $WS_EX_CLIENTEDGE)
	Else
		_GUICtrlTreeView_BeginUpdate($hTreeView)
		_GUICtrlTreeView_DeleteAll($hTreeView)
		_GUICtrlTreeView_EndUpdate($hTreeView)
	EndIf
	GUICtrlSetResizing($hTreeView, 2 + 32 + 256)
	$auTreeView = TreeViewFill()
EndFunc   ;==>TreeViewMain

Func Quit()
	Exit
EndFunc   ;==>Quit

Func SD_GUI_Mod_Controls_Disable()
	GUICtrlSetState($hModMoveUp, $GUI_DISABLE)
	GUICtrlSetState($hModMoveDown, $GUI_DISABLE)
	GUICtrlSetState($hModEnableDisable, $GUI_DISABLE)
	GUICtrlSetState($hModDelete, $GUI_DISABLE)
	GUICtrlSetState($hButtonPlugins, $GUI_DISABLE)
	GUICtrlSetState($hModWebsite, $GUI_DISABLE)
	GUICtrlSetState($hModOpenFolder, $GUI_DISABLE)
	GUICtrlSetState($hModReadmeC, $GUI_DISABLE)
	GUICtrlSetState($hModInfoC, $GUI_DISABLE)
	GUICtrlSetData($hModInfo, Lng_Get("group.modinfo.no_info"))
	$sFollowMod = ""
EndFunc   ;==>SD_GUI_Mod_Controls_Disable

Func SD_GUI_Mod_Controls_Set()
	For $iCount = 0 To UBound($auTreeView, 1) - 1
		If $auTreeView[$iCount][2] = -1 Then ContinueLoop
		If @GUI_CtrlId <> $auTreeView[$iCount][0] Then ContinueLoop
		Local $iModIndex = $auTreeView[$iCount][2]
		$sFollowMod = $MM_LIST_CONTENT[$iModIndex][0]
		If $iModIndex > 0 And $iModIndex <= $MM_LIST_CONTENT[0][0] Then

			; Info (5)
			GUICtrlSetData($hModInfo, Mod_InfoLoad($MM_LIST_CONTENT[$iModIndex][0], $MM_LIST_CONTENT[$iModIndex][5]))

			; MoveUp (2)
			If $iModIndex > 0 And $iModIndex <> -1 And $auTreeView[$iCount - 1][2] <> -1 And _
					$MM_LIST_CONTENT[$iModIndex][1] = "Enabled" And $MM_LIST_CONTENT[$auTreeView[$iCount - 1][2]][1] = "Enabled" Then
				GUICtrlSetState($hModMoveUp, $GUI_ENABLE)
			Else
				GUICtrlSetState($hModMoveUp, $GUI_DISABLE)
			EndIf

			; MoveDown (2)
			If $iModIndex < $MM_LIST_CONTENT[0][0] And $iModIndex <> -1 And $auTreeView[$iCount + 1][2] <> -1 And _
					$MM_LIST_CONTENT[$auTreeView[$iCount][2]][1] = "Enabled" And $MM_LIST_CONTENT[$auTreeView[$iCount + 1][2]][1] = "Enabled" Then
				GUICtrlSetState($hModMoveDown, $GUI_ENABLE)
			Else
				GUICtrlSetState($hModMoveDown, $GUI_DISABLE)
			EndIf

			; Enable/Disable/Remove (1,2)
			GUICtrlSetState($hModEnableDisable, $GUI_ENABLE)
			If $MM_LIST_CONTENT[$auTreeView[$iCount][2]][1] = "Disabled" Then
				GUICtrlSetData($hModEnableDisable, Lng_Get("group.modlist.enable"))
			ElseIf $MM_LIST_CONTENT[$auTreeView[$iCount][2]][2] Then ; Not exist
				GUICtrlSetData($hModEnableDisable, Lng_Get("group.modlist.remove"))
			Else
				GUICtrlSetData($hModEnableDisable, Lng_Get("group.modlist.disable"))
			EndIf

			; Plugins
			If Plugins_ModHavePlugins($MM_LIST_CONTENT[$iModIndex][0]) Then
				GUICtrlSetState($hButtonPlugins, $GUI_ENABLE)
			Else
				GUICtrlSetState($hButtonPlugins, $GUI_DISABLE)
			EndIf

			; Website (6)
			If $MM_LIST_CONTENT[$iModIndex][6] Then
				GUICtrlSetState($hModWebsite, $GUI_ENABLE)
			Else
				GUICtrlSetState($hModWebsite, $GUI_DISABLE)
			EndIf

			; Delete (2)
			If $MM_LIST_CONTENT[$iModIndex][2] Then
				GUICtrlSetState($hModDelete, $GUI_DISABLE)
			Else
				GUICtrlSetState($hModDelete, $GUI_ENABLE)
			EndIf

			; Modmaker (settings, 2)
			If Not $MM_LIST_CONTENT[$iModIndex][2] Then
				GUICtrlSetState($hModOpenFolder, $GUI_ENABLE)
				GUICtrlSetState($hModReadmeC, $GUI_ENABLE)
				GUICtrlSetState($hModInfoC, $GUI_ENABLE)
			Else
				GUICtrlSetState($hModOpenFolder, $GUI_DISABLE)
				GUICtrlSetState($hModReadmeC, $GUI_DISABLE)
				GUICtrlSetState($hModInfoC, $GUI_DISABLE)
			EndIf
		EndIf

		ExitLoop
	Next
EndFunc   ;==>SD_GUI_Mod_Controls_Set

Func TreeViewFill()
	_GUICtrlTreeView_BeginUpdate($hTreeView)

	Local $aTreeViewData[$MM_LIST_CONTENT[0][0] + 1][4] ; $TreeViewHandle, $ParentIndex, $ModIndex / $EnabledDisabled, $PriorityGroup (Only for groups)

	$aTreeViewData[0][0] = $hTreeView
	$aTreeViewData[0][1] = -1
	$aTreeViewData[0][2] = -1
	$aTreeViewData[0][3] = -1

	Local $iIndexToAdd = 1
	Local $iCurrentGroup = -1, $bCurrentGroupEnabled = True

	GUICtrlSetState($hModCompatibility, $GUI_DISABLE)

	For $iCount = 1 To $MM_LIST_CONTENT[0][0]
		Local $bEnabled = $MM_LIST_CONTENT[$iCount][1] = "Enabled"
		Local $iPriority = $MM_LIST_CONTENT[$iCount][9]


		Local $bCreateNewGroup = False
		If $iCurrentGroup = -1 Then $bCreateNewGroup = True
		If $iCurrentGroup <> -1 And $bCurrentGroupEnabled And $bEnabled And $aTreeViewData[$iCurrentGroup][3] <> $iPriority Then $bCreateNewGroup = True
		If $bCurrentGroupEnabled And Not $bEnabled Then $bCreateNewGroup = True

		If $bCreateNewGroup Then
			Local $sText = Lng_Get("group.modlist.label_disabled")
			If $bEnabled Then $sText = Lng_Get("group.modlist.label_enabled")
			If $bEnabled And $iPriority <> 0 Then $sText = StringFormat(Lng_Get("group.modlist.label_enabled_p"), $iPriority)

			$aTreeViewData[$iIndexToAdd][0] = GUICtrlCreateTreeViewItem($sText, $aTreeViewData[0][0])
			GUICtrlSetColor($aTreeViewData[$iIndexToAdd][0], 0x0000C0)
			GUICtrlSetOnEvent($aTreeViewData[$iIndexToAdd][0], "SD_GUI_Mod_Controls_Disable")
			If $bEnabled Then
				_GUICtrlTreeView_SetIcon($aTreeViewData[0][0], $aTreeViewData[$iIndexToAdd][0], @ScriptDir & "\icons\folder-green.ico", 0, 6)
			Else
				_GUICtrlTreeView_SetIcon($aTreeViewData[0][0], $aTreeViewData[$iIndexToAdd][0], @ScriptDir & "\icons\folder-red.ico", 0, 6)
			EndIf

			$aTreeViewData[$iIndexToAdd][1] = 0
			$aTreeViewData[$iIndexToAdd][2] = $bEnabled
			$aTreeViewData[$iIndexToAdd][3] = $iPriority

			$iCurrentGroup = $iIndexToAdd
			$bCurrentGroupEnabled = $bEnabled
			$iIndexToAdd += 1
			ReDim $aTreeViewData[UBound($aTreeViewData, 1) + 1][4]
		EndIf

		$aTreeViewData[$iIndexToAdd][3] = 0
		$aTreeViewData[$iIndexToAdd][2] = $iCount
		$aTreeViewData[$iIndexToAdd][1] = $iCurrentGroup

		$aTreeViewData[$iIndexToAdd][0] = GUICtrlCreateTreeViewItem(Mod_MakeDisplayName($MM_LIST_CONTENT[$iCount][3], $MM_LIST_CONTENT[$iCount][2], $MM_LIST_CONTENT[$iCount][8], $bDisplayVersion), $aTreeViewData[$aTreeViewData[$iIndexToAdd][1]][0])
		GUICtrlSetOnEvent($aTreeViewData[$iIndexToAdd][0], "SD_GUI_Mod_Controls_Set")
		If $MM_LIST_CONTENT[$iCount][7] <> "" And FileExists($MM_LIST_DIR_PATH & "\" & $MM_LIST_CONTENT[$iCount][0] & "\" & $MM_LIST_CONTENT[$iCount][7]) Then
			_GUICtrlTreeView_SetIcon($aTreeViewData[0][0], $aTreeViewData[$iIndexToAdd][0], $MM_LIST_DIR_PATH & "\" & $MM_LIST_CONTENT[$iCount][0] & "\" & $MM_LIST_CONTENT[$iCount][7], 0, 6)
		Else
			_GUICtrlTreeView_SetIcon($aTreeViewData[0][0], $aTreeViewData[$iIndexToAdd][0], @ScriptDir & "\icons\folder-grey.ico", 0, 6)
		EndIf

		$iIndexToAdd += 1
	Next

	For $iCount = 1 To UBound($aTreeViewData, 1) - 1
		If $aTreeViewData[$iCount][1] <> -1 Then GUICtrlSetState($aTreeViewData[$iCount][0], $GUI_EXPAND)
	Next

	TreeViewColor($aTreeViewData)
	_GUICtrlTreeView_EndUpdate($hTreeView)
	Return $aTreeViewData
EndFunc   ;==>TreeViewFill

Func TreeViewColor($auTreeView)
	$sCompatibilityMessage = ""
	Local $iListIndex, $bMasterIndex = 0

	For $iCount = 1 To $MM_LIST_CONTENT[0][0]
		$iListIndex = TreeViewGetIndexByModIndex($iCount, $auTreeView)

		GUICtrlSetColor($auTreeView[$iListIndex][0], Default)
		If $MM_LIST_CONTENT[$iCount][2] Then GUICtrlSetColor($auTreeView[$iListIndex][0], 0xC00000)
		If $bMasterIndex = 0 And $MM_LIST_CONTENT[$iCount][1] = "Enabled" And Not $MM_LIST_CONTENT[$iCount][2] Then
			For $jCount = 1 To $MM_LIST_CONTENT[0][0]
				If $jCount = $iCount Then ContinueLoop
				If $MM_LIST_CONTENT[$jCount][1] = "Disabled" Or $MM_LIST_CONTENT[$jCount][2] Then ContinueLoop
				If Not $abModCompatibilityMap[$iCount][$jCount] Then
					$bMasterIndex = $iCount
					GUICtrlSetColor($auTreeView[$iListIndex][0], 0x00C000) ; This is master mod
					$sCompatibilityMessage = StringFormat(Lng_Get("message.compatibility.part1"), $MM_LIST_CONTENT[$iCount][3]) & @CRLF
					ExitLoop
				EndIf
			Next
		ElseIf $bMasterIndex > 0 And $MM_LIST_CONTENT[$iCount][1] = "Enabled" And Not $MM_LIST_CONTENT[$iCount][2] Then
			If Not $abModCompatibilityMap[$bMasterIndex][$iCount] Then
				GUICtrlSetColor($auTreeView[$iListIndex][0], 0xCC0000) ; This is slave mod
				$sCompatibilityMessage &= $MM_LIST_CONTENT[$iCount][3] & @CRLF
			EndIf
		EndIf
	Next


	Local $iCurrentPriority = -100000
	For $iCount = UBound($auTreeView, 1) - 1 To 1 Step -1
		If $auTreeView[$iCount][1] = 0 And $auTreeView[$iCount][2] And $auTreeView[$iCount][3] < $iCurrentPriority Then
			GUICtrlSetColor($auTreeView[$iCount][0], 0xA00000)
		ElseIf $auTreeView[$iCount][1] = 0 And $auTreeView[$iCount][2] And $auTreeView[$iCount][3] > $iCurrentPriority Then
			$iCurrentPriority = $auTreeView[$iCount][3]
		EndIf
	Next

	If $sCompatibilityMessage <> "" Then
		$sCompatibilityMessage &= @CRLF & Lng_Get("message.compatibility.part2")
		GUICtrlSetState($hModCompatibility, $GUI_ENABLE)
	EndIf
EndFunc   ;==>TreeViewColor


Func TreeViewSwap($iModIndex1, $iModIndex2, $auTreeView)
	_GUICtrlTreeView_BeginUpdate($auTreeView[0][0])
	Local $iIndex1 = TreeViewGetIndexByModIndex($iModIndex1, $auTreeView)
	Local $iIndex2 = TreeViewGetIndexByModIndex($iModIndex2, $auTreeView)

	Local $vTemp

	$vTemp = _GUICtrlTreeView_GetText($auTreeView[0][0], $auTreeView[$iIndex1][0])
	_GUICtrlTreeView_SetText($auTreeView[0][0], $auTreeView[$iIndex1][0], _GUICtrlTreeView_GetText($auTreeView[0][0], $auTreeView[$iIndex2][0]))
	_GUICtrlTreeView_SetText($auTreeView[0][0], $auTreeView[$iIndex2][0], $vTemp)

	$vTemp = _GUICtrlTreeView_GetImageIndex($auTreeView[0][0], $auTreeView[$iIndex1][0])
	_GUICtrlTreeView_SetImageIndex($auTreeView[0][0], $auTreeView[$iIndex1][0], _GUICtrlTreeView_GetImageIndex($auTreeView[0][0], $auTreeView[$iIndex2][0]))
	_GUICtrlTreeView_SetImageIndex($auTreeView[0][0], $auTreeView[$iIndex2][0], $vTemp)

	$vTemp = _GUICtrlTreeView_GetStateImageIndex($auTreeView[0][0], $auTreeView[$iIndex1][0])
	_GUICtrlTreeView_SetStateImageIndex($auTreeView[0][0], $auTreeView[$iIndex1][0], _GUICtrlTreeView_GetStateImageIndex($auTreeView[0][0], $auTreeView[$iIndex2][0]))
	_GUICtrlTreeView_SetStateImageIndex($auTreeView[0][0], $auTreeView[$iIndex2][0], $vTemp)

	$vTemp = _GUICtrlTreeView_GetSelectedImageIndex($auTreeView[0][0], $auTreeView[$iIndex1][0])
	_GUICtrlTreeView_SetSelectedImageIndex($auTreeView[0][0], $auTreeView[$iIndex1][0], _GUICtrlTreeView_GetSelectedImageIndex($auTreeView[0][0], $auTreeView[$iIndex2][0]))
	_GUICtrlTreeView_SetSelectedImageIndex($auTreeView[0][0], $auTreeView[$iIndex2][0], $vTemp)

	TreeViewColor($auTreeView)

	_GUICtrlTreeView_EndUpdate($auTreeView[0][0])
EndFunc   ;==>TreeViewSwap

Func TreeViewGetSelectedIndex()
	Local $iSelected = GUICtrlRead($hTreeView)
	For $iCount = 0 To UBound($auTreeView, 1) - 1
		If $auTreeView[$iCount][0] = $iSelected Then Return $iCount
	Next
EndFunc   ;==>TreeViewGetSelectedIndex

Func TreeViewGetIndexByModIndex($iModIndex, $auTreeView)
	For $iCount = 0 To UBound($auTreeView, 1) - 1
		If $auTreeView[$iCount][1] > 0 And $auTreeView[$iCount][2] = $iModIndex Then Return $iCount
	Next

	Return -1
EndFunc   ;==>TreeViewGetIndexByModIndex

Func TreeViewTryFollow($sModName)
	If $bInTrack Then Return
	$bInTrack = True

	Local $iModIndex = 0
	For $iCount = 1 To $MM_LIST_CONTENT[0][0]
		If $MM_LIST_CONTENT[$iCount][0] = $sModName Then
			$iModIndex = $iCount
			ExitLoop
		EndIf
	Next

	If $iModIndex = 0 Then
		GUICtrlSetState($auTreeView[1][0], $GUI_FOCUS)
		$bInTrack = False
		Return
	EndIf

	GUICtrlSetState($auTreeView[1][0], $GUI_FOCUS)
	Local $iIndex = TreeViewGetIndexByModIndex($iModIndex, $auTreeView)
	GUICtrlSetState($auTreeView[$iIndex][0], $GUI_FOCUS)
	$bInTrack = False
EndFunc   ;==>TreeViewTryFollow

Func WM_GETMINMAXINFO($hwnd, $msg, $wParam, $lParam)
	#forceref $hwnd, $Msg, $wParam, $lParam
	Local $GUIMINWID = $MM_WINDOW_MIN_WIDTH + 16, $GUIMINHT = $MM_WINDOW_MIN_HEIGHT + 16 ; set your restrictions here
	Local $GUIMAXWID = 10000, $GUIMAXHT = 10000
	Local $tagMaxinfo = DllStructCreate("int;int;int;int;int;int;int;int;int;int", $lParam)
	DllStructSetData($tagMaxinfo, 7, $GUIMINWID) ; min X
	DllStructSetData($tagMaxinfo, 8, $GUIMINHT) ; min Y
	DllStructSetData($tagMaxinfo, 9, $GUIMAXWID); max X
	DllStructSetData($tagMaxinfo, 10, $GUIMAXHT) ; max Y
	Return 0
EndFunc   ;==>WM_GETMINMAXINFO

Func WM_NOTIFY($hwnd, $iMsg, $iwParam, $ilParam)
	#forceref $hWnd, $iMsg, $iwParam, $ilParam
	Local $hWndFrom, $iCode, $tNMHDR, $hWndTreeview
	$hWndTreeview = $hTreeView
	If Not IsHWnd($hTreeView) Then $hWndTreeview = GUICtrlGetHandle($hTreeView)
	If Not IsHWnd($hWndTreeview) Then Return $GUI_RUNDEFMSG

	$tNMHDR = DllStructCreate($tagNMHDR, $ilParam)
	$hWndFrom = HWnd(DllStructGetData($tNMHDR, "hWndFrom"))
	$iCode = DllStructGetData($tNMHDR, "Code")

	Switch $hWndFrom
		Case $hWndTreeview
			Switch $iCode
				Case $NM_DBLCLK
					$bEnableDisable = True
			EndSwitch
	EndSwitch

	Return $GUI_RUNDEFMSG
EndFunc   ;==>WM_NOTIFY
