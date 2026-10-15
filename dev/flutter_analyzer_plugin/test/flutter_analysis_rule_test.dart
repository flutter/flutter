// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_analyzer_plugin/src/flutter_analysis_rule.dart';
import 'package:test/test.dart';

void main() {
  test('material implementation files', () {
    expect(
      FlutterAnalysisRule.isReadOnly('packages/flutter/lib/src/material/button.dart'),
      isTrue,
      reason: 'Material button implementation',
    );
    expect(
      FlutterAnalysisRule.isReadOnly('packages/flutter/lib/src/material/popup_menu.dart'),
      isTrue,
      reason: 'Material popup_menu implementation',
    );
    expect(
      FlutterAnalysisRule.isReadOnly('packages/flutter/lib/material.dart'),
      isTrue,
      reason: 'Material umbrella library',
    );
  });

  test('material test files', () {
    expect(
      FlutterAnalysisRule.isReadOnly('packages/flutter/test/material/button_test.dart'),
      isTrue,
      reason: 'Material button test',
    );
    expect(
      FlutterAnalysisRule.isReadOnly('packages/flutter/test/material/theme_data_test.dart'),
      isTrue,
      reason: 'Material theme_data test',
    );
  });

  test('cupertino implementation files', () {
    expect(
      FlutterAnalysisRule.isReadOnly('packages/flutter/lib/src/cupertino/button.dart'),
      isTrue,
      reason: 'Cupertino button implementation',
    );
    expect(
      FlutterAnalysisRule.isReadOnly('packages/flutter/lib/cupertino.dart'),
      isTrue,
      reason: 'Cupertino umbrella library',
    );
  });

  test('cupertino test files', () {
    expect(
      FlutterAnalysisRule.isReadOnly('packages/flutter/test/cupertino/button_test.dart'),
      isTrue,
      reason: 'Cupertino button test',
    );
  });

  test('non-Material/Cupertino framework files', () {
    expect(
      FlutterAnalysisRule.isReadOnly('packages/flutter/lib/src/widgets/framework.dart'),
      isFalse,
      reason: 'Widgets framework file',
    );
    expect(
      FlutterAnalysisRule.isReadOnly('packages/flutter/test/widgets/framework_test.dart'),
      isFalse,
      reason: 'Widgets framework test',
    );
    expect(
      FlutterAnalysisRule.isReadOnly('packages/flutter/lib/src/rendering/box.dart'),
      isFalse,
      reason: 'Rendering box file',
    );
    expect(
      FlutterAnalysisRule.isReadOnly('packages/flutter_tools/lib/src/runner.dart'),
      isFalse,
      reason: 'Flutter tools runner file',
    );
  });

  test('in-memory test files', () {
    expect(
      FlutterAnalysisRule.isReadOnly('/home/test/lib/test.dart'),
      isFalse,
      reason: 'In-memory test lib file',
    );
    expect(
      FlutterAnalysisRule.isReadOnly('/home/test/test/test.dart'),
      isFalse,
      reason: 'In-memory test test file',
    );
  });
}
