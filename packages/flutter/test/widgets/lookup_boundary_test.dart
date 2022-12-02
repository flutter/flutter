// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
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
      value: 2,
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

  testWidgets('LookupBoundary.dependOnInheritedWidgetOfExactType ignores ancestor boundary', (WidgetTester tester) async {
    InheritedWidget? inheritedWidget;

    final Key inheritedKey = UniqueKey();

    await tester.pumpWidget(LookupBoundary(
      child: MyInheritedWidget(
        value: 2,
        key: inheritedKey,
        child: Builder(
          builder: (BuildContext context) {
            inheritedWidget = LookupBoundary.findAncestorWidgetOfExactType<MyInheritedWidget>(context);
            return const SizedBox.expand();
          },
        ),
      ),
    ));

    expect(inheritedWidget, equals(tester.widget(find.byKey(inheritedKey))));
  });

  testWidgets('LookupBoundary.dependOnInheritedWidgetOfExactType finds widget before boundary', (WidgetTester tester) async {
    InheritedWidget? containerThroughBoundary;
    InheritedWidget? containerStoppedAtBoundary;

    final Key inheritedKey = UniqueKey();

    await tester.pumpWidget(MyInheritedWidget(
      value: 2,
      child: LookupBoundary(
        child: MyInheritedWidget(
          key: inheritedKey,
          value: 1,
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

  testWidgets('LookupBoundary.dependOnInheritedWidgetOfExactType creates dependency', (WidgetTester tester) async {
    MyInheritedWidget? inheritedWidget;

    final Widget widgetTree = DidChangeDependencySpy(
      onDidChangeDependencies: (BuildContext context) {
        inheritedWidget = LookupBoundary.dependOnInheritedWidgetOfExactType<MyInheritedWidget>(context);
      },
    );

    await tester.pumpWidget(
      MyInheritedWidget(
        value: 1,
        child: widgetTree,
      ),
    );
    expect(inheritedWidget!.value, 1);
    expect(tester.state<_DidChangeDependencySpyState>(find.byType(DidChangeDependencySpy)).didChangeDependenciesCount, 1);

    await tester.pumpWidget(
      MyInheritedWidget(
        value: 2,
        child: widgetTree,
      ),
    );
    expect(inheritedWidget!.value, 2);
    expect(tester.state<_DidChangeDependencySpyState>(find.byType(DidChangeDependencySpy)).didChangeDependenciesCount, 2);
  });

  testWidgets('LookupBoundary.dependOnInheritedWidgetOfExactType causes didChangeDependencies to be called on move even if dependency was not fulfilled due to boundary', (WidgetTester tester) async {
    MyInheritedWidget? inheritedWidget;
    final Key globalKey = GlobalKey();

    final Widget widgetTree = DidChangeDependencySpy(
      key: globalKey,
      onDidChangeDependencies: (BuildContext context) {
        inheritedWidget = LookupBoundary.dependOnInheritedWidgetOfExactType<MyInheritedWidget>(context);
      },
    );

    await tester.pumpWidget(
      MyInheritedWidget(
        value: 1,
        child: LookupBoundary(
          child: widgetTree,
        ),
      ),
    );
    expect(inheritedWidget, isNull);
    expect(tester.state<_DidChangeDependencySpyState>(find.byType(DidChangeDependencySpy)).didChangeDependenciesCount, 1);

    // Value of inherited widget changes, but there should be no dependency due to boundary.
    await tester.pumpWidget(
      MyInheritedWidget(
        value: 2,
        child: LookupBoundary(
          child: widgetTree,
        ),
      ),
    );
    expect(inheritedWidget, isNull);
    expect(tester.state<_DidChangeDependencySpyState>(find.byType(DidChangeDependencySpy)).didChangeDependenciesCount, 1);

    // Widget is moved, didChangeDependencies is called, but dependency is still not found due to boundary.
    await tester.pumpWidget(
      SizedBox(
        child: MyInheritedWidget(
          value: 2,
          child: LookupBoundary(
            child: widgetTree,
          ),
        ),
      ),
    );
    expect(inheritedWidget, isNull);
    expect(tester.state<_DidChangeDependencySpyState>(find.byType(DidChangeDependencySpy)).didChangeDependenciesCount, 2);

    await tester.pumpWidget(
      SizedBox(
        child: MyInheritedWidget(
          value: 2,
          child: LookupBoundary(
            child: MyInheritedWidget(
              value: 4,
              child: widgetTree,
            ),
          ),
        ),
      ),
    );
    expect(inheritedWidget!.value, 4);
    expect(tester.state<_DidChangeDependencySpyState>(find.byType(DidChangeDependencySpy)).didChangeDependenciesCount, 3);
  });

  testWidgets('LookupBoundary.dependOnInheritedWidgetOfExactType causes didChangeDependencies to be called on move even if dependency was non-existant', (WidgetTester tester) async {
    MyInheritedWidget? inheritedWidget;
    final Key globalKey = GlobalKey();

    final Widget widgetTree = DidChangeDependencySpy(
      key: globalKey,
      onDidChangeDependencies: (BuildContext context) {
        inheritedWidget = LookupBoundary.dependOnInheritedWidgetOfExactType<MyInheritedWidget>(context);
      },
    );

    await tester.pumpWidget(widgetTree);
    expect(inheritedWidget, isNull);
    expect(tester.state<_DidChangeDependencySpyState>(find.byType(DidChangeDependencySpy)).didChangeDependenciesCount, 1);

    // Widget moved, didChangeDependencies must be called.
    await tester.pumpWidget(
      SizedBox(
        child: widgetTree,
      ),
    );
    expect(inheritedWidget, isNull);
    expect(tester.state<_DidChangeDependencySpyState>(find.byType(DidChangeDependencySpy)).didChangeDependenciesCount, 2);

    // Widget moved, didChangeDependencies must be called.
    await tester.pumpWidget(
      MyInheritedWidget(
        value: 6,
        child: SizedBox(
          child: widgetTree,
        ),
      ),
    );
    expect(inheritedWidget!.value, 6);
    expect(tester.state<_DidChangeDependencySpyState>(find.byType(DidChangeDependencySpy)).didChangeDependenciesCount, 3);
  });
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
  const MyInheritedWidget({super.key, required this.value, required super.child});

  final int value;

  @override
  bool updateShouldNotify(MyInheritedWidget oldWidget) => oldWidget.value != value;
}

class DidChangeDependencySpy extends StatefulWidget {
  const DidChangeDependencySpy({super.key, required this.onDidChangeDependencies});

  final OnDidChangeDependencies onDidChangeDependencies;

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

typedef OnDidChangeDependencies = void Function(BuildContext context);
