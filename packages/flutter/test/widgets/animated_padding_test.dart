// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

void main() {
  testWidgets('AnimatedPadding.debugFillProperties', (WidgetTester tester) async {
    final AnimatedPadding padding = AnimatedPadding(
      padding: const EdgeInsets.all(7.0),
      curve: Curves.ease,
      duration: const Duration(milliseconds: 200),
    );

    expect(padding, hasOneLineDescription);
  });

  testWidgets('AnimatedPadding padding visual-to-directional animation', (WidgetTester tester) async {
    final Key target = UniqueKey();

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.rtl,
        child: AnimatedPadding(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.only(right: 50.0),
          child: SizedBox.expand(key: target),
        ),
      ),
    );

    expect(tester.getSize(find.byKey(target)), const Size(750.0, 600.0));
    expect(tester.getTopRight(find.byKey(target)), const Offset(750.0, 0.0));

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.rtl,
        child: AnimatedPadding(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsetsDirectional.only(start: 100.0),
          child: SizedBox.expand(key: target),
        ),
      ),
    );

    expect(tester.getSize(find.byKey(target)), const Size(750.0, 600.0));
    expect(tester.getTopRight(find.byKey(target)), const Offset(750.0, 0.0));

    await tester.pump(const Duration(milliseconds: 100));

    expect(tester.getSize(find.byKey(target)), const Size(725.0, 600.0));
    expect(tester.getTopRight(find.byKey(target)), const Offset(725.0, 0.0));

    await tester.pump(const Duration(milliseconds: 500));

    expect(tester.getSize(find.byKey(target)), const Size(700.0, 600.0));
    expect(tester.getTopRight(find.byKey(target)), const Offset(700.0, 0.0));
  });
}
