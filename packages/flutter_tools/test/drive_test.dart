// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:file/file.dart';
import 'package:flutter_tools/src/commands/drive.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/globals.dart';
import 'package:test/test.dart';

import 'src/common.dart';
import 'src/context.dart';
import 'src/mocks.dart';

main() => defineTests();

defineTests() {
  group('drive', () {
    setUp(() {
      useInMemoryFileSystem();
    });

    tearDown(() {
      restoreFileSystem();
    });

    testUsingContext('returns 1 when test file is not found', () {
      DriveCommand command = new DriveCommand();
      applyMocksToCommand(command);

      List<String> args = [
        'drive',
        '--target=/some/app/test/e2e.dart',
      ];
      return createTestCommandRunner(command).run(args).then((int code) {
        expect(code, equals(1));
        BufferLogger buffer = logger;
        expect(buffer.errorText,
            contains('Test file not found: /some/app/test/e2e_test.dart'));
      });
    });

    testUsingContext('returns 1 when app fails to run', () async {
      DriveCommand command = new DriveCommand.custom(runAppFn: expectAsync(() {
        return new Future.value(1);
      }));
      applyMocksToCommand(command);

      String testApp = '/some/app/test/e2e.dart';
      String testFile = '/some/app/test/e2e_test.dart';

      MemoryFileSystem memFs = fs;
      await memFs.file(testApp).writeAsString('main() {}');
      await memFs.file(testFile).writeAsString('main() {}');

      List<String> args = [
        'drive',
        '--target=$testApp',
      ];
      return createTestCommandRunner(command).run(args).then((int code) {
        expect(code, equals(1));
        BufferLogger buffer = logger;
        expect(buffer.errorText, contains(
          'Application failed to start. Will not run test. Quitting.'
        ));
      });
    });

    testUsingContext('returns 0 when test ends successfully', () async {
      String testApp = '/some/app/test/e2e.dart';
      String testFile = '/some/app/test/e2e_test.dart';

      DriveCommand command = new DriveCommand.custom(
        runAppFn: expectAsync(() {
          return new Future<int>.value(0);
        }),
        runTestsFn: expectAsync((List<String> testArgs) {
          expect(testArgs, [testFile]);
          return new Future<Null>.value();
        }),
        stopAppFn: expectAsync(() {
          return new Future<int>.value(0);
        })
      );
      applyMocksToCommand(command);

      MemoryFileSystem memFs = fs;
      await memFs.file(testApp).writeAsString('main() {}');
      await memFs.file(testFile).writeAsString('main() {}');

      List<String> args = [
        'drive',
        '--target=$testApp',
      ];
      return createTestCommandRunner(command).run(args).then((int code) {
        expect(code, equals(0));
        BufferLogger buffer = logger;
        expect(buffer.errorText, isEmpty);
      });
    });
  });
}
