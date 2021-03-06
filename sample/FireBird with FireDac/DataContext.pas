unit DataContext;

interface

uses EF.Engine.DbSet, EF.Engine.DbContext, EF.Mapping.Base, Domain.Entity.Cliente, Domain.Entity.Contato, EF.Drivers.Connection;

type
  TDataContextPessoal = class(TDbContext)
  public
    Clientes : TDbset<TCliente>;
    Contatos : TDbset<TContato>;
  //Funcionarios : TDbset<TFuncionarios>;
  //Fornecedores : TDbset<TFornecedores>;
    constructor Create( aDatabase: TDatabaseFacade );override;
    destructor Destroy;override;
  end;

implementation

{ BoundContext }

constructor TDataContextPessoal.Create( aDatabase: TDatabaseFacade );
begin
  inherited;
  Clientes := TDbset<TCliente>.create( aDatabase );
  Contatos := TDbset<TContato>.create( aDatabase );
end;

destructor TDataContextPessoal.Destroy;
begin
  inherited;
  Clientes.Free;
  Contatos.Free;
end;

end.
