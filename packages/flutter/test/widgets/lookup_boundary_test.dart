// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
<<<<<<< HEAD

void main() {
  group('LookupBoundary.dependOnInheritedWidgetOfExactType', () {
    testWidgets('respects boundary', (WidgetTester tester) async {
=======
import 'package:leak_tracker_flutter_testing/leak_tracker_flutter_testing.dart';

void main() {
  group('LookupBoundary.dependOnInheritedWidgetOfExactType', () {
    testWidgetsWithLeakTracking('respects boundary', (WidgetTester tester) async {
>>>>>>> db7ef5bf9f59442b0e200a90587e8fa5e0c6336a
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
              containerStoppedAtBoundary = LookupBoundary.dependOnInheritedWidgetOfExactType<MyInheritedWidget>(context);
              return const SizedBox.expand();
            },
          ),
        ),
      ));

      expect(containerThroughBoundary, equals(tester.widget(find.byKey(inheritedKey))));
      expect(containerStoppedAtBoundary, isNull);
    });

<<<<<<< HEAD
    testWidgets('ignores ancestor boundary', (WidgetTester tester) async {
=======
    testWidgetsWithLeakTracking('ignores ancestor boundary', (WidgetTester tester) async {
>>>>>>> db7ef5bf9f59442b0e200a90587e8fa5e0c6336a
      InheritedWidget? inheritedWidget;

      final Key inheritedKey = UniqueKey();

      await tester.pumpWidget(LookupBoundary(
        child: MyInheritedWidget(
          value: 2,
          key: inheritedKey,
          child: Builder(
            builder: (BuildContext context) {
              inheritedWidget = LookupBoundary.dependOnInheritedWidgetOfExactType<MyInheritedWidget>(context);
              return const SizedBox.expand();
            },
          ),
        ),
      ));

      expect(inheritedWidget, equals(tester.widget(find.byKey(inheritedKey))));
    });

<<<<<<< HEAD
    testWidgets('finds widget before boundary', (WidgetTester tester) async {
=======
    testWidgetsWithLeakTracking('finds widget before boundary', (WidgetTester tester) async {
>>>>>>> db7ef5bf9f59442b0e200a90587e8fa5e0c6336a
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
                containerStoppedAtBoundary = LookupBoundary.dependOnInheritedWidgetOfExactType<MyInheritedWidget>(context);
                return const SizedBox.expand();
              },
            ),
          ),
        ),
      ));

      expect(containerThroughBoundary, equals(tester.widget(find.byKey(inheritedKey))));
      expect(containerStoppedAtBoundary, equals(tester.widget(find.byKey(inheritedKey))));
    });

<<<<<<< HEAD
    testWidgets('creates dependency', (WidgetTester tester) async {
=======
    testWidgetsWithLeakTracking('creates dependency', (WidgetTester tester) async {
>>>>>>> db7ef5bf9f59442b0e200a90587e8fa5e0c6336a
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

<<<<<<< HEAD
    testWidgets('causes didChangeDependencies to be called on move even if dependency was not fulfilled due to boundary', (WidgetTester tester) async {
=======
    testWidgetsWithLeakTracking('causes didChangeDependencies to be called on move even if dependency was not fulfilled due to boundary', (WidgetTester tester) async {
>>>>>>> db7ef5bf9f59442b0e200a90587e8fa5e0c6336a
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

<<<<<<< HEAD
    testWidgets('causes didChangeDependencies to be called on move even if dependency was non-existant', (WidgetTester tester) async {
=======
    testWidgetsWithLeakTracking('causes didChangeDependencies to be called on move even if dependency was non-existant', (WidgetTester tester) async {
>>>>>>> db7ef5bf9f59442b0e200a90587e8fa5e0c6336a
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
  });

  group('LookupBoundary.getElementForInheritedWidgetOfExactType', () {
<<<<<<< HEAD
    testWidgets('respects boundary', (WidgetTester tester) async {
=======
    testWidgetsWithLeakTracking('respects boundary', (WidgetTester tester) async {
>>>>>>> db7ef5bf9f59442b0e200a90587e8fa5e0c6336a
      InheritedElement? containerThroughBoundary;
      InheritedElement? containerStoppedAtBoundary;

      final Key inheritedKey = UniqueKey();

      await tester.pumpWidget(MyInheritedWidget(
        value: 2,
        key: inheritedKey,
        child: LookupBoundary(
          child: Builder(
            builder: (BuildContext context) {
              containerThroughBoundary = context.getElementForInheritedWidgetOfExactType<MyInheritedWidget>();
              containerStoppedAtBoundary = LookupBoundary.getElementForInheritedWidgetOfExactType<MyInheritedWidget>(context);
              return const SizedBox.expand();
            },
          ),
        ),
      ));

      expect(containerThroughBoundary, equals(tester.element(find.byKey(inheritedKey))));
      expect(containerStoppedAtBoundary, isNull);
    });

<<<<<<< HEAD
    testWidgets('ignores ancestor boundary', (WidgetTester tester) async {
=======
    testWidgetsWithLeakTracking('ignores ancestor boundary', (WidgetTester tester) async {
>>>>>>> db7ef5bf9f59442b0e200a90587e8fa5e0c6336a
      InheritedElement? inheritedWidget;

      final Key inheritedKey = UniqueKey();

      await tester.pumpWidget(LookupBoundary(
        child: MyInheritedWidget(
          value: 2,
          key: inheritedKey,
          child: Builder(
            builder: (BuildContext context) {
              inheritedWidget = LookupBoundary.getElementForInheritedWidgetOfExactType<MyInheritedWidget>(context);
              return const SizedBox.expand();
            },
          ),
        ),
      ));

      expect(inheritedWidget, equals(tester.element(find.byKey(inheritedKey))));
    });

<<<<<<< HEAD
    testWidgets('finds widget before boundary', (WidgetTester tester) async {
=======
    testWidgetsWithLeakTracking('finds widget before boundary', (WidgetTester tester) async {
>>>>>>> db7ef5bf9f59442b0e200a90587e8fa5e0c6336a
      InheritedElement? containerThroughBoundary;
      InheritedElement? containerStoppedAtBoundary;

      final Key inheritedKey = UniqueKey();

      await tester.pumpWidget(MyInheritedWidget(
        value: 2,
        child: LookupBoundary(
          child: MyInheritedWidget(
            key: inheritedKey,
            value: 1,
            child: Builder(
              builder: (BuildContext context) {
                containerThroughBoundary = context.getElementForInheritedWidgetOfExactType<MyInheritedWidget>();
                containerStoppedAtBoundary = LookupBoundary.getElementForInheritedWidgetOfExactType<MyInheritedWidget>(context);
                return const SizedBox.expand();
              },
            ),
          ),
        ),
      ));

      expect(containerThroughBoundary, equals(tester.element(find.byKey(inheritedKey))));
      expect(containerStoppedAtBoundary, equals(tester.element(find.byKey(inheritedKey))));
    });

<<<<<<< HEAD
    testWidgets('does not creates dependency', (WidgetTester tester) async {
=======
    testWidgetsWithLeakTracking('does not creates dependency', (WidgetTester tester) async {
>>>>>>> db7ef5bf9f59442b0e200a90587e8fa5e0c6336a

      final Widget widgetTree = DidChangeDependencySpy(
        onDidChangeDependencies: (BuildContext context) {
          LookupBoundary.getElementForInheritedWidgetOfExactType<MyInheritedWidget>(context);
        },
      );

      await tester.pumpWidget(
        MyInheritedWidget(
          value: 1,
          child: widgetTree,
        ),
      );
      expect(tester.state<_DidChangeDependencySpyState>(find.byType(DidChangeDependencySpy)).didChangeDependenciesCount, 1);

      await tester.pumpWidget(
        MyInheritedWidget(
          value: 2,
          child: widgetTree,
        ),
      );
      expect(tester.state<_DidChangeDependencySpyState>(find.byType(DidChangeDependencySpy)).didChangeDependenciesCount, 1);
    });

<<<<<<< HEAD
    testWidgets('does not cause didChangeDependencies to be called on move when found', (WidgetTester tester) async {
=======
    testWidgetsWithLeakTracking('does not cause didChangeDependencies to be called on move when found', (WidgetTester tester) async {
>>>>>>> db7ef5bf9f59442b0e200a90587e8fa5e0c6336a
      final Key globalKey = GlobalKey();

      final Widget widgetTree = DidChangeDependencySpy(
        key: globalKey,
        onDidChangeDependencies: (BuildContext context) {
          LookupBoundary.getElementForInheritedWidgetOfExactType<MyInheritedWidget>(context);
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
      expect(tester.state<_DidChangeDependencySpyState>(find.byType(DidChangeDependencySpy)).didChangeDependenciesCount, 1);

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
      expect(tester.state<_DidChangeDependencySpyState>(find.byType(DidChangeDependencySpy)).didChangeDependenciesCount, 1);
    });

<<<<<<< HEAD
    testWidgets('does not cause didChangeDependencies to be called on move when nothing was found', (WidgetTester tester) async {
=======
    testWidgetsWithLeakTracking('does not cause didChangeDependencies to be called on move when nothing was found', (WidgetTester tester) async {
>>>>>>> db7ef5bf9f59442b0e200a90587e8fa5e0c6336a
      final Key globalKey = GlobalKey();

      final Widget widgetTree = DidChangeDependencySpy(
        key: globalKey,
        onDidChangeDependencies: (BuildContext context) {
          LookupBoundary.getElementForInheritedWidgetOfExactType<MyInheritedWidget>(context);
        },
      );

      await tester.pumpWidget(widgetTree);
      expect(tester.state<_DidChangeDependencySpyState>(find.byType(DidChangeDependencySpy)).didChangeDependenciesCount, 1);

      // Widget moved, didChangeDependencies must be called.
      await tester.pumpWidget(
        SizedBox(
          child: widgetTree,
        ),
      );
      expect(tester.state<_DidChangeDependencySpyState>(find.byType(DidChangeDependencySpy)).didChangeDependenciesCount, 1);

      // Widget moved, didChangeDependencies must be called.
      await tester.pumpWidget(
        MyInheritedWidget(
          value: 6,
          child: SizedBox(
            child: widgetTree,
          ),
        ),
      );
      expect(tester.state<_DidChangeDependencySpyState>(find.byType(DidChangeDependencySpy)).didChangeDependenciesCount, 1);
    });
  });

  group('LookupBoundary.findAncestorWidgetOfExactType', () {
<<<<<<< HEAD
    testWidgets('respects boundary', (WidgetTester tester) async {
=======
    testWidgetsWithLeakTracking('respects boundary', (WidgetTester tester) async {
>>>>>>> db7ef5bf9f59442b0e200a90587e8fa5e0c6336a
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

<<<<<<< HEAD
    testWidgets('finds right widget before boundary', (WidgetTester tester) async {
=======
    testWidgetsWithLeakTracking('finds right widget before boundary', (WidgetTester tester) async {
>>>>>>> db7ef5bf9f59442b0e200a90587e8fa5e0c6336a
      Widget? containerThroughBoundary;
      Widget? containerStoppedAtBoundary;

      final Key outerContainerKey = UniqueKey();
      final Key innerContainerKey = UniqueKey();

      await tester.pumpWidget(Container(
        key: outerContainerKey,
        child: LookupBoundary(
          child: Container(
            padding: const EdgeInsets.all(10),
            color: Colors.blue,
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
        ),
      ));

      expect(containerThroughBoundary, equals(tester.widget(find.byKey(innerContainerKey))));
      expect(containerStoppedAtBoundary, equals(tester.widget(find.byKey(innerContainerKey))));
    });

<<<<<<< HEAD
    testWidgets('works if nothing is found', (WidgetTester tester) async {
=======
    testWidgetsWithLeakTracking('works if nothing is found', (WidgetTester tester) async {
>>>>>>> db7ef5bf9f59442b0e200a90587e8fa5e0c6336a
      Widget? containerStoppedAtBoundary;

      await tester.pumpWidget(Builder(
        builder: (BuildContext context) {
          containerStoppedAtBoundary = LookupBoundary.findAncestorWidgetOfExactType<Container>(context);
          return const SizedBox.expand();
        },
      ));

      expect(containerStoppedAtBoundary, isNull);
    });

<<<<<<< HEAD
    testWidgets('does not establish a dependency', (WidgetTester tester) async {
=======
    testWidgetsWithLeakTracking('does not establish a dependency', (WidgetTester tester) async {
>>>>>>> db7ef5bf9f59442b0e200a90587e8fa5e0c6336a
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
  });

  group('LookupBoundary.findAncestorStateOfType', () {
<<<<<<< HEAD
    testWidgets('respects boundary', (WidgetTester tester) async {
=======
    testWidgetsWithLeakTracking('respects boundary', (WidgetTester tester) async {
>>>>>>> db7ef5bf9f59442b0e200a90587e8fa5e0c6336a
      State? containerThroughBoundary;
      State? containerStoppedAtBoundary;

      final Key containerKey = UniqueKey();

      await tester.pumpWidget(MyStatefulContainer(
        key: containerKey,
        child: LookupBoundary(
          child: Builder(
            builder: (BuildContext context) {
              containerThroughBoundary = context.findAncestorStateOfType<MyStatefulContainerState>();
              containerStoppedAtBoundary = LookupBoundary.findAncestorStateOfType<MyStatefulContainerState>(context);
              return const SizedBox.expand();
            },
          ),
        ),
      ));

      expect(containerThroughBoundary, equals(tester.state(find.byKey(containerKey))));
      expect(containerStoppedAtBoundary, isNull);
    });

<<<<<<< HEAD
    testWidgets('finds right widget before boundary', (WidgetTester tester) async {
=======
    testWidgetsWithLeakTracking('finds right widget before boundary', (WidgetTester tester) async {
>>>>>>> db7ef5bf9f59442b0e200a90587e8fa5e0c6336a
      State? containerThroughBoundary;
      State? containerStoppedAtBoundary;

      final Key outerContainerKey = UniqueKey();
      final Key innerContainerKey = UniqueKey();

      await tester.pumpWidget(MyStatefulContainer(
        key: outerContainerKey,
        child: LookupBoundary(
          child: MyStatefulContainer(
            child: MyStatefulContainer(
              key: innerContainerKey,
              child: Builder(
                builder: (BuildContext context) {
                  containerThroughBoundary = context.findAncestorStateOfType<MyStatefulContainerState>();
                  containerStoppedAtBoundary = LookupBoundary.findAncestorStateOfType<MyStatefulContainerState>(context);
                  return const SizedBox.expand();
                },
              ),
            ),
          ),
        ),
      ));

      expect(containerThroughBoundary, equals(tester.state(find.byKey(innerContainerKey))));
      expect(containerStoppedAtBoundary, equals(tester.state(find.byKey(innerContainerKey))));
    });

<<<<<<< HEAD
    testWidgets('works if nothing is found', (WidgetTester tester) async {
=======
    testWidgetsWithLeakTracking('works if nothing is found', (WidgetTester tester) async {
>>>>>>> db7ef5bf9f59442b0e200a90587e8fa5e0c6336a
      State? containerStoppedAtBoundary;

      await tester.pumpWidget(Builder(
        builder: (BuildContext context) {
          containerStoppedAtBoundary = LookupBoundary.findAncestorStateOfType<MyStatefulContainerState>(context);
          return const SizedBox.expand();
        },
      ));

      expect(containerStoppedAtBoundary, isNull);
    });

<<<<<<< HEAD
    testWidgets('does not establish a dependency', (WidgetTester tester) async {
=======
    testWidgetsWithLeakTracking('does not establish a dependency', (WidgetTester tester) async {
>>>>>>> db7ef5bf9f59442b0e200a90587e8fa5e0c6336a
      State? containerThroughBoundary;
      State? containerStoppedAtBoundary;
      State? containerStoppedAtBoundaryUnfulfilled;

      final Key innerContainerKey = UniqueKey();
      final Key globalKey = GlobalKey();

      final Widget widgetTree = LookupBoundary(
        child: MyStatefulContainer(
          key: innerContainerKey,
          child: DidChangeDependencySpy(
            key: globalKey,
            onDidChangeDependencies: (BuildContext context) {
              containerThroughBoundary = context.findAncestorStateOfType<MyStatefulContainerState>();
              containerStoppedAtBoundary = LookupBoundary.findAncestorStateOfType<MyStatefulContainerState>(context);
              containerStoppedAtBoundaryUnfulfilled = LookupBoundary.findAncestorStateOfType<MyOtherStatefulContainerState>(context);
            },
          ),
        ),
      );

      await tester.pumpWidget(widgetTree);

      expect(containerThroughBoundary, equals(tester.state(find.byKey(innerContainerKey))));
      expect(containerStoppedAtBoundary, equals(tester.state(find.byKey(innerContainerKey))));
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
  });

  group('LookupBoundary.findRootAncestorStateOfType', () {
<<<<<<< HEAD
    testWidgets('respects boundary', (WidgetTester tester) async {
=======
    testWidgetsWithLeakTracking('respects boundary', (WidgetTester tester) async {
>>>>>>> db7ef5bf9f59442b0e200a90587e8fa5e0c6336a
      State? containerThroughBoundary;
      State? containerStoppedAtBoundary;

      final Key containerKey = UniqueKey();

      await tester.pumpWidget(MyStatefulContainer(
        key: containerKey,
        child: LookupBoundary(
          child: Builder(
            builder: (BuildContext context) {
              containerThroughBoundary = context.findRootAncestorStateOfType<MyStatefulContainerState>();
              containerStoppedAtBoundary = LookupBoundary.findRootAncestorStateOfType<MyStatefulContainerState>(context);
              return const SizedBox.expand();
            },
          ),
        ),
      ));

      expect(containerThroughBoundary, equals(tester.state(find.byKey(containerKey))));
      expect(containerStoppedAtBoundary, isNull);
    });

<<<<<<< HEAD
    testWidgets('finds right widget before boundary', (WidgetTester tester) async {
=======
    testWidgetsWithLeakTracking('finds right widget before boundary', (WidgetTester tester) async {
>>>>>>> db7ef5bf9f59442b0e200a90587e8fa5e0c6336a
      State? containerThroughBoundary;
      State? containerStoppedAtBoundary;

      final Key outerContainerKey = UniqueKey();
      final Key innerContainerKey = UniqueKey();

      await tester.pumpWidget(MyStatefulContainer(
        key: outerContainerKey,
        child: LookupBoundary(
          child: MyStatefulContainer(
            key: innerContainerKey,
            child: MyStatefulContainer(
              child: Builder(
                builder: (BuildContext context) {
                  containerThroughBoundary = context.findRootAncestorStateOfType<MyStatefulContainerState>();
                  containerStoppedAtBoundary = LookupBoundary.findRootAncestorStateOfType<MyStatefulContainerState>(context);
                  return const SizedBox.expand();
                },
              ),
            ),
          ),
        ),
      ));

      expect(containerThroughBoundary, equals(tester.state(find.byKey(outerContainerKey))));
      expect(containerStoppedAtBoundary, equals(tester.state(find.byKey(innerContainerKey))));
    });

<<<<<<< HEAD
    testWidgets('works if nothing is found', (WidgetTester tester) async {
=======
    testWidgetsWithLeakTracking('works if nothing is found', (WidgetTester tester) async {
>>>>>>> db7ef5bf9f59442b0e200a90587e8fa5e0c6336a
      State? containerStoppedAtBoundary;

      await tester.pumpWidget(Builder(
        builder: (BuildContext context) {
          containerStoppedAtBoundary = LookupBoundary.findRootAncestorStateOfType<MyStatefulContainerState>(context);
          return const SizedBox.expand();
        },
      ));

      expect(containerStoppedAtBoundary, isNull);
    });

<<<<<<< HEAD
    testWidgets('does not establish a dependency', (WidgetTester tester) async {
=======
    testWidgetsWithLeakTracking('does not establish a dependency', (WidgetTester tester) async {
>>>>>>> db7ef5bf9f59442b0e200a90587e8fa5e0c6336a
      State? containerThroughBoundary;
      State? containerStoppedAtBoundary;
      State? containerStoppedAtBoundaryUnfulfilled;

      final Key innerContainerKey = UniqueKey();
      final Key globalKey = GlobalKey();

      final Widget widgetTree = LookupBoundary(
        child: MyStatefulContainer(
          key: innerContainerKey,
          child: DidChangeDependencySpy(
            key: globalKey,
            onDidChangeDependencies: (BuildContext context) {
              containerThroughBoundary = context.findRootAncestorStateOfType<MyStatefulContainerState>();
              containerStoppedAtBoundary = LookupBoundary.findRootAncestorStateOfType<MyStatefulContainerState>(context);
              containerStoppedAtBoundaryUnfulfilled = LookupBoundary.findRootAncestorStateOfType<MyOtherStatefulContainerState>(context);
            },
          ),
        ),
      );

      await tester.pumpWidget(widgetTree);

      expect(containerThroughBoundary, equals(tester.state(find.byKey(innerContainerKey))));
      expect(containerStoppedAtBoundary, equals(tester.state(find.byKey(innerContainerKey))));
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
  });

  group('LookupBoundary.findAncestorRenderObjectOfType', () {
<<<<<<< HEAD
    testWidgets('respects boundary', (WidgetTester tester) async {
=======
    testWidgetsWithLeakTracking('respects boundary', (WidgetTester tester) async {
>>>>>>> db7ef5bf9f59442b0e200a90587e8fa5e0c6336a
      RenderPadding? paddingThroughBoundary;
      RenderPadding? passingStoppedAtBoundary;

      final Key paddingKey = UniqueKey();

      await tester.pumpWidget(Padding(
        padding: EdgeInsets.zero,
        key: paddingKey,
        child: LookupBoundary(
          child: Builder(
            builder: (BuildContext context) {
              paddingThroughBoundary = context.findAncestorRenderObjectOfType<RenderPadding>();
              passingStoppedAtBoundary = LookupBoundary.findAncestorRenderObjectOfType<RenderPadding>(context);
              return const SizedBox.expand();
            },
          ),
        ),
      ));

      expect(paddingThroughBoundary, equals(tester.renderObject(find.byKey(paddingKey))));
      expect(passingStoppedAtBoundary, isNull);
    });

<<<<<<< HEAD
    testWidgets('finds right widget before boundary', (WidgetTester tester) async {
=======
    testWidgetsWithLeakTracking('finds right widget before boundary', (WidgetTester tester) async {
>>>>>>> db7ef5bf9f59442b0e200a90587e8fa5e0c6336a
      RenderPadding? paddingThroughBoundary;
      RenderPadding? paddingStoppedAtBoundary;

      final Key outerPaddingKey = UniqueKey();
      final Key innerPaddingKey = UniqueKey();

      await tester.pumpWidget(Padding(
        padding: EdgeInsets.zero,
        key: outerPaddingKey,
        child: LookupBoundary(
          child: Padding(
            padding: EdgeInsets.zero,
            child: Padding(
              padding: EdgeInsets.zero,
              key: innerPaddingKey,
              child: Builder(
                builder: (BuildContext context) {
                  paddingThroughBoundary = context.findAncestorRenderObjectOfType<RenderPadding>();
                  paddingStoppedAtBoundary = LookupBoundary.findAncestorRenderObjectOfType<RenderPadding>(context);
                  return const SizedBox.expand();
                },
              ),
            ),
          ),
        ),
      ));

      expect(paddingThroughBoundary, equals(tester.renderObject(find.byKey(innerPaddingKey))));
      expect(paddingStoppedAtBoundary, equals(tester.renderObject(find.byKey(innerPaddingKey))));
    });

<<<<<<< HEAD
    testWidgets('works if nothing is found', (WidgetTester tester) async {
=======
    testWidgetsWithLeakTracking('works if nothing is found', (WidgetTester tester) async {
>>>>>>> db7ef5bf9f59442b0e200a90587e8fa5e0c6336a
      RenderPadding? paddingStoppedAtBoundary;

      await tester.pumpWidget(Builder(
        builder: (BuildContext context) {
          paddingStoppedAtBoundary = LookupBoundary.findAncestorRenderObjectOfType<RenderPadding>(context);
          return const SizedBox.expand();
        },
      ));

      expect(paddingStoppedAtBoundary, isNull);
    });

<<<<<<< HEAD
    testWidgets('does not establish a dependency', (WidgetTester tester) async {
=======
    testWidgetsWithLeakTracking('does not establish a dependency', (WidgetTester tester) async {
>>>>>>> db7ef5bf9f59442b0e200a90587e8fa5e0c6336a
      RenderPadding? paddingThroughBoundary;
      RenderPadding? paddingStoppedAtBoundary;
      RenderWrap? wrapStoppedAtBoundaryUnfulfilled;

      final Key innerPaddingKey = UniqueKey();
      final Key globalKey = GlobalKey();

      final Widget widgetTree = LookupBoundary(
        child: Padding(
          padding: EdgeInsets.zero,
          key: innerPaddingKey,
          child: DidChangeDependencySpy(
            key: globalKey,
            onDidChangeDependencies: (BuildContext context) {
              paddingThroughBoundary = context.findAncestorRenderObjectOfType<RenderPadding>();
              paddingStoppedAtBoundary = LookupBoundary.findAncestorRenderObjectOfType<RenderPadding>(context);
              wrapStoppedAtBoundaryUnfulfilled = LookupBoundary.findAncestorRenderObjectOfType<RenderWrap>(context);
            },
          ),
        ),
      );

      await tester.pumpWidget(widgetTree);

      expect(paddingThroughBoundary, equals(tester.renderObject(find.byKey(innerPaddingKey))));
      expect(paddingStoppedAtBoundary, equals(tester.renderObject(find.byKey(innerPaddingKey))));
      expect(wrapStoppedAtBoundaryUnfulfilled, isNull);
      expect(tester.state<_DidChangeDependencySpyState>(find.byType(DidChangeDependencySpy)).didChangeDependenciesCount, 1);

      await tester.pumpWidget(
        SizedBox( // Changes tree structure, triggers global key move of DidChangeDependencySpy.
          child: widgetTree,
        ),
      );

      // Tree restructuring above would have called didChangeDependencies if dependency had been established.
      expect(tester.state<_DidChangeDependencySpyState>(find.byType(DidChangeDependencySpy)).didChangeDependenciesCount, 1);
    });
  });

  group('LookupBoundary.visitAncestorElements', () {
<<<<<<< HEAD
    testWidgets('respects boundary', (WidgetTester tester) async {
=======
    testWidgetsWithLeakTracking('respects boundary', (WidgetTester tester) async {
>>>>>>> db7ef5bf9f59442b0e200a90587e8fa5e0c6336a
      final List<Element> throughBoundary = <Element>[];
      final List<Element> stoppedAtBoundary = <Element>[];
      final List<Element> stoppedAtBoundaryTerminatedEarly = <Element>[];

      final Key level0 = UniqueKey();
      final Key level1 = UniqueKey();
      final Key level2 = UniqueKey();
      final Key level3 = UniqueKey();
      final Key level4 = UniqueKey();

      await tester.pumpWidget(Container(
        key: level0,
        child: Container(
          key: level1,
          child: LookupBoundary(
            key: level2,
            child: Container(
              key: level3,
              child: Container(
                key: level4,
                child: Builder(
                  builder: (BuildContext context) {
                    context.visitAncestorElements((Element element) {
                      throughBoundary.add(element);
                      return element.widget.key != level0;
                    });
                    LookupBoundary.visitAncestorElements(context, (Element element) {
                      stoppedAtBoundary.add(element);
                      return element.widget.key != level0;
                    });
                    LookupBoundary.visitAncestorElements(context, (Element element) {
                      stoppedAtBoundaryTerminatedEarly.add(element);
                      return element.widget.key != level3;
                    });
                    return const SizedBox();
                  }
                )
              )
            )
          )
        ),
      ));

      expect(throughBoundary, <Element>[
        tester.element(find.byKey(level4)),
        tester.element(find.byKey(level3)),
        tester.element(find.byKey(level2)),
        tester.element(find.byKey(level1)),
        tester.element(find.byKey(level0)),
      ]);

      expect(stoppedAtBoundary, <Element>[
        tester.element(find.byKey(level4)),
        tester.element(find.byKey(level3)),
        tester.element(find.byKey(level2)),
      ]);

      expect(stoppedAtBoundaryTerminatedEarly, <Element>[
        tester.element(find.byKey(level4)),
        tester.element(find.byKey(level3)),
      ]);
    });
  });

  group('LookupBoundary.visitChildElements', () {
<<<<<<< HEAD
    testWidgets('respects boundary', (WidgetTester tester) async {
=======
    testWidgetsWithLeakTracking('respects boundary', (WidgetTester tester) async {
>>>>>>> db7ef5bf9f59442b0e200a90587e8fa5e0c6336a
      final Key root = UniqueKey();
      final Key child1 = UniqueKey();
      final Key child2 = UniqueKey();
      final Key child3 = UniqueKey();

      await tester.pumpWidget(Column(
        key: root,
        children: <Widget>[
          LookupBoundary(
            key: child1,
            child: Container(),
          ),
          Container(
            key: child2,
            child: LookupBoundary(
              child: Container(),
            ),
          ),
          Container(
            key: child3,
          ),
        ],
      ));

      final List<Element> throughBoundary = <Element>[];
      final List<Element> stoppedAtBoundary = <Element>[];

      final BuildContext context = tester.element(find.byKey(root));

      context.visitChildElements((Element element) {
        throughBoundary.add(element);
      });
      LookupBoundary.visitChildElements(context, (Element element) {
        stoppedAtBoundary.add(element);
      });

      expect(throughBoundary, <Element>[
        tester.element(find.byKey(child1)),
        tester.element(find.byKey(child2)),
        tester.element(find.byKey(child3)),
      ]);

      expect(stoppedAtBoundary, <Element>[
        tester.element(find.byKey(child2)),
        tester.element(find.byKey(child3)),
      ]);

    });
  });

  group('LookupBoundary.debugIsHidingAncestorWidgetOfExactType', () {
<<<<<<< HEAD
    testWidgets('is hiding', (WidgetTester tester) async {
=======
    testWidgetsWithLeakTracking('is hiding', (WidgetTester tester) async {
>>>>>>> db7ef5bf9f59442b0e200a90587e8fa5e0c6336a
      bool? isHidden;
      await tester.pumpWidget(Container(
        padding: const EdgeInsets.all(10),
        color: Colors.blue,
        child: LookupBoundary(
          child: Builder(
            builder: (BuildContext context) {
              isHidden = LookupBoundary.debugIsHidingAncestorWidgetOfExactType<Container>(context);
              return Container();
            },
          ),
        ),
      ));
      expect(isHidden, isTrue);
    });

<<<<<<< HEAD
    testWidgets('is not hiding entity within boundary', (WidgetTester tester) async {
=======
    testWidgetsWithLeakTracking('is not hiding entity within boundary', (WidgetTester tester) async {
>>>>>>> db7ef5bf9f59442b0e200a90587e8fa5e0c6336a
      bool? isHidden;
      await tester.pumpWidget(Container(
        padding: const EdgeInsets.all(10),
        color: Colors.blue,
        child: LookupBoundary(
          child: Container(
            padding: const EdgeInsets.all(10),
            color: Colors.red,
            child: Builder(
              builder: (BuildContext context) {
                isHidden = LookupBoundary.debugIsHidingAncestorWidgetOfExactType<Container>(context);
                return Container();
              },
            ),
          ),
        ),
      ));
      expect(isHidden, isFalse);
    });

<<<<<<< HEAD
    testWidgets('is not hiding if no boundary exists', (WidgetTester tester) async {
=======
    testWidgetsWithLeakTracking('is not hiding if no boundary exists', (WidgetTester tester) async {
>>>>>>> db7ef5bf9f59442b0e200a90587e8fa5e0c6336a
      bool? isHidden;
      await tester.pumpWidget(Container(
        padding: const EdgeInsets.all(10),
        color: Colors.blue,
        child: Builder(
          builder: (BuildContext context) {
            isHidden = LookupBoundary.debugIsHidingAncestorWidgetOfExactType<Container>(context);
            return Container();
          },
        ),
      ));
      expect(isHidden, isFalse);
    });

<<<<<<< HEAD
    testWidgets('is not hiding if no boundary and no entity exists', (WidgetTester tester) async {
=======
    testWidgetsWithLeakTracking('is not hiding if no boundary and no entity exists', (WidgetTester tester) async {
>>>>>>> db7ef5bf9f59442b0e200a90587e8fa5e0c6336a
      bool? isHidden;
      await tester.pumpWidget(Builder(
        builder: (BuildContext context) {
          isHidden = LookupBoundary.debugIsHidingAncestorWidgetOfExactType<Container>(context);
          return Container();
        },
      ));
      expect(isHidden, isFalse);
    });
  });

  group('LookupBoundary.debugIsHidingAncestorStateOfType', () {
<<<<<<< HEAD
    testWidgets('is hiding', (WidgetTester tester) async {
=======
    testWidgetsWithLeakTracking('is hiding', (WidgetTester tester) async {
>>>>>>> db7ef5bf9f59442b0e200a90587e8fa5e0c6336a
      bool? isHidden;
      await tester.pumpWidget(MyStatefulContainer(
        child: LookupBoundary(
          child: Builder(
            builder: (BuildContext context) {
              isHidden = LookupBoundary.debugIsHidingAncestorStateOfType<MyStatefulContainerState>(context);
              return Container();
            },
          ),
        ),
      ));
      expect(isHidden, isTrue);
    });

<<<<<<< HEAD
    testWidgets('is not hiding entity within boundary', (WidgetTester tester) async {
=======
    testWidgetsWithLeakTracking('is not hiding entity within boundary', (WidgetTester tester) async {
>>>>>>> db7ef5bf9f59442b0e200a90587e8fa5e0c6336a
      bool? isHidden;
      await tester.pumpWidget(MyStatefulContainer(
        child: LookupBoundary(
          child: MyStatefulContainer(
            child: Builder(
              builder: (BuildContext context) {
                isHidden = LookupBoundary.debugIsHidingAncestorStateOfType<MyStatefulContainerState>(context);
                return Container();
              },
            ),
          ),
        ),
      ));
      expect(isHidden, isFalse);
    });

<<<<<<< HEAD
    testWidgets('is not hiding if no boundary exists', (WidgetTester tester) async {
=======
    testWidgetsWithLeakTracking('is not hiding if no boundary exists', (WidgetTester tester) async {
>>>>>>> db7ef5bf9f59442b0e200a90587e8fa5e0c6336a
      bool? isHidden;
      await tester.pumpWidget(MyStatefulContainer(
        child: Builder(
          builder: (BuildContext context) {
            isHidden = LookupBoundary.debugIsHidingAncestorStateOfType<MyStatefulContainerState>(context);
            return Container();
          },
        ),
      ));
      expect(isHidden, isFalse);
    });

<<<<<<< HEAD
    testWidgets('is not hiding if no boundary and no entity exists', (WidgetTester tester) async {
=======
    testWidgetsWithLeakTracking('is not hiding if no boundary and no entity exists', (WidgetTester tester) async {
>>>>>>> db7ef5bf9f59442b0e200a90587e8fa5e0c6336a
      bool? isHidden;
      await tester.pumpWidget(Builder(
        builder: (BuildContext context) {
          isHidden = LookupBoundary.debugIsHidingAncestorStateOfType<MyStatefulContainerState>(context);
          return Container();
        },
      ));
      expect(isHidden, isFalse);
    });
  });

  group('LookupBoundary.debugIsHidingAncestorRenderObjectOfType', () {
<<<<<<< HEAD
    testWidgets('is hiding', (WidgetTester tester) async {
=======
    testWidgetsWithLeakTracking('is hiding', (WidgetTester tester) async {
>>>>>>> db7ef5bf9f59442b0e200a90587e8fa5e0c6336a
      bool? isHidden;
      await tester.pumpWidget(Padding(
        padding: EdgeInsets.zero,
        child: LookupBoundary(
          child: Builder(
            builder: (BuildContext context) {
              isHidden = LookupBoundary.debugIsHidingAncestorRenderObjectOfType<RenderPadding>(context);
              return Container();
            },
          ),
        ),
      ));
      expect(isHidden, isTrue);
    });

<<<<<<< HEAD
    testWidgets('is not hiding entity within boundary', (WidgetTester tester) async {
=======
    testWidgetsWithLeakTracking('is not hiding entity within boundary', (WidgetTester tester) async {
>>>>>>> db7ef5bf9f59442b0e200a90587e8fa5e0c6336a
      bool? isHidden;
      await tester.pumpWidget(Padding(
        padding: EdgeInsets.zero,
        child: LookupBoundary(
          child: Padding(
            padding: EdgeInsets.zero,
            child: Builder(
              builder: (BuildContext context) {
                isHidden = LookupBoundary.debugIsHidingAncestorRenderObjectOfType<RenderPadding>(context);
                return Container();
              },
            ),
          ),
        ),
      ));
      expect(isHidden, isFalse);
    });

<<<<<<< HEAD
    testWidgets('is not hiding if no boundary exists', (WidgetTester tester) async {
=======
    testWidgetsWithLeakTracking('is not hiding if no boundary exists', (WidgetTester tester) async {
>>>>>>> db7ef5bf9f59442b0e200a90587e8fa5e0c6336a
      bool? isHidden;
      await tester.pumpWidget(Padding(
        padding: EdgeInsets.zero,
        child: Builder(
          builder: (BuildContext context) {
            isHidden = LookupBoundary.debugIsHidingAncestorRenderObjectOfType<RenderPadding>(context);
            return Container();
          },
        ),
      ));
      expect(isHidden, isFalse);
    });

<<<<<<< HEAD
    testWidgets('is not hiding if no boundary and no entity exists', (WidgetTester tester) async {
=======
    testWidgetsWithLeakTracking('is not hiding if no boundary and no entity exists', (WidgetTester tester) async {
>>>>>>> db7ef5bf9f59442b0e200a90587e8fa5e0c6336a
      bool? isHidden;
      await tester.pumpWidget(Builder(
        builder: (BuildContext context) {
          isHidden = LookupBoundary.debugIsHidingAncestorRenderObjectOfType<RenderPadding>(context);
          return Container();
        },
      ));
      expect(isHidden, isFalse);
    });
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

class MyOtherStatefulContainerState extends State<MyStatefulContainer> {
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
