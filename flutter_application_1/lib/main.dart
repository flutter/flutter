import 'package:flutter_application_1/gradient_container.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(
  MaterialApp(
      home: Scaffold(
        body: GradientContainer(Alignment.topLeft, Alignment.bottomRight),
      ),
    ),
  );
} 
