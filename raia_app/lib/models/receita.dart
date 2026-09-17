class Receita {
  final String id;
  final String nome;
  final String imagem;
  final List<String> ingredientesFaltando;
  final String modoPreparo;

  Receita({
    required this.id,
    required this.nome,
    required this.imagem,
    required this.ingredientesFaltando,
    required this.modoPreparo,
  });

  factory Receita.fromJson(Map<String, dynamic> json) {
    return Receita(
      id: json['id'],
      nome: json['nome'],
      imagem: json['imagem'],
      ingredientesFaltando: List<String>.from(json['ingredientesFaltando']),
      modoPreparo: json['modoPreparo'],
    );
  }
}