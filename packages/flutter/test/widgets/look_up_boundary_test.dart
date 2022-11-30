// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('findAncestorWidgetOfExactType respects stopAtLookUpBoundary', (WidgetTester tester) async {
    Widget? containerThroughBoundary;
    Widget? containerStoppedAtBoundary;
    Widget? boundaryThroughBoundary;
    Widget? boundaryStoppedAtBoundary;

    final Key containerKey = UniqueKey();
    final Key boundaryKey = UniqueKey();

    await tester.pumpWidget(Container(
      key: containerKey,
      child: MyStatelessLookupBoundary(
        key: boundaryKey,
        child: Builder(
          builder: (BuildContext context) {
            containerThroughBoundary = context.findAncestorWidgetOfExactType<Container>();
            containerStoppedAtBoundary = context.findAncestorWidgetOfExactType<Container>(stopAtLookUpBoundary: true);
            boundaryThroughBoundary = context.findAncestorWidgetOfExactType<MyStatelessLookupBoundary>();
            boundaryStoppedAtBoundary = context.findAncestorWidgetOfExactType<MyStatelessLookupBoundary>(stopAtLookUpBoundary: true);
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

  testWidgets('findAncestorWidgetOfExactType finds widget before boundary', (WidgetTester tester) async {
    Widget? containerThroughBoundary;
    Widget? containerStoppedAtBoundary;

    final Key innerContainerKey = UniqueKey();

    await tester.pumpWidget(Container(
      child: MyStatelessLookupBoundary(
        child: Container(
          key: innerContainerKey,
          child: Builder(
            builder: (BuildContext context) {
              containerThroughBoundary = context.findAncestorWidgetOfExactType<Container>();
              containerStoppedAtBoundary = context.findAncestorWidgetOfExactType<Container>(stopAtLookUpBoundary: true);
              return const SizedBox.expand();
            },
          ),
        ),
      ),
    ));

    expect(containerThroughBoundary, equals(tester.widget(find.byKey(innerContainerKey))));
    expect(containerStoppedAtBoundary, equals(tester.widget(find.byKey(innerContainerKey))));
  });

  testWidgets('findAncestorStateOfType respects stopAtLookUpBoundary', (WidgetTester tester) async {
    State? containerThroughBoundary;
    State? containerStoppedAtBoundary;
    State? boundaryThroughBoundary;
    State? boundaryStoppedAtBoundary;

    final Key containerKey = UniqueKey();
    final Key boundaryKey = UniqueKey();

    await tester.pumpWidget(MyStatefulContainer(
      key: containerKey,
      child: MyStatefulLookupBoundary(
        key: boundaryKey,
        child: Builder(
          builder: (BuildContext context) {
            containerThroughBoundary = context.findAncestorStateOfType<_MyStatefulContainerState>();
            containerStoppedAtBoundary = context.findAncestorStateOfType<_MyStatefulContainerState>(stopAtLookUpBoundary: true);
            boundaryThroughBoundary = context.findAncestorStateOfType<MyStatefulLookupBoundaryState>();
            boundaryStoppedAtBoundary = context.findAncestorStateOfType<MyStatefulLookupBoundaryState>(stopAtLookUpBoundary: true);
            return const SizedBox.expand();
          },
        ),
      ),
    ));

    expect(containerThroughBoundary, equals(tester.state(find.byKey(containerKey))));
    expect(containerStoppedAtBoundary, isNull);
    expect(boundaryThroughBoundary, equals(tester.state(find.byKey(boundaryKey))));
    expect(boundaryStoppedAtBoundary, equals(tester.state(find.byKey(boundaryKey))));
  });

  testWidgets('findAncestorStateOfType finds state before boundary', (WidgetTester tester) async {
    State? containerThroughBoundary;
    State? containerStoppedAtBoundary;

    final Key innerKey = UniqueKey();

    await tester.pumpWidget(MyStatefulContainer(
      child: MyStatefulLookupBoundary(
        child: MyStatefulContainer(
          key: innerKey,
          child: Builder(
            builder: (BuildContext context) {
              containerThroughBoundary = context.findAncestorStateOfType<_MyStatefulContainerState>();
              containerStoppedAtBoundary = context.findAncestorStateOfType<_MyStatefulContainerState>(stopAtLookUpBoundary: true);
              return const SizedBox.expand();
            },
          ),
        ),
      ),
    ));

    expect(containerThroughBoundary, equals(tester.state(find.byKey(innerKey))));
    expect(containerStoppedAtBoundary, equals(tester.state(find.byKey(innerKey))));
  });

  testWidgets('findAncestorRenderObjectOfType respects stopAtLookUpBoundary', (WidgetTester tester) async {
    RenderObject? containerThroughBoundary;
    RenderObject? containerStoppedAtBoundary;
    RenderObject? boundaryThroughBoundary;
    RenderObject? boundaryStoppedAtBoundary;

    final Key containerKey = UniqueKey();
    final Key boundaryKey = UniqueKey();

    await tester.pumpWidget(SizedBox.expand(
      key: containerKey,
      child: MyRenderObjectWidgetLookupBoundary(
        key: boundaryKey,
        child: Builder(
          builder: (BuildContext context) {
            containerThroughBoundary = context.findAncestorRenderObjectOfType<RenderConstrainedBox>();
            containerStoppedAtBoundary = context.findAncestorRenderObjectOfType<RenderConstrainedBox>(stopAtLookUpBoundary: true);
            boundaryThroughBoundary = context.findAncestorRenderObjectOfType<RenderPadding>();
            boundaryStoppedAtBoundary = context.findAncestorRenderObjectOfType<RenderPadding>(stopAtLookUpBoundary: true);
            return const SizedBox.expand();
          },
        ),
      ),
    ));

    expect(containerThroughBoundary, equals(tester.renderObject(find.byKey(containerKey))));
    expect(containerStoppedAtBoundary, isNull);
    expect(boundaryThroughBoundary, equals(tester.renderObject(find.byKey(boundaryKey))));
    expect(boundaryStoppedAtBoundary, equals(tester.renderObject(find.byKey(boundaryKey))));
  });

  testWidgets('findAncestorRenderObjectOfType finds render object before boundary', (WidgetTester tester) async {
    RenderObject? containerThroughBoundary;
    RenderObject? containerStoppedAtBoundary;

    final Key innerKey = UniqueKey();

    await tester.pumpWidget(SizedBox.expand(
      child: MyRenderObjectWidgetLookupBoundary(
        child: SizedBox.expand(
          key: innerKey,
          child: Builder(
            builder: (BuildContext context) {
              containerThroughBoundary = context.findAncestorRenderObjectOfType<RenderConstrainedBox>();
              containerStoppedAtBoundary = context.findAncestorRenderObjectOfType<RenderConstrainedBox>(stopAtLookUpBoundary: true);
              return const SizedBox.expand();
            },
          ),
        ),
      ),
    ));

    expect(containerThroughBoundary, equals(tester.renderObject(find.byKey(innerKey))));
    expect(containerStoppedAtBoundary, equals(tester.renderObject(find.byKey(innerKey))));
  });

  ///

  testWidgets('findRootAncestorStateOfType respects stopAtLookUpBoundary', (WidgetTester tester) async {
    State? containerThroughBoundary;
    State? containerStoppedAtBoundary;
    State? boundaryThroughBoundary;
    State? boundaryStoppedAtBoundary;

    final Key rootContainerKey = UniqueKey();
    final Key rootBoundaryKey = UniqueKey();
    final Key innerBoundaryKey = UniqueKey();

    await tester.pumpWidget(MyStatefulContainer(
      key: rootContainerKey,
      child: MyStatefulLookupBoundary(
        key: rootBoundaryKey,
        child: MyStatefulContainer(
          child: MyStatefulLookupBoundary(
            key: innerBoundaryKey,
            child: Builder(
              builder: (BuildContext context) {
                containerThroughBoundary = context.findRootAncestorStateOfType<_MyStatefulContainerState>();
                containerStoppedAtBoundary = context.findRootAncestorStateOfType<_MyStatefulContainerState>(stopAtLookUpBoundary: true);
                boundaryThroughBoundary = context.findRootAncestorStateOfType<MyStatefulLookupBoundaryState>();
                boundaryStoppedAtBoundary = context.findRootAncestorStateOfType<MyStatefulLookupBoundaryState>(stopAtLookUpBoundary: true);
                return const SizedBox.expand();
              },
            ),
          ),
        ),
      ),
    ));

    expect(containerThroughBoundary, equals(tester.state(find.byKey(rootContainerKey))));
    expect(containerStoppedAtBoundary, isNull);
    expect(boundaryThroughBoundary, equals(tester.state(find.byKey(rootBoundaryKey))));
    expect(boundaryStoppedAtBoundary, equals(tester.state(find.byKey(innerBoundaryKey))));
  });

  testWidgets('findRootAncestorStateOfType finds state before boundary', (WidgetTester tester) async {
    State? containerThroughBoundary;
    State? containerStoppedAtBoundary;

    final Key outerRootKey = UniqueKey();
    final Key innerRootKey = UniqueKey();

    await tester.pumpWidget(MyStatefulContainer(
      key: outerRootKey,
      child: MyStatefulLookupBoundary(
        child: MyStatefulContainer(
          key: innerRootKey,
          child: MyStatefulContainer(
            child: Builder(
              builder: (BuildContext context) {
                containerThroughBoundary = context.findRootAncestorStateOfType<_MyStatefulContainerState>();
                containerStoppedAtBoundary = context.findRootAncestorStateOfType<_MyStatefulContainerState>(stopAtLookUpBoundary: true);
                return const SizedBox.expand();
              },
            ),
          ),
        ),
      ),
    ));

    expect(containerThroughBoundary, equals(tester.state(find.byKey(outerRootKey))));
    expect(containerStoppedAtBoundary, equals(tester.state(find.byKey(innerRootKey))));
  });
}

class MyStatelessLookupBoundary extends StatelessWidget {
  const MyStatelessLookupBoundary({super.key, required this.child});

  final Widget child;

  @override
  StatelessElement createElement() => MyStatelessLookupBoundaryElement(this);

  @override
  Widget build(BuildContext context) {
    return child;
  }
}

class MyStatelessLookupBoundaryElement extends StatelessElement with LookUpBoundary {
  MyStatelessLookupBoundaryElement(super.widget);
}

class MyStatefulLookupBoundary extends StatefulWidget {
  const MyStatefulLookupBoundary({super.key, required this.child});

  final Widget child;

  @override
  StatefulElement createElement() => MyStatefulLookupBoundaryElement(this);

  @override
  State<StatefulWidget> createState() => MyStatefulLookupBoundaryState();
}

class MyStatefulLookupBoundaryState extends State<MyStatefulLookupBoundary> {
  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

class MyStatefulLookupBoundaryElement extends StatefulElement with LookUpBoundary {
  MyStatefulLookupBoundaryElement(super.widget);
}

class MyStatefulContainer extends StatefulWidget {
  const MyStatefulContainer({super.key, required this.child});

  final Widget child;

  @override
  State<MyStatefulContainer> createState() => _MyStatefulContainerState();
}

class _MyStatefulContainerState extends State<MyStatefulContainer> {
  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

class MyRenderObjectWidgetLookupBoundary extends SingleChildRenderObjectWidget {
  const MyRenderObjectWidgetLookupBoundary({super.key, super.child});

  @override
  SingleChildRenderObjectElement createElement() => MyRenderObjectWidgetLookupBoundaryElement(this);

  @override
  RenderObject createRenderObject(BuildContext context) => RenderPadding(padding: EdgeInsets.zero);
}

class MyRenderObjectWidgetLookupBoundaryElement extends SingleChildRenderObjectElement with LookUpBoundary {
  MyRenderObjectWidgetLookupBoundaryElement(super.widget);
}
