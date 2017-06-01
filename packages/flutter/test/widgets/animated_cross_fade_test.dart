// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

void main() {
  testWidgets('AnimatedCrossFade test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const Center(
        child: const AnimatedCrossFade(
          firstChild: const SizedBox(
            width: 100.0,
            height: 100.0
          ),
          secondChild: const SizedBox(
            width: 200.0,
            height: 200.0
          ),
          duration: const Duration(milliseconds: 200),
          crossFadeState: CrossFadeState.showFirst
        )
      )
    );

    expect(find.byType(FadeTransition), findsNWidgets(2));
    RenderBox box = tester.renderObject(find.byType(AnimatedCrossFade));
    expect(box.size.width, equals(100.0));
    expect(box.size.height, equals(100.0));

    await tester.pumpWidget(
      const Center(
        child: const AnimatedCrossFade(
          firstChild: const SizedBox(
            width: 100.0,
            height: 100.0
          ),
          secondChild: const SizedBox(
            width: 200.0,
            height: 200.0
          ),
          duration: const Duration(milliseconds: 200),
          crossFadeState: CrossFadeState.showSecond
        )
      )
    );

    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(FadeTransition), findsNWidgets(2));
    box = tester.renderObject(find.byType(AnimatedCrossFade));
    expect(box.size.width, equals(150.0));
    expect(box.size.height, equals(150.0));
  });

  testWidgets('AnimatedCrossFade test showSecond', (WidgetTester tester) async {
    await tester.pumpWidget(
      const Center(
        child: const AnimatedCrossFade(
          firstChild: const SizedBox(
            width: 100.0,
            height: 100.0
          ),
          secondChild: const SizedBox(
            width: 200.0,
            height: 200.0
          ),
          duration: const Duration(milliseconds: 200),
          crossFadeState: CrossFadeState.showSecond
        )
      )
    );

    expect(find.byType(FadeTransition), findsNWidgets(2));
    final RenderBox box = tester.renderObject(find.byType(AnimatedCrossFade));
    expect(box.size.width, equals(200.0));
    expect(box.size.height, equals(200.0));
  });

  testWidgets('AnimatedCrossFade alignment', (WidgetTester tester) async {
    final Key firstKey = new UniqueKey();
    final Key secondKey = new UniqueKey();

    await tester.pumpWidget(
      new Center(
        child: new AnimatedCrossFade(
          alignment: FractionalOffset.bottomRight,
          firstChild: new SizedBox(
            key: firstKey,
            width: 100.0,
            height: 100.0
          ),
          secondChild: new SizedBox(
            key: secondKey,
            width: 200.0,
            height: 200.0
          ),
          duration: const Duration(milliseconds: 200),
          crossFadeState: CrossFadeState.showFirst
        )
      )
    );

    await tester.pumpWidget(
      new Center(
        child: new AnimatedCrossFade(
          alignment: FractionalOffset.bottomRight,
          firstChild: new SizedBox(
            key: firstKey,
            width: 100.0,
            height: 100.0
          ),
          secondChild: new SizedBox(
            key: secondKey,
            width: 200.0,
            height: 200.0
          ),
          duration: const Duration(milliseconds: 200),
          crossFadeState: CrossFadeState.showSecond
        )
      )
    );

    await tester.pump(const Duration(milliseconds: 100));

    final RenderBox box1 = tester.renderObject(find.byKey(firstKey));
    final RenderBox box2 = tester.renderObject(find.byKey(secondKey));
    expect(box1.localToGlobal(Offset.zero), const Offset(275.0, 175.0));
    expect(box2.localToGlobal(Offset.zero), const Offset(275.0, 175.0));
  });

}
