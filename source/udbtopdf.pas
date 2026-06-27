unit uDBToPdf;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, sqlite3conn, sqldb ;

procedure DatabaseToPDF(AConn : TSQLite3Connection;  const AOutputPDF: string);

implementation
uses
    fppdf, fpttf;

type


  // Define the style type here so the compiler knows what it is
  TPDFTextStyle = (tsNormal, tsBold, tsItalic);

procedure DatabaseToPDF(AConn: TSQLite3Connection; const AOutputPDF: string);
const
  Y_THRESHHOLD = 280;
var
  QryTables, QryCols, QryFK, QryIdx, QryIdxCols: TSQLQuery;

  Doc: TPDFDocument;
  Page: TPDFPage;
  FontStd, FontBold, FontItalic: Integer;
  CurrY: Integer;

  TableName: string;
  ColLine: string;
  FKLine: string;
  IdxName: string;
  IsUnique: string;
  IdxColsStr: string;

  // New variables for page numbering
  i: Integer;
  FooterText: string;

  procedure AddNewPage;
  begin
    Page := Doc.Pages.AddPage;
    Doc.Sections[0].AddPage(Page);
    CurrY := 30;
    Page.SetFont(FontStd, 10);
  end;

  procedure WriteLine(const AText: string; AStyle: TPDFTextStyle = tsNormal; AFontSize: Integer = 10; XOffset: Integer = 25);
  begin
    // Your threshold was 270, we check this for new pages
    if CurrY > Y_THRESHHOLD then
    begin
      AddNewPage;
    end;

    case AStyle of
      tsBold:   Page.SetFont(FontBold, AFontSize);
      tsItalic: Page.SetFont(FontItalic, AFontSize);
      else      Page.SetFont(FontStd, AFontSize);
    end;

    Page.WriteText(XOffset, CurrY, AText);
    CurrY := CurrY + (trunc(AFontSize * 0.65));
  end;

