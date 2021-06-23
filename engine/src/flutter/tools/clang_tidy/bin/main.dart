// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.12

// Runs clang-tidy on files with changes.
//
// Basic Usage:
// dart bin/main.dart --compile-commands <path to compile_commands.json> \
//                    --repo <path to git repository> \
//
// User environment variable FLUTTER_LINT_ALL to run on all files.

import 'package:clang_tidy/clang_tidy.dart';

Future<int> main(List<String> arguments) async {
  return ClangTidy.fromCommandLine(arguments).run();
}
