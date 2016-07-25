/*
o-----------------------------------------------------------------------------o
| Author : Lokesh Govindu                                                     |
|  Email : lokeshgovindu@gmail.com                                            |
| Inspired from https://github.com/ralesi/alttab.ahk                          |
(-----------------------------------------------------------------------------)
| Alt+Tab Alternative                  / A Script file for AutoHotkey 1.1.23+ |
|                                     ----------------------------------------|
|                                                                             |
| Details:                                                                    |
| --------                                                                    |
| Use Alt+Tab / Alt+Shift+Tab to bring the main AltTab window, use            |
|        Tab key to select next row                                           |
|  Shift+Tab key to select previous row                                       |
|                                                                             |
|-----------------------------------------------------------------------------|
| Keys                 | Description                                          |
|----------------------+------------------------------------------------------|
| Alt+Tab              | Brings the AltTab main window                        |
| Alt+Shift+Tab        | Brings the AltTab main window                        |
|----------------------+------------------------------------------------------|
| Home/PageUp          | Move selection to first row                          |
| End/PageDown         | Move selection to last row                           |
| Up                   | Move selection to previous row                       |
| Down                 | Move selection to next row                           |
|----------------------+------------------------------------------------------|
| Del                  | Terminate currently selected process                 |
| Shift+Del            | Forcefully terminate currently selected process      |
|----------------------+------------------------------------------------------|
| AlphaNumeric         | Filter windows while typing, can delete last typed   |
|                      | char using backspace.                                |
|                      | Search string is displayed on static control.        |
|-----------------------------------------------------------------------------|
|                                                                             |
| Credits:                                                                    |
| --------                                                                    |
| * Icon Designed by                                                          |
|   http://www.freepik.com/ and distributed by www.flaticon.com               |
|                                                                             |
| Known issues:                                                               |
| -------------                                                               |
| * Process is terminated on pressing Del key instead of default action on    |
|   that window. Ex: Skype, Cicso Jabber.                                     |
| * SearchString is "empty" initially, when you press Alt+Tab & Alt+Shift+Tab |
|   search string becomes "". (here quotes for clarity)                       |
|                                                                             |
| TODO Tasks:                                                                 |
| -----------                                                                 |
| * Never kill a process that is having explorer.exe as a child               |
| * Alt+Esc to be handled                                                     |
| * Ctrl+Num to activate the window(num) directly and close Alt+Tab window    |
|                                                                             |
o-----------------------------------------------------------------------------o
*/

#Include CommonUtils.ahk

#SingleInstance Force
#InstallKeybdHook

;========================================================================================================
; Windows Messages

WM_KEYDOWN := 0x100
WM_KEYUP   := 0x101

;========================================================================================================
; USER EDITABLE SETTINGS:

AppTitle := "Lokesh Govindu's Alt+Tab Alternative"
CurSearchString     := ""
NewSearchString     := ""
DisplayListShown    := 0
CtrlBtnDown         := false
NumberBtnDown       := false
NumberBtnValue      := -1
Window_Found_Count  := 0
SelectedRowNumber   := 1
SelectedWinNumber   := 0
LVE_VkCodePrev       =

; Icons
UseLargeIcons       := 1     ; 0 = small icons, 1 = large icons in listview
ListviewResizeIcons := 0     ; Resize icons to fit listview area

; Fonts
FontSize            := 11
FontColor           := 0xe9ded3
FontColorEdit       := 0xff0000
FontColorListView   := 0xffffff
FontStyle           := "norm"
FontSizeTab         := 8
FontTypeTab         := "Consolas"
FontType            := "Lucida Handwriting"

; Position
GuiX = Center
GuiY = Center

; Max height
HeightMaxModifier := 0.65 ; multiplier for screen height (e.g. 0.92 = 92% of screen height max )

; Width
ListViewWidth  := A_ScreenWidth * 0.5
ListViewWidth  := (ListViewWidth <= 864 ? 864 : ListViewWidth)
SBWidth        := ListViewWidth / 4 ; StatusBar section sizes
ExeWidthMax    := ListViewWidth / 5 ; Exe column max width

; Tray Icon file name
TrayIcon := "Icon.ico"

;========================================================================================================

; USER OVERRIDABLE SETTINGS:

; ListView Column Widths
Col_1 = Auto    ; Icon Column
Col_2 = 0       ; Row Number
; col 3 is autosized based on other column sizes
Col_4 = Auto    ; Process Name

ColumnTitleList = #| |Window Title|Process Name
StringSplit, ColumnTitle, ColumnTitleList,| ; Create list of listview header titles

; Max height
HeightMax := A_ScreenHeight * HeightMaxModifier ; limit height of listview
Small_to_Large_Ratio = 1.6 ; height of small rows compared to large rows

; Colours in RGB hex
TabColour      := 1c1b1a
ListviewColour := 1c1b1a ; does not need converting as only used for background

;========================================================================================================

If A_PtrSize = 8
    GetClassLong_API := "GetClassLongPtr"
else
    GetClassLong_API := "GetClassLong"

WS_EX_APPWINDOW = 0x40000   ; Provides a taskbar button
WS_EX_TOOLWINDOW = 0x80     ; Removes the window from the alt-tab list
GW_OWNER = 4

SysGet, ScrollbarVerticalThickness, 2 ; 2 is SM_CXVSCROLL, Width of a vertical scroll bar
If A_OSVersion = WIN_2000
    lv_h_win_2000_adj = 2 ; adjust height of main listview by +2 pixels to avoid scrollbar in windows 2000
Else
    lv_h_win_2000_adj = 0

UseLargeIconsCurrent = %UseLargeIcons% ; for remembering original user setting but changing on the fly

