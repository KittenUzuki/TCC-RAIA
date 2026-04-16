import 'package:flutter/material.dart';

class AddIngredientesScreen extends StatefulWidget {
  @override
  State<AddIngredientesScreen> createState() => _AddIngredientesScreenState();
}

class _AddIngredientesScreenState extends State<AddIngredientesScreen> {
  final nomeController = TextEditingController();
  final quantidadeController = TextEditingController();

  DateTime? dataValidade;

  Future<void> selecionarData(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked != null && picked != dataValidade) {
      setState(() {
        dataValidade = picked;
      });
    }
  }

  String formatarData(DateTime data) {
    return "${data.day}/${data.month}/${data.year}";
  }

  @override
  Widget build(BuildContext context) {
    final largura = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: Text("Adicionar Ingrediente"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: largura * 0.08),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Novo Ingrediente",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),

                SizedBox(height: 30),

                TextField(
                  controller: nomeController,
                  decoration: InputDecoration(
                    labelText: "Nome do ingrediente",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),

                SizedBox(height: 15),

                TextField(
                  controller: quantidadeController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: "Quantidade",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),

                SizedBox(height: 15),

                // CAMPO DE DATA
                GestureDetector(
                  onTap: () => selecionarData(context),
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 15, horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      dataValidade == null
                          ? "Selecionar data de validade (opcional)"
                          : "Validade: ${formatarData(dataValidade!)}",
                      style: TextStyle(
                        color: dataValidade == null
                            ? Colors.grey
                            : Colors.black,
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 25),

                ElevatedButton(
                  onPressed: () {
                    // AQUI FUTURAMENTE VAI PRO BANCO
                    print("Nome: ${nomeController.text}");
                    print("Quantidade: ${quantidadeController.text}");
                    print("Validade: $dataValidade");

                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    minimumSize: Size(double.infinity, 45),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
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