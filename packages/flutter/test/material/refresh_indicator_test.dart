// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

bool refreshCalled = false;

Future<void> refresh() {
  refreshCalled = true;
  return Future<void>.value();
}

Future<void> holdRefresh() {
  refreshCalled = true;
  return Completer<void>().future;
}

void main() {
  testWidgets('RefreshIndicator', (WidgetTester tester) async {
    refreshCalled = false;
    final SemanticsHandle handle = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        home: RefreshIndicator(
          onRefresh: refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: <String>['A', 'B', 'C', 'D', 'E', 'F'].map<Widget>((String item) {
              return SizedBox(
                height: 200.0,
                child: Text(item),
              );
            }).toList(),
          ),
        ),
      ),
    );

    await tester.fling(find.text('A'), const Offset(0.0, 300.0), 1000.0);
    await tester.pump();

    expect(tester.getSemantics(find.byType(RefreshProgressIndicator)), matchesSemantics(
      label: 'Refresh',
    ));

    await tester.pump(const Duration(seconds: 1)); // finish the scroll animation
    await tester.pump(const Duration(seconds: 1)); // finish the indicator settle animation
    await tester.pump(const Duration(seconds: 1)); // finish the indicator hide animation
    expect(refreshCalled, true);
    handle.dispose();
  });

  testWidgets('Refresh Indicator - nested', (WidgetTester tester) async {
    refreshCalled = false;
    await tester.pumpWidget(
      MaterialApp(
        home: RefreshIndicator(
          notificationPredicate: (ScrollNotification notification) => notification.depth == 1,
          onRefresh: refresh,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: 600.0,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: <String>['A', 'B', 'C', 'D', 'E', 'F'].map<Widget>((String item) {
                  return SizedBox(
                    height: 200.0,
                    child: Text(item),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.fling(find.text('A'), const Offset(300.0, 0.0), 1000.0); // horizontal fling
    await tester.pump();
    await tester.pump(const Duration(seconds: 1)); // finish the scroll animation
    await tester.pump(const Duration(seconds: 1)); // finish the indicator settle animation
    await tester.pump(const Duration(seconds: 1)); // finish the indicator hide animation
    expect(refreshCalled, false);

    await tester.fling(find.text('A'), const Offset(0.0, 300.0), 1000.0); // vertical fling
    await tester.pump();
    await tester.pump(const Duration(seconds: 1)); // finish the scroll animation
    await tester.pump(const Duration(seconds: 1)); // finish the indicator settle animation
    await tester.pump(const Duration(seconds: 1)); // finish the indicator hide animation
    expect(refreshCalled, true);
  });

  testWidgets('RefreshIndicator - reverse', (WidgetTester tester) async {
    refreshCalled = false;
    await tester.pumpWidget(
      MaterialApp(
        home: RefreshIndicator(
          onRefresh: refresh,
          child: ListView(
            reverse: true,
            physics: const AlwaysScrollableScrollPhysics(),
            children: const <Widget>[
              SizedBox(
                height: 200.0,
                child: Text('X'),
              ),
            ],
          ),
        ),
      ),
    );

    await tester.fling(find.text('X'), const Offset(0.0, 600.0), 1000.0);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1)); // finish the scroll animation
    await tester.pump(const Duration(seconds: 1)); // finish the indicator settle animation
    await tester.pump(const Duration(seconds: 1)); // finish the indicator hide animation
    expect(refreshCalled, true);
  });

  testWidgets('RefreshIndicator - top - position', (WidgetTester tester) async {
    refreshCalled = false;
    await tester.pumpWidget(
      MaterialApp(
        home: RefreshIndicator(
          onRefresh: holdRefresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: const <Widget>[
              SizedBox(
                height: 200.0,
                child: Text('X'),
              ),
            ],
          ),
        ),
      ),
    );

    await tester.fling(find.text('X'), const Offset(0.0, 300.0), 1000.0);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(tester.getCenter(find.byType(RefreshProgressIndicator)).dy, lessThan(300.0));
  });

  testWidgets('RefreshIndicator - reverse - position', (WidgetTester tester) async {
    refreshCalled = false;
    await tester.pumpWidget(
      MaterialApp(
        home: RefreshIndicator(
          onRefresh: holdRefresh,
          child: ListView(
            reverse: true,
            physics: const AlwaysScrollableScrollPhysics(),
            children: const <Widget>[
              SizedBox(
                height: 200.0,
                child: Text('X'),
              ),
            ],
          ),
        ),
      ),
    );

    await tester.fling(find.text('X'), const Offset(0.0, 600.0), 1000.0);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(tester.getCenter(find.byType(RefreshProgressIndicator)).dy, lessThan(300.0));
  });

  testWidgets('RefreshIndicator - no movement', (WidgetTester tester) async {
    refreshCalled = false;
    await tester.pumpWidget(
      MaterialApp(
        home: RefreshIndicator(
          onRefresh: refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: const <Widget>[
              SizedBox(
                height: 200.0,
                child: Text('X'),
              ),
            ],
          ),
        ),
      ),
    );

    // this fling is horizontal, not up or down
    await tester.fling(find.text('X'), const Offset(1.0, 0.0), 1000.0);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(refreshCalled, false);
  });

  testWidgets('RefreshIndicator - not enough', (WidgetTester tester) async {
    refreshCalled = false;
    await tester.pumpWidget(
      MaterialApp(
        home: RefreshIndicator(
          onRefresh: refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: const <Widget>[
              SizedBox(
                height: 200.0,
                child: Text('X'),
              ),
            ],
          ),
        ),
      ),
    );

    await tester.fling(find.text('X'), const Offset(0.0, 50.0), 1000.0);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(refreshCalled, false);
  });

  testWidgets('RefreshIndicator - just enough', (WidgetTester tester) async {
    refreshCalled = false;
    await tester.pumpWidget(
      MaterialApp(
        home: RefreshIndicator(
          onRefresh: refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: const <Widget>[
              SizedBox(
                height: 200.0,
                child: Text('X'),
              ),
            ],
          ),
        ),
      ),
    );

    await tester.fling(find.text('X'), const Offset(0.0, 100.0), 1000.0);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(refreshCalled, true);
  });

  testWidgets('RefreshIndicator - show - slow', (WidgetTester tester) async {
    refreshCalled = false;
    await tester.pumpWidget(
      MaterialApp(
        home: RefreshIndicator(
          onRefresh: holdRefresh, // this one never returns
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: const <Widget>[
              SizedBox(
                height: 200.0,
                child: Text('X'),
              ),
            ],
          ),
        ),
      ),
    );

    bool completed = false;
    tester.state<RefreshIndicatorState>(find.byType(RefreshIndicator))
      .show()
      .then<void>((void value) { completed = true; });
    await tester.pump();
    expect(completed, false);
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(refreshCalled, true);
    expect(completed, false);
    completed = false;
    refreshCalled = false;
    tester.state<RefreshIndicatorState>(find.byType(RefreshIndicator))
      .show()
      .then<void>((void value) { completed = true; });
    await tester.pump();
    expect(completed, false);
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(refreshCalled, false);
  });

  testWidgets('RefreshIndicator - show - fast', (WidgetTester tester) async {
    refreshCalled = false;
    await tester.pumpWidget(
      MaterialApp(
        home: RefreshIndicator(
          onRefresh: refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: const <Widget>[
              SizedBox(
                height: 200.0,
                child: Text('X'),
              ),
            ],
          ),
        ),
      ),
    );

    bool completed = false;
    tester.state<RefreshIndicatorState>(find.byType(RefreshIndicator))
      .show()
      .then<void>((void value) { completed = true; });
    await tester.pump();
    expect(completed, false);
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(refreshCalled, true);
    expect(completed, true);
    completed = false;
    refreshCalled = false;
    tester.state<RefreshIndicatorState>(find.byType(RefreshIndicator))
      .show()
      .then<void>((void value) { completed = true; });
    await tester.pump();
    expect(completed, false);
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(refreshCalled, true);
    expect(completed, true);
  });

  testWidgets('RefreshIndicator - show - fast - twice', (WidgetTester tester) async {
    refreshCalled = false;
    await tester.pumpWidget(
      MaterialApp(
        home: RefreshIndicator(
          onRefresh: refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: const <Widget>[
              SizedBox(
                height: 200.0,
                child: Text('X'),
              ),
            ],
          ),
        ),
      ),
    );

    bool completed1 = false;
    tester.state<RefreshIndicatorState>(find.byType(RefreshIndicator))
      .show()
      .then<void>((void value) { completed1 = true; });
    bool completed2 = false;
    tester.state<RefreshIndicatorState>(find.byType(RefreshIndicator))
      .show()
      .then<void>((void value) { completed2 = true; });
    await tester.pump();
    expect(completed1, false);
    expect(completed2, false);
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(refreshCalled, true);
    expect(completed1, true);
    expect(completed2, true);
  });

  testWidgets('Refresh starts while scroll view moves back to 0.0 after overscroll', (WidgetTester tester) async {
    refreshCalled = false;
    double lastScrollOffset;
    final ScrollController controller = ScrollController();

    await tester.pumpWidget(
      MaterialApp(
        home: RefreshIndicator(
          onRefresh: refresh,
          child: ListView(
            controller: controller,
            physics: const AlwaysScrollableScrollPhysics(),
            children: <String>['A', 'B', 'C', 'D', 'E', 'F'].map<Widget>((String item) {
              return SizedBox(
                height: 200.0,
                child: Text(item),
              );
            }).toList(),
          ),
        ),
      ),
    );

    await tester.fling(find.text('A'), const Offset(0.0, 300.0), 1000.0);
    await tester.pump(const Duration(milliseconds: 100));
    expect(lastScrollOffset = controller.offset, lessThan(0.0));
    expect(refreshCalled, isFalse);

    await tester.pump(const Duration(milliseconds: 100));
    expect(controller.offset, greaterThan(lastScrollOffset));
    expect(controller.offset, lessThan(0.0));
    expect(refreshCalled, isTrue);
  }, variant: const TargetPlatformVariant(<TargetPlatform>{ TargetPlatform.iOS,  TargetPlatform.macOS }));

  testWidgets('RefreshIndicator does not force child to relayout', (WidgetTester tester) async {
    int layoutCount = 0;

    Widget layoutCallback(BuildContext context, BoxConstraints constraints) {
      layoutCount++;
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: <String>['A', 'B', 'C', 'D', 'E', 'F'].map<Widget>((String item) {
          return SizedBox(
            height: 200.0,
            child: Text(item),
          );
        }).toList(),
      );
    }

    await tester.pumpWidget(
      MaterialApp(
        home: RefreshIndicator(
          onRefresh: refresh,
          child: LayoutBuilder(builder: layoutCallback),
        ),
      ),
    );

    await tester.fling(find.text('A'), const Offset(0.0, 300.0), 1000.0); // trigger refresh
    await tester.pump();

    await tester.pump(const Duration(seconds: 1)); // finish the scroll animation
    await tester.pump(const Duration(seconds: 1)); // finish the indicator settle animation
    await tester.pump(const Duration(seconds: 1)); // finish the indicator hide animation

    expect(layoutCount, 1);
  });

  testWidgets('RefreshIndicator responds to strokeWidth', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: RefreshIndicator(
          onRefresh: () async {},
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: <String>['A', 'B', 'C', 'D', 'E', 'F'].map<Widget>((String item) {
              return SizedBox(
                height: 200.0,
                child: Text(item),
              );
            }).toList(),
          ),
        ),
      ),
    );

    // Check for the default value
    expect(
      tester.widget<RefreshIndicator>(find.byType(RefreshIndicator)).strokeWidth,
      RefreshProgressIndicator.defaultStrokeWidth,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: RefreshIndicator(
          onRefresh: () async {},
          strokeWidth: 4.0,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: <String>['A', 'B', 'C', 'D', 'E', 'F'].map<Widget>((String item) {
              return SizedBox(
                height: 200.0,
                child: Text(item),
              );
            }).toList(),
          ),
        ),
      ),
    );

    expect(
      tester.widget<RefreshIndicator>(find.byType(RefreshIndicator)).strokeWidth,
      4.0,
    );
  });

  testWidgets('RefreshIndicator responds to edgeOffset', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: RefreshIndicator(
          onRefresh: () async {},
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: <String>['A', 'B', 'C', 'D', 'E', 'F'].map<Widget>((String item) {
              return SizedBox(
                height: 200.0,
                child: Text(item),
              );
            }).toList(),
          ),
        ),
      ),
    );

    //By default the value of edgeOffset is 0.0
    expect(
      tester.widget<RefreshIndicator>(find.byType(RefreshIndicator)).edgeOffset,
      0.0,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: RefreshIndicator(
          onRefresh: () async {},
          edgeOffset: kToolbarHeight,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: <String>['A', 'B', 'C', 'D', 'E', 'F'].map<Widget>((String item) {
              return SizedBox(
                height: 200.0,
                child: Text(item),
              );
            }).toList(),
          ),
        ),
      ),
    );

    expect(
      tester.widget<RefreshIndicator>(find.byType(RefreshIndicator)).edgeOffset,
      kToolbarHeight,
    );
  });

  testWidgets('RefreshIndicator appears at edgeOffset', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: RefreshIndicator(
        edgeOffset: kToolbarHeight,
        displacement: kToolbarHeight,
        onRefresh: () async {
          await Future<void>.delayed(const Duration(seconds: 1), () { });
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: <String>['A', 'B', 'C', 'D', 'E', 'F'].map<Widget>((String item) {
            return SizedBox(
              height: 200.0,
              child: Text(item),
            );
          }).toList(),
        ),
      ),
    ));

    await tester.fling(find.byType(ListView), const Offset(0.0, 2.0 * kToolbarHeight), 1000.0);
    await tester.pump(const Duration(seconds: 2));

    expect(
      tester.getTopLeft(find.byType(RefreshProgressIndicator)).dy,
      greaterThanOrEqualTo(2.0 * kToolbarHeight),
    );
  });

  testWidgets('Top RefreshIndicator(anywhere mode) should be shown when dragging from non-zero scroll position', (WidgetTester tester) async {
    refreshCalled = false;
    final ScrollController scrollController = ScrollController();
    await tester.pumpWidget(
      MaterialApp(
        home: RefreshIndicator(
          triggerMode: RefreshIndicatorTriggerMode.anywhere,
          onRefresh: holdRefresh,
          child: ListView(
            controller: scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            children: const <Widget>[
              SizedBox(
                height: 200.0,
                child: Text('X'),
              ),
              SizedBox(
                height: 800.0,
                child: Text('Y'),
              ),
            ],
          ),
        ),
      ),
    );

    scrollController.jumpTo(50.0);

    await tester.fling(find.text('X'), const Offset(0.0, 300.0), 1000.0);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1)); // finish the scroll animation
    await tester.pump(const Duration(seconds: 1)); // finish the indicator settle animation
    expect(tester.getCenter(find.byType(RefreshProgressIndicator)).dy, lessThan(300.0));
  });

  testWidgets('Reverse RefreshIndicator(anywhere mode) should be shown when dragging from non-zero scroll position', (WidgetTester tester) async {
    refreshCalled = false;
    final ScrollController scrollController = ScrollController();
    await tester.pumpWidget(
      MaterialApp(
        home: RefreshIndicator(
          triggerMode: RefreshIndicatorTriggerMode.anywhere,
          onRefresh: holdRefresh,
          child: ListView(
            reverse: true,
            controller: scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            children: const <Widget>[
              SizedBox(
                height: 200.0,
                child: Text('X'),
              ),
              SizedBox(
                height: 800.0,
                child: Text('Y'),
              ),
            ],
          ),
        ),
      ),
    );

    scrollController.jumpTo(50.0);

    await tester.fling(find.text('X'), const Offset(0.0, 600.0), 1000.0);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1)); // finish the scroll animation
    await tester.pump(const Duration(seconds: 1)); // finish the indicator settle animation
    expect(tester.getCenter(find.byType(RefreshProgressIndicator)).dy, lessThan(300.0));
  });

  // Regression test for https://github.com/flutter/flutter/issues/71936
  testWidgets('RefreshIndicator(anywhere mode) should not be shown when overscroll occurs due to inertia', (WidgetTester tester) async {
    refreshCalled = false;
    final ScrollController scrollController = ScrollController();
    await tester.pumpWidget(
      MaterialApp(
        home: RefreshIndicator(
          triggerMode: RefreshIndicatorTriggerMode.anywhere,
          onRefresh: holdRefresh,
          child: ListView(
            controller: scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            children: const <Widget>[
              SizedBox(
                height: 200.0,
                child: Text('X'),
              ),
              SizedBox(
                height: 2000.0,
                child: Text('Y'),
              ),
            ],
          ),
        ),
      ),
    );

    scrollController.jumpTo(100.0);

    // Release finger before reach the edge.
    await tester.fling(find.text('X'), const Offset(0.0, 99.0), 1000.0);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1)); // finish the scroll animation
    await tester.pump(const Duration(seconds: 1)); // finish the indicator settle animation
    expect(find.byType(RefreshProgressIndicator), findsNothing);
  });

  testWidgets('Top RefreshIndicator(onEdge mode) should not be shown when dragging from non-zero scroll position', (WidgetTester tester) async {
    refreshCalled = false;
    final ScrollController scrollController = ScrollController();
    await tester.pumpWidget(
      MaterialApp(
        home: RefreshIndicator(
          onRefresh: holdRefresh,
          child: ListView(
            controller: scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            children: const <Widget>[
              SizedBox(
                height: 200.0,
                child: Text('X'),
              ),
              SizedBox(
                height: 800.0,
                child: Text('Y'),
              ),
            ],
          ),
        ),
      ),
    );

    scrollController.jumpTo(50.0);

    await tester.fling(find.text('X'), const Offset(0.0, 300.0), 1000.0);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1)); // finish the scroll animation
    await tester.pump(const Duration(seconds: 1)); // finish the indicator settle animation
    expect(find.byType(RefreshProgressIndicator), findsNothing);
  });

  testWidgets('Reverse RefreshIndicator(onEdge mode) should be shown when dragging from non-zero scroll position', (WidgetTester tester) async {
    refreshCalled = false;
    final ScrollController scrollController = ScrollController();
    await tester.pumpWidget(
      MaterialApp(
        home: RefreshIndicator(
          onRefresh: holdRefresh,
          child: ListView(
            reverse: true,
            controller: scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            children: const <Widget>[
              SizedBox(
                height: 200.0,
                child: Text('X'),
              ),
              SizedBox(
                height: 800.0,
                child: Text('Y'),
              ),
            ],
          ),
        ),
      ),
    );

    scrollController.jumpTo(50.0);

    await tester.fling(find.text('X'), const Offset(0.0, -300.0), 1000.0);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1)); // finish the scroll animation
    await tester.pump(const Duration(seconds: 1)); // finish the indicator settle animation
    expect(find.byType(RefreshProgressIndicator), findsNothing);
  });

  testWidgets('ScrollController.jumpTo should not trigger the refresh indicator', (WidgetTester tester) async {
    refreshCalled = false;
    final ScrollController scrollController = ScrollController(initialScrollOffset: 500.0);
    await tester.pumpWidget(
      MaterialApp(
        home: RefreshIndicator(
          onRefresh: refresh,
          child: ListView(
            controller: scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            children: const <Widget>[
              SizedBox(
                height: 800.0,
                child: Text('X'),
              ),
              SizedBox(
                height: 800.0,
                child: Text('Y'),
              ),
            ],
          ),
        ),
      ),
    );

    scrollController.jumpTo(0.0);
    await tester.pump(const Duration(seconds: 1)); // finish the indicator settle animation
    await tester.pump(const Duration(seconds: 1)); // finish the indicator hide animation

    expect(refreshCalled, false);
  });

  testWidgets('RefreshIndicator color defaults to ColorScheme.primary', (WidgetTester tester) async {
    const Color primaryColor = Color(0xff4caf50);
    final ThemeData theme = ThemeData.from(colorScheme: const ColorScheme.light().copyWith(primary: primaryColor));
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: StatefulBuilder(
          builder: (BuildContext context, StateSetter stateSetter) {
            return RefreshIndicator(
              triggerMode: RefreshIndicatorTriggerMode.anywhere,
              onRefresh: holdRefresh,
              child: ListView(
                reverse: true,
                physics: const AlwaysScrollableScrollPhysics(),
                children: const <Widget>[
                  SizedBox(
                    height: 200.0,
                    child: Text('X'),
                  ),
                  SizedBox(
                    height: 800.0,
                    child: Text('Y'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );

    await tester.fling(find.text('X'), const Offset(0.0, 600.0), 1000.0);
    await tester.pump();
    expect(tester.widget<RefreshProgressIndicator>(find.byType(RefreshProgressIndicator)).valueColor!.value, primaryColor);
  });

  testWidgets('RefreshIndicator.color can be updated at runtime', (WidgetTester tester) async {
    refreshCalled = false;
    Color refreshIndicatorColor = Colors.green;
    const Color red = Colors.red;
    late StateSetter setState;

    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (BuildContext context, StateSetter stateSetter) {
            setState = stateSetter;
            return RefreshIndicator(
              triggerMode: RefreshIndicatorTriggerMode.anywhere,
              onRefresh: holdRefresh,
              color: refreshIndicatorColor,
              child: ListView(
                reverse: true,
                physics: const AlwaysScrollableScrollPhysics(),
                children: const <Widget>[
                  SizedBox(
                    height: 200.0,
                    child: Text('X'),
                  ),
                  SizedBox(
                    height: 800.0,
                    child: Text('Y'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );

    await tester.fling(find.text('X'), const Offset(0.0, 600.0), 1000.0);
    await tester.pump();
    expect(tester.widget<RefreshProgressIndicator>(find.byType(RefreshProgressIndicator)).valueColor!.value, refreshIndicatorColor.withOpacity(1.0));

    setState(() {
      refreshIndicatorColor = red;
    });

    await tester.pump();
    expect(tester.widget<RefreshProgressIndicator>(find.byType(RefreshProgressIndicator)).valueColor!.value, red.withOpacity(1.0));
  });

  testWidgets('RefreshIndicator - reverse - BouncingScrollPhysics', (WidgetTester tester) async {
    refreshCalled = false;
    await tester.pumpWidget(
      MaterialApp(
        home: RefreshIndicator(
          onRefresh: refresh,
          child: ListView(
            reverse: true,
            physics: const BouncingScrollPhysics(),
            children: <Widget>[
              for (int i = 0; i < 4; i++)
                SizedBox(
                  height: 200.0,
                  child: Text('X - $i'),
                ),
            ],
          )
        ),
      ),
    );

    // Scroll to top
    await tester.fling(find.text('X - 0'), const Offset(0.0, 800.0), 1000.0);
    await tester.pumpAndSettle();

    // Fling down to show refresh indicator
    await tester.fling(find.text('X - 3'), const Offset(0.0, 250.0), 1000.0);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1)); // finish the scroll animation
    await tester.pump(const Duration(seconds: 1)); // finish the indicator settle animation
    await tester.pump(const Duration(seconds: 1)); // finish the indicator hide animation
    expect(refreshCalled, true);
  });
}
