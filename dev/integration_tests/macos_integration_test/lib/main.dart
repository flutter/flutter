import 'package:flutter/material.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  int _count = 0;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Column(
          children: [
            Text('Count is $_count'),
            TextButton(
                onPressed: () {
                  setState(() {
                    _count++;
                  });
                },
                child: Text('Increment')),
          ],
        ),
      ),
    );
  }
}
