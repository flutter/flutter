// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:test/test.dart';

void main() {
  group('MultiplexingBuilder', () {
    test('Only passes matching inputs', () async {
      final builder = MultiplexingBuilder([
        TestBuilder(buildExtensions: replaceExtension('.foo', '.copy')),
        TestBuilder(buildExtensions: replaceExtension('.bar', '.copy')),
      ]);
      await testBuilder(builder, {'a|lib/a1.foo': 'a1', 'a|lib/a2.bar': 'a2'},
          outputs: {'a|lib/a1.copy': 'a1', 'a|lib/a2.copy': 'a2'});
    });

    test('merges non-overlapping extension maps', () {
      final builder = MultiplexingBuilder([
        TestBuilder(buildExtensions: replaceExtension('.foo', '.copy')),
        TestBuilder(buildExtensions: replaceExtension('.bar', '.copy')),
      ]);
      expect(builder.buildExtensions, {
        '.foo': ['.copy'],
        '.bar': ['.copy']
      });
    });

    test('merges overlapping extension maps', () {
      final builder = MultiplexingBuilder([
        TestBuilder(buildExtensions: {
          '.foo': ['.copy.0', '.copy.1']
        }),
        TestBuilder(buildExtensions: replaceExtension('.foo', '.new')),
      ]);
      expect(builder.buildExtensions, {
        '.foo': ['.copy.0', '.copy.1', '.new']
      });
    });
  });
}
