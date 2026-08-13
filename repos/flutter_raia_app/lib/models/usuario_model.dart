class UsuarioModel {
  final String id;
  final String nome;
  final String email;
  final DateTime dataCriacao;

  UsuarioModel({
    required this.id,
    required this.nome,
    required this.email,
    required this.dataCriacao,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'email': email,
      'dataCriacao': dataCriacao,
    };
  }

  factory UsuarioModel.fromMap(Map<String, dynamic> map) {
    return UsuarioModel(
      id: map['id'],
      nome: map['nome'],
      email: map['email'],
      dataCriacao: map['dataCriacao'].toDate(),
    );
  }
}