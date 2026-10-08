import 'package:flutter/material.dart';


import 'package:frontend/repositories/usuario_repository.dart';
import 'package:frontend/routes.dart';
import 'package:frontend/screens/cadastro_screen.dart';
import 'package:frontend/screens/inicio_screen.dart';
import 'package:frontend/screens/login_screen.dart';
import 'package:frontend/services/sessao_service.dart';


void main() {
  final sessao = SessaoService(UsuarioRepository());
  runApp(VendaDecamisasAPP(sessao: sessao));
}

class VendaDecamisasAPP extends StatelessWidget {
  const VendaDecamisasAPP({super.key, required this.sessao});

  final SessaoService sessao;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Venda de camisas',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.indigo),
      initialRoute: AppRoutes.login,
      routes: {
        AppRoutes.login:(context) => LoginScreen(sessao: sessao),
        AppRoutes.cadastro:(context) => const CadastroScreen(),
        AppRoutes.inicio: (context) => InicioScreen(sessao: sessao),
      },
      );
  }
}
