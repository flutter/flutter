// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

// This standalone SDK-only probe must also work without a package configuration.
// ignore: avoid_relative_lib_imports
import '../lib/src/linux/gtk4_capabilities.dart';

// Run in a separate process: GTK majors must not share a process. Do not call
// gtk_init or open a display; doctor must also work over SSH and in headless CI.
void main() {
  final DynamicLibrary gtk;
  try {
    gtk = DynamicLibrary.open('libgtk-4.so.1');
  } on ArgumentError {
    stdout.writeln(jsonEncode(<String, Object>{'available': false}));
    return;
  }
  int version(String symbol) => gtk.lookupFunction<Uint32 Function(), int Function()>(symbol)();
  stdout.writeln(
    jsonEncode(<String, Object>{
      'available': true,
      'version': <int>[
        version('gtk_get_major_version'),
        version('gtk_get_minor_version'),
        version('gtk_get_micro_version'),
      ],
      'symbols': <String>[
        for (final capability in gtk4Capabilities)
          for (final symbol in capability.symbols)
            if (gtk.providesSymbol(symbol)) symbol,
      ],
    }),
  );
}
