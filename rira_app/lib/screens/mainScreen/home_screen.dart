class HomeScreen extends StatelessWidget {

  final List<String> itens = [
    "Tomate (2)",
    "Leite (1L)",
    "Arroz (1 pacote)"
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],

      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              SizedBox(height: 20),

              Text(
                "Rira",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),

              Text("Sua cozinha inteligente"),

              SizedBox(height: 20),

              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text("Você tem ${itens.length} itens no estoque"),
              ),

              SizedBox(height: 20),

              buildButton("Adicionar alimento", () {}),
              buildButton("Ver estoque", () {}),
              buildButton("Ver receitas", () {}),

              SizedBox(height: 20),

              Text(
                "Itens recentes",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),

              ...itens.map((item) => buildItem(item)).toList(),
            ],
          ),
        ),
      ),
    );
  }
}