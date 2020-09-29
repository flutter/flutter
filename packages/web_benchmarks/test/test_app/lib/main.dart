import 'package:flutter/material.dart';

import 'homepage.dart';
import 'aboutpage.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: 'home',
      routes: {
        'home': (_) => HomePage(title: 'Flutter Demo Home Page'),
        'about': (_) => AboutPage(),
      },
    );
  }
}
