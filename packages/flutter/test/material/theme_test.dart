// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ThemeDataTween control test', () {
    final ThemeData light = new ThemeData.light();
    final ThemeData dark = new ThemeData.light();
    final ThemeDataTween tween = new ThemeDataTween(begin: light, end: dark);
    expect(tween.lerp(0.25), equals(ThemeData.lerp(light, dark, 0.25)));
  });

  testWidgets('PopupMenu inherits app theme', (WidgetTester tester) async {
    final Key popupMenuButtonKey = new UniqueKey();
    await tester.pumpWidget(
      new MaterialApp(
        theme: new ThemeData(brightness: Brightness.dark),
        home: new Scaffold(
          appBar: new AppBar(
            actions: <Widget>[
              new PopupMenuButton<String>(
                key: popupMenuButtonKey,
                itemBuilder: (BuildContext context) {
                  return <PopupMenuItem<String>>[
                    const PopupMenuItem<String>(child: const Text('menuItem'))
                  ];
                }
              ),
            ]
          )
        )
      )
    );

    await tester.tap(find.byKey(popupMenuButtonKey));
    await tester.pump(const Duration(seconds: 1));

    expect(Theme.of(tester.element(find.text('menuItem'))).brightness, equals(Brightness.dark));
  });

  testWidgets('Fallback theme', (WidgetTester tester) async {
    BuildContext capturedContext;
    await tester.pumpWidget(
      new Builder(
        builder: (BuildContext context) {
          capturedContext = context;
          return new Container();
        }
      )
    );

    expect(Theme.of(capturedContext), equals(new ThemeData.fallback()));
    expect(Theme.of(capturedContext, shadowThemeOnly: true), isNull);
  });

  testWidgets('PopupMenu inherits shadowed app theme', (WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/5572
    final Key popupMenuButtonKey = new UniqueKey();
    await tester.pumpWidget(
      new MaterialApp(
        theme: new ThemeData(brightness: Brightness.dark),
        home: new Theme(
          data: new ThemeData(brightness: Brightness.light),
          child: new Scaffold(
            appBar: new AppBar(
              actions: <Widget>[
                new PopupMenuButton<String>(
                  key: popupMenuButtonKey,
                  itemBuilder: (BuildContext context) {
                    return <PopupMenuItem<String>>[
                      const PopupMenuItem<String>(child: const Text('menuItem'))
                    ];
                  }
                ),
              ]
            )
          )
        )
      )
    );

    await tester.tap(find.byKey(popupMenuButtonKey));
    await tester.pump(const Duration(seconds: 1));

    expect(Theme.of(tester.element(find.text('menuItem'))).brightness, equals(Brightness.light));
  });

  testWidgets('DropdownMenu inherits shadowed app theme', (WidgetTester tester) async {
    final Key dropdownMenuButtonKey = new UniqueKey();
    await tester.pumpWidget(
      new MaterialApp(
        theme: new ThemeData(brightness: Brightness.dark),
        home: new Theme(
          data: new ThemeData(brightness: Brightness.light),
          child: new Scaffold(
            appBar: new AppBar(
              actions: <Widget>[
                new DropdownButton<String>(
                  key: dropdownMenuButtonKey,
                  onChanged: (String newValue) { },
                  value: 'menuItem',
                  items: <DropdownMenuItem<String>>[
                    const DropdownMenuItem<String>(
                      value: 'menuItem',
                      child: const Text('menuItem'),
                    ),
                  ],
                )
              ]
            )
          )
        )
      )
    );

    await tester.tap(find.byKey(dropdownMenuButtonKey));
    await tester.pump(const Duration(seconds: 1));

    for(Element item in tester.elementList(find.text('menuItem')))
      expect(Theme.of(item).brightness, equals(Brightness.light));
  });

  testWidgets('ModalBottomSheet inherits shadowed app theme', (WidgetTester tester) async {
    await tester.pumpWidget(
      new MaterialApp(
        theme: new ThemeData(brightness: Brightness.dark),
        home: new Theme(
          data: new ThemeData(brightness: Brightness.light),
          child: new Scaffold(
            body: new Center(
              child: new Builder(
                builder: (BuildContext context) {
                  return new RaisedButton(
                    onPressed: () {
                      showModalBottomSheet<Null>(
                        context: context,
                        builder: (BuildContext context) => const Text('bottomSheet'),
                      );
                    },
                    child: const Text('SHOW'),
                  );
                }
              )
            )
          )
        )
      )
    );

    await tester.tap(find.text('SHOW'));
    await tester.pump(const Duration(seconds: 1));
    expect(Theme.of(tester.element(find.text('bottomSheet'))).brightness, equals(Brightness.light));

    await tester.tap(find.text('bottomSheet')); // dismiss the bottom sheet
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('Dialog inherits shadowed app theme', (WidgetTester tester) async {
    final GlobalKey<ScaffoldState> scaffoldKey = new GlobalKey<ScaffoldState>();
    await tester.pumpWidget(
      new MaterialApp(
        theme: new ThemeData(brightness: Brightness.dark),
        home: new Theme(
          data: new ThemeData(brightness: Brightness.light),
          child: new Scaffold(
            key: scaffoldKey,
            body: new Center(
              child: new Builder(
                builder: (BuildContext context) {
                  return new RaisedButton(
                    onPressed: () {
                      showDialog<Null>(
                        context: context,
                        child: const Text('dialog'),
                      );
                    },
                    child: const Text('SHOW'),
                  );
                }
              )
            )
          )
        )
      )
    );

    await tester.tap(find.text('SHOW'));
    await tester.pump(const Duration(seconds: 1));
    expect(Theme.of(tester.element(find.text('dialog'))).brightness, equals(Brightness.light));
  });

  testWidgets("Scaffold inherits theme's scaffoldBackgroundColor", (WidgetTester tester) async {
    const Color green = const Color(0xFF00FF00);

    await tester.pumpWidget(
      new MaterialApp(
        theme: new ThemeData(scaffoldBackgroundColor: green),
        home: new Scaffold(
          body: new Center(
            child: new Builder(
              builder: (BuildContext context) {
                return new GestureDetector(
                  onTap: () {
                    showDialog<Null>(
                      context: context,
                      child: const Scaffold(
                        body: const SizedBox(
                          width: 200.0,
                          height: 200.0,
                        ),
                      )
                    );
                  },
                  child: const Text('SHOW'),
                );
              },
            ),
          ),
        ),
      )
    );

    await tester.tap(find.text('SHOW'));
    await tester.pump(const Duration(seconds: 1));

    final List<Material> materials = tester.widgetList(find.byType(Material)).toList();
    expect(materials.length, equals(2));
    expect(materials[0].color, green); // app scaffold
    expect(materials[1].color, green); // dialog scaffold
  });

  testWidgets('IconThemes are applied', (WidgetTester tester) async {
    await tester.pumpWidget(
      new MaterialApp(
        theme: new ThemeData(iconTheme: const IconThemeData(color: Colors.green, size: 10.0)),
        home: const Icon(Icons.computer),
      )
    );

    RenderParagraph glyphText = tester.renderObject(find.byType(RichText));

    expect(glyphText.text.style.color, Colors.green);
    expect(glyphText.text.style.fontSize, 10.0);

    await tester.pumpWidget(
      new MaterialApp(
        theme: new ThemeData(iconTheme: const IconThemeData(color: Colors.orange, size: 20.0)),
        home: const Icon(Icons.computer),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100)); // Halfway through the theme transition

    glyphText = tester.renderObject(find.byType(RichText));

    expect(glyphText.text.style.color, Color.lerp(Colors.green, Colors.orange, 0.5));
    expect(glyphText.text.style.fontSize, 15.0);

    await tester.pump(const Duration(milliseconds: 100)); // Finish the transition
    glyphText = tester.renderObject(find.byType(RichText));

    expect(glyphText.text.style.color, Colors.orange);
    expect(glyphText.text.style.fontSize, 20.0);
  });

  testWidgets(
    'Same ThemeData reapplied does not trigger descendents rebuilds',
    (WidgetTester tester) async {
      testBuildCalled = 0;
      ThemeData themeData = new ThemeData(primaryColor: const Color(0xFF000000));

      await tester.pumpWidget(
        new Theme(
          data: themeData,
          child: const Test(),
        ),
      );
      expect(testBuildCalled, 1);

      // Pump the same widgets again.
      await tester.pumpWidget(
        new Theme(
          data: themeData,
          child: const Test(),
        ),
      );
      // No repeated build calls to the child since it's the same theme data.
      expect(testBuildCalled, 1);

      // New instance of theme data but still the same content.
      themeData = new ThemeData(primaryColor: const Color(0xFF000000));
      await tester.pumpWidget(
        new Theme(
          data: themeData,
          child: const Test(),
        ),
      );
      // Still no repeated calls.
      expect(testBuildCalled, 1);

      // Different now.
      themeData = new ThemeData(primaryColor: const Color(0xFF222222));
      await tester.pumpWidget(
        new Theme(
          data: themeData,
          child: const Test(),
        ),
      );
      // Should call build again.
      expect(testBuildCalled, 2);
    },
  );
}

int testBuildCalled;
class Test extends StatefulWidget {
  const Test();

  @override
  _TestState createState() => new _TestState();
}

class _TestState extends State<Test> {
  @override
  Widget build(BuildContext context) {
    testBuildCalled += 1;
    return new Container(
      decoration: new BoxDecoration(
        color: Theme.of(context).primaryColor,
      ),
    );
  }
}
