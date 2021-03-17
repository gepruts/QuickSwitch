
;_____________________________________________________________________________
;
;					SETTINGS
;_____________________________________________________________________________
;

	#NoEnv  						; Recommended for performance and compatibility with future AutoHotkey releases.
;	#Warn							; Enable warnings to assist with detecting common errors.
	SendMode Input					; Recommended for new scripts due to its superior speed and reliability.
	SetWorkingDir %A_ScriptDir%		; Ensures a consistent starting directory.
	#singleinstance force


;	Total Commander internal codes
	global cm_CopySrcPathToClip  := 2029
	global cm_CopyTrgPathToClip  := 2030

	global $DEBUG := 0


	FunctionShowMenu := Func("ShowMenu")
	Hotkey, ^Q, %FunctionShowMenu%, Off




;	INI file ( <program name without extension>.INI)
	SplitPath, A_ScriptFullPath,,,, name_no_ext
	$INI := name_no_ext  . ".ini"
	name_no_ext := ""
	




;_____________________________________________________________________________
;
;					ACTION!
;_____________________________________________________________________________
;

loop
{
	
	WinWaitActive, ahk_class #32770

;_____________________________________________________________________________
;
;					DIALOG ACTIVE
;_____________________________________________________________________________
;

	
;	Get ID of dialog box
	$WinID := WinExist("A")

	$DialogType := SmellsLikeAFileDialog($WinID)

	If $DialogType											;	This is a supported dialog
	{
		
	;	Get Windows title and process.exe of this dialog
		WinGet, $ahk_exe, ProcessName, ahk_id %$WinID%
		WinGetTitle, $window_title , ahk_id %$WinID%

		$FingerPrint := $ahk_exe . "___" . $window_title


	;	Check if FingerPrint entry is already in INI, so we know what to do.
		IniRead, $DialogAction, %$INI%, Dialogs, %$FingerPrint%




		If ($DialogAction = 1 )   								;	======= AutoSwitch ==
		{	
			$FolderPath := Get_Zfolder($WinID)
;MsgBox $FolderPath = %$FolderPath%

			If ( ValidFolder( $FolderPath )) 
			{ 
			;	FeedDialog($WinID, $FolderPath)
				FeedDialog%$DialogType%($WinID, $FolderPath)
			}
		}
		Else If ($DialogAction = 0 )							;	======= Never here ==
		{
		;	Do nothing
		}
		Else															;	======= Show Menu ==
		{
			ShowMenu()
		}



	;	If we end up here, we checked the INI for what to do in this supported dialog and did it
	;	We are still in this dialog and can now enable the hotkey for manual menu-activation
	;	Activate the CTR-Q hotkey. When pressed, start the  ShowMenu routine


		Hotkey, ^Q, On
	}																	;	End of File Dialog routine
	Else																;	This is a NOT supported dialog
	{
	;	Do nothing; Not a supported dialogtype
	}

	sleep, 100






	WinWaitNotActive
		
;_____________________________________________________________________________
;
;					DIALOG NOT ACTIVE
;_____________________________________________________________________________
;

		Hotkey, ^Q, Off

	
;	Clean up
	$WinID := ""
	$ahk_exe := ""
	$window_title := ""
	$ahk_exe := ""
	$DialogAction := ""
	$DialogType := ""
	$FolderPath := ""
	$DialogType := ""



;_____________________________________________________________________________
;
}	; End of continuous	WinWaitActive /	WinWaitNotActive loop
;_____________________________________________________________________________




