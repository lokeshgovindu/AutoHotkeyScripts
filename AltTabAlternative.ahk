/*
o-----------------------------------------------------------------------------o
| Author : Lokesh Govindu                                                     |
|  Email : lokeshgovindu@gmail.com                                            |
| Inspired from https://github.com/ralesi/alttab.ahk                          |
(-----------------------------------------------------------------------------)
| Alt+Tab Alternative                  / A Script file for AutoHotkey 1.0.22+ |
|                                     ----------------------------------------|
| Details:                                                                    |
|                                                                             |
|                                                                             |
o-----------------------------------------------------------------------------o
*/

#SingleInstance Force
#Include CommonUtils.ahk
#Include Class_Subclass.ahk ; Include Class_Subclass.ahk to subclass edit

;========================================================================================================
; Windows Messages

WM_KEYDOWN := 0x100
WM_KEYUP   := 0x101

;========================================================================================================
; USER EDITABLE SETTINGS:

AppTitle := "Lokesh Govindu's Alt+Tab Alternative"
NewEditSearchString  = 
FocusedRowNumber    := 1
Display_List_Shown  := 0
CtrlBtnDown         := false
NumberBtnDown       := false
NumberBtnValue      := -1

; Icons
Use_Large_Icons         = 1     ; 0 = small icons, 1 = large icons in listview
Listview_Resize_Icons   = 0     ; Resize icons to fit listview area

; Fonts
Font_Size           = 11
Font_Color          = e9ded3
Font_Color_Edit     = ff0000
Font_Color_ListView = 000000
Font_Color_ListView = ffffff
Font_Style          = norm
Font_Size_Tab       = 8
Font_Type_Tab       = Consolas
Font_Type           = Lucida Handwriting

; Position
Gui_x = Center
Gui_y = Center

; Max height
Height_Max_Modifier = 0.65 ; multiplier for screen height (e.g. 0.92 = 92% of screen height max )

; Width
Listview_Width  := A_ScreenWidth * 0.45
Listview_Width  := (Listview_Width < 864 ? 864 : Listview_Width)
SB_Width        := Listview_Width / 4 ; StatusBar section sizes
Exe_Width_Max   := Listview_Width / 5 ; Exe column max width

Listview_Column_ProcessNameWidth := 200
Listview_Column_TitleWidth       := Listview_Width - Listview_Column_ProcessNameWidth

; Tray Icon file name
Tray_Icon := "Icon.ico"

;========================================================================================================

; USER OVERRIDABLE SETTINGS:

; ListView Column Widths
Col_1 = Auto        ; Icon Column
Col_2 = 0           ; Row Number
; col 3 is autosized based on other column sizes
Col_4 = Auto    ; Process Name

Column_Title_List = #| |Window Title|Process Name
StringSplit, Column_Title, Column_Title_List,| ; Create list of listview header titles

; Max height
Height_Max := A_ScreenHeight * Height_Max_Modifier ; limit height of listview
Small_to_Large_Ratio = 1.6 ; height of small rows compared to large rows

; Colours in RGB hex
Tab_Colour      := 1c1b1a
Listview_Colour := 1c1b1a ; does not need converting as only used for background

; convert colours to correct format for listview color functions:
Listview_Colour_Max_Text            := RGBtoBGR("0xffffff") ; highlight minimised windows
Listview_Colour_Max_Back            := RGBtoBGR("0x000000")
Listview_Colour_Min_Text            := RGBtoBGR("0x000000") ; highlight minimised windows
Listview_Colour_Min_Back            := RGBtoBGR("0xffa724")
Listview_Colour_OnTop_Text          := RGBtoBGR("0x000000") ; highlight alwaysontop windows
Listview_Colour_OnTop_Back          := RGBtoBGR("0xff2c4b")
Listview_Colour_Dialog_Text         := RGBtoBGR("0xFFFFFF")
Listview_Colour_Dialog_Back         := RGBtoBGR("0xFB5959")
Listview_Colour_Selected_Text       := RGBtoBGR("0xffffff")
Listview_Colour_Selected_Back       := RGBtoBGR("0x0a9dff")
Listview_Colour_Not_Responding_Text := RGBtoBGR("0xFFFFFF")
Listview_Colour_Not_Responding_Back := RGBtoBGR("0xFF0000")

