import 'package:flutter/material.dart';
import 'package:flutter_unity_widget_example/screens/no_interaction_screen.dart';
import 'package:flutter_unity_widget_example/screens/orientation_screen.dart';

import 'menu_screen.dart';
import 'screens/api_screen.dart';
import 'screens/loader_screen.dart';
import 'screens/simple_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Unity Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => MenuScreen(),
        '/simple': (context) => SimpleScreen(),
        '/loader': (context) => LoaderScreen(),
        '/orientation': (context) => OrientationScreen(),
        '/api': (context) => ApiScreen(),
        '/none': (context) => NoInteractionScreen(),
      },
    );
  }
}
