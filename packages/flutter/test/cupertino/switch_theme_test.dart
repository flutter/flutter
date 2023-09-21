// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file is run as part of a reduced test set in CI on Mac and Windows
// machines.
@Tags(<String>['reduced-test-set'])
library;

import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leak_tracker_flutter_testing/leak_tracker_flutter_testing.dart';

void main() {
  test('CupertinoSwitchThemeData copyWith, ==, hashCode basics', () {
    expect(const CupertinoSwitchThemeData(), const CupertinoSwitchThemeData().copyWith());
    expect(const CupertinoSwitchThemeData().hashCode, const CupertinoSwitchThemeData().copyWith().hashCode);
  });

  testWidgets('CupertinoSwitchThemeData equality', (WidgetTester tester) async {
    const CupertinoSwitchThemeData a = CupertinoSwitchThemeData();
    final CupertinoSwitchThemeData b = a.copyWith();
    final CupertinoSwitchThemeData c = a.copyWith(
      thumbColor: CupertinoColors.activeOrange,
      trackColor: CupertinoColors.activeGreen,
      activeColor: CupertinoColors.activeBlue,
    );
    final CupertinoSwitchThemeData d = a.copyWith(
      thumbColor: CupertinoColors.white,
      trackColor: CupertinoColors.black,
      activeColor: CupertinoColors.systemYellow,
    );
    expect(a, equals(b));
    expect(b, equals(a));
    expect(a, isNot(equals(c)));
    expect(d, isNot(equals(c)));
    expect(c.thumbColor, isNot(equals(d.thumbColor)));
    expect(c.activeColor, isNot(equals(d.activeColor)));
    expect(c.trackColor, isNot(equals(d.trackColor)));
  });

  testWidgetsWithLeakTracking('Default CupertinoSwitchThemeData debugFillProperties', (WidgetTester tester) async {
    final DiagnosticPropertiesBuilder builder = DiagnosticPropertiesBuilder();
    const CupertinoSwitchThemeData().debugFillProperties(builder);

    final List<String> description = builder.properties
      .where((DiagnosticsNode node) => !node.isFiltered(DiagnosticLevel.info))
      .map((DiagnosticsNode node) => node.toString())
      .toList();

    expect(description, <String>[]);
  });

  testWidgetsWithLeakTracking('CupertinoSwitchThemeData implements debugFillProperties', (WidgetTester tester) async {
    final DiagnosticPropertiesBuilder builder = DiagnosticPropertiesBuilder();
    const CupertinoSwitchThemeData(
      thumbColor: Color(0xfffffff0),
      trackColor: Color(0xfffffff1),
      activeColor: Color(0xfffffff3),
    ).debugFillProperties(builder);

    final List<String> description = builder.properties
      .where((DiagnosticsNode node) => !node.isFiltered(DiagnosticLevel.info))
      .map((DiagnosticsNode node) => node.toString())
      .toList();
    expect(description[0], 'thumbColor: Color(0xfffffff0)');
    expect(description[1], 'trackColor: Color(0xfffffff1)');
    expect(description[2], 'activeColor: Color(0xfffffff3)');
  });

  testWidgets('Switch is using CupertinoTheme.data.switchTheme.track color when set', (WidgetTester tester) async {
    const Color trackColor = Color(0xFF00FF00);
    await tester.pumpWidget(
      const CupertinoTheme(
          data: CupertinoThemeData(
            switchTheme: CupertinoSwitchThemeData(
              trackColor: trackColor,
            ),
          ),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Center(
              child: CupertinoSwitch(
                value: false,
                dragStartBehavior: DragStartBehavior.down,
                onChanged: null,
              ),
            ),
          )),
    );

    expect(find.byType(CupertinoSwitch), findsOneWidget);
    expect(tester.widget<CupertinoSwitch>(find.byType(CupertinoSwitch)).trackColor, null);
    expect(find.byType(CupertinoSwitch), paints..rrect(color: trackColor));
  });

  testWidgets('Switch is using CupertinoTheme.data.switchTheme.thumb color when set', (WidgetTester tester) async {
    const Color thumbColor = Color(0xFF000000);
    await tester.pumpWidget(
      const CupertinoTheme(
        data: CupertinoThemeData(
          switchTheme: CupertinoSwitchThemeData(
            thumbColor: thumbColor,
          ),
        ),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: CupertinoSwitch(
              value: false,
              onChanged: null,
            ),
          ),
        ),
      ),
    );

    expect(find.byType(CupertinoSwitch), findsOneWidget);
    expect(tester.widget<CupertinoSwitch>(find.byType(CupertinoSwitch)).thumbColor, null);
    expect(
      find.byType(CupertinoSwitch),
      paints
        ..rrect()
        ..rrect()
        ..rrect()
        ..rrect()
        ..rrect(color: thumbColor),
    );
  });

  testWidgets('Switch can apply the ambient switchTheme theme and be opted out', (WidgetTester tester) async {
    final Key switchKey = UniqueKey();
    bool value = false;
    await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Center(
                child: RepaintBoundary(
                  child: Column(
                    children: <Widget>[
                      CupertinoTheme(
                        data: const CupertinoThemeData(
                          switchTheme: CupertinoSwitchThemeData(
                            activeColor: Colors.amber,
                          ),
                        ),
                        child: CupertinoSwitch(
                        key: switchKey,
                        value: value,
                        dragStartBehavior: DragStartBehavior.down,
                        applyTheme: true,
                        onChanged: (bool newValue) {
                          setState(() {
                            value = newValue;
                          });
                        },
                      ),),
                      CupertinoSwitch(
                        value: value,
                        dragStartBehavior: DragStartBehavior.down,
                        onChanged: (bool newValue) {
                          setState(() {
                            value = newValue;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        )
    );

    await expectLater(
      find.byType(Column),
      matchesGoldenFile('switch.tap.off.themed.png'),
    );

    await tester.tap(find.byKey(switchKey));
    expect(value, isTrue);

    await tester.pumpAndSettle();
    await expectLater(
      find.byType(Column),
      matchesGoldenFile('switch.tap.on.themed.png'),
    );
  });

  testWidgets('Switch color priority when use Theme and CupertinoTheme widgets', (WidgetTester tester) async {
    const Color thumbColorInSwitch = Color(0xFF000000);
    const Color thumbColorInCupertinoTheme = Color(0xFF000001);
    const Color thumbColorInTheme = Color(0xFF000002);
    await tester.pumpWidget(
      Theme(
        data: ThemeData(
            cupertinoOverrideTheme: const CupertinoThemeData(
              switchTheme: CupertinoSwitchThemeData(
                thumbColor: thumbColorInTheme,
              ),
            )
        ),
        child: const CupertinoTheme(
          data: CupertinoThemeData(
            switchTheme: CupertinoSwitchThemeData(
              thumbColor: thumbColorInCupertinoTheme,
            ),
          ),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Center(
              child: CupertinoSwitch(
                thumbColor: thumbColorInSwitch,
                value: false,
                onChanged: null,
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.byType(CupertinoSwitch), findsOneWidget);
    expect(tester.widget<CupertinoSwitch>(find.byType(CupertinoSwitch)).thumbColor, thumbColorInSwitch);
    expect(
      find.byType(CupertinoSwitch),
      paints
        ..rrect()
        ..rrect()
        ..rrect()
        ..rrect()
        ..rrect(color: thumbColorInSwitch),
    );
  });

}
