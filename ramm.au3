#NoTrayIcon
#cs
	; this is a drity hack to allow easy overwrite #AutoIt3Wrapper_Res_Fileversion via simple IniWrite in make_build.au3
	[Version]
#ce
#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Version=Beta
#AutoIt3Wrapper_Icon=icons\preferences-system.ico
#AutoIt3Wrapper_Outfile=ramm.exe
#AutoIt3Wrapper_Compression=4
#AutoIt3Wrapper_UseUpx=y
#AutoIt3Wrapper_Res_Description=A mod manager for Era II
#AutoIt3Wrapper_Res_Fileversion=0.90.4.2
#AutoIt3Wrapper_Res_LegalCopyright=Aliaksei SyDr Karalenka
#AutoIt3Wrapper_Res_requestedExecutionLevel=asInvoker
#AutoIt3Wrapper_AU3Check_Parameters=-d -w 1 -w 2 -w 3 -w 4 -w 5 -w 6 -w 7
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
; Author:         Aliaksei SyDr Karalenka

#include "include_fwd.au3"

#include "folder_mods.au3"
#include "lng.au3"
#include "packed_mods.au3"
#include "plugins.au3"
#include "settings.au3"
#include "startup.au3"
#include "update.au3"
#include "ui.au3"

AutoItSetOption("MustDeclareVars", 1)
AutoItSetOption("GUIOnEventMode", 1)
AutoItSetOption("GUICloseOnESC", 1)
If Not @Compiled Then AutoItSetOption("TrayIconHide", 0)

#Region Variables
Global $hGUI[]
$hGUI.MenuMod = MapEmpty()
$hGUI.MenuGame = MapEmpty()
$hGUI.MenuMore = MapEmpty()
$hGUI.MenuHelp = MapEmpty()
$hGUI.ModList = MapEmpty()
$hGUI.PluginsList = MapEmpty()
$hGUI.Info = MapEmpty()
$hGUI.WindowResizeInProgress = False
Global $hDummyF5, $hDummyLinks
Global Const $iItemSpacing = 4

Global $aModListGroups[1][3]; group item id, is enabled, priority
Global $aPlugins[1][2], $hPluginsParts[3]
Global $sFollowMod = ""
Global $bEnableDisable, $bSelectionChanged
Global $bInTrack = False
#EndRegion Variables

If @Compiled And @ScriptName = "installmod.exe" Then
	StartUp_WorkAsInstallmod()
EndIf

If $CMDLine[0] > 0 And $CMDLine[1] = '/assocdel' Then
	StartUp_Assoc_Delete()
EndIf

$MM_SETTINGS_LANGUAGE = Settings_Get("language")
Lng_LoadList()
Lng_Load()

If $CMDLine[0] > 0 Then
	If Not SD_CLI_Mod_Add() Then Exit
EndIf

StartUp_CheckRunningInstance()

If Not IsDeclared("__MM_NO_UI") Then
	UI_Main()
EndIf

Func UI_Main()
	SD_GUI_LoadSize()
	SD_GUI_Create()
	TreeViewMain()
	TreeViewTryFollow($MM_LIST_CONTENT[0][0] > 0 ? $MM_LIST_CONTENT[1][$MOD_ID] : "")
	SD_SwitchView()
	SD_SwitchSubView()
	MainLoop()
EndFunc

Func MainLoop()
	Local $bGUINeedUpdate = False

	While True
		Sleep(50)
		If Not $bGUINeedUpdate And Not WinActive($MM_UI_MAIN) Then
			$bGUINeedUpdate = True
		EndIf

		If $bGUINeedUpdate And WinActive($MM_UI_MAIN) Then
			$bGUINeedUpdate = False
			If Not Mod_ListIsActual() Then SD_GUI_Update()
		EndIf

		If $bEnableDisable Then
			$bEnableDisable = False
			SD_GUI_List_ChangeState()
		EndIf

		If $bSelectionChanged Then
			$bSelectionChanged = False
			SD_GUI_List_SelectionChanged()
		EndIf
	WEnd
EndFunc   ;==>MainLoop

Func SD_GUI_Language_Change()
	Local $iIndex = -1
	For $iCount = 1 To $MM_LNG_LIST[0][0]
		If @GUI_CtrlId = $MM_LNG_LIST[$iCount][$MM_LNG_MENU_ID] Then
			$iIndex = $iCount
			ExitLoop
		EndIf
	Next

	If $iIndex = -1 Then Return False
	$MM_SETTINGS_LANGUAGE = $MM_LNG_LIST[$iIndex][$MM_LNG_FILE]

	Local $sIsLoaded = Lng_Load()
	If @error Then
		MsgBox($MB_ICONINFORMATION + $MB_SYSTEMMODAL, "", $sIsLoaded, Default, $MM_UI_MAIN)
	Else
		Settings_Set("Language", $MM_SETTINGS_LANGUAGE)
	EndIf

	SD_GUI_SetLng()
	SD_GUI_Update()
EndFunc   ;==>SD_GUI_Language_Change