;========================================================================================================

If A_PtrSize = 8
    GetClassLong_API := "GetClassLongPtr"
else
    GetClassLong_API := "GetClassLong"

WS_EX_APPWINDOW = 0x40000   ; Provides a taskbar button
WS_EX_TOOLWINDOW = 0x80     ; Removes the window from the alt-tab list
GW_OWNER = 4

SysGet, Scrollbar_Vertical_Thickness, 2 ; 2 is SM_CXVSCROLL, Width of a vertical scroll bar
If A_OSVersion = WIN_2000
    lv_h_win_2000_adj = 2 ; adjust height of main listview by +2 pixels to avoid scrollbar in windows 2000
Else
    lv_h_win_2000_adj = 0

Use_Large_Icons_Current = %Use_Large_Icons% ; for remembering original user setting but changing on the fly

;========================================================================================================

Gosub, Initiate_Hotkeys

Return

;========================================================================================================

Initiate_Hotkeys:
    Print("[Sub] Initiate_Hotkeys")
    Hotkey, ``, Alt_Tab_Alternative, On
    Hotkey, Esc, ListView_Destroy, Off
    Return

;========================================================================================================

Alt_Tab_Alternative:
    if (Display_List_Shown = 1) {
        ; Window is already displayed
        Return
    }
    Print("[Sub] Alt_Tab_Alternative Begin ---------------------------------------")
    Gosub, Initialize_Defaults
    Gosub, Create_Window
    Gosub, Display_List
    Gosub, Gui_Resize_and_Position
    Gosub, Show_Window
    Display_List_Shown = 1
    Print("[Sub] Alt_Tab_Alternative End ---------------------------------------")
    return
    
;========================================================================================================
    
Initialize_Defaults:
    Print("Initialize_Defaults")
    NewEditSearchString  = 
    FocusedRowNumber    := 1
    Display_List_Shown  := 0
    CtrlBtnDown         := false
    NumberBtnDown       := false
    NumberBtnValue      := -1
    Return

;========================================================================================================

Create_Window:
    Print("[Sub] Create_Window")
    Gui, 1: +AlwaysOnTop +ToolWindow -Caption +HwndMainWindowHwnd
    Gui, 1: Color, %Tab_Colour% ; i.e. border/background 
    Gui, 1: Margin, 0, 0

    Gui, 1: Font, s%Font_Size% c%Font_Color_Edit% %Font_Style%, %Font_Type%
    Gui, 1: Add, Edit, vEditSearchStringVar HwndEditSearchStringHwnd Center w%Listview_Width%
    Print("EditSearchStringHwnd = [ " . EditSearchStringHwnd . "]")

    Gui, 1: Font, s%Font_Size% c%Font_Color_ListView% %Font_Style%, %Font_Type%
    Gui, Add, ListView, w%Listview_Width% h200 AltSubmit +Redraw -Multi NoSort +LV0x2 Background%Listview_Colour% Count10 gListView_Event vListView1 HwndListView1Hwnd, %Column_Title_List%
    Print("ListView1Hwnd = [" . ListView1Hwnd . "]")
    Gui, 1: +LastFound
    WinSet, Transparent, 222
    Return

;========================================================================================================

Show_Window:
    Print("[Sub] Show_Window")
    Gui_vx := Gui_CenterX()
    Gui, 1: Show, AutoSize x%Gui_vx% y%Gui_y%, %AppTitle%
    Return

;========================================================================================================

