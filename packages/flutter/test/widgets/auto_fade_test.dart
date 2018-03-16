// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('AutoFade fades in a new child.', (WidgetTester tester) async {
    await tester.pumpWidget(
      new AutoFade(
        duration: const Duration(milliseconds: 100),
        child: new Container(color: const Color(0x00000000)),
        curve: Curves.linear,
      ),
    );
    // First one just appears.
    FadeTransition transition = tester.firstWidget(find.byType(FadeTransition));
    expect(transition.opacity.value, equals(1.0));

    await tester.pumpWidget(
      new AutoFade(
        duration: const Duration(milliseconds: 100),
        child: new Container(color: const Color(0xff000000)),
        curve: Curves.linear,
      ),
    );
    // Second one cross-fades with the first.
    await tester.pump(const Duration(milliseconds: 50));
    transition = tester.firstWidget(find.byType(FadeTransition));
    expect(transition.opacity.value, equals(0.5));
    await tester.pumpAndSettle();
  });

  testWidgets('AutoFade respects alignment.', (WidgetTester tester) async {
    final UniqueKey containerKey = new UniqueKey();
    await tester.pumpWidget(
      new Container(
        constraints: new BoxConstraints.tight(const Size.square(200.0)),
        child: new AutoFade(
          duration: const Duration(milliseconds: 100),
          child: new Container(
            key: containerKey,
            constraints: new BoxConstraints.tight(const Size.square(10.0)),
            color: const Color(0xff000000),
          ),
          alignment: Alignment.centerLeft,
          curve: Curves.linear,
        ),
      ),
    );
    expect(tester.getSize(find.byKey(containerKey)), equals(const Size(10.0, 10.0)));
    expect(tester.getTopLeft(find.byKey(containerKey)), equals(const Offset(0.0, 295.0)));

    await tester.pumpWidget(
      new Container(
        constraints: new BoxConstraints.tight(const Size.square(200.0)),
        child: new AutoFade(
          duration: const Duration(milliseconds: 100),
          child: new Container(
            key: containerKey,
            constraints: new BoxConstraints.tight(const Size.square(10.0)),
            color: const Color(0xff000000),
          ),
          alignment: Alignment.bottomRight,
          curve: Curves.linear,
        ),
      ),
    );
    expect(tester.getSize(find.byKey(containerKey).first), equals(const Size(10.0, 10.0)));
    expect(tester.getTopLeft(find.byKey(containerKey).first), equals(const Offset(790.0, 590.0)));
  });

  testWidgets("AutoFade doesn't start any animations after dispose.", (WidgetTester tester) async {
    await tester.pumpWidget(new AutoFade(
      duration: const Duration(milliseconds: 100),
      child: new Container(color: const Color(0xff000000)),
      curve: Curves.linear,
    ));
    await tester.pump(const Duration(milliseconds: 50));

    // Change the widget tree in the middle of the animation.
    await tester.pumpWidget(new Container(color: const Color(0xffff0000)));
    expect(await tester.pumpAndSettle(const Duration(milliseconds: 100)), equals(1));
  });
}
