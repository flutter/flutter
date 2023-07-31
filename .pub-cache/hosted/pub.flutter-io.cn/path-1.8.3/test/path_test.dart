// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:path/path.dart' as path;
import 'package:test/test.dart';

void main() {
  group('path.Style', () {
    test('name', () {
      expect(path.Style.posix.name, 'posix');
      expect(path.Style.windows.name, 'windows');
    });

    test('separator', () {
      // ignore: deprecated_member_use_from_same_package
      expect(path.Style.posix.separator, '/');
      // ignore: deprecated_member_use_from_same_package
      expect(path.Style.windows.separator, '\\');
    });

    test('toString()', () {
      expect(path.Style.posix.toString(), 'posix');
      expect(path.Style.windows.toString(), 'windows');
    });
  });

  group('new Context()', () {
    test('uses the given current directory', () {
      final context = path.Context(current: '/a/b/c');
      expect(context.current, '/a/b/c');
    });

    test('uses the given style', () {
      final context = path.Context(style: path.Style.windows);
      expect(context.style, path.Style.windows);
    });
  });

  test('posix is a default Context for the POSIX style', () {
    expect(path.posix.style, path.Style.posix);
    expect(path.posix.current, '.');
  });

  test('windows is a default Context for the Windows style', () {
    expect(path.windows.style, path.Style.windows);
    expect(path.windows.current, '.');
  });

  test('url is a default Context for the URL style', () {
    expect(path.url.style, path.Style.url);
    expect(path.url.current, '.');
  });
}
