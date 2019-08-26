// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';

import '../rendering/mock_canvas.dart';

void main() {
  testWidgets('Activity indicator animate property works', (WidgetTester tester) async {

    await tester.pumpWidget(buildCupertinoActivityIndicator());
    expect(SchedulerBinding.instance.transientCallbackCount, equals(1));

    await tester.pumpWidget(buildCupertinoActivityIndicator(false));
    expect(SchedulerBinding.instance.transientCallbackCount, equals(0));

    await tester.pumpWidget(Container());

    await tester.pumpWidget(buildCupertinoActivityIndicator(false));
    expect(SchedulerBinding.instance.transientCallbackCount, equals(0));

    await tester.pumpWidget(buildCupertinoActivityIndicator());
    expect(SchedulerBinding.instance.transientCallbackCount, equals(1));
  });

  testWidgets('Activity indicator dark mode', (WidgetTester tester) async {
    final CupertinoDynamicColor dynamicColor = CupertinoDynamicColor.withBrightness(
      color: const Color(0xFF000000),
      darkColor: const Color(0xFF000001),
    );

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(platformBrightness: Brightness.light),
        child: CupertinoActivityIndicator(
          activeTickColor: dynamicColor,
        ),
      ),
    );

    expect(find.byType(CupertinoActivityIndicator), paints..rrect(color: const Color(0xFF000000)));

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(platformBrightness: Brightness.dark),
        child: CupertinoActivityIndicator(
          activeTickColor: dynamicColor,
        ),
      ),
    );

    expect(find.byType(CupertinoActivityIndicator), paints..rrect(color: const Color(0xFF000001)));
  });
}

Widget buildCupertinoActivityIndicator([ bool animating ]) {
  return MediaQuery(
    data: const MediaQueryData(platformBrightness: Brightness.light),
    child: CupertinoActivityIndicator(
      animating: animating ?? true,
    ),
  );
}