Func SD_GUI_Create()
	Local Const $iOptionGUICoordMode = AutoItSetOption("GUICoordMode", 0)

	$MM_UI_MAIN = GUICreate($MM_TITLE, $MM_WINDOW_MIN_WIDTH, $MM_WINDOW_MIN_HEIGHT, Default, Default, BitOR($GUI_SS_DEFAULT_GUI, $WS_SIZEBOX, $WS_MAXIMIZEBOX), $WS_EX_ACCEPTFILES)
	$MM_WINDOW_MIN_WIDTH_FULL = WinGetPos($MM_UI_MAIN)[2]
	$MM_WINDOW_MIN_HEIGHT_FULL = WinGetPos($MM_UI_MAIN)[3]
	GUISetIcon(@ScriptDir & "\icons\preferences-system.ico")

	$hGUI.MenuLanguage = GUICtrlCreateMenu("-")
	For $iCount = 1 To $MM_LNG_LIST[0][0]
		$MM_LNG_LIST[$iCount][$MM_LNG_MENU_ID] = GUICtrlCreateMenuItem($MM_LNG_LIST[$iCount][$MM_LNG_NAME], $hGUI.MenuLanguage, Default, 1)
		If $MM_LNG_LIST[$iCount][$MM_LNG_FILE] = $MM_SETTINGS_LANGUAGE Then GUICtrlSetState($MM_LNG_LIST[$iCount][$MM_LNG_MENU_ID], $GUI_CHECKED)
	Next

	$hGUI.MenuMod.Menu = GUICtrlCreateMenu("-")
	$hGUI.MenuMod.Plugins = GUICtrlCreateMenuItem("-", $hGUI.MenuMod.Menu)
	$hGUI.MenuMod.OpenHomepage = GUICtrlCreateMenuItem("-", $hGUI.MenuMod.Menu)
	$hGUI.MenuMod.Delete = GUICtrlCreateMenuItem("-", $hGUI.MenuMod.Menu)
	$hGUI.MenuMod.OpenFolder = GUICtrlCreateMenuItem("-", $hGUI.MenuMod.Menu)
	If $MM_GAME_NO_DIR Then GUICtrlSetState($hGUI.MenuMod.Menu, $GUI_DISABLE)

	$hGUI.MenuGame.Menu = GUICtrlCreateMenu("-")
	$hGUI.MenuGame.Launch = GUICtrlCreateMenuItem("-", $hGUI.MenuGame.Menu)
	GUICtrlSetState($hGUI.MenuGame.Launch, $MM_GAME_EXE = "" ? $GUI_DISABLE : $GUI_ENABLE)
	GUICtrlCreateMenuItem("", $hGUI.MenuGame.Menu)
	$hGUI.MenuGame.Change = GUICtrlCreateMenuItem("-", $hGUI.MenuGame.Menu)
	If $MM_GAME_NO_DIR Then GUICtrlSetState($hGUI.MenuGame.Menu, $GUI_DISABLE)

	$hGUI.MenuMore.Menu = GUICtrlCreateMenu("-")
	$hGUI.MenuMore.Add = GUICtrlCreateMenuItem("-", $hGUI.MenuMore.Menu)
	$hGUI.MenuMore.Compatibility = GUICtrlCreateMenuItem("-", $hGUI.MenuMore.Menu)
	$hGUI.MenuMore.ChangeModDir = GUICtrlCreateMenuItem("-", $hGUI.MenuMore.Menu)
	If $MM_GAME_NO_DIR Then GUICtrlSetState($hGUI.MenuMore.Add, $GUI_DISABLE)
	If $MM_SETTINGS_PORTABLE Then GUICtrlSetState($hGUI.MenuMore.ChangeModDir, $GUI_DISABLE)

	$hGUI.MenuHelp.Menu = GUICtrlCreateMenu("?")
	$hGUI.MenuHelp.CheckForUpdates = GUICtrlCreateMenuItem("-", $hGUI.MenuHelp.Menu)

	$hGUI.ModList.Group = GUICtrlCreateGroup("-", 0, 0)
	$hGUI.PluginsList.Group = GUICtrlCreateGroup("-", 0, 0)

	$hGUI.ModList.List = GUICtrlCreateTreeView(0, 0, Default, Default, BitOR($TVS_FULLROWSELECT, $TVS_DISABLEDRAGDROP, $TVS_SHOWSELALWAYS), $WS_EX_CLIENTEDGE)
	$hGUI.PluginsList.List = GUICtrlCreateTreeView(0, 0, Default, Default, BitOR($TVS_FULLROWSELECT, $TVS_DISABLEDRAGDROP, $TVS_SHOWSELALWAYS), $WS_EX_CLIENTEDGE)

	$hGUI.ModList.Up = GUICtrlCreateButton("", 0, 0, 90, 25)
	$hGUI.PluginsList.Back = GUICtrlCreateButton("", 0, 0, 90, 25)
	$hGUI.ModList.Down = GUICtrlCreateButton("", 0, 0, 90, 25)
	$hGUI.ModList.ChangeState = GUICtrlCreateButton("", 0, 0, 90, 25)
	GUICtrlSetState($hGUI.PluginsList.Group, $GUI_HIDE)
	GUICtrlSetState($hGUI.PluginsList.List, $GUI_HIDE)
	GUICtrlSetState($hGUI.PluginsList.Back, $GUI_HIDE)

	$hGUI.Info.TabControl = GUICtrlCreateTab(0, 0, Default, Default, BitOR($TCS_FLATBUTTONS, $TCS_BUTTONS, $TCS_FOCUSNEVER))
	$hGUI.Info.TabDesc = GUICtrlCreateTabItem("-")
	$hGUI.Info.TabInfo = GUICtrlCreateTabItem("-")
	$hGUI.Info.TabScreens = GUICtrlCreateTabItem("-")
	GUICtrlCreateTabItem("")

	$hGUI.Info.Edit = GUICtrlCreateEdit("", 0, 0, 0, 0, BitOR($ES_READONLY, $WS_VSCROLL, $WS_TABSTOP))
	$hGUI.Info.Desc = _GUICtrlSysLink_Create($MM_UI_MAIN, "-", 0, 0, 0, 0)

	$hDummyF5 = GUICtrlCreateDummy()
	$hDummyLinks = GUICtrlCreateDummy()

	Local $AccelKeys[1][2] = [["{F5}", $hDummyF5]]
	GUISetAccelerators($AccelKeys)

	SD_GUI_Mod_Controls_Disable()
	SD_GUI_Events_Register()
	SD_GUI_SetLng()
	SD_GUI_MainWindowResize()

	WinMove($MM_UI_MAIN, '', (@DesktopWidth - $MM_WINDOW_WIDTH) / 2, (@DesktopHeight - $MM_WINDOW_HEIGHT) / 2, $MM_WINDOW_WIDTH, $MM_WINDOW_HEIGHT)
	If $MM_WINDOW_MAXIMIZED Then WinSetState($MM_UI_MAIN, '', @SW_MAXIMIZE)

	GUISetState(@SW_SHOW)
	AutoItSetOption("GUICoordMode", $iOptionGUICoordMode)
EndFunc   ;==>SD_GUI_Create

Func WM_SIZE()
	If Not $hGUI.WindowResizeInProgress Then SD_GUI_MainWindowResize()
	Return 0
EndFunc

Func WM_ENTERSIZEMOVE()
	$hGUI.WindowResizeInProgress = True
EndFunc

Func WM_EXITSIZEMOVE()
	SD_GUI_MainWindowResize()
	$hGUI.WindowResizeInProgress = False
EndFunc

Func SD_GUI_MainWindowResize()
	Local $aSize = WinGetClientSize($MM_UI_MAIN)
	If $aSize[0] <> $MM_WINDOW_CLIENT_WIDTH Or $aSize[1] <> $MM_WINDOW_CLIENT_HEIGHT Then
		$MM_WINDOW_CLIENT_WIDTH = $aSize[0]
		$MM_WINDOW_CLIENT_HEIGHT = $aSize[1]
	Else
		Return
	EndIf

	Local Const $iListLength = 400 + ($MM_WINDOW_CLIENT_WIDTH - 800) / 4
	GUICtrlSetPos($hGUI.ModList.Group, $iItemSpacing, $iItemSpacing, $iListLength, $MM_WINDOW_CLIENT_HEIGHT - 2 * $iItemSpacing)
	GUICtrlSetPos($hGUI.PluginsList.Group, GUICtrlGetPos($hGUI.ModList.Group)[0], GUICtrlGetPos($hGUI.ModList.Group)[1], GUICtrlGetPos($hGUI.ModList.Group)[2], GUICtrlGetPos($hGUI.ModList.Group)[3])
	GUICtrlSetPos($hGUI.ModList.List, GUICtrlGetPos($hGUI.ModList.Group)[0] + 2 * $iItemSpacing, GUICtrlGetPos($hGUI.ModList.Group)[1] + 4 * $iItemSpacing, _
			GUICtrlGetPos($hGUI.ModList.Group)[2] - 4 * $iItemSpacing - 90, GUICtrlGetPos($hGUI.ModList.Group)[3] - 6 * $iItemSpacing)
	GUICtrlSetPos($hGUI.PluginsList.List, GUICtrlGetPos($hGUI.ModList.List)[0], GUICtrlGetPos($hGUI.ModList.List)[1], GUICtrlGetPos($hGUI.ModList.List)[2], GUICtrlGetPos($hGUI.ModList.List)[3])
	GUICtrlSetPos($hGUI.ModList.Up, GUICtrlGetPos($hGUI.ModList.List)[0] + GUICtrlGetPos($hGUI.ModList.List)[2] + $iItemSpacing, GUICtrlGetPos($hGUI.ModList.List)[1] - 1, 90, 25)
	GUICtrlSetPos($hGUI.PluginsList.Back, GUICtrlGetPos($hGUI.ModList.Up)[0], GUICtrlGetPos($hGUI.ModList.Up)[1], 90, 25)
	GUICtrlSetPos($hGUI.ModList.Down, GUICtrlGetPos($hGUI.ModList.Up)[0], GUICtrlGetPos($hGUI.ModList.Up)[1] + GUICtrlGetPos($hGUI.ModList.Up)[3] + $iItemSpacing, 90, 25)
	GUICtrlSetPos($hGUI.ModList.ChangeState, GUICtrlGetPos($hGUI.ModList.Down)[0], GUICtrlGetPos($hGUI.ModList.Down)[1] + GUICtrlGetPos($hGUI.ModList.Down)[3] + $iItemSpacing, 90, 25)

	GUICtrlSetPos($hGUI.Info.TabControl, GUICtrlGetPos($hGUI.ModList.Group)[0] + GUICtrlGetPos($hGUI.ModList.Group)[2] + $iItemSpacing, GUICtrlGetPos($hGUI.ModList.Group)[1], $MM_WINDOW_CLIENT_WIDTH - $iListLength - 3 * $iItemSpacing, 19)
	GUICtrlSetPos($hGUI.Info.Edit, GUICtrlGetPos($hGUI.Info.TabControl)[0] + 2, GUICtrlGetPos($hGUI.Info.TabControl)[1] + GUICtrlGetPos($hGUI.Info.TabControl)[3] + $iItemSpacing, _
			GUICtrlGetPos($hGUI.Info.TabControl)[2] - 2, $MM_WINDOW_CLIENT_HEIGHT - (GUICtrlGetPos($hGUI.Info.TabControl)[1] + GUICtrlGetPos($hGUI.Info.TabControl)[3] + 2 * $iItemSpacing))
	ControlMove($hGUI.Info.Desc, '', 0, GUICtrlGetPos($hGUI.Info.Edit)[0], GUICtrlGetPos($hGUI.Info.Edit)[1], GUICtrlGetPos($hGUI.Info.Edit)[2], GUICtrlGetPos($hGUI.Info.Edit)[3])
EndFunc

