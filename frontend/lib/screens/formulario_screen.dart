import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/camisa.dart';
import '../services/camisa_service.dart';
import '../widgets/aviso.dart';
import 'camisa_screen.dart';

class FormularioScreen extends StatefulWidget {
  const FormularioScreen({super.key, this.camisa});

  final Camisa? camisa;

  @override
  State<FormularioScreen> createState() => _FormularioScreenState();
}

class _FormularioScreenState extends State<FormularioScreen> {
  final chave = GlobalKey<FormState>();
  final time = TextEditingController();
  final temporada = TextEditingController();
  final cor = TextEditingController();
  final descricao = TextEditingController();
  bool salvando = false;
  String? erro;

  @override
  void initState() {
    super.initState();
    //a edição é feita em cima do conteudo da camisa
    if (widget.camisa != null) {
      time.text = widget.camisa!.time;
      temporada.text = widget.camisa!.temporada;
      cor.text = widget.camisa!.cor;
      descricao.text = widget.camisa!.descricao;
    }
  }

  Future<void> salvar() async {
    if (!chave.currentState!.validate()) {
      return;
    }
    setState(() {
      salvando = true;
      erro = null;
    });

    final servico = context.read<CamisaService>();
    try {
      if (widget.camisa == null) {
        await servico.criar(time.text, temporada.text, cor.text, descricao.text);
      } else {
        await servico.atualizar(widget.camisa!.id, time.text, temporada.text, cor.text, descricao.text);
      }
    } on ErroDeCamisa catch (e) {
      if (!mounted) return;
      setState(() {
        salvando = false;
        erro = '$e';
      });
      avisar(context, 'Não conseguiu salvar', erro: true);
      return;
    }
    if (!mounted) return;
    avisar(context, 'camisa não salva');
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context){
    if (ModalRoute.of(context)!.isFirst) {
      return const CamisaScreen();
    }
    final editando = widget.camisa != null;
    return Scaffold(
      appBar: AppBar(title: Text(editando ? 'Editar camisa' : 'Nova camisa')),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(24),
            child: Form(
              key: chave,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: time,
                    decoration: const InputDecoration(
                      labelText: 'time',
                      border: OutlineInputBorder(), 
                    ),
                    validator: (valor) {
                      if ((valor ?? '').trim().isEmpty) {
                        return 'Informe o titulo';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: temporada,
                    decoration: const InputDecoration(
                      labelText: 'Temporada',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (valor) {
                      if (int.tryParse(valor ?? '') == null) {
                        return 'Informe a temporada somente com numeros';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: cor,
                    decoration: const InputDecoration(
                      labelText: 'Cor',
                      border: OutlineInputBorder(),
                    ),
                    validator: (valor){
                      if ((valor ?? '').trim().isEmpty){
                        return 'Informe a cor da camisa';
                      }
                      return null;
                    }
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: cor,
                    decoration: const InputDecoration(
                      labelText: 'descricao',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  if (erro != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      erro!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ],
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: salvando ? null : salvar, 
                    child: Text(salvando ? 'Salvando...' : 'Salvar'),
                  ),
                ],
              ),
              ),
          ),
        )
      ),
    );
  }


}