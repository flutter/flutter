import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  TextEditingController textEditingController =  TextEditingController();
  String val="";

  @override
  Widget build(BuildContext context) {
    return MaterialApp( // bpleh tambah theme and all
      theme : ThemeData(primarySwatch: Colors.pink),
      title: 'Material App',
      home: Scaffold(
        appBar: AppBar(
          title: const Text('My Calculator'),
        ),
        body:  Center(
          child: Column( crossAxisAlignment :CrossAxisAlignment.center, 
          children:[
          SizedBox(
            width : 300,
            child : TextField( 
              decoration : InputDecoration( hintText: ' ',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.0))),
                )),  //textField // Sized Box
          const SizedBox(
          height : 16,
          ), //SizedBox
          Container( padding: const EdgeInsets.all(16),
          height : 250,
          width : 250,
          color : Color.fromARGB(255, 233, 187, 202),
          child : Column( children : [ 
              Row ( 
               mainAxisAlignment :MainAxisAlignment.spaceBetween,  
                children : [
              ElevatedButton(
                onPressed:() { 
                onPressed("1");
                },
                child: const Text('1')),

                ElevatedButton(
                onPressed:() { 
                onPressed("2");
                },
                child: const Text("2")),

                ElevatedButton(
                onPressed:() { 
                onPressed("3");
                },
                child: const Text("3")),
                
                ], ), // row 

                Row( mainAxisAlignment: MainAxisAlignment.spaceAround,
                children : [
                ElevatedButton(
                onPressed:() { 
                onPressed("4");
                },
                child: const Text("4")),

                ElevatedButton(
                onPressed:() { 
                onPressed("5");
                },
                child: const Text("5")),

                ElevatedButton(
                onPressed:() { 
                onPressed("6");
                },
                child: const Text("6")),

                 ], ), // row 

                 Row( mainAxisAlignment: MainAxisAlignment.spaceAround,
                children : [

                ElevatedButton(
                onPressed:() { 
                onPressed("7");
                },
                child: const Text("7")),

                ElevatedButton(
                onPressed:() { 
                onPressed("8");
                },
                child: const Text("8")),

                ElevatedButton(
                onPressed:() { 
                onPressed("9");
                },
                child: const Text("9")),
                
                ], ), // row

                Row( mainAxisAlignment: MainAxisAlignment.spaceAround,
                children : [

                ElevatedButton(
                onPressed:() { 
                onPressed("0");
                },
                child: const Text("0")),
                ], ), // row 

          ]), //column
        )]) // container
  ), //column
  ), // center
  ); // scaffold // materialapp
}

    

  void onPressed(String s) {
    val = val + s;
    textEditingController.text = val;
   setState(() {
     
   });
    
      }
    
  
}
