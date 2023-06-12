// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('browser')
import 'dart:html';

import 'package:path/path.dart' as path;
import 'package:test/test.dart';

void main() {
  group('new Context()', () {
    test('uses the window location if root and style are omitted', () {
      final context = path.Context();
      expect(context.current,
          Uri.parse(window.location.href).resolve('.').toString());
    });

    test('uses "." if root is omitted', () {
      final context = path.Context(style: path.Style.platform);
      expect(context.current, '.');
    });

    test('uses the host platform if style is omitted', () {
      final context = path.Context();
      expect(context.style, path.Style.platform);
    });
  });

  test('Style.platform is url', () {
    expect(path.Style.platform, path.Style.url);
  });

  test('current', () {
    expect(
        path.current, Uri.parse(window.location.href).resolve('.').toString());
  });
}
