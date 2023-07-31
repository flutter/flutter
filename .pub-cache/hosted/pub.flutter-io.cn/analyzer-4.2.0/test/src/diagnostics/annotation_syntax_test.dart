// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/syntactic_errors.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AnnotationSyntaxTest);
  });
}

@reflectiveTest
class AnnotationSyntaxTest extends PubPackageResolutionTest {
  test_annotation_on_type_argument() async {
    await assertErrorsInCode('''
const annotation = null;

class Annotation {
  final String message;
  const Annotation(this.message);
}

class A<E> {}

class C {
  m() => new A<@annotation @Annotation("test") C>();
}
''', [
      error(ParserErrorCode.ANNOTATION_ON_TYPE_ARGUMENT, 146, 11),
      error(ParserErrorCode.ANNOTATION_ON_TYPE_ARGUMENT, 158, 19),
    ]);
  }
}
