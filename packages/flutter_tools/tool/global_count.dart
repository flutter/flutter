// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';
import 'package:path/path.dart' as path;

/// Count the number of libraries that import globals_null_migrated.dart and globals.dart in lib and test.
///
/// This must be run from the flutter_tools project root directory.
void main() {
  final Directory sources = Directory(path.join(Directory.current.path, 'lib'));
  final Directory tests = Directory(path.join(Directory.current.path, 'test'));
  countGlobalImports(sources);
  countGlobalImports(tests);
}

final RegExp globalImport = RegExp(r"import.*(?:globals|globals_null_migrated)\.dart' as globals;");
final RegExp globalNullUnsafeImport = RegExp('import.*globals.dart\' as globals;');

void countGlobalImports(Directory directory) {
  int count = 0;
  int nullUnsafeImportCount = 0;
  for (final FileSystemEntity file in directory.listSync(recursive: true)) {
    if (!file.path.endsWith('.dart') || file is! File) {
      continue;
    }
    final List<String> fileLines = file.readAsLinesSync();
    final bool hasImport = fileLines.any((String line) {
      return globalImport.hasMatch(line);
    });
    if (hasImport) {
      count += 1;
    }
    final bool hasUnsafeImport = fileLines.any((String line) {
      return globalNullUnsafeImport.hasMatch(line);
    });
    if (hasUnsafeImport) {
      nullUnsafeImportCount += 1;
    }
  }
  print('${path.basename(directory.path)} contains $count libraries with global usage ($nullUnsafeImportCount unsafe)');
}
