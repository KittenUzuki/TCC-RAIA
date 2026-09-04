
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:raia_app/db.dart';

class AddIngredientesScreen extends StatefulWidget {
  final QueryDocumentSnapshot? ingrediente; // Ingrediente para edição

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

  final List<String> _unidades = ['un', 'g', 'kg', 'ml', 'L'];

  @override
  void initState() {
    super.initState();
    _isEditing = widget.ingrediente != null;

    _nomeController = TextEditingController();
    _quantidadeController = TextEditingController();

    if (_isEditing) {
      final data = widget.ingrediente!.data() as Map<String, dynamic>;
      _nomeController.text = data['nome'] ?? '';
      _quantidadeController.text = (data['quantidade'] ?? '').toString();
      _unidadeSelecionada = data['unidade'] ?? 'un';
      final Timestamp? validadeTimestamp = data['validade'];
      if (validadeTimestamp != null) {
        _dataValidade = validadeTimestamp.toDate();
      }
    }
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
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro: Usuário não autenticado.')),
          );
          setState(() => _isLoading = false);
        }
        return;
      }
      
      try {
        final collection = db.collection('ingredientes');

        final data = {
          'userId': user.uid,
          'nome': _nomeController.text,
          'quantidade': int.tryParse(_quantidadeController.text) ?? 0,
          'unidade': _unidadeSelecionada,
          'validade': _dataValidade != null ? Timestamp.fromDate(_dataValidade!) : null,
        };

        final Future<void> operacao;
        if (_isEditing) {
          operacao = collection.doc(widget.ingrediente!.id).update(data);
        } else {
          final dataToCreate = {
            ...data,
            'criadoEm': Timestamp.now(),
          };
          operacao = collection.add(dataToCreate).then((_) {});
        }

        await operacao.timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            throw Exception(
              'TIMEOUT: o Firestore nao respondeu em 10s. '
              'Provavel causa: banco em modo Datastore (nao Nativo) ou conexao bloqueada.',
            );
          },
        );

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
                        keyboardType: TextInputType.number,
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
