import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:raia_app/models/comando_voz.dart';
import 'package:raia_app/services/auth_service.dart';
import 'package:raia_app/services/estoque_voz_service.dart';
import 'package:raia_app/services/ingrediente_service.dart';
import 'package:raia_app/services/ocr_service.dart';
import 'package:raia_app/services/texto_foto_parser.dart';

/// Abre a tela de "adicionar por foto" (cupom fiscal ou lista escrita).
Future<void> abrirFotoIngredientes(BuildContext context) {
  return Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const FotoIngredientesScreen()),
  );
}

/// Tela para adicionar alimentos lendo as palavras de uma foto.
///
/// Fluxo: tira/escolhe a foto -> o ML Kit lê o texto -> o
/// [TextoFotoParser] separa os produtos -> o usuário confere e corrige
/// nome, quantidade e unidade -> grava no estoque (somando com o que já
/// existe, igual ao comando de voz).
class FotoIngredientesScreen extends StatefulWidget {
  const FotoIngredientesScreen({Key? key}) : super(key: key);

  @override
  State<FotoIngredientesScreen> createState() => _FotoIngredientesScreenState();
}

class _ItemEditavel {
  bool marcado = true;
  final TextEditingController nome;
  final TextEditingController quantidade;
  String unidade;
  final String linhaOriginal;

  _ItemEditavel(ItemFoto item)
      : nome = TextEditingController(text: item.nome),
        quantidade = TextEditingController(
            text: EstoqueVozService.formatarQuantidade(item.quantidade, '')
                .trim()),
        unidade = item.unidade,
        linhaOriginal = item.linhaOriginal;

  _ItemEditavel.vazio()
      : nome = TextEditingController(),
        quantidade = TextEditingController(text: '1'),
        unidade = 'un',
        linhaOriginal = '';

  double? get quantidadeNumero =>
      double.tryParse(quantidade.text.trim().replaceAll(',', '.'));

  void dispose() {
    nome.dispose();
    quantidade.dispose();
  }
}

class _FotoIngredientesScreenState extends State<FotoIngredientesScreen> {
  static const _unidades = ['un', 'g', 'kg', 'ml', 'L'];

  final _picker = ImagePicker();
  final _ocr = OcrService();
  final _authService = AuthService();
  final _ingredienteService = IngredienteService();
  late final EstoqueVozService _estoque =
      EstoqueVozService(ingredienteService: _ingredienteService);

  Uint8List? _foto;
  bool _lendo = false;
  bool _salvando = false;
  bool _jaLeu = false;
  String? _mensagem;
  String _textoLido = '';
  final List<_ItemEditavel> _itens = [];