;========================================================================================================

; Alt+Tab Hotkey version
Gosub, InitiateHotkeys
Return


;========================================================================================================

InitiateHotkeys:
    PrintSub("InitiateHotkeys")
    AltHotKey       = !
    AltHotKey2      = Alt
    TabHotKey       = Tab
    ShiftTabHotkey  = +Tab
    EscHotKey       = Esc
    PrintKV4("AltHotkey", AltHotkey, "TabHotkey", TabHotkey, "ShiftTabHotkey", ShiftTabHotkey, "EscHotKey", EscHotKey)
    
    ; Turn on Alt+Tab & Alt+Shift+Tab hotkey here to be able to turn it off for
    ;   simple switching of apps in script
    ;~ Hotkey, %AltHotkey%%EscHotKey%, AltEsc, Off
    Hotkey, %AltHotkey%%TabHotkey%, AltTabAlternative, On
    Hotkey, %AltHotkey%%ShiftTabHotkey%, AltShiftTabAlternative, On
Return

;========================================================================================================

AltEsc:
    PrintSub("AltEsc")
    AltEscPressed = 1
    Gosub, ListViewDestroy
Return

;========================================================================================================

AltTabAlternative:
    PrintSub("AltTabAlternative")
    AltTabCommonFunction(1)
Return
    
;========================================================================================================

AltShiftTabAlternative:
    PrintSub("AltShiftTabAlternative")
    AltTabCommonFunction(-1)
Return

;========================================================================================================

AltTabCommonFunction(direction)
{
    Global DisplayListShown
    Global Window_Found_Count
    PrintSub("AltTabCommonFunction")
    PrintKV("direction", direction)
    PrintKV("DisplayListShown", DisplayListShown)
    if (DisplayListShown = 0) {
        Print("--- Test ---")
        Gosub, InitializeDefaults
        Gosub, CreateWindow
        Gosub, DisplayList
        Gosub, GuiResizeAndPosition
        Gosub, ShowWindow
    }

    ; Check for Alt Up 
    SetTimer, CheckAltHotkeyUp, 40    
    
    SelectedRowNumber := LV_GetNext(0, "F")
    SelectedRowNumber += direction
    if (SelectedRowNumber > Window_Found_Count) {
        SelectedRowNumber = 1
    }
    if (SelectedRowNumber < 1) {
        SelectedRowNumber := Window_Found_Count
    }
    PrintKV("SelectedRowNumber", SelectedRowNumber)
    LV_Modify(SelectedRowNumber, "Select Vis Focus") ; Get selected row and ensure selection & focus is visible
    Return
}

;========================================================================================================

CheckAltHotkeyUp:
    ;~ PrintSub("CheckAltHotkeyUp")
    ;~ PrintKV("AltHotKey2", AltHotKey2)
    IsAltKeyReleased := GetKeyState(AltHotKey2, "P")
    ;~ PrintKV("IsAltKeyReleased", IsAltKeyReleased)
    If !(GetKeyState(AltHotKey2, "P") or GetKeyState(AltHotKey2)) ; Alt key released
    {
        Print("Alt key released")
        Gosub, ListViewDestroy
    }
Return

;========================================================================================================
    
InitializeDefaults:
    Print("InitializeDefaults")
    NewSearchString     := ""
    CurSearchString     := ""
    SelectedRowNumber   := 1
    DisplayListShown    := 0
    CtrlBtnDown         := false
    NumberBtnDown       := false
    NumberBtnValue      := -1
Return

;========================================================================================================

CreateWindow:
    PrintSub("CreateWindow")
    Gui, 1: +AlwaysOnTop +ToolWindow -Caption +HwndMainWindowHwnd
    Gui, 1: Color, %TabColour% ; i.e. border/background 
    Gui, 1: Margin, 0, 0

    ;~ Gui, 1: Font, s%FontSize% c%FontColorEdit% %FontStyle%, %FontType%
    ;~ Gui, 1: Add, Edit, vEditSearchStringVar HwndEditSearchStringHwnd Center w%ListViewWidth% +ReadOnly
    ;~ Print("EditSearchStringHwnd = [ " . EditSearchStringHwnd . "]")

    Gui, 1: Font, s%FontSize% c%FontColorEdit% %FontStyle%, %FontType%
    Gui, 1: Add, Text, vTextCtrlVar hwndhTextCtrl Center w%ListViewWidth% +Border, Search String: empty

    Gui, 1: Font, s%FontSize% c%FontColorEdit% %FontStyle%, %FontType%
    Gui, 1: Font, s%FontSize% c%FontColorListView% %FontStyle%, %FontType%
    Gui, 1: Add, ListView, w%ListViewWidth% h200 AltSubmit +Redraw -Multi NoSort +LV0x2 Background%ListviewColour% Count10 gListViewEvent vListView1 HwndListView1Hwnd, %ColumnTitleList%
    Print("ListView1Hwnd = [" . ListView1Hwnd . "]")
    
    Gui, 1: Font, s%FontSize% c%FontColorEdit% %FontStyle%, %FontType%
    ;~ Gui, 1: Add, StatusBar, w%ListViewWidth% hwndhStatusBar vStatusBarVar +Border
    ;~ PrintKV("hStatusBar", hStatusBar)

    Gui, 1: +LastFound
    WinSet, Transparent, 222
Return

;========================================================================================================

ShowWindow:
    PrintSub("ShowWindow")
    Gui_vx := GuiCenterX()
    Gui, 1: Show, AutoSize x%Gui_vx% y%GuiY%, %AppTitle%
    DisplayListShown = 1
Return

;========================================================================================================

