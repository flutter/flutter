// Copyright 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('vm')
import 'package:io/io.dart';
import 'package:test/test.dart';

void main() {
  group('isExecutable', () {
    const files = 'test/_files';
    const shellIsExec = '$files/is_executable.sh';
    const shellNotExec = '$files/is_not_executable.sh';

    group('on shell scripts', () {
      test('should return true for "is_executable.sh"', () async {
        expect(await isExecutable(shellIsExec), isTrue);
      });

      test('should return false for "is_not_executable.sh"', () async {
        expect(await isExecutable(shellNotExec), isFalse);
      });
    }, testOn: '!windows');

    group('on shell scripts [windows]', () {
      test('should return true for "is_executable.sh"', () async {
        expect(await isExecutable(shellIsExec, isWindows: true), isTrue);
      });

      test('should return true for "is_not_executable.sh"', () async {
        expect(await isExecutable(shellNotExec, isWindows: true), isTrue);
      });
    });
  });
}
