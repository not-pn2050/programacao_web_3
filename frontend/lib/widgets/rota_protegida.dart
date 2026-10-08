import 'package:flutter/material.dart';

import '../screens/login_screen.dart';
import '../services/sessao_service.dart';

class RotaProtegida extends StatelessWidget {
  const RotaProtegida({super.key, required this.sessao, required  this.tela});

  final SessaoService sessao;
  final Widget tela;

  @override
  Widget build(BuildContext context) {
    return sessao.token != null ?tela : LoginScreen(sessao: sessao);
  }
}