Func SD_GUI_Events_Register()
	GUISetOnEvent($GUI_EVENT_CLOSE, "SD_GUI_Close")
	GUIRegisterMsgStateful($WM_GETMINMAXINFO, "WM_GETMINMAXINFO") ; Limit min size
	GUIRegisterMsgStateful($WM_DROPFILES, "SD_GUI_Mod_AddByDnD") ; Input files
	GUIRegisterMsgStateful($WM_NOTIFY, "WM_NOTIFY")
	GUIRegisterMsgStateful($WM_SIZE, "WM_SIZE")
	GUIRegisterMsgStateful($WM_ENTERSIZEMOVE, "WM_ENTERSIZEMOVE")
	GUIRegisterMsgStateful($WM_EXITSIZEMOVE, "WM_EXITSIZEMOVE")

	For $iCount = 1 To $MM_LNG_LIST[0][0]
		GUICtrlSetOnEvent($MM_LNG_LIST[$iCount][$MM_LNG_MENU_ID], "SD_GUI_Language_Change")
	Next

	GUICtrlSetOnEvent($hGUI.ModList.Up, "SD_GUI_Mod_Move_Up")
	GUICtrlSetOnEvent($hGUI.ModList.Down, "SD_GUI_Mod_Move_Down")
	GUICtrlSetOnEvent($hGUI.ModList.ChangeState, "SD_GUI_Mod_EnableDisable")
	GUICtrlSetOnEvent($hGUI.MenuMore.Compatibility, "SD_GUI_Mod_Compatibility")
	GUICtrlSetOnEvent($hGUI.MenuMod.Plugins, "SD_GUI_Manage_Plugins")
	GUICtrlSetOnEvent($hGUI.MenuMod.OpenHomepage, "SD_GUI_Mod_Website")
	GUICtrlSetOnEvent($hGUI.MenuMod.Delete, "SD_GUI_Mod_Delete")
	GUICtrlSetOnEvent($hGUI.MenuGame.Launch, "UI_GameExeLaunch")
	GUICtrlSetOnEvent($hGUI.MenuGame.Change, "SD_GUI_GameExeChange")
	GUICtrlSetOnEvent($hGUI.MenuMore.Add, "SD_GUI_Mod_Add")
	GUICtrlSetOnEvent($hGUI.MenuMod.OpenFolder, "SD_GUI_Mod_OpenFolder")
	GUICtrlSetOnEvent($hGUI.MenuMore.ChangeModDir, "SD_GUI_ChangeGameDir")

	GUICtrlSetOnEvent($hGUI.PluginsList.Back, "SD_GUI_Plugins_Close")
	GUICtrlSetOnEvent($hGUI.MenuHelp.CheckForUpdates, "SD_GUI_CheckForUpdates")

	GUICtrlSetOnEvent($hGUI.Info.TabControl, "SD_GUI_TabChanged")

	GUICtrlSetOnEvent($hDummyF5, "SD_GUI_Update")
	GUICtrlSetOnEvent($hDummyLinks, "SD_GUI_Mod_Website")
EndFunc   ;==>SD_GUI_Events_Register

Func SD_GUI_SetLng()
	GUICtrlSetData($hGUI.MenuLanguage, Lng_Get("lang.language"))
	GUICtrlSetData($hGUI.ModList.Group, Lng_GetF("mod_list.caption", Not $MM_GAME_NO_DIR ? $MM_GAME_DIR : Lng_Get("mod_list.no_game_dir")))
	GUICtrlSetData($hGUI.ModList.Up, Lng_Get("mod_list.up"))
	GUICtrlSetData($hGUI.ModList.Down, Lng_Get("mod_list.down"))
	GUICtrlSetData($hGUI.ModList.ChangeState, Lng_Get("mod_list.enable"))

	GUICtrlSetData($hGUI.MenuMod.Menu, Lng_Get("mod_list.mod"))
	GUICtrlSetData($hGUI.MenuMod.Delete, Lng_Get("mod_list.delete"))
	GUICtrlSetData($hGUI.MenuMod.Plugins, Lng_Get("mod_list.plugins"))
	GUICtrlSetData($hGUI.MenuMod.OpenHomepage, Lng_Get("mod_list.homepage"))
	GUICtrlSetData($hGUI.MenuMod.OpenFolder, Lng_Get("mod_list.open_dir"))

	GUICtrlSetData($hGUI.MenuGame.Menu, Lng_Get("game.caption"))
	GUICtrlSetData($hGUI.MenuGame.Launch, Lng_GetF("game.launch", $MM_GAME_EXE))
	GUICtrlSetData($hGUI.MenuGame.Change, Lng_Get("game.change"))

	GUICtrlSetData($hGUI.MenuMore.Menu, Lng_Get("mod_list.more"))
	GUICtrlSetData($hGUI.MenuMore.Compatibility, Lng_Get("mod_list.compatibility"))
	GUICtrlSetData($hGUI.MenuMore.Add, Lng_Get("mod_list.add_new"))
	GUICtrlSetData($hGUI.MenuMore.ChangeModDir, Lng_Get("settings.game_dir.change"))

	GUICtrlSetData($hGUI.MenuHelp.CheckForUpdates, Lng_Get("update.caption"))

	GUICtrlSetData($hGUI.PluginsList.Group, Lng_GetF("plugins_list.caption", $MM_LIST_CONTENT[0][0] > 0 ? $MM_LIST_CONTENT[1][$MOD_ID] : ""))
	GUICtrlSetData($hGUI.PluginsList.Back, Lng_Get("plugins_list.back"))

	GUICtrlSetData($hGUI.Info.TabDesc, Lng_Get("info_group.desc"))
	GUICtrlSetData($hGUI.Info.TabInfo, Lng_Get("info_group.info.caption"))
	GUICtrlSetData($hGUI.Info.TabScreens, Lng_Get("info_group.screens"))

	_GUICtrlSysLink_SetText($hGUI.Info.Desc, SD_FormatDescription())
EndFunc   ;==>SD_GUI_SetLng

Func SD_GUI_Mod_Compatibility()
	MsgBox(4096, "", $MM_COMPATIBILITY_MESSAGE, Default, $MM_UI_MAIN)
EndFunc   ;==>SD_GUI_Mod_Compatibility

Func SD_GUI_CheckForUpdates()
	Update_CheckNewPorgram(Settings_Get("Portable"), $MM_UI_MAIN)
EndFunc   ;==>SD_GUI_CheckForUpdates

Func SD_GUI_Mod_OpenFolder()
	Local $iModIndex1 = TreeViewGetSelectedIndex()
	If $iModIndex1 = -1 Then Return -1 ; never
	Local $sPath = '"' & $MM_LIST_DIR_PATH & "\" & $MM_LIST_CONTENT[$iModIndex1][$MOD_ID] & '"'
	ShellExecute($sPath)
EndFunc   ;==>SD_GUI_Mod_OpenFolder

Func SD_GUI_Manage_Plugins()
	Local $iTreeViewIndex = TreeViewGetSelectedIndex()
	Plugins_ListLoad($MM_LIST_CONTENT[$iTreeViewIndex][$MOD_ID])
	GUICtrlSetData($hGUI.PluginsList.Group, Lng_GetF("plugins_list.caption", $MM_LIST_CONTENT[0][0] > 0 ? Mod_Get("caption", $iTreeViewIndex) : ""))
	SD_GUI_PluginsDisplay()
	SD_SwitchView($MM_VIEW_PLUGINS)
EndFunc   ;==>SD_GUI_Manage_Plugins

Func SD_GUI_Plugins_Close()
	SD_SwitchView($MM_VIEW_MODS)
EndFunc   ;==>SD_GUI_Plugins_Close

Func SD_GUI_GameExeChange()
	Local $sNewExe = UI_SelectGameExe()
	If $MM_GAME_EXE <> $sNewExe Then
		$MM_GAME_EXE = $sNewExe
		GUICtrlSetData($hGUI.MenuGame.Launch, Lng_GetF("game.launch", $MM_GAME_EXE))
		Settings_Set("exe", $MM_GAME_EXE)
		GUICtrlSetState($hGUI.MenuGame.Launch, $MM_GAME_EXE = "" ? $GUI_DISABLE : $GUI_ENABLE)
	EndIf
EndFunc

