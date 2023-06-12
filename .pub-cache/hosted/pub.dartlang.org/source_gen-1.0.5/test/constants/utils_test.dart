// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:build_test/build_test.dart';
import 'package:source_gen/src/constants/utils.dart';
import 'package:test/test.dart';

void main() {
  group('assertHasField', () {
    late LibraryElement testLib;

    setUpAll(() async {
      testLib = await resolveSource(
        r'''
          library test_lib;

          class A {
            String a;
          }

          class B extends A {
            String b;
          }

          class C {
            String c;
          }
          ''',
        (resolver) async => (await resolver.findLibraryByName('test_lib'))!,
      );
    });

    test('should not throw when a class contains a field', () {
      final $A = testLib.getType('A')!;
      expect(() => assertHasField($A, 'a'), returnsNormally);
    });

    test('should not throw when a super class contains a field', () {
      final $B = testLib.getType('B')!;
      expect(() => assertHasField($B, 'a'), returnsNormally);
    });

    test('should throw when a class does not contain a field', () {
      final $C = testLib.getType('C')!;
      expect(() => assertHasField($C, 'a'), throwsFormatException);
    });
  });

  group('getFieldRecursive', () {
    late List<DartObject> objects;

    setUpAll(() async {
      final testLib = await resolveSource(
        r'''
          library test_lib;

          @A('a-value')
          @B('a-value', 'b-value')
          @C('c-value')
          class Example {}

          class A {
            final String a;

            const A(this.a);
          }

          class B extends A {
            final String b;

            const B(String a, this.b) : super(a);
          }

          class C {
            final String c;

            const C(this.c);
          }
          ''',
        (resolver) async => (await resolver.findLibraryByName('test_lib'))!,
      );
      objects = testLib
          .getType('Example')!
          .metadata
          .map((e) => e.computeConstantValue()!)
          .toList();
    });

    test('should find a field directly on an object', () {
      expect(getFieldRecursive(objects[0], 'a')!.toStringValue(), 'a-value');
    });

    test('should find a field available on a super', () {
      expect(getFieldRecursive(objects[1], 'b')!.toStringValue(), 'b-value');
      expect(getFieldRecursive(objects[1], 'a')!.toStringValue(), 'a-value');
    });

    test('should return null when a field is not found', () {
      expect(getFieldRecursive(objects[2], 'a'), isNull);
    });
  });
}
