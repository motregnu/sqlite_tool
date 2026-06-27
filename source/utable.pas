unit uTable;

{$mode ObjFPC}{$H+}


interface

uses
  Classes, SysUtils, SQLite3Conn, SQLDB, DB;

 Type

   { TField }

   TField  = record

    FldName   : string;
    FldType   : string;
    Nullabel  : boolean;
    PK        : boolean;
    PKAutoInc : boolean;
    DeflVal   : string;
   end;

   { TTable }

   TTable = class

    protected
     FName   : string;
     Qry     : TSQLQuery;
     procedure SetName (sName : string) virtual;
     procedure GetFields(sTable : string);
    public
     FldArray          : array of TField;
     Conn              : TSQLite3Connection;
     property Name     : string   read FName write SetName;
     procedure FillNameList(var AList : TStringlist);

     constructor Create(aConn: TSQLite3Connection);
     destructor Destroy; override;
   end;

implementation

{ TTable }


procedure TTable.GetFields(sTable : string);
  var
    cnt: integer ;
    i  : integer ;
    s : string;
    HasAutoInc : boolean;
  begin

      Qry.Active   := false;
      Qry.SQL.Text := 'SELECT sql FROM sqlite_master WHERE name = ' +QuotedStr(sTable);
      Qry.Active   := True;
      s := UpperCase(Qry.FieldByName('sql').AsAnsiString);
      HasAutoInc := false;
      if Pos('AUTOINCREMENT',s) > 0
       then HasAutoInc := true;
      Qry.Active   := false;



      Qry.Active   := false;
      Qry.SQL.Text := format('pragma table_info(%s)',[QuotedStr(sTable)]) ;
      Qry.Active   := True;

      Qry.Last;
      cnt := Qry.RecordCount;
      Qry.first;

      SetLength(FldArray,cnt);
      i := 0;
      while not Qry.EOF do
      begin

        FldArray[i].FldName := Qry.FieldByName('name').AsAnsiString;
        FldArray[i].FldType := Qry.FieldByName('type').AsString;
        FldArray[i].DeflVal := Qry.FieldByName('dflt_value').AsString;
        FldArray[i].Nullabel:= Not LongBool(Qry.FieldByName('notnull').AsInteger);
        FldArray[i].PK      := LongBool(Qry.FieldByName('pk').AsInteger);
        If FldArray[i].PK  and HasAutoInc then
           FldArray[i].PKAutoInc:= true
        Else
          FldArray[i].PKAutoInc:= False;
        Qry.Next;
        Inc(i);
      end;
  end;

procedure TTable.FillNameList(var AList: TStringlist);
var
  i: integer;
begin
  AList.Clear;

  for i := 0 to length(FldArray) -1 do
    AList.Add(FldArray[i].FldName);

end;

procedure TTable.SetName(sName: string);
begin
  FName :=  sName;
  GetFields(sName);
end;



constructor TTable.Create(aConn: TSQLite3Connection);
begin
  inherited Create;
  Conn  := aConn;
  Qry   := TSQLQuery.Create(nil);
  Qry.database := Conn;
end;

destructor TTable.Destroy;
begin
   Qry.Free;
   SetLength(FldArray, 0);
  inherited Destroy;
end;

end.
