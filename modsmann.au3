#NoTrayIcon
#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=icons\preferences-system.ico
#AutoIt3Wrapper_Outfile=modsmann.exe
#AutoIt3Wrapper_Compression=4
#AutoIt3Wrapper_UseUpx=y
#AutoIt3Wrapper_Res_Description=A mod manager for Era II
#AutoIt3Wrapper_Res_Fileversion=0.90.0.0
#AutoIt3Wrapper_Res_requestedExecutionLevel=asInvoker
#AutoIt3Wrapper_AU3Check_Parameters=-d -w 1 -w 2 -w 3 -w 4 -w 5 -w 6 -w 7
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
; Author:         Aliaksei SyDr Karalenka

#include <GuiMenu.au3>
#include <GuiTreeView.au3>
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
Global $hFormMain, $hLanguageMenu, $hDummyF5
Global $aLanguages[1][2]
Global $hMoreActionsMenu, $hModDelete, $hModAdd, $hModCompatibility, $hModPlugins, $hModHomepage, $hModOpenFolder

Global $hGroupList, $hModList, $hModUp, $hModDown, $hModChangeState
Global $auTreeView, $abModCompatibilityMap

Global $hGroupPlugins, $hPluginsList, $hPluginsBack
Global $aPlugins[1][2], $hPluginsParts[3]

Global $hGroupInfo, $hModInfo

Global $sFollowMod = ""
Global $sCompatibilityMessage = ""
Global $bEnableDisable, $bSelectionChanged
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

StartUp_CheckRunningInstance()

SD_GUI_LoadSize()
SD_GUI_Create()
TreeViewMain()
TreeViewTryFollow($MM_LIST_CONTENT[0][0] > 0 ? $MM_LIST_CONTENT[1][0] : "")
SD_SwitchView()
MainLoop()

Func MainLoop()
	Local $bGUINeedUpdate = False

	While True
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
			SD_GUI_List_ChangeState()
		EndIf

		If $bSelectionChanged Then
			$bSelectionChanged = False
			SD_GUI_List_SelectionChanged()
		EndIf
	WEnd
EndFunc



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
		MsgBox($MB_ICONINFORMATION + $MB_SYSTEMMODAL, "", $sIsLoaded, Default, $hFormMain)
	Else
		Settings_Set("Language", $MM_SETTINGS_LANGUAGE)
	EndIf

	SD_GUI_SetLng()
	SD_GUI_Update()
EndFunc   ;==>SD_GUI_Language_Change

Func SD_GUI_Create()
	Local Const $iLeftOffset = 4, $iTopOffset = 0, $iItemSpacing = 4
