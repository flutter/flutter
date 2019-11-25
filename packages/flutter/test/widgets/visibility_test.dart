// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../rendering/mock_canvas.dart';
import 'semantics_tester.dart';

class TestState extends StatefulWidget {
  const TestState({ Key key, this.child, this.log }) : super(key: key);
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
    final SemanticsTester semantics = SemanticsTester(tester);
    final List<String> log = <String>[];

    final Widget testChild = GestureDetector(
      onTap: () { log.add('tap'); },
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

    await tester.pumpWidget(Visibility(child: testChild, visible: false));
    expect(find.byType(Text, skipOffstage: false), findsNothing);
    expect(find.byType(Visibility), paintsNothing);
    expect(tester.getSize(find.byType(Visibility)), const Size(800.0, 600.0));
    expect(semantics, expectedSemanticsWhenAbsent);
    expect(log, <String>[]);
    await tester.tap(find.byType(Visibility));
    expect(log, <String>[]);
    log.clear();

    await tester.pumpWidget(Center(
      child: Visibility(
        child: testChild,
        visible: false,
      )
    ));
    expect(find.byType(Text, skipOffstage: false), findsNothing);
    expect(find.byType(Placeholder), findsNothing);
    expect(find.byType(Visibility), paintsNothing);
    expect(tester.getSize(find.byType(Visibility)), Size.zero);
    expect(semantics, expectedSemanticsWhenAbsent);
    expect(log, <String>[]);
    await tester.tap(find.byType(Visibility));
    expect(log, <String>[]);
    log.clear();

    await tester.pumpWidget(Center(
      child: Visibility(
        child: testChild,
        replacement: const Placeholder(),
        visible: false,
      )
    ));
    expect(find.byType(Text, skipOffstage: false), findsNothing);
    expect(find.byType(Placeholder), findsOneWidget);
    expect(find.byType(Visibility), paints..path());
    expect(tester.getSize(find.byType(Visibility)), const Size(800.0, 600.0));
    expect(semantics, expectedSemanticsWhenAbsent);
    expect(log, <String>[]);
    await tester.tap(find.byType(Visibility));
    expect(log, <String>[]);
    log.clear();

    await tester.pumpWidget(Center(
      child: Visibility(
        child: testChild,
        replacement: const Placeholder(),
        visible: true,
      )
    ));
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

    await tester.pumpWidget(Center(
      child: Visibility(
        child: testChild,
        visible: true,
        maintainState: true,
        maintainAnimation: true,
        maintainSize: true,
        maintainInteractivity: true,
        maintainSemantics: true,
      )
    ));
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

    await tester.pumpWidget(Center(
      child: Visibility(
        child: testChild,
        visible: false,
        maintainState: true,
        maintainAnimation: true,
        maintainSize: true,
        maintainInteractivity: true,
        maintainSemantics: true,
      )
    ));
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

    await tester.pumpWidget(Center(
      child: Visibility(
        child: testChild,
        visible: false,
        maintainState: true,
        maintainAnimation: true,
        maintainSize: true,
        maintainInteractivity: true,
      )
    ));
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

    await tester.pumpWidget(Center(
      child: Visibility(
        child: testChild,
        visible: false,
        maintainState: true,
        maintainAnimation: true,
        maintainSize: true,
        maintainSemantics: true,
      )
    ));
    expect(find.byType(Text, skipOffstage: false), findsOneWidget);
    expect(find.text('a true', skipOffstage: false), findsOneWidget);
    expect(find.byType(Placeholder), findsNothing);
    expect(find.byType(Visibility), paintsNothing);
    expect(tester.getSize(find.byType(Visibility)), const Size(84.0, 14.0));
    expect(semantics, expectedSemanticsWhenPresent);
    expect(log, <String>['created new state']);
    await tester.tap(find.byType(Visibility));
    expect(log, <String>['created new state']);
    log.clear();

    await tester.pumpWidget(Center(
      child: Visibility(
        child: testChild,
        visible: false,
        maintainState: true,
        maintainAnimation: true,
        maintainSize: true,
      )
    ));
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

    await tester.pumpWidget(Center(
      child: Visibility(
        child: testChild,
        visible: false,
        maintainState: true,
        maintainAnimation: true,
      )
    ));
    expect(find.byType(Text, skipOffstage: false), findsOneWidget);
    expect(find.byType(Text, skipOffstage: true), findsNothing);
    expect(find.text('a true', skipOffstage: false), findsOneWidget);
    expect(find.byType(Placeholder), findsNothing);
    expect(find.byType(Visibility), paintsNothing);
    expect(tester.getSize(find.byType(Visibility)), Size.zero);
    expect(semantics, expectedSemanticsWhenAbsent);
    expect(log, <String>['created new state']);
    await tester.tap(find.byType(Visibility));
    expect(log, <String>['created new state']);
    log.clear();

    await tester.pumpWidget(Center(
      child: Visibility(
        child: testChild,
        visible: false,
        maintainState: true,
      )
    ));
    expect(find.byType(Text, skipOffstage: false), findsOneWidget);
    expect(find.byType(Text, skipOffstage: true), findsNothing);
    expect(find.text('a false', skipOffstage: false), findsOneWidget);
    expect(find.byType(Placeholder), findsNothing);
    expect(find.byType(Visibility), paintsNothing);
    expect(tester.getSize(find.byType(Visibility)), Size.zero);
    expect(semantics, expectedSemanticsWhenAbsent);
    expect(log, <String>['created new state']);
    await tester.tap(find.byType(Visibility));
    expect(log, <String>['created new state']);
    log.clear();

    // Now we toggle the visibility off and on a few times to make sure that works.

    await tester.pumpWidget(Center(
      child: Visibility(
        child: testChild,
        visible: true,
        maintainState: true,
      )
    ));
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

    await tester.pumpWidget(Center(
      child: Visibility(
        child: testChild,
        visible: false,
        maintainState: true,
      )
    ));
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

    await tester.pumpWidget(Center(
      child: Visibility(
        child: testChild,
        visible: true,
        maintainState: true,
      )
    ));
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

    await tester.pumpWidget(Center(
      child: Visibility(
        child: testChild,
        visible: false,
        maintainState: true,
      )
    ));
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

    // Same but without maintainState.

    await tester.pumpWidget(Center(
      child: Visibility(
        child: testChild,
        visible: false,
      )
    ));
    expect(find.byType(Text, skipOffstage: false), findsNothing);
    expect(find.byType(Placeholder), findsNothing);
    expect(find.byType(Visibility), paintsNothing);
    expect(tester.getSize(find.byType(Visibility)), Size.zero);
    expect(semantics, expectedSemanticsWhenAbsent);
    expect(log, <String>[]);
    await tester.tap(find.byType(Visibility));
    expect(log, <String>[]);
    log.clear();

    await tester.pumpWidget(Center(
      child: Visibility(
        child: testChild,
        visible: true,
      )
    ));
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

    await tester.pumpWidget(Center(
      child: Visibility(
        child: testChild,
        visible: false,
      )
    ));
    expect(find.byType(Text, skipOffstage: false), findsNothing);
    expect(find.byType(Placeholder), findsNothing);
    expect(find.byType(Visibility), paintsNothing);
    expect(tester.getSize(find.byType(Visibility)), Size.zero);
    expect(semantics, expectedSemanticsWhenAbsent);
    expect(log, <String>[]);
    await tester.tap(find.byType(Visibility));
    expect(log, <String>[]);
    log.clear();

    await tester.pumpWidget(Center(
      child: Visibility(
        child: testChild,
        visible: true,
      )
    ));
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
  }, skip: isBrowser);

  testWidgets('SliverVisibility', (WidgetTester tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);
    final List<String> log = <String>[];
    const Key anchor = Key('drag');

    Widget _boilerPlate(Widget sliver) {
      return Localizations(
        locale: const Locale('en', 'us'),
        delegates: const <LocalizationsDelegate<dynamic>>[
          DefaultWidgetsLocalizations.delegate,
          DefaultMaterialLocalizations.delegate,
        ],
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: MediaQuery(
            data: const MediaQueryData(),
            child: CustomScrollView(slivers: <Widget>[sliver])
          )
        )
      );
    }

    final Widget testChild = SliverToBoxAdapter(
      child: GestureDetector(
        onTap: () { log.add('tap'); },
        child: Builder(
          builder: (BuildContext context) {
            final bool animating = TickerMode.of(context);
            return TestState(
              key: anchor,
              log: log,
              child: Text('a $animating', textDirection: TextDirection.rtl),
            );
          },
        ),
      )
    );

    // We now run a sequence of pumpWidget calls one after the other. In
    // addition to verifying that the right behavior is seen in each case, this
    // also verifies that the widget can dynamically change from state to state.

    // Default
    await tester.pumpWidget(_boilerPlate(SliverVisibility(sliver: testChild)));
    expect(find.byType(Text, skipOffstage: false), findsOneWidget);
    expect(find.text('a true', skipOffstage: false), findsOneWidget);
    expect(find.byType(SliverVisibility), findsOneWidget);
    expect(find.byType(SliverVisibility), paints..paragraph());
    RenderViewport renderViewport = tester.renderObject(find.byType(Viewport));
    RenderSliver renderSliver = renderViewport.lastChild;
    expect(renderSliver.geometry.scrollExtent, 14.0);
    expect(renderSliver.constraints.crossAxisExtent, 800.0);
    expect(semantics.nodesWith(label: 'a true'), hasLength(1));
    expect(log, <String>['created new state']);
    await tester.tap(find.byKey(anchor));
    expect(log, <String>['created new state', 'tap']);
    log.clear();

    // visible: false
    await tester.pumpWidget(_boilerPlate(SliverVisibility(
      sliver: testChild,
      visible: false,
    )));
    expect(find.byType(Text), findsNothing);
    expect(find.byType(Text, skipOffstage: false), findsNothing);
    expect(find.byType(SliverVisibility, skipOffstage: false), findsOneWidget);
    expect(find.byType(SliverVisibility, skipOffstage: false), paintsNothing);
    renderViewport = tester.renderObject(find.byType(Viewport));
    renderSliver = renderViewport.lastChild;
    expect(renderSliver.geometry.scrollExtent, 0.0);
    expect(semantics.nodesWith(label: 'a true'), hasLength(0));
    expect(log, <String>[]);
    expect(find.byKey(anchor), findsNothing);
    log.clear();

    // visible: false, with replacementSliver
    await tester.pumpWidget(_boilerPlate(SliverVisibility(
      sliver: testChild,
      replacementSliver: const SliverToBoxAdapter(child: Placeholder()),
      visible: false,
    )));
    expect(find.byType(Text, skipOffstage: false), findsNothing);
    expect(find.byType(Placeholder), findsOneWidget);
    expect(find.byType(SliverVisibility), findsOneWidget);
    expect(find.byType(SliverVisibility), paints..path());
    renderViewport = tester.renderObject(find.byType(Viewport));
    renderSliver = renderViewport.lastChild;
    expect(renderSliver.geometry.scrollExtent, 400.0);
    expect(semantics.nodesWith(label: 'a true'), hasLength(0));
    expect(log, <String>[]);
    expect(find.byKey(anchor), findsNothing);
    log.clear();

    // visible: true, with replacementSliver
    await tester.pumpWidget(_boilerPlate(SliverVisibility(
      sliver: testChild,
      replacementSliver: const SliverToBoxAdapter(child: Placeholder()),
      visible: true,
    )));
    expect(find.byType(Text, skipOffstage: false), findsOneWidget);
    expect(find.text('a true', skipOffstage: false), findsOneWidget);
    expect(find.byType(Placeholder), findsNothing);
    expect(find.byType(SliverVisibility), findsOneWidget);
    expect(find.byType(SliverVisibility), paints..paragraph());
    renderViewport = tester.renderObject(find.byType(Viewport));
    renderSliver = renderViewport.lastChild;
    expect(renderSliver.geometry.scrollExtent, 14.0);
    expect(semantics.nodesWith(label: 'a true'), hasLength(1));
    expect(log, <String>['created new state']);
    await tester.tap(find.byKey(anchor));
    expect(log, <String>['created new state', 'tap']);
    log.clear();

    // visible: true, maintain all
    await tester.pumpWidget(_boilerPlate(SliverVisibility(
      sliver: testChild,
      visible: true,
      maintainState: true,
      maintainAnimation: true,
      maintainSize: true,
      maintainInteractivity: true,
      maintainSemantics: true,
    )));
    expect(find.byType(Text, skipOffstage: false), findsOneWidget);
    expect(find.text('a true', skipOffstage: false), findsOneWidget);
    expect(find.byType(SliverVisibility), findsOneWidget);
    expect(find.byType(SliverVisibility), paints..paragraph());
    renderViewport = tester.renderObject(find.byType(Viewport));
    renderSliver = renderViewport.lastChild;
    expect(renderSliver.geometry.scrollExtent, 14.0);
    expect(semantics.nodesWith(label: 'a true'), hasLength(1));
    expect(log, <String>['created new state']);
    await tester.tap(find.byKey(anchor));
    expect(log, <String>['created new state', 'tap']);
    log.clear();

    // visible: false, maintain all
    await tester.pumpWidget(_boilerPlate(SliverVisibility(
      sliver: testChild,
      visible: false,
      maintainState: true,
      maintainAnimation: true,
      maintainSize: true,
      maintainInteractivity: true,
      maintainSemantics: true,
    )));
    expect(find.byType(Text, skipOffstage: false), findsOneWidget);
    expect(find.text('a true', skipOffstage: false), findsOneWidget);
    expect(find.byType(SliverVisibility), findsOneWidget);
    expect(find.byType(SliverVisibility), paintsNothing);
    renderViewport = tester.renderObject(find.byType(Viewport));
    renderSliver = renderViewport.lastChild;
    expect(renderSliver.geometry.scrollExtent, 14.0);
    expect(semantics.nodesWith(label: 'a true'), hasLength(1));
    expect(log, <String>[]);
    await tester.tap(find.byKey(anchor));
    expect(log, <String>['tap']);
    log.clear();

    // visible: false, maintain all, replacementSliver
    await tester.pumpWidget(_boilerPlate(SliverVisibility(
      sliver: testChild,
      replacementSliver: const SliverToBoxAdapter(child: Placeholder()),
      visible: false,
      maintainState: true,
      maintainAnimation: true,
      maintainSize: true,
      maintainInteractivity: true,
      maintainSemantics: true,
    )));
    expect(find.byType(Text, skipOffstage: false), findsOneWidget);
    expect(find.text('a true', skipOffstage: false), findsOneWidget);
    expect(find.byType(Placeholder), findsOneWidget);
    expect(find.byType(SliverVisibility), findsOneWidget);
    expect(find.byType(SliverVisibility), paintsNothing);
    renderViewport = tester.renderObject(find.byType(Viewport));
    renderSliver = renderViewport.lastChild;
    expect(renderSliver.geometry.scrollExtent, 14.0);
    expect(renderSliver.constraints.crossAxisExtent, 800.0);
    expect(semantics.nodesWith(label: 'a true'), hasLength(1));
    expect(log, <String>[]);
    await tester.tap(find.byKey(anchor));
    expect(log, <String>['tap']);
    log.clear();

    // visible: false, maintain all but size, replacementSliver
    await tester.pumpWidget(_boilerPlate(SliverVisibility(
      sliver: testChild,
      replacementSliver: const SliverToBoxAdapter(child: Placeholder()),
      visible: false,
      maintainState: true,
      maintainAnimation: true,
      maintainSize: true,
      maintainInteractivity: true,
      maintainSemantics: true,
    )));
    expect(find.byType(Text, skipOffstage: false), findsNothing);
    expect(find.text('a true', skipOffstage: false), findsNothing);
    expect(find.byType(Placeholder), findsOneWidget);
    expect(find.byType(SliverVisibility), findsOneWidget);
    expect(find.byType(SliverVisibility), paintsNothing);
    renderViewport = tester.renderObject(find.byType(Viewport));
    renderSliver = renderViewport.lastChild;
    expect(renderSliver.geometry.scrollExtent, 400.0);
    expect(renderSliver.constraints.crossAxisExtent, 800.0);
    expect(semantics.nodesWith(label: 'a true'), hasLength(1));
    expect(log, <String>[]);
    await tester.tap(find.byKey(anchor));
    expect(log, <String>['tap']);
    log.clear();

    // visible: false, maintain all but semantics
    await tester.pumpWidget(_boilerPlate(SliverVisibility(
      sliver: testChild,
      visible: false,
      maintainState: true,
      maintainAnimation: true,
      maintainSize: true,
      maintainInteractivity: true,
    )));
    expect(find.byType(Text, skipOffstage: false), findsOneWidget);
    expect(find.text('a true', skipOffstage: false), findsOneWidget);
    expect(find.byType(SliverVisibility), findsOneWidget);
    expect(find.byType(SliverVisibility), paintsNothing);
    renderViewport = tester.renderObject(find.byType(Viewport));
    renderSliver = renderViewport.lastChild;
    expect(renderSliver.geometry.scrollExtent, 14.0);
    expect(renderSliver.constraints.crossAxisExtent, 800.0);
    expect(semantics.nodesWith(label: 'a true'), hasLength(0));
    expect(log, <String>[]);
    await tester.tap(find.byKey(anchor));
    expect(log, <String>['tap']);
    log.clear();

    // visible: false, maintain all but interactivity
    await tester.pumpWidget(_boilerPlate(SliverVisibility(
      sliver: testChild,
      visible: false,
      maintainState: true,
      maintainAnimation: true,
      maintainSize: true,
      maintainSemantics: true,
    )));
    expect(find.byType(Text, skipOffstage: false), findsOneWidget);
    expect(find.text('a true', skipOffstage: false), findsOneWidget);
    expect(find.byType(SliverVisibility), findsOneWidget);
    expect(find.byType(SliverVisibility), paintsNothing);
    renderViewport = tester.renderObject(find.byType(Viewport));
    renderSliver = renderViewport.lastChild;
    expect(renderSliver.geometry.scrollExtent, 14.0);
    expect(renderSliver.constraints.crossAxisExtent, 800.0);
    expect(semantics.nodesWith(label: 'a true'), hasLength(1));
    expect(log, <String>['created new state']);
    await tester.tap(find.byKey(anchor));
    expect(log, <String>['created new state']);
    log.clear();

    // visible: false, maintain state, animation, size.
    await tester.pumpWidget(_boilerPlate(SliverVisibility(
      sliver: testChild,
      visible: false,
      maintainState: true,
      maintainAnimation: true,
      maintainSize: true,
    )));
    expect(find.byType(Text, skipOffstage: false), findsOneWidget);
    expect(find.text('a true', skipOffstage: false), findsOneWidget);
    expect(find.byType(SliverVisibility), findsOneWidget);
    expect(find.byType(SliverVisibility), paintsNothing);
    renderViewport = tester.renderObject(find.byType(Viewport));
    renderSliver = renderViewport.lastChild;
    expect(renderSliver.geometry.scrollExtent, 14.0);
    expect(renderSliver.constraints.crossAxisExtent, 800.0);
    expect(semantics.nodesWith(label: 'a true'), hasLength(0));
    expect(log, <String>[]);
    await tester.tap(find.byKey(anchor));
    expect(log, <String>[]);
    log.clear();

    // visible: false, maintain state and animation.
    await tester.pumpWidget(_boilerPlate(SliverVisibility(
      sliver: testChild,
      visible: false,
      maintainState: true,
      maintainAnimation: true,
    )));
    expect(find.byType(Text, skipOffstage: false), findsOneWidget);
    expect(find.byType(Text, skipOffstage: true), findsNothing);
    expect(find.text('a true', skipOffstage: false), findsOneWidget);
    expect(find.byType(SliverVisibility, skipOffstage: false), findsOneWidget);
    expect(find.byType(SliverVisibility, skipOffstage: false), paintsNothing);
    renderViewport = tester.renderObject(find.byType(Viewport));
    renderSliver = renderViewport.lastChild;
    expect(renderSliver.geometry.scrollExtent, 0.0);
    expect(renderSliver.constraints.crossAxisExtent, 800.0);
    expect(semantics.nodesWith(label: 'a true'), hasLength(0));
    expect(log, <String>['created new state']);
    expect(find.byKey(anchor), findsNothing);
    log.clear();

    // visible: false, maintain state.
    await tester.pumpWidget(_boilerPlate(SliverVisibility(
      sliver: testChild,
      visible: false,
      maintainState: true,
    )));
    expect(find.byType(Text, skipOffstage: false), findsOneWidget);
    expect(find.byType(Text, skipOffstage: true), findsNothing);
    expect(find.text('a false', skipOffstage: false), findsOneWidget);
    expect(find.byType(SliverVisibility, skipOffstage: false), findsOneWidget);
    expect(find.byType(SliverVisibility, skipOffstage: false), paintsNothing);
    renderViewport = tester.renderObject(find.byType(Viewport));
    renderSliver = renderViewport.lastChild;
    expect(renderSliver.geometry.scrollExtent, 0.0);
    expect(renderSliver.constraints.crossAxisExtent, 800.0);
    expect(semantics.nodesWith(label: 'a true'), hasLength(0));
    expect(log, <String>['created new state']);
    expect(find.byKey(anchor), findsNothing);
    log.clear();

    // Now we toggle the visibility off and on a few times to make sure that
    // works.

    // visible: true, maintain state/
    await tester.pumpWidget(_boilerPlate(SliverVisibility(
      sliver: testChild,
      visible: true,
      maintainState: true,
    )));
    expect(find.byType(Text), findsOneWidget);
    expect(find.text('a true'), findsOneWidget);
    expect(find.byType(SliverVisibility), findsOneWidget);
    // TODO(Piinks): this fails
