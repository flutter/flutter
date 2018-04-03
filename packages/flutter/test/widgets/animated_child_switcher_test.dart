// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('AnimatedChildSwitcher fades in a new child.', (WidgetTester tester) async {
    await tester.pumpWidget(
      new AnimatedChildSwitcher(
        duration: const Duration(milliseconds: 100),
        child: new Container(color: const Color(0x00000000)),
        switchInCurve: Curves.linear,
      ),
    );
    // First one just appears.
    FadeTransition transition = tester.firstWidget(find.byType(FadeTransition));
    expect(transition.opacity.value, equals(1.0));

    await tester.pumpWidget(
      new AnimatedChildSwitcher(
        duration: const Duration(milliseconds: 100),
        child: new Container(color: const Color(0xff000000)),
        switchInCurve: Curves.linear,
      ),
    );
    // Second one cross-fades with the first.
    await tester.pump(const Duration(milliseconds: 50));
    transition = tester.firstWidget(find.byType(FadeTransition));
    expect(transition.opacity.value, equals(0.5));
    await tester.pumpAndSettle();
  });

  testWidgets("AnimatedChildSwitcher doesn't start any animations after dispose.", (WidgetTester tester) async {
    await tester.pumpWidget(new AnimatedChildSwitcher(
      duration: const Duration(milliseconds: 100),
      child: new Container(color: const Color(0xff000000)),
      switchInCurve: Curves.linear,
    ));
    await tester.pump(const Duration(milliseconds: 50));

    // Change the widget tree in the middle of the animation.
    await tester.pumpWidget(new Container(color: const Color(0xffff0000)));
    expect(await tester.pumpAndSettle(const Duration(milliseconds: 100)), equals(1));
  });
}