;~ 	Local Const $iGroupAddHeight = 16
	Local Const $iMenuHeight = 25 ; yep, this is a magic number, maybe something like 17 (real menu height) + fake group offset 8 (but specified here like 0)

	$hFormMain = GUICreate($MM_TITLE, $MM_WINDOW_MIN_WIDTH, $MM_WINDOW_MIN_HEIGHT, Default, Default, BitOR($GUI_SS_DEFAULT_GUI, $WS_SIZEBOX, $WS_MAXIMIZEBOX), $WS_EX_ACCEPTFILES)
	$MM_WINDOW_MIN_WIDTH_FULL = WinGetPos($hFormMain)[2]
	$MM_WINDOW_MIN_HEIGHT_FULL = WinGetPos($hFormMain)[3]
	GUISetIcon(@ScriptDir & "\icons\preferences-system.ico")
	GUISetState(@SW_HIDE) ; this as dirty fix for GUICtrlSetResizing bug in beta 3.3.13.19

	$hLanguageMenu = GUICtrlCreateMenu("-")
	Local $asTemp = Lng_LoadList()
	For $iCount = 1 To $asTemp[0][0]
		$aLanguages[0][0] += 1
		ReDim $aLanguages[$aLanguages[0][0] + 1][2]
		$aLanguages[$iCount][0] = GUICtrlCreateMenuItem($asTemp[$iCount][0], $hLanguageMenu, Default, 1)
		$aLanguages[$iCount][1] = $asTemp[$iCount][1]
		If $aLanguages[$iCount][1] = $MM_SETTINGS_LANGUAGE Then GUICtrlSetState($aLanguages[$iCount][0], $GUI_CHECKED)
	Next

	$hMoreActionsMenu = GUICtrlCreateMenu("-")
	$hModPlugins = GUICtrlCreateMenuItem("-", $hMoreActionsMenu)
	$hModHomepage = GUICtrlCreateMenuItem("-", $hMoreActionsMenu)
	$hModDelete = GUICtrlCreateMenuItem("-", $hMoreActionsMenu)
	GUICtrlCreateMenuItem("", $hMoreActionsMenu)
	$hModAdd = GUICtrlCreateMenuItem("-", $hMoreActionsMenu)
	$hModCompatibility = GUICtrlCreateMenuItem("-", $hMoreActionsMenu)
	GUICtrlCreateMenuItem("", $hMoreActionsMenu)
	$hModOpenFolder = GUICtrlCreateMenuItem("-", $hMoreActionsMenu)

	$hGroupList = GUICtrlCreateGroup("-", $iLeftOffset, $iTopOffset, $MM_WINDOW_MIN_WIDTH / 2 - $iLeftOffset, $MM_WINDOW_MIN_HEIGHT - $iMenuHeight - $iTopOffset)
	$hModList = GUICtrlCreateTreeView($iLeftOffset + $iItemSpacing, $iTopOffset + 4 * $iItemSpacing, _ ; left, top
			$MM_WINDOW_MIN_WIDTH / 2 - $iLeftOffset - 3 * $iItemSpacing - 90, $MM_WINDOW_MIN_HEIGHT - $iMenuHeight - $iTopOffset - 5 * $iItemSpacing, _ ; width, height, 90 + $iItemSpacing reserved for buttons column
			BitOR($TVS_FULLROWSELECT, $TVS_DISABLEDRAGDROP, $TVS_SHOWSELALWAYS), $WS_EX_CLIENTEDGE)
	$hModUp = GUICtrlCreateButton("", $MM_WINDOW_MIN_WIDTH / 2 - 90 - $iItemSpacing, $iTopOffset + 4 * $iItemSpacing - 1, 90, 25)
	$hModDown = GUICtrlCreateButton("", $MM_WINDOW_MIN_WIDTH / 2 - 90 - $iItemSpacing, $iTopOffset + 5 * $iItemSpacing - 1 + 25, 90, 25)
	$hModChangeState = GUICtrlCreateButton("", $MM_WINDOW_MIN_WIDTH / 2 - 90 - $iItemSpacing, $iTopOffset + 6 * $iItemSpacing - 1 + 2 * 25,90, 25)


	GUICtrlCreateGroup("", -99, -99, 1, 1)


	$hGroupPlugins = GUICtrlCreateGroup("-", $iLeftOffset, $iTopOffset, $MM_WINDOW_MIN_WIDTH / 2 - $iLeftOffset, $MM_WINDOW_MIN_HEIGHT - $iMenuHeight - $iTopOffset)
	$hPluginsList = GUICtrlCreateTreeView($iLeftOffset + $iItemSpacing, $iTopOffset + 4 * $iItemSpacing, _ ; left, top
			$MM_WINDOW_MIN_WIDTH / 2 - $iLeftOffset - 3 * $iItemSpacing - 90, $MM_WINDOW_MIN_HEIGHT - $iMenuHeight - $iTopOffset - 5 * $iItemSpacing, _ ; width, height, 90 + $iItemSpacing reserved for buttons column
			BitOR($TVS_FULLROWSELECT, $TVS_DISABLEDRAGDROP, $TVS_SHOWSELALWAYS), $WS_EX_CLIENTEDGE)
	$hPluginsBack = GUICtrlCreateButton("", $MM_WINDOW_MIN_WIDTH / 2 - 90 - $iItemSpacing, $iTopOffset + 4 * $iItemSpacing - 1, 90, 25)
	GUICtrlCreateGroup("", -99, -99, 1, 1)

	$hGroupInfo = GUICtrlCreateGroup("-", $MM_WINDOW_MIN_WIDTH / 2 + $iItemSpacing, $iTopOffset, _
			$MM_WINDOW_MIN_WIDTH / 2 - $iLeftOffset - $iItemSpacing, $MM_WINDOW_MIN_HEIGHT - $iTopOffset - $iMenuHeight)
	$hModInfo = GUICtrlCreateEdit("", $MM_WINDOW_MIN_WIDTH / 2 + $iItemSpacing + $iItemSpacing, $iTopOffset + 4 * $iItemSpacing, _
			$MM_WINDOW_MIN_WIDTH / 2 - $iLeftOffset - 3 * $iItemSpacing, $MM_WINDOW_MIN_HEIGHT - $iMenuHeight - $iTopOffset - 5 * $iItemSpacing, _
			BitOR($ES_READONLY, $WS_VSCROLL, $WS_TABSTOP))
	GUICtrlCreateGroup("", -99, -99, 1, 1)

	SD_GUI_Mod_Controls_Disable()
	SD_GUI_SetResizing()
	SD_GUI_Events_Register()
	SD_GUI_SetLng()

	WinMove($hFormMain, '', (@DesktopWidth - $MM_WINDOW_WIDTH) / 2, (@DesktopHeight - $MM_WINDOW_HEIGHT) / 2, $MM_WINDOW_WIDTH, $MM_WINDOW_HEIGHT)
	If $MM_WINDOW_MAXIMIZED Then WinSetState($hFormMain, '', @SW_MAXIMIZE)
	$hDummyF5 = GUICtrlCreateDummy()
	Local $AccelKeys[1][2] = [["{F5}", $hDummyF5]]
	GUISetAccelerators($AccelKeys)
	GUISetState(@SW_SHOW)