  @override
  void dispose() {
    for (final i in _itens) {
      i.dispose();
    }
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Ações
  // ---------------------------------------------------------------------------

  Future<void> _escolherFoto(ImageSource origem) async {
    if (!OcrService.disponivel) {
      setState(() => _mensagem =
          'A leitura de fotos funciona só no Android e no iPhone. '
          'Aqui você pode usar "Digitar texto".');
      return;
    }

    XFile? arquivo;
    try {
      arquivo = await _picker.pickImage(
        source: origem,
        maxWidth: 2500, // grande o suficiente para letras pequenas de cupom
        imageQuality: 95,
      );
    } catch (e) {
      setState(() => _mensagem = 'Não foi possível abrir a câmera/galeria: $e');
      return;
    }
    if (arquivo == null) return; // usuário cancelou

    final bytes = await arquivo.readAsBytes();
    setState(() {
      _foto = bytes;
      _lendo = true;
      _mensagem = null;
    });

    try {
      final lido = await _ocr.lerImagem(arquivo.path);
      if (!mounted) return;
      _usarTexto(lido.texto);
    } catch (e) {
      if (mounted) setState(() => _mensagem = 'Erro ao ler a foto: $e');
    } finally {
      if (mounted) setState(() => _lendo = false);
    }
  }

  Future<void> _digitarTexto() async {
    final controller = TextEditingController(text: _textoLido);
    final texto = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Digitar ou colar texto'),
        content: TextField(
          controller: controller,
          autofocus: true,
          minLines: 5,
          maxLines: 12,
          decoration: const InputDecoration(
            hintText: 'Um item por linha. Ex.:\n2 kg de arroz\n6 ovos\nleite',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('Ler'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (texto != null && texto.trim().isNotEmpty) _usarTexto(texto);
  }

  void _usarTexto(String texto) {
    final encontrados = TextoFotoParser.interpretar(texto);
    setState(() {
      for (final i in _itens) {
        i.dispose();
      }
      _itens
        ..clear()
        ..addAll(encontrados.map(_ItemEditavel.new));
      _textoLido = texto;
      _jaLeu = true;
      _mensagem = encontrados.isEmpty
          ? 'Não encontrei alimentos no texto. Tente uma foto mais nítida, '
              'bem iluminada e reta, ou adicione os itens manualmente.'
          : null;
    });
  }

  void _adicionarLinha() {
    setState(() => _itens.add(_ItemEditavel.vazio()));
  }

  void _removerLinha(_ItemEditavel item) {
    setState(() => _itens.remove(item));
    item.dispose();
  }

  Future<void> _salvar() async {
    final user = _authService.usuarioAtual;
    if (user == null) {
      setState(() => _mensagem = 'Faça login para alterar o estoque.');
      return;
    }

    final comandos = <ComandoVoz>[];
    for (final item in _itens.where((i) => i.marcado)) {
      final nome = item.nome.text.trim();
      final q = item.quantidadeNumero;
      if (nome.isEmpty) continue;
      if (q == null || q <= 0) {
        setState(() => _mensagem = 'Quantidade inválida em "$nome".');
        return;
      }
      comandos.add(ComandoVoz(
        tipo: TipoComando.adicionar,
        nome: nome,
        quantidade: q,
        unidade: item.unidade,
        trecho: item.linhaOriginal,
      ));
    }
    if (comandos.isEmpty) {
      setState(() => _mensagem = 'Marque pelo menos um item.');
      return;
    }

    setState(() {
      _salvando = true;
      _mensagem = null;
    });
    try {
      final estoqueAtual = await _ingredienteService.listarUmaVez(user.uid);
      final plano = EstoqueVozService.planejar(comandos, estoqueAtual, user.uid);
      if (!mounted) return;

      final confirmou = await _confirmarPlano(plano);
      if (confirmou != true || !mounted) {
        setState(() => _salvando = false);
        return;
      }

      final messenger = ScaffoldMessenger.of(context);
      final navigator = Navigator.of(context);
      final n = await _estoque.aplicar(plano);
      navigator.pop();
      messenger.showSnackBar(SnackBar(
        content: Text(n == 1
            ? 'Estoque atualizado pela foto (1 alteração).'
            : 'Estoque atualizado pela foto ($n alterações).'),
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

  /// Mostra o que vai acontecer (itens novos e itens que vão somar com o que
  /// já está no estoque) antes de gravar.
  Future<bool?> _confirmarPlano(PlanoVoz plano) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar alterações'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              for (final linha in plano.linhas)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    linha.ok ? Icons.check_circle : Icons.error_outline,
                    color: linha.ok ? Colors.green : Colors.orange,
                  ),
                  title: Text(linha.descricao),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Voltar'),
          ),
          FilledButton(
            onPressed:
                plano.temAlteracoes ? () => Navigator.pop(ctx, true) : null,
            child: const Text('Salvar no estoque'),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final marcados = _itens.where((i) => i.marcado).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F2EE),
      appBar: AppBar(
        title: const Text('Adicionar por foto'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
          children: [
            Text(
              'Fotografe o cupom fiscal do mercado ou uma lista escrita. '
              'O app lê as palavras e você confere os itens antes de salvar.',
              style: TextStyle(color: Colors.grey.shade800),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _lendo || _salvando
                        ? null
                        : () => _escolherFoto(ImageSource.camera),
                    icon: const Icon(Icons.photo_camera),
                    label: const Text('Tirar foto'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _lendo || _salvando
                        ? null
                        : () => _escolherFoto(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Galeria'),
                  ),
                ),
              ],
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _lendo || _salvando ? null : _digitarTexto,
                icon: const Icon(Icons.keyboard, size: 18),
                label: const Text('Digitar texto'),
              ),
            ),
            if (_foto != null) ...[
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(
                  _foto!,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ],
            if (_lendo) ...[
              const SizedBox(height: 24),
              const Center(child: CircularProgressIndicator()),
              const SizedBox(height: 8),
              const Center(child: Text('Lendo a foto...')),
            ],
            if (_mensagem != null) ...[
              const SizedBox(height: 16),
              Text(_mensagem!, style: TextStyle(color: Colors.red.shade700)),
            ],
            if (_jaLeu && !_lendo) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _itens.isEmpty
                          ? 'Nenhum item'
                          : 'Itens encontrados (${_itens.length})',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _salvando ? null : _adicionarLinha,
                    icon: const Icon(Icons.add),
                    label: const Text('Item'),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              ..._itens.map(_cartaoItem),
              if (_textoLido.trim().isNotEmpty)
                ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  title: const Text('Ver texto lido'),
                  children: [
                    SelectableText(
                      _textoLido,
                      style: const TextStyle(
                          fontFamily: 'monospace', fontSize: 12),
                    ),
                  ],
                ),
            ],
          ],
        ),
      ),
      floatingActionButton: _itens.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: _salvando || marcados == 0 ? null : _salvar,
              backgroundColor:
                  marcados == 0 ? Colors.grey : Colors.green.shade600,
              icon: _salvando
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.check),
              label: Text('Adicionar ($marcados)'),
            ),
    );
  }

  Widget _cartaoItem(_ItemEditavel item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Checkbox(
                  value: item.marcado,
                  onChanged: (v) => setState(() => item.marcado = v ?? false),
                ),
                Expanded(
                  child: TextField(
                    controller: item.nome,
                    decoration: const InputDecoration(
                      labelText: 'Alimento',
                      isDense: true,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Remover da lista',
                  icon: const Icon(Icons.close),
                  onPressed: () => _removerLinha(item),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(left: 48, right: 48),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: item.quantidade,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Quantidade',
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  DropdownButton<String>(
                    value: _unidades.contains(item.unidade)
                        ? item.unidade
                        : 'un',
                    items: _unidades
                        .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                        .toList(),
                    onChanged: (u) =>
                        setState(() => item.unidade = u ?? item.unidade),
                  ),
                ],
              ),
            ),
            if (item.linhaOriginal.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 48, right: 12, top: 6),
                child: Text(
                  item.linhaOriginal,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
