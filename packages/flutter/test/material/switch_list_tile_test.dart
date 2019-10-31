// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../rendering/mock_canvas.dart';

void main() {
  testWidgets('SwitchListTile has the right colors', (WidgetTester tester) async {
    bool value = false;
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(padding: EdgeInsets.all(8.0)),
        child: Directionality(
        textDirection: TextDirection.ltr,
        child:
          StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Material(
                child: SwitchListTile(
                  value: value,
                  onChanged: (bool newValue) {
                    setState(() { value = newValue; });
                  },
                  activeColor: Colors.red[500],
                  activeTrackColor: Colors.green[500],
                  inactiveThumbColor: Colors.yellow[500],
                  inactiveTrackColor: Colors.blue[500],
                ),
              );
            },
          ),
        ),
      ),
    );

    expect(
      find.byType(Switch),
      paints
        ..rrect(color: Colors.blue[500])
        ..circle(color: const Color(0x33000000))
        ..circle(color: const Color(0x24000000))
        ..circle(color: const Color(0x1f000000))
        ..circle(color: Colors.yellow[500]),
    );

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    expect(
      Material.of(tester.element(find.byType(Switch))),
      paints
        ..rrect(color: Colors.green[500])
        ..circle(color: const Color(0x33000000))
        ..circle(color: const Color(0x24000000))
        ..circle(color: const Color(0x1f000000))
        ..circle(color: Colors.red[500]),
    );
  });

  testWidgets('SwitchListTile.adaptive delegates to', (WidgetTester tester) async {
    bool value = false;

    Widget buildFrame(TargetPlatform platform) {
      return MaterialApp(
        theme: ThemeData(platform: platform),
        home: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Material(
              child: Center(
                child: SwitchListTile.adaptive(
                  value: value,
                  onChanged: (bool newValue) {
                    setState(() {
                      value = newValue;
                    });
                  },
                ),
              ),
            );
          },
        ),
      );
    }

    await tester.pumpWidget(buildFrame(TargetPlatform.iOS));
    expect(find.byType(CupertinoSwitch), findsOneWidget);
    expect(value, isFalse);

    await tester.tap(find.byType(SwitchListTile));
    expect(value, isTrue);

    await tester.pumpWidget(buildFrame(TargetPlatform.android));
    await tester.pumpAndSettle(); // Finish the theme change animation.

    expect(find.byType(CupertinoSwitch), findsNothing);
    expect(value, isTrue);
    await tester.tap(find.byType(SwitchListTile));
    expect(value, isFalse);
  });

  testWidgets('SwitchListTile contentPadding', (WidgetTester tester) async {
    Widget buildFrame(TextDirection textDirection) {
      return MediaQuery(
        data: const MediaQueryData(
          padding: EdgeInsets.zero,
          textScaleFactor: 1.0,
        ),
        child: Directionality(
          textDirection: textDirection,
          child: Material(
            child: Container(
              alignment: Alignment.topLeft,
              child: SwitchListTile(
                contentPadding: const EdgeInsetsDirectional.only(
                  start: 10.0,
                  end: 20.0,
                  top: 30.0,
                  bottom: 40.0,
                ),
                secondary: const Text('L'),
                title: const Text('title'),
                value: true,
                onChanged: (bool selected) {},
              ),
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(buildFrame(TextDirection.ltr));

    expect(tester.getTopLeft(find.text('L')).dx, 10.0); // contentPadding.start = 10
    expect(tester.getTopRight(find.byType(Switch)).dx, 780.0); // 800 - contentPadding.end

    await tester.pumpWidget(buildFrame(TextDirection.rtl));

    expect(tester.getTopLeft(find.byType(Switch)).dx, 20.0); // contentPadding.end = 20
    expect(tester.getTopRight(find.text('L')).dx, 790.0); // 800 - contentPadding.start
  });
}
