unit frmCSVImp;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, SQLite3Conn, SQLDB, Forms, Controls, Graphics, Dialogs,
  StdCtrls, ValEdit, ExtCtrls, CheckLst, ComCtrls,
  Buttons, utable;

type



  { TfrmCSVImport }

  TfrmCSVImport = class(TForm)
    BitBtn1: TBitBtn;
    Button3: TButton;
    ButtonCSVColMove: TButton;
    Button4: TButton;
    cboTables: TComboBox;
    CheckListBox1: TCheckListBox;
    cmdRest: TButton;
    cmdSelAll: TButton;
    Label1: TLabel;
    lblFile: TLabel;
    OpenDialog1: TOpenDialog;
    Panel1: TPanel;
    StatusBar1: TStatusBar;
    ValueListEditor1: TValueListEditor;


    procedure cboTablesChange(Sender: TObject);
    procedure cmdRestClick(Sender: TObject);
    procedure cmdSelAllClick(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormResize(Sender: TObject);

    procedure FormShow(Sender: TObject);

    procedure ButtonCSVColMoveClick(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure SelectInportFile(Sender: TObject);

    procedure FormCreate(Sender: TObject);
    procedure loadTables;
    procedure ShowImportStatus( Staus : string);
  private
    ColumnsOfInterest: array of Integer;
    TargetTable : TTable;
    FFileName   : string;

  public
    Conn : TSQLite3Connection;
    procedure BuildInsertLists(lValues, LFields : Tstringlist);

    procedure LoadCSVColumns;
    Function Validate : boolean;
    Function ValidateImport : boolean;
    procedure update_status(Sender: TObject; StatusText: String);
  end;

var
  frmCSVImport: TfrmCSVImport;

implementation

uses dmod, UCsvUtil;
{$R *.lfm}


{ TfrmCSVImport }

procedure TfrmCSVImport.FormShow(Sender: TObject);
begin
  loadTables;
  ValueListEditor1.ColWidths[0] := 150;
end;

procedure TfrmCSVImport.cboTablesChange(Sender: TObject);
begin
  TargetTable.Name:= cboTables.Items[cboTables.ItemIndex];  ;
end;

procedure TfrmCSVImport.cmdRestClick(Sender: TObject);
var
  i: Integer;
begin
  for i := 0 to CheckListBox1.Count - 1 do
    CheckListBox1.Checked[i] := False;
  Self.ValueListEditor1.Clear;
end;

procedure TfrmCSVImport.cmdSelAllClick(Sender: TObject);
var
  i: Integer;
begin
  for i := 0 to CheckListBox1.Count - 1 do
    CheckListBox1.Checked[i] := True;

end;

procedure TfrmCSVImport.FormDestroy(Sender: TObject);
begin
   TargetTable.Free;
end;

procedure TfrmCSVImport.FormResize(Sender: TObject);
begin

  ButtonCSVColMove.Left:= CheckListBox1.Left + CheckListBox1.Width + 10;
end;

procedure TfrmCSVImport.ButtonCSVColMoveClick(Sender: TObject);
var
    i, pos: integer;
    ItemProp:  TItemProp;
    MyStringList : TStringlist;
    s : string;

begin

  If not Validate then exit;

  MyStringList := TStringlist.create;
  for i := low(TargetTable.FldArray) to high(TargetTable.FldArray) do
  begin
     if not TargetTable.FldArray[i].PKAutoInc then
      MyStringList.Add(TargetTable.FldArray[i].FldName);
  end;

    ItemProp := TItemProp.Create(ValueListEditor1);
    ItemProp.EditStyle := esPickList;

  for i := 0 to CheckListBox1.Items.Count -1 do
  begin
   if CheckListBox1.Checked[i] then
     ValueListEditor1.InsertRow(CheckListBox1.items[i],'', true);
  end;

 for i := 1 to ValueListEditor1.RowCount -1  do
   begin

     begin
       s := ValueListEditor1.Keys[i];
       ItemProp := ValueListEditor1.ItemProps[s];
       ItemProp.EditStyle := esPickList;
       ItemProp.ReadOnly := True; // Optional: prevents user from typing custom values
       ItemProp.PickList := MyStringList;
     end;
   end;
   MyStringList.Sort;
  for i:= 1 to ValueListEditor1.RowCount - 1 do
      begin
        s := ValueListEditor1.Keys[i];
        pos := MyStringList.IndexOf(s);
        if pos <> -1 then
          ValueListEditor1.Values[s] := MyStringList[pos];
      end;
end;

procedure TfrmCSVImport.Button3Click(Sender: TObject);
var
 slCols ,slFields : Tstringlist;
 iRecordsImpoted : integer;
 StartTick, EndTick: QWord;
 Total: Int64;
 sMsg : string;
begin
  If not ValidateImport then
     exit;

   slCols   := Tstringlist.Create;
   slFields := Tstringlist.Create;
   BuildInsertLists(slCols,slFields);

   StartTick := GetTickCount64;

   iRecordsImpoted := UCsvUtil.ImportFile(Conn,FFileName,TargetTable.Name,
                                          slCols, slFields,ColumnsOfInterest);

   EndTick := GetTickCount64;
   sMsg := Format('%d records imported. Time elapsed: %d ms',
        [iRecordsImpoted,EndTick - StartTick]);
   update_status(Self, sMsg );

end;

procedure TfrmCSVImport.SelectInportFile(Sender: TObject);
begin

  if self.OpenDialog1.Execute then begin
    FFileName:= OpenDialog1.FileName;
    self.lblFile.Caption:= ExtractFileName(FFileName);
    LoadCSVColumns;
  end;

end;



procedure TfrmCSVImport.FormCreate(Sender: TObject);
begin
  Conn := dmMain.Conn;
  TargetTable := TTable.Create(Conn);
end;

procedure TfrmCSVImport.loadTables;
begin
  Conn.GetTableNames(cboTables.Items, false);
  cboTables.DroppedDown:= True;
end;

procedure TfrmCSVImport.ShowImportStatus(Staus: string);
begin
  StatusBar1.Panels[0].Text:= Staus;
end;

procedure TfrmCSVImport.BuildInsertLists(lValues, LFields: Tstringlist);
var
     i, pos : integer;
     sKey, sVal : string;
     sMsg : string;
begin
  lValues.Clear;
  LFields.Clear;


  for i:= 1 to ValueListEditor1.RowCount - 1 do
      begin
        sKey := ValueListEditor1.Keys[i];
        sVal := ValueListEditor1.Values[sKey];

        lValues.Add(sVal);
        LFields.add(sKey);
      end;
    SetLength(ColumnsOfInterest, LFields.Count);
    for i := 0 to lValues.Count - 1 do
      begin


   pos :=  CheckListBox1.Items.IndexOf(LFields[i]);
   if pos > -1 then
    ColumnsOfInterest[i] := pos;
   end;

end;

procedure TfrmCSVImport.LoadCSVColumns;
var
  TheCols: string;
  F: TextFile;
  sl: Tstringlist;
begin
   sl := Tstringlist.Create;
   sl.Delimiter := ',';
   sl.StrictDelimiter := True;

   AssignFile(F, FFileName);
  try
    Reset(F);
    if not Eof(F) then
    begin
      ReadLn(F, TheCols);
      sl.DelimitedText := TheCols;
      CheckListBox1.Items := sl;
    end;
  finally
    CloseFile(F);
    sl.Free;
  end;
end;

function TfrmCSVImport.Validate: boolean;
Var
  i, cnt : integer;
begin
  Result := True;
  If (TargetTable.Name = '') or  (FFileName = '') then
   begin
    Showmessage('A table and an input file must be selected.');
    Result := False;
    exit;
   end;
  cnt := 0;
  for i := 0 to  Checklistbox1.Count -1 do
   begin
     if Checklistbox1.Checked[i] then inc(cnt);
   end;
  If cnt = 0 then
   begin
     Showmessage('No columns are selected.');
    Result := False;
   end;
end;

function TfrmCSVImport.ValidateImport: boolean;
var
  i : integer;
  K,V : string;
begin

   If ValueListEditor1.RowCount < 3 then
    begin
     Showmessage('No colums and fields.');
     Result := False;
     exit;
    end;

   For i := 1 to ValueListEditor1.RowCount -1 do
    begin
     K := ValueListEditor1.Keys[i];
     V := ValueListEditor1.Values[K];
     If V = '' then begin
      Showmessage('Blank DB field not allowed. Select a field for ' + K );
      Result := False;
      exit;
     end;
    end;
end;

procedure TfrmCSVImport.update_status(Sender: TObject; StatusText: String);
begin
   ShowImportStatus(StatusText);
   Application.ProcessMessages;
end;

end.

