{*******************************************************}
{         Copyright(c) Lindemberg Cortez.               }
{              All rights reserved                      }
{         https://github.com/LinlindembergCz            }
{		Since 01/01/2019                        }
{*******************************************************}
unit EF.Schema.MSSQL;

interface

uses
  SysUtils, classes, strUtils,
  EF.Mapping.Atributes,
  EF.Mapping.AutoMapper,
  EF.Drivers.Connection,
  EF.Schema.Abstract;

type
  TMSSQL = class(TCustomDataBase)
  private
     function AlterColumn(Table, Field, Tipo: string; IsNull: boolean): string ;override;

  public
     function CreateTable( List: TList; Table: string;  Key:TStringList = nil): string ;override;
     function AlterTable( Table, Field, Tipo: string; IsNull: boolean;ColumnExist: boolean): string ;override;
     function GetPrimaryKey( Table, Fields: string):string;
     function CreateForeignKey(AtributoForeignKey: PParamForeignKeys;Table: string): string;override;
  end;

implementation

{ TMSSQLServer }

function TMSSQL.AlterColumn(Table, Field, Tipo: string;
  IsNull: boolean): string;
begin
   result:= 'Alter table ' + Table + ' Alter Column ' + Field + ' ' +
                 Tipo + ' ' + ifthen(IsNull, '', 'NOT NULL');
end;

function TMSSQL.AlterTable(Table, Field, Tipo: string; IsNull: boolean;ColumnExist: boolean): string;
begin
  if ColumnExist then
    result:= AlterColumn( Table , Field, tipo , IsNull)
  else
    result:= 'Alter table ' + Table + ' Add ' + Field + ' ' +
            Tipo + ' ' + ifthen(IsNull, '', 'NOT NULL')
end;

function TMSSQL.CreateTable( List: TList; Table: string; Key:TStringList = nil ): string;
var
  J: integer;

  TableList: TStringList;
  FieldAutoInc: string;

  Name, Tipo: string;
  AutoInc, PrimaryKey, IsNull: boolean;
  CreateScript , ListKey :TStringList;

begin
  CreateScript := TStringList.Create;
  ListKey          := TStringList.Create;
  ListKey.delimiter := ',';

  CreateScript.Clear;
  CreateScript.Add('Create Table ' + uppercase(Table));
  CreateScript.Add('(');
  FieldAutoInc := '';
  try
      for J := 0 to List.Count - 1 do
      begin
        Name := PParamAtributies(List.Items[J]).Name;
        Tipo := PParamAtributies(List.Items[J]).Tipo;
        if Tipo ='' then
          break;
        AutoInc := PParamAtributies(List.Items[J]).AutoInc;
        PrimaryKey := PParamAtributies(List.Items[J]).PrimaryKey;
        IsNull := PParamAtributies(List.Items[J]).IsNull;

        CreateScript.Add(Name + ' ' + Tipo + ' ' + ifthen(AutoInc, ' IDENTITY(1,1) ', '') +
         ifthen(IsNull, '', 'NOT NULL') + ifthen(J < List.Count - 1, ',', ''));

        if PrimaryKey then
        begin
          ListKey.Add(Name);
          if Key <> nil then
             Key.Add(Name);
        end;
      end;
      if ListKey.Count > 0 then
      begin
        CreateScript.Add( GetPrimaryKey(Table,ListKey.DelimitedText) );
        result:= CreateScript.Text;
      end
      else
        raise exception.Create('Primary Key is riquered!');
  finally
     CreateScript.Free;
     ListKey.Free;
     //Key.Free;
  end;
end;

function TMSSQL.GetPrimaryKey(Table, Fields: string): string;
begin
  result:= ', CONSTRAINT [PK_' + Table +
            '] PRIMARY KEY CLUSTERED([' + Fields +
            '] ASC) ON [PRIMARY])';
end;

function TMSSQL.CreateForeignKey(AtributoForeignKey: PParamForeignKeys;
  Table: string): string;
begin
  result:= 'ALTER TABLE '+Table +
           ' ADD CONSTRAINT FK_'+AtributoForeignKey.ForeignKey+
           ' FOREIGN KEY ('+AtributoForeignKey.ForeignKey+')'+
           ' REFERENCES '+AtributoForeignKey.Name+' (ID) '+
           ' ON DELETE '+ ifthen( AtributoForeignKey.OnDelete = rlCascade, ' CASCADE ',
                          ifthen( AtributoForeignKey.OnDelete = rlSetNull, ' SET NULL ',
                          ifthen( AtributoForeignKey.OnDelete = rlRestrict,' RESTRICT ',
                                                                           ' NO ACTION ' )))+
           ' ON Update '+ ifthen( AtributoForeignKey.OnUpdate = rlCascade, ' CASCADE ',
                          ifthen( AtributoForeignKey.OnUpdate = rlSetNull, ' SET NULL ',
                          ifthen( AtributoForeignKey.OnUpdate = rlRestrict,' RESTRICT ',
                                                                           ' NO ACTION ' )));
end;

end.