DisplayDimBackground:
    PrintSub("DisplayDimBackground")
    ; define background GUI to dim all active applications
    SysGet, Width, 78
    SysGet, Height, 79

    SysGet, X0, 76
    SysGet, Y0, 77

    ; Background GUI used to show foremost window
    Gui, 4: +LastFound -Caption +ToolWindow
    Gui, 4: Color, Black
    Gui, 4: Show, Hide
    WinSet, Transparent, 120
    Gui, 4: Show, x%X0% y%Y0% w%Width% h%Height%
    Gui4_ID := WinExist() ; for auto-sizing columns later
Return
    
;========================================================================================================

DisplayList:
    PrintSub("DisplayList")
    PrintKV("[DisplayList] SelectedRowNumber", SelectedRowNumber)
    
    GuiControl, -Redraw, ListView1
    LV_Delete()
    windowList =
    Window_Found_Count := 0
    
    DetectHiddenWindows, Off ; makes DllCall("IsWindowVisible") unnecessary
    
    ImageListID1 := IL_Create(10, 5, UseLargeIconsCurrent) ; Create an ImageList so that the ListView can display some icons
    LV_SetImageList(ImageListID1, 1)    ; Attach the ImageLists to the ListView so that it can later display the icons
    
    WinGet, windowList, List ; gather a list of running programs
    Loop, %windowList%
    {
        ownerID := windowID := windowList%A_Index%
        
        Loop {
            ownerID := DecimalToHex(DllCall("GetWindow", "UInt", ownerID, "UInt", GW_OWNER))
        } Until !DecimalToHex(DllCall("GetWindow", "UInt", ownerID, "UInt", GW_OWNER))
        
        ownerID := ownerID ? ownerID : windowID
        If (DecimalToHex(DllCall("GetLastActivePopup", "UInt", ownerID)) = windowID) {
            WinGet, es, ExStyle, ahk_id %windowID%
            WinGetTitle, windowTitle, ahk_id %windowID%
            ;~ FileAppend, windowTitle = [%windowTitle%]`n, *
            If (!((es & WS_EX_TOOLWINDOW) && !(es & WS_EX_APPWINDOW)) &&
                !IsInvisibleWin10BackgroundAppWindow(windowID))
            {
                ;~ FileAppend, windowTitle = [%windowTitle%]`n, *
                WinGetTitle, title, ahk_id %ownerID%
                WinGet, procPath, ProcessPath, ahk_id %windowID%
                WinGet, procName, ProcessName, ahk_id %windowID%
                
                ;~ FileAppend, A_Index = [%A_Index%] title = [%title%]`, processName = [%procName%]`n, *
                ;~ Print("CurSearchString = " . CurSearchString)
                If (InStr(title, CurSearchString, false) != 0 or InStr(procName, CurSearchString, false) != 0)
                {
                    Window_Found_Count += 1
                    GetWindowIcon(windowID, UseLargeIconsCurrent)          ; (window id, whether to get large icons)
                    WindowStoreAttributes(Window_Found_Count, windowID, "")  ; Index, wid, parent (or blank if none)
                    LV_Add("Icon" . Window_Found_Count, "", Window_Found_Count, title, procName)
                }
            }
        }
    }

	; HANDLE WM_KEYDOWN EVENT TO SELECT THE ITEMS OF LISTBOX USING UP / DOWN KEYS FROM
	; FILENAME EDIT CONTROL
	;~ OnMessage(WM_KEYDOWN, "OnKeyDown")
	;~ OnMessage(WM_KEYUP,   "OnKeyUp")

    GuiControl, +Redraw, ListView1
    ;~ PrintKV("[DisplayList] SelectedRowNumber", SelectedRowNumber)
    LV_Modify(SelectedRowNumber, "Select Vis Focus") ; Get selected row and ensure selection & focus is visible
    ;~ LV_Modify(1, "Select Vis Focus") ; Get selected row and ensure selection & focus is visible

    ; TURN ON INCREMENTAL SEARCH
    SetTimer, tIncrementalSearch, 500
Return

;========================================================================================================

ConstructWindowsList:
    PrintSub("ConstructWindowsList")
    windowList =
    Window_Found_Count := 0
    
    DetectHiddenWindows, Off ; makes DllCall("IsWindowVisible") unnecessary
    
    ImageListID1 := IL_Create(10, 5, UseLargeIconsCurrent) ; Create an ImageList so that the ListView can display some icons
    LV_SetImageList(ImageListID1, 1)    ; Attach the ImageLists to the ListView so that it can later display the icons
    
    WinGet, windowList, List ; gather a list of running programs
    Loop, %windowList%
    {
        ownerID := windowID := windowList%A_Index%
        
        Loop {
            ownerID := DecimalToHex(DllCall("GetWindow", "UInt", ownerID, "UInt", GW_OWNER))
        } Until !DecimalToHex(DllCall("GetWindow", "UInt", ownerID, "UInt", GW_OWNER))
        
        ownerID := ownerID ? ownerID : windowID
        If (DecimalToHex(DllCall("GetLastActivePopup", "UInt", ownerID)) = windowID) {
            WinGet, es, ExStyle, ahk_id %windowID%
            WinGetTitle, windowTitle, ahk_id %windowID%
            ;~ FileAppend, windowTitle = [%windowTitle%]`n, *
            If (!((es & WS_EX_TOOLWINDOW) && !(es & WS_EX_APPWINDOW)) &&
                !IsInvisibleWin10BackgroundAppWindow(windowID))
            {
                ;~ FileAppend, windowTitle = [%windowTitle%]`n, *
                WinGetTitle, title, ahk_id %ownerID%
                WinGet, procPath, ProcessPath, ahk_id %windowID%
                WinGet, procName, ProcessName, ahk_id %windowID%
                
                ;~ FileAppend, A_Index = [%A_Index%] title = [%title%]`, processName = [%procName%]`n, *
                ;~ Print("CurSearchString = " . CurSearchString)
                If (InStr(title, CurSearchString, false) != 0 or InStr(procName, CurSearchString, false) != 0)
                {
                    Window_Found_Count += 1
                    GetWindowIcon(windowID, UseLargeIconsCurrent)          ; (window id, whether to get large icons)
                    WindowStoreAttributes(Window_Found_Count, windowID, "")  ; Index, wid, parent (or blank if none)
                    ;~ LV_Add("Icon" . Window_Found_Count, "", Window_Found_Count, title, procName)
                }
            }
        }
    }
    PrintKV("Window_Found_Count", Window_Found_Count)
