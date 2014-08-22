; Author:         Aliaksei SyDr Karalenka
#NoTrayIcon

#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=icons\Misc-Tools.ico
#AutoIt3Wrapper_Outfile=modsmann.exe
#AutoIt3Wrapper_Compression=4
#AutoIt3Wrapper_UseX64=n
#AutoIt3Wrapper_Res_requestedExecutionLevel=None
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****

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
#include <Misc.au3>
#include <StaticConstants.au3>
#include <TreeViewConstants.au3>
#include <WinAPI.au3>
#include <WindowsConstants.au3>

#include "folder_mods.au3"
#include "lng.au3"
#include "packed_mods.au3"
#include "plugins.au3"
#include "settings.au3"

AutoItSetOption("MustDeclareVars", 1)
AutoItSetOption("GUIOnEventMode", 1)
AutoItSetOption("GUIResizeMode", 2+32+4+64)
AutoItSetOption("GUICloseOnESC", 1)

#Region Variables
Global Const $_VERSION = "ver. 0.14.08"
Global $hFormMain, $hTreeView
Global $auTreeView, $auModList, $abModCompatibilityMap
Global $sBasePath = @ScriptDir & "\..\..\Mods"
Global $sDefaultList = $sBasePath & "\list.txt"
Global $bGUINeedUpdate = False, $sMListUpdate = ""

Global $hGroupModList, $hGroupPresets, $hGroupGame, $hGroupModInfo, $hSettings, $hButtonChangeLanguage, $hChangeLanguageContextMenuID
Global $aLanguages[1][2]
Global $hModMoveUp, $hModMoveDown, $hModEnableDisable, $hModDelete, $hModAdd, $hModCompatibility
Global $hButtonPlugins, $hModWebsite, $hModOpenFolder, $hMoreActionsContextMenuID, $hButtonMoreActions
Global $hModReadmeC, $hModInfoC
Global $hLabelPreset, $hPreset, $hPresetSave, $hPresetLoad, $hPresetDelete
Global $hLabelExe, $hComboExe, $hButtonRun, $hButtonCSC
Global $hLabelWO, $hComboWO
Global $hModInfo
Global $sFollowMod = "WoG"
Global $sCompatibilityMessage = ""
Global $hDummyF5
Global $bEnableDisable
Global $bInTrack = False
#EndRegion

Global $sLanguage = Settings_Get("Language")
If $sLanguage = "" Then $sLanguage = "english.txt"
Lng_LoadFile($sLanguage)

If $CMDLine[0]>0 Then
	If @Compiled Then
		If $CMDLine[1] = '/assocset' Then
			Assoc_Create()
			Exit
		ElseIf $CMDLine[1] = '/assocdel' Then
			Assoc_Delete()
			Exit
		EndIf
	EndIf
	If Not SD_CLI_Mod_Add() Then Exit
EndIf


Global $hSingleton = _Singleton("EMMat." & Hex(StringToBinary(@ScriptDir)), 1)

If $hSingleton = 0 Then
	If WinActivate(StringFormat(Lng_Get("main.title"), $_VERSION)) Then Exit
EndIf

Global $bSyncPresetWithWS = Settings_Get("SyncPresetWithWS")
Global $bDisplayVersion = Settings_Get("DisplayVersion")
Global $bRememberWindowSizePos = Settings_Get("RememberSizePos")
Global $bModMaker = Settings_Get("ModMaker")
Global $iModMakerPlace = 0
If $bModMaker Then $iModMakerPlace = 89+4
Global $iLeft = 192, $iTop = 152, $iWidth=800, $iHeight=475
If $bRememberWindowSizePos Then SD_GUI_LoadSizePos()

;CheckForEraVersion()

SD_GUI_ReCreate()

Dim $aWindowSize
While 1
	Sleep(50)
	If Not $bGUINeedUpdate And Not WinActive($hFormMain) Then
		$bGUINeedUpdate = True
	EndIf

	If $bGUINeedUpdate And WinActive($hFormMain) Then
		$bGUINeedUpdate = False
		Local $sListFile = Settings_Global("Get", "List")
		Local $sNewDate = FileGetTime($sListFile, 0, 1)
		If $sNewDate<>$sMListUpdate Then SD_GUI_Update()
		$sMListUpdate = $sNewDate
	EndIf

	If $bEnableDisable Then
		$bEnableDisable = False
		SD_GUI_Mod_EnableDisable()
	EndIf
WEnd

Func CheckForEraVersion() ; Not used yet
	Local $sFile = @ScriptDir & "\..\..\era.dll"
	Local $sVersion = FileGetVersion($sFile, "Version")
	If $sVersion < 2500 Then
		MsgBox(4096, Lng_Get(""), Lng_Get(""))
		MsgBox(4096, Lng_Get(""), Lng_Get(""))
	EndIf
EndFunc

Func SD_GUI_Language_Change()
	Local $iIndex = -1
	For $iCount = 1 To $aLanguages[0][0]
		If @GUI_CtrlId=$aLanguages[$iCount][0] Then
			$iIndex = $iCount
			ExitLoop
		EndIf
	Next

	If $iIndex = -1 Then Return False
	$sLanguage = $aLanguages[$iIndex][1]

	Local $sLoaded = Lng_LoadFile($sLanguage)
	If @error Then
		MsgBox(64+4096, "", $sLoaded, Default, $hFormMain)
	Else
		Settings_Set("Language", $sLanguage)
	EndIf

	SD_GUI_SetLng()
	SD_GUI_Update()
	Return $sLanguage
EndFunc

Func SD_GUI_ReCreate()
	If IsHWnd($hFormMain) Then
		If $bRememberWindowSizePos Then SD_GUI_SaveSizePos()
		If $bRememberWindowSizePos Then SD_GUI_LoadSizePos()

		$hTreeView = 0
		SD_GUI_Events_UnRegister()
		GUIDelete($hFormMain)
	EndIf

	If Not $bModMaker Then
		$iModMakerPlace = 0
	Else
		$iModMakerPlace = 89+4
	EndIf
	SD_GUI_Create()
	TreeViewTryFollow($sFollowMod)
EndFunc

Func SD_GUI_Create()
	$hFormMain = 	GUICreate(StringFormat(Lng_Get("main.title"), $_VERSION), 800+$iModMakerPlace, 455, 192, 152, BitOr($GUI_SS_DEFAULT_GUI, $WS_SIZEBOX), $WS_EX_ACCEPTFILES)
	GUISwitch($hFormMain)
	$hGroupModList = GUICtrlCreateGroup("Mod load order control", 8, 8, 473+$iModMakerPlace, 441)
