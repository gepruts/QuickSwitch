$ThisVersion := "0.5"

;@Ahk2Exe-SetVersion 0.5
;@Ahk2Exe-SetName QuickSwitch
;@Ahk2Exe-SetDescription Use opened file manager folders in File dialogs.
;@Ahk2Exe-SetCopyright NotNull

/*
By		: NotNull
Info	: https://www.voidtools.com/forum/viewtopic.php?f=2&t=9881
*/

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


;	Path to tempfilefor Directory Opus
	EnvGet, _tempfolder, TEMP
	_tempfile := _tempfolder . "\dopusinfo.xml"
	FileDelete, %_tempfile%



;_____________________________________________________________________________
;
;					ACTION!
;_____________________________________________________________________________
;

;	Check if Win7 or higher; if not: exit

;	If !(RegExMatch(A_OSVersion, "^10\."))
;WIN_7,WIN_8,WIN_8.1,WIN_VISTA,WIN_2003,WIN_XP,WIN_2000

	If A_OSVersion in WIN_VISTA,WIN_2003,WIN_XP,WIN_2000
	{
		MsgBox %A_OSVersion% is not supported.
		ExitApp
	}



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

	sleep 50

;	Focus Edit1
	ControlFocus Edit1, ahk_id %_thisID%

	WinGet, ActivecontrolList, ControlList, ahk_id %_thisID%


	Loop, Parse, ActivecontrolList, `n	; which addressbar and "Enter" controls to use 
	{
		If InStr(A_LoopField, "ToolbarWindow32")
		{
		;	ControlGetText _thisToolbarText , %A_LoopField%, ahk_id %_thisID%
			ControlGet, _ctrlHandle, Hwnd,, %A_LoopField%, ahk_id %_thisID%

		;	Get handle of parent control
			_parentHandle := DllCall("GetParent", "Ptr", _ctrlHandle)

		;	Get class of parent control
			WinGetClass, _parentClass, ahk_id %_parentHandle%

			If InStr( _parentClass, "Breadcrumb Parent" )
			{
				_UseToolbar := A_LoopField
			}

			If Instr( _parentClass, "msctls_progress32" )
			{
				_EnterToolbar := A_LoopField
			}	
		}

	;	Start next round clean
		_ctrlHandle			:= ""
		_parentHandle		:= ""
		_parentClass		:= ""
	
	}

	If ( _UseToolbar AND _EnterToolbar )
	{
		Loop, 5
		{
			SendInput ^l
			sleep 100

		;	Check and insert folder
			ControlGetFocus, _ctrlFocus,A

			If ( InStr( _ctrlFocus, "Edit" ) AND ( _ctrlFocus != "Edit1" ) )
			{
				Control, EditPaste, %_thisFOLDER%, %_ctrlFocus%, A
				ControlGetText, _editAddress, %_ctrlFocus%, ahk_id %_thisID%
				If (_editAddress = _thisFOLDER )
				{
					_FolderSet := TRUE
				}
			}
		;	else: 	Try it in the next round

		;	Start next round clean
			_ctrlFocus := ""
			_editAddress := ""

		}	Until _FolderSet


		
		If (_FolderSet)
		{
		;	Click control to "execute" new folder	
			ControlClick, %_EnterToolbar%, ahk_id %_thisID%

		;	Focus file name
			Sleep, 15
			ControlFocus Edit1, ahk_id %_thisID%
		}
		Else
		{
		;	What to do if folder is not set?
		}
	}
	Else ; unsupported dialog. At least one of the needed controls is missing
	{
		MsgBox This type of dialog can not be handled (yet).`nPlease report it!
	}


