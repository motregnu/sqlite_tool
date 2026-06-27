unit uHistory;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, DB, Forms, Controls, Graphics, Dialogs, DBCtrls, DBGrids,
  StdCtrls, Buttons, memds, Grids, types, LCLIntf, ExtCtrls,
  UProportionalResizer;

type

  { TfrmHist }

  TfrmHist = class(TForm)
    BitBtn1: TBitBtn;
    ButtonClearHistory: TButton;
    ButtonLoadHistory: TButton;
    ButtonSaveHistory: TButton;
    cbAutoRun: TCheckBox;
    cmdRetrieText: TButton;
    dsHist: TDataSource;
    DBGrid1: TDBGrid;
    DBNavigator1: TDBNavigator;
    Panel1: TPanel;
    procedure ButtonClearHistoryClick(Sender: TObject);
    procedure ButtonLoadHistoryClick(Sender: TObject);
    procedure ButtonSaveHistoryClick(Sender: TObject);
    procedure cmdRetrieTextClick(Sender: TObject);
    procedure DBGrid1DblClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);

  private
   Resizer: TProportionalResizer;
  public

  end;

var
  frmHist: TfrmHist;

implementation

Uses
   umain;

{$R *.lfm}

{ TfrmHist }

procedure TfrmHist.cmdRetrieTextClick(Sender: TObject);
var
   s : string;
begin
   s := dsHist.DataSet.FieldByName('Qry').asString;
   Fmain.SynEdit1.Text:= s;
   if cbAutoRun.Checked then begin
     Fmain.bRemenberQuery:= False;
     Fmain.run_main_query;
   end;
   Fmain.bRemenberQuery:= True;
end;

procedure TfrmHist.DBGrid1DblClick(Sender: TObject);
begin
  cmdRetrieTextClick(Sender);
end;

procedure TfrmHist.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin

end;

procedure TfrmHist.FormCreate(Sender: TObject);
begin
  Resizer := TProportionalResizer.create;
  Resizer.RegisterControl(cmdRetrieText, rmHoriz);

  Resizer.RegisterControl(cmdRetrieText, rmHoriz);
  Resizer.RegisterControl(ButtonLoadHistory, rmHoriz);
  Resizer.RegisterControl(ButtonSaveHistory, rmHoriz);
  Resizer.RegisterControl(ButtonClearHistory, rmHoriz);
end;

procedure TfrmHist.FormDestroy(Sender: TObject);
begin
    if Assigned(Resizer) then
      Resizer.Free;
end;

procedure TfrmHist.ButtonSaveHistoryClick(Sender: TObject);
begin
  if Fmain.SaveDialog1.Execute then
  Fmain.mdHistory.SaveToFile(Fmain.SaveDialog1.FileName, true);
end;

procedure TfrmHist.ButtonLoadHistoryClick(Sender: TObject);
begin
  if Fmain.OpenDialog1.Execute then
  begin
   Fmain.mdHistory.LoadFromFile(Fmain.OpenDialog1.FileName);
   Fmain.mdHistory.Open;
  end;
end;

procedure TfrmHist.ButtonClearHistoryClick(Sender: TObject);
begin
  Fmain.mdHistory.First;
 while Fmain.mdHistory.RecordCount >0 do
 begin
   Fmain.mdHistory.Delete;
   Fmain.mdHistory.Next;
 end;
end;





end.