//    expect(find.byType(SliverVisibility), paints..paragraph());
    renderViewport = tester.renderObject(find.byType(Viewport));
    renderSliver = renderViewport.lastChild;
    expect(renderSliver.geometry.scrollExtent, 14.0);
    expect(renderSliver.constraints.crossAxisExtent, 800.0);
    expect(semantics.nodesWith(label: 'a true'), hasLength(1));
    expect(log, <String>[]);
    await tester.tap(find.byKey(anchor));
    expect(log, <String>['tap']);
    log.clear();

    // visible: false, maintain state.
    await tester.pumpWidget(_boilerPlate(SliverVisibility(
      sliver: testChild,
      visible: false,
      maintainState: true,
    )));
    expect(find.byType(Text, skipOffstage: false), findsOneWidget);
    expect(find.byType(Text, skipOffstage: true), findsNothing);
    expect(find.text('a false', skipOffstage: false), findsOneWidget);
    expect(find.byType(SliverVisibility, skipOffstage: false), findsOneWidget);
    expect(find.byType(SliverVisibility, skipOffstage: false), paintsNothing);
    renderViewport = tester.renderObject(find.byType(Viewport));
    renderSliver = renderViewport.lastChild;
    expect(renderSliver.geometry.scrollExtent, 0.0);
    expect(renderSliver.constraints.crossAxisExtent, 800.0);
    expect(semantics.nodesWith(label: 'a false'), hasLength(0));
    expect(log, <String>[]);
    expect(find.byKey(anchor), findsNothing);
    log.clear();

    // visible: true, maintain state.
    await tester.pumpWidget(_boilerPlate(SliverVisibility(
      sliver: testChild,
      visible: true,
      maintainState: true,
    )));
    expect(find.byType(Text), findsOneWidget);
    expect(find.text('a true', skipOffstage: false), findsOneWidget);
    expect(find.byType(SliverVisibility, skipOffstage: false), findsOneWidget);
    // TODO(Piinks): This fails
