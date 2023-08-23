// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io' as io show Directory, File;

import 'package:path/path.dart' as path;

// TODO(matanl): Replace this file by embedding in //.clang-tidy directly.
//
// By bringing in package:yaml, we can instead embed this in a key in the
// .clang-tidy file, read the checks in, and create a new .clang-tidy file (i.e.
// in /tmp/.../.clang-tidy) with the checks we want to run.
//
// However that requires a bit more work, so for now we just have this file.
const List<String> _kExcludeChecks = <String>[
  'performance-unnecessary-value-param',
];

/// Given a `.clang-tidy` file, rewrites it to exclude non-performant checks.
///
/// Returns a path to the rewritten file.
io.File rewriteClangTidyConfig(io.File input) {
  // Because the file is YAML, and we aren't using a YAML package to parse it,
  // instead we'll carefully remove the name of the check, optionally followed
  // by a comma and a newline.
  String contents = input.readAsStringSync();

  for (final String check in _kExcludeChecks) {
    // \s+{{CHECK}},?\n, with {{CHECK}} escaped for regex.
    final RegExp checkRegex = RegExp(r'\s+' + check + r',?\n');
    contents = contents.replaceAll(checkRegex, '');
  }

  final io.Directory tmpDir = io.Directory.systemTemp.createTempSync('clang_tidy');
  final io.File output = io.File(path.join(tmpDir.path, '.clang-tidy-for-githooks'));
  output.writeAsStringSync(contents);

  return output;
}
