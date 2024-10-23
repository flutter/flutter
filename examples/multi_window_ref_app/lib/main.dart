import 'package:flutter/material.dart';

import 'app/main_window.dart';

void main() {
  runWidget(MultiWindowApp(initialWindows: [
    (BuildContext context) => createRegular(
        context: context,
        size: const Size(800, 600),
        builder: (context) {
          return const MaterialApp(home: MainWindow());
        })
  ]));
}
