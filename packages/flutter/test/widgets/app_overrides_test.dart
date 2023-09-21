// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leak_tracker_flutter_testing/leak_tracker_flutter_testing.dart';

class TestRoute<T> extends PageRoute<T> {
  TestRoute({ required this.child, super.settings });

  final Widget child;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 150);

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  bool get maintainState => false;

  @override
  Widget buildPage(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
    return child;
  }
}

Future<void> pumpApp(WidgetTester tester) async {
  await tester.pumpWidget(
    WidgetsApp(
      color: const Color(0xFF333333),
      onGenerateRoute: (RouteSettings settings) {
        return TestRoute<void>(settings: settings, child: Container());
      },
    ),
  );
}

void main() {
  testWidgetsWithLeakTracking('WidgetsApp control test', (WidgetTester tester) async {
    await pumpApp(tester);
    expect(find.byType(WidgetsApp), findsOneWidget);
    expect(find.byType(Navigator), findsOneWidget);
    expect(find.byType(PerformanceOverlay), findsNothing);
    expect(find.byType(CheckedModeBanner), findsOneWidget);
  });

  testWidgetsWithLeakTracking('showPerformanceOverlayOverride true', (WidgetTester tester) async {
    expect(WidgetsApp.showPerformanceOverlayOverride, false);
    WidgetsApp.showPerformanceOverlayOverride = true;
    await pumpApp(tester);
    expect(find.byType(WidgetsApp), findsOneWidget);
    expect(find.byType(Navigator), findsOneWidget);
    expect(find.byType(PerformanceOverlay), findsOneWidget);
    expect(find.byType(CheckedModeBanner), findsOneWidget);
    WidgetsApp.showPerformanceOverlayOverride = false;
  });

  testWidgetsWithLeakTracking('showPerformanceOverlayOverride false', (WidgetTester tester) async {
    WidgetsApp.showPerformanceOverlayOverride = true;
    expect(WidgetsApp.showPerformanceOverlayOverride, true);
    WidgetsApp.showPerformanceOverlayOverride = false;
    await pumpApp(tester);
    expect(find.byType(WidgetsApp), findsOneWidget);
    expect(find.byType(Navigator), findsOneWidget);
    expect(find.byType(PerformanceOverlay), findsNothing);
    expect(find.byType(CheckedModeBanner), findsOneWidget);
  });

  testWidgetsWithLeakTracking('debugAllowBannerOverride false', (WidgetTester tester) async {
    expect(WidgetsApp.showPerformanceOverlayOverride, false);
    expect(WidgetsApp.debugAllowBannerOverride, true);
    WidgetsApp.debugAllowBannerOverride = false;
    await pumpApp(tester);
    expect(find.byType(WidgetsApp), findsOneWidget);
    expect(find.byType(Navigator), findsOneWidget);
    expect(find.byType(PerformanceOverlay), findsNothing);
    expect(find.byType(CheckedModeBanner), findsNothing);
    WidgetsApp.debugAllowBannerOverride = true; // restore to default value
  });

  testWidgetsWithLeakTracking('debugAllowBannerOverride true', (WidgetTester tester) async {
    WidgetsApp.debugAllowBannerOverride = false;
    expect(WidgetsApp.showPerformanceOverlayOverride, false);
    expect(WidgetsApp.debugAllowBannerOverride, false);
    WidgetsApp.debugAllowBannerOverride = true;
    await pumpApp(tester);
    expect(find.byType(WidgetsApp), findsOneWidget);
    expect(find.byType(Navigator), findsOneWidget);
    expect(find.byType(PerformanceOverlay), findsNothing);
    expect(find.byType(CheckedModeBanner), findsOneWidget);
  });
}
