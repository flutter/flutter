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

  });

  testWidgets('slot layout config stores information about animation and widgets correctly', (WidgetTester tester) async {

  });

  testWidgets('slot layout properly switches between items with the appropriate animation', (WidgetTester tester) async {

  });


  // [AnimationSheet]
  testWidgets('adaptive layout properly animates secondary body into view', (WidgetTester tester) async {});
}
