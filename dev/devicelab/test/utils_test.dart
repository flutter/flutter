// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io' as io;
import 'package:flutter_devicelab/framework/utils.dart';
import 'package:path/path.dart' as path;

import 'common.dart';

void main() {
  group('grep', () {
    test('greps lines', () {
      expect(grep('b', from: 'ab\ncd\nba'), <String>['ab', 'ba']);
    });

    test('understands RegExp', () {
      expect(grep(RegExp('^b'), from: 'ab\nba'), <String>['ba']);
    });
  });

  group('parse service', () {
    const badOutput = 'No uri here';
    const sampleOutput =
        'A Dart VM Service on '
        'Pixel 3 XL is available at: http://127.0.0.1:9090/LpjUpsdEjqI=/';

    test('uri', () {
      expect(parseServiceUri(sampleOutput), Uri.parse('http://127.0.0.1:9090/LpjUpsdEjqI=/'));
      expect(parseServiceUri(badOutput), null);
    });

    test('port', () {
      expect(parseServicePort(sampleOutput), 9090);
      expect(parseServicePort(badOutput), null);
    });
  });

  group('engine environment declarations', () {
    test('localEngine', () {
      expect(localEngineFromEnv, null);
      expect(localEngineHostFromEnv, null);
      expect(localEngineSrcPathFromEnv, null);
    });
  });

  group('filesystem safety guard', () {
    test('isolates modifications to system temp directory', () {
      final tempFile = io.File(
        path.join(io.Directory.systemTemp.path, 'devicelab_fs_guard_test_safe.txt'),
      );
      addTearDown(() {
        if (tempFile.existsSync()) {
          tempFile.deleteSync();
        }
      });
      // Writing under system temp should succeed
      tempFile.writeAsStringSync('safe-devicelab-content');
      expect(tempFile.readAsStringSync(), 'safe-devicelab-content');

      // Modifying outside system temp should fail and throw our guarded exception
      final String root = path.rootPrefix(io.Directory.current.absolute.path);
      final unsafeFile = io.File(path.join(root, 'tmp_unsafe_devicelab.txt'));
      expect(unsafeFile.existsSync(), false);
      expect(
        () => unsafeFile.writeAsStringSync('unsafe-content'),
        throwsA(
          isA<io.FileSystemException>().having(
            (e) => e.message,
            'message',
            contains('Test attempted to modify file outside of temp directory'),
          ),
        ),
      );
    });
  });
}
