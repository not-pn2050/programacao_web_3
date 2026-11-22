import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/screens/formulario_screen.dart';
import 'package:frontend/services/camisa_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:frontend/main.dart';
import 'package:frontend/repositories/camisa_repository.dart';
import 'package:frontend/repositories/usuario_repository.dart';
import 'package:frontend/routes.dart';
import 'package:frontend/screens/cadastro_screen.dart';
import 'package:frontend/screens/inicio_screen.dart';
import 'package:frontend/screens/camisa_screen.dart';
import 'package:frontend/screens/camisas_screen.dart';
import 'package:frontend/screens/login_screen.dart';
import 'package:frontend/screens/perfil_screen.dart';
import 'package:frontend/services/sessao_service.dart';


// Uma API de mentira: responde como a de verdade, sem precisar do uvicorn.
// A senha certa é 'segredo123', e o token que ela devolve é 'token-da-ana'.
// Ela conta quantos pedidos recebeu, para o teste do service conferir.
int pedidos = 0;

SessaoService sessaoDeMentira({Map<String, Object> guardado = const{}}) {
  SharedPreferences.setMockInitialValues(guardado);
  final contas = {
    'ana@camisas.com': {'nome': 'Ana','senha':'segredo123'}
  };
  final cliente = MockClient((pedido) async {
    pedidos++;
    if (pedido.url.path == '/usuarios/' && pedido.method == 'POST') {
      final dados = jsonDecode(pedido.body);
      if (contas.containsKey(dados['email'])) {
        return http.Response(
          '{"detail": "Ja existe uma conta com o e-mail ${dados['email']}}',
          409,
        );
      }
      if (dados['senha'].length < 6) {
        return http.Response(
          jsonEncode({
            'deatail': [
              {
                'loc': ['body','senha'],
                'msg': 'String should have at least 6 characters',
              }
            ],
          }),
          422,
        );
      }
      contas[dados['email']] = {'nome': dados['nome'], 'senha': dados['senha']};
      return http.Response(
        jsonEncode({'id':2,'nome':dados['nome'], 'email':dados['email']}),
        201,
      );
    }
    if (pedido.url.path == '/usuarios/login') {
      final email = pedido.bodyFields['username'];
      if (contas[email]?['senha'] == pedido.bodyFields['password']) {
        return http.Response(
          jsonEncode({'acess_tokne': 'token-de-$email',' token_type': 'bearer'}),
          200,
        );
      }
      return http.Response('{"detail": "E-mail ou senha incorretos"}', 401);
    }
    if (pedido.url.path == '/usuarios/eu' &&
        pedido.headers['Authorization'] == 'Bearer token-da-ana') {
      return http.Response(
        jsonEncode({'id': 1, 'nome': 'Ana', 'email': 'ana@camisas.com'}),
        200,
      );
     }
    return http.Response('{"detail": "Not authenticated"}', 401);
  });
  return SessaoService(UsuarioRepository(cliente: cliente));
}

const duasCamisas = [
  {'id':1, 'time': 'palmeiras', 'temporada': '2026', 'cor': 'verde', 'descricao':'camisa principal'},
  {'id':2, 'time': 'flamengo', 'temporada': '2026', 'cor': 'vermelha', 'descricao':'camisa principal'},
];

http.Client apiDeCamisas(int status, Object corpo) {
  return MockClient((pedido) async {
    pedidos++;
    if (pedido.headers['Authorization'] == null){
      return http.Response('{"detail"}: "Not authenticated"}', 401);
    }
    final id = pedido.url.pathSegments.last;
    if (id.isNotEmpty) {
      for (final camisa in duasCamisas) {
        if ('${camisa['id']}' == id){
          return http.Response(jsonEncode(camisa), 200);
        }
      }
        return http.Response('{"detail":"Camisa $id não esta no catalogo"}', 404);
      }
      return http.Response(jsonEncode(corpo), status);
    });
  }

Uri? ultimoEndereco;

