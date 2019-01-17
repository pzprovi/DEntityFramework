{*******************************************************}
{         Copyright(c) Lindemberg Cortez.               }
{              All rights reserved                      }
{         https://github.com/LinlindembergCz            }
{		Since 01/01/2019                        }
{*******************************************************}
unit EF.Schema.Abstract;

interface

uses
Classes;

type
  TCustomDataBase= class
  public
     function AlterColumn(Table, Field, Tipo: string; IsNull: boolean): string ;virtual; abstract;
     function CreateTable( List: TList; Table: string; Key:TStringList = nil ): string ;virtual; abstract;
     function AlterTable(Table, Field, Tipo: string; IsNull: boolean;ColumnExist:boolean): string ;virtual; abstract;
  end;

implementation

end.