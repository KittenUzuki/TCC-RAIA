import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// Envolve o pacote `speech_to_text` (reconhecimento de voz do próprio
/// aparelho: Google no Android, Apple no iOS/macOS, Chrome na Web).
///
/// Uso:
///   final voz = VozService();
///   if (await voz.inicializar(onStatus: ..., onErro: ...)) {
///     await voz.ouvir((texto, ehFinal) { ... });
///   }
class VozService {
  final SpeechToText _stt = SpeechToText();
  String? _localeId;

  bool get ouvindo => _stt.isListening;

  /// Pede permissão de microfone (na primeira vez) e escolhe o idioma pt-BR.
  /// Retorna false se o aparelho não tiver reconhecimento de voz ou se a
  /// permissão for negada.
  Future<bool> inicializar({
    required void Function(bool ouvindo) onStatus,
    required void Function(String mensagem) onErro,
  }) async {
    void status(String s) => onStatus(s == SpeechToText.listeningStatus);
    void erro(SpeechRecognitionError e) => onErro(traduzirErro(e.errorMsg));

    bool ok;
    try {
      ok = await _stt.initialize(onStatus: status, onError: erro);
    } catch (e) {
      onErro('Não foi possível iniciar o reconhecimento de voz: $e');
      return false;
    }
    // O SpeechToText é um singleton: se já tinha sido inicializado por outra
    // tela, o initialize() não troca os callbacks. Por isso setamos de novo.
    _stt.statusListener = status;
    _stt.errorListener = erro;

    if (ok) _localeId = await _escolherPortugues();
    return ok;
  }

  Future<String?> _escolherPortugues() async {
    try {
      final locales = await _stt.locales();
      String norm(String id) => id.toLowerCase().replaceAll('-', '_');
      for (final l in locales) {
        if (norm(l.localeId) == 'pt_br') return l.localeId;
      }
      for (final l in locales) {
        if (norm(l.localeId).startsWith('pt')) return l.localeId;
      }
    } catch (_) {
      // alguns navegadores não listam idiomas
    }
    return 'pt_BR';
  }

  /// Começa a ouvir. [onTexto] é chamado várias vezes enquanto a pessoa fala
  /// (resultado parcial) e uma última vez com `ehFinal == true`.
  Future<void> ouvir(void Function(String texto, bool ehFinal) onTexto,
      {void Function(double nivel)? onVolume}) async {
    // listenFor/pauseFor/localeId ficam aqui (e não no SpeechListenOptions)
    // pra funcionar em todas as versões 7.x do pacote.
    await _stt.listen(
      onResult: (r) => onTexto(r.recognizedWords, r.finalResult),
      // ignore: deprecated_member_use
      localeId: _localeId,
      // ignore: deprecated_member_use
      listenFor: const Duration(seconds: 30),
      // ignore: deprecated_member_use
      pauseFor: const Duration(seconds: 4),
      onSoundLevelChange: onVolume,
      listenOptions: SpeechListenOptions(
        partialResults: true,
        listenMode: ListenMode.dictation,
        cancelOnError: true,
      ),
    );
  }

  Future<void> parar() => _stt.stop();

  Future<void> cancelar() => _stt.cancel();

  static String traduzirErro(String codigo) {
    switch (codigo) {
      case 'error_no_match':
        return 'Não entendi. Tente falar de novo, mais devagar.';
      case 'error_speech_timeout':
        return 'Não ouvi nada. Toque no microfone e fale.';
      case 'error_permission':
      case 'error_insufficient_permissions':
      case 'not-allowed':
        return 'O app não tem permissão para usar o microfone.';
      case 'error_network':
      case 'error_network_timeout':
      case 'network':
        return 'Sem internet para reconhecer a voz.';
      case 'error_busy':
      case 'error_recognizer_busy':
        return 'O reconhecimento de voz está ocupado. Tente de novo.';
      case 'error_audio':
      case 'audio-capture':
        return 'Não consegui acessar o microfone.';
      default:
        return 'Erro no reconhecimento de voz ($codigo).';
    }
  }
}
