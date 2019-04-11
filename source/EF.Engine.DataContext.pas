{*******************************************************}
{         Copyright(c) Lindemberg Cortez.               }
{              All rights reserved                      }
{         https://github.com/LinlindembergCz            }
{		            Since 01/01/2019                        }
{*******************************************************}
unit EF.Engine.DataContext;

interface

uses
  MidasLib, System.Classes, strUtils, SysUtils, Variants, Dialogs,
  DateUtils,
  Datasnap.Provider, Forms, Datasnap.DBClient, System.Contnrs, Data.DB,
  System.Generics.Collections, Vcl.DBCtrls, StdCtrls, Controls, System.TypInfo,
  System.threading,
  // Essas units dar�o suporte ao nosso framework
  EF.Core.Consts,
  EF.Drivers.Connection,
  EF.Core.Types,
  EF.Mapping.Atributes,
  EF.Mapping.Base,
  EF.Core.Functions,
  EF.QueryAble.Base,
  EF.QueryAble.Interfaces,
  FireDAC.Comp.Client,
  Data.DB.Helper ;

Type
  TDataContext = class(TQueryAble)
  private
    ListObjectsInclude:TList;
    Classes: array of TClass;
    TableList: TStringList;
    FFDQuery: TFDQuery;
    drpProvider: TDataSetProvider;
    FDbSet: TClientDataSet;

    FConnection: TEntityConn;
    FProviderName: string;
    FTypeConnetion: TTypeConnection;

    ListField: TStringList;
    function CreateTables: boolean; // (aClass: array of TClass);
    function AlterTables: boolean;
    procedure FreeObjects;
    function CriarTabela(i: integer): boolean;
    function IsFireBird: boolean;
  protected
    procedure DataSetProviderGetTableName(Sender: TObject; DataSet: TDataSet; var TableName: string); virtual;
    procedure ReconcileError(DataSet: TCustomClientDataSet; E: EReconcileError; UpdateKind: TUpdateKind; var Action: TReconcileAction); virtual;
    procedure CreateClientDataSet(proDataSetProvider: TDataSetProvider; SQL: string = '');
    procedure CreateProvider(var proSQLQuery: TFDQuery; prsNomeProvider: string);
  public
    destructor Destroy; override;
    constructor Create(proEntity: TEntityBase = nil); overload; virtual;
    procedure Add;
    procedure Update;
    procedure Remove;
    procedure SaveChanges;
    function FindEntity(QueryAble: IQueryAble): TEntityBase; overload;
    function FindEntity<T: Class>(QueryAble: IQueryAble): T; overload;
    function FirstOrDefault(Condicion: TString): TEntityBase;
    function Include( E: TObject ):TDataContext;
    function Where(Condicion: TString): TDataContext;
    function GetData(QueryAble: IQueryAble): OleVariant;
    function GetDataSet(QueryAble: IQueryAble): TClientDataSet;
    function GetList(QueryAble: IQueryAble): TList;overload;
    function GetList<T: TEntityBase>(QueryAble: IQueryAble): TList<T>; overload;
    function GetJson(QueryAble: IQueryAble): string;
    procedure AddDirect;
    procedure UpdateDirect;
    procedure RemoveDirect;
    procedure InputEntity(Contener: TComponent);
    procedure ReadEntity(Contener: TComponent; DataSet: TDataSet = nil);
    procedure InitEntity(Contener: TComponent);
    function UpdateDataBase(aClasses: array of TClass): boolean;
    procedure RefreshDataSet;
    function ChangeCount: integer;
    function GetFieldList: Data.DB.TFieldList;
  published
    property DbSet: TClientDataSet read FDbSet write FDbSet;
    property Connection: TEntityConn read FConnection write FConnection;
    property ProviderName: string read FProviderName write FProviderName;
    property TypeConnetion: TTypeConnection read FTypeConnetion write FTypeConnetion;
  end;

  function From(E: String): TFrom; overload;
  function From(E: TEntityBase): TFrom; overload;
  function From(E: array of TEntityBase): TFrom; overload;
  function From(E: TClass): TFrom; overload;
  function From(E: IQueryAble): TFrom; overload;

implementation

uses
  Vcl.ExtCtrls,
  EF.Schema.Firebird,
  EF.Schema.MSSQL,
  EF.Mapping.AutoMapper;

function TDataContext.GetData(QueryAble: IQueryAble): OleVariant;
begin
  try
    FFDQuery := Connection.CreateDataSet(GetQuery(QueryAble));

    CreateProvider(FFDQuery, trim(fStringReplace(QueryAble.SEntity,
        trim(StrFrom), '')));
    CreateClientDataSet(drpProvider);

    result := DbSet.Data;

  finally
    DbSet.Free;
    DbSet:= nil;
    drpProvider.Free;
    drpProvider:= nil;
    FFDQuery.Free;
    FFDQuery:= nil;
  end;
end;

procedure TDataContext.FreeObjects;
begin

  if DbSet <> nil then
  begin
    DbSet.Close;
    DbSet.Free;
  end;
  if drpProvider <> nil then
  begin
    drpProvider.Free;
  end;
  if FFDQuery <> nil then
  begin
    FFDQuery.close;
    FFDQuery.Free;
  end;
end;

function TDataContext.GetDataSet(QueryAble: IQueryAble): TClientDataSet;
var
  Keys: TStringList;
begin
  try
    try
      FreeObjects;
      if FProviderName = '' then
      begin
        Keys := TAutoMapper.GetFieldsPrimaryKeyList(QueryAble.Entity);
        FSEntity := TAutoMapper.GetTableAttribute(FEntity.ClassType);

        FFDQuery := Connection.CreateDataSet(GetQuery(QueryAble), Keys);

        CreateProvider(FFDQuery, trim(fStringReplace(QueryAble.SEntity,  trim(StrFrom), '')));

        CreateClientDataSet(drpProvider);
      end
      else
      begin
        CreateClientDataSet(nil, GetQuery(QueryAble));
      end;
      result := DbSet;
    except
      on E: Exception do
      begin
        showmessage(E.message);
      end;
    end;
  finally
    Keys.Free;
  end;
end;

function TDataContext.GetList<T>(QueryAble: IQueryAble): TList<T>;
var
  List: TList<T>;
  DataSet: TClientDataSet;
begin
  try
    FEntity := QueryAble.Entity;
    FSEntity := TAutoMapper.GetTableAttribute(FEntity.ClassType);

    List := TList<T>.Create;
    DataSet := TClientDataSet.Create(Application);
    DataSet.Data := GetData(QueryAble);
    while not DataSet.Eof do
    begin
      TAutoMapper.DataToEntity(DataSet, QueryAble.Entity);
      List.Add(QueryAble.Entity);
      DataSet.Next;
    end;
    result := List;
  finally
    FreeAndNil(DataSet);
  end;
end;

function TDataContext.GetList(QueryAble: IQueryAble): TList;
var
  List: TList;
  DataSet: TClientDataSet;
begin
  try
    FEntity := QueryAble.Entity;
    FSEntity := TAutoMapper.GetTableAttribute(FEntity.ClassType);

    List := TList.Create;
    DataSet := TClientDataSet.Create(Application);
    DataSet.Data := GetData(QueryAble);
    while not DataSet.Eof do
    begin
      TAutoMapper.DataToEntity(DataSet, QueryAble.Entity);
      List.Add(QueryAble.Entity);
      DataSet.Next;
    end;
    result := List;
  finally
    FreeAndNil(DataSet);
  end;
end;

function TDataContext.FindEntity(QueryAble: IQueryAble): TEntityBase;
var
  DataSet: TClientDataSet;
begin
  try
    FEntity := QueryAble.Entity;
    FSEntity := TAutoMapper.GetTableAttribute(FEntity.ClassType);

    DataSet := TClientDataSet.Create(Application);
    DataSet.Data := GetData(QueryAble);
    TAutoMapper.DataToEntity(DataSet, QueryAble.Entity);
    result := QueryAble.Entity;
  finally
    FreeAndNil(DataSet);
  end;
end;

function TDataContext.FindEntity<T>(QueryAble: IQueryAble): T;
var
  DataSet: TClientDataSet;
begin
  try
    result := nil;
    DataSet := TClientDataSet.Create(Application);
    DataSet.Data := GetData(QueryAble);
    TAutoMapper.DataToEntity(DataSet, QueryAble.Entity);
    result := QueryAble.Entity as T;
  finally
    FreeAndNil(DataSet);
  end;
end;

function TDataContext.IsFireBird:boolean;
begin
  result:= (FConnection.Driver = 'Firebird') or (FConnection.Driver = 'FB');
end;

function TDataContext.CriarTabela(i: integer): boolean;
var
  Table: string;
  ListAtributes: TList;
  ListForeignKeys: TList;
  KeyList: TStringList;
  classe: TClass;
  index:integer;

begin
  classe := Classes[i];
  Table := TAutoMapper.GetTableAttribute(classe);
  if Pos(uppercase(Table), uppercase(TableList.Text)) = 0 then
  begin
    try
      ListAtributes := nil;
      ListAtributes := TAutoMapper.GetListAtributes(classe);
      KeyList := TStringList.Create(true);
      FConnection.ExecutarSQL(FConnection.CustomTypeDataBase.CreateTable(ListAtributes, Table, KeyList));

      ListForeignKeys:= TAutoMapper.GetListAtributesForeignKeys(classe);

      if FConnection.CustomTypeDataBase is TFirebird then
      begin
        with FConnection.CustomTypeDataBase as TFirebird do
        begin
          FConnection.ExecutarSQL( CreateGenarator(Table, trim(KeyList.Text)) );
          FConnection.ExecutarSQL( SetGenarator(Table, trim(KeyList.Text)) );
          FConnection.ExecutarSQL( CrateTriggerGenarator(Table,trim(KeyList.Text)) );
        end;
      end;

      for index := 0 to ListForeignKeys.Count -1  do
      begin
        FConnection.ExecutarSQL( FConnection.CustomTypeDataBase.CreateForeignKey( ListForeignKeys[index], Table ) );
      end;

      result := true;
    finally
      KeyList.Free;
    end;
  end;
end;

function TDataContext.UpdateDataBase(aClasses: array of TClass): boolean;
var
  i: integer;
  Created, Altered: boolean;
begin
  Created := false;
  Altered := false;
  if FConnection <> nil then
  begin
    TableList := TStringList.Create(true);
    FConnection.GetTableNames(TableList);
    SetLength(Classes, length(aClasses));
    for i := 0 to length(aClasses) - 1 do
    begin
      Classes[i] := aClasses[i];
    end;
    if length(aClasses) > 0 then
    begin
      Created := CreateTables;
      // Altered := AlterTables;
    end;
  end;
  result := Created;
end;

function TDataContext.CreateTables: boolean;
var
  i: integer;
  Created: boolean;
begin
  Created := false;
  result := false;
  for i := 0 to length(Classes) - 1 do
  begin
    Created := CriarTabela(i);
    if Created then
      result := Created;
  end;
end;

function TDataContext.AlterTables: boolean;
var
  i, K, j: integer;
  Table: string;
  List: TList;
  FieldList: TStringList;
  ColumnExist: boolean;
  Created: boolean;
begin
  try
    Created := false;
    FieldList := TStringList.Create(true);
    for i := 0 to length(Classes) - 1 do
    begin
      Table := TAutoMapper.GetTableAttribute(Classes[i]);
      if TableList.IndexOf(Table) <> -1 then
      begin
        FConnection.GetFieldNames(FieldList, Table);
        List := TAutoMapper.GetListAtributes(Classes[i]);
        for K := 0 to List.Count - 1 do
        begin
          if PParamAtributies(List.Items[K]).Tipo <> '' then
          begin
            ColumnExist := FieldList.IndexOf(PParamAtributies(List.Items[K])
                .Name) <> -1;
            if not ColumnExist then
            begin
              FConnection.ExecutarSQL(FConnection.CustomTypeDataBase.AlterTable
                  (Table, PParamAtributies(List.Items[K]).Name,
                  PParamAtributies(List.Items[K]).Tipo,
                  PParamAtributies(List.Items[K]).IsNull, ColumnExist));
              Created := true;
            end;
          end;
        end;
      end;
    end;
  finally
    result := Created;
    FieldList.Free;
  end;
end;

procedure TDataContext.AddDirect;
var
  SQLInsert: string;
begin
  SQLInsert := Format('Insert into %s ( %s ) ) values ( %s ) ',
                      [TAutoMapper.GetTableAttribute(FEntity.ClassType),
                      TAutoMapper.GetAttributies(FEntity),
                      TAutoMapper.GetValuesFields(FEntity)]);
  Connection.ExecutarSQL(SQLInsert);
end;

procedure TDataContext.Add;
var
  ListValues: TStringList;
  i: integer;
begin
  FEntity.Validation;
  if DbSet <> nil then
  begin
    try
      try
        if ListField = nil then
           ListField := TAutoMapper.GetFieldsList(FEntity);
        ListValues := TAutoMapper.GetValuesFieldsList(FEntity);
        DbSet.append;
        pParserDataSet(ListField, ListValues, DbSet);
        DbSet.Post;
      except
        on E: Exception do
        begin
          raise Exception.Create(E.message);
        end;
      end;
    finally
      //ListField.Free;
      ListValues.Free;
    end;
  end
  else
    AddDirect;
end;

procedure TDataContext.Update;
var
   ListValues: TStringList;
  i: integer;
begin
  FEntity.Validation;
  if DbSet <> nil then
  begin
    try
      try
        if ListField = nil then
           ListField := TAutoMapper.GetFieldsList(FEntity);
        ListValues := TAutoMapper.GetValuesFieldsList(FEntity);
        DbSet.Edit;
        pParserDataSet(ListField, ListValues, DbSet);
        DbSet.Post;
      except
        on E: Exception do
        begin
          raise Exception.Create(E.message);
        end;
      end;
    finally
      //ListField.Free;
      //ListField := nil;
      ListValues.Free;
      ListValues := nil;
    end;
  end
  else
    UpdateDirect;
end;

procedure TDataContext.UpdateDirect;
var
  SQL: string;
  ListPrimaryKey, FieldsPrimaryKey: TStringList;
begin
  try
    try
      ListPrimaryKey := TAutoMapper.GetFieldsPrimaryKeyList(FEntity);
      FieldsPrimaryKey := TAutoMapper.GetValuesFieldsPrimaryKeyList(FEntity);

      SQL := Format( 'Update %s Set %s where %s',[TAutoMapper.GetTableAttribute(FEntity.ClassType),
                                                  fParserUpdate(TAutoMapper.GetFieldsList(FEntity),
                                                                TAutoMapper.GetValuesFieldsList(FEntity)),
                                                  fParserWhere(ListPrimaryKey, FieldsPrimaryKey) ] );
      Connection.ExecutarSQL(SQL);
    except
      on E: Exception do
      begin
        raise Exception.Create(E.message);
      end;
    end;
  finally
    ListPrimaryKey.Free;
    FieldsPrimaryKey.Free;
  end;
end;

procedure TDataContext.RemoveDirect;
var
  SQL: string;
  ListPrimaryKey, FieldsPrimaryKey: TStringList;
begin
  try
    try
      ListPrimaryKey := TAutoMapper.GetFieldsPrimaryKeyList(FEntity);
      FieldsPrimaryKey := TAutoMapper.GetValuesFieldsPrimaryKeyList(FEntity);
      SQL := Format( 'Delete From %s where %s',[TAutoMapper.GetTableAttribute(FEntity.ClassType),
                                                fParserWhere(ListPrimaryKey, FieldsPrimaryKey) ] );
      Connection.ExecutarSQL(SQL);
    except
      on E: Exception do
      begin
        raise Exception.Create(E.message);
      end;
    end;
  finally
    ListPrimaryKey.Free;
    FieldsPrimaryKey.Free;
  end;
end;

procedure TDataContext.InputEntity(Contener: TComponent);
begin
  // refatorar
  if Contener is TForm then
    TAutoMapper.Puts(Contener, FEntity)
  else
    TAutoMapper.PutsFromControl(Contener as TCustomControl, FEntity);
end;

procedure TDataContext.ReadEntity(Contener: TComponent;
    DataSet: TDataSet = nil);
begin
  // Refatorar
  if DataSet <> nil then
    TAutoMapper.Read(Contener, FEntity, false, DataSet)
  else if not DbSet.IsEmpty then
    TAutoMapper.Read(Contener, FEntity, false, DbSet)
  else
    TAutoMapper.Read(Contener, FEntity, false);
end;

procedure TDataContext.InitEntity(Contener: TComponent);
begin
  // FEntity:= TEntityBase.create;
  FEntity.Id := 0;
  TAutoMapper.Read(Contener, FEntity, true);
end;

procedure TDataContext.ReconcileError(DataSet: TCustomClientDataSet;
    E: EReconcileError; UpdateKind: TUpdateKind; var Action: TReconcileAction);
begin
  showmessage(E.message);
end;

function TDataContext.GetFieldList: Data.DB.TFieldList;
begin
  result := DbSet.FieldList;
end;

function TDataContext.GetJson(QueryAble: IQueryAble): string;
  var
  Keys: TStringList;
begin
  try
    Keys     := TAutoMapper.GetFieldsPrimaryKeyList(QueryAble.Entity);
    FSEntity := TAutoMapper.GetTableAttribute(FEntity.ClassType);
    FFDQuery := Connection.CreateDataSet(GetQuery(QueryAble), Keys);
    if not FFDQuery.Active then
       FFDQuery.Open;
    result:= FFDQuery.ToJson();
  finally
    FFDQuery.Free;
    //Keys.Free;
  end;
end;

destructor TDataContext.Destroy;
begin
  if drpProvider <> nil then
    drpProvider.Free;
  if FFDQuery <> nil then
    FFDQuery.Free;
  if DbSet <> nil then
    DbSet.Free;
  if oFrom <> nil then
    oFrom.Free;
  if FEntity <> nil then
    FEntity.Free;
  if TableList <> nil then
    TableList.Free;
  if ListField <> nil then
    ListField.Free;
  // if FConnection <> nil then    FConnection.Free;
end;

procedure TDataContext.DataSetProviderGetTableName(Sender: TObject;
    DataSet: TDataSet; var TableName: string);
begin
  TableName := uppercase(FSEntity);
end;

procedure TDataContext.Remove;
begin
  if (DbSet.Active) and (not DbSet.IsEmpty) then
    DbSet.Delete;
end;

procedure TDataContext.SaveChanges;
begin
  if ChangeCount > 0 then
    DbSet.ApplyUpdates(0);
end;

procedure TDataContext.RefreshDataSet;
begin
  if (DbSet.Active) then
    DbSet.Refresh;
end;

function TDataContext.ChangeCount: integer;
begin
  result := FDbSet.ChangeCount;
end;

procedure TDataContext.CreateProvider(var proSQLQuery: TFDQuery;
    prsNomeProvider: string);
begin
  drpProvider := TDataSetProvider.Create(Application);
  drpProvider.Name := prsNomeProvider + formatdatetime('SS', now);
  drpProvider.DataSet := proSQLQuery;
  drpProvider.UpdateMode := upWhereKeyOnly;
  // drpProvider.UpdateMode     := upWhereAll;
  drpProvider.Options := [poAutoRefresh, poUseQuoteChar];
  drpProvider.OnGetTableName := DataSetProviderGetTableName;
  // drpProvider.ResolveToDataSet:= true;
end;

constructor TDataContext.Create(proEntity: TEntityBase = nil);
begin
  FEntity := proEntity;
end;

procedure TDataContext.CreateClientDataSet(proDataSetProvider: TDataSetProvider;
    SQL: string = '');
begin
  if proDataSetProvider <> nil then
  begin
    DbSet := TClientDataSet.Create(Application);
    DbSet.OnReconcileError := ReconcileError;
    DbSet.ProviderName := proDataSetProvider.Name;
  end
  else if FProviderName <> '' then
  begin
    DbSet.ProviderName := FProviderName + formatdatetime('SS', now);
    DbSet.DataRequest(SQL);
  end
  else
  begin
    showmessage('DataSetProvider n�o foi definido!');
    abort;
  end;
  DbSet.open;
end;


function TDataContext.FirstOrDefault(Condicion: TString ): TEntityBase;
var
  I:Integer;
  max:integer;
  FirstEntidy, PriorEntity, CurrentEntidy: TEntityBase;
  TableForeignKey: string;
begin
  max:= ListObjectsInclude.Count-1;
  for I := 0 to max do
  begin
    CurrentEntidy:= TEntityBase(ListObjectsInclude.Items[i]);
    if i = 0 then
    begin
       FirstEntidy:= TEntityBase(ListObjectsInclude.Items[0]);
       TableForeignKey := Copy(FirstEntidy.ClassName,2,length(FirstEntidy.ClassName) );
       FirstEntidy := FindEntity( From(TEntityBase(FirstEntidy)).Where( Condicion ).Select );
    end
    else
    begin
       ListObjectsInclude.Items[i] := FindEntity( From(CurrentEntidy).
                                                 Where(TableForeignKey+'Id='+ FirstEntidy.Id.Value.ToString ).
                                                 Select );
    end;
  end;
  result:= FirstEntidy;
  ListObjectsInclude.clear;

end;

function TDataContext.Where(Condicion: TString): TDataContext;
var
  I:Integer;
  max:integer;
  FirstEntidy, PriorEntity, CurrentEntidy: TEntityBase;
  TableForeignKey: string;
begin
  {
  max:= ListObjectsInclude.Count-1;
  for I := 0 to max do
  begin
    CurrentEntidy:= TEntityBase(ListObjectsInclude.Items[i]);
    if i = 0 then
    begin
       FirstEntidy:= ListObjectsInclude.Items[0] as TEntityBase;
       FirstEntidy := GetEntity( From(TEntityBase(FirstEntidy)).Where( Condicion ).Select );
    end
    else
    begin
       TableForeignKey := Copy(FirstEntidy.ClassName,2,length(FirstEntidy.ClassName) );
       ListObjectsInclude.Items[i] := GetEntity( From(CurrentEntidy).
                                                 Where(TableForeignKey+'Id='+ FirstEntidy.Id.Value.ToString ).
                                                 Select );
    end;
  end;
  result:= nil;
  }

end;

function TDataContext.Include( E: TObject ):TDataContext;
begin
   if ListObjectsInclude = nil then
      ListObjectsInclude:= TList.Create;
   ListObjectsInclude.Add( E );
 { if ListClassInclude = nil then
      ListClassInclude:= TClassList.Create;
   ListClassInclude.Add( E.ClassType );}
   result:= self;
end;

{ TLinq }

function From(E: TEntityBase): TFrom;
begin
  result := TFrom(Linq.From(E));
end;

function From(E: array of TEntityBase): TFrom;
begin
  result := TFrom(Linq.From(E));
end;

function From(E: String): TFrom;
begin
  result := TFrom(Linq.From(E));
end;

function From(E: TClass): TFrom;
begin
  result := TFrom(Linq.From(E));
end;

function From(E: IQueryAble): TFrom;
begin
  result := TFrom(Linq.From(E));
end;



end.
