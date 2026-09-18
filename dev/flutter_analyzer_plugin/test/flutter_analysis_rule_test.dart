// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_analyzer_plugin/src/flutter_analysis_rule.dart';
import 'package:test/test.dart';

void main() {
  late FlutterAnalysisRuleTest testSuite;

  setUp(() {
    testSuite = FlutterAnalysisRuleTest();
  });

  test('materialImplementationFiles', () => testSuite.testMaterialImplementationFiles());
  test('materialTestFiles', () => testSuite.testMaterialTestFiles());
  test('cupertinoImplementationFiles', () => testSuite.testCupertinoImplementationFiles());
  test('cupertinoTestFiles', () => testSuite.testCupertinoTestFiles());
  test(
    'nonMaterialCupertinoFrameworkFiles',
    () => testSuite.testNonMaterialCupertinoFrameworkFiles(),
  );
  test('inMemoryTestFiles', () => testSuite.testInMemoryTestFiles());
}

class FlutterAnalysisRuleTest {
  void _assertTrue(bool value, String message) {
    if (!value) {
      throw StateError('Expected true for: $message');
    }
  }

  void _assertFalse(bool value, String message) {
    if (value) {
      throw StateError('Expected false for: $message');
    }
  }

  void testMaterialImplementationFiles() {
    _assertTrue(
      FlutterAnalysisRule.isReadOnly('packages/flutter/lib/src/material/button.dart'),
      'Material button implementation',
    );
    _assertTrue(
      FlutterAnalysisRule.isReadOnly('packages/flutter/lib/src/material/popup_menu.dart'),
      'Material popup_menu implementation',
    );
    _assertTrue(
      FlutterAnalysisRule.isReadOnly('packages/flutter/lib/material.dart'),
      'Material umbrella library',
    );
  }

  void testMaterialTestFiles() {
    _assertTrue(
      FlutterAnalysisRule.isReadOnly('packages/flutter/test/material/button_test.dart'),
      'Material button test',
    );
    _assertTrue(
      FlutterAnalysisRule.isReadOnly('packages/flutter/test/material/theme_data_test.dart'),
      'Material theme_data test',
    );
  }

  void testCupertinoImplementationFiles() {
    _assertTrue(
      FlutterAnalysisRule.isReadOnly('packages/flutter/lib/src/cupertino/button.dart'),
      'Cupertino button implementation',
    );
    _assertTrue(
      FlutterAnalysisRule.isReadOnly('packages/flutter/lib/cupertino.dart'),
      'Cupertino umbrella library',
    );
  }

  void testCupertinoTestFiles() {
    _assertTrue(
      FlutterAnalysisRule.isReadOnly('packages/flutter/test/cupertino/button_test.dart'),
      'Cupertino button test',
    );
  }

  void testNonMaterialCupertinoFrameworkFiles() {
    _assertFalse(
      FlutterAnalysisRule.isReadOnly('packages/flutter/lib/src/widgets/framework.dart'),
      'Widgets framework file',
    );
    _assertFalse(
      FlutterAnalysisRule.isReadOnly('packages/flutter/test/widgets/framework_test.dart'),
      'Widgets framework test',
    );
    _assertFalse(
      FlutterAnalysisRule.isReadOnly('packages/flutter/lib/src/rendering/box.dart'),
      'Rendering box file',
    );
    _assertFalse(
      FlutterAnalysisRule.isReadOnly('packages/flutter_tools/lib/src/runner.dart'),
      'Flutter tools runner file',
    );
  }

  void testInMemoryTestFiles() {
    _assertFalse(
      FlutterAnalysisRule.isReadOnly('/home/test/lib/test.dart'),
      'In-memory test lib file',
    );
    _assertFalse(
      FlutterAnalysisRule.isReadOnly('/home/test/test/test.dart'),
      'In-memory test test file',
    );
  }
}
