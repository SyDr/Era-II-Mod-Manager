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
Global $hFormMain, $hModList, $hLanguageMenu
Global $auTreeView, $abModCompatibilityMap
Global $bGUINeedUpdate = False

Global $hGroupList, $hGroupScenario, $hGroupModInfo, $hSettings
Global $aLanguages[1][2]
Global $hButtonUp, $hButtonDown, $hButtonEnable, $hButtonDisable, $hButtonRemove, $hModDelete, $hModAdd, $hModCompatibility
Global $hButtonPlugins, $hModWebsite, $hModOpenFolder, $hMoreActionsContextMenuID, $hButtonMoreActions
Global $hModReadmeC, $hModInfoC
Global $hModInfo
Global $sFollowMod = ""
Global $sCompatibilityMessage = ""
Global $hDummyF5
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

Global $bSyncPresetWithWS = Settings_Get("SyncPresetWithWS")
Global $bDisplayVersion = Settings_Get("DisplayVersion")

SD_GUI_LoadSize()
SD_GUI_Create()
TreeViewMain()
TreeViewTryFollow("")

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
		SD_GUI_Mod_EnableDisable(True)
	EndIf

	If $bSelectionChanged Then
		$bSelectionChanged = False
		SD_GUI_Mod_SelectionChanged()
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
		MsgBox($MB_ICONINFORMATION + $MB_SYSTEMMODAL, "", $sIsLoaded, Default, $hFormMain)
	Else
		Settings_Set("Language", $MM_SETTINGS_LANGUAGE)
	EndIf

	SD_GUI_SetLng()
	SD_GUI_Update()
EndFunc   ;==>SD_GUI_Language_Change

