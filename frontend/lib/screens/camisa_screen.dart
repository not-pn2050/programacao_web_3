import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/camisa.dart';
import '../routes.dart';
import '../services/camisa_service.dart';
import '../widgets/aviso.dart';
import 'camisas_screen.dart';

class CamisaScreen extends StatefulWidget {
  const  CamisaScreen({super.key, this.id});

  final int? id;

  @override
  State<CamisaScreen> createState() => _CamisaScreenState();

}

class _CamisaScreenState extends State<CamisaScreen> {
  late Future<Camisa> pedido;
  
  String? erro;

  @override
  void initState() {
    super.initState();
    if (widget.id != null){
      pedido = context.read<CamisaService>().buscar(widget.id!);
    }
  }

  void tentarDeNovo() {
    setState(() {
      pedido = context.read<CamisaService>().buscar(widget.id!);
    });
  }

  Future<void> editar(Camisa camisa) async {
    final salvou = await Navigator.pushNamed(context, AppRoutes.formulario, arguments: camisa);
    if (salvou == true && mounted) {
      Navigator.pop(context, true);
    }
  }

  Future<void> excluir(Camisa camisa) async {
    final certeza = await showDialog<bool>(
      context: context,
       builder: (context) => AlertDialog(
        title: Text('Excluir a camisa do ${camisa.time}? da temporada ${camisa.temporada} da cor ${camisa.cor}'),
        content: const Text('Tem certeza? a camisa sairá do catalogo'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context,false),
            child: const Text('cancelar'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir'),
            ),
        ],
       ),
    );
    if (certeza != true || !mounted) {
      return;
    }
    try {
      await context.read<CamisaService>().excluir(camisa.id);
    } on ErroDeCamisa catch (e) {
      if (!mounted) return;
      setState(() {
        erro = '$e';
      });
      avisar(context, 'Não conseguiu salvar', erro: true);
      return;
    }
    if (!mounted) return;
    avisar(context, 'camisa excluída');
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.id == null) {
      return const CamisaScreen();
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Camisa')),
      body: FutureBuilder<Camisa>(
        future: pedido, 
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
                  const Text('Não consegui carregar a camisa'),
                  const SizedBox(height: 8),
                  Text(
                    '${snapshot.error}',
                    style: const TextStyle(color: Colors.red),
                    ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: tentarDeNovo, 
                    child: const Text('Tentar de novo'),
                    ),
                ],
              ),
              );
          }
          final camisa = snapshot.data!;
          return ListView(
            children: [
              ListTile(
                leading: const Icon(Icons.menu_book),
                title: const Text('Time'),
                subtitle: Text(camisa.time),
              ),
              ListTile(
                leading: const Icon(Icons.calendar_month),
                title: const Text('Temporada'),
                subtitle: Text(camisa.temporada),
              ),
              ListTile(
                leading: const Icon(Icons.palette),
                title: const Text('Cor'),
                subtitle: Text(camisa.cor),
              ),
              ListTile(
                leading: const Icon(Icons.list_alt),
                title: const Text('descrição'),
                subtitle: Text(camisa.descricao),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => editar(camisa),
                    icon: const Icon(Icons.edit),
                    label: const Text('Editar'),
                    ),
                  const SizedBox(width: 16),
                  OutlinedButton.icon(
                    onPressed: () => excluir(camisa),
                    icon: const Icon(Icons.delete),
                    label: const Text('Excluir'),
                  ),
                ],
              ),
              if (erro != null) ...[
                const SizedBox(height: 16),
                Text(
                  erro!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
