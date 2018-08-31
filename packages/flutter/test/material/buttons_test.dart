// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../rendering/mock_canvas.dart';
import '../widgets/semantics_tester.dart';

void main() {
  setUp(() {
    debugResetSemanticsIdCounter();
  });

  testWidgets('Does FlatButton contribute semantics', (WidgetTester tester) async {
    final SemanticsTester semantics = new SemanticsTester(tester);
    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.ltr,
        child: new Material(
          child: new Center(
            child: new FlatButton(
              onPressed: () { },
              child: const Text('ABC')
            ),
          ),
        ),
      ),
    );

    expect(semantics, hasSemantics(
      new TestSemantics.root(
        children: <TestSemantics>[
          new TestSemantics.rootChild(
            actions: <SemanticsAction>[
              SemanticsAction.tap,
            ],
            label: 'ABC',
            rect: new Rect.fromLTRB(0.0, 0.0, 88.0, 48.0),
            transform: new Matrix4.translationValues(356.0, 276.0, 0.0),
            flags: <SemanticsFlag>[
              SemanticsFlag.isButton,
              SemanticsFlag.hasEnabledState,
              SemanticsFlag.isEnabled,
            ],
          )
        ],
      ),
      ignoreId: true,
    ));

    semantics.dispose();
  });

  testWidgets('Does RaisedButton contribute semantics', (WidgetTester tester) async {
    final SemanticsTester semantics = new SemanticsTester(tester);
    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.ltr,
        child: new Material(
          child: new Center(
            child: new RaisedButton(
              onPressed: () { },
              child: const Text('ABC')
            ),
          ),
        ),
      ),
    );

    expect(semantics, hasSemantics(
      new TestSemantics.root(
        children: <TestSemantics>[
          new TestSemantics.rootChild(
            actions: <SemanticsAction>[
              SemanticsAction.tap,
            ],
            label: 'ABC',
            rect: new Rect.fromLTRB(0.0, 0.0, 88.0, 48.0),
            transform: new Matrix4.translationValues(356.0, 276.0, 0.0),
            flags: <SemanticsFlag>[
              SemanticsFlag.isButton,
              SemanticsFlag.hasEnabledState,
              SemanticsFlag.isEnabled,
            ],
          )
        ]
      ),
      ignoreId: true,
    ));

    semantics.dispose();
  });

  testWidgets('Does FlatButton scale with font scale changes', (WidgetTester tester) async {
    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.ltr,
        child: new Material(
          child: new MediaQuery(
            data: const MediaQueryData(textScaleFactor: 1.0),
            child: new Center(
              child: new FlatButton(
                onPressed: () { },
                child: const Text('ABC'),
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.getSize(find.byType(FlatButton)), equals(const Size(88.0, 48.0)));
    expect(tester.getSize(find.byType(Text)), equals(const Size(42.0, 14.0)));

    // textScaleFactor expands text, but not button.
    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.ltr,
        child: new Material(
          child: new MediaQuery(
            data: const MediaQueryData(textScaleFactor: 1.3),
            child: new Center(
              child: new FlatButton(
                onPressed: () { },
                child: const Text('ABC'),
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.getSize(find.byType(FlatButton)), equals(const Size(88.0, 48.0)));
    // Scaled text rendering is different on Linux and Mac by one pixel.
    // TODO(gspencergoog): Figure out why this is, and fix it. https://github.com/flutter/flutter/issues/12357
    expect(tester.getSize(find.byType(Text)).width, isIn(<double>[54.0, 55.0]));
    expect(tester.getSize(find.byType(Text)).height, isIn(<double>[18.0, 19.0]));

    // Set text scale large enough to expand text and button.
    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.ltr,
        child: new Material(
          child: new MediaQuery(
            data: const MediaQueryData(textScaleFactor: 3.0),
            child: new Center(
              child: new FlatButton(
                onPressed: () { },
                child: const Text('ABC'),
              ),
            ),
          ),
        ),
      ),
    );

    // Scaled text rendering is different on Linux and Mac by one pixel.
    // TODO(gspencergoog): Figure out why this is, and fix it. https://github.com/flutter/flutter/issues/12357
    expect(tester.getSize(find.byType(FlatButton)).width, isIn(<double>[158.0, 159.0]));
    expect(tester.getSize(find.byType(FlatButton)).height, equals(48.0));
    expect(tester.getSize(find.byType(Text)).width, isIn(<double>[126.0, 127.0]));
    expect(tester.getSize(find.byType(Text)).height, equals(42.0));
  });

  // This test is very similar to the '...explicit splashColor and highlightColor' test
  // in icon_button_test.dart. If you change this one, you may want to also change that one.
  testWidgets('MaterialButton with explicit splashColor and highlightColor', (WidgetTester tester) async {
    const Color directSplashColor = Color(0xFF000011);
    const Color directHighlightColor = Color(0xFF000011);

    Widget buttonWidget = new Material(
      child: new Center(
        child: new MaterialButton(
          splashColor: directSplashColor,
          highlightColor: directHighlightColor,
          onPressed: () { /* to make sure the button is enabled */ },
          clipBehavior: Clip.antiAlias,
        ),
      ),
    );

    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.ltr,
        child: new Theme(
          data: new ThemeData(
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: buttonWidget,
        ),
      ),
    );

    final Offset center = tester.getCenter(find.byType(MaterialButton));
    final TestGesture gesture = await tester.startGesture(center);
    await tester.pump(); // start gesture
    await tester.pump(const Duration(milliseconds: 200)); // wait for splash to be well under way

    final Rect expectedClipRect = new Rect.fromLTRB(356.0, 282.0, 444.0, 318.0);
    final Path expectedClipPath = new Path()
     ..addRRect(new RRect.fromRectAndRadius(
         expectedClipRect,
         const Radius.circular(2.0),
     ));
    expect(
      Material.of(tester.element(find.byType(MaterialButton))),
      paints
        ..clipPath(pathMatcher: coversSameAreaAs(
            expectedClipPath,
            areaToCompare: expectedClipRect.inflate(10.0),
        ))
        ..circle(color: directSplashColor)
        ..rect(color: directHighlightColor)
    );

    const Color themeSplashColor1 = Color(0xFF001100);
    const Color themeHighlightColor1 = Color(0xFF001100);

    buttonWidget = new Material(
      child: new Center(
        child: new MaterialButton(
          onPressed: () { /* to make sure the button is enabled */ },
          clipBehavior: Clip.antiAlias,
        ),
      ),
    );

    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.ltr,
        child: new Theme(
          data: new ThemeData(
            highlightColor: themeHighlightColor1,
            splashColor: themeSplashColor1,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: buttonWidget,
        ),
      ),
    );

    expect(
      Material.of(tester.element(find.byType(MaterialButton))),
      paints
        ..clipPath(pathMatcher: coversSameAreaAs(
            expectedClipPath,
            areaToCompare: expectedClipRect.inflate(10.0),
        ))
        ..circle(color: themeSplashColor1)
        ..rect(color: themeHighlightColor1)
    );

    const Color themeSplashColor2 = Color(0xFF002200);
    const Color themeHighlightColor2 = Color(0xFF002200);

    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.ltr,
        child: new Theme(
          data: new ThemeData(
            highlightColor: themeHighlightColor2,
            splashColor: themeSplashColor2,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: buttonWidget, // same widget, so does not get updated because of us
        ),
      ),
    );

    expect(
      Material.of(tester.element(find.byType(MaterialButton))),
      paints
        ..circle(color: themeSplashColor2)
        ..rect(color: themeHighlightColor2)
    );

    await gesture.up();
  });

  testWidgets('MaterialButton has no clip by default', (WidgetTester tester) async {
    final GlobalKey buttonKey = new GlobalKey();
    final Widget buttonWidget = new Material(
      child: new Center(
        child: new MaterialButton(
          key: buttonKey,
          onPressed: () { /* to make sure the button is enabled */ },
        ),
      ),
    );

    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.ltr,
        child: new Theme(
          data: new ThemeData(
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: buttonWidget,
        ),
      ),
    );

    expect(
        tester.renderObject(find.byKey(buttonKey)),
        paintsExactlyCountTimes(#clipPath, 0)
    );
  });

  testWidgets('Disabled MaterialButton has same semantic size as enabled and exposes disabled semantics', (WidgetTester tester) async {
    final SemanticsTester semantics = new SemanticsTester(tester);

    final Rect expectedButtonSize = new Rect.fromLTRB(0.0, 0.0, 116.0, 48.0);
    // Button is in center of screen
    final Matrix4 expectedButtonTransform = new Matrix4.identity()
      ..translate(
        TestSemantics.fullScreen.width / 2 - expectedButtonSize.width /2,
        TestSemantics.fullScreen.height / 2 - expectedButtonSize.height /2,
      );

    // enabled button
    await tester.pumpWidget(new Directionality(
      textDirection: TextDirection.ltr,
      child: new Material(
        child: new Center(
          child: new MaterialButton(
            child: const Text('Button'),
            onPressed: () { /* to make sure the button is enabled */ },
          ),
        ),
      ),
    ));

    expect(semantics, hasSemantics(
      new TestSemantics.root(
        children: <TestSemantics>[
          new TestSemantics.rootChild(
            id: 1,
            rect: expectedButtonSize,
            transform: expectedButtonTransform,
            label: 'Button',
            actions: <SemanticsAction>[
              SemanticsAction.tap,
            ],
            flags: <SemanticsFlag>[
              SemanticsFlag.isButton,
              SemanticsFlag.hasEnabledState,
              SemanticsFlag.isEnabled,
            ],
          ),
        ],
      ),
    ));

    // disabled button
    await tester.pumpWidget(const Directionality(
      textDirection: TextDirection.ltr,
      child: Material(
        child: Center(
          child: MaterialButton(
            child: Text('Button'),
            onPressed: null, // button is disabled
          ),
        ),
      ),
    ));

    expect(semantics, hasSemantics(
      new TestSemantics.root(
        children: <TestSemantics>[
          new TestSemantics.rootChild(
            id: 1,
            rect: expectedButtonSize,
            transform: expectedButtonTransform,
            label: 'Button',
            flags: <SemanticsFlag>[
              SemanticsFlag.isButton,
              SemanticsFlag.hasEnabledState,
            ],
          ),
        ],
      ),
    ));


    semantics.dispose();
  });

  testWidgets('MaterialButton size is configurable by ThemeData.materialTapTargetSize', (WidgetTester tester) async {
    final Key key1 = new UniqueKey();
    await tester.pumpWidget(
      new Theme(
        data: new ThemeData(materialTapTargetSize: MaterialTapTargetSize.padded),
        child: new Directionality(
          textDirection: TextDirection.ltr,
          child: new Material(
            child: new Center(
              child: new MaterialButton(
                key: key1,
                child: const SizedBox(width: 50.0, height: 8.0),
                onPressed: () {},
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.getSize(find.byKey(key1)), const Size(88.0, 48.0));

    final Key key2 = new UniqueKey();
    await tester.pumpWidget(
      new Theme(
        data: new ThemeData(materialTapTargetSize: MaterialTapTargetSize.shrinkWrap),
        child: new Directionality(
          textDirection: TextDirection.ltr,
          child: new Material(
            child: new Center(
              child: new MaterialButton(
                key: key2,
                child: const SizedBox(width: 50.0, height: 8.0),
                onPressed: () {},
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.getSize(find.byKey(key2)), const Size(88.0, 36.0));
  });

  testWidgets('FlatButton size is configurable by ThemeData.materialTapTargetSize', (WidgetTester tester) async {
    final Key key1 = new UniqueKey();
    await tester.pumpWidget(
      new Theme(
        data: new ThemeData(materialTapTargetSize: MaterialTapTargetSize.padded),
        child: new Directionality(
          textDirection: TextDirection.ltr,
          child: new Material(
            child: new Center(
              child: new FlatButton(
                key: key1,
                child: const SizedBox(width: 50.0, height: 8.0),
                onPressed: () {},
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.getSize(find.byKey(key1)), const Size(88.0, 48.0));

    final Key key2 = new UniqueKey();
    await tester.pumpWidget(
      new Theme(
        data: new ThemeData(materialTapTargetSize: MaterialTapTargetSize.shrinkWrap),
        child: new Directionality(
          textDirection: TextDirection.ltr,
          child: new Material(
            child: new Center(
              child: new FlatButton(
                key: key2,
                child: const SizedBox(width: 50.0, height: 8.0),
                onPressed: () {},
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.getSize(find.byKey(key2)), const Size(88.0, 36.0));
  });

  testWidgets('RaisedButton size is configurable by ThemeData.materialTapTargetSize', (WidgetTester tester) async {
    final Key key1 = new UniqueKey();
    await tester.pumpWidget(
      new Theme(
        data: new ThemeData(materialTapTargetSize: MaterialTapTargetSize.padded),
        child: new Directionality(
          textDirection: TextDirection.ltr,
          child: new Material(
            child: new Center(
              child: new RaisedButton(
                key: key1,
                child: const SizedBox(width: 50.0, height: 8.0),
                onPressed: () {},
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.getSize(find.byKey(key1)), const Size(88.0, 48.0));

    final Key key2 = new UniqueKey();
    await tester.pumpWidget(
      new Theme(
        data: new ThemeData(materialTapTargetSize: MaterialTapTargetSize.shrinkWrap),
        child: new Directionality(
          textDirection: TextDirection.ltr,
          child: new Material(
            child: new Center(
              child: new RaisedButton(
                key: key2,
                child: const SizedBox(width: 50.0, height: 8.0),
                onPressed: () {},
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.getSize(find.byKey(key2)), const Size(88.0, 36.0));
  });

  testWidgets('RaisedButton has no clip by default', (WidgetTester tester) async{
    await tester.pumpWidget(
      new Directionality(
          textDirection: TextDirection.ltr,
          child: new Material(
            child: new RaisedButton(
              onPressed: () { /* to make sure the button is enabled */ },
            ),
          )
      ),
    );

    expect(
        tester.renderObject(find.byType(RaisedButton)),
        paintsExactlyCountTimes(#clipPath, 0)
    );
  });
}
