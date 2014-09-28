{
    fpGUI  -  Free Pascal GUI Toolkit

    Copyright (C) 2006 - 2014 See the file AUTHORS.txt, included in this
    distribution, for details of the copyright.

    See the file COPYING.modifiedLGPL, included in this distribution,
    for details about redistributing fpGUI.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

    Description:
      This defines the CoreLib backend interface to the AROS API.
}

unit fpg_aros;

{$mode objfpc}{$H+}

{.$Define DEBUG}
{.$Define DND_DEBUG}
{.$Define DEBUGKEYS}

interface

uses
  dos,
  Classes,
  SysUtils,
  Contnrs,
  StrUtils,
  Intuition, InputEvent, exec, utility, tagsarray, agraphics, diskfont, amigados,
  keymap, layers, clipboard, cybergraphics,
  fpg_base,
  fpg_impl
  {$IFDEF DEBUG}
  ,dbugintf
  {$ENDIF DEBUG}

  ,fpg_OLEDragDrop
  ;

type
  TARGBPixel = packed record
    A: Byte;
    R: Byte;
    G: Byte;
    B: Byte;
  end;
  PARGBPixel = ^TARGBPixel;

  // forward declaration
  TfpgArosWindow = class;
  //TArosDragManager = class;
  TfpgArosDrag = class;

  TWindowList = class
    FWinList: array of PWindow;
  public
    procedure AddWindow(AWin: PWindow);
    procedure RemoveWindow(AWin: PWindow);
    function IsValidWindow(AWin: PWindow): Boolean;
  end;


  TfpgArosFontResource = class(TfpgFontResourceBase)
  protected
    function    OpenFontByDesc(const desc: string): pTextFont;
  public
    FFontData: pTextFont;
    Desc: string;
    constructor Create(const afontdesc: string);
    destructor  Destroy; override;
    function    HandleIsValid: boolean;
    function    GetAscent: integer; override;
    function    GetDescent: integer; override;
    function    GetHeight: integer; override;
    function    GetTextWidth(const txt: string): integer; override;
  end;

  TfpgArosImage = class(TfpgImageBase)
  private
    FImage: PARGBPixel;
  protected
    procedure   DoFreeImage; override;
    procedure   DoInitImage(acolordepth, awidth, aheight: integer; aimgdata: Pointer); override;
    procedure   DoInitImageMask(awidth, aheight: integer; aimgdata: Pointer); override;
  public
    constructor Create;
  end;


  TfpgArosCanvas = class(TfpgCanvasBase)
  private
    FDrawing: boolean;
    RWidth: LongInt;
    RHeight: LongInt;
    TextPen: LongWord;
    DrawPen: LongWord;
    FPenWidth: Integer;
    FDrawWindow: TfpgArosWindow;
    FRastPort: PRastPort;
    FCurFontRes: TfpgArosFontResource;
    FClipRect: TfpgRect;
    FClipRectSet: Boolean;
    FLocalRastPort: PRastPort;
    FBuffered: Boolean;
    function GatherPen(cl: TfpgColor): LongWord;
  protected
    procedure   DoSetFontRes(fntres: TfpgFontResourceBase); override;
    procedure   DoSetTextColor(cl: TfpgColor); override;
    procedure   DoSetColor(cl: TfpgColor); override;
    procedure   DoSetLineStyle(awidth: integer; astyle: TfpgLineStyle); override;
    procedure   DoGetWinRect(out r: TfpgRect); override;
    procedure   DoFillRectangle(x, y, w, h: TfpgCoord); override;
    procedure   DoXORFillRectangle(col: TfpgColor; x, y, w, h: TfpgCoord); override;
    procedure   DoFillTriangle(x1, y1, x2, y2, x3, y3: TfpgCoord); override;
    procedure   DoDrawRectangle(x, y, w, h: TfpgCoord); override;
    procedure   DoDrawLine(x1, y1, x2, y2: TfpgCoord); override;
    procedure   DoDrawImagePart(x, y: TfpgCoord; img: TfpgImageBase; xi, yi, w, h: integer); override;
    procedure   DoDrawString(x, y: TfpgCoord; const txt: string); override;
    procedure   DoSetClipRect(const ARect: TfpgRect); override;
    function    DoGetClipRect: TfpgRect; override;
    procedure   DoAddClipRect(const ARect: TfpgRect); override;
    procedure   DoClearClipRect; override;
    procedure   DoBeginDraw(awin: TfpgWindowBase; buffered: boolean); override;
    procedure   DoPutBufferToScreen(x, y, w, h: TfpgCoord); override;
    procedure   DoEndDraw; override;
    function    GetPixel(X, Y: integer): TfpgColor; override;
    procedure   SetPixel(X, Y: integer; const AValue: TfpgColor); override;
    procedure   DoDrawArc(x, y, w, h: TfpgCoord; a1, a2: Extended); override;
    procedure   DoFillArc(x, y, w, h: TfpgCoord; a1, a2: Extended); override;
    procedure   DoDrawPolygon(Points: PPoint; NumPts: Integer; Winding: boolean = False); override;
  public
    constructor Create(AWin: TfpgWindowBase); override;
    destructor  Destroy; override;
  end;


  { TfpgArosWindow }

  TfpgArosWindow = class(TfpgWindowBase)
  private
    FDropPos: TPoint;
    FUserMimeSelection: TfpgString;
    FUserAcceptDrag: Boolean;
  private
    FVisible: Boolean;
    FParent: TfpgArosWindow;
    FZeroZero: Boolean;
    FTitle: string;
    //FMouseInWindow: boolean;
    //FNonFullscreenRect: TfpgRect;
    //FNonFullscreenStyle: longword;
    FFullscreenIsSet: boolean;
    FSkipResizeMessage: boolean;
    FSkipNextResizeMessage: Boolean;
    QueueAcceptDrops: boolean;
    function GetScreenTitle: string;
  protected
    BorderWidth: TPoint;
    FWinHandle: TfpgWinHandle;
    FModalForWin: TfpgArosWindow;
    FWinStyle: longword;
    FWinStyleEx: longword;
    FParentWinHandle: TfpgWinHandle;
    procedure   DoAllocateWindowHandle(AParent: TfpgWindowBase); override;
    procedure   DoReleaseWindowHandle; override;
    procedure   DoRemoveWindowLookup; override;
    procedure   DoSetWindowVisible(const AValue: Boolean); override;
    function    HandleIsValid: boolean; override;
    procedure   DoUpdateWindowPosition; override;
    procedure   DoMoveWindow(const x: TfpgCoord; const y: TfpgCoord); override;
    function    DoWindowToScreen(ASource: TfpgWindowBase; const AScreenPos: Classes.TPoint): Classes.TPoint; override;
//    procedure   MoveToScreenCenter; override;
    procedure   DoSetWindowTitle(const ATitle: string); override;
    procedure   DoSetMouseCursor; override;
    procedure   DoDNDEnabled(const AValue: boolean); override;
    procedure   DoAcceptDrops(const AValue: boolean); override;
    procedure   DoDragStartDetected; override;
    function    GetWindowState: TfpgWindowState; override;
    property    WinHandle: TfpgWinHandle read FWinHandle;
    property    Parent: TfpgArosWindow read FParent write FParent;
    property    ZeroZero: Boolean read FZeroZero;

  public
    RunningResize: Boolean;
    constructor Create(AOwner: TComponent); override;
    destructor  Destroy; override;
    procedure   ActivateWindow; override;
    procedure   CaptureMouse; override;
    procedure   ReleaseMouse; override;
    procedure   SetFullscreen(AValue: Boolean); override;
    procedure   BringToFront; override;

    procedure   DoMouseEnterLeaveCheck(var AWindow: TfpgArosWindow; uMsg: Cardinal; var msgp: TfpgMessageParams);

    property    Visible: Boolean read FVisible;
    property    ScreenTitle: string read GetScreenTitle;
  end;


  TfpgArosApplication = class(TfpgApplicationBase)
  private
    FDrag: TfpgArosDrag;
    procedure   SetDrag(const AValue: TfpgArosDrag);
    //property    Drag: TfpgArosDrag read FDrag write SetDrag;
  protected
    FFocusedWindow: THANDLE;
    function    DoGetFontFaceList: TStringList; override;
    procedure   DoWaitWindowMessage(atimeoutms: integer); override;
    function    MessagesPending: boolean; override;
  public
    Waiting: Boolean;
    BlockRefresh: Boolean;
    LastWindowHndl: TfpgWinHandle;
    CapturedWindow: TfpgArosWindow;
    WindowList: TWindowList;
    GlobalMsgPort: PMsgPort;
    GlobalScreen: PScreen;
    DrawRastPort: PRastPort;

    constructor Create(const AParams: string); override;
    destructor  Destroy; override;
    procedure   DoFlush;
    function    GetScreenWidth: TfpgCoord; override;
    function    GetScreenHeight: TfpgCoord; override;
    function    Screen_dpi_x: integer; override;
    function    Screen_dpi_y: integer; override;
    function    Screen_dpi: integer; override;
    function ProcessAllMessages: Boolean;
  end;


  TfpgArosClipboard = class(TfpgClipboardBase)
  protected
    FClipboardText: TfpgString;
    function    DoGetText: TfpgString; override;
    procedure   DoSetText(const AValue: TfpgString); override;
    procedure   InitClipboard; override;
  end;


  TfpgArosFileList = class(TfpgFileListBase)
    function    EncodeAttributesString(attrs: longword): TFileModeString;
    constructor Create; override;
    function    InitializeEntry(sr: TSearchRec): TFileEntry; override;
    procedure   PopulateSpecialDirs(const aDirectory: TfpgString); override;
  end;


  TfpgArosMimeDataBase = class(TfpgMimeDataBase)
  end;


  { Used mainly for sending drags - being the source of the drag }
  TfpgArosDrag = class(TfpgDragBase)
  protected
    FSource: TfpgArosWindow;
    function    GetSource: TfpgArosWindow; virtual;
  public
    destructor  Destroy; override;
    function    Execute(const ADropActions: TfpgDropActions; const ADefaultAction: TfpgDropAction=daCopy): TfpgDropAction; override;
  end;

  { TfpgArosTimer }

  TfpgArosTimer = class(TfpgBaseTimer)
  private
    FHandle: THandle;
  protected
    procedure   SetEnabled(const AValue: boolean); override;
  public
    constructor Create(AInterval: integer); override;
  end;

