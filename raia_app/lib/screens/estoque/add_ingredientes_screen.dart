import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:raia_app/models/ingrediente.dart';
import 'package:raia_app/services/auth_service.dart';
import 'package:raia_app/services/ingrediente_service.dart';

class AddIngredientesScreen extends StatefulWidget {
  final Ingrediente? ingrediente; // Ingrediente para edição

  const AddIngredientesScreen({Key? key, this.ingrediente}) : super(key: key);

  @override
  _AddIngredientesScreenState createState() => _AddIngredientesScreenState();
}

class _AddIngredientesScreenState extends State<AddIngredientesScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nomeController;
  late TextEditingController _quantidadeController;
  DateTime? _dataValidade;
  String _unidadeSelecionada = 'un'; // Valor padrão
  bool _isLoading = false;
  late bool _isEditing;
  final _authService = AuthService();
  final _ingredienteService = IngredienteService();

  final List<String> _unidades = ['un', 'g', 'kg', 'ml', 'L'];

  @override
  void initState() {
    super.initState();
    _isEditing = widget.ingrediente != null;

    _nomeController = TextEditingController();
    _quantidadeController = TextEditingController();

    if (_isEditing) {
      final ingrediente = widget.ingrediente!;
      _nomeController.text = ingrediente.nome;
      _quantidadeController.text = _formatarQuantidadeParaEdicao(ingrediente.quantidade);
      _unidadeSelecionada = ingrediente.unidade;
      _dataValidade = ingrediente.validade;
    }
  }

  /// Evita mostrar "2.0" no campo de edição quando a quantidade é inteira.
  String _formatarQuantidadeParaEdicao(double quantidade) {
    if (quantidade == quantidade.roundToDouble()) {
      return quantidade.toInt().toString();
    }
    return quantidade.toString();
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _quantidadeController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dataValidade ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _dataValidade) {
      setState(() {
        _dataValidade = picked;
      });
    }
  }

  Future<void> _salvarIngrediente() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final user = _authService.usuarioAtual;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: Usuário não autenticado.')),
        );
        setState(() => _isLoading = false);
      }
      return;
    }

    // Aceita tanto "1" quanto "1,5" ou "1.5" como quantidade.
    final quantidade =
        double.tryParse(_quantidadeController.text.replaceAll(',', '.')) ?? 0;

    final ingrediente = Ingrediente(
      id: _isEditing ? widget.ingrediente!.id : '',
      userId: user.uid,
      nome: _nomeController.text.trim(),
      quantidade: quantidade,
      unidade: _unidadeSelecionada,
      validade: _dataValidade,
    );

    try {
      if (_isEditing) {
        await _ingredienteService.atualizar(ingrediente);
      } else {
        await _ingredienteService.adicionar(ingrediente);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ingrediente salvo com sucesso!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar ingrediente: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar Ingrediente' : 'Adicionar Ingrediente'),
        elevation: 2,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                SizedBox(height: 20),
                TextFormField(
                  controller: _nomeController,
                  decoration: InputDecoration(labelText: 'Nome do Ingrediente'),
                  validator: (value) => value!.isEmpty ? 'Por favor, insira um nome' : null,
                ),
                SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _quantidadeController,
                        decoration: InputDecoration(labelText: 'Quantidade'),
                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                        validator: (value) => value!.isEmpty ? 'Insira a quantidade' : null,
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      flex: 1,
                      child: DropdownButtonFormField<String>(
                        value: _unidadeSelecionada,
                        items: _unidades.map((String unidade) {
                          return DropdownMenuItem<String>(
                            value: unidade,
                            child: Text(unidade),
                          );
                        }).toList(),
                        onChanged: (newValue) {
                          setState(() {
                            _unidadeSelecionada = newValue!;
                          });
                        },
                        decoration: InputDecoration(labelText: 'Un.'),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Text(_dataValidade == null
                          ? 'Nenhuma data selecionada'
                          : 'Validade: ${DateFormat('dd/MM/yyyy').format(_dataValidade!)}'),
                    ),
                    TextButton(
                      onPressed: () => _selectDate(context),
                      child: Text('Selecionar Data'),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                _isLoading
                    ? CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: _salvarIngrediente,
                        child: Text(_isEditing ? 'Salvar Alterações' : 'Adicionar'),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}