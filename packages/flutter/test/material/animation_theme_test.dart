// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leak_tracker_flutter_testing/leak_tracker_flutter_testing.dart';

void main() {
  test('AnimationThemeData copyWith, ==, hashCode basics', () {
    expect(const AnimationThemeData(), const AnimationThemeData().copyWith());
    expect(const AnimationThemeData().hashCode, const AnimationThemeData().copyWith().hashCode);
  });

  test('AnimationThemeData lerp special cases', () {
    expect(AnimationThemeData.lerp(null, null, 0), const AnimationThemeData());
    const AnimationThemeData data = AnimationThemeData();
    expect(identical(AnimationThemeData.lerp(data, data, 0.5), data), true);
  });

  test('AnimationThemeData defaults', () {
    const AnimationThemeData themeData = AnimationThemeData();
    expect(themeData.animationCurve, null);
    expect(themeData.animationDuration, null);
    expect(themeData.reverseAnimationDuration, null);
    expect(themeData.sizeCurve, null);
    expect(themeData.crossFadeFirstCurve, null);
    expect(themeData.crossFadeSecondCurve, null);
    expect(themeData.switchInCurve, null);
    expect(themeData.switchOutCurve, null);
  });

  testWidgetsWithLeakTracking('Default AnimationThemeData debugFillProperties', (WidgetTester tester) async {
    final DiagnosticPropertiesBuilder builder = DiagnosticPropertiesBuilder();
    const AnimationThemeData().debugFillProperties(builder);

    final List<String> description = builder.properties
        .where((DiagnosticsNode node) => !node.isFiltered(DiagnosticLevel.info))
        .map((DiagnosticsNode node) => node.toString())
        .toList();

    expect(description, <String>[
      'animationCurve: null',
      'animationDuration: null',
      'reverseAnimationDuration: null',
      'sizeCurve: null',
      'crossFadeFirstCurve: null',
      'crossFadeSecondCurve: null',
      'switchInCurve: null',
      'switchOutCurve: null'
    ]);
  });

  testWidgetsWithLeakTracking('AnimationThemeData implements debugFillProperties', (WidgetTester tester) async {
    final DiagnosticPropertiesBuilder builder = DiagnosticPropertiesBuilder();
    const AnimationThemeData(
      animationCurve: Curves.linear,
      animationDuration: Duration(milliseconds: 250),
      reverseAnimationDuration: Duration(milliseconds: 500),
      sizeCurve: Curves.easeInOut,
      crossFadeFirstCurve: Curves.bounceIn,
      crossFadeSecondCurve: Curves.bounceOut,
      switchInCurve: Curves.elasticIn,
      switchOutCurve: Curves.elasticOut,
    ).debugFillProperties(builder);

    final List<String> description = builder.properties
        .where((DiagnosticsNode node) => !node.isFiltered(DiagnosticLevel.info))
        .map((DiagnosticsNode node) => node.toString())
        .toList();

    expect(description, <String>[
      'animationCurve: _Linear',
      'animationDuration: 0:00:00.250000',
      'reverseAnimationDuration: 0:00:00.500000',
      'sizeCurve: Cubic(0.42, 0.00, 0.58, 1.00)',
      'crossFadeFirstCurve: _BounceInCurve',
      'crossFadeSecondCurve: _BounceOutCurve',
      'switchInCurve: ElasticInCurve(0.4)',
      'switchOutCurve: ElasticOutCurve(0.4)'
    ]);
  });

}
