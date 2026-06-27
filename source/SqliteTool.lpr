program SqliteTool;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  {$IFDEF HASAMIGA}
  athreads,
  {$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Forms, lazdbexport, memdslaz, umain, dmod, uSQLhist, uHistory, uTable,
  frmCSVImp, UCsvUtil, UAttached;

{$R *.res}

begin
  RequireDerivedFormResource:=True;
  Application.Scaled:=True;
  Application.Initialize;
  Application.CreateForm(TdmMain, dmMain);
  Application.CreateForm(TFmain, Fmain);
  Application.Run;
end.

