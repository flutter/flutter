// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:analyzer/instrumentation/instrumentation.dart';

/// An [InstrumentationLogger] that writes to a file (as opposed to an external
/// source or in-memory source etc.)
class FileInstrumentationLogger implements InstrumentationLogger {
  final String filePath;
  late final IOSink _sink;

  FileInstrumentationLogger(this.filePath) {
    File file = File(filePath);
    _sink = file.openWrite();
  }

  @override
  void log(String message) {
    _sink.writeln(message);
  }

  @override
  Future shutdown() async {
    await _sink.close();
  }
}