implementation

uses
  fpg_main,
  fpg_widget,
  fpg_popupwindow,
  fpg_stringutils,
  fpg_form,
  math;


var
  wapplication: TfpgApplication;

// some required keyboard functions
{$INCLUDE fpg_keys_Aros.inc}


function fpgColorToWin(col: TfpgColor): longword;
var
  c: dword;
begin
  c      := fpgColorToRGB(col);
  //swapping bytes (Red and Blue colors)
  Result := ((c and $FF0000) shr 16) or ((c and $0000FF) shl 16) or (c and $00FF00);
end;

function WinColorTofpgColor(col: longword): TfpgColor;
begin
  //swapping bytes
  Result := fpgColorToWin(col);
end;

procedure TWindowList.AddWindow(AWin: PWindow);
var
  Idx: Integer;
  i: Integer;
begin
  // search for free space
  Idx := -1;
  for i := 0 to High(FWinList) do
  begin
    if FWinList[i] = nil then
    begin
      Idx := i;
      Break;
    end;
  end;
  if Idx = -1 then
  begin
    Idx := Length(FWinList);
    SetLength(FWinList, Idx + 1);
  end;
  FWinList[Idx] := AWin;
end;

procedure TWindowList.RemoveWindow(AWin: PWindow);
var
  i: Integer;
begin
  for i := 0 to High(FWinList) do
  begin
    if FWinList[i] = AWin then
    begin
      FWinList[i] := nil;
      Break;
    end;
  end;
end;

function TWindowList.IsValidWindow(AWin: PWindow): Boolean;
var
  i: Integer;
begin
  Result := False;
  for i := 0 to High(FWinList) do
  begin
    if FWinList[i] = AWin then
    begin
      Result := True;
      Break;
    end;
  end;
end;



function GetMyWidgetFromHandle(wh: TfpgWinHandle): TfpgWidget;
begin
  Result := nil;
  if wh = 0 then
    Exit;
  if wapplication.WindowList.IsValidWindow(pWindow(wh)) then
  begin
    if pWindow(wh)^.UserData = nil then
      Exit;
     Result := TfpgWidget(pWindow(wh)^.UserData);
  end;
end;

{  **********   Some helper conversion functions   ************* }

procedure GetWindowBorderDimensions(const w: TfpgWindowBase; var dx, dy: integer);
begin
  dx := 0;
  dy := 0;
  if TfpgArosWindow(w).HandleIsValid and TfpgForm(w).ZeroZero then
  begin
    dx := pWindow(TfpgArosWindow(w).WinHandle)^.BorderLeft + pWindow(TfpgArosWindow(w).WinHandle)^.BorderRight;
    dy := pWindow(TfpgArosWindow(w).WinHandle)^.BorderTop + pWindow(TfpgArosWindow(w).WinHandle)^.BorderBottom;
  end;
end;

{ TfpgArosApplication }

type
  TAROSFont = record
    BaseName: string;
    Normal: string;
    Italic: string;
    Bold: string;
    BoldItalic: string;
  end;
  TAROSFontList = array of TAROSFont;
var
  AROSFontList: TAROSFontList;

function TfpgArosApplication.DoGetFontFaceList: TStringList;
//var
//  LFont: TLogFont;
var
  Test: Pointer;
  pH: pAvailFontsHeader;
  Count: Integer;
  paf: pAvailFonts;
  i,f,Idx: Integer;
  str: string;
  isBold: Boolean;
  IsItalic: Boolean;
  filename: string;
begin
  Result := TStringList.Create;
  if Length(AROSFontList) = 0 then
  begin
    //Result.Add('');
    GetMem(Test, 4096);
    //writeln('get font start');
    if AvailFonts(test, 4096, AFF_DISK) = 0 then
    begin
      //writeln('get font start');
      ph := Test;
      Count := ph^.afh_NumEntries;
      //writeln('found ', Count,'Entries');
      inc(Ph);
      paf := Pointer(ph);
      for i := 0 to Count - 1 do
      begin
        str := LowerCase(string(PAf^.af_Attr.ta_Name));      
        filename := str;
        str := LowerCase(string(PAf^.af_Attr.ta_Name));
        str := StringReplace(str, '.font', '', [rfReplaceAll, rfIgnoreCase]);
        isBold := False;
        isItalic := False;
        if Pos('italic', str) > 0 then
        begin
          isItalic := True;
          str := StringReplace(str, 'italic', '', [rfReplaceAll, rfIgnoreCase]);
        end;
        if (Pos('bold', str) > 0) then
        begin
          isBold := True;
          str := StringReplace(str, 'bold', '', [rfReplaceAll, rfIgnoreCase]);
        end;
        str := Trim(str);
        Idx := -1;
        for f := 0 to High(AROSFontList) do
        begin
          if str = AROSFontList[f].BaseName then
          begin
            Idx := f;
            Break;
          end;
        end;
        if Idx < 0 then
        begin
          Idx := Length(AROSFontList);
          SetLength(AROSFontList, Idx + 1);
          AROSFontList[Idx].BaseName := str;
          AROSFontList[Idx].Normal := '';
          AROSFontList[Idx].Bold := '';
          AROSFontList[Idx].Italic := '';
          AROSFontList[Idx].BoldItalic := '';
        end;
        if isItalic then
        begin
          if isBold then
            AROSFontList[Idx].BoldItalic := filename
          else
            AROSFontList[Idx].Italic := filename;        
        end else
        begin
          if isBold then
            AROSFontList[Idx].Bold := filename
          else
            AROSFontList[Idx].Normal := filename;  
        end;
        inc(Paf);
      end;
    end;
    for i := 0 to High(AROSFontList) do
    begin
      FileName := AROSFontList[i].Normal;
      if Filename = '' then
        filename := AROSFontList[i].Bold; 
      if Filename = '' then
        filename := AROSFontList[i].Italic;
      if Filename = '' then
        filename := AROSFontList[i].BoldItalic;
      if AROSFontList[i].Normal = '' then
        AROSFontList[i].Normal := filename;
      if AROSFontList[i].Bold = '' then
        AROSFontList[i].Bold := filename;
      if AROSFontList[i].Italic = '' then
        AROSFontList[i].Italic := filename;
      if AROSFontList[i].BoldItalic = '' then
        AROSFontList[i].BoldItalic := filename;  
    end;
    FreeMem(Test);
  end;  
  for i := 0 to High(AROSFontList) do
  begin
    Result.Add(AROSFontList[i].BaseName);    
  end;
  Result.Sort;
end;

procedure TfpgArosApplication.SetDrag(const AValue: TfpgArosDrag);
begin
  if Assigned(FDrag) then
    FDrag.Free;
  FDrag := AValue;
end;

constructor TfpgArosApplication.Create(const AParams: string);
begin
  inherited Create(AParams);
  WindowList := TWindowList.Create;
  GlobalMsgPort := CreateMsgPort;
  FIsInitialized  := True;
  wapplication   := TfpgApplication(self);
  Waiting := False;
  BlockRefresh := True;
end;

destructor TfpgArosApplication.Destroy;
var
  IMsg: PIntuiMessage;
begin
  Forbid();
  if Assigned(GlobalMsgPort) then
  begin
    repeat
      IMsg := PIntuiMessage(GetMsg(GlobalMsgPort));
      if Assigned(IMsg) then
        ReplyMsg(pMessage(IMsg));  
    Until IMsg = nil; 
    DeleteMsgPort(GlobalMsgPort);
  end;
  GlobalMsgPort := NIL;
  Permit();
  WindowList.Free;
  inherited Destroy;
end;

function TfpgArosApplication.MessagesPending: boolean;
begin
  Result := False;
end;

function TfpgArosApplication.ProcessAllMessages: Boolean;
var
  IMsg: PIntuiMessage;
  IsMsgAvail: Boolean;
  IClass: LongWord;
  ICode: Word;
  IQual: Word;
  Window: TfpgArosWindow;
  AWin: PWindow;
  MsgP: TfpgMessageParams;
  x, y: LongInt;
  mw: TfpgAROSWindow;
  kwg: TfpgAROSWindow;
  keyUp: Boolean;
  Buff: array[0..19] of Char;
  ie: TInputEvent;
  Ret: SmallInt;