MsgBox We never get here (and that's how it should be)
ExitApp






;=============================================================================
;=============================================================================
;=============================================================================
;
;			SUBROUTINES AND FUNCTIONS
;
;=============================================================================
;=============================================================================
;=============================================================================



;_____________________________________________________________________________
;
				SmellsLikeAFileDialog(_thisID )
;_____________________________________________________________________________
;
{

;	Only consider this dialog a possible file-dialog when:
;	(SysListView321 AND ToolbarWindow321) OR (DirectUIHWND1 AND ToolbarWindow321) controls detected
;	First is for Notepad++; second for all other filedialogs
;	That is our rough detection of a File dialog. Returns 1 or 0 (TRUE/FALSE)

	WinGet, _controlList, ControlList, ahk_id %_thisID%

	Loop, Parse, _controlList, `n
	{
		If ( A_LoopField = "SysListView321"  )
			_SysListView321 := 1

		If ( A_LoopField = "ToolbarWindow321")
			_ToolbarWindow321 := 1

		If ( A_LoopField = "DirectUIHWND1"   ) 
			_DirectUIHWND1 := 1

		If ( A_LoopField = "Edit1"   ) 
			_Edit1 := 1
	}


	If ( _DirectUIHWND1 and _ToolbarWindow321 and _Edit1 ) 
	{
		Return "GENERAL"

	}
	Else If ( _SysListView321 and _ToolbarWindow321 and _Edit1 ) 
	{
		Return "SYSLISTVIEW"
	}
	else
	{
		Return FALSE
	}

}


;_____________________________________________________________________________
;
				FeedDialogGENERAL( _thisID, _thisFOLDER )
;_____________________________________________________________________________
;    
{
	Global $DialogType

	WinActivate, ahk_id %_thisID%

;MsgBox FeedDialogGENERAL	
	WinGet, ActivecontrolList, ControlList, ahk_id %_thisID%


	Loop, Parse, ActivecontrolList, `n
	{
		If InStr(A_LoopField, "ToolbarWindow32")
		{
		;	ControlGetText _thisToolbarText , %A_LoopField%, ahk_id %_thisID%
			ControlGet, _CtrlHandle, Hwnd,, %A_LoopField%, ahk_id %_thisID%

		;	Get handle of parent control
			_parentHandle := DllCall("GetParent", "Ptr", _CtrlHandle)

		;	Get class of parent control
			WinGetClass, _parentClass, ahk_id %_parentHandle%

			If ( _parentClass = "Breadcrumb Parent" )
				_useToolbar := A_LoopField

			If ( _parentClass = "msctls_progress32" )
				_EnterToolbar := A_LoopField
		}
	}


	If ( _useToolbar AND _EnterToolbar )
	{
;MsgBox Controls OK _thisFOLDER = %_thisFOLDER%
	;	Click address toolbar until Edit 2 visible. Fill Edit 2 with new folder	
		Loop, 50
		{
			ControlGet, _ToolbarVisible, Visible, , %_useToolbar%, ahk_id %_thisID%

			sleep, 10
			If (_ToolbarVisible)
			{
			;	Toolbar_attempts := A_Index
				ControlClick, %_useToolbar%, ahk_id %_thisID%, , , 2, X7 Y7
				Sleep, 10
			}
			Else			; Edit2 visible?
			{
				ControlGet, _Edit2Visible, Visible, , Edit2, ahk_id %_thisID%
				Sleep, 10

				If (_Edit2Visible)
				{
					ControlSetText, Edit2, %_thisFOLDER%, ahk_id %_thisID%
					Sleep, 10
					ControlGetText, _Edit2, Edit2, ahk_id %_thisID%
					If (_Edit2 = _thisFOLDER )
					{
						_FolderSet := TRUE
					}
				}
			} 

		}	Until _FolderSet

	;	Click control to "execute" new folder	
		ControlClick, %_EnterToolbar%, ahk_id %_thisID%

	;	Focus file name
		Sleep, 15
		ControlFocus Edit1, ahk_id %_thisID%

	}
	else ; unsupported dialog. At least one of the needed controls is missing
	{
		MsgBox This type of dialog can not be handled (yet).`nPlease report it!
	}


;	Clean up; probably not needed
	ActivecontrolList	:= ""
	_CtrlHandle			:= ""
	_parentHandle		:= ""
	_parentClass		:= ""
	_useToolbar			:= ""
	_EnterToolbar		:= ""
	_ToolbarVisible	:= ""
	_Edit2Visible		:= ""
	_Edit2				:= ""
	_FolderSet			:= ""


Return
}





;_____________________________________________________________________________
;
				FeedDialogSYSLISTVIEW( _thisID, _thisFOLDER )
;_____________________________________________________________________________
;    
{
	Global $DialogType

	WinActivate, ahk_id %_thisID%
;	Sleep, 50


;	Read the current text in the "File Name:" box (= $OldText)

	ControlGetText _oldText, Edit1, ahk_id %_thisID%
	Sleep, 20


;	Make sure there exactly 1 \ at the end.

	_thisFOLDER := RTrim( _thisFOLDER , "\")
	_thisFOLDER := _thisFOLDER . "\"

	Loop, 20
	{
		Sleep, 10
		ControlSetText, Edit1, %_thisFOLDER%, ahk_id %_thisID%
		ControlGetText, _Edit1, Edit1, ahk_id %_thisID%
		If ( _Edit1 = _thisFOLDER )
			_FolderSet := TRUE

	} Until _FolderSet

	If _FolderSet
	{
		Sleep, 20
		ControlFocus Edit1, ahk_id %_thisID%
		ControlSend Edit1, {Enter}, ahk_id %_thisID%



	;	Restore  original filename / make empty in case of previous folder

		Sleep, 15

		ControlFocus Edit1, ahk_id %_thisID%
		Sleep, 20

		Loop, 5
		{
			ControlSetText, Edit1, %_oldText%, ahk_id %_thisID%		; set
			Sleep, 15
			ControlGetText, _2thisCONTROLTEXT, Edit1, ahk_id %_thisID%		; check
			If ( _2thisCONTROLTEXT = _oldText )
				Break
		}
	}
Return
}





;_____________________________________________________________________________
;
				ShowMenu()
;_____________________________________________________________________________
;
{

	Global $DialogType
	Global $DialogAction
	
	_showMenu := 0

;	---------------[ Title BAr ]--------------------------------------
	Menu ContextMenu, Add,  QuickSwitch Menu, Dummy
	Menu ContextMenu, Default,  QuickSwitch Menu
	Menu ContextMenu, disable, QuickSwitch Menu



	WinGet, _allWindows, list
	Loop, %_allWindows%
	{
		_thisID := _allWindows%A_Index%
		WinGetClass, _thisClass, ahk_id %_thisID%

	;---------------[ Total Commander Folders]--------------------------------------

		If ( _thisClass = "TTOTAL_CMD")
		{
		;	Get Process information for TC icon
			WinGet, _thisPID, PID, ahk_id %_thisID%
			_TC_exe := GetModuleFileNameEx( _thisPID )

			ClipSaved := ClipboardAll
			Clipboard := ""

			SendMessage 1075, %cm_CopySrcPathToClip%, 0, , ahk_id %_thisID%

		;	Check if valid folder first. Only add it if it is.
			If (ErrorLevel = 0) AND ( ValidFolder( clipboard ) )
			{	
				Menu ContextMenu, Add,  %clipboard%, FolderChoice
				Menu ContextMenu, Icon, %clipboard%, %_TC_exe%,0, 32
				_showMenu := 1
	
			}

			SendMessage 1075, %cm_CopyTrgPathToClip%, 0, , ahk_id %_thisID%

			If (ErrorLevel = 0) AND ( ValidFolder( clipboard ) )
			{
				Menu ContextMenu, Add,  %clipboard%, FolderChoice
				Menu ContextMenu, Icon, %clipboard%, %_TC_exe%,0,32
				_showMenu := 1
			}


			Clipboard := ClipSaved
			ClipSaved := ""
		}


	;---------------[ XYPlorer               ]--------------------------------------

		If ( _thisClass = "ThunderRT6FormDC")
		{
		;	Get Process information for TC icon
			WinGet, _thisPID, PID, ahk_id %_thisID%
			_XYPlorer_exe := GetModuleFileNameEx( _thisPID )

			ClipSaved := ClipboardAll
			Clipboard := ""

			Send_XYPlorer_Message(_thisID, "::copytext get('path', a);")

		;	Check if valid folder first. Only add it if it is.
			If (ErrorLevel = 0) AND ( ValidFolder( clipboard ))
			{
				Menu ContextMenu, Add,  %clipboard%, FolderChoice
				Menu ContextMenu, Icon, %clipboard%, %_XYPlorer_exe%,0, 32
				_showMenu := 1
			}

			Send_XYPlorer_Message(_thisID, "::copytext get('path', i);")

			If (ErrorLevel = 0) AND ( ValidFolder( clipboard ))
			{
				Menu ContextMenu, Add,  %clipboard%, FolderChoice
				Menu ContextMenu, Icon, %clipboard%, %_XYPlorer_exe%,0,32
				_showMenu := 1
			}


			Clipboard := ClipSaved
			ClipSaved := ""
		}

	;---------------[ File Explorer Folders ]----------------------------------------


		If ( _thisClass = "CabinetWClass")
		{
			For _Exp in ComObjCreate("Shell.Application").Windows	
			{
				If ( _thisID = _Exp.Hwnd)
				{
					_thisExplorerPath := _Exp.Document.Folder.Self.Path

				;	Check if valid folder first. Don't add it if not.
					If ( ValidFolder(_thisExplorerPath))
					{
						Menu ContextMenu, Add,  %_thisExplorerPath%, FolderChoice
						Menu ContextMenu, Icon, %_thisExplorerPath%, shell32.dll, 5,32
						_showMenu := 1
					}
				}
			}
		}
	}	; end loop parsing all windows to find file manager folders

;	All windows have been checked for valid File Manager folders
;	Most recent used filemanager will be shown on top. 
;	If no folders found to be shown: no need to show menu ...

	
	If ( _showMenu = 1 )
	{


	;---------------[ Settings ]----------------------------------------

		Menu ContextMenu, Add,
		Menu ContextMenu, Add, Settings for this dialog, Dummy
		Menu ContextMenu, disable, Settings for this dialog

		Menu ContextMenu, Add,  Allow AutoSwitch, AutoSwitch, Radio
		Menu ContextMenu, Add,  Never here, Never, Radio
		Menu ContextMenu, Add,  Not now, ThisMenu, Radio


	;	Activate radiobutton for current setting (depends on INI setting)
	;	Only show AutoSwitchException if AutoSwitch is activated.

		If ($DialogAction = 1)
		{
			Menu ContextMenu, Check, Allow AutoSwitch
			Menu ContextMenu, Add,  AutoSwitch exception, AutoSwitchException
		}
		Else If ($DialogAction = 0)
		{
			Menu ContextMenu, Check, Never here
		}
		Else
		{
			Menu ContextMenu, Check, Not now
		}
		


	;---------------[ Show ]----------------------------------------

	;	Menu ContextMenu, Standard
	;	BAckup to prevent errors
	
		Menu ContextMenu, UseErrorLevel

		Menu ContextMenu, Color, C0C59C

		Menu ContextMenu, Show, 100,100
		Menu ContextMenu, Delete

		show_menu := 0

	}
	else
	{
		Menu ContextMenu, Delete
	}


Return
}



;_____________________________________________________________________________
;
				FolderChoice:
;_____________________________________________________________________________
;

	Global $DialogType
;MsgBox FolderChoice $DialogType %$DialogType%  Folder %A_ThisMenuItem%
	If ValidFolder( A_ThisMenuItem )
	{ 
	;	FeedDialog($WinID, $FolderPath)
		FeedDialog%$DialogType%($WinID, A_ThisMenuItem)
	}
		
Return


;_____________________________________________________________________________
;
				AutoSwitch:
;_____________________________________________________________________________
;
	Global $DialogType

	IniWrite, 1, %$INI%, Dialogs, %$FingerPrint%

	$DialogAction := 1

	$FolderPath := Get_Zfolder($WinID)
;	MsgBox FolderPath = %$FolderPath%

	If ( ValidFolder( $FolderPath ))
	{ 
	;	FeedDialog($WinID, $FolderPath)
		FeedDialog%$DialogType%($WinID, $FolderPath)
	}

Return



;_____________________________________________________________________________
;
				Never:
;_____________________________________________________________________________
;

	IniWrite, 0, %$INI%, Dialogs, %$FingerPrint%

	$DialogAction := 0

Return



;_____________________________________________________________________________
;
				ThisMenu:
;_____________________________________________________________________________
;

	IniDelete, %$INI%, Dialogs, %$FingerPrint%

	$DialogAction := ""

Return

;_____________________________________________________________________________
;
				AutoSwitchException:
;_____________________________________________________________________________
;
	Global $DialogType


	MsgBox, 1, AutoSwitch Exceptions,
	(

  For AutoSwitch to work, typically a file manager is "2 windows away" :
  Dialog ==> Aapplication ==> File manager.

  If AutoSwitch doesn't work as expected, the application might have 
  created extra (possibly hidden) windows
  Example: Dialog ==> Task Manager Run new task ==> Task Manager
  ==> File manager.


  To support these dialogs too:
  - Click Cancel in this Dialog
  - Alt-Tab to the file manager
  - Alt-Tab back to the file dialog
  - Press Control-Q
  - Select AutoSwitch Exception
  - Press OK


  The correct number of "windows away" will be detected and shown
  If these values are accepted, an exception will be added for this dialog.

  - Press OK if all looks OK
    (most common exception is 3; default is 2)
	
	)
	
	IfMsgBox OK
	{
	
;		Header for list
		Gui, Add, ListView, r30 w1024, Nr|ID|Window Title|program|Class

		WinGet, id, list

		Loop, %id%
		{
			this_id := id%A_Index%

			WinGetClass, this_class, ahk_id %this_id%
			WinGet, this_exe, ProcessName, ahk_id %this_id%
			WinGetTitle, this_title , ahk_id %this_id%
			
			If ( this_id = $WinID )
			{
				$select := "select"
				level_1 := A_Index
				Z_exe		:= this_exe
				Z_title	:= this_title
			}

			If (NOT level_2) AND ( ( this_class = "TTOTAL_CMD" ) OR ( this_class = "CabinetWClass" ) OR ( this_class = "ThunderRT6FormDC" ))
			{
				$select	:= "select"
				level_2	:= A_Index
			}
			
			LV_Add( $select, A_Index, This_id, this_title, this_exe, this_class )
			$select := ""
		}


		Delta := level_2 - level_1
		LV_ModifyCol()  ; Auto-size each column to fit its contents.
		LV_ModifyCol(1, "Integer")  ; For sorting purposes, indicate that column 1 is an integer.

		Gui, Show

	;	Handle case when no file manager found (no Level2)
		MsgBox, 1, "File manager found ..", It looks like the filemanager is %Delta% levels away `n(default = 2)`n`nMAke this the new default for this specific dialog window?

		IfMsgBox OK
		{
			If ( Delta =  2 )
			{
				IniDelete, %$INI%, AutoSwitchException, %$FingerPrint%

			} Else
			{
				IniWrite, %Delta%,		%$INI%, AutoSwitchException, %$FingerPrint%
			}

		;	After INI was updated: try to AutoSwich straight away ..
				
			$FolderPath := Get_Zfolder($WinID)

			If ( ValidFolder( $FolderPath ))
			{ 
			;	FeedDialog($WinID, $FolderPath)
				FeedDialog%$DialogType%($WinID, $FolderPath)
			}
		}

		
		GUI, Destroy
		id := ""
		this_class := ""
		this_exe := ""
		this_id := ""
		this_title := ""
		$select := ""
		level_1 := ""
		Z_exe		:= ""
		Z_title	:= ""
		level_2 := ""
		Delta := ""
		$select := ""

	}

Return



;_____________________________________________________________________________
;
				Dummy:
;_____________________________________________________________________________
;

Return



;_____________________________________________________________________________
;
				ValidFolder(_thisPath_)
;_____________________________________________________________________________
;
{
;	Prepared for extra checks
;	If ( _thisPath_ != "") {
	If ( _thisPath_ != ""  AND (StrLen(_thisPath_) < 259 ))
	{
		If InStr(FileExist(_thisPath_), "D")
			Return TRUE
		Else
			Return FALSE
	}
	Else
	{
		Return FALSE
	}
}

;_____________________________________________________________________________
;
				Get_Zfolder( _thisID_ )
;_____________________________________________________________________________
;
{
;	Get z-order of all applicatiions.
;	When "our" ID is found: save z-order of "the next one"
;	Actualy: The next-next one as the next one is the parent-program that opens the dialog (e.g. notepad )
;	if the next-next one is a file mananger (Explorer class = CabinetWClass ; TC = TTOTAL_CMD),
;	read the active folder and browse to it in the dialog.
;	Exceptions are in INI section [AutoSwitchException]

;MsgBox Get_Zfolder $DialogType %$DialogType%

	Global $FingerPrint
	Global $INI
	
;	Read Z-Order for this application (based on $Fingerprint) 
;	from INI section [AutoSwitchException]
;	If not found, use default ( = 2)

	IniRead, _zDelta, %$INI%, AutoSwitchException, %$FingerPrint%, 2

	WinGet, id, list

		Loop, %id%
		{
			this_id := id%A_Index%
			If ( _thisID_ = this_id )
			{
				this_z := A_Index
				Break
			}
		}

		$next := this_z + _zDelta
		next_id := id%$next%
		WinGetClass, next_class, ahk_id %next_id%


		If ( next_class = "TTOTAL_CMD") 							;	Total Commander
		{
			ClipSaved := ClipboardAll
			Clipboard := ""

			SendMessage 1075, %cm_CopySrcPathToClip%, 0, , ahk_id  %next_id%

			If (ErrorLevel = 0)
			{

				$ZFolder := clipboard
				Clipboard	:= ClipSaved
			}
		}


		If ( next_class = "ThunderRT6FormDC") 							;	XYPlorer
		{
			ClipSaved := ClipboardAll
			Clipboard := ""

			Send_XYPlorer_Message( next_id, "::copytext get('path', a);")
			ClipWait,0

			$ZFolder := clipboard
			Clipboard	:= ClipSaved
		}

			
		If ( next_class = "CabinetWClass") 						;	File Explorer
		{
			For $Exp in ComObjCreate("Shell.Application").Windows
			{
				if ( $Exp.hwnd = next_id )
				{
					$ZFolder := $Exp.Document.Folder.Self.Path
					Break
				}
			}
		}

	Return $ZFolder
}



;_____________________________________________________________________________
;
				GetModuleFileNameEx( p_pid )
;_____________________________________________________________________________
;
;	From: https://autohotkey.com/board/topic/32965-getting-file-path-of-a-running-process/
;	NotNull: changed "GetModuleFileNameExA" to "GetModuleFileNameExW""

{
	
	h_process := DllCall( "OpenProcess", "uint", 0x10|0x400, "int", false, "uint", p_pid )
	if ( ErrorLevel or h_process = 0 )
	  return

	name_size = 255
	VarSetCapacity( name, name_size )

	result := DllCall( "psapi.dll\GetModuleFileNameExW", "uint", h_process, "uint", 0, "str", name, "uint", name_size )

	DllCall( "CloseHandle", h_process )

	return, name
}




;_____________________________________________________________________________
;
				Send_XYPlorer_Message(xyHwnd, message)
;_____________________________________________________________________________
;

{
	size := StrLen(message)
	If !(A_IsUnicode)
	{
		VarSetCapacity(data, size * 2, 0)
		StrPut(message, &data, "UTF-16")
	} Else
	{
		data := message
	}

	VarSetCapacity(COPYDATA, A_PtrSize * 3, 0)
	NumPut(4194305, COPYDATA, 0, "Ptr")
	NumPut(size * 2, COPYDATA, A_PtrSize, "UInt")
	NumPut(&data, COPYDATA, A_PtrSize * 2, "Ptr")
	result := DllCall("User32.dll\SendMessageW", "Ptr", xyHwnd, "UInt", 74, "Ptr", 0, "Ptr", &COPYDATA, "Ptr")
Return
}





/*
============================================================================




ValidFolder routine

	Bepaal folderlengte
	ALs lengte > 254?
	begint met X:\ ?  		==>  \\?\X:\
	begint met \\server ?	==>  \\?\UNC\server
	? wat als al win32 pad aangeleverd wordt? Check op \\?\ en \\.\

	Dit is noodzakelijk omdat de FileExist functie van AHK geen lange DOS-paden ondersteunt
	Anders werkt ValidFolder() niet!
	Check Nieuwe \\?\ pad



FeedDialog routine

	Als "SaveAs"
	  Doe nix. SaveAs accepteert "gewoon" lange paden, zonder conversoie naar \\?\C:\... of "\\?\UNC\server\share"
	  Gewone feed. KLOPT DAT???
		
	Als Notepad++ (SyslistView)
		check folderlengte. Als <= 254 : gewone feed
		Als > 254:
			converteer naar SFN
			Als SFN > 254
				MsgBox PAd te lang voor dit type dialoog
			Anders 
				feed
	
	? Moet dat eerst weer naar \\ syntax omgesmurfd worden voordat SFN bepaald kan worden?



2DO Priority

- naming structure of variables 
- TEST !!!
- New menu /UI (no inspiration yet on how that should look ..)
- Support paths > 259 ? (max length menu text = 260, so requirea a new menu) 
? Add menu: debugging > list all controls (+text)?
? Pre-fill [AutoSwitchException] If values don't exist
  (taskmgr, pspad, etc. Will be depending on localization
  Open, Öffnen, Ouvrir, etc. MAybe only English? )


2021-03-16
V Code cleanup/restructure
V work out all 2do entries in code.



2021-03-14
V change menu folder order from fixed (TC > XY > Explorer) to most recent first.
V Bug!! AotoSwitch/Never/Not Now/ radio buttons.
V Long paths are skipped (for now; prevents error/crash)
V Add "exception-detector" (Z=3)
V AutoSwitch after added exception


2021-03-10
V Replace search for text with detect parent for ToolbarWindow32 controls (turnned out this system text was localized)
V Fix KArl's issues (can't test all)


2021-03-03
V Only activate hotkey in 'real' file dialogs
V Use NotapadSaveAs method for all windows except Notepad++ (syslistview)
V SmellsLikeAFileDialog returns exact DialogType to be used later on (or FALSE If undetected).
V Replace all A with AHK_id %%



 2DO
X Add menu: debugging > z-order? (part of AutoSwitchException routine now)
V Combineer FeedExplorer en FeedNotepad tot 1 routine.
V Maak daar een functie van: FeedDialog(WinID, folder)
V Roep FeedDialog(selecteditem) aan vanuit FolderChoice
V Get_Zfolder(), maar dan zonder de cm_CopySrcPathToClip iets met Global)
V Support for XYPlorer:
V Function SmellsLikeAFileDialog($WinID)
V  In File Dialog, analyze all Toolbarwindow32* and search for text "<Address> c:\..."
  That is the Toolbar to click when in "NotepadSaveAs mode" (now hardcoded ToolbarWindow324)
V Include [Z-order] INI-section:
  Default=2
  pspad.exe___Open=3 ($FingerPrint = 3)
  ? Or .... Try 2. If found TTOLALCMD / Explorer / XYPLorer: use that If not: try 3.
  ! No, might give unwanted folderchange
V FeedDialog NotepadSaveAs in a loop: change folder => check => repeat If needed
  If check is false, don't switch folders
V Optimize timings (currently quite slow)
  No longer needed, thanks to repeat/loop

- Hotkey variabel maken (nu overal Ctrl-Q gedefinieerd)
- Vervang GetModuleFileNameEx door ahk internal functie 
  (WinGet, OutputVar, ProcessPath [)
- When no INI: create these entries.
- Check all functions on return value.
- Try to make path entering less "blinking" (fill (hidden) edit first)
- TEST
? Keep dialog-list in memory. Re-read when changes are made.
? Own copy of file manager icons? (instead of reading exe)
? Lees huidige folder. Als gelijk aan switchfolder: doe nix
X SpeedTest on first run? (to get sensitive timings right (no longer needed)



Known limitations (at this moment)
- Long paths (>=255) not supported. Limitation of [1] Menu entry length and [2] File Dialog.
  Found a solution for (2) for 'normal' dialogs; halfway workaround for syslistview dialogs
- 

- PSPad behaves different with AutoSwitch:
  When last program = filemanager, run PSPad > File Open (/save/..) no Autoswitch. (z-order = 3)
  Alt-Tab to filemanager and back: AutoSwitch. (z-order = 2)
  PSPad puts an extra windows in between.
  Can make both of these scenarios work, but not at the same time.
  Choice: Activated through Alt-Tab. (z-order = 2)

- 

Known Bugs:
V FeedDialog Notepad SaveAs vanuit FolderChoice wiebelig ..
V $DialogAction is niet bekend binnen ShowMenu
V Is $Fingerprint wel bekend in Menu? (tbv AutoSwitch/ Never here etc.)
- 


============================================================================
*/

