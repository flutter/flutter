// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_api_samples/widgets/splash_box/splash_box.0.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('GradientButton and AppBar hues are in sync', (WidgetTester tester) async {
    await tester.pumpWidget(const SplashBoxExampleApp());

    int getHue(Color color) => Hue.fromColor(color).hue;

    ({int buttonHue, int appBarHue}) getHues() {
      final Color buttonColor = tester.widget<GradientButton>(find.byType(GradientButton)).color;
      final Color appBarColor = tester.widget<Material>(
        find.descendant(of: find.byType(AppBar), matching: find.byType(Material)),
      ).color!;

      return (buttonHue: getHue(buttonColor), appBarHue: getHue(appBarColor));
    }
    int buttonHue, appBarHue;

    (:buttonHue, :appBarHue) = getHues();
    expect(buttonHue, equals(appBarHue));

    await tester.tap(find.byType(GradientButton));
    (:buttonHue, :appBarHue) = getHues();
    expect(buttonHue, equals(appBarHue));

    await tester.pump(Durations.short2);
    (:buttonHue, :appBarHue) = getHues();
    expect(buttonHue, equals(appBarHue));

    await tester.pump(Durations.short2);
    (:buttonHue, :appBarHue) = getHues();
    expect(buttonHue, equals(appBarHue));

    await tester.pump(Durations.short2);
    (:buttonHue, :appBarHue) = getHues();
    expect(buttonHue, equals(appBarHue));
  });
}
