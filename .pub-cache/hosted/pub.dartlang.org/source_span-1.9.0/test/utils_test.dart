// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:source_span/src/utils.dart';
import 'package:test/test.dart';

void main() {
  group('find line start', () {
    test('skip entries in wrong column', () {
      final context = '0_bb\n1_bbb\n2b____\n3bbb\n';
      final index = findLineStart(context, 'b', 1)!;
      expect(index, 11);
      expect(context.substring(index - 1, index + 3), '\n2b_');
    });

    test('end of line column for empty text', () {
      final context = '0123\n56789\nabcdefgh\n';
      final index = findLineStart(context, '', 5)!;
      expect(index, 5);
      expect(context[index], '5');
    });

    test('column at the end of the file for empty text', () {
      var context = '0\n2\n45\n';
      var index = findLineStart(context, '', 2)!;
      expect(index, 4);
      expect(context[index], '4');

      context = '0\n2\n45';
      index = findLineStart(context, '', 2)!;
      expect(index, 4);
    });

    test('empty text in empty context', () {
      final index = findLineStart('', '', 0);
      expect(index, 0);
    });

    test('found on the first line', () {
      final context = '0\n2\n45\n';
      final index = findLineStart(context, '0', 0);
      expect(index, 0);
    });

    test('finds text that starts with a newline', () {
      final context = '0\n2\n45\n';
      final index = findLineStart(context, '\n2', 1);
      expect(index, 0);
    });

    test('not found', () {
      final context = '0\n2\n45\n';
      final index = findLineStart(context, '0', 1);
      expect(index, isNull);
    });
  });
}
