import 'package:flutter/material.dart';
import '202310272_202310235_database.dart';
import 'dart:convert';
import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // inicialização multiplataforma do banco
  if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  await DatabaseInitialization.instance.db; 
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData temaDarkPro = ThemeData.dark().copyWith(
      primaryColor: Colors.black,
      colorScheme: const ColorScheme.dark(
        primary: Colors.black,
        secondary: Colors.deepPurple,
      ),
      scaffoldBackgroundColor: Colors.black,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        labelStyle: TextStyle(color: Colors.white70),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.deepPurple),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.deepPurpleAccent),
        ),
      ),
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: temaDarkPro,
      home: const TelaTarefas(),
    );
  }
}

class TelaTarefas extends StatefulWidget {
  const TelaTarefas({super.key});

  @override
  _TelaTarefasState createState() => _TelaTarefasState();
}

class _TelaTarefasState extends State<TelaTarefas> {
  List<Map<String, dynamic>> tarefas = [];

  final tituloController = TextEditingController();
  final descricaoController = TextEditingController();
  final prioridadeController = TextEditingController();
  final nivelAcessoController = TextEditingController();

  int usuarioNivel = 1;

  @override
  void initState() {
    super.initState();
    carregarTarefas();
  }

  Future<void> carregarTarefas() async {
    final dados = await DatabaseInitialization.instance.listarTarefas();

    print(jsonEncode(dados));

    setState(() {
      tarefas = dados;
    });
  }

  Future<void> inserirTarefa() async {
    if (tituloController.text.isEmpty) return;

    await DatabaseInitialization.instance.inserirTarefa({
      "titulo": tituloController.text,
      "descricao": descricaoController.text,
      "prioridade": int.tryParse(prioridadeController.text) ?? 0,
      "criadoEm": DateTime.now().toIso8601String(),
      "nivelAcesso": int.tryParse(nivelAcessoController.text) ?? 0,
    });

    limparCampos();
    carregarTarefas();
  }

  Future<void> editarTarefa(Map tarefa) async {
    tituloController.text = tarefa["titulo"];
    descricaoController.text = tarefa["descricao"];
    prioridadeController.text = tarefa["prioridade"].toString();
    nivelAcessoController.text = tarefa["nivelAcesso"].toString();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Editar Tarefa"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            campo("Título", tituloController),
            campo("Descrição", descricaoController),
            campo("Prioridade", prioridadeController),
            campo("Nível de acesso", nivelAcessoController),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              if (usuarioNivel != 1) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Você não tem permissão para editar.")),
                );
                Navigator.pop(context);
                return;
              }

              await DatabaseInitialization.instance.editarTarefa(
                tarefa["id"],
                {
                  "titulo": tituloController.text,
                  "descricao": descricaoController.text,
                  "prioridade": int.tryParse(prioridadeController.text) ?? 0,
                  "criadoEm": tarefa["criadoEm"],
                  "nivelAcesso": int.tryParse(nivelAcessoController.text) ?? 0,
                },
                usuarioNivel,
              );

              limparCampos();
              carregarTarefas();
              Navigator.pop(context);
            },
            child: const Text("Salvar"),
          )
        ],
      ),
    );
  }

  Future<void> excluirTarefa(int id) async {
    if (usuarioNivel != 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Você não tem permissão para excluir.")),
      );
      return;
    }

    await DatabaseInitialization.instance.excluirTarefa(id, usuarioNivel);
    carregarTarefas();
  }

  void limparCampos() {
    tituloController.clear();
    descricaoController.clear();
    prioridadeController.clear();
    nivelAcessoController.clear();
  }

  Widget campo(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(labelText: label),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Mini Cadastro de Tarefas Profissionais"),
        titleTextStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color:Colors.deepPurple),
        ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            campo("Título", tituloController),
            campo("Descrição", descricaoController),
            campo("Prioridade", prioridadeController),
            campo("Nível de acesso", nivelAcessoController),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: inserirTarefa,
              child: const Text("Adicionar"),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: tarefas.isEmpty
                  ? const Center(child: Text("Nenhuma tarefa cadastrada", style: TextStyle(color: Colors.white70)))
                  : ListView.builder(
                      itemCount: tarefas.length,
                      itemBuilder: (context, index) {
                        final t = tarefas[index];
                        return Card(
                          color: Colors.grey[900],
                          child: ListTile(
                            title: Text(t["titulo"], style: const TextStyle(color: Colors.white)),
                            subtitle: Text(
                              "Prioridade: ${t["prioridade"]} | Nível de acesso: ${t["nivelAcesso"]}",
                              style: const TextStyle(color: Colors.white70),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.white),
                                  onPressed: () {
                                    editarTarefa(t);
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.redAccent),
                                  onPressed: () {
                                    excluirTarefa(t["id"]);
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