Func SD_GUI_Mod_AddByDnD($hwnd, $msg, $wParam, $lParam)
	#forceref $hwnd, $Msg, $wParam, $lParam
	Local $aRet = DllCall("shell32.dll", "int", "DragQueryFile", "int", $wParam, "int", -1, "ptr", Null, "int", 0)
	If @error Then Return SetError(1, 0, 0)
	Local $aDroppedFiles[$aRet[0] + 1], $i, $tBuffer = DllStructCreate("char[256]")
	$aDroppedFiles[0] = $aRet[0]
	For $i = 0 To $aRet[0] - 1
		DllCall("shell32.dll", "int", "DragQueryFile", "int", $wParam, "int", $i, "ptr", DllStructGetPtr($tBuffer), "int", DllStructGetSize($tBuffer))
		$aDroppedFiles[$i + 1] = DllStructGetData($tBuffer, 1)
	Next
	DllCall("shell32.dll", "none", "DragFinish", "int", $wParam)
	$tBuffer = 0

	GUISetState(@SW_DISABLE, $MM_UI_MAIN)

	Local $aModList = Mod_ListCheck($aDroppedFiles); FilePath, ModName, ModLocalizedName, ModLocalizedDescription, Version, MinVersion, InstalledVersion, AuthorName, ModWebSite

	GUISetState(@SW_ENABLE, $MM_UI_MAIN)
	GUISetState(@SW_RESTORE, $MM_UI_MAIN)

	If $aModList[0][0] = 0 Then
		MsgBox($MB_SYSTEMMODAL, "", StringFormat(Lng_Get("add_new.progress.no_mods"), "0_O"), Default, $MM_UI_MAIN)
		Return "GUI_RUNDEFMSG"
	EndIf

	GUISetState(@SW_DISABLE, $MM_UI_MAIN)
	Local $iGUIOnEventModeState = AutoItSetOption("GUIOnEventMode", 0)
	PackedMod_InstallGUI_Simple($aModList, $MM_UI_MAIN)
	AutoItSetOption("GUIOnEventMode", $iGUIOnEventModeState)
	GUISetState(@SW_ENABLE, $MM_UI_MAIN)
	GUISetState(@SW_RESTORE, $MM_UI_MAIN)

	TreeViewMain()
	TreeViewTryFollow($sFollowMod)

	Return $GUI_RUNDEFMSG
EndFunc   ;==>SD_GUI_Mod_AddByDnD

Func Mod_ListCheck($aFileList, $sDir = "")
	Local $iTotalMods = 0
	Local $aModList[$aFileList[0] + 1][9] ; FilePath, ModName, ModLocalizedName, ModLocalizedDescription, Version, MinVersion, InstalledVersion
	ProgressOn(Lng_Get("add_new.progress.caption"), "", "", Default, Default, $DLG_MOVEABLE)
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
	Local $sFileList = FileOpenDialog("", "", Lng_Get("add_new.filter"), $FD_FILEMUSTEXIST + $FD_MULTISELECT, "", $MM_UI_MAIN)
	If @error Then Return False
	GUISetState(@SW_DISABLE, $MM_UI_MAIN)

	Local $aFileList = StringSplit($sFileList, "|", $STR_NOCOUNT)

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

	GUISetState(@SW_ENABLE, $MM_UI_MAIN)
	GUISetState(@SW_RESTORE, $MM_UI_MAIN)

	If $aModList[0][0] = 0 Then
		MsgBox($MB_SYSTEMMODAL, "", StringFormat(Lng_Get("add_new.progress.no_mods"), "0_O"), Default, $MM_UI_MAIN)
		Return False
	EndIf

	GUISetState(@SW_DISABLE, $MM_UI_MAIN)
	Local $iGUIOnEventModeState = AutoItSetOption("GUIOnEventMode", 0)
	PackedMod_InstallGUI_Simple($aModList, $MM_UI_MAIN)
	AutoItSetOption("GUIOnEventMode", $iGUIOnEventModeState)
	GUISetState(@SW_ENABLE, $MM_UI_MAIN)
	GUISetState(@SW_RESTORE, $MM_UI_MAIN)

	TreeViewMain()
	TreeViewTryFollow($sFollowMod)
EndFunc   ;==>SD_GUI_Mod_Add

Func SD_CLI_Mod_Add()
	Mod_ListLoad()
	Mod_ListLoad()
	Local $aModList = Mod_ListCheck($CMDLine); FilePath, ModName, ModLocalizedName, ModLocalizedDescription, Version, MinVersion, InstalledVersion, AuthorName, ModWebSite

	If $aModList[0][0] = 0 Then
		MsgBox($MB_SYSTEMMODAL, "", StringFormat(Lng_Get("add_new.no_mods"), "0_O"), Default)
		Return False
	EndIf

	Local $iGUIOnEventModeState = AutoItSetOption("GUIOnEventMode", 0)
	Local $bResult = PackedMod_InstallGUI_Simple($aModList)
	AutoItSetOption("GUIOnEventMode", $iGUIOnEventModeState)

	Return $bResult
EndFunc   ;==>SD_CLI_Mod_Add

Func SD_GUI_SaveSize()
	Local $aPos = WinGetPos($MM_UI_MAIN)

	$MM_WINDOW_WIDTH = $aPos[2]
	$MM_WINDOW_HEIGHT = $aPos[3]
	$MM_WINDOW_MAXIMIZED = BitAND(WinGetState($MM_UI_MAIN), 32) ? True : False

	Settings_Set("maximized", $MM_WINDOW_MAXIMIZED)
	If Not $MM_WINDOW_MAXIMIZED Then
		Settings_Set("width", $MM_WINDOW_WIDTH)
		Settings_Set("height", $MM_WINDOW_HEIGHT)
	EndIf
EndFunc   ;==>SD_GUI_SaveSize

Func SD_GUI_LoadSize()
	$MM_WINDOW_WIDTH = Settings_Get("width")
	$MM_WINDOW_HEIGHT = Settings_Get("height")
	$MM_WINDOW_MAXIMIZED = Settings_Get("maximized")
EndFunc   ;==>SD_GUI_LoadSize

Func SD_GUI_Close()
	SD_GUI_SaveSize()
	Settings_Save()
	Exit
EndFunc   ;==>SD_GUI_Close

Func SD_GUI_Mod_Website()
	Local $iTreeViewIndex = TreeViewGetSelectedIndex()
	If $iTreeViewIndex = -1 Then Return -1 ; never

	Utils_LaunchInBrowser(Mod_Get("homepage", $iTreeViewIndex))
EndFunc   ;==>SD_GUI_Mod_Website

Func SD_GUI_Mod_Move_Up()
	Local $iTreeViewIndex = TreeViewGetSelectedIndex()
	Local $iModIndex1 = $iTreeViewIndex, $iModIndex2
	If $iModIndex1 < 2 Or $iModIndex1 > $MM_LIST_CONTENT[0][0] Then Return -1 ; never
	$iModIndex2 = $iModIndex1 - 1
	SD_GUI_Mod_Swap($iModIndex1, $iModIndex2)
EndFunc   ;==>SD_GUI_Mod_Move_Up

Func SD_GUI_Mod_Move_Down()
	Local $iTreeViewIndex = TreeViewGetSelectedIndex()
	Local $iModIndex1 = $iTreeViewIndex, $iModIndex2
	If $iModIndex1 < 1 Or $iModIndex1 > $MM_LIST_CONTENT[0][0] - 1 Then Return -1 ; never
	$iModIndex2 = $iModIndex1 + 1
	SD_GUI_Mod_Swap($iModIndex1, $iModIndex2)
EndFunc   ;==>SD_GUI_Mod_Move_Down

Func SD_GUI_Mod_Swap($iModIndex1, $iModIndex2)
	Mod_ListSwap($iModIndex1, $iModIndex2)
	TreeViewSwap($iModIndex1, $iModIndex2)
	TreeViewTryFollow($sFollowMod)
;~ 	ControlFocus($MM_UI_MAIN, "", @GUI_CtrlId)
EndFunc   ;==>SD_GUI_Mod_Swap

Func SD_GUI_Mod_Delete()
	Local $iTreeViewIndex = TreeViewGetSelectedIndex()
	Local $iModIndex = $iTreeViewIndex
	Local $iAnswer = MsgBox($MB_YESNO + $MB_ICONQUESTION + $MB_DEFBUTTON2 + $MB_TASKMODAL, "", StringFormat(Lng_Get("mod_list.delete_confirm"), Mod_Get("caption", $iModIndex)), Default, $MM_UI_MAIN)
	If $iAnswer = $IDNO Then Return

	Mod_Delete($iModIndex)
	TreeViewMain()
	If $MM_LIST_CONTENT[0][0] < $iModIndex Then
		$iModIndex = $MM_LIST_CONTENT[0][0]
	EndIf

	If $iModIndex > 0 Then
		$sFollowMod = $MM_LIST_CONTENT[$iModIndex][$MOD_ID]
		TreeViewTryFollow($sFollowMod)
	EndIf
