// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/src/foundation/diagnostics.dart';
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

    expect(Theme.of(capturedContext), equals(ThemeData.localize(new ThemeData.fallback(), MaterialTextGeometry.englishLike)));
    expect(Theme.of(capturedContext, shadowThemeOnly: true), isNull);
  });

  testWidgets('ThemeData.localize memoizes the result', (WidgetTester tester) async {
    final ThemeData light = new ThemeData.light();
    final ThemeData dark = new ThemeData.dark();

    // Same input, same output.
    expect(
      ThemeData.localize(light, MaterialTextGeometry.englishLike),
      same(ThemeData.localize(light, MaterialTextGeometry.englishLike)),
    );

    // Different text geometry, different output.
    expect(
      ThemeData.localize(light, MaterialTextGeometry.englishLike),
      isNot(same(ThemeData.localize(light, MaterialTextGeometry.tall))),
    );

    // Different base theme, different output.
    expect(
      ThemeData.localize(light, MaterialTextGeometry.englishLike),
      isNot(same(ThemeData.localize(dark, MaterialTextGeometry.englishLike))),
    );
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
                  items: const <DropdownMenuItem<String>>[
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

    for (Element item in tester.elementList(find.text('menuItem')))
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
                        builder: (BuildContext context) => const Text('dialog'),
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
                      builder: (BuildContext context) {
                        return const Scaffold(
                          body: const SizedBox(
                            width: 200.0,
                            height: 200.0,
                          ),
                        );
                      },
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

    final List<Material> materials = tester.widgetList<Material>(find.byType(Material)).toList();
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
    'Same ThemeData reapplied does not trigger descendants rebuilds',
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

  testWidgets('Text geometry set in Theme has higher precedence than that of Localizations', (WidgetTester tester) async {
    const double _kMagicFontSize = 4321.0;
    final ThemeData fallback = new ThemeData.fallback();
    final ThemeData customTheme = fallback.copyWith(
      primaryTextTheme: fallback.primaryTextTheme.copyWith(
        body1: fallback.primaryTextTheme.body1.copyWith(
          fontSize: _kMagicFontSize,
        )
      ),
    );
    expect(customTheme.primaryTextTheme.body1.fontSize, _kMagicFontSize);

    double actualFontSize;
    await tester.pumpWidget(new Directionality(
      textDirection: TextDirection.ltr,
      child: new Theme(
        data: customTheme,
        child: new Builder(builder: (BuildContext context) {
          final ThemeData theme = Theme.of(context);
          actualFontSize = theme.primaryTextTheme.body1.fontSize;
          return new Text(
            'A',
            style: theme.primaryTextTheme.body1,
          );
        }),
      ),
    ));

    expect(actualFontSize, _kMagicFontSize);
  });

  testWidgets('Default Theme provides all basic TextStyle properties', (WidgetTester tester) async {
    ThemeData theme;
    await tester.pumpWidget(new Directionality(
      textDirection: TextDirection.ltr,
      child: new Builder(
        builder: (BuildContext context) {
          theme = Theme.of(context);
          return const Text('A');
        },
      ),
    ));

    List<TextStyle> extractStyles(TextTheme textTheme) {
      return <TextStyle>[
        textTheme.display4,
        textTheme.display3,
        textTheme.display2,
        textTheme.display1,
        textTheme.headline,
        textTheme.title,
        textTheme.subhead,
        textTheme.body2,
        textTheme.body1,
        textTheme.caption,
        textTheme.button,
      ];
    }

    for (TextTheme textTheme in <TextTheme>[theme.textTheme, theme.primaryTextTheme, theme.accentTextTheme]) {
      for (TextStyle style in extractStyles(textTheme).map((TextStyle style) => new _TextStyleProxy(style))) {
        expect(style.inherit, false);
        expect(style.color, isNotNull);
        expect(style.fontFamily, isNotNull);
        expect(style.fontSize, isNotNull);
        expect(style.fontWeight, isNotNull);
        expect(style.fontStyle, null);
        expect(style.letterSpacing, null);
        expect(style.wordSpacing, null);
        expect(style.textBaseline, isNotNull);
        expect(style.height, null);
        expect(style.decoration, TextDecoration.none);
        expect(style.decorationColor, null);
        expect(style.decorationStyle, null);
        expect(style.debugLabel, isNotNull);
      }
    }

    expect(theme.textTheme.display4.debugLabel, '(englishLike display4).merge(blackMountainView display4)');
  });
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

/// This class exists only to make sure that we test all the properties of the
/// [TextStyle] class. If a property is added/removed/renamed, the analyzer will
/// complain that this class has incorrect overrides.
class _TextStyleProxy implements TextStyle {
  _TextStyleProxy(this._delegate);

  final TextStyle _delegate;

  // Do make sure that all the properties correctly forward to the _delegate.
  @override Color get color => _delegate.color;
  @override String get debugLabel => _delegate.debugLabel;
  @override TextDecoration get decoration => _delegate.decoration;
  @override Color get decorationColor => _delegate.decorationColor;
  @override TextDecorationStyle get decorationStyle => _delegate.decorationStyle;
  @override String get fontFamily => _delegate.fontFamily;
  @override double get fontSize => _delegate.fontSize;
  @override FontStyle get fontStyle => _delegate.fontStyle;
  @override FontWeight get fontWeight => _delegate.fontWeight;
  @override double get height => _delegate.height;
  @override bool get inherit => _delegate.inherit;
  @override double get letterSpacing => _delegate.letterSpacing;
  @override TextBaseline get textBaseline => _delegate.textBaseline;
  @override double get wordSpacing => _delegate.wordSpacing;

  @override
  DiagnosticsNode toDiagnosticsNode({String name, DiagnosticsTreeStyle style}) {
    throw new UnimplementedError();
  }

  @override
  String toStringShort() {
    throw new UnimplementedError();
  }

  @override
  TextStyle apply({Color color, TextDecoration decoration, Color decorationColor, TextDecorationStyle decorationStyle, String fontFamily, double fontSizeFactor: 1.0, double fontSizeDelta: 0.0, int fontWeightDelta: 0, double letterSpacingFactor: 1.0, double letterSpacingDelta: 0.0, double wordSpacingFactor: 1.0, double wordSpacingDelta: 0.0, double heightFactor: 1.0, double heightDelta: 0.0}) {
    throw new UnimplementedError();
  }

  @override
  RenderComparison compareTo(TextStyle other) {
    throw new UnimplementedError();
  }

  @override
  TextStyle copyWith({Color color, String fontFamily, double fontSize, FontWeight fontWeight, FontStyle fontStyle, double letterSpacing, double wordSpacing, TextBaseline textBaseline, double height, TextDecoration decoration, Color decorationColor, TextDecorationStyle decorationStyle, String debugLabel}) {
    throw new UnimplementedError();
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties, {String prefix: ''}) {
    throw new UnimplementedError();
  }

  @override
  ui.ParagraphStyle getParagraphStyle({TextAlign textAlign, TextDirection textDirection, double textScaleFactor: 1.0, String ellipsis, int maxLines}) {
    throw new UnimplementedError();
  }

  @override
  ui.TextStyle getTextStyle({double textScaleFactor: 1.0}) {
    throw new UnimplementedError();
  }

  @override
  TextStyle merge(TextStyle other) {
    throw new UnimplementedError();
  }
}
