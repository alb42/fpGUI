{
  Log to a window above the application's main form, but only if
  the -lv parameter is passed on the command line
  
  This in normally controlled by the tiLogReg unit.
}
unit tiLogToGUI;

{$mode objfpc}{$H+}

interface
uses
  Classes, SysUtils,
  gfx_widget, gui_form, gui_memo, gui_menu, gui_panel, gui_button, fpgfx,
  tiLog;

type
  TtiLogToGUI = class(TtiLogToCacheAbs)
  private
    FForm: TfpgForm;
    FMemoLog: TfpgMemo;
    FToolBar: TfpgPanel;
    FPopupMenu: TfpgPopupMenu;
    FSeveritySubMenu: TfpgPopupMenu;
    FLogMenuItem: TfpgMenuItem;
    FViewLogMenuItem: TfpgMenuItem;
    FWordWrapMenuItem: TfpgMenuItem;
    function    GetFormParent: TfpgWidget;
    procedure   SetFormParent(const AValue: TfpgWidget);
    function    CreateForm: TfpgForm;
    procedure   FormClearMenuItemClick(Sender: TObject);
    procedure   FormWordWrapMenuItemClick(Sender: TObject);
    procedure   FormLogMenuItemClick(Sender: TObject);
    procedure   FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure   FormLogLevelMenuItemClick(Sender: TObject);
    procedure   FormLogLevelButtonClick(Sender: TObject);
    procedure   DoViewLogFile(Sender: TObject);
    procedure   DoOnPopup(Sender: TObject);
    procedure   WriteToMemo(const AMessage: string);
  protected
    procedure   WriteToOutput; override;
    procedure   SetSevToLog(const AValue: TtiSevToLog); override;
  public
    constructor Create; override;
    destructor  Destroy; override;
    property    FormParent: TfpgWidget read GetFormParent; // write SetFormParent;
    procedure   Log(const ADateTime, AThreadID, AMessage: string; ASeverity: TtiLogSeverity); override;
  end;


implementation
uses
  gfxbase,
  tiUtils,
  tiGUIUtils,
  tiCommandLineParams,
  tiGUIConstants,
  tiDialogs;


{ TtiLogToGUI }

constructor TtiLogToGUI.Create;
begin
  // GUI output must be synchronized with the main thread.
  inherited CreateSynchronized;
  FForm := CreateForm;
  ThrdLog.Resume;
end;

destructor TtiLogToGUI.Destroy;
begin
//  writeln('>> TtiLogToGUI.Destroy');
  FForm := nil;
  inherited Destroy;
//  writeln('<< TtiLogToGUI.Destroy');
end;

function TtiLogToGUI.CreateForm: TfpgForm;
var
  lMenuItem: TfpgMenuItem;
  lLogSev: TtiLogSeverity;
  lToolButton: TfpgButton;
  x: integer;
begin
  FForm                     := TfpgForm.Create(fpgApplication);
  FForm.WindowPosition      := wpUser;
  FForm.Top                 := 10;
  FForm.Left                := 10;
  FForm.Height              := 150;
  FForm.Width               := fpgApplication.ScreenWidth - 20;
  FForm.WindowTitle         := 'Application event log - ' + ApplicationName;
  FForm.OnCloseQuery        := @FormCloseQuery;

  FPopupMenu                := TfpgPopupMenu.Create(FForm);
  FPopupMenu.Name           := 'PopupMenu';
  FPopupMenu.BeforeShow     := @DoOnPopup;

  FToolBar                  := TfpgPanel.Create(FForm);
  FToolBar.Name             := 'ToolBar';
  FToolBar.SetPosition(0, 0, FForm.Width, 29);
  FToolBar.Text             := '';
  FToolBar.Align            := alTop;
  FToolBar.TabOrder         := 1;

  FMemoLog                  := TfpgMemo.Create(FForm);
  FMemoLog.Name             := 'MemoLog';
  FMemoLog.Top              := 29;
  FMemoLog.Align            := alClient;
  FMemoLog.FontDesc         := '#Edit2';  // monospaced font
  FMemoLog.PopupMenu        := FPopupMenu;
//  FMemoLog.ReadOnly         := True;
//  FMemoLog.ScrollBars       := ssBoth;
  FMemoLog.TabOrder         := 0;
