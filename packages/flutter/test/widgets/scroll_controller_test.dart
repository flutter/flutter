// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';

import 'states.dart';

void main() {
  testWidgets('ScrollController control test', (WidgetTester tester) async {
    ScrollController controller = new ScrollController();

    await tester.pumpWidget(new ListView(
      controller: controller,
      children: kStates.map<Widget>((String state) {
        return new Container(
          height: 200.0,
          child: new Text(state),
        );
      }).toList()
    ));

    double realOffset() {
      return tester.state<ScrollableState>(find.byType(Scrollable)).position.pixels;
    }

    expect(controller.offset, equals(0.0));
    expect(realOffset(), equals(controller.offset));

    controller.jumpTo(653.0);

    expect(controller.offset, equals(653.0));
    expect(realOffset(), equals(controller.offset));

    await tester.pump();

    expect(controller.offset, equals(653.0));
    expect(realOffset(), equals(controller.offset));

    controller.animateTo(326.0, duration: const Duration(milliseconds: 300), curve: Curves.ease);
    await tester.pumpUntilNoTransientCallbacks(const Duration(milliseconds: 100));

    expect(controller.offset, equals(326.0));
    expect(realOffset(), equals(controller.offset));

    await tester.pumpWidget(new ListView(
      key: const Key('second'),
      controller: controller,
      children: kStates.map<Widget>((String state) {
        return new Container(
          height: 200.0,
          child: new Text(state),
        );
      }).toList()
    ));

    expect(controller.offset, equals(0.0));
    expect(realOffset(), equals(controller.offset));

    controller.jumpTo(653.0);

    expect(controller.offset, equals(653.0));
    expect(realOffset(), equals(controller.offset));

    ScrollController controller2 = new ScrollController();

    await tester.pumpWidget(new ListView(
      key: const Key('second'),
      controller: controller2,
      children: kStates.map<Widget>((String state) {
        return new Container(
          height: 200.0,
          child: new Text(state),
        );
      }).toList()
    ));

    expect(() => controller.offset, throwsAssertionError);
    expect(controller2.offset, equals(653.0));
    expect(realOffset(), equals(controller2.offset));

    expect(() => controller.jumpTo(120.0), throwsAssertionError);
    expect(() => controller.animateTo(132.0, duration: const Duration(milliseconds: 300), curve: Curves.ease), throwsAssertionError);

    await tester.pumpWidget(new ListView(
      key: const Key('second'),
      controller: controller2,
      physics: const BouncingScrollPhysics(),
      children: kStates.map<Widget>((String state) {
        return new Container(
          height: 200.0,
          child: new Text(state),
        );
      }).toList()
    ));

    expect(controller2.offset, equals(653.0));
    expect(realOffset(), equals(controller2.offset));

    controller2.jumpTo(432.0);

    expect(controller2.offset, equals(432.0));
    expect(realOffset(), equals(controller2.offset));

    await tester.pump();

    expect(controller2.offset, equals(432.0));
    expect(realOffset(), equals(controller2.offset));
  });

  testWidgets('ScrollController control test', (WidgetTester tester) async {
    ScrollController controller = new ScrollController(
      initialScrollOffset: 209.0,
    );

    await tester.pumpWidget(new GridView.count(
      crossAxisCount: 4,
      controller: controller,
      children: kStates.map<Widget>((String state) => new Text(state)).toList(),
    ));

    double realOffset() {
      return tester.state<ScrollableState>(find.byType(Scrollable)).position.pixels;
    }

    expect(controller.offset, equals(209.0));
    expect(realOffset(), equals(controller.offset));

    controller.jumpTo(105.0);

    await tester.pump();

    expect(controller.offset, equals(105.0));
    expect(realOffset(), equals(controller.offset));

    await tester.pumpWidget(new GridView.count(
      crossAxisCount: 2,
      controller: controller,
      children: kStates.map<Widget>((String state) => new Text(state)).toList(),
    ));

    expect(controller.offset, equals(105.0));
    expect(realOffset(), equals(controller.offset));
  });

  testWidgets('DrivenScrollActivity ending after dispose', (WidgetTester tester) async {
    ScrollController controller = new ScrollController();

    await tester.pumpWidget(new ListView(
      controller: controller,
      children: <Widget>[ new Container(height: 200000.0) ],
    ));

    controller.animateTo(1000.0, duration: const Duration(seconds: 1), curve: Curves.linear);

    await tester.pump(); // Start the animation.

    // We will now change the tree on the same frame as the animation ends.
    await tester.pumpWidget(new Container(), const Duration(seconds: 2));
  });

}
