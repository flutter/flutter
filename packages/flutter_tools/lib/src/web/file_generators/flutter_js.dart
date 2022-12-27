// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io' as io;

import 'package:path/path.dart' as path;

import 'helper.dart';

/// Generates the flutter.js file.
///
/// flutter.js should be completely static, so **do not use any parameter or
/// environment variable to generate this file**.
String generateFlutterJsFile() {
  final String flutterJsPath = path.join(
    fileGeneratorsRoot,
    'js',
    'flutter.js',
  );
  return io.File(flutterJsPath).readAsStringSync();
}
