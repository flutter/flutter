// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:code_builder/code_builder.dart';
import 'package:test/test.dart';

import '../common.dart';

void main() {
  useDartfmt();

  test('should create a field', () {
    expect(
      Field((b) => b..name = 'foo'),
      equalsDart(r'''
        var foo;
      '''),
    );
  });

  test('should create a typed field', () {
    expect(
      Field((b) => b
        ..name = 'foo'
        ..type = refer('String')),
      equalsDart(r'''
        String foo;
      '''),
    );
  });

  test('should create a final field', () {
    expect(
      Field((b) => b
        ..name = 'foo'
        ..modifier = FieldModifier.final$),
      equalsDart(r'''
        final foo;
      '''),
    );
  });

  test('should create a constant field', () {
    expect(
      Field((b) => b
        ..name = 'foo'
        ..modifier = FieldModifier.constant),
      equalsDart(r'''
        const foo;
      '''),
    );
  });

  test('should create a field with an assignment', () {
    expect(
      Field((b) => b
        ..name = 'foo'
        ..assignment = const Code('1')),
      equalsDart(r'''
        var foo = 1;
      '''),
    );
  });
}
