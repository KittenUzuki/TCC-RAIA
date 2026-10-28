import 'package:flutter/material.dart';
import 'package:raia_app/models/comando_voz.dart';
import 'package:raia_app/services/auth_service.dart';
import 'package:raia_app/services/comando_voz_parser.dart';
import 'package:raia_app/services/estoque_voz_service.dart';
import 'package:raia_app/services/ingrediente_service.dart';
import 'package:raia_app/services/voz_service.dart';

/// Abre a "telinha" de voz por baixo (mesmo estilo do formulário manual).
Future<void> abrirVozIngredientes(
  BuildContext context, {
  TipoComando padrao = TipoComando.adicionar,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: VozIngredientesScreen(padrao: padrao),
    ),
  );
}

/// Tela para adicionar/remover alimentos falando.
///
/// Fluxo: ouve -> mostra o texto -> mostra a prévia do que vai mudar ->
/// usuário confirma -> grava no Firestore.
/// O texto reconhecido fica num campo editável: dá pra corrigir uma palavra
/// errada ou até digitar o comando (útil no emulador sem microfone).
class VozIngredientesScreen extends StatefulWidget {
  final TipoComando padrao;

  const VozIngredientesScreen({Key? key, this.padrao = TipoComando.adicionar})
      : super(key: key);

  @override
  State<VozIngredientesScreen> createState() => _VozIngredientesScreenState();
}

class _VozIngredientesScreenState extends State<VozIngredientesScreen> {
  final _voz = VozService();
  final _authService = AuthService();
  final _ingredienteService = IngredienteService();
  late final EstoqueVozService _estoqueVoz =
      EstoqueVozService(ingredienteService: _ingredienteService);
  final _textoController = TextEditingController();

  late TipoComando _padrao;
  bool? _vozDisponivel; // null = ainda verificando
  bool _ouvindo = false;
  bool _interpretando = false;
  bool _salvando = false;
  double _volume = 0;
  String? _mensagem;
  PlanoVoz? _plano;
  List<String> _ignorados = [];

  @override
  void initState() {
    super.initState();
    _padrao = widget.padrao;
    _iniciarVoz();
  }

  @override
  void dispose() {
    _voz.cancelar();
    _textoController.dispose();
    super.dispose();
  }

  Future<void> _iniciarVoz() async {
    final ok = await _voz.inicializar(
      onStatus: (ouvindo) {
        if (!mounted) return;
        final parou = _ouvindo && !ouvindo;
        setState(() {
          _ouvindo = ouvindo;
          if (!ouvindo) _volume = 0;
        });
        // Em alguns aparelhos o resultado "final" não chega; quando o
        // microfone desliga, interpretamos o que já foi ouvido.
        if (parou && _plano == null && _textoController.text.trim().isNotEmpty) {
          _interpretar();
        }
      },
      onErro: (msg) {
        if (!mounted) return;
        setState(() {
          _mensagem = msg;
          _ouvindo = false;
        });
      },
    );
    if (!mounted) return;
    setState(() => _vozDisponivel = ok);
    if (ok) {
      _ouvir();
    } else {
      setState(() => _mensagem ??=
          'Reconhecimento de voz indisponível neste aparelho. '
          'Você pode digitar o comando abaixo.');
    }
  }

