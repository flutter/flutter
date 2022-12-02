// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('LookupBoundary.findAncestorWidgetOfExactType respects boundary', (WidgetTester tester) async {
    Widget? containerThroughBoundary;
    Widget? containerStoppedAtBoundary;
    Widget? boundaryThroughBoundary;
    Widget? boundaryStoppedAtBoundary;

    final Key containerKey = UniqueKey();
    final Key boundaryKey = UniqueKey();

    await tester.pumpWidget(Container(
      key: containerKey,
      child: LookupBoundary(
        key: boundaryKey,
        child: Builder(
          builder: (BuildContext context) {
            containerThroughBoundary = context.findAncestorWidgetOfExactType<Container>();
            containerStoppedAtBoundary = LookupBoundary.findAncestorWidgetOfExactType<Container>(context);
            boundaryThroughBoundary = context.findAncestorWidgetOfExactType<LookupBoundary>();
            boundaryStoppedAtBoundary = LookupBoundary.findAncestorWidgetOfExactType<LookupBoundary>(context);
            return const SizedBox.expand();
          },
        ),
      ),
    ));

    expect(containerThroughBoundary, equals(tester.widget(find.byKey(containerKey))));
    expect(containerStoppedAtBoundary, isNull);
    expect(boundaryThroughBoundary, equals(tester.widget(find.byKey(boundaryKey))));
    expect(boundaryStoppedAtBoundary, equals(tester.widget(find.byKey(boundaryKey))));
  });

  testWidgets('LookupBoundary.findAncestorWidgetOfExactType finds widget before boundary', (WidgetTester tester) async {
    Widget? containerThroughBoundary;
    Widget? containerStoppedAtBoundary;

    final Key outerContainerKey = UniqueKey();
    final Key innerContainerKey = UniqueKey();

    await tester.pumpWidget(Container(
      key: outerContainerKey,
      child: LookupBoundary(
        child: Container(
          key: innerContainerKey,
          child: Builder(
            builder: (BuildContext context) {
              containerThroughBoundary = context.findAncestorWidgetOfExactType<Container>();
              containerStoppedAtBoundary = LookupBoundary.findAncestorWidgetOfExactType<Container>(context);
              return const SizedBox.expand();
            },
          ),
        ),
      ),
    ));

    expect(containerThroughBoundary, equals(tester.widget(find.byKey(innerContainerKey))));
    expect(containerStoppedAtBoundary, equals(tester.widget(find.byKey(innerContainerKey))));
  });

  testWidgets('LookupBoundary.findAncestorWidgetOfExactType works if nothing is found', (WidgetTester tester) async {
    Widget? containerStoppedAtBoundary;

    await tester.pumpWidget(Builder(
      builder: (BuildContext context) {
        containerStoppedAtBoundary = LookupBoundary.findAncestorWidgetOfExactType<Container>(context);
        return const SizedBox.expand();
      },
    ));

    expect(containerStoppedAtBoundary, isNull);
  });

  testWidgets('LookupBoundary.findAncestorWidgetOfExactType does not establish a dependency', (WidgetTester tester) async {
    Widget? containerThroughBoundary;
    Widget? containerStoppedAtBoundary;
    Widget? containerStoppedAtBoundaryUnfulfilled;

    final Key innerContainerKey = UniqueKey();
    final Key globalKey = GlobalKey();

    final Widget widgetTree = LookupBoundary(
      child: Container(
        key: innerContainerKey,
        child: DidChangeDependencySpy(
          key: globalKey,
          onDidChangeDependencies: (BuildContext context) {
            containerThroughBoundary = context.findAncestorWidgetOfExactType<Container>();
            containerStoppedAtBoundary = LookupBoundary.findAncestorWidgetOfExactType<Container>(context);
            containerStoppedAtBoundaryUnfulfilled = LookupBoundary.findAncestorWidgetOfExactType<Material>(context);
          },
        ),
      ),
    );

    await tester.pumpWidget(widgetTree);

    expect(containerThroughBoundary, equals(tester.widget(find.byKey(innerContainerKey))));
    expect(containerStoppedAtBoundary, equals(tester.widget(find.byKey(innerContainerKey))));
    expect(containerStoppedAtBoundaryUnfulfilled, isNull);
    expect(tester.state<_DidChangeDependencySpyState>(find.byType(DidChangeDependencySpy)).didChangeDependenciesCount, 1);

    await tester.pumpWidget(
      SizedBox( // Changes tree structure, triggers global key move of DidChangeDependencySpy.
        child: widgetTree,
      ),
    );

    // Tree restructuring above would have called didChangeDependencies if dependency had been established.
    expect(tester.state<_DidChangeDependencySpyState>(find.byType(DidChangeDependencySpy)).didChangeDependenciesCount, 1);
  });

  testWidgets('LookupBoundary.dependOnInheritedWidgetOfExactType respects boundary', (WidgetTester tester) async {
    InheritedWidget? containerThroughBoundary;
    InheritedWidget? containerStoppedAtBoundary;

    final Key inheritedKey = UniqueKey();

    await tester.pumpWidget(MyInheritedWidget(
      key: inheritedKey,
      child: LookupBoundary(
        child: Builder(
          builder: (BuildContext context) {
            containerThroughBoundary = context.dependOnInheritedWidgetOfExactType<MyInheritedWidget>();
            containerStoppedAtBoundary = LookupBoundary.findAncestorWidgetOfExactType<MyInheritedWidget>(context);
            return const SizedBox.expand();
          },
        ),
      ),
    ));

    expect(containerThroughBoundary, equals(tester.widget(find.byKey(inheritedKey))));
    expect(containerStoppedAtBoundary, isNull);
  });

  testWidgets('dependOnInheritedWidgetOfExactType finds widget before boundary', (WidgetTester tester) async {
    InheritedWidget? containerThroughBoundary;
    InheritedWidget? containerStoppedAtBoundary;

    final Key inheritedKey = UniqueKey();

    await tester.pumpWidget(MyInheritedWidget(
      child: LookupBoundary(
        child: MyInheritedWidget(
          key: inheritedKey,
          child: Builder(
            builder: (BuildContext context) {
              containerThroughBoundary = context.dependOnInheritedWidgetOfExactType<MyInheritedWidget>();
              containerStoppedAtBoundary = LookupBoundary.findAncestorWidgetOfExactType<MyInheritedWidget>(context);
              return const SizedBox.expand();
            },
          ),
        ),
      ),
    ));

    expect(containerThroughBoundary, equals(tester.widget(find.byKey(inheritedKey))));
    expect(containerStoppedAtBoundary, equals(tester.widget(find.byKey(inheritedKey))));
  });

  // TODO(goderbauer): test that dependency is established.
  // TODO(goderbauer): test that didChangeDependencies is called when moved and dependency was unfulfilled.
}

class MyStatefulContainer extends StatefulWidget {
  const MyStatefulContainer({super.key, required this.child});

  final Widget child;

  @override
  State<MyStatefulContainer> createState() => MyStatefulContainerState();
}

class MyStatefulContainerState extends State<MyStatefulContainer> {
  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
class MyInheritedWidget extends InheritedWidget {
  const MyInheritedWidget({super.key, required super.child});

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) => true;
}

class DidChangeDependencySpy extends StatefulWidget {
  const DidChangeDependencySpy({super.key, required this.onDidChangeDependencies});

  final Function onDidChangeDependencies;

  @override
  State<DidChangeDependencySpy> createState() => _DidChangeDependencySpyState();
}

class _DidChangeDependencySpyState extends State<DidChangeDependencySpy> {
  int didChangeDependenciesCount = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    didChangeDependenciesCount += 1;
    widget.onDidChangeDependencies(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