EndFunc   ;==>SD_GUI_Create

Func SD_GUI_SetResizing()
	GUICtrlSetResizing($hModList, $GUI_DOCKLEFT + $GUI_DOCKTOP + $GUI_DOCKBOTTOM + $GUI_DOCKWIDTH)
	GUICtrlSetResizing($hGroupList, $GUI_DOCKLEFT + $GUI_DOCKTOP + $GUI_DOCKBOTTOM + $GUI_DOCKWIDTH)
	GUICtrlSetResizing($hModUp, $GUI_DOCKALL)
	GUICtrlSetResizing($hModDown, $GUI_DOCKALL)
	GUICtrlSetResizing($hModChangeState, $GUI_DOCKALL)
	GUICtrlSetResizing($hModCompatibility, $GUI_DOCKALL)
	GUICtrlSetResizing($hModAdd, $GUI_DOCKLEFT + $GUI_DOCKBOTTOM + $GUI_DOCKWIDTH + $GUI_DOCKHEIGHT)
	GUICtrlSetResizing($hModOpenFolder, $GUI_DOCKALL)
	GUICtrlSetResizing($hGroupInfo, $GUI_DOCKLEFT + $GUI_DOCKRIGHT + $GUI_DOCKTOP + $GUI_DOCKBOTTOM)
	GUICtrlSetResizing($hModInfo, $GUI_DOCKLEFT + $GUI_DOCKRIGHT + $GUI_DOCKTOP + $GUI_DOCKBOTTOM)
EndFunc   ;==>SD_GUI_SetResizing

Func SD_GUI_Events_Register()
	GUISetOnEvent($GUI_EVENT_CLOSE, "SD_GUI_Close")
	GUIRegisterMsg($WM_GETMINMAXINFO, "WM_GETMINMAXINFO") ; Limit min size
	GUIRegisterMsg($WM_DROPFILES, "SD_GUI_Mod_AddByDnD") ; Input files
	GUIRegisterMsg($WM_NOTIFY, "WM_NOTIFY") ;  TreeView

	For $iCount = 1 To $aLanguages[0][0]
		GUICtrlSetOnEvent($aLanguages[$iCount][0], "SD_GUI_Language_Change")
	Next

	GUICtrlSetOnEvent($hModUp, "SD_GUI_Mod_Move_Up")
	GUICtrlSetOnEvent($hModDown, "SD_GUI_Mod_Move_Down")
	GUICtrlSetOnEvent($hModChangeState, "SD_GUI_Mod_EnableDisableEvent")
	GUICtrlSetOnEvent($hModCompatibility, "SD_GUI_Mod_Compatibility")
	GUICtrlSetOnEvent($hModPlugins, "SD_GUI_Manage_Plugins")
	GUICtrlSetOnEvent($hModHomepage, "SD_GUI_Mod_Website")
	GUICtrlSetOnEvent($hModDelete, "SD_GUI_Mod_Delete")
	GUICtrlSetOnEvent($hModAdd, "SD_GUI_Mod_Add")
	GUICtrlSetOnEvent($hModOpenFolder, "SD_GUI_Mod_OpenFolder")
	GUICtrlSetOnEvent($hDummyF5, "SD_GUI_Update")

	GUICtrlSetOnEvent($hPluginsBack, "SD_GUI_Plugins_Close")
EndFunc   ;==>SD_GUI_Events_Register

