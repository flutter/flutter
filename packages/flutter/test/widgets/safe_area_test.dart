// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

void main() {
  testWidgets('SafeArea - basic', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MediaQuery(
        data: const MediaQueryData(padding: const EdgeInsets.all(20.0)),
        child: const SafeArea(
          left: false,
          child: const Placeholder(),
        ),
      ),
    );
    expect(tester.getTopLeft(find.byType(Placeholder)), const Offset(0.0, 20.0));
    expect(tester.getBottomRight(find.byType(Placeholder)), const Offset(780.0, 580.0));
  });

  testWidgets('SafeArea - nested', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MediaQuery(
        data: const MediaQueryData(padding: const EdgeInsets.all(20.0)),
        child: const SafeArea(
          top: false,
          child: const SafeArea(
            right: false,
            child: const Placeholder(),
          ),
        ),
      ),
    );
    expect(tester.getTopLeft(find.byType(Placeholder)), const Offset(20.0, 20.0));
    expect(tester.getBottomRight(find.byType(Placeholder)), const Offset(780.0, 580.0));
  });

  testWidgets('SafeArea - changing', (WidgetTester tester) async {
    final Widget child = const SafeArea(
      bottom: false,
      child: const SafeArea(
        left: false,
        bottom: false,
        child: const Placeholder(),
      ),
    );
    await tester.pumpWidget(
      new MediaQuery(
        data: const MediaQueryData(padding: const EdgeInsets.all(20.0)),
        child: child,
      ),
    );
    expect(tester.getTopLeft(find.byType(Placeholder)), const Offset(20.0, 20.0));
    expect(tester.getBottomRight(find.byType(Placeholder)), const Offset(780.0, 600.0));
    await tester.pumpWidget(
      new MediaQuery(
        data: const MediaQueryData(padding: const EdgeInsets.only(
          left: 100.0,
          top: 30.0,
          right: 0.0,
          bottom: 40.0,
        )),
        child: child,
      ),
    );
    expect(tester.getTopLeft(find.byType(Placeholder)), const Offset(100.0, 30.0));
    expect(tester.getBottomRight(find.byType(Placeholder)), const Offset(800.0, 600.0));
  });
}