begin
  Result := True;
  if Assigned(GlobalMsgPort) then
  begin
    Result := False;
    repeat
      FillChar(MsgP, SizeOf(MsgP), 0);
      Window := nil;
      IMsg := nil;
      //writeln('get message');
      // Get message
      if Assigned(GlobalMsgPort) then
        IMsg := PIntuiMessage(GetMsg(GlobalMsgPort));
      IsMsgAvail := Assigned(IMsg);
      if IsMsgAvail then
      begin
        Result := True;
        // Not a windows message -> next message
        if not Assigned(IMsg^.IDCMPWindow) then
        begin
          ReplyMsg(pMessage(IMsg)); 
          Continue;
        end;   
        // get the window
        AWin := IMsg^.IDCMPWindow;
        // copy the Properties 
        ICode := IMsg^.Code;
        IQual := IMsg^.Qualifier;
        IClass:= IMsg^.IClass;
        // Answer to the message
        ReplyMsg(pMessage(IMsg));
        
        // not an attached window or Window which is currently closing 
        if not wapplication.Windowlist.isValidWindow(AWin) then
          Continue;
        
        if not Assigned(AWin^.UserData) then
          Continue;


        // Mouse properties
        Window := TfpgArosWindow(AWin^.UserData);
        if Window.ZeroZero then
        begin
          x := pWindow(Window.WinHandle)^.GZZMouseX;
          y := pWindow(Window.WinHandle)^.GZZMouseY;
        end else
        begin
          x := pWindow(Window.WinHandle)^.MouseX - Window.BorderWidth.X;
          y := pWindow(Window.WinHandle)^.MouseY - Window.BorderWidth.Y;

        end;

        msgp.keyboard.shiftstate := KeyboardShiftState(IQual);
        msgp.mouse.shiftstate := msgp.keyboard.shiftstate;
        msgp.mouse.Buttons := ButtonState(IQual);
        // Check for modal windows, only allow Refresh and newsize 
        mw := nil;
        if (wapplication.TopModalForm <> nil) then
        begin 
          mw := TfpgAROSWindow(WidgetParentForm(TfpgWidget(Window)));
          if (mw <> nil) and (wapplication.TopModalForm <> mw) then
          begin  
            if (IClass = IDCMP_INACTIVEWINDOW) and TfpgAROSWindow(wapplication.TopModalForm).HandleIsValid then 
            begin // if ModalWindow is active activate the modalwindow again
              intuition.ActivateWindow(pWindow(TfpgAROSWindow(wapplication.TopModalForm).WinHandle));
              Continue;
            end;
            if not ((IClass = IDCMP_REFRESHWINDOW) or (IClass = IDCMP_NEWSIZE))then
              Continue;             
          end;
        end;
        //system.debugln('msg: $' + IntToHex(IClass, 8));
        //system.debugln('Msg: $' +IntToHex(IClass, 8) + ' Win: ' + IntToHex(PtrUInt(Window),8));
        case IClass of
          IDCMP_CLOSEWINDOW: begin
            fpgSendMessage(nil, Window, FPGM_CLOSE, MsgP);
          end;
          IDCMP_INACTIVEWINDOW: begin           
            fpgSendMessage(nil, Window, FPGM_DEACTIVATE);
          end;
          IDCMP_ACTIVEWINDOW: begin
            SetWindowTitles(AWin, PChar(Window.FTitle), PChar(Window.ScreenTitle));
            fpgSendMessage(nil, Window, FPGM_ACTIVATE);
          end; 
          IDCMP_REFRESHWINDOW: begin
              BeginRefresh(AWin);
              EndRefresh(AWin, True);
              fpgSendMessage(nil, Window, FPGM_PAINT, MsgP);
            end;
          IDCMP_INTUITICKS:begin
            fpgCheckTimers;
            if Assigned(FOnIdle) then
              OnIdle(self);
          end;
          IDCMP_RAWKEY:begin
            //system.debug('.');
            kwg := FindKeyboardFocus;
            //system.debug(',');
            if kwg <> nil then
            begin
              if wapplication.Windowlist.isValidWindow(PWindow(kwg.FWinHandle)) then
              begin
                //writeln('found keyboard focus');
                Window := kwg;
              end;  
            end;
            //system.debug('-');
            // Mouse wheel up
            if (ICode = $7A) or (ICode = $7B) then
            begin
              msgp.mouse.X := x;
              msgp.mouse.Y := y;
              if ICode = $7A then
                msgp.Mouse.Delta := -1
              else
                msgp.Mouse.Delta := 1;
              fpgSendMessage(nil, Window, FPGM_SCROLL, MsgP);
            end else
            begin
              keyUp := (ICode and IECODE_UP_PREFIX) <> 0;
              ICode := ICode and not IECODE_UP_PREFIX;
              ie.ie_Class := IECLASS_RAWKEY;
              ie.ie_SubClass := 0;
              ie.ie_Code := ICode;
              ie.ie_Qualifier := IQual;
              ie.ie_NextEvent := nil;

              Buff[0] := #0;
              Ret := MapRawKey(@ie, @Buff[0], 1, nil);
              if Ret <= 0 then
              begin
                msgp.keyboard.keycode :=  RawKeyToKeycode(ICode);

                msgp.keyboard.keychar := #0; //chr(msgp.keyboard.keycode);
              end else
              begin
                msgp.keyboard.keychar := Buff[0];
                msgp.keyboard.keycode := Ord(Buff[0]);
              end;
              {$IFDEF DEBUGKEYS}
              writeln('Msg: RawKey Code: $', inttoHex(ICode,2), ' -> $',IntToHex(msgp.keyboard.keycode,4), '(', msgp.keyboard.keychar,') ret: ',ret);
              {$ENDIF}
              //system.debugln('Msg: $' +IntToHex(IClass, 8) + ' Win: ' + IntToHex(PtrUInt(Window),8));
              if KeyUp then
              begin
                //system.debug('#');
                fpgSendMessage(nil, Window, FPGM_KEYRELEASE, MsgP);
                //system.debugln('+');
              end else
              begin
                //system.debug(':');
                fpgSendMessage(nil, Window, FPGM_KEYPRESS, MsgP);
                fpgSendMessage(nil, Window, FPGM_KEYCHAR, Msgp);
                //system.debugln(';');
              end;    
            end;
          end;
          IDCMP_NEWSIZE: begin
            if not Window.FSkipResizeMessage then
            begin
              if Window.ZeroZero then
              begin
                msgp.rect.Width := pWindow(Window.WinHandle)^.GZZWidth;
                msgp.rect.Height := pWindow(Window.WinHandle)^.GZZHeight;
              end else
              begin
                msgp.rect.Width := pWindow(Window.WinHandle)^.Width;
                msgp.rect.Height := pWindow(Window.WinHandle)^.Height;
              end;
              //writeln('----->Msg: NewSize: ',Window.Classname, ' = ', msgp.rect.Width ,' x ', msgp.rect.Height);
              if Window.Parent = nil then
                fpgSendMessage(nil, Window, FPGM_RESIZE, MsgP);
              fpgSendMessage(nil, Window, FPGM_PAINT, MsgP);
              Window.RunningResize := False;
            end;
          end;
          IDCMP_CHANGEWINDOW: begin
            if not Window.FSkipResizeMessage then
            begin
              msgp.rect.Left := pWindow(Window.WinHandle)^.RelLeftEdge;
              msgp.rect.Top := pWindow(Window.WinHandle)^.RelTopEdge;
              //writeln('---->Msg: changewindow: ',Window.Classname, ' = ', msgp.rect.Left ,' x ', msgp.rect.Top);
              if Window.Parent = nil then            
                fpgSendMessage(nil, Window, FPGM_MOVE, MsgP);               
              fpgSendMessage(nil, Window, FPGM_PAINT, MsgP);
              Window.RunningResize := False;
            end;
          end;
          IDCMP_MOUSEMOVE: begin
            //writeln('Msg:MouseMove: IQual: ', inttoHex(IQual,2));
            
            //writeln('before captured Window: ', x, ', ', y);
            mw := Window;
            
            if Assigned(wapplication.CapturedWindow) then
            begin
              mw := wapplication.CapturedWindow;
              //writeln('capwin: ', mw.Classname);
              if wapplication.CapturedWindow.ZeroZero then
              begin
                x := pWindow(wapplication.CapturedWindow.WinHandle)^.GZZMouseX;
                y := pWindow(wapplication.CapturedWindow.WinHandle)^.GZZMouseY;
              end else
              begin
                x := pWindow(wapplication.CapturedWindow.WinHandle)^.MouseX - mw.BorderWidth.X;
                y := pWindow(wapplication.CapturedWindow.WinHandle)^.MouseY - mw.BorderWidth.Y;
              end;
              msgp.mouse.X := x;
              msgp.mouse.Y := y;
            end else
            begin
              //writeln('before mouse enter leave: ', x, ', ', y);
              msgp.mouse.X := x;
              msgp.mouse.Y := y;
              Window.DoMouseEnterLeaveCheck(mw, FPGM_MOUSEMOVE, msgp);            
              //writeln('after mouse enter leave: ', msgp.mouse.X, ', ', msgp.mouse.Y);
            end;          
            if Assigned(mw) then
            begin
              //writeln('####Move: ', x,', ', y, ' assigned: ', mw.classname, ' Zero: ', mw.ZeroZero);  
              fpgSendMessage(nil, mw, FPGM_MOUSEMOVE, MsgP);
            end;
          end;
          IDCMP_MOUSEBUTTONS: begin
            mw := Window;
            if Assigned(wapplication.CapturedWindow) then
            begin
              mw := wapplication.CapturedWindow;
              if wapplication.CapturedWindow.ZeroZero then
              begin
                x := pWindow(wapplication.CapturedWindow.WinHandle)^.GZZMouseX;
                y := pWindow(wapplication.CapturedWindow.WinHandle)^.GZZMouseY;
              end else
              begin
                x := pWindow(wapplication.CapturedWindow.WinHandle)^.MouseX - mw.BorderWidth.X;
                y := pWindow(wapplication.CapturedWindow.WinHandle)^.MouseY - mw.BorderWidth.Y;
              end;
              msgp.mouse.X := x;
              msgp.mouse.Y := y;
            end else
            begin
              msgp.mouse.X := x;
              msgp.mouse.Y := y;
              Window.DoMouseEnterLeaveCheck(mw, FPGM_MOUSEMOVE, msgp);            
            end;  
            if Assigned(mw) then
            begin 
              //writeln('####Click: ', x,', ', y, ' assigned: ', mw.classname, ' Zero: ', mw.ZeroZero, ' has parent: ', Assigned(mw.Parent));                         
              case ICode of
                104: begin // Left Down
                  msgp.mouse.Buttons := MOUSE_LEFT;
                  if mw is TfpgWidget then
                  begin
                    //if TfpgWidget(mw).FormDesigner <> nil then
                      mw.CaptureMouse;
                  end;                  
                  fpgSendMessage(nil, mw, FPGM_MOUSEDOWN, MsgP);
                end;
                232: begin // Left up
                  msgp.mouse.Buttons := MOUSE_LEFT;
                  if mw is TfpgWidget then
                  begin
                    //if TfpgWidget(mw).FormDesigner <> nil then
                      mw.ReleaseMouse;
                  end;
                  fpgSendMessage(nil, mw, FPGM_MOUSEUP, MsgP);
                end;
                106: begin // Middle Down
                  msgp.mouse.Buttons := MOUSE_MIDDLE;
                  fpgSendMessage(nil, mw, FPGM_MOUSEDOWN, MsgP);
                end;
                234: begin // Middle Up
                  msgp.mouse.Buttons := MOUSE_MIDDLE;
                  fpgSendMessage(nil, mw, FPGM_MOUSEUP, MsgP);
                end;
                105: begin // Right Down
                  msgp.mouse.Buttons := MOUSE_RIGHT;
                  fpgSendMessage(nil, mw, FPGM_MOUSEDOWN, MsgP);
                end;
                233: begin // Right Up
                  msgp.mouse.Buttons := MOUSE_RIGHT;
                  fpgSendMessage(nil, mw, FPGM_MOUSEUP, MsgP);
                end;
              end;
            end;            
          end;
          else begin
            //writeln('Msg: $',IntToHex(Msg^.IClass, 8),' Code: ', Msg^.Code);
          end;
        end;
      end;
      //Debugln('Timer ' + IntToStr(GetMSCount - t1));
      //t1 := GetmsCount;
    until (not IsMsgAvail) or (GlobalMsgPort = nil);
  end;