Return

;========================================================================================================

ListViewEvent:
    Critical, 50
    ;~ PrintSub("ListViewEvent")
    ;~ Print("A_GuiEvent = " . A_GuiEvent)
    if A_GuiEvent = DoubleClick     ; DoubleClick
    {
        LV_GetText(RowText, A_EventInfo)
        ;~ ToolTip You double-clicked row number %A_EventInfo%. Text: "%RowText%"        
        SelectedRowNumber := A_EventInfo
        Print("SelectedRowNumber = " . SelectedRowNumber)
        windowID := Window%SelectedRowNumber%
        Print("Activating windowID = " . windowID)`
        Print("Activating windowTitle = " . WindowTitle%SelectedRowNumber%)
        WinActivate, ahk_id %windowID%
        Gosub, ListViewDestroy
    }
    if A_GuiEvent = Normal          ; Mouse left-click
    {
        LV_GetText(RowText, A_EventInfo)
        ;~ ToolTip You double-clicked row number %A_EventInfo%. Text: "%RowText%"        
        SelectedRowNumber := A_EventInfo
        Print("SelectedRowNumber = " . SelectedRowNumber)
        ;~ windowID := Window%SelectedRowNumber%
        ;~ Print("Activating windowID = " . windowID)
        ;~ Print("Activating windowTitle = " . WindowTitle%SelectedRowNumber%)
        ;~ WinActivate, ahk_id %windowID%
        ;~ Gosub, ListView_Destroy
    }
    ;~ if A_GuiEvent = I               ; Item Changed
    ;~ {
        ;~ LV_GetText(RowText, A_EventInfo)
        ;~ ToolTip You double-clicked row number %A_EventInfo%. Text: "%RowText%"        
        ;~ SelectedRowNumber := A_EventInfo
        ;~ Print("[A_GuiEvent = I] SelectedRowNumber = " . SelectedRowNumber)
        ;~ windowID := Window%SelectedRowNumber%
        ;~ Print("Activating windowID = " . windowID)
        ;~ Print("Activating windowTitle = " . WindowTitle%SelectedRowNumber%)
        ;~ WinActivate, ahk_id %windowID%
        ;~ Gosub, ListView_Destroy
    ;~ }
    if A_GuiEvent = K
    {
        key := GetKeyName(Format("vk{:x}", A_EventInfo))
        PrintKV2("A_EventInfo", A_EventInfo, "key", key)
        
        PrintKV("LVE_VkCodePrev", LVE_VkCodePrev)
        vkCode := A_EventInfo
        ; NumpadDown - 40
        if (vkCode = GetKeyVK("NumpadDown")) {
            Gosub, AltTabAlternative
            Return
        }
        ; NumpadUp - 38
        else if (vkCode = GetKeyVK("NumpadUp")) {
            Gosub, AltShiftTabAlternative
            Return
        }
        ; NumpadHome - 36, NumpadPgUp - 33
        else if (vkCode = GetKeyVK("NumpadHome") or vkCode = GetKeyVK("NumpadPgUp")) {
            SelectedRowNumber = 1
            LV_Modify(SelectedRowNumber, "Select Vis Focus")
            Return
        }
        ; NumpadEnd - 35, NumpadPgDn - 34
        else if (vkCode = GetKeyVK("NumpadEnd") or vkCode = GetKeyVK("NumpadPgDn")) {
            SelectedRowNumber := Window_Found_Count
            LV_Modify(SelectedRowNumber, "Select Vis Focus")
            Return
        }
        else if (vkCode = GetKeyVK("NumpadDel")) {  ; NumpadDel - 46
            GetSelectedRowInfo()
            Print("[A_GuiEvent] SelectedRowNumber = " . SelectedRowNumber)
            windowID := Window%SelectedRowNumber%
            exeName := Exe_Name%SelectedRowNumber%
            Print("   windowID = " . windowID)
            Print("windowTitle = " . WindowTitle%SelectedRowNumber%)
            Print("    exeName = " . exeName)
            explorerName = "explorer.exe"
            
            ; Focus will be lost from Alt+Tab main window and it may ask to save data
            ; if we specify a waittime, so it is better to not to wait.
            ; *** Never kill explorer.exe forcefully
            if (exeName <> "explorer.exe" && LVE_VkCodePrev = GetKeyVK("Shift")) {
                Print("Shift+Del pressed")
                ;~ WinKill, ahk_id %windowID%
                procID := PID%SelectedRowNumber%
                PrintKV("Forcefully kill PID = ", procID)
                KillCmd := "TASKKILL /PID " . procID . " /T /F"
                PrintKV("KillCmd", KillCmd)
                RunWait, %KillCmd%, , Hide
            }
            else {
                Print("NumpadDel pressed")
                WinClose, ahk_id %windowID%
            }

            LV_Delete(SelectedRowNumber)

            if (SelectedRowNumber = Window_Found_Count) {
                SelectedRowNumber := Window_Found_Count - 1
            }

            ;~ Gosub, ConstructWindowsList
            ;~ PrintKV("After ConstructWindowsList Window_Found_Count", Window_Found_Count)
            ;~ PrintKV("Selecting SelectedRowNumber", SelectedRowNumber)
            ;~ LV_Modify(SelectedRowNumber, "Select Vis Focus")
            Gosub, DisplayList
            WinActivate, ahk_id %MainWindowHwnd%
            Return
        }
        
        ; Always getting lower case letters even the capslock is turned on
        ; Hence, no need to check for upper case letters.
        if ((vkCode >= 65 && vkCode <= 90) || (vkCode >= 48 && vkCode <= 57)) {
            ;~ Print("Key is alnum")
            NewSearchString := NewSearchString . key
            SelectedRowNumber := 1
        }        
        else if (vkCode = 8) { ; Backspace
            ;~ Print("Key is Backspace")
            NewSearchString := SubStr(NewSearchString, 1, StrLen(NewSearchString) - 1)
            SelectedRowNumber := 1
        }
        ;~ PrintKV("[ListViewEvent] NewSearchString", NewSearchString)
        ;~ SB_SetText("SearchString: " . NewSearchString)
        ControlSetText, Static1, Search String: %NewSearchString%
        
        LVE_VkCodePrev := vkCode
    }
Return

IsAlpha(x) {
   If x is Alpha
      Return 1
   Return 0
}

IsNum(x) {
   If x is Number
      Return 1
   Return 0
}

IsAlNum(x) {
   If x is alnum
      Return 1
   Return 0
}

IsSymbol(x) {
   List = 43,45,47,61
   x := Asc(x)
   If List contains %x%
      Return 1
   Return 0
}

;========================================================================================================

ListViewDestroy:
    PrintSub("ListViewDestroy")
    Gui, 1: Default
    Gosub, DisableTimers
    if (AltEscPressed != 1) {
        GetSelectedRowInfo()
        Print("SelectedRowNumber = " . SelectedRowNumber)
        windowID := Window%SelectedRowNumber%
        Print("Activating windowID = " . windowID)`
        Print("Activating windowTitle = " . WindowTitle%SelectedRowNumber%)
        Gui, 1: Destroy
        WinActivate, ahk_id %windowID%
    }
    else if (AltEscPressed = 0) {
        Gui, 1: Destroy
    }
    DisplayListShown := 0
