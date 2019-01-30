// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

void main() {
  testWidgets('AnimatedAlign.debugFillProperties', (WidgetTester tester) async {
    const AnimatedAlign box = AnimatedAlign(
      alignment: Alignment.topCenter,
      curve: Curves.ease,
      duration: Duration(milliseconds: 200),
    );
    expect(box, hasOneLineDescription);
  });

  testWidgets('AnimatedAlign alignment visual-to-directional animation', (WidgetTester tester) async {
    final Key target = UniqueKey();

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.rtl,
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          alignment: Alignment.topRight,
          child: SizedBox(key: target, width: 100.0, height: 200.0),
        ),
      ),
    );

    expect(tester.getSize(find.byKey(target)), const Size(100.0, 200.0));
    expect(tester.getTopRight(find.byKey(target)), const Offset(800.0, 0.0));

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.rtl,
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          alignment: AlignmentDirectional.bottomStart,
          child: SizedBox(key: target, width: 100.0, height: 200.0),
        ),
      ),
    );

    expect(tester.getSize(find.byKey(target)), const Size(100.0, 200.0));
    expect(tester.getTopRight(find.byKey(target)), const Offset(800.0, 0.0));

    await tester.pump(const Duration(milliseconds: 100));

    expect(tester.getSize(find.byKey(target)), const Size(100.0, 200.0));
    expect(tester.getTopRight(find.byKey(target)), const Offset(800.0, 200.0));

    await tester.pump(const Duration(milliseconds: 500));

    expect(tester.getSize(find.byKey(target)), const Size(100.0, 200.0));
    expect(tester.getTopRight(find.byKey(target)), const Offset(800.0, 400.0));
  });
}