end;

procedure TfpgArosApplication.DoWaitWindowMessage(atimeoutms: integer);
var
  t: System.TDateTime;
  b: Boolean;
begin
  t := Now;
  repeat
    try
      b := ProcessAllMessages;
    except
      b := False;
    end;
    if not b then
    begin
      if Assigned(FOnIdle) then
      begin
        OnIdle(Self);
        //Sleep(10);
      end else
      begin
        Waiting := True;
        Sleep(1);
        //Sleep(25);
        //WaitPort(GlobalMsgPort);
        Waiting := False;
      end;
    end;
  until (b) or (((Now - t) * 24*60*60*1000) > atimeoutms);
end;

procedure TfpgArosApplication.DoFlush;
begin

end;

function TfpgArosApplication.GetScreenWidth: TfpgCoord;
var
  Screen: pScreen;
begin
  Screen := LockPubScreen('Workbench');
  Result := Screen^.Width;
  UnlockPubScreen('Workbench', Screen);
end;

function TfpgArosApplication.GetScreenHeight: TfpgCoord;
var
  Screen: pScreen;
begin
  Screen := LockPubScreen('Workbench');
  Result := Screen^.Height;
  UnlockPubScreen('Workbench', Screen);
end;

function TfpgArosApplication.Screen_dpi_x: integer;
begin
  Result := 72;
end;

function TfpgArosApplication.Screen_dpi_y: integer;
begin
  Result := 72;
end;

function TfpgArosApplication.Screen_dpi: integer;
begin
  Result := Screen_dpi_y;
end;

{ TfpgArosWindow }

function TfpgArosWindow.GetScreenTitle: string;
begin
  if Parent = nil then
    Result := FTitle
  else
    Result := Parent.ScreenTitle;
end;

procedure TfpgArosWindow.DoMouseEnterLeaveCheck(var AWindow: TfpgArosWindow; uMsg: Cardinal; var msgp: TfpgMessageParams);
var
  Win: PWindow;
  Scrn: PScreen;
  Layer: PLayer;
  CurrentWindowHndl: TfpgWinHandle;
  LastWindow: TfpgArosWindow;
  CurrentWindow: TfpgArosWindow;
begin
  if FWinHandle <= 0 then
    Exit;
  Win := PWindow(FWinHandle);
  Scrn := Win^.WScreen;

  // Idea for find window by position
  LockLayerInfo(@(Scrn^.LayerInfo));
  Layer := WhichLayer(@(Scrn^.LayerInfo), Scrn^.MouseX, Scrn^.MouseY);
  //writeln('Screen: ', Scrn^.MouseY, ', ', Scrn^.MouseX);
  
  UnlockLayerInfo(@(Scrn^.LayerInfo));
  CurrentWindowHndl := 0;
  if Assigned(Layer) then
    CurrentWindowHndl := TfpgWinHandle(Layer^.Window);
  if CurrentWindowHndl = 0 then
    Exit;

  if (CurrentWindowHndl <> wapplication.LastWindowHndl) then
  begin
    LastWindow := GetMyWidgetFromHandle(wapplication.LastWindowHndl);
    // check if last window still exits. eg: Dialog window could be closed.
    if LastWindow <> nil then
    begin
      if Assigned(LastWindow.Parent) then
      begin
        Msgp.Mouse.X := Scrn^.MouseX - PWindow(LastWindow.WinHandle)^.LeftEdge - LastWindow.BorderWidth.X;
        Msgp.Mouse.Y := Scrn^.MouseY - PWindow(LastWindow.WinHandle)^.TopEdge - LastWindow.BorderWidth.Y;
      end else
      begin
        Msgp.Mouse.X := Scrn^.MouseX - PWindow(LastWindow.WinHandle)^.LeftEdge - LastWindow.BorderWidth.X;
        Msgp.Mouse.Y := Scrn^.MouseY - PWindow(LastWindow.WinHandle)^.TopEdge - LastWindow.BorderWidth.Y;
      end;  
      fpgSendMessage(nil, LastWindow, FPGM_MOUSEEXIT, msgp);
    end;

    CurrentWindow := GetMyWidgetFromHandle(CurrentWindowHndl);
    if (CurrentWindow <> nil) then
    begin    
      if Assigned(CurrentWindow.Parent) then
      begin
        Msgp.Mouse.X := Scrn^.MouseX - PWindow(CurrentWindow.WinHandle)^.LeftEdge - CurrentWindow.BorderWidth.X;
        Msgp.Mouse.Y := Scrn^.MouseY - PWindow(CurrentWindow.WinHandle)^.TopEdge - CurrentWindow.BorderWidth.Y;
      end else
      begin
        Msgp.Mouse.X := Scrn^.MouseX - PWindow(CurrentWindow.WinHandle)^.LeftEdge - CurrentWindow.BorderWidth.X;
        Msgp.Mouse.Y := Scrn^.MouseY - PWindow(CurrentWindow.WinHandle)^.TopEdge - CurrentWindow.BorderWidth.X;
      end;  
      fpgSendMessage(nil, CurrentWindow, FPGM_MOUSEENTER, msgp);
    end;
  end;
  wapplication.LastWindowHndl := CurrentWindowHndl;
  AWindow := GetMyWidgetFromHandle(CurrentWindowHndl);
  if Assigned(AWindow) then
  begin
    if Assigned(AWindow.Parent) then
    begin
      Msgp.Mouse.X := Scrn^.MouseX - PWindow(AWindow.WinHandle)^.LeftEdge - AWindow.BorderWidth.X;
      Msgp.Mouse.Y := Scrn^.MouseY - PWindow(AWindow.WinHandle)^.TopEdge - AWindow.BorderWidth.Y;
    end else
    begin
      Msgp.Mouse.X := Scrn^.MouseX - PWindow(AWindow.WinHandle)^.LeftEdge - AWindow.BorderWidth.X;
      Msgp.Mouse.Y := Scrn^.MouseY - PWindow(AWindow.WinHandle)^.TopEdge - AWindow.BorderWidth.Y;
    end;  
  end;
end;

procedure TfpgArosWindow.DoAllocateWindowHandle(AParent: TfpgWindowBase);
var
  WTags: TTagsList;
  ScreenName: string;
  Tags: PTagItem;
  FPForm: pWindow;
  FLags: LongWord;
  bw, bh: LongInt;
  GetBW: Boolean;
begin
  if FWinHandle > 0 then
    Exit;
  ScreenName := 'Workbench';
  //Writeln('Create ' + Self.ClassName,' - ',FLeft,',', FTop,' - ', FWidth, ',', FHeight);
  FParent := TfpgArosWindow(AParent);
  FSkipResizeMessage := True;
  //w := FWidth;
  //h := FHeight;
  FParentWinHandle := 0;
  AdjustWindowStyle;
