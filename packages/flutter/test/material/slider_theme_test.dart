// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../rendering/mock_canvas.dart';

void main() {
  test('SliderThemeData copyWith, ==, hashCode basics', () {
    expect(const SliderThemeData(), const SliderThemeData().copyWith());
    expect(const SliderThemeData().hashCode, const SliderThemeData().copyWith().hashCode);
  });

  testWidgets('Default SliderThemeData debugFillProperties', (WidgetTester tester) async {
    final DiagnosticPropertiesBuilder builder = DiagnosticPropertiesBuilder();
    const SliderThemeData().debugFillProperties(builder);

    final List<String> description = builder.properties
        .where((DiagnosticsNode node) => !node.isFiltered(DiagnosticLevel.info))
        .map((DiagnosticsNode node) => node.toString())
        .toList();

    expect(description, <String>[]);
  });


  testWidgets('SliderThemeData implements debugFillProperties', (WidgetTester tester) async {
    final DiagnosticPropertiesBuilder builder = DiagnosticPropertiesBuilder();
    const SliderThemeData(
      trackHeight: 7.0,
      activeTrackColor: Color(0xFF000001),
      inactiveTrackColor: Color(0xFF000002),
      disabledActiveTrackColor: Color(0xFF000003),
      disabledInactiveTrackColor: Color(0xFF000004),
      activeTickMarkColor: Color(0xFF000005),
      inactiveTickMarkColor: Color(0xFF000006),
      disabledActiveTickMarkColor: Color(0xFF000007),
      disabledInactiveTickMarkColor: Color(0xFF000008),
      thumbColor: Color(0xFF000009),
      overlappingShapeStrokeColor: Color(0xFF000010),
      disabledThumbColor: Color(0xFF000011),
      overlayColor: Color(0xFF000012),
      valueIndicatorColor: Color(0xFF000013),
      overlayShape: RoundSliderOverlayShape(),
      tickMarkShape: RoundSliderTickMarkShape(),
      thumbShape: RoundSliderThumbShape(),
      trackShape: RoundedRectSliderTrackShape(),
      valueIndicatorShape: PaddleSliderValueIndicatorShape(),
      rangeTickMarkShape: RoundRangeSliderTickMarkShape(),
      rangeThumbShape: RoundRangeSliderThumbShape(),
      rangeTrackShape: RoundedRectRangeSliderTrackShape(),
      rangeValueIndicatorShape: PaddleRangeSliderValueIndicatorShape(),
      showValueIndicator: ShowValueIndicator.always,
      valueIndicatorTextStyle: TextStyle(color: Colors.black),
      mouseCursor: MaterialStateMouseCursor.clickable,
    ).debugFillProperties(builder);

    final List<String> description = builder.properties
        .where((DiagnosticsNode node) => !node.isFiltered(DiagnosticLevel.info))
        .map((DiagnosticsNode node) => node.toString())
        .toList();

    expect(description, <String>[
      'trackHeight: 7.0',
      'activeTrackColor: Color(0xff000001)',
      'inactiveTrackColor: Color(0xff000002)',
      'disabledActiveTrackColor: Color(0xff000003)',
      'disabledInactiveTrackColor: Color(0xff000004)',
      'activeTickMarkColor: Color(0xff000005)',
      'inactiveTickMarkColor: Color(0xff000006)',
      'disabledActiveTickMarkColor: Color(0xff000007)',
      'disabledInactiveTickMarkColor: Color(0xff000008)',
      'thumbColor: Color(0xff000009)',
      'overlappingShapeStrokeColor: Color(0xff000010)',
      'disabledThumbColor: Color(0xff000011)',
      'overlayColor: Color(0xff000012)',
      'valueIndicatorColor: Color(0xff000013)',
      "overlayShape: Instance of 'RoundSliderOverlayShape'",
      "tickMarkShape: Instance of 'RoundSliderTickMarkShape'",
      "thumbShape: Instance of 'RoundSliderThumbShape'",
      "trackShape: Instance of 'RoundedRectSliderTrackShape'",
      "valueIndicatorShape: Instance of 'PaddleSliderValueIndicatorShape'",
      "rangeTickMarkShape: Instance of 'RoundRangeSliderTickMarkShape'",
      "rangeThumbShape: Instance of 'RoundRangeSliderThumbShape'",
      "rangeTrackShape: Instance of 'RoundedRectRangeSliderTrackShape'",
      "rangeValueIndicatorShape: Instance of 'PaddleRangeSliderValueIndicatorShape'",
      'showValueIndicator: always',
      'valueIndicatorTextStyle: TextStyle(inherit: true, color: Color(0xff000000))',
      'mouseCursor: MaterialStateMouseCursor(clickable)',
    ]);
  });

  testWidgets('Slider uses ThemeData slider theme if present', (WidgetTester tester) async {
    final ThemeData theme = ThemeData(
      platform: TargetPlatform.android,
      primarySwatch: Colors.red,
    );
    final SliderThemeData sliderTheme = theme.sliderTheme;
    final SliderThemeData customTheme = sliderTheme.copyWith(
      activeTrackColor: Colors.purple,
      inactiveTrackColor: Colors.purple.withAlpha(0x3d),
    );

    await tester.pumpWidget(_buildApp(sliderTheme, value: 0.5, enabled: false));
    final MaterialInkController material = Material.of(tester.element(find.byType(Slider)))!;

    expect(
      material,
      paints
        ..rrect(color: customTheme.disabledActiveTrackColor)
        ..rrect(color: customTheme.disabledInactiveTrackColor),
    );
  });

  testWidgets('Slider overrides ThemeData theme if SliderTheme present', (WidgetTester tester) async {
    final ThemeData theme = ThemeData(
      platform: TargetPlatform.android,
      primarySwatch: Colors.red,
    );
    final SliderThemeData sliderTheme = theme.sliderTheme;
    final SliderThemeData customTheme = sliderTheme.copyWith(
      activeTrackColor: Colors.purple,
      inactiveTrackColor: Colors.purple.withAlpha(0x3d),
    );

    await tester.pumpWidget(_buildApp(sliderTheme, value: 0.5, enabled: false));
    final MaterialInkController material = Material.of(tester.element(find.byType(Slider)))!;

    expect(
      material,
      paints
        ..rrect(color: customTheme.disabledActiveTrackColor)
        ..rrect(color: customTheme.disabledInactiveTrackColor),
    );
  });

  testWidgets('SliderThemeData generates correct opacities for fromPrimaryColors', (WidgetTester tester) async {
    const Color customColor1 = Color(0xcafefeed);
    const Color customColor2 = Color(0xdeadbeef);
    const Color customColor3 = Color(0xdecaface);
    const Color customColor4 = Color(0xfeedcafe);

    final SliderThemeData sliderTheme = SliderThemeData.fromPrimaryColors(
      primaryColor: customColor1,
      primaryColorDark: customColor2,
      primaryColorLight: customColor3,
      valueIndicatorTextStyle: ThemeData.fallback().textTheme.bodyLarge!.copyWith(color: customColor4),
    );

    expect(sliderTheme.activeTrackColor, equals(customColor1.withAlpha(0xff)));
    expect(sliderTheme.inactiveTrackColor, equals(customColor1.withAlpha(0x3d)));
    expect(sliderTheme.disabledActiveTrackColor, equals(customColor2.withAlpha(0x52)));
    expect(sliderTheme.disabledInactiveTrackColor, equals(customColor2.withAlpha(0x1f)));
    expect(sliderTheme.activeTickMarkColor, equals(customColor3.withAlpha(0x8a)));
    expect(sliderTheme.inactiveTickMarkColor, equals(customColor1.withAlpha(0x8a)));
    expect(sliderTheme.disabledActiveTickMarkColor, equals(customColor3.withAlpha(0x1f)));
    expect(sliderTheme.disabledInactiveTickMarkColor, equals(customColor2.withAlpha(0x1f)));
    expect(sliderTheme.thumbColor, equals(customColor1.withAlpha(0xff)));
    expect(sliderTheme.disabledThumbColor, equals(customColor2.withAlpha(0x52)));
    expect(sliderTheme.overlayColor, equals(customColor1.withAlpha(0x1f)));
    expect(sliderTheme.valueIndicatorColor, equals(customColor1.withAlpha(0xff)));
    expect(sliderTheme.valueIndicatorTextStyle!.color, equals(customColor4));
  });

  testWidgets('SliderThemeData generates correct shapes for fromPrimaryColors', (WidgetTester tester) async {
    const Color customColor1 = Color(0xcafefeed);
    const Color customColor2 = Color(0xdeadbeef);
    const Color customColor3 = Color(0xdecaface);
    const Color customColor4 = Color(0xfeedcafe);

    final SliderThemeData sliderTheme = SliderThemeData.fromPrimaryColors(
      primaryColor: customColor1,
      primaryColorDark: customColor2,
      primaryColorLight: customColor3,
      valueIndicatorTextStyle: ThemeData.fallback().textTheme.bodyLarge!.copyWith(color: customColor4),
    );

    expect(sliderTheme.overlayShape, const RoundSliderOverlayShape());
    expect(sliderTheme.tickMarkShape, const RoundSliderTickMarkShape());
    expect(sliderTheme.thumbShape, const RoundSliderThumbShape());
    expect(sliderTheme.trackShape, const RoundedRectSliderTrackShape());
    expect(sliderTheme.valueIndicatorShape, const PaddleSliderValueIndicatorShape());
    expect(sliderTheme.rangeTickMarkShape, const RoundRangeSliderTickMarkShape());
    expect(sliderTheme.rangeThumbShape, const RoundRangeSliderThumbShape());
    expect(sliderTheme.rangeTrackShape, const RoundedRectRangeSliderTrackShape());
    expect(sliderTheme.rangeValueIndicatorShape, const PaddleRangeSliderValueIndicatorShape());
  });

  testWidgets('SliderThemeData lerps correctly', (WidgetTester tester) async {
    final SliderThemeData sliderThemeBlack = SliderThemeData.fromPrimaryColors(
      primaryColor: Colors.black,
      primaryColorDark: Colors.black,
      primaryColorLight: Colors.black,
      valueIndicatorTextStyle: ThemeData.fallback().textTheme.bodyLarge!.copyWith(color: Colors.black),
    ).copyWith(trackHeight: 2.0);
    final SliderThemeData sliderThemeWhite = SliderThemeData.fromPrimaryColors(
      primaryColor: Colors.white,
      primaryColorDark: Colors.white,
      primaryColorLight: Colors.white,
      valueIndicatorTextStyle: ThemeData.fallback().textTheme.bodyLarge!.copyWith(color: Colors.white),
    ).copyWith(trackHeight: 6.0);
    final SliderThemeData lerp = SliderThemeData.lerp(sliderThemeBlack, sliderThemeWhite, 0.5);
    const Color middleGrey = Color(0xff7f7f7f);

    expect(lerp.trackHeight, equals(4.0));
    expect(lerp.activeTrackColor, equals(middleGrey.withAlpha(0xff)));
    expect(lerp.inactiveTrackColor, equals(middleGrey.withAlpha(0x3d)));
    expect(lerp.disabledActiveTrackColor, equals(middleGrey.withAlpha(0x52)));
    expect(lerp.disabledInactiveTrackColor, equals(middleGrey.withAlpha(0x1f)));
    expect(lerp.activeTickMarkColor, equals(middleGrey.withAlpha(0x8a)));
    expect(lerp.inactiveTickMarkColor, equals(middleGrey.withAlpha(0x8a)));
    expect(lerp.disabledActiveTickMarkColor, equals(middleGrey.withAlpha(0x1f)));
    expect(lerp.disabledInactiveTickMarkColor, equals(middleGrey.withAlpha(0x1f)));
    expect(lerp.thumbColor, equals(middleGrey.withAlpha(0xff)));
    expect(lerp.disabledThumbColor, equals(middleGrey.withAlpha(0x52)));
    expect(lerp.overlayColor, equals(middleGrey.withAlpha(0x1f)));
    expect(lerp.valueIndicatorColor, equals(middleGrey.withAlpha(0xff)));
    expect(lerp.valueIndicatorTextStyle!.color, equals(middleGrey.withAlpha(0xff)));
  });

  testWidgets('Default slider track draws correctly', (WidgetTester tester) async {
    final ThemeData theme = ThemeData(
      platform: TargetPlatform.android,
      primarySwatch: Colors.blue,
    );
    final SliderThemeData sliderTheme = theme.sliderTheme.copyWith(thumbColor: Colors.red.shade500);

    await tester.pumpWidget(_buildApp(sliderTheme, value: 0.25));
    final MaterialInkController material = Material.of(tester.element(find.byType(Slider)))!;

    const Radius radius = Radius.circular(2);
    const Radius activatedRadius = Radius.circular(3);

    // The enabled slider thumb has track segments that extend to and from
    // the center of the thumb.
    expect(
      material,
      paints
        ..rrect(rrect: RRect.fromLTRBAndCorners(24.0, 297.0, 212.0, 303.0, topLeft: activatedRadius, bottomLeft: activatedRadius), color: sliderTheme.activeTrackColor)
        ..rrect(rrect: RRect.fromLTRBAndCorners(212.0, 298.0, 776.0, 302.0, topRight: radius, bottomRight: radius), color: sliderTheme.inactiveTrackColor),
    );

    await tester.pumpWidget(_buildApp(sliderTheme, value: 0.25, enabled: false));
    await tester.pumpAndSettle(); // wait for disable animation

    // The disabled slider thumb is the same size as the enabled thumb.
    expect(
      material,
      paints
        ..rrect(rrect: RRect.fromLTRBAndCorners(24.0, 297.0, 212.0, 303.0, topLeft: activatedRadius, bottomLeft: activatedRadius), color: sliderTheme.disabledActiveTrackColor)
        ..rrect(rrect: RRect.fromLTRBAndCorners(212.0, 298.0, 776.0, 302.0, topRight: radius, bottomRight: radius), color: sliderTheme.disabledInactiveTrackColor),
    );
  });

  testWidgets('Default slider overlay draws correctly', (WidgetTester tester) async {
    final ThemeData theme = ThemeData(
      platform: TargetPlatform.android,
      primarySwatch: Colors.blue,
    );
    final SliderThemeData sliderTheme = theme.sliderTheme.copyWith(thumbColor: Colors.red.shade500);

    await tester.pumpWidget(_buildApp(sliderTheme, value: 0.25));
    final MaterialInkController material = Material.of(tester.element(find.byType(Slider)))!;

    // With no touch, paints only the thumb.
    expect(
      material,
      paints
        ..circle(
          color: sliderTheme.thumbColor,
          x: 212.0,
          y: 300.0,
          radius: 10.0,
        ),
    );

    final Offset center = tester.getCenter(find.byType(Slider));
    final TestGesture gesture = await tester.startGesture(center);
    // Wait for overlay animation to finish.
    await tester.pumpAndSettle();

    // After touch, paints thumb and overlay.
    expect(
      material,
      paints
        ..circle(
          color: sliderTheme.overlayColor,
          x: 212.0,
          y: 300.0,
          radius: 24.0,
        )
        ..circle(
          color: sliderTheme.thumbColor,
          x: 212.0,
          y: 300.0,
          radius: 10.0,
        ),
    );

    await gesture.up();
    await tester.pumpAndSettle();

    // After the gesture is up and complete, it again paints only the thumb.
    expect(
      material,
      paints
        ..circle(
          color: sliderTheme.thumbColor,
          x: 212.0,
          y: 300.0,
          radius: 10.0,
        ),
    );
  });

  testWidgets('Default slider ticker and thumb shape draw correctly', (WidgetTester tester) async {
    final ThemeData theme = ThemeData(
      platform: TargetPlatform.android,
      primarySwatch: Colors.blue,
    );
    final SliderThemeData sliderTheme = theme.sliderTheme.copyWith(thumbColor: Colors.red.shade500);

    await tester.pumpWidget(_buildApp(sliderTheme, value: 0.45));
    final MaterialInkController material = Material.of(tester.element(find.byType(Slider)))!;

    expect(material, paints..circle(color: sliderTheme.thumbColor, radius: 10.0));

    await tester.pumpWidget(_buildApp(sliderTheme, value: 0.45, enabled: false));
    await tester.pumpAndSettle(); // wait for disable animation

    expect(material, paints..circle(color: sliderTheme.disabledThumbColor, radius: 10.0));

    await tester.pumpWidget(_buildApp(sliderTheme, value: 0.45, divisions: 3));
    await tester.pumpAndSettle(); // wait for enable animation

    expect(
      material,
      paints
        ..circle(color: sliderTheme.activeTickMarkColor)
        ..circle(color: sliderTheme.activeTickMarkColor)
        ..circle(color: sliderTheme.inactiveTickMarkColor)
        ..circle(color: sliderTheme.inactiveTickMarkColor)
        ..circle(color: sliderTheme.thumbColor, radius: 10.0),
    );

    await tester.pumpWidget(_buildApp(sliderTheme, value: 0.45, divisions: 3, enabled: false));
    await tester.pumpAndSettle(); // wait for disable animation

    expect(
      material,
      paints
        ..circle(color: sliderTheme.disabledActiveTickMarkColor)
        ..circle(color: sliderTheme.disabledInactiveTickMarkColor)
        ..circle(color: sliderTheme.disabledInactiveTickMarkColor)
        ..circle(color: sliderTheme.disabledInactiveTickMarkColor)
        ..circle(color: sliderTheme.disabledThumbColor, radius: 10.0),
    );
  });

  testWidgets('Default paddle slider value indicator shape draws correctly', (WidgetTester tester) async {
    debugDisableShadows = false;
    try {
      final ThemeData theme = ThemeData(
        platform: TargetPlatform.android,
        primarySwatch: Colors.blue,
      );
      final SliderThemeData sliderTheme = theme.sliderTheme.copyWith(
        thumbColor: Colors.red.shade500,
        showValueIndicator: ShowValueIndicator.always,
        valueIndicatorShape: const PaddleSliderValueIndicatorShape(),
      );
      Widget buildApp(String value, { double sliderValue = 0.5, double textScale = 1.0 }) {
        return MaterialApp(
          home: Directionality(
            textDirection: TextDirection.ltr,
            child: MediaQuery(
              data: MediaQueryData.fromWindow(WidgetsBinding.instance.window).copyWith(textScaleFactor: textScale),
              child: Material(
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: SliderTheme(
                        data: sliderTheme,
                        child: Slider(
                          value: sliderValue,
                          label: value,
                          divisions: 3,
                          onChanged: (double d) { },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }

      await tester.pumpWidget(buildApp('1'));

      final RenderBox valueIndicatorBox = tester.renderObject(find.byType(Overlay));

      Offset center = tester.getCenter(find.byType(Slider));
      TestGesture gesture = await tester.startGesture(center);
      // Wait for value indicator animation to finish.
      await tester.pumpAndSettle();
      expect(
        valueIndicatorBox,
        paints
          ..path(
            color: sliderTheme.valueIndicatorColor,
            includes: <Offset>[
              const Offset(0.0, -40.0),
              const Offset(15.9, -40.0),
              const Offset(-15.9, -40.0),
            ],
            excludes: <Offset>[const Offset(16.1, -40.0), const Offset(-16.1, -40.0)],
          ),
      );

      await gesture.up();

      // Test that it expands with a larger label.
      await tester.pumpWidget(buildApp('1000'));
      center = tester.getCenter(find.byType(Slider));
      gesture = await tester.startGesture(center);
      // Wait for value indicator animation to finish.
      await tester.pumpAndSettle();
      expect(
        valueIndicatorBox,
        paints
          ..path(
            color: sliderTheme.valueIndicatorColor,
            includes: <Offset>[
              const Offset(0.0, -40.0),
              const Offset(35.9, -40.0),
              const Offset(-35.9, -40.0),
            ],
            excludes: <Offset>[const Offset(36.1, -40.0), const Offset(-36.1, -40.0)],
          ),
      );
      await gesture.up();

      // Test that it avoids the left edge of the screen.
      await tester.pumpWidget(buildApp('1000000', sliderValue: 0.0));
      center = tester.getCenter(find.byType(Slider));
      gesture = await tester.startGesture(center);
      // Wait for value indicator animation to finish.
      await tester.pumpAndSettle();
      expect(
        valueIndicatorBox,
        paints
          ..path(
            color: sliderTheme.valueIndicatorColor,
            includes: <Offset>[
              const Offset(0.0, -40.0),
              const Offset(92.0, -40.0),
              const Offset(-16.0, -40.0),
            ],
            excludes: <Offset>[const Offset(98.1, -40.0), const Offset(-20.1, -40.0)],
          ),
      );
      await gesture.up();

      // Test that it avoids the right edge of the screen.
      await tester.pumpWidget(buildApp('1000000', sliderValue: 1.0));
      center = tester.getCenter(find.byType(Slider));
      gesture = await tester.startGesture(center);
      // Wait for value indicator animation to finish.
      await tester.pumpAndSettle();
      expect(
        valueIndicatorBox,
        paints
          ..path(
            color: sliderTheme.valueIndicatorColor,
            includes: <Offset>[
              const Offset(0.0, -40.0),
              const Offset(16.0, -40.0),
              const Offset(-92.0, -40.0),
            ],
            excludes: <Offset>[const Offset(20.1, -40.0), const Offset(-98.1, -40.0)],
          ),
      );
      await gesture.up();

      // Test that the neck stretches when the text scale gets smaller.
      await tester.pumpWidget(buildApp('1000000', sliderValue: 0.0, textScale: 0.5));
      center = tester.getCenter(find.byType(Slider));
      gesture = await tester.startGesture(center);
      // Wait for value indicator animation to finish.
      await tester.pumpAndSettle();
      expect(
        valueIndicatorBox,
        paints
          ..path(
            color: sliderTheme.valueIndicatorColor,
            includes: <Offset>[
              const Offset(0.0, -49.0),
              const Offset(68.0, -49.0),
              const Offset(-24.0, -49.0),
            ],
            excludes: <Offset>[
              const Offset(98.0, -32.0),  // inside full size, outside small
              const Offset(-40.0, -32.0),  // inside full size, outside small
              const Offset(90.1, -49.0),
              const Offset(-40.1, -49.0),
            ],
          ),
      );
      await gesture.up();

      // Test that the neck shrinks when the text scale gets larger.
      await tester.pumpWidget(buildApp('1000000', sliderValue: 0.0, textScale: 2.5));
      center = tester.getCenter(find.byType(Slider));
      gesture = await tester.startGesture(center);
      // Wait for value indicator animation to finish.
      await tester.pumpAndSettle();
      expect(
        valueIndicatorBox,
        paints
          ..path(
            color: sliderTheme.valueIndicatorColor,
            includes: <Offset>[
              const Offset(0.0, -38.8),
              const Offset(92.0, -38.8),
              const Offset(8.0, -23.0), // Inside large, outside scale=1.0
              const Offset(-2.0, -23.0), // Inside large, outside scale=1.0
            ],
            excludes: <Offset>[
              const Offset(98.5, -38.8),
              const Offset(-16.1, -38.8),
            ],
          ),
      );
      await gesture.up();
    } finally {
      debugDisableShadows = true;
    }
  });

  testWidgets('Default paddle slider value indicator shape draws correctly', (WidgetTester tester) async {
    debugDisableShadows = false;
    try {
      final ThemeData theme = ThemeData(
        platform: TargetPlatform.android,
        primarySwatch: Colors.blue,
      );
      final SliderThemeData sliderTheme = theme.sliderTheme.copyWith(
        thumbColor: Colors.red.shade500,
        showValueIndicator: ShowValueIndicator.always,
        valueIndicatorShape: const PaddleSliderValueIndicatorShape(),
      );
      Widget buildApp(String value, { double sliderValue = 0.5, double textScale = 1.0 }) {
        return MaterialApp(
          home: Directionality(
            textDirection: TextDirection.ltr,
            child: MediaQuery(
              data: MediaQueryData.fromWindow(WidgetsBinding.instance.window).copyWith(textScaleFactor: textScale),
              child: Material(
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: SliderTheme(
                        data: sliderTheme,
                        child: Slider(
                          value: sliderValue,
                          label: value,
                          divisions: 3,
                          onChanged: (double d) { },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }

      await tester.pumpWidget(buildApp('1'));

      final RenderBox valueIndicatorBox = tester.renderObject(find.byType(Overlay));

      Offset center = tester.getCenter(find.byType(Slider));
      TestGesture gesture = await tester.startGesture(center);
      // Wait for value indicator animation to finish.
      await tester.pumpAndSettle();
      expect(
        valueIndicatorBox,
        paints
          ..path(
            color: sliderTheme.valueIndicatorColor,
            includes: <Offset>[
              const Offset(0.0, -40.0),
              const Offset(15.9, -40.0),
              const Offset(-15.9, -40.0),
            ],
            excludes: <Offset>[const Offset(16.1, -40.0), const Offset(-16.1, -40.0)],
          ),
      );

      await gesture.up();

      // Test that it expands with a larger label.
      await tester.pumpWidget(buildApp('1000'));
      center = tester.getCenter(find.byType(Slider));
      gesture = await tester.startGesture(center);
      // Wait for value indicator animation to finish.
      await tester.pumpAndSettle();
      expect(
        valueIndicatorBox,
        paints
          ..path(
            color: sliderTheme.valueIndicatorColor,
            includes: <Offset>[
              const Offset(0.0, -40.0),
              const Offset(35.9, -40.0),
              const Offset(-35.9, -40.0),
            ],
            excludes: <Offset>[const Offset(36.1, -40.0), const Offset(-36.1, -40.0)],
          ),
      );
      await gesture.up();

      // Test that it avoids the left edge of the screen.
      await tester.pumpWidget(buildApp('1000000', sliderValue: 0.0));
      center = tester.getCenter(find.byType(Slider));
      gesture = await tester.startGesture(center);
      // Wait for value indicator animation to finish.
      await tester.pumpAndSettle();
      expect(
        valueIndicatorBox,
        paints
          ..path(
            color: sliderTheme.valueIndicatorColor,
            includes: <Offset>[
              const Offset(0.0, -40.0),
              const Offset(92.0, -40.0),
              const Offset(-16.0, -40.0),
            ],
            excludes: <Offset>[const Offset(98.1, -40.0), const Offset(-20.1, -40.0)],
          ),
      );
      await gesture.up();

      // Test that it avoids the right edge of the screen.
      await tester.pumpWidget(buildApp('1000000', sliderValue: 1.0));
      center = tester.getCenter(find.byType(Slider));
      gesture = await tester.startGesture(center);
      // Wait for value indicator animation to finish.
      await tester.pumpAndSettle();
      expect(
        valueIndicatorBox,
        paints
          ..path(
            color: sliderTheme.valueIndicatorColor,
            includes: <Offset>[
              const Offset(0.0, -40.0),
              const Offset(16.0, -40.0),
              const Offset(-92.0, -40.0),
            ],
            excludes: <Offset>[const Offset(20.1, -40.0), const Offset(-98.1, -40.0)],
          ),
      );
      await gesture.up();

      // Test that the neck stretches when the text scale gets smaller.
      await tester.pumpWidget(buildApp('1000000', sliderValue: 0.0, textScale: 0.5));
      center = tester.getCenter(find.byType(Slider));
      gesture = await tester.startGesture(center);
      // Wait for value indicator animation to finish.
      await tester.pumpAndSettle();
      expect(
        valueIndicatorBox,
        paints
          ..path(
            color: sliderTheme.valueIndicatorColor,
            includes: <Offset>[
              const Offset(0.0, -49.0),
              const Offset(68.0, -49.0),
              const Offset(-24.0, -49.0),
            ],
            excludes: <Offset>[
              const Offset(98.0, -32.0),  // inside full size, outside small
              const Offset(-40.0, -32.0),  // inside full size, outside small
              const Offset(90.1, -49.0),
              const Offset(-40.1, -49.0),
            ],
          ),
      );
      await gesture.up();

      // Test that the neck shrinks when the text scale gets larger.
      await tester.pumpWidget(buildApp('1000000', sliderValue: 0.0, textScale: 2.5));
      center = tester.getCenter(find.byType(Slider));
      gesture = await tester.startGesture(center);
      // Wait for value indicator animation to finish.
      await tester.pumpAndSettle();
      expect(
        valueIndicatorBox,
        paints
          ..path(
            color: sliderTheme.valueIndicatorColor,
            includes: <Offset>[
              const Offset(0.0, -38.8),
              const Offset(92.0, -38.8),
              const Offset(8.0, -23.0), // Inside large, outside scale=1.0
              const Offset(-2.0, -23.0), // Inside large, outside scale=1.0
            ],
            excludes: <Offset>[
              const Offset(98.5, -38.8),
              const Offset(-16.1, -38.8),
            ],
          ),
      );
      await gesture.up();
    } finally {
      debugDisableShadows = true;
    }
  });

  testWidgets('The slider track height can be overridden', (WidgetTester tester) async {
    final SliderThemeData sliderTheme = ThemeData().sliderTheme.copyWith(trackHeight: 16);
    const Radius radius = Radius.circular(8);
    const Radius activatedRadius = Radius.circular(9);

    await tester.pumpWidget(_buildApp(sliderTheme, value: 0.25));

    final MaterialInkController material = Material.of(tester.element(find.byType(Slider)))!;

    // Top and bottom are centerY (300) + and - trackRadius (8).
    expect(
      material,
      paints
        ..rrect(rrect: RRect.fromLTRBAndCorners(24.0, 291.0, 212.0, 309.0, topLeft: activatedRadius, bottomLeft: activatedRadius), color: sliderTheme.activeTrackColor)
        ..rrect(rrect: RRect.fromLTRBAndCorners(212.0, 292.0, 776.0, 308.0, topRight: radius, bottomRight: radius), color: sliderTheme.inactiveTrackColor),
    );

    await tester.pumpWidget(_buildApp(sliderTheme, value: 0.25, enabled: false));
    await tester.pumpAndSettle(); // wait for disable animation

    // The disabled thumb is smaller so the active track has to paint longer to
    // get to the edge.
    expect(
      material,
      paints
        ..rrect(rrect: RRect.fromLTRBAndCorners(24.0, 291.0, 212.0, 309.0, topLeft: activatedRadius, bottomLeft: activatedRadius), color: sliderTheme.disabledActiveTrackColor)
        ..rrect(rrect: RRect.fromLTRBAndCorners(212.0, 292.0, 776.0, 308.0, topRight: radius, bottomRight: radius), color: sliderTheme.disabledInactiveTrackColor),
    );
  });

  testWidgets('The default slider thumb shape sizes can be overridden', (WidgetTester tester) async {
    final SliderThemeData sliderTheme = ThemeData().sliderTheme.copyWith(
      thumbShape: const RoundSliderThumbShape(
        enabledThumbRadius: 7,
        disabledThumbRadius: 11,
      ),
    );

    await tester.pumpWidget(_buildApp(sliderTheme, value: 0.25));
    final MaterialInkController material = Material.of(tester.element(find.byType(Slider)))!;

    expect(
      material,
      paints..circle(x: 212, y: 300, radius: 7, color: sliderTheme.thumbColor),
    );

    await tester.pumpWidget(_buildApp(sliderTheme, value: 0.25, enabled: false));
    await tester.pumpAndSettle(); // wait for disable animation

    expect(
      material,
      paints..circle(x: 212, y: 300, radius: 11, color: sliderTheme.disabledThumbColor),
    );
  });

  testWidgets('The default slider thumb shape disabled size can be inferred from the enabled size', (WidgetTester tester) async {
    final SliderThemeData sliderTheme = ThemeData().sliderTheme.copyWith(
      thumbShape: const RoundSliderThumbShape(
        enabledThumbRadius: 9,
      ),
    );

    await tester.pumpWidget(_buildApp(sliderTheme, value: 0.25));
    final MaterialInkController material = Material.of(tester.element(find.byType(Slider)))!;

    expect(
      material,
      paints..circle(x: 212, y: 300, radius: 9, color: sliderTheme.thumbColor),
    );

    await tester.pumpWidget(_buildApp(sliderTheme, value: 0.25, enabled: false));
    await tester.pumpAndSettle(); // wait for disable animation
    expect(
      material,
      paints..circle(x: 212, y: 300, radius: 9, color: sliderTheme.disabledThumbColor),
    );
  });

  testWidgets('The default slider tick mark shape size can be overridden', (WidgetTester tester) async {
    final SliderThemeData sliderTheme = ThemeData().sliderTheme.copyWith(
      tickMarkShape: const RoundSliderTickMarkShape(tickMarkRadius: 5),
      activeTickMarkColor: const Color(0xfadedead),
      inactiveTickMarkColor: const Color(0xfadebeef),
      disabledActiveTickMarkColor: const Color(0xfadecafe),
      disabledInactiveTickMarkColor: const Color(0xfadeface),
    );

    await tester.pumpWidget(_buildApp(sliderTheme, value: 0.5, divisions: 2));

    final MaterialInkController material = Material.of(tester.element(find.byType(Slider)))!;

    expect(
      material,
      paints
        ..circle(x: 26, y: 300, radius: 5, color: sliderTheme.activeTickMarkColor)
        ..circle(x: 400, y: 300, radius: 5, color: sliderTheme.activeTickMarkColor)
        ..circle(x: 774, y: 300, radius: 5, color: sliderTheme.inactiveTickMarkColor),
    );

    await tester.pumpWidget(_buildApp(sliderTheme, value: 0.5, divisions: 2,  enabled: false));
    await tester.pumpAndSettle();

    expect(
      material,
      paints
        ..circle(x: 26, y: 300, radius: 5, color: sliderTheme.disabledActiveTickMarkColor)
        ..circle(x: 400, y: 300, radius: 5, color: sliderTheme.disabledActiveTickMarkColor)
        ..circle(x: 774, y: 300, radius: 5, color: sliderTheme.disabledInactiveTickMarkColor),
    );
  });

  testWidgets('The default slider overlay shape size can be overridden', (WidgetTester tester) async {
    const double uniqueOverlayRadius = 23;
    final SliderThemeData sliderTheme = ThemeData().sliderTheme.copyWith(
      overlayShape: const RoundSliderOverlayShape(
        overlayRadius: uniqueOverlayRadius,
      ),
    );

    await tester.pumpWidget(_buildApp(sliderTheme, value: 0.5));
    // Tap center and wait for animation.
    final Offset center = tester.getCenter(find.byType(Slider));
    await tester.startGesture(center);
    await tester.pumpAndSettle();

    final MaterialInkController material = Material.of(tester.element(find.byType(Slider)))!;
    expect(
      material,
      paints..circle(
        x: center.dx,
        y: center.dy,
        radius: uniqueOverlayRadius,
        color: sliderTheme.overlayColor,
      ),
    );
  });

  // Regression test for https://github.com/flutter/flutter/issues/74503
  testWidgets('The slider track layout correctly when the overlay size is smaller than the thumb size', (WidgetTester tester) async {
    final SliderThemeData sliderTheme = ThemeData().sliderTheme.copyWith(
      overlayShape: SliderComponentShape.noOverlay,
    );

    await tester.pumpWidget(_buildApp(sliderTheme, value: 0.5));

    final MaterialInkController material = Material.of(
      tester.element(find.byType(Slider)),
    )!;

    // The track rectangle begins at 10 pixels from the left of the screen and ends 10 pixels from the right
    // (790 pixels from the left). The main check here it that the track itself should be centered on
    // the 800 pixel-wide screen.
    expect(
      material,
      paints
        // active track RRect. Starts 10 pixels from left of screen.
        ..rrect(rrect: RRect.fromLTRBAndCorners(
            10.0,
            297.0,
            400.0,
            303.0,
            topLeft: const Radius.circular(3.0),
            bottomLeft: const Radius.circular(3.0),
        ))
        // inactive track RRect. Ends 10 pixels from right of screen.
        ..rrect(rrect: RRect.fromLTRBAndCorners(
            400.0,
            298.0,
            790.0,
            302.0,
            topRight: const Radius.circular(2.0),
            bottomRight: const Radius.circular(2.0),
        ))
        // The thumb.
        ..circle(x: 400.0, y: 300.0, radius: 10.0),
    );
  });

  // Only the thumb, overlay, and tick mark have special shortcuts to provide
  // no-op or empty shapes.
  //
  // The track can also be skipped by providing 0 height.
  //
  // The value indicator can be skipped by passing the appropriate
  // [ShowValueIndicator].
  testWidgets('The slider can skip all of its component painting', (WidgetTester tester) async {
    // Pump a slider with all shapes skipped.
    await tester.pumpWidget(_buildApp(
      ThemeData().sliderTheme.copyWith(
        trackHeight: 0,
        overlayShape: SliderComponentShape.noOverlay,
        thumbShape: SliderComponentShape.noThumb,
        tickMarkShape: SliderTickMarkShape.noTickMark,
        showValueIndicator: ShowValueIndicator.never,
      ),
      value: 0.5,
      divisions: 4,
    ));

    final MaterialInkController material = Material.of(tester.element(find.byType(Slider)))!;

    expect(material, paintsExactlyCountTimes(#drawRect, 0));
    expect(material, paintsExactlyCountTimes(#drawCircle, 0));
    expect(material, paintsExactlyCountTimes(#drawPath, 0));
  });

  testWidgets('The slider can skip all component painting except the track', (WidgetTester tester) async {
    // Pump a slider with just a track.
    await tester.pumpWidget(_buildApp(
      ThemeData().sliderTheme.copyWith(
        overlayShape: SliderComponentShape.noOverlay,
        thumbShape: SliderComponentShape.noThumb,
        tickMarkShape: SliderTickMarkShape.noTickMark,
        showValueIndicator: ShowValueIndicator.never,
      ),
      value: 0.5,
      divisions: 4,
    ));

    final MaterialInkController material = Material.of(tester.element(find.byType(Slider)))!;

    // Only 2 track segments.
    expect(material, paintsExactlyCountTimes(#drawRRect, 2));
    expect(material, paintsExactlyCountTimes(#drawCircle, 0));
    expect(material, paintsExactlyCountTimes(#drawPath, 0));
  });

  testWidgets('The slider can skip all component painting except the tick marks', (WidgetTester tester) async {
    // Pump a slider with just tick marks.
    await tester.pumpWidget(_buildApp(
      ThemeData().sliderTheme.copyWith(
        trackHeight: 0,
        overlayShape: SliderComponentShape.noOverlay,
        thumbShape: SliderComponentShape.noThumb,
        showValueIndicator: ShowValueIndicator.never,
        // When the track is hidden to 0 height, a tick mark radius
        // must be provided to get a non-zero radius.
        tickMarkShape: const RoundSliderTickMarkShape(tickMarkRadius: 1),
      ),
      value: 0.5,
      divisions: 4,
    ));

    final MaterialInkController material = Material.of(tester.element(find.byType(Slider)))!;

    // Only 5 tick marks.
    expect(material, paintsExactlyCountTimes(#drawRect, 0));
    expect(material, paintsExactlyCountTimes(#drawCircle, 5));
    expect(material, paintsExactlyCountTimes(#drawPath, 0));
  });

  testWidgets('The slider can skip all component painting except the thumb', (WidgetTester tester) async {
    debugDisableShadows = false;
    try {
      // Pump a slider with just a thumb.
      await tester.pumpWidget(_buildApp(
        ThemeData().sliderTheme.copyWith(
          trackHeight: 0,
          overlayShape: SliderComponentShape.noOverlay,
          tickMarkShape: SliderTickMarkShape.noTickMark,
          showValueIndicator: ShowValueIndicator.never,
        ),
        value: 0.5,
        divisions: 4,
      ));

      final MaterialInkController material = Material.of(tester.element(find.byType(Slider)))!;

      // Only 1 thumb.
      expect(material, paintsExactlyCountTimes(#drawRect, 0));
      expect(material, paintsExactlyCountTimes(#drawCircle, 1));
      expect(material, paintsExactlyCountTimes(#drawPath, 0));
    } finally {
      debugDisableShadows = true;
    }
  });

  testWidgets('The slider can skip all component painting except the overlay', (WidgetTester tester) async {
    // Pump a slider with just an overlay.
    await tester.pumpWidget(_buildApp(
      ThemeData().sliderTheme.copyWith(
        trackHeight: 0,
        thumbShape: SliderComponentShape.noThumb,
        tickMarkShape: SliderTickMarkShape.noTickMark,
        showValueIndicator: ShowValueIndicator.never,
      ),
      value: 0.5,
      divisions: 4,
    ));

    final MaterialInkController material = Material.of(tester.element(find.byType(Slider)))!;

    // Tap the center of the track and wait for animations to finish.
    final Offset center = tester.getCenter(find.byType(Slider));
    final TestGesture gesture = await tester.startGesture(center);
    await tester.pumpAndSettle();

    // Only 1 overlay.
    expect(material, paintsExactlyCountTimes(#drawRect, 0));
    expect(material, paintsExactlyCountTimes(#drawCircle, 1));
    expect(material, paintsExactlyCountTimes(#drawPath, 0));

    await gesture.up();
  });

  testWidgets('The slider can skip all component painting except the value indicator', (WidgetTester tester) async {
    // Pump a slider with just a value indicator.
    await tester.pumpWidget(_buildApp(
      ThemeData().sliderTheme.copyWith(
        trackHeight: 0,
        overlayShape: SliderComponentShape.noOverlay,
        thumbShape: SliderComponentShape.noThumb,
        tickMarkShape: SliderTickMarkShape.noTickMark,
        showValueIndicator: ShowValueIndicator.always,
      ),
      value: 0.5,
      divisions: 4,
    ));

    final MaterialInkController material = Material.of(tester.element(find.byType(Slider)))!;
    final RenderBox valueIndicatorBox = tester.renderObject(find.byType(Overlay));

    // Tap the center of the track and wait for animations to finish.
    final Offset center = tester.getCenter(find.byType(Slider));
    final TestGesture gesture = await tester.startGesture(center);
    await tester.pumpAndSettle();

    // Only 1 value indicator.
    expect(material, paintsExactlyCountTimes(#drawRect, 0));
    expect(material, paintsExactlyCountTimes(#drawCircle, 0));
    expect(valueIndicatorBox, paintsExactlyCountTimes(#drawPath, 1));

    await gesture.up();
  });

  testWidgets('PaddleSliderValueIndicatorShape skips all painting at zero scale', (WidgetTester tester) async {
    // Pump a slider with just a value indicator.
    await tester.pumpWidget(_buildApp(
      ThemeData().sliderTheme.copyWith(
        trackHeight: 0,
        overlayShape: SliderComponentShape.noOverlay,
        thumbShape: SliderComponentShape.noThumb,
        tickMarkShape: SliderTickMarkShape.noTickMark,
        showValueIndicator: ShowValueIndicator.always,
        valueIndicatorShape: const PaddleSliderValueIndicatorShape(),
      ),
      value: 0.5,
      divisions: 4,
    ));

    final MaterialInkController material = Material.of(tester.element(find.byType(Slider)))!;
    final RenderBox valueIndicatorBox = tester.renderObject(find.byType(Overlay));

    // Tap the center of the track to kick off the animation of the value indicator.
    final Offset center = tester.getCenter(find.byType(Slider));
    final TestGesture gesture = await tester.startGesture(center);

    // Nothing to paint at scale 0.
    await tester.pump();
    expect(material, paintsExactlyCountTimes(#drawRect, 0));
    expect(material, paintsExactlyCountTimes(#drawCircle, 0));
    expect(valueIndicatorBox, paintsExactlyCountTimes(#drawPath, 0));

    // Painting a path for the value indicator.
    await tester.pump(const Duration(milliseconds: 16));
    expect(valueIndicatorBox, paintsExactlyCountTimes(#drawPath, 1));

    await gesture.up();
  });

  testWidgets('Default slider value indicator shape skips all painting at zero scale', (WidgetTester tester) async {
    // Pump a slider with just a value indicator.
    await tester.pumpWidget(_buildApp(
      ThemeData().sliderTheme.copyWith(
        trackHeight: 0,
        overlayShape: SliderComponentShape.noOverlay,
        thumbShape: SliderComponentShape.noThumb,
        tickMarkShape: SliderTickMarkShape.noTickMark,
        showValueIndicator: ShowValueIndicator.always,
      ),
      value: 0.5,
      divisions: 4,
    ));

    final RenderBox valueIndicatorBox = tester.renderObject(find.byType(Overlay));

    // Tap the center of the track to kick off the animation of the value indicator.
    final Offset center = tester.getCenter(find.byType(Slider));
    final TestGesture gesture = await tester.startGesture(center);

    // Nothing to paint at scale 0.
    await tester.pump();
    expect(valueIndicatorBox, paintsExactlyCountTimes(#drawPath, 0));

    // Painting a path for the value indicator.
    await tester.pump(const Duration(milliseconds: 16));
    expect(valueIndicatorBox, paintsExactlyCountTimes(#drawPath, 1));

    await gesture.up();
  });


  testWidgets('Default paddle range slider value indicator shape draws correctly', (WidgetTester tester) async {
    debugDisableShadows = false;
    try {
      final ThemeData theme = ThemeData(
        platform: TargetPlatform.android,
        primarySwatch: Colors.blue,
      );
      final SliderThemeData sliderTheme = theme.sliderTheme.copyWith(
        thumbColor: Colors.red.shade500,
        showValueIndicator: ShowValueIndicator.always,
        rangeValueIndicatorShape: const PaddleRangeSliderValueIndicatorShape(),
      );

      await tester.pumpWidget(_buildRangeApp(sliderTheme));

      final RenderBox valueIndicatorBox = tester.renderObject(find.byType(Overlay));

      final Offset center = tester.getCenter(find.byType(RangeSlider));
      final TestGesture gesture = await tester.startGesture(center);
      // Wait for value indicator animation to finish.
      await tester.pumpAndSettle();
      expect(
        valueIndicatorBox,
        paints
          // physical model
          ..rrect()
          ..rrect(rrect: RRect.fromLTRBAndCorners(
            24.0, 298.0, 24.0, 302.0,
            topLeft: const Radius.circular(2.0),
            bottomLeft: const Radius.circular(2.0),
          ))
          ..rect(rect: const Rect.fromLTRB(24.0, 297.0, 24.0, 303.0))
          ..rrect(rrect: RRect.fromLTRBAndCorners(
            24.0, 298.0, 776.0, 302.0,
            topRight: const Radius.circular(2.0),
            bottomRight: const Radius.circular(2.0),
          ))
          ..circle(x: 24.0, y: 300.0)
          ..shadow(elevation: 1.0)
          ..circle(x: 24.0, y: 300.0)
          ..shadow(elevation: 6.0)
          ..circle(x: 24.0, y: 300.0),
      );

      await gesture.up();
    } finally {
      debugDisableShadows = true;
    }
  });

  testWidgets('Default paddle range slider value indicator shape draws correctly with debugDisableShadows', (WidgetTester tester) async {
    debugDisableShadows = true;
    final ThemeData theme = ThemeData(
      platform: TargetPlatform.android,
      primarySwatch: Colors.blue,
    );
    final SliderThemeData sliderTheme = theme.sliderTheme.copyWith(
      thumbColor: Colors.red.shade500,
      showValueIndicator: ShowValueIndicator.always,
      rangeValueIndicatorShape: const PaddleRangeSliderValueIndicatorShape(),
    );

    await tester.pumpWidget(_buildRangeApp(sliderTheme));

    final RenderBox valueIndicatorBox = tester.renderObject(find.byType(Overlay));

    final Offset center = tester.getCenter(find.byType(RangeSlider));
    final TestGesture gesture = await tester.startGesture(center);
    // Wait for value indicator animation to finish.
    await tester.pumpAndSettle();
    expect(
      valueIndicatorBox,
      paints
        // physical model
        ..rrect()
        ..rrect(rrect: RRect.fromLTRBAndCorners(
          24.0, 298.0, 24.0, 302.0,
          topLeft: const Radius.circular(2.0),
          bottomLeft: const Radius.circular(2.0),
        ))
        ..rect(rect: const Rect.fromLTRB(24.0, 297.0, 24.0, 303.0))
        ..rrect(rrect: RRect.fromLTRBAndCorners(
          24.0, 298.0, 776.0, 302.0,
          topRight: const Radius.circular(2.0),
          bottomRight: const Radius.circular(2.0),
        ))
        ..circle(x: 24.0, y: 300.0)
        ..path(strokeWidth: 1.0 * 2.0, color: Colors.black)
        ..circle(x: 24.0, y: 300.0)
        ..path(strokeWidth: 6.0 * 2.0, color: Colors.black)
        ..circle(x: 24.0, y: 300.0),
    );

    await gesture.up();
  });

  testWidgets('PaddleRangeSliderValueIndicatorShape skips all painting at zero scale', (WidgetTester tester) async {
    debugDisableShadows = false;
    try {
      // Pump a slider with just a value indicator.
      await tester.pumpWidget(_buildRangeApp(
        ThemeData().sliderTheme.copyWith(
          trackHeight: 0,
          rangeValueIndicatorShape: const PaddleRangeSliderValueIndicatorShape(),
        ),
        values: const RangeValues(0, 0.5),
        divisions: 4,
      ));

      //  final RenderBox sliderBox = tester.firstRenderObject<RenderBox>(find.byType(RangeSlider));
      final RenderBox valueIndicatorBox = tester.renderObject(find.byType(Overlay));

      // Tap the center of the track to kick off the animation of the value indicator.
      final Offset center = tester.getCenter(find.byType(RangeSlider));
      final TestGesture gesture = await tester.startGesture(center);

      // No value indicator path to paint at scale 0.
      await tester.pump();
      expect(valueIndicatorBox, paintsExactlyCountTimes(#drawPath, 0));

      // Painting a path for each value indicator.
      await tester.pump(const Duration(milliseconds: 16));
      expect(valueIndicatorBox, paintsExactlyCountTimes(#drawPath, 2));

      await gesture.up();
    } finally {
      debugDisableShadows = true;
    }
  });

  testWidgets('Default range indicator shape skips all painting at zero scale', (WidgetTester tester) async {
    debugDisableShadows = false;
    try {
      // Pump a slider with just a value indicator.
      await tester.pumpWidget(_buildRangeApp(
        ThemeData().sliderTheme.copyWith(
          trackHeight: 0,
          overlayShape: SliderComponentShape.noOverlay,
          thumbShape: SliderComponentShape.noThumb,
          tickMarkShape: SliderTickMarkShape.noTickMark,
          showValueIndicator: ShowValueIndicator.always,
        ),
        values: const RangeValues(0, 0.5),
        divisions: 4,
      ));

      final RenderBox valueIndicatorBox = tester.renderObject(find.byType(Overlay));

      // Tap the center of the track to kick off the animation of the value indicator.
      final Offset center = tester.getCenter(find.byType(RangeSlider));
      final TestGesture gesture = await tester.startGesture(center);

      // No value indicator path to paint at scale 0.
      await tester.pump();
      expect(valueIndicatorBox, paintsExactlyCountTimes(#drawPath, 0));

      // Painting a path for each value indicator.
      await tester.pump(const Duration(milliseconds: 16));
      expect(valueIndicatorBox, paintsExactlyCountTimes(#drawPath, 2));

      await gesture.up();
    } finally {
      debugDisableShadows = true;
    }
  });

  testWidgets('activeTrackRadius is taken into account when painting the border of the active track', (WidgetTester tester) async {
    await tester.pumpWidget(_buildApp(
      ThemeData().sliderTheme.copyWith(
        trackShape: const RoundedRectSliderTrackShapeWithCustomAdditionalActiveTrackHeight(
          additionalActiveTrackHeight: 10.0
        )
      )
    ));
    await tester.pumpAndSettle();
    final Offset center = tester.getCenter(find.byType(Slider));
    await tester.startGesture(center);
    expect(
      find.byType(Slider),
      paints
        ..rrect(rrect: RRect.fromLTRBAndCorners(
          24.0, 293.0, 24.0, 307.0,
          topLeft: const Radius.circular(7.0),
          bottomLeft: const Radius.circular(7.0),
        ))
        ..rrect(rrect: RRect.fromLTRBAndCorners(
          24.0, 298.0, 776.0, 302.0,
          topRight: const Radius.circular(2.0),
          bottomRight: const Radius.circular(2.0),
        )),
    );
  });

  testWidgets('The mouse cursor is themeable', (WidgetTester tester) async {
    await tester.pumpWidget(_buildApp(
      ThemeData().sliderTheme.copyWith(
        mouseCursor: const MaterialStatePropertyAll<MouseCursor>(SystemMouseCursors.text),
      )
    ));

    await tester.pumpAndSettle();
    final TestGesture gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer();
    await gesture.moveTo(tester.getCenter(find.byType(Slider)));
    await tester.pumpAndSettle();
    expect(RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1), SystemMouseCursors.text);
  });
}

class RoundedRectSliderTrackShapeWithCustomAdditionalActiveTrackHeight extends RoundedRectSliderTrackShape {
  const RoundedRectSliderTrackShapeWithCustomAdditionalActiveTrackHeight({required this.additionalActiveTrackHeight});
  final double additionalActiveTrackHeight;
  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required TextDirection textDirection,
    required Offset thumbCenter,
    bool isDiscrete = false,
    bool isEnabled = false,
    double additionalActiveTrackHeight = 2.0,
  }) {
    super.paint(context, offset, parentBox: parentBox, sliderTheme: sliderTheme, enableAnimation: enableAnimation, textDirection: textDirection, thumbCenter: thumbCenter, additionalActiveTrackHeight: this.additionalActiveTrackHeight);
  }
}

Widget _buildApp(
    SliderThemeData sliderTheme, {
      double value = 0.0,
      bool enabled = true,
      int? divisions,
    }) {
  final ValueChanged<double>? onChanged = enabled ? (double d) => value = d : null;
  return MaterialApp(
    home: Scaffold(
      body: Center(
        child: SliderTheme(
          data: sliderTheme,
          child: Slider(
            value: value,
            label: '$value',
            onChanged: onChanged,
            divisions: divisions,
          ),
        ),
      ),
    ),
  );
}

Widget _buildRangeApp(
    SliderThemeData sliderTheme, {
      RangeValues values = const RangeValues(0, 0),
      bool enabled = true,
      int? divisions,
    }) {
  final ValueChanged<RangeValues>? onChanged = enabled ? (RangeValues d) => values = d : null;
  return MaterialApp(
    home: Scaffold(
      body: Center(
        child: SliderTheme(
          data: sliderTheme,
          child: RangeSlider(
            values: values,
            labels: RangeLabels(values.start.toString(), values.end.toString()),
            onChanged: onChanged,
            divisions: divisions,
          ),
        ),
      ),
    ),
  );
}
