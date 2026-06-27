unit uShortcutCheckDialogEx;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ComCtrls,
  StdCtrls, ExtCtrls;

type
  { TShortcutCheckDialog }

  TShortcutCheckDialog = class(TForm)
  private
    FHotKeyCtrl: TEdit;
    FShortcutCombo: TComboBox;
    FCurrentKey: TShortCut;
    FPromptLabel: TLabel;
    FComboLabel: TLabel;
    FWarningLabel: TLabel;
    FInUseLabel: TLabel;
    FInUseListBox: TListBox;
    FButtonPanel: TPanel;
    FOkButton: TButton;
    FCancelButton: TButton;
    FClearButton: TButton;
    FAssignedList: TStringList;
    FCompact : boolean;

    procedure ClearButtonClick(Sender: TObject);
    procedure HotKeyCtrlKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure ShortcutComboChange(Sender: TObject);
    procedure SetupLayout;
    procedure PopulateCommonShortcuts;
    procedure UpdateShortcutDisplay(SourceFromCombo: Boolean = False);
    procedure CheckForCollisions(const AShortcutText: string);
    procedure SetCompact(BeCompact : boolean);
  public
    constructor Create(AOwner: TComponent ); override;
    destructor Destroy; override;
    property Compact: boolean read FCompact write SetCompact;
    // Updated Execute to accept the Target form for scanning
    function Execute(var ACurrentShortcut: TShortCut; ATargetForm: TForm): Boolean;
  end;

implementation

uses
   TypInfo, LCLType, LCLIntf, LCLProc;

{ TShortcutCheckDialog }

procedure GetAssignedShortcuts(AForm: TForm; AList: TStringList);
var
  i: Integer;
  Comp: TComponent;
  CurrentShortCut: TShortCut;
  PropInfo: PPropInfo;
  ShortCutString: string;
begin
  if not Assigned(AList) then
    Exit;

  AList.Clear;

  for i := 0 to AForm.ComponentCount - 1 do
  begin
    Comp := AForm.Components[i];
    CurrentShortCut := 0;

    // Use RTTI to check if the component has a published 'ShortCut' property
    PropInfo := GetPropInfo(Comp, 'ShortCut');

    // If the property exists, safely extract its numeric value
    if Assigned(PropInfo) then
      CurrentShortCut := TShortCut(GetOrdProp(Comp, PropInfo));

    // If a shortcut is actually assigned (not 0)
    if CurrentShortCut <> 0 then
    begin
      ShortCutString := ShortCutToText(CurrentShortCut);
      AList.Add(Comp.Name + '=' + ShortCutString);
    end;
  end;
end;

constructor TShortcutCheckDialog.Create(AOwner: TComponent);
begin
  inherited CreateNew(AOwner);
  FAssignedList := TStringList.Create;
  SetupLayout;
  PopulateCommonShortcuts;
end;

destructor TShortcutCheckDialog.Destroy;
begin
  FAssignedList.Free;
  inherited Destroy;
end;

