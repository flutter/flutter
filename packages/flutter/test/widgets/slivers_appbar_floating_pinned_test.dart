// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('Sliver appbars - floating and pinned - second app bar stacks below', (WidgetTester tester) async {
    final ScrollController controller = new ScrollController();
    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.ltr,
        child: new MediaQuery(
          data: const MediaQueryData(),
          child: new CustomScrollView(
            controller: controller,
            slivers: const <Widget>[
              const SliverAppBar(floating: true, pinned: true, expandedHeight: 200.0, title: const Text('A')),
              const SliverAppBar(primary: false, pinned: true, title: const Text('B')),
              const SliverList(
                delegate: const SliverChildListDelegate(
                  const <Widget>[
                    const Text('C'),
                    const Text('D'),
                    const SizedBox(height: 500.0),
                    const Text('E'),
                    const SizedBox(height: 500.0),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    const Offset textPositionInAppBar = const Offset(16.0, 18.0);
    expect(tester.getTopLeft(find.text('A')), textPositionInAppBar);
    // top app bar is 200.0 high at this point
    expect(tester.getTopLeft(find.text('B')), const Offset(0.0, 200.0) + textPositionInAppBar);
    // second app bar is 56.0 high
    expect(tester.getTopLeft(find.text('C')), const Offset(0.0, 200.0 + 56.0)); // height of both appbars
    final Size cSize = tester.getSize(find.text('C'));
    controller.jumpTo(200.0 - 56.0);
    await tester.pump();
    expect(tester.getTopLeft(find.text('A')), textPositionInAppBar);
    // top app bar is now only 56.0 high, same as second
    expect(tester.getTopLeft(find.text('B')), const Offset(0.0, 56.0) + textPositionInAppBar);
    expect(tester.getTopLeft(find.text('C')), const Offset(0.0, 56.0 * 2.0)); // height of both collapsed appbars
    expect(find.text('E'), findsNothing);
    controller.jumpTo(600.0);
    await tester.pump();
    expect(tester.getTopLeft(find.text('A')), textPositionInAppBar); // app bar is pinned at top
    expect(tester.getTopLeft(find.text('B')), const Offset(0.0, 56.0) + textPositionInAppBar); // second one too
    expect(find.text('C'), findsNothing); // contents are scrolled off though
    expect(find.text('D'), findsNothing);
    // we have scrolled 600.0 pixels
    // initial position of E was 200 + 56 + cSize.height + cSize.height + 500
    // we've scrolled that up by 600.0, meaning it's at that minus 600 now:
    expect(tester.getTopLeft(find.text('E')), new Offset(0.0, 200.0 + 56.0 + cSize.height * 2.0 + 500.0 - 600.0));
  });
}