Func SD_GUI_Create()
	Local Const $iLeftOffset = 4, $iTopOffset = 0, $iItemSpacing = 4
	Local Const $iMenuHeight = 25 ; yep, this is a magic number, maybe something like 17 (real menu height) + fake group offset 8 (but specified here like 0)

	$hFormMain = GUICreate($MM_TITLE, $MM_WINDOW_MIN_WIDTH, $MM_WINDOW_MIN_HEIGHT, Default, Default, BitOR($GUI_SS_DEFAULT_GUI, $WS_SIZEBOX, $WS_MAXIMIZEBOX), $WS_EX_ACCEPTFILES)
	GUISetIcon(@ScriptDir & "\icons\preferences-system.ico")
	GUISetState(@SW_HIDE) ; this as dirty fix for GUICtrlSetResizing bug in beta 3.3.13.19

	$hLanguageMenu = GUICtrlCreateMenu("&Language")
	Local $asTemp = Lng_LoadList()
	For $iCount = 1 To $asTemp[0][0]
		$aLanguages[0][0] += 1
		ReDim $aLanguages[$aLanguages[0][0] + 1][2]
		$aLanguages[$iCount][0] = GUICtrlCreateMenuItem($asTemp[$iCount][0], $hLanguageMenu, Default, 1)
		$aLanguages[$iCount][1] = $asTemp[$iCount][1]
		If $aLanguages[$iCount][1] = $MM_SETTINGS_LANGUAGE Then GUICtrlSetState($aLanguages[$iCount][0], $GUI_CHECKED)
	Next

	$hGroupList = GUICtrlCreateGroup("", $iLeftOffset, $iTopOffset, $MM_WINDOW_MIN_WIDTH / 2 - $iLeftOffset, $MM_WINDOW_MIN_HEIGHT - $iMenuHeight - $iTopOffset)
	$hModList = GUICtrlCreateTreeView($iLeftOffset + $iItemSpacing, $iTopOffset + 4 * $iItemSpacing, _ ; left, top
			$MM_WINDOW_MIN_WIDTH / 2 - $iLeftOffset - 3 * $iItemSpacing - 90, $MM_WINDOW_MIN_HEIGHT - $iMenuHeight - $iTopOffset - 5 * $iItemSpacing, _ ; width, height, 90 + $iItemSpacing reserved for buttons column
			BitOR($TVS_HASBUTTONS, $TVS_FULLROWSELECT, $TVS_DISABLEDRAGDROP, $TVS_SHOWSELALWAYS), $WS_EX_CLIENTEDGE)
	$hButtonUp = GUICtrlCreateButton("", $MM_WINDOW_MIN_WIDTH / 2 - 90 - $iItemSpacing, $iTopOffset + 4 * $iItemSpacing - 1, 90, 25)
	$hButtonDown = GUICtrlCreateButton("", $MM_WINDOW_MIN_WIDTH / 2 - 90 - $iItemSpacing, $iTopOffset + 5 * $iItemSpacing - 1 + 25, 90, 25)
	$hButtonEnable = GUICtrlCreateButton("", $MM_WINDOW_MIN_WIDTH / 2 - 90 - $iItemSpacing, $iTopOffset + 6 * $iItemSpacing - 1 + 2 * 25,90, 25)
	$hButtonDisable = GUICtrlCreateButton("", $MM_WINDOW_MIN_WIDTH / 2 - 90 - $iItemSpacing, $iTopOffset + 6 * $iItemSpacing - 1 + 2 * 25,90, 25)
	$hButtonRemove = GUICtrlCreateButton("", $MM_WINDOW_MIN_WIDTH / 2 - 90 - $iItemSpacing, $iTopOffset + 6 * $iItemSpacing - 1 + 2 * 25, 90, 25)
	GUICtrlSetState($hButtonDisable, $GUI_HIDE)
	GUICtrlSetState($hButtonRemove, $GUI_HIDE)

	$hButtonMoreActions = GUICtrlCreateButton("", $MM_WINDOW_MIN_WIDTH / 2 - 90 - $iItemSpacing, $iTopOffset + 8 * $iItemSpacing - 1 + 4 * 25, 90, 25)
	Local $hMoreActionsDummy = GUICtrlCreateDummy()
	$hDummyF5 = GUICtrlCreateDummy()
	$hMoreActionsContextMenuID = GUICtrlCreateContextMenu($hMoreActionsDummy)
	$hButtonPlugins = GUICtrlCreateMenuItem("", $hMoreActionsDummy)
	$hModWebsite = GUICtrlCreateMenuItem("", $hMoreActionsDummy)
	$hModCompatibility = GUICtrlCreateMenuItem("", $hMoreActionsDummy)
	$hModDelete = GUICtrlCreateMenuItem("", $hMoreActionsDummy)
	GUICtrlCreateMenuItem("", $hMoreActionsDummy)
	$hModOpenFolder = GUICtrlCreateMenuItem("", $hMoreActionsDummy)
	$hModInfoC = GUICtrlCreateMenuItem("", $hMoreActionsDummy)
	$hModReadmeC = GUICtrlCreateMenuItem("", $hMoreActionsDummy)

	$hModAdd = GUICtrlCreateButton("", $MM_WINDOW_MIN_WIDTH / 2 - 90 - $iItemSpacing, $MM_WINDOW_MIN_HEIGHT - $iMenuHeight - $iTopOffset - 8 * $iItemSpacing - 25, 90, 25)
	$hSettings = GUICtrlCreateButton("", $MM_WINDOW_MIN_WIDTH / 2 - 90 - $iItemSpacing, $MM_WINDOW_MIN_HEIGHT - $iMenuHeight - $iTopOffset - 7 * $iItemSpacing, 90, 25)
	GUICtrlCreateGroup("", -99, -99, 1, 1)

	$hGroupScenario = GUICtrlCreateGroup("", $MM_WINDOW_MIN_WIDTH / 2 + $iItemSpacing, $iTopOffset, $MM_WINDOW_MIN_WIDTH / 2 - $iLeftOffset - $iItemSpacing, $MM_WINDOW_MIN_HEIGHT / 2 - $iMenuHeight - $iItemSpacing - $iTopOffset)


	GUICtrlCreateGroup("", -99, -99, 1, 1)

	$hGroupModInfo = GUICtrlCreateGroup("", $MM_WINDOW_MIN_WIDTH / 2 + $iItemSpacing, $MM_WINDOW_MIN_HEIGHT / 2 - $iItemSpacing - $iMenuHeight, $MM_WINDOW_MIN_WIDTH / 2 - $iLeftOffset - $iItemSpacing, $MM_WINDOW_MIN_HEIGHT / 2 + $iItemSpacing - $iTopOffset)
	$hModInfo = GUICtrlCreateEdit("", $MM_WINDOW_MIN_WIDTH / 2 + $iItemSpacing + $iItemSpacing, _
			$MM_WINDOW_MIN_HEIGHT / 2 + 3 * $iItemSpacing - $iMenuHeight, $MM_WINDOW_MIN_WIDTH / 2 - $iLeftOffset - 3 * $iItemSpacing, $MM_WINDOW_MIN_HEIGHT / 2 - 4 * $iItemSpacing - $iTopOffset, _
			$ES_READONLY + $ES_AUTOVSCROLL + $WS_VSCROLL)
	GUICtrlCreateGroup("", -99, -99, 1, 1)

	SD_GUI_Mod_Controls_Disable()
	SD_GUI_SetResizing()
	SD_GUI_Events_Register()
	SD_GUI_SetLng()

	WinMove($hFormMain, '', (@DesktopWidth - $MM_WINDOW_WIDTH) / 2, (@DesktopHeight - $MM_WINDOW_HEIGHT) / 2, $MM_WINDOW_WIDTH, $MM_WINDOW_HEIGHT)
	If $MM_WINDOW_MAXIMIZED Then WinSetState($hFormMain, '', @SW_MAXIMIZE)
	GUISetState(@SW_SHOW)
	Local $AccelKeys[1][2] = [["{F5}", $hDummyF5]]
	GUISetAccelerators($AccelKeys)
