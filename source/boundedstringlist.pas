unit BoundedStringList;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils;

type
  EListFull = class(Exception);

  { TBoundedStringList }

  TBoundedStringList = class(TStringList)
  private
    FLimit: Integer;
    FCursor: Integer;
    FWrapAround: Boolean;
    function GetCurrent: string;
    procedure SetCurrent(AValue: string);
  public
    constructor Create(ALimit: Integer);
    function Add(const S: string): Integer; override;

    procedure Clear; override;
    procedure Next;
    procedure Previous;

    property Position: integer read FCursor;
    property Limit: Integer read FLimit write FLimit;
    property Current: string read GetCurrent write SetCurrent;
    property WrapAround: Boolean read FWrapAround write FWrapAround; // New property
  end;

implementation

constructor TBoundedStringList.Create(ALimit: Integer);
begin
  inherited Create;
  FLimit := ALimit;
  FCursor := -1;
  FWrapAround := True; // Defaults to your original ring-buffer behavior
end;

function TBoundedStringList.Add(const S: string): Integer;
var
  i :integer;
begin
  i := Self.IndexOf(S);
  Result := i;
  if i > -1 then exit;

  if (FLimit > 0) and (Count >= FLimit) then
    Self.Delete(0);

  Result := inherited Add(S);
  FCursor := Self.Count -1;


  // Initialize cursor to the first item if the list was previously empty
  if Count = 1 then
    FCursor := 0;
end;

procedure TBoundedStringList.Clear;
begin
  inherited Clear;
  FCursor := -1;
end;

function TBoundedStringList.GetCurrent: string;
begin
  if (FCursor >= 0) and (FCursor < Count) then
    Result := inherited Get(FCursor)
  else
    Result := '';
end;

procedure TBoundedStringList.SetCurrent(AValue: string);
begin
  if (FCursor >= 0) and (FCursor < Count) then
    inherited Put(FCursor, AValue)
  else if Count > 0 then
    FCursor := 0;
end;

procedure TBoundedStringList.Next;
begin
  if Count = 0 then Exit;

  if FWrapAround then
  begin
    Inc(FCursor);
    if FCursor >= Count then
      FCursor := 0; // Wrap around to the beginning
  end
  else
  begin
    // Only increment if we aren't already at the last item
    if FCursor < Count - 1 then
      Inc(FCursor);
  end;
end;

procedure TBoundedStringList.Previous;
begin
  if Count = 0 then Exit;

  if FWrapAround then
  begin
    Dec(FCursor);
    if FCursor < 0 then
      FCursor := Count - 1; // Wrap around to the end
  end
  else
  begin
    // Only decrement if we aren't already at the first item
    if FCursor > 0 then
      Dec(FCursor);
  end;
end;

end.

