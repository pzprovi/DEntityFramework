unit Unit1;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Data.DB,
  Vcl.StdCtrls, Vcl.Grids, Vcl.DBGrids, Datasnap.DBClient, Domain.Entity.Cliente,
  EF.Engine.DataContext, EF.QueryAble.base, Vcl.ExtCtrls;

type
  TForm1 = class(TForm)
    ClientDataSet1: TClientDataSet;
    DataSource1: TDataSource;
    Button1: TButton;
    panelButtons: TPanel;
    Panel2: TPanel;
    DBGrid1: TDBGrid;
    buttonLoadData: TButton;
    buttonGetDataSet: TButton;
    mLog: TMemo;
    buttonGetSQL: TButton;
    buttonGetEntity: TButton;
    Button2: TButton;
    Button3: TButton;
    Button4: TButton;
    Button5: TButton;
    Button6: TButton;
    Button7: TButton;
    Button8: TButton;
    Button9: TButton;
    procedure FormCreate(Sender: TObject);
    procedure buttonLoadDataClick(Sender: TObject);
    procedure buttonGetDataSetClick(Sender: TObject);
    procedure buttonGetSQLClick(Sender: TObject);
    procedure buttonGetEntityClick(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure Button4Click(Sender: TObject);
    procedure Button5Click(Sender: TObject);
    procedure Button6Click(Sender: TObject);
    procedure Button7Click(Sender: TObject);
    procedure Button9Click(Sender: TObject);
  private
    { Private declarations }
  public
    E: TCliente;
    Context: TDataContext<TCliente>;
    QueryAble: IQueryAble;
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

uses UDataModule, EF.Mapping.AutoMapper, Domain.Entity.Contato, EF.Core.Types;

procedure TForm1.FormCreate(Sender: TObject);
begin
  Context := TDataContext<TCliente>.Create;
  Context.Connection := DataModule1.FConnection;
  E:= Context.Entity;
end;

procedure TForm1.Button2Click(Sender: TObject);
begin
   QueryAble := From( E )
               .Select
               .Where( E.Id = DataSource1.DataSet.FieldByName('ID').AsInteger );

   E := Context.Find<TCliente>( QueryAble );

   mLog.Text:= E.ToJson;
end;

procedure TForm1.Button3Click(Sender: TObject);
begin
  Context.Entity.FromJson(mLog.Text);
end;

procedure TForm1.Button4Click(Sender: TObject);
var
   C:TCliente;
   contato: TContato;
begin
   C:= Context.Include(E.Veiculo).
               Include(E.Contatos).
               Where( E.ID = 3 //DataSource1.DataSet.FieldByName('ID').AsInteger
                     );

   mlog.Lines.Add('ID: ' + C.ID.Value.ToString );
   mlog.Lines.Add('Nome: ' + C.Nome.Value);
   mlog.Lines.Add('Veiculo: ' + C.Veiculo.Placa.Value);

   mlog.Lines.Add('Contatos :');
   for contato in C.Contatos do
   begin
      mlog.Lines.Add('    ' + contato.Nome.Value);
   end;

   FreeAndNIL(C);
end;

procedure TForm1.Button5Click(Sender: TObject);
var
  C:TCliente;
  contato:TContato;
begin
   C := Context.Include(E.Contatos).
                    Include(E.ClienteEmpresa).
                         ThenInclude(E.ClienteEmpresa.Empresa).
                             Where( E.ID =  3 //DataSource1.DataSet.FieldByName('ID').AsInteger
                              );

   mlog.Lines.Add('Empresa : ' + C.ClienteEmpresa.Empresa.Descricao.Value);
   mlog.Lines.Add('ID : ' + C.ID.Value.ToString );
   mlog.Lines.Add('Cliente : ' +C.Nome.Value);
   mlog.Lines.Add('Contatos :');
   for contato in C.Contatos do
   begin
      mlog.Lines.Add('    ' + contato.Nome.Value);
   end;

   FreeAndNIL(C);
end;

procedure TForm1.Button6Click(Sender: TObject);
var
  C: TCliente;
begin
  C:= TCliente.Create;

  C.Nome:= 'JOAO Cristo de nazare';
  C.NomeFantasia:= 'jesus Cristo de nazare';
  C.CPFCNPJ:= '02316937454';
  C.RG:= '1552666';
  C.Ativo:= '1';
  C.DataNascimento := strtodate('19/04/1976');
  C.Email.value := 'lindemberg.desenvolvimento@gmail.com';

  Context.Entity:= C;

  Context.Add;

  Context.SaveChanges;

  DataSource1.DataSet := Context.ToDataSet( From( Context.Entity ).Select.OrderBy(Context.Entity.Nome) );

end;

procedure TForm1.Button7Click(Sender: TObject);
begin
  TAutoMapper.DataToEntity( DataSource1.DataSet, Context.Entity );

  with Context.Entity as TCliente do
  begin
    Nome.Value:= 'Nome do Cliente '+datetimetostr(now);
  end;
  Context.Update;
  Context.SaveChanges;

  DataSource1.DataSet := Context.ToDataSet( From( E ).Select.OrderBy ( E.Nome ) );
end;

procedure TForm1.Button9Click(Sender: TObject);
var
  L:TEntityList<TCliente>;
  C:TCliente;
begin
   L := Context.ToList( E.Ativo = '1' );
   for C in L do
   begin
      mlog.Lines.Add('ID: ' + C.ID.Value.ToString +'       Nome: ' + C.Nome.Value);
   end;
end;

procedure TForm1.buttonGetDataSetClick(Sender: TObject);
begin
   QueryAble := From( E ).Select.OrderBy ( E.Nome );
   DataSource1.DataSet := Context.ToDataSet( QueryAble );
end;

procedure TForm1.buttonGetEntityClick(Sender: TObject);
begin
   QueryAble := From( E ).Select.Where( E.Id = DataSource1.DataSet.FieldByName('ID').AsInteger );
   E := Context.Find<TCliente>( QueryAble );
   mlog.Lines.Add('ID: ' + E.ID.Value.ToString+'      Nome: ' + E.Nome.Value);
end;

procedure TForm1.buttonGetSQLClick(Sender: TObject);
begin
   QueryAble := From   ( E )
                .Select([ E.Id, E.Nome, E.Observacao ])
                .OrderBy ( E.Nome );
   mlog.Lines.Text := Context.GetQuery( QueryAble );
end;

procedure TForm1.buttonLoadDataClick(Sender: TObject);
begin
   QueryAble := From( E )
                .Select
                .OrderBy ( E.Nome );
   DataSource1.DataSet := ClientDataSet1;
   ClientDataSet1.Data := Context.ToData( QueryAble );
end;

end.
