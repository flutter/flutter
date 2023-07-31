// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(LibraryAugmentationDirectiveResolutionTest);
  });
}

@reflectiveTest
class LibraryAugmentationDirectiveResolutionTest
    extends PubPackageResolutionTest {
  test_directive() async {
    newFile('$testPackageLibPath/a.dart', r'''
import augment 'b.dart';
''');

    final b = newFile('$testPackageLibPath/b.dart', r'''
library augment 'a.dart';
''');

    newFile('$testPackageLibPath/c.dart', '');

    await resolveFile2(b.path);
    assertNoErrorsInResult();

    final node = findNode.libraryAugmentation('a.dart');
    assertResolvedNodeText(node, r'''
LibraryAugmentationDirective
  libraryKeyword: library
  augmentKeyword: augment
  uri: SimpleStringLiteral
    literal: 'a.dart'
  semicolon: ;
  element: self::@augmentation::package:test/b.dart
''');
  }
}
