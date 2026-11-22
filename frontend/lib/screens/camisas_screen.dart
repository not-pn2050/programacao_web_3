import 'dart:nativewrappers/_internal/vm/lib/ffi_native_type_patch.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/camisa.dart';
import '../routes.dart';
import '../services/camisa_service.dart';
import '../widgets/app_drawer.dart';


class CamisasScreen extends StatefulWidget {
  const CamisasScreen({super.key});

  @override
  State<CamisasScreen> createState() => _CamisasScreenState();
  }

class _CamisasScreenState extends State<CamisasScreen> {

  late Future<List<Camisa>> camisas;

  String busca = '';

  @override 
  void initState() {
    super.initState();
    camisas = context.read<CamisaService>().listar();
  }

  void pedirDeNovo() {
    setState(() {
      camisas = context.read<CamisaService>().listar(busca: busca);
    });
  }

  void buscar(String texto) {
    busca = texto.trim();
    pedirDeNovo();
  }

  Widget listaDasCamisas() {
    return FutureBuilder<List<Camisa>>(
      future: camisas,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off, size: 56),
                const SizedBox(height: 16),
                const Text('não consegui carregar as camisas'),
                const SizedBox(height: 8),
                Text(
                  '${snapshot.error}',
                  style: const TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: pedirDeNovo,
                  child: const Text('Tentar de novo')),
              ],
            ),
          );
        }
        
        final lista = snapshot.data!;
        if (lista.isEmpty) {
          final frase = busca.isEmpty
          ? 'Nenhuma camisa aidna.'
          : 'Nenhuma camisa com "$busca" no time';
          return Center(child: Text(frase));
        }

        return ListView.builder(
          itemCount: lista.length,
          itemBuilder: (context, i) {
            final camisa = lista[i];
            return ListTile(
              leading: const Icon(Icons.menu_book),
              title: Text(camisa.time),
              subtitle: Text(camisa.temporada),
              onTap: () async {
                final mudou = await Navigator.pushNamed(context, AppRoutes.camisa, arguments: camisa.id);
                if (mudou == true) {
                  pedirDeNovo();
                }
              },
            );
          },
        );
      }
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Camisas')),
      drawer: const AppDrawer(),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Buscar pelo time',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),  
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: buscar,
            ),
          ),
          Expanded(child: listaDasCamisas()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Nova camisa',
        onPressed: () async {
          final salvou = await Navigator.pushNamed(context, AppRoutes.formulario);
          if (salvou == true) {
            pedirDeNovo();
          }
        },
        child: const Icon(Icons.add),
      ),
    );          
  }
}