Func SD_GUI_SetLng()
	GUICtrlSetData($hLanguageMenu, Lng_Get("lang.language"))
	GUICtrlSetData($hGroupList, Lng_Get("mod_list.caption"))
	GUICtrlSetData($hModUp, Lng_Get("mod_list.up"))
	GUICtrlSetData($hModDown, Lng_Get("mod_list.down"))
	GUICtrlSetData($hModChangeState, Lng_Get("mod_list.enable"))
	GUICtrlSetData($hModDelete, Lng_Get("mod_list.delete"))
	GUICtrlSetData($hModPlugins, Lng_Get("mod_list.plugins"))
	GUICtrlSetData($hModCompatibility, Lng_Get("mod_list.compatibility"))
	GUICtrlSetData($hModAdd, Lng_Get("mod_list.add_new"))
	GUICtrlSetData($hModHomepage, Lng_Get("mod_list.homepage"))
	GUICtrlSetData($hMoreActionsMenu, Lng_Get("mod_list.more"))
	GUICtrlSetData($hModOpenFolder, Lng_Get("mod_list.open_dir"))

	GUICtrlSetData($hGroupPlugins, Lng_GetF("plugins_list.caption", $MM_LIST_CONTENT[0][0] > 0 ? $MM_LIST_CONTENT[1][3] : ""))
	GUICtrlSetData($hPluginsBack, Lng_Get("plugins_list.back"))

	GUICtrlSetData($hGroupInfo, Lng_Get("info_group.caption"))
EndFunc   ;==>SD_GUI_SetLng

Func SD_GUI_Mod_Compatibility()
	MsgBox(4096, "", $sCompatibilityMessage, Default, $hFormMain)
EndFunc   ;==>SD_GUI_Mod_Compatibility


Func SD_GUI_Mod_OpenFolder()
	Local $iTreeViewIndex = TreeViewGetSelectedIndex()
	Local $iModIndex1 = $auTreeView[$iTreeViewIndex][2]
	If $iModIndex1 < 1 Or $iModIndex1 > $MM_LIST_CONTENT[0][0] Then Return -1 ; never
	Local $sPath = '"' & $MM_LIST_DIR_PATH & "\" & $MM_LIST_CONTENT[$iModIndex1][0] & '"'
	ShellExecute($sPath)
EndFunc   ;==>SD_GUI_Mod_OpenFolder

Func SD_GUI_Manage_Plugins()
	Plugins_ListLoad($MM_LIST_CONTENT[$auTreeView[TreeViewGetSelectedIndex()][2]][0])
	GUICtrlSetData($hGroupPlugins, Lng_GetF("plugins_list.caption", $MM_LIST_CONTENT[0][0] > 0 ? $MM_LIST_CONTENT[$auTreeView[TreeViewGetSelectedIndex()][2]][3] : ""))
	SD_GUI_PluginsDisplay()
	SD_SwitchView($MM_VIEW_PLUGINS)
EndFunc   ;==>SD_GUI_Manage_Plugins

Func SD_GUI_Plugins_Close()
	SD_SwitchView($MM_VIEW_MODS)
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

	GUISetState(@SW_DISABLE, $hFormMain)

	Local $aModList = Mod_ListCheck($aDroppedFiles); FilePath, ModName, ModLocalizedName, ModLocalizedDescription, Version, MinVersion, InstalledVersion, AuthorName, ModWebSite

	GUISetState(@SW_ENABLE, $hFormMain)
	GUISetState(@SW_RESTORE, $hFormMain)

	If $aModList[0][0] = 0 Then
		MsgBox($MB_SYSTEMMODAL, "", StringFormat(Lng_Get("add_new.progress.no_mods"), "0_O"), Default, $hFormMain)
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
	Local $sFileList = FileOpenDialog("", "", Lng_Get("add_new.filter"), $FD_FILEMUSTEXIST + $FD_MULTISELECT, "", $hFormMain)
	If @error Then Return False
	GUISetState(@SW_DISABLE, $hFormMain)

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

	GUISetState(@SW_ENABLE, $hFormMain)
	GUISetState(@SW_RESTORE, $hFormMain)

	If $aModList[0][0] = 0 Then
		MsgBox($MB_SYSTEMMODAL, "", StringFormat(Lng_Get("add_new.progress.no_mods"), "0_O"), Default, $hFormMain)
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
EndFunc   ;==>SD_GUI_Mod_Swap

Func SD_GUI_Mod_Delete()
	Local $iTreeViewIndex = TreeViewGetSelectedIndex()
	Local $iModIndex = $auTreeView[$iTreeViewIndex][2]
	Local $iAnswer = MsgBox($MB_YESNO + $MB_ICONQUESTION + $MB_DEFBUTTON2 + $MB_TASKMODAL, "", StringFormat(Lng_Get("mod_list.delete_confirm"), $MM_LIST_CONTENT[$iModIndex][0]), Default, $hFormMain)
	If $iAnswer = $IDNO Then Return

	Mod_Delete($iModIndex)

	TreeViewMain()
	If $MM_LIST_CONTENT[0][0] < $iModIndex Then
		$iModIndex = $MM_LIST_CONTENT[0][0]
	EndIf

	If $iModIndex > 0 Then
		$sFollowMod = $MM_LIST_CONTENT[$iModIndex][0]
		TreeViewTryFollow($sFollowMod)
	EndIf
