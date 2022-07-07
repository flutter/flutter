// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('slot layout dislays correct item of config based on screen width', (WidgetTester tester) async {
    MediaQuery slot(double width){
      return MediaQuery(
        data: MediaQueryData.fromWindow(WidgetsBinding.instance.window).copyWith(size: Size(width, 800)),
        child: const Directionality(
          textDirection: TextDirection.ltr,
          child: SlotLayout(
            config: <int, SlotLayoutConfig>{
              0: SlotLayoutConfig(key: Key('0'), child: SizedBox()),
              400: SlotLayoutConfig(key: Key('400'), child: SizedBox()),
              800: SlotLayoutConfig(key: Key('800'), child: SizedBox()),
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

  testWidgets('adaptive layout displays children in correct places', (WidgetTester tester) async {
    const Widget on = SizedBox(width: 100, height: 100,);
    const Widget off = SizedBox();

    MediaQuery layout(double width){
      return MediaQuery(
        data: MediaQueryData.fromWindow(WidgetsBinding.instance.window).copyWith(size: Size(width, 1800)),
        child: const Directionality(
          textDirection: TextDirection.ltr,
          child: AdaptiveLayout(
            primaryNavigation: SlotLayout(
              config: <int, SlotLayoutConfig>{
                0: SlotLayoutConfig(key: Key('pnav'), child: on),
                400: SlotLayoutConfig(key: Key('pnav1'), child: on),
                800: SlotLayoutConfig(key: Key('pnav2'), child: on),
                1000: SlotLayoutConfig(key: Key('pnav3'), child: on),
              },
            ),
            secondaryNavigation: SlotLayout(
              config: <int, SlotLayoutConfig>{
                0: SlotLayoutConfig(key: Key('snav'), child: on),
                400: SlotLayoutConfig(key: Key('snav1'), child: on),
                800: SlotLayoutConfig(key: Key('snav2'), child: on),
                1000: SlotLayoutConfig(key: Key('snav3'), child: on),
              },
            ),
            topNavigation: SlotLayout(
              config: <int, SlotLayoutConfig>{
                0: SlotLayoutConfig(key: Key('tnav'), child: on),
                400: SlotLayoutConfig(key: Key('tnav1'), child: on),
                800: SlotLayoutConfig(key: Key('tnav2'), child: on),
                1000: SlotLayoutConfig(key: Key('tnav3'), child: on),
              },
            ),
            bottomNavigation: SlotLayout(
              config: <int, SlotLayoutConfig>{
                0: SlotLayoutConfig(key: Key('bnav'), child: on),
                400: SlotLayoutConfig(key: Key('bnav1'), child: on),
                800: SlotLayoutConfig(key: Key('bnav2'), child: on),
                1000: SlotLayoutConfig(key: Key('bnav3'), child: on),
              },
            ),
            body: SlotLayout(
              config: <int, SlotLayoutConfig>{
                0: SlotLayoutConfig(key: Key('b'), child: on),
                400: SlotLayoutConfig(key: Key('b1'), child: on),
                800: SlotLayoutConfig(key: Key('b2'), child: on),
                1000: SlotLayoutConfig(key: Key('b3'), child: on),
              },
            ),
            secondaryBody: SlotLayout(
              config: <int, SlotLayoutConfig>{
                0: SlotLayoutConfig(key: Key('sb'), child: on),
                400: SlotLayoutConfig(key: Key('sb1'), child: on),
                800: SlotLayoutConfig(key: Key('sb2'), child: on),
                1000: SlotLayoutConfig(key: Key('sb3'), child: on),
              },
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(layout(390));

    Finder pnav = find.byKey(const Key('pnav'));
    Finder snav = find.byKey(const Key('snav'));
    Finder tnav = find.byKey(const Key('tnav'));
    Finder bnav = find.byKey(const Key('bnav'));
    Finder b = find.byKey(const Key('b'));
    Finder sb = find.byKey(const Key('sb'));

    expect(tester.getTopLeft(pnav), Offset.zero);
    expect(tester.getTopLeft(snav), const Offset(290,0));


  });

  testWidgets('slot layout config stores information about animation and widgets correctly', (WidgetTester tester) async {

  });

  testWidgets('slot layout properly switches between items with the appropriate animation', (WidgetTester tester) async {

  });


  // [AnimationSheet]
  testWidgets('adaptive layout properly animates secondary body into view', (WidgetTester tester) async {

  });

}