EndFunc   ;==>SD_GUI_Mod_Delete

Func SD_GUI_Mod_EnableDisable()

	Local $iModIndex = TreeViewGetSelectedIndex()
	If $iModIndex < 1 Then Return

	Local $bState = $MM_LIST_CONTENT[$iModIndex][$MOD_IS_ENABLED]
	If Not $bState Then
		Mod_Enable($iModIndex)
	Else
		Mod_Disable($iModIndex)
	EndIf

	TreeViewMain()
	If Not $bState Then
		TreeViewTryFollow($sFollowMod)
	Else
		If $iModIndex <> 1 Then $iModIndex -= 1
		$sFollowMod = $MM_LIST_CONTENT[$iModIndex][$MOD_ID]
		TreeViewTryFollow($sFollowMod)
	EndIf
EndFunc   ;==>SD_GUI_Mod_EnableDisable

Func SD_GUI_Plugin_ChangeState()
	Local $hSelected = _GUICtrlTreeView_GetSelection($hGUI.PluginsList.List)

	For $i = 1 To $aPlugins[0][0]
		If $hSelected <> $aPlugins[$i][0] Then ContinueLoop

		Local $iPlugin = $aPlugins[$i][1]

		If $iPlugin > 0 And $iPlugin <= $MM_PLUGINS_CONTENT[0][0] Then
			Plugins_ChangeState($iPlugin)
			_GUICtrlTreeView_SetIcon($hGUI.PluginsList.List, $aPlugins[$i][0], $MM_PLUGINS_CONTENT[$iPlugin][$PLUGIN_STATE] ? (@ScriptDir & "\icons\dialog-ok-apply.ico") : (@ScriptDir & "\icons\edit-delete.ico"), 0, 6)
		EndIf

		ExitLoop
	Next
EndFunc   ;==>SD_GUI_Plugin_ChangeState

Func SD_GUI_List_ChangeState()
	Switch $MM_VIEW_CURRENT
		Case $MM_VIEW_MODS
			SD_GUI_Mod_EnableDisable()
		Case $MM_VIEW_PLUGINS
			SD_GUI_Plugin_ChangeState()
	EndSwitch
EndFunc   ;==>SD_GUI_List_ChangeState

Func SD_GUI_ChangeGameDir()
	If UI_SelectGameDir() Then
		GUICtrlSetData($hGUI.ModList.Group, Lng_GetF("mod_list.caption", $MM_GAME_DIR))
		GUICtrlSetData($hGUI.MenuGame.Launch, Lng_GetF("game.launch", $MM_GAME_EXE))
		GUICtrlSetState($hGUI.MenuGame.Menu, $GUI_ENABLE)
		GUICtrlSetState($hGUI.MenuMore.Add, $GUI_ENABLE)
		GUICtrlSetState($hGUI.MenuGame.Launch, $MM_GAME_EXE = "" ? $GUI_DISABLE : $GUI_ENABLE)
		SD_GUI_Update()
	EndIf
EndFunc   ;==>SD_GUI_ChangeGameDir

Func SD_GUI_Update()
	GUISwitch($MM_UI_MAIN)
	TreeViewMain()
	If $MM_VIEW_CURRENT = $MM_VIEW_MODS Then TreeViewTryFollow($sFollowMod)
EndFunc   ;==>SD_GUI_Update

Func TreeViewMain()
	Mod_ListLoad()
	Mod_CompatibilityMapLoad()

	_GUICtrlTreeView_BeginUpdate($hGUI.ModList.List)
	_GUICtrlTreeView_DeleteAll($hGUI.ModList.List)
	_GUICtrlTreeView_EndUpdate($hGUI.ModList.List)

	TreeViewFill()
EndFunc   ;==>TreeViewMain

Func SD_GUI_PluginsDisplay()
	_GUICtrlTreeView_BeginUpdate($hGUI.PluginsList.List)
	_GUICtrlTreeView_DeleteAll($hGUI.PluginsList.List)

	If $MM_PLUGINS_PART_PRESENT[$PLUGIN_GROUP_GLOBAL] Then
		$hPluginsParts[$PLUGIN_GROUP_GLOBAL] = _GUICtrlTreeView_Add($hGUI.PluginsList.List, 0, Lng_Get("plugins_list.global"))
		_GUICtrlTreeView_SetIcon($hGUI.PluginsList.List, $hPluginsParts[$PLUGIN_GROUP_GLOBAL], @ScriptDir & "\icons\folder-green.ico", 0, 6)
	EndIf

	If $MM_PLUGINS_PART_PRESENT[$PLUGIN_GROUP_BEFORE] Then
		$hPluginsParts[$PLUGIN_GROUP_BEFORE] = _GUICtrlTreeView_Add($hGUI.PluginsList.List, 0, Lng_Get("plugins_list.before_wog"))
		_GUICtrlTreeView_SetIcon($hGUI.PluginsList.List, $hPluginsParts[$PLUGIN_GROUP_BEFORE], @ScriptDir & "\icons\folder-green.ico", 0, 6)
	EndIf

	If $MM_PLUGINS_PART_PRESENT[$PLUGIN_GROUP_AFTER] Then
		$hPluginsParts[$PLUGIN_GROUP_AFTER] = _GUICtrlTreeView_Add($hGUI.PluginsList.List, 0, Lng_Get("plugins_list.after_wog"))
		_GUICtrlTreeView_SetIcon($hGUI.PluginsList.List, $hPluginsParts[$PLUGIN_GROUP_AFTER], @ScriptDir & "\icons\folder-green.ico", 0, 6)
	EndIf

	ReDim $aPlugins[$MM_PLUGINS_CONTENT[0][0] + 1][2]
	$aPlugins[0][0] = $MM_PLUGINS_CONTENT[0][0]
	Local $hItem
	For $i = 1 To $MM_PLUGINS_CONTENT[0][0]
		$hItem = _GUICtrlTreeView_AddChild($hGUI.PluginsList.List, $hPluginsParts[$MM_PLUGINS_CONTENT[$i][$PLUGIN_GROUP]], $MM_PLUGINS_CONTENT[$i][$PLUGIN_CAPTION])
		_GUICtrlTreeView_SetIcon($hGUI.PluginsList.List, $hItem, $MM_PLUGINS_CONTENT[$i][$PLUGIN_STATE] ? (@ScriptDir & "\icons\dialog-ok-apply.ico") : (@ScriptDir & "\icons\edit-delete.ico"), 0, 6)
		$aPlugins[$i][0] = $hItem
		$aPlugins[$i][1] = $i
	Next

	If $MM_PLUGINS_PART_PRESENT[$PLUGIN_GROUP_GLOBAL] Then _GUICtrlTreeView_Expand($hGUI.PluginsList.List, $hPluginsParts[$PLUGIN_GROUP_GLOBAL], True)
	If $MM_PLUGINS_PART_PRESENT[$PLUGIN_GROUP_BEFORE] Then _GUICtrlTreeView_Expand($hGUI.PluginsList.List, $hPluginsParts[$PLUGIN_GROUP_BEFORE], True)
	If $MM_PLUGINS_PART_PRESENT[$PLUGIN_GROUP_AFTER] Then _GUICtrlTreeView_Expand($hGUI.PluginsList.List, $hPluginsParts[$PLUGIN_GROUP_AFTER], True)

	_GUICtrlTreeView_EndUpdate($hGUI.PluginsList.List)
EndFunc   ;==>SD_GUI_PluginsDisplay

Func SD_GUI_Mod_Controls_Disable()
	GUICtrlSetState($hGUI.ModList.Up, $GUI_DISABLE)
	GUICtrlSetState($hGUI.ModList.Down, $GUI_DISABLE)
	GUICtrlSetState($hGUI.ModList.ChangeState, $GUI_DISABLE)
	GUICtrlSetState($hGUI.MenuMod.Delete, $GUI_DISABLE)
	GUICtrlSetState($hGUI.MenuMod.Plugins, $GUI_DISABLE)
	GUICtrlSetState($hGUI.MenuMod.OpenHomepage, $GUI_DISABLE)
	GUICtrlSetState($hGUI.MenuMod.OpenFolder, $GUI_DISABLE)
	GUICtrlSetState($hGUI.MenuMod.Menu, $GUI_DISABLE)
	GUICtrlSetData($hGUI.Info.Edit, Lng_Get("info_group.no_info"))
	_GUICtrlSysLink_SetText($hGUI.Info.Desc, "")
