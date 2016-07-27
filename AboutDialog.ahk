/*
o-----------------------------------------------------------------------------o
|   Author : Lokesh Govindu                                                   |
|    Email : lokeshgovindu@gmail.com                                          |
| HomePage : http://lokeshgovindu.blogspot.in/                                |
(-----------------------------------------------------------------------------)
| About Dialog                         / A Script file for AutoHotkey 1.1.23+ |
|                                     ----------------------------------------|
|                                                                             |
o-----------------------------------------------------------------------------o
*/

AboutDialog()
{
	Global
	AboutDialogWidth := 480

	ProgramName := "AltTabAlternative"
	ProgramVersion := "2016.1"
	AuthorName := "Lokesh Govindu"
	AuthorPage := "http://lokeshgovindu.blogspot.in/"

	Gui AboutDialog: New, , About %ProgramName%
	Gui Margin, 10, 10
	Gui Font, s11 Norm, Comic Sans MS
	Gui Add, Link, hWndhAppSysLink vProgNameSysLink, <a href="http://alttabalternative.sourceforge.net/">%ProgramName%</a> Version %ProgramVersion%
	Gui Add, Link, y+1 hWndhAuthorSysLink vAuthorSysLink, <a href="%AuthorPage%">%AuthorName%</a> (C) 2016

	Gui Font, s11, Lucida Handwriting
	Gui Add, Text, y+9 w447 r3 c004080 vAboutTextVar, AltTabAlternative is a small application created in AutoHotkey, an alternative for windows native Alt+Tab switcher.
	GroupBox("GB1", "About", 15, 6, "AboutTextVar")
	Gui Font
	Gui Add, Button, w75 gBtnOk vBtnOk +Default +Center, OK
	Gui Show, w%AboutDialogWidth%
	Return
	
	
AboutDialogGuiEscape:	
AboutDialogGuiClose:
BtnOk:
    Gui, AboutDialog:Hide

AboutDialogGuiSize:
	MoveControlToHorizontalCenter("ProgNameSysLink", AboutDialogWidth)
	MoveControlToHorizontalCenter("AuthorSysLink", AboutDialogWidth)
	MoveControlToHorizontalCenter("BtnOk", AboutDialogWidth)
	GuiControl, Focus, BtnOk
Return

; End of the GUI section

}

;************************** GroupBox *******************************
;
;	Adds and wraps a GroupBox around a group of controls in
;	the default Gui. Use the Gui Default command if needed.
;	For instance:
;
;		Gui, 2:Default
;
;	sets the default Gui to Gui 2.
;
;	Add the controls you want in the GroupBox to the Gui using
;	the "v" option to assign a variable name to each control. *
;	Then immediately after the last control for the group
;	is added call this function. It will add a GroupBox and
;	wrap it around the controls.
;
;	Example:
;
;	Gui, Add, Text, vControl1, This is Control 1
;	Gui, Add, Text, vControl2 x+30, This is Control 2
;	GroupBox("GB1", "Testing", 20, 10, "Control1|Control2")
;	Gui, Add, Text, Section xMargin, This is Control 3
;	GroupBox("GB2", "Another Test", 20, 10, "This is Control 3")
;	Gui, Add, Text, yS, This is Control 4
;	GroupBox("GB3", "Third Test", 20, 10, "Static4")
;	Gui, Show, , GroupBox Test
;
;	* The "v" option to assign Control ID is not mandatory. You
;	may also use the ClassNN name or text of the control.
;
;	Author: dmatch @ AHK forum
;	Date: Sept. 5, 2011
;
;********************************************************************

GroupBox(GBvName			;Name for GroupBox control variable
		,Title				;Title for GroupBox
		,TitleHeight		;Height in pixels to allow for the Title
		,Margin				;Margin in pixels around the controls
		,Piped_CtrlvNames	;Pipe (|) delimited list of Controls
		,FixedWidth=""		;Optional fixed width
		,FixedHeight="")	;Optional fixed height
{
	Local maxX, maxY, minX, minY, xPos, yPos ;all else assumed Global
	minX:=99999
	minY:=99999
	maxX:=0
	maxY:=0
	Loop, Parse, Piped_CtrlvNames, |, %A_Space%
	{
		;Get position and size of each control in list.
		GuiControlGet, GB, Pos, %A_LoopField%
		;creates GBX, GBY, GBW, GBH
		if(GBX<minX) ;check for minimum X
			minX:=GBX
		if(GBY<minY) ;Check for minimum Y
			minY:=GBY
		if(GBX+GBW>maxX) ;Check for maximum X
			maxX:=GBX+GBW
		if(GBY+GBH>maxY) ;Check for maximum Y
			maxY:=GBY+GBH

		;Move the control to make room for the GroupBox
		xPos:=GBX+Margin
		yPos:=GBY+TitleHeight+Margin ;fixed margin
		GuiControl, Move, %A_LoopField%, x%xPos% y%yPos%
	}
	;re-purpose the GBW and GBH variables
	if(FixedWidth)
		GBW:=FixedWidth
	else
		GBW:=maxX-minX+2*Margin ;calculate width for GroupBox
	if(FixedHeight)
		GBH:=FixedHeight
	else
		GBH:=maxY-MinY+TitleHeight+2*Margin ;calculate height for GroupBox ;fixed 2*margin

	;Add the GroupBox
	Gui, Add, GroupBox, v%GBvName% x%minX% y%minY% w%GBW% h%GBH%, %Title%
	return
}

MoveControlToHorizontalCenter(CtrlvName, Width)
{
	GuiControlGet, CtrlPos, Pos, %CtrlvName%
	XPos := (Width - CtrlPosW) / 2
	GuiControl, Move, %CtrlvName%, x%XPos%
}
