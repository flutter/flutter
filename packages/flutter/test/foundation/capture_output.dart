// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/src/foundation/_error_dumper_io.dart'
    if (dart.library.js_interop) 'package:flutter/src/foundation/_error_dumper_web.dart';

List<String> captureOutput(VoidCallback fn) {
  final List<String> log = <String>[];

  bool capturedFromWeb = false;
  bool capturedFromZone = false;

  // On the web, error messages are directed to `console.error` and it's not possible to capture
  // them via `print` overrides. Therefore, we add a listener to capture those messages.
  ErrorToConsoleDumper.addWebDumpListener((String message) {
    capturedFromWeb = true;
    log.addAll(message.split('\n'));
  });

  runZoned<void>(
    fn,
    zoneSpecification: ZoneSpecification(
      print: (Zone self, ZoneDelegate parent, Zone zone, String line) {
        capturedFromZone = true;
        log.add(line);
      },
    ),
  );

  ErrorToConsoleDumper.clearWebDumpListeners();

  if (capturedFromWeb && capturedFromZone) {
    throw FlutterError(
      'Output was captured from both the web error dumper and the zone print override. '
      'This indicates a problem with the test setup.',
    );
  }

  return log;
}
