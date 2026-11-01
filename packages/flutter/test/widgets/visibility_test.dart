// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'semantics_tester.dart';

class TestState extends StatefulWidget {
  const TestState({super.key, required this.child, required this.log});
  final Widget child;
  final List<String> log;
  @override
  State<TestState> createState() => _TestStateState();
}

class _TestStateState extends State<TestState> {
  @override
  void initState() {
    super.initState();
    widget.log.add('created new state');
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

void main() {
  testWidgets('Visibility', (WidgetTester tester) async {
    final semantics = SemanticsTester(tester);
    final log = <String>[];

    final Widget testChild = GestureDetector(
      onTap: () {
        log.add('tap');
      },
      child: Builder(
        builder: (BuildContext context) {
          final bool animating = TickerMode.of(context);
          return TestState(
            log: log,
            child: Text('a $animating', textDirection: TextDirection.rtl),
          );
        },
      ),
    );

    final Matcher expectedSemanticsWhenPresent = hasSemantics(
      TestSemantics.root(
        children: <TestSemantics>[
          TestSemantics.rootChild(
            label: 'a true',
            textDirection: TextDirection.rtl,
            actions: <SemanticsAction>[SemanticsAction.tap],
          ),
        ],
      ),
      ignoreId: true,
      ignoreRect: true,
      ignoreTransform: true,
    );

    final Matcher expectedSemanticsWhenPresentWithIgnorePointer = hasSemantics(
      TestSemantics.root(
        children: <TestSemantics>[
          TestSemantics.rootChild(label: 'a true', textDirection: TextDirection.rtl),
        ],
      ),
      ignoreId: true,
      ignoreRect: true,
      ignoreTransform: true,
    );

    final Matcher expectedSemanticsWhenAbsent = hasSemantics(TestSemantics.root());

    // We now run a sequence of pumpWidget calls one after the other. In
    // addition to verifying that the right behavior is seen in each case, this
    // also verifies that the widget can dynamically change from state to state.

    await tester.pumpWidget(Visibility(child: testChild));
    expect(find.byType(Text, skipOffstage: false), findsOneWidget);
    expect(find.text('a true', skipOffstage: false), findsOneWidget);
    expect(find.byType(Visibility), paints..paragraph());
    expect(tester.getSize(find.byType(Visibility)), const Size(800.0, 600.0));
    expect(semantics, expectedSemanticsWhenPresent);
    expect(log, <String>['created new state']);
    await tester.tap(find.byType(Visibility));
    expect(log, <String>['created new state', 'tap']);
    log.clear();

    await tester.pumpWidget(Visibility(visible: false, child: testChild));
    expect(find.byType(Text, skipOffstage: false), findsNothing);
    expect(find.byType(Visibility), paintsNothing);
    expect(tester.getSize(find.byType(Visibility)), const Size(800.0, 600.0));
    expect(semantics, expectedSemanticsWhenAbsent);
    expect(log, <String>[]);
    await tester.tap(find.byType(Visibility), warnIfMissed: false);
    expect(log, <String>[]);
    log.clear();

    await tester.pumpWidget(Center(child: Visibility(visible: false, child: testChild)));
    expect(find.byType(Text, skipOffstage: false), findsNothing);
    expect(find.byType(Placeholder), findsNothing);
    expect(find.byType(Visibility), paintsNothing);
    expect(tester.getSize(find.byType(Visibility)), Size.zero);
    expect(semantics, expectedSemanticsWhenAbsent);
    expect(log, <String>[]);
    await tester.tap(find.byType(Visibility), warnIfMissed: false);
    expect(log, <String>[]);
    log.clear();

    await tester.pumpWidget(
      Center(
        child: Visibility(replacement: const Placeholder(), visible: false, child: testChild),
      ),
    );
    expect(find.byType(Text, skipOffstage: false), findsNothing);
    expect(find.byType(Placeholder), findsOneWidget);
    expect(find.byType(Visibility), paints..path());
    expect(tester.getSize(find.byType(Visibility)), const Size(800.0, 600.0));
    expect(semantics, expectedSemanticsWhenAbsent);
    expect(log, <String>[]);
    await tester.tap(find.byType(Visibility), warnIfMissed: false);
    expect(log, <String>[]);
    log.clear();

    await tester.pumpWidget(
      Center(
        child: Visibility(replacement: const Placeholder(), child: testChild),
      ),
    );
    expect(find.byType(Text, skipOffstage: false), findsOneWidget);
    expect(find.text('a true', skipOffstage: false), findsOneWidget);
    expect(find.byType(Placeholder), findsNothing);
    expect(find.byType(Visibility), paints..paragraph());
    expect(tester.getSize(find.byType(Visibility)), const Size(84.0, 14.0));
    expect(semantics, expectedSemanticsWhenPresent);
    expect(log, <String>['created new state']);
    await tester.tap(find.byType(Visibility));
    expect(log, <String>['created new state', 'tap']);
    log.clear();

    await tester.pumpWidget(
      Center(
        child: Visibility(
          maintainState: true,
          maintainAnimation: true,
          maintainSize: true,
          maintainInteractivity: true,
          maintainSemantics: true,
          child: testChild,
        ),
      ),
    );
    expect(find.byType(Text, skipOffstage: false), findsOneWidget);
    expect(find.text('a true', skipOffstage: false), findsOneWidget);
    expect(find.byType(Placeholder), findsNothing);
    expect(find.byType(Visibility), paints..paragraph());
    expect(tester.getSize(find.byType(Visibility)), const Size(84.0, 14.0));
    expect(semantics, expectedSemanticsWhenPresent);
    expect(log, <String>['created new state']);
    await tester.tap(find.byType(Visibility));
    expect(log, <String>['created new state', 'tap']);
    log.clear();

    await tester.pumpWidget(
      Center(
        child: Visibility(
          visible: false,
          maintainState: true,
          maintainAnimation: true,
          maintainSize: true,
          maintainInteractivity: true,
          maintainSemantics: true,
          child: testChild,
        ),
      ),
    );
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

    await tester.pumpWidget(
      Center(
        child: Visibility(
          visible: false,
          maintainState: true,
          maintainAnimation: true,
          maintainSize: true,
          maintainInteractivity: true,
          child: testChild,
        ),
      ),
    );
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

    await tester.pumpWidget(
      Center(
        child: Visibility(
          visible: false,
          maintainState: true,
          maintainAnimation: true,
          maintainSize: true,
          maintainSemantics: true,
          child: testChild,
        ),
      ),
    );
    expect(find.byType(Text, skipOffstage: false), findsOneWidget);
    expect(find.text('a true', skipOffstage: false), findsOneWidget);
    expect(find.byType(Placeholder), findsNothing);
    expect(find.byType(Visibility), paintsNothing);
    expect(tester.getSize(find.byType(Visibility)), const Size(84.0, 14.0));
    expect(semantics, expectedSemanticsWhenPresentWithIgnorePointer);
    expect(log, <String>[]);
    await tester.tap(find.byType(Visibility), warnIfMissed: false);
    expect(log, <String>[]);
    log.clear();

    await tester.pumpWidget(
      Center(
        child: Visibility(
          visible: false,
          maintainState: true,
          maintainAnimation: true,
          maintainSize: true,
          child: testChild,
        ),
      ),
    );
    expect(find.byType(Text, skipOffstage: false), findsOneWidget);
    expect(find.text('a true', skipOffstage: false), findsOneWidget);
    expect(find.byType(Placeholder), findsNothing);
    expect(find.byType(Visibility), paintsNothing);
    expect(tester.getSize(find.byType(Visibility)), const Size(84.0, 14.0));
    expect(semantics, expectedSemanticsWhenAbsent);
    expect(log, <String>[]);
    await tester.tap(find.byType(Visibility), warnIfMissed: false);
    expect(log, <String>[]);
    log.clear();

    await tester.pumpWidget(
      Center(
        child: Visibility(
          visible: false,
          maintainState: true,
          maintainAnimation: true,
          child: testChild,
        ),
      ),
    );
    expect(find.byType(Text, skipOffstage: false), findsOneWidget);
    expect(find.byType(Text), findsNothing);
    expect(find.text('a true', skipOffstage: false), findsOneWidget);
    expect(find.byType(Placeholder), findsNothing);
    expect(find.byType(Visibility), paintsNothing);
    expect(tester.getSize(find.byType(Visibility)), Size.zero);
    expect(semantics, expectedSemanticsWhenAbsent);
    expect(log, <String>['created new state']);
    await tester.tap(find.byType(Visibility), warnIfMissed: false);
    expect(log, <String>['created new state']);
    log.clear();

    await tester.pumpWidget(
      Center(child: Visibility(visible: false, maintainState: true, child: testChild)),
    );
    expect(find.byType(Text, skipOffstage: false), findsOneWidget);
    expect(find.byType(Text), findsNothing);
    expect(find.text('a false', skipOffstage: false), findsOneWidget);
    expect(find.byType(Placeholder), findsNothing);
    expect(find.byType(Visibility), paintsNothing);
    expect(tester.getSize(find.byType(Visibility)), Size.zero);
    expect(semantics, expectedSemanticsWhenAbsent);
    expect(log, <String>['created new state']);
    await tester.tap(find.byType(Visibility), warnIfMissed: false);
    expect(log, <String>['created new state']);
    log.clear();

    // Now we toggle the visibility off and on a few times to make sure that works.

    await tester.pumpWidget(Center(child: Visibility(maintainState: true, child: testChild)));
    expect(find.byType(Text), findsOneWidget);
    expect(find.text('a true', skipOffstage: false), findsOneWidget);
    expect(find.byType(Placeholder), findsNothing);
    expect(find.byType(Visibility), paints..paragraph());
    expect(tester.getSize(find.byType(Visibility)), const Size(84.0, 14.0));
    expect(semantics, expectedSemanticsWhenPresent);
    expect(log, <String>[]);
    await tester.tap(find.byType(Visibility), warnIfMissed: false);
    expect(log, <String>['tap']);
    log.clear();

    await tester.pumpWidget(
      Center(child: Visibility(visible: false, maintainState: true, child: testChild)),
    );
    expect(find.byType(Text, skipOffstage: false), findsOneWidget);
    expect(find.byType(Text), findsNothing);
    expect(find.text('a false', skipOffstage: false), findsOneWidget);
    expect(find.byType(Placeholder), findsNothing);
    expect(find.byType(Visibility), paintsNothing);
    expect(tester.getSize(find.byType(Visibility)), Size.zero);
    expect(semantics, expectedSemanticsWhenAbsent);
    expect(log, <String>[]);
    await tester.tap(find.byType(Visibility), warnIfMissed: false);
    expect(log, <String>[]);
    log.clear();

    await tester.pumpWidget(Center(child: Visibility(maintainState: true, child: testChild)));
    expect(find.byType(Text), findsOneWidget);
    expect(find.text('a true', skipOffstage: false), findsOneWidget);
    expect(find.byType(Placeholder), findsNothing);
    expect(find.byType(Visibility), paints..paragraph());
    expect(tester.getSize(find.byType(Visibility)), const Size(84.0, 14.0));
    expect(semantics, expectedSemanticsWhenPresent);
    expect(log, <String>[]);
    await tester.tap(find.byType(Visibility));
    expect(log, <String>['tap']);
    log.clear();

    await tester.pumpWidget(
      Center(child: Visibility(visible: false, maintainState: true, child: testChild)),
    );
    expect(find.byType(Text, skipOffstage: false), findsOneWidget);
    expect(find.byType(Text), findsNothing);
    expect(find.text('a false', skipOffstage: false), findsOneWidget);
    expect(find.byType(Placeholder), findsNothing);
    expect(find.byType(Visibility), paintsNothing);
    expect(tester.getSize(find.byType(Visibility)), Size.zero);
    expect(semantics, expectedSemanticsWhenAbsent);
    expect(log, <String>[]);
    await tester.tap(find.byType(Visibility), warnIfMissed: false);
    expect(log, <String>[]);
    log.clear();

    // Same but without maintainState.

    await tester.pumpWidget(Center(child: Visibility(visible: false, child: testChild)));
    expect(find.byType(Text, skipOffstage: false), findsNothing);
    expect(find.byType(Placeholder), findsNothing);
    expect(find.byType(Visibility), paintsNothing);
    expect(tester.getSize(find.byType(Visibility)), Size.zero);
    expect(semantics, expectedSemanticsWhenAbsent);
    expect(log, <String>[]);
    await tester.tap(find.byType(Visibility), warnIfMissed: false);
    expect(log, <String>[]);
    log.clear();

    await tester.pumpWidget(Center(child: Visibility(child: testChild)));
    expect(find.byType(Text), findsOneWidget);
    expect(find.text('a true', skipOffstage: false), findsOneWidget);
    expect(find.byType(Placeholder), findsNothing);
    expect(find.byType(Visibility), paints..paragraph());
    expect(tester.getSize(find.byType(Visibility)), const Size(84.0, 14.0));
    expect(semantics, expectedSemanticsWhenPresent);
    expect(log, <String>['created new state']);
    await tester.tap(find.byType(Visibility));
    expect(log, <String>['created new state', 'tap']);
    log.clear();

    await tester.pumpWidget(Center(child: Visibility(visible: false, child: testChild)));
    expect(find.byType(Text, skipOffstage: false), findsNothing);
    expect(find.byType(Placeholder), findsNothing);
    expect(find.byType(Visibility), paintsNothing);
    expect(tester.getSize(find.byType(Visibility)), Size.zero);
    expect(semantics, expectedSemanticsWhenAbsent);
    expect(log, <String>[]);
    await tester.tap(find.byType(Visibility), warnIfMissed: false);
    expect(log, <String>[]);
    log.clear();

    await tester.pumpWidget(Center(child: Visibility(child: testChild)));
    expect(find.byType(Text), findsOneWidget);
    expect(find.text('a true', skipOffstage: false), findsOneWidget);
    expect(find.byType(Placeholder), findsNothing);
    expect(find.byType(Visibility), paints..paragraph());
    expect(tester.getSize(find.byType(Visibility)), const Size(84.0, 14.0));
    expect(semantics, expectedSemanticsWhenPresent);
    expect(log, <String>['created new state']);
    await tester.tap(find.byType(Visibility));
    expect(log, <String>['created new state', 'tap']);
    log.clear();

    semantics.dispose();
  });

  testWidgets('Visibility with maintain* false excludes focus of child when not visible', (
    WidgetTester tester,
  ) async {
    Future<void> pumpVisibility(bool visible) async {
      await tester.pumpWidget(
        Visibility(
          visible: visible,
          child: const Focus(child: Text('child', textDirection: TextDirection.ltr)),
        ),
      );
    }

    await pumpVisibility(true);

    final Element child = tester.element(find.text('child', skipOffstage: false));
    final FocusNode childFocusNode = Focus.of(child);

    childFocusNode.requestFocus();
    await tester.pump();

    expect(childFocusNode.hasFocus, true);

    await pumpVisibility(false);
    childFocusNode.requestFocus();

    expect(childFocusNode.hasFocus, false);
  });

  testWidgets('Visibility with maintain* true does not exclude focus of child when not visible', (
    WidgetTester tester,
  ) async {
    Future<void> pumpVisibility(bool visible) async {
      await tester.pumpWidget(
        Visibility.maintain(
          visible: visible,
          child: const Focus(child: Text('child', textDirection: TextDirection.ltr)),
        ),
      );
    }

    await pumpVisibility(true);

    final Element child = tester.element(find.text('child', skipOffstage: false));
    final FocusNode childFocusNode = Focus.of(child);

    childFocusNode.requestFocus();
    await tester.pump();

    expect(childFocusNode.hasFocus, true);

    await pumpVisibility(false);

    expect(childFocusNode.hasFocus, true);
  });

  testWidgets(
    'Visibility with maintain* true except maintainFocusability which is false excludes focus of child when not visible',
    (WidgetTester tester) async {
      Future<void> pumpVisibility(bool visible) async {
        await tester.pumpWidget(
          Visibility(
            visible: visible,
            maintainState: true,
            maintainAnimation: true,
            maintainInteractivity: true,
            maintainSemantics: true,
            maintainSize: true,
            child: const Focus(child: Text('child', textDirection: TextDirection.ltr)),
          ),
        );
      }

      await pumpVisibility(true);

      final Element child = tester.element(find.text('child', skipOffstage: false));
      final FocusNode childFocusNode = Focus.of(child);

      childFocusNode.requestFocus();
      await tester.pump();

      expect(childFocusNode.hasFocus, true);

      await pumpVisibility(false);
      childFocusNode.requestFocus();

      expect(childFocusNode.hasFocus, false);
    },
  );

  testWidgets(
    'Visibility throws assertion error if maintainFocusability is true without maintainState',
    (WidgetTester tester) async {
      expect(() {
        Visibility(
          maintainFocusability: true,
          child: const Text('hello', textDirection: TextDirection.ltr),
        );
      }, throwsAssertionError);
    },
  );

  testWidgets('Visibility does not force compositing when visible and maintain*', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const Visibility(
        maintainSize: true,
        maintainAnimation: true,
        maintainState: true,
        child: Text('hello', textDirection: TextDirection.ltr),
      ),
    );

    // Root transform from the tester and then the picture created by the text.
    expect(tester.layers, hasLength(2));
    expect(tester.layers, isNot(contains(isA<OpacityLayer>())));
    expect(tester.layers.last, isA<PictureLayer>());
  });

