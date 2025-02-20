// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class TestExpansibleWidget extends StatefulWidget {
  const TestExpansibleWidget({
    super.key,
    this.initiallyExpanded = false,
    this.maintainState = false,
    this.onExpansionChanged,
    this.expansionDuration = const Duration(milliseconds: 200),
    this.expansionCurve = Curves.linear,
    required this.controller,
    required this.children,
  });
  final bool initiallyExpanded;
  final List<Widget> children;
  final bool maintainState;
  final ValueChanged<bool>? onExpansionChanged;
  final Duration expansionDuration;
  final Curve expansionCurve;
  final ExpansibleController<TestExpansibleWidget> controller;

  @override
  State<TestExpansibleWidget> createState() => _TestExpansibleWidgetState();
}

class _TestExpansibleWidgetState extends State<TestExpansibleWidget>
    with TickerProviderStateMixin, ExpansibleStateMixin<TestExpansibleWidget> {
  @override
  List<Widget> get children => widget.children;

  @override
  ValueChanged<bool>? get onExpansionChanged => widget.onExpansionChanged;

  @override
  Duration get expansionDuration => widget.expansionDuration;

  @override
  Curve get expansionCurve => widget.expansionCurve;

  @override
  bool get initiallyExpanded => widget.initiallyExpanded;

  @override
  bool get maintainState => widget.maintainState;

  @override
  ExpansibleController<TestExpansibleWidget> get controller => widget.controller;

  @override
  Widget buildHeader(BuildContext context) {
    return GestureDetector(onTap: toggleExpansion, child: const Text('Header'));
  }

  @override
  Widget buildBody(BuildContext context) {
    return Column(children: children);
  }
}

void main() {
  testWidgets('Controller expands and collapses the widget', (WidgetTester tester) async {
    final ExpansibleController<TestExpansibleWidget> controller =
        ExpansibleController<TestExpansibleWidget>();
    await tester.pumpWidget(
      MaterialApp(
        color: const Color(0xffffffff),
        home: TestExpansibleWidget(controller: controller, children: const <Widget>[Text('Body')]),
      ),
    );

    expect(find.text('Body'), findsNothing);
    controller.expand();
    await tester.pumpAndSettle();
    expect(find.text('Body'), findsOneWidget);

    controller.collapse();
    await tester.pumpAndSettle();
    expect(find.text('Body'), findsNothing);
  });

  testWidgets('onExpansionChanged callback', (WidgetTester tester) async {
    final ExpansibleController<TestExpansibleWidget> controller =
        ExpansibleController<TestExpansibleWidget>();
    bool? expansionState;
    await tester.pumpWidget(
      MaterialApp(
        color: const Color(0xffffffff),
        home: TestExpansibleWidget(
          controller: controller,
          children: const <Widget>[Text('Body')],
          onExpansionChanged: (bool expanded) {
            expansionState = expanded;
          },
        ),
      ),
    );

    // Tap on the header to toggle the expansion.
    await tester.tap(find.text('Header'));
    await tester.pumpAndSettle();
    expect(expansionState, true);

    await tester.tap(find.text('Header'));
    await tester.pumpAndSettle();
    expect(expansionState, false);

    // Use the controller to toggle the expansion.
    controller.expand();
    await tester.pumpAndSettle();
    expect(expansionState, true);

    controller.collapse();
    await tester.pumpAndSettle();
    expect(expansionState, false);
  });

  testWidgets('Respects initiallyExpanded', (WidgetTester tester) async {
    final ExpansibleController<TestExpansibleWidget> controller =
        ExpansibleController<TestExpansibleWidget>();
    await tester.pumpWidget(
      MaterialApp(
        home: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              TestExpansibleWidget(
                controller: controller,
                initiallyExpanded: true,
                children: const <Widget>[Text('Body')],
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Body'), findsOneWidget);

    await tester.tap(find.text('Header'));
    await tester.pumpAndSettle();

    expect(find.text('Body'), findsNothing);
  });

  testWidgets('ExpansionTile maintainState', (WidgetTester tester) async {
    final ExpansibleController<TestExpansibleWidget> controller1 =
        ExpansibleController<TestExpansibleWidget>();
    final ExpansibleController<TestExpansibleWidget> controller2 =
        ExpansibleController<TestExpansibleWidget>();
    await tester.pumpWidget(
      MaterialApp(
        home: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              TestExpansibleWidget(
                controller: controller1,
                maintainState: true,
                children: const <Widget>[Text('Maintaining State')],
              ),
              TestExpansibleWidget(
                controller: controller2,
                children: const <Widget>[Text('Discarding State')],
              ),
            ],
          ),
        ),
      ),
    );

    // This text should be offstage while ExpansionTile collapsed
    expect(find.text('Maintaining State', skipOffstage: false), findsOneWidget);
    expect(find.text('Maintaining State'), findsNothing);
    // This text shouldn't be there while ExpansionTile collapsed
    expect(find.text('Discarding State'), findsNothing);
  });
}
