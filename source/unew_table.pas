unit unew_table;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, SQLite3Conn, SQLDB, Forms, Controls, Graphics, Dialogs,
  Grids, StdCtrls, ExtCtrls, Buttons, LazStringUtils;

type

  TRowVal = record
    Field    : string;
    DataType : string;
    Size     : integer;
    PK       : boolean;
    NNull    : boolean;
    AUTOINC  : boolean;
  end;

  { TfrmNewTable }

  TfrmNewTable = class(TForm)
    cmdCreatTable: TButton;
    cmdShowSQL: TButton;
    cmdPickFile: TButton;
    edNewTblName: TEdit;
    Memo1: TMemo;
    OpenDialog1: TOpenDialog;
    SpeedButton1: TSpeedButton;
    SpeedButton2: TSpeedButton;
    Splitter1: TSplitter;
    StringGrid1: TStringGrid;
    procedure cmdCreatTableClick(Sender: TObject);
    procedure cmdPickFileClick(Sender: TObject);
    procedure cmdShowSQLClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure SpeedButton1Click(Sender: TObject);
    procedure SpeedButton2Click(Sender: TObject);
    procedure StringGrid1SelectEditor(Sender: TObject; aCol, aRow: Integer;
      var Editor: TWinControl);
    procedure StringGrid1ValidateEntry(Sender: TObject; aCol, aRow: Integer;
      const OldValue: string; var NewValue: String);
  private
   function MakeCreatSql : string;
   function validate_input : boolean;
   function get_row(iRow : integer) : TRowVal;
  public

  end;

var
  frmNewTable: TfrmNewTable;

implementation

uses dmod;

{$R *.lfm}

{ TfrmNewTable }

procedure TfrmNewTable.cmdPickFileClick(Sender: TObject);
var
  MyFile: TextFile;
  LineContent: String;
  FileName: String;
  Splitted: TStringArray;
  i : integer;
  Item: string;
begin
   if OpenDialog1.Execute then begin
     edNewTblName.Text := ChangeFileExt(extractFilename(OpenDialog1.FileName),'');
     FileName :=  OpenDialog1.FileName;
     AssignFile(MyFile, FileName);
     Reset(MyFile);
     ReadLn(MyFile, LineContent);
     CloseFile(MyFile);



     Splitted := LineContent.Split([',']);

     StringGrid1.RowCount:= high(Splitted) + 2;
     i := 0;
      for Item in Splitted do
        begin
          inc(i);
          StringGrid1.Cells[0,i] := StringReplace(Item, ' ', '', [rfReplaceAll]);


        end;
   end;
end;

procedure TfrmNewTable.cmdCreatTableClick(Sender: TObject);
var
   s : string;
begin

   s := Memo1.Text;

   dmMain.Conn.ExecuteDirect(s);
   dmMain.Trans.CommitRetaining;

end;

procedure TfrmNewTable.cmdShowSQLClick(Sender: TObject);
var
    s : string;
begin
   if not validate_input then exit;
   s := MakeCreatSql;
   Memo1.lines.Text:= s;
   //showmessage(MakeCreatSql );
end;

procedure TfrmNewTable.FormCreate(Sender: TObject);
begin
  StringGrid1.Cells[0,0] := 'FieldName';
  StringGrid1.Cells[1,0] := 'DataType';
  StringGrid1.Cells[2,0] := 'Size';
  StringGrid1.Cells[3,0] := 'PrimaryKey';
  StringGrid1.Cells[4,0] := 'Not Null';
  StringGrid1.Cells[5,0] := 'Auto INC';


end;

procedure TfrmNewTable.SpeedButton1Click(Sender: TObject);
begin
  StringGrid1.RowCount:= + StringGrid1.RowCount + 1;
end;

procedure TfrmNewTable.SpeedButton2Click(Sender: TObject);
begin
  StringGrid1.DeleteRow(StringGrid1.Row);

end;

procedure TfrmNewTable.StringGrid1SelectEditor(Sender: TObject; aCol, aRow: Integer;
  var Editor: TWinControl);
