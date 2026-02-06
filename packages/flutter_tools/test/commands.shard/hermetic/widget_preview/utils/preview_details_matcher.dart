// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:analyzer/dart/constant/value.dart';
import 'package:flutter_tools/src/widget_preview/dependency_graph.dart';
import 'package:flutter_tools/src/widget_preview/preview_details.dart';
import 'package:test/test.dart';

typedef _PreviewDetailsMatcherMismatchPair = ({Object? expected, Object? actual});

extension on DartObject {
  /// Climbs the object's class hierarchy, returning the first field matching [name].
  DartObject? getFirstField(String name) {
    DartObject? annotation = this;
    while (annotation != null) {
      final DartObject? field = annotation.getField(name);
      if (field != null) {
        return field;
      }
      annotation = annotation.getField('(super)');
    }
    return null;
  }
}

/// Matches properties of a `@Preview` annotation instance.
class PreviewMatcher extends Matcher {
  PreviewMatcher({
    this.group = 'Default',
    this.name,
    this.size,
    this.textScaleFactor,
    this.wrapper,
    this.theme,
    this.brightness,
    this.localizations,
  });

  static const kBrightness = 'brightness';
  static const kGroup = 'group';
  static const kLocalizations = 'localizations';
  static const kName = 'name';
  static const kPackageName = 'packageName';
  static const kScriptUri = 'scriptUri';
  static const kSize = 'size';
  static const kTextScaleFactor = 'textScaleFactor';
  static const kTheme = 'theme';
  static const kWrapper = 'wrapper';

  final String? group;
  final String? name;
  final String? size;
  final double? textScaleFactor;
  final String? wrapper;
  final String? theme;
  final String? brightness;
  final String? localizations;

  @override
  Description describe(Description description) {
    description.add('PreviewMatcher');
    return description;
  }

  @override
  bool matches(Object? item, Map<Object?, Object?> matchState) {
    if (item is! DartObject) {
      return false;
    }

    var matches = true;
    void checkPropertyMatch({
      required String name,
      required Object? actual,
      required Object? expected,
    }) {
      if (actual != expected) {
        matchState[name] = (actual: actual, expected: expected);
        matches = false;
      }
    }

    checkPropertyMatch(
      name: kGroup,
      actual: item.getFirstField('group')?.toStringValue(),
      expected: group,
    );
    checkPropertyMatch(
      name: kName,
      actual: item.getFirstField(kName)?.toStringValue(),
      expected: name,
    );
    final DartObject? actualSize = item.getFirstField(kSize);
    checkPropertyMatch(
      name: kSize,
      actual: (actualSize?.isNull ?? true) ? null : size.toString(),
      expected: size,
    );
    checkPropertyMatch(
      name: kTextScaleFactor,
      actual: item.getFirstField(kTextScaleFactor)?.toDoubleValue(),
      expected: textScaleFactor,
    );
    checkPropertyMatch(
      name: kWrapper,
      actual: item.getFirstField(kWrapper)?.toFunctionValue()?.displayName,
      expected: wrapper,
    );
    checkPropertyMatch(
      name: kTheme,
      actual: item.getFirstField(kTheme)?.toFunctionValue()?.displayName,
      expected: theme,
    );

    final DartObject? actualBrightness = item.getFirstField(kBrightness);
    checkPropertyMatch(
      name: kBrightness,
      actual: (actualBrightness?.isNull ?? true) ? null : actualBrightness!.variable!.toString(),
      expected: brightness,
    );
    checkPropertyMatch(
      name: kLocalizations,
      actual: item.getFirstField(kLocalizations)?.toFunctionValue()?.displayName,
      expected: localizations,
    );
    return matches;
  }
}

/// A [Matcher] that verifies each property of a `@Preview` declaration matches an expected value.
///
/// WARNING: the preview details will be compared against the initial state of the `Preview`
/// instance, before `Preview.transform()` is invoked.
class PreviewDetailsMatcher extends Matcher {
  PreviewDetailsMatcher({
    required this.packageName,
    required this.functionName,
    required this.isBuilder,
    String? group = 'Default',
    String? name,
    String? size,
    double? textScaleFactor,
    String? wrapper,
    String? theme,
    String? brightness,
    String? localizations,
  }) : previewMatcher = PreviewMatcher(
         group: group,
         name: name,
         size: size,
         textScaleFactor: textScaleFactor,
         wrapper: wrapper,
         theme: theme,
         brightness: brightness,
         localizations: localizations,
       );

  final String functionName;
  final bool isBuilder;
  final String packageName;
  final PreviewMatcher previewMatcher;

  @override
  Description describe(Description description) {
    description.add('PreviewDetailsMatcher');
    return description;
  }

