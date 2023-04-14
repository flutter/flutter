import 'package:flutter/material.dart';

void main() => runApp(const MyApp()); // main method

class MyApp extends StatefulWidget { // class 1
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> { // class 2 
TextEditingController textEditingController =  TextEditingController();
String _value="";
     
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Material App',
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Material App Bar'),
        ),
        body:  Center(
          child: Column(
            children: [
              const Text("Enter the text below"),
              TextField(controller: textEditingController,),
              ElevatedButton(onPressed: _pressMe, child: const Text("Press Me")),
              Text(_value)
            ],
        ),)
      ),
    );
  }

  void _pressMe() {
    //ignore : avoid_print
    print('Hello World');
    setState((){
      _value = textEditingController.text;
    });
  }
}