//writeln('create ',FLeft,',', FTop,' - ', FWidth, ',', FHeight);
  Flags :=  WFLG_OTHER_REFRESH or WFLG_REPORTMOUSE or WFLG_RMBTRAP;
  if (WindowType in [wtPopup]) or (waBorderLess in FWindowAttributes) or (AParent <> nil) then
  begin
    //writeln('Borderless');
    GetBw := False;
    FZeroZero := False;
    Flags := Flags or WFLG_BORDERLESS;
    if AParent = nil then
    begin
      bw := 0;
      bh := 0;
      FZeroZero := False;
      //Flags := Flags or WFLG_GIMMEZEROZERO;
    end else
    begin
      bw := 0;
      bh := 0;
    end;    
    AddTags(WTags, [Integer(WA_Left), FLeft + bw, Integer(WA_Top), FTop + bw, Integer(WA_Width), 0 {FWidth + bw}, Integer(WA_Height), 0 {FHeight + bh}]);
  end else
  begin
    //writeln('normal');
    Flags := Flags or WFLG_GIMMEZEROZERO or WFLG_CLOSEGADGET or WFLG_SIZEGADGET or WFLG_DRAGBAR or WFLG_DEPTHGADGET;
    bw := 30;
    bh := 30;
    GetBW := True;
    FZeroZero := True;
    AddTags(WTags, [Integer(WA_Left), FLeft, Integer(WA_Top), FTop, Integer(WA_Width), FWidth + bw, Integer(WA_Height), FHeight + bh]);
  end;

  AddTags(WTags, [Integer(WA_IDCMP), IDCMP_REFRESHWINDOW or IDCMP_CLOSEWINDOW or IDCMP_NEWSIZE or
    IDCMP_ACTIVEWINDOW or IDCMP_INACTIVEWINDOW or IDCMP_RAWKEY or
    IDCMP_MOUSEBUTTONS or IDCMP_MOUSEMOVE or IDCMP_MENUPICK or
    IDCMP_DELTAMOVE or IDCMP_INTUITICKS or IDCMP_IDCMPUPDATE or IDCMP_CHANGEWINDOW]);
  AddTags(WTags, [Integer(WA_PubScreenName), PtrInt(ScreenName), Integer(WA_SimpleRefresh), Integer(True)]);
  if AParent <> nil then
  begin
    AddTags(WTags, [Integer(WA_Parent), Integer(TfpgArosWindow(AParent).WinHandle)]);
    AddTags(WTags, [Integer(WA_DepthGadget), Integer(False)]);
    AddTags(WTags, [Integer(WA_CloseGadget), Integer(False)]);
  end else
  begin
    AddTags(WTags, [Integer(WA_DepthGadget), Integer(True)]);
    AddTags(WTags, [Integer(WA_CloseGadget), Integer(True)]);
  end;
  AddTags(WTags, [Integer(WA_FLAGS), Integer(Flags)]);
  Tags := GetTagPtr(WTags);
  Forbid();
  FPForm := OpenWindowTagList(NIL, Tags);
  if FPForm^.UserPort <> nil then
    DeleteMsgPort(FPForm^.UserPort);
  FPForm^.UserPort := wapplication.GlobalMsgPort;
  FPForm^.UserData := Pointer(Self);
  wapplication.WindowList.AddWindow(FPForm);
  if wapplication.GlobalScreen = nil then
    wapplication.GlobalScreen := FPForm^.WScreen;
  Permit();
  FWinHandle := PtrUInt(FPForm);
  if Assigned(AParent) then
  begin
    BorderWidth := TfpgArosWindow(AParent).BorderWidth;
  end else
  begin
    BorderWidth.X := 0;
    BorderWidth.Y := 0;
  end;  
  //
  if GetBW then
  begin
    BorderWidth.X := FPForm^.BorderLeft;
    BorderWidth.Y := FPForm^.BorderTop;
  end;  
  if AParent = nil then
    WindowLimits(FPForm, Max(200, MinWidth), Max(100, MinHeight), pScreen(FPForm^.WScreen)^.Width, pScreen(FPForm^.WScreen)^.Height);
  SetWindowParameters;
  FParentWinHandle := PtrUInt(AParent);
  FSkipResizeMessage := False;
  DoSetMouseCursor;
  if QueueAcceptDrops then
  begin
    DoAcceptDrops(True);
  end;
  RunningResize := False;
  //writeln('Created Window: $', inttoHex(FWinHandle,8), ' self: $', inttoHex(PtrUInt(Self),8));
end;


procedure SaveRemoveMsg(var Mp: PMsgPort; Win: PWindow);
var
  Msgs: array of PIntuiMessage;
  Msg: PIntuiMessage;
  Index: Integer;
  i: Integer;
begin
  Index := -1;
  SetLength(Msgs, 1000);
  repeat
    Msg := PIntuiMessage(GetMsg(Mp));
    if Assigned(Msg) then
    begin
      if Msg^.IDCMPWindow = Win then
      begin
        ReplyMsg(PMessage(Msg));
      end else
      begin
        Inc(Index);
        if Index > High(Msgs) then
          SetLength(Msgs, Length(Msgs) + 1000);
        Msgs[Index] := Msg;
      end;
    end;
  until Msg = nil;
  for i := Index downto 0 do
  begin
    PutMsg(mp, PMessage(Msgs[i]));
  end;
end;

procedure TfpgArosWindow.DoReleaseWindowHandle;
var
  Win: PWindow;
begin
  if FocusRootWidget = Self then
  begin
    FocusRootWidget := TFPGWidget(wapplication.MainForm);
  end;  
  FVisible := False;
  //Debugln('-->Release ' +self.Classname +': $' + inttoHex(FWinHandle,8) + ' self: $' + inttoHex(PtrUInt(Self),8));
  if FWinHandle <= 0 then
    Exit;
  Win := PWindow(FWinHandle);
  Forbid();
  wapplication.WindowList.RemoveWindow(Win);
  SaveRemoveMsg(wapplication.GlobalMsgPort, Win);
  Win^.UserPort := nil;
  Win^.UserData := nil;
  ModifyIDCMP(win,0);
  FWinHandle := 0;
  Permit();
  CloseWindow(Win);
  //writeln('<--Release ',self.Classname,': $', inttoHex(FWinHandle,8), ' self: $', inttoHex(PtrUInt(Self),8));
end;

procedure TfpgArosWindow.DoRemoveWindowLookup;
begin
  // Nothing to do here
end;

procedure TfpgArosWindow.DoSetWindowVisible(const AValue: Boolean);
var
  MsgP: TfpgMessageParams;
begin
  //writeln('Visible ', self.classname , ' -> ', IntToHex(WinHandle, 8), ' ', AValue);
  FVisible := AValue;
  if HandleIsValid then
  begin
    if AValue then
    begin
      ModifyIDCMP(pWindow(WinHandle), pWindow(WinHandle)^.IDCMPFlags or IDCMP_INTUITICKS);
      UpdateWindowPosition;
      FSkipResizeMessage := True;
      intuition.ActivateWindow(pWindow(WinHandle));
      FSkipResizeMessage := False;
    end else
    begin
      if Parent <> nil then
      begin
        // dirty hack to hide items because HideWindow does NOT work!
        intuition.ChangeWindowBox(pWindow(WinHandle),  -2000,  -2000, FWidth, FHeight);
      end;
    end;
    {if AValue then
      ShowWindow(PWindow(FWinHandle))
    else
      HideWindow(PWindow(FWinHandle));}
  end;
end;

procedure TfpgArosWindow.DoMoveWindow(const x: TfpgCoord; const y: TfpgCoord);
var
  dx, dy: LongInt;
begin
  //Writeln('-->>enter Move: ' ,x , ', ' , y , ' ' , self.ClassName);
  FSkipResizeMessage := True;
  if HandleIsValid and Visible then
  begin
    if Is_Children(pWindow(WinHandle)) then
    begin
      dx := x - pWindow(WinHandle)^.RelLeftEdge;
      dy := y - pWindow(WinHandle)^.RelTopEdge;
      //writeln('Move REL ', dx, ',',dy, ' (from ',pWindow(WinHandle)^.RelLeftEdge,',',pWindow(WinHandle)^.RelTopEdge,')');
    end else
    begin
      dx := x - pWindow(WinHandle)^.LeftEdge;
      dy := y - pWindow(WinHandle)^.TopEdge;
      //writeln('Move ABS ', dx, ',',dy, ' (from ',pWindow(WinHandle)^.LeftEdge,',',pWindow(WinHandle)^.TopEdge,')');
    end;
    //Forbid();
    if (dx <> 0) or (dy <> 0) then
      intuition.MoveWindow(pWindow(WinHandle), dx, dy);
    //Permit();
  end;
  FSkipResizeMessage := False;
  //Writeln('<<--Leave Move: ' ,x , ', ' , y);
end;

procedure TfpgArosWindow.DoUpdateWindowPosition;
var
  dx, dy: Integer;
begin
  if RunningResize then
  begin
    //writeln('#### already got one! ', self.classname);
    //Exit;
  end;  
  FSkipResizeMessage := True;
  if HandleIsValid and Visible then
  begin
    if IS_CHILDREN(pWindow(WinHandle)) or (Parent <> nil) then
    begin
      dx := pWindow(WinHandle)^.Parent2^.LeftEdge + FLeft;
      dy := pWindow(WinHandle)^.Parent2^.TopEdge + FTop;      
      //writeln('Move to: ', dx, ' ; ', dy);
      //intuition.MoveWindow(pWindow(WinHandle), FLeft - pWindow(WinHandle)^.LeftEdge, FTop - pWindow(WinHandle)^.TopEdge);
      //intuition.SizeWindow(pWindow(WinHandle), FWidth - pWindow(WinHandle)^.Width, FHeight - pWindow(WinHandle)^.Height);
      intuition.ChangeWindowBox(pWindow(WinHandle),  dx,  dy, FWidth, FHeight);
      //fpgSendMessage(nil, self.Parent, FPGM_PAINT, MsgP);
      //fpgSendMessage(nil, self, FPGM_PAINT, MsgP);
      RunningResize := True;
    end else
    begin
      if ZeroZero then
        intuition.ChangeWindowBox(pWindow(WinHandle),  FLeft,  FTop, FWidth + pWindow(WinHandle)^.BorderLeft + pWindow(WinHandle)^.BorderRight, FHeight + pWindow(WinHandle)^.BorderTop + pWindow(WinHandle)^.BorderBottom)
      else
        intuition.ChangeWindowBox(pWindow(WinHandle),  FLeft,  FTop, FWidth, FHeight);    
      //fpgSendMessage(nil, Self, FPGM_PAINT, MsgP);
    end;  
  end;
  FSkipResizeMessage := False;
  //writeln('<<< Leave Resize ', self.classname);
