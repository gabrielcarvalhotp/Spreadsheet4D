unit Spreadsheets4D;

{$I Spreadsheets4D.inc}

interface

uses
  System.SysUtils,
  System.Classes,
  System.Variants,
  Data.DB,
{$IFDEF HAS_FMX}
  FMX.Types,
  FMX.Graphics,
  System.UITypes,
{$ELSE}
  Vcl.ExtCtrls,
  Vcl.Graphics,
{$ENDIF}
  System.StrUtils;

procedure DataSetForExcelSpreadsheet(ADataSet: TDataSet; ANameSizeColum: array of string; ASizeColum: array of Integer; AMergeCells, ASpreadsheetTitle: string);
procedure DataSetForBrOfficeSpreadsheet(ADataSet: TDataSet; ATitle: String);

implementation

{$IFDEF HAS_FMX}
{$ELSE}
{$ENDIF}

uses
  System.Win.ComObj;

procedure DataSetForExcelSpreadsheet(ADataSet: TDataSet; ANameSizeColum: array of string; ASizeColum: array of Integer; AMergeCells, ASpreadsheetTitle: string);
var
  LSpreadsheet: Variant;
  LFieldValue: string;
begin
  LSpreadsheet := CreateOleObject('Excel.Application');
  LSpreadsheet.WorkBooks.add(1);
  LSpreadsheet.caption := 'Exportando dados do dbGrid para o Excel';
  LSpreadsheet.visible := true;
  LSpreadsheet.Range[AMergeCells].Mergecells := true;
  LSpreadsheet.Cells[1, 1] := ASpreadsheetTitle;
  ADataSet.First;
  for var LLine := 0 to ADataSet.RecordCount - 1 do
  begin
    for var LColum := 1 to ADataSet.FieldCount do
    begin
      if ADataSet.Fields.Fields[LColum - 1].visible then
      begin
        if ADataSet.Fields.Fields[LColum - 1].DataType in [ftFloat, ftCurrency, ftBCD, ftFMTBcd] then
        begin
{$IFDEF HAS_FMX}
          LSpreadsheet.Cells[LLine + 3, LColum].Borders.Color := TAlphaColors.Black;
{$ELSE}
          LSpreadsheet.Cells[LLine + 3, LColum].Borders.Color := clBlack;
{$ENDIF}
          LSpreadsheet.Cells[LLine + 3, LColum].Font.Size := 8;
          LSpreadsheet.Cells[LLine + 3, LColum].numberFormat := '#.#0,00_);(#.#0,00)';
          LSpreadsheet.Cells[LLine + 3, LColum] := ADataSet.Fields.Fields[LColum - 1].AsFloat;
        end
        else if ADataSet.Fields.Fields[LColum - 1].DataType in [ftDate, ftDateTime, ftTimeStamp] then
        begin
{$IFDEF HAS_FMX}
          LSpreadsheet.Cells[LLine + 3, LColum].Borders.Color := TAlphaColors.Black;
{$ELSE}
          LSpreadsheet.Cells[LLine + 3, LColum].Borders.Color := clBlack;
{$ENDIF}
          LSpreadsheet.Cells[LLine + 3, LColum].Font.Size := 8;
          if ADataSet.Fields.Fields[LColum - 1].DataType in [ftTimeStamp] then
            LSpreadsheet.Cells[LLine + 3, LColum].numberFormat := 'DD/MM/AAAA'
          else
            LSpreadsheet.Cells[LLine + 3, LColum].numberFormat := 'DD/MM/AA';
          if ADataSet.Fields.Fields[LColum - 1].AsDateTime > 0 then
            LSpreadsheet.Cells[LLine + 3, LColum] := ADataSet.Fields.Fields[LColum - 1].AsDateTime;
        end
        else
        begin
{$IFDEF HAS_FMX}
          LSpreadsheet.Cells[LLine + 3, LColum].Borders.Color := TAlphaColors.Black;
{$ELSE}
          LSpreadsheet.Cells[LLine + 3, LColum].Borders.Color := clBlack;
{$ENDIF}
          LSpreadsheet.Cells[LLine + 3, LColum].Font.Size := 8;
          LSpreadsheet.Cells[LLine + 3, LColum] := ADataSet.Fields.Fields[LColum - 1].AsString;
        end;
      end;
    end;
    ADataSet.Next;
  end;
  for var LColum := 1 to ADataSet.FieldCount do
  begin
    if ADataSet.Fields.Fields[LColum - 1].visible then
    begin
      LFieldValue := ADataSet.Fields[LColum - 1].DisplayLabel;
      LSpreadsheet.Cells[2, LColum] := LFieldValue;
      LSpreadsheet.Cells[2, LColum].Font.Bold := true;
{$IFDEF HAS_FMX}
      LSpreadsheet.Cells[2, LColum].Font.Color := TAlphaColors.Black;
      LSpreadsheet.Cells[2, LColum].Borders.Color := TAlphaColors.Black;
      LSpreadsheet.Cells[2, LColum].Interior.Color := TAlphaColors.Gray;
{$ELSE}
      LSpreadsheet.Cells[2, LColum].Font.Color := clBlack;
      LSpreadsheet.Cells[2, LColum].Borders.Color := clBlack;
      LSpreadsheet.Cells[2, LColum].Interior.Color := clGray;
{$ENDIF}
    end;
  end;
  LSpreadsheet.columns.Autofit;
  for var I := 0 to Length(ANameSizeColum) - 1 do
    LSpreadsheet.Range[ANameSizeColum[I]].ColumnWidth := ASizeColum[I];
  LSpreadsheet := Unassigned;
