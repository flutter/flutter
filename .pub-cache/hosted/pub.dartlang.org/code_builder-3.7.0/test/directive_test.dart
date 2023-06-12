// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:code_builder/code_builder.dart';
import 'package:test/test.dart';

import 'common.dart';

void main() {
  useDartfmt();

  final $LinkedHashMap = refer('LinkedHashMap', 'dart:collection');

  final library = Library((b) => b
    ..directives.add((Directive.export('../relative.dart')))
    ..directives.add((Directive.export('package:foo/foo.dart')))
    ..directives.add((Directive.part('lib.g.dart')))
    ..body.add(Field((b) => b
      ..name = 'relativeRef'
      ..modifier = FieldModifier.final$
      ..assignment =
          refer('Relative', '../relative.dart').newInstance([]).code))
    ..body.add(Field((b) => b
      ..name = 'pkgRefFoo'
      ..modifier = FieldModifier.final$
      ..assignment = refer('Foo', 'package:foo/foo.dart').newInstance([]).code))
    ..body.add(Field((b) => b
      ..name = 'pkgRefBar'
      ..modifier = FieldModifier.final$
      ..assignment = refer('Bar', 'package:foo/bar.dart').newInstance([]).code))
    ..body.add(Field((b) => b
      ..name = 'collectionRef'
      ..modifier = FieldModifier.final$
      ..assignment = $LinkedHashMap.newInstance([]).code)));

  test('should emit a source file with imports in defined order', () {
    expect(
      library,
      equalsDart(r'''
          import '../relative.dart' as _i1;
          import 'package:foo/foo.dart' as _i2;
          import 'package:foo/bar.dart' as _i3;
          import 'dart:collection' as _i4;
          export '../relative.dart';
          export 'package:foo/foo.dart';
          part 'lib.g.dart';

          final relativeRef = _i1.Relative();
          final pkgRefFoo = _i2.Foo();
          final pkgRefBar = _i3.Bar();
          final collectionRef = _i4.LinkedHashMap();''', DartEmitter.scoped()),
    );
  });

  test('should emit a source file with ordered', () {
    expect(
      library,
      equalsDart(r'''
          import 'dart:collection' as _i4;

          import 'package:foo/bar.dart' as _i3;
          import 'package:foo/foo.dart' as _i2;

          import '../relative.dart' as _i1;

          export 'package:foo/foo.dart';
          export '../relative.dart';

          part 'lib.g.dart';

          final relativeRef = _i1.Relative();
          final pkgRefFoo = _i2.Foo();
          final pkgRefBar = _i3.Bar();
          final collectionRef = _i4.LinkedHashMap();''',
          DartEmitter.scoped(orderDirectives: true)),
    );
  });
}
