import 'package:flutter/material.dart';
import 'theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tema Personalizado',
      theme: ThemeData(
        colorScheme: MaterialTheme.lightScheme(),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: MaterialTheme.darkScheme(),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system, // alterna automaticamente claro/escuro
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Exemplo de Tema'),
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(
            backgroundColor: scheme.primaryContainer,
            foregroundColor: scheme.onPrimaryContainer,
          ),
          child: const Text('Botão com tema'),
        ),
      ),
    );
  }
}import 'package:flutter/material.dart';
@override
Widget build(BuildContext context) {
return MaterialApp(
debugShowCheckedModeBanner: false,
title: 'Flutter Demo',
theme: ThemeData(
colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
useMaterial3: true,
),
home: const HomePage(),
);
}
}

class HomePage extends StatelessWidget {
const HomePage({super.key});

@override
Widget build(BuildContext context) {
return Scaffold(
appBar: AppBar(
title: const Text('Menu Principal'),
backgroundColor: Colors.deepPurple.shade200,
),
drawer: Drawer(
child: ListView(
children: [
const DrawerHeader(
child: Text('Navegação', style: TextStyle(fontSize: 22)),
),
ListTile(
leading: const Icon(Icons.pages),
title: const Text('Componentes'),
onTap: () {
Navigator.pop(context);
Navigator.push(
context,
MaterialPageRoute(builder: (_) => const ComponentsPage()),
);
},
),
ListTile(
leading: const Icon(Icons.person),
title: const Text('Alunos'),
onTap: () {
Navigator.pop(context);
Navigator.push(
context,
MaterialPageRoute(builder: (_) => const StudentsPage()),
);
},
),
],
),
),
body: const Center(
child: Text("Selecione uma opção no menu"),
),
);
}
}
