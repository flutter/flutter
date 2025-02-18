import 'package:flutter/material.dart';

void main() {
  runApp(
    MaterialApp(
      home: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[
                Color.fromARGB(255, 26, 2, 80),
                Color.fromARGB(55, 9, 1, 24),
              ],
            ),
          ),
          child: const Center(
            child: Text( 
            "Hello World!", 
            style: TextStyle( 
              color: Colors.white,
              fontSize:34
            )
            )
            ),

        ),
      ),
    ),
  );
} 