begin

  case aCol of
  1: Begin
     Editor := StringGrid1.EditorByStyle(cbsPickList);
     TCustomComboBox(Editor).Items.CommaText := 'VARCHAR,INTEGER,REAL,TEXT';
    end;
  3, 4, 5:  begin
        Editor := StringGrid1.EditorByStyle(cbsPickList);
        TCustomComboBox(Editor).Items.CommaText := 'Y,N';
     end;

  end;

end;

procedure TfrmNewTable.StringGrid1ValidateEntry(Sender: TObject; aCol, aRow: Integer;
  const OldValue: string; var NewValue: String);
begin
  if (aCol <> 2) or (NewValue = '') then exit;

  if not IsNumeric(NewValue) then
   begin
     Showmessage('Entry must be numeric.');
     NewValue := OldValue
   end;
end;

function TfrmNewTable.MakeCreatSql: string;
var
   i : integer;
   sFields, sOneField : string;


   function rowval(iRow : integer) : string;
   var
    ssql : string;
    sField, sType, sSize, NNUll,PK : string;
    RV : TRowVal;
   begin

     RV := get_row(i);
     sField := RV.Field;
     sType  := RV.DataType;
     sSize  := RV.Size.ToString;
     PK     := BoolToStr(RV.PK,'Y','N');
     NNUll  := BoolToStr(RV.NNull,'Y','N');



     if sType = 'VARCHAR' then
      sType := sType + '(' + sSize + ')';

     ssql := sField + ' ' + sType;

     if PK = 'Y' then
        ssql := ssql + ' ' + 'PRIMARY KEY';

     if RV.AUTOINC then
      ssql := ssql + ' ' + 'AUTOINCREMENT';

     if (NNUll = 'Y') and (not RV.AUTOINC) then
        ssql := ssql + ' ' + 'NOT NULL';
     Result := ssql;
   end;

begin
  for i := 1 to StringGrid1.RowCount - 1 do
    begin
       sOneField := rowval(i) ;
       if i < StringGrid1.RowCount - 1 then
        sOneField := sOneField +', ';
       sOneField := sOneField + #13;
       sFields := sFields + sOneField;
    end;


  result := 'CREATE Table ' + edNewTblName.Text + ' (' + sFields + ')';
end;

function TfrmNewTable.validate_input: boolean;
var
  i : integer;
  RV : TRowVal;
begin
  if edNewTblName.Text = '' then
   begin
     Showmessage('No name name entered');
     edNewTblName.SetFocus;
     Result := False;
     Exit;
   end;
  Result := True;
  for i := 1 to  StringGrid1.RowCount -1 do
    begin
      RV := get_row(i);
      if (trim(RV.Field) = '') and (trim(RV.DataType) = '') then
       begin

        continue;
       end;
      if (trim(RV.Field) = '') or (trim(RV.DataType) = '') then
       begin
         Showmessage('Fieldname and DataType are required');
         Result := False;
         StringGrid1.Row:= i;
         break;
       end;
      If (RV.DataType = 'VARCHAR') and (RV.Size < 1) then
         begin
           Showmessage('VARCHAR must have size > 0');
           StringGrid1.Row:= i;
           StringGrid1.SetFocus;
           Result := False;
           break;
         end;
     if RV.AUTOINC and (not RV.PK) then
      begin
         Showmessage('AUTOINC must be for PK');
         StringGrid1.Row:= i;
         StringGrid1.SetFocus;
         Result := False;
         break;
      end;
    end;
    StringGrid1.SetFocus;
end;

function TfrmNewTable.get_row(iRow : integer): TRowVal;
var
 RV : TRowVal;
begin
     RV.Field     := StringGrid1.Cells[0,iRow];
     RV.DataType  := StringGrid1.Cells[1,iRow];
     RV.Size      := StrToIntDef(StringGrid1.Cells[2,iRow],0);
     RV.PK        := StringGrid1.Cells[3,iRow] = 'Y';
     RV.NNull     := StringGrid1.Cells[4,iRow] = 'Y';
     RV.AUTOINC   := StringGrid1.Cells[5,iRow] = 'Y';
     Result := RV;
end;

end.

