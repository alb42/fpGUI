{%mainunit fpg_utils.pas}

uses
  fpg_constants, fpg_stringutils;


function fpgToOSEncoding(aString: TfpgString): string;
begin
  Result := Utf8ToAnsi(aString);
end;

function fpgFromOSEncoding(aString: string): TfpgString;
begin
  Result := AnsiToUtf8(aString);
end;

procedure fpgOpenURL(const aURL: TfpgString);
begin
  try
    //ShellExecute(0, 'open', PChar(aURL), nil, nil, 1 {SW_SHOWNORMAL});
  except
    // do nothing
  end;
end;

function fpgFileSize(const AFilename: TfpgString): integer;
var
  f: File;
begin
  AssignFile(F, AFileName);
  Result := FileSize(F);
end;