;	Clean up; probably not needed

	_UseToolbar := ""
	_EnterToolbar := ""
	_editAddress := ""
	_FolderSet := ""
	_ctrlFocus := ""


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
	Global _tempfile
	
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

	;---------------[ Directory Opus         ]--------------------------------------

		If ( _thisClass = "dopus.lister")
		{
		;	Get Process information for Opus icon
			WinGet, _thisPID, PID, ahk_id %_thisID%
			_dopus_exe := GetModuleFileNameEx( _thisPID )


			If !(OpusInfo)
			{
			;	Comma needs escaping: `,
				Run, "%_dopus_exe%\..\dopusrt.exe" /info "%_tempfile%"`,paths,,, $DUMMY
						
				Sleep, 100
				FileRead, OpusInfo, %_tempfile%
				
				Sleep, 20
				FileDelete, %_tempfile%


			}


			;	Get active path of this lister (regex instead of XML library)
				RegExMatch(OpusInfo, "mO)^.*lister=\""" . _thisID . "\"".*tab_state=\""1\"".*\>(.*)\<\/path\>$", out)
				_thisFolder := out.Value(1)
				
			;	Check if valid folder first. Only add it if it is.
				If ValidFolder( _thisFolder )
				{
					Menu ContextMenu, Add,  %_thisFolder%, FolderChoice
					Menu ContextMenu, Icon, %_thisFolder%, %_dopus_exe%,0, 32
					_showMenu := 1
				}
				_thisFolder := ""


			;	Get passive path of this lister
				RegExMatch(OpusInfo, "mO)^.*lister=\""" . _thisID . "\"".*tab_state=\""2\"".*\>(.*)\<\/path\>$", out)
				_thisFolder := out.Value(1)
				
			;	Check if valid folder first. Only add it if it is.
				If ValidFolder( _thisFolder )
				{
					Menu ContextMenu, Add,  %_thisFolder%, FolderChoice
					Menu ContextMenu, Icon, %_thisFolder%, %_dopus_exe%,0, 32
					_showMenu := 1
				}
				_thisFolder := ""

		}

	;---------------[ File Explorer Folders ]----------------------------------------


		If ( _thisClass = "CabinetWClass")
		{
			For _Exp in ComObjCreate("Shell.Application").Windows
			{
				try  ; Attempts to execute code.
				{
					_checkID := _Exp.hwnd
				}
				catch e  ; Handles the errors that Opus will generate.
				{
					; Do nothing. Just ignore error.
					; Proceed to the next Explorer instance
				}

				If ( _thisID = _checkID )
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
				_checkID := ""
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


		Menu ContextMenu, Add,  Debug this dialog, Debug_Controls		


	;---------------[ Show ]----------------------------------------

	;	Menu ContextMenu, Standard
	;	BAckup to prevent errors
	
		Menu ContextMenu, UseErrorLevel

		Menu ContextMenu, Color, C0C59C

		Menu ContextMenu, Show, 100,100
		Menu ContextMenu, Delete

	}
	else
	{
		Menu ContextMenu, Delete
	}
	
;	Delete _tempfile	


Return
}



;_____________________________________________________________________________
;
				FolderChoice:
;_____________________________________________________________________________
;
{
	Global $DialogType
	If ValidFolder( A_ThisMenuItem )
	{ 
	;	FeedDialog($WinID, $FolderPath)
		FeedDialog%$DialogType%($WinID, A_ThisMenuItem)
	}
		
Return
}

;_____________________________________________________________________________
;
				AutoSwitch:
;_____________________________________________________________________________
;
	Global $DialogType

	IniWrite, 1, %$INI%, Dialogs, %$FingerPrint%

	$DialogAction := 1

	$FolderPath := Get_Zfolder($WinID)

	If ( ValidFolder( $FolderPath ))
	{ 
	;	FeedDialog($WinID, $FolderPath)
		FeedDialog%$DialogType%($WinID, $FolderPath)
	}
	
	$FolderPath := ""
	

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
  File manager ==> Aapplication ==> Dialog.
  AutoSwitch uses that fore deteceting when to switch folders. 

  If AutoSwitch doesn't work as expected, the application might have 
  created extra (possibly even hidden) windows
  Example: File manager==> Task Manager ==> Run new task ==> Browse
  ==> Dialog .


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
				IniDelete, 	%$INI%, AutoSwitchException, %$FingerPrint%

			} Else
			{
				IniWrite, %Delta%, %$INI%, AutoSwitchException, %$FingerPrint%
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


	Global $FingerPrint
	Global $INI
	Global _tempfile
	
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


	If ( next_class = "TTOTAL_CMD" ) 							;	Total Commander
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


	If ( next_class = "ThunderRT6FormDC" ) 						;	XYPlorer
	{
		ClipSaved := ClipboardAll
		Clipboard := ""

		Send_XYPlorer_Message( next_id, "::copytext get('path', a);")
		ClipWait,0

		$ZFolder := clipboard
		Clipboard	:= ClipSaved
	}

		
	If ( next_class = "CabinetWClass" ) 							;	File Explorer
	{
		For $Exp in ComObjCreate("Shell.Application").Windows
		{
			try  ; Attempts to execute code.
			{
				_checkID := $Exp.hwnd
			}
			catch e  ; Handles the errors that Opus will generate.
			{
				; Do nothing. Just ignore error.
				; Proceed to the next Explorer instance
			}

;		if ( $Exp.hwnd = next_id )
			if ( next_id = _checkID )
			{
				$ZFolder := $Exp.Document.Folder.Self.Path
				Break
			}
		}
	}


	If ( next_class = "dopus.lister" )							;	Directory Opus
	{
	;	Get dopus.exe loction
		WinGet, _thisPID, PID, ahk_id %next_id%
		_dopus_exe := GetModuleFileNameEx( _thisPID )


	;	Get lister info
		Run, "%_dopus_exe%\..\dopusrt.exe" /info "%_tempfile%"`,paths,,, $DUMMY
		
		Sleep, 100
		
		FileRead, OpusInfo, %_tempfile%
		
		Sleep, 20
		FileDelete, %_tempfile%

	;	Get active path of the most recent lister
		RegExMatch(OpusInfo, "mO)^.*lister=\""" . next_id . "\"".*tab_state=\""1\"".*\>(.*)\<\/path\>$", out)
		$ZFolder := out.Value(1)
;		MsgBox Active Z-folder = [%$ZFolder%]

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





;_____________________________________________________________________________
;
				Debug_Controls:
;_____________________________________________________________________________
;




; Add ControlGetPos [, X, Y, Width, Height, Control, WinTitle, WinText, ExcludeTitle, ExcludeText]
; change folder to ahk folder. change name to fingerpringt.csv


	SetFormat, Integer, D
;	Header for list
	Gui, Add, ListView, r30 w1024, Control|ID|PID||Text|X|Y|Width|Height

;	Loop through controls
	WinGet, ActivecontrolList, ControlList, A

	Loop, Parse, ActivecontrolList, `n
	{
	;	Get ID
		ControlGet, _ctrlHandle, Hwnd,, %A_LoopField%, A

	;	Get Text
		ControlGetText _ctrlText ,, ahk_id %_ctrlHandle%

	;	Get control coordinates
		ControlGetPos _X, _Y, _Width, _Height, , ahk_id %_ctrlHandle%
	;	Get PID
		_parentHandle := DllCall("GetParent", "Ptr", _ctrlHandle)

	;	Add to listview ; abs for hex to dec
		LV_Add(, A_LoopField, abs(_ctrlHandle), _parentHandle, _ctrlText, _X, _Y, _Width, _Height  )


		_ctrlHandle := ""
		_ctrlText := ""
		_parentHandle := ""
		_X := ""
		_Y := ""
		_Width := ""
		_Height := ""

	}

	LV_ModifyCol()  ; Auto-size each column to fit its contents.
	LV_ModifyCol(2, "Integer")
	LV_ModifyCol(3, "Integer")


	Gui, Add, Button, y+10 w100 h30 gDebugExport, Export 
	Gui, Add, Button, x+10 w100 h30 gCancelLV, Cancel 

	Gui, Show

return



;_____________________________________________________________________________
;
				DebugExport:
;_____________________________________________________________________________
;

	_fileName :=  A_ScriptDir . "\" . $FingerPrint . ".csv"
	oFile := FileOpen(_fileName, "w")   ; Creates a new file, overwriting any existing file.
	If (IsObject(oFile))
	{
	;	Header
		_line := "ControlName;ID;PID;Text;X;Y;Width;Height"

		oFile.WriteLine(_line)

		Gui, ListView
		Loop % LV_GetCount()
		{
			LV_GetText(_col1, A_index, 1)
			LV_GetText(_col2, A_index, 2)
			LV_GetText(_col3, A_index, 3)
			LV_GetText(_col4, A_index, 4)
			LV_GetText(_col5, A_index, 5)
			LV_GetText(_col6, A_index, 6)
			LV_GetText(_col7, A_index, 7)
			LV_GetText(_col8, A_index, 8)
			_line := _col1 ";" _col2 "," _col3 ";" _col4 ";" _col5 ";" _col6 ";" _col7 ";" _col8 ";"
			oFile.WriteLine(_line)
		}

		oFile.Close()
		oFile:=""

		Msgbox Results exported to:`n`n"%_filename%"

	}
	Else						; File could not be initialized
	{
		Msgbox Can't create %_fileName%
	}



;	Clean up
	_fileName := ""
	_line := ""
	_col1 := ""
	_col2 := ""
	_col3 := ""
	_col4 := ""
	_col5 := ""
	_col6 := ""
	_col7 := ""
	_col8 := ""

;_____________________________________________________________________________
				CancelLV:
;_____________________________________________________________________________

		LV_Delete()
		GUI, Destroy

Return


/*
============================================================================
*/