procedure TShortcutCheckDialog.SetupLayout;
begin
  // Configure Form properties
  Self.Caption := 'Select Shortcut';
  Self.Position := poMainFormCenter;
  Self.BorderStyle := bsDialog;
  Self.Width := 400;
  Self.Height := 450; // Increased height to accommodate the listbox
  Self.KeyPreview := True;

  // Prompt Label for Custom Input
  FPromptLabel := TLabel.Create(Self);
  FPromptLabel.Parent := Self;
  FPromptLabel.Align := alTop;
  FPromptLabel.Alignment := taCenter;
  FPromptLabel.BorderSpacing.Top := 12;
  FPromptLabel.Caption := 'Press custom key combination:';
  FPromptLabel.Font.Style := [fsBold];

  // HotKey Capture Control (TEdit)
  FHotKeyCtrl := TEdit.Create(Self);
  FHotKeyCtrl.Parent := Self;
  FHotKeyCtrl.Align := alTop;
  FHotKeyCtrl.BorderSpacing.Around := 12;
  FHotKeyCtrl.ReadOnly := True;
  FHotKeyCtrl.Alignment := taCenter;
  FHotKeyCtrl.OnKeyDown := @HotKeyCtrlKeyDown;

  // Label for Drop-down
  FComboLabel := TLabel.Create(Self);
  FComboLabel.Parent := Self;
  FComboLabel.Align := alTop;
  FComboLabel.Alignment := taCenter;
  FComboLabel.Caption := 'Or select a standard shortcut:';
  FComboLabel.Font.Style := [fsBold];

  // Drop-down ComboBox
  FShortcutCombo := TComboBox.Create(Self);
  FShortcutCombo.Parent := Self;
  FShortcutCombo.Align := alTop;
  FShortcutCombo.Style := csDropDownList;
  FShortcutCombo.BorderSpacing.Around := 12;
  FShortcutCombo.OnChange := @ShortcutComboChange;

  // Warning Label (Real-time collision detection)
  FWarningLabel := TLabel.Create(Self);
  FWarningLabel.Parent := Self;
  FWarningLabel.Align := alTop;
  FWarningLabel.Alignment := taCenter;
  FWarningLabel.BorderSpacing.Bottom := 12;
  FWarningLabel.Font.Style := [fsBold];
  FWarningLabel.Caption := '';

  // Button Panel (Bottom)
  FButtonPanel := TPanel.Create(Self);
  FButtonPanel.Parent := Self;
  FButtonPanel.Align := alBottom;
  FButtonPanel.BevelOuter := bvNone;
  FButtonPanel.Height := 40;
  FButtonPanel.BorderSpacing.Bottom := 10;

  // In Use Label
  FInUseLabel := TLabel.Create(Self);
  FInUseLabel.Parent := Self;
  FInUseLabel.Align := alTop;
  FInUseLabel.Caption := '  Shortcuts currently in use:';
  FInUseLabel.BorderSpacing.Bottom := 4;

  // In Use ListBox (Takes remaining space)
  if not FCompact then
  begin
  FInUseListBox := TListBox.Create(Self);
  FInUseListBox.Parent := Self;
  FInUseListBox.Align := alClient;
  FInUseListBox.BorderSpacing.Left := 12;
  FInUseListBox.BorderSpacing.Right := 12;
  FInUseListBox.BorderSpacing.Bottom := 12;
  FInUseListBox.TabStop := False; // Prevent stealing focus
  end;

  // OK Button
  FOkButton := TButton.Create(Self);
  FOkButton.Parent := FButtonPanel;
  FOkButton.Caption := 'OK';
  FOkButton.ModalResult := mrOk;
  FOkButton.Default := True;
  FOkButton.Width := 75;
  FOkButton.Align := alRight;
  FOkButton.BorderSpacing.Right := 15;

  // Cancel Button
  FCancelButton := TButton.Create(Self);
  FCancelButton.Parent := FButtonPanel;
  FCancelButton.Caption := 'Cancel';
  FCancelButton.ModalResult := mrCancel;
  FCancelButton.Cancel := True;
  FCancelButton.Width := 75;
  FCancelButton.Align := alRight;
  FCancelButton.BorderSpacing.Right := 10;

  // Clear Button
  FClearButton := TButton.Create(Self);
  FClearButton.Parent := FButtonPanel;
  FClearButton.Caption := 'Clear';
  FClearButton.Width := 75;
  FClearButton.Align := alLeft;
  FClearButton.BorderSpacing.Left := 15;
  FClearButton.OnClick := @ClearButtonClick;
end;

procedure TShortcutCheckDialog.PopulateCommonShortcuts;
var
  Modifiers: array[0..3] of TShiftState;
  i, k: Integer;
  SC: TShortCut;
begin
  FShortcutCombo.Items.BeginUpdate;
  try
    FShortcutCombo.Items.Clear;
    FShortcutCombo.Items.Add('None');

    Modifiers[0] := [ssCtrl];
    Modifiers[1] := [ssCtrl, ssShift];
    Modifiers[2] := [ssAlt];
    Modifiers[3] := [ssCtrl, ssAlt];

    for i := 0 to High(Modifiers) do
    begin
      for k := ord('A') to ord('Z') do
      begin
        SC := KeyToShortCut(k, Modifiers[i]);
        FShortcutCombo.Items.AddObject(ShortCutToText(SC), TObject(PtrInt(Integer(SC))));
      end;
    end;

    for k := VK_F1 to VK_F12 do
    begin
      SC := KeyToShortCut(k, []);
      FShortcutCombo.Items.AddObject(ShortCutToText(SC), TObject(PtrInt(Integer(SC))));
    end;

  finally
    FShortcutCombo.Items.EndUpdate;
  end;