Return
    
;========================================================================================================

GuiCenterX()
{
    Global ListViewWidth
    Coordmode, Mouse, Screen
    MouseGetPos, x, y
    SysGet, m, MonitorCount
    ; Iterate through all monitors.
    Loop, %m%
    {   ; Check if the window is on this monitor.
        SysGet, Mon, Monitor, %A_Index%
        if (x >= MonLeft && x <= MonRight && y >= MonTop && y <= MonBottom)
        {
            return (0.5 * (MonRight - MonLeft) + MonLeft - ListViewWidth / 2)
        }
    }
}


;=== BEGIN Window__Store_attributes EVENT ========================

; index = Window_Found_Count, windowID = window id, ID_Parent = parent or blank if none
WindowStoreAttributes(index, windowsID, ID_Parent) 
{
    Local State_temp
    ;~ PrintSub("WindowStoreAttributes")
    WinGetTitle, windowTitle, ahk_id %ownerID%
    WinGet, procPath, ProcessPath, ahk_id %windowID%
    WinGet, procName, ProcessName, ahk_id %windowID%
    WinGet, procID, PID, ahk_id %windowID%
    
    Window%index%        := windowID        ; Store ahk_id's to a list
    WindowParent%index%  := ID_Parent       ; Store Parent ahk_id's to a list to later see if window is owned
    WindowTitle%index%   := windowTitle     ; Store titles to a list
    hw_popup%index%      := hw_popup        ; Store the active popup window to a list (eg the find window in notepad)
    Exe_Name%index%      := procName        ; Store the process name
    Exe_Path%index%      := procPath        ; Store the process path
    PID%index%           := procID          ; Store the process id
    Dialog%index%        := Dialog          ; S if found a Dialog window, else 0
}

;... END WindowStoreAttributes EVENT ..........................


;=== BEGIN ListView_Resize_Vertically EVENT ========================

GetSelectedRowInfo()
{
    Global
    PrintSub("GetSelectedRowInfo")
    
    SelectedRowNumber := LV_GetNext(0, "F")
    PrintKV("[GetSelectedRowInfo] SelectedRowNumber", SelectedRowNumber)

    ; Get the row's 2nd column's text for real order number (hidden column).
    LV_GetText(RowText, SelectedWinNumber, 2)
}


;... END WindowStoreAttributes EVENT ..........................


;=== BEGIN ListView_Resize_Vertically EVENT ========================