EndFunc   ;==>SD_GUI_Mod_Delete

Func SD_GUI_Mod_EnableDisable($bNoCtrlId = False)
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

	If Not $bNoCtrlId Then ControlFocus($hFormMain, "", @GUI_CtrlId)
EndFunc   ;==>SD_GUI_Mod_EnableDisable

Func SD_GUI_Plugin_ChangeState()
	Local $hSelected = _GUICtrlTreeView_GetSelection($hPluginsList)

	For $i = 1 To $aPlugins[0][0]
		If $hSelected <> $aPlugins[$i][0] Then ContinueLoop

		Local $iPlugin = $aPlugins[$i][1]

		If $iPlugin > 0 And $iPlugin <= $MM_PLUGINS_CONTENT[0][0] Then
			Plugins_ChangeState($iPlugin)
			_GUICtrlTreeView_SetIcon($hPluginsList, $aPlugins[$i][0], $MM_PLUGINS_CONTENT[$iPlugin][$PLUGIN_STATE] ? (@ScriptDir & "\icons\dialog-ok-apply.ico") : (@ScriptDir & "\icons\edit-delete.ico"), 0, 6)
		EndIf

		ExitLoop
	Next
EndFunc

Func SD_GUI_List_ChangeState()
	Switch $MM_VIEW_CURRENT
		Case $MM_VIEW_MODS
			SD_GUI_Mod_EnableDisable(True)
		Case $MM_VIEW_PLUGINS
			SD_GUI_Plugin_ChangeState()
	EndSwitch
EndFunc

Func SD_GUI_Mod_EnableDisableEvent()
	SD_GUI_Mod_EnableDisable()
EndFunc   ;==>SD_GUI_Mod_EnableDisableEvent

Func SD_GUI_Update()
	GUISwitch($hFormMain)
	TreeViewMain()
	GUICtrlSetState($auTreeView[1][0], $GUI_FOCUS)
	TreeViewTryFollow($sFollowMod)
EndFunc   ;==>SD_GUI_Update

Func TreeViewMain()
	Mod_ListLoad()
	$abModCompatibilityMap = Mod_CompatibilityMapLoad()

	_GUICtrlTreeView_BeginUpdate($hModList)
	_GUICtrlTreeView_DeleteAll($hModList)
	_GUICtrlTreeView_EndUpdate($hModList)

	$auTreeView = TreeViewFill()
EndFunc   ;==>TreeViewMain

Func SD_GUI_PluginsDisplay()
	_GUICtrlTreeView_BeginUpdate($hPluginsList)
	_GUICtrlTreeView_DeleteAll($hPluginsList)

	If $MM_PLUGINS_PART_PRESENT[$PLUGIN_GROUP_GLOBAL] Then
		$hPluginsParts[$PLUGIN_GROUP_GLOBAL] = _GUICtrlTreeView_Add($hPluginsList, 0, Lng_Get("plugins_list.global"))
		_GUICtrlTreeView_SetIcon($hPluginsList, $hPluginsParts[$PLUGIN_GROUP_GLOBAL], @ScriptDir & "\icons\folder-green.ico", 0, 6)
	EndIf

	If $MM_PLUGINS_PART_PRESENT[$PLUGIN_GROUP_BEFORE] Then
		$hPluginsParts[$PLUGIN_GROUP_BEFORE] = _GUICtrlTreeView_Add($hPluginsList, 0, Lng_Get("plugins_list.before_wog"))
		_GUICtrlTreeView_SetIcon($hPluginsList, $hPluginsParts[$PLUGIN_GROUP_BEFORE], @ScriptDir & "\icons\folder-green.ico", 0, 6)
	EndIf

	If $MM_PLUGINS_PART_PRESENT[$PLUGIN_GROUP_AFTER] Then
		$hPluginsParts[$PLUGIN_GROUP_AFTER] = _GUICtrlTreeView_Add($hPluginsList, 0, Lng_Get("plugins_list.after_wog"))
		_GUICtrlTreeView_SetIcon($hPluginsList, $hPluginsParts[$PLUGIN_GROUP_AFTER], @ScriptDir & "\icons\folder-green.ico", 0, 6)
	EndIf

	ReDim $aPlugins[$MM_PLUGINS_CONTENT[0][0] + 1][2]
	$aPlugins[0][0] = $MM_PLUGINS_CONTENT[0][0]
	Local $hItem
	For $i = 1 To $MM_PLUGINS_CONTENT[0][0]
		$hItem = _GUICtrlTreeView_AddChild($hPluginsList, $hPluginsParts[$MM_PLUGINS_CONTENT[$i][$PLUGIN_GROUP]], $MM_PLUGINS_CONTENT[$i][$PLUGIN_CAPTION])
		_GUICtrlTreeView_SetIcon($hPluginsList, $hItem, $MM_PLUGINS_CONTENT[$i][$PLUGIN_STATE] ? (@ScriptDir & "\icons\dialog-ok-apply.ico") : (@ScriptDir & "\icons\edit-delete.ico"), 0, 6)
		$aPlugins[$i][0] = $hItem
		$aPlugins[$i][1] = $i
	Next

	If $MM_PLUGINS_PART_PRESENT[$PLUGIN_GROUP_GLOBAL] Then _GUICtrlTreeView_Expand($hPluginsList, $hPluginsParts[$PLUGIN_GROUP_GLOBAL], True)
	If $MM_PLUGINS_PART_PRESENT[$PLUGIN_GROUP_BEFORE] Then _GUICtrlTreeView_Expand($hPluginsList, $hPluginsParts[$PLUGIN_GROUP_BEFORE], True)
	If $MM_PLUGINS_PART_PRESENT[$PLUGIN_GROUP_AFTER] Then _GUICtrlTreeView_Expand($hPluginsList, $hPluginsParts[$PLUGIN_GROUP_AFTER], True)

	_GUICtrlTreeView_EndUpdate($hPluginsList)
