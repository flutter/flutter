// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// reduced-test-set:
//   This file is run as part of a reduced test set in CI on Mac and Windows
//   machines.
@Tags(<String>['reduced-test-set'])
library;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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

  testWidgets('ProgressIndicatorThemeData implements debugFillProperties', (WidgetTester tester) async {
    final DiagnosticPropertiesBuilder builder = DiagnosticPropertiesBuilder();
    const ProgressIndicatorThemeData(
      color: Color(0XFF0000F1),
      linearTrackColor: Color(0XFF0000F2),
      linearMinHeight: 25.0,
      circularTrackColor: Color(0XFF0000F3),
      refreshBackgroundColor: Color(0XFF0000F4),
      borderRadius: BorderRadius.all(Radius.circular(8.0)),
      stopIndicatorColor: Color(0XFF0000F5),
      stopIndicatorRadius: 10.0,
      strokeWidth: 8.0,
      strokeAlign: BorderSide.strokeAlignOutside,
      strokeCap: StrokeCap.butt,
      constraints: BoxConstraints.tightFor(width: 80.0, height: 80.0),
      trackGap: 16.0,
    ).debugFillProperties(builder);

    final List<String> description = builder.properties
        .where((DiagnosticsNode node) => !node.isFiltered(DiagnosticLevel.info))
        .map((DiagnosticsNode node) => node.toString())
        .toList();

    expect(description, equalsIgnoringHashCodes(<String>[
      'color: Color(alpha: 1.0000, red: 0.0000, green: 0.0000, blue: 0.9451, colorSpace: ColorSpace.sRGB)',
      'linearTrackColor: Color(alpha: 1.0000, red: 0.0000, green: 0.0000, blue: 0.9490, colorSpace: ColorSpace.sRGB)',
      'linearMinHeight: 25.0',
      'circularTrackColor: Color(alpha: 1.0000, red: 0.0000, green: 0.0000, blue: 0.9529, colorSpace: ColorSpace.sRGB)',
      'refreshBackgroundColor: Color(alpha: 1.0000, red: 0.0000, green: 0.0000, blue: 0.9569, colorSpace: ColorSpace.sRGB)',
      'borderRadius: BorderRadius.circular(8.0)',
      'stopIndicatorColor: Color(alpha: 1.0000, red: 0.0000, green: 0.0000, blue: 0.9608, colorSpace: ColorSpace.sRGB)',
      'stopIndicatorRadius: 10.0',
      'strokeWidth: 8.0',
      'strokeAlign: 1.0',
      'strokeCap: StrokeCap.butt',
      'constraints: BoxConstraints(w=80.0, h=80.0)',
      'trackGap: 16.0'
    ]));
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

  testWidgets('Can theme LinearProgressIndicator when year2023 to false', (WidgetTester tester) async {
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

  testWidgets('Can theme CircularProgressIndicator using ProgressIndicatorTheme', (WidgetTester tester) async {
    const Color color = Color(0XFFFF0000);
    const Color circularTrackColor = Color(0XFF0000FF);
    const double strokeWidth = 8.0;
    const double strokeAlign = BorderSide.strokeAlignOutside;
    const StrokeCap strokeCap = StrokeCap.butt;
    const BoxConstraints constraints = BoxConstraints.tightFor(width: 80.0, height: 80.0);
    final ThemeData theme = ThemeData(
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: color,
        circularTrackColor: circularTrackColor,
        strokeWidth: strokeWidth,
        strokeAlign: strokeAlign,
        strokeCap: strokeCap,
        constraints: constraints,
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: const Scaffold(
          body: Center(
            child: CircularProgressIndicator(
              value: 0.5,
            ),
          ),
        ),
      ),
    );

    expect(
      tester.getSize(find.byType(CircularProgressIndicator)),
      equals(Size(constraints.maxWidth, constraints.maxHeight)),
    );
    expect(
      find.byType(CircularProgressIndicator),
      paints
        // Track.
        ..arc(
          color: circularTrackColor,
          strokeWidth: strokeWidth,
          strokeCap: strokeCap,
        )
        // Active indicator.
        ..arc(
          color: color,
          strokeWidth: strokeWidth,
          strokeCap: strokeCap,
        ),
    );
    await expectLater(
      find.byType(CircularProgressIndicator),
      matchesGoldenFile('circular_progress_indicator_theme.png'),
    );
  });

  testWidgets('Can theme CircularProgressIndicator when year2023 to false', (WidgetTester tester) async {
    const Color color = Color(0XFFFF0000);
    const Color circularTrackColor = Color(0XFF0000FF);
    const double strokeWidth = 8.0;
    const double strokeAlign = BorderSide.strokeAlignOutside;
    const StrokeCap strokeCap = StrokeCap.butt;
    const BoxConstraints constraints = BoxConstraints.tightFor(width: 80.0, height: 80.0);
    const double trackGap = 12.0;
    final ThemeData theme = ThemeData(
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: color,
        circularTrackColor: circularTrackColor,
        strokeWidth: strokeWidth,
        strokeAlign: strokeAlign,
        strokeCap: strokeCap,
        constraints: constraints,
        trackGap: trackGap,
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: const Scaffold(
          body: Center(
            child: CircularProgressIndicator(
              year2023: false,
              value: 0.5,
            ),
          ),
        ),
      ),
    );

    expect(
      tester.getSize(find.byType(CircularProgressIndicator)),
      equals(Size(constraints.maxWidth, constraints.maxHeight)),
    );
    expect(
      find.byType(CircularProgressIndicator),
      paints
        // Track.
        ..arc(
          color: circularTrackColor,
          strokeWidth: strokeWidth,
          strokeCap: strokeCap,
        )
        // Active indicator.
        ..arc(
          color: color,
          strokeWidth: strokeWidth,
          strokeCap: strokeCap,
        ),
    );
    await expectLater(
      find.byType(CircularProgressIndicator),
      matchesGoldenFile('circular_progress_indicator_theme_year2023_false.png'),
    );
  });
}
