/*
o-----------------------------------------------------------------------------o
| Author : Lokesh Govindu                                                     |
|  Email : lokeshgovindu@gmail.com                                            |
(-----------------------------------------------------------------------------)
| This is my personal ahk script       / A Script file for AutoHotkey 1.0.22+ |
|                                     ----------------------------------------|
| Details:                                                                    |
| --------                                                                    |
|                                                                             |
o-----------------------------------------------------------------------------o
*/

#SingleInstance Force
SetTitleMatchMode RegEx

; Using #Include to Share Functions Among Multiple 
;~ #Include CommonUtils.ahk
;~ #Include RBMS.ahk

;------------------------------------------------------------------------------
; Volume Up
;------------------------------------------------------------------------------
!NumpadAdd::
	Send {Volume_Up 1}
	return


;------------------------------------------------------------------------------
; Volume Down
;------------------------------------------------------------------------------
!NumpadSub::
	Send {Volume_Down 1}
	return


;------------------------------------------------------------------------------
; Volume Mute
;------------------------------------------------------------------------------
!NumpadDiv::
	Send {Volume_Mute}
	return


;------------------------------------------------------------------------------
; Seek
;------------------------------------------------------------------------------
#Space::
	Run, "E:\Labs\AutoHotkey\Seek.ahk"
	return


;------------------------------------------------------------------------------
; Alt+Tab
;------------------------------------------------------------------------------
;~ `::
;~ !`::
	MsgBox %A_AhkPath%
	;~ Run, "E:\Labs\AutoHotkey\AltTabAlternative.ahk"
	;~ return


;------------------------------------------------------------------------------
; Skype
;------------------------------------------------------------------------------
#S::
	if (WinExist("ahk_exe Skype.exe")) {
		WinActivate
	} else {
		Run, "C:\Program Files (x86)\Skype\Phone\Skype.exe"
	}
	return 


;------------------------------------------------------------------------------
; Cisco Jabber
;------------------------------------------------------------------------------
#J::
	if (WinExist("ahk_exe CiscoJabber.exe")) {
		WinActivate
	} else {
		Run, "C:\Program Files (x86)\Cisco Systems\Cisco Jabber\CiscoJabber.exe" 
	}
	return


;------------------------------------------------------------------------------
; Date and Time related stuff
;------------------------------------------------------------------------------
::$d::
	FormatTime, dateStr, , yyyyMMdd
	SendInput %dateStr%
	return

::$-d::
	FormatTime, dateStr, , yyyy-MM-dd
	SendInput, %dateStr%
	return

::$t::
	FormatTime, timeStr, , HHmm
	SendInput, %timeStr%
	return

::$dt::
	FormatTime, dtStr, , yyyyMMddHHmm
	SendInput, %dtStr%
	return
	
::$-dt::
	FormatTime, dtStr, , yyyy-MM-dd_HHmm
	SendInput, %dtStr%
	return


;------------------------------------------------------------------------------
; TopCoder
; Window Title : TopCoder
;        Class : ahk_class SunAwtFrame
;      Process : ahk_exe jp2launcher.exe
;------------------------------------------------------------------------------
!Numpad7::
	EnvGet, un, TCUserName
	EnvGet, pw, TCPassword
	if (un = "" or pw = "") {
		MsgBox Either TCUserName = [%un%] or TCPassword = [%pw%] is Emptry.
		return
	}
	Run "E:\Lokesh\Softwares\TopCoder\ContestAppletProd.jnlp", , Max, TCPID
	WinWaitActive, ahk_class SunAwtFrame
	Sleep, 1000
	LoginToTopCoder(un, pw)
	return


; *****************************************************************************
; Some hot keys are not working. Please write your function after Hotkeys.
; *****************************************************************************


;------------------------------------------------------------------------------
; Login to TopCoder Arena
;------------------------------------------------------------------------------
LoginToTopCoder(un, pw)
{
	IfWinExist, ahk_class SunAwtFrame
	WinActivate
	BlockInput, On
	SendInput, %un%
	SendInput, {Tab}
	; Wait for 0.5 second, otherwise Tab won't move the cursor to password field
	Sleep, 500
	SendInput, %pw%
	Sleep, 500
	SendInput, {Enter}
	WinMaximize
	BlockInput, Off
	return
}