EndFunc

Func SD_GUI_Mod_Controls_Disable()
	GUICtrlSetState($hModUp, $GUI_DISABLE)
	GUICtrlSetState($hModDown, $GUI_DISABLE)
	GUICtrlSetState($hModChangeState, $GUI_DISABLE)
	GUICtrlSetState($hModDelete, $GUI_DISABLE)
	GUICtrlSetState($hModPlugins, $GUI_DISABLE)
	GUICtrlSetState($hModHomepage, $GUI_DISABLE)
	GUICtrlSetState($hModOpenFolder, $GUI_DISABLE)
	GUICtrlSetData($hModInfo, Lng_Get("info_group.no_info"))
;~ 	$sFollowMod = ""
EndFunc   ;==>SD_GUI_Mod_Controls_Disable

Func SD_GUI_List_SelectionChanged()
	Switch $MM_VIEW_CURRENT
		Case $MM_VIEW_MODS
			SD_GUI_Mod_SelectionChanged()
		Case $MM_VIEW_PLUGINS
			SD_GUI_Plugin_SelectionChanged()
	EndSwitch
EndFunc

Func SD_GUI_Mod_SelectionChanged()
	Local $hSelected = GUICtrlRead($auTreeView[0][0])

	For $iCount = 1 To UBound($auTreeView, 1) - 1
		If $hSelected <> $auTreeView[$iCount][0] Then ContinueLoop

		If $auTreeView[$iCount][1] = 0 Then
			SD_GUI_Mod_Controls_Disable()
			ExitLoop
		EndIf

		Local $iModIndex = $auTreeView[$iCount][2]

		$sFollowMod = $MM_LIST_CONTENT[$iModIndex][0]
		If $iModIndex > 0 And $iModIndex <= $MM_LIST_CONTENT[0][0] Then

			; Info (5)
			GUICtrlSetData($hModInfo, Mod_InfoLoad($MM_LIST_CONTENT[$iModIndex][0], $MM_LIST_CONTENT[$iModIndex][5]))

			; MoveUp (2)
			If $iModIndex > 0 And $iModIndex <> -1 And $auTreeView[$iCount - 1][2] <> -1 And _
					$MM_LIST_CONTENT[$iModIndex][1] = "Enabled" And $MM_LIST_CONTENT[$auTreeView[$iCount - 1][2]][1] = "Enabled" Then
				GUICtrlSetState($hModUp, $GUI_ENABLE)
			Else
				GUICtrlSetState($hModUp, $GUI_DISABLE)
			EndIf

			; MoveDown (2)
			If $iModIndex < $MM_LIST_CONTENT[0][0] And $iModIndex <> -1 And $auTreeView[$iCount + 1][2] <> -1 And _
					$MM_LIST_CONTENT[$auTreeView[$iCount][2]][1] = "Enabled" And $MM_LIST_CONTENT[$auTreeView[$iCount + 1][2]][1] = "Enabled" Then
				GUICtrlSetState($hModDown, $GUI_ENABLE)
			Else
				GUICtrlSetState($hModDown, $GUI_DISABLE)
			EndIf

			; Enable/Disable/Remove (1,2)

			GUICtrlSetState($hModChangeState, $GUI_ENABLE)
			If $MM_LIST_CONTENT[$auTreeView[$iCount][2]][1] = "Disabled" Then
				GUICtrlSetData($hModChangeState, Lng_Get("mod_list.enable"))
			ElseIf $MM_LIST_CONTENT[$auTreeView[$iCount][2]][2] Then ; Not exist
				GUICtrlSetData($hModChangeState, Lng_Get("mod_list.remove"))
			Else
				GUICtrlSetData($hModChangeState, Lng_Get("mod_list.disable"))
			EndIf

			; Plugins
			If Plugins_ModHavePlugins($MM_LIST_CONTENT[$iModIndex][0]) Then
				GUICtrlSetState($hModPlugins, $GUI_ENABLE)
			Else
				GUICtrlSetState($hModPlugins, $GUI_DISABLE)
			EndIf

			; Website (6)
			If $MM_LIST_CONTENT[$iModIndex][6] Then
				GUICtrlSetState($hModHomepage, $GUI_ENABLE)
			Else
				GUICtrlSetState($hModHomepage, $GUI_DISABLE)
			EndIf

			; Delete (2)
			If $MM_LIST_CONTENT[$iModIndex][2] Then
				GUICtrlSetState($hModDelete, $GUI_DISABLE)
			Else
				GUICtrlSetState($hModDelete, $GUI_ENABLE)
			EndIf

			; Modmaker (2)
			If Not $MM_LIST_CONTENT[$iModIndex][2] Then
				GUICtrlSetState($hModOpenFolder, $GUI_ENABLE)
			Else
				GUICtrlSetState($hModOpenFolder, $GUI_DISABLE)
			EndIf
		EndIf

		ExitLoop
	Next