ListViewResizeVertically(Gui_ID) ; Automatically resize listview vertically
{
    Global Window_Found_Count, lv_h_win_2000_adj
    SendMessage, 0x1000+31, 0, 0, SysListView321, ahk_id %Gui_ID% ; LVM_GETHEADER
    WinGetPos,,,, lv_header_h, ahk_id %ErrorLevel%
    VarSetCapacity( rect, 16, 0 )
    SendMessage, 0x1000+14, 0, &rect, SysListView321, ahk_id %Gui_ID% ; LVM_GETITEMRECT ; LVIR_BOUNDS
    ;~ Print("rect = " . &rect)
    y1 := 0
    y2 := 0
    Loop, 4
    {
        ;~ Print("*( &rect + 3 + A_Index ) = " . *( &rect + 3 + A_Index ))
        ;~ Print("*( &rect + 11 + A_Index ) = " . *( &rect + 11 + A_Index ))
        y1 += *( &rect + 3 + A_Index )
        y2 += *( &rect + 11 + A_Index )
    }
    ;~ Print("y1 = " . y1)
    ;~ Print("y2 = " . y2)
    lv_row_h := y2 - y1
    lv_row_h := (lv_row_h < 0 ? 24 : lv_row_h)
    ;~ Print("lv_row_h = " . lv_row_h)
    ;~ Print("lv_header_h = " . lv_header_h)
    ;~ Print("lv_row_h = " . lv_row_h)
    ;~ Print("Window_Found_Count = " . Window_Found_Count)
    ;~ Print("lv_h_win_2000_adj = " . lv_h_win_2000_adj)
    lv_h := 4 + lv_header_h + ( lv_row_h * Window_Found_Count ) + lv_h_win_2000_adj
    ; tab_y := lv_h - 6
    ; Tooltip % lv_header_h
    ;~ Print("lv_h = " . lv_h)
    GuiControl, Move, SysListView321, h%lv_h%
    ; GuiControl, Move, Gui1_Tab, y%tab_y%
}

;... END ListViewResizeVertically EVENT ..........................


