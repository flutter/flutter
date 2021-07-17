// Hello World Program for Bengalees
// নমস্কার বাঙালী
import 'package:flutter/material.dart';
void main() => runApp(MaterialApp(debugShowCheckedModeBanner: false, title: 'নমস্কার বাঙালী', home: Home()));

class Home extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: Text('নমস্কার বাঙালী'),), body: Center(child: Text('নমস্কার বিশ্ব 🙏 ', style: TextStyle(fontSize: 40, fontWeight: FontWeight.w800),)));
  }
}
// Contributed By - Anirban Chand