EndFunc   ;==>SD_GUI_Create

Func SD_GUI_SetResizing()
	GUICtrlSetResizing($hModList, $GUI_DOCKLEFT + $GUI_DOCKTOP + $GUI_DOCKBOTTOM + $GUI_DOCKWIDTH)
	GUICtrlSetResizing($hGroupList, $GUI_DOCKLEFT + $GUI_DOCKTOP + $GUI_DOCKBOTTOM + $GUI_DOCKWIDTH)
	GUICtrlSetResizing($hButtonUp, $GUI_DOCKALL)
	GUICtrlSetResizing($hButtonDown, $GUI_DOCKALL)
	GUICtrlSetResizing($hButtonEnable, $GUI_DOCKALL)
	GUICtrlSetResizing($hButtonDisable, $GUI_DOCKALL)
	GUICtrlSetResizing($hButtonRemove, $GUI_DOCKALL)
	GUICtrlSetResizing($hModCompatibility, $GUI_DOCKALL)
	GUICtrlSetResizing($hButtonMoreActions, $GUI_DOCKALL)
	GUICtrlSetResizing($hModAdd, $GUI_DOCKLEFT + $GUI_DOCKBOTTOM + $GUI_DOCKWIDTH + $GUI_DOCKHEIGHT)
	GUICtrlSetResizing($hModOpenFolder, $GUI_DOCKALL)
	GUICtrlSetResizing($hModInfoC, $GUI_DOCKALL)
	GUICtrlSetResizing($hModReadmeC, $GUI_DOCKALL)
	GUICtrlSetResizing($hGroupScenario, $GUI_DOCKRIGHT + $GUI_DOCKTOP + $GUI_DOCKWIDTH + $GUI_DOCKHEIGHT)
	GUICtrlSetResizing($hGroupModInfo, $GUI_DOCKLEFT + $GUI_DOCKRIGHT + $GUI_DOCKTOP + $GUI_DOCKBOTTOM)
	GUICtrlSetResizing($hModInfo, $GUI_DOCKLEFT + $GUI_DOCKRIGHT + $GUI_DOCKTOP + $GUI_DOCKBOTTOM)
