import 'package:flutter/material.dart';
import 'package:vector_graphics/vector_graphics.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        body: Center(
          child: VectorGraphic(loader: AssetBytesLoader('assets/test.svg')),
        ),
      ),
    );
  }
}