//    expect(find.byType(SliverVisibility, skipOffstage: false), paints..paragraph());
    renderViewport = tester.renderObject(find.byType(Viewport));
    renderSliver = renderViewport.lastChild;
    expect(renderSliver.geometry.scrollExtent, 14.0);
    expect(renderSliver.constraints.crossAxisExtent, 800.0);
    expect(semantics.nodesWith(label: 'a true'), hasLength(1));
    expect(log, <String>[]);
    await tester.tap(find.byKey(anchor));
    expect(log, <String>['tap']);
    log.clear();

    // visible: false, maintain state.
    await tester.pumpWidget(_boilerPlate(SliverVisibility(
      sliver: testChild,
      visible: false,
      maintainState: true,
    )));
    expect(find.byType(Text, skipOffstage: false), findsOneWidget);
    expect(find.byType(Text, skipOffstage: true), findsNothing);
    expect(find.text('a false', skipOffstage: false), findsOneWidget);
    expect(find.byType(SliverVisibility, skipOffstage: false), findsOneWidget);
    expect(find.byType(SliverVisibility, skipOffstage: false), paintsNothing);
    renderViewport = tester.renderObject(find.byType(Viewport));
    renderSliver = renderViewport.lastChild;
    expect(renderSliver.geometry.scrollExtent, 0.0);
    expect(renderSliver.constraints.crossAxisExtent, 800.0);
    expect(semantics.nodesWith(label: 'a false'), hasLength(0));
    expect(log, <String>[]);
    expect(find.byKey(anchor), findsNothing);
    log.clear();

    // Same but without maintainState.

    // visible: false.
    await tester.pumpWidget(_boilerPlate(SliverVisibility(
      sliver: testChild,
      visible: false,
    )));
    expect(find.byType(Text, skipOffstage: false), findsNothing);
    expect(find.byType(SliverVisibility, skipOffstage: false), findsOneWidget);
    expect(find.byType(SliverVisibility, skipOffstage: false), paintsNothing);
    renderViewport = tester.renderObject(find.byType(Viewport));
    renderSliver = renderViewport.lastChild;
    expect(renderSliver.geometry.scrollExtent, 0.0);
    expect(renderSliver.constraints.crossAxisExtent, 800.0);
    expect(semantics.nodesWith(label: 'a true'), hasLength(0));
    expect(log, <String>[]);
    expect(find.byKey(anchor), findsNothing);
    log.clear();

    // visible: true.
    await tester.pumpWidget(_boilerPlate(SliverVisibility(
      sliver: testChild,
      visible: true,
    )));
    expect(find.byType(Text), findsOneWidget);
    expect(find.text('a true', skipOffstage: false), findsOneWidget);
    expect(find.byType(SliverVisibility), findsOneWidget);
    expect(find.byType(SliverVisibility), paints..paragraph());
    renderViewport = tester.renderObject(find.byType(Viewport));
    renderSliver = renderViewport.lastChild;
    expect(renderSliver.geometry.scrollExtent, 14.0);
    expect(renderSliver.constraints.crossAxisExtent, 800.0);
    expect(semantics.nodesWith(label: 'a true'), hasLength(1));
    expect(log, <String>['created new state']);
    await tester.tap(find.byKey(anchor));
    expect(log, <String>['created new state', 'tap']);
    log.clear();

    //visible: false.
    await tester.pumpWidget(_boilerPlate(SliverVisibility(
      sliver: testChild,
      visible: false,
    )));
    expect(find.byType(Text, skipOffstage: false), findsNothing);
    expect(find.byType(SliverVisibility, skipOffstage: false), findsOneWidget);
    expect(find.byType(SliverVisibility, skipOffstage: false), paintsNothing);
    renderViewport = tester.renderObject(find.byType(Viewport));
    renderSliver = renderViewport.lastChild;
    expect(renderSliver.geometry.scrollExtent, 0.0);
    expect(renderSliver.constraints.crossAxisExtent, 800.0);
    expect(semantics.nodesWith(label: 'a true'), hasLength(0));
    expect(log, <String>[]);
    expect(find.byKey(anchor), findsNothing);
    log.clear();

    // visible: true.
    await tester.pumpWidget(_boilerPlate(SliverVisibility(
      sliver: testChild,
      visible: true,
    )));
    expect(find.byType(Text), findsOneWidget);
    expect(find.text('a true', skipOffstage: false), findsOneWidget);
    expect(find.byType(SliverVisibility), findsOneWidget);
    expect(find.byType(SliverVisibility), paints..paragraph());
    renderViewport = tester.renderObject(find.byType(Viewport));
    renderSliver = renderViewport.lastChild;
    expect(renderSliver.geometry.scrollExtent, 14.0);
    expect(renderSliver.constraints.crossAxisExtent, 800.0);
    expect(semantics.nodesWith(label: 'a true'), hasLength(1));
    expect(log, <String>['created new state']);
    await tester.tap(find.byKey(anchor));
    expect(log, <String>['created new state', 'tap']);
    log.clear();
    
    semantics.dispose();
  }, skip: isBrowser);
}
