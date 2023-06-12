// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';

import 'package:vm_snapshot_analysis/utils.dart';

void main() async {
  group('utils', () {
    test('partsForPath', () async {
      expect(partsForPath('@shared'), equals(['@shared']));
      expect(
        partsForPath('dart:async/_Future'),
        equals(['dart:async', '_Future']),
      );
      expect(
        partsForPath('dart:typed_data/_Int32x4/&'),
        equals(['dart:typed_data', '_Int32x4', '&']),
      );
      expect(
        partsForPath('package:foo/bar/baz/bop.dart'),
        equals(['package:foo', 'bar', 'baz', 'bop.dart']),
      );
      expect(
        partsForPath('package:foo.bar.baz/src/foobar/foobaz'),
        equals(['package:foo', 'bar', 'baz', 'src', 'foobar', 'foobaz']),
      );
      expect(
        partsForPath('package:foo.bar.baz/src/foobar/foobaz.dart/::/_method'),
        equals([
          'package:foo',
          'bar',
          'baz',
          'src',
          'foobar',
          'foobaz.dart',
          '::',
          '_method',
        ]),
      );

      expect(
        partsForPath('package:foo.bar.baz.proto/model.pb.dart'),
        equals([
          'package:foo',
          'bar',
          'baz',
          'proto',
          'model.pb.dart',
        ]),
      );
      expect(
        partsForPath(
            'package:a.b.c.d.e.f/src/page/controller.dart/PageController/new PageController./<anonymous closure @2770>'),
        equals([
          'package:a',
          'b',
          'c',
          'd',
          'e',
          'f',
          'src',
          'page',
          'controller.dart',
          'PageController',
          'new PageController.',
          '<anonymous closure @2770>',
        ]),
      );
    });
  });
}