Display_Dim_Background:
    Print("[Sub] Display_Dim_Background")
    ; define background GUI to dim all active applications
    SysGet, Width, 78
    SysGet, Height, 79

    SysGet, X0, 76
    SysGet, Y0, 77

    ; Background GUI used to show foremost window
    Gui, 4: +LastFound -Caption +ToolWindow
    Gui, 4: Color, Black
    Gui, 4: Show, Hide
    ;~ WinSet, Transparent, 120
    Gui, 4: Show, NA x%X0% y%Y0% w%Width% h%Height%
    Gui4_ID := WinExist() ; for auto-sizing columns later

    return
    
;========================================================================================================

Display_List:
    Print("[Sub] Display_List")
    LV_Delete()
    windowList =
    Window_Found_Count := 0
    
    DetectHiddenWindows, Off ; makes DllCall("IsWindowVisible") unnecessary
    
    ImageListID1 := IL_Create(10, 5, Use_Large_Icons_Current) ; Create an ImageList so that the ListView can display some icons
    LV_SetImageList(ImageListID1, 1)    ; Attach the ImageLists to the ListView so that it can later display the icons
    
    WinGet, windowList, List ; gather a list of running programs
    Loop, %windowList%
    {
        ownerID := windowID := windowList%A_Index%
        
        Loop {
            ownerID := Decimal_to_Hex(DllCall("GetWindow", "UInt", ownerID, "UInt", GW_OWNER))
        } Until !Decimal_to_Hex(DllCall("GetWindow", "UInt", ownerID, "UInt", GW_OWNER))
        
        ownerID := ownerID ? ownerID : windowID
        If (Decimal_to_Hex(DllCall("GetLastActivePopup", "UInt", ownerID)) = windowID) {
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
                ;~ Print("NewEditSearchString = " . NewEditSearchString)
                If (InStr(title, NewEditSearchString, false) != 0 or InStr(procName, NewEditSearchString, false) != 0)
                {
                    Window_Found_Count += 1
                    Get_Window_Icon(windowID, Use_Large_Icons_Current)          ; (window id, whether to get large icons)
                    Window__Store_attributes(Window_Found_Count, windowID, "")  ; Index, wid, parent (or blank if none)
                    LV_Add("Icon" . Window_Found_Count, "", Window_Found_Count, title, procName)
                    ;~ LV_Add("", "", Window_Found_Count, title, procName)
                    ;~ result := LV_SetSI(ListView1Hwnd, Window_Found_Count, 3, Window_Found_Count)
                    ;~ Print("result = " . result)
                    ;~ LV_Add("Icon" . Window_Found_Count, "", Window_Found_Count, Window_Found_Count . ". " . title, procName)
                    ;~ LV_Add(Window_Found_Count, "Icon" . Window_Found_Count, "", title, procName)
                }
            }
        }
    }

	; HANDLE WM_KEYDOWN EVENT TO SELECT THE ITEMS OF LISTBOX USING UP / DOWN KEYS FROM
	; FILENAME EDIT CONTROL
	OnMessage(WM_KEYDOWN, "OnKeyDown")
	OnMessage(WM_KEYUP,   "OnKeyUp")

	; SUBCLASS FILENAME EDIT CONTROL TO DISABLE THE UP/DOWN KEY EVENTS
	Subclass.SetFunction(EditSearchStringHwnd, WM_KEYDOWN, "EditSearchString_WM_KEYDOWN")

    GuiControl, +Redraw, ListView1
    LV_Modify(FocusedRowNumber, "Select Vis") ; get selected row and ensure selection is visible

    ; TURN ON INCREMENTAL SEARCH
    SetTimer, tIncrementalSearch, 500

    Return

;========================================================================================================

