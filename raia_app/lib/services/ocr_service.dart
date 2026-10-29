import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:raia_app/services/texto_foto_parser.dart';

/// Texto lido de uma foto, já organizado em linhas.
class TextoLido {
  /// Texto como o OCR devolveu (blocos separados).
  final String textoBruto;

  /// Linhas remontadas pela posição na foto (nome + preço na mesma linha).
  final List<String> linhas;

  const TextoLido(this.textoBruto, this.linhas);

  String get texto => linhas.join('\n');
}

/// Lê as palavras de uma foto usando o ML Kit do Google.
///
/// O reconhecimento roda no próprio celular (não precisa de internet nem de
/// chave de API). Funciona só no Android e no iOS.
class OcrService {
  static bool get disponivel =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  Future<TextoLido> lerImagem(String caminho) async {
    if (!disponivel) {
      throw UnsupportedError(
          'A leitura de fotos funciona só no Android e no iPhone.');
    }

    final reconhecedor = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final resultado =
          await reconhecedor.processImage(InputImage.fromFilePath(caminho));

      final trechos = <TrechoTexto>[
        for (final bloco in resultado.blocks)
          for (final linha in bloco.lines)
            TrechoTexto(
              linha.text,
              linha.boundingBox.left,
              linha.boundingBox.top,
              linha.boundingBox.right,
              linha.boundingBox.bottom,
            ),
      ];

      return TextoLido(resultado.text, TextoFotoParser.montarLinhas(trechos));
    } finally {
      await reconhecedor.close();
    }
  }
}
