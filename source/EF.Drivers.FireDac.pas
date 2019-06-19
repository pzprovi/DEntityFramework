{*******************************************************}
{         Copyright(c) Lindemberg Cortez.               }
{              All rights reserved                      }
{         https://github.com/LinlindembergCz            }
{		Since 01/01/2019                        }
{*******************************************************}
unit EF.Drivers.FireDac;

interface

uses
  Forms,FireDAC.Phys.FBDef, FireDAC.UI.Intf, FireDAC.VCLUI.Wait, FireDAC.Stan.Intf,
  FireDAC.Stan.Option, FireDAC.Stan.Error, FireDAC.Phys.Intf, FireDAC.Stan.Def,
  FireDAC.Stan.Pool, FireDAC.Stan.Async, FireDAC.Phys, FireDAC.Phys.FB,
  FireDAC.Comp.Client, FireDAC.Comp.UI, FireDAC.Phys.MSSQLDef,FireDAC.Phys.MSSQL,
  FireDAC.Phys.IBBase, FireDAC.Stan.Param, FireDAC.DatS, FireDAC.DApt.Intf,
  FireDAC.DApt, FireDAC.Comp.DataSet, DBClient, classes, Data.DB, SysUtils,
  EF.Drivers.Connection, FireDAC.Phys.PGDef, FireDAC.Phys.PG;

type


  TEntityFDConnection = class(TEntityConn)
  private
    procedure BeforeConnect(Sender: TObject);
  public
    procedure GetTableNames(var List: TStringList); override;
    procedure GetFieldNames(var List: TStringList; Table: string); override;
    procedure ExecutarSQL(prsSQL: string); override;
    function CreateDataSet(prsSQL: string; Keys:TStringList = nil): TFDQuery; override;
    procedure LoadFromFile(IniFileName: string);override;
    constructor Create(aDriver: FDConn; aUser,aPassword,aServer,aDataBase: string);overload;override;
    constructor Create(aDriver: FDConn; Conn : TFDConnection);overload;override;
  end;



implementation

uses
 EF.Core.Functions,
 EF.Schema.MSSQL,
 EF.Schema.Firebird,
 EF.Schema.MySQL,
 EF.Schema.PostGres;

resourcestring
  StrMyQL = 'MySQL';
  StrMSSQL = 'MSSQL';
  StrFirebird = 'Firebird';
  StrFB = 'FB';
  StrPG = 'PG';

{ TLinqFDConnection }

function TEntityFDConnection.CreateDataSet(prsSQL: string; Keys:TStringList = nil ): TFDQuery;
var
  qryVariavel: TFDQuery;
  J : integer;
begin
  qryVariavel := TFDQuery.Create(Application);
  with TFDQuery(qryVariavel) do
  begin
    Connection := CustomConnection as TFDConnection;
    SQL.Text := prsSQL;
    Prepared := true;
    open;

    UpdateOptions.AutoIncFields:= 'ID';
    Fieldbyname('ID').ProviderFlags :=[pfInWhere, pfInKey];
    Fieldbyname('ID').Required := false;
    UpdateOptions.UpdateMode := upWhereKeyOnly;

    for J := 0 to Fields.Count-1 do
    begin
      if UpperCase( Fields[J].FieldName) <> 'ID' then
      begin
        Fields[J].ProviderFlags:=[pfInUpdate];
      end;
    end;
  end;
  result := qryVariavel;
end;

procedure TEntityFDConnection.ExecutarSQL(prsSQL: string);
begin
  TFDConnection(CustomConnection).ExecSQL(prsSQL);
end;

procedure TEntityFDConnection.GetFieldNames(var List: TStringList; Table: string);
var
  I:integer;
begin
  TFDConnection(CustomConnection).GetFieldNames('','',Table,'',List);
  for I := 0 to List.Count - 1 do
  begin
    List[i]:= fStringReplace( List[i] ,'"','');
  end;
end;

procedure TEntityFDConnection.GetTableNames(var List: TStringList);
begin
  TFDConnection(CustomConnection).GetTableNames('','','',List);
end;

procedure TEntityFDConnection.LoadFromFile(IniFileName: string);
begin
  inherited;
  TFDConnection(CustomConnection).Params.LoadFromFile(IniFileName);
end;

constructor TEntityFDConnection.Create(aDriver: FDConn; aUser,aPassword,aServer,aDataBase: string);
begin
  inherited;
  CustomConnection := TFDConnection.Create(application);
  CustomConnection.LoginPrompt:= false;
  CustomConnection.BeforeConnect:= BeforeConnect;


  FServer   := aServer;
  FDataBase := aDataBase;
  FUser     := aUser;
  FPassword := aPassword;

  case aDriver of
     fdMyQL:
     begin
        CustomTypeDataBase := TMySQL.create;
        FDriver   := StrMyQL;
     end;
     fdMSSQL:
     begin
        CustomTypeDataBase := TMSSQL.create;
        FDriver   := StrMSSQL;
     end;
     fdFirebird:
     begin
        CustomTypeDataBase := TFirebird.create;
        FDriver   := StrFirebird;
     end;
     fdFB:
     begin
        CustomTypeDataBase := TFirebird.create;
        FDriver   := StrFB;
     end;
     fdPG:
     begin
        CustomTypeDataBase := TPostgres.create;
        FDriver   := StrPG;
     end;
  end;
end;

constructor TEntityFDConnection.Create(aDriver: FDConn; Conn: TFDConnection);
begin
  CustomConnection:= Conn;
  CustomConnection.LoginPrompt:= false;
  case aDriver of
     fdMyQL:
     begin
        CustomTypeDataBase := TMySQL.create;
        FDriver   := StrMyQL;
     end;
     fdMSSQL:
     begin
        CustomTypeDataBase := TMSSQL.create;
        FDriver   := StrMSSQL;
     end;
     fdFirebird:
     begin
        CustomTypeDataBase := TFirebird.create;
        FDriver   := StrFirebird;
     end;
     fdFB:
     begin
        CustomTypeDataBase := TFirebird.create;
        FDriver   := StrFB;
     end;
     fdPG:
     begin
        CustomTypeDataBase := TPostgres.create;
        FDriver   := StrPG;
     end;
  end;

end;

procedure TEntityFDConnection.BeforeConnect(Sender: TObject);
begin
  with TFDConnection(CustomConnection) do
  begin
    DriverName                  := FDriver;
    Params.Values['DriverID']   := FDriver;
    Params.Values['Server']     := FServer;
    Params.Values['DataBase']   := FDataBase;
    Params.Values['User_Name']  := FUser;
    Params.Values['Password']   := FPassword;
   //if Params.Find('yes',I) then
    //Params.Values['OSAuthent']  := 'yes';
  end;
end;

end.
