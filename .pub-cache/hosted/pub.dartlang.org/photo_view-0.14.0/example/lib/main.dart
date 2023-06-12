import 'package:flutter/material.dart';
import './screens/home_screen.dart';

void main() => runApp(MyApp());

ThemeData theme = ThemeData(
  primaryColor: Colors.black,
  backgroundColor: Colors.white10,
  fontFamily: 'PTSans',
);

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Photo View Example App',
      theme: theme,
      home: Scaffold(
        body: HomeScreen(),
      ),
    );
  }
}
