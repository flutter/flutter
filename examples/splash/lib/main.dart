import 'package:flutter/material.dart';

void main() => runApp(MyApp());

void loop() {
  while (true) {
    /* Do nothing */
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Material App',
      home: Scaffold(
        appBar: AppBar(title: Text('Material App Bar')),
        body: Center(
          child: GestureDetector(
            onTap: loop,
            child: Container(child: Text('Hello ssBar')),
          ),
        ),
      ),
    );
  }
}