EndFunc   ;==>SD_GUI_Mod_SelectionChanged

Func SD_GUI_Plugin_SelectionChanged()
	Local $hSelected = _GUICtrlTreeView_GetSelection($hPluginsList)

	For $i = 1 To $aPlugins[0][0]
		If $hSelected <> $aPlugins[$i][0] Then ContinueLoop

		Local $iPlugin = $aPlugins[$i][1]

		If $iPlugin > 0 And $iPlugin <= $MM_PLUGINS_CONTENT[0][0] Then
			GUICtrlSetData($hModInfo, $MM_PLUGINS_CONTENT[$iPlugin][$PLUGIN_DESCRIPTION])
		EndIf

		Return
	Next

	GUICtrlSetData($hModInfo, Lng_Get("info_group.no_info"))
EndFunc   ;==>SD_GUI_Mod_SelectionChanged

Func TreeViewFill()
	_GUICtrlTreeView_BeginUpdate($hModList)

	Local $aTreeViewData[$MM_LIST_CONTENT[0][0] + 1][4] ; $TreeViewHandle, $ParentIndex, $ModIndex / $EnabledDisabled, $PriorityGroup (Only for groups)

	$aTreeViewData[0][0] = $hModList
	$aTreeViewData[0][1] = -1
	$aTreeViewData[0][2] = -1
	$aTreeViewData[0][3] = -1

	Local $iIndexToAdd = 1
	Local $iCurrentGroup = -1, $bCurrentGroupEnabled = True

	GUICtrlSetState($hModCompatibility, $GUI_DISABLE)

	For $iCount = 1 To $MM_LIST_CONTENT[0][0]
		Local $bEnabled = $MM_LIST_CONTENT[$iCount][1] = "Enabled"
		Local $iPriority = $MM_LIST_CONTENT[$iCount][9]
		Local $sCaption = $MM_LIST_CONTENT[$iCount][2] ? Lng_GetF("mod_list.missing", $MM_LIST_CONTENT[$iCount][3]) : $MM_LIST_CONTENT[$iCount][3]

		Local $bCreateNewGroup = False
		If $iCurrentGroup = -1 Then $bCreateNewGroup = True
		If $iCurrentGroup <> -1 And $bCurrentGroupEnabled And $bEnabled And $aTreeViewData[$iCurrentGroup][3] <> $iPriority Then $bCreateNewGroup = True
		If $bCurrentGroupEnabled And Not $bEnabled Then $bCreateNewGroup = True

		If $bCreateNewGroup Then
			Local $sText = Lng_Get("mod_list.group.disabled")
			If $bEnabled Then $sText = Lng_Get("mod_list.group.enabled")
			If $bEnabled And $iPriority <> 0 Then $sText = StringFormat(Lng_Get("mod_list.group.enabled_with_priority"), $iPriority)

			$aTreeViewData[$iIndexToAdd][0] = GUICtrlCreateTreeViewItem($sText, $aTreeViewData[0][0])
			GUICtrlSetColor($aTreeViewData[$iIndexToAdd][0], 0x0000C0)
