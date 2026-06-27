unit MRUMenu;

{$mode ObjFPC}{$H+}
interface

uses
  Classes, SysUtils, Menus, Dialogs;

type
  TMRUFileEvent = procedure(Sender: TObject; const FileName: string) of object;

  { TMRUMenuManager }

  TMRUMenuManager = class
  private
    FFileList: TStringList;
    FMaxFiles: Integer;
    FMenu: TMenuItem;
    FOnOpenFile: TMRUFileEvent;
    FIniPath : string;
    FIniSection : string;
    function GetCount: Integer;
    procedure SetMaxFiles(AValue: Integer);
  public
    constructor Create(AMenu: TMenuItem; AMaxFiles: Integer = 5);
    destructor Destroy; override;

    procedure AddFile(const FileName: string);
    procedure RemoveFile(const FileName: string);
    procedure Clear;
    procedure RefreshMenu;
    procedure MenuItemClick(Sender: TObject);

    procedure LoadFromIni(const IniPath: string; const Section: string = 'MRU');
    procedure SaveToIni(const IniPath: string; const Section: string = 'MRU');

    property Count: Integer read GetCount;
    property MaxFiles: Integer read FMaxFiles write SetMaxFiles;
    property OnOpenFile: TMRUFileEvent read FOnOpenFile write FOnOpenFile;
  end;

implementation

Uses
  IniFiles;

{ TMRUMenuManager }

constructor TMRUMenuManager.Create(AMenu: TMenuItem; AMaxFiles: Integer);
begin
  FFileList := TStringList.Create;
  FFileList.Duplicates := dupIgnore;
  FFileList.Sorted := False;

  FMenu := AMenu;
  FMaxFiles := AMaxFiles;
end;

destructor TMRUMenuManager.Destroy;
begin
  FFileList.Free;
  inherited Destroy;
end;

function TMRUMenuManager.GetCount: Integer;
begin
  Result := FFileList.Count;
end;

procedure TMRUMenuManager.SetMaxFiles(AValue: Integer);
begin
  if FMaxFiles <> AValue then
  begin
    FMaxFiles := AValue;
    if FFileList.Count > FMaxFiles then
    begin
      while FFileList.Count > FMaxFiles do
        FFileList.Delete(FFileList.Count - 1);
      RefreshMenu;
    end;
  end;
end;

procedure TMRUMenuManager.AddFile(const FileName: string);
var
  Idx: Integer;
begin

  // If file exists, move it to the top of the list
  Idx := FFileList.IndexOf(FileName);
  if Idx <> -1 then
  begin
    FFileList.Delete(Idx);
  end;

  FFileList.Insert(0, FileName);

  // Enforce max files limit
  if FFileList.Count > FMaxFiles then
    FFileList.Delete(FFileList.Count - 1);

  RefreshMenu;
end;

procedure TMRUMenuManager.RemoveFile(const FileName: string);
var
  Idx: Integer;
begin
  if FileName = '' then Exit;

  Idx := FFileList.IndexOf(FileName);
  if Idx <> -1 then
  begin
    FFileList.Delete(Idx);
    SaveToIni(Self.FIniPath, self.FIniSection);
    RefreshMenu;
  end;

end;

procedure TMRUMenuManager.Clear;
begin
  FFileList.Clear;
  RefreshMenu;
end;

procedure TMRUMenuManager.RefreshMenu;
var
  i: Integer;
  NewItem: TMenuItem;
begin
  // Clear existing dynamically generated items under this parent menu
  while FMenu.Count > 0 do
  begin
    FMenu.Items[0].Free;
  end;

  // Re-populate menu
  for i := 0 to FFileList.Count - 1 do
  begin
    NewItem := TMenuItem.Create(FMenu.Owner);
    NewItem.Caption := Format('&%d %s', [i + 1, ExtractFileName(FFileList[i])]);
    NewItem.Hint := FFileList[i]; // Store full path in Hint
    NewItem.OnClick := @MenuItemClick;

    FMenu.Add(NewItem);
  end;
end;

procedure TMRUMenuManager.MenuItemClick(Sender: TObject);
var
  ClickedItem: TMenuItem;
begin
  if (Sender is TMenuItem) then
  begin
    ClickedItem := TMenuItem(Sender);
    // Fire event and bring file to the top
    if Assigned(FOnOpenFile) then
      FOnOpenFile(Self, ClickedItem.Hint);
    AddFile(ClickedItem.Hint);
  end;
end;

procedure TMRUMenuManager.LoadFromIni(const IniPath: string;
  const Section: string);
var
  Ini: TIniFile;
  i: Integer;
  CountLoaded: Integer;
  Path: string;
begin
  FFileList.Clear;
  Ini := TIniFile.Create(IniPath);
  try
    CountLoaded := Ini.ReadInteger(Section, 'Count', 0);
    for i := 0 to CountLoaded - 1 do
    begin
      Path := Ini.ReadString(Section, 'File_' + IntToStr(i), '');
      if (Path <> '') and (FFileList.Count < FMaxFiles) then
        FFileList.Add(Path);
    end;
    FIniPath:= IniPath;
    FIniSection:=Section;
  finally
    Ini.Free;
  end;
  RefreshMenu;

end;

procedure TMRUMenuManager.SaveToIni(const IniPath: string; const Section: string
  );
var
  Ini: TIniFile;
  i: Integer;
begin
  Ini := TIniFile.Create(IniPath);
  try
    // Erase existing old values to prevent leftover entries
    Ini.EraseSection(Section);

    Ini.WriteInteger(Section, 'Count', FFileList.Count);
    for i := 0 to FFileList.Count - 1 do
    begin
      Ini.WriteString(Section, 'File_' + IntToStr(i), FFileList[i]);
    end;
  finally
    Ini.Free;
  end;

end;

(*

How to use it in your Form

function TForm1.GetIniPath: string;
begin
  Result := ExtractFilePath(Application.ExeName) + 'config.ini';
end;

procedure TForm1.FormCreate(Sender: TObject);
begin

  MRUMenuMgr := TMRUMenuManager.Create(mnuRecentFiles, 5);
  MRUMenuMgr.OnOpenFile := @MRUMenuMgrOpenFile;
  MRUMenuMgr.LoadFromIni(GetIniPath, 'RecentFiles');
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
  MRUMenuMgr.SaveToIni(GetIniPath, 'RecentFiles');
   MRUMenuMgr.Free;
end;

procedure TForm1.MRUMenuMgrOpenFile(Sender: TObject; const FileName: string);
begin
  If not FileExists(FileName) then
   begin
     Showmessage('File not found: ' + FileName);
     MRUMenuMgr.RemoveFile(FileName);
   end;
  Memo1.Lines.LoadFromFile(FileName);
end;
*)

end.

