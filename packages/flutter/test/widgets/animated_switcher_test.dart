// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('AnimatedSwitcher fades in a new child.', (WidgetTester tester) async {
    final UniqueKey containerOne = new UniqueKey();
    final UniqueKey containerTwo = new UniqueKey();
    final UniqueKey containerThree = new UniqueKey();
    await tester.pumpWidget(
      new AnimatedSwitcher(
        duration: const Duration(milliseconds: 100),
        child: new Container(key: containerOne, color: const Color(0x00000000)),
        switchInCurve: Curves.linear,
        switchOutCurve: Curves.linear,
      ),
    );

    expect(find.byType(FadeTransition), findsOneWidget);
    FadeTransition transition = tester.firstWidget(find.byType(FadeTransition));
    expect(transition.opacity.value, equals(1.0));

    await tester.pumpWidget(
      new AnimatedSwitcher(
        duration: const Duration(milliseconds: 100),
        child: new Container(key: containerTwo, color: const Color(0xff000000)),
        switchInCurve: Curves.linear,
        switchOutCurve: Curves.linear,
      ),
    );

    await tester.pump(const Duration(milliseconds: 50));
    expect(find.byType(FadeTransition), findsNWidgets(2));
    transition = tester.firstWidget(find.byType(FadeTransition));
    expect(transition.opacity.value, equals(0.5));

    await tester.pumpWidget(
      new AnimatedSwitcher(
        duration: const Duration(milliseconds: 100),
        child: new Container(key: containerThree, color: const Color(0xffff0000)),
        switchInCurve: Curves.linear,
        switchOutCurve: Curves.linear,
      ),
    );

    await tester.pump(const Duration(milliseconds: 10));
    transition = tester.widget(find.byType(FadeTransition).at(0));
    expect(transition.opacity.value, closeTo(0.4, 0.01));
    transition = tester.widget(find.byType(FadeTransition).at(1));
    expect(transition.opacity.value, closeTo(0.4, 0.01));
    transition = tester.widget(find.byType(FadeTransition).at(2));
    expect(transition.opacity.value, closeTo(0.1, 0.01));
    await tester.pumpAndSettle();
  });

  testWidgets("AnimatedSwitcher doesn't transition in a new child of the same type.", (WidgetTester tester) async {
    await tester.pumpWidget(
      new AnimatedSwitcher(
        duration: const Duration(milliseconds: 100),
        child: new Container(color: const Color(0x00000000)),
        switchInCurve: Curves.linear,
        switchOutCurve: Curves.linear,
      ),
    );

    expect(find.byType(FadeTransition), findsOneWidget);
    FadeTransition transition = tester.firstWidget(find.byType(FadeTransition));
    expect(transition.opacity.value, equals(1.0));

    await tester.pumpWidget(
      new AnimatedSwitcher(
        duration: const Duration(milliseconds: 100),
        child: new Container(color: const Color(0xff000000)),
        switchInCurve: Curves.linear,
        switchOutCurve: Curves.linear,
      ),
    );

    await tester.pump(const Duration(milliseconds: 50));
    expect(find.byType(FadeTransition), findsOneWidget);
    transition = tester.firstWidget(find.byType(FadeTransition));
    expect(transition.opacity.value, equals(1.0));
    await tester.pumpAndSettle();
  });

  testWidgets('AnimatedSwitcher handles null children.', (WidgetTester tester) async {
    await tester.pumpWidget(
      const AnimatedSwitcher(
        duration: const Duration(milliseconds: 100),
        child: null,
        switchInCurve: Curves.linear,
        switchOutCurve: Curves.linear,
      ),
    );

    expect(find.byType(FadeTransition), findsNothing);

    await tester.pumpWidget(
      new AnimatedSwitcher(
        duration: const Duration(milliseconds: 100),
        child: new Container(color: const Color(0xff000000)),
        switchInCurve: Curves.linear,
        switchOutCurve: Curves.linear,
      ),
    );

    await tester.pump(const Duration(milliseconds: 50));
    FadeTransition transition = tester.firstWidget(find.byType(FadeTransition));
    expect(transition.opacity.value, equals(0.5));
    await tester.pumpAndSettle();

    await tester.pumpWidget(
      new AnimatedSwitcher(
        duration: const Duration(milliseconds: 100),
        child: new Container(color: const Color(0x00000000)),
        switchInCurve: Curves.linear,
        switchOutCurve: Curves.linear,
      ),
    );

    expect(find.byType(FadeTransition), findsOneWidget);
    transition = tester.firstWidget(find.byType(FadeTransition));
    expect(transition.opacity.value, equals(1.0));

    await tester.pumpWidget(
      const AnimatedSwitcher(
        duration: const Duration(milliseconds: 100),
        child: null,
        switchInCurve: Curves.linear,
        switchOutCurve: Curves.linear,
      ),
    );

    await tester.pump(const Duration(milliseconds: 50));
    transition = tester.firstWidget(find.byType(FadeTransition));
    expect(transition.opacity.value, equals(0.5));

    await tester.pumpWidget(
      const AnimatedSwitcher(
        duration: const Duration(milliseconds: 100),
        child: null,
        switchInCurve: Curves.linear,
        switchOutCurve: Curves.linear,
      ),
    );

    await tester.pump(const Duration(milliseconds: 50));
    transition = tester.firstWidget(find.byType(FadeTransition));
    expect(transition.opacity.value, equals(0.0));

    await tester.pumpAndSettle();
  });

  testWidgets("AnimatedSwitcher doesn't start any animations after dispose.", (WidgetTester tester) async {
    await tester.pumpWidget(new AnimatedSwitcher(
      duration: const Duration(milliseconds: 100),
      child: new Container(color: const Color(0xff000000)),
      switchInCurve: Curves.linear,
    ));
    await tester.pump(const Duration(milliseconds: 50));

    // Change the widget tree in the middle of the animation.
    await tester.pumpWidget(new Container(color: const Color(0xffff0000)));
    expect(await tester.pumpAndSettle(const Duration(milliseconds: 100)), equals(1));
  });

  testWidgets('AnimatedSwitcher uses custom layout.', (WidgetTester tester) async {
    Widget newLayoutBuilder(Widget currentChild, List<Widget> previousChildren) {
      return new Column(
        children: previousChildren + <Widget>[currentChild],
      );
    }

    await tester.pumpWidget(
      new AnimatedSwitcher(
        duration: const Duration(milliseconds: 100),
        child: new Container(color: const Color(0x00000000)),
        switchInCurve: Curves.linear,
        layoutBuilder: newLayoutBuilder,
      ),
    );

    expect(find.byType(Column), findsOneWidget);
  });

  testWidgets('AnimatedSwitcher uses custom transitions.', (WidgetTester tester) async {
    final List<Widget> foundChildren = <Widget>[];
    Widget newLayoutBuilder(Widget currentChild, List<Widget> previousChildren) {
      foundChildren.clear();
      if (currentChild != null)
        foundChildren.add(currentChild);
      foundChildren.addAll(previousChildren);
      return new Column(
        children: previousChildren,
      );
    }

    Widget newTransitionBuilder(Widget child, Animation<double> animation) {
      return new SizeTransition(
        sizeFactor: animation,
        child: child,
      );
    }

    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.rtl,
        child: new AnimatedSwitcher(
          duration: const Duration(milliseconds: 100),
          child: new Container(color: const Color(0x00000000)),
          switchInCurve: Curves.linear,
          layoutBuilder: newLayoutBuilder,
          transitionBuilder: newTransitionBuilder,
        ),
      ),
    );

    expect(find.byType(Column), findsOneWidget);
    for (Widget child in foundChildren) {
      expect(child, const isInstanceOf<KeyedSubtree>());
    }

    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.rtl,
        child: new AnimatedSwitcher(
          duration: const Duration(milliseconds: 100),
          child: null,
          switchInCurve: Curves.linear,
          layoutBuilder: newLayoutBuilder,
          transitionBuilder: newTransitionBuilder,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 50));

    for (Widget child in foundChildren) {
      expect(child, const isInstanceOf<KeyedSubtree>());
      expect(
        find.descendant(of: find.byWidget(child), matching: find.byType(SizeTransition)),
        findsOneWidget,
      );
    }
  });

  testWidgets("AnimatedSwitcher doesn't reset state of the children in transitions.", (WidgetTester tester) async {
    final UniqueKey statefulOne = new UniqueKey();
    final UniqueKey statefulTwo = new UniqueKey();
    final UniqueKey statefulThree = new UniqueKey();

    StatefulTestState.generation = 0;

    await tester.pumpWidget(
      new AnimatedSwitcher(
        duration: const Duration(milliseconds: 100),
        child: new StatefulTest(key: statefulOne),
        switchInCurve: Curves.linear,
        switchOutCurve: Curves.linear,
      ),
    );

    expect(find.byType(FadeTransition), findsOneWidget);
    FadeTransition transition = tester.firstWidget(find.byType(FadeTransition));
    expect(transition.opacity.value, equals(1.0));
    expect(StatefulTestState.generation, equals(1));

    await tester.pumpWidget(
      new AnimatedSwitcher(
        duration: const Duration(milliseconds: 100),
        child: new StatefulTest(key: statefulTwo),
        switchInCurve: Curves.linear,
        switchOutCurve: Curves.linear,
      ),
    );

    await tester.pump(const Duration(milliseconds: 50));
    expect(find.byType(FadeTransition), findsNWidgets(2));
    transition = tester.firstWidget(find.byType(FadeTransition));
    expect(transition.opacity.value, equals(0.5));
    expect(StatefulTestState.generation, equals(2));

    await tester.pumpWidget(
      new AnimatedSwitcher(
        duration: const Duration(milliseconds: 100),
        child: new StatefulTest(key: statefulThree),
        switchInCurve: Curves.linear,
        switchOutCurve: Curves.linear,
      ),
    );

    await tester.pump(const Duration(milliseconds: 10));
    expect(StatefulTestState.generation, equals(3));
    transition = tester.widget(find.byType(FadeTransition).at(0));
    expect(transition.opacity.value, closeTo(0.4, 0.01));
    transition = tester.widget(find.byType(FadeTransition).at(1));
    expect(transition.opacity.value, closeTo(0.4, 0.01));
    transition = tester.widget(find.byType(FadeTransition).at(2));
    expect(transition.opacity.value, closeTo(0.1, 0.01));
    await tester.pumpAndSettle();
    expect(StatefulTestState.generation, equals(3));
  });
}

class StatefulTest extends StatefulWidget {
  const StatefulTest({Key key}) : super(key: key);

  @override
  StatefulTestState createState() => new StatefulTestState();
}

class StatefulTestState extends State<StatefulTest> {
  StatefulTestState();
  static int generation = 0;

  @override
  void initState() {
    super.initState();
    generation++;
  }

  @override
  Widget build(BuildContext context) => new Container();
}