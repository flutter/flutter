// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:apicheck/apicheck.dart';
import 'package:litetest/litetest.dart';

/// Verify that duplicate Flutter API is consistent between implementations.
///
/// Flutter contains API that is required to match between implementations.
/// Notably, some enums such as those used by Flutter accessibility, appear in:
/// * dart:ui (native)
/// * dart:ui (web)
/// * embedder.h
/// * Internal enumerations used by iOS/Android
///
/// WARNING: The embedder API makes strong API/ABI stability guarantees. Care
/// must be taken when adding new enums, or values to existing enums. These
/// CANNOT be removed without breaking backward compatibility, which we have
/// never done. See the note at the top of `shell/platform/embedder/embedder.h`
/// for further details.
main(List<String> arguments) {
  if (arguments.length < 1) {
    print('usage: dart bin/apicheck.dart path/to/engine/src/flutter');
    exit(1);
  }
  final String flutterRoot = arguments[0];

  test('AccessibilityFeatures enums match', () {
    // Dart values: _kFooBarIndex = 1 << N
    List<String> uiFields = getDartClassFields(
      sourcePath:'$flutterRoot/lib/ui/window.dart',
      className:'AccessibilityFeatures',
    );
    List<String> webuiFields = getDartClassFields(
      sourcePath:'$flutterRoot/lib/ui/window.dart',
      className:'AccessibilityFeatures',
    );
    // C values: kFlutterAccessibilityFeatureFooBar = 1 << N,
    List<String> embedderEnumValues = getCppEnumValues(
      sourcePath: '$flutterRoot/shell/platform/embedder/embedder.h',
      enumName: 'FlutterAccessibilityFeature',
    );
    // C++ values: kFooBar = 1 << N,
    List<String> internalEnumValues = getCppEnumClassValues(
      sourcePath: '$flutterRoot/lib/ui/window/platform_configuration.h',
      enumName: 'AccessibilityFeatureFlag',
    );
    // Java values: FOO_BAR(1 << N).
    List<String> javaEnumValues = getJavaEnumValues(
      sourcePath: '$flutterRoot/shell/platform/android/io/flutter/view/AccessibilityBridge.java',
      enumName: 'AccessibilityFeature',
    ).map(allCapsToCamelCase).toList();

    expect(webuiFields, uiFields);
    expect(embedderEnumValues, uiFields);
    expect(internalEnumValues, uiFields);
    expect(javaEnumValues, uiFields);
  });

  test('SemanticsAction enums match', () {
    // Dart values: _kFooBarIndex = 1 << N.
    List<String> uiFields = getDartClassFields(
      sourcePath:'$flutterRoot/lib/ui/semantics.dart',
      className:'SemanticsAction',
    );
    List<String> webuiFields = getDartClassFields(
      sourcePath:'$flutterRoot/lib/ui/semantics.dart',
      className:'SemanticsAction',
    );
    // C values: kFlutterSemanticsActionFooBar = 1 << N.
    List<String> embedderEnumValues = getCppEnumValues(
      sourcePath: '$flutterRoot/shell/platform/embedder/embedder.h',
      enumName: 'FlutterSemanticsAction',
    );
    // C++ values: kFooBar = 1 << N.
    List<String> internalEnumValues = getCppEnumClassValues(
      sourcePath: '$flutterRoot/lib/ui/semantics/semantics_node.h',
      enumName: 'SemanticsAction',
    );
    // Java values: FOO_BAR(1 << N).
    List<String> javaEnumValues = getJavaEnumValues(
      sourcePath: '$flutterRoot/shell/platform/android/io/flutter/view/AccessibilityBridge.java',
      enumName: 'Action',
    ).map(allCapsToCamelCase).toList();

    expect(webuiFields, uiFields);
    expect(embedderEnumValues, uiFields);
    expect(internalEnumValues, uiFields);
    expect(javaEnumValues, uiFields);
  });

  test('SemanticsFlag enums match', () {
    // Dart values: _kFooBarIndex = 1 << N.
    List<String> uiFields = getDartClassFields(
      sourcePath:'$flutterRoot/lib/ui/semantics.dart',
      className:'SemanticsFlag',
    );
    List<String> webuiFields = getDartClassFields(
      sourcePath:'$flutterRoot/lib/ui/semantics.dart',
      className:'SemanticsFlag',
    );
    // C values: kFlutterSemanticsFlagFooBar = 1 << N.
    List<String> embedderEnumValues = getCppEnumValues(
      sourcePath: '$flutterRoot/shell/platform/embedder/embedder.h',
      enumName: 'FlutterSemanticsFlag',
    );
    // C++ values: kFooBar = 1 << N.
    List<String> internalEnumValues = getCppEnumClassValues(
      sourcePath: '$flutterRoot/lib/ui/semantics/semantics_node.h',
      enumName: 'SemanticsFlags',
    );
    // Java values: FOO_BAR(1 << N).
    List<String> javaEnumValues = getJavaEnumValues(
      sourcePath: '$flutterRoot/shell/platform/android/io/flutter/view/AccessibilityBridge.java',
      enumName: 'Flag',
    ).map(allCapsToCamelCase).toList();

    expect(webuiFields, uiFields);
    expect(embedderEnumValues, uiFields);
    expect(internalEnumValues, uiFields);
    expect(javaEnumValues, uiFields);
  });
}

/// Returns the CamelCase equivalent of an ALL_CAPS identifier.
String allCapsToCamelCase(String identifier) {
  StringBuffer buffer = StringBuffer();
  for (String word in identifier.split('_')) {
    if (word.isNotEmpty) {
      buffer.write(word[0]);
    }
    if (word.length > 1) {
      buffer.write(word.substring(1).toLowerCase());
    }
  }
  return buffer.toString();
}
