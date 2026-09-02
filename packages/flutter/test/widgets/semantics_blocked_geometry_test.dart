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
}