EndFunc   ;==>SD_GUI_SetResizing


Func SD_GUI_Events_Register()
	GUISetOnEvent($GUI_EVENT_CLOSE, "SD_GUI_Close")
	GUIRegisterMsg($WM_GETMINMAXINFO, "WM_GETMINMAXINFO") ; Limit min size
	GUIRegisterMsg($WM_DROPFILES, "SD_GUI_Mod_AddByDnD") ; Input files
	GUIRegisterMsg($WM_NOTIFY, "WM_NOTIFY") ; DblClick in TreeView
	GUICtrlSetOnEvent($hButtonUp, "SD_GUI_Mod_Move_Up")
	GUICtrlSetOnEvent($hButtonDown, "SD_GUI_Mod_Move_Down")
	GUICtrlSetOnEvent($hButtonEnable, "SD_GUI_Mod_EnableDisableEvent")
	GUICtrlSetOnEvent($hButtonDisable, "SD_GUI_Mod_EnableDisableEvent")
	GUICtrlSetOnEvent($hButtonRemove, "SD_GUI_Mod_EnableDisableEvent")
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
	GUICtrlSetOnEvent($hDummyF5, "SD_GUI_Update")
	For $iCount = 1 To $aLanguages[0][0]
		GUICtrlSetOnEvent($aLanguages[$iCount][0], "SD_GUI_Language_Change")
	Next
EndFunc   ;==>SD_GUI_Events_Register

Func SD_GUI_SetLng()
	GUICtrlSetData($hGroupList, Lng_Get("group.modlist.title"))
	GUICtrlSetData($hButtonUp, Lng_Get("group.modlist.move_up"))
	GUICtrlSetData($hButtonDown, Lng_Get("group.modlist.move_down"))
	GUICtrlSetData($hButtonEnable, Lng_Get("group.modlist.enable"))
	GUICtrlSetData($hButtonDisable, Lng_Get("group.modlist.disable"))
	GUICtrlSetData($hButtonRemove, Lng_Get("group.modlist.remove"))
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
	GUICtrlSetData($hGroupScenario, Lng_Get("group.scenario.title"))
	GUICtrlSetData($hGroupModInfo, Lng_Get("group.modinfo.title"))
EndFunc   ;==>SD_GUI_SetLng

Func SD_GUI_Mod_Compatibility()
	MsgBox(4096, "", $sCompatibilityMessage, Default, $hFormMain)
EndFunc   ;==>SD_GUI_Mod_Compatibility

Func SD_GUI_MoreActionsPopup()
	_GUICtrlMenu_TrackPopupMenu(GUICtrlGetHandle($hMoreActionsContextMenuID), $hFormMain, -1, -1, 1, 1, 1)
EndFunc   ;==>SD_GUI_MoreActionsPopup

Func SD_GUI_Settings()
	GUISetState(@SW_DISABLE, $hFormMain)
	Local $iGUIOnEventModeState = AutoItSetOption("GUIOnEventMode", 0)
	Local $iResult = Settings_GUI($hFormMain)
	AutoItSetOption("GUIOnEventMode", $iGUIOnEventModeState)
	GUISetState(@SW_ENABLE, $hFormMain)
	GUISetState(@SW_RESTORE, $hFormMain)

	$bDisplayVersion = Settings_Get("DisplayVersion")

	If $iResult = 1 Then ; Names
		SD_GUI_Update()
	EndIf
EndFunc   ;==>SD_GUI_Settings

