// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

class TestPaintingContext implements PaintingContext {
  final List<Invocation> invocations = <Invocation>[];

  @override
    void noSuchMethod(Invocation invocation) {
      invocations.add(invocation);
    }
}

void main() {
  testWidgets('AnimatedSize test', (WidgetTester tester) async {
    await tester.pumpWidget(
      new Center(
        child: new AnimatedSize(
          duration: const Duration(milliseconds: 200),
          vsync: tester,
          child: const SizedBox(
            width: 100.0,
            height: 100.0,
          ),
        ),
      ),
    );

    RenderBox box = tester.renderObject(find.byType(AnimatedSize));
    expect(box.size.width, equals(100.0));
    expect(box.size.height, equals(100.0));

    await tester.pumpWidget(
      new Center(
        child: new AnimatedSize(
          duration: const Duration(milliseconds: 200),
          vsync: tester,
          child: const SizedBox(
            width: 200.0,
            height: 200.0,
          ),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 100));
    box = tester.renderObject(find.byType(AnimatedSize));
    expect(box.size.width, equals(150.0));
    expect(box.size.height, equals(150.0));

    TestPaintingContext context = new TestPaintingContext();
    box.paint(context, Offset.zero);
    expect(context.invocations.first.memberName, equals(#pushClipRect));

    await tester.pump(const Duration(milliseconds: 100));
    box = tester.renderObject(find.byType(AnimatedSize));
    expect(box.size.width, equals(200.0));
    expect(box.size.height, equals(200.0));

    await tester.pumpWidget(
      new Center(
        child: new AnimatedSize(
          duration: const Duration(milliseconds: 200),
          vsync: tester,
          child: const SizedBox(
            width: 100.0,
            height: 100.0,
          ),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 100));
    box = tester.renderObject(find.byType(AnimatedSize));
    expect(box.size.width, equals(150.0));
    expect(box.size.height, equals(150.0));

    context = new TestPaintingContext();
    box.paint(context, Offset.zero);
    expect(context.invocations.first.memberName, equals(#paintChild));

    await tester.pump(const Duration(milliseconds: 100));
    box = tester.renderObject(find.byType(AnimatedSize));
    expect(box.size.width, equals(100.0));
    expect(box.size.height, equals(100.0));
  });

  testWidgets('AnimatedSize constrained test', (WidgetTester tester) async {
    await tester.pumpWidget(
      new Center(
        child: new SizedBox (
          width: 100.0,
          height: 100.0,
          child: new AnimatedSize(
            duration: const Duration(milliseconds: 200),
            vsync: tester,
            child: const SizedBox(
              width: 100.0,
              height: 100.0,
            ),
          ),
        ),
      ),
    );

    RenderBox box = tester.renderObject(find.byType(AnimatedSize));
    expect(box.size.width, equals(100.0));
    expect(box.size.height, equals(100.0));

    await tester.pumpWidget(
      new Center(
        child: new SizedBox (
          width: 100.0,
          height: 100.0,
          child: new AnimatedSize(
            duration: const Duration(milliseconds: 200),
            vsync: tester,
            child: const SizedBox(
              width: 200.0,
              height: 200.0,
            ),
          ),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 100));
    box = tester.renderObject(find.byType(AnimatedSize));
    expect(box.size.width, equals(100.0));
    expect(box.size.height, equals(100.0));
  });

  testWidgets('AnimatedSize with AnimatedContainer', (WidgetTester tester) async {
    await tester.pumpWidget(
      new Center(
        child: new AnimatedSize(
          duration: const Duration(milliseconds: 200),
          vsync: tester,
          child: new AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            width: 100.0,
            height: 100.0,
          ),
        ),
      ),
    );

    RenderBox box = tester.renderObject(find.byType(AnimatedSize));
    expect(box.size.width, equals(100.0));
    expect(box.size.height, equals(100.0));

    await tester.pumpWidget(
      new Center(
        child: new AnimatedSize(
          duration: const Duration(milliseconds: 200),
          vsync: tester,
          child: new AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            width: 200.0,
            height: 200.0,
          ),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 1)); // register change
    await tester.pump(const Duration(milliseconds: 49));
    expect(box.size.width, equals(150.0));
    expect(box.size.height, equals(150.0));
    await tester.pump(const Duration(milliseconds: 50));
    box = tester.renderObject(find.byType(AnimatedSize));
    expect(box.size.width, equals(200.0));
    expect(box.size.height, equals(200.0));
  });

  testWidgets('AnimatedSize resync', (WidgetTester tester) async {
    await tester.pumpWidget(
      const Center(
        child: const AnimatedSize(
          duration: const Duration(milliseconds: 200),
          vsync: const TestVSync(),
          child: const SizedBox(
            width: 100.0,
            height: 100.0,
          ),
        ),
      ),
    );

    await tester.pumpWidget(
      new Center(
        child: new AnimatedSize(
          duration: const Duration(milliseconds: 200),
          vsync: tester,
          child: const SizedBox(
            width: 200.0,
            height: 100.0,
          ),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 100));

    final RenderBox box = tester.renderObject(find.byType(AnimatedSize));
    expect(box.size.width, equals(150.0));
  });
}
