// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:test/expect.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../generated/type_system_base.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RecordTypeTest);
  });
}

@reflectiveTest
class RecordTypeTest extends AbstractTypeSystemTest {
  void check(DartType type, String expected) {
    expect(type.getDisplayString(withNullability: true), expected);
  }

  void test_empty() {
    check(
      RecordType(
        positional: const [],
        named: const {},
        nullabilitySuffix: NullabilitySuffix.none,
      ),
      '()',
    );
  }

  void test_mixed() {
    check(
      RecordType(
        positional: [
          typeProvider.stringType,
        ],
        named: {
          'a': typeProvider.intType,
          'b': typeProvider.boolType,
        },
        nullabilitySuffix: NullabilitySuffix.none,
      ),
      '(String, {int a, bool b})',
    );
  }

  void test_onlyNamed() {
    check(
      RecordType(
        positional: const [],
        named: {
          'a': typeProvider.intType,
          'b': typeProvider.boolType,
        },
        nullabilitySuffix: NullabilitySuffix.none,
      ),
      '({int a, bool b})',
    );
  }

  void test_onlyPositional() {
    check(
      RecordType(
        positional: [
          typeProvider.intType,
          typeProvider.boolType,
        ],
        named: const {},
        nullabilitySuffix: NullabilitySuffix.none,
      ),
      '(int, bool)',
    );
  }

  void test_suffix() {
    check(
      RecordType(
        positional: [
          typeProvider.intType,
          typeProvider.boolType,
        ],
        named: const {},
        nullabilitySuffix: NullabilitySuffix.question,
      ),
      '(int, bool)?',
    );
  }
}
