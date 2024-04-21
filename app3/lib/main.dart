import 'package:app3/widget/Myalert.dart';
import 'package:app3/widget/Myanimatedtext.dart';
import 'package:app3/widget/Mybottomnavigation.dart';
import 'package:app3/widget/Mybottomsheet.dart';
import 'package:app3/widget/Myderopdown.dart';
import 'package:app3/widget/Mydismissible.dart';
import 'package:app3/widget/Mydrawer.dart';
import 'package:app3/widget/Myforms1.dart';
import 'package:app3/widget/Mygrid1.dart';
import 'package:app3/widget/Myimage.dart';
import 'package:app3/widget/Myforms.dart';
import 'package:app3/widget/Mystackandpos.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(new Myapp());
}

class Myapp extends StatelessWidget {
  const Myapp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.blue,
      ),
      home: Mystack(),
    );
  }
}
