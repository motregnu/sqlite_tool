unit utableEX;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, uTable, SQLite3Conn, SQLDB, DB;

Type

  TForeignKey  = record
    SourceTable : string;
    SourceField : string;
    HomeField   : string;
    OnUpdate    : string;
    OnDelete    : string;
    Match       : string;
  end;

  TIndexInfo = record
    IndexName   : string;
    Unique      : boolean;
    Origin      : string;
    Partial     : boolean;
    Column      : string;
    ColumnPos   : integer;
  end;

  { TTableEx }

  TTableEx = class(TTable)
   Protected
    procedure SetName (sName : string) override;
    procedure GetForeignKeys(sTable : string);
    procedure GetInxInfo(sTable : string);
   Public
      FFKArray         : array of TForeignKey;
      FTInxInfoArray   : array of TIndexInfo;
     constructor Create(aConn: TSQLite3Connection);
     destructor Destroy; override;
  end;

implementation

{ TTableEx }

procedure TTableEx.SetName(sName: string);
begin
  inherited SetName(sName);
  GetForeignKeys(sName);
  GetInxInfo(sName);
end;

procedure TTableEx.GetForeignKeys(sTable: string);
var
   cnt: integer ;
   i  : integer ;
begin
  Qry.Active   := false;
  Qry.SQL.Text := format('pragma foreign_key_list(%s)',[QuotedStr(sTable)]) ;
  Qry.Active   := True;

  Qry.Last;
  cnt := Qry.RecordCount;
  Qry.first;


  SetLength(FFKArray,cnt);
  i := 0;

  while not Qry.EOF do
      begin

        FFKArray[i].SourceTable := Qry.FieldByName('table').AsAnsiString;
        FFKArray[i].SourceField := Qry.FieldByName('to').AsString;
        FFKArray[i].HomeField   := Qry.FieldByName('from').AsString;
        FFKArray[i].OnUpdate    := Qry.FieldByName('on_update').AsString;
        FFKArray[i].OnDelete    := Qry.FieldByName('on_delete').AsString;
        FFKArray[i].Match       := Qry.FieldByName('match').AsString;

        Qry.Next;
        Inc(i);
      end;
end;

procedure TTableEx.GetInxInfo(sTable: string);
var
   cnt: integer ;
   i  : integer ;
   sSql : string;

   function make_slq() : string;
   var
      s : string;
   begin
     s := 'SELECT il.*, ';
     s := s + 'ii.name AS column_name,';
     s := s + 'ii.seqno AS column_position ';
     s := s + format('FROM pragma_index_list(%s) AS il ',[QuotedStr(sTable)]) ;
     s := s + 'JOIN pragma_index_info(il.name) AS ii ';
     Result := s;
   end;

begin
  sSql := make_slq;
  Qry.Active   := false;
  Qry.SQL.Text := sSql;
  Qry.Active   := True;

  Qry.Last;
  cnt := Qry.RecordCount;
  Qry.first;

  SetLength(FTInxInfoArray,cnt);
  i := 0;


  while not Qry.EOF do
      begin

        FTInxInfoArray[i].IndexName := Qry.FieldByName('name').AsAnsiString;
        FTInxInfoArray[i].Unique    := LongBool(Qry.FieldByName('unique').AsInteger);
        FTInxInfoArray[i].Origin    := Qry.FieldByName('origin').AsString;
        FTInxInfoArray[i].Partial   := LongBool(Qry.FieldByName('partial').AsInteger);
        FTInxInfoArray[i].Column    := Qry.FieldByName('column_name').AsString;
        FTInxInfoArray[i].ColumnPos := Qry.FieldByName('column_position').AsInteger;

        Qry.Next;
        Inc(i);
      end;
end;

constructor TTableEx.Create(aConn: TSQLite3Connection);
begin
  inherited Create(aConn);
end;

destructor TTableEx.Destroy;
begin
  Setlength(FFKArray,0);
  Setlength(FTInxInfoArray,0);

  inherited Destroy;
end;

end.

