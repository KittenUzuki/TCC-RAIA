import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

/// Resolve sozinho o endereço da API Flask (`IA/server.py`) dependendo de
/// ONDE o app Flutter está rodando — não de onde o Flask está rodando (o
/// Flask sempre roda no seu computador, em localhost:5000).
///
///  - Chrome: o navegador roda na mesma máquina que o Flask, então
///    'localhost' funciona direto.
///  - Emulador Android: é uma máquina virtual separada. Para ela,
///    'localhost' seria ela mesma, não o seu PC — o Android reserva o
///    endereço especial 10.0.2.2 para apontar de volta ao computador
///    hospedeiro.
///
/// CELULAR FÍSICO é o único caso que não dá pra detectar sozinho: não tem
/// como o app adivinhar o IP do seu computador na rede Wi-Fi. Se for testar
/// assim, descubra o IP da sua máquina (`ipconfig` no Windows, procure por
/// "Endereço IPv4") e preencha abaixo, em [_ipDaMinhaMaquina].
class ApiConfig {
  ApiConfig._();

  // Exemplo: '192.168.0.15'. Deixe null enquanto testar no Chrome ou no
  // emulador — só preencha quando for testar num celular físico.
  static const String? _ipDaMinhaMaquina = null;

  static String get baseUrl {
    if (_ipDaMinhaMaquina != null) {
      return 'http://$_ipDaMinhaMaquina:5000';
    }
    if (kIsWeb) {
      return 'http://localhost:5000';
    }
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:5000';
    }
    // iOS no simulador, Windows/macOS desktop etc. também enxergam
    // localhost como o próprio computador.
    return 'http://localhost:5000';
  }
}
