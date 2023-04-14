import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  TextEditingController textEditingController =  TextEditingController();
  TextEditingController textEditingController2 =  TextEditingController();
  double numA = 0, numB = 0, result = 0;  //variable

  @override
  Widget build(BuildContext context) {
    return MaterialApp( // tempat buat theme semua 
      title: 'Material App',
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Material App Bar'),
        ),
        body: Center(
          child: Column(children: [  mainAxisAlignment: MainAxisAlignment.spaceAround,
            TextField(controller: textEditingController,),
            TextField(controller: textEditingController2,),
              ElevatedButton(onPressed: _calculate, child: const Text("Calculate")),
              Text('Result: ' + result.toString())
          ],)
        ),
      ),
    );
  }

  void _calculate() {
    setState(() {
      numA = double.parse(textEditingController.text);
      numB = double.parse(textEditingController2.text);
      result = numA + numB;
    });
  }
}

Row ( 
                mainAxisAllignment :MainAxisAlignment.spaceBetween, 
                children : [
              ElevatedButton(onPressed: onPressed, child: const Text("4")),
              ElevatedButton(onPressed: onPressed, child: const Text("5")),
              ElevatedButton(onPressed: onPressed, child: const Text("6")),