import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  Widget _buildContainer({required String text, Color? txt_color})
  {
    return(
       Container(
                color: Colors.red,
                width: 100,
                height: 50, 
                child: Center(child: Text(text,style: TextStyle(color: txt_color),)), margin: EdgeInsets.all(10),
              )
    );
  }



  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Row( 
            mainAxisAlignment: MainAxisAlignment.center, 
            children: [
              _buildContainer(text:"Hello", txt_color:Colors.white),
            ],
          )),
    )
      
    );
  }
}
