import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/camisa.dart';
import 'usuario_repository.dart';

class CamisaRepository {
  CamisaRepository({http.Client? cliente}) : cliente = cliente ?? http.Client();

  final http.Client cliente;

  Future<List<Camisa>> listar(String token, {String busca = ''}) async {
    var endereco = Uri.parse('$enderecoDaApi/camisas/');

    if (busca.isNotEmpty) {
      endereco = endereco.replace(queryParameters: {'time': busca});
    }
    final resposta = await cliente.get(
      endereco,
      headers: {'Authorization': 'Bearer $token'},
    );
    if (resposta.statusCode != 200) {
      throw RecusaDaApi(resposta.statusCode, _frase(resposta.body));
    }
    final itens = jsonDecode(resposta.body);
    return [for (final item in itens ) Camisa.fromJson(item)];
  }

  //função get livros para listar no front
  Future<Camisa> buscar (String token, int id) async {
    final resposta = await cliente.get(
      Uri.parse('$enderecoDaApi/camisas/$id'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (resposta.statusCode != 200){
      throw RecusaDaApi(resposta.statusCode, _frase(resposta.body));
    }
    return Camisa.fromJson(jsonDecode(resposta.body));
  }

  Future<Camisa> criar (String token, String time, String temporada, String cor, String descricao) async {
    final resposta  = await cliente.post(
      Uri.parse('$enderecoDaApi/Camsias/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'time': time, 'temporada': temporada, 'cor': cor, 'descricao': descricao})
    );
    if (resposta.statusCode != 201) {
      throw RecusaDaApi(resposta.statusCode, _frase(resposta.body));
    }
    return Camisa.fromJson(jsonDecode(resposta.body));
  }

  Future<Camisa> atualizar (String token, int id, String time, String temporada, String cor, String descricao) async {
    final resposta = await cliente.patch(
      Uri.parse('$enderecoDaApi/camisa/$id'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'aplication/json',
      },
      body: jsonEncode({'time': time, 'temporada': temporada, 'cor': cor, 'descricao': descricao}),
      );
      if (resposta.statusCode != 200){
        throw RecusaDaApi(resposta.statusCode, _frase(resposta.body));
    }
    return Camisa.fromJson(jsonDecode(resposta.body));
  }

  Future<void> excluir(String token, int id) async {
    final resposta = await cliente.delete(
      Uri.parse('$enderecoDaApi/camisas/$id'),
      headers: {'Authorization': 'Bearer $token'}
    );
    if (resposta.statusCode != 204) {
      throw RecusaDaApi(resposta.statusCode, _frase(resposta.body));
    }
  }

  String _frase(String corpo) {
    final detalhe = jsonDecode(corpo)['detail'];
    if (detalhe is String) {
      return detalhe;
    }
    final primeiro = detalhe[0];
    final mensagem = '${primeiro['msg']}'.replaceFirst('Value error, ', '');
    return '${primeiro['loc'].last}: $mensagem';
  }

}