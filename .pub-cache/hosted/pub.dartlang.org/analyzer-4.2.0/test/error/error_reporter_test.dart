// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:source_span/source_span.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../generated/test_support.dart';
import '../src/dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ErrorReporterTest);
  });
}

@reflectiveTest
class ErrorReporterTest extends PubPackageResolutionTest {
  var listener = GatheringErrorListener();

  test_creation() async {
    var source = TestSource();
    var reporter = ErrorReporter(
      listener,
      source,
      isNonNullableByDefault: false,
    );
    expect(reporter, isNotNull);
  }

  test_reportErrorForElement_named() async {
    await resolveTestCode('class A {}');
    var element = findElement.class_('A');
    var reporter = ErrorReporter(
      listener,
      element.source,
      isNonNullableByDefault: false,
    );
    reporter.reportErrorForElement(
      CompileTimeErrorCode.CAST_TO_NON_TYPE,
      element,
      ['A'],
    );

    var error = listener.errors[0];
    expect(error.offset, element.nameOffset);
  }

  test_reportErrorForElement_unnamed() async {
    await resolveTestCode(r'''
import 'dart:async';
import 'dart:math';
''');
    var element = findElement.import('dart:math');

    var reporter = ErrorReporter(
      listener,
      element.source,
      isNonNullableByDefault: false,
    );
    reporter.reportErrorForElement(
      CompileTimeErrorCode.CAST_TO_NON_TYPE,
      element,
      ['A'],
    );

    var error = listener.errors[0];
    expect(error.offset, element.nameOffset);
  }

  test_reportErrorForNode_types_differentNames() async {
    newFile('$testPackageLibPath/a.dart', 'class A {}');
    newFile('$testPackageLibPath/b.dart', 'class B {}');
    await resolveTestCode(r'''
import 'package:test/a.dart';
import 'package:test/b.dart';

main() {
  x;
}
''');
    var aImport = findElement.importFind('package:test/a.dart');
    var bImport = findElement.importFind('package:test/b.dart');

    var firstType = aImport.class_('A').instantiate(
      typeArguments: [],
      nullabilitySuffix: NullabilitySuffix.none,
    );
    var secondType = bImport.class_('B').instantiate(
      typeArguments: [],
      nullabilitySuffix: NullabilitySuffix.none,
    );

    var reporter = ErrorReporter(
      listener,
      firstType.element.source,
      isNonNullableByDefault: false,
    );

    reporter.reportErrorForNode(
      CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE,
      findNode.simple('x'),
      [firstType, secondType],
    );

    var error = listener.errors[0];
    expect(error.message, isNot(contains('(')));
  }

  test_reportErrorForNode_types_sameName() async {
    newFile('$testPackageLibPath/a.dart', 'class A {}');
    newFile('$testPackageLibPath/b.dart', 'class A {}');
    await resolveTestCode(r'''
import 'package:test/a.dart';
import 'package:test/b.dart';

main() {
  x;
}
''');
    var aImport = findElement.importFind('package:test/a.dart');
    var bImport = findElement.importFind('package:test/b.dart');

    var firstType = aImport.class_('A').instantiate(
      typeArguments: [],
      nullabilitySuffix: NullabilitySuffix.none,
    );
    var secondType = bImport.class_('A').instantiate(
      typeArguments: [],
      nullabilitySuffix: NullabilitySuffix.none,
    );

    var reporter = ErrorReporter(
      listener,
      firstType.element.source,
      isNonNullableByDefault: false,
    );
    reporter.reportErrorForNode(
      CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE,
      findNode.simple('x'),
      [firstType, secondType],
    );

    var error = listener.errors[0];
    expect(error.message, contains('('));
  }

  test_reportErrorForNode_types_sameName_functionType() async {
    newFile('$testPackageLibPath/a.dart', 'class A{}');
    newFile('$testPackageLibPath/b.dart', 'class A{}');
    await resolveTestCode(r'''
import 'a.dart' as a;
import 'b.dart' as b;

a.A Function() fa;
b.A Function() fb;

main() {
  x;
}
''');
    var fa = findNode.topLevelVariableDeclaration('fa');
    var fb = findNode.topLevelVariableDeclaration('fb');

    var source = result.unit.declaredElement!.source;
    var reporter = ErrorReporter(
      listener,
      source,
      isNonNullableByDefault: false,
    );
    reporter.reportErrorForNode(
      CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE,
      findNode.simple('x'),
      [fa.variables.type!.type!, fb.variables.type!.type!],
    );

    var error = listener.errors[0];
    expect(error.message, contains('a.dart'));
    expect(error.message, contains('b.dart'));
  }

  test_reportErrorForNode_types_sameName_nested() async {
    newFile('$testPackageLibPath/a.dart', 'class A{}');
    newFile('$testPackageLibPath/b.dart', 'class A{}');
    await resolveTestCode(r'''
import 'a.dart' as a;
import 'b.dart' as b;

B<a.A> ba;
B<b.A> bb;
class B<T> {}

main() {
  x;
}
''');
    var ba = findNode.topLevelVariableDeclaration('ba');
    var bb = findNode.topLevelVariableDeclaration('bb');

    var source = result.unit.declaredElement!.source;
    var reporter = ErrorReporter(
      listener,
      source,
      isNonNullableByDefault: false,
    );
    reporter.reportErrorForNode(
      CompileTimeErrorCode.ARGUMENT_TYPE_NOT_ASSIGNABLE,
      findNode.simple('x'),
      [ba.variables.type!.type!, bb.variables.type!.type!],
    );

    var error = listener.errors[0];
    expect(error.message, contains('a.dart'));
    expect(error.message, contains('b.dart'));
  }

  test_reportErrorForSpan() async {
    var source = TestSource();
    var reporter = ErrorReporter(
      listener,
      source,
      isNonNullableByDefault: false,
    );

    var text = '''
foo: bar
zap: baz
''';

    var offset = text.indexOf('baz');
    var length = 'baz'.length;

    var span = SourceSpanBase(
      SourceLocation(offset),
      SourceLocation(offset + length),
      'baz',
    );

    reporter.reportErrorForSpan(
      AnalysisOptionsWarningCode.UNSUPPORTED_OPTION_WITH_LEGAL_VALUE,
      span,
      ['test', 'zip', 'zap'],
    );
    expect(listener.errors, hasLength(1));
    expect(listener.errors.first.offset, offset);
    expect(listener.errors.first.length, length);
  }
}
