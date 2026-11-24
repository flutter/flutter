// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const targetKey = Key('target');

  // A page with a semantics boundary, a text with an inline widget span, a
  // spacer that controls where the target sits, and a target that forms its
  // own semantics node. An optional BlockSemantics models a modal barrier
  // covering the page.
  Widget buildTest({required double spacerHeight, required bool blocked, required String text}) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(
        textDirection: TextDirection.ltr,
        children: <Widget>[
          Semantics(
            container: true,
            label: 'page',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                RichText(
                  text: TextSpan(
                    text: text,
                    style: const TextStyle(fontSize: 10),
                    children: const <InlineSpan>[WidgetSpan(child: SizedBox(width: 5, height: 5))],
                  ),
                ),
                SizedBox(height: spacerHeight),
                Semantics(
                  container: true,
                  label: 'target',
                  child: const SizedBox(key: targetKey, width: 100, height: 20),
                ),
              ],
            ),
          ),
          if (blocked)
            BlockSemantics(
              child: Semantics(container: true, label: 'barrier', child: const SizedBox.expand()),
            ),
        ],
      ),
    );
  }

  // The global rect of `node` in logical pixels. Semantics geometry is in
  // physical pixels, so the device pixel ratio is divided back out.
  Rect globalSemanticsRect(WidgetTester tester, SemanticsNode node) {
    Matrix4 transform = node.transform ?? Matrix4.identity();
    for (SemanticsNode? parent = node.parent; parent != null; parent = parent.parent) {
      if (parent.transform != null) {
        transform = parent.transform!.multiplied(transform);
      }
    }
    final Rect rect = MatrixUtils.transformRect(transform, node.rect);
    final double scale = tester.view.devicePixelRatio;
    return Rect.fromLTRB(
      rect.left / scale,
      rect.top / scale,
      rect.right / scale,
      rect.bottom / scale,
    );
  }

  testWidgets('Regression test: semantics geometry is updated for a node that moved '
      'while its branch was blocked from the semantics tree', (WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/186178.
    await tester.pumpWidget(buildTest(spacerHeight: 100.0, blocked: false, text: 'a'));
    expect(
      globalSemanticsRect(tester, tester.getSemantics(find.byKey(targetKey))),
      tester.getRect(find.byKey(targetKey)),
    );

    // A modal barrier blocks the page, e.g. a dialog opens.
    await tester.pumpWidget(buildTest(spacerHeight: 100.0, blocked: true, text: 'a'));

    // While the page is blocked its layout changes, e.g. the keyboard is
    // dismissed: the text re-layout dirties the parent data throughout the
    // blocked branch, and the spacer change moves the target without
    // resizing it.
    await tester.pumpWidget(buildTest(spacerHeight: 300.0, blocked: true, text: 'bb'));

    // The barrier goes away, e.g. the dialog is closed.
    await tester.pumpWidget(buildTest(spacerHeight: 300.0, blocked: false, text: 'bb'));

    final SemanticsNode target = tester.getSemantics(find.byKey(targetKey));
    expect(target.isInvisible, isFalse);
    expect(target.flagsCollection.isHidden, isFalse);
    expect(globalSemanticsRect(tester, target), tester.getRect(find.byKey(targetKey)));
  });

  testWidgets('Regression test: semantics geometry is updated after the keyboard is dismissed '
      'while a modal route is up', (WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/186178.
    final navigatorKey = GlobalKey<NavigatorState>();

    // The keyboard is up.
    tester.view.viewInsets = const FakeViewPadding(bottom: 300.0);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      WidgetsApp(
        color: const Color(0xFF000000),
        navigatorKey: navigatorKey,
        onGenerateRoute: (RouteSettings settings) => PageRouteBuilder<void>(
          settings: settings,
          pageBuilder:
              (
                BuildContext context,
                Animation<double> animation,
                Animation<double> secondaryAnimation,
              ) {
                return Column(
                  children: <Widget>[
                    const Expanded(child: SizedBox.expand()),
                    Semantics(
                      container: true,
                      label: 'target',
                      child: const SizedBox(key: targetKey, width: 100.0, height: 20.0),
                    ),
                    // Stands in for the space taken by the keyboard.
                    SizedBox(height: MediaQuery.viewInsetsOf(context).bottom),
                  ],
                );
              },
        ),
      ),
    );

    // A modal route with a barrier opens, e.g. a dialog.
    navigatorKey.currentState!.push(
      PageRouteBuilder<void>(
        opaque: false,
        barrierColor: const Color(0x80000000),
        pageBuilder:
            (
              BuildContext context,
              Animation<double> animation,
              Animation<double> secondaryAnimation,
            ) => Semantics(
              container: true,
              label: 'dialog',
              child: const SizedBox(width: 100.0, height: 100.0),
            ),
      ),
    );
    await tester.pump();

    // The keyboard is dismissed while the modal route is up.
    tester.view.viewInsets = FakeViewPadding.zero;
    await tester.pumpAndSettle();

    // The modal route is closed.
    navigatorKey.currentState!.pop();
    await tester.pumpAndSettle();

    final SemanticsNode target = tester.getSemantics(find.byKey(targetKey));
    expect(globalSemanticsRect(tester, target), tester.getRect(find.byKey(targetKey)));
  });

  testWidgets('blocked branch with pending geometry update can be removed', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(buildTest(spacerHeight: 100.0, blocked: false, text: 'a'));
    await tester.pumpWidget(buildTest(spacerHeight: 100.0, blocked: true, text: 'a'));
    await tester.pumpWidget(buildTest(spacerHeight: 300.0, blocked: true, text: 'bb'));

    // The whole page, including the subtree with the pending geometry update,
    // goes away while it is still blocked.
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Semantics(container: true, label: 'other', child: const SizedBox.expand()),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(tester.getSemantics(find.bySemanticsLabel('other')), isNotNull);
  });

  testWidgets('a node that becomes invisible while its branch is blocked does not '
      'crash when an ancestor geometry cache is stale', (WidgetTester tester) async {
    final blocked = ValueNotifier<bool>(false);
    addTearDown(blocked.dispose);
    final outerLabel = ValueNotifier<String>('outer');
    addTearDown(outerLabel.dispose);
    final offset = ValueNotifier<double>(0.0);
    addTearDown(offset.dispose);
    final middleLabel = ValueNotifier<String>('middle');
    addTearDown(middleLabel.dispose);
    final innerLabel = ValueNotifier<String>('inner');
    addTearDown(innerLabel.dispose);

    // Each part of the tree is rebuilt by its own notifier so that each frame
    // only dirties the render objects it needs to.
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: ValueListenableBuilder<bool>(
          valueListenable: blocked,
          builder: (BuildContext context, bool isBlocked, Widget? page) {
            return Stack(
              children: <Widget>[
                page!,
                if (isBlocked) const BlockSemantics(child: SizedBox.expand()),
              ],
            );
          },
          child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 200.0,
              height: 200.0,
              // "outer" is a semantics boundary and a relayout boundary.
              child: ValueListenableBuilder<String>(
                valueListenable: outerLabel,
                builder: (BuildContext context, String label, Widget? child) {
                  return Semantics(
                    container: true,
                    explicitChildNodes: true,
                    label: label,
                    child: child,
                  );
                },
                // The transform does not contribute to the semantics tree, so
                // changing it clears the geometry of "middle".
                child: ValueListenableBuilder<double>(
                  valueListenable: offset,
                  builder: (BuildContext context, double dx, Widget? child) {
                    return Transform.translate(offset: Offset(dx, 0.0), child: child);
                  },
                  child: Align(
                    alignment: Alignment.topLeft,
                    // "middle" forms a semantics node but is not a boundary.
                    child: ValueListenableBuilder<String>(
                      valueListenable: middleLabel,
                      builder: (BuildContext context, String label, Widget? child) {
                        return Semantics(label: label, child: child);
                      },
                      // "inner" is a semantics boundary with an empty rect.
                      child: ValueListenableBuilder<String>(
                        valueListenable: innerLabel,
                        builder: (BuildContext context, String label, Widget? child) {
                          return Semantics(
                            container: true,
                            label: label,
                            child: const SizedBox.shrink(),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    // A modal barrier blocks the page.
    blocked.value = true;
    await tester.pump();

    // "middle" gets dirty geometry and caches "outer", which still has clean
    // geometry, as its first ancestor with clean geometry.
    offset.value = 1.0;
    middleLabel.value = 'middle 2';
    await tester.pump();

    // "outer" and "middle" get dirty geometry, which cannot be recomputed
    // while the page is blocked, and the invisible "inner" makes
    // flushSemantics look up the first ancestor of "middle" with clean
    // geometry. That lookup must not reuse the cache from the previous frame.
    outerLabel.value = 'outer 2';
    offset.value = 2.0;
    innerLabel.value = 'inner 2';
    await tester.pump();
    expect(tester.takeException(), isNull);

    // The barrier goes away.
    blocked.value = false;
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.bySemanticsLabel('outer 2'), findsOneWidget);
    expect(find.bySemanticsLabel('middle 2'), findsOneWidget);
  });
}
