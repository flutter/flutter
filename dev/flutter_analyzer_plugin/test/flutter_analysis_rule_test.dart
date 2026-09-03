// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_analyzer_plugin/src/flutter_analysis_rule.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FlutterAnalysisRuleTest);
  });
}

@reflectiveTest
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

  // ignore: non_constant_identifier_names
  void test_materialImplementationFiles() {
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

  // ignore: non_constant_identifier_names
  void test_materialTestFiles() {
    _assertTrue(
      FlutterAnalysisRule.isReadOnly('packages/flutter/test/material/button_test.dart'),
      'Material button test',
    );
    _assertTrue(
      FlutterAnalysisRule.isReadOnly('packages/flutter/test/material/theme_data_test.dart'),
      'Material theme_data test',
    );
  }

  // ignore: non_constant_identifier_names
  void test_cupertinoImplementationFiles() {
    _assertTrue(
      FlutterAnalysisRule.isReadOnly('packages/flutter/lib/src/cupertino/button.dart'),
      'Cupertino button implementation',
    );
    _assertTrue(
      FlutterAnalysisRule.isReadOnly('packages/flutter/lib/cupertino.dart'),
      'Cupertino umbrella library',
    );
  }

  // ignore: non_constant_identifier_names
  void test_cupertinoTestFiles() {
    _assertTrue(
      FlutterAnalysisRule.isReadOnly('packages/flutter/test/cupertino/button_test.dart'),
      'Cupertino button test',
    );
  }

  // ignore: non_constant_identifier_names
  void test_nonMaterialCupertinoFrameworkFiles() {
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

  // ignore: non_constant_identifier_names
  void test_inMemoryTestFiles() {
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
