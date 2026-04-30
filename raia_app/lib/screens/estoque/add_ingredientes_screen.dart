
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AddIngredientesScreen extends StatefulWidget {
  @override
  State<AddIngredientesScreen> createState() => _AddIngredientesScreenState();
}

class _AddIngredientesScreenState extends State<AddIngredientesScreen> {
  final _formKey = GlobalKey<FormState>();
  final nomeController = TextEditingController();
  final quantidadeController = TextEditingController();
  
  DateTime? dataValidade;
  String? unidadeSelecionada = 'un'; // Valor inicial
  bool _isLoading = false;

  final List<String> unidades = ['un', 'g', 'kg', 'ml', 'L'];

  Future<void> _selecionarData(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (picked != null && picked != dataValidade) {
      setState(() {
        dataValidade = picked;
      });
    }
  }

  Future<void> _salvarIngrediente() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: Usuário não autenticado.')),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('ingredientes')
            .add({
          'nome': nomeController.text,
          'quantidade': double.parse(quantidadeController.text.replaceAll(',', '.')),
          'unidade': unidadeSelecionada,
          'validade': dataValidade,
          'dataAdicionado': FieldValue.serverTimestamp(),
        });

        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ingrediente salvo com sucesso!')),
        );
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar ingrediente: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Adicionar Ingrediente"),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: nomeController,
                  decoration: InputDecoration(labelText: "Nome do ingrediente"),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, insira o nome.';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: quantidadeController,
                        decoration: InputDecoration(labelText: "Quantidade"),
                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Obrigatório';
                          }
                          if (double.tryParse(value.replaceAll(',', '.')) == null) {
                            return 'Número inválido';
                          }
                          return null;
                        },
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      flex: 1,
                      child: DropdownButtonFormField<String>(
                        value: unidadeSelecionada,
                        decoration: InputDecoration(labelText: "Unid."),
                        items: unidades.map((String unidade) {
                          return DropdownMenuItem<String>(
                            value: unidade,
                            child: Text(unidade),
                          );
                        }).toList(),
                        onChanged: (newValue) {
                          setState(() {
                            unidadeSelecionada = newValue;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                GestureDetector(
                  onTap: () => _selecionarData(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: Colors.grey)),
                    ),
                    child: Text(
                      dataValidade == null
                          ? "Selecionar data de validade (opcional)"
                          : "Validade: ${DateFormat('dd/MM/yyyy').format(dataValidade!)}",
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
                SizedBox(height: 32),
                _isLoading
                    ? Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        onPressed: _salvarIngrediente,
                        child: Text("Salvar"),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
