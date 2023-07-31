// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../generated/type_system_base.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ElementDisplayStringTest);
  });
}

@reflectiveTest
class ElementDisplayStringTest extends AbstractTypeSystemTest {
  void test_longMethod() {
    final methodA = method(
      'longMethodName',
      stringQuestion,
      parameters: [
        requiredParameter(name: 'aaa', type: stringQuestion),
        positionalParameter(
            name: 'bbb', type: stringQuestion, defaultValueCode: "'a'"),
        positionalParameter(name: 'ccc', type: stringQuestion),
      ],
    );

    final singleLine = methodA.getDisplayString(withNullability: true);
    expect(singleLine, '''
String? longMethodName(String? aaa, [String? bbb = 'a', String? ccc])''');

    final multiLine =
        methodA.getDisplayString(withNullability: true, multiline: true);
    expect(multiLine, '''
String? longMethodName(
  String? aaa, [
  String? bbb = 'a',
  String? ccc,
])''');
  }

  void test_longMethod_functionType() {
    // Function types are always kept on one line, even nested within multiline
    // signatures.
    final methodA = method(
      'longMethodName',
      stringQuestion,
      parameters: [
        requiredParameter(name: 'aaa', type: stringQuestion),
        positionalParameter(
            name: 'bbb',
            type: functionTypeNone(
              parameters: [
                requiredParameter(name: 'xxx', type: stringQuestion),
                requiredParameter(name: 'yyy', type: stringQuestion),
                requiredParameter(name: 'zzz', type: stringQuestion),
              ],
              returnType: stringQuestion,
            )),
        positionalParameter(name: 'ccc', type: stringQuestion),
      ],
    );

    final singleLine = methodA.getDisplayString(withNullability: true);
    expect(singleLine, '''
String? longMethodName(String? aaa, [String? Function(String?, String?, String?) bbb, String? ccc])''');

    final multiLine =
        methodA.getDisplayString(withNullability: true, multiline: true);
    expect(multiLine, '''
String? longMethodName(
  String? aaa, [
  String? Function(String?, String?, String?) bbb,
  String? ccc,
])''');
  }

  void test_shortMethod() {
    final methodA = method(
      'm',
      stringQuestion,
      parameters: [
        requiredParameter(name: 'a', type: stringQuestion),
        positionalParameter(name: 'b', type: stringQuestion),
      ],
    );

    final singleLine = methodA.getDisplayString(withNullability: true);
    expect(singleLine, 'String? m(String? a, [String? b])');

    final multiLine =
        methodA.getDisplayString(withNullability: true, multiline: true);
    // The signature is short enough that it remains on one line even for
    // multiline: true.
    expect(multiLine, 'String? m(String? a, [String? b])');
  }
}
