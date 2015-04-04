#NoTrayIcon
#cs
this allows easy overwrite #AutoIt3Wrapper_Res_Fileversion via simple IniWrite
[Version]
#ce
#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Version=Beta
#AutoIt3Wrapper_Icon=icons\preferences-system.ico
#AutoIt3Wrapper_Outfile=mmanager.exe
#AutoIt3Wrapper_Compression=4
#AutoIt3Wrapper_UseUpx=y
#AutoIt3Wrapper_Res_Description=A mod manager for Era II
#AutoIt3Wrapper_Res_Fileversion=0.92.2.0
#AutoIt3Wrapper_Res_LegalCopyright=Aliaksei SyDr Karalenka
#AutoIt3Wrapper_Res_requestedExecutionLevel=asInvoker
#AutoIt3Wrapper_AU3Check_Parameters=-d -w 1 -w 2 -w 3 -w 4 -w 5 -w 6 -w 7
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
; Author:         Aliaksei SyDr Karalenka

#include "include_fwd.au3"

#include "mod_edit.au3"
#include "mods.au3"
#include "lng.au3"
#include "packed_mods.au3"
#include "plugins.au3"
#include "presets.au3"
#include "settings.au3"
#include "startup.au3"
#include "update.au3"
#include "ui.au3"

AutoItSetOption("MustDeclareVars", 1)
AutoItSetOption("GUIOnEventMode", 1)
AutoItSetOption("GUICloseOnESC", 1)
If Not @Compiled Then AutoItSetOption("TrayIconHide", 0)
If Not @Compiled Then Global $__DEBUG

#Region Variables
Global $hGUI[]
$hGUI.MenuScn = MapEmpty()
$hGUI.MenuMod = MapEmpty()
$hGUI.MenuGame = MapEmpty()
$hGUI.MenuSettings = MapEmpty()
$hGUI.MenuHelp = MapEmpty()
$hGUI.ModList = MapEmpty()
$hGUI.PluginsList = MapEmpty()
$hGUI.ScnList = MapEmpty()
$hGUI.Info = MapEmpty()
$hGUI.WindowResizeInProgress = False
$hGUI.WindowResizeLags = False
$hGUI.Screen = MapEmpty()
Global $hDummyF5, $hDummyLinks, $hDummyCategories
Global Const $iItemSpacing = 4

Global $aModListGroups[1][3]; group item id, is enabled, priority/group tag
Global $aPlugins[1][2], $hPluginsParts[3]
Global $aScreens[1], $iScreenIndex, $iScreenWidth, $iScreenHeight, $sScreenPath
Global $sFollowMod = ""
Global $bEnableDisable, $bSelectionChanged
Global $bInTrack = False
Global $bMainUICycle = True, $bExit = True
Global $bPackModHint = True
#EndRegion Variables

If @Compiled And @ScriptName = "installmod.exe" Then
	StartUp_WorkAsInstallmod()
EndIf

If $CMDLine[0] > 0 And $CMDLine[1] = '/assocdel' Then
	StartUp_Assoc_Delete()
EndIf

Lng_LoadList()
If $CMDLine[0] > 1 And $CMDLine[1] = '/install' Then
	Settings_Set("language",  Utils_InnoLangToMM($CMDLine[2]))
ElseIf $CMDLine[0] > 0 Then
	If Not SD_CLI_Mod_Add() Then Exit
EndIf

StartUp_CheckRunningInstance()
Update_AutoInit()

If Not IsDeclared("__MM_NO_UI") Then
	While True
		$bMainUICycle = True
		UI_Main()
	WEnd
EndIf

Func UI_Main()
	_TraceStart("Init UI")
	_GDIPlus_Startup()
	If Not $MM_PORTABLE And Not Settings_Get("path") Then UI_SelectGameDir()
	SD_GUI_LoadSize()
	SD_GUI_Create()
	TreeViewMain()
	TreeViewTryFollow($MM_LIST_CONTENT[0][0] > 0 ? $MM_LIST_CONTENT[1][$MOD_ID] : "")
	SD_SwitchView()
	SD_SwitchSubView()
	GUISetState(@SW_SHOW)
	_TraceEnd()
	MainLoop()
EndFunc

Func MainLoop()
	While $bMainUICycle
		Sleep(20)
		SD_UI_AutoUpdate()
		SD_UI_ModStateChange()

		If $MM_LIST_CANT_WORK Then
			$MM_LIST_CANT_WORK = False
			If MsgBox($MB_SYSTEMMODAL + $MB_YESNO, "", Lng_GetF("mod_list.list_inaccessible", $MM_LIST_FILE_PATH)) = $IDYES Then
				ShellExecute("explorer.exe", "/select," & $MM_LIST_FILE_PATH, $MM_LIST_DIR_PATH)
			EndIf
		EndIf

		Update_AutoCycle()
	WEnd
EndFunc   ;==>MainLoop

Func SD_UI_AutoUpdate()
	Local Static $bGUINeedUpdate = False

	If Not $bGUINeedUpdate And Not WinActive($MM_UI_MAIN) Then
		$bGUINeedUpdate = True
	EndIf

	If $bGUINeedUpdate And WinActive($MM_UI_MAIN) Then
		$bGUINeedUpdate = False
		If Not Mod_ListIsActual() Then SD_GUI_Update()
	EndIf
EndFunc

Func SD_UI_ModStateChange()
	If $bEnableDisable Then
		$bEnableDisable = False
		SD_GUI_List_ChangeState()
	EndIf

	If $bSelectionChanged Then
		$bSelectionChanged = False
		SD_GUI_List_SelectionChanged()
	EndIf
