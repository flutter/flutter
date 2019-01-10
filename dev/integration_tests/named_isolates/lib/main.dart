import 'dart:ui' as ui;
import 'package:flutter/material.dart';

// named_isolates_test depends on these values.
const String _kFirstIsolateName = 'first isolate name';
const String _kSecondIsolateName = 'second isolate name';

void first() {
  _run(_kFirstIsolateName);
}

void second() {
  _run(_kSecondIsolateName);
}

void _run(String name) {
  ui.window.setIsolateDebugName(name);
  runApp(Center(child: Text(name, textDirection: TextDirection.ltr)));
}

// `first` and `second` are the actual entrypoints to this app, but dart specs
// require a main function.
void main() { }
