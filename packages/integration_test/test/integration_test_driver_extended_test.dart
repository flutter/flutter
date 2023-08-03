// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;

final String bat = Platform.isWindows ? '.bat' : '';
final String _flutterBin =
    path.join(Directory.current.parent.parent.path, 'bin', 'flutter$bat');

void main() {
  group('integrationDriver', () {
    test('write response data when all test pass', () async {
      final ProcessResult process = await Process.run(_flutterBin, <String>[
        'test',
        '--machine',
        path.join('test', 'data', 'integration_test_driver_extended',
            'pass_test_script.dart')
      ]);
      expect(process.stdout, contains('responseDataCallback called'));
    });

    test(
        'write response data when test fail and writeResponseOnFailure is true',
        () async {
      final ProcessResult process = await Process.run(_flutterBin, <String>[
        'test',
        '--machine',
        path.join('test', 'data', 'integration_test_driver_extended',
            'fail_test_write_response_script.dart')
      ]);
      expect(process.stdout, contains('responseDataCallback called'));
    });

    test(
        'write response data when test fail and writeResponseOnFailure is false',
        () async {
      final ProcessResult process = await Process.run(_flutterBin, <String>[
        'test',
        '--machine',
        path.join('test', 'data', 'integration_test_driver_extended',
            'fail_test_not_write_response_script.dart')
      ]);
      expect(process.stdout, isNot(contains('responseDataCallback called')));
    });
  });
}