  @override
  Description describeMismatch(
    dynamic item,
    Description mismatchDescription,
    Map<Object?, Object?> matchState,
    bool verbose,
  ) {
    mismatchDescription.add('has the following mismatches:\n\n');
    for (final MapEntry<String, _PreviewDetailsMatcherMismatchPair>(
          :String key,
          value: _PreviewDetailsMatcherMismatchPair(:Object? actual, :Object? expected),
        )
        in matchState.cast<String, _PreviewDetailsMatcherMismatchPair>().entries) {
      mismatchDescription.add("- $key = '$actual' differs from the expected value '$expected'\n");
    }
    return mismatchDescription;
  }

  @override
  bool matches(Object? item, Map<Object?, Object?> matchState) {
    if (item is! PreviewDetails) {
      return false;
    }

    var matches = true;
    void checkPropertyMatch({
      required String name,
      required Object? actual,
      required Object? expected,
    }) {
      if (actual != expected) {
        matchState[name] = (actual: actual, expected: expected);
        matches = false;
      }
    }

    checkPropertyMatch(name: 'packageName', actual: item.packageName, expected: packageName);
    checkPropertyMatch(name: 'functionName', actual: item.functionName, expected: functionName);
    checkPropertyMatch(name: 'isBuilder', actual: item.isBuilder, expected: isBuilder);
    if (!previewMatcher.matches(item.previewAnnotation, matchState)) {
      matches = false;
    }
    return matches;
  }
}

/// A [Matcher] that verifies each property of a `MultiPreview` declaration matches an expected
/// value.
///
/// WARNING: this matcher will only work with `MultiPreview`s with `previews` fields as constant
/// evaluation doesn't allow for getting the values of getters. Matching is done before any calls
/// to `MultiPreview.transform()`, so previews must be compared to their initial non-transformed
/// state.
class MultiPreviewDetailsMatcher extends Matcher {
  MultiPreviewDetailsMatcher({
    required this.packageName,
    required this.functionName,
    required this.isBuilder,
    required this.previewMatchers,
  });

  final String functionName;
  final bool isBuilder;
  final String packageName;
  final List<PreviewMatcher> previewMatchers;

  @override
  Description describe(Description description) {
    description.add('MultiPreviewDetailsMatcher');
    return description;
  }

  @override
  Description describeMismatch(
    dynamic item,
    Description mismatchDescription,
    Map<Object?, Object?> matchState,
    bool verbose,
  ) {
    mismatchDescription.add('has the following mismatches:\n\n');
    for (final MapEntry<String, _PreviewDetailsMatcherMismatchPair>(
          :String key,
          value: _PreviewDetailsMatcherMismatchPair(:Object? actual, :Object? expected),
        )
        in matchState.cast<String, _PreviewDetailsMatcherMismatchPair>().entries) {
      mismatchDescription.add("- $key = '$actual' differs from the expected value '$expected'\n");
    }
    return mismatchDescription;
  }

  @override
  bool matches(Object? item, Map<Object?, Object?> matchState) {
    if (item is! PreviewDetails) {
      return false;
    }

    var matches = true;
    void checkPropertyMatch({
      required String name,
      required Object? actual,
      required Object? expected,
    }) {
      if (actual != expected) {
        matchState[name] = (actual: actual, expected: expected);
        matches = false;
      }
    }

    checkPropertyMatch(name: 'isMultiPreview', actual: item.isMultiPreview, expected: true);
    checkPropertyMatch(name: 'packageName', actual: item.packageName, expected: packageName);
    checkPropertyMatch(name: 'functionName', actual: item.functionName, expected: functionName);
    checkPropertyMatch(name: 'isBuilder', actual: item.isBuilder, expected: isBuilder);
    final List<DartObject> previews = item.previewAnnotation
        .getFirstField('previews')!
        .toListValue()!;
    if (previews.length != previewMatchers.length) {
      matchState['previews'] = (
        actual: 'previews length(${previews.length})',
        expected: 'preview matchers length(${previewMatchers.length})',
      );
      return false;
    }
    for (var i = 0; i < previewMatchers.length; ++i) {
      if (!previewMatchers[i].matches(previews[i], matchState)) {
        matches = false;
      }
    }
    return matches;
  }
}

void expectContainsPreviews(
  Map<PreviewPath, LibraryPreviewNode> actual,
  Map<PreviewPath, List<Matcher>> expected,
) {
  for (final MapEntry<PreviewPath, List<Matcher>>(
        key: PreviewPath previewPath,
        value: List<Matcher> filePreviews,
      )
      in expected.entries) {
    expect(actual.containsKey(previewPath), true);
    expect(actual[previewPath]!.previews, filePreviews);
  }
}