;~ 	$hTreeView = 	GUICtrlCreateTreeView(16, 24, 361, 417, BitOR($TVS_HASBUTTONS, $TVS_HASLINES, $TVS_DISABLEDRAGDROP, $TVS_SHOWSELALWAYS), $WS_EX_CLIENTEDGE)
					TreeViewMain($hTreeView, $auModList, $auTreeView)
	$hModMoveUp = GUICtrlCreateButton("Up", 384, 24, 89, 25)
	$hModMoveDown =	GUICtrlCreateButton("Down", 384, 56, 89, 25)
	$hModEnableDisable = GUICtrlCreateButton("Enable/Disable", 384, 88, 89, 25)
	GUICtrlSetData($hModEnableDisable, Lng_Get("group.modlist.disable"))
	$hModCompatibility = GUICtrlCreateButton("Compatibility", 384, 120, 89, 25)
	GUICtrlSetState($hModCompatibility, $GUI_DISABLE)
 	$hButtonMoreActions = GUICtrlCreateButton("More actions", 384, 152, 89, 25)
	Local $hMoreActionsDummy = GUICtrlCreateDummy()
	$hDummyF5 = GUICtrlCreateDummy()
	$hMoreActionsContextMenuID = GUICtrlCreateContextMenu($hMoreActionsDummy)
	$hButtonPlugins = GUICtrlCreateMenuItem("Plugins", $hMoreActionsDummy)
	$hModWebSite = GUICtrlCreateMenuItem("Website", $hMoreActionsDummy)
	$hModDelete = GUICtrlCreateMenuItem("Delete", $hMoreActionsDummy)
	$hModAdd = GUICtrlCreateButton("Add new", 384, 455-32-8-32, 89, 25)
	$hModOpenFolder = GUICtrlCreateButton("Open Folder", 384+$iModMakerPlace, 24, 89, 25)
	$hModInfoC = GUICtrlCreateButton("mod_info.ini", 384+$iModMakerPlace, 56, 89, 25)
	$hModReadmeC = GUICtrlCreateButton("Create Readme", 384+$iModMakerPlace, 88, 89, 25)
	If Not $bModMaker Then
		GUICtrlSetState($hModOpenFolder, $GUI_HIDE)
		GUICtrlSetState($hModInfoC, $GUI_HIDE)
		GUICtrlSetState($hModReadmeC, $GUI_HIDE)
	EndIf
	$hSettings = GUICtrlCreateButton("Settings", 384, 455-32-8, 89, 25)
	$hGroupPresets = GUICtrlCreateGroup("Presets", 488+$iModMakerPlace, 8, 308, 73)
	$hLabelPreset =	GUICtrlCreateLabel("Current preset:", 496+$iModMakerPlace, 25, 97, 17)
	$hPreset = 		GUICtrlCreateInput("None", 600+$iModMakerPlace, 24, 193, 21, BitOR($GUI_SS_DEFAULT_INPUT,$ES_READONLY))
	$hPresetSave = 	GUICtrlCreateButton("Save", 496+$iModMakerPlace, 48, 97, 25)
	$hPresetLoad = 	GUICtrlCreateButton("Load", 600+$iModMakerPlace, 48, 97, 25)
	$hPresetDelete =GUICtrlCreateButton("Delete", 704+$iModMakerPlace, 48, 89, 25)
					GUICtrlCreateGroup("", -99, -99, 1, 1)
	$hGroupGame = 		GUICtrlCreateGroup("Game", 488+$iModMakerPlace, 84, 308, 80+32)
	$hLabelExe  = 	GUICtrlCreateLabel("Game exe", 496+$iModMakerPlace, 108, 100, 17)
	$hComboExe  = 	GUICtrlCreateCombo("h3era.exe", 608+$iModMakerPlace, 104, 169, 21)
					SD_GUI_FillComboExe(@ScriptDir & "\..\..", $hComboExe, Settings_Get("Exe"))
	$hLabelWO  = 	GUICtrlCreateLabel("WoG options", 496+$iModMakerPlace, 130, 100, 17)
	$hComboWO  = 	GUICtrlCreateCombo("settings.dat", 608+$iModMakerPlace, 130, 169, 21)
					SD_GUI_FillComboWo(@ScriptDir & "\..\..", $hComboWO, IniRead(@ScriptDir & "\..\..\wog.ini", "WoGification", "Options_File_Name", "settings.dat"))
	$hButtonRun = 	GUICtrlCreateButton("Run game", 496+$iModMakerPlace, 155, 140, 25)
	$hButtonCSC = 	GUICtrlCreateButton("Create shortcut", 496 + 160+$iModMakerPlace, 155, 136, 25)
	GUICtrlSetState($hButtonCSC, $GUI_DISABLE)
	GUICtrlCreateGroup("", -99, -99, 1, 1)
	$hGroupModInfo = 		GUICtrlCreateGroup("Mod info", 488+$iModMakerPlace, 180+15, 308, 250-32)
	$hModInfo = 	GUICtrlCreateEdit("", 496+$iModMakerPlace, 178+32, 294, 230-32, $ES_READONLY + $ES_AUTOVSCROLL + $WS_VSCROLL)
	GUICtrlCreateGroup("", -99, -99, 1, 1)
	$hButtonChangeLanguage = GUICtrlCreateButton("Language", 800-161-4+$iModMakerPlace, 420, 161, 25)
	Local $hChangeLanguageDummy = GUICtrlCreateDummy()
	$hChangeLanguageContextMenuID = GUICtrlCreateContextMenu($hChangeLanguageDummy)
	Local $asTemp = _FileListToArray(@ScriptDir & "\lng\", "*.ini", 1)

	For $iCount = 1 To $asTemp[0]
		$aLanguages[0][0] += 1
		ReDim $aLanguages[$aLanguages[0][0]+1][2]
		$aLanguages[$iCount][0] = GUICtrlCreateMenuItem(IniRead(@ScriptDir & "\lng\" & $asTemp[$iCount], "lang.info", "lang.name", "Remove, please " & $asTemp[$iCount]), $hChangeLanguageDummy)
		$aLanguages[$iCount][1] = $asTemp[$iCount]
	Next

	SD_GUI_Mod_Controls_Disable()
	TreeViewTryFollow("") ; Workaround : if Mod is already selected, no SD_GUI_Mod_Controls_Set is called
	SD_GUI_SetResizing()
	SD_GUI_Events_Register()
	SD_GUI_SetLng()
	WinMove($hFormMain, '', $iLeft, $iTop, $iWidth+$iModMakerPlace, $iHeight)
	Local $AccelKeys[1][2] = [["{F5}", $hDummyF5]]
	GUISetAccelerators($AccelKeys)
	GUISetState(@SW_SHOW)
EndFunc

Func SD_GUI_SetResizing()
	GUICtrlSetResizing($hGroupModList, 2+32+64+256)
	GUICtrlSetResizing($hModMoveUp, 802)
	GUICtrlSetResizing($hModMoveDown, 802)
	GUICtrlSetResizing($hModEnableDisable, 802)
	GUICtrlSetResizing($hModCompatibility, 802)
	GUICtrlSetResizing($hButtonMoreActions, 802)
	GUICtrlSetResizing($hModAdd, 802)
	GUICtrlSetResizing($hModOpenFolder, 802)
	GUICtrlSetResizing($hModInfoC, 802)
	GUICtrlSetResizing($hModReadmeC, 802)
	GUICtrlSetResizing($hGroupPresets, 4+32+256+512)
	GUICtrlSetResizing($hLabelPreset, 4+32+256+512)
	GUICtrlSetResizing($hPreset, 4+32+256+512)
	GUICtrlSetResizing($hSettings, 802)
	GUICtrlSetResizing($hPresetSave, 4+32+256+512)
	GUICtrlSetResizing($hPresetLoad, 4+32+256+512)
	GUICtrlSetResizing($hPresetDelete, 4+32+256+512)
	GUICtrlSetResizing($hGroupGame, 4+32+256+512)
	GUICtrlSetResizing($hLabelExe, 4+32+256+512)
	GUICtrlSetResizing($hComboExe, 4+32+256+512)
	GUICtrlSetResizing($hLabelWO, 4+32+256+512)
	GUICtrlSetResizing($hComboWO, 4+32+256+512)
	GUICtrlSetResizing($hButtonRun, 4+32+256+512)
	GUICtrlSetResizing($hButtonCSC, 4+32+256+512)
	GUICtrlSetResizing($hGroupModInfo, 2+4+32+64)
	GUICtrlSetResizing($hModInfo, 2+4+32+64)
	GUICtrlSetResizing($hButtonChangeLanguage, 4+64+256+512)
EndFunc


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
	GUICtrlSetOnEvent($hModWebSite, "SD_GUI_Mod_Website")
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
	GUICtrlSetOnEvent($hComboWo, "SD_GUI_Game_Wo_Change")
	GUICtrlSetOnEvent($hButtonRun, "SD_GUI_Game_Exe_Run")
	GUICtrlSetOnEvent($hButtonCSC, "SD_GUI_Game_Shortcut_Create")
	GUICtrlSetOnEvent($hButtonChangeLanguage, "SD_GUI_Language_Popup")
	GUICtrlSetOnEvent($hDummyF5, "SD_GUI_Update")
	For $iCount = 1 To $aLanguages[0][0]
		GUICtrlSetOnEvent($aLanguages[$iCount][0], "SD_GUI_Language_Change")
	Next
EndFunc

Func SD_GUI_Events_UnRegister()
	GUISetOnEvent($GUI_EVENT_CLOSE, "")
	GUIRegisterMsg($WM_GETMINMAXINFO, "")
	GUIRegisterMsg($WM_DROPFILES, "")
	GUIRegisterMsg($WM_NOTIFY, "")
	GUICtrlSetOnEvent($hModMoveUp, "")
	GUICtrlSetOnEvent($hModMoveDown, "")
	GUICtrlSetOnEvent($hModEnableDisable, "")
	GUICtrlSetOnEvent($hModCompatibility, "")
	GUICtrlSetOnEvent($hButtonMoreActions, "")
	GUICtrlSetOnEvent($hButtonPlugins, "")
	GUICtrlSetOnEvent($hModWebSite, "")
	GUICtrlSetOnEvent($hModDelete, "")
	GUICtrlSetOnEvent($hModAdd, "")
	GUICtrlSetOnEvent($hModOpenFolder, "")
	GUICtrlSetOnEvent($hModInfoC, "")
	GUICtrlSetOnEvent($hModReadmeC, "")
	GUICtrlSetOnEvent($hSettings, "")
	GUICtrlSetOnEvent($hPresetSave, "")
	GUICtrlSetOnEvent($hPresetLoad, "")
	GUICtrlSetOnEvent($hPresetDelete, "")
	GUICtrlSetOnEvent($hComboExe, "")
	GUICtrlSetOnEvent($hButtonRun, "")
	GUICtrlSetOnEvent($hDummyF5, "")
	GUICtrlSetOnEvent($hButtonCSC, "")
	GUICtrlSetOnEvent($hButtonChangeLanguage, "")
	For $iCount = 1 To $aLanguages[0][0]
		GUICtrlSetOnEvent($aLanguages[$iCount][0], "")
	Next

EndFunc

Func SD_GUI_SetLng()
	GUICtrlSetData($hGroupModList, Lng_Get("group.modlist.title"))
	GUICtrlSetData($hModMoveUp, Lng_Get("group.modlist.move_up"))
	GUICtrlSetData($hModMoveDown, Lng_Get("group.modlist.move_down"))
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
	GUICtrlSetData($hLabelWo, Lng_Get("group.game.label_wog_opt"))
	GUICtrlSetData($hButtonRun, Lng_Get("group.game.launch"))
	GUICtrlSetData($hButtonCSC, Lng_Get("group.game.create_csc"))

	GUICtrlSetData($hGroupModInfo, Lng_Get("group.modinfo.title"))
	GUICtrlSetData($hButtonChangeLanguage, StringFormat("Language (%s)", Lng_Get("lang.name")))
	WinSetTitle($hFormMain, "", StringFormat(Lng_Get("main.title"), $_VERSION))
EndFunc

Func SD_GUI_Mod_Compatibility()
	MsgBox(4096, "", $sCompatibilityMessage, Default, $hFormMain)
EndFunc

Func SD_GUI_MoreActionsPopup()
	_GUICtrlMenu_TrackPopupMenu(GUICtrlGetHandle($hMoreActionsContextMenuID), $hFormMain, -1, -1, 1, 1, 1)
EndFunc

Func SD_GUI_Language_Popup()
;~ 	_ArrayDisplay($aLanguages)
	_GUICtrlMenu_TrackPopupMenu(GUICtrlGetHandle($hChangeLanguageContextMenuID), $hFormMain, -1, -1, 1, 1, 1)
EndFunc

Func SD_GUI_Settings()
	GUISetState(@SW_DISABLE, $hFormMain)
	Local $bAssoc = Settings_Get("Assoc")
	Local $iGUIOnEventModeState = AutoItSetOption("GUIOnEventMode", 0)
	Local $iResult = Settings_GUI($hFormMain)
	AutoItSetOption("GUIOnEventMode", $iGUIOnEventModeState)
	GUISetState(@SW_ENABLE, $hFormMain)
	GUISetState(@SW_RESTORE, $hFormMain)

	$bRememberWindowSizePos = Settings_Get("RememberSizePos")
	$bDisplayVersion = Settings_Get("DisplayVersion")
	$bModMaker = Settings_Get("ModMaker")
	$bSyncPresetWithWS = Settings_Get("SyncPresetWithWS")
	Local $bAssocNew = Settings_Get("Assoc")

	If $bAssoc<>$bAssocNew Then
		If $bAssocNew Then
			Assoc_Create()
		Else
			Assoc_Delete()
		EndIf
	EndIf

	If $iResult=1 Then ; ModMaker
		SD_GUI_ReCreate()
	ElseIf $iResult=2 Then ; Icons
		TreeViewDelete()
		SD_GUI_Update()
	ElseIf $iResult=3 Then ; Names
		SD_GUI_Update()
	EndIf


EndFunc

Func SD_GUI_Mod_CreateModifyReadme()
	Local $iTreeViewIndex = TreeViewGetSelectedIndex()
	Local $iModIndex1=$auTreeView[$iTreeViewIndex][2]
	If $iModIndex1<1 Or $iModIndex1>$auModList[0][0] Then Return -1 ; never
	Local $sPath = $sBasePath & "\" & $auModList[$iModIndex1][0] & '\Readme.txt'
	Local $hFile = FileOpen($sPath, 1)
	FileClose($hFile)
	ShellExecute($sPath)
EndFunc

Func SD_GUI_Mod_CreateModifyModInfo()
	Local $iTreeViewIndex = TreeViewGetSelectedIndex()
	Local $iModIndex1=$auTreeView[$iTreeViewIndex][2]
	If $iModIndex1<1 Or $iModIndex1>$auModList[0][0] Then Return -1 ; never
	Local $sPath = $sBasePath & "\" & $auModList[$iModIndex1][0] & '\mod_info.ini'
	Local $bAddInfo = Not FileExists($sPath)
	Local $hFile = FileOpen($sPath, 1+8+32)
	If $bAddInfo Then
		FileWriteLine($hFile, "[info]")
		FileWriteLine($hFile, "; this section contains various settings + default name/description (use English here, please) ")
		FileWriteLine($hFile, "Caption = " & $auModList[$iModIndex1][0])
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
		FileWriteLine($hFile, "Caption." & Lng_Get("lang.code") & " = " & $auModList[$iModIndex1][0])
		FileWriteLine($hFile, "Description File." & Lng_Get("lang.code") & " = Readme.txt")
		FileWriteLine($hFile, "")
		FileWriteLine($hFile, "[Compatibility]")
		FileWriteLine($hFile, "WoG = 1")
		FileWriteLine($hFile, "; usage: 'ModName = value', values are -1 (not compatible) and 1 (compatible) with this mod")
	EndIf

	FileClose($hFile)
	ShellExecute($sPath)
EndFunc

Func SD_GUI_Mod_OpenFolder()
	Local $iTreeViewIndex = TreeViewGetSelectedIndex()
	Local $iModIndex1=$auTreeView[$iTreeViewIndex][2]
	If $iModIndex1<1 Or $iModIndex1>$auModList[0][0] Then Return -1 ; never
	Local $sPath = '"' & $sBasePath & "\" & $auModList[$iModIndex1][0] & '"'
	Local $sExplorer = Settings_Get("Explorer")
	If $sExplorer == "" Then
		ShellExecute($sPath)
	Else
		ShellExecute($sExplorer, $sPath)
	EndIf
EndFunc

Func SD_GUI_FillComboExe($sPath, $hCombo, $sDefault = "h3era.exe")
	If StringRight($sPath, 1) = "\" Then $sPath = StringTrimRight($sPath, 1)
	Local $aFiles = _FileListToArray($sPath & "\", "*.exe", 1)
	If @error Then Return False
	GUICtrlSetData($hCombo, "")
	For $iCount = 1 To $aFiles[0]
		GUICtrlSetData($hCombo, $aFiles[$iCount])
	Next
	If FileExists($sPath & "\" & $sDefault) Then
		GUICtrlSetData($hCombo, $sDefault)
	ElseIf Not FileExists($sPath & "\h3era.exe") Then
		; Нет, ну какого фига нужен менеджер модов без Эры?
	Else
		GUICtrlSetData($hCombo, "h3era.exe")
	EndIf
	Return True
EndFunc

Func SD_GUI_FillComboWo($sPath, $hCombo, $sDefault = "settings.dat")
	If StringRight($sPath, 1) = "\" Then $sPath = StringTrimRight($sPath, 1)
	If $sDefault = "" Then $sDefault = "settings.dat"
	Local $aFiles = _FileListToArray($sPath & "\", "*.dat", 1)

	If @error Then Return False
	GUICtrlSetData($hCombo, "")
	For $iCount = 1 To $aFiles[0]
		GUICtrlSetData($hCombo, $aFiles[$iCount])
	Next
	If FileExists($sPath & "\" & $sDefault) Then
		GUICtrlSetData($hCombo, $sDefault)
	ElseIf Not FileExists($sPath & "\settings.dat") Then
		;
		;MsgBox(4096, Default, "NE")
	Else
		GUICtrlSetData($hCombo, "settings.dat")
		;MsgBox(4096, Default, "Def")
	EndIf
	Return True
EndFunc

Func SD_GUI_Manage_Plugins()
	GUISetState(@SW_DISABLE, $hFormMain)
	Local $iGUIOnEventModeState = AutoItSetOption("GUIOnEventMode", 0)
	Plugins_Manage($auModList[$auTreeView[TreeViewGetSelectedIndex()][2]][0], $hFormMain)
	AutoItSetOption("GUIOnEventMode", $iGUIOnEventModeState)
	GUISetState(@SW_ENABLE, $hFormMain)
	GUISetState(@SW_RESTORE, $hFormMain)
EndFunc

Func SD_GUI_Game_Shortcut_Create()
	Local $sPresetName = GUICtrlRead($hPreset)
	If StringLeft($sPresetName, 1)="*" Then $sPresetName=StringTrimLeft($sPresetName, 1)
	If $sPresetName=Lng_Get("group.presets.none") Then $sPresetName=""
	;If $sPresetName="" Then Return MsgBox(4096, "", Lng_Get(""), Default, $hFormMain)
	Local $sFile = FileSaveDialog("", @DesktopDir, Lng_Get("group.game.sc_filter"), 2+16, "Era II " & $sPresetName , $hFormMain)
	If @error Then Return False
	FileCreateShortcut(@ScriptDir & "\..\..\" & GUICtrlRead($hComboExe), $sFile, @ScriptDir & "\..\..\", 'modlist="' & @ScriptDir & '\presets\' & $sPresetName & '.txt"', StringFormat(Lng_Get("group.game.sc_tip"), $sPresetName))
EndFunc

Func SD_GUI_Mod_AddByDnD($hwnd, $msg, $wParam, $lParam)
	Local $aRet = DllCall("shell32.dll", "int", "DragQueryFile", "int", $wParam, "int", -1, "ptr", 0, "int", 0)
    If @error Then Return SetError(1, 0, 0)
    Local $aDroppedFiles[$aRet[0]+1], $i, $tBuffer = DllStructCreate("char[256]")
	$aDroppedFiles[0] = $aRet[0]
    For $i = 0 To $aRet[0] - 1 ; цикл запрашивает все файлы и папки
        DllCall("shell32.dll", "int", "DragQueryFile", "int", $wParam, "int", $i, "ptr", DllStructGetPtr($tBuffer), "int", DllStructGetSize($tBuffer))
        $aDroppedFiles[$i+1] = DllStructGetData($tBuffer, 1)
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
	PackedMod_InstallGUI_Simple($aModList, $auModList, $hFormMain)
	AutoItSetOption("GUIOnEventMode", $iGUIOnEventModeState)
	GUISetState(@SW_ENABLE, $hFormMain)
	GUISetState(@SW_RESTORE, $hFormMain)

	TreeViewMain($hTreeView, $auModList, $auTreeView)
	TreeViewTryFollow($sFollowMod)
	ControlFocus($hFormMain, "", $hButtonRun)

    Return "GUI_RUNDEFMSG"
EndFunc

Func Mod_ListCheck($aFileList, $sDir = "")
	Local $iTotalMods = 0
	Local $aModList[$aFileList[0]+1][9] ; FilePath, ModName, ModLocalizedName, ModLocalizedDescription, Version, MinVersion, InstalledVersion
	ProgressOn(Lng_Get("add_new.progress.title"), "", "", Default, Default, 16)
	For $iCount = 1 To $aFileList[0]
		Local $sPackedPath = $sDir & $aFileList[$iCount]
		ProgressSet(Round($iCount/$aFileList[0]*100)-1, StringFormat(Lng_Get("add_new.progress.scanned"), $iCount-1, $aFileList[0]) & @LF & $aFileList[$iCount] & @LF & StringFormat(Lng_Get("add_new.progress.found"), $iTotalMods))
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
EndFunc

Func SD_GUI_Mod_Add()
	Local $sFileList = FileOpenDialog("", "", Lng_Get("add_new.filter"), 1+4, "", $hFormMain)
	If @error Then Return False
	GUISetState(@SW_DISABLE, $hFormMain)

	Local $aFileList = StringSplit($sFileList, "|", 2)

	If UBound($aFileList, 1)=1 Then
		ReDim $aFileList[2]
		Local $szDrive, $szDir, $szFName, $szExt
		Local $TestPath = _PathSplit($aFileList[0], $szDrive, $szDir, $szFName, $szExt)
		$aFileList[0] = $szDrive & $szDir
		$aFileList[1] = $szFName & $szExt
	EndIf

	Local $sDirPath = $aFileList[0]
	$aFileList[0] = UBound($aFileList, 1)-1

	Local $aModList = Mod_ListCheck($aFileList, $sDirPath & "\"); FilePath, ModName, ModLocalizedName, ModLocalizedDescription, Version, MinVersion, InstalledVersion, AuthorName, ModWebSite

	GUISetState(@SW_ENABLE, $hFormMain)
	GUISetState(@SW_RESTORE, $hFormMain)

	If $aModList[0][0] = 0 Then
		MsgBox(4096, "", StringFormat(Lng_Get("add_new.no_mods"), "0_O"), Default, $hFormMain)
		Return False
	EndIf

;~ 	_ArrayDisplay($aModList)
	GUISetState(@SW_DISABLE, $hFormMain)
	Local $iGUIOnEventModeState = AutoItSetOption("GUIOnEventMode", 0)
	PackedMod_InstallGUI_Simple($aModList, $auModList, $hFormMain)
	AutoItSetOption("GUIOnEventMode", $iGUIOnEventModeState)
	GUISetState(@SW_ENABLE, $hFormMain)
	GUISetState(@SW_RESTORE, $hFormMain)

	TreeViewMain($hTreeView, $auModList, $auTreeView)
	TreeViewTryFollow($sFollowMod)
	ControlFocus($hFormMain, "", $hButtonRun)
EndFunc

Func SD_CLI_Mod_Add()
	Settings_Global("Set", "List", $sDefaultList)
	Settings_Global("Set", "Path", $sBasePath)
	$auModList = Mod_ListLoad()
	$auModList = Mod_ListLoad()
	Local $aModList = Mod_ListCheck($CMDLine); FilePath, ModName, ModLocalizedName, ModLocalizedDescription, Version, MinVersion, InstalledVersion, AuthorName, ModWebSite

	If $aModList[0][0] = 0 Then
		MsgBox(4096, "", StringFormat(Lng_Get("add_new.no_mods"), "0_O"), Default)
		Return False
	EndIf

;~ 	_ArrayDisplay($aModList)
	Local $iGUIOnEventModeState = AutoItSetOption("GUIOnEventMode", 0)
	Settings_Global("Set", "List", $sDefaultList)
	Settings_Global("Set", "Path", $sBasePath)
	Local $bResult = PackedMod_InstallGUI_Simple($aModList, $auModList, 0)
	AutoItSetOption("GUIOnEventMode", $iGUIOnEventModeState)
	Return $bResult
EndFunc


Func TreeViewTryFollow($sModName = "WoG")
	If $bInTrack Then Return
	$bInTrack = True
	Local $iModIndex = 0
	For $iCount = 1 To $auModList[0][0]
		If $auModList[$iCount][0]=$sModName Then
			$iModIndex = $iCount
			ExitLoop
		EndIf
	Next
	If $iModIndex = 0 Then
		GUICtrlSetState($auTreeView[1][0], $GUI_FOCUS)
		$bInTrack = False
		Return 0
	EndIf
	For $iCount = 0 To UBound($auTreeView, 1)-1
		If $auTreeView[$iCount][2]=$iModIndex Then
;~ 			_GUICtrlTreeView_BeginUpdate($auTreeView[0][0])
;~ 			_GUICtrlTreeView_EnsureVisible($auTreeView[0][0], $auTreeView[1][0])
;~ 			_GUICtrlTreeView_EnsureVisible($auTreeView[0][0], $auTreeView[$iCount][0])
			_GUICtrlTreeView_SelectItem($auTreeView[0][0], $auTreeView[$iCount][0])
;~ 			_GUICtrlTreeView_EndUpdate($auTreeView[0][0])
			;GUICtrlSetState($auTreeView[$iCount][0], $GUI_FOCUS)
			$bInTrack = False
			Return 0
		EndIf
	Next
	$bInTrack = False
EndFunc

Func SD_GUI_Game_Exe_Run()
;~ 	GUISetState(@SW_MINIMIZE, $hFormMain)
	If $sCompatibilityMessage <> "" Then
		Local $iAnswer = MsgBox(4096+4, "", $sCompatibilityMessage & @CRLF & Lng_Get("message.compatibility.launch"), Default, $hFormMain)
		If $iAnswer <> 6 Then Return 0
	EndIf

	Run('"' & @ScriptDir & '\..\..\' & GUICtrlRead($hComboExe) & '"', @ScriptDir & "\..\..\")
	;MsgBox(4096, @error, @ScriptDir & '\..\..\"' & GUICtrlRead($hComboExe) & '"')
	If @error Then Run('"' & GUICtrlRead($hComboExe) & '"', @ScriptDir & "\..\..\")
	Settings_Set("Exe", GUICtrlRead($hComboExe))
EndFunc

Func SD_GUI_Game_Exe_Change()
	Settings_Set("Exe", GUICtrlRead($hComboExe))
EndFunc

Func SD_GUI_Game_Wo_Change()
	IniWrite(@ScriptDir & "\..\..\wog.ini", "WoGification", "Options_File_Name", GUICtrlRead($hComboWo))
EndFunc

Func SD_GUI_Preset_Load()
	Local $sSuggestName = GUICtrlRead($hPreset) & ".txt"
	If StringLeft($sSuggestName, 1)="*" Then $sSuggestName=StringTrimLeft($sSuggestName, 1)
	If $sSuggestName=Lng_Get("group.presets.none") & ".txt" Then $sSuggestName=""
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
			GUICtrlSetData($hComboWo, IniRead(@ScriptDir & "\..\..\wog.ini", "WoGification", "Options_File_Name", "settings.dat"))
		EndIf
		Local $sPresetName = StringTrimRight(StringRegExpReplace($sLoadPath, ".*\\", ""), 4)
		GUICtrlSetData($hPreset, $sPresetName)
		GUICtrlSetState($hButtonCSC, $GUI_ENABLE)

		TreeViewMain($hTreeView, $auModList, $auTreeView)
		TreeViewTryFollow($sFollowMod)
		ControlFocus($hFormMain, "", $hButtonRun)
	EndIf
EndFunc

Func Preset_Load($sLoadPath)
	Local $asPreset
	_FileReadToArray($sLoadPath, $asPreset)
	If @error=2 Then
		Local $asPreset[1]
	ElseIf @error Then
		Return False
	EndIf

	Local $hList = FileOpen($sBasePath & "\list.txt", 2)

	For $iCount = 1 To $asPreset[0]
		FileWriteLine($hList, $asPreset[$iCount])
	Next

	FileClose($hList)

	TreeViewMain($hTreeView, $auModList, $auTreeView)
EndFunc

Func SD_GUI_Preset_Delete()
	Local $sSuggestName = GUICtrlRead($hPreset) & ".txt"
	If StringLeft($sSuggestName, 1)="*" Then $sSuggestName=StringTrimLeft($sSuggestName, 1)
	If $sSuggestName=Lng_Get("group.presets.none") & ".txt" Then $sSuggestName=""
	Local $sDeletePath = FileOpenDialog(Lng_Get("group.presets.dialog_delete"), @ScriptDir & "\presets\", Lng_Get("group.presets.dialog_filter"), 1, $sSuggestName, $hFormMain)
	If @error Then
		Return False
	Else
		If StringLeft($sDeletePath, StringLen(@ScriptDir & "\presets\")) <> @ScriptDir & "\presets\" Then Return False
		FileRecycle($sDeletePath) ; Preset_Delete
		Local $sPresetName = StringTrimRight(StringRegExpReplace($sDeletePath, ".*\\", ""), 4)
		If GUICtrlRead($hPreset)=$sPresetName Then
			GUICtrlSetData($hPreset, Lng_Get("group.presets.none"))
			GUICtrlSetState($hButtonCSC, $GUI_DISABLE)
		EndIf
	EndIf
EndFunc

Func SD_GUI_Preset_Save()
	Local $sSuggestName = GUICtrlRead($hPreset)
	If StringLeft($sSuggestName, 1)="*" Then $sSuggestName=StringTrimLeft($sSuggestName, 1)
	If $sSuggestName=Lng_Get("group.presets.none") Then $sSuggestName=$auModList[1][0]
	Local $sSavePath = FileSaveDialog(Lng_Get("group.presets.dialog_save"), @ScriptDir & "\presets\", Lng_Get("group.presets.dialog_filter"), Default, $sSuggestName, $hFormMain)
	If @error Then
		Return False
	Else
		If StringLeft($sSavePath, StringLen(@ScriptDir & "\presets\")) <> @ScriptDir & "\presets\" Then Return False
		If StringRight($sSavePath, 4)<>".txt" Then
			If StringLeft(StringRight($sSavePath, 4), 1) = "." Then
				$sSavePath = StringTrimRight($sSuggestName, 3) & "txt"
			Else
				$sSavePath &= ".txt"
			EndIf
		EndIf

		Preset_Save($auModList, $sSavePath)
		If $bSyncPresetWithWS Then
			FileDelete($sSavePath & ".e2p")
			FileWriteLine($sSavePath & ".e2p", IniRead(@ScriptDir & "\..\..\wog.ini", "WoGification", "Options_File_Name", ""))
			FileWriteLine($sSavePath & ".e2p", GUICtrlRead($hComboExe))
		EndIf

		Local $sPresetName = StringTrimRight(StringRegExpReplace($sSavePath, ".*\\", ""), 4)
		GUICtrlSetData($hPreset, $sPresetName)
		GUICtrlSetState($hButtonCSC, $GUI_ENABLE)
	EndIf
EndFunc

Func Preset_Save($aModList, $sSavePath)
	Local $sPrevPath = Settings_Global("Set", "List", $sSavePath)
	Mod_ListSave($aModList)
	Settings_Global("Set", "List", $sPrevPath)
EndFunc

Func SD_GUI_SaveSizePos()
	Local $aPos = WinGetPos($hFormMain)
	Settings_Set("Left", $aPos[0])
	Settings_Set("Top", $aPos[1])
	Settings_Set("Width", $aPos[2]-$iModMakerPlace)
	Settings_Set("Height", $aPos[3])
EndFunc

Func SD_GUI_LoadSizePos()
	$iLeft = Settings_Get("Left")
	$iTop = Settings_Get("Top")
	$iWidth = Settings_Get("Width") - $iModMakerPlace
	$iHeight = Settings_Get("Height")
EndFunc

Func SD_GUI_Close()
	If $bRememberWindowSizePos Then SD_GUI_SaveSizePos()
 	Exit
EndFunc

Func SD_GUI_Mod_Website()
	Local $iTreeViewIndex = TreeViewGetSelectedIndex()
	Local $iModIndex1=$auTreeView[$iTreeViewIndex][2]
	If $iModIndex1<1 Or $iModIndex1>$auModList[0][0] Then Return -1 ; never

	Local $sBrowser = Settings_Get("Browser")
	Run(StringReplace($sBrowser, "%1", $auModList[$iModIndex1][6]))
EndFunc

Func SD_GUI_PresetChange()
	If GUICtrlRead($hPreset)<>Lng_Get("group.presets.none") Then
		Local $sPresetName=GUICtrlRead($hPreset)
		If StringLeft($sPresetName, 1)<>"*" Then $sPresetName= "*" & $sPresetName
		GUICtrlSetData($hPreset, $sPresetName)
	EndIf
EndFunc

Func SD_GUI_Mod_Move_Up()
	Local $iTreeViewIndex = TreeViewGetSelectedIndex()
	Local $iModIndex1=$auTreeView[$iTreeViewIndex][2], $iModIndex2
	If $iModIndex1<2 Or $iModIndex1>$auModList[0][0] Then Return -1 ; never
	$iModIndex2=$iModIndex1-1
	SD_GUI_Mod_Swap($iModIndex1, $iModIndex2)
EndFunc

Func SD_GUI_Mod_Move_Down()
	Local $iTreeViewIndex = TreeViewGetSelectedIndex()
	Local $iModIndex1=$auTreeView[$iTreeViewIndex][2], $iModIndex2
	If $iModIndex1<1 Or $iModIndex1>$auModList[0][0]-1 Then Return -1 ; never
	$iModIndex2=$iModIndex1+1
	SD_GUI_Mod_Swap($iModIndex1, $iModIndex2)
EndFunc

Func SD_GUI_Mod_Swap($iModIndex1, $iModIndex2)
	Mod_ListSwap($iModIndex1, $iModIndex2, $auModList)
	TreeViewMain($hTreeView, $auModList, $auTreeView)
	TreeViewTryFollow($sFollowMod)
	ControlFocus($hFormMain, "", @GUI_CtrlId)
	SD_GUI_PresetChange()
EndFunc

Func SD_GUI_Mod_Delete()
	Local $iTreeViewIndex = TreeViewGetSelectedIndex()
	Local $iModIndex=$auTreeView[$iTreeViewIndex][2]
	Local $iAnswer = MsgBox(4+32+256+8192, "", StringFormat(Lng_Get("group.modlist.delete_confirm"), $auModList[$iModIndex][0]), Default, $hFormMain)
	If $iAnswer=7 Then Return False

	Mod_Delete($iModIndex, $auModList)

	TreeViewMain($hTreeView, $auModList, $auTreeView)
	If $auModList[0][0]<$iModIndex Then
		$iModIndex = $auModList[0][0]
	EndIf

	If $iModIndex>0 Then
		$sFollowMod = $auModList[$iModIndex][0]
		TreeViewTryFollow($sFollowMod)
	EndIf
	SD_GUI_PresetChange()
EndFunc

Func SD_GUI_Mod_EnableDisable()
	Local $iTreeViewIndex = TreeViewGetSelectedIndex()
	Local $iModIndex=$auTreeView[$iTreeViewIndex][2]

	If $iModIndex<1 Then Return

	Local $sState = $auModList[$iModIndex][1]
	If $sState = "Disabled" Then
		Mod_Enable($iModIndex, $auModList)
	Else
		Mod_Disable($iModIndex, $auModList)
	EndIf

	TreeViewMain($hTreeView, $auModList, $auTreeView)
	If $sState = "Disabled" Then
		TreeViewTryFollow($sFollowMod)
	Else
		If $iModIndex<>1 Then $iModIndex -= 1
		$sFollowMod = $auModList[$iModIndex][0]
		TreeViewTryFollow($sFollowMod)
	EndIf


	ControlFocus($hFormMain, "", @GUI_CtrlId)
	SD_GUI_PresetChange()
EndFunc

Func SD_GUI_Update()
	GUISwitch($hFormMain)
	TreeViewMain($hTreeView, $auModList, $auTreeView)
	GUICtrlSetState($auTreeView[1][0], $GUI_FOCUS)
	GUICtrlSetData($hComboExe, Settings_Get("Exe"))
	GUICtrlSetData($hComboWo, IniRead(@ScriptDir & "\..\..\wog.ini", "WoGification", "Options_File_Name", "settings.dat"))
	;TreeViewTryFollow($sFollowMod)
EndFunc

Func _2DModListTo1D($aModList)
	Local $aAnswer[1]=[0]
	For $iCount = 1 To $aModList[0][0]
		If $aModList[$iCount][1]="Enabled" Then
			ReDim $aAnswer[UBound($aAnswer, 1)+1]
			$aAnswer[0]+=1
			$aAnswer[$aAnswer[0]]=$aModList[$iCount][0]
		EndIf
	Next
	Return $aAnswer
EndFunc

Func TreeViewDelete()
	If $hTreeView Then GUICtrlDelete($hTreeView)
	$hTreeView = 0
EndFunc

Func TreeViewMain(ByRef $hTreeView, ByRef $auModList, ByRef $auTreeView)
	Settings_Global("Set", "List", $sDefaultList)
	Settings_Global("Set", "Path", $sBasePath)
	$auModList = Mod_ListLoad()
	$abModCompatibilityMap = Mod_CompatibilityMapLoad($auModList)
	;If $hTreeView Then GUICtrlDelete($hTreeView)
	Local $aWindowSize = WinGetClientSize($hFormMain)
;~ 	If<492 Then WinMove($hFormMain, "", Default, Default, Default, 492+25)
	If Not $hTreeView Then
		$hTreeView = GUICtrlCreateTreeView(16, 24, 361, $aWindowSize[1]-40, BitOR($TVS_HASBUTTONS, $TVS_HASLINES, $TVS_FULLROWSELECT, $TVS_DISABLEDRAGDROP, $TVS_SHOWSELALWAYS), $WS_EX_CLIENTEDGE)
	Else
		For $iCount = 1 To UBound($auTreeView, 1)-1
			GUICtrlDelete($auTreeView[$iCount][0])
		Next
	EndIf
	GUICtrlSetResizing($hTreeView, 2+32+256)
	If $hTreeView=0 Then MsgBox(4096, "Этого не должно быть", "@error:	" & @error & @CRLF & "@extended:	" & @extended)
	$auTreeView = TreeViewFill($hTreeView, $auModList)
EndFunc

Func Quit()
	Exit
EndFunc

Func SD_GUI_Mod_Controls_Disable()
	GUICtrlSetState($hModMoveUp, $GUI_DISABLE)
	GUICtrlSetState($hModMoveDown, $GUI_DISABLE)
	GUICtrlSetState($hModEnableDisable, $GUI_DISABLE)
	GUICtrlSetState($hModDelete, $GUI_DISABLE)
	GUICtrlSetState($hButtonPlugins, $GUI_DISABLE)
	GUICtrlSetState($hModWebSite, $GUI_DISABLE)
	GUICtrlSetState($hButtonMoreActions, $GUI_DISABLE)
	GUICtrlSetState($hModOpenFolder, $GUI_DISABLE)
	GUICtrlSetState($hModReadmeC, $GUI_DISABLE)
	GUICtrlSetState($hModInfoC, $GUI_DISABLE)
EndFunc

Func SD_GUI_Mod_Controls_Set()
	For $iCount = 0 To UBound($auTreeView, 1)-1
		If $auTreeView[$iCount][2]=-1 Then ContinueLoop
		If @GUI_CtrlId<>$auTreeView[$iCount][0] Then ContinueLoop
;~ 		_ArrayDisplay($auModList)
		Local $iModIndex = $auTreeView[$iCount][2]
		$sFollowMod = $auModList[$iModIndex][0]
		If $iModIndex>0 And $iModIndex<=$auModList[0][0] Then
;~ 			_ArrayDisplay($auTreeView)

			; Info (5)
			GUICtrlSetData($hModInfo, Mod_InfoLoad($auModList[$iModIndex][0], $auModList[$iModIndex][5]))

			; MoveUp (2)
			If $iModIndex>0 And $iModIndex<>-1 And $auTreeView[$iCount-1][2]<>-1 And _
				$auModList[$iModIndex][1]="Enabled" And $auModList[$auTreeView[$iCount-1][2]][1]="Enabled" Then
				GUICtrlSetState($hModMoveUp, $GUI_ENABLE)
			Else
				GUICtrlSetState($hModMoveUp, $GUI_DISABLE)
			EndIf

			; MoveDown (2)
			If $iModIndex<$auModList[0][0] And $iModIndex<>-1 And $auTreeView[$iCount+1][2]<>-1 And _
				$auModList[$auTreeView[$iCount][2]][1]="Enabled" And $auModList[$auTreeView[$iCount+1][2]][1]="Enabled" Then
				GUICtrlSetState($hModMoveDown, $GUI_ENABLE)
			Else
				GUICtrlSetState($hModMoveDown, $GUI_DISABLE)
			EndIf

			; Enable/Disable/Remove (1,2)
			GUICtrlSetState($hModEnableDisable, $GUI_ENABLE)
			If $auModList[$auTreeView[$iCount][2]][1]="Disabled" Then
				GUICtrlSetData($hModEnableDisable, Lng_Get("group.modlist.enable"))
			ElseIf $auModList[$auTreeView[$iCount][2]][2] Then ; Not exist
				GUICtrlSetData($hModEnableDisable, Lng_Get("group.modlist.remove"))
			Else
				GUICtrlSetData($hModEnableDisable, Lng_Get("group.modlist.disable"))
			EndIf

			; Plugins
			If Plugins_ModHavePlugins($auModList[$iModIndex][0]) Then
				GUICtrlSetState($hButtonPlugins, $GUI_ENABLE)
			Else
				GUICtrlSetState($hButtonPlugins, $GUI_DISABLE)
			EndIf

			; Website (6)
			If $auModList[$iModIndex][6] Then
				GUICtrlSetState($hModWebSite, $GUI_ENABLE)
			Else
				GUICtrlSetState($hModWebSite, $GUI_DISABLE)
			EndIf

			; Delete (2)
			If $auModList[$iModIndex][2] Then
				GUICtrlSetState($hModDelete, $GUI_DISABLE)
			Else
				GUICtrlSetState($hModDelete, $GUI_ENABLE)
			EndIf

			; More actions (2)
			If Not $auModList[$iModIndex][2] Then
				GUICtrlSetState($hButtonMoreActions, $GUI_ENABLE)
			Else
				GUICtrlSetState($hButtonMoreActions, $GUI_DISABLE)
			EndIf

			; Modmaker (settings, 2)
			If Not $auModList[$iModIndex][2] Then
				GUICtrlSetState($hModOpenFolder, $GUI_ENABLE)
				GUICtrlSetState($hModReadmeC, $GUI_ENABLE)
				GUICtrlSetState($hModInfoC, $GUI_ENABLE)
			Else
				GUICtrlSetState($hModOpenFolder, $GUI_DISABLE)
				GUICtrlSetState($hModReadmeC, $GUI_DISABLE)
				GUICtrlSetState($hModInfoC, $GUI_DISABLE)
			EndIf
		EndIf

		;TreeViewTryFollow($sFollowMod)
		ExitLoop
	Next
EndFunc

Func TreeViewFill($hRoot, $aModList)
	_GUICtrlTreeView_BeginUpdate($hRoot)
;~ 	_ArrayDisplay($aModList)
	Local $aTreeViewData[$aModList[0][0]+3][3] ; $TreeViewHandle, $ParentIndex, $ModIndex

	$aTreeViewData[0][0] = $hRoot
;~ 	If Not $hRoot Then MsgBox(Default, Default, Default)
	$aTreeViewData[0][1] = -1
	$aTreeViewData[0][2] = -1


	$aTreeViewData[1][0] = GUICtrlCreateTreeViewItem(Lng_Get("group.modlist.label_enabled"), $aTreeViewData[0][0]) ; Enabled
						   GUICtrlSetColor($aTreeViewData[1][0], 0x0000C0)
						   GUICtrlSetOnEvent($aTreeViewData[1][0], "SD_GUI_Mod_Controls_Disable")
						   If Settings_Get("IconSize")>0 Then _GUICtrlTreeView_SetIconX($aTreeViewData[0][0], $aTreeViewData[1][0], @ScriptDir & "\icons\Sign-Select.ico", 0, 6, Settings_Get("IconSize"))
						   ;If @error Then MsgBox(4096, @error, Default)
	$aTreeViewData[1][1] = 0
	$aTreeViewData[1][2] = -1

	$aTreeViewData[2][0] = GUICtrlCreateTreeViewItem(Lng_Get("group.modlist.label_disabled"), $aTreeViewData[0][0]) ; Disabled
						   GUICtrlSetColor($aTreeViewData[2][0], 0x0000C0)
						   GUICtrlSetOnEvent($aTreeViewData[2][0], "SD_GUI_Mod_Controls_Disable")
						   If Settings_Get("IconSize")>0 Then _GUICtrlTreeView_SetIconX($aTreeViewData[0][0], $aTreeViewData[2][0], @ScriptDir & "\icons\Sign-Stop.ico", 0, 6, Settings_Get("IconSize"))
	$aTreeViewData[2][1] = 0
	$aTreeViewData[2][2] = -1

	Local $bMasterIndex = 0
	$sCompatibilityMessage = ""
	GUICtrlSetState($hModCompatibility, $GUI_DISABLE)

	For $iCount = 2 To $aModList[0][0]+1
		$aTreeViewData[$iCount+1][2] = $iCount-1

		If $aModList[$iCount-1][1] = "Enabled" Then ; Parent is label ("Enabled" or "Disabled")
			$aTreeViewData[$iCount+1][1] = 1
		Else
			$aTreeViewData[$iCount+1][1] = 2
		EndIf

		$aTreeViewData[$iCount+1][0] = GUICtrlCreateTreeViewItem(Mod_MakeDisplayName($aModList[$iCount-1][3], _
		$aModList[$iCount-1][2], $aModList[$iCount-1][0], $aModList[$iCount-1][8], $bDisplayVersion), $aTreeViewData[$aTreeViewData[$iCount+1][1]][0])
									   GUICtrlSetOnEvent($aTreeViewData[$iCount+1][0], "SD_GUI_Mod_Controls_Set")
		If $aModList[$iCount-1][2] Then GUICtrlSetColor($aTreeViewData[$iCount+1][0], 0xC00000) ; Is Exist?
		If Settings_Get("IconSize")>0 Then
			If $aModList[$iCount-1][7] <> "" And FileExists($sBasePath & "\" & $aModList[$iCount-1][0] & "\" & $aModList[$iCount-1][7]) Then
				_GUICtrlTreeView_SetIconX($aTreeViewData[0][0], $aTreeViewData[$iCount+1][0], $sBasePath & "\" & $aModList[$iCount-1][0] & "\" & $aModList[$iCount-1][7], 0, 6, Settings_Get("IconSize"))
			Else
				_GUICtrlTreeView_SetIconX($aTreeViewData[0][0], $aTreeViewData[$iCount+1][0], @ScriptDir & "\icons\Folder-grey.ico", 0, 6, Settings_Get("IconSize"))
			EndIf
		EndIf

		If $bMasterIndex = 0 And $aModList[$iCount-1][1] = "Enabled" And Not $aModList[$iCount-1][2] Then
			For $jCount = 1 To $auModList[0][0]
				If $jCount = $iCount-1 Then ContinueLoop
				If $aModList[$jCount][1] = "Disabled" Or $aModList[$jCount][2] Then ContinueLoop
				If Not $abModCompatibilityMap[$iCount-1][$jCount] Then
					$bMasterIndex = $iCount-1
					GUICtrlSetColor($aTreeViewData[$iCount+1][0], 0x00C000) ; This is master mod
					$sCompatibilityMessage = StringFormat(Lng_Get("message.compatibility.part1"), $aModList[$iCount-1][3]) & @CRLF
					ExitLoop
				EndIf
			Next
		ElseIf $bMasterIndex > 0 And $aModList[$iCount-1][1] = "Enabled" And Not $aModList[$iCount-1][2] Then
			If Not $abModCompatibilityMap[$bMasterIndex][$iCount-1] Then
				GUICtrlSetColor($aTreeViewData[$iCount+1][0], 0xCC0000) ; This is slave mod
				$sCompatibilityMessage &= $aModList[$iCount-1][3] & @CRLF
			EndIf
		EndIf
	Next

	If $sCompatibilityMessage <> "" Then
		$sCompatibilityMessage &= @CRLF & Lng_Get("message.compatibility.part2")
		GUICtrlSetState($hModCompatibility, $GUI_ENABLE)
	EndIf


	GUICtrlSetState($aTreeViewData[1][0], $GUI_EXPAND)
	GUICtrlSetState($aTreeViewData[2][0], $GUI_EXPAND)

	;_ArrayDisplay($aTreeViewData)
	_GUICtrlTreeView_EndUpdate($hRoot)
	Return $aTreeViewData
EndFunc

Func TreeViewGetSelectedIndex()
	Local $iSelected = GUICtrlRead($hTreeView)
	For $iCount = 0 To UBound($auTreeView, 1)-1
		If $auTreeView[$iCount][0]=$iSelected Then Return $iCount
	Next
EndFunc

Func Assoc_Create()
	If Not IsAdmin() Then
		Return ShellExecuteWait(@ScriptFullPath, '/assocset', @WorkingDir , "runas", @SW_SHOWNORMAL)
	EndIf

	RegWrite("HKCR\.emp", "", "REG_SZ", "Era.ModManager.Package")
	RegWrite("HKCR\Era.ModManager.Package", "", "REG_SZ", "Era II Mod Manager Package File")
	RegWrite("HKCR\Era.ModManager.Package\shell\open\command", "", "REG_SZ", '"' & @ScriptFullPath & '" "%1"')
	RegWrite("HKCR\Era.ModManager.Package\DefaultIcon", "", "REG_SZ", @ScriptDir & "\icons\package.ico,0")
	Dim Const $SHCNE_ASSOCCHANGED = 0x8000000
	Dim Const $SHCNF_IDLIST = 0
	Dim Const $NULL = 0

	DllCall("shell32.dll", "none", "SHChangeNotify", "long", $SHCNE_ASSOCCHANGED, "int", $SHCNF_IDLIST, "ptr", 0, "ptr", 0)
EndFunc

Func Assoc_Delete()
	If Not IsAdmin() Then
		Return ShellExecuteWait(@ScriptFullPath, '/assocdel', @WorkingDir , "runas", @SW_SHOWNORMAL)
	EndIf

	RegDelete("HKCR\.emp")
	RegDelete("HKCR\Era.ModManager.Package")
	Dim Const $SHCNE_ASSOCCHANGED = 0x8000000
	Dim Const $SHCNF_IDLIST = 0
	Dim Const $NULL = 0

	DllCall("shell32.dll", "none", "SHChangeNotify", "long", $SHCNE_ASSOCCHANGED, "int", $SHCNF_IDLIST, "ptr", 0, "ptr", 0)
EndFunc

Func _GUICtrlTreeView_SetIconX($hWnd, $hItem = 0, $sIconFile = "", $iIconID = 0, $iImageMode = 6, $iIconSize = 16)

	If $hItem = 0 Then $hItem = 0x00000000

	If $hItem <> 0x00000000 And Not IsHWnd($hItem) Then $hItem = _GUICtrlTreeView_GetItemHandle($hWnd, $hItem)
	If $hItem = 0x00000000 Or $sIconFile = "" Then Return SetError(1, 1, False)

	If Not IsHWnd($hWnd) Then $hWnd = GUICtrlGetHandle($hWnd)

	Local $tTVITEM = DllStructCreate($tagTVITEMEX)

	Local $tIcon = DllStructCreate("handle")
	Local $i_count = DllCall("shell32.dll", "uint", "ExtractIconExW", "wstr", $sIconFile, "int", $iIconID, _
			"handle", 0, "struct*", $tIcon, "uint", 1)
	If @error Then Return SetError(@error, @extended, 0)
	If $i_count[0] = 0 Then Return 0

	Local $hImageList = _SendMessage($hWnd, $TVM_GETIMAGELIST, 0, 0, 0, "wparam", "lparam", "handle")
	If $hImageList = 0x00000000 Then
		$hImageList = DllCall("comctl32.dll", "handle", "ImageList_Create", "int", $iIconSize, "int", $iIconSize, "uint", 0x0021, "int", 0, "int", 1)
		If @error Then Return SetError(@error, @extended, 0)
		$hImageList = $hImageList[0]
		If $hImageList = 0 Then Return SetError(1, 1, False)

		_SendMessage($hWnd, $TVM_SETIMAGELIST, 0, $hImageList, 0, "wparam", "handle")
	EndIf

	Local $hIcon = DllStructGetData($tIcon, 1)
	Local $i_icon = DllCall("comctl32.dll", "int", "ImageList_AddIcon", "handle", $hImageList, "handle", $hIcon)
	$i_icon = $i_icon[0]
	If @error Then
		Local $iError = @error, $iExtended = @extended
		DllCall("user32.dll", "int", "DestroyIcon", "handle", $hIcon)
		; No @error test because results are unimportant.
		Return SetError($iError, $iExtended, 0)
	EndIf

	DllCall("user32.dll", "int", "DestroyIcon", "handle", $hIcon)
	; No @error test because results are unimportant.

	Local $iMask = BitOR($TVIF_IMAGE, $TVIF_SELECTEDIMAGE)

	If BitAND($iImageMode, 2) Then
		DllStructSetData($tTVITEM, "Image", $i_icon)
		If Not BitAND($iImageMode, 4) Then $iMask = $TVIF_IMAGE
	EndIf

	If BitAND($iImageMode, 4) Then
		DllStructSetData($tTVITEM, "SelectedImage", $i_icon)
		If Not BitAND($iImageMode, 2) Then
			$iMask = $TVIF_SELECTEDIMAGE
		Else
			$iMask = BitOR($TVIF_IMAGE, $TVIF_SELECTEDIMAGE)
		EndIf
	EndIf

	DllStructSetData($tTVITEM, "Mask", $iMask)
	DllStructSetData($tTVITEM, "hItem", $hItem)

	Return __GUICtrlTreeView_SetItem($hWnd, $tTVITEM)
EndFunc   ;==>_GUICtrlTreeView_SetIcon

Func WM_GETMINMAXINFO($hwnd, $Msg, $wParam, $lParam)
    #forceref $hwnd, $Msg, $wParam, $lParam
    Local $GUIMINWID = 816+$iModMakerPlace, $GUIMINHT = 492 ; set your restrictions here
    Local $GUIMAXWID = 10000, $GUIMAXHT = 10000
    Local $tagMaxinfo = DllStructCreate("int;int;int;int;int;int;int;int;int;int", $lParam)
    DllStructSetData($tagMaxinfo, 7, $GUIMINWID) ; min X
    DllStructSetData($tagMaxinfo, 8, $GUIMINHT) ; min Y
    DllStructSetData($tagMaxinfo, 9, $GUIMAXWID); max X
    DllStructSetData($tagMaxinfo, 10, $GUIMAXHT) ; max Y
    Return 0
EndFunc   ;==>WM_GETMINMAXINFO

Func WM_NOTIFY($hWnd, $iMsg, $iwParam, $ilParam)
    #forceref $hWnd, $iMsg, $iwParam
    Local $hWndFrom, $iIDFrom, $iCode, $tNMHDR, $hWndTreeview
    $hWndTreeview = $hTreeView
    If Not IsHWnd($hTreeView) Then $hWndTreeview = GUICtrlGetHandle($hTreeView)
	If Not IsHWnd($hWndTreeview) Then Return $GUI_RUNDEFMSG

    $tNMHDR = DllStructCreate($tagNMHDR, $ilParam)
    $hWndFrom = HWnd(DllStructGetData($tNMHDR, "hWndFrom"))
    $iIDFrom = DllStructGetData($tNMHDR, "IDFrom")
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
