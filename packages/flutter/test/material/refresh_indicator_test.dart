// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

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
            child: Container(
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

  testWidgets('RefreshIndicator - bottom', (WidgetTester tester) async {
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

    await tester.fling(find.text('X'), const Offset(0.0, -300.0), 1000.0);
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

  testWidgets('RefreshIndicator - bottom - position', (WidgetTester tester) async {
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

    await tester.fling(find.text('X'), const Offset(0.0, -300.0), 1000.0);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(tester.getCenter(find.byType(RefreshProgressIndicator)).dy, greaterThan(300.0));
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

    await tester.fling(find.text('X'), const Offset(0.0, 100.0), 1000.0);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(refreshCalled, false);
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

  testWidgets('RefreshIndicator - onRefresh asserts', (WidgetTester tester) async {
    refreshCalled = false;
    await tester.pumpWidget(
      MaterialApp(
        home: RefreshIndicator(
          onRefresh: () {
            refreshCalled = true;
            return null; // Missing a returned Future value here, should cause framework to throw.
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
      ),
    );

    await tester.fling(find.text('A'), const Offset(0.0, 300.0), 1000.0);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1)); // finish the scroll animation
    expect(refreshCalled, true);
    expect(tester.takeException(), isFlutterError);
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

  testWidgets('strokeWidth cannot be null in RefreshIndicator', (WidgetTester tester) async {
    try {
      await tester.pumpWidget(
          MaterialApp(
            home: RefreshIndicator(
              onRefresh: () async {},
              strokeWidth: null,
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
          )
      );
    } on AssertionError catch(_) {
      return;
    }
    fail('The assertion was not thrown when strokeWidth was null');
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
        )
    );

    //By default the value of strokeWidth is 2.0
    expect(
        tester.widget<RefreshIndicator>(find.byType(RefreshIndicator)).strokeWidth,
        2.0,
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
        )
    );

    expect(
        tester.widget<RefreshIndicator>(find.byType(RefreshIndicator)).strokeWidth,
        4.0,
    );
  });
}
