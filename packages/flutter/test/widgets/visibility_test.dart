// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../rendering/mock_canvas.dart';
import 'semantics_tester.dart';

void main() {
  testWidgets('Visibility', (WidgetTester tester) async {
    final SemanticsTester semantics = new SemanticsTester(tester);
    final List<String> log = <String>[];

    final Widget testChild = new GestureDetector(
      onTap: () { log.add('tap'); },
      child: new Builder(
        builder: (BuildContext context) {
          final bool animating = TickerMode.of(context);
          return new Text('a $animating', textDirection: TextDirection.rtl);
        },
      ),
    );

    final Matcher expectedSemanticsWhenPresent = hasSemantics(
      new TestSemantics.root(
        children: <TestSemantics>[
          new TestSemantics.rootChild(
            label: 'a true',
            textDirection: TextDirection.rtl,
            actions: <SemanticsAction>[SemanticsAction.tap],
          )
        ],
      ),
      ignoreId: true,
      ignoreRect: true,
      ignoreTransform: true,
    );

    final Matcher expectedSemanticsWhenAbsent = hasSemantics(new TestSemantics.root());

    await tester.pumpWidget(new Visibility(child: testChild));
    expect(find.byType(Text, skipOffstage: false), findsOneWidget);
    expect(find.text('a true', skipOffstage: false), findsOneWidget);
    expect(find.byType(Visibility), paints..paragraph());
    expect(tester.getSize(find.byType(Visibility)), const Size(800.0, 600.0));
    expect(semantics, expectedSemanticsWhenPresent);
    expect(log, <String>[]);
    await tester.tap(find.byType(Visibility));
    expect(log, <String>['tap']);
    log.clear();

    await tester.pumpWidget(new Visibility(child: testChild, visible: false));
    expect(find.byType(Text, skipOffstage: false), findsNothing);
    expect(find.byType(Visibility), paintsNothing);
    expect(tester.getSize(find.byType(Visibility)), const Size(800.0, 600.0));
    expect(semantics, expectedSemanticsWhenAbsent);
    expect(log, <String>[]);
    await tester.tap(find.byType(Visibility));
    expect(log, <String>[]);
    log.clear();

    await tester.pumpWidget(new Center(child: new Visibility(child: testChild, visible: false)));
    expect(find.byType(Text, skipOffstage: false), findsNothing);
    expect(find.byType(Placeholder), findsNothing);
    expect(find.byType(Visibility), paintsNothing);
    expect(tester.getSize(find.byType(Visibility)), Size.zero);
    expect(semantics, expectedSemanticsWhenAbsent);
    expect(log, <String>[]);
    await tester.tap(find.byType(Visibility));
    expect(log, <String>[]);
    log.clear();

    await tester.pumpWidget(new Center(child: new Visibility(child: testChild, replacement: const Placeholder(), visible: false)));
    expect(find.byType(Text, skipOffstage: false), findsNothing);
    expect(find.byType(Placeholder), findsOneWidget);
    expect(find.byType(Visibility), paints..path());
    expect(tester.getSize(find.byType(Visibility)), const Size(800.0, 600.0));
    expect(semantics, expectedSemanticsWhenAbsent);
    expect(log, <String>[]);
    await tester.tap(find.byType(Visibility));
    expect(log, <String>[]);
    log.clear();

    await tester.pumpWidget(new Center(child: new Visibility(child: testChild, replacement: const Placeholder(), visible: true)));
    expect(find.byType(Text, skipOffstage: false), findsOneWidget);
    expect(find.text('a true', skipOffstage: false), findsOneWidget);
    expect(find.byType(Placeholder), findsNothing);
    expect(find.byType(Visibility), paints..paragraph());
    expect(tester.getSize(find.byType(Visibility)), const Size(84.0, 14.0));
    expect(semantics, expectedSemanticsWhenPresent);
    expect(log, <String>[]);
    await tester.tap(find.byType(Visibility));
    expect(log, <String>['tap']);
    log.clear();

    await tester.pumpWidget(new Center(child: new Visibility(child: testChild, visible: true, maintainState: true, maintainAnimation: true, maintainSize: true, maintainInteractivity: true, maintainSemantics: true)));
    expect(find.byType(Text, skipOffstage: false), findsOneWidget);
    expect(find.text('a true', skipOffstage: false), findsOneWidget);
    expect(find.byType(Placeholder), findsNothing);
    expect(find.byType(Visibility), paints..paragraph());
    expect(tester.getSize(find.byType(Visibility)), const Size(84.0, 14.0));
    expect(semantics, expectedSemanticsWhenPresent);
    expect(log, <String>[]);
    await tester.tap(find.byType(Visibility));
    expect(log, <String>['tap']);
    log.clear();

    await tester.pumpWidget(new Center(child: new Visibility(child: testChild, visible: false, maintainState: true, maintainAnimation: true, maintainSize: true, maintainInteractivity: true, maintainSemantics: true)));
    expect(find.byType(Text, skipOffstage: false), findsOneWidget);
    expect(find.text('a true', skipOffstage: false), findsOneWidget);
    expect(find.byType(Placeholder), findsNothing);
    expect(find.byType(Visibility), paintsNothing);
    expect(tester.getSize(find.byType(Visibility)), const Size(84.0, 14.0));
    expect(semantics, expectedSemanticsWhenPresent);
    expect(log, <String>[]);
    await tester.tap(find.byType(Visibility));
    expect(log, <String>['tap']);
    log.clear();

    await tester.pumpWidget(new Center(child: new Visibility(child: testChild, visible: false, maintainState: true, maintainAnimation: true, maintainSize: true, maintainInteractivity: true)));
    expect(find.byType(Text, skipOffstage: false), findsOneWidget);
    expect(find.text('a true', skipOffstage: false), findsOneWidget);
    expect(find.byType(Placeholder), findsNothing);
    expect(find.byType(Visibility), paintsNothing);
    expect(tester.getSize(find.byType(Visibility)), const Size(84.0, 14.0));
    expect(semantics, expectedSemanticsWhenAbsent);
    expect(log, <String>[]);
    await tester.tap(find.byType(Visibility));
    expect(log, <String>['tap']);
    log.clear();

    await tester.pumpWidget(new Center(child: new Visibility(child: testChild, visible: false, maintainState: true, maintainAnimation: true, maintainSize: true, maintainSemantics: true)));
    expect(find.byType(Text, skipOffstage: false), findsOneWidget);
    expect(find.text('a true', skipOffstage: false), findsOneWidget);
    expect(find.byType(Placeholder), findsNothing);
    expect(find.byType(Visibility), paintsNothing);
    expect(tester.getSize(find.byType(Visibility)), const Size(84.0, 14.0));
    expect(semantics, expectedSemanticsWhenPresent);
    expect(log, <String>[]);
    await tester.tap(find.byType(Visibility));
    expect(log, <String>[]);
    log.clear();

    await tester.pumpWidget(new Center(child: new Visibility(child: testChild, visible: false, maintainState: true, maintainAnimation: true, maintainSize: true)));
    expect(find.byType(Text, skipOffstage: false), findsOneWidget);
    expect(find.text('a true', skipOffstage: false), findsOneWidget);
    expect(find.byType(Placeholder), findsNothing);
    expect(find.byType(Visibility), paintsNothing);
    expect(tester.getSize(find.byType(Visibility)), const Size(84.0, 14.0));
    expect(semantics, expectedSemanticsWhenAbsent);
    expect(log, <String>[]);
    await tester.tap(find.byType(Visibility));
    expect(log, <String>[]);
    log.clear();

    await tester.pumpWidget(new Center(child: new Visibility(child: testChild, visible: false, maintainState: true, maintainAnimation: true)));
    expect(find.byType(Text, skipOffstage: false), findsOneWidget);
    expect(find.byType(Text, skipOffstage: true), findsNothing);
    expect(find.text('a true', skipOffstage: false), findsOneWidget);
    expect(find.byType(Placeholder), findsNothing);
    expect(find.byType(Visibility), paintsNothing);
    expect(tester.getSize(find.byType(Visibility)), Size.zero);
    expect(semantics, expectedSemanticsWhenAbsent);
    expect(log, <String>[]);
    await tester.tap(find.byType(Visibility));
    expect(log, <String>[]);
    log.clear();

    await tester.pumpWidget(new Center(child: new Visibility(child: testChild, visible: false, maintainState: true)));
    expect(find.byType(Text, skipOffstage: false), findsOneWidget);
    expect(find.byType(Text, skipOffstage: true), findsNothing);
    expect(find.text('a false', skipOffstage: false), findsOneWidget);
    expect(find.byType(Placeholder), findsNothing);
    expect(find.byType(Visibility), paintsNothing);
    expect(tester.getSize(find.byType(Visibility)), Size.zero);
    expect(semantics, expectedSemanticsWhenAbsent);
    expect(log, <String>[]);
    await tester.tap(find.byType(Visibility));
    expect(log, <String>[]);
    log.clear();

    await tester.pumpWidget(new Center(child: new Visibility(child: testChild, visible: false)));
    expect(find.byType(Text, skipOffstage: false), findsNothing);
    expect(find.byType(Placeholder), findsNothing);
    expect(find.byType(Visibility), paintsNothing);
    expect(tester.getSize(find.byType(Visibility)), Size.zero);
    expect(semantics, expectedSemanticsWhenAbsent);
    expect(log, <String>[]);
    await tester.tap(find.byType(Visibility));
    expect(log, <String>[]);
    log.clear();

    semantics.dispose();
  });
}