  Future<void> _ouvir() async {
    if (_vozDisponivel != true) return;
    setState(() {
      _mensagem = null;
      _plano = null;
      _ignorados = [];
      _textoController.clear();
      _ouvindo = true;
    });
    try {
      await _voz.ouvir(
        (texto, ehFinal) {
          if (!mounted) return;
          setState(() => _textoController.text = texto);
          if (ehFinal) _interpretar();
        },
        onVolume: (nivel) {
          if (mounted) setState(() => _volume = nivel);
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _ouvindo = false;
          _mensagem = 'Não consegui começar a ouvir: $e';
        });
      }
    }
  }

  Future<void> _alternarMicrofone() async {
    if (_ouvindo) {
      await _voz.parar();
    } else {
      await _ouvir();
    }
  }

  Future<void> _interpretar() async {
    final texto = _textoController.text.trim();
    if (texto.isEmpty || _interpretando) return;

    final user = _authService.usuarioAtual;
    if (user == null) {
      setState(() => _mensagem = 'Faça login para alterar o estoque.');
      return;
    }

    setState(() {
      _interpretando = true;
      _mensagem = null;
    });
    try {
      final resultado = ComandoVozParser.interpretar(texto, padrao: _padrao);
      final estoque = await _ingredienteService.listarUmaVez(user.uid);
      final plano =
          EstoqueVozService.planejar(resultado.comandos, estoque, user.uid);
      if (!mounted) return;
      setState(() {
        _plano = plano;
        _ignorados = resultado.trechosIgnorados;
        if (resultado.vazio) {
          _mensagem = 'Não encontrei nenhum alimento na frase. '
              'Ex.: "adicionar 2 kg de arroz".';
        }
      });
    } catch (e) {
      if (mounted) setState(() => _mensagem = 'Erro ao ler o estoque: $e');
    } finally {
      if (mounted) setState(() => _interpretando = false);
    }
  }

  Future<void> _confirmar() async {
    final plano = _plano;
    if (plano == null || !plano.temAlteracoes) return;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    setState(() => _salvando = true);
    try {
      final n = await _estoqueVoz.aplicar(plano);
      navigator.pop();
      messenger.showSnackBar(SnackBar(
        content: Text(n == 1
            ? 'Estoque atualizado por voz (1 alteração).'
            : 'Estoque atualizado por voz ($n alterações).'),
      ));
    } catch (e) {
      if (mounted) {
        setState(() {
          _salvando = false;
          _mensagem = 'Erro ao salvar: $e';
        });
      }
    }
  }

  // ---------------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final verde = Colors.green.shade600;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Estoque por voz',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Ex.: "adicionar 2 kg de arroz e 6 ovos" ou "remover o leite"',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
            ),
            const SizedBox(height: 20),
            Center(child: _botaoMicrofone(verde)),
            const SizedBox(height: 10),
            Text(
              _textoStatus(),
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade800),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _textoController,
              minLines: 1,
              maxLines: 3,
              textInputAction: TextInputAction.done,
              onChanged: (_) {
                if (_plano != null) setState(() => _plano = null);
              },
              onSubmitted: (_) => _interpretar(),
              decoration: InputDecoration(
                labelText: 'O que foi entendido (dá pra corrigir)',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  tooltip: 'Interpretar',
                  icon: const Icon(Icons.check),
                  onPressed: _interpretar,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Se eu não disser o verbo:',
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                  ),
                ),
                SegmentedButton<TipoComando>(
                  segments: const [
                    ButtonSegment(
                      value: TipoComando.adicionar,
                      label: Text('Adicionar'),
                    ),
                    ButtonSegment(
                      value: TipoComando.remover,
                      label: Text('Remover'),
                    ),
                  ],
                  selected: {_padrao},
                  showSelectedIcon: false,
                  style: const ButtonStyle(
                    visualDensity: VisualDensity.compact,
                  ),
                  onSelectionChanged: (s) {
                    setState(() => _padrao = s.first);
                    if (_textoController.text.trim().isNotEmpty) {
                      _plano = null;
                      _interpretar();
                    }
                  },
                ),
              ],
            ),
            if (_mensagem != null) ...[
              const SizedBox(height: 12),
              _aviso(_mensagem!),
            ],
            if (_interpretando) ...[
              const SizedBox(height: 16),
              const Center(child: CircularProgressIndicator()),
            ],
            if (_plano != null && _plano!.linhas.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text('O que vai mudar:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              ..._plano!.linhas.map(_linhaPlano),
            ],
            if (_ignorados.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                'Não entendi: ${_ignorados.map((t) => '"$t"').join(', ')}',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _salvando ? null : () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: verde,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: (_plano?.temAlteracoes ?? false) && !_salvando
                        ? _confirmar
                        : null,
                    child: _salvando
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Confirmar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _textoStatus() {
    if (_vozDisponivel == null) return 'Preparando o microfone...';
    if (_vozDisponivel == false) return 'Digite o comando no campo abaixo.';
    if (_ouvindo) return 'Ouvindo... pode falar';
    if (_plano != null) return 'Confira e toque em Confirmar, ou fale de novo';
    return 'Toque no microfone para falar';
  }

  Widget _botaoMicrofone(Color verde) {
    // O nível de som vem mais ou menos entre -2 e 10; vira um "pulso".
    final pulso = _ouvindo ? (_volume.clamp(0, 10) / 10) * 18 : 0.0;
    final desabilitado = _vozDisponivel != true;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      width: 84 + pulso,
      height: 84 + pulso,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: (_ouvindo ? Colors.red : verde).withAlpha(40),
      ),
      alignment: Alignment.center,
      child: Material(
        color: desabilitado
            ? Colors.grey.shade400
            : (_ouvindo ? Colors.red : verde),
        shape: const CircleBorder(),
        elevation: 2,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: desabilitado ? null : _alternarMicrofone,
          child: SizedBox(
            width: 72,
            height: 72,
            child: Icon(
              _ouvindo ? Icons.stop : Icons.mic,
              color: Colors.white,
              size: 34,
            ),
          ),
        ),
      ),
    );
  }

  Widget _aviso(String texto) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.orange.shade800, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(texto)),
        ],
      ),
    );
  }

  Widget _linhaPlano(LinhaPlano l) {
    final IconData icone;
    final Color cor;
    if (!l.ok) {
      icone = Icons.error_outline;
      cor = Colors.orange.shade800;
    } else if (l.comando.tipo == TipoComando.adicionar) {
      icone = Icons.add_circle;
      cor = Colors.green.shade700;
    } else {
      icone = Icons.remove_circle;
      cor = Colors.red.shade700;
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icone, color: cor, size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              l.descricao,
              style: TextStyle(
                color: l.ok ? null : Colors.orange.shade900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