;~ 			GUICtrlSetOnEvent($aTreeViewData[$iIndexToAdd][0], "SD_GUI_Mod_Controls_Disable")
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

		$aTreeViewData[$iIndexToAdd][0] = GUICtrlCreateTreeViewItem($sCaption, $aTreeViewData[$aTreeViewData[$iIndexToAdd][1]][0])
;~ 		GUICtrlSetOnEvent($aTreeViewData[$iIndexToAdd][0], "SD_GUI_Mod_Controls_Set")
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
	_GUICtrlTreeView_EndUpdate($hModList)
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
					$sCompatibilityMessage = StringFormat(Lng_Get("compatibility.part1"), $MM_LIST_CONTENT[$iCount][3]) & @CRLF
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
		$sCompatibilityMessage &= @CRLF & Lng_Get("compatibility.part2")
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
	Local $iSelected = GUICtrlRead($hModList)
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
		If $MM_LIST_CONTENT[$iCount][0] = $sModID Then
			$iModIndex = $iCount
			ExitLoop
		EndIf
	Next

	If $iModIndex = 0 Then
		GUICtrlSetState($auTreeView[0][0], $GUI_FOCUS)
		Return
	EndIf

	GUICtrlSetState($auTreeView[1][0], $GUI_FOCUS)
	Local $iIndex = TreeViewGetIndexByModIndex($iModIndex, $auTreeView)
	GUICtrlSetState($auTreeView[$iIndex][0], $GUI_FOCUS)
EndFunc

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
		_GUICtrlTreeView_SelectItem($hPluginsList, $hPluginsParts[$PLUGIN_GROUP_GLOBAL], $TVGN_FIRSTVISIBLE)
		_GUICtrlTreeView_SelectItem($hPluginsList, $hPluginsParts[$PLUGIN_GROUP_GLOBAL], $TVGN_CARET)
	EndIf

	If $MM_PLUGINS_CONTENT[0][0] > 0 Then
		_GUICtrlTreeView_SelectItem($hPluginsList, $aPlugins[1][0], $TVGN_CARET)
	EndIf
EndFunc

Func WM_GETMINMAXINFO($hwnd, $msg, $wParam, $lParam)
	#forceref $hwnd, $Msg, $wParam, $lParam
	Local $tagMaxinfo = DllStructCreate("int;int;int;int;int;int;int;int;int;int", $lParam)
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
		Case GUICtrlGetHandle($hModList), GUICtrlGetHandle($hPluginsList)
			Switch $iCode
				Case $NM_DBLCLK
					$bEnableDisable = True
				Case $TVN_SELCHANGEDA, $TVN_SELCHANGEDW
					$bSelectionChanged = True
			EndSwitch
	EndSwitch

	Return $GUI_RUNDEFMSG
EndFunc   ;==>WM_NOTIFY

Func SD_SwitchView($iNewView = $MM_VIEW_MODS)
	GUICtrlSetData($hModInfo, "")

	$MM_VIEW_CURRENT = $iNewView

	Switch $iNewView
		Case $MM_VIEW_MODS
			GUICtrlSetState($hGroupPlugins, $GUI_HIDE)
			GUICtrlSetState($hPluginsList, $GUI_HIDE)
			GUICtrlSetState($hPluginsBack, $GUI_HIDE)

			GUICtrlSetState($hGroupList, $GUI_SHOW)
			GUICtrlSetState($hModList, $GUI_SHOW)
			GUICtrlSetState($hModUp, $GUI_SHOW)
			GUICtrlSetState($hModDown, $GUI_SHOW)
			GUICtrlSetState($hModChangeState, $GUI_SHOW)
			GUICtrlSetState($hModPlugins, $GUI_ENABLE)
			GUICtrlSetState($hModDelete, $GUI_ENABLE)

			TreeViewTryFollow($sFollowMod)
		Case $MM_VIEW_PLUGINS
			GUICtrlSetState($hGroupList, $GUI_HIDE)
			GUICtrlSetState($hModList, $GUI_HIDE)
			GUICtrlSetState($hModUp, $GUI_HIDE)
			GUICtrlSetState($hModDown, $GUI_HIDE)
			GUICtrlSetState($hModChangeState, $GUI_HIDE)
			GUICtrlSetState($hModPlugins, $GUI_DISABLE)
			GUICtrlSetState($hModDelete, $GUI_DISABLE)

			GUICtrlSetState($hGroupPlugins, $GUI_SHOW)
			GUICtrlSetState($hPluginsList, $GUI_SHOW)
			GUICtrlSetState($hPluginsBack, $GUI_SHOW)

			TreeViewTryFollow("")
		Case $MM_VIEW_INSTALL
	EndSwitch
EndFunc
