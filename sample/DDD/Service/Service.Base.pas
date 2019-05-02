unit Service.Base;

interface

uses
System.Classes, DB, EF.Mapping.Base,
Service.Interfaces.Services.ServiceBase,
infra.Interfaces.Repositorios.Repositorybase, Context,
Winapi.Windows, System.JSON;

type
  {$M+}
  TServiceBase<T:TEntityBase> = class(TInterfacedPersistent, IServiceBase<T>)
  private
    FRefCount: Integer;
    procedure InitEntity(Contener: TComponent);
  protected
    Repository: IRepositoryBase<T>;
  public
    constructor Create( pRepository: IRepositoryBase<T>);virtual;

    procedure RefresData;virtual;
    function  Load(iId:Integer; Fields: string = ''): TDataSet;virtual;
    function  LoadEntity(iId: Integer = 0): T;virtual;
    procedure Delete;virtual;
    procedure Post( State: TEntityState);virtual;
    procedure Persist;virtual;
    function GetEntity: T;virtual;
    procedure Add(JSOnObject: TJSOnObject);overload; virtual;
    procedure Read(Contener: TComponent);virtual;
    function FieldList:TFieldList;virtual;

    function ChangeCount:Integer;virtual;

    function _AddRef: Integer; stdcall;
    function _Release: Integer; stdcall;
  end;
  {$M-}
implementation

uses  EF.Mapping.AutoMapper, Service.Utils.DataBind;

constructor TServiceBase<T>.Create(pRepository: IRepositoryBase<T>);
begin
  Inherited Create;
  Repository:= pRepository;
end;

procedure TServiceBase<T>.Post(State: TEntityState);
begin
   Repository.AddOrUpdate(State);
end;

procedure TServiceBase<T>.Persist;
begin
  Repository.Commit;
end;

procedure TServiceBase<T>.Delete;
begin
  Repository.Delete;
end;

function TServiceBase<T>.FieldList: TFieldList;
begin
  result:= Repository.dbContext.GetFieldList;
end;

function TServiceBase<T>.GetEntity: T;
begin
  //result:= Repository.GetEntity;
end;

procedure TServiceBase<T>.InitEntity(Contener: TComponent);
begin
  Repository.Entity.Id := 0;
  TDataBind.Read(Contener, Repository.Entity, true);
end;

procedure TServiceBase<T>.Read(Contener: TComponent);
begin
  TDataBind.Read(Contener, Repository.Entity, false, Repository.dbContext.DbSet);
end;

procedure TServiceBase<T>.Add(JSOnObject: TJSOnObject);
begin
  TAutoMapper.JsonObjectToObject<T>( JSOnObject, Repository.Entity );
end;

function TServiceBase<T>.ChangeCount: Integer;
begin
  result:= Repository.dbContext.ChangeCount;
end;

function TServiceBase<T>.Load(iId:Integer; Fields: string = ''): TDataSet;
begin
  result := Repository.LoadDataSet(iID , Fields );
end;

function TServiceBase<T>.LoadEntity(iId: Integer= 0): T;
begin
  result := Repository.Load(iId);
end;

procedure TServiceBase<T>.RefresData;
begin
  Repository.RefreshDataSet;
end;

function TServiceBase<T>._AddRef: Integer;
begin
  Result := inherited _AddRef;
  InterlockedIncrement(FRefCount);
end;

function TServiceBase<T>._Release: Integer;
begin
  Result := inherited _Release;
  InterlockedDecrement(FRefCount);
  if FRefCount <=0 then
    Free;
end;

end.
