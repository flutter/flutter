// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

class TestDelegate extends LazyBlockDelegate {
  @override
  Widget buildItem(BuildContext context, int index) {
    return new Text('$index');
  }

  @override
  double estimateTotalExtent(int firstIndex, int lastIndex, double minOffset, double firstStartOffset, double lastEndOffset) {
    return double.INFINITY;
  }

  @override
  bool shouldRebuild(LazyBlockDelegate oldDelegate) => false;
}

double currentOffset;

Future<Null> pumpTest(WidgetTester tester, TargetPlatform platform) async {
  await tester.pumpWidget(new Container());
  await tester.pumpWidget(new MaterialApp(
    theme: new ThemeData(
      platform: platform
    ),
    home: new LazyBlock(
      delegate: new TestDelegate(),
      onScroll: (double scrollOffset) { currentOffset = scrollOffset; },
    ),
  ));
  return null;
}

const double dragOffset = 213.82;

void main() {
  testWidgets('Flings on different platforms', (WidgetTester tester) async {
    await pumpTest(tester, TargetPlatform.android);
    await tester.fling(find.byType(LazyBlock), const Offset(0.0, -dragOffset), 1000.0);
    expect(currentOffset, dragOffset);
    await tester.pump(); // trigger fling
    expect(currentOffset, dragOffset);
    await tester.pump(const Duration(seconds: 5));
    final double result1 = currentOffset;

    await pumpTest(tester, TargetPlatform.iOS);
    await tester.fling(find.byType(LazyBlock), const Offset(0.0, -dragOffset), 1000.0);
    expect(currentOffset, dragOffset);
    await tester.pump(); // trigger fling
    expect(currentOffset, dragOffset);
    await tester.pump(const Duration(seconds: 5));
    final double result2 = currentOffset;

    expect(result1, lessThan(result2)); // iOS (result2) is slipperier than Android (result1)
  });

  testWidgets('fling and tap to stop', (WidgetTester tester) async {
    List<String> log = <String>[];

    List<Widget> textWidgets = <Widget>[];
    for (int i = 0; i < 250; i++)
      textWidgets.add(new GestureDetector(onTap: () { log.add('tap $i'); }, child: new Text('$i')));
    await tester.pumpWidget(new Block(children: textWidgets));

    expect(log, equals(<String>[]));
    await tester.tap(find.byType(Scrollable));
    await tester.pump(const Duration(milliseconds: 50));
    expect(log, equals(<String>['tap 18']));
    await tester.fling(find.byType(Scrollable), const Offset(0.0, -200.0), 1000.0);
    await tester.pump(const Duration(milliseconds: 50));
    expect(log, equals(<String>['tap 18']));
    await tester.tap(find.byType(Scrollable));
    await tester.pump(const Duration(milliseconds: 50));
    expect(log, equals(<String>['tap 18']));
    await tester.tap(find.byType(Scrollable));
    await tester.pump(const Duration(milliseconds: 50));
    expect(log, equals(<String>['tap 18', 'tap 31']));
  }, skip: Platform.isMacOS); // Skip due to https://github.com/flutter/flutter/issues/6961

  testWidgets('fling and wait and tap', (WidgetTester tester) async {
    List<String> log = <String>[];

    List<Widget> textWidgets = <Widget>[];
    for (int i = 0; i < 250; i++)
      textWidgets.add(new GestureDetector(onTap: () { log.add('tap $i'); }, child: new Text('$i')));
    await tester.pumpWidget(new Block(children: textWidgets));

    expect(log, equals(<String>[]));
    await tester.tap(find.byType(Scrollable));
    await tester.pump(const Duration(milliseconds: 50));
    expect(log, equals(<String>['tap 18']));
    await tester.fling(find.byType(Scrollable), const Offset(0.0, -200.0), 1000.0);
    await tester.pump(const Duration(milliseconds: 50));
    expect(log, equals(<String>['tap 18']));
    await tester.pump(const Duration(seconds: 50));
    expect(log, equals(<String>['tap 18']));
    await tester.tap(find.byType(Scrollable));
    await tester.pump(const Duration(milliseconds: 50));
    expect(log, equals(<String>['tap 18', 'tap 43']));
  }, skip: Platform.isMacOS); // Skip due to https://github.com/flutter/flutter/issues/6961
}
