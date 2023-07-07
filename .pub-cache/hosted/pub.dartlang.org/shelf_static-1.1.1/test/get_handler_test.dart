// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:path/path.dart' as p;
import 'package:shelf_static/shelf_static.dart';
import 'package:test/test.dart';
import 'package:test_descriptor/test_descriptor.dart' as d;

void main() {
  setUp(() async {
    await d.file('root.txt', 'root txt').create();
    await d.dir('files', [
      d.file('test.txt', 'test txt content'),
      d.file('with space.txt', 'with space content')
    ]).create();
  });

  test('non-existent relative path', () async {
    expect(() => createStaticHandler('random/relative'), throwsArgumentError);
  });

  test('existing relative path', () async {
    final existingRelative = p.relative(d.sandbox);
    expect(() => createStaticHandler(existingRelative), returnsNormally);
  });

  test('non-existent absolute path', () {
    final nonExistingAbsolute = p.join(d.sandbox, 'not_here');
    expect(() => createStaticHandler(nonExistingAbsolute), throwsArgumentError);
  });

  test('existing absolute path', () {
    expect(() => createStaticHandler(d.sandbox), returnsNormally);
  });
}
