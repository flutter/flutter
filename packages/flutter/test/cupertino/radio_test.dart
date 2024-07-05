// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../widgets/semantics_tester.dart';

void main() {
  testWidgets('Radio control test', (WidgetTester tester) async {
    final Key key = UniqueKey();
    final List<int?> log = <int?>[];

    await tester.pumpWidget(CupertinoApp(
      home: Center(
        child: CupertinoRadio<int>(
          key: key,
          value: 1,
          groupValue: 2,
          onChanged: log.add,
        ),
      ),
    ));

    await tester.tap(find.byKey(key));

    expect(log, equals(<int>[1]));
    log.clear();

    await tester.pumpWidget(CupertinoApp(
      home: Center(
        child: CupertinoRadio<int>(
          key: key,
          value: 1,
          groupValue: 1,
          onChanged: log.add,
          activeColor: CupertinoColors.systemGreen,
        ),
      ),
    ));

    await tester.tap(find.byKey(key));

    expect(log, isEmpty);

    await tester.pumpWidget(CupertinoApp(
      home: Center(
        child: CupertinoRadio<int>(
          key: key,
          value: 1,
          groupValue: 2,
          onChanged: null,
        ),
      ),
    ));

    await tester.tap(find.byKey(key));

    expect(log, isEmpty);
  });

  testWidgets('Radio can be toggled when toggleable is set', (WidgetTester tester) async {
    final Key key = UniqueKey();
    final List<int?> log = <int?>[];

    await tester.pumpWidget(CupertinoApp(
      home: Center(
        child: CupertinoRadio<int>(
          key: key,
          value: 1,
          groupValue: 2,
          onChanged: log.add,
          toggleable: true,
        ),
      ),
    ));

    await tester.tap(find.byKey(key));

    expect(log, equals(<int>[1]));
    log.clear();

    await tester.pumpWidget(CupertinoApp(
      home: Center(
        child: CupertinoRadio<int>(
          key: key,
          value: 1,
          groupValue: 1,
          onChanged: log.add,
          toggleable: true,
        ),
      ),
    ));

    await tester.tap(find.byKey(key));

    expect(log, equals(<int?>[null]));
    log.clear();

    await tester.pumpWidget(CupertinoApp(
      home: Center(
        child: CupertinoRadio<int>(
          key: key,
          value: 1,
          groupValue: null,
          onChanged: log.add,
          toggleable: true,
        ),
      ),
    ));

    await tester.tap(find.byKey(key));

    expect(log, equals(<int>[1]));
  });

  testWidgets('Radio selected semantics - platform adaptive', (WidgetTester tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);

    await tester.pumpWidget(CupertinoApp(
      home: Center(
        child: CupertinoRadio<int>(
          value: 1,
          groupValue: 1,
          onChanged: (int? i) { },
        ),
      ),
    ));

    final bool isApple = defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS;
    expect(
      semantics,
      includesNodeWith(
        flags: <SemanticsFlag>[
          SemanticsFlag.isInMutuallyExclusiveGroup,
          SemanticsFlag.hasCheckedState,
          SemanticsFlag.hasEnabledState,
          SemanticsFlag.isEnabled,
          SemanticsFlag.isFocusable,
          SemanticsFlag.isChecked,
          if (isApple) SemanticsFlag.isSelected,
        ],
        actions: <SemanticsAction>[
          SemanticsAction.tap,
        ],
      ),
    );
    semantics.dispose();
  }, variant: TargetPlatformVariant.all());

  testWidgets('Radio semantics', (WidgetTester tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);

    await tester.pumpWidget(CupertinoApp(
      home: Center(
        child: CupertinoRadio<int>(
          value: 1,
          groupValue: 2,
          onChanged: (int? i) { },
        ),
      ),
    ));

    expect(tester.getSemantics(find.byType(Focus).last), matchesSemantics(
      hasCheckedState: true,
      hasEnabledState: true,
      isEnabled: true,
      hasTapAction: true,
      isFocusable: true,
      isInMutuallyExclusiveGroup: true,
    ));

    await tester.pumpWidget(CupertinoApp(
      home: Center(
        child: CupertinoRadio<int>(
          value: 2,
          groupValue: 2,
          onChanged: (int? i) { },
        ),
      ),
    ));

    expect(tester.getSemantics(find.byType(Focus).last), matchesSemantics(
      hasCheckedState: true,
      hasEnabledState: true,
      isEnabled: true,
      hasTapAction: true,
      isFocusable: true,
      isInMutuallyExclusiveGroup: true,
      isChecked: true,
    ));

    await tester.pumpWidget(const CupertinoApp(
      home: Center(
        child: CupertinoRadio<int>(
          value: 1,
          groupValue: 2,
          onChanged: null,
        ),
      ),
    ));

    expect(tester.getSemantics(find.byType(Focus).last), matchesSemantics(
      hasCheckedState: true,
      hasEnabledState: true,
      isFocusable: true,
      isInMutuallyExclusiveGroup: true,
    ));

    await tester.pump();

    // Now the isFocusable should be gone.
    expect(tester.getSemantics(find.byType(Focus).last), matchesSemantics(
      hasCheckedState: true,
      hasEnabledState: true,
      isInMutuallyExclusiveGroup: true,
    ));

    await tester.pumpWidget(const CupertinoApp(
      home: Center(
        child: CupertinoRadio<int>(
          value: 2,
          groupValue: 2,
          onChanged: null,
        ),
      ),
    ));

    expect(tester.getSemantics(find.byType(Focus).last), matchesSemantics(
      hasCheckedState: true,
      hasEnabledState: true,
      isChecked: true,
      isInMutuallyExclusiveGroup: true,
    ));

    semantics.dispose();
  });

  testWidgets('has semantic events', (WidgetTester tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);
    final Key key = UniqueKey();
    dynamic semanticEvent;
    int? radioValue = 2;
    tester.binding.defaultBinaryMessenger.setMockDecodedMessageHandler<dynamic>(SystemChannels.accessibility, (dynamic message) async {
      semanticEvent = message;
    });

    await tester.pumpWidget(CupertinoApp(
      home: Center(
        child: CupertinoRadio<int>(
          key: key,
          value: 1,
          groupValue: radioValue,
          onChanged: (int? i) {
            radioValue = i;
          },
        ),
      ),
    ));

    await tester.tap(find.byKey(key));
    final RenderObject object = tester.firstRenderObject(find.byKey(key));

    expect(radioValue, 1);
    expect(semanticEvent, <String, dynamic>{
      'type': 'tap',
      'nodeId': object.debugSemantics!.id,
      'data': <String, dynamic>{},
    });
    expect(object.debugSemantics!.getSemanticsData().hasAction(SemanticsAction.tap), true);

    semantics.dispose();
    tester.binding.defaultBinaryMessenger.setMockDecodedMessageHandler<dynamic>(SystemChannels.accessibility, null);
  });

  testWidgets('Radio can be controlled by keyboard shortcuts', (WidgetTester tester) async {
    tester.binding.focusManager.highlightStrategy = FocusHighlightStrategy.alwaysTraditional;
    int? groupValue = 1;
    const Key radioKey0 = Key('radio0');
    const Key radioKey1 = Key('radio1');
    const Key radioKey2 = Key('radio2');
    final FocusNode focusNode2 = FocusNode(debugLabel: 'radio2');
    addTearDown(focusNode2.dispose);
    Widget buildApp({bool enabled = true}) {
      return CupertinoApp(
        home: Center(
          child: StatefulBuilder(builder: (BuildContext context, StateSetter setState) {
            return SizedBox(
              width: 200,
              height: 100,
              child: Row(
                children: <Widget>[
                  CupertinoRadio<int>(
                    key: radioKey0,
                    value: 0,
                    onChanged: enabled ? (int? newValue) {
                      setState(() {
                        groupValue = newValue;
                      });
                    } : null,
                    groupValue: groupValue,
                    autofocus: true,
                  ),
                  CupertinoRadio<int>(
                    key: radioKey1,
                    value: 1,
                    onChanged: enabled ? (int? newValue) {
                      setState(() {
                        groupValue = newValue;
                      });
                    } : null,
                    groupValue: groupValue,
                  ),
                  CupertinoRadio<int>(
                    key: radioKey2,
                    value: 2,
                    onChanged: enabled ? (int? newValue) {
                      setState(() {
                        groupValue = newValue;
                      });
                    } : null,
                    groupValue: groupValue,
                    focusNode: focusNode2,
                  ),
                ],
              ),
            );
          }),
        ),
      );
    }

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    // On web, radios don't respond to the enter key.
    expect(groupValue, kIsWeb ? equals(1) : equals(0));

    focusNode2.requestFocus();
    await tester.pumpAndSettle();

    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pumpAndSettle();
    expect(groupValue, equals(2));
  });

  testWidgets('Show a checkmark when useCheckmarkStyle is true', (WidgetTester tester) async {
    await tester.pumpWidget(CupertinoApp(
      home: Center(
        child: CupertinoRadio<int>(
          value: 1,
          groupValue: 1,
          onChanged: (int? i) { },
        ),
      ),
    ));
    await tester.pumpAndSettle();

    // Has no checkmark when useCheckmarkStyle is false
    expect(
      tester.firstRenderObject<RenderBox>(find.byType(CupertinoRadio<int>)),
      isNot(paints..path())
    );

    await tester.pumpWidget(CupertinoApp(
      home: Center(
        child: CupertinoRadio<int>(
          value: 1,
          groupValue: 2,
          useCheckmarkStyle: true,
          onChanged: (int? i) { },
        ),
      ),
    ));
    await tester.pumpAndSettle();

    // Has no checkmark when group value doesn't match the value
    expect(
      tester.firstRenderObject<RenderBox>(find.byType(CupertinoRadio<int>)),
      isNot(paints..path())
    );

    await tester.pumpWidget(CupertinoApp(
      home: Center(
        child: CupertinoRadio<int>(
          value: 1,
          groupValue: 1,
          useCheckmarkStyle: true,
          onChanged: (int? i) { },
        ),
      ),
    ));
    await tester.pumpAndSettle();

    // Draws a path to show the checkmark when toggled on
    expect(
      tester.firstRenderObject<RenderBox>(find.byType(CupertinoRadio<int>)),
      paints..path()
    );
  });

  testWidgets('Do not crash when widget disappears while pointer is down', (WidgetTester tester) async {
    final Key key = UniqueKey();

    Widget buildRadio(bool show) {
      return CupertinoApp(
        home: Center(
          child: show ? CupertinoRadio<bool>(key: key, value: true, groupValue: false, onChanged: (_) { }) : Container(),
        ),
      );
    }

    await tester.pumpWidget(buildRadio(true));
    final Offset center = tester.getCenter(find.byKey(key));
    // Put a pointer down on the screen.
    final TestGesture gesture = await tester.startGesture(center);
    await tester.pump();
    // While the pointer is down, the widget disappears.
    await tester.pumpWidget(buildRadio(false));
    expect(find.byKey(key), findsNothing);
    // Release pointer after widget disappeared.
    await gesture.up();
  });
}