Func SD_GUI_Mod_CreateModifyReadme()
	Local $iTreeViewIndex = TreeViewGetSelectedIndex()
	Local $iModIndex1 = $auTreeView[$iTreeViewIndex][2]
	If $iModIndex1 < 1 Or $iModIndex1 > $MM_LIST_CONTENT[0][0] Then Return -1 ; never
	Local $sPath = $MM_LIST_DIR_PATH & "\" & $MM_LIST_CONTENT[$iModIndex1][0] & '\Readme.txt'
	Local $hFile = FileOpen($sPath, $FO_APPEND)
	FileClose($hFile)
	ShellExecute($sPath)
EndFunc   ;==>SD_GUI_Mod_CreateModifyReadme

Func SD_GUI_Mod_CreateModifyModInfo()
	Local $iTreeViewIndex = TreeViewGetSelectedIndex()
	Local $iModIndex1 = $auTreeView[$iTreeViewIndex][2]
	If $iModIndex1 < 1 Or $iModIndex1 > $MM_LIST_CONTENT[0][0] Then Return -1 ; never
	Local $sPath = $MM_LIST_DIR_PATH & "\" & $MM_LIST_CONTENT[$iModIndex1][0] & '\mod_info.ini'
	Local $bAddInfo = Not FileExists($sPath)
	Local $hFile = FileOpen($sPath, $FO_APPEND + $FO_CREATEPATH + $FO_UNICODE)
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

Func SD_GUI_Manage_Plugins()
	GUISetState(@SW_DISABLE, $hFormMain)
	Local $iGUIOnEventModeState = AutoItSetOption("GUIOnEventMode", 0)
	Plugins_Manage($MM_LIST_CONTENT[$auTreeView[TreeViewGetSelectedIndex()][2]][0], $hFormMain)
	AutoItSetOption("GUIOnEventMode", $iGUIOnEventModeState)
	GUISetState(@SW_ENABLE, $hFormMain)
	GUISetState(@SW_RESTORE, $hFormMain)
EndFunc   ;==>SD_GUI_Manage_Plugins

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
		MsgBox($MB_SYSTEMMODAL, "", StringFormat(Lng_Get("add_new.no_mods"), "0_O"), Default, $hFormMain)
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
	ProgressOn(Lng_Get("add_new.progress.title"), "", "", Default, Default, $DLG_MOVEABLE)
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
		MsgBox($MB_SYSTEMMODAL, "", StringFormat(Lng_Get("add_new.no_mods"), "0_O"), Default, $hFormMain)
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
	Local $iAnswer = MsgBox($MB_YESNO + $MB_ICONQUESTION + $MB_DEFBUTTON2 + $MB_TASKMODAL, "", StringFormat(Lng_Get("group.modlist.delete_confirm"), $MM_LIST_CONTENT[$iModIndex][0]), Default, $hFormMain)
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

Func Quit()
	Exit
EndFunc   ;==>Quit

Func SD_GUI_Mod_Controls_Disable()
	GUICtrlSetState($hButtonUp, $GUI_DISABLE)
	GUICtrlSetState($hButtonDown, $GUI_DISABLE)
	GUICtrlSetState($hButtonEnable, $GUI_DISABLE)
	GUICtrlSetState($hButtonDisable, $GUI_DISABLE)
	GUICtrlSetState($hButtonRemove, $GUI_DISABLE)
	GUICtrlSetState($hModDelete, $GUI_DISABLE)
	GUICtrlSetState($hButtonPlugins, $GUI_DISABLE)
	GUICtrlSetState($hModWebsite, $GUI_DISABLE)
	GUICtrlSetState($hModOpenFolder, $GUI_DISABLE)
	GUICtrlSetState($hModReadmeC, $GUI_DISABLE)
	GUICtrlSetState($hModInfoC, $GUI_DISABLE)
	GUICtrlSetData($hModInfo, Lng_Get("group.modinfo.no_info"))