end;

function TfpgArosWindow.DoWindowToScreen(ASource: TfpgWindowBase; const AScreenPos: Classes.TPoint): Classes.TPoint;
begin
  //if not TfpgArosWindow(ASource).HandleIsValid then
  //  Exit; //==>
  //Result.X := AScreenPos.X + pWindow(TfpgArosWindow(ASource).WinHandle)^.LeftEdge + pWindow(TfpgArosWindow(ASource).WinHandle)^.BorderLeft;
  //Result.Y := AScreenPos.Y + pWindow(TfpgArosWindow(ASource).WinHandle)^.TopEdge + pWindow(TfpgArosWindow(ASource).WinHandle)^.BorderTop;
  if ASource.Parent = nil then
  begin
    Result.X := pWindow(TfpgArosWindow(ASource).WinHandle)^.LeftEdge + pWindow(TfpgArosWindow(ASource).WinHandle)^.BorderLeft + AScreenPos.X;
    Result.Y := pWindow(TfpgArosWindow(ASource).WinHandle)^.TopEdge + pWindow(TfpgArosWindow(ASource).WinHandle)^.BorderTop + AScreenPos.Y;
  end else
  begin
    Result.X := pWindow(TfpgArosWindow(ASource).WinHandle)^.RelLeftEdge + pWindow(TfpgArosWindow(ASource).WinHandle)^.BorderLeft + AScreenPos.X;
    Result.Y := pWindow(TfpgArosWindow(ASource).WinHandle)^.RelTopEdge + pWindow(TfpgArosWindow(ASource).WinHandle)^.BorderTop + AScreenPos.Y;
    Result := TfpgArosWindow(ASource).Parent.DoWindowToScreen(TfpgArosWindow(ASource).Parent, Result);
  end;
end;


{
procedure TfpgArosWindow.MoveToScreenCenter;
begin
end;
}

procedure TfpgArosWindow.DoSetWindowTitle(const ATitle: string);
var
  ScTitle: string;
begin
  FTitle := ATitle;
  ScTitle := ScreenTitle;
  SetWindowTitles(pWindow(WinHandle), PChar(FTitle), PChar(ScTitle));
end;

procedure TfpgArosWindow.DoSetMouseCursor;
begin
  
  if not HasHandle then
    Exit;
  //writeln('Do Set Cursor ', Ord(FMouseCursor), ' busy: ', Ord(mcHourGlass));  
  case FMouseCursor of
    mcHourGlass:
    begin
      SetWindowPointer(PWindow(FWinHandle), [WA_BusyPointer, True, TAG_DONE, 0]);
    end;  
    else
      SetWindowPointer(PWindow(FWinHandle), [WA_BusyPointer, False, TAG_DONE, 0]);
  end;  
end;

procedure TfpgArosWindow.DoDNDEnabled(const AValue: boolean);
begin
  { Aros has nothing to do here }
end;

procedure TfpgArosWindow.DoAcceptDrops(const AValue: boolean);
begin
  { Aros has nothing to do here }
end;

procedure TfpgArosWindow.DoDragStartDetected;
begin
  inherited DoDragStartDetected;
end;

function TfpgArosWindow.GetWindowState: TfpgWindowState;
begin
  Result := inherited GetWindowState;
end;

constructor TfpgArosWindow.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FSkipNextResizeMessage := False;
  FWinHandle := 0;
  FParent := nil;
  FDropPos.x := 0;
  FDropPos.y := 0;
  FFullscreenIsSet := false;
  FUserMimeSelection := '';
  FUserAcceptDrag := False;
end;

destructor TfpgArosWindow.Destroy;
begin
  inherited Destroy;
end;

procedure TfpgArosWindow.ActivateWindow;
begin
  //writeln(self.classname, ' activated');
  if HandleIsValid then
    intuition.ActivateWindow(pWindow(WinHandle));
end;

procedure TfpgArosWindow.CaptureMouse;
begin
  wapplication.CapturedWindow := self;
  //writeln('-> capture ', self.classname);
end;

procedure TfpgArosWindow.ReleaseMouse;
begin
  wapplication.CapturedWindow := nil;
  //writeln('<- release ', self.classname);
end;

procedure TfpgArosWindow.SetFullscreen(AValue: Boolean);
begin
  inherited SetFullscreen(AValue);
end;

procedure TfpgArosWindow.BringToFront;
begin
  if HandleIsValid then
    WindowToFront(pWindow(WinHandle));
end;

function TfpgArosWindow.HandleIsValid: boolean;
begin
  Result := FWinHandle > 0;
end;

{ TfpgArosCanvas }

constructor TfpgArosCanvas.Create(AWin: TfpgWindowBase);
begin
  inherited;
  FDrawing      := False;
  FDrawWindow   := nil;
end;

destructor TfpgArosCanvas.Destroy;
begin
  if FDrawing then
    DoEndDraw;
  inherited;
end;

procedure TfpgArosCanvas.DoBeginDraw(awin: TfpgWindowBase; buffered: boolean);
var
  Win: pWindow;
begin
  FDrawWindow := nil; 
  if not Assigned(AWin) then
    Exit;
  FDrawWindow := TfpgArosWindow(awin);
  if FDrawWindow.FWinHandle = 0 then
    Exit;  
  DrawPen := LongWord(-1);
  Win := PWindow(FDrawWindow.FWinHandle);
  FRastPort :=  Win^.RPort;
  RWidth := FDrawWindow.Width;
  RHeight := FDrawWindow.Height;
  FLineStyle := lsSolid;
  FDrawing := TfpgArosWindow(AWin).Visible;
  FLocalRastPort := nil;
  FBuffered := False;
  FBuffered := Buffered;
  if FBuffered then
  begin
    FLocalRastPort := FRastPort;
    FRastPort := CreateRastPort;
    FRastPort^.Layer := nil;
    FRastPort^.Bitmap := AllocBitMap(RWidth, RHeight, FLocalRastPort^.Bitmap^.Depth, BMF_CLEAR, FLocalRastPort^.Bitmap);
  end;
  SetDrMd(FRastPort, JAM1);
  wapplication.DrawRastPort := FRastPort;
end;

procedure TfpgArosCanvas.DoPutBufferToScreen(x, y, w, h: TfpgCoord);
begin
  if (not FDrawing) or (not FBuffered) then
    Exit;
  BltBitMapRastPort(FRastPort^.Bitmap, 0,0,  FLocalRastPort, x, y, w, h, $00C0);
end;

procedure TfpgArosCanvas.DoEndDraw;
begin
  if FBuffered then
  begin
    FreeBitmap(FRastPort^.Bitmap);
    FreeRastPort(FRastPort);
  end;
  FBuffered := False;
  FLocalRastPort := nil;
  FRastPort := nil;
  FDrawing    := False;
  FDrawWindow := nil;
  wapplication.DrawRastPort := nil;
end;

function TfpgArosCanvas.GetPixel(X, Y: integer): TfpgColor;
var
  pv: pView;
  V: PViewPort;
begin
  pv := ViewAddress();
  V := pv^.ViewPort;
  Result := ReadPixel(FRastPort, x, y);
  Result := GetRGB4(V^.ColorMap, Result);
end;

procedure TfpgArosCanvas.SetPixel(X, Y: integer; const AValue: TfpgColor);
begin
  if not FDrawing then
    Exit;
  DoSetColor(AValue);
  WritePixel(FRastPort, x, y);
end;

procedure TfpgArosCanvas.DoDrawArc(x, y, w, h: TfpgCoord; a1, a2: Extended);
var
  CX, CY, EX, EY: Longint;
begin
  if not FDrawing then
    Exit;
  EX := w div 2;
  Ey := h div 2;
  CX := x + EX;
  CY := y + EY;
  DrawEllipse(FRastPort, CX , CY, EX, EY);
end;

procedure TfpgArosCanvas.DoFillArc(x, y, w, h: TfpgCoord; a1, a2: Extended);
var
  CX, CY, EX, EY: Longint;
begin
  if not FDrawing then
    Exit;
  EX := w div 2;
  Ey := h div 2;
  CX := x + EX;
  CY := y + EY;
  DrawEllipse(FRastPort, CX , CY, EX, EY);
end;

procedure TfpgArosCanvas.DoDrawPolygon(Points: PPoint; NumPts: Integer; Winding: boolean);
var
  i: Integer;
begin
  if not FDrawing then
    Exit;
  if NumPts < 1 then
    Exit;
  GfxMove(FRastPort, Points[0].X, Points[0].Y);
  for i := 1 to NumPts - 1 do
  begin
    Draw(FRastPort, Points[i].X, Points[i].Y);
  end;
  Draw(FRastPort, Points[0].X, Points[0].Y);
end;

procedure TfpgArosCanvas.DoAddClipRect(const ARect: TfpgRect);
begin
  if not FDrawing then
    Exit;
  //writeln('Add Clip Rect ', Arect.LEft,' , ',ARect.Top);
  FClipRect    := ARect;
  FClipRectSet := True;
end;

procedure TfpgArosCanvas.DoClearClipRect;
begin
  if not FDrawing then
    Exit;
  //writeln('Clear Clip Rect');
  FClipRectSet := False;
end;

