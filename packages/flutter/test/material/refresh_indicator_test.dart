// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

bool refreshCalled = false;

Future<Null> refresh() {
  refreshCalled = true;
  return new Future<Null>.value();
}

Future<Null> holdRefresh() {
  refreshCalled = true;
  return new Completer<Null>().future;
}

void main() {
  testWidgets('RefreshIndicator', (WidgetTester tester) async {
    refreshCalled = false;
    await tester.pumpWidget(
      new MaterialApp(
        home: new RefreshIndicator(
          onRefresh: refresh,
          child: new ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: <String>['A', 'B', 'C', 'D', 'E', 'F'].map((String item) {
              return new SizedBox(
                height: 200.0,
                child: new Text(item),
              );
            }).toList(),
          ),
        ),
      ),
    );

    await tester.fling(find.text('A'), const Offset(0.0, 300.0), 1000.0);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1)); // finish the scroll animation
    await tester.pump(const Duration(seconds: 1)); // finish the indicator settle animation
    await tester.pump(const Duration(seconds: 1)); // finish the indicator hide animation
    expect(refreshCalled, true);
  });

  testWidgets('Refresh Indicator - nested', (WidgetTester tester) async {
    refreshCalled = false;
    await tester.pumpWidget(
      new MaterialApp(
        home: new RefreshIndicator(
          notificationPredicate: (ScrollNotification notification) => notification.depth == 1,
          onRefresh: refresh,
          child: new SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: new Container(
              width: 600.0,
              child: new ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: <String>['A', 'B', 'C', 'D', 'E', 'F'].map((String item) {
                  return new SizedBox(
                    height: 200.0,
                    child: new Text(item),
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
      new MaterialApp(
        home: new RefreshIndicator(
          onRefresh: refresh,
          child: new ListView(
            reverse: true,
            physics: const AlwaysScrollableScrollPhysics(),
            children: const <Widget>[
              const SizedBox(
                height: 200.0,
                child: const Text('X'),
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
      new MaterialApp(
        home: new RefreshIndicator(
          onRefresh: holdRefresh,
          child: new ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: const <Widget>[
              const SizedBox(
                height: 200.0,
                child: const Text('X'),
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
      new MaterialApp(
        home: new RefreshIndicator(
          onRefresh: holdRefresh,
          child: new ListView(
            reverse: true,
            physics: const AlwaysScrollableScrollPhysics(),
            children: const <Widget>[
              const SizedBox(
                height: 200.0,
                child: const Text('X'),
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
      new MaterialApp(
        home: new RefreshIndicator(
          onRefresh: refresh,
          child: new ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: const <Widget>[
              const SizedBox(
                height: 200.0,
                child: const Text('X'),
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
      new MaterialApp(
        home: new RefreshIndicator(
          onRefresh: refresh,
          child: new ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: const <Widget>[
              const SizedBox(
                height: 200.0,
                child: const Text('X'),
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
      new MaterialApp(
        home: new RefreshIndicator(
          onRefresh: holdRefresh, // this one never returns
          child: new ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: const <Widget>[
              const SizedBox(
                height: 200.0,
                child: const Text('X'),
              ),
            ],
          ),
        ),
      ),
    );

    bool completed = false;
    tester.state<RefreshIndicatorState>(find.byType(RefreshIndicator))
      .show()
      .then<Null>((Null value) { completed = true; });
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
      .then<Null>((Null value) { completed = true; });
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
      new MaterialApp(
        home: new RefreshIndicator(
          onRefresh: refresh,
          child: new ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: const <Widget>[
              const SizedBox(
                height: 200.0,
                child: const Text('X'),
              ),
            ],
          ),
        ),
      ),
    );

    bool completed = false;
    tester.state<RefreshIndicatorState>(find.byType(RefreshIndicator))
      .show()
      .then<Null>((Null value) { completed = true; });
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
      .then<Null>((Null value) { completed = true; });
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
      new MaterialApp(
        home: new RefreshIndicator(
          onRefresh: refresh,
          child: new ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: const <Widget>[
              const SizedBox(
                height: 200.0,
                child: const Text('X'),
              ),
            ],
          ),
        ),
      ),
    );

    bool completed1 = false;
    tester.state<RefreshIndicatorState>(find.byType(RefreshIndicator))
      .show()
      .then<Null>((Null value) { completed1 = true; });
    bool completed2 = false;
    tester.state<RefreshIndicatorState>(find.byType(RefreshIndicator))
      .show()
      .then<Null>((Null value) { completed2 = true; });
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
      new MaterialApp(
        home: new RefreshIndicator(
          onRefresh: () {
            refreshCalled = true;
            // Missing a returned Future value here.
          },
          child: new ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: <String>['A', 'B', 'C', 'D', 'E', 'F'].map((String item) {
              return new SizedBox(
                height: 200.0,
                child: new Text(item),
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
}
