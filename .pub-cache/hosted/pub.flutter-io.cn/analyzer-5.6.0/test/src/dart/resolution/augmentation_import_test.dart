// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AugmentationImportDirectiveResolutionTest);
  });
}

@reflectiveTest
class AugmentationImportDirectiveResolutionTest
    extends PubPackageResolutionTest {
  test_inAugmentation_augmentation() async {
    newFile('$testPackageLibPath/a.dart', r'''
import augment 'b.dart';
''');

    final b = newFile('$testPackageLibPath/b.dart', r'''
library augment 'a.dart';
import augment 'c.dart';
''');

    newFile('$testPackageLibPath/c.dart', r'''
library augment 'b.dart';
''');

    await resolveFile2(b.path);
    assertNoErrorsInResult();

    final node = findNode.augmentationImportDirective('c.dart');
    assertResolvedNodeText(node, r'''
AugmentationImportDirective
  importKeyword: import
  augmentKeyword: augment
  uri: SimpleStringLiteral
    literal: 'c.dart'
  semicolon: ;
  element: AugmentationImportElement
    uri: DirectiveUriWithAugmentation
      uri: package:test/c.dart
''');
  }

  test_inAugmentation_augmentation_duplicate() async {
    newFile('$testPackageLibPath/a.dart', r'''
import augment 'b.dart';
''');

    final b = newFile('$testPackageLibPath/b.dart', r'''
library augment 'a.dart';
import augment 'c.dart';
import augment 'c.dart' /*2*/;
''');

    newFile('$testPackageLibPath/c.dart', r'''
library augment 'b.dart';
''');

    await resolveFile2(b.path);
    assertErrorsInResult([
      error(CompileTimeErrorCode.DUPLICATE_AUGMENTATION_IMPORT, 66, 8),
    ]);

    final node = findNode.augmentationImportDirective('/*2*/');
    assertResolvedNodeText(node, r'''
AugmentationImportDirective
  importKeyword: import
  augmentKeyword: augment
  uri: SimpleStringLiteral
    literal: 'c.dart'
  semicolon: ;
  element: AugmentationImportElement
    uri: DirectiveUriWithAugmentation
      uri: package:test/c.dart
''');
  }

  test_inAugmentation_notAugmentation_library() async {
    newFile('$testPackageLibPath/a.dart', r'''
import augment 'b.dart';
''');

    final b = newFile('$testPackageLibPath/b.dart', r'''
library augment 'a.dart';
import augment 'c.dart';
''');

    newFile('$testPackageLibPath/c.dart', '');

    await resolveFile2(b.path);
    assertErrorsInResult([
      error(CompileTimeErrorCode.IMPORT_OF_NOT_AUGMENTATION, 41, 8),
    ]);

    final node = findNode.augmentationImportDirective('c.dart');
    assertResolvedNodeText(node, r'''
AugmentationImportDirective
  importKeyword: import
  augmentKeyword: augment
  uri: SimpleStringLiteral
    literal: 'c.dart'
  semicolon: ;
  element: AugmentationImportElement
    uri: DirectiveUriWithSource
      source: package:test/c.dart
''');
  }

  test_inAugmentation_notAugmentation_noRelativeUri() async {
    newFile('$testPackageLibPath/a.dart', r'''
import augment 'b.dart';
''');

    final b = newFile('$testPackageLibPath/b.dart', r'''
library augment 'a.dart';
import augment ':net';
''');

    await resolveFile2(b.path);
    assertErrorsInResult([
      error(CompileTimeErrorCode.INVALID_URI, 41, 6),
    ]);

    final node = findNode.augmentationImportDirective(':net');
    assertResolvedNodeText(node, r'''
AugmentationImportDirective
  importKeyword: import
  augmentKeyword: augment
  uri: SimpleStringLiteral
    literal: ':net'
  semicolon: ;
  element: AugmentationImportElement
    uri: DirectiveUriWithRelativeUriString
      relativeUriString: :net
''');
  }

  test_inAugmentation_notAugmentation_noRelativeUriStr() async {
    newFile('$testPackageLibPath/a.dart', r'''
import augment 'b.dart';
''');

    final b = newFile('$testPackageLibPath/b.dart', r'''
library augment 'a.dart';
import augment '${'foo'}.dart';
''');

    await resolveFile2(b.path);
    assertErrorsInResult([
      error(CompileTimeErrorCode.URI_WITH_INTERPOLATION, 41, 15),
    ]);

    final node = findNode.augmentationImportDirective('foo');
    assertResolvedNodeText(node, r'''
AugmentationImportDirective
  importKeyword: import
  augmentKeyword: augment
  uri: StringInterpolation
    elements
      InterpolationString
        contents: '
      InterpolationExpression
        leftBracket: ${
        expression: SimpleStringLiteral
          literal: 'foo'
        rightBracket: }
      InterpolationString
        contents: .dart'
    staticType: String
    stringValue: null
  semicolon: ;
  element: AugmentationImportElement
    uri: DirectiveUri
''');
  }

  test_inAugmentation_notAugmentation_noSource() async {
    newFile('$testPackageLibPath/a.dart', r'''
import augment 'b.dart';
''');

    final b = newFile('$testPackageLibPath/b.dart', r'''
library augment 'a.dart';
import augment 'foo:bar';
''');

    await resolveFile2(b.path);
    assertErrorsInResult([
      error(CompileTimeErrorCode.URI_DOES_NOT_EXIST, 41, 9),
    ]);

    final node = findNode.augmentationImportDirective('foo:bar');
    assertResolvedNodeText(node, r'''
AugmentationImportDirective
  importKeyword: import
  augmentKeyword: augment
  uri: SimpleStringLiteral
    literal: 'foo:bar'
  semicolon: ;
  element: AugmentationImportElement
    uri: DirectiveUriWithRelativeUri
      relativeUri: foo:bar
''');
  }

  test_inLibrary_augmentation() async {
    newFile('$testPackageLibPath/a.dart', r'''
library augment 'test.dart';
''');

    await assertNoErrorsInCode(r'''
import augment 'a.dart';
''');

    final node = findNode.augmentationImportDirective('a.dart');
    assertResolvedNodeText(node, r'''
AugmentationImportDirective
  importKeyword: import
  augmentKeyword: augment
  uri: SimpleStringLiteral
    literal: 'a.dart'
  semicolon: ;
  element: AugmentationImportElement
    uri: DirectiveUriWithAugmentation
      uri: package:test/a.dart
''');
  }

  test_inLibrary_augmentation_duplicate() async {
    newFile('$testPackageLibPath/a.dart', r'''
library augment 'test.dart';
''');

    await assertErrorsInCode(r'''
import augment 'a.dart';
import augment /*2*/ 'a.dart';
''', [
      error(CompileTimeErrorCode.DUPLICATE_AUGMENTATION_IMPORT, 46, 8),
    ]);

    final node = findNode.augmentationImportDirective('/*2*/');
    assertResolvedNodeText(node, r'''
AugmentationImportDirective
  importKeyword: import
  augmentKeyword: augment
  uri: SimpleStringLiteral
    literal: 'a.dart'
  semicolon: ;
  element: AugmentationImportElement
    uri: DirectiveUriWithAugmentation
      uri: package:test/a.dart
''');
  }

  test_inLibrary_notAugmentation_fileDoesNotExist() async {
    await assertErrorsInCode(r'''
import augment 'a.dart';
''', [
      error(CompileTimeErrorCode.URI_DOES_NOT_EXIST, 15, 8),
    ]);

    final node = findNode.augmentationImportDirective('a.dart');
    assertResolvedNodeText(node, r'''
AugmentationImportDirective
  importKeyword: import
  augmentKeyword: augment
  uri: SimpleStringLiteral
    literal: 'a.dart'
  semicolon: ;
  element: AugmentationImportElement
    uri: DirectiveUriWithSource
      source: package:test/a.dart
''');
  }

  test_inLibrary_notAugmentation_library() async {
    newFile('$testPackageLibPath/a.dart', '');

    await assertErrorsInCode(r'''
import augment 'a.dart';
''', [
      error(CompileTimeErrorCode.IMPORT_OF_NOT_AUGMENTATION, 15, 8),
    ]);

    final node = findNode.augmentationImportDirective('a.dart');
    assertResolvedNodeText(node, r'''
AugmentationImportDirective
  importKeyword: import
  augmentKeyword: augment
  uri: SimpleStringLiteral
    literal: 'a.dart'
  semicolon: ;
  element: AugmentationImportElement
    uri: DirectiveUriWithSource
      source: package:test/a.dart
''');
  }

  test_inLibrary_notAugmentation_noRelativeUri() async {
    await assertErrorsInCode(r'''
import augment ':net';
''', [
      error(CompileTimeErrorCode.INVALID_URI, 15, 6),
    ]);

    final node = findNode.augmentationImportDirective(':net');
    assertResolvedNodeText(node, r'''
AugmentationImportDirective
  importKeyword: import
  augmentKeyword: augment
  uri: SimpleStringLiteral
    literal: ':net'
  semicolon: ;
  element: AugmentationImportElement
    uri: DirectiveUriWithRelativeUriString
      relativeUriString: :net
''');
  }

  test_inLibrary_notAugmentation_noRelativeUriStr() async {
    await assertErrorsInCode(r'''
import augment '${'foo'}.dart';
''', [
      error(CompileTimeErrorCode.URI_WITH_INTERPOLATION, 15, 15),
    ]);

    final node = findNode.augmentationImportDirective('foo');
    assertResolvedNodeText(node, r'''
AugmentationImportDirective
  importKeyword: import
  augmentKeyword: augment
  uri: StringInterpolation
    elements
      InterpolationString
        contents: '
      InterpolationExpression
        leftBracket: ${
        expression: SimpleStringLiteral
          literal: 'foo'
        rightBracket: }
      InterpolationString
        contents: .dart'
    staticType: String
    stringValue: null
  semicolon: ;
  element: AugmentationImportElement
    uri: DirectiveUri
''');
  }

  test_inLibrary_notAugmentation_noSource() async {
    await assertErrorsInCode(r'''
import augment 'foo:bar';
''', [
      error(CompileTimeErrorCode.URI_DOES_NOT_EXIST, 15, 9),
    ]);

    final node = findNode.augmentationImportDirective('foo:bar');
    assertResolvedNodeText(node, r'''
AugmentationImportDirective
  importKeyword: import
  augmentKeyword: augment
  uri: SimpleStringLiteral
    literal: 'foo:bar'
  semicolon: ;
  element: AugmentationImportElement
    uri: DirectiveUriWithRelativeUri
      relativeUri: foo:bar
''');
  }

  test_inLibrary_notAugmentation_partOfName() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of my.lib;
''');

    await assertErrorsInCode(r'''
import augment 'a.dart';
''', [
      error(CompileTimeErrorCode.IMPORT_OF_NOT_AUGMENTATION, 15, 8),
    ]);

    final node = findNode.augmentationImportDirective('a.dart');
    assertResolvedNodeText(node, r'''
AugmentationImportDirective
  importKeyword: import
  augmentKeyword: augment
  uri: SimpleStringLiteral
    literal: 'a.dart'
  semicolon: ;
  element: AugmentationImportElement
    uri: DirectiveUriWithSource
      source: package:test/a.dart
''');
  }

  test_inLibrary_notAugmentation_partOfUri() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
''');

    await assertErrorsInCode(r'''
import augment 'a.dart';
''', [
      error(CompileTimeErrorCode.IMPORT_OF_NOT_AUGMENTATION, 15, 8),
    ]);

    final node = findNode.augmentationImportDirective('a.dart');
    assertResolvedNodeText(node, r'''
AugmentationImportDirective
  importKeyword: import
  augmentKeyword: augment
  uri: SimpleStringLiteral
    literal: 'a.dart'
  semicolon: ;
  element: AugmentationImportElement
    uri: DirectiveUriWithSource
      source: package:test/a.dart
''');
  }
}
