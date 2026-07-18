// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:engine_build_configs/src/update_compdb.dart';
import 'package:test/test.dart';

void main() {
  group('stripCompilerWrappers', () {
    test('strips C++ compiler wrapper prefixes before clang++', () {
      const input = r'''
[
  {
    "file": "../../flutter/foo.cc",
    "directory": "/out/config",
    "command": "/path/to/rewrapper --cfg=... ../../clang/bin/clang++ -c ../../flutter/foo.cc"
  }
]
''';
      const expected = r'''
[
  {
    "file": "../../flutter/foo.cc",
    "directory": "/out/config",
    "command": "../../clang/bin/clang++ -c ../../flutter/foo.cc"
  }
]
''';
      expect(stripCompilerWrappers(input), equals(expected));
    });

    test('strips C compiler wrapper prefixes before clang', () {
      const input = r'''
[
  {
    "file": "../../flutter/foo.c",
    "directory": "/out/config",
    "command": "/path/to/rewrapper --cfg=... ../../clang/bin/clang -c ../../flutter/foo.c"
  }
]
''';
      const expected = r'''
[
  {
    "file": "../../flutter/foo.c",
    "directory": "/out/config",
    "command": "../../clang/bin/clang -c ../../flutter/foo.c"
  }
]
''';
      expect(stripCompilerWrappers(input), equals(expected));
    });

    test('does not truncate the command at a later -Xclang flag', () {
      const input = r'''
[
  {
    "file": "../../flutter/foo.cc",
    "directory": "/out/config",
    "command": "/path/to/rewrapper --cfg=... ../../clang/bin/clang++ -Xclang -fdebug-compilation-dir -Xclang . -c ../../flutter/foo.cc"
  }
]
''';
      const expected = r'''
[
  {
    "file": "../../flutter/foo.cc",
    "directory": "/out/config",
    "command": "../../clang/bin/clang++ -Xclang -fdebug-compilation-dir -Xclang . -c ../../flutter/foo.cc"
  }
]
''';
      expect(stripCompilerWrappers(input), equals(expected));
    });

    test('does not truncate the command at a source file whose name contains "clang"', () {
      const input = r'''
[
  {
    "file": "../../flutter/testing/clang_static_analyzer_wrapper_test.cc",
    "directory": "/out/config",
    "command": "../../clang/bin/clang++ -c ../../flutter/testing/clang_static_analyzer_wrapper_test.cc -o out.o"
  }
]
''';
      expect(stripCompilerWrappers(input), equals(input));
    });
  });
}
