unit ubuildsql;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, SQLite3Conn, SQLDB, Forms, Controls, Graphics, Dialogs,
  StdCtrls, CheckLst, ExtCtrls, SynEdit, SynHighlighterSQL;

type

  { TfrmBuildSql }

  TfrmBuildSql = class(TForm)
    ButtonAddJoin: TButton;
    ButtonAddFields: TButton;
    cbFields: TCheckListBox;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;

    lbTables: TListBox;
    lbJoins: TListBox;
    rbInsert: TRadioGroup;
    rgMisc: TRadioGroup;
    procedure ButtonAddJoinClick(Sender: TObject);

    procedure ButtonAddFieldsClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    function  GetJoinString(ABaseTable,
           AJoinedTable : string; nthFk : integer) : string;
    procedure lbTablesClick(Sender: TObject);
    procedure rgMiscSelectionChanged(Sender: TObject);

  private
    procedure AddMisc;
    procedure AddText(const s: string);
    procedure ShowFields;
    procedure SaveSettings;
    procedure LoadSettings;

  public
    TheEditor : TSynEdit;
    Conn : TSQLite3Connection;
    procedure Refresh;
  end;

var
  frmBuildSql: TfrmBuildSql;

implementation

uses
  utableEX, Variants, dmod, IniFiles;

{$R *.lfm}

{ TfrmBuildSql }



procedure TfrmBuildSql.ButtonAddFieldsClick(Sender: TObject);
var
  sl : TStringlist;
  i : integer;
  sCurrTable : string;
begin
  if lbTables.ItemIndex = -1 then Exit;
  sCurrTable := lbTables.Items[lbTables.ItemIndex];
  sl := TStringlist.Create;

  for i := 0 to cbFields.Count-1 do
   if cbFields.Checked[i] then
    sl.Add(sCurrTable + '.' + cbFields.Items[i]);


  if rbInsert.ItemIndex = 0 then
    TheEditor.InsertTextAtCaret(sl.CommaText)
  else
   TheEditor.Lines.Add(sl.CommaText);
  sl.free;
end;

procedure TfrmBuildSql.FormClose(Sender: TObject;
       var CloseAction: TCloseAction );
begin
  SaveSettings;
  CloseAction :=caFree
end;

procedure TfrmBuildSql.FormCreate(Sender: TObject);
begin

  LoadSettings;
  dmMain.Conn.GetTableNames(lbTables.Items, false);
end;

function TfrmBuildSql.GetJoinString(ABaseTable,
                 AJoinedTable: string; nthFk : integer): string;
Var
  T : TTableEx;
  i : integer;
  JoinedField, BaseField : string;
  Jtbl, Btbl : string;
  aValue : Variant;
begin

  T := TTableEx.Create(dmMain.Conn);

  T.Name:=ABaseTable;

   aValue      := t.FFKArray[nthFk].SourceField;
   JoinedField := VarToStr(aValue);

   aValue      := t.FFKArray[nthFk].HomeField;
   BaseField   :=  VarToStr(aValue);

  Jtbl := AJoinedTable + '.';
  Btbl := ABaseTable   + '.';

  Result := Format('join %s on %s%s = %s%s',
        [AJoinedTable,Jtbl,JoinedField,
         Btbl,BaseField ]);

  T.Free;
end;

procedure TfrmBuildSql.lbTablesClick(Sender: TObject);
begin
  ShowFields;
end;

procedure TfrmBuildSql.rgMiscSelectionChanged(Sender: TObject);
begin
  AddMisc;
end;




procedure TfrmBuildSql.AddMisc;
var
  s: string;
  function getTableName : string;
  begin
    if (lbTables.ItemIndex >= 0) then
      Result := lbTables.Items[lbTables.ItemIndex]
    else
      Result := '';
  end;

begin
  case rgMisc.ItemIndex of
   0: s := getTableName;
   1: s := 'Select ';
   2: s := 'From '  ;
   3: s := 'Where ';
   end;
    AddText(s);
end;



procedure TfrmBuildSql.AddText(const s: string);
begin
  if rbInsert.ItemIndex = 0 then
      TheEditor.InsertTextAtCaret(s)
    else  begin
     TheEditor.Lines.Add(s);
     TheEditor.CaretY := TheEditor.Lines.Count;
     TheEditor.CaretX := Length(TheEditor.Lines[TheEditor.CaretY - 1]) + 1;
    end;
end;

procedure TfrmBuildSql.ShowFields;
var
  i: integer;
  T: TTableEx;
  sTable: string;
begin
  if lbTables.ItemIndex = -1 then Exit;
  T := TTableEx.Create(dmMain.Conn);
    sTable := lbTables.Items[lbTables.ItemIndex];
    dmMain.Conn.GetFieldNames(sTable, cbFields.Items);

    T.Name:= sTable;
    lbJoins.Items.Clear;
    for i := low(t.FFKArray) to high(t.FFKArray) do
      lbJoins.Items.Add(t.FFKArray[i].SourceTable);

    T.Free;
end;

procedure TfrmBuildSql.SaveSettings;
var
  Ini: TIniFile;
begin

  Ini := TIniFile.Create(ExtractFilePath(Application.Exename) + 'config.ini');
  try

    Ini.WriteInteger('BuildsSQL', 'Top', Self.Top);
    Ini.WriteInteger('BuildsSQL', 'Left', Self.Left);



  finally
    Ini.Free;
  end;


end;

procedure TfrmBuildSql.LoadSettings;
var
  Ini: TIniFile;
begin

  Ini := TIniFile.Create(ExtractFilePath(Application.Exename) + 'config.ini');
  try

    Self.Top   := Ini.ReadInteger('BuildsSQL', 'Top', Self.Top);
    Self.Left  := Ini.ReadInteger('BuildsSQL', 'Left', Self.Left);
  finally
    Ini.Free;
  end;
end;

procedure TfrmBuildSql.Refresh;
begin

   dmMain.Conn.GetTableNames(lbTables.Items, false);
   cbFields.Clear;
   lbJoins.Clear;
end;



procedure TfrmBuildSql.ButtonAddJoinClick(Sender: TObject);
var
  i : integer;
  sTbl, MainTB : string;
  s : string;
begin
  if lbJoins.ItemIndex < 0 then Exit;
  MainTB := lbTables.Items[lbTables.ItemIndex];
  i := lbJoins.ItemIndex;
  if i > -1 then
   sTbl := lbJoins.Items[i];

  s := GetJoinString(MainTB,sTbl,lbJoins.ItemIndex);

  rbInsert.ItemIndex:= 1;
  AddText(s);


  lbTables.ItemIndex:= lbTables.Items.IndexOf(sTbl);
  ShowFields;
end;




end.

