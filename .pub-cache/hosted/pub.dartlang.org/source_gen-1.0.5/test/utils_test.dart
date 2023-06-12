// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Increase timeouts on this test which resolves source code and can be slow.
@Timeout.factor(2.0)
import 'package:analyzer/dart/element/element.dart';
import 'package:build_test/build_test.dart';
import 'package:source_gen/source_gen.dart';
import 'package:test/test.dart';

void main() {
  late ClassElement example;

  setUpAll(() async {
    const source = r'''
      library example;

      abstract class Example {
        ClassType classType();
        FunctionType functionType();
      }

      class ClassType {}
      typedef FunctionType();
    ''';
    example = await resolveSource(
        source,
        (resolver) => resolver
            .findLibraryByName('example')
            .then((e) => e!.getType('Example')!));
  });

  test('should return the name of a class type', () {
    final classType = example.methods.first.returnType;
    expect(typeNameOf(classType), 'ClassType');
  });

  test('should return the name of a function type', () {
    final functionType = example.methods.last.returnType;
    expect(typeNameOf(functionType), 'FunctionType');
  });
}
