// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/generated/java_io.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

main() {
  group('JavaFile', () {
    group('toURI', () {
      test('forAbsolute', () {
        String tempPath = '/temp';
        String absolutePath = path.context.join(tempPath, 'foo.dart');
        // we use an absolute path
        expect(path.context.isAbsolute(absolutePath), isTrue,
            reason: '"$absolutePath" is not absolute');
        // test that toURI() returns an absolute URI
        // ignore: deprecated_member_use_from_same_package
        Uri uri = JavaFile(absolutePath).toURI();
        expect(uri.isAbsolute, isTrue);
        expect(uri.scheme, 'file');
      });
      test('forRelative', () {
        String tempPath = '/temp';
        String absolutePath = path.context.join(tempPath, 'foo.dart');
        expect(path.context.isAbsolute(absolutePath), isTrue,
            reason: '"$absolutePath" is not absolute');
        // prepare a relative path
        // We should not check that "relPath" is actually relative -
        // it may be not on Windows, if "temp" is on other disk.
        String relPath = path.context.relative(absolutePath);
        // test that toURI() returns an absolute URI
        // ignore: deprecated_member_use_from_same_package
        Uri uri = JavaFile(relPath).toURI();
        expect(uri.isAbsolute, isTrue);
        expect(uri.scheme, 'file');
      });
    });
  });
}
