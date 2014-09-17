{
   fpGUI  -  Free Pascal GUI Toolkit

   Copyright (C) 2006 - 2010 See the file AUTHORS.txt, included in this
   distribution, for details of the copyright.

   See the file COPYING.modifiedLGPL, included in this distribution,
   for details about redistributing fpGUI.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

   Description:
     AROS target implementation: Keycode translation helpers
}

{%mainunit fpg_aros.pas}

function RawKeyToKeycode(RawKey: Byte): Word;
const
  TranslTable: array[Byte] of Integer = (
    -1,		// $00  
    $31,		// $01  1
    $32,		// $02  2
    $33,		// $03  3
    $34,		// $04  4
    $35,		// $05  5
    $36,		// $06  6
    $37,		// $07  7
    $38,		// $08  8
    $39,		// $09  9
    $30,		// $0a  0
    -1,			// $0b
    keyClear,		// $0c  
    keyReturn,		// $0d
    -1,			// $0e
    -1,			// $0f
    -1,		// $10  
    -1,		        // $11  
    Ord('e'),		// $12  e
    -1,		        // $13  
    -1,			// $14  
    -1,			// $15  
    -1,			// $16
    -1,			// $17  
    -1,			// $18  
    -1,			// $19  
    -1,			// $1a
    keyEscape,		// $1b  
    -1,			// $1c  
    -1,			// $1d  
    -1,			// $1e  
    keyModeSwitch,	// $1f  
    Ord('a'),		// $20  a
    keyPrior,		// $21  
    Ord('d'),		// $22  d
    -1,                 // $23  
    -1,		        // $24  
    -1,		        // $25  
    -1,		        // $26  
    -1,		        // $27  
    -1,		        // $28  
    keySelect,		// $29  
    keyPrintScreen,	// $2a  
    keyExecute,		// $2b  
    keyPrintScreen,	// $2c  
    keyInsert,		// $2d  
    keyDelete,		// $2e  
    keyHelp,		// $2f  
    $30,		// $30  
    $31,		// $31  
    $32,		// $32  
    Ord('c'),		// $33  c
    $34,		// $34  
    Ord('b'),		// $35  b
    $36,		// $36  
    $37,		// $37  
    $38,		// $38  
    $39,		// $39  
    -1,			// $3a
    -1,			// $3b
    -1,			// $3c
    -1,			// $3d
    -1,			// $3e
    -1,			// $3f
    $20,		// $40 Space
    -1,			// $41  'A'
    -1,			// $42  'B'
    -1,			// $43  'C'
    -1,			// $44  'D'
    -1,			// $45  'E'
    -1,			// $46  'F'
    keyInsert,		// $47  'G'
    keyPageUp,		// $48  'H'
    keyPageDown,	// $49  'I'
    -1,			// $4a  'J'
    keyF11,             // $4b  'K'
    keyUp,		// $4c  'L'
    keyDown,		// $4d  'M'
    keyRight,		// $4e  'N'
    keyLeft,		// $4f  'O'
    keyF1,		// $50  'P'
    keyF2,		// $51  'Q'
    keyF3,		// $52  'R'
    keyF4,		// $53  'S'
    keyF5,		// $54  'T'
    keyF6,		// $55  'U'
    keyF7,		// $56  'V'
    keyF8,		// $57  'W'
    keyF9,		// $58  'X'
    keyF10,		// $59  'Y'
    keyNumLock,		// $5a  'Z'
    -1,			// $5b  VK_LWIN
    -1,			// $5c  VK_RWIN
    keyMenu,		// $5d  VK_APPS
    -1,			// $5e
    keyPause,		// $5f  VK_SLEEP
    keyShiftL,		// $60  VK_NUMPAD0
    keyShiftR,	        // $61  VK_NUMPAD1
    keyCaps,            // $62  VK_NUMPAD2
    keyCtrl,	        // $63  VK_NUMPAD3
    keyAlt,	        // $64  VK_NUMPAD4
    keyAltGr,	        // $65  VK_NUMPAD5
    keyMeta,	        // $66  VK_NUMPAD6
    keyP7,		// $67  VK_NUMPAD7
    keyP8,		// $68  VK_NUMPAD8
    keyP9,		// $69  VK_NUMPAD9
    keyPAsterisk,	// $6a  VK_MULTIPLY
    keyPPlus,		// $6b  VK_ADD
    keyPSeparator,	// $6c  VK_SEPARATOR
    keyPMinus,		// $6d  VK_SUBTRACT
    keyPDecimal,	// $6e  VK_DECIMAL
    keyF12,		// $6f  VK_DIVIDE
    keyHome,		// $70  VK_F1
    keyEnd,		// $71  VK_F2
    $52,		        // $72  VK_F3
    $53,		        // $73  VK_F4
    $54,		        // $74  VK_F5
    $55,		        // $75  VK_F6
    $56,		        // $76  VK_F7
    $57,		        // $77  VK_F8
    $58,		        // $78  VK_F9
    $59,		        // $79  VK_F10
    $5a,		        // $7a  VK_F11
    keyF12,		// $7b  VK_F12
    keyF13,		// $7c  VK_F13
    keyF14,		// $7d  VK_F14
    keyF15,		// $7e  VK_F15
    keyF16,		// $7f  VK_F16
    keyF17,		// $80  VK_F17
    keyF18,		// $81  VK_F18
    keyF19,		// $82  VK_F19
    keyF20,		// $83  VK_F20
    keyF21,		// $84  VK_F21
    keyF22,		// $85  VK_F22
    keyF23,		// $86  VK_F23
    keyF24,		// $87  VK_F24
    -1,			// $88
    -1,			// $89
    -1,			// $8a
    -1,			// $8b
    -1,			// $8c
    -1,			// $8d
    -1,			// $8e
    -1,			// $8f
    keyNumLock,		// $90  VK_NUMLOCK
    keyScroll,		// $91  VK_SCROLL
    -1,			// $92  VK_OEM_NEC_EQUAL
    -1,			// $93  VK_OEM_FJ_MASSHOU
    -1,			// $94  VK_OEM_FJ_TOUROKU
    -1,			// $95  VK_OEM_FJ_LOYA
    -1,			// $96  VK_OEM_FJ_ROYA
    -1,			// $97
    -1,			// $98
    -1,			// $99
    -1,			// $9a
    -1,			// $9b
    -1,			// $9c
    -1,			// $9d
    -1,			// $9e
    -1,			// $9f
    keyShiftL,		// $a0  VK_LSHIFT
    keyShiftR,		// $a1  VK_RSHIFT
    keyCtrlL,		// $a2  VK_LCONTROL
    keyCtrlR,		// $a3  VK_RCONTROL
    -1,			// $a4  VK_LMENU
    -1,			// $a5  VK_RMENU
    -1,			// $a6  VK_BROWSER_BACK
    -1,			// $a7  VK_BROWSER_FORWARD
    -1,			// $a8  VK_BROWSER_REFRESH
    -1,			// $a9  VK_BROWSER_STOP
    -1,			// $aa  VK_BROWSER_SEARCH
    -1,			// $ab  VK_BROWSER_FAVORITES
    -1,			// $ac  VK_BROWSER_HOME
    -1,			// $ad  VK_VOLUME_MUTE
    -1,			// $ae  VK_VOLUME_DOWN
    -1,			// $af  VK_VOLUME_UP
    -1,			// $b0  VK_MEDIA_NEXT_TRACK
    -1,			// $b1  VK_MEDIA_PREV_TRACK
    -1,			// $b2  VK_MEDIA_STOP
    -1,			// $b3  VK_MEDIA_PLAY_PAUSE
    -1,			// $b4  VK_LAUNCH_MAIL
    -1,			// $b5  VK_LAUNCH_MEDIA_SELECT
    -1,			// $b6  VK_LAUNCH_APP1
    -1,			// $b7  VK_LAUNCH_APP2
    -1,			// $b8
    -1,			// $b9
    $dc, {U Umlaut}	// $ba  VK_OEM_1
    $2b, {+ char}	// $bb  VK_OEM_PLUS
    $2c, {, char}	// $bc  VK_OEM_COMMA
    $2d, {- char}	// $bd  VK_OEM_MINUS
    $2e, {. char}	// $be  VK_OEM_PERIOD
    $23, {# char}	// $bf  VK_OEM_2
    $d6, {O Umlaut}	// $c0  VK_OEM_3
    -1,			// $c1
    -1,			// $c2
    -1,			// $c3
    -1,			// $c4
    -1,			// $c5
    -1,			// $c6
    -1,			// $c7
    -1,			// $c8
    -1,			// $c9
    -1,			// $ca
    -1,			// $cb
    -1,			// $cc
    -1,			// $cd
    -1,			// $ce
    -1,			// $cf
    -1,			// $d0
    -1,			// $d1
    -1,			// $d2
    -1,			// $d3
    -1,			// $d4
    -1,			// $d5
    -1,			// $d6
    -1,			// $d7
    -1,			// $d8
    -1,			// $d9
    -1,			// $da
    -1,			// $db  VK_OEM_4
    keyDeadCircumflex,	// $dc  VK_OEM_5
    keyDeadAcute,	// $dd  VK_OEM_6
    $c4, {A Umlaut}	// $de  VK_OEM_7
    -1,    	        // $df  VK_OEM_8
    -1,			// $e0
    -1,			// $e1  VK_OEM_AX
    $3c, {< char}	// $e2  VK_OEM_102
    -1,			// $e3  VK_ICO_HELP
    keyP5,		// $e4  VK_ICO_00
    -1,			// $e5  VK_PROCESSKEY
    -1,			// $e6  VK_ICO_CLEAR
    -1,			// $e7  VK_PACKET
    -1,			// $e8
    -1,			// $e9  VK_OEM_RESET
    -1,			// $ea  VK_OEM_JUMP
    -1,			// $eb  VK_OEM_PA1
    -1,			// $ec  VK_OEM_PA2
    -1,			// $ed  VK_OEM_PA3
    -1,			// $ee  VK_OEM_WSCTRL
    -1,			// $ef  VK_OEM_CUSEL
    -1,			// $f0  VK_OEM_ATTN
    -1,			// $f1  VK_OEM_FINISH
    -1,			// $f2  VK_OEM_COPY
    -1,			// $f3  VK_OEM_AUTO
    -1,			// $f4  VK_OEM_ENLW
    -1,			// $f5  VK_OEM_BACKTAB
    -1,			// $f6  VK_ATTN
    -1,			// $f7  VK_CRSEL
    -1,			// $f8  VK_EXSEL
    -1,			// $f9  VK_EREOF
    -1,			// $fa  VK_PLAY
    -1,			// $fb  VK_ZOOM
    -1,			// $fc  VK_NONAME
    -1,			// $fd  VK_PA1
    -1,			// $fe  VK_OEM_CLEAR
    -1			// $ff
  );
begin
  Result := 0;
  if TranslTable[RawKey]  = -1 then
    Result := keyNIL
  else
    Result := TranslTable[RawKey];
end;

function VanillaToKeycode(VanillaKey: Byte): Word;
begin
  Result := VanillaKey;
  case VanillaKey of
    $7F: Result := keyDelete;
  end; 
end;

function KeyboardShiftState(State: Word): TShiftState;
begin
  Result := [];
  if State and IEQUALIFIER_LSHIFT <> 0 then
    Include(Result, ssShift);
  if State and IEQUALIFIER_RSHIFT <> 0 then
    Include(Result, ssShift);
  if State and IEQUALIFIER_LALT <> 0 then
    Include(Result, ssAlt);
  if State and IEQUALIFIER_RALT <> 0 then
    Include(Result, ssAlt);
  if State and IEQUALIFIER_CONTROL <> 0 then
    Include(Result, ssCtrl);
  if State and IEQUALIFIER_LEFTBUTTON <> 0 then
    Include(Result, ssLeft);
  if State and IEQUALIFIER_MIDBUTTON <> 0 then
    Include(Result, ssMiddle);
  if State and IEQUALIFIER_RBUTTON <> 0 then
    Include(Result, ssRight);
  if State and IEQUALIFIER_CAPSLOCK <> 0 then
    Include(Result, ssCaps);
end;

function ButtonState(State: Word): Word;
begin
  Result := 0;
  if State and IEQUALIFIER_LEFTBUTTON <> 0 then
    Result := Result or MOUSE_LEFT;
  if State and IEQUALIFIER_MIDBUTTON <> 0 then
    Result := Result or MOUSE_MIDDLE;
  if State and IEQUALIFIER_RBUTTON <> 0 then
    Result := Result or MOUSE_RIGHT;
end;

