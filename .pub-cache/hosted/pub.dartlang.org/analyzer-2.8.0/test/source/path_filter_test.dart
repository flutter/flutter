// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/source/path_filter.dart';
import 'package:path/path.dart';
import 'package:test/test.dart';

main() {
  String root(String path) => context.absolute(context.normalize(path));

  PathFilter withSingleRoot(String root, List<String> ignorePatterns) {
    return PathFilter(root, root, ignorePatterns, context);
  }

  group('PathFilterTest', () {
    test('test_ignoreEverything', () {
      var filter = withSingleRoot(root('/'), ['*']);
      expect(filter.ignored('a'), isTrue);
    });

    test('test_ignoreFile', () {
      var filter = withSingleRoot(root('/'), ['apple']);
      expect(filter.ignored('apple'), isTrue);
      expect(filter.ignored('banana'), isFalse);
    });

    test('test_ignoreMultipleFiles', () {
      var filter = withSingleRoot(root('/'), ['apple', 'banana']);
      expect(filter.ignored('apple'), isTrue);
      expect(filter.ignored('banana'), isTrue);
    });

    test('test_ignoreSubDir', () {
      var filter = withSingleRoot(root('/'), ['apple/*']);
      expect(filter.ignored('apple/banana'), isTrue);
      expect(filter.ignored('apple/banana/cantaloupe'), isFalse);
    });

    test('test_ignoreTree', () {
      var filter = withSingleRoot(root('/'), ['apple/**']);
      expect(filter.ignored('apple/banana'), isTrue);
      expect(filter.ignored('apple/banana/cantaloupe'), isTrue);
    });

    test('test_ignoreSdkExt', () {
      var filter = withSingleRoot(root('/'), ['sdk_ext/**']);
      expect(filter.ignored('sdk_ext/entry.dart'), isTrue);
      expect(filter.ignored('sdk_ext/lib/src/part.dart'), isTrue);
    });

    test('test_outsideRoot', () {
      var filter = withSingleRoot(root('/workspace/dart/sdk'), ['sdk_ext/**']);
      expect(filter.ignored('/'), isTrue);
      expect(filter.ignored('/workspace'), isTrue);
      expect(filter.ignored('/workspace/dart'), isTrue);
      expect(filter.ignored('/workspace/dart/sdk'), isFalse);
      expect(filter.ignored('/workspace/dart/../dart/sdk'), isFalse);
    });

    test('test_relativePaths', () {
      var filter = withSingleRoot(root('/workspace/dart/sdk'), ['sdk_ext/**']);
      expect(filter.ignored('../apple'), isTrue);
      expect(filter.ignored('../sdk/main.dart'), isFalse);
      expect(filter.ignored('../sdk/sdk_ext/entry.dart'), isTrue);
    });

    test('different ignore patterns root', () {
      var filter = PathFilter(
          root('/home/my'), root('/home'), ['my/test/ignored/*.dart'], context);
      expect(filter.ignored(root('/home/my/lib/a.dart')), isFalse);
      expect(filter.ignored(root('/home/my/test/ignored/b.dart')), isTrue);
    });
  });
}
