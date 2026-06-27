unit UProportionalResizer;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Controls, Forms, dialogs;

type
  TResizeMode = (rmNone, rmVertical,rmHoriz, rmBoth);

  TControlData = record
    Control: TControl;
    Mode: TResizeMode;
    // Initial bounds of the control
    OrigLeft, OrigTop, OrigWidth, OrigHeight: Integer;
    // Initial bounds of the parent at the time of registration
    OrigParentWidth, OrigParentHeight: Integer;
  end;

  { TProportionalResizer }

  TProportionalResizer = class
  private
    FItems: array of TControlData;
    procedure UpdateControl(const Data: TControlData);
  public
    procedure RegisterControl(AControl: TControl; AMode: TResizeMode);
    procedure Execute; // Call this in FormResize

  end;

implementation

{ TProportionalResizer }

procedure TProportionalResizer.RegisterControl(AControl: TControl; AMode: TResizeMode);
var
  Idx: Integer;
begin

  if not Assigned(AControl) or not Assigned(AControl.Parent) then Exit;

  Idx := Length(FItems);
  SetLength(FItems, Idx + 1);

  with FItems[Idx] do
  begin
    Control := AControl;
    Mode := AMode;
    OrigLeft := AControl.Left;
    OrigTop := AControl.Top;
    OrigWidth := AControl.Width;
    OrigHeight := AControl.Height;
    // We scale relative to the parent's size at the moment of registration
    OrigParentWidth := AControl.Parent.ClientWidth;
    OrigParentHeight := AControl.Parent.ClientHeight;
  end;
end;

procedure TProportionalResizer.UpdateControl(const Data: TControlData);
var
  RatioX, RatioY: Double;
  NewLeft, NewTop, NewWidth, NewHeight: Integer;
begin
  // Calculate how much the parent has grown/shrunk
  RatioX := Data.Control.Parent.ClientWidth / Data.OrigParentWidth;
  RatioY := Data.Control.Parent.ClientHeight / Data.OrigParentHeight;

  // 1. Position always scales to maintain relative "percentage" placement
  NewLeft := Round(Data.OrigLeft * RatioX);
  NewTop := Round(Data.OrigTop * RatioY);

  // 2. Size scales based on the chosen mode
  case Data.Mode of
    rmNone:
      begin
        NewWidth := Data.OrigWidth;
        NewHeight := Data.OrigHeight;
      end;
    rmVertical:
      begin
        NewWidth := Data.OrigWidth;
        NewHeight := Round(Data.OrigHeight * RatioY);
      end;
    rmHoriz:
      begin
        NewHeight := Data.OrigHeight;
        NewWidth := Round(Data.OrigWidth * RatioX);
      end;
    rmBoth:
      begin
        NewWidth := Round(Data.OrigWidth * RatioX);
        NewHeight := Round(Data.OrigHeight * RatioY);
      end;
  end;

  Data.Control.SetBounds(NewLeft, NewTop, NewWidth, NewHeight);
end;

procedure TProportionalResizer.Execute;
var
  i: Integer;
begin
  for i := 0 to High(FItems) do
    UpdateControl(FItems[i]);
end;



end.
