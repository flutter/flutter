// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('WidgetInspector smoke test', (WidgetTester tester) async {
    // This is a smoke test to verify that adding the inspector doesn't crash.
    await tester.pumpWidget(
      new Stack(
        children: <Widget>[
          const Text('a'),
          const Text('b'),
          const Text('c'),
        ],
      ),
    );

    await tester.pumpWidget(
      new WidgetInspector(
        selectButtonBuilder: null,
        child: new Stack(
          children: <Widget>[
            const Text('a'),
            const Text('b'),
            const Text('c'),
          ],
        ),
      ),
    );

    expect(true, isTrue); // Expect that we reach here without crashing.
  });

  testWidgets('WidgetInspector interaction test', (WidgetTester tester) async {
    final List<String> log = <String>[];
    final GlobalKey selectButtonKey = new GlobalKey();
    final GlobalKey inspectorKey = new GlobalKey();
    final GlobalKey topButtonKey = new GlobalKey();

    Widget selectButtonBuilder(BuildContext context, VoidCallback onPressed) {
      return new Material(child: new RaisedButton(onPressed: onPressed, key: selectButtonKey));
    }
    // State type is private, hence using dynamic.
    dynamic getInspectorState() => inspectorKey.currentState;
    String paragraphText(RenderParagraph paragraph) => paragraph.text.text;

    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.ltr,
        child: new WidgetInspector(
          key: inspectorKey,
          selectButtonBuilder: selectButtonBuilder,
          child: new Material(
            child: new ListView(
              children: <Widget>[
                new RaisedButton(
                  key: topButtonKey,
                  onPressed: () {
                    log.add('top');
                  },
                  child: const Text('TOP'),
                ),
                new RaisedButton(
                  onPressed: () {
                    log.add('bottom');
                  },
                  child: const Text('BOTTOM'),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(getInspectorState().selection.current, isNull);
    await tester.tap(find.text('TOP'));
    await tester.pump();
    // Tap intercepted by the inspector
    expect(log, equals(<String>[]));
    final InspectorSelection selection = getInspectorState().selection;
    expect(paragraphText(selection.current), equals('TOP'));
    final RenderObject topButton = find.byKey(topButtonKey).evaluate().first.renderObject;
    expect(selection.candidates.contains(topButton), isTrue);

    await tester.tap(find.text('TOP'));
    expect(log, equals(<String>['top']));
    log.clear();

    await tester.tap(find.text('BOTTOM'));
    expect(log, equals(<String>['bottom']));
    log.clear();
    // Ensure the inspector selection has not changed to bottom.
    expect(paragraphText(getInspectorState().selection.current), equals('TOP'));

    await tester.tap(find.byKey(selectButtonKey));
    await tester.pump();

    // We are now back in select mode so tapping the bottom button will have
    // not trigger a click but will cause it to be selected.
    await tester.tap(find.text('BOTTOM'));
    expect(log, equals(<String>[]));
    log.clear();
    expect(paragraphText(getInspectorState().selection.current), equals('BOTTOM'));
  });

  testWidgets('WidgetInspector scroll test', (WidgetTester tester) async {
    final Key childKey = new UniqueKey();
    final GlobalKey selectButtonKey = new GlobalKey();
    final GlobalKey inspectorKey = new GlobalKey();

    Widget selectButtonBuilder(BuildContext context, VoidCallback onPressed) {
      return new Material(child: new RaisedButton(onPressed: onPressed, key: selectButtonKey));
    }
    // State type is private, hence using dynamic.
    dynamic getInspectorState() => inspectorKey.currentState;

    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.ltr,
        child: new WidgetInspector(
          key: inspectorKey,
          selectButtonBuilder: selectButtonBuilder,
          child: new ListView(
            children: <Widget>[
              new Container(
                key: childKey,
                height: 5000.0,
              ),
            ],
          ),
        ),
      ),
    );

    expect(tester.getTopLeft(find.byKey(childKey)).dy, equals(0.0));

    await tester.fling(find.byType(ListView), const Offset(0.0, -200.0), 200.0);
    await tester.pump();

    // Fling does nothing as are in inspect mode.
    expect(tester.getTopLeft(find.byKey(childKey)).dy, equals(0.0));

    await tester.fling(find.byType(ListView), const Offset(200.0, 0.0), 200.0);
    await tester.pump();

    // Fling still does nothing as are in inspect mode.
    expect(tester.getTopLeft(find.byKey(childKey)).dy, equals(0.0));

    await tester.tap(find.byType(ListView));
    await tester.pump();
    expect(getInspectorState().selection.current, isNotNull);

    // Now out of inspect mode due to the click.
    await tester.fling(find.byType(ListView), const Offset(0.0, -200.0), 200.0);
    await tester.pump();

    expect(tester.getTopLeft(find.byKey(childKey)).dy, equals(-200.0));

    await tester.fling(find.byType(ListView), const Offset(0.0, 200.0), 200.0);
    await tester.pump();

    expect(tester.getTopLeft(find.byKey(childKey)).dy, equals(0.0));
  });

  testWidgets('WidgetInspector long press', (WidgetTester tester) async {
    bool didLongPress = false;

    await tester.pumpWidget(
      new WidgetInspector(
        selectButtonBuilder: null,
        child: new GestureDetector(
          onLongPress: () {
            expect(didLongPress, isFalse);
            didLongPress = true;
          },
          child: const Text('target'),
        ),
      ),
    );

    await tester.longPress(find.text('target'));
    // The inspector will swallow the long press.
    expect(didLongPress, isFalse);
  });

  testWidgets('WidgetInspector offstage', (WidgetTester tester) async {
    final GlobalKey inspectorKey = new GlobalKey();
    final GlobalKey clickTarget = new GlobalKey();

    Widget createSubtree({ double width, Key key }) {
      return new Stack(
        children: <Widget>[
          new Positioned(
            key: key,
            left: 0.0,
            top: 0.0,
            width: width,
            height: 100.0,
            child: new Text(width.toString()),
          ),
        ]
      );
    }
    await tester.pumpWidget(
      new WidgetInspector(
        key: inspectorKey,
        selectButtonBuilder: null,
        child: new Overlay(
          initialEntries: <OverlayEntry>[
            new OverlayEntry(
              opaque: false,
              maintainState: true,
              builder: (BuildContext _) => createSubtree(width: 94.0),
            ),
            new OverlayEntry(
              opaque: true,
              maintainState: true,
              builder: (BuildContext _) => createSubtree(width: 95.0),
            ),
            new OverlayEntry(
              opaque: false,
              maintainState: true,
              builder: (BuildContext _) => createSubtree(width: 96.0, key: clickTarget),
            ),
          ],
        ),
      ),
    );

    await tester.longPress(find.byKey(clickTarget));
    // State type is private, hence using dynamic.
    final dynamic inspectorState = inspectorKey.currentState;
    // The object with width 95.0 wins over the object with width 94.0 because
    // the subtree with width 94.0 is offstage.
    expect(inspectorState.selection.current.semanticBounds.width, equals(95.0));

    // Exactly 2 out of the 3 text elements should be in the candidate list of
    // objects to select as only 2 are onstage.
    expect(inspectorState.selection.candidates.where((RenderObject object) => object is RenderParagraph).length, equals(2));
  });
}
