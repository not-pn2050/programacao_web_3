import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../routes.dart';
import '../services/sessao_service.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final usuario = context.watch<SessaoService>().usuario!;
    return Drawer(
      child: ListView(
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(usuario.nome), 
            accountEmail: Text(usuario.email),
            ),
          ListTile(
            leading: const Icon(Icons.menu),
            title: const Text('inicio'),
            onTap: () => Navigator.restorablePushReplacementNamed(context, AppRoutes.inicio)
          ),
          ListTile(
            leading: const Icon(Icons.menu_book),
            title: const Text('Camisas'),
            onTap: () => Navigator.restorablePushReplacementNamed(context, AppRoutes.camisas)
          ),
          ListTile(
            leading: const Icon(Icons.menu),
            title: const Text('Perfil'),
            onTap: () => Navigator.restorablePushReplacementNamed(context, AppRoutes.perfil),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Sair'),
            onTap: () async {
              await context.read<SessaoService>().sair();
              if (!context.mounted) return;
              Navigator.pushNamedAndRemoveUntil(
                context, 
                AppRoutes.login,
                (rota) => false
                );
            },
          )
        //termiando de construir o drawer

        ],
      ),
    );
  }

}