EndFunc

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

	SD_GUI_MenuCreate()

	; mod list
	$hGUI.ModList.Group = GUICtrlCreateGroup("-", 0, 0)
	$hGUI.ModList.List = GUICtrlCreateTreeView(0, 0, Default, Default, BitOR($TVS_FULLROWSELECT, $TVS_DISABLEDRAGDROP, $TVS_SHOWSELALWAYS), $WS_EX_CLIENTEDGE)
	$hGUI.ModList.Up = GUICtrlCreateButton("", 0, 0, 90, 25)
	$hGUI.ModList.Down = GUICtrlCreateButton("", 0, 0, 90, 25)
	$hGUI.ModList.ChangeState = GUICtrlCreateButton("", 0, 0, 90, 25)

	; mod list context menu
	$hGUI.MenuMod.Menu = GUICtrlCreateContextMenu($hGUI.ModList.List)
	$hGUI.MenuMod.Plugins = GUICtrlCreateMenuItem("-", $hGUI.MenuMod.Menu)
	$hGUI.MenuMod.OpenHomepage = GUICtrlCreateMenuItem("-", $hGUI.MenuMod.Menu)
	GUICtrlCreateMenuItem("", $hGUI.MenuMod.Menu)
	$hGUI.MenuMod.Delete = GUICtrlCreateMenuItem("-", $hGUI.MenuMod.Menu)
	$hGUI.MenuMod.OpenFolder = GUICtrlCreateMenuItem("-", $hGUI.MenuMod.Menu)
	$hGUI.MenuMod.EditMod = GUICtrlCreateMenuItem("-", $hGUI.MenuMod.Menu)
	$hGUI.MenuMod.PackMod = GUICtrlCreateMenuItem("-", $hGUI.MenuMod.Menu)
	If $MM_GAME_NO_DIR Then GUICtrlSetState($hGUI.MenuMod.Menu, $GUI_DISABLE)

	; plugins list
	$hGUI.PluginsList.Group = GUICtrlCreateGroup("-", 0, 0)
	$hGUI.PluginsList.List = GUICtrlCreateTreeView(0, 0, Default, Default, BitOR($TVS_FULLROWSELECT, $TVS_DISABLEDRAGDROP, $TVS_SHOWSELALWAYS), $WS_EX_CLIENTEDGE)

	; info tabs
	$hGUI.Info.TabControl = GUICtrlCreateTab(0, 0, Default, Default, BitOR($TCS_FLATBUTTONS, $TCS_BUTTONS, $TCS_FOCUSNEVER))
	$hGUI.Info.TabDesc = GUICtrlCreateTabItem("-")
	$hGUI.Info.TabInfo = GUICtrlCreateTabItem("-")
	$hGUI.Info.TabScreens = GUICtrlCreateTabItem("-")
	GUICtrlCreateTabItem("")

	$hGUI.Info.Edit = GUICtrlCreateEdit("", 0, 0, 0, 0, BitOR($ES_READONLY, $WS_VSCROLL, $WS_TABSTOP))
	$hGUI.Info.Desc = _GUICtrlSysLink_Create($MM_UI_MAIN, "-", 0, 0, 0, 0)

	$hGUI.Screen.Control = GUICtrlCreatePic("", 0, 0)
	GUICtrlSetCursor($hGUI.Screen.Control, 0)
	$hGUI.Screen.Open = GUICtrlCreateButton("", 0, 0, 25, 25, $BS_ICON)
	$hGUI.Screen.Back = GUICtrlCreateButton("", 0, 0, 25, 25, $BS_ICON)
	$hGUI.Screen.Forward = GUICtrlCreateButton("", 0, 0, 25, 25, $BS_ICON)
	GUICtrlSetImage($hGUI.Screen.Open, @ScriptDir & "\icons\folder-open.ico")
	GUICtrlSetImage($hGUI.Screen.Back, @ScriptDir & "\icons\arrow-left.ico")
	GUICtrlSetImage($hGUI.Screen.Forward, @ScriptDir & "\icons\arrow-right.ico")

	; sceanrio controls
	$hGUI.ScnList.Group = GUICtrlCreateGroup("-", 0, 0)
	$hGUI.ScnList.List = GUICtrlCreateListView("1|Name", 2, 2, Default, Default, BitOR($LVS_NOCOLUMNHEADER, $LVS_SINGLESEL, $LVS_SHOWSELALWAYS), BitOR($LVS_EX_FULLROWSELECT, 0))
	$hGUI.ScnList.Load = GUICtrlCreateButton("", 0, 0, 90, 25)
	$hGUI.ScnList.Save = GUICtrlCreateButton("", 0, 0, 90, 25)
	$hGUI.ScnList.Delete = GUICtrlCreateButton("", 0, 0, 90, 25)
	GUICtrlSetState($hGUI.ScnList.Load, $GUI_DISABLE)
	GUICtrlSetState($hGUI.ScnList.Save, $GUI_DISABLE)
	GUICtrlSetState($hGUI.ScnList.Delete, $GUI_DISABLE)

	SD_UI_ScnLoadItems()

	; other
	$hGUI.Back = GUICtrlCreateButton("", 0, 0, 90, 25)

	$hDummyF5 = GUICtrlCreateDummy()
	$hDummyLinks = GUICtrlCreateDummy()
	$hDummyCategories = GUICtrlCreateDummy()

	Local $AccelKeys[2][2] = [["{F5}", $hDummyF5], ["{F8}", $hDummyCategories]]
	GUISetAccelerators($AccelKeys)

	SD_GUI_Mod_Controls_Disable()
	SD_GUI_Events_Register()
	SD_GUI_SetLng()
	SD_GUI_MainWindowResize()

	WinMove($MM_UI_MAIN, '', (@DesktopWidth - $MM_WINDOW_WIDTH) / 2, (@DesktopHeight - $MM_WINDOW_HEIGHT) / 2, $MM_WINDOW_WIDTH, $MM_WINDOW_HEIGHT)
	If $MM_WINDOW_MAXIMIZED Then WinSetState($MM_UI_MAIN, '', @SW_MAXIMIZE)

	AutoItSetOption("GUICoordMode", $iOptionGUICoordMode)
EndFunc   ;==>SD_GUI_Create

Func SD_GUI_MenuCreate()
	$hGUI.MenuScn.Menu = GUICtrlCreateMenu("-")
	$hGUI.MenuScn.Manage = GUICtrlCreateMenuItem("-", $hGUI.MenuScn.Menu)
	$hGUI.MenuScn.Import = GUICtrlCreateMenuItem("-", $hGUI.MenuScn.Manage)
	$hGUI.MenuScn.Export = GUICtrlCreateMenuItem("-", $hGUI.MenuScn.Manage)
	If $MM_GAME_NO_DIR Then GUICtrlSetState($hGUI.MenuScn.Import, $GUI_DISABLE)
	If $MM_GAME_NO_DIR Then GUICtrlSetState($hGUI.MenuScn.Export, $GUI_DISABLE)

	$hGUI.MenuGame.Menu = GUICtrlCreateMenu("-")
	$hGUI.MenuGame.Launch = GUICtrlCreateMenuItem("-", $hGUI.MenuGame.Menu)
	GUICtrlSetState($hGUI.MenuGame.Launch, $MM_GAME_EXE = "" ? $GUI_DISABLE : $GUI_ENABLE)
	GUICtrlCreateMenuItem("", $hGUI.MenuGame.Menu)
	$hGUI.MenuGame.Change = GUICtrlCreateMenuItem("-", $hGUI.MenuGame.Menu)
	If $MM_GAME_NO_DIR Then GUICtrlSetState($hGUI.MenuGame.Menu, $GUI_DISABLE)

	$hGUI.MenuSettings.Menu = GUICtrlCreateMenu("-")
	$hGUI.MenuSettings.Add = GUICtrlCreateMenuItem("-", $hGUI.MenuSettings.Menu)
	$hGUI.MenuSettings.Compatibility = GUICtrlCreateMenuItem("-", $hGUI.MenuSettings.Menu)
	$hGUI.MenuSettings.ChangeModDir = GUICtrlCreateMenuItem("-", $hGUI.MenuSettings.Menu)
	If $MM_GAME_NO_DIR Then GUICtrlSetState($hGUI.MenuSettings.Add, $GUI_DISABLE)
	If $MM_PORTABLE Then GUICtrlSetState($hGUI.MenuSettings.ChangeModDir, $GUI_DISABLE)
	GUICtrlCreateMenuItem("", $hGUI.MenuSettings.Menu)

	$hGUI.MenuSettings.Settings = GUICtrlCreateMenuItem("-", $hGUI.MenuSettings.Menu)
	$hGUI.MenuLanguage = GUICtrlCreateMenu("-", $hGUI.MenuSettings.Menu)
	For $iCount = 1 To $MM_LNG_LIST[0][0]
		$MM_LNG_LIST[$iCount][$MM_LNG_MENU_ID] = GUICtrlCreateMenuItem($MM_LNG_LIST[$iCount][$MM_LNG_NAME], $hGUI.MenuLanguage, Default, 1)
		If $MM_LNG_LIST[$iCount][$MM_LNG_FILE] = $MM_SETTINGS_LANGUAGE Then GUICtrlSetState($MM_LNG_LIST[$iCount][$MM_LNG_MENU_ID], $GUI_CHECKED)
	Next

	$hGUI.MenuHelp.Menu = GUICtrlCreateMenu("?")
	$hGUI.MenuHelp.CheckForUpdates = GUICtrlCreateMenuItem("-", $hGUI.MenuHelp.Menu)
