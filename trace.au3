#AutoIt3Wrapper_Version=Beta

#include <String.au3>

Global $__T_POINT = TimerInit()
Global $_TRACE[1][2] ; Message, Timer

Func _TracePrint(Const $sToPrint)
	If IsDeclared("__DEBUG") Then ConsoleWrite(_StringRepeat(" ", $_TRACE[0][0]) & $sToPrint & @CRLF)
	If IsDeclared("__DEBUG_TO_FILE") Then FileWriteLine(@ScriptDir & "\debug0.log", _StringRepeat(" ", $_TRACE[0][0]) & $sToPrint)
EndFunc

Func _Trace(Const $sToPrint = StringFormat("Called from %i line", @ScriptLineNumber), Const $sEmoji = "!!")
	If Not IsDeclared("__DEBUG") And Not IsDeclared("__DEBUG_TO_FILE") Then Return

	Local $iEndTime = Int(TimerDiff($__T_POINT))
	$__T_POINT = TimerInit()
	_TracePrint(StringFormat("%s (%s)\t%s msec later (%s memory)", $sToPrint, $sEmoji, $iEndTime, ProcessGetStats()[0]/1024))
	Return $__T_POINT
EndFunc

Func _TraceStart(Const $sToPrint = StringFormat("Called from %i line", @ScriptLineNumber))
	If Not IsDeclared("__DEBUG") And Not IsDeclared("__DEBUG_TO_FILE") Then Return

	$_TRACE[0][0] += 1
	If UBound($_TRACE) <= $_TRACE[0][0] Then ReDim $_TRACE[$_TRACE[0][0] * 2][2]
	$_TRACE[$_TRACE[0][0]][0] = $sToPrint
	$_TRACE[$_TRACE[0][0]][1] = _Trace($sToPrint, "->")
EndFunc

Func _TraceEnd()
	If Not IsDeclared("__DEBUG") And Not IsDeclared("__DEBUG_TO_FILE") Then Return
	If $_TRACE[0][0] = 0 Then Return
	Local $iEndTime = Int(TimerDiff($_TRACE[$_TRACE[0][0]][1]))

	_Trace($_TRACE[$_TRACE[0][0]][0], "<-")
	_TracePrint(StringFormat("%s (%s)\t%s msec total (%s memory)", $_TRACE[$_TRACE[0][0]][0], "==", $iEndTime, ProcessGetStats()[0]/1024))
	$_TRACE[0][0] -= 1
EndFunc