procedure TfpgArosCanvas.DoDrawLine(x1, y1, x2, y2: TfpgCoord);
begin
  if not FDrawing then
    Exit;
  GfxMove(FRastPort, x1, y1);
  Draw(FRastPort, x2, y2);
end;

procedure TfpgArosCanvas.DoDrawRectangle(x, y, w, h: TfpgCoord);
var
  r: TfpgRect;
begin
  if not FDrawing then
    Exit;
  r.SetRect(x, y, w, h);
  DoDrawLine(r.Left, r.Top, r.Right, r.Top);
  DoDrawLine(r.Right, r.Top, r.Right, r.Bottom);
  DoDrawLine(r.Right, r.Bottom, r.Left, r.Bottom);
  DoDrawLine(r.Left, r.Bottom, r.Left, r.Top);
end;

procedure TfpgArosCanvas.DoDrawString(x, y: TfpgCoord; const txt: string);
var
  Tags: TTagsList;
  Tags2: TTagsList;
begin
  if not FDrawing then
    Exit;
  if Length(txt) < 1 then
    Exit;
  if TextPen <> -1 then
  begin
    AddTags(Tags, [LongInt($80000080), LongInt(False), LongInt($80000081), LongInt(TextPen), LongInt(TAG_DONE), 0]);
    SetRPAttrsA(FRastPort, GetTagPtr(Tags));
  end;
  GfxMove(FRastPort, x, y + FCurFontRes.GetHeight - 2);// + (3*(FCurFontRes.GetHeight div 4)));
  GfxText(FRastPort, PChar(txt), Length(txt));
  if DrawPen <> -1 then
  begin
    AddTags(Tags2, [LongInt($80000080), LongInt(False), LongInt($80000081), LongInt(DrawPen), LongInt(TAG_DONE), 0]);
    SetRPAttrsA(FRastPort, GetTagPtr(Tags2));
  end;
  //writeln('write: "'+txt+'" with ', FCurFontRes.Desc);
end;

procedure TfpgArosCanvas.DoFillRectangle(x, y, w, h: TfpgCoord);
begin
  if not FDrawing then
    Exit;
  RectFill(FRastPort, x, y, x + w, y + h);
end;

procedure TfpgArosCanvas.DoFillTriangle(x1, y1, x2, y2, x3, y3: TfpgCoord);
begin
  if not FDrawing then
    Exit;
  GfxMove(FRastPort, x1, y1);
  Draw(FRastPort, x2, y2);
  Draw(FRastPort, x3, y3);
  Draw(FRastPort, x1, y1);
end;

function TfpgArosCanvas.DoGetClipRect: TfpgRect;
begin
  Result := FClipRect;
end;

procedure TfpgArosCanvas.DoGetWinRect(out r: TfpgRect);
begin
  r.Left := FDrawWindow.Left;
  r.Top := FDrawWindow.Top;
  r.Width := FDrawWindow.Width;
  r.Height := FDrawWindow.Height;
  //writeln(FDrawWindow.Classname,' Do Get WinRect ', r.Width,' x ',r.Height);
end;

procedure TfpgArosCanvas.DoSetClipRect(const ARect: TfpgRect);
begin
  //writeln('set clip rest ', ARect.Left , ',', ARect.top );
  FClipRectSet := True;
  FClipRect    := ARect;
end;

function TfpgArosCanvas.GatherPen(cl: TfpgColor): LongWord;
var
  c: LongWord;
  r: LongWord;
  g: LongWord;
  b: LongWord;
begin
  c := fpgColorToWin(cl);
  b := (c and $00FF0000) shr 16;
  g := (c and $0000FF00);
  r := (c and $000000FF) shl 16;
  Result := r or g or b;
end;

procedure TfpgArosCanvas.DoSetColor(cl: TfpgColor);
var
  Tags: TTagsList;
begin
  if not FDrawing then
    Exit;
  DrawPen := GatherPen(cl);
  AddTags(Tags, [LongInt($80000080), LongInt(False), LongInt($80000081), LongInt(DrawPen), LongInt(TAG_DONE), 0]);
  SetRPAttrsA(FRastPort, GetTagPtr(Tags));
end;

procedure TfpgArosCanvas.DoSetLineStyle(awidth: integer; astyle: TfpgLineStyle);
begin
  if not FDrawing then
    Exit;
  case AStyle of
    lsDot: FRastPort^.LinePtrn := $AAAA;
    lsDash: FRastPort^.LinePtrn := $FF00;
    lsSolid: FRastPort^.LinePtrn := $FFFF;
  end;
  FPenWidth := AWidth;
  FLineStyle := aStyle;
  FRastPort^.PenWidth := AWidth;
  FRastPort^.PenHeight := AWidth;
end;

procedure TfpgArosCanvas.DoSetTextColor(cl: TfpgColor);
begin
  TextPen := GatherPen(cl);
end;

procedure TfpgArosCanvas.DoSetFontRes(fntres: TfpgFontResourceBase);
begin
  if not FDrawing then
    Exit;
  if fntres = nil then
    Exit; //==>
  FCurFontRes := TfpgArosFontResource(fntres);
  if FCurFontRes.FFontData <> nil then
    agraphics.SetFont(FRastPort, FCurFontRes.FFontData);
end;

procedure TfpgArosCanvas.DoDrawImagePart(x, y: TfpgCoord; img: TfpgImageBase; xi, yi, w, h: integer);
var
  NImg: TfpgArosImage;
begin
  if not FDrawing then
    Exit;
  if img = nil then
    Exit; //==>
  NImg := TfpgArosImage(Img);
  WritePixelArrayAlpha(NImg.FImage, xi, yi, NImg.Width * SizeOf(LongWord), FRastPort, x, y, w, h, 255);
end;

procedure TfpgArosCanvas.DoXORFillRectangle(col: TfpgColor; x, y, w, h: TfpgCoord);
var
  OldDrawMode: LongWord;
begin
  if not FDrawing then
    Exit;
  oldDrawMode := GetDrMd(FRastPort);
  SetDrMd(FRastPort, COMPLEMENT);
  DoSetColor(col);
  RectFill(FRastPort, x, y, x + w, y + h);
  SetDrMd(FRastPort, OldDrawMode);
end;

{ TfpgArosFontResource }

constructor TfpgArosFontResource.Create(const afontdesc: string);
begin
  //Writeln('create font: ', afontdesc);
  FFontData := OpenFontByDesc(afontdesc);
  Desc := AFontDesc;
end;

destructor TfpgArosFontResource.Destroy;
begin
  if HandleIsValid then
    CloseFont(FFontData);
  inherited;
end;


function TfpgArosFontResource.OpenFontByDesc(const desc: string): pTextFont;