EndFunc

Func SD_GUI_UpdateScreen(Const $iIndex)
	$iScreenWidth = 0
	$iScreenHeight = 0

	$iScreenIndex = $iIndex
	$sScreenPath = $iIndex > 0 ? $aScreens[$iIndex] : ""
	GUICtrlSetState($hGUI.Screen.Back, $iIndex <= 1 ? $GUI_DISABLE : $GUI_ENABLE)
	GUICtrlSetState($hGUI.Screen.Forward, $iIndex >= $aScreens[0] ? $GUI_DISABLE : $GUI_ENABLE)
	GUICtrlSetState($hGUI.Screen.Control, $iIndex = 0 ? $GUI_DISABLE : $GUI_ENABLE)
	GUICtrlSetState($hGUI.Screen.Open, $iIndex = 0 ? $GUI_DISABLE : $GUI_ENABLE)

	If $MM_SUBVIEW_CURRENT <> $MM_SUBVIEW_SCREENS Then Return

	If $iIndex <> 0 Then
		Local $hScreenImage = _GDIPlus_ImageLoadFromFile($sScreenPath)
		Local $hScreenBitmap = _GDIPlus_BitmapCreateHBITMAPFromBitmap($hScreenImage)
		$iScreenWidth = _GDIPlus_ImageGetWidth($hScreenImage)
		$iScreenHeight = _GDIPlus_ImageGetHeight($hScreenImage)
		_WinAPI_DeleteObject(GUICtrlSendMsg($hGUI.Screen.Control, $STM_SETIMAGE, $IMAGE_BITMAP, $hScreenBitmap))
		_GDIPlus_ImageDispose($hScreenImage)
		_WinAPI_DeleteObject($hScreenBitmap)
		GUICtrlSetPos($hGUI.Screen.Control, 0, 0, 0, 0)
	EndIf

	SD_GUI_MainWindowResize(True)
EndFunc

Func SD_GUI_UpdateScreenByPath(Const $sPath)
	For $i = 1 To $aScreens[0]
		If $aScreens[$i] = $sPath Then Return SD_GUI_UpdateScreen($i)
	Next
	SD_GUI_UpdateScreen($aScreens[0] > 0 ? 1 : 0)
EndFunc

