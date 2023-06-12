// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:code_builder/code_builder.dart';
import 'package:test/test.dart';

import '../common.dart';

void main() {
  useDartfmt();

  group('File', () {
    final $LinkedHashMap = refer('LinkedHashMap', 'dart:collection');

    test('should emit a source file with manual imports', () {
      expect(
        Library((b) => b
          ..directives.add(Directive.import('dart:collection'))
          ..body.add(Field((b) => b
            ..name = 'test'
            ..modifier = FieldModifier.final$
            ..assignment = $LinkedHashMap.newInstance([]).code))),
        equalsDart(r'''
            import 'dart:collection';
          
            final test = LinkedHashMap();
          ''', DartEmitter()),
      );
    });

    test('should emit a source file with a deferred import', () {
      expect(
        Library(
          (b) => b
            ..directives.add(
              Directive.importDeferredAs(
                'package:foo/foo.dart',
                'foo',
              ),
            ),
        ),
        equalsDart(r'''
          import 'package:foo/foo.dart' deferred as foo;
        '''),
      );
    });

    test('should emit a source file with a "show" combinator', () {
      expect(
        Library(
          (b) => b
            ..directives.add(
              Directive.import(
                'package:foo/foo.dart',
                show: ['Foo', 'Bar'],
              ),
            ),
        ),
        equalsDart(r'''
          import 'package:foo/foo.dart' show Foo, Bar;
        '''),
      );
    });

    test('should emit a source file with a "hide" combinator', () {
      expect(
        Library(
          (b) => b
            ..directives.add(
              Directive.import(
                'package:foo/foo.dart',
                hide: ['Foo', 'Bar'],
              ),
            ),
        ),
        equalsDart(r'''
          import 'package:foo/foo.dart' hide Foo, Bar;
        '''),
      );
    });

    test('should emit a source file with allocation', () {
      expect(
        Library((b) => b
          ..body.add(Field((b) => b
            ..name = 'test'
            ..modifier = FieldModifier.final$
            ..assignment = Code.scope((a) => '${a($LinkedHashMap)}()')))),
        equalsDart(r'''
          import 'dart:collection';
          
          final test = LinkedHashMap();
        ''', DartEmitter(Allocator())),
      );
    });

    test('should emit a source file with allocation + prefixing', () {
      expect(
        Library((b) => b
          ..body.add(Field((b) => b
            ..name = 'test'
            ..modifier = FieldModifier.final$
            ..assignment = Code.scope((a) => '${a($LinkedHashMap)}()')))),
        equalsDart(r'''
          import 'dart:collection' as _i1;
          
          final test = _i1.LinkedHashMap();
        ''', DartEmitter(Allocator.simplePrefixing())),
      );
    });

    test('should emit a source file with part directives', () {
      expect(
        Library(
          (b) => b
            ..directives.add(
              Directive.part('test.g.dart'),
            ),
        ),
        equalsDart(r'''
            part 'test.g.dart';
          ''', DartEmitter()),
      );
    });

    test('should emit a source file with part of directives', () {
      expect(
        Library(
          (b) => b
            ..directives.add(
              Directive.partOf('test.dart'),
            ),
        ),
        equalsDart(r'''
            part of 'test.dart';
          ''', DartEmitter()),
      );
    });
  });
}
