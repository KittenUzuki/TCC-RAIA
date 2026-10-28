/// O que o usuário pediu para fazer com um alimento, por voz.
enum TipoComando { adicionar, remover }

/// Um comando já interpretado a partir da frase falada.
///
/// Exemplo: "adicionar 2 kg de arroz" vira
/// `ComandoVoz(tipo: adicionar, nome: 'arroz', quantidade: 2, unidade: 'kg')`.
///
/// `quantidade` e `unidade` ficam `null` quando o usuário não falou.
/// Isso importa principalmente na remoção:
///   - "remover o leite"      -> quantidade null -> apaga o item inteiro
///   - "remover 1 litro de leite" -> subtrai 1 L do que tiver no estoque
class ComandoVoz {
  final TipoComando tipo;
  final String nome;
  final double? quantidade;

  /// Uma das unidades do app: 'un', 'g', 'kg', 'ml', 'L' (ou null).
  final String? unidade;

  /// Trecho da frase que gerou este comando (útil pra mostrar ao usuário).
  final String trecho;

  const ComandoVoz({
    required this.tipo,
    required this.nome,
    this.quantidade,
    this.unidade,
    this.trecho = '',
  });

  @override
  String toString() =>
      'ComandoVoz(${tipo.name}, "$nome", $quantidade, $unidade)';
}

/// Resultado de interpretar uma frase inteira, que pode ter vários itens:
/// "adicionar 2 ovos e 1 kg de arroz e remover o leite".
class ResultadoInterpretacao {
  final List<ComandoVoz> comandos;

  /// Pedaços da frase que não deu pra entender (ex.: só um verbo solto).
  final List<String> trechosIgnorados;

  const ResultadoInterpretacao(this.comandos, this.trechosIgnorados);

  bool get vazio => comandos.isEmpty;
}
