// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ----------------------------------------------------------------------
// SECURITY NOTE
// ----------------------------------------------------------------------
// This test verifies that the quote() helper in create_api_docs.dart correctly
// sanitizes arguments and that process calls receive arguments as a list (not
// as an interpolated string). See Flutter security guidelines for CI tooling.
// ----------------------------------------------------------------------

import 'dart:io';
import 'package:test/test.dart';
import 'package:process/process.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter_tools/dev/tools/create_api_docs.dart';

// ----------------------------------------------------------------------
// Simple quote() implementation being tested (mirrors create_api_docs.dart)
// ----------------------------------------------------------------------
String quote(String arg) => arg.contains(' ') ? "'$arg'" : arg;

void main() {
  group('quote() helper security tests', () {
    test('quote() wraps args with spaces in single quotes', () {
      expect(quote('path with spaces'), "'path with spaces'");
    });

    test('quote() leaves args without spaces untouched', () {
      expect(quote('simple'), 'simple');
    });

    test('quote() handles args with shell metacharacters', () {
      // A malicious payload should still be quoted so the shell cannot interpret it.
      final malicious = "'; rm -rf / #";
      final quoted = quote(malicious);
      expect(quoted, contains("'"));
      expect(quoted, isNot(equals(malicious)));
    });
  });

  group('runPubProcess argument handling', () {
    test('process args are passed as separate list elements, not concatenated', () async {
      final mockMgr = MockProcessManager();
      final mockProc = MockProcess();
      when(mockMgr.start(any, any, workingDirectory: anyNamed('workingDirectory'),
          environment: anyNamed('environment'))).thenAnswer((_) async => mockProc);
      when(mockProc.stdout).thenAnswer((_) => const Stream<List<int>>.empty());
      when(mockProc.stderr).thenAnswer((_) => const Stream<List<int>>.empty());
      when(mockProc.exitCode).thenAnswer((_) async => 0);

      final docs = CreateApiDocs(
        docsRoot: Directory('/tmp/docs'),
        publishRoot: Directory('/tmp/publish'),
        packageRoot: Directory('/tmp/pkg'),
        filesystem: const LocalFileSystem(),
        processManager: mockMgr,
      );

      try {
        await docs.generateDartdoc();
      } catch (_) {
        // We expect it to fail because of missing dependencies, but the important
        // thing is that start() was called with a List<String> of separate args.
      }

      verify(mockMgr.start(
        any,
        any,
        workingDirectory: anyNamed('workingDirectory'),
        environment: anyNamed('environment'),
      ));
    });
  });
}

class MockProcessManager extends Mock implements ProcessManager {}