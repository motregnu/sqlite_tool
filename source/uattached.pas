unit UAttached;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, SQLDB, DB, Forms, Controls, Graphics, Dialogs, DBGrids,
  StdCtrls, ExtCtrls;

type

  { TfrmAttached }

  TfrmAttached = class(TForm)
    cmdAttachNew: TButton;
    cmdDetach: TButton;
    cmdNewDB: TButton;
    cmdShowAttached: TButton;
    dsAttached: TDataSource;
    edAlias: TEdit;
    GridAttached: TDBGrid;
    Label1: TLabel;
    lblNewDBPath: TLabel;
    pnlMiddle: TPanel;
    pnlBottom: TPanel;
    QryAttached: TSQLQuery;
    procedure cmdAttachNewClick(Sender: TObject);
    procedure cmdDetachClick(Sender: TObject);
    procedure cmdNewDBClick(Sender: TObject);
    procedure cmdShowAttachedClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure QryAttachedAfterOpen(DataSet: TDataSet);
  private
    procedure ReSet;
    procedure ShowAttachedTables;
  public
    procedure Refresh;
    procedure LoadSettings;
    procedure SaveSettings;
  end;

var
  frmAttached: TfrmAttached;

implementation
Uses dmod, umain, IniFiles;

{$R *.lfm}

{ TfrmAttached }

procedure TfrmAttached.FormCreate(Sender: TObject);
begin
  QryAttached.DataBase := dmMain.Conn;
  QryAttached.Open;
  QryAttached.Active:= True;
  LoadSettings;
end;

procedure TfrmAttached.QryAttachedAfterOpen(DataSet: TDataSet);
begin
  GridAttached.AutoAdjustColumns;
end;

procedure TfrmAttached.ReSet;
begin
  edAlias.Text := '';
  lblNewDBPath.Caption:= '';
  QryAttached.Active:= false;
  QryAttached.Active:= True;
end;

procedure TfrmAttached.ShowAttachedTables;
var
  sDB : string;
  S : string;
  bSave : boolean;
begin

  sDB := QryAttached.FieldByName('name').asstring;
  s := 'select name '  + #13#10;
  s := s + Format(' from %s.sqlite_master',[sDB]) + #13#10;
  s := s + ' where type = ' + QuotedStr('table') + #13#10;
  s := s + ' and name <> ''sqlite_sequence''';

  Fmain.SynEdit1.Text:= s;

  bSave := Fmain.bRemenberQuery;
  Fmain.bRemenberQuery:= False;
  Fmain.run_main_query;
  Fmain.bRemenberQuery:= bSave;

end;

procedure TfrmAttached.Refresh;
begin
   QryAttached.Active:= false;
   QryAttached.Active:= True;
end;

procedure TfrmAttached.LoadSettings;
var
  Ini: TIniFile;
begin

  Ini := TIniFile.Create(ExtractFilePath(Application.Exename) + 'config.ini');
  try

    Self.Top   := Ini.ReadInteger('AttachForm', 'Top', Self.Top);
    Self.Left  := Ini.ReadInteger('AttachForm', 'Left', Self.Left);
    Self.Width := Ini.ReadInteger('AttachForm', 'Width', Self.Width);
    Self.Height := Ini.ReadInteger('AttachForm', 'Height', Self.Height);

  finally
    Ini.Free;
  end;


end;

procedure TfrmAttached.SaveSettings;
var
  Ini: TIniFile;
begin

  Ini := TIniFile.Create(ExtractFilePath(Application.Exename) + 'config.ini');
  try

    Ini.WriteInteger('AttachForm', 'Top', Self.Top);
    Ini.WriteInteger('AttachForm', 'Left', Self.Left);
    Ini.WriteInteger('AttachForm', 'Width', Self.Width);
    Ini.WriteInteger('AttachForm', 'Height', Self.Height);

  finally
    Ini.Free;
  end;

end;



procedure TfrmAttached.cmdNewDBClick(Sender: TObject);
begin
  Fmain.OpenDialog1.Filter:= 'SQlite files (*.db, *.dat)|*.db;*.dat|All files (*.*)|*.*';
  If Fmain.OpenDialog1.Execute then
   lblNewDBPath.Caption:= Fmain.OpenDialog1.FileName;

end;

procedure TfrmAttached.cmdShowAttachedClick(Sender: TObject);
begin
  ShowAttachedTables;
end;

procedure TfrmAttached.FormClose(Sender: TObject; var CloseAction: TCloseAction
  );
begin
  SaveSettings;
end;

procedure TfrmAttached.cmdAttachNewClick(Sender: TObject);
begin
  If trim(edAlias.Text) = '' then
   begin
      Showmessage('Alias name is blank');
      exit;
   end;

  if (lblNewDBPath.Caption = '') or ((lblNewDBPath.Caption = 'none'))  then
   begin
    Showmessage('No file selected.');
      exit;
   end;
   dmMain.attach(lblNewDBPath.Caption, edAlias.Text);

   ReSet;
end;

procedure TfrmAttached.cmdDetachClick(Sender: TObject);
var
  DetachName : string;
begin
  DetachName := QryAttached.FieldByName('name').asstring;
  If DetachName = 'main' then
   ShowMessage('Cannot remove ' + DetachName)
  else begin
    dmMain.detach(DetachName);
    ReSet;
  end;
end;

end.

