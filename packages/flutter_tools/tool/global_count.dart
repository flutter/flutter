// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';
import 'package:path/path.dart' as path;

/// Count the number of libraries that import globals.dart in lib and test.
///
/// This must be run from the flutter_tools project root directory.
void main() {
  final Directory sources = Directory(path.join(Directory.current.path, 'lib'));
  final Directory tests = Directory(path.join(Directory.current.path, 'test'));
  final int sourceGlobals = countGlobalImports(sources);
  final int testGlobals = countGlobalImports(tests);
  print('lib/ contains $sourceGlobals libraries with global usage');
  print('test/ contains $testGlobals libraries with global usage');
}

final RegExp globalImport = RegExp("import.*globals.dart' as globals;");

int countGlobalImports(Directory directory) {
  int count = 0;
  for (final FileSystemEntity file in directory.listSync(recursive: true)) {
    if (!file.path.endsWith('.dart') || file is! File) {
      continue;
    }
    final bool hasImport = file.readAsLinesSync().any((String line) {
      return globalImport.hasMatch(line);
    });
    if (hasImport) {
      count += 1;
    }
  }
  return count;
}