end;

procedure DataSetForBrOfficeSpreadsheet(ADataSet: TDataSet; ATitle: String);
var
  LOpenDesktop, LCalc, LSheets, LSheet: Variant;
  LConnect, LOpenOffice: Variant;
  LColum: Integer; // Coluna
  LRow: Integer; // Linha
  LNumSheet: Integer;
  LFieldValue: string;

begin
  ADataSet.Open;
  ADataSet.Last;
  // Cria o link OLE com o LOpenOffice
  if VarIsEmpty(LOpenOffice) then
    LOpenOffice := CreateOleObject('com.sun.star.ServiceManager');

  LConnect := not(VarIsEmpty(LOpenOffice) or VarIsNull(LOpenOffice));
  // Inicia o LCalc
  LOpenDesktop := LOpenOffice.CreateInstance('com.sun.star.frame.Desktop');
  LCalc := LOpenDesktop.LoadComponentFromURL('private:factory/scalc', '_blank', 0, VarArrayCreate([0, -1], varVariant));
  LSheets := LCalc.Sheets;
  LSheet := LSheets.getByIndex(0);

  // Cria linha de cabe�alho
  LSheet.getCellByPosition(0, 0).setString(ATitle);

  LRow := 1;
  LColum := 0;
  for LColum := 0 to Pred(ADataSet.FieldCount) do
    if ADataSet.Fields[LColum].DataType <> ftDataSet then
      LSheet.getCellByPosition(LColum, LRow).setString(ADataSet.Fields[LColum].FieldName);

  // Preenche a planilha
  LRow := 2;
  ADataSet.First;
  while not ADataSet.Eof do
  begin
    LColum := 0;
    while LColum <= ADataSet.FieldCount - 1 do
    begin
      if ADataSet.Fields[LColum].DataType in [ftDate, ftTime, ftDateTime] then
      begin
        if ((DateToStr(ADataSet.Fields[LColum].Value) <> Null) and (DateToStr(ADataSet.Fields[LColum].Value) <> '')) then
        begin
          LSheet.getCellByPosition(LColum, LRow).setString(ADataSet.Fields[LColum].Value);
          LColum := LColum + 1;
        end;
      end
      else if ADataSet.Fields[LColum].DataType in [ftSmallint, ftInteger, ftLargeint, ftString, ftFloat] then
      begin
        LSheet := LSheets.getByIndex(0);

        // Cria linha de cabe�alho
        LColum := 0;
        while LColum <= ADataSet.FieldCount - 1 do
        begin
          if (ADataSet.Fields[LColum].FieldName <> 'ICONE') then
            if not(ADataSet.Fields[LColum].DataType in [ftDataSet]) then
              LSheet.getCellByPosition(LColum, LRow).setString(ADataSet.Fields[LColum].FieldName);
          LColum := LColum + 1;
        end;

        // Preenche a planilha
        LRow := 2;
        ADataSet.First;
        while not ADataSet.Eof do
        begin
          if LRow = 65536 then
          begin
            inc(LNumSheet);
            LSheet := LSheets.getByIndex(LNumSheet);
            LRow := 0;
          end;
          LColum := 0;

          // preenche linhas
          while LColum <= ADataSet.FieldCount - 1 do
          begin
            if (ADataSet.Fields[LColum].FieldName <> 'ICONE') then
            begin
              if not(ADataSet.Fields[LColum].DataType in [ftDataSet]) then
              begin
                if (ADataSet.Fields[LColum].AsString <> EmptyStr) then
                begin
                  if ADataSet.Fields[LColum].DataType in [ftDate, ftTime, ftDateTime, ftTimeStamp] then
                  begin
                    LSheet.getCellByPosition(LColum, LRow).setString(ADataSet.Fields[LColum].AsString);
                  end
                  else if ADataSet.Fields[LColum].DataType in [ftSmallint, ftInteger, ftLargeint] then
                  begin
                    LSheet.getCellByPosition(LColum, LRow).SetValue(ADataSet.Fields[LColum].AsInteger);
                  end
                  else if ADataSet.Fields[LColum].DataType in [ftFloat, ftCurrency, ftBCD, ftFMTBcd] then
                  begin
                    LSheet.getCellByPosition(LColum, LRow).SetValue(ADataSet.Fields[LColum].AsFloat);
                  end
                  else
                  begin
                    if ((ADataSet.Fields[LColum].Value <> Null) and (ADataSet.Fields[LColum].Value <> '')) then
                    begin
                      LFieldValue := ADataSet.Fields[LColum].Value;
                      LSheet.getCellByPosition(LColum, LRow).setString(LFieldValue);
                    end;
                  end;
                end
                else
                  LSheet.getCellByPosition(LColum, LRow).setString('');
              end;
            end;
            LColum := LColum + 1;
          end;
          ADataSet.Next;
          LRow := LRow + 1;
        end;
      end
      else
        LColum := LColum + 1;
    end;
  end;
  // Desconecta o LOpenOffice
  LOpenOffice := Unassigned;
end;

end.
