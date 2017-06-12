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
}
