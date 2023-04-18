// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../../globals.dart' as globals;

/// Generates the flutter.js file.
///
/// flutter.js should be completely static, so **do not use any parameter or
/// environment variable to generate this file**.
String generateFlutterJsFile(String fileGeneratorsPath) {
  final String flutterJsPath = globals.localFileSystem.path.join(
    fileGeneratorsPath,
    'js',
    'flutter.js',
  );
  return globals.localFileSystem.file(flutterJsPath).readAsStringSync();
}