var
  facename: string;
  cp: integer;
  c: char;
  token: string;
  prop: string;
  TextAttr: tTextAttr;
  Height: integer;
  i, Idx: Integer;
  Filename: string;
  IsBold: Boolean;
  IsItalic: Boolean;

  function NextC: char;
  begin
    Inc(cp);
    if cp > length(desc) then
      c := #0
    else
      c := desc[cp];
    Result := c;
  end;

  procedure NextToken;
  begin
    token := '';
    while (c <> #0) and (c in [' ', 'a'..'z', 'A'..'Z', '_', '0'..'9']) do
    begin
      token := token + c;
      NextC;
    end;
  end;
begin
  cp := 0;
  Height := 11;
  NextC;
  NextToken;
  facename := token + #0;

  if c = '-' then
  begin
    NextC;
    NextToken;
    Height := StrToIntDef(token, 8);
  end;
  TextAttr.ta_Style := FS_NORMAL;
  IsItalic := False;
  IsBold := False;
  while c = ':' do
  begin
    NextC;
    NextToken;
    prop    := UpperCase(token);

    if c = '=' then
    begin
      NextC;
      NextToken;
    end;
    
    if Prop = 'BOLD' then
      IsBold := True;
    if Prop = 'ITALIC' then
      IsItalic := True;  
      
    if prop = 'BOLD' then
    begin
      TextAttr.ta_Style := TextAttr.ta_Style or FSF_BOLD;
    end; 
    if prop = 'ITALIC' then
    begin
      TextAttr.ta_Style := TextAttr.ta_Style or FSF_ITALIC
    end;
  end;
  Idx := -1;
  for i := 0 to High(AROSFontList) do
  begin
    if LowerCase(trim(facename)) = AROSFontList[i].BaseName then
    begin
      Idx := i;
      Break;
    end;
  end;
  if Idx >= 0 then
  begin
    Filename := AROSFontList[i].Normal;
    if IsItalic then
    begin
      if IsBold then
        Filename := AROSFontList[i].BoldItalic
      else
        Filename := AROSFontList[i].Italic; 
    end else
    begin
      if IsBold then
        Filename := AROSFontList[i].Bold
      else
        Filename := AROSFontList[i].Normal;   
    end;  
  end else
  begin
    FileName := facename + '.font'; 
  end;  
  
  TextAttr.ta_Name := PChar(FileName);
  TextAttr.ta_YSize := Height;
  TextAttr.ta_Flags := FPF_DISKFONT;
  Result := OpenDiskFont(@TextAttr);
  {if Result = nil then
    writeln(idx,' cant open Font ', desc, ' filename: ', FileName)
  else
    writeln(idx,' successful open Font ', desc, ' filename: ', FileName);
   } 
end;


function TfpgArosFontResource.HandleIsValid: boolean;
begin
  Result := TRUE;
  //;FFontData <> nil;
end;

function TfpgArosFontResource.GetAscent: integer;
begin
  Result := 2;
  //writeln('get Ascent ', Result);
end;

function TfpgArosFontResource.GetDescent: integer;
begin
  Result := 1;
  //writeln('get Descent ', Result);
end;

function TfpgArosFontResource.GetHeight: integer;
var
  ext: tTextExtent;
begin
  Result := 9;
  if Assigned(FFontData) then
  begin
    FontExtent(FFontData, @ext);
    Result := ext.te_Height + 5;
    //writeln(desc ,' Height -> ', ext.te_Height, ',  ', ext.te_Width);
    //write('-')
  end;
  //writeln('get Height ', Result);
end;

function TfpgArosFontResource.GetTextWidth(const txt: string): integer;
var
  RastPort: pRastPort;
  OwnRP: Boolean;
  str: string;
begin
  if length(txt) < 1 then
  begin
    Result := 0;
    Exit;
  end;
  str := txt;
  if Assigned(wapplication.DrawRastPort) then
  begin
    RastPort := wapplication.DrawRastPort;
    OwnRP := False;
  end else
  begin
    RastPort := CreateRastPort;
    RastPort^.Bitmap := AllocBitMap(100, 100, 1, BMF_CLEAR, nil);
    agraphics.SetFont(RastPort, FFontData);
    OwnRP := True;
  end;  
  try    
    Result := TextLength(RastPort, PChar(str), Length(str));
  finally
    if OwnRP then
    begin
      FreeBitmap(RastPort^.Bitmap);
      RastPort^.Bitmap := nil;
      FreeRastPort(RastPort);
      RastPort := nil;
    end;
  end;
  //writeln('get Text width "',txt,'" ', Result, ' ownrp: ', OwnRP);
end;

{ TfpgArosImage }

constructor TfpgArosImage.Create;
begin
  inherited;
  FImage := nil;
end;

procedure TfpgArosImage.DoFreeImage;
begin
  FreeMem(FImage);
end;

procedure TfpgArosImage.DoInitImage(acolordepth, awidth, aheight: integer; aimgdata: Pointer);
var
  Col: PLongWord;
  c: LongWord;
  Aim, Src: PLongWord;
  x, y, i: Integer;
begin
  if acolordepth > 1 then
  begin
    if Assigned(FImage) then
    begin
      if (FWidth <> AWidth) or (FHeight <> AHeight) then
      begin
        FreeMem(FImage);
        FImage := GetMem(AWidth * AHeight * SizeOf(LongWord));
      end;
    end else
    begin
      FImage := GetMem(AWidth * AHeight * SizeOf(LongWord));
    end;
    FWidth := AWidth;
    FHeight := AHeight;
    Src := Pointer(AImgData);
    Aim := Pointer(FImage);
    for i := 0 to (AWidth * AHeight) - 1 do
    begin
      {$ifdef ENDIAN_LITTLE}
      Aim^ := SwapEndian(Src^);
      {$else}
      Aim^ := Src^;
      {$endif}
      PARGBPixel(Aim)^.A := 255;
      Inc(Src);
      Inc(Aim);
    end;
  end;
end;

procedure TfpgArosImage.DoInitImageMask(awidth, aheight: integer; aimgdata: Pointer);
var
  x,y: Integer;
  c: PARGBPixel;
  Shift: Integer;
  Mask: PLongWord;
  M: LongWord;
begin
  if Assigned(FImage) and (FWidth = AWidth) and (FHeight = AHeight) then
  begin
    c := FImage;
    Shift := 0;
    Mask := AimgData;
    M := SwapEndian(Mask^);
    for y := 0 to AHeight - 1 do
    begin
      for x := 0 to AWidth - 1 do
      begin   
        if M and (1 shl (31 - Shift)) <> 0 then
          c^.A := 255
        else
          c^.A := 0;          
        Inc(Shift);
        if Shift > 31 then
        begin
          Inc(Mask);
          {$ifdef ENDIAN_LITTLE}
          M := SwapEndian(Mask^);
          {$else}
          M := Mask^;
          {$endif}
          Shift := 0;
        end;        
        Inc(c);
      end;
      if Shift > 0 then
      begin
        Inc(Mask);
        {$ifdef ENDIAN_LITTLE}
        M := SwapEndian(Mask^);
        {$else}
        M := Mask^;
        {$endif}
        Shift := 0;
      end;
    end;
  end;
end;

{ TfpgArosClipboard }

function TfpgArosClipboard.DoGetText: TfpgString;
begin
  Result := GetTextFromClip(PRIMARY_CLIP);
end;

procedure TfpgArosClipboard.DoSetText(const AValue: TfpgString);
begin
  PutTextToClip(PRIMARY_CLIP, AValue);
end;

procedure TfpgArosClipboard.InitClipboard;
begin
  // nothing to do here
end;


{ TfpgArosFileList }

function TfpgArosFileList.EncodeAttributesString(attrs: longword
  ): TFileModeString;
begin
  Result := ' ';
  //writeln(' attrs: ' + IntToHex(Attrs,8));
  if (attrs and faArchive) <> 0 then Result := Result + 'a' else Result := Result + '-';
  if (attrs and faReadOnly) <> 0 then Result := Result + 'r-' else Result := Result + 'rw';
  //if (attrs and faScript) <> 0 then Result := Result + 's' else Result := Result + '-';
  //if (attrs and faRead) <> 0 then Result := Result + 'r' else Result := Result + '-';
  //if (attrs and faWrite) <> 0 then Result := Result + 'w' else Result := Result + '-';
  //if (attrs and faExecute) <> 0 then Result := Result + 'e' else Result := Result + '-';
  //if (attrs and faDelete) <> 0 then Result := Result + 'd' else Result := Result + '-';

end;

constructor TfpgArosFileList.Create;
begin
  inherited Create;
  FHasFileMode := false;
end;

function TfpgArosFileList.InitializeEntry(sr: TSearchRec): TFileEntry;
begin
  Result := inherited InitializeEntry(sr);

  if Assigned(Result) then
  begin
    // using sr.Attr here is incorrect and needs to be improved!
    //writeln('File: ', sr.Name , ' attr: $', inttohex(sr.Attr, 8));
    if (sr.Attr and 16) <> 0 then
      Result.EntryType := etDir
    else
      Result.EntryType := etFile;

    Result.Attributes   := EncodeAttributesString(sr.Attr);
    Result.IsExecutable := (LowerCase(Result.Extension) = '.exe');
  end;
end;



procedure ReadInDevices;

begin
  
end;


procedure TfpgArosFileList.PopulateSpecialDirs(const aDirectory: TfpgString);
const
  IgnoreDevs: array[0..10] of string =('NIL:','XPIPE:','EMU:','PED:','PRJ:','PIPE:','CON:','RAW:','SER:','PAR:','PRT:');
  
  function IsInDeviceList(Str : string): Boolean;
  var
    i : Integer;
  begin
    IsInDeviceList := False;
    for i := Low(IgnoreDevs) to High(IgnoreDevs) do
    begin
      if Str = IgnoreDevs[i] then
      begin
        IsInDeviceList := True;
        Exit;
      end;
    end;
  end;
  
var
  Dl : PDosList;
  Temp: PChar;
  Str: string;
begin
  Forbid();
  FSpecialDirs.Clear;
  Dl := LockDosList(LDF_DEVICES or LDF_READ);
  repeat
     Dl := NextDosEntry(Dl, LDF_DEVICES);
     if Dl <> nil then
     begin
       Temp := PChar(Dl^.dol_Handler.dol_Name);
       //Temp := BSTR2STRING(Dl^.dol_Name);
       Str := StrPas(Temp) + ':';
       if not IsInDeviceList(Str) then
       begin
         FSpecialDirs.Add(str);
       end;  
     end;
  until Dl = nil;
  UnLockDosList(LDF_DEVICES or LDF_READ);
  Dl := LockDosList(LDF_VOLUMES or LDF_READ);
  repeat
     Dl := NextDosEntry(Dl, LDF_VOLUMES);
     if Dl <> nil then
     begin
       Temp := PChar(Dl^.dol_Handler.dol_Name);
       //Temp := BSTR2STRING(Dl^.dol_Name);
       Str := StrPas(Temp) + ':';
       if not IsInDeviceList(Str) then
       begin
         FSpecialDirs.Add(str);
       end;  
     end;
  until Dl = nil;
  UnLockDosList(LDF_VOLUMES or LDF_READ);
  Dl := LockDosList(LDF_ASSIGNS or LDF_READ);
  repeat
     Dl := NextDosEntry(Dl, LDF_ASSIGNS);
     if Dl <> nil then
     begin
       Temp := PChar(Dl^.dol_Handler.dol_Name);
       //Temp := BSTR2STRING(Dl^.dol_Name);
       Str := StrPas(Temp) + ':';
       if not IsInDeviceList(Str) then
       begin
         FSpecialDirs.Add(str);
       end;  
     end;
  until Dl = nil;
  UnLockDosList(LDF_ASSIGNS or LDF_READ);
  Permit();
  inherited PopulateSpecialDirs(aDirectory);
end;

{ TfpgArosDrag }

function TfpgArosDrag.GetSource: TfpgArosWindow;
begin
  Result := FSource;
end;

destructor TfpgArosDrag.Destroy;
begin
  {$IFDEF DND_DEBUG}
  writeln('TfpgArosDrag.Destroy ');
  {$ENDIF}
  inherited Destroy;
end;

function TfpgArosDrag.Execute(const ADropActions: TfpgDropActions; const ADefaultAction: TfpgDropAction): TfpgDropAction;
begin
  Result := daIgnore;
end;

{ TfpgArosTimer }

procedure TfpgArosTimer.SetEnabled(const AValue: boolean);
begin
  inherited SetEnabled(AValue);
end;

constructor TfpgArosTimer.Create(AInterval: integer);
begin
  inherited Create(AInterval);
  FHandle := 0;
end;


initialization
  wapplication   := nil;
finalization

end.

