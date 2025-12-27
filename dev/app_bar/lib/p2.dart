import 'package:flutter/material.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        appBar: AppBar(tite;Text("New App Bar")  ),
        body: Center(
          child: Text('Hello World!'),
        ),
      ),
    );
  }
}
