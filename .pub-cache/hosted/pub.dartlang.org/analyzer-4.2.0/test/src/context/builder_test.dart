// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/context/builder.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../embedder_tests.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(EmbedderYamlLocatorTest);
  });
}

@reflectiveTest
class EmbedderYamlLocatorTest extends EmbedderRelatedTest {
  void test_empty() {
    EmbedderYamlLocator locator = EmbedderYamlLocator({
      'fox': <Folder>[pathTranslator.getResource(emptyPath) as Folder]
    });
    expect(locator.embedderYamls, hasLength(0));
  }

  void test_invalid() {
    EmbedderYamlLocator locator = EmbedderYamlLocator(null);
    locator.addEmbedderYaml(
      pathTranslator.getResource(foxLib) as Folder,
      r'''{{{,{{}}},}}''',
    );
    expect(locator.embedderYamls, hasLength(0));
  }

  void test_valid() {
    EmbedderYamlLocator locator = EmbedderYamlLocator({
      'fox': <Folder>[pathTranslator.getResource(foxLib) as Folder]
    });
    expect(locator.embedderYamls, hasLength(1));
  }
}