ListView_Event:
    Critical, 50
    Print("A_GuiEvent = " . A_GuiEvent)
    if A_GuiEvent = DoubleClick     ; DoubleClick
    {
        LV_GetText(RowText, A_EventInfo)
        ;~ ToolTip You double-clicked row number %A_EventInfo%. Text: "%RowText%"        
        FocusedRowNumber := A_EventInfo
        Print("FocusedRowNumber = " . FocusedRowNumber)
        windowID := Window%FocusedRowNumber%
        Print("Activating windowID = " . windowID)
        Print("Activating windowTitle = " . WindowTitle%FocusedRowNumber%)
        WinActivate, ahk_id %windowID%
        Gosub, ListView_Destroy
    }
    if A_GuiEvent = Normal          ; Mouse left-click
    {
        LV_GetText(RowText, A_EventInfo)
        ;~ ToolTip You double-clicked row number %A_EventInfo%. Text: "%RowText%"        
        FocusedRowNumber := A_EventInfo
        Print("FocusedRowNumber = " . FocusedRowNumber)
        windowID := Window%FocusedRowNumber%
        Print("Activating windowID = " . windowID)
        Print("Activating windowTitle = " . WindowTitle%FocusedRowNumber%)
        ;~ WinActivate, ahk_id %windowID%
        ;~ Gosub, ListView_Destroy
    }
    if A_GuiEvent = I               ; Mouse left-click
    {
        LV_GetText(RowText, A_EventInfo)
        ;~ ToolTip You double-clicked row number %A_EventInfo%. Text: "%RowText%"        
        FocusedRowNumber := A_EventInfo
        Print("FocusedRowNumber = " . FocusedRowNumber)
        windowID := Window%FocusedRowNumber%
        Print("Activating windowID = " . windowID)
        Print("Activating windowTitle = " . WindowTitle%FocusedRowNumber%)
        ;~ WinActivate, ahk_id %windowID%
        ;~ Gosub, ListView_Destroy
    }
    Return

;========================================================================================================

ListView_Destroy:
    Print("[Sub] ListView_Destroy")
    Gosub, Disable_Timers
    Gui, 1: Destroy
    Display_List_Shown := 0
    Return
    
;========================================================================================================

Gui_CenterX()
{
    Global Listview_Width
    Coordmode, Mouse, Screen
    MouseGetPos, x, y
    SysGet, m, MonitorCount
    ; Iterate through all monitors.
    Loop, %m%
    {   ; Check if the window is on this monitor.
        SysGet, Mon, Monitor, %A_Index%
        if (x >= MonLeft && x <= MonRight && y >= MonTop && y <= MonBottom)
        {
            return (0.5 * (MonRight - MonLeft) + MonLeft - Listview_Width / 2)
        }
    }
}


;=== BEGIN Window__Store_attributes EVENT ========================

Window__Store_attributes(index, windowsID, ID_Parent) ; index = Window_Found_Count, windowID = window id, ID_Parent = parent or blank if none
{
    Local State_temp
    WinGetTitle, windowTitle, ahk_id %ownerID%
    WinGet, procPath, ProcessPath, ahk_id %windowID%
    WinGet, procName, ProcessName, ahk_id %windowID%
    WinGet, procID, PID, ahk_id %windowID%
    
    Window%index%        := windowID        ; store ahk_id's to a list
    WindowParent%index%  := ID_Parent       ; store Parent ahk_id's to a list to later see if window is owned
    WindowTitle%index%   := windowTitle     ; store titles to a list
    hw_popup%index%      := hw_popup        ; store the active popup window to a list (eg the find window in notepad)
    Exe_Name%index%      := procName        ; store the process name
    Exe_Path%index%      := procPath        ; store the process path
    PID%index%           := procID          ; store the process id
    Dialog%index%        := Dialog          ; 1 if found a Dialog window, else 0
    
    ;~ Print("Index = " . Window%index% . ", Parent = " . Window_Parent%index% . ", WindowTitle = " . WindowTitle%index%)
    
    ;~ WinGet, Exe_Name%index%, ProcessName, ahk_id %wid% ; store processes to a list
    ;~ WinGet, PID%index%, PID, ahk_id %wid% ; store pid's to a list
    ;~ Dialog%index% := Dialog  ; 1 if found a Dialog window, else 0
    ;~ WinGet, State_temp, MinMax, ahk_id %wid%
    ;~ If State_temp =1
        ;~ State%index% =Max
    ;~ Else If State_temp =-1
        ;~ State%index% =Min
    ;~ Else If State_temp =0
        ;~ State%index% =
    ;~ WinGet, es_hw_popup, ExStyle, ahk_id %hw_popup% ; eg to detect on top status of zoomplayer window
    ;~ If ((es & 0x8) or (es_hw_popup & 0x8))  ; 0x8 is WS_EX_TOPMOST.
    ;~ {
        ;~ OnTop%index% =Top
        ;~ OnTop_Found =1
    ;~ }
    ;~ Else
        ;~ OnTop%index% =

    ;~ If Responding
        ;~ Status%index% =
    ;~ Else
    ;~ {
        ;~ Status%index% =Not Responding
        ;~ Status_Found =1
    ;~ }
}

