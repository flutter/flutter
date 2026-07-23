// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert' as convert;

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
      expect(updateCompilationDatabase(input), equals(expected));
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
      expect(updateCompilationDatabase(input), equals(expected));
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
      expect(updateCompilationDatabase(input), equals(expected));
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
      expect(updateCompilationDatabase(input), equals(input));
      expect(stripCompilerWrappers(input), equals(input));
    });
  });

  group('expandSwiftcCommands', () {
    test('leaves standard compile_commands untouched if no swiftc.py or wrapper is present', () {
      const input = r'''
[
  {
    "file": "../../flutter/foo.cc",
    "directory": "/out/config",
    "command": "../../clang/bin/clang++ -c ../../flutter/foo.cc"
  }
]
''';
      expect(updateCompilationDatabase(input), equals(input));
      expect(stripCompilerWrappers(input), equals(input));
      expect(expandSwiftcCommands(input), equals(input));
    });

    test('translates swiftc.py flags and makes paths absolute', () {
      const input = r'''
[
  {
    "file": "../../flutter/bar.swift",
    "directory": "/out/config",
    "command": "python3 ../../flutter/tools/swiftc.py -module-name Bar -import-objc-header ../../flutter/header.h -target arm64-macos14.0 -I ../../flutter/include -D FOO_BAR ../../flutter/bar.swift"
  }
]
''';
      final String output = updateCompilationDatabase(input);
      final json = convert.jsonDecode(output) as List<dynamic>;
      expect(json.length, equals(1));
      final entry = json[0] as Map<String, dynamic>;
      expect(entry['file'], equals('/flutter/bar.swift'));
      final command = entry['command'] as String;
      expect(command, contains('swiftc'));
      expect(command, contains('-parse-as-library'));
      expect(command, contains('-module-name Bar'));
      expect(command, contains('-import-objc-header /flutter/header.h'));
      expect(command, contains('-target arm64-macos14.0'));
      expect(command, contains('-I /flutter/include'));
      expect(command, contains('-Xcc -I -Xcc /flutter/include'));
      expect(command, contains('-D FOO_BAR'));
      expect(command, contains('-Xcc -DFOO_BAR'));
    });

    test('-isystem is forwarded to clang only, never bare to swiftc', () {
      const input = r'''
[
  {
    "file": "../../flutter/bar.swift",
    "directory": "/out/config",
    "command": "python3 ../../flutter/tools/swiftc.py -module-name Bar -isystem ../../flutter/sysinclude ../../flutter/bar.swift"
  }
]
''';
      final String output = updateCompilationDatabase(input);
      final json = convert.jsonDecode(output) as List<dynamic>;
      final entry = json[0] as Map<String, dynamic>;
      final List<String> args = splitShellWords(entry['command'] as String);
      expect(
        args,
        equals(<String>[
          'swiftc',
          '-parse-as-library',
          '-module-name',
          'Bar',
          '-Xcc',
          '-isystem',
          '-Xcc',
          '/flutter/sysinclude',
          '/flutter/bar.swift',
        ]),
      );
    });

    test('-F and -Fsystem are forwarded to both swiftc and clang', () {
      const input = r'''
[
  {
    "file": "../../flutter/bar.swift",
    "directory": "/out/config",
    "command": "python3 ../../flutter/tools/swiftc.py -module-name Bar -F ../../flutter/frameworks -Fsystem../../flutter/sysframeworks ../../flutter/bar.swift"
  }
]
''';
      final String output = updateCompilationDatabase(input);
      final json = convert.jsonDecode(output) as List<dynamic>;
      final entry = json[0] as Map<String, dynamic>;
      final List<String> args = splitShellWords(entry['command'] as String);
      expect(
        args,
        equals(<String>[
          'swiftc',
          '-parse-as-library',
          '-module-name',
          'Bar',
          '-F',
          '/flutter/frameworks',
          '-Xcc',
          '-F',
          '-Xcc',
          '/flutter/frameworks',
          '-Fsystem/flutter/sysframeworks',
          '-Xcc',
          '-Fsystem/flutter/sysframeworks',
          '/flutter/bar.swift',
        ]),
      );
    });

    test('-D with a value ("key=value") is forwarded to clang only', () {
      const input = r'''
[
  {
    "file": "../../flutter/bar.swift",
    "directory": "/out/config",
    "command": "python3 ../../flutter/tools/swiftc.py -module-name Bar -D FOO=1 -DBAR=2 ../../flutter/bar.swift"
  }
]
''';
      final String output = updateCompilationDatabase(input);
      final json = convert.jsonDecode(output) as List<dynamic>;
      final entry = json[0] as Map<String, dynamic>;
      final List<String> args = splitShellWords(entry['command'] as String);
      expect(
        args,
        equals(<String>[
          'swiftc',
          '-parse-as-library',
          '-module-name',
          'Bar',
          '-Xcc',
          '-DFOO=1',
          '-Xcc',
          '-DBAR=2',
          '/flutter/bar.swift',
        ]),
      );
    });

    test('drops -import-objc-header when the value is an empty quoted string', () {
      const input = r'''
[
  {
    "file": "../../flutter/bar.swift",
    "directory": "/out/config",
    "command": "python3 ../../flutter/tools/swiftc.py -module-name Bar -import-objc-header \"\" -target arm64-macos14.0 ../../flutter/bar.swift"
  }
]
''';
      final String output = updateCompilationDatabase(input);
      final json = convert.jsonDecode(output) as List<dynamic>;
      final entry = json[0] as Map<String, dynamic>;
      final command = entry['command'] as String;
      expect(command, isNot(contains('-import-objc-header')));
      expect(command, contains('-module-name Bar'));
      expect(command, contains('-target arm64-macos14.0'));
    });

    test('leaves a malformed swiftc.py JSON block untouched', () {
      const input = r'''
[
  {
    "file": "../../flutter/bar.swift"
    "directory": "/out/config",
    "command": "python3 ../../flutter/tools/swiftc.py -module-name Bar ../../flutter/bar.swift"
  }
]
''';
      expect(expandSwiftcCommands(input), equals(input));
    });

    test('expands multi-file swiftc.py invocations into individual entries', () {
      const input = r'''
[
  {
    "file": "../../flutter/bar.swift",
    "directory": "/out/config",
    "command": "python3 ../../flutter/tools/swiftc.py -module-name Bar ../../flutter/bar.swift ../../flutter/baz.swift"
  }
]
''';
      final String output = updateCompilationDatabase(input);
      final json = convert.jsonDecode(output) as List<dynamic>;
      expect(json.length, equals(2));
      final entry1 = json[0] as Map<String, dynamic>;
      final entry2 = json[1] as Map<String, dynamic>;
      expect(entry1['file'], equals('/flutter/bar.swift'));
      expect(entry2['file'], equals('/flutter/baz.swift'));
      expect(entry1['command'], equals(entry2['command']));
    });
  });

  group('splitShellWords / quoteShellWord', () {
    test('splitShellWords and quoteShellWord work correctly', () {
      final List<String> words = splitShellWords("python3 'foo bar' \"baz qux\" -D \"\\\$FOO\"");
      expect(words, equals(<String>['python3', 'foo bar', 'baz qux', '-D', r'$FOO']));
      expect(quoteShellWord('foo bar'), equals("'foo bar'"));
      expect(quoteShellWord('simple'), equals('simple'));
    });

    test('splitShellWords handles edge cases gracefully', () {
      expect(splitShellWords(''), isEmpty);
      expect(splitShellWords('   \t  '), isEmpty);
      expect(splitShellWords(r'foo\'), equals(<String>['foo']));
      expect(quoteShellWord(''), equals("''"));
    });

    test('splitShellWords preserves an empty quoted argument as an empty string', () {
      expect(splitShellWords('-foo "" -bar'), equals(<String>['-foo', '', '-bar']));
      expect(splitShellWords("-foo '' -bar"), equals(<String>['-foo', '', '-bar']));
    });
  });
}
