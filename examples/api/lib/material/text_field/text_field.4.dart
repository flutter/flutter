import 'package:flutter/material.dart';

void main() {
  runApp(const TextFieldExampleApp());
}

class TextFieldExampleApp extends StatelessWidget {
  const TextFieldExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: const TextFieldExample());
  }
}

class TextFieldExample extends StatelessWidget {
  const TextFieldExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: const TextField(
        decoration: InputDecoration(
          labelText: 'TextField',
          errorText: 'Error text',
          contentPadding: EdgeInsets.all(5),
          errorPadding: EdgeInsets.all(10),
        ),
      ),
    );
  }
}
