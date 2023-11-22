// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
<<<<<<< HEAD

import '../rendering/mock_canvas.dart';
=======
import 'package:leak_tracker_flutter_testing/leak_tracker_flutter_testing.dart';

>>>>>>> db7ef5bf9f59442b0e200a90587e8fa5e0c6336a
import '../widgets/semantics_tester.dart';

void main() {
  setUp(() {
    debugResetSemanticsIdCounter();
  });

<<<<<<< HEAD
  testWidgets('CupertinoCheckbox semantics', (WidgetTester tester) async {
=======
  testWidgetsWithLeakTracking('CupertinoCheckbox semantics', (WidgetTester tester) async {
>>>>>>> db7ef5bf9f59442b0e200a90587e8fa5e0c6336a
    final SemanticsHandle handle = tester.ensureSemantics();

    await tester.pumpWidget(
      CupertinoApp (
        home: Center(
          child: CupertinoCheckbox(
            value: false,
            onChanged: (bool? b) { },
          ),
        )
      ),
    );

    expect(tester.getSemantics(find.byType(Focus).last), matchesSemantics(
      hasCheckedState: true,
      hasEnabledState: true,
      isEnabled: true,
      hasTapAction: true,
      isFocusable: true,
    ));

    await tester.pumpWidget(
      CupertinoApp (
        home: Center(
          child: CupertinoCheckbox(
            value: true,
            onChanged: (bool? b) { },
          ),
        )
      ),
    );

    expect(tester.getSemantics(find.byType(Focus).last), matchesSemantics(
      hasCheckedState: true,
      hasEnabledState: true,
      isChecked: true,
      isEnabled: true,
      hasTapAction: true,
      isFocusable: true,
    ));

    await tester.pumpWidget(
      const CupertinoApp (
        home: Center(
          child: CupertinoCheckbox(
            value: false,
            onChanged: null,
          ),
        )
      ),
    );

    expect(tester.getSemantics(find.byType(CupertinoCheckbox)), matchesSemantics(
      hasCheckedState: true,
      hasEnabledState: true,
      // isFocusable is delayed by 1 frame.
      isFocusable: true,
    ));

    await tester.pump();
    // isFocusable should be false now after the 1 frame delay.
    expect(tester.getSemantics(find.byType(CupertinoCheckbox)), matchesSemantics(
      hasCheckedState: true,
      hasEnabledState: true,
    ));

    await tester.pumpWidget(
      const CupertinoApp (
        home: Center(
          child: CupertinoCheckbox(
            value: true,
            onChanged: null,
          ),
        )
      ),
    );

    expect(tester.getSemantics(find.byType(CupertinoCheckbox)), matchesSemantics(
      hasCheckedState: true,
      hasEnabledState: true,
      isChecked: true,
    ));

    await tester.pumpWidget(
      const CupertinoApp (
        home: Center(
          child: CupertinoCheckbox(
            value: null,
            tristate: true,
            onChanged: null,
          ),
        )
      ),
    );

    expect(tester.getSemantics(find.byType(CupertinoCheckbox)), matchesSemantics(
      hasCheckedState: true,
      hasEnabledState: true,
      isCheckStateMixed: true,
    ));

    await tester.pumpWidget(
      const CupertinoApp (
        home: Center(
          child: CupertinoCheckbox(
            value: true,
            tristate: true,
            onChanged: null,
          ),
        )
      ),
    );

    expect(tester.getSemantics(find.byType(CupertinoCheckbox)), matchesSemantics(
      hasCheckedState: true,
      hasEnabledState: true,
      isChecked: true,
    ));

    await tester.pumpWidget(
      const CupertinoApp (
        home: Center(
          child: CupertinoCheckbox(
            value: false,
            tristate: true,
            onChanged: null,
          ),
        )
      ),
    );

    expect(tester.getSemantics(find.byType(CupertinoCheckbox)), matchesSemantics(
      hasCheckedState: true,
      hasEnabledState: true,
    ));

    handle.dispose();
  });

<<<<<<< HEAD
  testWidgets('Can wrap CupertinoCheckbox with Semantics', (WidgetTester tester) async {
=======
  testWidgetsWithLeakTracking('Can wrap CupertinoCheckbox with Semantics', (WidgetTester tester) async {
>>>>>>> db7ef5bf9f59442b0e200a90587e8fa5e0c6336a
    final SemanticsHandle handle = tester.ensureSemantics();

    await tester.pumpWidget(
      CupertinoApp(
        home: Semantics(
          label: 'foo',
          textDirection: TextDirection.ltr,
          child: CupertinoCheckbox(
            value: false,
            onChanged: (bool? b) { },
          ),
        ),
      ),
    );

    expect(tester.getSemantics(find.byType(Focus).last), matchesSemantics(
      label: 'foo',
      textDirection: TextDirection.ltr,
      hasCheckedState: true,
      hasEnabledState: true,
      isEnabled: true,
      hasTapAction: true,
      isFocusable: true,
    ));
    handle.dispose();
  });

<<<<<<< HEAD
  testWidgets('CupertinoCheckbox tristate: true', (WidgetTester tester) async {
=======
  testWidgetsWithLeakTracking('CupertinoCheckbox tristate: true', (WidgetTester tester) async {
>>>>>>> db7ef5bf9f59442b0e200a90587e8fa5e0c6336a
    bool? checkBoxValue;

    await tester.pumpWidget(
      CupertinoApp(
        home: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return CupertinoCheckbox(
              tristate: true,
              value: checkBoxValue,
              onChanged: (bool? value) {
                setState(() {
                  checkBoxValue = value;
                });
              },
            );
          },
        ),
      ),
    );

    expect(tester.widget<CupertinoCheckbox>(find.byType(CupertinoCheckbox)).value, null);

    await tester.tap(find.byType(CupertinoCheckbox));
    await tester.pumpAndSettle();
    expect(checkBoxValue, false);

    await tester.tap(find.byType(CupertinoCheckbox));
    await tester.pumpAndSettle();
    expect(checkBoxValue, true);

    await tester.tap(find.byType(CupertinoCheckbox));
    await tester.pumpAndSettle();
    expect(checkBoxValue, null);

    checkBoxValue = true;
    await tester.pumpAndSettle();
    expect(checkBoxValue, true);

    checkBoxValue = null;
    await tester.pumpAndSettle();
    expect(checkBoxValue, null);
  });

<<<<<<< HEAD
  testWidgets('has semantics for tristate', (WidgetTester tester) async {
=======
  testWidgetsWithLeakTracking('has semantics for tristate', (WidgetTester tester) async {
>>>>>>> db7ef5bf9f59442b0e200a90587e8fa5e0c6336a
    final SemanticsTester semantics = SemanticsTester(tester);
    await tester.pumpWidget(
      CupertinoApp(
        home: CupertinoCheckbox(
          tristate: true,
          value: null,
          onChanged: (bool? newValue) { },
        ),
      ),
    );

    expect(semantics.nodesWith(
      flags: <SemanticsFlag>[
        SemanticsFlag.hasCheckedState,
        SemanticsFlag.hasEnabledState,
        SemanticsFlag.isEnabled,
        SemanticsFlag.isFocusable,
        SemanticsFlag.isCheckStateMixed,
      ],
      actions: <SemanticsAction>[SemanticsAction.tap],
    ), hasLength(1));

    await tester.pumpWidget(
      CupertinoApp(
        home: CupertinoCheckbox(
          tristate: true,
          value: true,
          onChanged: (bool? newValue) { },
        ),
      ),
    );

    expect(semantics.nodesWith(
      flags: <SemanticsFlag>[
        SemanticsFlag.hasCheckedState,
        SemanticsFlag.hasEnabledState,
        SemanticsFlag.isEnabled,
        SemanticsFlag.isChecked,
        SemanticsFlag.isFocusable,
      ],
      actions: <SemanticsAction>[SemanticsAction.tap],
    ), hasLength(1));

    await tester.pumpWidget(
      CupertinoApp(
        home: CupertinoCheckbox(
          tristate: true,
          value: false,
          onChanged: (bool? newValue) { },
        ),
      ),
    );

    expect(semantics.nodesWith(
      flags: <SemanticsFlag>[
        SemanticsFlag.hasCheckedState,
        SemanticsFlag.hasEnabledState,
        SemanticsFlag.isEnabled,
        SemanticsFlag.isFocusable,
      ],
      actions: <SemanticsAction>[SemanticsAction.tap],
    ), hasLength(1));

    semantics.dispose();
  });

<<<<<<< HEAD
  testWidgets('has semantic events', (WidgetTester tester) async {
=======
  testWidgetsWithLeakTracking('has semantic events', (WidgetTester tester) async {
>>>>>>> db7ef5bf9f59442b0e200a90587e8fa5e0c6336a
    dynamic semanticEvent;
    bool? checkboxValue = false;
    tester.binding.defaultBinaryMessenger.setMockDecodedMessageHandler<dynamic>(SystemChannels.accessibility, (dynamic message) async {
      semanticEvent = message;
    });
    final SemanticsTester semanticsTester = SemanticsTester(tester);

    await tester.pumpWidget(
      CupertinoApp(
        home: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return CupertinoCheckbox(
              value: checkboxValue,
              onChanged: (bool? value) {
                setState(() {
                  checkboxValue = value;
                });
              },
            );
          },
        ),
      ),
    );

    await tester.tap(find.byType(CupertinoCheckbox));
    final RenderObject object = tester.firstRenderObject(find.byType(CupertinoCheckbox));

    expect(checkboxValue, true);
    expect(semanticEvent, <String, dynamic>{
      'type': 'tap',
      'nodeId': object.debugSemantics!.id,
      'data': <String, dynamic>{},
    });
    expect(object.debugSemantics!.getSemanticsData().hasAction(SemanticsAction.tap), true);

    tester.binding.defaultBinaryMessenger.setMockDecodedMessageHandler<dynamic>(SystemChannels.accessibility, null);
    semanticsTester.dispose();
  });

<<<<<<< HEAD
  testWidgets('Checkbox can be toggled by keyboard shortcuts', (WidgetTester tester) async {
=======
  testWidgetsWithLeakTracking('Checkbox can be toggled by keyboard shortcuts', (WidgetTester tester) async {
>>>>>>> db7ef5bf9f59442b0e200a90587e8fa5e0c6336a
    tester.binding.focusManager.highlightStrategy = FocusHighlightStrategy.alwaysTraditional;
    bool? value = true;
    Widget buildApp({bool enabled = true}) {
      return CupertinoApp(
        home: Center(
          child: StatefulBuilder(builder: (BuildContext context, StateSetter setState) {
            return CupertinoCheckbox(
              value: value,
              onChanged: enabled ? (bool? newValue) {
                setState(() {
                  value = newValue;
                });
              } : null,
              autofocus: true,
            );
          }),
        ),
      );
    }
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    // On web, switches don't respond to the enter key.
    expect(value, kIsWeb ? isTrue : isFalse);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(value, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pumpAndSettle();
    expect(value, isFalse);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pumpAndSettle();
    expect(value, isTrue);
  });

<<<<<<< HEAD
  testWidgets('Checkbox respects shape and side', (WidgetTester tester) async {
=======
  testWidgetsWithLeakTracking('Checkbox respects shape and side', (WidgetTester tester) async {
>>>>>>> db7ef5bf9f59442b0e200a90587e8fa5e0c6336a
    const RoundedRectangleBorder roundedRectangleBorder =
        RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(5)));

    const BorderSide side = BorderSide(
      width: 4,
      color: Color(0xfff44336),
    );

    Widget buildApp() {
      return CupertinoApp(
        home: Center(
          child: StatefulBuilder(builder: (BuildContext context, StateSetter setState) {
            return CupertinoCheckbox(
              value: false,
              onChanged: (bool? newValue) {},
              shape: roundedRectangleBorder,
              side: side,
            );
          }),
        ),
      );
    }

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(tester.widget<CupertinoCheckbox>(find.byType(CupertinoCheckbox)).shape, roundedRectangleBorder);
    expect(tester.widget<CupertinoCheckbox>(find.byType(CupertinoCheckbox)).side, side);
    expect(
      find.byType(CupertinoCheckbox),
      paints
        ..drrect(
          color: const Color(0xfff44336),
          outer: RRect.fromLTRBR(13.0, 13.0, 31.0, 31.0, const Radius.circular(5)),
          inner: RRect.fromLTRBR(17.0, 17.0, 27.0, 27.0, const Radius.circular(1)),
        ),
    );
  });
}
