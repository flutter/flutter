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
    transition = tester.widget(find.byType(FadeTransition));
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
    Widget newLayoutBuilder(List<Widget> children) {
      return new Column(
        children: children,
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
    final List<Widget> transitions = <Widget>[];
    Widget newLayoutBuilder(List<Widget> children) {
      transitions.clear();
      transitions.addAll(children);
      return new Column(
        children: children,
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
    for (Widget transition in transitions) {
      expect(transition, const isInstanceOf<KeyedSubtree>());
      expect(
        find.descendant(of: find.byWidget(transition), matching: find.byType(SizeTransition)),
        findsOneWidget,
      );
    }
  });
}