//  FMemoLog.WordWrap         := False;
  FMemoLog.Lines.Clear;

  FViewLogMenuItem          := FPopupMenu.AddMenuItem('View log file', '', @DoViewLogFile);
  FViewLogMenuItem.Name     := 'Viewlogfile1';

  lMenuItem                 := FPopupMenu.AddMenuItem('-', '', nil);
  lMenuItem.Name            := 'N1';

  lMenuItem                 := FPopupMenu.AddMenuItem('Clear', '', @FormClearMenuItemClick);
  lMenuItem.Name            := 'ClearMenuItem';

  FWordWrapMenuItem         := FPopupMenu.AddMenuItem('Word wrap', '', @FormWordWrapMenuItemClick);
  FWordWrapMenuItem.Name    := 'WordWrapMenuItem';
  FWordWrapMenuItem.Enabled := False;

  FLogMenuItem              := FPopupMenu.AddMenuItem('Log', '', @FormLogMenuItemClick);
  FLogMenuItem.Name         := 'LogMenuItem';

  FSeveritySubMenu          := TfpgPopupMenu.Create(FForm);
  FSeveritySubMenu.Name    := 'SeveritySubMenu';
  for lLogSev := Low(TtiLogSeverity) to High(TtiLogSeverity) do
  begin
    lMenuItem              := FSeveritySubMenu.AddMenuItem(cTILogSeverityStrings[lLogSev], '', @FormLogLevelMenuItemClick);
    lMenuItem.Tag          := Ord(lLogSev);
  end;
  FLogMenuItem.SubMenu := FSeveritySubMenu;

  x := 0;
  for lLogSev := Low(TtiLogSeverity) to High(TtiLogSeverity) do
  begin
    lToolButton           := TfpgButton.Create(FToolBar);
    lToolButton.SetPosition(x, 0, 50, 30);
    lToolButton.Text      := cTILogSeverityStrings[lLogSev];
    lToolButton.Tag       := Ord(lLogSev);
    lToolButton.AllowDown := True;
    lToolButton.AllowAllUp := True;
    lToolButton.Down      := lLogSev in GLog.SevToLog;
    lToolButton.OnClick   := @FormLogLevelButtonClick;
    lToolButton.Focusable := False;
    Inc(x, 50);
  end;
  
 Result := FForm;
end;

function TtiLogToGUI.GetFormParent: TfpgWidget;
begin
  result := FForm.Parent;
end;

procedure TtiLogToGUI.Log(const ADateTime, AThreadID, AMessage: string; ASeverity: TtiLogSeverity);
begin
  if Terminated then
    Exit; //==>
  if not FForm.HasHandle then
    FForm.Show;
  inherited Log(ADateTime, AThreadID, AMessage, ASeverity);
end;

procedure TtiLogToGUI.SetFormParent(const AValue: TfpgWidget);
begin
  {$Note This is untested!!! }
  FForm.Parent      := AValue;
  FForm.Align       := alClient;
  FForm.WindowAttributes := FForm.WindowAttributes + [waBorderless];
//  FForm.BorderStyle := bsNone;
end;

procedure TtiLogToGUI.SetSevToLog(const AValue: TtiSevToLog);
var
  i: integer;
  lLogSev: TtiLogSeverity;
begin
  // Let parent perform important task(s)
  inherited;
  // All we do here is reflect any changes to LogSeverity in the visual controls
  for i := 0 to FToolBar.ComponentCount - 1 do
  begin
    lLogSev := TtiLogSeverity(FToolBar.Components[i].Tag);
    if FToolBar.Components[i] is TfpgButton then
      TfpgButton(FToolBar.Components[i]).Down := lLogSev in AValue;
  end;
end;

procedure TtiLogToGUI.WriteToMemo(const AMessage: string);
var
  i: integer;
  LLine: string;
  LCount: integer;
begin
  LCount := tiNumToken(AMessage, CrLf);
  if LCount = 1 then
    FMemoLog.Lines.Add(tiTrimTrailingWhiteSpace(AMessage))
  else
    for i := 1 to LCount do
    begin
      LLine := tiTrimTrailingWhiteSpace(tiToken(AMessage, CrLf, i));
      FMemoLog.Lines.Add(LLine);
    end;
end;

procedure TtiLogToGUI.WriteToOutput;
var
  i: integer;
  LLogEvent: TtiLogEvent;
  LPosStart: integer;
  LPosEnd: integer;
const
  ciMaxLineCount = 200;
