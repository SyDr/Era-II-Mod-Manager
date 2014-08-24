;Author:			Aliaksei SyDr Karalenka

#include <Array.au3>
#include <File.au3>
#include <GUIConstantsEx.au3>

#include "settings.au3"

#include-once

Func Plugins_ModHavePlugins($sModName)
	Local $aGlobal, $aBeforeWog, $aAfterWog
	Return Plugins_LoadList($sModName, $aGlobal, $aBeforeWog, $aAfterWog)
EndFunc

Func Plugins_LoadList($sModName, ByRef $aGlobal, ByRef $aBeforeWog, ByRef $aAfterWog)
	Local $Path = Settings_Global("Get", "Path") & "\" & $sModName
	If $sModName="" Or Not FileExists($Path) Then
		Return False
	EndIf

	$aGlobal = _FileListToArray($Path & "\EraPlugins\", "*", 1)
	$aBeforeWog = _FileListToArray($Path & "\EraPlugins\BeforeWoG\", "*", 1)
	$aAfterWog = _FileListToArray($Path & "\EraPlugins\AfterWoG\", "*", 1)
	If IsArray($aGlobal) Then
		For $iCount = $aGlobal[0] To 1 Step -1
			If FileGetSize($Path & "\EraPlugins\" & $aGlobal[$iCount])=0 Then
				_ArrayDelete($aGlobal, $iCount)
				$aGlobal[0] -= 1
			EndIf
		Next
	EndIf

	If IsArray($aBeforeWog) Then
		For $iCount = $aBeforeWog[0] To 1 Step -1
			If FileGetSize($Path & "\EraPlugins\BeforeWoG\" & $aBeforeWog[$iCount])=0 Then
				_ArrayDelete($aBeforeWog, $iCount)
				$aBeforeWog[0] -= 1
			EndIf
		Next
	EndIf

	If IsArray($aAfterWog) Then
		For $iCount = $aAfterWog[0] To 1 Step -1
			If FileGetSize($Path & "\EraPlugins\AfterWoG\" & $aAfterWog[$iCount])=0 Then
				_ArrayDelete($aAfterWog, $iCount)
				$aAfterWog[0] -= 1
			EndIf
		Next
	EndIf

	Local $iTotalPlugins = 0, $iTotalSections = 0
	If IsArray($aGlobal) Then
		$iTotalPlugins += $aGlobal[0]
		$iTotalSections += 1
	EndIf
	If IsArray($aBeforeWog) Then
		$iTotalPlugins += $aBeforeWog[0]
		$iTotalSections += 1
	EndIf
	If IsArray($aAfterWog) Then
		$iTotalPlugins += $aAfterWog[0]
		$iTotalSections += 1
	EndIf

	Return SetError(0, $iTotalSections, $iTotalPlugins)
EndFunc

Func Plugins_Manage($sModName, $hFormParent)
	Local $Path = Settings_Global("Get", "Path") & "\" & $sModName
	If $sModName="" Or Not FileExists($Path) Then
		Return False
	EndIf

	Local $aGlobal, $aBeforeWog, $aAfterWog
	Local $iTotalPlugins = Plugins_LoadList($sModName, $aGlobal, $aBeforeWog, $aAfterWog)
	Local $iTotalSections = @extended
	Local $hCheckboxes[1], $hNames[1], $hPathes[1]
	Local $iBaseOffset = 8
	Local $hGUI, $msg
	Local $k = 0

	If $iTotalPlugins>0 Then
		ReDim $hCheckboxes[$iTotalPlugins]
		ReDim $hNames[$iTotalPlugins]
		ReDim $hPathes[$iTotalPlugins]
	EndIf

	$hGUI = GUICreate(Lng_Get("plugins.title"), 252, $iBaseOffset + $iTotalPlugins*17+13+$iTotalSections*17, Default, Default, Default, Default, $hFormParent)
	GUISetState(@SW_SHOW)

	If IsArray($aGlobal) Then
		GUICtrlCreateGroup("Global", 1, $iBaseOffset + 1, 250, 17*($aGlobal[0]+1))
		For $i=1 To $aGlobal[0]
			$hCheckboxes[$k] = GUICtrlCreateCheckbox($aGlobal[$i], 8, $iBaseOffset + 16 + 17*($i-1), 200, 17)
			$hNames[$k] = $aGlobal[$i]
			$hPathes[$k] = $Path & "\EraPlugins\" & $aGlobal[$i]
			$k += 1
			If StringRight($aGlobal[$i], 3) <> "off" Then GuiCtrlSetState(-1, $GUI_CHECKED)
		Next
		GUICtrlCreateGroup("Global", 1, $iBaseOffset + 1, 250, 17*($aGlobal[0]+1))
	EndIf

	If IsArray($aBeforeWog) Then
		Local $iGlobal=-1
		If IsArray($aGlobal) Then $iGlobal=$aGlobal[0]
		GUICtrlCreateGroup("BeforeWoG", 1, $iBaseOffset + 1 + 17*($iGlobal+1) + 1, 250, 17*($aBeforeWog[0]+1))
		For $i=1 To $aBeforeWog[0]
			$hCheckboxes[$k] = GUICtrlCreateCheckbox($aBeforeWog[$i], 8, $iBaseOffset + 17*($iGlobal+1) + 1 + 16 + 17*($i-1), 200, 17)
			$hNames[$k] = $aBeforeWog[$i]
			$hPathes[$k] = $Path & "\EraPlugins\BeforeWoG\" & $aBeforeWog[$i]
			$k += 1
			If StringRight($aBeforeWog[$i], 3) <> "off" Then GuiCtrlSetState(-1, $GUI_CHECKED)
		Next
		GUICtrlCreateGroup("BeforeWoG", 1, $iBaseOffset + 1 + 17*($iGlobal+1) + 1, 250, 17*($aBeforeWog[0]+1))
	EndIf

	If IsArray($aAfterWog) Then
		Local $iGlobal=-1
		Local $iBeforeWog=-1
		If IsArray($aBeforeWog) Then $iBeforeWog=$aBeforeWog[0]
		If IsArray($aGlobal) Then $iGlobal=$aGlobal[0]
		GUICtrlCreateGroup("AfterWoG", 1, $iBaseOffset + 1 + 17*($iGlobal+1) + 1 + 17*($iBeforeWog+1) + 1, 250, 17*($aAfterWog[0]+1))
		For $i=1 To $aAfterWog[0]
			$hCheckboxes[$k] = GUICtrlCreateCheckbox($aAfterWog[$i], 8, $iBaseOffset + 17*($iBeforeWog+1) + 1 + 17*($iGlobal+1) + 1 + 16 + 17*($i-1), 200, 17)
			$hNames[$k] = $aAfterWog[$i]
			$hPathes[$k] = $Path & "\EraPlugins\AfterWoG\" & $aAfterWog[$i]
			$k += 1
			If StringRight($aAfterWog[$i], 3) <> "off" Then GuiCtrlSetState(-1, $GUI_CHECKED)
		Next
		GUICtrlCreateGroup("AfterWoG", 1, $iBaseOffset + 1 + 17*($iGlobal+1) + 1 + 17*($iBeforeWog+1) + 1, 250, 17*($aAfterWog[0]+1))
	EndIf

	While 1
		Sleep(10)
		$msg = GUIGetMsg()
		If $msg = 0 Then ContinueLoop
		If $msg = $GUI_EVENT_CLOSE Then ExitLoop
		If IsArray($aGlobal) Or IsArray($aBeforeWog) Or IsArray($aAfterWog) Then
			For $i = 0 To UBound($hCheckboxes)-1
				If $msg = $hCheckboxes[$i] Then
					If BitAND(GUICtrlRead($hCheckboxes[$i]), $GUI_CHECKED) Then
						FileMove($hPathes[$i], StringTrimRight($hPathes[$i], 4))
						$hPathes[$i] = StringTrimRight($hPathes[$i], 4)
						$hNames[$i] = StringTrimRight($hNames[$i], 4)
						GUICtrlSetData($hCheckboxes[$i], $hNames[$i])
					Else
						FileMove($hPathes[$i], $hPathes[$i] & ".off")
						$hPathes[$i] = $hPathes[$i] & ".off"
						$hNames[$i] = $hNames[$i] & ".off"
						GUICtrlSetData($hCheckboxes[$i], $hNames[$i])
					EndIf
					ExitLoop
			EndIf
		Next
			EndIf
	WEnd
	GUIDelete($hGUI)
EndFunc