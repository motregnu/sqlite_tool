unit dmod;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, SQLite3Conn, SQLDB, DB, memds;

type

  { TdmMain }

  TdmMain = class(TDataModule)
    Conn: TSQLite3Connection;
    DataSource1: TDataSource;
    Qry: TSQLQuery;
    qryTables: TSQLQuery;
    Trans: TSQLTransaction;
    procedure ConnAfterConnect(Sender: TObject);
    procedure DataModuleCreate(Sender: TObject);
    procedure DataModuleDestroy(Sender: TObject);
    procedure exe_direct(sql : string);
  private

  public
    procedure attach(ANewDbPath, AName : string);
    procedure detach(AAlias : string);
    procedure GetTablesAndViews( List: TStrings);
  end;

var
  dmMain: TdmMain;

implementation

{$R *.lfm}

{ TdmMain }

procedure TdmMain.GetTablesAndViews( List: TStrings);
var
  Query: TSQLQuery;

begin
  List.Clear;

  Query := TSQLQuery.Create(nil);
  Query.DataBase := Conn;

  try
    Query.SQL.Text := 'SELECT name FROM sqlite_master WHERE type IN (''table'', ''view'') AND name NOT LIKE ''sqlite_%'' ORDER BY name;';
    Query.Open;

    while not Query.EOF do
    begin
      List.Add(Query.FieldByName('name').AsString);
      Query.Next;
    end;
    Query.Close;
  finally
    Query.Free;

  end;
end;

 procedure TdmMain.exe_direct(sql : string);
 begin
   Trans.Active := false;
   Conn.ExecuteDirect(sql);
   Trans.Commit;

 end;

 procedure TdmMain.attach(ANewDbPath, AName: string);
 begin
    Trans.Active := false;
    Conn.ExecuteDirect('ATTACH DATABASE ' + QuotedStr(ANewDbPath) + ' AS ' + AName);

 end;

 procedure TdmMain.detach(AAlias: string);
 begin
  Trans.Active := false;
  Conn.ExecuteDirect('DETACH DATABASE ' + AAlias);


 end;



procedure TdmMain.ConnAfterConnect(Sender: TObject);
begin
  Conn.ExecuteDirect('PRAGMA locking_mode = NORMAL;')
end;

procedure TdmMain.DataModuleCreate(Sender: TObject);
begin


end;

procedure TdmMain.DataModuleDestroy(Sender: TObject);
begin

end;

end.

