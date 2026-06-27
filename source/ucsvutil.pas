unit UCsvUtil;

{$mode ObjFPC}{$H+}

interface

Uses Classes, SysUtils,utable, SQLite3Conn ;

Type
  TMyObjectCallback = procedure(Sender: TObject; StatusText: String) of object;

 procedure ImportCSV( aFileName: string; aTable: TTable;
                      lValues, LFields: Tstringlist;
                      ColumnsOfInterest: array of Integer;
                      StatCallBack : TMyObjectCallback
                      );

 function ImportFile(AConn :TSQLite3Connection;   AFileName, ATargetTable : string;
                         ADBFields, ACSVColumns   : TStringList;
                         AColumnOffsets: array of Integer
                         ) : integer ;


implementation

Uses SQLDB;

procedure AddPrefixToItems(const APrefix : string; AList : TStringlist);
var
   i : integer;
begin
    for i := 0 to AList.Count -1 do
    begin
     AList[i] := APrefix + AList[i];
    end;
end;

function ImportFile(AConn :TSQLite3Connection; AFileName,
           ATargetTable: string; ADBFields,
          ACSVColumns: TStringList; AColumnOffsets: array of Integer
          ) : integer;
var
  F: TextFile;
  CurrentLine: string;
  sSql, ColVal : string;
  slRow : Tstringlist;
  iCol, iParam, iInserted : integer;
  Qry : TSQLQuery;
begin
  Result := 0;
  slRow := Tstringlist.Create;
  // Crucial fix for CSV space-splitting bug
  slRow.Delimiter := ',';
  slRow.StrictDelimiter := True;

  Qry := TSQLQuery.Create(nil);
  try
    Qry.DataBase := AConn;

    // Standardizing SQL structure safely
    sSql := 'INSERT INTO "' + ATargetTable  + '" ( ' + ADBFields.CommaText + ' ) VALUES ( ';
    AddPrefixToItems(':', ADBFields);
    sSql := sSql +  ADBFields.CommaText + ' )';

    Qry.SQL.Text := sSql ;
    Qry.Params.ParseSQL(Qry.SQL.Text, True);
    iInserted := 0;

    AssignFile(F, AFileName);
    Reset(F);
    try
      if not Eof(F) then ReadLn(F, CurrentLine); // skip header safely

      if not AConn.Transaction.Active then
         AConn.Transaction.StartTransaction;

      while not Eof(F) do
      begin
        ReadLn(F, CurrentLine);
        if trim(CurrentLine) = '' then continue;

        slRow.DelimitedText := CurrentLine;
        iParam := 0;

        for iCol := low(AColumnOffsets) to high(AColumnOffsets) do
        begin
          // Prevention of out of bounds errors if CSV row is truncated
          if (AColumnOffsets[iCol] >= 0) and (AColumnOffsets[iCol] < slRow.Count) then
            ColVal := slRow[AColumnOffsets[iCol]]
          else
            ColVal := '';

          if trim(ColVal) = '' then
            Qry.Params[iParam].Value := Null
          else
            Qry.Params[iParam].Value := ColVal;
          Inc(iParam);
        end;

        Qry.ExecSQL;
        Inc(iInserted);

        if (iInserted mod 1000 = 0) then
          AConn.Transaction.CommitRetaining;
      end;

      AConn.Transaction.CommitRetaining;
      Result := iInserted;
    finally
      CloseFile(F); // Ensure file descriptor is freed
    end;
  finally
    slRow.Free;
    Qry.Free; // Ensure heap memories are freed even on failure
  end;
end;

function BuildInsert(LFields : Tstringlist; ColumnsOfInterest : array of Integer; TargetTable: TTable): String;
  var
    i: integer;
    sIns : string;
    sVals : string;
  begin
    sIns := 'INSERT INTO ' +  TargetTable.Name;
    sIns := sIns + ' ( ';
    for i := low(ColumnsOfInterest) to high(ColumnsOfInterest) do
     begin
      sIns := sIns + LFields[i] ;
      If i < high(ColumnsOfInterest) then sIns := sIns + ',';
     end;
     sIns := sIns + ')';
    Result:=sIns;

end;

procedure ImportCSV(aFileName: string; aTable: TTable;
                    lValues, LFields: Tstringlist;
                    ColumnsOfInterest: array of Integer;
                    StatCallBack : TMyObjectCallback
                    );


  function needs_quotes(sFldType : string) : boolean;
  begin
    sFldType := UpperCase(sFldType);
    if pos('CHAR',sFldType) > 0 then Result := True
    else if pos('TEXT',sFldType) > 0 then Result := True
    else if pos('CLOB',sFldType) > 0 then Result := True
    else Result := False;
  end;

  var
    i, pad  : integer;
    iCol : integer;
    iInserted : integer;
    sMsg : string;
    sInsert : string;
    sValues : string;

    sl : Tstringlist;

    FieldType : string;
    AField : string;
    F: TextFile;
    CurrentLine: string;
    TheCols: string;

  begin
    pad := 0;

    sl := Tstringlist.Create;
    sInsert := BuildInsert(lValues, ColumnsOfInterest,aTable);

    sValues := 'Values (';

    AssignFile(F, aFileName);
    Reset(F);
    ReadLn(F, TheCols); // skip first line

    iInserted := 0;
    while not Eof(F) do
    begin
      ReadLn(F, CurrentLine);
      sl.DelimitedText := CurrentLine;
       sValues := 'Values( ';

       for i := low(ColumnsOfInterest) to high(ColumnsOfInterest) do
        begin
         iCol := ColumnsOfInterest[i];

         if aTable.FldArray[i].PKAutoInc then
           pad :=1;
         FieldType := aTable.FldArray[i+pad].FldType;

         AField := Trim(sl[iCol]);
         If AField = '' then
            AField := 'null' else
         if needs_quotes(FieldType) then
           AField := QuotedStr(AField);

         sValues := sValues + AField ;
         if i < high(ColumnsOfInterest)
           then sValues := sValues + ',';
       end;
       sMsg := sInsert + ' ' + sValues + ')';

       aTable.Conn.ExecuteDirect(sMsg);
       Inc(iInserted);
       if (iInserted mod 200 = 0) then begin

       if Assigned(StatCallBack) then
         StatCallBack(nil,FormatFloat('#,##0', iInserted) + ' records processed');

       end;
       if (iInserted mod 500) = 0 then
        aTable.Conn.Transaction.CommitRetaining;
    end;
    CloseFile(F);
    sl.Free;
    aTable.Conn.Transaction.Commit;

    if Assigned(StatCallBack) then
         StatCallBack(nil,FormatFloat('#,##0', iInserted) + ' records imported.');


  end;

end.

