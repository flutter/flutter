// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';


void main() {
  testWidgets('ResizingHeaderSliver basics', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CustomScrollView(
            slivers: <Widget>[
              const ResizingHeaderSliver(
                minExtentPrototype: SizedBox(height: 100),
                maxExtentPrototype: SizedBox(height: 300),
                child: SizedBox(height: 300, child: Text('header')),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (BuildContext context, int index) => SizedBox(height: 50, child: Text('$index')),
                  childCount: 100,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    double getHeaderHeight() => tester.getSize(find.text('header')).height;

    expect(getHeaderHeight(), 300);

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -200));
    await tester.pumpAndSettle();
    expect(getHeaderHeight(), 100);

    await tester.drag(find.byType(CustomScrollView), const Offset(0, 200));
    await tester.pumpAndSettle();
    expect(getHeaderHeight(), 300);
  });

  testWidgets('ResizingHeaderSliver overrides initial out of bounds child size', (WidgetTester tester) async {
    Widget buildFrame(double childHeight) {
      return MaterialApp(
        home: Scaffold(
          body: CustomScrollView(
            slivers: <Widget>[
              ResizingHeaderSliver(
                minExtentPrototype: const SizedBox(height: 100),
                maxExtentPrototype: const SizedBox(height: 300),
                child: SizedBox(height: childHeight, child: const Text('header')),
              ),
            ],
          ),
        ),
      );
    }

    await tester.pumpWidget(buildFrame(50));
    expect(tester.getSize(find.text('header')).height, 100);

    await tester.pumpWidget(buildFrame(350));
    expect(tester.getSize(find.text('header')).height, 300);
  });

  testWidgets('ResizingHeaderSliver update prototypes', (WidgetTester tester) async {
    Widget buildFrame(double minHeight, double maxHeight) {
      return MaterialApp(
        home: Scaffold(
          body: CustomScrollView(
            slivers: <Widget>[
              ResizingHeaderSliver(
                minExtentPrototype: SizedBox(height: minHeight),
                maxExtentPrototype: SizedBox(height: maxHeight),
                child: const SizedBox(height: 300, child: Text('header')),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (BuildContext context, int index) => SizedBox(height: 50, child: Text('$index')),
                  childCount: 100,
                ),
              ),
            ],
          ),
        ),
      );
    }


    double getHeaderHeight() => tester.getSize(find.text('header')).height;

    await tester.pumpWidget(buildFrame(100, 300));
    expect(getHeaderHeight(), 300);

    // Scroll more than needed to reach the min and max header heights.

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(getHeaderHeight(), 100);

    await tester.drag(find.byType(CustomScrollView), const Offset(0, 300));
    await tester.pumpAndSettle();
    expect(getHeaderHeight(), 300);

    // Change min,maxExtentPrototype widget heights from 150,200 to

    await tester.pumpWidget(buildFrame(150, 200));
    expect(getHeaderHeight(), 200);

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -100));
    await tester.pumpAndSettle();
    expect(getHeaderHeight(), 150);

    await tester.drag(find.byType(CustomScrollView), const Offset(0, 100));
    await tester.pumpAndSettle();
    expect(getHeaderHeight(), 200);
  });
}
