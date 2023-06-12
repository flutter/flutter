// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:code_builder/code_builder.dart';
import 'package:test/test.dart';

import 'common.dart';

void main() {
  useDartfmt();

  final constMap = literalConstMap({
    'list': literalConstList([]),
    'duration': refer('Duration').constInstance([]),
  });

  test('expression', () {
    expect(constMap, equalsDart(r'''
          const {'list': [], 'duration': Duration()}'''));
  });

  test('assignConst', () {
    expect(
      constMap.assignConst('constField'),
      equalsDart(r'''
          const constField = {'list': [], 'duration': Duration()}''',
          DartEmitter.scoped()),
    );
  });

  final library = Library((b) => b
    ..body.add(Field((b) => b
      ..name = 'val1'
      ..modifier = FieldModifier.constant
      ..assignment = refer('ConstClass').constInstance([]).code))
    ..body.add(Field((b) => b
      ..name = 'val2'
      ..modifier = FieldModifier.constant
      ..assignment =
          refer('ConstClass').constInstanceNamed('other', []).code)));

  test('should emit a source file with imports in defined order', () {
    expect(
      library,
      equalsDart(r'''
        const val1 = ConstClass();
        const val2 = ConstClass.other();'''),
    );
  });
}
