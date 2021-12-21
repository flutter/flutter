import 'dart:html';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // Widget _buildContainer({required String text, Color? txt_color})
  // {
  //   return(
  //      Container(
  //               color: Colors.red,
  //               width: 100,
  //               height: 50, 
  //               child: Center(child: Text(text,style: TextStyle(color: txt_color),)), margin: EdgeInsets.all(10),
  //             )
  //   );
  // }

  Widget _subjects({required String name,required String letter})
  {
    return
    Center(
      child: (
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
          Container(
            width: 50,
            child:Text(name)),
          Container(
            child:Text(letter, style: TextStyle(color: Colors.purple[400]),))
        ],)
      ),
    );
  }


  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Column( 
            mainAxisAlignment: MainAxisAlignment.center, 
            children: [
              // _buildContainer(text:"Hello", txt_color:Colors.white),
              Container(
                margin: EdgeInsets.all(30),
                child: Text("Grade Calculator",
                style: TextStyle(color: Colors.purple[400]),),),
              _subjects(name: "Science", letter: "B"),
              _subjects(name: "Math", letter: "C"),
              _subjects(name: "Biology", letter: "A"),
              _subjects(name: "Arabic", letter: "F"),
              Container(
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(5), color: Colors.purple[400]),
                padding: EdgeInsets.all(10),
                margin: EdgeInsets.all(50),
                child: Text("Total GPA 🙄",
                style: TextStyle(color: Colors.white),),)
            ],
          )),
    )
      
    );
  }
}
