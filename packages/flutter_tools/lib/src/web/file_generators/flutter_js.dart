// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:path/path.dart' as path;

import '../../globals.dart' as globals;
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
  return globals.localFileSystem.file(flutterJsPath).readAsStringSync();
}
