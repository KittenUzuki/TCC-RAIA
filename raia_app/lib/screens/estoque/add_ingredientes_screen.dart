
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AddIngredientesScreen extends StatefulWidget {
  // Adicionado para receber o ingrediente a ser editado
  final QueryDocumentSnapshot? ingrediente;

  const AddIngredientesScreen({Key? key, this.ingrediente}) : super(key: key);

  @override
  State<AddIngredientesScreen> createState() => _AddIngredientesScreenState();
}

class _AddIngredientesScreenState extends State<AddIngredientesScreen> {
  final _formKey = GlobalKey<FormState>();
  final nomeController = TextEditingController();
  final quantidadeController = TextEditingController();
  
  DateTime? dataValidade;
  String? unidadeSelecionada;
  bool _isLoading = false;
  bool get _isEditing => widget.ingrediente != null;

  final List<String> unidades = ['un', 'g', 'kg', 'ml', 'L'];

  @override
  void initState() {
    super.initState();
    // Preenche o formulário se um ingrediente foi passado
    if (_isEditing) {
      final data = widget.ingrediente!.data() as Map<String, dynamic>;
      nomeController.text = data['nome'] ?? '';
      quantidadeController.text = (data['quantidade'] ?? 0).toString().replaceAll('.', ',');
      unidadeSelecionada = data['unidade'] ?? 'un';
      dataValidade = (data['validade'] as Timestamp?)?.toDate();
    } else {
      unidadeSelecionada = 'un';
    }
  }

  Future<void> _selecionarData(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: dataValidade ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != dataValidade) {
      setState(() {
        dataValidade = picked;
      });
    }
  }

  Future<void> _salvarIngrediente() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) { /* ... (código de erro) ... */ return; }

    final data = {
      'nome': nomeController.text,
      'quantidade': double.parse(quantidadeController.text.replaceAll(',', '.')),
      'unidade': unidadeSelecionada,
      'validade': dataValidade != null ? Timestamp.fromDate(dataValidade!) : null,
      'dataAdicionado': _isEditing ? widget.ingrediente!['dataAdicionado'] : FieldValue.serverTimestamp(),
    };

    try {
      final collection = FirebaseFirestore.instance.collection('ingredientes').doc(user.uid).collection('userIngredientes');
      if (_isEditing) {
        await collection.doc(widget.ingrediente!.id).update(data);
      } else {
        await collection.add(data);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ingrediente salvo com sucesso!')),
        );
        Navigator.pop(context);
      }
    } catch (e) { /* ... (código de erro) ... */
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _isEditing ? "Editar Ingrediente" : "Adicionar Ingrediente",
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 24),
              TextFormField(controller: nomeController, /* ... */ ),
              SizedBox(height: 16),
              Row(/* ... (campos de quantidade e unidade) ... */),
              SizedBox(height: 16),
              GestureDetector(onTap: () => _selecionarData(context), /* ... (campo de data) ... */),
              SizedBox(height: 32),
              _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _salvarIngrediente,
                      child: Text(_isEditing ? "Salvar Alterações" : "Adicionar"),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
