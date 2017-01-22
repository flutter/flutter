// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart' hide TypeMatcher;

class Foo extends StatefulWidget {
  @override
  FooState createState() => new FooState();
}

class FooState extends State<Foo> {
  final GlobalKey blockKey = new GlobalKey();
  GlobalKey<ScrollableState> scrollableKey = new GlobalKey<ScrollableState>();

  @override
  Widget build(BuildContext context) {
    return new LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return new ScrollConfiguration(
          delegate: new FooScrollConfiguration(),
          child: new Block(
            scrollableKey: scrollableKey,
            children: <Widget>[
              new GestureDetector(
                onTap: () {
                  setState(() { /* this is needed to trigger the original bug this is regression-testing */ });
                  scrollableKey.currentState.scrollBy(200.0, duration: const Duration(milliseconds: 500));
                },
                child: new DecoratedBox(
                  decoration: const BoxDecoration(backgroundColor: const Color(0)),
                  child: const SizedBox(
                    height: 200.0,
                  ),
                )
              ),
              new DecoratedBox(
                decoration: const BoxDecoration(backgroundColor: const Color(0)),
                child: const SizedBox(
                  height: 200.0,
                ),
              ),
              new DecoratedBox(
                decoration: const BoxDecoration(backgroundColor: const Color(0)),
                child: const SizedBox(
                  height: 200.0,
                ),
              ),
              new DecoratedBox(
                decoration: const BoxDecoration(backgroundColor: const Color(0)),
                child: const SizedBox(
                  height: 200.0,
                ),
              ),
              new DecoratedBox(
                decoration: const BoxDecoration(backgroundColor: const Color(0)),
                child: const SizedBox(
                  height: 200.0,
                ),
              ),
              new DecoratedBox(
                decoration: const BoxDecoration(backgroundColor: const Color(0)),
                child: const SizedBox(
                  height: 200.0,
                ),
              ),
            ],
          )
        );
      }
    );
  }
}

class FooScrollConfiguration extends ScrollConfigurationDelegate {
  @override
  TargetPlatform get platform => defaultTargetPlatform;

  @override
  ExtentScrollBehavior createScrollBehavior() =>
      new OverscrollWhenScrollableBehavior(platform: platform);

  @override
  bool updateShouldNotify(FooScrollConfiguration old) => true;
}

void main() {
  testWidgets('https://github.com/flutter/flutter/issues/5630', (WidgetTester tester) async {
    await tester.pumpWidget(new Foo());
    expect(tester.state<ScrollableState>(find.byType(Scrollable)).scrollOffset, 0.0);
    await tester.tap(find.byType(GestureDetector).first);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(tester.state<ScrollableState>(find.byType(Scrollable)).scrollOffset, 200.0);
  });
}