;=== BEGIN tIncrementalSearch EVENT ========================
; AUTOMATICALLY CONDUCT REAL-TIME INCREMENTAL SEARCH
; TO FIND MATCHING RECORDS WITHOUT WAITING FOR USER
; TO PRESS <ENTER>
tIncrementalSearch:
    ;~ Print("tIncrementalSearch")
    Loop
    ; REPEAT SEARCHING UNTIL USER HAS STOPPED CHANGING THE QUERY STRING
    {
        Gui, %MainWindowHwnd%:Submit, NoHide
        ; TODO
        If (CurSearchString <> NewSearchString) {
            Print("CurSearchString = [" . CurSearchString . "], NewSearchString = [" . NewSearchString . "]")
            ;~ OpenTarget =
            CurSearchString := NewSearchString
            Gosub DisplayList
            ;~ Sleep, 100 ; DON'T HOG THE CPU!
            ;~ If OpenTarget <>			
                FileAppend, [tIncrementalSearch] OpenTarget is not empty`n, *
                ;~ GuiControl, 1:Choose, OpenTarget, |1
        }
        Else
        {
            ; QUERY STRING HAS STOPPED CHANGING
            Break
        }
    }

    ; USER HAS HIT <ENTER> TO LOOK FOR MATCHING RECORDS.
    ; RUN FindMatches NOW.
    If ResumeFindMatches = TRUE
    {
        ResumeFindMatches = FALSE
        ;~ Gosub FindMatches
    }

    ; CONTINUE MONITORING FOR CHANGES
    SetTimer, tIncrementalSearch, 100
Return

;... END tIncrementalSearch EVENT ..........................


;=== BEGIN DisableTimers SUBROUTINE =================================

DisableTimers:
    PrintSub("DisableTimers")
    SetTimer, CheckAltHotkeyUp, Off
    SetTimer, tIncrementalSearch, Off    
Return
    
;... END DisableTimers EVENT ..........................


;=== BEGIN OnKeyDown SUBROUTINE =================================

; Handle Up/Down when the are pressed in Filename Edit Control
; Select the ListBox items or move the selection to up/down when
;  Up/Down keys are pressed.
OnKeyDown(wParam, lParam, msg, hwnd)
{
    Global
    ;~ Global ListView1
    key := Format("vk{1:x}", wParam)
    keyName := GetKeyName(key)
    FileAppend, [OnKeyDown] wParam = [%wParam% %keyName%] lParam = [%lParam%] msg = [%msg%] hwnd = [%hwnd%]`n, *

    nItems := LV_GetCount()
    if (wParam = GetKeyVK("Control")) {
        CtrlBtnDown := true
        Print("CtrlBtnDown := true")
    }
    else if (wParam >= 48 && wParam <= 57) {    ; Number Key (not Numpad key)
        NumberBtnDown := true
        NumberBtnValue := (keyName = 0 ? 10 : keyName)
        Print("NumberBtnDown := true, NumberBtnValue = " . NumberBtnValue)
    }
    
    if (CtrlBtnDown && NumberBtnDown && (NumberBtnValue >= 1 && NumberBtnValue <= 10)) {
        Print("CtrlBtnDown && NumberBtnDown, NumberBtnValue = " . NumberBtnValue)
        windowID := Window%NumberBtnValue%
        ;~ Print("windowID = " . windowID)
        WinActivate, ahk_id %windowID%
        Gosub, ListViewDestroy
    }

    if (hwnd = ListView1Hwnd) {
        nItems := LV_GetCount()
        ;~ Print("Current SelectedRowNumber = " . SelectedRowNumber)
        if (wParam = GetKeyVK("Esc")) {
            ;~ Print("[OnKeyDown] ListView1Hwnd: Esc key pressed.")
            Gosub, ListViewDestroy
        }
        else if (wParam = GetKeyVK("Enter") and SelectedRowNumber <> 0) {
            ;~ Print("Opening...")
            windowID := Window%SelectedRowNumber%
            ;~ Print("windowID = " . windowID)
            WinActivate, ahk_id %windowID%
            Gosub, ListViewDestroy
        }
        else if (wParam = GetKeyVK("Down")) {
            SelectedRowNumber := (SelectedRowNumber >= nItems ? 1 : (SelectedRowNumber + 1))
            LV_Modify(SelectedRowNumber, "Select Vis")
            ;~ Print("LV_Modify")
        }
        else if (wParam = GetKeyVK("Up")) {
            SelectedRowNumber := (SelectedRowNumber <= 1 ? nItems : (SelectedRowNumber - 1))
            LV_Modify(SelectedRowNumber, "Select Vis")
            ;~ Print("LV_Modify")
        }
        ;~ Print("New SelectedRowNumber = " . SelectedRowNumber)
    }
}

;... END OnKeyDown SUBROUTINE ...................................


;=== BEGIN OnKeyUp SUBROUTINE =================================

OnKeyUp(wParam, lParam, msg, hwnd) {
    Global
    ;~ Global ListView1
    key := Format("vk{1:x}", wParam)
    keyName := GetKeyName(key)
    FileAppend, [OnKeyUp] wParam = [%wParam% %keyName%] lParam = [%lParam%] msg = [%msg%] hwnd = [%hwnd%]`n, *
}

;... END OnKeyUp SUBROUTINE ...................................


;=== BEGIN LV_ClickRow SUBROUTINE =================================

LV_ClickRow(lvHwnd, Row) { ; just me -> http://www.autohotkey.com/board/topic/86490-click-listview-row/#entry550767
    ; lvHwnd : ListView's HWND, Row : 1-based row number
    VarSetCapacity(RECT, 16, 0)
    SendMessage, 0x100E, Row - 1, &RECT, , ahk_id %lvHwnd%  ; LVM_GETITEMRECT
    POINT := NumGet(RECT, 0, "Short") | (NumGet(RECT, 4, "Short") << 16)
    PostMessage, 0x0201, 0, POINT, , ahk_id %lvHwnd% ; WM_LBUTTONDOWN
    PostMessage, 0x0202, 0, POINT, , ahk_id %lvHwnd% ; WM_LBUTTONUP
}

;... END LV_ClickRow SUBROUTINE ...................................


;=== BEGIN Get_Window_Icon SUBROUTINE =================================

GetWindowIcon(windowID, UseLargeIconsCurrent) ; (window id, whether to get large icons)
{
    Local NR_temp, h_icon
    ; check status of window - if window is responding or "Not Responding"
    NR_temp = 0 ; init
    h_icon =
    Responding := DllCall("SendMessageTimeout", "UInt", windowID, "UInt", 0x0, "Int", 0, "Int", 0, "UInt", 0x2, "UInt", 150, "UInt *", NR_temp) ; 150 = timeout in millisecs
    If (Responding) {
        ; WM_GETICON values -    ICON_SMALL =0,   ICON_BIG =1,   ICON_SMALL2 =2
        If (UseLargeIconsCurrent = 1) {
            SendMessage, 0x7F, 1, 0,, ahk_id %windowID%
            h_icon := ErrorLevel
        }
        If (!h_icon) {
            SendMessage, 0x7F, 2, 0,, ahk_id %windowID%
            h_icon := ErrorLevel
            If (!h_icon) {
                SendMessage, 0x7F, 0, 0,, ahk_id %windowID%
                h_icon := ErrorLevel
                If (!h_icon) {
                    If UseLargeIconsCurrent = 1
                        h_icon := DllCall( GetClassLong_API, "uint", windowID, "int", -14 )  ; GCL_HICON is -14
                    If (!h_icon) {
                        h_icon := DllCall( GetClassLong_API, "uint", windowID, "int", -34 )  ; GCL_HICONSM is -34
                        If (!h_icon) {
                            h_icon := DllCall( "LoadIcon", "uint", 0, "uint", 32512 )   ; IDI_APPLICATION is 32512
                        }
                    }
                }
            }
        }
    }
    
    If (!(h_icon = "" or h_icon = "FAIL")) {
        ; Add the HICON directly to the icon list
        ;~ Print("Got icon, Add the HICON directly to the icon list")
        Gui_Icon_Number := DllCall("ImageList_ReplaceIcon", UInt, ImageListID1, Int, -1, UInt, h_icon)
    }
    Else { ; use a generic icon
        Gui_Icon_Number := IL_Add(ImageListID1, "shell32.dll" , 3)
    }
    ;~ Print("Gui_Icon_Number = " . Gui_Icon_Number)
}

;... END GetWindowIcon SUBROUTINE ...................................


;=== BEGIN RGBtoBGR SUBROUTINE =================================

RGBtoBGR(oldValue) {
    return (oldValue & 0x00ff00) + ((oldValue & 0xff0000) >> 16) + ((oldValue & 0x0000ff) << 16)
}

;... END RGBtoBGR SUBROUTINE ...................................


;=== BEGIN GuiResizeAndPosition SUBROUTINE =================================

GuiResizeAndPosition:
    DetectHiddenWindows, On ; retrieving column widths to enable calculation of col 3 width
    Gui, +LastFound
    
    If (true) ; resize listview columns - no need to resize columns for updating listview
    {
        LV_ModifyCol(1, Col_1) ; icon column
        LV_ModifyCol(2, Col_2) ; hidden column for row number
        ; col 3 - see below
        LV_ModifyCol(4, Col_4) ; exe
        SendMessage, 0x1000+29, 3, 0,, ahk_id %ListView1Hwnd% ; LVM_GETCOLUMNWIDTH is 0x1000+29
        Width_Column_4 := ErrorLevel
        If Width_Column_4 > %ExeWidthMax%
        LV_ModifyCol(4, ExeWidthMax) ; resize title column

        Loop, 4
        {
            SendMessage, 0x1000+29, A_Index - 1, 0,, ahk_id %ListView1Hwnd% ; LVM_GETCOLUMNWIDTH is 0x1000+29
            Width_Column_%A_Index% := ErrorLevel
            ;~ Print("Width_Column_" . A_Index . " = " . Width_Column_%A_Index%)
        }

        Col_3_w := ListViewWidth - Width_Column_1 - Width_Column_2 - Width_Column_4 - 4 ; total width of columns - 4 for border
        LV_ModifyCol(3, Col_3_w) ; resize title column
    }
    
    Gui_ID := WinExist() ; for auto-sizing columns later
    ;~ Print("Gui_ID = " . Gui_ID)
    ListViewResizeVertically(Gui_ID) ; Automatically resize listview vertically - pass the gui id value

    GuiControlGet, Listview_Now, Pos, ListView1 ; retrieve listview dimensions/position ; for auto-sizing (elsewhere)
    ; resize listview according to scrollbar presence
    ; If (Listview_NowH > HeightMax AND UseLargeIconsCurrent =0) ; already using small icons so limit height
    If (Listview_NowH > HeightMax) ; limit height to specified fraction of window size
    {
        Col_3_w -= ScrollbarVerticalThickness ; allow for vertical scrollbar being visible
        LV_ModifyCol(3, Col_3_w) ; resize title column
        ; GuiControl, MoveDraw, Gui1_Tab
        GuiControl, Move, ListView1, h%HeightMax%
    }
    DetectHiddenWindows, Off
    Return

GuiResizeListViewColumnSize:
    DetectHiddenWindows, On ; retrieving column widths to enable calculation of col 3 width
    Gui, +LastFound
    
    LV_ModifyCol(1, Col_1) ; icon column
    LV_ModifyCol(2, Col_2) ; hidden column for row number
    ; col 3 - see below
    LV_ModifyCol(4, Col_4) ; exe
    SendMessage, 0x1000+29, 3, 0,, ahk_id %ListView1Hwnd% ; LVM_GETCOLUMNWIDTH is 0x1000+29
    Width_Column_4 := ErrorLevel
    If Width_Column_4 > %ExeWidthMax%
    LV_ModifyCol(4, ExeWidthMax) ; resize title column

    Loop, 4
    {
        SendMessage, 0x1000+29, A_Index - 1, 0,, ahk_id %ListView1Hwnd% ; LVM_GETCOLUMNWIDTH is 0x1000+29
        Width_Column_%A_Index% := ErrorLevel
        ;~ Print("Width_Column_" . A_Index . " = " . Width_Column_%A_Index%)
    }

    Col_3_w := ListViewWidth - Width_Column_1 - Width_Column_2 - Width_Column_4 - 4 ; total width of columns - 4 for border
    LV_ModifyCol(3, Col_3_w) ; resize title column
    
    ;~ Gui_ID := WinExist() ; for auto-sizing columns later
    Print("Gui_ID = " . Gui_ID)
    ListViewResizeVertically(Gui_ID) ; Automatically resize listview vertically - pass the gui id value

    GuiControlGet, Listview_Now, Pos, ListView1 ; retrieve listview dimensions/position ; for auto-sizing (elsewhere)
    ; Resize listview according to scrollbar presence
    ; If (Listview_NowH > HeightMax AND UseLargeIconsCurrent =0) ; already using small icons so limit height
    If (Listview_NowH > HeightMax) ; limit height to specified fraction of window size
    {
        Col_3_w -= ScrollbarVerticalThickness ; allow for vertical scrollbar being visible
        LV_ModifyCol(3, Col_3_w) ; resize title column
        ; GuiControl, MoveDraw, Gui1_Tab
        GuiControl, Move, ListView1, h%HeightMax%
    }
    DetectHiddenWindows, Off
    Return

;... END GuiResizeAndPosition SUBROUTINE ...................................


DecimalToHex(var) {
    SetFormat, IntegerFast, H
    var += 0 
    var .= ""
    SetFormat, Integer, D
    return var
}


/*
 * DWMWA_CLOAKED: If the window is cloaked, the following values explain why:
 * 1  The window was cloaked by its owner application (DWM_CLOAKED_APP)
 * 2  The window was cloaked by the Shell (DWM_CLOAKED_SHELL)
 * 4  The cloak value was inherited from its owner window (DWM_CLOAKED_INHERITED)
 */
IsInvisibleWin10BackgroundAppWindow(hWindow) {
    result := 0
    VarSetCapacity(cloakedVal, A_PtrSize) ; DWMWA_CLOAKED := 14
    hr := DllCall("DwmApi\DwmGetWindowAttribute", "Ptr", hWindow, "UInt", 14, "Ptr", &cloakedVal, "UInt", A_PtrSize)
    if !hr ; returns S_OK (which is zero) on success. Otherwise, it returns an HRESULT error code
    result := NumGet(cloakedVal) ; omitting the "&" performs better
    return result ? true : false
}

;=== BEGIN NewFunc SUBROUTINE =================================

LV_SetSI(hList, iItem, iSubItem, iImage) {
    Print("LV_SetSI")
	VarSetCapacity(LVITEM, 13 * 4 + 2 + A_PtrSize, 0)
	LVM_SETITEM := 0x1006, mask := 2    ; LVIF_IMAGE := 0x2
	iItem-- , iSubItem-- , iImage--		; Note first column (iSubItem) is #ZERO, hence adjustment
	NumPut(mask, LVITEM, 0, "UInt")
	NumPut(iItem, LVITEM, 4, "Int")
	NumPut(iSubItem, LVITEM, 8, "Int")
	NumPut(iImage, LVITEM, 28 + A_PtrSize, "Int")
	result := DllCall("SendMessage", UInt, hList, UInt, LVM_SETITEM, UInt, 0, UInt, &LVITEM)
	SendMessage, LVM_SETITEM, -1, &LVITEM, , ahk_id %hList%
	return result
}

;... END NewFunc SUBROUTINE ...................................


;=== BEGIN NewFunc SUBROUTINE =================================
;... END NewFunc SUBROUTINE ...................................


