import 'dart:ui' as ui;
import 'package:flutter/material.dart';

// named_isolates_test depends on these values.
const String _kFirstIsolateName = 'first isolate name';
const String _kSecondIsolateName = 'second isolate name';

void first() {
  main(_kFirstIsolateName);
}

void second() {
  main(_kSecondIsolateName);
}

void main(String name) {
  ui.window.setIsolateDebugName(name);
  runApp(Center(child: Text(name, textDirection: TextDirection.ltr)));
}