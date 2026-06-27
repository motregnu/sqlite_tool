unit uReporterpas;

interface
 uses
  Classes, SysUtils, sqldb, sqlite3conn;

type
  TSQLiteSchemaReporter = class
  private
    FConnection: TSQLite3Connection;
    FMarkdown: TStringList;
    procedure GetTableStructure(const TableName: string);
    procedure GetForeignKeys(const TableName: string);
    procedure GetTriggers;
  public
    constructor Create(AConnection: TSQLite3Connection);
    destructor Destroy; override;
    function GenerateReport: string;
  end;

implementation

constructor TSQLiteSchemaReporter.Create(AConnection: TSQLite3Connection);
begin
  inherited Create;
  FConnection := AConnection;
  FMarkdown := TStringList.Create;
end;

destructor TSQLiteSchemaReporter.Destroy;
begin
  FMarkdown.Free;
  inherited Destroy;
end;

procedure TSQLiteSchemaReporter.GetTableStructure(const TableName: string);
var
  Query: TSQLQuery;
  ColName, ColType, NotNull, DefaultVal: string;
begin
  Query := TSQLQuery.Create(nil);
  try
    Query.DataBase := FConnection;
    Query.SQL.Text := 'PRAGMA table_info("' + TableName + '")';
    Query.Open;



    FMarkdown.Add('### Table: ' + TableName);
    FMarkdown.Add('');
    FMarkdown.Add('| Column | Type | Not Null | Default |');
    FMarkdown.Add('| :--- | :--- | :--- | :--- |');

    while not Query.EOF do
    begin
      ColName := Query.FieldByName('name').AsString;
      ColType := Query.FieldByName('type').AsString;
      if Query.FieldByName('notnull').AsBoolean then NotNull := 'Yes' else NotNull := 'No';
      DefaultVal := Query.FieldByName('dflt_value').AsString;
      if DefaultVal = '' then DefaultVal := 'NULL';

      FMarkdown.Add(Format('| %s | %s | %s | %s |', [ColName, ColType, NotNull, DefaultVal]));
      Query.Next;
    end;
    FMarkdown.Add('');
  finally
    Query.Free;
  end;
end;

procedure TSQLiteSchemaReporter.GetForeignKeys(const TableName: string);
var
  Query: TSQLQuery;
begin
  Query := TSQLQuery.Create(nil);
  try
    Query.DataBase := FConnection;
    Query.SQL.Text := 'PRAGMA foreign_key_list("' + TableName + '")';
    Query.Open;

    if not Query.EOF then
    begin
      FMarkdown.Add('**Foreign Keys:**');
      FMarkdown.Add('');
      FMarkdown.Add('| Column | References Table | References Col |');
      FMarkdown.Add('| :--- | :--- | :--- |');
      while not Query.EOF do
      begin
        FMarkdown.Add(Format('| %s | %s | %s |', [
          Query.FieldByName('from').AsString,
          Query.FieldByName('table').AsString,
          Query.FieldByName('to').AsString
        ]));
        Query.Next;
      end;
      FMarkdown.Add('');
    end;
  finally
    Query.Free;
  end;
end;

procedure TSQLiteSchemaReporter.GetTriggers;
var
  Query: TSQLQuery;
  TriggerName, TriggerSQL: string;
begin
  Query := TSQLQuery.Create(nil);
  try
    Query.DataBase := FConnection;
    Query.SQL.Text := 'SELECT name, sql FROM sqlite_master WHERE type = ''trigger''';
    Query.Open;

    if not Query.EOF then
    begin
      FMarkdown.Add('## Triggers');
      FMarkdown.Add('');
      while not Query.EOF do
      begin
        TriggerName := Query.FieldByName('name').AsString;
        TriggerSQL := Query.FieldByName('sql').AsString;
        FMarkdown.Add('**Trigger:** `' + TriggerName + '`');
        FMarkdown.Add('```sql');
        FMarkdown.Add(TriggerSQL + ';');
        FMarkdown.Add('```');
        FMarkdown.Add('');
        Query.Next;
      end;
    end;
  finally
    Query.Free;
  end;
end;

function TSQLiteSchemaReporter.GenerateReport: string;
var
  Query: TSQLQuery;
begin
  FMarkdown.Clear;

  FMarkdown.Add('Printed: ' + FormatDateTime('mmm-dd-yyyy  h:nn am/pm', Now));
  FMarkdown.Add('');
  FMarkdown.Add('*' + ExtractFileName(FConnection.DatabaseName)+ '*' );
  FMarkdown.Add('');
  FMarkdown.Add('# Database Schema Report:');
  FMarkdown.Add('');

  Query := TSQLQuery.Create(nil);
  try
    Query.DataBase := FConnection;
    // Get all tables
    Query.SQL.Text := 'SELECT name FROM sqlite_master WHERE type = ''table'' AND name NOT LIKE ''sqlite_%''';
    Query.Open;

    while not Query.EOF do
    begin
      GetTableStructure(Query.FieldByName('name').AsString);
      GetForeignKeys(Query.FieldByName('name').AsString);
      Query.Next;
    end;
  finally
    Query.Free;
  end;

  GetTriggers;
  Result := FMarkdown.Text;
end;

end.

