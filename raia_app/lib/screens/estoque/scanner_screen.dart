import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Tela da câmera que lê QR code ou código de barras.
/// Ao ler, fecha e devolve o texto lido via `Navigator.pop(context, valor)`.
class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  // Evita fechar a tela várias vezes se a câmera ler o mesmo código em
  // sequência.
  bool _lido = false;

  void _aoDetectar(BarcodeCapture captura) {
    if (_lido) return;

    for (final barcode in captura.barcodes) {
      final valor = barcode.rawValue;
      if (valor != null && valor.trim().isNotEmpty) {
        _lido = true;
        Navigator.pop(context, valor.trim());
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Escanear código'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          MobileScanner(onDetect: _aoDetectar),
          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.greenAccent, width: 3),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          const Positioned(
            left: 24,
            right: 24,
            bottom: 40,
            child: Text(
              'Aponte a câmera para o QR code ou o código de barras do produto',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