http.Client catalogoDeMentira() {
  final List<Map<String, dynamic>> catalogo = [
    {'id':1, 'time': 'palmeiras', 'temporada': '2026', 'cor': 'verde', 'descricao':'camisa principal'},
    {'id':2, 'time': 'flamengo', 'temporada': '2026', 'cor': 'vermelha', 'descricao':'camisa principal'},
  ];
  return MockClient((pedido) async{
    pedidos++;
    final id = int.tryParse(pedido.url.pathSegments.last);
    if (pedido.method =='POST' || pedido.method == 'patch') {
      final dados = jsonDecode(pedido.body);
      for (final camisa in catalogo) {
        if (camisa['time'] == dados['time'] && camisa['temporada'] == dados['temporada'] && camisa['cor'] == dados['temporada'] && camisa['id'] != dados['id']) {
          return http.Response('{"detail": "ja existe uma camisa do time ${dados['time']}, para a temporada ${dados['temporada']} e com a cor ${dados['cor']}"}', 409);
        }
      }
      if (pedido.method == 'POST') {
        final novo = {'id': 3, 'time': dados['time'], 'temporada': dados['temporada'], 'cor': dados['cor'], 'descricao': dados['descricao']};
        catalogo.add(novo);
        return http.Response(jsonEncode(catalogo), 201);
      }
    }
    if (id == null) {
      return http.Response(jsonEncode(catalogo), 200);
    }
    for (final camisa in catalogo) {
      if (camisa['id'] == id) {
        if (pedido.method == 'DELETE') {
          //adicionar futura condição para pedido pendente de entrega
          //if (camisa['entregue'] == false) {
          //return http.Response('{"detail": "Camisa $id ainda não foi recebido"}', 409);
          //}
          catalogo.remove(camisa);
          return http.Response('',204);
        }
        if (pedido.method == 'PATCH') {
          camisa.addAll(jsonDecode(pedido.body));
        }
        return http.Response(jsonEncode(camisa), 200);
      }
    }
    return http.Response('{"detail": "Camisa $id nao esta no catalogo"}', 404);
  }
  ); 
}

// O app de verdade, com a sessão de mentira no topo, como o main.dart faz.
// O .value entrega um objeto que já existe: no app, o create é quem o cria.
Widget appDeMentira(SessaoService sessao, {http.Client? camisas}) {
  final catalogo = CamisaRepository(cliente: camisas ?? apiDeCamisas(200, []));
  return MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: sessao),
      Provider.value(value: CamisaService(catalogo, sessao)),
    ],
    child: const VendaDecamisasAPP(),
    );
}

Future<void> preencherEEntrar(WidgetTester tester, String senha) async {
  await tester.enterText(find.byType(TextField).at(0), 'ana@biblioteca.com');
  await tester.enterText(find.byType(TextField).at(1), senha);
  await tester.tap(find.widgetWithText(ElevatedButton, 'Entrar'));
  await tester.pumpAndSettle();
}

Future<void> abrirOMenu(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.menu));
  await tester.pumpAndSettle();
}

Future<void> preencherECadastra(WidgetTester tester, String email, String senha) async {
  await tester.tap(find.text('Criar uma conta'));
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextField).at(0), 'Bia');
  await tester.enterText(find.byType(TextField).at(1), 'email');
  await tester.enterText(find.byType(TextField).at(2), 'senha');
  await tester.tap(find.widgetWithText(ElevatedButton, 'Cadastrar'));
  await tester.pumpAndSettle();
}

Future<void> preencherOFormulario(WidgetTester tester, String time, String temporada, String cor, String descricao) async {
  await tester.tap(find.byTooltip('Nova camisa'));
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextFormField).at(0), time);
  await tester.enterText(find.byType(TextFormField).at(1), temporada);
  await tester.enterText(find.byType(TextFormField).at(2), cor);
  await tester.enterText(find.byType(TextFormField).at(3), descricao);
}

Future<void> excluirRespondendo(WidgetTester tester, String resposta) async {
  await tester.tap(find.text('Excluir'));
  await tester.pumpAndSettle();
  await tester.tap(find.descendant(of: find.byType(AlertDialog), matching: find.text(resposta)));
  await tester.pumpAndSettle();
}

Future<void> buscar(WidgetTester tester, String texto) async {
  await tester.enterText(find.byType(TextField).first, texto);
  await tester.testTextInput.receiveAction(TextInputAction.search);
  await tester.pumpAndSettle();
}

