// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('slot layout dislays correct item of config based on screen width', (WidgetTester tester) async {
    MediaQuery slot(double width) {
      return MediaQuery(
        data: MediaQueryData.fromWindow(WidgetsBinding.instance.window).copyWith(size: Size(width, 800)),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: SlotLayout(
            config: <int, SlotLayoutConfig>{
              0: SlotLayoutConfig(key: const Key('0'), builder: (_) => const SizedBox()),
              400: SlotLayoutConfig(key: const Key('400'), builder: (_) => const SizedBox()),
              800: SlotLayoutConfig(key: const Key('800'), builder: (_) => const SizedBox()),
            },
          ),
        ),
      );
    }

    await tester.pumpWidget(slot(300));
    expect(find.byKey(const Key('0')), findsOneWidget);
    expect(find.byKey(const Key('400')), findsNothing);
    expect(find.byKey(const Key('800')), findsNothing);

    await tester.pumpWidget(slot(500));
    expect(find.byKey(const Key('0')), findsNothing);
    expect(find.byKey(const Key('400')), findsOneWidget);
    expect(find.byKey(const Key('800')), findsNothing);

    await tester.pumpWidget(slot(1000));
    expect(find.byKey(const Key('0')), findsNothing);
    expect(find.byKey(const Key('400')), findsNothing);
    expect(find.byKey(const Key('800')), findsOneWidget);
  });
  Widget on(_) {
    return const SizedBox(width: 10, height: 10);
  }

  Future<SizedBox> layout(double width, WidgetTester tester) async {
    await tester.binding.setSurfaceSize(Size(width, 800));
    return SizedBox(
      width: width,
      child: MediaQuery(
        data: MediaQueryData(size: Size(width, 800)),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: AdaptiveLayout(
            primaryNavigation: SlotLayout(
              config: <int, SlotLayoutConfig>{
                0: SlotLayoutConfig(key: const Key('pnav'), builder: on),
                400: SlotLayoutConfig(key: const Key('pnav1'), builder: on),
                800: SlotLayoutConfig(key: const Key('pnav2'), builder: on),
                1000: SlotLayoutConfig(key: const Key('pnav3'), builder: on),
              },
            ),
            secondaryNavigation: SlotLayout(
              config: <int, SlotLayoutConfig>{
                0: SlotLayoutConfig(key: const Key('snav'), builder: on),
                400: SlotLayoutConfig(key: const Key('snav1'), builder: on),
                800: SlotLayoutConfig(key: const Key('snav2'), builder: on),
                1000: SlotLayoutConfig(key: const Key('snav3'), builder: on),
              },
            ),
            topNavigation: SlotLayout(
              config: <int, SlotLayoutConfig>{
                0: SlotLayoutConfig(key: const Key('tnav'), builder: on),
                400: SlotLayoutConfig(key: const Key('tnav1'), builder: on),
                800: SlotLayoutConfig(key: const Key('tnav2'), builder: on),
                1000: SlotLayoutConfig(key: const Key('tnav3'), builder: on),
              },
            ),
            bottomNavigation: SlotLayout(
              config: <int, SlotLayoutConfig>{
                0: SlotLayoutConfig(key: const Key('bnav'), builder: on),
                400: SlotLayoutConfig(key: const Key('bnav1'), builder: on),
                800: SlotLayoutConfig(key: const Key('bnav2'), builder: on),
                1000: SlotLayoutConfig(key: const Key('bnav3'), builder: on),
              },
            ),
            body: SlotLayout(
              config: <int, SlotLayoutConfig>{
                0: SlotLayoutConfig(key: const Key('b'), builder: (_) => Container(color: Colors.red)),
                400: SlotLayoutConfig(key: const Key('b1'), builder: (_) => Container(color: Colors.red)),
                800: SlotLayoutConfig(key: const Key('b2'), builder: (_) => Container(color: Colors.red)),
                1000: SlotLayoutConfig(key: const Key('b3'), builder: (_) => Container(color: Colors.red)),
              },
            ),
            secondaryBody: SlotLayout(
              config: <int, SlotLayoutConfig>{
                0: SlotLayoutConfig(key: const Key('sb'), builder: (_) => Container(color: Colors.blue)),
                400: SlotLayoutConfig(key: const Key('sb1'), builder: (_) => Container(color: Colors.blue)),
                800: SlotLayoutConfig(key: const Key('sb2'), builder: (_) => Container(color: Colors.blue)),
                1000: SlotLayoutConfig(key: const Key('sb3'), builder: (_) => Container(color: Colors.blue)),
              },
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('adaptive layout displays children in correct places', (WidgetTester tester) async {
    // Widget off(_){return const SizedBox.shrink();}

    await tester.pumpWidget(await layout(400, tester));
    await tester.pumpAndSettle();

    final Finder tnav = find.byKey(const Key('tnav'));
    final Finder snav = find.byKey(const Key('snav'));
    final Finder pnav = find.byKey(const Key('pnav'));
    final Finder bnav = find.byKey(const Key('bnav'));
    final Finder b = find.byKey(const Key('b'));
    final Finder sb = find.byKey(const Key('sb'));

    await tester.pumpAndSettle();
    expect(tester.getTopLeft(tnav), Offset.zero);
    expect(tester.getTopLeft(snav), const Offset(390, 10));
    expect(tester.getTopLeft(pnav), const Offset(0, 10));
    expect(tester.getTopLeft(bnav), const Offset(0, 790));
    expect(tester.getTopLeft(b), const Offset(10, 10));
    expect(tester.getBottomRight(b), const Offset(200, 790));
    expect(tester.getTopLeft(sb), const Offset(200, 10));
    expect(tester.getBottomRight(sb), const Offset(390, 790));
  });

  testWidgets('slot layout properly switches between items with the appropriate animation',
      (WidgetTester tester) async {
    AnimatedWidget leftOutIn(Widget child, AnimationController animation) {
      return SlideTransition(
        key: Key('in-${child.key}'),
        position: Tween<Offset>(
          begin: const Offset(-1, 0),
          end: Offset.zero,
        ).animate(animation),
        child: child,
      );
    }

    AnimatedWidget leftInOut(Widget child, AnimationController animation) {
      return SlideTransition(
        key: Key('out-${child.key}'),
        position: Tween<Offset>(
          begin: Offset.zero,
          end: const Offset(-1, 0),
        ).animate(animation),
        child: child,
      );
    }

    MediaQuery slot(double width) {
      return MediaQuery(
        data: MediaQueryData.fromWindow(WidgetsBinding.instance.window).copyWith(size: Size(width, 800)),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: SlotLayout(
            config: <int, SlotLayoutConfig>{
              0: SlotLayoutConfig(
                inAnimation: leftOutIn,
                outAnimation: leftInOut,
                key: const Key('0'),
                builder: (_) => const SizedBox(width: 10, height: 10),
              ),
              400: SlotLayoutConfig(
                inAnimation: leftOutIn,
                outAnimation: leftInOut,
                key: const Key('400'),
                builder: (_) => const SizedBox(width: 10, height: 10),
              ),
            },
          ),
        ),
      );
    }

    final Finder begin = find.byKey(const Key('0'));
    final Finder end = find.byKey(const Key('400'));
    Finder slideIn(String key) => find.byKey(Key('in-${Key(key)}'));
    Finder slideOut(String key) => find.byKey(Key('out-${Key(key)}'));

    await tester.pumpWidget(slot(300));
    expect(begin, findsOneWidget);
    expect(end, findsNothing);

    await tester.pumpWidget(slot(500));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.widget<SlideTransition>(slideOut('0')).position.value, const Offset(-0.5, 0));
    expect(tester.widget<SlideTransition>(slideIn('400')).position.value, const Offset(-0.5, 0));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.widget<SlideTransition>(slideOut('0')).position.value, const Offset(-1.0, 0));
    expect(tester.widget<SlideTransition>(slideIn('400')).position.value, Offset.zero);

    await tester.pumpAndSettle();
    expect(begin, findsNothing);
    expect(end, findsOneWidget);
  });

  // [AnimationSheet]
  testWidgets('adaptive layout handles internal animations correctly', (WidgetTester tester) async {
    final Finder b = find.byKey(const Key('b'));
    final Finder sb = find.byKey(const Key('sb'));

    await tester.pumpWidget(await layout(400, tester));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1000));

    expect(tester.getTopLeft(b), const Offset(10, 10));
    expect(tester.getBottomRight(b), const Offset(200, 790));
    expect(tester.getTopLeft(sb), const Offset(200, 10));
    expect(tester.getBottomRight(sb), const Offset(390, 790));
  });
  // testWidgets('adaptive layout correct layout when body vertical', (WidgetTester tester) async {});
  // testWidgets('adaptive layout correct layout when rtl', (WidgetTester tester) async {});
  // testWidgets('adaptive layout correct layout when body ratio not default', (WidgetTester tester) async {});
  // testWidgets('adaptive layout does not animate when animations off', (WidgetTester tester) async {});
  // testWidgets('slot layout can tolerate rapid changes in breakpoints', (WidgetTester tester) async {});
}
