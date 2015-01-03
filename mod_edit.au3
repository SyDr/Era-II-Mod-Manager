; Author:         Aliaksei SyDr Karalenka

#AutoIt3Wrapper_Version=Beta
#include-once

#include "include_fwd.au3"

#include "mods.au3"
#include "lng.au3"
#include "settings.au3"
#include "utils.au3"

Func ModEdit_Editor(Const $iModIndex, Const $hParent)
	Local Const $iSelectedMod = Mod_GetSelectedMod()
	Mod_SetSelectedMod($iModIndex)

	Local Const $iOptionGUIOnEventMode = AutoItSetOption("GUIOnEventMode", 0)

	GUISetState(@SW_DISABLE, $hParent)

	Local Const $iItemSpacing = 4
	Local Const $iLabelHeight = 17
	Local Const $iInputHeight = 23
	Local Const $iButtonHeight = 25
	Local $hGUI = MapEmpty()
	$hGUI.Info = $MM_LIST_MAP[Mod_Get("id")]
	$hGUI.LngCode = Lng_Get("lang.code")
	Local $aSize, $vRes, $nMsg

	$hGUI.Form = GUICreate(Lng_Get("mod_edit.caption"), 420, 278 + 25 + 4, Default, Default, Default, Default, $hParent)
	If Not @Compiled Then GUISetIcon(@ScriptDir & "\icons\preferences-system.ico")
	$aSize = WinGetClientSize($hGUI.Form)

	$hGUI.GroupCaption = GUICtrlCreateGroup(Lng_Get("mod_edit.group_caption.caption"), $iItemSpacing, $iItemSpacing, $aSize[0] - 2 * $iItemSpacing, 7 * $iItemSpacing + 25 + $iButtonHeight + $iLabelHeight)
	$hGUI.LabelCaptionLanguage = GUICtrlCreateLabel(Lng_Get("mod_edit.group_caption.language"), 2 * $iItemSpacing, 5 * $iItemSpacing, Default, $iLabelHeight, $SS_CENTERIMAGE)
	$hGUI.ComboCaptionLanguage = GUICtrlCreateCombo("", GUICtrlGetPos($hGUI.LabelCaptionLanguage).NextX, 5 * $iItemSpacing, $aSize[0] - GUICtrlGetPos($hGUI.LabelCaptionLanguage).NextX - 5 * $iItemSpacing - 2 * $iButtonHeight, 25, BitOR($CBS_DROPDOWNLIST, $CBS_AUTOHSCROLL))
	GUICtrlSetData($hGUI.ComboCaptionLanguage, _ArrayToString($MM_LNG_LIST, Default, 1, Default, "|", 2, 2))
	GUICtrlSetData($hGUI.ComboCaptionLanguage, Lng_Get("lang.name"))

	$hGUI.ButtonCaptionHelp = GUICtrlCreateButton("?", $aSize[0] - 3 * $iItemSpacing - $iButtonHeight, GUICtrlGetPos($hGUI.ComboCaptionLanguage).Top - 2, $iButtonHeight, $iButtonHeight)

	$hGUI.LabelCaptionCaption = GUICtrlCreateLabel(Lng_Get("mod_edit.group_caption.caption_label"), 2 * $iItemSpacing, GUICtrlGetPos($hGUI.ComboCaptionLanguage).NextY + $iItemSpacing, Default, $iLabelHeight, $SS_CENTERIMAGE)
	$hGUI.InputCaptionCaption = GUICtrlCreateInput($hGUI.Info["caption"][$hGUI.LngCode], GUICtrlGetPos($hGUI.LabelCaptionCaption).NextX, GUICtrlGetPos($hGUI.LabelCaptionCaption).Top, $aSize[0] - GUICtrlGetPos($hGUI.LabelCaptionCaption).NextX - 3 * $iItemSpacing, $iInputHeight)

 	$hGUI.LabelCaptionFile = GUICtrlCreateLabel(Lng_Get("mod_edit.group_caption.description_file"), 2 * $iItemSpacing, GUICtrlGetPos($hGUI.InputCaptionCaption).NextY + $iItemSpacing, Default, $iLabelHeight, $SS_CENTERIMAGE)
 	$hGUI.InputCaptionFile = GUICtrlCreateInput($hGUI.Info["description"]["full"][$hGUI.LngCode], GUICtrlGetPos($hGUI.LabelCaptionFile).NextX, GUICtrlGetPos($hGUI.LabelCaptionFile).Top, $aSize[0] - GUICtrlGetPos($hGUI.LabelCaptionFile).NextX - 5 * $iItemSpacing - 2 * $iButtonHeight, $iInputHeight, $ES_READONLY)
 	$hGUI.ButtonCaptionFile = GUICtrlCreateButton("...",GUICtrlGetPos($hGUI.InputCaptionFile).NextX + $iItemSpacing, GUICtrlGetPos($hGUI.InputCaptionFile).Top - 1, $iButtonHeight, $iButtonHeight)
 	$hGUI.ButtonCaptionFileRemove = GUICtrlCreateButton("X", GUICtrlGetPos($hGUI.ButtonCaptionFile).NextX + $iItemSpacing, GUICtrlGetPos($hGUI.InputCaptionFile).Top - 1, $iButtonHeight, $iButtonHeight)

	$hGUI.GroupOther = GUICtrlCreateGroup(Lng_Get("mod_edit.group_other.caption"), $iItemSpacing, GUICtrlGetPos($hGUI.GroupCaption).NextY, $aSize[0] - 2 * $iItemSpacing, 8 * $iItemSpacing + 3 * $iButtonHeight + $iInputHeight)
	$hGUI.LabelModVersion = GUICtrlCreateLabel(Lng_Get("mod_edit.group_other.mod_version"), 2 * $iItemSpacing, GUICtrlGetPos($hGUI.GroupOther).Top + 4 * $iItemSpacing, Default, $iLabelHeight, $SS_CENTERIMAGE)
	$hGUI.InputModVersion = GUICtrlCreateInput($hGUI.Info["mod_version"], GUICtrlGetPos($hGUI.LabelModVersion).NextX, GUICtrlGetPos($hGUI.LabelModVersion).Top, ($aSize[0] / 2) - GUICtrlGetPos($hGUI.LabelModVersion).NextX - $iButtonHeight - 2 * $iItemSpacing, $iInputHeight)
	$hGUI.ButtonModVersion = GUICtrlCreateButton("+", GUICtrlGetPos($hGUI.InputModVersion).NextX + $iItemSpacing, GUICtrlGetPos($hGUI.InputModVersion).Top - 1, $iButtonHeight, $iButtonHeight)
	$hGUI.LabelAuthor = GUICtrlCreateLabel(Lng_Get("mod_edit.group_other.author"), GUICtrlGetPos($hGUI.ButtonModVersion).NextX + 2 * $iItemSpacing, GUICtrlGetPos($hGUI.LabelModVersion).Top, Default, $iLabelHeight, $SS_CENTERIMAGE)
	$hGUI.InputAuthor = GUICtrlCreateInput($hGUI.Info["author"], GUICtrlGetPos($hGUI.LabelAuthor).NextX, GUICtrlGetPos($hGUI.LabelAuthor).Top, $aSize[0] - GUICtrlGetPos($hGUI.LabelAuthor).NextX - 3 * $iItemSpacing, $iInputHeight)

	$hGUI.LabelPriority = GUICtrlCreateLabel(Lng_Get("mod_edit.group_other.priority"), 2 * $iItemSpacing, GUICtrlGetPos($hGUI.ButtonModVersion).NextY + $iItemSpacing, Default, $iLabelHeight, $SS_CENTERIMAGE)
	$hGUI.InputPriority = GUICtrlCreateInput($hGUI.Info["priority"], GUICtrlGetPos($hGUI.LabelPriority).NextX, GUICtrlGetPos($hGUI.LabelPriority).Top, ($aSize[0] / 2) - GUICtrlGetPos($hGUI.LabelPriority).NextX - $iItemSpacing, $iInputHeight, $ES_READONLY)
	$hGUI.UpDownPriority = GUICtrlCreateUpdown($hGUI.InputPriority)
	GUICtrlSetLimit($hGUI.UpDownPriority, 100, -100)

 	$hGUI.IconSelected = $hGUI.Info["icon"]["file"] <> ""
	$hGUI.LabelIcon = GUICtrlCreateLabel(Lng_Get("mod_edit.group_other.icon"), GUICtrlGetPos($hGUI.UpDownPriority).NextX + 2 * $iItemSpacing, GUICtrlGetPos($hGUI.UpDownPriority).Top, Default, $iLabelHeight, $SS_CENTERIMAGE)
	$hGUI.IconIcon = GUICtrlCreateIcon($MM_LIST_DIR_PATH & "\" & $MM_LIST_CONTENT[$iModIndex][0] & "\" & $hGUI.Info["icon"]["file"], -($hGUI.Info["icon"]["index"] + 1), GUICtrlGetPos($hGUI.LabelIcon).NextX, GUICtrlGetPos($hGUI.LabelIcon).Top, 16, 16)
	If $hGUI.IconIcon = 0 Then
		$hGUI.IconSelected = False
		$hGUI.IconIcon = GUICtrlCreateIcon(@ScriptDir & "\icons\folder-grey.ico", 0, GUICtrlGetPos($hGUI.LabelIcon).NextX, GUICtrlGetPos($hGUI.LabelIcon).Top, 16, 16)
	EndIf

	GUICtrlSetCursor($hGUI.IconIcon, 0)
	$hGUI.ButtonIcon = GUICtrlCreateButton("X", GUICtrlGetPos($hGUI.IconIcon).NextX + $iItemSpacing, GUICtrlGetPos($hGUI.InputPriority).Top - 1, $iButtonHeight, $iButtonHeight)

	$hGUI.LabelHomepage = GUICtrlCreateLabel(Lng_Get("mod_edit.group_other.homepage"), 2 * $iItemSpacing, GUICtrlGetPos($hGUI.ButtonIcon).NextY + $iItemSpacing, Default, $iLabelHeight, $SS_CENTERIMAGE)
	$hGUI.InputHomepage = GUICtrlCreateInput($hGUI.Info["homepage"], GUICtrlGetPos($hGUI.LabelHomepage).NextX, GUICtrlGetPos($hGUI.LabelHomepage).Top, $aSize[0] - GUICtrlGetPos($hGUI.LabelHomepage).NextX - 3 * $iItemSpacing, $iInputHeight)

	$hGUI.LabelCategory = GUICtrlCreateLabel(Lng_Get("mod_edit.group_other.category"), 2 * $iItemSpacing, GUICtrlGetPos($hGUI.InputHomepage).NextY + $iItemSpacing, Default, $iLabelHeight, $SS_CENTERIMAGE)
	$hGUI.ComboCategory = GUICtrlCreateCombo("", GUICtrlGetPos($hGUI.LabelCategory).NextX, GUICtrlGetPos($hGUI.LabelCategory).Top, $aSize[0] - GUICtrlGetPos($hGUI.LabelCategory).NextX - 3 * $iItemSpacing, 25, BitOR($CBS_DROPDOWN, $CBS_AUTOHSCROLL))
	GUICtrlSetData($hGUI.ComboCategory, __ModEdit_PrepareCategoryList($hGUI.Info["category"]))
	If Lng_Get("category." & $hGUI.Info["category"]) <> "" Then GUICtrlSetData($hGUI.ComboCategory, Lng_Get("category." & $hGUI.Info["category"]))

	$hGUI.GroupCompatibility = GUICtrlCreateGroup(Lng_Get("mod_edit.group_compatibility.caption"), $iItemSpacing, GUICtrlGetPos($hGUI.GroupOther).NextY, $aSize[0] - 2 * $iItemSpacing, 5 * $iItemSpacing + 25)
	$hGUI.LabelCompatibilityClass = GUICtrlCreateLabel(Lng_Get("mod_edit.group_compatibility.class"), 2 * $iItemSpacing, GUICtrlGetPos($hGUI.GroupCompatibility).Top + 4 * $iItemSpacing, Default, $iLabelHeight, $SS_CENTERIMAGE)
	$hGUI.ComboCompatibilityClass = GUICtrlCreateCombo("", GUICtrlGetPos($hGUI.LabelCompatibilityClass).NextX, GUICtrlGetPos($hGUI.LabelCompatibilityClass).Top, _
		$aSize[0] - GUICtrlGetPos($hGUI.LabelCompatibilityClass).NextX - 3 * $iItemSpacing, 25, BitOR($CBS_DROPDOWNLIST, $CBS_AUTOHSCROLL))
	GUICtrlSetData($hGUI.ComboCompatibilityClass, __ModEdit_FormatCompatibilityClass("default") & "|" & __ModEdit_FormatCompatibilityClass("all") & "|" & __ModEdit_FormatCompatibilityClass("none"))
	GUICtrlSetData($hGUI.ComboCompatibilityClass, __ModEdit_FormatCompatibilityClass($hGUI.Info["compatibility"]["class"]))

	$hGUI.ButtonSave = GUICtrlCreateButton(Lng_Get("mod_edit.save"), $aSize[0] - $iItemSpacing - 90, GUICtrlGetPos($hGUI.GroupCompatibility).NextY + $iItemSpacing, 90, $iButtonHeight)
	$hGUI.ButtonCancel = GUICtrlCreateButton(Lng_Get("mod_edit.cancel"), GUICtrlGetPos($hGUI.ButtonSave).Left - 90 - $iItemSpacing, GUICtrlGetPos($hGUI.ButtonSave).Top, 90, $iButtonHeight)

	__ModEdit_SetControlAccessibility($hGUI)
	GUISetState(@SW_SHOW)

	Local $bOk = False, $bIsCancel = False

	While Not $bOk And Not $bIsCancel
		$nMsg = GUIGetMsg()
		Switch $nMsg
			Case $GUI_EVENT_CLOSE, $hGUI.ButtonCancel
				$bIsCancel = True
			Case $hGUI.ComboCaptionLanguage
				$hGUI["Info"]["caption"][$hGUI.LngCode] = GUICtrlRead($hGUI.InputCaptionCaption)
				$hGUI["Info"]["description"]["full"][$hGUI.LngCode] = GUICtrlRead($hGUI.InputCaptionFile)

				$hGUI.LngCode = Lng_GetCodeByName(GUICtrlRead($hGUI.ComboCaptionLanguage))

				GUICtrlSetData($hGUI.InputCaptionCaption, $hGUI.Info["caption"][$hGUI.LngCode])
				GUICtrlSetData($hGUI.InputCaptionFile, $hGUI.Info["description"]["full"][$hGUI.LngCode])

				__ModEdit_SetControlAccessibility($hGUI)

			Case $hGUI.ButtonCaptionHelp
				MsgBox(0, "", Lng_Get("mod_edit.group_caption.hint"), Default, $hGUI.Form)
			Case $hGUI.ButtonCaptionFile
				$vRes = FileOpenDialog("", Mod_Get("dir\"), "(*.*)", $FD_PATHMUSTEXIST + $FD_FILEMUSTEXIST, GUICtrlRead($hGUI.InputCaptionFile), $hGUI.Form)
				If Not @error  And StringLeft($vRes, StringLen(Mod_Get("dir\"))) = Mod_Get("dir\")  Then
					GUICtrlSetData($hGUI.InputCaptionFile, StringTrimLeft($vRes, StringLen(Mod_Get("dir\"))))
					__ModEdit_SetControlAccessibility($hGUI)
				EndIf
			Case $hGUI.ButtonCaptionFileRemove
				GUICtrlSetData($hGUI.InputCaptionFile, "")
				__ModEdit_SetControlAccessibility($hGUI)
			Case $hGUI.ButtonModVersion
				GUICtrlSetData($hGUI.InputModVersion, VersionIncrement(GUICtrlRead($hGUI.InputModVersion)))
			Case $hGUI.IconIcon
				$vRes = DllCall("shell32.dll", "int", "PickIconDlg", "hwnd", 0, "wstr", Mod_Get("dir\") & $hGUI.Info["icon"]["file"], "int", 1000, "int*", $hGUI.Info["icon"]["index"])
				If Not @error And $vRes[0] And StringLeft($vRes[2], StringLen(Mod_Get("dir\"))) = Mod_Get("dir\") Then
					$hGUI["Info"]["icon"]["file"] = StringTrimLeft($vRes[2], StringLen(Mod_Get("dir\")))
					$hGUI["Info"]["icon"]["index"] = Int($vRes[4])
					__ModEdit_SetIcon($hGUI)
					__ModEdit_SetControlAccessibility($hGUI)
				EndIf
			Case $hGUI.ButtonIcon
				$hGUI["Info"]["icon"]["file"] = ""
				$hGUI["Info"]["icon"]["index"] = 0
				__ModEdit_SetIcon($hGUI)
				__ModEdit_SetControlAccessibility($hGUI)
			Case $hGUI.ButtonSave
				$bOk = True
		EndSwitch
	WEnd

	$hGUI["Info"]["caption"][$hGUI.LngCode] = GUICtrlRead($hGUI.InputCaptionCaption)
	$hGUI["Info"]["description"]["full"][$hGUI.LngCode] = GUICtrlRead($hGUI.InputCaptionFile)
	$hGUI["Info"]["mod_version"] = GUICtrlRead($hGUI.InputModVersion)
	$hGUI["Info"]["author"] = GUICtrlRead($hGUI.InputAuthor)
	$hGUI["Info"]["homepage"] = GUICtrlRead($hGUI.InputHomepage)
	$hGUI["Info"]["priority"] = Int(GUICtrlRead($hGUI.InputPriority))
	$hGUI["Info"]["compatibility"]["class"] = __ModEdit_FormattedCompatibilityClassToPlain(GUICtrlRead($hGUI.ComboCompatibilityClass))
	$hGUI["Info"]["category"] = __ModEdit_FormattedCategoryToPlain(GUICtrlRead($hGUI.ComboCategory))

	AutoItSetOption("GUIOnEventMode", $iOptionGUIOnEventMode)

	Mod_SetSelectedMod($iSelectedMod)
	If $bOk Then Mod_Save($iModIndex, $hGUI.Info)
	GUIDelete($hGUI.Form)

	GUISetState(@SW_ENABLE, $hParent)
	GUISetState(@SW_RESTORE, $hParent)

	Return $bOk
EndFunc

Func __ModEdit_PrepareCategoryList(Const $sForseThis)
	Local $aKeys = Lng_GetCategoryList()
	Local $sReturn, $bForsedIn = False

	For $i = 0 To UBound($aKeys) - 1
		$sReturn &= "|" & Lng_Get("category." & $aKeys[$i])
		If $aKeys[$i] = StringLower($sForseThis) Then $bForsedIn = True
	Next

	If Not $bForsedIn And $sForseThis <> "" Then $sReturn &= "|" & $sForseThis

	Return $sReturn
EndFunc

Func __ModEdit_FormattedCategoryToPlain(Const $sCategory)
	Local $aKeys = Lng_GetCategoryList()

	For $i = 0 To UBound($aKeys) - 1
		If Lng_Get("category." & $aKeys[$i]) = $sCategory Then Return $aKeys[$i]
	Next

	Return $sCategory
EndFunc

Func __ModEdit_FormatCompatibilityClass(Const $sClass)
	Return StringFormat("%s - %s", $sClass, Lng_Get(StringFormat("mod_edit.group_compatibility.%s", $sClass)))
EndFunc

Func __ModEdit_FormattedCompatibilityClassToPlain(Const $sPath)
	If __ModEdit_FormatCompatibilityClass("all") = $sPath Then Return "all"
	If __ModEdit_FormatCompatibilityClass("default") = $sPath Then Return "default"
	If __ModEdit_FormatCompatibilityClass("none") = $sPath Then Return "none"
EndFunc

Func __ModEdit_SetControlAccessibility(ByRef $hGUI)
	GUICtrlSetState($hGUI.ButtonCaptionFileRemove, GUICtrlRead($hGUI.InputCaptionFile) <> "" ? $GUI_ENABLE : $GUI_DISABLE)
	GUICtrlSetState($hGUI.ButtonIcon, $hGUI.IconSelected ? $GUI_ENABLE : $GUI_DISABLE)
EndFunc

Func __ModEdit_SetIcon(ByRef $hGUI)
 	$hGUI.IconSelected = $hGUI.Info["icon"]["file"] <> ""
	Local $bIsOk = GUICtrlSetImage($hGUI.IconIcon, Mod_Get("dir\") & $hGUI.Info["icon"]["file"], -($hGUI.Info["icon"]["index"] + 1))
	If Not $bIsOk Then
		$hGUI.IconSelected = False
		GUICtrlSetImage($hGUI.IconIcon, @ScriptDir & "\icons\folder-grey.ico", 0)
	EndIf
EndFunc