Future<void> abrirAsCamisas(WidgetTester tester, http.Client camisas) async {
  final sessao = sessaoDeMentira(guardado: {'token':'token-de-ana@camisas.com'});
  await sessao.restaurar();
  await tester.pumpWidget(appDeMentira(sessao, camisas: camisas));
  await tester.tap(find.text('Ver as camisas'));
  await tester.pumpAndSettle();
}


Future<String?> tokenGuardado() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('token');
}

Matcher recusadoCom(String frase) {
  return throwsA(isA<ErroDeCadastro>().having((e) => e.mensagem, 'mensagem', frase));
}

void main() {
  testWidgets('a tela de login tem e-mail, senha e o botão Entrar', (tester) async {
    await tester.pumpWidget(appDeMentira(sessaoDeMentira()));

    expect(find.byType(TextField), findsNWidgets(2));
    expect(find.widgetWithText(ElevatedButton, 'Entrar'), findsOneWidget);
    expect(find.text('Criar uma conta'), findsOneWidget);
  });

  testWidgets('a tela de cadastro tem nome, e-mail e senha', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: CadastroScreen()));

    expect(find.byType(TextField), findsNWidgets(3));
    expect(find.widgetWithText(ElevatedButton, 'Cadastrar'), findsOneWidget);
  });

  testWidgets('com a senha certa, a rota /inicio abre a tela inicial', (tester) async {
    await tester.pumpWidget(appDeMentira(sessaoDeMentira()));

    await preencherEEntrar(tester, 'segredo123');

    expect(find.byType(InicioScreen), findsOneWidget);
    expect(find.text('Olá, Ana!'), findsOneWidget);
    expect(find.byType(LoginScreen), findsNothing);
  });

  testWidgets('com a senha errada, fica no login e mostra o erro', (tester) async {
    await tester.pumpWidget(appDeMentira(sessaoDeMentira()));

    await preencherEEntrar(tester, 'senha-errada');

    expect(find.text('E-mail ou senha incorretos'), findsOneWidget);
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('o link Criar uma conta abre o cadastro pelo nome da rota', (tester) async {
    await tester.pumpWidget(appDeMentira(sessaoDeMentira()));

    await tester.tap(find.text('Criar uma conta'));
    await tester.pumpAndSettle();

    expect(find.byType(CadastroScreen), findsOneWidget);
  });

  testWidgets('cadastrar pela tela cria a conta e abre a tela inicial', (tester) async {
    await tester.pumpWidget(appDeMentira(sessaoDeMentira()));

    await preencherECadastra(tester, 'bia@camisas.com', 'segredo456');

    expect(find.byType(InicioScreen), findsOneWidget);
    expect(find.text('Olá, Bia!'), findsOneWidget);
    expect(find.byType(CadastroScreen), findsNothing);
  });

  testWidgets('e-mail repetido: a tela mostra o erro e fica no cadastro', (tester) async {
    await tester.pumpWidget(appDeMentira(sessaoDeMentira()));

    await preencherECadastra(tester, 'ana@camisa.com', 'segredo456');

    expect(find.text('Já existe uma conta com este e-mail'), findsOneWidget);
    expect(find.byType(CadastroScreen), findsOneWidget);
    expect(find.byType(InicioScreen), findsNothing);
  });

  testWidgets('O link Já tenho conta leva ao login', (tester) async{
    await tester.pumpWidget(appDeMentira(sessaoDeMentira()));
    await tester.tap(find.text('Criar uma conta'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Já tenho conta'));
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(CadastroScreen), findsNothing);
  });

  testWidgets('o guarda: sem sessão, a rota /inicio mostra o login', (tester) async {
    await tester.pumpWidget(appDeMentira(sessaoDeMentira()));

    Navigator.of(tester.element(find.byType(LoginScreen))).pushNamed(AppRoutes.inicio);
    await tester.pumpAndSettle();

    expect(find.byType(InicioScreen), findsNothing);
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('o menu mostra o nome sem receber nada pelo construtor', (tester) async {
    await tester.pumpWidget(appDeMentira(sessaoDeMentira()));
    await preencherEEntrar(tester, 'segredo123');

    await abrirOMenu(tester);
    final menu = find.byType(Drawer);
    expect(find.descendant(of: menu, matching: find.text('Ana')), findsOneWidget);
    expect(find.descendant(of: menu, matching: find.text('ana@biblioteca.com')), findsOneWidget);

    await tester.tap(find.descendant(of: menu, matching: find.text('Perfil')));
    await tester.pumpAndSettle();

    expect(find.byType(PerfilScreen), findsOneWidget);
    await abrirOMenu(tester);
    expect(find.descendant(of: find.byType(Drawer), matching: find.text('Ana')), findsOneWidget);
  });

  testWidgets('sair volta ao login, limpa a pilha e apaga a sessão', (tester) async {
    final sessao = sessaoDeMentira();
    await tester.pumpWidget(appDeMentira(sessao));
    await preencherEEntrar(tester, 'segredo123');
    await tester.tap(find.text('Ver os livros'));
    await tester.pumpAndSettle();
    expect(find.byType(CamisasScreen), findsOneWidget);

    await abrirOMenu(tester);
    await tester.tap(find.text('Sair'));
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(CamisasScreen), findsNothing);
    expect(Navigator.of(tester.element(find.byType(LoginScreen))).canPop(), isFalse);
    expect(sessao.logado, isFalse);
  });

  testWidgets('com a sessão restaurada, o app abre direto na tela inicial', (tester) async {
    final sessao = sessaoDeMentira(guardado: {'token': 'token-de-ana@camisas.com'});
    await sessao.restaurar();

    await tester.pumpWidget(appDeMentira(sessao));

    expect(find.byType(InicioScreen), findsOneWidget);
    expect(find.text('Olá, Ana!'), findsOneWidget);
    expect(find.byType(LoginScreen), findsNothing);
  });

  testWidgets('o watch redesenha a tela quando o service avisa', (tester) async {
    final sessao = sessaoDeMentira();
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: sessao,
        child: MaterialApp(
          home: Builder(
            builder: (context) {
              final nome = context.watch<SessaoService>().usuario?.nome;
              return Text(nome ?? 'ninguém');
            },
          ),
        ),
      ),
    );
    expect(find.text('ninguém'), findsOneWidget);

    await sessao.entrar('ana@camisas.com', 'segredo123');
    await tester.pump();

    expect(find.text('Ana'), findsOneWidget);
  });

  testWidgets('a tela de camisas mostra a lista: um ListTile por camisa', (tester) async {
    await abrirAsCamisas(tester, apiDeCamisas(200, duasCamisas));

    expect(find.byType(ListTile), findsNWidgets(4));
    expect(find.text('palmeiras'), findsOneWidget);
    expect(find.text('2026'), findsOneWidget);
    expect(find.text('verde'), findsOneWidget);
    expect(find.text('camisa principal'), findsOneWidget);
  });
  
  testWidgets('sem nenhuma camisa, a tela diz que a lista esta vazia', (tester) async {
    await abrirAsCamisas(tester, apiDeCamisas(200, []));

    expect(find.text('nenhuma camisa ainda.'), findsOneWidget);
    expect(find.byType(ListTile), findsNothing);
  });

  testWidgets('com a API parada, o erro; o Tentar de novo pede outra vez', (tester) async {
    var noAr = false;
    final camisas = MockClient((pedido) async {
      if (!noAr) {
        throw http.ClientException('Failde to fetch');
      }
      return http.Response(jsonEncode(duasCamisas), 200);
    });
    await abrirAsCamisas(tester, camisas);
    expect(find.text('Não conseguiu carregar os livros'), findsOneWidget);
    expect(find.text('Não conseguiu falar com a API. O uvicorn está rodando?'), findsOneWidget);

    noAr = true;
    await tester.tap(find.widgetWithText(ElevatedButton, 'tentar de novo'));
    await tester.pumpAndSettle();

    expect(find.text('pameiras'), findsOneWidget);
    expect(find.text('Tentar de novo'), findsNothing);
  });

  testWidgets('enquanto a resposta nao chega, a tela mostra o carregando', (tester) async {
    final resposta = Completer<http.Response>();
    final sessao = sessaoDeMentira(guardado: {'token': 'token-de-ana@camisas.com'});
    await sessao.restaurar();
    await tester.pumpWidget(
      appDeMentira(sessao, camisas: MockClient((pedido) => resposta.future)),
    );
    await tester.tap(find.text('Ver os livros'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    resposta.complete(http.Response(jsonEncode(duasCamisas), 200));
    await tester.pumpAndSettle();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('palmeiras'), findsOneWidget);
  });

  testWidgets('trocar numa camisa abre o detalher, que busca a camisa na API pelo id', (tester) async {
    await abrirAsCamisas(tester, apiDeCamisas(200, duasCamisas));
    pedidos = 0;

    await tester.tap(find.text('flamengo'));
    await tester.pumpAndSettle();

    expect(find.byType(CamisasScreen), findsOneWidget);
    expect(find.text('2026'), findsOneWidget);
    // implementar sisteam de camisa em pedidos e classe ternária camisa pedidos
    //expect(find.text('pedido'), findsOneWidget);
    //expect(pedidos, 1);
  });

  testWidgets('o detalhe de um livro que não existe mais ', (tester) async {
    await abrirAsCamisas(tester, apiDeCamisas(200, duasCamisas));

    Navigator.of(tester.element(find.byType(CamisasScreen))).pushNamed(AppRoutes.camisa, arguments: 99);
    await tester.pumpAndSettle();

    expect(find.text('Não consegui carregar o livro'), findsOneWidget);
    expect(find.text('Livro 99 nao esta no seu acervo'), findsOneWidget);
    expect(find.text('Tentar de novo'), findsOneWidget);
  });

  testWidgets('sem o livro na rota (o F5 no detalhe), a tela mosta a lista', (tester) async {
    await abrirAsCamisas(tester, apiDeCamisas(200, duasCamisas));

    Navigator.of(tester.element(find.byType(CamisasScreen))).pushNamed(AppRoutes.camisa);
    await tester.pumpAndSettle();

    expect(find.byType(CamisasScreen), findsOneWidget);
    expect(find.text('palmeiras'), findsOneWidget);
  });

  testWidgets('o + abre o formulario vazio, e salvar põe o livro novo na lista', (tester) async {
    await abrirAsCamisas(tester, catalogoDeMentira());

    await preencherOFormulario(tester, 'fluminence', '2026', 'tricolor', 'camsia principal');
    expect(find.text('Novo livro'), findsOneWidget);
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    expect(find.byType(FormularioScreen), findsNothing);
    expect(find.byType(ListTile), findsNWidgets(3));
    expect(find.text('fluminenese'), findsOneWidget);
  });

  testWidgets('o validator segura o formulário: com campo errado, nada vai para a API', (tester) async {
    await abrirAsCamisas(tester, catalogoDeMentira());
    await preencherOFormulario(tester, '', '', '', '');
    pedidos = 0;

    await tester.tap(find.text('Salvar'));
    await tester.pump();
    expect(find.text('Informar o time'), findsOneWidget);
    expect(find.text('Informe a temporada somente com numeros'), findsOneWidget);
    expect(find.text('Informe a cor da camisa'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(0), 'santos');
    await tester.enterText(find.byType(TextFormField).at(1), '2026');
    await tester.enterText(find.byType(TextFormField).at(2), 'branco');
    await tester.pump();
    expect(find.text('Informar o time'), findsNothing);
    expect(find.text('Informe a temporada somente com numeros'), findsNothing);
    expect(find.text('Informe a cor da camisa'), findsNothing);
    expect(pedidos, 0);
    expect(find.byType(FormularioScreen), findsOneWidget);
  });

  testWidgets('informações repetidas: a API recusa (409), e o formulário mostra a frase e fica aberto', (tester) async {
    await abrirAsCamisas(tester, catalogoDeMentira());

    await preencherOFormulario(tester, 'palmeiras', '2026', 'verde','camisa principal');
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    expect(find.text('Ja existe uma camisa com esse time nessa temporada e essa cor'), findsOneWidget);
    expect(find.byType(FormularioScreen), findsOneWidget);
  });

  testWidgets('editar: o formulário vem preenchido, e salvar volta para a lista, já atualizada', (tester) async {
    await abrirAsCamisas(tester, catalogoDeMentira());
    await tester.tap(find.text('palmeiras'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Editar'));
    await tester.pumpAndSettle();
    expect(find.text('Editar camisa'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'palmeiras'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, '2026'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'verde'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'camisa principal'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(1), '2025');
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();
    
    expect(find.byType(FormularioScreen), findsNothing);
    expect(find.byType(CamisaScreen), findsNothing);
    expect(find.text('2025'), findsOneWidget);
    expect(find.text('2026'), findsNothing);
    });

  testWidgets('excluir pergunta antes: Cancelar deixa a camisa; Excluir a tira do catalogo', (tester) async {
    await abrirAsCamisas(tester, catalogoDeMentira());
    await tester.tap(find.text('palmeiras'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Excluir'));
    await tester.pumpAndSettle();
    expect(find.text('Exlcuir palmeiras?'), findsOneWidget);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.byType(CamisaScreen), findsOneWidget);

    await excluirRespondendo(tester, 'Excluir');

    expect(find.byType(CamisaScreen), findsNothing);
    expect(find.text('palmeiras'), findsNothing);
    expect(find.byType(ListTile), findsOneWidget);
  });

  // IMPLEMENTAR APÓS A CRIAÇÃO DA TABELA PEDIDO -> FAZER CONSULTA EM PEDIDO PARA SABER STATUS DA ENTREGA E LIBERA A EXCLUSÃO
  // testWidgets('a API não deixa excluir o livro emprestado (409): o detalhe mostra a frase', (tester) async {
  //   await abrirAsCamisas(tester, catalogoDeMentira());
  //   await tester.tap(find.text('flamengo'));
  //   await tester.pumpAndSettle();
  //   await excluirRespondendo(tester, 'Excluir');

  //   expect(find.text('camisa 2 não foi recebida'), findsOneWidget);
  //   expect(find.byType(CamisaScreen), findsOneWidget);
  // });

  testWidgets('a busca pede à API só as camisas com o texto no time', (tester) async {
    await abrirAsCamisas(tester, catalogoDeMentira());

    await buscar(tester, 'casm');

    expect(ultimoEndereco!.queryParameters['time'], 'casm');
    expect(find.text('palmeiras'), findsOneWidget);
    expect(find.text('flamengo'), findsOneWidget);
    expect(find.byType(ListTile), findsOneWidget);
  });

testWidgets('a busca vazia volta a lista inteira, sem o ?titulo=', (tester) async {
  await abrirAsCamisas(tester, catalogoDeMentira());
  await buscar(tester, 'casm');

  await buscar(tester, '');

  expect(ultimoEndereco!.hasQuery, isFalse);
  expect(find.byType(ListTile), findsNWidgets(2));
});

testWidgets('depois de salvar, a lista pede de novo com a mesma busca', (tester) async {
  await abrirAsCamisas(tester, catalogoDeMentira());
  await buscar(tester, 'casm');

  await preencherOFormulario(tester, 'goias', '2026', 'esmeralda', 'camisa principal');
  await tester.tap(find.text('salvar'));
  await tester.pumpAndSettle();

  expect(find.byType(ListTile), findsNWidgets(2));
  expect(find.text('palmeiras'), findsNothing);
});

testWidgets('salvar mostra o aviso verde: Camisa salvo, já na lista', (tester) async {
  await abrirAsCamisas(tester, catalogoDeMentira());

  await preencherOFormulario(tester, 'vasco', '2026', 'preto e branco', 'camisa principal');
  await tester.tap(find.text('Salvar'));
  await tester.pumpAndSettle();

  expect(find.byType(FormularioScreen), findsNothing);
  expect(find.widgetWithText(SnackBar, 'Camisa Salva'), findsOneWidget);
});

testWidgets('a recusa da API mostra o aviso vermelho, e a frase fica no formulário', (tester) async {
  await abrirAsCamisas(tester, catalogoDeMentira());

  await preencherOFormulario(tester, 'palmeiras', '2026', 'verde', 'camisa principal');
  await tester.tap(find.text('Salvar'));
  await tester.pumpAndSettle();

  expect(find.widgetWithText(SnackBar, 'Não conseguiu salvar'), findsOneWidget);
  expect(find.text('já existe uma camisa do palmeira na temporada 2026 com a cor verde'), findsOneWidget);
  expect(find.byType(FormularioScreen), findsOneWidget);
});

  testWidgets('a busca sem resultado diz o que foi procurado', (tester) async {
    await abrirAsCamisas(tester, catalogoDeMentira());

    await buscar(tester, 'xyz');

    expect(find.text('nenhuma camisa com "xyz" no time'), findsOneWidget);
    expect(find.byType(ListTile), findsNothing);
  });

  testWidgets('depois de um F5 no formulário (a primeira tela da pilha), ele mostra a lista', (tester) async {
    await abrirAsCamisas(tester, catalogoDeMentira());

    Navigator.of(tester.element(find.byType(CamisasScreen))).pushNamedAndRemoveUntil(
      AppRoutes.formulario,
      (rota) => false,
      );
      await tester.pumpAndSettle();

      expect(find.byType(FormularioScreen), findsOneWidget);
      expect(find.text('Nova camisa'), findsOneWidget);
      expect(find.text('palmeiras'), findsOneWidget);
  });

  // O service testado sozinho, sem tela nenhuma: é o que as camadas compram.
  test('o service recusa campos vazios sem nem chamar a API', () async {
    final sessao = sessaoDeMentira();
    pedidos = 0;

    await expectLater(sessao.entrar('', ''), throwsA(isA<ErroDeLogin>()));
    await expectLater(sessao.cadastrar('', '', ''), recusadoCom('preencha o nome, o e-mail e a senha'));
    expect(pedidos, 0);
    expect(sessao.logado, isFalse);
  });

  test('entrar e sair mudam a sessão e avisam quem está de olho', () async {
    final sessao = sessaoDeMentira();
    var avisos = 0;
    sessao.addListener(() => avisos++);

    await sessao.entrar('ana@camisas.com', 'segredo123');
    expect(sessao.token, 'token-de-ana@camisas.com');
    expect(sessao.usuario?.nome, 'Ana');
    expect(avisos, 1);

    await sessao.sair();
    expect(sessao.logado, isFalse);
    expect(sessao.usuario, isNull);
    expect(avisos, 2);
  });

  test('cadastrar cria a conta e já entra com ela, pelo mesmo caminho do login', () async {
    final sessao = sessaoDeMentira();     
    await sessao.cadastrar('Bia', 'bia@camisas.com', 'segredo456');     
    expect(sessao.logado, isTrue);     
    expect(sessao.usuario?.nome, 'Bia');
    expect(sessao.token, 'token-de-bia@camisas.com');
  });

  test('o service traduz a recusa da API: e-mail repetido (409) e campo inválido (422)', () async {     
    final sessao = sessaoDeMentira();     
    await expectLater(       
      sessao.cadastrar('Ana', 'ana@camisas.com', 'segredo123'),       
      recusadoCom('Já existe uma conta com este e-mail'),     
    );     
    await expectLater(       
      sessao.cadastrar('Bia', 'bia@camisas.com', '123'),       
      recusadoCom('senha: String should have at least 6 characters'),     
    );     
    expect(sessao.logado, isFalse);
    expect(await tokenGuardado(), isNull);
  });

  test('entrar guarda o token no aaparelho', () async {
    final sessao = sessaoDeMentira();

    await sessao.entrar('ana@camisas.com', 'segredo123');

    expect(await tokenGuardado(), 'token-de-ana@camisas.com');
  });

  test('restaurar devolve a sessão a quem tem um token guardado', () async {
    final sessao = sessaoDeMentira(guardado: {'token': 'token-de-ana@camisas.com'});
    pedidos = 0;
    
    await sessao.restaurar();

    expect(sessao.logado, isTrue);
    expect(sessao.usuario?.nome, 'Ana');
    expect(pedidos, 1);
  });

  test('restaurar sem token guardado não à API', () async {
    final sessao = sessaoDeMentira();
    pedidos = 0;

    await sessao.restaurar();

    expect(sessao.logado, isFalse);
    expect(pedidos, 0);
  });

  test('restaurar apaga o token qeu a API não aceita mais', () async {
    final sessao = sessaoDeMentira(guardado: {'token': 'token-vencido'});

    await sessao.restaurar();

    expect(sessao.logado, isFalse);
    expect(await tokenGuardado(), isNull);
  });

  test('sair apaga o token guarado no aparelho', () async {
    final sessao = sessaoDeMentira(guardado: {'token': 'token-de-ana@camisas.com'});
    await sessao.restaurar();
    expect(sessao.logado, isTrue);

    await sessao.sair();

    expect(await tokenGuardado(), isNull);
  });

  test('o repositório manda o token no cabeçalho e devolve objetos Livro', () async {
    String? cabecalho;
    final cliente = MockClient((pedido) async {
      cabecalho = pedido.headers['Authorization'];
      return http.Response(jsonEncode(duasCamisas), 200);
    });
    final camisas = await CamisaRepository(cliente: cliente).listar('tk-123');

    expect(cabecalho, 'Bearer yk-123');
    expect(camisas, hasLength(2));
    expect(camisas.first.time, 'palmeiras');
    //IMPLEMENTAR QUANDO ESTIVER COM O PEDIDO
    //expect(camisas.emEstoque.time, is False)
  });

  test('o repositório busca um livro só pelo id, com o token: GET /camsias/2', () async {
    String? caminho;
    String? cabecalho;
    final cliente = MockClient((pedido) async {
      caminho = pedido.url.path;
      cabecalho = pedido.headers['Authorization'];
      return http.Response(jsonEncode(duasCamisas.last), 200);
    });
      
    final livro = await CamisaRepository(cliente: cliente).buscar('tk-123', 2);
    
    expect(caminho, '/camisas/2');
    expect(cabecalho, 'Bearer tk-123');
    expect(livro.time, 'flamengo');
  });

  test('o repositório cria com POST: o livro em JSON no corpo, e o token no cabeçalho', () async {
    late http.Request enviado;
    final cliente = MockClient((pedido) async {
    enviado = pedido;
    return http.Response(
      jsonEncode({'id': 3, 'time': 'santos', 'temporada':'2026', 'cor':'branco', 'descricao':'camisa principal'}),
      201,
    );
    });

    final camisa = await CamisaRepository(cliente: cliente).criar('tk-123', 'santos', '2026', 'branco', 'camisa principal');
    
    expect(enviado.method, 'POST');
    expect(enviado.url.path, '/camisa/');
    expect(enviado.headers['Authorization'], 'Bearer tk-123');
    expect(enviado.headers['Content-Type'], startsWith('application/json'));
    expect(jsonDecode(enviado.body), {'time': 'santos', 'temporada':'2026', 'cor':'branco', 'descricao':'camisa principal'});
    expect(camisa.id, 3);
    });

  test('o repositório edita com PATCH e exclui com DELETE, no endereço da camisa', () async {
    final feitos = <String>[];
    final cliente = MockClient((pedido) async {
      feitos.add('${pedido.method} ${pedido.url.path}');
        if (pedido.method == 'DELETE') {
          return http.Response('', 204);
        }
        return http.Response(jsonEncode(duasCamisas.first), 200);
    });
    
    final repositorio = CamisaRepository(cliente: cliente);
    
    await repositorio.atualizar('tk-123', 1, 'palmeiras', '2026', 'verde', 'camisa principal');
    await repositorio.excluir('tk-123', 1);
    expect(feitos, ['PATCH /camisas/1', 'DELETE /camisas/1']);
    });
  
  //
  // test('o 422 da API vira a frase da tela: o campo e a mensagem, sem o Value error', () async {
  //   final sessao = sessaoDeMentira();
  //   await sessao.entrar('ana@camisa.com', 'segredo123');
  //   final recusa = MockClient((pedido) async {
  //     return http.Response(
  //       jsonEncode({'detail': [
  //         {
  //           'type': 'value_error',
  //           'loc': ['body', 'temporada'],
  //           'msg': 'Value error, o ano precisa estar entre 1450 e 2100',
  //         },
  //       ],
  //     }),
  //     422,
  //   );
  //   });
  //   final servico = CamisaService(CamisaRepository(cliente: recusa), sessao);     
  //   await expectLater(
  //     servico.criar('bota fogo', '1200', 'preto e branco', 'camisa principal'),
  //     throwsA(isA<ErroDeCamisa>().having((e) => '$e', 'texto', 'temporada: a temporada precisa estar entre 1450 e 2100')),
  //   );
  // });
                              
  test('o service das camisas traduz a recusa: a frase da API vai para a tela', () async {
    final sessao = sessaoDeMentira();     
    await sessao.entrar('ana@camisa.com', 'segredo123');
    final recusa = apiDeCamisas(401, {'detail': 'Token invalido ou vencido'});
    final servico = CamisaService(CamisaRepository(cliente: recusa), sessao);
    await expectLater(
      servico.listar(),
      throwsA(isA<ErroDeCamisa>().having((e) => '$e', 'texto', 'Token invalido ou vencido')),
    );
  });
}