;~ 	$sFollowMod = ""
EndFunc   ;==>SD_GUI_Mod_Controls_Disable

Func SD_GUI_List_SelectionChanged()
	Switch $MM_VIEW_CURRENT
		Case $MM_VIEW_MODS
			SD_GUI_Mod_SelectionChanged()
		Case $MM_VIEW_PLUGINS
			SD_GUI_Plugin_SelectionChanged()
	EndSwitch
EndFunc   ;==>SD_GUI_List_SelectionChanged

Func SD_GUI_Mod_SelectionChanged()
	Local $iSelected = TreeViewGetSelectedIndex()

	If $iSelected = -1 Then
		SD_GUI_Mod_Controls_Disable()
	Else
		Local $iModIndex = $iSelected
		$MM_SELECTED_MOD = $iModIndex
		Local $iModIndexPrev = $iSelected > 1 ? $iSelected - 1 : -1
		Local $iModIndexNext = $iSelected < $MM_LIST_CONTENT[0][0] ? $iSelected + 1 : -1

		$sFollowMod = $MM_LIST_CONTENT[$iModIndex][$MOD_ID]

		; Info (5)
		GUICtrlSetData($hGUI.Info.Edit, Mod_InfoLoad($MM_LIST_CONTENT[$iModIndex][$MOD_ID], Mod_Get("description\full", $iModIndex)))

		; MoveUp (2)
		If $iModIndexPrev <> -1 And $MM_LIST_CONTENT[$iModIndex][$MOD_IS_ENABLED] And $MM_LIST_CONTENT[$iModIndexPrev][$MOD_IS_ENABLED] And (Mod_Get("priority", $iModIndex) = Mod_Get("priority", $iModIndexPrev)) Then
			GUICtrlSetState($hGUI.ModList.Up, $GUI_ENABLE)
		Else
			GUICtrlSetState($hGUI.ModList.Up, $GUI_DISABLE)
		EndIf

		; MoveDown (2)
		If $iModIndexNext <> -1 And $MM_LIST_CONTENT[$iModIndex][$MOD_IS_ENABLED] And $MM_LIST_CONTENT[$iModIndexNext][$MOD_IS_ENABLED] And (Mod_Get("priority", $iModIndex) = Mod_Get("priority", $iModIndexNext)) Then
			GUICtrlSetState($hGUI.ModList.Down, $GUI_ENABLE)
		Else
			GUICtrlSetState($hGUI.ModList.Down, $GUI_DISABLE)
		EndIf

		; Enable/Disable/Remove (1,2)

		GUICtrlSetState($hGUI.ModList.ChangeState, $GUI_ENABLE)

		If Not $MM_LIST_CONTENT[$iModIndex][$MOD_IS_ENABLED] Then
			GUICtrlSetData($hGUI.ModList.ChangeState, Lng_Get("mod_list.enable"))
		ElseIf Not $MM_LIST_CONTENT[$iModIndex][$MOD_IS_EXIST] Then ; Not exist
			GUICtrlSetData($hGUI.ModList.ChangeState, Lng_Get("mod_list.remove"))
		Else
			GUICtrlSetData($hGUI.ModList.ChangeState, Lng_Get("mod_list.disable"))
		EndIf

		; Plugins
		If Plugins_ModHavePlugins($MM_LIST_CONTENT[$iModIndex][$MOD_ID]) Then
			GUICtrlSetState($hGUI.MenuMod.Plugins, $GUI_ENABLE)
		Else
			GUICtrlSetState($hGUI.MenuMod.Plugins, $GUI_DISABLE)
		EndIf

		; Website (6)
		If Mod_Get("homepage", $iModIndex) Then
			GUICtrlSetState($hGUI.MenuMod.OpenHomepage, $GUI_ENABLE)
		Else
			GUICtrlSetState($hGUI.MenuMod.OpenHomepage, $GUI_DISABLE)
		EndIf

		; Delete (2), Modmaker
		If Not $MM_LIST_CONTENT[$iModIndex][$MOD_IS_EXIST] Then
			GUICtrlSetState($hGUI.MenuMod.Delete, $GUI_DISABLE)
			GUICtrlSetState($hGUI.MenuMod.OpenFolder, $GUI_DISABLE)
			GUICtrlSetState($hGUI.MenuMod.Menu, $GUI_DISABLE)
		Else
			GUICtrlSetState($hGUI.MenuMod.Delete, $GUI_ENABLE)
			GUICtrlSetState($hGUI.MenuMod.OpenFolder, $GUI_ENABLE)
			GUICtrlSetState($hGUI.MenuMod.Menu, $GUI_ENABLE)
		EndIf

		_GUICtrlSysLink_SetText($hGUI.Info.Desc, SD_FormatDescription())
	EndIf
EndFunc   ;==>SD_GUI_Mod_SelectionChanged

Func SD_GUI_Plugin_SelectionChanged()
	Local $hSelected = _GUICtrlTreeView_GetSelection($hGUI.PluginsList.List)
	For $i = 1 To $aPlugins[0][0]
		If $hSelected <> $aPlugins[$i][0] Then ContinueLoop

		Local $iPlugin = $aPlugins[$i][1]

		If $iPlugin > 0 And $iPlugin <= $MM_PLUGINS_CONTENT[0][0] Then
			GUICtrlSetData($hGUI.Info.Edit, $MM_PLUGINS_CONTENT[$iPlugin][$PLUGIN_DESCRIPTION])
		EndIf

		Return
	Next

	GUICtrlSetData($hGUI.Info.Edit, Lng_Get("info_group.no_info"))
EndFunc   ;==>SD_GUI_Plugin_SelectionChanged