  testWidgets('SliverVisibility does not force compositing when visible and maintain*', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: CustomScrollView(
          slivers: <Widget>[
            SliverVisibility(
              maintainSize: true,
              maintainAnimation: true,
              maintainState: true,
              sliver: SliverList(
                delegate: SliverChildListDelegate.fixed(addRepaintBoundaries: false, <Widget>[
                  Text('hello'),
                ]),
              ),
            ),
          ],
        ),
      ),
    );

    // This requires a lot more layers due to including sliver lists which do manage additional
    // offset layers. Just trust me this is one fewer layers than before...
    expect(tester.layers, hasLength(6));
    expect(tester.layers, isNot(contains(isA<OpacityLayer>())));
    expect(tester.layers.last, isA<PictureLayer>());
  });

  testWidgets('Visibility.of returns correct value', (WidgetTester tester) async {
    await tester.pumpWidget(
      const Directionality(textDirection: TextDirection.ltr, child: _ShowVisibility()),
    );
    expect(find.text('is visible ? true', skipOffstage: false), findsOneWidget);

    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Visibility(maintainState: true, child: _ShowVisibility()),
      ),
    );
    expect(find.text('is visible ? true', skipOffstage: false), findsOneWidget);

    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Visibility(visible: false, maintainState: true, child: _ShowVisibility()),
      ),
    );
    expect(find.text('is visible ? false', skipOffstage: false), findsOneWidget);
  });

  testWidgets('Visibility.of works when multiple Visibility widgets are in hierarchy', (
    WidgetTester tester,
  ) async {
    var didChangeDependencies = false;
    void handleDidChangeDependencies() {
      didChangeDependencies = true;
    }

    Widget newWidget({required bool ancestorIsVisible, required bool descendantIsVisible}) {
      return Directionality(
        textDirection: TextDirection.ltr,
        child: Visibility(
          visible: ancestorIsVisible,
          maintainState: true,
          child: Center(
            child: Visibility(
              visible: descendantIsVisible,
              maintainState: true,
              child: _ShowVisibility(onDidChangeDependencies: handleDidChangeDependencies),
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(newWidget(ancestorIsVisible: true, descendantIsVisible: true));
    expect(didChangeDependencies, isTrue);
    expect(find.text('is visible ? true', skipOffstage: false), findsOneWidget);
    didChangeDependencies = false;

    await tester.pumpWidget(newWidget(ancestorIsVisible: true, descendantIsVisible: false));
    expect(didChangeDependencies, isTrue);
    expect(find.text('is visible ? false', skipOffstage: false), findsOneWidget);
    didChangeDependencies = false;

    await tester.pumpWidget(newWidget(ancestorIsVisible: true, descendantIsVisible: false));
    expect(didChangeDependencies, isFalse);

    await tester.pumpWidget(newWidget(ancestorIsVisible: false, descendantIsVisible: false));
    expect(didChangeDependencies, isTrue);
    didChangeDependencies = false;

    await tester.pumpWidget(newWidget(ancestorIsVisible: false, descendantIsVisible: true));
    expect(didChangeDependencies, isTrue);
    expect(find.text('is visible ? false', skipOffstage: false), findsOneWidget);
  });

  testWidgets('Visibility does not crash at zero area', (WidgetTester tester) async {
    tester.view.physicalSize = Size.zero;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      const TestWidgetsApp(
        home: Center(child: Visibility(child: Placeholder())),
      ),
    );
    expect(tester.getSize(find.byType(Visibility)), Size.zero);
  });

  group('Visibility.excludeFromSpacing', () {
    Widget buildColumn({
      required bool visible,
      bool excludeFromSpacing = true,
      bool maintainState = false,
      List<String>? log,
    }) {
      Widget hidden = const SizedBox(key: Key('hidden'), height: 20.0);
      if (log != null) {
        hidden = TestState(log: log, child: hidden);
      }
      return Directionality(
        textDirection: TextDirection.ltr,
        child: Align(
          alignment: Alignment.topLeft,
          child: Column(
            spacing: 10.0,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const SizedBox(height: 20.0),
              Visibility(
                visible: visible,
                maintainState: maintainState,
                excludeFromSpacing: excludeFromSpacing,
                child: hidden,
              ),
              const SizedBox(key: Key('last'), height: 20.0),
            ],
          ),
        ),
      );
    }

    double lastTop(WidgetTester tester) => tester.getTopLeft(find.byKey(const Key('last'))).dy;

    testWidgets('hidden Visibility receives spacing by default', (WidgetTester tester) async {
      await tester.pumpWidget(buildColumn(visible: false, excludeFromSpacing: false));
      expect(lastTop(tester), 40.0);
      expect(tester.getSize(find.byType(Column)).height, 60.0);
    });

    testWidgets('hidden Visibility receives no spacing', (WidgetTester tester) async {
      await tester.pumpWidget(buildColumn(visible: false));
      expect(lastTop(tester), 30.0);
      expect(tester.getSize(find.byType(Column)).height, 50.0);
    });

    testWidgets('visible Visibility still receives spacing', (WidgetTester tester) async {
      await tester.pumpWidget(buildColumn(visible: true));
      expect(tester.getTopLeft(find.byKey(const Key('hidden'))).dy, 30.0);
      expect(lastTop(tester), 60.0);
      expect(tester.getSize(find.byType(Column)).height, 80.0);
    });

    testWidgets('works with maintainState and keeps the state when toggled', (
      WidgetTester tester,
    ) async {
      final log = <String>[];
      await tester.pumpWidget(buildColumn(visible: true, maintainState: true, log: log));
      expect(log, <String>['created new state']);
      expect(lastTop(tester), 60.0);

      await tester.pumpWidget(buildColumn(visible: false, maintainState: true, log: log));
      expect(lastTop(tester), 30.0);

      await tester.pumpWidget(buildColumn(visible: true, maintainState: true, log: log));
      expect(lastTop(tester), 60.0);
      expect(log, <String>['created new state']);
    });

    testWidgets('works inside Expanded', (WidgetTester tester) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              height: 100.0,
              child: Column(
                spacing: 10.0,
                children: <Widget>[
                  SizedBox(height: 20.0),
                  Expanded(
                    child: Visibility(
                      visible: false,
                      excludeFromSpacing: true,
                      child: SizedBox(height: 20.0),
                    ),
                  ),
                  SizedBox(key: Key('last'), height: 20.0),
                ],
              ),
            ),
          ),
        ),
      );
      // The hidden child takes the remaining space, with no spacing around it.
      expect(lastTop(tester), 80.0);
    });

    test('cannot be combined with maintainSize', () {
      expect(
        () => Visibility(
          maintainState: true,
          maintainAnimation: true,
          maintainSize: true,
          excludeFromSpacing: true,
          child: const SizedBox(),
        ),
        throwsAssertionError,
      );
    });

    testWidgets('debugFillProperties', (WidgetTester tester) async {
      final builder = DiagnosticPropertiesBuilder();
      const Visibility(excludeFromSpacing: true, child: SizedBox()).debugFillProperties(builder);
      final List<String> description = builder.properties
          .where((DiagnosticsNode node) => !node.isFiltered(DiagnosticLevel.info))
          .map((DiagnosticsNode node) => node.toString())
          .toList();
      expect(description, contains('excludeFromSpacing'));
    });
  });

  testWidgets('ExcludeFromSpacing updates its render object', (WidgetTester tester) async {
    Widget build({required bool excluding}) {
      return Directionality(
        textDirection: TextDirection.ltr,
        child: Align(
          alignment: Alignment.topLeft,
          child: Row(
            spacing: 10.0,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const SizedBox(width: 20.0),
              ExcludeFromSpacing(excluding: excluding, child: const SizedBox(width: 20.0)),
              const SizedBox(key: Key('last'), width: 20.0),
            ],
          ),
        ),
      );
    }

    await tester.pumpWidget(build(excluding: true));
    final RenderExcludeFromSpacing renderObject = tester.renderObject(
      find.byType(ExcludeFromSpacing),
    );
    expect(renderObject.excluding, isTrue);
    expect(tester.getTopLeft(find.byKey(const Key('last'))).dx, 50.0);

    await tester.pumpWidget(build(excluding: false));
    expect(renderObject.excluding, isFalse);
    expect(tester.getTopLeft(find.byKey(const Key('last'))).dx, 60.0);
  });
}

class _ShowVisibility extends StatefulWidget {
  const _ShowVisibility({this.onDidChangeDependencies});

  final VoidCallback? onDidChangeDependencies;

  @override
  State<_ShowVisibility> createState() => _ShowVisibilityState();
}

class _ShowVisibilityState extends State<_ShowVisibility> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.onDidChangeDependencies != null) {
      widget.onDidChangeDependencies!();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Text('is visible ? ${Visibility.of(context)}');
  }
}