end;

procedure TShortcutCheckDialog.HotKeyCtrlKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if (Key = VK_CONTROL) or (Key = VK_SHIFT) or (Key = VK_MENU) then
    Exit;

  FCurrentKey := KeyToShortCut(Key, Shift);
  UpdateShortcutDisplay(False);
  Key := 0;
end;

procedure TShortcutCheckDialog.ShortcutComboChange(Sender: TObject);
var
  Idx: Integer;
begin
  Idx := FShortcutCombo.ItemIndex;
  if Idx <= 0 then
    FCurrentKey := 0
  else
    FCurrentKey := TShortCut(Integer(PtrInt(FShortcutCombo.Items.Objects[Idx])));

  UpdateShortcutDisplay(True);
end;

procedure TShortcutCheckDialog.CheckForCollisions(const AShortcutText: string);
var
  i: Integer;
  CompName, ScValue: string;
  Found: Boolean;
begin
  if AShortcutText = 'None' then
  begin
    FWarningLabel.Caption := '';
    Exit;
  end;

  Found := False;
  CompName := '';

  // Iterate through the assigned list using TStringList Key/Value properties
  for i := 0 to FAssignedList.Count - 1 do
  begin
    ScValue := FAssignedList.ValueFromIndex[i];

    if SameText(ScValue, AShortcutText) then
    begin
      CompName := FAssignedList.Names[i];
      Found := True;
      Break;
    end;
  end;

  if Found then
  begin
    if not FCompact then
      FWarningLabel.Caption := 'Warning: In use!'
    else
     FWarningLabel.Caption := 'Warning: In use by "' + CompName + '"';
    FWarningLabel.Font.Color := clRed;
  end
  else
  begin
    FWarningLabel.Caption := 'Shortcut is available.';
    FWarningLabel.Font.Color := clGreen;
  end;
end;

procedure TShortcutCheckDialog.SetCompact(BeCompact: boolean);
begin

    if  BeCompact then
    begin
      Self.Height:= 350;
      FInUseListBox.Height:= 1;
      FInUseListBox.Visible := False;
      FInUseListBox.Align:= alNone;
      Self.Height:= Self.Height - FInUseListBox.Height;
      FInUseLabel.Visible:= False;
    end;

end;

procedure TShortcutCheckDialog.UpdateShortcutDisplay(SourceFromCombo: Boolean);
var
  Txt: string;
  Idx: Integer;
begin
  if FCurrentKey = 0 then
    Txt := 'None'
  else
    Txt := ShortCutToText(FCurrentKey);

  FHotKeyCtrl.Text := Txt;

  // Verify against existing shortcuts
  CheckForCollisions(Txt);

  if not SourceFromCombo then
  begin
    Idx := FShortcutCombo.Items.IndexOf(Txt);
    if Idx >= 0 then
      FShortcutCombo.ItemIndex := Idx
    else
      FShortcutCombo.ItemIndex := -1;
  end;
end;

procedure TShortcutCheckDialog.ClearButtonClick(Sender: TObject);
begin
  FCurrentKey := 0;
  UpdateShortcutDisplay(False);
  FHotKeyCtrl.SetFocus;
end;

function TShortcutCheckDialog.Execute(var ACurrentShortcut: TShortCut; ATargetForm: TForm): Boolean;
begin

  // Fetch currently assigned shortcuts on the target form
  if Assigned(ATargetForm) then
  begin
    GetAssignedShortcuts(ATargetForm, FAssignedList);
    FInUseListBox.Items.Assign(FAssignedList);
  end;

  FCurrentKey := ACurrentShortcut;
  UpdateShortcutDisplay(False);

  Self.ActiveControl := FHotKeyCtrl;

  if Self.ShowModal = mrOk then
  begin
    ACurrentShortcut := FCurrentKey;
    Result := True;
  end
  else
    Result := False;
end;

end.

