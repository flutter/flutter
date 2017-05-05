import 'package:flutter/material.dart';

// Tests that importing files with unusal casing in the file name works with hot reload.
import 'Import_With_Strange_Casing.dart';

void main() {
  runApp(new MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Import Test App',
      theme: new ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const Scaffold(
        body: const Center(
          child: const Text('$importWithStrangeCasing'),
        ),
      )
    );
  }
}
