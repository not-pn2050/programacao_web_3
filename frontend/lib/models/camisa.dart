class Camisa {
  Camisa({
    required this.id,
    required this.time,
    required this.temporada,
    required this.cor,
    required this.descricao,
    required this.camisaPedidoId,
  });

  final int id;
  final String time;
  final String temporada;
  final String cor;
  final String descricao;
  final int camisaPedidoId;

  factory Camisa.fromJson(Map<String, dynamic> json) {
    return Camisa(
      id: json['id'],
      time: json['time'],
      temporada: json['temporada'],
      cor: json['cor'],
      descricao: json['descricao'],
      camisaPedidoId: json['camisaPedidoId'],
    );
  }
}