;~ 	$sFollowMod = ""
EndFunc   ;==>SD_GUI_Mod_Controls_Disable

Func SD_GUI_Mod_SelectionChanged()
	Local $hSelected = GUICtrlRead($auTreeView[0][0])
;~ 	_ArrayDisplay($auTreeView)

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
				GUICtrlSetState($hButtonUp, $GUI_ENABLE)
			Else
				GUICtrlSetState($hButtonUp, $GUI_DISABLE)
			EndIf

			; MoveDown (2)
			If $iModIndex < $MM_LIST_CONTENT[0][0] And $iModIndex <> -1 And $auTreeView[$iCount + 1][2] <> -1 And _
					$MM_LIST_CONTENT[$auTreeView[$iCount][2]][1] = "Enabled" And $MM_LIST_CONTENT[$auTreeView[$iCount + 1][2]][1] = "Enabled" Then
				GUICtrlSetState($hButtonDown, $GUI_ENABLE)
			Else
				GUICtrlSetState($hButtonDown, $GUI_DISABLE)
			EndIf

			; Enable/Disable/Remove (1,2)

			If $MM_LIST_CONTENT[$auTreeView[$iCount][2]][1] = "Disabled" Then
				GUICtrlSetState($hButtonEnable, $GUI_ENABLE + $GUI_SHOW)
				GUICtrlSetState($hButtonDisable, $GUI_DISABLE + $GUI_HIDE)
				GUICtrlSetState($hButtonRemove, $GUI_DISABLE + $GUI_HIDE)
			ElseIf $MM_LIST_CONTENT[$auTreeView[$iCount][2]][2] Then ; Not exist
				GUICtrlSetState($hButtonEnable, $GUI_DISABLE + $GUI_HIDE)
				GUICtrlSetState($hButtonDisable, $GUI_DISABLE + $GUI_HIDE)
				GUICtrlSetState($hButtonRemove, $GUI_ENABLE + $GUI_SHOW)
			Else
				GUICtrlSetState($hButtonEnable, $GUI_DISABLE + $GUI_HIDE)
				GUICtrlSetState($hButtonDisable, $GUI_ENABLE + $GUI_SHOW)
				GUICtrlSetState($hButtonRemove, $GUI_DISABLE + $GUI_HIDE)
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

		$aTreeViewData[$iIndexToAdd][0] = GUICtrlCreateTreeViewItem(Mod_MakeDisplayName($MM_LIST_CONTENT[$iCount][3], $MM_LIST_CONTENT[$iCount][2], $MM_LIST_CONTENT[$iCount][8], $bDisplayVersion), $aTreeViewData[$aTreeViewData[$iIndexToAdd][1]][0])
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

	Local $iModIndex = 0
	For $iCount = 1 To $MM_LIST_CONTENT[0][0]
		If $MM_LIST_CONTENT[$iCount][0] = $sModName Then
			$iModIndex = $iCount
			ExitLoop
		EndIf
	Next

	If $iModIndex = 0 Then
		GUICtrlSetState($auTreeView[0][0], $GUI_FOCUS)
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
	$hWndTreeview = $hModList
	If Not IsHWnd($hModList) Then $hWndTreeview = GUICtrlGetHandle($hModList)
	If Not IsHWnd($hWndTreeview) Then Return $GUI_RUNDEFMSG

	$tNMHDR = DllStructCreate($tagNMHDR, $ilParam)
	$hWndFrom = HWnd(DllStructGetData($tNMHDR, "hWndFrom"))
	$iCode = DllStructGetData($tNMHDR, "Code")

	Switch $hWndFrom
		Case $hWndTreeview
			Switch $iCode
				Case $NM_DBLCLK
					$bEnableDisable = True
				Case $TVN_SELCHANGEDW
					$bSelectionChanged = True
			EndSwitch
	EndSwitch

	Return $GUI_RUNDEFMSG
EndFunc   ;==>WM_NOTIFY
