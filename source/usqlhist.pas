unit uSQLhist;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, DB, SQLDB, Forms, Controls, Graphics, Dialogs, DBCtrls,
  ExtCtrls, Buttons, StdCtrls, Grids, IniPropStorage, SynEdit,
  SynHighlighterSQL, uTable, utableEX, SQLite3Conn;

type

  { TfrmCreateSQL }

  TfrmCreateSQL = class(TForm)
    BitBtn1: TBitBtn;
    cmdExport: TButton;
    ComboBox1: TComboBox;
    DataSource1: TDataSource;
    DBNavigator1: TDBNavigator;
    DBText1: TDBText;
    DBText2: TDBText;
    lblCount: TLabel;
    Panel1: TPanel;
    pnlTblGrid: TPanel;
    qryCreateSql: TSQLQuery;
    RadioGroup1: TRadioGroup;
    SaveDialog1: TSaveDialog;
    Splitter1: TSplitter;
    StringGrid1: TStringGrid;
    SynEdit1: TSynEdit;
    SynSQLSyn1: TSynSQLSyn;
    procedure cmdExportClick(Sender: TObject);
    procedure ComboBox1CloseUp(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure qryCreateSqlAfterScroll(DataSet: TDataSet);
    procedure export_create_sql;
    procedure addGridCol(Acaption: string; aWidth : integer);
    procedure RadioGroup1Click(Sender: TObject);
  private
    AConn  : TSQLite3Connection;
    Atabledef :  TTableEx;
    procedure showfield(aFld : TField);
    procedure showFK(aFK : TForeignKey);
    procedure showInxRec(aInx : TIndexInfo);
    procedure GetTblInfo;

    procedure LoadIndexInfo;
    procedure LoadForeignKeys;
    procedure LoadFields;
  public
    procedure ShoWForeignKeys;
    procedure ShoWIndexInfo;
    procedure InitGrid;
    procedure Refresh;
    procedure SaveSettings;
    procedure LoadSettings;

  end;

var
  frmCreateSQL: TfrmCreateSQL;

implementation

uses
  dmod, SynEditWrappedView, umain, IniFiles;

{$R *.lfm}

{ TfrmCreateSQL }



procedure TfrmCreateSQL.FormCreate(Sender: TObject);
begin
 LoadSettings;
 Aconn := dmMain.Conn;
end;

procedure TfrmCreateSQL.FormDestroy(Sender: TObject);
begin
  if Assigned(Atabledef) then
   Atabledef.Free;
end;

procedure TfrmCreateSQL.FormShow(Sender: TObject);
begin
  qryCreateSql.Active := true;
  TLazSynEditLineWrapPlugin.Create(SynEdit1); // Wordwrapping
end;

procedure TfrmCreateSQL.qryCreateSqlAfterScroll(DataSet: TDataSet);
var
   s, sTblName, sType : string;
begin

      if not Assigned(Atabledef) Then
      begin
       Atabledef :=  TTableEx.Create(dmMain.Conn);
      end;

   s:=  qryCreateSql.FieldByName('sql').AsString;
   synedit1.Lines.Text:= s;
   sType := qryCreateSql.FieldByName('type').AsString;
   if   (sType = 'table') or (sType = 'view') then
   begin
     sTblName := qryCreateSql.FieldByName('name').AsString;
     Atabledef.Name:= sTblName;
      StringGrid1.RowCount:=1;
     GetTblInfo;
     pnlTblGrid.Visible:= True;
     InitGrid;
   end
   else
     pnlTblGrid.Visible:= False;

end;

procedure TfrmCreateSQL.export_create_sql;
var
  Sl : TStringlist;
  B : Tbookmark;
  tbl : TTableEx;
  i  : integer;
  s : string;
begin
  SaveDialog1.FileName:= 'export.sql';
  If SaveDialog1.Execute then
  begin
    if FileExists(SaveDialog1.FileName) then
    begin
      If MessageDlg('File already exists. Do you want to continue?',
             mtWarning, [mbYes, mbNo], 0) = mrNo then Exit;
    end;
    B := qryCreateSql.Bookmark;
    Sl := TStringlist.Create;
    tbl := TTableEx.Create(Aconn);

    qryCreateSql.First;
    while not qryCreateSql.EOF do
    begin

     Sl.Add(' -- ' + qryCreateSql.FieldByName('name').AsString);
     Sl.Add(qryCreateSql.FieldByName('sql').AsString);
     Sl.Add('');
     if qryCreateSql.FieldByName('type').AsString = 'table' then
      begin
        tbl.name := qryCreateSql.FieldByName('name').AsString;
        for i := low(tbl.FFKArray) to high(tbl.FFKArray) do
        begin
        s := tbl.FFKArray[i].HomeField + ' -> ';
        s := s + tbl.FFKArray[i].SourceTable + '.';
        s := s + tbl.FFKArray[i].SourceField;
        Sl.Add(s);
        end;
      end;
     Sl.Add('');
     Sl.Add('');
     qryCreateSql.Next;
    end;
    qryCreateSql.GotoBookmark(B);
    Sl.SaveToFile(SaveDialog1.FileName);
    Sl.free;
    tbl.Free;
  end;
end;

procedure TfrmCreateSQL.showfield(aFld: TField);
Var
 s    : string;
 iRow : integer;
begin
  iRow := StringGrid1.RowCount;

  StringGrid1.InsertRowWithValues(
           iRow,
           [
            aFld.FldName,
            aFld.FldType,
            aFld.DeflVal,
            BoolToStr( aFld.Nullabel,'Y','N'),
            BoolToStr(aFld.PK ,'Y','N'),
            BoolToStr(aFld.PKAutoInc ,'Y','N')
            ]
          );

end;

procedure TfrmCreateSQL.showFK(aFK: TForeignKey);
Var
 s    : string;
 iRow : integer;
begin
  iRow := StringGrid1.RowCount;

  StringGrid1.InsertRowWithValues(
           iRow,
           [
            aFK.SourceTable,
            aFK.SourceField,
            aFK.HomeField,
            aFK.OnUpdate,
            aFK.OnDelete
            ]
          );

end;

procedure TfrmCreateSQL.showInxRec(aInx: TIndexInfo);
Var
 s    : string;
 iRow : integer;
begin
  iRow := StringGrid1.RowCount;

  StringGrid1.InsertRowWithValues(
           iRow,
           [
            aInx.IndexName,
            BoolToStr(aInx.Unique,'Y','N'),
            aInx.Origin,
            BoolToStr(aInx.Partial,'Y','N'),
            aInx.Column,
            aInx.ColumnPos.ToString
            ]
          );

end;

procedure TfrmCreateSQL.GetTblInfo;
var
    cnt, i: integer;
    F     : TField;
begin
    cnt := High(Atabledef.FldArray);
     for i := 0 to cnt do
     begin
       F := Atabledef.FldArray[i];
       showfield(F);
     end;

end;
procedure TfrmCreateSQL.addGridCol(Acaption: string; aWidth: integer);
var
    colcount : integer;
begin
   StringGrid1.Columns.Add;
   colcount := StringGrid1.Columns.Count;
   StringGrid1.Columns.Items[colcount-1].Title.Caption := Acaption;
   StringGrid1.Columns.Items[colcount-1].Width:= aWidth;
end;

procedure TfrmCreateSQL.RadioGroup1Click(Sender: TObject);
begin
  InitGrid;
end;

procedure TfrmCreateSQL.LoadIndexInfo;
begin
 StringGrid1.Columns.Clear;
   StringGrid1.RowCount:= 1;

     addGridCol('Index Name', 150);
     addGridCol('Unique', 75);
     addGridCol('Origin', 75);
     addGridCol('Partial', 75);
     addGridCol('Column', 150);
     addGridCol('ColumnPos', 150);
     ShoWIndexInfo;
end;

procedure TfrmCreateSQL.LoadForeignKeys;
begin
     StringGrid1.Columns.Clear;
     StringGrid1.RowCount:= 1;

     addGridCol('SourceTable', 150);
     addGridCol('SourceField', 120);
     addGridCol('HomeField', 100);
     addGridCol('OnUpdate', 100);
     addGridCol('OnDelete', 100);
     ShoWForeignKeys;

end;

procedure TfrmCreateSQL.LoadFields;
begin
    StringGrid1.Columns.Clear;
    StringGrid1.RowCount:= 1;

    addGridCol('Field Name', 150);
    addGridCol('Type', 100);
    addGridCol('Default', 100);
    addGridCol('Nullable', 100);
    addGridCol('PK', 50);
    addGridCol('AutoInc', 100);
    GetTblInfo;

end;

procedure TfrmCreateSQL.ShoWForeignKeys;
var
  cnt: integer;
  i: integer;
  Fk: TForeignKey;

begin

       cnt := High(Atabledef.FFKArray);
         for i := 0 to cnt do
         begin
           Fk := Atabledef.FFKArray[i];
           showFK(Fk);
         end;

end;

procedure TfrmCreateSQL.ShoWIndexInfo;
var
  cnt: integer;
  i: integer;
  INXInfo: TIndexInfo;

begin

       cnt := High(Atabledef.FTInxInfoArray);
         for i := 0 to cnt do
         begin
           INXInfo := Atabledef.FTInxInfoArray[i];
           showInxRec(INXInfo);
         end;

end;

procedure TfrmCreateSQL.InitGrid;
begin
   Case RadioGroup1.ItemIndex of
    0: LoadFields ;
    1: LoadForeignKeys;
    2: LoadIndexInfo
  end;
   StringGrid1.AutoSizeColumns;
end;

procedure TfrmCreateSQL.Refresh;
begin
 qryCreateSql.Close;
 qryCreateSql.Open;
 qryCreateSqlAfterScroll(self.DataSource1.DataSet);

end;

procedure TfrmCreateSQL.SaveSettings;
var
  Ini: TIniFile;
begin

  Ini := TIniFile.Create(ExtractFilePath(Application.Exename) + 'config.ini');
  try

    Ini.WriteInteger('ObjForm', 'Top', Self.Top);
    Ini.WriteInteger('ObjForm', 'Left', Self.Left);
    Ini.WriteInteger('ObjForm', 'Width', Self.Width);
    Ini.WriteInteger('ObjForm', 'Height', Self.Height);

  finally
    Ini.Free;
  end;

end;

procedure TfrmCreateSQL.LoadSettings;
var
  Ini: TIniFile;
begin

  Ini := TIniFile.Create(ExtractFilePath(Application.Exename) + 'config.ini');
  try

    Self.Top   := Ini.ReadInteger('ObjForm', 'Top', Self.Top);
    Self.Left  := Ini.ReadInteger('ObjForm', 'Left', Self.Left);
    Self.Width := Ini.ReadInteger('ObjForm', 'Width', Self.Width);
    Self.Height := Ini.ReadInteger('ObjForm', 'Height', Self.Height);

  finally
    Ini.Free;
  end;


end;

procedure TfrmCreateSQL.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin


  SaveSettings;
  CloseAction :=  caFree;

end;

procedure TfrmCreateSQL.ComboBox1CloseUp(Sender: TObject);
var
   sFilter : string;
begin
    sFilter := ComboBox1.Text;
    if sFilter = 'All' then
      sFilter := ''
    else
       sFilter := 'type = ' + QuotedStr(sFilter);

    qryCreateSql.Filter := sFilter;

    if sFilter <> '' then
       qryCreateSql.filtered := true
    else
       qryCreateSql.filtered := false;

    qryCreateSql.First;
end;

procedure TfrmCreateSQL.FormActivate(Sender: TObject);
begin
 // SynEdit1.font := Fmain.SynEdit1.Font;

end;

procedure TfrmCreateSQL.cmdExportClick(Sender: TObject);
begin
  export_create_sql;
end;

end.

