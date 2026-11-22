import '../models/camisa.dart';
import '../repositories/camisa_repository.dart';
import '../repositories/usuario_repository.dart';
import 'sessao_service.dart';

class ErroDeCamisa implements Exception{
  ErroDeCamisa(this.mensagem);

  final String mensagem;

  @override
  String toString() => mensagem;
}

class CamisaService {
  CamisaService(this.repositorio, this.sessao);

  final CamisaRepository repositorio;
  final SessaoService sessao;

  Future<List<Camisa>> listar({String busca = ''}) async {
    try{
      return await repositorio.listar(sessao.token!, busca: busca);
    } on RecusaDaApi catch (e) {
      throw ErroDeCamisa(e.mensagem);
    } on Exception {
      throw ErroDeCamisa('não consegui falar com a API. O uvicorn esta rodando?');
    }
  }

  Future<Camisa> buscar(int id) async {
    try{
      return await repositorio.buscar(sessao.token!, id);
    } on RecusaDaApi catch (e) {
      throw ErroDeCamisa(e.mensagem);
    } on Exception {
      throw ErroDeCamisa('Não conseguiu falar com a API. O unicorn está rodando');
    }
  }

  Future<Camisa> criar(String time, String temporada, String cor, String descricao) async {
    try{
      return await repositorio.criar(sessao.token!, time, temporada, cor, descricao);
    } on RecusaDaApi catch (e) {
      throw ErroDeCamisa(e.mensagem);
    } on Exception {
      throw ErroDeCamisa('Não conseguiu falar com a API. o uvicorn está rodando?');
    }
  }

  Future<Camisa> atualizar(int id, String time, String temporada, String cor, String descricao) async {
    try{
      return await repositorio.atualizar(sessao.token!, id, time, temporada, cor, descricao);
    } on RecusaDaApi catch (e) {
      throw ErroDeCamisa(e.mensagem);
    } on Exception {
      throw ErroDeCamisa('Não consegui falar com a API, o uivcorn está Rodando?');
    }
  }

  Future<void> excluir(int id) async {
    try {
      await repositorio.excluir(sessao.token!, id);
    } on RecusaDaApi catch (e) {
      throw ErroDeCamisa(e.mensagem);
    } on Exception {
      throw ErroDeCamisa('Não consegui falar com a API, o uivcorn está Rodando?');
    }

}
}