Func TreeViewFill()
	_GUICtrlTreeView_BeginUpdate($hGUI.ModList.List)

	Local $bCurrentGroupEnabled = True

	GUICtrlSetState($hGUI.MenuMore.Compatibility, $GUI_DISABLE)

	Local $iCurrentGroup = -1
	$aModListGroups[0][0] = 0

	For $iCount = 1 To $MM_LIST_CONTENT[0][0]
		Local $bEnabled = $MM_LIST_CONTENT[$iCount][$MOD_IS_ENABLED]
		Local $iPriority = Mod_Get("priority", $iCount)
		Local $sCaption = Mod_Get("caption", $iCount) ? Mod_Get("caption", $iCount) : $MM_LIST_CONTENT[$iCount][$MOD_ID]
		$sCaption = $MM_LIST_CONTENT[$iCount][$MOD_IS_EXIST] ? $sCaption : Lng_GetF("mod_list.missing", $sCaption)

		$iCurrentGroup = $aModListGroups[0][0]
		Local $bCreateNewGroup = $iCurrentGroup < 1

		If Not $bCreateNewGroup And $bEnabled And $iPriority <> Mod_Get("priority", $iCount - 1) Then $bCreateNewGroup = True
		If $bCurrentGroupEnabled And Not $bEnabled Then $bCreateNewGroup = True

		If $bCreateNewGroup Then
			Local $sText = $bEnabled ? Lng_Get("mod_list.group.enabled") : Lng_Get("mod_list.group.disabled")
			If $bEnabled And $iPriority <> 0 Then $sText = StringFormat(Lng_Get("mod_list.group.enabled_with_priority"), $iPriority)

			$aModListGroups[0][0] += 1
			$iCurrentGroup = $aModListGroups[0][0]
			ReDim $aModListGroups[$iCurrentGroup + 1][3]

			$aModListGroups[$iCurrentGroup][0] = GUICtrlCreateTreeViewItem($sText, $hGUI.ModList.List)
			GUICtrlSetColor($aModListGroups[$iCurrentGroup][0], 0x0000C0)

			If $bEnabled Then
				_GUICtrlTreeView_SetIcon($hGUI.ModList.List, $aModListGroups[$iCurrentGroup][0], @ScriptDir & "\icons\folder-green.ico", 0, 6)
			Else
				_GUICtrlTreeView_SetIcon($hGUI.ModList.List, $aModListGroups[$iCurrentGroup][0], @ScriptDir & "\icons\folder-red.ico", 0, 6)
			EndIf

			$aModListGroups[$iCurrentGroup][1] = $bEnabled
			$aModListGroups[$iCurrentGroup][2] = $iPriority

			$bCurrentGroupEnabled = $bEnabled
		EndIf

		$MM_LIST_CONTENT[$iCount][$MOD_PARENT_ID] = $iCurrentGroup
		$MM_LIST_CONTENT[$iCount][$MOD_ITEM_ID] = GUICtrlCreateTreeViewItem($sCaption, $aModListGroups[$MM_LIST_CONTENT[$iCount][$MOD_PARENT_ID]][0])

		If Mod_Get("icon\file", $iCount) <> "" And FileExists($MM_LIST_DIR_PATH & "\" & $MM_LIST_CONTENT[$iCount][$MOD_ID] & "\" & Mod_Get("icon\file", $iCount)) Then
			_GUICtrlTreeView_SetIcon($hGUI.ModList.List, $MM_LIST_CONTENT[$iCount][$MOD_ITEM_ID], $MM_LIST_DIR_PATH & "\" & $MM_LIST_CONTENT[$iCount][0] & "\" & Mod_Get("icon\file", $iCount), Mod_Get("icon\index", $iCount), 6)
		Else
			_GUICtrlTreeView_SetIcon($hGUI.ModList.List, $MM_LIST_CONTENT[$iCount][$MOD_ITEM_ID], @ScriptDir & "\icons\folder-grey.ico", 0, 6)
		EndIf
	Next

	For $iCount = 1 To $aModListGroups[0][0]
		GUICtrlSetState($aModListGroups[$iCount][0], $GUI_EXPAND)
	Next

	TreeViewColor()
	_GUICtrlTreeView_EndUpdate($hGUI.ModList.List)
EndFunc   ;==>TreeViewFill

Func TreeViewColor()
	$MM_COMPATIBILITY_MESSAGE = ""
	Local $iMasterIndex = -1

	For $iModIndex = 1 To $MM_LIST_CONTENT[0][0]
		GUICtrlSetColor($MM_LIST_CONTENT[$iModIndex][$MOD_ITEM_ID], Default)
		If Not $MM_LIST_CONTENT[$iModIndex][$MOD_IS_EXIST] Then GUICtrlSetColor($MM_LIST_CONTENT[$iModIndex][$MOD_ITEM_ID], 0xC00000)

		If $iMasterIndex = -1 And $MM_LIST_CONTENT[$iModIndex][$MOD_IS_ENABLED] And $MM_LIST_CONTENT[$iModIndex][$MOD_IS_EXIST] Then
			For $i = 1 To $MM_LIST_CONTENT[0][0]
				If $iModIndex = $i Or Not $MM_LIST_CONTENT[$i][$MOD_IS_ENABLED] Or Not $MM_LIST_CONTENT[$i][$MOD_IS_EXIST] Then ContinueLoop
				If Not Mod_IsCompatible($iModIndex, $i) Then
					$iMasterIndex = $iModIndex
					GUICtrlSetColor($MM_LIST_CONTENT[$iModIndex][$MOD_ITEM_ID], 0x00C000) ; This is master mod
					$MM_COMPATIBILITY_MESSAGE = StringFormat(Lng_Get("compatibility.part1"), Mod_Get("caption", $iModIndex)) & @CRLF
					ExitLoop
				EndIf
			Next
		ElseIf $iMasterIndex > 0 And $MM_LIST_CONTENT[$iModIndex][$MOD_IS_ENABLED] And $MM_LIST_CONTENT[$iModIndex][$MOD_IS_EXIST] Then
			If Not Mod_IsCompatible($iMasterIndex, $iModIndex) Then
				GUICtrlSetColor($MM_LIST_CONTENT[$iModIndex][$MOD_ITEM_ID], 0xCC0000) ; This is slave mod
				$MM_COMPATIBILITY_MESSAGE &= Mod_Get("caption", $iModIndex) & @CRLF
			EndIf
		EndIf
	Next

	If $MM_COMPATIBILITY_MESSAGE <> "" Then
		$MM_COMPATIBILITY_MESSAGE &= @CRLF & Lng_Get("compatibility.part2")
		GUICtrlSetState($hGUI.MenuMore.Compatibility, $GUI_ENABLE)
	EndIf
EndFunc   ;==>TreeViewColor

Func TreeViewSwap($iIndex1, $iIndex2)
	_GUICtrlTreeView_BeginUpdate($hGUI.ModList.List)

	Local $vTemp

	$vTemp = _GUICtrlTreeView_GetText($hGUI.ModList.List, $MM_LIST_CONTENT[$iIndex1][$MOD_ITEM_ID])
	_GUICtrlTreeView_SetText($hGUI.ModList.List, $MM_LIST_CONTENT[$iIndex1][$MOD_ITEM_ID], _GUICtrlTreeView_GetText($hGUI.ModList.List, $MM_LIST_CONTENT[$iIndex2][$MOD_ITEM_ID]))
	_GUICtrlTreeView_SetText($hGUI.ModList.List, $MM_LIST_CONTENT[$iIndex2][$MOD_ITEM_ID], $vTemp)

	$vTemp = _GUICtrlTreeView_GetImageIndex($hGUI.ModList.List, $MM_LIST_CONTENT[$iIndex1][$MOD_ITEM_ID])
	_GUICtrlTreeView_SetImageIndex($hGUI.ModList.List, $MM_LIST_CONTENT[$iIndex1][$MOD_ITEM_ID], _GUICtrlTreeView_GetImageIndex($hGUI.ModList.List, $MM_LIST_CONTENT[$iIndex2][$MOD_ITEM_ID]))
	_GUICtrlTreeView_SetImageIndex($hGUI.ModList.List, $MM_LIST_CONTENT[$iIndex2][$MOD_ITEM_ID], $vTemp)

	$vTemp = _GUICtrlTreeView_GetStateImageIndex($hGUI.ModList.List, $MM_LIST_CONTENT[$iIndex1][$MOD_ITEM_ID])
	_GUICtrlTreeView_SetStateImageIndex($hGUI.ModList.List, $MM_LIST_CONTENT[$iIndex1][$MOD_ITEM_ID], _GUICtrlTreeView_GetStateImageIndex($hGUI.ModList.List, $MM_LIST_CONTENT[$iIndex2][$MOD_ITEM_ID]))
	_GUICtrlTreeView_SetStateImageIndex($hGUI.ModList.List, $MM_LIST_CONTENT[$iIndex2][$MOD_ITEM_ID], $vTemp)

	$vTemp = _GUICtrlTreeView_GetSelectedImageIndex($hGUI.ModList.List, $MM_LIST_CONTENT[$iIndex1][$MOD_ITEM_ID])
	_GUICtrlTreeView_SetSelectedImageIndex($hGUI.ModList.List, $MM_LIST_CONTENT[$iIndex1][$MOD_ITEM_ID], _GUICtrlTreeView_GetSelectedImageIndex($hGUI.ModList.List, $MM_LIST_CONTENT[$iIndex2][$MOD_ITEM_ID]))
	_GUICtrlTreeView_SetSelectedImageIndex($hGUI.ModList.List, $MM_LIST_CONTENT[$iIndex2][$MOD_ITEM_ID], $vTemp)

	TreeViewColor()

	_GUICtrlTreeView_EndUpdate($hGUI.ModList.List)
EndFunc   ;==>TreeViewSwap

Func TreeViewGetSelectedIndex()
	Local $hSelected = GUICtrlRead($hGUI.ModList.List)

	For $iCount = 1 To $MM_LIST_CONTENT[0][0]
		If $MM_LIST_CONTENT[$iCount][$MOD_ITEM_ID] = $hSelected Then Return $iCount
	Next
	Return -1
EndFunc   ;==>TreeViewGetSelectedIndex

Func TreeViewTryFollow($sModName)
	If $bInTrack Then Return
	$bInTrack = True

	Switch $MM_VIEW_CURRENT
		Case $MM_VIEW_MODS
			List_ModsTryFollow($sModName)
		Case $MM_VIEW_PLUGINS
			List_PluginsResetSelection()
	EndSwitch

	$bInTrack = False
EndFunc   ;==>TreeViewTryFollow

Func List_ModsTryFollow($sModID)
	Local $iModIndex = 0
	For $iCount = 1 To $MM_LIST_CONTENT[0][0]
		If $MM_LIST_CONTENT[$iCount][$MOD_ID] = $sModID Then
			$iModIndex = $iCount
			ExitLoop
		EndIf
	Next

	If $iModIndex = 0 Then
		GUICtrlSetState($hGUI.ModList.List, $GUI_FOCUS)
		Return
	EndIf

	If $aModListGroups[0][0] > 0 Then GUICtrlSetState($aModListGroups[1][0], $GUI_FOCUS)
	If $iModIndex <> -1 Then GUICtrlSetState($MM_LIST_CONTENT[$iModIndex][$MOD_ITEM_ID], $GUI_FOCUS)
EndFunc   ;==>List_ModsTryFollow

Func List_PluginsResetSelection()
	Local $iFirstGroup = -1

	If $MM_PLUGINS_PART_PRESENT[$PLUGIN_GROUP_GLOBAL] Then
		$iFirstGroup = $PLUGIN_GROUP_GLOBAL
	ElseIf $MM_PLUGINS_PART_PRESENT[$PLUGIN_GROUP_BEFORE] Then
		$iFirstGroup = $PLUGIN_GROUP_BEFORE
	ElseIf $MM_PLUGINS_PART_PRESENT[$PLUGIN_GROUP_AFTER] Then
		$iFirstGroup = $PLUGIN_GROUP_AFTER
	EndIf

	If $iFirstGroup <> -1 Then
		_GUICtrlTreeView_SelectItem($hGUI.PluginsList.List, $hPluginsParts[$PLUGIN_GROUP_GLOBAL], $TVGN_FIRSTVISIBLE)
		_GUICtrlTreeView_SelectItem($hGUI.PluginsList.List, $hPluginsParts[$PLUGIN_GROUP_GLOBAL], $TVGN_CARET)
	EndIf

	If $MM_PLUGINS_CONTENT[0][0] > 0 Then
		_GUICtrlTreeView_SelectItem($hGUI.PluginsList.List, $aPlugins[1][0], $TVGN_CARET)
		GUICtrlSetState($aPlugins[1][0], $GUI_FOCUS)
	EndIf
EndFunc   ;==>List_PluginsResetSelection

Func WM_GETMINMAXINFO($hwnd, $msg, $iwParam, $ilParam)
	#forceref $hwnd, $Msg, $iwParam, $ilParam

	If $hwnd <> $MM_UI_MAIN Then Return $GUI_RUNDEFMSG

	Local $tagMaxinfo = DllStructCreate("int;int;int;int;int;int;int;int;int;int", $ilParam)
	DllStructSetData($tagMaxinfo, 7, $MM_WINDOW_MIN_WIDTH_FULL) ; min X
	DllStructSetData($tagMaxinfo, 8, $MM_WINDOW_MIN_HEIGHT_FULL) ; min Y
	Return 0
EndFunc   ;==>WM_GETMINMAXINFO

Func WM_NOTIFY($hwnd, $iMsg, $iwParam, $ilParam)
	#forceref $hWnd, $iMsg, $iwParam, $ilParam
	Local $hWndFrom, $iCode, $tNMHDR

	$tNMHDR = DllStructCreate($tagNMHDR, $ilParam)
	$hWndFrom = HWnd(DllStructGetData($tNMHDR, "hWndFrom"))
	$iCode = DllStructGetData($tNMHDR, "Code")

	Switch $hWndFrom
		Case GUICtrlGetHandle($hGUI.ModList.List), GUICtrlGetHandle($hGUI.PluginsList.List)
			Switch $iCode
				Case $NM_DBLCLK
					$bEnableDisable = True
				Case $TVN_SELCHANGEDA, $TVN_SELCHANGEDW
					$bSelectionChanged = True
			EndSwitch
		Case $hGUI.Info.Desc
			Local $tNMLINK = DllStructCreate($tagNMLINK, $ilParam)
			Local $ID = DllStructGetData($tNMLINK, "Code")
			Switch $ID
				Case $NM_CLICK, $NM_RETURN
					GUICtrlSendToDummy($hDummyLinks, DllStructGetData($tNMLINK, "Link"))
			EndSwitch
	EndSwitch

	Return $GUI_RUNDEFMSG
EndFunc   ;==>WM_NOTIFY

Func SD_GUI_TabChanged()
	Switch GUICtrlRead($hGUI.Info.TabControl, 1)
		Case $hGUI.Info.TabDesc
			SD_SwitchSubView($MM_SUBVIEW_DESC)
		Case $hGUI.Info.TabInfo
			SD_SwitchSubView($MM_SUBVIEW_INFO)
		Case $hGUI.Info.TabScreens
			SD_SwitchSubView($MM_SUBVIEW_SCREENS)
	EndSwitch
EndFunc

Func SD_SwitchView(Const $iNewView = $MM_VIEW_MODS)
	GUICtrlSetData($hGUI.Info.Edit, "")

	$MM_VIEW_CURRENT = $iNewView

	Switch $iNewView
		Case $MM_VIEW_MODS
			GUICtrlSetState($hGUI.PluginsList.Group, $GUI_HIDE)
			GUICtrlSetState($hGUI.PluginsList.List, $GUI_HIDE)
			GUICtrlSetState($hGUI.PluginsList.Back, $GUI_HIDE)

			GUICtrlSetState($hGUI.ModList.Group, $GUI_SHOW)
			GUICtrlSetState($hGUI.ModList.List, $GUI_SHOW)
			GUICtrlSetState($hGUI.ModList.Up, $GUI_SHOW)
			GUICtrlSetState($hGUI.ModList.Down, $GUI_SHOW)
			GUICtrlSetState($hGUI.ModList.ChangeState, $GUI_SHOW)
 			If Not $MM_SETTINGS_PORTABLE Then GUICtrlSetState($hGUI.MenuMore.ChangeModDir, $GUI_ENABLE)

			TreeViewTryFollow($sFollowMod)
		Case $MM_VIEW_PLUGINS
			GUICtrlSetState($hGUI.ModList.Group, $GUI_HIDE)
			GUICtrlSetState($hGUI.ModList.List, $GUI_HIDE)
			GUICtrlSetState($hGUI.ModList.Up, $GUI_HIDE)
			GUICtrlSetState($hGUI.ModList.Down, $GUI_HIDE)
			GUICtrlSetState($hGUI.ModList.ChangeState, $GUI_HIDE)
			GUICtrlSetState($hGUI.MenuMod.Menu, $GUI_DISABLE)
			If Not $MM_SETTINGS_PORTABLE Then GUICtrlSetState($hGUI.MenuMore.ChangeModDir, $GUI_DISABLE)

			GUICtrlSetState($hGUI.PluginsList.Group, $GUI_SHOW)
			GUICtrlSetState($hGUI.PluginsList.List, $GUI_SHOW)
			GUICtrlSetState($hGUI.PluginsList.Back, $GUI_SHOW)

			TreeViewTryFollow("")
		Case $MM_VIEW_INSTALL
	EndSwitch
EndFunc   ;==>SD_SwitchView

Func SD_SwitchSubView(Const $iNewView = $MM_SUBVIEW_DESC)
	$MM_SUBVIEW_CURRENT = $iNewView

	Switch $iNewView
		Case $MM_SUBVIEW_DESC
			GUICtrlSetState($hGUI.Info.Edit, $GUI_SHOW)
			ControlHide($MM_UI_MAIN, '', $hGUI.Info.Desc)
		Case $MM_SUBVIEW_INFO
			GUICtrlSetState($hGUI.Info.Edit, $GUI_HIDE)
			ControlShow($MM_UI_MAIN, '', $hGUI.Info.Desc)
		Case $MM_SUBVIEW_SCREENS
			GUICtrlSetState($hGUI.Info.Edit, $GUI_HIDE)
			ControlHide($MM_UI_MAIN, '', $hGUI.Info.Desc)
	EndSwitch
EndFunc

Func SD_FormatDescription()
	If $MM_SELECTED_MOD < 0 Then Return ""
	Local $sText
	If Mod_Get("id") <> Mod_Get("caption") Then
		$sText = Lng_GetF("info_group.info.mod_caption", Mod_Get("caption"), Mod_Get("id"))
	Else
		$sText = Lng_GetF("info_group.info.mod_caption_s", Mod_Get("caption"))
	EndIf

	If Mod_Get("version\mod") <> "0.0" Then	$sText &= @CRLF & Lng_GetF("info_group.info.version", Mod_Get("version\mod"))
	If Mod_Get("author") <> "" Then	$sText &= @CRLF & Lng_GetF("info_group.info.author", Mod_Get("author"))
	If Mod_Get("homepage") <> "" Then	$sText &= @CRLF & Lng_GetF("info_group.info.link", Mod_Get("homepage"))

	Return $sText
EndFunc
