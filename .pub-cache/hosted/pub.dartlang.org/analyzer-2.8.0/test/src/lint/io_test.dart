// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:analyzer/src/lint/io.dart';
import 'package:test/test.dart';

main() {
  defineTests();
}

defineTests() {
  // TODO: redefine tests

//  group('commandline args', () {
//    var mockFile = new File('foo.dart');
//    when(mockFile.absolute).thenReturn(mockFile);
//
//    var options = new LinterOptions(() => []);
//    var mockLinter = new MockLinter();
//    when(mockLinter.options).thenReturn(options);
//
//    lintFile(mockFile,
//        dartSdkPath: '/path/to/sdk',
//        packageRoot: '/my/pkgs',
//        linter: mockLinter);
//
//    test('dartSdkPath', () {
//      expect(options.dartSdkPath, equals('/path/to/sdk'));
//      expect(options.packageRootPath, equals('/my/pkgs'));
//    });
//
//    test('packageRoot', () {
//      expect(options.dartSdkPath, equals('/path/to/sdk'));
//      expect(options.packageRootPath, equals('/my/pkgs'));
//    });
//
//    test('exception handling', () {
//      var mockErr = new MockIOSink();
//      std_err = mockErr;
//      when(mockLinter.lintFiles(any)).thenAnswer((_) => throw 'err');
//      expect(lintFiles([mockFile], linter: mockLinter), isFalse);
//      verify(std_err.writeln(any)).called(1);
//    });
//  });

  group('processing', () {
    group('files', () {
      test('dart', () {
        var file = File('foo.dart');
        expect(isLintable(file), isTrue);
      });
      test('pubspec', () {
        var file = File('pubspec.yaml');
        expect(isLintable(file), isTrue);
      });
      test('_pubspec', () {
        // Analyzable for testing purposes
        var file = File('_pubspec.yaml');
        expect(isLintable(file), isTrue);
      });
      test('text', () {
        var file = File('foo.txt');
        expect(isLintable(file), isFalse);
      });
      test('hidden dirs', () {
        expect(isInHiddenDir('.foo/'), isTrue);
        expect(isInHiddenDir('.foo/bar'), isTrue);
      });
    });
  });

  // TODO(brianwilkerson) Rewrite this to use a memory resource provider.
//  group('collecting', () {
//    group('files', () {
//      test('basic', () {
//        expect(
//            collectFiles(p.join('test', '_data', 'p1')).map((f) => f.path),
//            unorderedEquals([
//              p.join('test', '_data', 'p1', 'p1.dart'),
//              p.join('test', '_data', 'p1', '_pubspec.yaml'),
//              p.join('test', '_data', 'p1', 'src', 'p2.dart')
//            ]));
//      });
//    });
//  });
}
