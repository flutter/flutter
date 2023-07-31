// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/hint/sdk_constraint_extractor.dart';
import 'package:analyzer/src/test_utilities/resource_provider_mixin.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SdkConstraintExtractorTest);
  });
}

@reflectiveTest
class SdkConstraintExtractorTest with ResourceProviderMixin {
  SdkConstraintExtractor extractorFor(String pubspecContent) {
    String pubspecPath = '/pkg/test/pubspec.yaml';
    File pubspecFile = newFile(pubspecPath, pubspecContent);
    return SdkConstraintExtractor(pubspecFile);
  }

  test_constraint_any() {
    SdkConstraintExtractor extractor = extractorFor('''
environment:
  sdk: any
''');
    expect(extractor.constraint().toString(), 'any');
  }

  test_constraint_caret() {
    SdkConstraintExtractor extractor = extractorFor('''
environment:
  sdk: ^2.1.0
''');
    expect(extractor.constraint().toString(), '^2.1.0');
  }

  test_constraint_compound() {
    SdkConstraintExtractor extractor = extractorFor('''
environment:
  sdk: '>=2.1.0 <3.0.0'
''');
    expect(extractor.constraint().toString(), '>=2.1.0 <3.0.0');
  }

  test_constraint_gt() {
    SdkConstraintExtractor extractor = extractorFor('''
environment:
  sdk: '>2.1.0'
''');
    expect(extractor.constraint().toString(), '>2.1.0');
  }

  test_constraint_gte() {
    SdkConstraintExtractor extractor = extractorFor('''
environment:
  sdk: '>=2.2.0-dev.3.0'
''');
    expect(extractor.constraint().toString(), '>=2.2.0-dev.3.0');
  }

  test_constraint_invalid_badConstraint() {
    SdkConstraintExtractor extractor = extractorFor('''
environment:
  sdk: latest
''');
    expect(extractor.constraint(), isNull);
  }

  test_constraint_invalid_noEnvironment() {
    SdkConstraintExtractor extractor = extractorFor('''
name: test
''');
    expect(extractor.constraint(), isNull);
  }

  test_constraint_invalid_noSdk() {
    SdkConstraintExtractor extractor = extractorFor('''
environment:
  os: 'Analytical Engine'
''');
    expect(extractor.constraint(), isNull);
  }

  test_constraint_invalid_notYaml() {
    SdkConstraintExtractor extractor = extractorFor('''
class C {}
''');
    expect(extractor.constraint(), isNull);
  }
}
