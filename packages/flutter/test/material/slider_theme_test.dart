// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show window;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/painting.dart';

import '../rendering/mock_canvas.dart';

void main() {
  testWidgets('Slider theme is built by ThemeData', (WidgetTester tester) async {
    final ThemeData theme = ThemeData(
      platform: TargetPlatform.android,
      primarySwatch: Colors.red,
    );
    final SliderThemeData sliderTheme = theme.sliderTheme;

    expect(sliderTheme.activeTrackColor.value, equals(Colors.red.value));
    expect(sliderTheme.inactiveTrackColor.value, equals(Colors.red.withAlpha(0x3d).value));
  });

  testWidgets('Slider uses ThemeData slider theme if present', (WidgetTester tester) async {
    final ThemeData theme = ThemeData(
      platform: TargetPlatform.android,
      primarySwatch: Colors.red,
    );
    final SliderThemeData sliderTheme = theme.sliderTheme;

    Widget buildSlider(SliderThemeData data) {
      return Directionality(
        textDirection: TextDirection.ltr,
        child: MediaQuery(
          data: MediaQueryData.fromWindow(window),
          child: Material(
            child: Center(
              child: Theme(
                data: theme,
                child: const Slider(
                  value: 0.5,
                  label: '0.5',
                  onChanged: null,
                ),
              ),
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(buildSlider(sliderTheme));

    final RenderBox sliderBox = tester.firstRenderObject<RenderBox>(find.byType(Slider));

    expect(sliderBox, paints..rect(color: sliderTheme.disabledActiveTrackColor)..rect(color: sliderTheme.disabledInactiveTrackColor));
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

    Widget buildSlider(SliderThemeData data) {
      return Directionality(
        textDirection: TextDirection.ltr,
        child: MediaQuery(
          data: MediaQueryData.fromWindow(window),
          child: Material(
            child: Center(
              child: Theme(
                data: theme,
                child: SliderTheme(
                  data: customTheme,
                  child: const Slider(
                    value: 0.5,
                    label: '0.5',
                    onChanged: null,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(buildSlider(sliderTheme));

    final RenderBox sliderBox = tester.firstRenderObject<RenderBox>(find.byType(Slider));

    expect(sliderBox, paints..rect(color: customTheme.disabledActiveTrackColor)..rect(color: customTheme.disabledInactiveTrackColor));
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
      valueIndicatorTextStyle: ThemeData.fallback().accentTextTheme.body2.copyWith(color: customColor4),
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
    expect(sliderTheme.overlayColor, equals(customColor1.withAlpha(0x29)));
    expect(sliderTheme.valueIndicatorColor, equals(customColor1.withAlpha(0xff)));
    expect(sliderTheme.thumbShape, equals(isInstanceOf<RoundSliderThumbShape>()));
    expect(sliderTheme.valueIndicatorShape, equals(isInstanceOf<PaddleSliderValueIndicatorShape>()));
    expect(sliderTheme.showValueIndicator, equals(ShowValueIndicator.onlyForDiscrete));
    expect(sliderTheme.valueIndicatorTextStyle.color, equals(customColor4));
  });

  testWidgets('SliderThemeData lerps correctly', (WidgetTester tester) async {
    final SliderThemeData sliderThemeBlack = SliderThemeData.fromPrimaryColors(
      primaryColor: Colors.black,
      primaryColorDark: Colors.black,
      primaryColorLight: Colors.black,
      valueIndicatorTextStyle: ThemeData.fallback().accentTextTheme.body2.copyWith(color: Colors.black),
    );
    final SliderThemeData sliderThemeWhite = SliderThemeData.fromPrimaryColors(
      primaryColor: Colors.white,
      primaryColorDark: Colors.white,
      primaryColorLight: Colors.white,
      valueIndicatorTextStyle: ThemeData.fallback().accentTextTheme.body2.copyWith(color: Colors.white),
    );
    final SliderThemeData lerp = SliderThemeData.lerp(sliderThemeBlack, sliderThemeWhite, 0.5);
    const Color middleGrey = Color(0xff7f7f7f);
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
    expect(lerp.overlayColor, equals(middleGrey.withAlpha(0x29)));
    expect(lerp.valueIndicatorColor, equals(middleGrey.withAlpha(0xff)));
    expect(lerp.valueIndicatorTextStyle.color, equals(middleGrey.withAlpha(0xff)));
  });

  testWidgets('Default slider thumb shape draws correctly', (WidgetTester tester) async {
    final ThemeData theme = ThemeData(
      platform: TargetPlatform.android,
      primarySwatch: Colors.blue,
    );
    final SliderThemeData sliderTheme = theme.sliderTheme.copyWith(thumbColor: Colors.red.shade500);
    double value = 0.45;
    Widget buildApp({
      int divisions,
      bool enabled = true,
    }) {
      final ValueChanged<double> onChanged = enabled ? (double d) => value = d : null;
      return Directionality(
        textDirection: TextDirection.ltr,
        child: MediaQuery(
          data: MediaQueryData.fromWindow(window),
          child: Material(
            child: Center(
              child: SliderTheme(
                data: sliderTheme,
                child: Slider(
                  value: value,
                  label: '$value',
                  divisions: divisions,
                  onChanged: onChanged,
                ),
              ),
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(buildApp());

    final RenderBox sliderBox = tester.firstRenderObject<RenderBox>(find.byType(Slider));

    expect(sliderBox, paints..circle(color: sliderTheme.thumbColor, radius: 6.0));

    await tester.pumpWidget(buildApp(enabled: false));
    await tester.pumpAndSettle(); // wait for disable animation
    expect(sliderBox, paints..circle(color: sliderTheme.disabledThumbColor, radius: 4.0));

    await tester.pumpWidget(buildApp(divisions: 3));
    await tester.pumpAndSettle(); // wait for disable animation
    expect(
        sliderBox,
        paints
          ..circle(color: sliderTheme.activeTickMarkColor)
          ..circle(color: sliderTheme.activeTickMarkColor)
          ..circle(color: sliderTheme.inactiveTickMarkColor)
          ..circle(color: sliderTheme.inactiveTickMarkColor)
          ..circle(color: sliderTheme.thumbColor, radius: 6.0));

    await tester.pumpWidget(buildApp(divisions: 3, enabled: false));
    await tester.pumpAndSettle(); // wait for disable animation
    expect(
        sliderBox,
        paints
          ..circle(color: sliderTheme.disabledActiveTickMarkColor)
          ..circle(color: sliderTheme.disabledInactiveTickMarkColor)
          ..circle(color: sliderTheme.disabledInactiveTickMarkColor)
          ..circle(color: sliderTheme.disabledThumbColor, radius: 4.0));
  });

  testWidgets('Default slider value indicator shape draws correctly', (WidgetTester tester) async {
    final ThemeData theme = ThemeData(
      platform: TargetPlatform.android,
      primarySwatch: Colors.blue,
    );
    final SliderThemeData sliderTheme = theme.sliderTheme.copyWith(thumbColor: Colors.red.shade500, showValueIndicator: ShowValueIndicator.always);
    Widget buildApp(String value, {double sliderValue = 0.5, double textScale = 1.0}) {
      return Directionality(
        textDirection: TextDirection.ltr,
        child: MediaQuery(
          data: MediaQueryData.fromWindow(window).copyWith(textScaleFactor: textScale),
          child: Material(
            child: Row(
              children: <Widget>[
                Expanded(
                  child: SliderTheme(
                    data: sliderTheme,
                    child: Slider(
                      value: sliderValue,
                      label: '$value',
                      divisions: 3,
                      onChanged: (double d) {},
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(buildApp('1'));

    final RenderBox sliderBox = tester.firstRenderObject<RenderBox>(find.byType(Slider));

    Offset center = tester.getCenter(find.byType(Slider));
    TestGesture gesture = await tester.startGesture(center);
    // Wait for value indicator animation to finish.
    await tester.pumpAndSettle();
    expect(
        sliderBox,
        paints
          ..path(
            color: sliderTheme.valueIndicatorColor,
            includes: <Offset>[
              const Offset(0.0, -40.0),
              const Offset(15.9, -40.0),
              const Offset(-15.9, -40.0),
            ],
            excludes: <Offset>[const Offset(16.1, -40.0), const Offset(-16.1, -40.0)],
          ));

    await gesture.up();

    // Test that it expands with a larger label.
    await tester.pumpWidget(buildApp('1000'));
    center = tester.getCenter(find.byType(Slider));
    gesture = await tester.startGesture(center);
    // Wait for value indicator animation to finish.
    await tester.pumpAndSettle();
    expect(
        sliderBox,
        paints
          ..path(
            color: sliderTheme.valueIndicatorColor,
            includes: <Offset>[
              const Offset(0.0, -40.0),
              const Offset(35.9, -40.0),
              const Offset(-35.9, -40.0),
            ],
            excludes: <Offset>[const Offset(36.1, -40.0), const Offset(-36.1, -40.0)],
          ));
    await gesture.up();

    // Test that it avoids the left edge of the screen.
    await tester.pumpWidget(buildApp('1000000', sliderValue: 0.0));
    center = tester.getCenter(find.byType(Slider));
    gesture = await tester.startGesture(center);
    // Wait for value indicator animation to finish.
    await tester.pumpAndSettle();
    expect(
        sliderBox,
        paints
          ..path(
            color: sliderTheme.valueIndicatorColor,
            includes: <Offset>[
              const Offset(0.0, -40.0),
              const Offset(98.0, -40.0),
              const Offset(-16.0, -40.0),
            ],
            excludes: <Offset>[const Offset(98.1, -40.0), const Offset(-16.1, -40.0)],
          ));
    await gesture.up();

    // Test that it avoids the right edge of the screen.
    await tester.pumpWidget(buildApp('1000000', sliderValue: 1.0));
    center = tester.getCenter(find.byType(Slider));
    gesture = await tester.startGesture(center);
    // Wait for value indicator animation to finish.
    await tester.pumpAndSettle();
    expect(
        sliderBox,
        paints
          ..path(
            color: sliderTheme.valueIndicatorColor,
            includes: <Offset>[
              const Offset(0.0, -40.0),
              const Offset(16.0, -40.0),
              const Offset(-98.0, -40.0),
            ],
            excludes: <Offset>[const Offset(16.1, -40.0), const Offset(-98.1, -40.0)],
          ));
    await gesture.up();

    // Test that the neck stretches when the text scale gets smaller.
    await tester.pumpWidget(buildApp('1000000', sliderValue: 0.0, textScale: 0.5));
    center = tester.getCenter(find.byType(Slider));
    gesture = await tester.startGesture(center);
    // Wait for value indicator animation to finish.
    await tester.pumpAndSettle();
    expect(
        sliderBox,
        paints
          ..path(
            color: sliderTheme.valueIndicatorColor,
            includes: <Offset>[
              const Offset(0.0, -49.0),
              const Offset(90.0, -49.0),
              const Offset(-24.0, -49.0),
            ],
            excludes: <Offset>[
              const Offset(98.0, -32.0),  // inside full size, outside small
              const Offset(-16.0, -32.0),  // inside full size, outside small
              const Offset(90.1, -49.0),
              const Offset(-24.1, -49.0),
            ],
          ));
    await gesture.up();

    // Test that the neck shrinks when the text scale gets larger.
    await tester.pumpWidget(buildApp('1000000', sliderValue: 0.0, textScale: 2.5));
    center = tester.getCenter(find.byType(Slider));
    gesture = await tester.startGesture(center);
    // Wait for value indicator animation to finish.
    await tester.pumpAndSettle();
    expect(
        sliderBox,
        paints
          ..path(
            color: sliderTheme.valueIndicatorColor,
            includes: <Offset>[
              const Offset(0.0, -38.8),
              const Offset(98.0, -38.8),
              const Offset(-16.0, -38.8),
              const Offset(10.0, -23.0), // Inside large, outside scale=1.0
              const Offset(-4.0, -23.0), // Inside large, outside scale=1.0
            ],
            excludes: <Offset>[
              const Offset(98.5, -38.8),
              const Offset(-16.1, -38.8),
            ],
          ));
    await gesture.up();
  });
}
