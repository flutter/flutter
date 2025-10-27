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
}