unit umain;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, dmod,
  fpcsvexport, memds, DBGrids, Buttons, ExtCtrls, Menus, ComCtrls, ActnList,
  SynHighlighterSQL, SynEdit, SynCompletion, MRUMenu,
  BoundedStringList, uTable, Types, LCLType, Grids;

type

  { TFmain }

  TFmain = class(TForm)
    actSqliteFinctions: TAction;
    actPrev: TAction;
    actNext: TAction;
    ActionList1: TActionList;
    cmdCreateNew: TButton;
    cmdDirect: TButton;
    cmdRun: TButton;
    ComboBox1: TComboBox;
    CSVExporter1: TCSVExporter;
    dbgQryResults: TDBGrid;
    FontDialog1: TFontDialog;
    MainMenu1: TMainMenu;
    mdHistory: TMemDataset;
    Menugridfont: TMenuItem;
    MenuEditFont: TMenuItem;
    MenuAttach: TMenuItem;
    mnuBuildSql: TMenuItem;
    mnuSqlFunctions: TMenuItem;
    mnuFilesShortCut: TMenuItem;
    mnuTableShortcut: TMenuItem;
    mnuShortcuts: TMenuItem;
    mnuSaveToPdf: TMenuItem;
    mnuSaveToMarkdown: TMenuItem;
    mnuClearQueryList: TMenuItem;
    mnuSchemaExport: TMenuItem;
    mnuShowMetadata: TMenuItem;
    mnuRecentFiles: TMenuItem;
    mnuOpen: TMenuItem;
    mnuFont: TMenuItem;
    Separator2: TMenuItem;
    mnuCSVImort: TMenuItem;
    mnuHist: TMenuItem;
    mnuExport: TMenuItem;
    mnuOther: TMenuItem;
    mnuSqlCreateSQL: TMenuItem;
    mnuFile: TMenuItem;
    mnuSavetoFile: TMenuItem;
    mnuLoadFile: TMenuItem;
    mnuCreateTable: TMenuItem;
    OpenDialog1: TOpenDialog;
    Panel1: TPanel;
    PopupMnuFields: TPopupMenu;
    RadioGroup1: TRadioGroup;
    SaveDialog1: TSaveDialog;
    SaveDialog2: TSaveDialog;
    Separator1: TMenuItem;
    sbNext: TSpeedButton;
    sbPrevious: TSpeedButton;
    Splitter1: TSplitter;
    StatusBar: TStatusBar;
    SynCompFields: TSynCompletion;
    SynCompTables: TSynCompletion;
    SynEdit1: TSynEdit;
    SynSQLSyn1: TSynSQLSyn;
    procedure actNextExecute(Sender: TObject);
    procedure actPrevExecute(Sender: TObject);
    procedure actSqliteFinctionsExecute(Sender: TObject);

    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure MenuAttachClick(Sender: TObject);
    procedure MenuEditFontClick(Sender: TObject);
    procedure MenugridfontClick(Sender: TObject);
    procedure mnuBuildSqlClick(Sender: TObject);
    procedure mnuClearQueryListClick(Sender: TObject);
    procedure mnuFilesShortCutClick(Sender: TObject);

    procedure mnuOpenClick(Sender: TObject);
    procedure mnuSaveToMarkdownClick(Sender: TObject);
    procedure mnuSaveToPdfClick(Sender: TObject);

    procedure mnuShowMetadataClick(Sender: TObject);
    procedure mnuSqlFunctionsClick(Sender: TObject);
    procedure mnuTableShortcutClick(Sender: TObject);

    procedure MRUManagerRecentFile(Sender: TObject;
                                          const AFileName: String  );
    procedure ShowMetaData(Sender: TObject);
    procedure cmdCreateNewClick(Sender: TObject);
    procedure cmdDirectClick(Sender: TObject);

    procedure cmdRunClick(Sender: TObject);
    procedure ComboBox1CloseUp(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure MenuItem1Click(Sender: TObject);
    procedure mnuCreateTableClick(Sender: TObject);
    procedure mnuCSVImortClick(Sender: TObject);
    procedure mnuExportClick(Sender: TObject);
    procedure mnuHistClick(Sender: TObject);
    procedure mnuSaveClick(Sender: TObject);
    procedure mnuSqlCreateSQLClick(Sender: TObject);

    procedure MenuITabletemClick(Sender: TObject);
    procedure SynCompTablesCodeCompletion(var Value: string;
      SourceValue: string; var SourceStart, SourceEnd: TPoint;
      KeyChar: TUTF8Char; Shift: TShiftState);

  //  procedure SynEdit1KeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
  private
    MRUMenuMgr: TMRUMenuManager;
    QryList : TBoundedStringList;

    function Boiler_sql_meta: string;
    function Boiler_sql_createtable: string;
    procedure get_tablenames;
    procedure InitNewFile(Sender: TObject; const sFileName : string);

    procedure InitPopupSQL(Sender: TObject);
    procedure MenuIFieldtemClick(Sender: TObject);
    procedure RememberQry(sQry : string);
    procedure OpenNewDB;
    procedure EnableMenus(bEnabled : boolean);

    function GetIniPath : string;
    procedure SaveSscemaToMD;
    procedure SyneditToLastPos;

  public
    bRemenberQuery : boolean;
    procedure InitSynCompFields(var Value: string);
    procedure run_main_query;
    procedure SaveSettings;
    procedure LoadSettings;
    procedure DisplayDataFileName(sFile : string);
    procedure ShowHintInStatusBar(Sender: TObject);

  end;

var
  Fmain: TFmain;

implementation

uses
   uSQLhist, uHistory, unew_table, frmCSVImp,
   IniFiles, UAttached, uReporterpas, LazFileUtils, uDBToPdf,
   uShortcutCheckDialogEx, ubuildsql;

{$R *.lfm}

 { TFmain }


procedure TFmain.mnuOpenClick(Sender: TObject);
begin
  OpenNewDB;
end;

procedure TFmain.mnuSaveToMarkdownClick(Sender: TObject);
begin
  SaveSscemaToMD;
end;

procedure TFmain.mnuSaveToPdfClick(Sender: TObject);
var
  SD: TSaveDialog;
begin
  SD := TSaveDialog.Create(nil);
  try
    SD.Filter := '*.pdf';
    SD.FileName := ExtractFileNameOnly(dmMain.Conn.DatabaseName) + '.pdf';
    // This tells the OS to prompt the user automatically if the file exists!
    SD.Options := SD.Options + [ofOverwritePrompt];

    if SD.Execute then
      DatabaseToPDF(dmMain.Conn, SD.FileName);
  finally
    SD.Free;
  end;
end;

procedure TFmain.mnuShowMetadataClick(Sender: TObject);
begin
  ShowMetaData(Self);
end;

procedure TFmain.mnuSqlFunctionsClick(Sender: TObject);
Var
   Dlg : TShortcutCheckDialog;
   SC : TShortcut;
begin
  SC := actSqliteFinctions.ShortCut;
  Dlg := TShortcutCheckDialog.Create(nil);
  Dlg.Compact:= True;
  if Dlg.Execute(SC, Self) then
   actSqliteFinctions.ShortCut := SC;

  Dlg.Free;

end;

procedure TFmain.mnuTableShortcutClick(Sender: TObject);
Var
   Dlg : TShortcutCheckDialog;
   SC : TShortcut;
begin
  SC := SynCompTables.ShortCut;
  Dlg := TShortcutCheckDialog.Create(nil);
  Dlg.Compact:= True;
  if Dlg.Execute(SC, Self) then
   SynCompTables.ShortCut := SC;

  Dlg.Free;

end;

procedure TFmain.MRUManagerRecentFile(Sender: TObject;
  const AFileName: String);
begin

 if not FileExists(AFileName) then
 begin
   ShowMessage('The selecteed file no longer exists.');
   MRUMenuMgr.RemoveFile(AFileName);
   exit;
 end;

 InitNewFile(Self, AFileName);
end;

procedure TFmain.MenugridfontClick(Sender: TObject);
begin
  FontDialog1.Font := Synedit1.Font;
  If FontDialog1.Execute then
   dbgQryResults.Font := FontDialog1.Font;
end;

procedure TFmain.mnuBuildSqlClick(Sender: TObject);
var
f : TfrmBuildSql;
i : integer;
begin

   for i := 0 to Screen.FormCount - 1 do
   begin
    if Screen.Forms[i] is TfrmBuildSql then
    begin
      Screen.Forms[i].Refresh;
      Screen.Forms[i].Show;
      Screen.Forms[i].BringToFront;
      Exit;
    end;
  end;


  f := TfrmBuildSql.Create(Self);
  f.TheEditor := SynEdit1;

  f.Show;
end;

procedure TFmain.mnuClearQueryListClick(Sender: TObject);
begin
  QryList.Clear;
end;

procedure TFmain.mnuFilesShortCutClick(Sender: TObject);
Var
   Dlg : TShortcutCheckDialog;
   SC : TShortcut;
begin
  SC := SynCompFields.ShortCut;
  Dlg := TShortcutCheckDialog.Create(nil);
  Dlg.Compact:= True;
  if Dlg.Execute(SC, Self) then
   SynCompFields.ShortCut := SC;

  Dlg.Free;
end;

procedure TFmain.MenuEditFontClick(Sender: TObject);
begin
  FontDialog1.Font := Synedit1.Font;
  If FontDialog1.Execute then
   Synedit1.Font := FontDialog1.Font;
end;

procedure TFmain.MenuAttachClick(Sender: TObject);
var
  NewDBName : string;
  f : TfrmAttached;
  i : integer;
begin

   for i := 0 to Screen.FormCount - 1 do
   begin
    if Screen.Forms[i] is TfrmAttached then
    begin
      Screen.Forms[i].Show;
      Screen.Forms[i].BringToFront;
      Exit;
    end;
  end;

  f := TfrmAttached.Create(self);
  f.Show;

end;

procedure TFmain.FormShow(Sender: TObject);
begin
  Refresh;
end;

procedure TFmain.FormDestroy(Sender: TObject);
begin
  QryList.Free;

end;

procedure TFmain.actNextExecute(Sender: TObject);
begin
    if QryList.Position = QryList.Count -1 then
  begin
    StatusBar.Panels[1].Text := 'At end of queries.';
    exit;
  end;
  QryList.Next;
  Synedit1.Text:= QryList.Current;
  SyneditToLastPos;
end;

procedure TFmain.actPrevExecute(Sender: TObject);
begin
  if QryList.Position = 0 then
  begin
    StatusBar.Panels[1].Text := 'At end of queries.';
    exit;
  end;
  QryList.Previous;
  Synedit1.Text:= QryList.Current;
  SyneditToLastPos;
end;

procedure TFmain.actSqliteFinctionsExecute(Sender: TObject);
begin
  PopupMnuFields.PopUp;
end;

procedure TFmain.ShowMetaData(Sender: TObject);
var
  s : string;
begin
     s:=Boiler_sql_meta;
     SynEdit1.Text:= s;
end;

procedure TFmain.cmdCreateNewClick(Sender: TObject);
var
  sFile   : string;
  s       : string;
  Dlg : TSaveDialog;
begin

  Dlg := TSaveDialog.Create(nil);
  Dlg.InitialDir:= GetCurrentDir;
  Dlg.Options:= [ofOverwritePrompt] ;
  Dlg.DefaultExt:= '.db';

  if Dlg.Execute then
   begin
    sFile := Dlg.FileName;
    dmMain.Conn.connected := false;
    dmMain.Conn.DatabaseName:= sFile;
    dmMain.Conn.connected := true;

    s := Boiler_sql_createtable;

    dmMain.Conn.ExecuteDirect(s);

    dmMain.Trans.Commit;
    dmMain.Conn.ExecuteDirect('DROP table people');
    dmMain.Trans.Commit;
    dmMain.Conn.connected := false;
    InitNewFile(Self, sFile);
  end;

  Dlg.Free;
end;

procedure TFmain.cmdDirectClick(Sender: TObject);
var
  s :string;
begin
   s := SynEdit1.Lines.Text ;
   dmMain.exe_direct(s);
end;



procedure TFmain.cmdRunClick(Sender: TObject);
begin

  if (dmMain.Conn.DatabaseName = '') then
  begin
     Showmessage('No database set');
     exit;
  end;

   dmMain.Conn.connected := true;
   run_main_query;
  end;

procedure TFmain.ComboBox1CloseUp(Sender: TObject);
var
   sTableName  : string;
   sTblRawName    : string;
   sTable_info : string;
   sFK, sIDX   : string;
   sCnxd       : string;
   bWantMataData : boolean;

begin
   bWantMataData := RadioGroup1.ItemIndex = 0;

  try
   SynEdit1.Lines.clear;
   sTblRawName := Trim(ComboBox1.Text);
   sTableName := '"' +ComboBox1.Text + '"';

   sCnxd := '-- select * from sqlite_schema where tbl_name = ' + sTableName + ' and type <> ''table''' ;

   sFK :=  '-- pragma foreign_key_list(' + sTableName + ')';

   sIDX := '-- pragma index_list(' + sTableName + ')';

   sTable_info:= '-- pragma table_info(' + sTableName + ')';

  if bWantMataData then
  begin
   SynEdit1.Lines.Add(sCnxd);
   SynEdit1.Lines.Add(sIDX);
   SynEdit1.Lines.Add(sFK);
   SynEdit1.Lines.Add(sTable_info);
  End;

  SynEdit1.Lines.Add('select * ');

  SynEdit1.Lines.Add('from ' + sTableName);
  SynEdit1.Lines.Add('');

 // SyneditToLastPos;
  SynEdit1.setfocus;

  run_main_query;
  InitSynCompFields(sTblRawName);



 except
   on E : exception do
   Showmessage('Error: ' + E.Message);
 end;

end;

procedure TFmain.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
   dmMain.Conn.connected := false;
   SaveSettings;
   MRUMenuMgr.SaveToIni(GetIniPath, 'RecentFiles');
   MRUMenuMgr.Free;

end;


procedure TFmain.FormCreate(Sender: TObject);
begin

  dbgQryResults.Options:= dbgQryResults.Options + [dgDisplayMemoText];
  bRemenberQuery := True;
  Self.Height:= trunc(SynEdit1.Height * 2.5);

  MRUMenuMgr := TMRUMenuManager.Create(mnuRecentFiles, 5);
  MRUMenuMgr.OnOpenFile := @MRUManagerRecentFile;
  MRUMenuMgr.LoadFromIni(GetIniPath, 'RecentFiles');

  QryList := TBoundedStringList.Create(200);
  QryList.WrapAround:=False;

  Panel1.Enabled:= False;
  LoadSettings;
  EnableMenus(false);
  InitPopupSQL(Self);

  Application.OnHint := @ShowHintInStatusBar;
end;

procedure TFmain.MenuItem1Click(Sender: TObject);
begin

 OpenDialog1.Filter:= 'SQL (*.sql, *.txt)|*.sql;*.txt|All files (*.*)|*.*';
  if OpenDialog1.Execute then
  begin
    SynEdit1.lines.LoadFromFile(OpenDialog1.FileName);
  end;
end;

procedure TFmain.mnuCreateTableClick(Sender: TObject);
var
  s :string;
  f : TfrmNewTable;
begin
  f := TfrmNewTable.Create(self);
  f.ShowModal;
  get_tablenames;
end;

procedure TFmain.mnuCSVImortClick(Sender: TObject);
var
   f : TfrmCsvImport;
begin
  f := TfrmCsvImport.Create(Self);
  f.Conn := dmMain.Conn;
  f.ShowModal;
  f.free;
end;

procedure TFmain.mnuExportClick(Sender: TObject);
begin
  SaveDialog1.InitialDir:= GetCurrentDir;

  if SaveDialog1.Execute then
  begin
   if FileExists(SaveDialog1.FileName) then
   begin
     ShowMessage(SaveDialog1.FileName + ' already exists!')
   end;
   dmMain.Qry.First;
   CSVExporter1.FileName:= SaveDialog1.FileName;
   CSVExporter1.Execute;
  end;
end;

procedure TFmain.mnuHistClick(Sender: TObject);
var
 f : TfrmHist;
 i : integer;
begin


   for i := 0 to Screen.FormCount - 1 do
   begin
    if Screen.Forms[i] is TfrmHist then
    begin
      Screen.Forms[i].Show;
      Screen.Forms[i].BringToFront;
      Exit;
    end;
  end;

   f := TfrmHist.create(Self);
   f.dsHist.DataSet :=mdHistory;
   F.Show;

end;

procedure TFmain.mnuSaveClick(Sender: TObject);
var
  Dlg : TSaveDialog;
begin

  Dlg := TSaveDialog.Create(nil);
  Dlg.InitialDir:= GetCurrentDir;
  Dlg.Options:= [ofOverwritePrompt] ;
  Dlg.DefaultExt:= '.sql';
 try
  if Dlg.Execute then
  begin
   SynEdit1.lines.SaveToFile(Dlg.FileName);
  end;
 finally;
  Dlg.Free;
end;

end;

procedure TFmain.mnuSqlCreateSQLClick(Sender: TObject);
Var
   F  : TfrmCreateSQL;
   i : integer;
begin


    for i := 0 to Screen.FormCount - 1 do
   begin
    if Screen.Forms[i] is TfrmCreateSQL then
    begin
      Screen.Forms[i].Show;
      Screen.Forms[i].BringToFront;
      Exit;
    end;
  end;

   f := TfrmCreateSQL.create(Self);
   F.Show;

end;



procedure TFmain.InitPopupSQL(Sender: TObject);
var
  i: Integer;
  MenuItem: TMenuItem;

  procedure Add(s: string);
  begin
    MenuItem := TMenuItem.Create(PopupMnuFields);
    MenuItem.Caption := s;
    MenuItem.OnClick := @MenuITabletemClick;
    PopupMnuFields.Items.Add(MenuItem);
  end;

begin

  PopupMnuFields.Items.Clear;
   Add('coalesce(X,Y,...): Returns first non-NULL.');
   Add('concat(X,...): Appends strings together.');
   Add('substr(string, start_position, length): select SUBSTR(phone_number, 2, 3) AS area_code');
   Add('format(F,...): Formats strings like printf.');
   Add('length(X): Returns character count.');
   Add('lower(X): Converts to lowercase.');
   Add('quote(X): Formats text for SQL.');
   Add('random(): Generates pseudo-random integer.');
   Add('soundex(X): Returns phonetic string encoding.');
   Add('upper(X): Converts to uppercase.');
   Add('date(T,M,...):  date(''now'', ''+2 years'', ''+1 month'', ''+5 days'')');
   Add('time(T,M,...): Formats time as HH:MM:SS.');
   Add('timediff(T1,T2): Returns difference between times');
   Add('ceiling(X): Rounds value upward.');
   Add('floor(X): Rounds value downward.');
   Add('row_number(): Assigns sequential integers sequentially.');
   Add('rank(): Ranks with gaps for ties.');
   Add('lag(E,O,D): Fetches preceding row data expressions.');
   Add('lead(E,O,D): Fetches succeeding row data expressions.');
   Add('first_value(E): Evaluates first partition window value.');
   Add('last_value(E): Evaluates last partition window value.');
   Add('nth_value(E,N): Evaluates Nth partition window value');


end;



function TFmain.Boiler_sql_meta: string;
var
  s: string;
begin

  s := '-- SELECT * FROM pragma_function_list()' + #13#10;
  s := s + ' SELECT m.*, p.* '  + #13#10;
  s := s + ' FROM sqlite_master AS m ' + #13#10 ;
  s := s + ' JOIN pragma_table_info(m.name) AS p ' + #13#10 ;
  s := s + ' WHERE   m.type = ''table''' + #13#10 ;
  s := s + ' ORDER BY   m.name,  p.cid ';
  Result:=s;
end;
function TFmain.Boiler_sql_createtable: string;
var
  s: string;
begin
    s := 'CREATE TABLE people (id INTEGER PRIMARY KEY AUTOINCREMENT, ' + #13#10;
  s := s +     'first_name varchar(20), ' + #13#10;
  s := s +    ' last_name varchar(20) )';

  Result:=s;
end;

procedure TFmain.get_tablenames;
var
  s : string;
begin
    ComboBox1.Clear;

    dmMain.Conn.connected := true;

    SynCompTables.ItemList.Clear;
    SynCompFields.ItemList.Clear;
    dmMain.GetTablesAndViews(SynCompTables.ItemList);
    dmMain.qryTables.Active:= true;
    dmMain.qryTables.First;
    while  not dmMain.qryTables.EOF do
    begin
      s := dmMain.qryTables.FieldByName('name').AsString;
      ComboBox1.Items.Add(s);
      dmMain.qryTables.Next;
    end;
    dmMain.qryTables.Active:= false;

end;

procedure TFmain.InitNewFile(Sender: TObject; const sFileName : string);
var
  f : TForm;
  i : integer;
begin
  dmMain.Conn.connected := false;
  dmMain.Conn.DatabaseName:= sFileName ;

  DisplayDataFileName(sFileName);
  Panel1.Enabled:= true;
  EnableMenus(true);
  get_tablenames;

  mnuSqlCreateSQL.Enabled:= true;
 // ComboBox1.setfocus;
 // ComboBox1.DroppedDown := True;


  for i := 0 to Screen.FormCount - 1 do
   begin

    if Screen.Forms[i] is TfrmCreateSQL then
    begin
      f := TfrmCreateSQL(Screen.Forms[i]);
      TfrmCreateSQL(f).Refresh;
    end;

    if Screen.Forms[i] is TfrmBuildSql then
    begin

      if Screen.Forms[i] is TfrmBuildSql then
      begin
        f := TfrmBuildSql(Screen.Forms[i]);
        TfrmBuildSql(f).Refresh;
      end;

    end;
end;

end;

procedure TFmain.RememberQry(sQry: string);
begin
  if bRemenberQuery then
  begin
   mdHistory.Append;
   mdHistory.FieldByName('Qry').AsString := sQry;
   mdHistory.Post;
  end;
end;

procedure TFmain.OpenNewDB;
var
 f : TfrmCreateSQL;
 i : integer;
 begin
  OpenDialog1.Filter:= 'SQlite files (*.db, *.dat)|*.db;*.dat|All files (*.*)|*.*';
  if not OpenDialog1.Execute then exit;

    MRUMenuMgr.AddFile(OpenDialog1.FileName) ;

    InitNewFile(Self, OpenDialog1.FileName);

   for i := 0 to Screen.FormCount - 1 do
   begin
    if Screen.Forms[i] is TfrmCreateSQL then
    begin
      f := TfrmCreateSQL(Screen.Forms[i]);
      f.Refresh;
      Exit;
    end;
  end;

end;

procedure TFmain.EnableMenus(bEnabled: boolean);
begin
  mnuSavetoFile.Enabled:= bEnabled;

  mnuLoadFile.Enabled:= bEnabled;
  mnuCreateTable.Enabled:= bEnabled;
  mnuCSVImort.Enabled:= bEnabled;
  mnuExport.Enabled:= bEnabled;
  mnuOther.Enabled:= bEnabled;
  mnuSchemaExport.Enabled := bEnabled;
end;



function TFmain.GetIniPath : string;
begin
  Result := ExtractFilePath(Application.ExeName) + 'config.ini';
end;

procedure TFmain.SaveSscemaToMD;
var
  Answer: Integer;
  sl: Tstringlist;
  MDReport: string;
  Reporter: TSQLiteSchemaReporter;
  SD: TSaveDialog;
begin
 Answer := mrYes;
  SD := TSaveDialog.Create(self);
    sl := Tstringlist.Create;
    SD.Filter:= '*.md';
    SD.FileName:= ExtractFileNameOnly(dmMain.Conn.DatabaseName) +'.md';
    if SD.Execute then
    if FileExists(SD.FileName) then
     Answer := MessageDlg('File already exists', 'Replace existing file:' ,
     mtConfirmation,
      [mbYes, mbNo, mbCancel],
      0
    );
    if Answer <> mrYes then exit;
    begin
     Reporter := TSQLiteSchemaReporter.Create(dmMain.Conn);
     try
      MDReport := Reporter.GenerateReport;

      sl.Text:= MDReport;
      sl.SaveToFile(SD.FileName);

    finally
      Reporter.Free;
      sl.Free;
      SD.Free;
    end;
    end;
end;

procedure TFmain.SyneditToLastPos;
var
   NewCaretPos: TPoint;
  begin
  // TSynEdit uses 1-based coordinates
    NewCaretPos.Y := SynEdit1.Lines.Count;

    if NewCaretPos.Y > 0 then
    // Set X to the length of the final line + 1
      NewCaretPos.X := Length(SynEdit1.Lines[NewCaretPos.Y - 1]) + 1
    else
     NewCaretPos.X := 1; // Fallback if the editor is completely empty

   SynEdit1.CaretXY := NewCaretPos;

end;

procedure TFmain.MenuIFieldtemClick(Sender: TObject);
var
   SelectedFieldName: string;
begin
   SelectedFieldName := (Sender as TMenuItem).Caption;
   Synedit1.InsertTextAtCaret(SelectedFieldName,scamAdjust);
end;

procedure TFmain.MenuITabletemClick(Sender: TObject);
var
   SelectedFieldName: string;
   Start : string;
   i : integer;
begin

       SelectedFieldName := (Sender as TMenuItem).Caption;
       i := Pos(':',SelectedFieldName);
       Start := Copy(SelectedFieldName, 1, i-1);
       Synedit1.InsertTextAtCaret(Start,scamEnd);

end;

procedure TFmain.SynCompTablesCodeCompletion(var Value: string;
  SourceValue: string; var SourceStart, SourceEnd: TPoint; KeyChar: TUTF8Char;
  Shift: TShiftState);
begin
  InitSynCompFields(Value);
end;





procedure TFmain.run_main_query;
var
  sQry : string;
begin

  if SynEdit1.SelText = '' then
    sQry := SynEdit1.Lines.Text
  else
   sQry := SynEdit1.SelText;


 try
  dmMain.Qry.active := False;
  dmMain.Qry.SQL.Text := sQry;
  dmMain.Qry.active := true;
  QryList.Add(sQry);
  RememberQry(sQry);
  dbgQryResults.AutoAdjustColumns;
 except
   on E : exception do
   Showmessage('Error: ' + E.Message);
 end;
end;

procedure TFmain.InitSynCompFields(var Value: string);
var
  T: TTable;
  sl: TStringlist;
  i: integer;
begin
  T := TTable.Create(dmMain.Conn);
    T.Name:= Value;
    sl := TStringlist.Create;
    SynCompFields.ItemList.Clear;

   T.FillNameList(sl);
   for i := 0 to sl.Count -1 do
    SynCompFields.ItemList.Add( sl[i]);
   sl.Free;
   T.Free;
end;

procedure TFmain.SaveSettings;
var
  Ini: TIniFile;
begin

  Ini := TIniFile.Create(ExtractFilePath(Application.Exename) + 'config.ini');
  try

    Ini.WriteInteger('MainForm', 'Top', Self.Top);
    Ini.WriteInteger('MainForm', 'Left', Self.Left);
    Ini.WriteInteger('MainForm', 'Width', Self.Width);
    Ini.WriteInteger('MainForm', 'RadioGroup1_ItemIndex', RadioGroup1.itemIndex);

    Ini.WriteInteger('MainForm', 'SynCompTablesShortcut', SynCompTables.ShortCut);
    Ini.WriteInteger('MainForm', 'SynCompFieldsShortcut', SynCompFields.ShortCut);

    Ini.WriteString('MainForm', 'SynEdit1_FontName', SynEdit1.Font.Name);
    Ini.WriteInteger('MainForm', 'SynEdit1_FontSize', SynEdit1.Font.Size);
  finally
    Ini.Free;
  end;

end;

procedure TFmain.LoadSettings;
var
  Ini: TIniFile;
begin

  Ini := TIniFile.Create(ExtractFilePath(Application.Exename) + 'config.ini');
  try

    Self.Top   := Ini.ReadInteger('MainForm', 'Top', Self.Top);
    Self.Left  := Ini.ReadInteger('MainForm', 'Left', Self.Left);
    Self.Width := Ini.ReadInteger('MainForm', 'Width', Self.Width);
    RadioGroup1.itemIndex := Ini.ReadInteger('MainForm', 'RadioGroup1_ItemIndex', 0);

    SynCompTables.ShortCut  := Ini.ReadInteger('MainForm', 'SynCompTablesShortcut', SynCompTables.ShortCut);
    SynCompFields.ShortCut  := Ini.ReadInteger('MainForm', 'SynCompFieldsShortcut', SynCompFields.ShortCut);

    SynEdit1.Font.Name := Ini.ReadString('MainForm', 'SynEdit1_FontName', SynEdit1.Font.Name);
    SynEdit1.Font.Size := Ini.ReadInteger('MainForm', 'SynEdit1_FontSize', SynEdit1.Font.Size);
  finally
    Ini.Free;
  end;

end;

procedure TFmain.DisplayDataFileName(sFile: string);
begin
  StatusBar.Panels[0].Text := sFile;
end;

procedure TFmain.ShowHintInStatusBar(Sender: TObject);
begin
 StatusBar.Panels[1].Text := Application.Hint;
end;

end.

