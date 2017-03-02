// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';

import 'states.dart';

const double kItemHeight = 64.0;
const Duration kDuration = const Duration(milliseconds: 100);

void main() {
  testWidgets('ScrollController control test', (WidgetTester tester) async {
    ScrollLeader leader = new ScrollLeader();
    final List<ScrollController> controllers = <ScrollController>[
      new ScrollController(leader: leader),
      new ScrollController(leader: leader),
      new ScrollController(leader: leader),
    ];

    await tester.pumpWidget(new Row(
      children: controllers.map((ScrollController controller) {
        return new Flexible(
          child: new ListView(
            controller: controller,
            children: kStates.map<Widget>((String state) {
              return new Container(
                height: kItemHeight,
                child: new Text(state),
              );
            }).toList(),
          ),
        );
      }).toList(),
    ));

    List<double> scrollOffsets() {
      return tester.stateList<ScrollableState>(find.byType(Scrollable)).map((ScrollableState state) {
        return state.position.pixels;
      }).toList();
    }

    bool allScrollOffsetsEqual() {
      final List<double> offsets = scrollOffsets();
      return offsets.every((double offset) => offset == offsets.first);
    }

    expect(scrollOffsets(), <double>[0.0, 0.0, 0.0]);

    tester.state<ScrollableState>(find.byType(Scrollable).first).position.jumpTo(100.0);
    await tester.pump();
    expect(scrollOffsets(), <double>[100.0, 100.0, 100.0]);

    tester.state<ScrollableState>(find.byType(Scrollable).last).position.jumpTo(500.0);
    await tester.pump();
    expect(scrollOffsets(), <double>[500.0, 500.0, 500.0]);

    tester.state<ScrollableState>(find.byType(Scrollable).first).position.animateTo(200.0,
      duration: kDuration,
      curve: Curves.linear
    );
    await tester.pump();
    await tester.pump(kDuration);
    expect(scrollOffsets(), <double>[200.0, 200.0, 200.0]);

    tester.state<ScrollableState>(find.byType(Scrollable).last).position.animateTo(600.0,
      duration: kDuration,
      curve: Curves.linear
    );
    await tester.pump();
    await tester.pump(kDuration);
    expect(scrollOffsets(), <double>[600.0, 600.0, 600.0]);

    await tester.fling(find.byType(ListView).first, const Offset(0.0, -200.0), 1000.0);
    expect(allScrollOffsetsEqual(), isTrue);

    await tester.fling(find.byType(ListView).first, const Offset(0.0, 200.0), 1000.0);
    expect(allScrollOffsetsEqual(), isTrue);
  });
}
