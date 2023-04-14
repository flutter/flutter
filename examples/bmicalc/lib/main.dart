import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget { //MyApp -> 
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Material App',
        theme: ThemeData (
        primarySwatch: Colors.yellow,
        ),
        home : const SplashPage());
  }
}

class SplashPage extends StatefulWidget {  //use 'stf' as shortcut // tukar class name 
    const SplashPage({super.key});
  
  @override
  _SplashPageState createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  Widget build(BuildContext context) {  //circularprocessindicator -> utk mcm button loading tu
    return Scaffold(
        body: Center(
          child: 
          Row( mainAxisAlignment: MainAxisAlignment.spaceAround,
           
    // TODO: implement build
    throw UnimplementedError();
  }
}
}
