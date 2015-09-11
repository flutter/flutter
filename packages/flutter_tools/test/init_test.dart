// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:mockito/mockito.dart';
import 'package:path/path.dart' as p;
import 'package:sky_tools/src/init.dart';
import 'package:test/test.dart';

import 'src/common.dart';

main() => defineTests();

defineTests() {
  group('', () {
    Directory temp;

    setUp(() {
      temp = Directory.systemTemp.createTempSync('sky_tools');
    });

    tearDown(() {
      temp.deleteSync(recursive: true);
    });

    // Verify that we create a project that is well-formed.
    test('init sky-simple', () async {
      InitCommandHandler handler = new InitCommandHandler();
      MockArgResults results = new MockArgResults();
      when(results['help']).thenReturn(false);
      when(results['pub']).thenReturn(true);
      when(results.wasParsed('out')).thenReturn(true);
      when(results['out']).thenReturn(temp.path);
      await handler.processArgResults(results);
      String path = p.join(temp.path, 'lib/main.dart');
      expect(new File(path).existsSync(), true);
      ProcessResult exec = Process.runSync(
          'dartanalyzer', ['--fatal-warnings', path],
          workingDirectory: temp.path);
      expect(exec.exitCode, 0);
    });
  });
}
