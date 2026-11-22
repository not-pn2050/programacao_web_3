import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:frontend/models/camisa.dart';
import 'package:frontend/repositories/camisa_repository.dart';
import 'package:frontend/repositories/token_repository.dart';
import 'package:frontend/repositories/usuario_repository.dart';
import 'package:frontend/routes.dart';
import 'package:frontend/screens/cadastro_screen.dart';
import 'package:frontend/screens/formulario_screen.dart';
import 'package:frontend/screens/inicio_screen.dart';
import 'package:frontend/screens/camisa_screen.dart';
import 'package:frontend/screens/camisas_screen.dart';
import 'package:frontend/screens/login_screen.dart';
import 'package:frontend/screens/perfil_screen.dart';
import 'package:frontend/services/camisa_service.dart';
import 'package:frontend/services/sessao_service.dart';
import 'package:frontend/widgets/rota_protegida.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final sessao = SessaoService(UsuarioRepository(), tokens: TokenRepository());

  await sessao.restaurar();

  final camisas = CamisaService(CamisaRepository(), sessao);
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: sessao),
        Provider.value(value: camisas),
      ],
      child: const VendaDecamisasAPP()
    ),
  );
}

class VendaDecamisasAPP extends StatelessWidget {
  const VendaDecamisasAPP({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Venda de camisas',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.indigo),
      initialRoute: AppRoutes.inicio,
      routes: {
        AppRoutes.login:(context) => const LoginScreen(),
        AppRoutes.cadastro:(context) => const CadastroScreen(),
        AppRoutes.inicio: (context) => const RotaProtegida(tela: InicioScreen()),
        AppRoutes.camisas:(context) => const RotaProtegida(tela: CamisasScreen()),
        AppRoutes.camisa:(context) => RotaProtegida(
          tela: CamisaScreen(id: ModalRoute.of(context)!.settings.arguments as int?)),
        AppRoutes.formulario:(context) => RotaProtegida(
          tela: FormularioScreen(camisa: ModalRoute.of(context)!.settings.arguments as Camisa?)
          ),
        AppRoutes.perfil: (context) => const RotaProtegida(tela: PerfilScreen()),
      },
      );
  }
}