begin
  if ThrdLog.Terminated then
    Exit; //==>

  inherited WriteToOutput;

  if ListWorking.Count > ciMaxLineCount * 2 then
  begin
    FMemoLog.Lines.Clear;
    LPosStart := ListWorking.Count - 1 - ciMaxLineCount;
    LPosEnd   := ListWorking.Count - 1;
  end else
  begin
    if FMemoLog.Lines.Count > ciMaxLineCount then
    begin
      for i := 0 to ciMaxLineCount div 2 do
        FMemoLog.Lines.Delete(0);
      //{$IFDEF MSWINDOWS}
      //SendMessage(FMemoLog.handle, WM_VSCROLL, SB_Bottom, 0);
      //{$ENDIF MSWINDOWS}
    end;
    LPosStart := 0;
    LPosEnd   := ListWorking.Count - 1;
  end;

  for i := LPosStart to LPosEnd do begin
    if ThrdLog.Terminated then
      Break; //==>
    LLogEvent := TtiLogEvent(ListWorking.Items[i]);
    WriteToMemo(LLogEvent.AsLeftPaddedString);
  end;

  ListWorking.Clear;
end;

procedure TtiLogToGUI.FormClearMenuItemClick(Sender: TObject);
begin
  FMemoLog.Lines.Clear;
end;

procedure TtiLogToGUI.FormWordWrapMenuItemClick(Sender: TObject);
begin
  //FMemoLog.WordWrap        := not FMemoLog.WordWrap;
  //FWordWrapMenuItem.Checked := FMemoLog.WordWrap;
  //if FMemoLog.WordWrap then
    //FMemoLog.ScrollBars := ssVertical
  //else
    //FMemoLog.ScrollBars := ssBoth;
end;

procedure TtiLogToGUI.FormLogMenuItemClick(Sender: TObject);
var
  i: integer;
begin
  //for i := 0 to FLogMenuItem.Count - 1 do
    //FLogMenuItem.Items[i].Checked := TtiLogSeverity(FLogMenuItem.Items[i].Tag) in GLog.SevToLog;
end;

procedure TtiLogToGUI.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
//  CanClose := False;
  //FForm.WindowState := wsMinimized;
end;

procedure TtiLogToGUI.FormLogLevelMenuItemClick(Sender: TObject);
var
  lLogSev: TtiLogSeverity;
  lLogChecked: boolean;
  i: integer;
  lFound: boolean;
begin
  if not (Sender is TfpgMenuItem) then
    Exit; //==>

  lLogSev := TtiLogSeverity(TfpgWidget(Sender).Tag);
  //TfpgMenuItem(Sender).Checked := not TMenuItem(Sender).Checked;
  //lLogChecked := TMenuItem(Sender).Checked;

  lFound := False;
  i := FToolBar.ComponentCount-1;
  while (i > 0) and not lFound do
  begin
    if FToolBar.Components[i] is TfpgButton then
    begin
      lFound := TfpgButton(FToolBar.Components[i]).Tag = TfpgWidget(Sender).Tag;
      if lFound then
      begin
        TfpgButton(FToolbar.Components[i]).Down := not TfpgButton(FToolbar.Components[i]).Down;
        lLogChecked := TfpgButton(FToolbar.Components[i]).Down;
      end;
    end;
//    FToolBar.Buttons[TMenuItem(Sender).Tag].Down := lLogChecked;
  end;

  if lLogChecked then
    GLog.SevToLog := GLog.SevToLog + [lLogSev]
  else
    GLog.SevToLog := GLog.SevToLog - [lLogSev];
end;

procedure TtiLogToGUI.FormLogLevelButtonClick(Sender: TObject);
var
  lLogSev: TtiLogSeverity;
  lLogChecked: boolean;
begin
  if not (Sender is TfpgButton) then
    Exit; //==>

  lLogSev := TtiLogSeverity(TfpgWidget(Sender).Tag);
  lLogChecked := TfpgButton(Sender).Down;
  if lLogChecked then
    GLog.SevToLog := GLog.SevToLog + [lLogSev]
  else
    GLog.SevToLog := GLog.SevToLog - [lLogSev];
end;

procedure TtiLogToGUI.DoViewLogFile(Sender: TObject);
var
  sl: TStringList;
begin
  if (GLog.LogToFileName <> '') and
     (FileExists(GLog.LogToFileName)) then
  begin
    sl := TStringList.Create;
    try
      sl.LoadFromFile(GLog.LogToFilename);
      tiShowStringList(sl, GLog.LogToFilename);
//      tiEditFile(GLog.LogToFileName);
    finally
      sl.Free;
    end;
  end;
end;

procedure TtiLogToGUI.DoOnPopup(Sender: TObject);
begin
  FViewLogMenuItem.Visible:=
    (GLog.LogToFileName <> '') and
    (FileExists(GLog.LogToFileName));
end;


//initialization
  //if gCommandLineParams.IsParam(csLogVisual) then
    //GLog.RegisterLog(TtiLogToGUI);

end.