begin
  QryTables := TSQLQuery.Create(nil);
  QryCols := TSQLQuery.Create(nil);
  QryFK := TSQLQuery.Create(nil);
  QryIdx := TSQLQuery.Create(nil);
  QryIdxCols := TSQLQuery.Create(nil);

  try
    QryTables.DataBase := AConn;
    QryCols.DataBase := AConn;
    QryFK.DataBase := AConn;
    QryIdx.DataBase := AConn;
    QryIdxCols.DataBase := AConn;

    Doc := TPDFDocument.Create(nil);
    try
      Doc.Options := [poPageOriginAtTop];
      Doc.StartDocument;
      Doc.Sections.AddSection;

      // Font Paths
      {$IFDEF WINDOWS}
      Doc.FontDirectory := IncludeTrailingPathDelimiter(GetEnvironmentVariable('WINDIR')) + 'Fonts\';
      {$ENDIF}
      {$IFDEF LINUX}
      Doc.FontDirectory := '/usr/share/fonts/truetype/dejavu/';
      {$ENDIF}
      {$IFDEF DARWIN}
      Doc.FontDirectory := '/Library/Fonts/';
      {$ENDIF}
      FontStd := Doc.AddFont('DejaVuSans.ttf', 'DejaVu');
      FontBold := Doc.AddFont('DejaVuSans-Bold.ttf', 'DejaVuBold');
      FontItalic := Doc.AddFont('DejaVuSans-Oblique.ttf', 'DejaVuItalic');

      AddNewPage;
      WriteLine('Database Schema Report: ' + ExtractFileName(AConn.DatabaseName), tsBold, 16);
      WriteLine('Generated: ' + DateTimeToStr(Now), tsNormal, 10);
      WriteLine(StringOfChar('-', 80), tsNormal, 10);
      CurrY := CurrY + 10;

      QryTables.SQL.Text := 'SELECT name FROM sqlite_master WHERE type="table" AND name NOT LIKE "sqlite_%" ORDER BY name;';
      QryTables.Open;

      while not QryTables.EOF do
      begin
        TableName := QryTables.FieldByName('name').AsString;

        WriteLine('TABLE: ' + TableName, tsBold, 12);

        // Columns
        WriteLine('  Columns:', tsBold, 10);
        QryCols.Close;
        QryCols.SQL.Text := Format('PRAGMA table_info(%s);', [TableName]);
        QryCols.Open;
        while not QryCols.EOF do
        begin
          ColLine := Format('    • %s (%s)', [QryCols.FieldByName('name').AsString, QryCols.FieldByName('type').AsString]);
          if QryCols.FieldByName('pk').AsInteger = 1 then ColLine := ColLine + ' [PK]';
          if QryCols.FieldByName('notnull').AsInteger = 1 then ColLine := ColLine + ' NOT NULL';
          if QryCols.FieldByName('dflt_value').AsString <> '' then
            ColLine := ColLine + ' Default : ' + QryCols.FieldByName('dflt_value').AsString;
          WriteLine(ColLine, tsNormal, 10);
          QryCols.Next;
        end;

        // Foreign Keys
        QryFK.Close;
        QryFK.SQL.Text := Format('PRAGMA foreign_key_list(%s);', [TableName]);
        QryFK.Open;
        if not QryFK.EOF then
        begin
          WriteLine('  Foreign Keys:', tsBold, 10);
          while not QryFK.EOF do
          begin
            FKLine := Format('    → %s : references %s(%s)', [
              QryFK.FieldByName('from').AsString,
             // QryFK.FieldByName('id').AsString,
              QryFK.FieldByName('table').AsString,
              QryFK.FieldByName('to').AsString
            ]);
            WriteLine(FKLine, tsItalic, 9);
            QryFK.Next;
          end;
        end;

        // Indexes
        QryIdx.Close;
        QryIdx.SQL.Text := Format('PRAGMA index_list(%s);', [TableName]);
        QryIdx.Open;
        if not QryIdx.EOF then
        begin
          WriteLine('  Indexes:', tsBold, 10);
          while not QryIdx.EOF do
          begin
            IdxName := QryIdx.FieldByName('name').AsString;
            IsUnique := '';
            if QryIdx.FieldByName('unique').AsInteger = 1 then IsUnique := ' [UNIQUE]';

            QryIdxCols.Close;
            QryIdxCols.SQL.Text := Format('PRAGMA index_info(%s);', [IdxName]);
            QryIdxCols.Open;
            IdxColsStr := '';
            while not QryIdxCols.EOF do
            begin
              if IdxColsStr <> '' then IdxColsStr := IdxColsStr + ', ';
              IdxColsStr := IdxColsStr + QryIdxCols.FieldByName('name').AsString;
              QryIdxCols.Next;
            end;

            WriteLine(Format('    ⚡ %s on (%s)%s', [IdxName, IdxColsStr, IsUnique]), tsItalic, 9);
            QryIdx.Next;
          end;
        end;

        WriteLine('', tsNormal, 10);
        CurrY := CurrY + 10;
        QryTables.Next;
      end;

      // --- ADD PAGE NUMBERS HERE ---
      // We loop through all generated pages and add the footer
      for i := 0 to Doc.Pages.Count - 1 do
      begin
        FooterText := Format('Page %d of %d', [i + 1, Doc.Pages.Count]);
        Page := Doc.Pages[i];
        Page.SetFont(FontStd, 8); // Smaller font for footer
        // Use a Y coordinate near the bottom.
        // Since your line logic uses 270 as a limit, 285 is a good spot for the footer.
        Page.WriteText(80, 285, FooterText);
      end;

      Doc.SaveToFile(AOutputPDF);
    finally
      Doc.Free;
    end;

  finally
    QryIdxCols.Free;
    QryIdx.Free;
    QryFK.Free;
    QryCols.Free;
    QryTables.Free;
  end;
end;
end.