Func SD_GUI_OpenScreenFolder()
	Utils_OpenFolder($MM_LIST_DIR_PATH & "\" & Mod_Get("id") & "\Screens\", $sScreenPath)
EndFunc

Func SD_GUI_NextScreen()
	If $iScreenIndex < $aScreens[0] Then SD_GUI_UpdateScreen($iScreenIndex + 1)
EndFunc

Func SD_GUI_PrevScreen()
	If $iScreenIndex > 0 Then SD_GUI_UpdateScreen($iScreenIndex - 1)
EndFunc

Func WM_SIZE()
	If Not $hGUI.WindowResizeInProgress Or Not $hGUI.WindowResizeLags Then SD_GUI_MainWindowResize()
	Return 0
EndFunc

Func WM_ENTERSIZEMOVE()
	$hGUI.WindowResizeInProgress = True
EndFunc

Func WM_EXITSIZEMOVE()
	SD_GUI_MainWindowResize()
	$hGUI.WindowResizeInProgress = False
EndFunc

Func SD_GUI_BigScreen()
	If $MM_VIEW_CURRENT <> $MM_VIEW_BIG_SCREEN Then
		SD_SwitchView($MM_VIEW_BIG_SCREEN)
	Else
		SD_SwitchView($MM_VIEW_PREV)
	EndIf
EndFunc

Func SD_GUI_MainWindowResize(Const $bForce = False)
	Local $iTimer = TimerInit()
	Local $aSize = WinGetClientSize($MM_UI_MAIN)
	If Not $bForce And $aSize[0] == $MM_WINDOW_CLIENT_WIDTH And $aSize[1] == $MM_WINDOW_CLIENT_HEIGHT Then Return

	$MM_WINDOW_CLIENT_WIDTH = $aSize[0]
	$MM_WINDOW_CLIENT_HEIGHT = $aSize[1]

	Local Const $iListLength = 400 + ($MM_WINDOW_CLIENT_WIDTH - 800) / 4
	Local Const $iButtonWidth = 90, $iButtonLeft = $iListLength - $iButtonWidth

	If $MM_VIEW_CURRENT = $MM_VIEW_MODS Then
		GUICtrlSetPos($hGUI.ModList.Group, $iItemSpacing, 0, $iListLength, $MM_WINDOW_CLIENT_HEIGHT - $iItemSpacing)
		GUICtrlSetPos($hGUI.ModList.List, 2 * $iItemSpacing, 17, $iListLength - 3 * $iItemSpacing - $iButtonWidth, $MM_WINDOW_CLIENT_HEIGHT - 6 * $iItemSpacing)
		GUICtrlSetPos($hGUI.ModList.Up, $iButtonLeft, 16, $iButtonWidth, 25)
		GUICtrlSetPos($hGUI.ModList.Down, $iButtonLeft, 16 + 25 + $iItemSpacing, $iButtonWidth, 25)
		GUICtrlSetPos($hGUI.ModList.ChangeState, $iButtonLeft, 16 + 50 + 2 * $iItemSpacing, $iButtonWidth, 25)
	ElseIf $MM_VIEW_CURRENT = $MM_VIEW_PLUGINS Then
		GUICtrlSetPos($hGUI.PluginsList.Group, $iItemSpacing, 0, $iListLength, $MM_WINDOW_CLIENT_HEIGHT - $iItemSpacing)
		GUICtrlSetPos($hGUI.PluginsList.List, 2 * $iItemSpacing, 17, $iListLength - 3 * $iItemSpacing - $iButtonWidth, $MM_WINDOW_CLIENT_HEIGHT - 6 * $iItemSpacing)
	ElseIf $MM_VIEW_CURRENT = $MM_VIEW_SCN Then
		GUICtrlSetPos($hGUI.ScnList.Group, $iItemSpacing, 0, $iListLength, $MM_WINDOW_CLIENT_HEIGHT - $iItemSpacing)
		GUICtrlSetPos($hGUI.ScnList.List, 2 * $iItemSpacing, 17, $iListLength - 3 * $iItemSpacing - $iButtonWidth, $MM_WINDOW_CLIENT_HEIGHT - 6 * $iItemSpacing)
		_GUICtrlListView_SetColumnWidth($hGUI.ScnList.List, 1, $LVSCW_AUTOSIZE_USEHEADER)
		GUICtrlSetPos($hGUI.ScnList.Load, $iButtonLeft, 16, $iButtonWidth, 25)
		GUICtrlSetPos($hGUI.ScnList.Save, $iButtonLeft, 16 + 25 + $iItemSpacing, $iButtonWidth, 25)
		GUICtrlSetPos($hGUI.ScnList.Delete, $iButtonLeft, 16 + 50 + 2 * $iItemSpacing, $iButtonWidth, 25)
	EndIf

	If $MM_VIEW_CURRENT = $MM_VIEW_PLUGINS Or $MM_VIEW_CURRENT = $MM_VIEW_SCN Then
		GUICtrlSetPos($hGUI.Back, $iButtonLeft, $MM_WINDOW_CLIENT_HEIGHT - $iItemSpacing * 2 - 25 + 2, $iButtonWidth, 25)
	EndIf

	GUICtrlSetPos($hGUI.Info.TabControl, $iListLength + $iItemSpacing, 2 * $iItemSpacing - 2, $MM_WINDOW_CLIENT_WIDTH - $iListLength - 3 * $iItemSpacing, 19)

	If $MM_SUBVIEW_CURRENT = $MM_SUBVIEW_DESC Then
		GUICtrlSetPos($hGUI.Info.Edit, $iListLength + $iItemSpacing + 2, 3 * $iItemSpacing + 17, $MM_WINDOW_CLIENT_WIDTH - $iListLength - 2 * $iItemSpacing - 2, $MM_WINDOW_CLIENT_HEIGHT - (4 * $iItemSpacing + 17))
	ElseIf $MM_SUBVIEW_CURRENT = $MM_SUBVIEW_INFO Then
		ControlMove($hGUI.Info.Desc, '', 0, $iListLength + 2 * $iItemSpacing + 2, 3 * $iItemSpacing + 17, $MM_WINDOW_CLIENT_WIDTH - $iListLength - 3 * $iItemSpacing - 2, $MM_WINDOW_CLIENT_HEIGHT - (4 * $iItemSpacing + 17))
	ElseIf $MM_SUBVIEW_CURRENT = $MM_SUBVIEW_SCREENS Then
		Local $iLeft = ($MM_VIEW_CURRENT = $MM_VIEW_BIG_SCREEN) ? $iItemSpacing : ($iListLength + $iItemSpacing + 2)
		Local $iTop = ($MM_VIEW_CURRENT = $MM_VIEW_BIG_SCREEN) ? $iItemSpacing : (3 * $iItemSpacing + 17)
		GUICtrlSetPos($hGUI.Screen.Open, $iLeft, $iTop, 25, 25)
		GUICtrlSetPos($hGUI.Screen.Back, $MM_WINDOW_CLIENT_WIDTH - 50 - 2 * $iItemSpacing, $iTop, 25, 25)
		GUICtrlSetPos($hGUI.Screen.Forward, $MM_WINDOW_CLIENT_WIDTH - 25 - $iItemSpacing, $iTop, 25, 25)
		Local Const $iMaxWidth = ($MM_VIEW_CURRENT = $MM_VIEW_BIG_SCREEN) ? $MM_WINDOW_CLIENT_WIDTH : ($MM_WINDOW_CLIENT_WIDTH - $iListLength - 2 * $iItemSpacing - 2)
		Local Const $iMaxHeight =  ($MM_VIEW_CURRENT = $MM_VIEW_BIG_SCREEN) ? ($MM_WINDOW_CLIENT_HEIGHT - 25 - $iItemSpacing) : ($MM_WINDOW_CLIENT_HEIGHT - (5 * $iItemSpacing + 17 + 25))
		Local $iWidth = _Min($iMaxWidth, $iScreenWidth)
		Local $iHeight = _Min($iMaxHeight, $iScreenHeight)

		Local $f, $fRatio

		If $iScreenWidth > $iScreenHeight Then
			$f = $iScreenWidth / $iWidth
		Else
			$f = $iScreenHeight / $iHeight
		EndIf
		$iWidth = Int($iScreenWidth / $f)
		$iHeight = Int($iScreenHeight / $f)

		If $iWidth > $iMaxWidth Then
			$fRatio = $iMaxWidth / $iWidth
			$iWidth = Int($iWidth * $fRatio)
			$iHeight = Int($iHeight * $fRatio)
		ElseIf $iHeight > $iMaxHeight Then
			$fRatio = $iMaxHeight / $iHeight
			$iWidth = Int($iWidth * $fRatio)
			$iHeight = Int($iHeight * $fRatio)
		EndIf

		GUICtrlSetPos($hGUI.Screen.Control, $iLeft + ($iMaxWidth - $iWidth) / 2, $iTop + 25 + $iItemSpacing, $iWidth, $iHeight)
	EndIf

	$hGUI.WindowResizeLags = TimerDiff($iTimer) > 50
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
	GUICtrlSetOnEvent($hGUI.MenuScn.Manage, "SD_GUI_ScenarioManage")
	GUICtrlSetOnEvent($hGUI.MenuScn.Import, "SD_UI_ScnImport")
	GUICtrlSetOnEvent($hGUI.MenuScn.Export, "SD_UI_ScnExport")
	GUICtrlSetOnEvent($hGUI.MenuSettings.Compatibility, "SD_GUI_Mod_Compatibility")
	GUICtrlSetOnEvent($hGUI.MenuSettings.Settings, "SD_GUI_ChangeSettings")
	GUICtrlSetOnEvent($hGUI.MenuMod.Plugins, "SD_GUI_Manage_Plugins")
	GUICtrlSetOnEvent($hGUI.MenuMod.OpenHomepage, "SD_GUI_Mod_Website")
	GUICtrlSetOnEvent($hGUI.MenuMod.Delete, "SD_GUI_Mod_Delete")
	GUICtrlSetOnEvent($hGUI.MenuGame.Launch, "UI_GameExeLaunch")
	GUICtrlSetOnEvent($hGUI.MenuGame.Change, "SD_GUI_GameExeChange")
	GUICtrlSetOnEvent($hGUI.MenuSettings.Add, "SD_GUI_Mod_Add")
	GUICtrlSetOnEvent($hGUI.MenuMod.OpenFolder, "SD_GUI_Mod_OpenFolder")
	GUICtrlSetOnEvent($hGUI.MenuMod.EditMod, "SD_GUI_Mod_EditMod")
	GUICtrlSetOnEvent($hGUI.MenuMod.PackMod, "SD_GUI_Mod_PackMod")
	GUICtrlSetOnEvent($hGUI.MenuSettings.ChangeModDir, "SD_GUI_ChangeGameDir")

	GUICtrlSetOnEvent($hGUI.Back, "SD_GUI_BackToMainView")
	GUICtrlSetOnEvent($hGUI.MenuHelp.CheckForUpdates, "Update_CheckNewPorgram")
	GUICtrlSetOnEvent($hGUI.ScnList.Delete, "SD_UI_ScnDelete")
	GUICtrlSetOnEvent($hGUI.ScnList.Load, "SD_UI_ScnLoad")
	GUICtrlSetOnEvent($hGUI.ScnList.Save, "SD_UI_ScnSave")

	GUICtrlSetOnEvent($hGUI.Info.TabControl, "SD_GUI_TabChanged")

	GUICtrlSetOnEvent($hGUI.Screen.Open, "SD_GUI_OpenScreenFolder")
	GUICtrlSetOnEvent($hGUI.Screen.Back, "SD_GUI_PrevScreen")
	GUICtrlSetOnEvent($hGUI.Screen.Forward, "SD_GUI_NextScreen")
	GUICtrlSetOnEvent($hGUI.Screen.Control, "SD_GUI_BigScreen")

	GUICtrlSetOnEvent($hDummyF5, "SD_GUI_Update")
	GUICtrlSetOnEvent($hDummyLinks, "SD_GUI_Mod_Website")
	GUICtrlSetOnEvent($hDummyCategories, "SD_GUI_ModCategoriesUpdate")
EndFunc   ;==>SD_GUI_Events_Register

Func SD_UI_ScnLoadItems()
	Scn_ListLoad()
	_GUICtrlListView_BeginUpdate($hGUI.ScnList.List)
	_GUICtrlListView_DeleteAllItems($hGUI.ScnList.List)
	_GUICtrlListView_EnableGroupView($hGUI.ScnList.List, True)
	_GUICtrlListView_InsertGroup($hGUI.ScnList.List, -1, 1, Lng_Get("scenarios.special"))
	_GUICtrlListView_InsertGroup($hGUI.ScnList.List, -1, 3, Lng_Get("scenarios.all"))

    Local $iIndex = _GUICtrlListView_AddItem($hGUI.ScnList.List, "")
	_GUICtrlListView_SetItemGroupID($hGUI.ScnList.List, $iIndex, 1)
    _GUICtrlListView_AddSubItem($hGUI.ScnList.List, $iIndex,  Lng_Get("scenarios.new"), 1)

	For $i = 1 To $MM_SCN_LIST[0]
		$iIndex = _GUICtrlListView_AddItem($hGUI.ScnList.List, "")
		_GUICtrlListView_SetItemGroupID($hGUI.ScnList.List, $iIndex, 3)
		_GUICtrlListView_AddSubItem($hGUI.ScnList.List, $iIndex, $MM_SCN_LIST[$i], 1)
	Next

	_GUICtrlListView_EndUpdate($hGUI.ScnList.List)
EndFunc

Func SD_UI_ScnImport()
	Local $mData = UI_Import_Scn()
	If Not $mData["selected"] Then Return

	Scn_Apply($mData["data"])
	If $mData["wog_settings"] Then Scn_ApplyWogSettings($mData["wog_settings"])
	If $mData["exe"] Then SD_UI_ApplyExe($mData["exe"])
	TreeViewMain()
	$sFollowMod = $MM_LIST_CONTENT[0][0] > 0 ? $MM_LIST_CONTENT[1][$MOD_ID] : ""
	TreeViewTryFollow($sFollowMod)

	If Not $mData["only_load"] Then
		Scn_Save($mData["data"])
		SD_UI_ScnLoadItems()
	EndIf
EndFunc

Func SD_UI_ScnExport()
;~ 	UI_ScnExport()
EndFunc

Func SD_UI_ScnDelete()
	Local $iItemIndex = _GUICtrlListView_GetSelectedIndices($hGUI.ScnList.List)
	If $iItemIndex < 0 Then Return

	Local $iAnswer = MsgBox($MB_YESNO + $MB_ICONQUESTION + $MB_DEFBUTTON2 + $MB_TASKMODAL, "", StringFormat(Lng_Get("scenarios.delete_confirm"), $MM_SCN_LIST[$iItemIndex]), Default, $MM_UI_MAIN)
	If $iAnswer = $IDNO Then Return

	Scn_Delete($iItemIndex)
	SD_UI_ScnLoadItems()
EndFunc

Func SD_UI_ScnSave()
	Local $iItemIndex = _GUICtrlListView_GetSelectedIndices($hGUI.ScnList.List)
	If $iItemIndex < 0 Then Return

	Local $mOptions = UI_SelectScnSaveOptions($iItemIndex > 0 ? $MM_SCN_LIST[$iItemIndex] : "")
	If Not $mOptions["selected"] Then Return

	Scn_Save($mOptions)
	SD_UI_ScnLoadItems()
	SD_GUI_BackToMainView()
EndFunc

Func SD_UI_ScnLoad()
	Local $iItemIndex = _GUICtrlListView_GetSelectedIndices($hGUI.ScnList.List)
	If $iItemIndex < 0 Then Return

	Local $mData = Scn_Load($iItemIndex)
	Local $mOptions = UI_SelectScnLoadOptions($mData)
	If Not $mOptions["selected"] Then Return

	Scn_Apply($mData)
	If $mOptions["wog_settings"] Then Scn_ApplyWogSettings($mData["wog_settings"])
	If $mOptions["exe"] Then SD_UI_ApplyExe($mData["exe"])

	TreeViewMain()
	$sFollowMod = $MM_LIST_CONTENT[0][0] > 0 ? $MM_LIST_CONTENT[1][$MOD_ID] : ""
	SD_GUI_BackToMainView()
EndFunc

Func SD_GUI_ChangeSettings()
	UI_Settings()
EndFunc

Func SD_GUI_ModCategoriesUpdate()
	Local $iAnswer = MsgBox(4096 + 4, "", "Do you want to process all mods?" & @CRLF & "(Yes - all mods, No - only enabled)", 0, $MM_UI_MAIN)
	Local $sFolder = FileSelectFolder("", "", 1 + 2, "", $MM_UI_MAIN)
	If @error Then Return

	ProgressOn("Please wait...", "Mod packing", "", -1, -1, 2 + 16)
	Local $iTotalMods = 0
	For $i = 1 To $MM_LIST_CONTENT[0][0]
		If $iAnswer = $IDYES Or $MM_LIST_CONTENT[$i][$MOD_IS_ENABLED] Then $iTotalMods += 1
	Next

	For $i = 1 To $MM_LIST_CONTENT[0][0]
		If $iAnswer = $IDYES Or $MM_LIST_CONTENT[$i][$MOD_IS_ENABLED] Then
			Local $iProcess = Mod_CreatePackage($i, $sFolder & "\" & Mod_Get("caption\formatted", $i) & ".exe")
			ProcessWaitClose($iProcess)
		EndIf
		ProgressSet($i/$iTotalMods*100, StringFormat("%i from %i done", $i, $iTotalMods))
	Next
	ProgressOff()
EndFunc

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
	GUICtrlSetData($hGUI.MenuMod.EditMod, Lng_Get("mod_list.edit_mod"))
	GUICtrlSetData($hGUI.MenuMod.PackMod, Lng_Get("mod_list.pack_mod"))

	GUICtrlSetData($hGUI.MenuScn.Menu, Lng_Get("scenarios.caption"))
	GUICtrlSetData($hGUI.MenuScn.Manage, Lng_Get("scenarios.manage"))
	GUICtrlSetData($hGUI.MenuScn.Import, Lng_Get("scenarios.import.caption"))
	GUICtrlSetData($hGUI.MenuScn.Export, Lng_Get("scenarios.export.caption"))
	GUICtrlSetData($hGUI.ScnList.Group, Lng_Get("scenarios.caption"))
	GUICtrlSetData($hGUI.ScnList.Save, Lng_Get("scenarios.save"))
	GUICtrlSetData($hGUI.ScnList.Load, Lng_Get("scenarios.load"))
	GUICtrlSetData($hGUI.ScnList.Delete, Lng_Get("scenarios.delete"))

	GUICtrlSetData($hGUI.MenuGame.Menu, Lng_Get("game.caption"))
	GUICtrlSetData($hGUI.MenuGame.Launch, Lng_GetF("game.launch", $MM_GAME_EXE))
	GUICtrlSetData($hGUI.MenuGame.Change, Lng_Get("game.change"))

	GUICtrlSetData($hGUI.MenuSettings.Compatibility, Lng_Get("mod_list.compatibility"))
	GUICtrlSetData($hGUI.MenuSettings.Add, Lng_Get("mod_list.add_new"))
	GUICtrlSetData($hGUI.MenuSettings.ChangeModDir, Lng_Get("settings.game_dir.change"))

	GUICtrlSetData($hGUI.MenuSettings.Menu, Lng_Get("settings.menu.caption"))
	GUICtrlSetData($hGUI.MenuSettings.Settings, Lng_Get("settings.menu.settings"))


	GUICtrlSetData($hGUI.MenuHelp.CheckForUpdates, Lng_Get("update.caption"))

	GUICtrlSetData($hGUI.PluginsList.Group, Lng_GetF("plugins_list.caption", $MM_LIST_CONTENT[0][0] > 0 ? $MM_LIST_CONTENT[1][$MOD_ID] : ""))
	GUICtrlSetData($hGUI.Back, Lng_Get("plugins_list.back"))

	GUICtrlSetData($hGUI.Info.TabDesc, Lng_Get("info_group.desc"))
	GUICtrlSetData($hGUI.Info.TabInfo, Lng_Get("info_group.info.caption"))
	GUICtrlSetData($hGUI.Info.TabScreens, Lng_Get("info_group.screens.caption"))

	_GUICtrlListView_SetGroupInfo($hGUI.ScnList.List, 1, Lng_Get("scenarios.special"))
	_GUICtrlListView_SetGroupInfo($hGUI.ScnList.List, 3, Lng_Get("scenarios.all"))
	_GUICtrlListView_SetItemText($hGUI.ScnList.List, 0, Lng_Get("scenarios.new"), 1)

	_GUICtrlSysLink_SetText($hGUI.Info.Desc, SD_FormatDescription())
EndFunc   ;==>SD_GUI_SetLng

Func SD_GUI_Mod_Compatibility()
	MsgBox(4096, "", $MM_COMPATIBILITY_MESSAGE, Default, $MM_UI_MAIN)
EndFunc   ;==>SD_GUI_Mod_Compatibility

Func SD_GUI_Mod_OpenFolder()
	Local $iModIndex = TreeViewGetSelectedIndex()
	If $iModIndex = -1 Then Return -1 ; never
	Local $sPath = '"' & $MM_LIST_DIR_PATH & "\" & $MM_LIST_CONTENT[$iModIndex][$MOD_ID] & '"'
	ShellExecute($sPath)
EndFunc   ;==>SD_GUI_Mod_OpenFolder

Func SD_GUI_Mod_EditMod()
	Local $iModIndex = TreeViewGetSelectedIndex()
	If $iModIndex = -1 Then Return -1 ; never
	If ModEdit_Editor($iModIndex, $MM_UI_MAIN) Then SD_GUI_Update()
EndFunc

Func SD_GUI_Mod_PackMod()
	Local $iModIndex = TreeViewGetSelectedIndex()
	If $iModIndex = -1 Then Return -1 ; never

	Local $sSavePath = FileSaveDialog("", "", "(*.*)", $FD_PATHMUSTEXIST + $FD_PROMPTOVERWRITE, Mod_Get("caption\formatted") & ".exe", $MM_UI_MAIN)
	If Not @error Then
		Mod_CreatePackage($iModIndex, $sSavePath)
		If $bPackModHint Then MsgBox($MB_ICONINFORMATION, "", Lng_Get("mod_list.pack_mod_hint"))
		$bPackModHint = False
	EndIf
EndFunc

Func SD_GUI_Manage_Plugins()
	Local $iTreeViewIndex = TreeViewGetSelectedIndex()
	Plugins_ListLoad($MM_LIST_CONTENT[$iTreeViewIndex][$MOD_ID])
	GUICtrlSetData($hGUI.PluginsList.Group, Lng_GetF("plugins_list.caption", $MM_LIST_CONTENT[0][0] > 0 ? Mod_Get("caption", $iTreeViewIndex) : ""))
	SD_GUI_PluginsDisplay()
	SD_SwitchView($MM_VIEW_PLUGINS)
EndFunc   ;==>SD_GUI_Manage_Plugins

Func SD_GUI_BackToMainView()
	SD_SwitchView($MM_VIEW_MODS)
	If $MM_SUBVIEW_CURRENT = $MM_SUBVIEW_BLANK Then SD_SwitchSubView($MM_SUBVIEW_PREV)
EndFunc   ;==>SD_GUI_BackToMainView

Func SD_GUI_GameExeChange()
	SD_UI_ApplyExe(UI_SelectGameExe())
EndFunc

Func SD_UI_ApplyExe(Const $sNewExe)
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
	$aScreens = ArrayEmpty()
	SD_GUI_UpdateScreen(0)
	_GDIPlus_Shutdown()
	$bMainUICycle = False
	GUIDelete($MM_UI_MAIN)
	If $bExit Then Exit
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
	_TraceStart("UI: Swap")
	Mod_ListSwap($iModIndex1, $iModIndex2)
	TreeViewSwap($iModIndex1, $iModIndex2)
	TreeViewTryFollow($sFollowMod)
	_TraceEnd()
EndFunc   ;==>SD_GUI_Mod_Swap

Func SD_GUI_Mod_Delete()
	Local $iTreeViewIndex = TreeViewGetSelectedIndex()
	Local $iModIndex = $iTreeViewIndex
	Local $iAnswer = MsgBox($MB_YESNO + $MB_ICONQUESTION + $MB_DEFBUTTON2 + $MB_TASKMODAL, "", StringFormat(Lng_Get("mod_list.delete_confirm"), Mod_Get("caption", $iModIndex)), Default, $MM_UI_MAIN)
	If $iAnswer = $IDNO Then Return

	SD_GUI_UpdateScreen(0)
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

Func SD_GUI_ScenarioManage()
	SD_SwitchView($MM_VIEW_SCN)
	SD_SwitchSubView($MM_SUBVIEW_BLANK)
EndFunc

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
		GUICtrlSetState($hGUI.MenuSettings.Add, $GUI_ENABLE)
		GUICtrlSetState($hGUI.MenuGame.Launch, $MM_GAME_EXE = "" ? $GUI_DISABLE : $GUI_ENABLE)
		$aScreens = ArrayEmpty()
		SD_GUI_UpdateScreen(0)
		SD_GUI_Update()
	EndIf
EndFunc   ;==>SD_GUI_ChangeGameDir

Func SD_GUI_Update()
	Mod_CacheClear()
	GUISwitch($MM_UI_MAIN)
	TreeViewMain()
	If $MM_VIEW_CURRENT = $MM_VIEW_MODS Then TreeViewTryFollow($sFollowMod)
	SD_UI_ScnLoadItems()
EndFunc   ;==>SD_GUI_Update

Func TreeViewMain()
	Mod_ListLoad()
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
	GUICtrlSetState($hGUI.MenuMod.EditMod, $GUI_DISABLE)
	GUICtrlSetState($hGUI.MenuMod.PackMod, $GUI_DISABLE)
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
	_TraceStart("UI: Mod Selected")
	Local $iSelected = TreeViewGetSelectedIndex()

	If $iSelected = -1 Then
		SD_GUI_Mod_Controls_Disable()
		$aScreens[0] = 0
		SD_GUI_UpdateScreen(0)
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
			GUICtrlSetState($hGUI.MenuMod.EditMod, $GUI_DISABLE)
			GUICtrlSetState($hGUI.MenuMod.PackMod, $GUI_DISABLE)
			GUICtrlSetState($hGUI.MenuMod.Menu, $GUI_DISABLE)
		Else
			GUICtrlSetState($hGUI.MenuMod.Delete, $GUI_ENABLE)
			GUICtrlSetState($hGUI.MenuMod.OpenFolder, $GUI_ENABLE)
			GUICtrlSetState($hGUI.MenuMod.EditMod, $GUI_ENABLE)
			GUICtrlSetState($hGUI.MenuMod.PackMod, $GUI_ENABLE)
			GUICtrlSetState($hGUI.MenuMod.Menu, $GUI_ENABLE)
		EndIf

		_GUICtrlSysLink_SetText($hGUI.Info.Desc, SD_FormatDescription())

		$aScreens = Mod_ScreenListLoad($MM_LIST_CONTENT[$iModIndex][$MOD_ID])
		SD_GUI_UpdateScreenByPath($sScreenPath)
	EndIf
	_TraceEnd()
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
	_GUICtrlTreeView_DeleteAll($hGUI.ModList.List)

	GUICtrlSetState($hGUI.MenuSettings.Compatibility, $GUI_DISABLE)

	Local $iCurrentGroup = -1
	$aModListGroups[0][0] = 0

	Local $aGroupEnabledList[1], $aGroupDisabledList[1]
	Local $bEnabled, $iPriority, $sCategory, $vGroup, $bFound, $sCaption

	For $i = 1 To $MM_LIST_CONTENT[0][0]
		$bEnabled = $MM_LIST_CONTENT[$i][$MOD_IS_ENABLED]
		$iPriority = Mod_Get("priority", $i)
		$sCategory = Mod_Get("category", $i)
		$vGroup = $bEnabled ? $iPriority : $sCategory

		$bFound = False

		If $bEnabled Then
			For $j = 1 To $aGroupEnabledList[0]
				If $aGroupEnabledList[$j] = $vGroup Then
					$bFound = True
					ExitLoop
				EndIf
			Next
		Else
			For $j = 1 To $aGroupDisabledList[0]
				If $aGroupDisabledList[$j] = $vGroup Then
					$bFound = True
					ExitLoop
				EndIf
			Next
		EndIf

		If Not $bFound Then
			If $bEnabled Then
				$aGroupEnabledList[0] += 1
				ReDim $aGroupEnabledList[$aGroupEnabledList[0] + 1]
				$aGroupEnabledList[$aGroupEnabledList[0]] = $vGroup
			Else
				$aGroupDisabledList[0] += 1
				ReDim $aGroupDisabledList[$aGroupDisabledList[0] + 1]
				$aGroupDisabledList[$aGroupDisabledList[0]] = $vGroup
			EndIf
		EndIf
	Next

	For $i = 1 To $aGroupEnabledList[0]
		TreeViewAddGroup(True, $aGroupEnabledList[$i])
	Next

	Local $aCategories = MapKeys(Lng_Get("category"))
	_ArraySort($aGroupDisabledList, Default, 1)
	For $i = 0 To UBound($aCategories) - 1
		_ArraySearch($aGroupDisabledList, $aCategories[$i], 1)
		If Not @error Then TreeViewAddGroup(False, $aCategories[$i])
	Next

	Local $bAddEmpty = False
	For $i = 1 To $aGroupDisabledList[0]
		If $aGroupDisabledList[$i] = "" Then
			$bAddEmpty = True
		Else
			_ArraySearch($aCategories, $aGroupDisabledList[$i])
			If @error Then TreeViewAddGroup(False, $aGroupDisabledList[$i])
		EndIf
	Next

	If $bAddEmpty Then TreeViewAddGroup(False, "")

	For $iCount = 1 To $MM_LIST_CONTENT[0][0]
		$bEnabled = $MM_LIST_CONTENT[$iCount][$MOD_IS_ENABLED]
		$iPriority = Mod_Get("priority", $iCount)
		$sCategory = Mod_Get("category", $iCount)
		$sCaption = $bEnabled ? Mod_Get("caption\formatted\caps", $iCount) : Mod_Get("caption", $iCount)
		$sCaption = $MM_LIST_CONTENT[$iCount][$MOD_IS_EXIST] ? $sCaption : Lng_GetF("mod_list.missing", $sCaption)

		$iCurrentGroup = TreeViewFindCategory($bEnabled, $bEnabled ? $iPriority : $sCategory)

		$MM_LIST_CONTENT[$iCount][$MOD_PARENT_ID] = $iCurrentGroup
		$MM_LIST_CONTENT[$iCount][$MOD_ITEM_ID] = GUICtrlCreateTreeViewItem($sCaption, $aModListGroups[$MM_LIST_CONTENT[$iCount][$MOD_PARENT_ID]][0])

		_GUICtrlTreeView_SetIcon($hGUI.ModList.List, $MM_LIST_CONTENT[$iCount][$MOD_ITEM_ID], Mod_Get("icon_path", $iCount), Mod_Get("icon\index", $iCount), 6)
	Next

	For $iCount = 1 To $aModListGroups[0][0]
		GUICtrlSetState($aModListGroups[$iCount][0], $GUI_EXPAND)
	Next

	TreeViewColor()
	_GUICtrlTreeView_EndUpdate($hGUI.ModList.List)
EndFunc   ;==>TreeViewFill

Func TreeViewAddGroup(Const $bEnabled, Const $vItem)
	Local $sText = StringUpper($bEnabled ? Lng_Get("mod_list.group.enabled") : Lng_Get("mod_list.group.disabled"))
	If $bEnabled And $vItem <> 0 Then $sText = StringFormat(Lng_Get("mod_list.group.enabled_with_priority"), $vItem)
	If Not $bEnabled And $vItem <> "" Then $sText = Lng_GetF("mod_list.group.disabled_group", StringUpper(Lng_GetCategory($vItem)))

	$aModListGroups[0][0] += 1
	ReDim $aModListGroups[$aModListGroups[0][0] + 1][3]

	$aModListGroups[$aModListGroups[0][0]][0] = GUICtrlCreateTreeViewItem($sText, $hGUI.ModList.List)
	GUICtrlSetColor($aModListGroups[$aModListGroups[0][0]][0], 0x0000C0)

	_GUICtrlTreeView_SetIcon($hGUI.ModList.List, $aModListGroups[$aModListGroups[0][0]][0], @ScriptDir & "\icons\" & ($bEnabled ? "folder-green.ico" : "folder-red.ico"), 0, 6)

	$aModListGroups[$aModListGroups[0][0]][1] = $bEnabled
	$aModListGroups[$aModListGroups[0][0]][2] = $vItem
EndFunc


Func TreeViewFindCategory(Const $bEnabled, Const $vData)
	For $i = 1 To $aModListGroups[0][0]
		If $bEnabled = $aModListGroups[$i][1] And $aModListGroups[$i][2] = $vData Then Return $i
	Next

	Return -1
EndFunc

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
		GUICtrlSetState($hGUI.MenuSettings.Compatibility, $GUI_ENABLE)
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
				Case $NM_RCLICK
                    Local $tPoint = _WinAPI_GetMousePos(True, $hWndFrom), $tHitTest
                    $tHitTest = _GUICtrlTreeView_HitTestEx($hWndFrom, DllStructGetData($tPoint, 1), DllStructGetData($tPoint, 2))
                    If BitAND(DllStructGetData($tHitTest, "Flags"), BitOR($TVHT_ONITEM, $TVHT_ONITEMRIGHT)) Then
                        _GUICtrlTreeView_SelectItem($hWndFrom, DllStructGetData($tHitTest, 'Item'))
						SD_GUI_List_SelectionChanged()
                    EndIf
			EndSwitch
		Case GUICtrlGetHandle($hGUI.ScnList.List)
			Switch $iCode
				Case $LVN_BEGINDRAG
					Return 0
				Case $LVN_ITEMCHANGED
					If Not _GUICtrlListView_GetSelectedCount($hGUI.ScnList.List) Then
						GUICtrlSetState($hGUI.ScnList.Load, $GUI_DISABLE)
						GUICtrlSetState($hGUI.ScnList.Save, $GUI_DISABLE)
						GUICtrlSetState($hGUI.ScnList.Delete, $GUI_DISABLE)
					Else
						GUICtrlSetState($hGUI.ScnList.Save, $MM_GAME_NO_DIR ? $GUI_DISABLE : $GUI_ENABLE)
						Local $aSelected = _GUICtrlListView_GetSelectedIndices($hGUI.ScnList.List, True)
						GUICtrlSetState($hGUI.ScnList.Load, ($aSelected[0] >= 1 And $aSelected[1] == 0) Or $MM_GAME_NO_DIR ? $GUI_DISABLE : $GUI_ENABLE)
						GUICtrlSetState($hGUI.ScnList.Delete, $aSelected[0] >= 1 And $aSelected[1] == 0 ? $GUI_DISABLE : $GUI_ENABLE)
					EndIf
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

	$MM_VIEW_PREV = $MM_VIEW_CURRENT
	$MM_VIEW_CURRENT = $iNewView
	SD_GUI_MainWindowResize(True)

	GUICtrlSetState($hGUI.ModList.Group, $MM_VIEW_CURRENT = $MM_VIEW_MODS ? $GUI_SHOW : $GUI_HIDE)
	GUICtrlSetState($hGUI.ModList.List, $MM_VIEW_CURRENT = $MM_VIEW_MODS ? $GUI_SHOW : $GUI_HIDE)
	GUICtrlSetState($hGUI.ModList.Up, $MM_VIEW_CURRENT = $MM_VIEW_MODS ? $GUI_SHOW : $GUI_HIDE)
	GUICtrlSetState($hGUI.ModList.Down, $MM_VIEW_CURRENT = $MM_VIEW_MODS ? $GUI_SHOW : $GUI_HIDE)
	GUICtrlSetState($hGUI.ModList.ChangeState, $MM_VIEW_CURRENT = $MM_VIEW_MODS ? $GUI_SHOW : $GUI_HIDE)
	If Not $MM_PORTABLE Then GUICtrlSetState($hGUI.MenuSettings.ChangeModDir, $MM_VIEW_CURRENT = $MM_VIEW_MODS ? $GUI_ENABLE : $GUI_DISABLE)

	GUICtrlSetState($hGUI.PluginsList.Group, $MM_VIEW_CURRENT = $MM_VIEW_PLUGINS ? $GUI_SHOW : $GUI_HIDE)
	GUICtrlSetState($hGUI.PluginsList.List, $MM_VIEW_CURRENT = $MM_VIEW_PLUGINS ? $GUI_SHOW : $GUI_HIDE)

	GUICtrlSetState($hGUI.MenuScn.Manage, $MM_VIEW_CURRENT = $MM_VIEW_SCN ? $GUI_DISABLE : $GUI_ENABLE)
	GUICtrlSetState($hGUI.ScnList.Group, $MM_VIEW_CURRENT = $MM_VIEW_SCN ? $GUI_SHOW : $GUI_HIDE)
	GUICtrlSetState($hGUI.ScnList.List, $MM_VIEW_CURRENT = $MM_VIEW_SCN ? $GUI_SHOW : $GUI_HIDE)
	GUICtrlSetState($hGUI.ScnList.Load, $MM_VIEW_CURRENT = $MM_VIEW_SCN ? $GUI_SHOW : $GUI_HIDE)
	GUICtrlSetState($hGUI.ScnList.Save, $MM_VIEW_CURRENT = $MM_VIEW_SCN ? $GUI_SHOW : $GUI_HIDE)
	GUICtrlSetState($hGUI.ScnList.Delete, $MM_VIEW_CURRENT = $MM_VIEW_SCN ? $GUI_SHOW : $GUI_HIDE)

	GUICtrlSetState($hGUI.Back, ($MM_VIEW_CURRENT = $MM_VIEW_PLUGINS Or $MM_VIEW_CURRENT = $MM_VIEW_SCN) ? $GUI_SHOW : $GUI_HIDE)

	If $MM_VIEW_CURRENT = $MM_VIEW_MODS Then
		TreeViewTryFollow($sFollowMod)
	ElseIf $MM_VIEW_CURRENT = $MM_VIEW_PLUGINS Then
		GUICtrlSetState($hGUI.MenuMod.Menu, $GUI_DISABLE)
		TreeViewTryFollow("")
	EndIf

	GUICtrlSetState($hGUI.Info.TabControl, $MM_VIEW_CURRENT = $MM_VIEW_BIG_SCREEN Or $MM_VIEW_CURRENT = $MM_VIEW_SCN ? $GUI_HIDE : $GUI_SHOW)
EndFunc   ;==>SD_SwitchView

Func SD_SwitchSubView(Const $iNewView = $MM_SUBVIEW_DESC)
	$MM_SUBVIEW_PREV = $MM_SUBVIEW_CURRENT
	$MM_SUBVIEW_CURRENT = $iNewView
	SD_GUI_MainWindowResize(True)

	GUICtrlSetState($hGUI.Info.Edit, $MM_SUBVIEW_CURRENT = $MM_SUBVIEW_DESC ? $GUI_SHOW : $GUI_HIDE)

	If $MM_SUBVIEW_CURRENT = $MM_SUBVIEW_INFO Then
		ControlShow($MM_UI_MAIN, '', $hGUI.Info.Desc)
	Else
		ControlHide($MM_UI_MAIN, '', $hGUI.Info.Desc)
	EndIf

	GUICtrlSetState($hGUI.Screen.Control, $MM_SUBVIEW_CURRENT = $MM_SUBVIEW_SCREENS ? $GUI_SHOW : $GUI_HIDE)
	GUICtrlSetState($hGUI.Screen.Open, $MM_SUBVIEW_CURRENT = $MM_SUBVIEW_SCREENS ? $GUI_SHOW : $GUI_HIDE)
	GUICtrlSetState($hGUI.Screen.Back, $MM_SUBVIEW_CURRENT = $MM_SUBVIEW_SCREENS ? $GUI_SHOW : $GUI_HIDE)
	GUICtrlSetState($hGUI.Screen.Forward, $MM_SUBVIEW_CURRENT = $MM_SUBVIEW_SCREENS ? $GUI_SHOW : $GUI_HIDE)
	If $MM_SUBVIEW_CURRENT = $MM_SUBVIEW_SCREENS Then SD_GUI_UpdateScreenByPath($sScreenPath)
EndFunc

Func SD_FormatDescription()
	If $MM_SELECTED_MOD < 0 Then Return ""
	Local $sText
	If $MM_LIST_CONTENT[$MM_SELECTED_MOD][$MOD_ID] <> Mod_Get("caption") Then
		$sText = Lng_GetF("info_group.info.mod_caption", Mod_Get("caption"), $MM_LIST_CONTENT[$MM_SELECTED_MOD][$MOD_ID])
	Else
		$sText = Lng_GetF("info_group.info.mod_caption_s", Mod_Get("caption"))
	EndIf

	If Mod_Get("category") <> "" Then $sText &= @CRLF & Lng_GetF("info_group.info.category", Lng_GetCategory(Mod_Get("category")))
	If Mod_Get("mod_version") <> "0.0" Then	$sText &= @CRLF & Lng_GetF("info_group.info.version", Mod_Get("mod_version"))
	If Mod_Get("author") <> "" Then	$sText &= @CRLF & Lng_GetF("info_group.info.author", Mod_Get("author"))
	If Mod_Get("homepage") <> "" Then	$sText &= @CRLF & Lng_GetF("info_group.info.link", Mod_Get("homepage"))

	Return $sText
EndFunc
