// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ProgressIndicatorThemeData copyWith, ==, hashCode, basics', () {
    expect(const ProgressIndicatorThemeData(), const ProgressIndicatorThemeData().copyWith());
    expect(const ProgressIndicatorThemeData().hashCode, const ProgressIndicatorThemeData().copyWith().hashCode);
  });

  test('ProgressIndicatorThemeData lerp special cases', () {
    expect(ProgressIndicatorThemeData.lerp(null, null, 0), null);
    const ProgressIndicatorThemeData data = ProgressIndicatorThemeData();
    expect(identical(ProgressIndicatorThemeData.lerp(data, data, 0.5), data), true);
  });

  testWidgets('Can theme LinearProgressIndicator using ProgressIndicatorTheme', (WidgetTester tester) async {
    const Color color = Color(0XFF00FF00);
    const Color linearTrackColor = Color(0XFFFF0000);
    const double linearMinHeight = 25.0;
    const double borderRadius = 8.0;
    final ThemeData theme = ThemeData(
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: color,
        linearTrackColor: linearTrackColor,
        linearMinHeight: linearMinHeight,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: const Scaffold(
          body: Center(
            child: SizedBox(
              width: 200.0,
              child: LinearProgressIndicator(
                value: 0.5,
              ),
            ),
          ),
        ),
      ),
    );

    expect(
      find.byType(LinearProgressIndicator),
      paints
        // Track.
        ..rrect(
          rrect: RRect.fromLTRBR(0.0, 0.0, 200.0, linearMinHeight, const Radius.circular(borderRadius)),
          color: linearTrackColor,
        )
        // Active indicator.
        ..rrect(
          rrect: RRect.fromLTRBR(0.0, 0.0, 100.0, linearMinHeight, const Radius.circular(borderRadius)),
          color: color,
        ),
    );
  });

  testWidgets('Can theme LinearProgressIndicator with year2023 to false', (WidgetTester tester) async {
    const Color color = Color(0XFF00FF00);
    const Color linearTrackColor = Color(0XFFFF0000);
    const double linearMinHeight = 25.0;
    const double borderRadius = 8.0;
    const Color stopIndicatorColor = Color(0XFF0000FF);
    const double stopIndicatorRadius = 10.0;
    const double trackGap = 16.0;
    final ThemeData theme = ThemeData(
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: color,
        linearTrackColor: linearTrackColor,
        linearMinHeight: linearMinHeight,
        borderRadius: BorderRadius.circular(borderRadius),
        stopIndicatorColor: stopIndicatorColor,
        stopIndicatorRadius: stopIndicatorRadius,
        trackGap: trackGap,
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: const Scaffold(
          body: Center(
            child: SizedBox(
              width: 200.0,
              child: LinearProgressIndicator(
                year2023: false,
                value: 0.5,
              ),
            ),
          ),
        ),
      ),
    );

    expect(
      find.byType(LinearProgressIndicator),
      paints
        // Track.
        ..rrect(
          rrect: RRect.fromLTRBR(100.0 + trackGap, 0.0, 200.0, linearMinHeight, const Radius.circular(borderRadius)),
          color: linearTrackColor,
        )
        // Stop indicator.
        ..circle(
          x: 187.5,
          y: 12.5,
          radius: stopIndicatorRadius,
          color: stopIndicatorColor,
        )
        // Active indicator.
        ..rrect(
          rrect: RRect.fromLTRBR(0.0, 0.0, 100.0, linearMinHeight, const Radius.circular(borderRadius)),
          color: color,
        ),
    );
  });

  testWidgets('Local ProgressIndicatorTheme takes precedence over inherited ProgressIndicatorTheme', (WidgetTester tester) async {
    const Color color = Color(0XFFFF00FF);
    const Color linearTrackColor = Color(0XFF00FFFF);
    const double linearMinHeight = 20.0;
    const double borderRadius = 6.0;
    const Color stopIndicatorColor = Color(0XFFFFFF00);
    const double stopIndicatorRadius = 8.0;
    const double trackGap = 12.0;
    final ThemeData theme = ThemeData(
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: Color(0XFF00FF00),
        linearTrackColor: Color(0XFFFF0000),
        linearMinHeight: 25.0,
        borderRadius: BorderRadius.all(Radius.circular(8.0)),
        stopIndicatorColor: Color(0XFF0000FF),
        stopIndicatorRadius: 10.0,
        trackGap: 16.0,
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Scaffold(
          body: Center(
            child: ProgressIndicatorTheme(
              data: ProgressIndicatorThemeData(
                color: color,
                linearTrackColor: linearTrackColor,
                linearMinHeight: linearMinHeight,
                borderRadius: BorderRadius.circular(borderRadius),
                stopIndicatorColor: stopIndicatorColor,
                stopIndicatorRadius: stopIndicatorRadius,
                trackGap: trackGap,
              ),
              child: const SizedBox(
                width: 200.0,
                child: LinearProgressIndicator(
                  value: 0.5,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    expect(
      find.byType(LinearProgressIndicator),
      paints
        // Track.
        ..rrect(
          rrect: RRect.fromLTRBR(0.0, 0.0, 200.0, linearMinHeight, const Radius.circular(borderRadius)),
          color: linearTrackColor,
        )
        // Active indicator.
        ..rrect(
          rrect: RRect.fromLTRBR(0.0, 0.0, 100.0, linearMinHeight, const Radius.circular(borderRadius)),
          color: color,
        ),
    );
  });
}
