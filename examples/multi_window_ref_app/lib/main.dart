import 'package:flutter/material.dart';
import 'app/main_window.dart';

void main() {
  runWidget(WindowingApp(children: <Widget>[
    RegularWindow(
        preferredSize: const Size(800, 600),
        child: const MaterialApp(home: MainWindow()))
  ]));
}
