// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import '../rendering/mock_canvas.dart';

import '../widgets/semantics_tester.dart';

Widget wrap({ required Widget child }) {
  return MediaQuery(
    data: const MediaQueryData(),
    child: Directionality(
      textDirection: TextDirection.ltr,
      child: Material(child: child),
    ),
  );
}

void main() {
  testWidgets('SwitchListTile control test', (WidgetTester tester) async {
    final List<dynamic> log = <dynamic>[];
    await tester.pumpWidget(wrap(
      child: SwitchListTile(
        value: true,
        onChanged: (bool value) { log.add(value); },
        title: const Text('Hello'),
      ),
    ));
    await tester.tap(find.text('Hello'));
    log.add('-');
    await tester.tap(find.byType(Switch));
    expect(log, equals(<dynamic>[false, '-', false]));
  });

  testWidgets('SwitchListTile semantics test', (WidgetTester tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);
    await tester.pumpWidget(wrap(
      child: Column(
        children: <Widget>[
          SwitchListTile(
            value: true,
            onChanged: (bool value) { },
            title: const Text('AAA'),
            secondary: const Text('aaa'),
          ),
          CheckboxListTile(
            value: true,
            onChanged: (bool? value) { },
            title: const Text('BBB'),
            secondary: const Text('bbb'),
          ),
          RadioListTile<bool>(
            value: true,
            groupValue: false,
            onChanged: (bool? value) { },
            title: const Text('CCC'),
            secondary: const Text('ccc'),
          ),
        ],
      ),
    ));

    // This test verifies that the label and the control get merged.
    expect(semantics, hasSemantics(TestSemantics.root(
      children: <TestSemantics>[
        TestSemantics.rootChild(
          id: 1,
          rect: const Rect.fromLTWH(0.0, 0.0, 800.0, 56.0),
          transform: null,
          flags: <SemanticsFlag>[
            SemanticsFlag.hasEnabledState,
            SemanticsFlag.hasToggledState,
            SemanticsFlag.isEnabled,
            SemanticsFlag.isFocusable,
            SemanticsFlag.isToggled,
          ],
          actions: SemanticsAction.tap.index,
          label: 'aaa\nAAA',
        ),
        TestSemantics.rootChild(
          id: 3,
          rect: const Rect.fromLTWH(0.0, 0.0, 800.0, 56.0),
          transform: Matrix4.translationValues(0.0, 56.0, 0.0),
          flags: <SemanticsFlag>[
            SemanticsFlag.hasCheckedState,
            SemanticsFlag.hasEnabledState,
            SemanticsFlag.isChecked,
            SemanticsFlag.isEnabled,
            SemanticsFlag.isFocusable,
          ],
          actions: SemanticsAction.tap.index,
          label: 'bbb\nBBB',
        ),
        TestSemantics.rootChild(
          id: 5,
          rect: const Rect.fromLTWH(0.0, 0.0, 800.0, 56.0),
          transform: Matrix4.translationValues(0.0, 112.0, 0.0),
          flags: <SemanticsFlag>[
            SemanticsFlag.hasCheckedState,
            SemanticsFlag.hasEnabledState,
            SemanticsFlag.isEnabled,
            SemanticsFlag.isFocusable,
            SemanticsFlag.isInMutuallyExclusiveGroup,
          ],
          actions: SemanticsAction.tap.index,
          label: 'CCC\nccc',
        ),
      ],
    )));

    semantics.dispose();
  });

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

    for (final TargetPlatform platform in <TargetPlatform>[ TargetPlatform.iOS, TargetPlatform.macOS ]) {
      value = false;
      await tester.pumpWidget(buildFrame(platform));
      expect(find.byType(CupertinoSwitch), findsOneWidget);
      expect(value, isFalse, reason: 'on ${describeEnum(platform)}');

      await tester.tap(find.byType(SwitchListTile));
      expect(value, isTrue, reason: 'on ${describeEnum(platform)}');
    }

    for (final TargetPlatform platform in <TargetPlatform>[ TargetPlatform.android, TargetPlatform.fuchsia, TargetPlatform.linux, TargetPlatform.windows ]) {
      value = false;
      await tester.pumpWidget(buildFrame(platform));
      await tester.pumpAndSettle(); // Finish the theme change animation.

      expect(find.byType(CupertinoSwitch), findsNothing);
      expect(value, isFalse, reason: 'on ${describeEnum(platform)}');
      await tester.tap(find.byType(SwitchListTile));
      expect(value, isTrue, reason: 'on ${describeEnum(platform)}');
    }
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

  testWidgets('SwitchListTile can autofocus unless disabled.', (WidgetTester tester) async {
    final GlobalKey childKey = GlobalKey();

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: ListView(
            children: <Widget>[
              SwitchListTile(
                value: true,
                onChanged: (_) {},
                title: Text('A', key: childKey),
                autofocus: true,
              ),
            ],
          ),
        ),
      ),
    );

    await tester.pump();
    expect(Focus.of(childKey.currentContext!).hasPrimaryFocus, isTrue);

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: ListView(
            children: <Widget>[
              SwitchListTile(
                value: true,
                onChanged: null,
                title: Text('A', key: childKey),
                autofocus: true,
              ),
            ],
          ),
        ),
      ),
    );

    await tester.pump();
    expect(Focus.of(childKey.currentContext!).hasPrimaryFocus, isFalse);
  });

  testWidgets('SwitchListTile controlAffinity test', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Material(
        child: SwitchListTile(
          value: true,
          onChanged: null,
          secondary: Icon(Icons.info),
          title: Text('Title'),
          controlAffinity: ListTileControlAffinity.leading,
        ),
      ),
    ));

    final ListTile listTile = tester.widget(find.byType(ListTile));
    // When controlAffinity is ListTileControlAffinity.leading, the position of
    // Switch is at leading edge and SwitchListTile.secondary at trailing edge.
    expect(listTile.leading.runtimeType, Switch);
    expect(listTile.trailing.runtimeType, Icon);
  });

  testWidgets('SwitchListTile controlAffinity default value test', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Material(
        child: SwitchListTile(
          value: true,
          onChanged: null,
          secondary: Icon(Icons.info),
          title: Text('Title'),
        ),
      ),
    ));

    final ListTile listTile = tester.widget(find.byType(ListTile));
    // By default, value of controlAffinity is ListTileControlAffinity.platform,
    // where the position of SwitchListTile.secondary is at leading edge and Switch
    // at trailing edge. This also covers test for ListTileControlAffinity.trailing.
    expect(listTile.leading.runtimeType, Icon);
    expect(listTile.trailing.runtimeType, Switch);
  });

  testWidgets('SwitchListTile respects shape', (WidgetTester tester) async {
    const ShapeBorder shapeBorder = RoundedRectangleBorder(
      borderRadius: BorderRadius.horizontal(right: Radius.circular(100))
    );

    await tester.pumpWidget(const MaterialApp(
      home: Material(
        child: SwitchListTile(
          value: true,
          onChanged: null,
          title: Text('Title'),
          shape: shapeBorder,
        ),
      ),
    ));

    expect(tester.widget<InkWell>(find.byType(InkWell)).customBorder, shapeBorder);
  });

  testWidgets('SwitchListTile respects tileColor', (WidgetTester tester) async {
    final Color tileColor = Colors.red.shade500;

    await tester.pumpWidget(
      wrap(
        child: Center(
          child: SwitchListTile(
            value: false,
            onChanged: null,
            title: const Text('Title'),
            tileColor: tileColor,
          ),
        ),
      ),
    );

    expect(find.byType(Material), paints..path(color: tileColor));
  });

  testWidgets('SwitchListTile respects selectedTileColor', (WidgetTester tester) async {
    final Color selectedTileColor = Colors.green.shade500;

    await tester.pumpWidget(
      wrap(
        child: Center(
          child: SwitchListTile(
            value: false,
            onChanged: null,
            title: const Text('Title'),
            selected: true,
            selectedTileColor: selectedTileColor,
          ),
        ),
      ),
    );

    expect(find.byType(Material), paints..path(color: selectedTileColor));
  });

  testWidgets('SwitchListTile selected item text Color', (WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/pull/76909

    const Color activeColor = Color(0xff00ff00);

    Widget buildFrame({ Color? activeColor, Color? toggleableActiveColor }) {
      return MaterialApp(
        theme: ThemeData.light().copyWith(
          toggleableActiveColor: toggleableActiveColor,
        ),
        home: Scaffold(
          body: Center(
            child: SwitchListTile(
              activeColor: activeColor,
              selected: true,
              title: const Text('title'),
              value: true,
              onChanged: (bool? value) { },
            ),
          ),
        ),
      );
    }

    Color? textColor(String text) {
      return tester.renderObject<RenderParagraph>(find.text(text)).text.style?.color;
    }

    await tester.pumpWidget(buildFrame(toggleableActiveColor: activeColor));
    expect(textColor('title'), activeColor);

    await tester.pumpWidget(buildFrame(activeColor: activeColor));
    expect(textColor('title'), activeColor);
  });
}