;... END Window__Store_attributes EVENT ..........................


;=== BEGIN ListView_Resize_Vertically EVENT ========================

ListView_Resize_Vertically(Gui_ID) ; Automatically resize listview vertically
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

;... END ListView_Resize_Vertically EVENT ..........................


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
        CurSearchString = %EditSearchStringVar%
        If NewEditSearchString <> %CurSearchString%
        {
            Print("CurSearchString = [" . CurSearchString . "], NewEditSearchString = [" . NewEditSearchString . "]")
            ;~ OpenTarget =
            NewEditSearchString = %CurSearchString%
            Gosub Display_List
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


;=== BEGIN OnKeyDown SUBROUTINE =================================

Disable_Timers:
    SetTimer, tIncrementalSearch, Off
    Return
    
;... END tIncrementalSearch EVENT ..........................


;=== BEGIN OnKeyDown SUBROUTINE =================================

; Handle Up/Down when the are pressed in Filename Edit Control
; Select the ListBox items or move the selection to up/down when
;  Up/Down keys are pressed.
OnKeyDown(wParam, lParam, msg, hwnd) {
    Global
    ;~ Global EditSearchStringHwnd
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
        Gosub, ListView_Destroy
    }

    if (hwnd = EditSearchStringHwnd) {
        ;~ FocusedRowNumber := LV_GetNext(0)  ; Find the focused row.
        ;~ if (not FocusedRowNumber) { ; No row is focused.
            ;~ FocusedRowNumber := 1
            ;~ Print("[INFO] No row is focused")
        ;~ }
        nItems := LV_GetCount()
        Print("Current FocusedRowNumber = " . FocusedRowNumber)
        ;~ FileAppend, [OnKeyDown] hwnd = EditSearchStringHwnd`n, *
        if (wParam = GetKeyVK("Enter") and FocusedRowNumber <> 0) {
            Print("Opening...")
            windowID := Window%FocusedRowNumber%
            ;~ Print("windowID = " . windowID)
            WinActivate, ahk_id %windowID%
            Gosub, ListView_Destroy
        }
        else if (wParam = GetKeyVK("Down")) {
            FocusedRowNumber := (FocusedRowNumber >= nItems ? 1 : (FocusedRowNumber + 1))
            LV_Modify(FocusedRowNumber, "Select Vis")
            ;~ Print("LV_Modify")
        }
        else if (wParam = GetKeyVK("Up")) {
            FocusedRowNumber := (FocusedRowNumber <= 1 ? nItems : (FocusedRowNumber - 1))
            LV_Modify(FocusedRowNumber, "Select Vis")
            ;~ Print("LV_Modify")
        }
        else if (wParam = GetKeyVK("Esc")) {
            Print("[OnKeyDown] Esc key pressed.")
            Gosub, ListView_Destroy
        }
        Print("New FocusedRowNumber = " . FocusedRowNumber)
    }
    else if (hwnd = ListView1Hwnd) {
        nItems := LV_GetCount()
        Print("Current FocusedRowNumber = " . FocusedRowNumber)
        if (wParam = GetKeyVK("Esc")) {
            Print("[OnKeyDown] ListView1Hwnd: Esc key pressed.")
            Gosub, ListView_Destroy
        }
        else if (wParam = GetKeyVK("Enter") and FocusedRowNumber <> 0) {
            Print("Opening...")
            windowID := Window%FocusedRowNumber%
            ;~ Print("windowID = " . windowID)
            WinActivate, ahk_id %windowID%
            Gosub, ListView_Destroy
        }
        else if (wParam = GetKeyVK("Down")) {
            FocusedRowNumber := (FocusedRowNumber >= nItems ? 1 : (FocusedRowNumber + 1))
            LV_Modify(FocusedRowNumber, "Select Vis")
            Print("LV_Modify")
        }
        else if (wParam = GetKeyVK("Up")) {
            FocusedRowNumber := (FocusedRowNumber <= 1 ? nItems : (FocusedRowNumber - 1))
            LV_Modify(FocusedRowNumber, "Select Vis")
            Print("LV_Modify")
        }
        Print("New FocusedRowNumber = " . FocusedRowNumber)
    }
}

;... END OnKeyDown SUBROUTINE ...................................


;=== BEGIN OnKeyUp SUBROUTINE =================================

OnKeyUp(wParam, lParam, msg, hwnd) {
    Global
    ;~ Global EditSearchStringHwnd
    ;~ Global ListView1
    key := Format("vk{1:x}", wParam)
    keyName := GetKeyName(key)
    FileAppend, [OnKeyUp] wParam = [%wParam% %keyName%] lParam = [%lParam%] msg = [%msg%] hwnd = [%hwnd%]`n, *
}

;... END OnKeyUp SUBROUTINE ...................................


;=== BEGIN EditSearchString_WM_KEYDOWN SUBROUTINE =================================

; Disable the Up/Down keys on Filename Edit Control. And handle these keys
;  in OnKeyDown callback function to select the ListBox items and move the
;  selection to up/down when Up/Down keys are pressed.
EditSearchString_WM_KEYDOWN(Hwnd, Message, wParam, lParam) {
	key := Format("vk{1:x}", wParam)
	keyName := GetKeyName(key)
	FileAppend, [EditSearchString_WM_KEYDOWN] wParam = [%wParam% %keyName%] lParam = [%lParam%] msg = [%Message%] hwnd = [%hwnd%]`n, *
	if (wParam = GetKeyVK("Down") or wParam = GetKeyVK("Up")) {
		return False	; Prevent default message processing
	}
	return True
}

;... END EditSearchString_WM_KEYDOWN SUBROUTINE ...................................


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

Get_Window_Icon(windowID, Use_Large_Icons_Current) ; (window id, whether to get large icons)
{
    Local NR_temp, h_icon
    ; check status of window - if window is responding or "Not Responding"
    NR_temp = 0 ; init
    h_icon =
    Responding := DllCall("SendMessageTimeout", "UInt", windowID, "UInt", 0x0, "Int", 0, "Int", 0, "UInt", 0x2, "UInt", 150, "UInt *", NR_temp) ; 150 = timeout in millisecs
    If (Responding) {
        ; WM_GETICON values -    ICON_SMALL =0,   ICON_BIG =1,   ICON_SMALL2 =2
        If (Use_Large_Icons_Current = 1) {
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
                    If Use_Large_Icons_Current = 1
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

;... END Get_Window_Icon SUBROUTINE ...................................


;=== BEGIN RGBtoBGR SUBROUTINE =================================

RGBtoBGR(oldValue) {
    return (oldValue & 0x00ff00) + ((oldValue & 0xff0000) >> 16) + ((oldValue & 0x0000ff) << 16)
}

;... END RGBtoBGR SUBROUTINE ...................................


;=== BEGIN Gui_Resize_and_Position SUBROUTINE =================================

Gui_Resize_and_Position:
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
        If Width_Column_4 > %Exe_Width_Max%
        LV_ModifyCol(4, Exe_Width_Max) ; resize title column

        Loop, 4
        {
            SendMessage, 0x1000+29, A_Index - 1, 0,, ahk_id %ListView1Hwnd% ; LVM_GETCOLUMNWIDTH is 0x1000+29
            Width_Column_%A_Index% := ErrorLevel
            ;~ Print("Width_Column_" . A_Index . " = " . Width_Column_%A_Index%)
        }

        Col_3_w := Listview_Width - Width_Column_1 - Width_Column_2 - Width_Column_4 - 4 ; total width of columns - 4 for border
        LV_ModifyCol(3, Col_3_w) ; resize title column
    }
    
    Gui_ID := WinExist() ; for auto-sizing columns later
    ;~ Print("Gui_ID = " . Gui_ID)
    ListView_Resize_Vertically(Gui_ID) ; Automatically resize listview vertically - pass the gui id value

    GuiControlGet, Listview_Now, Pos, ListView1 ; retrieve listview dimensions/position ; for auto-sizing (elsewhere)
    ; resize listview according to scrollbar presence
    ; If (Listview_NowH > Height_Max AND Use_Large_Icons_Current =0) ; already using small icons so limit height
    If (Listview_NowH > Height_Max) ; limit height to specified fraction of window size
    {
        Col_3_w -= Scrollbar_Vertical_Thickness ; allow for vertical scrollbar being visible
        LV_ModifyCol(3, Col_3_w) ; resize title column
        ; GuiControl, MoveDraw, Gui1_Tab
        GuiControl, Move, ListView1, h%Height_Max%
    }
    DetectHiddenWindows, Off
    Return

Gui_Resize_ListView_ColumnSize:
    DetectHiddenWindows, On ; retrieving column widths to enable calculation of col 3 width
    Gui, +LastFound
    
    LV_ModifyCol(1, Col_1) ; icon column
    LV_ModifyCol(2, Col_2) ; hidden column for row number
    ; col 3 - see below
    LV_ModifyCol(4, Col_4) ; exe
    SendMessage, 0x1000+29, 3, 0,, ahk_id %ListView1Hwnd% ; LVM_GETCOLUMNWIDTH is 0x1000+29
    Width_Column_4 := ErrorLevel
    If Width_Column_4 > %Exe_Width_Max%
    LV_ModifyCol(4, Exe_Width_Max) ; resize title column

    Loop, 4
    {
        SendMessage, 0x1000+29, A_Index - 1, 0,, ahk_id %ListView1Hwnd% ; LVM_GETCOLUMNWIDTH is 0x1000+29
        Width_Column_%A_Index% := ErrorLevel
        ;~ Print("Width_Column_" . A_Index . " = " . Width_Column_%A_Index%)
    }

    Col_3_w := Listview_Width - Width_Column_1 - Width_Column_2 - Width_Column_4 - 4 ; total width of columns - 4 for border
    LV_ModifyCol(3, Col_3_w) ; resize title column
    
    ;~ Gui_ID := WinExist() ; for auto-sizing columns later
    Print("Gui_ID = " . Gui_ID)
    ListView_Resize_Vertically(Gui_ID) ; Automatically resize listview vertically - pass the gui id value

    GuiControlGet, Listview_Now, Pos, ListView1 ; retrieve listview dimensions/position ; for auto-sizing (elsewhere)
    ; resize listview according to scrollbar presence
    ; If (Listview_NowH > Height_Max AND Use_Large_Icons_Current =0) ; already using small icons so limit height
    If (Listview_NowH > Height_Max) ; limit height to specified fraction of window size
    {
        Col_3_w -= Scrollbar_Vertical_Thickness ; allow for vertical scrollbar being visible
        LV_ModifyCol(3, Col_3_w) ; resize title column
        ; GuiControl, MoveDraw, Gui1_Tab
        GuiControl, Move, ListView1, h%Height_Max%
    }
    DetectHiddenWindows, Off
    Return

;... END Gui_Resize_and_Position SUBROUTINE ...................................


Decimal_to_Hex(var) {
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


