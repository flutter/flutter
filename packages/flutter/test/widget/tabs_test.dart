// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:test/test.dart';

Widget buildFrame({ List<String> tabs, String value, bool isScrollable: false, Key tabBarKey }) {
  return new Material(
    child: new TabBarSelection<String>(
      value: value,
      values: tabs,
      child: new TabBar<String>(
        key: tabBarKey,
        labels: new Map<String, TabLabel>.fromIterable(tabs, value: (String tab) => new TabLabel(text: tab)),
        isScrollable: isScrollable
      )
    )
  );
}

void main() {
  test('TabBar tap selects tab', () {
    testWidgets((WidgetTester tester) {
      List<String> tabs = <String>['A', 'B', 'C'];

      tester.pumpWidget(buildFrame(tabs: tabs, value: 'C', isScrollable: false));
      TabBarSelectionState<String> selection = TabBarSelection.of(tester.findText('A'));
      expect(selection, isNotNull);
      expect(selection.indexOf('A'), equals(0));
      expect(selection.indexOf('B'), equals(1));
      expect(selection.indexOf('C'), equals(2));
      expect(tester.findText('A'), isNotNull);
      expect(tester.findText('B'), isNotNull);
      expect(tester.findText('C'), isNotNull);
      expect(selection.index, equals(2));
      expect(selection.previousIndex, equals(2));
      expect(selection.value, equals('C'));
      expect(selection.previousValue, equals('C'));

      tester.pumpWidget(buildFrame(tabs: tabs, value: 'C' ,isScrollable: false));
      tester.tap(tester.findText('B'));
      tester.pump();
      expect(selection.valueIsChanging, true);
      tester.pump(const Duration(seconds: 1)); // finish the animation
      expect(selection.valueIsChanging, false);
      expect(selection.value, equals('B'));
      expect(selection.previousValue, equals('C'));
      expect(selection.index, equals(1));
      expect(selection.previousIndex, equals(2));

      tester.pumpWidget(buildFrame(tabs: tabs, value: 'C', isScrollable: false));
      tester.tap(tester.findText('C'));
      tester.pump();
      tester.pump(const Duration(seconds: 1));
      expect(selection.value, equals('C'));
      expect(selection.previousValue, equals('B'));
      expect(selection.index, equals(2));
      expect(selection.previousIndex, equals(1));

      tester.pumpWidget(buildFrame(tabs: tabs, value: 'C', isScrollable: false));
      tester.tap(tester.findText('A'));
      tester.pump();
      tester.pump(const Duration(seconds: 1));
      expect(selection.value, equals('A'));
      expect(selection.previousValue, equals('C'));
      expect(selection.index, equals(0));
      expect(selection.previousIndex, equals(2));
    });
  });

  test('Scrollable TabBar tap selects tab', () {
    testWidgets((WidgetTester tester) {
      List<String> tabs = <String>['A', 'B', 'C'];

      tester.pumpWidget(buildFrame(tabs: tabs, value: 'C', isScrollable: true));
      TabBarSelectionState<String> selection = TabBarSelection.of(tester.findText('A'));
      expect(selection, isNotNull);
      expect(tester.findText('A'), isNotNull);
      expect(tester.findText('B'), isNotNull);
      expect(tester.findText('C'), isNotNull);
      expect(selection.value, equals('C'));

      tester.pumpWidget(buildFrame(tabs: tabs, value: 'C', isScrollable: true));
      tester.tap(tester.findText('B'));
      tester.pump();
      expect(selection.value, equals('B'));

      tester.pumpWidget(buildFrame(tabs: tabs, value: 'C', isScrollable: true));
      tester.tap(tester.findText('C'));
      tester.pump();
      expect(selection.value, equals('C'));

      tester.pumpWidget(buildFrame(tabs: tabs, value: 'C', isScrollable: true));
      tester.tap(tester.findText('A'));
      tester.pump();
      expect(selection.value, equals('A'));
    });
  });

  test('Scrollable TabBar tap centers selected tab', () {
    testWidgets((WidgetTester tester) {
      List<String> tabs = <String>['AAAAAA', 'BBBBBB', 'CCCCCC', 'DDDDDD', 'EEEEEE', 'FFFFFF', 'GGGGGG', 'HHHHHH', 'IIIIII', 'JJJJJJ', 'KKKKKK', 'LLLLLL'];
      Key tabBarKey = new Key('TabBar');
      tester.pumpWidget(buildFrame(tabs: tabs, value: 'AAAAAA', isScrollable: true, tabBarKey: tabBarKey));
      TabBarSelectionState<String> selection = TabBarSelection.of(tester.findText('AAAAAA'));
      expect(selection, isNotNull);
      expect(selection.value, equals('AAAAAA'));

      expect(tester.getSize(tester.findElementByKey(tabBarKey)).width, equals(800.0));
      // The center of the FFFFFF item is to the right of the TabBar's center
      expect(tester.getCenter(tester.findText('FFFFFF')).x, greaterThan(401.0));

      tester.tap(tester.findText('FFFFFF'));
      tester.pump();
      tester.pump(const Duration(seconds: 1)); // finish the scroll animation
      expect(selection.value, equals('FFFFFF'));
      // The center of the FFFFFF item is now at the TabBar's center
      expect(tester.getCenter(tester.findText('FFFFFF')).x, closeTo(400.0, 1.0));
    });
  });


  test('TabBar can be scrolled independent of the selection', () {
    testWidgets((WidgetTester tester) {
      List<String> tabs = <String>['AAAAAA', 'BBBBBB', 'CCCCCC', 'DDDDDD', 'EEEEEE', 'FFFFFF', 'GGGGGG', 'HHHHHH', 'IIIIII', 'JJJJJJ', 'KKKKKK', 'LLLLLL'];
      Key tabBarKey = new Key('TabBar');
      tester.pumpWidget(buildFrame(tabs: tabs, value: 'AAAAAA', isScrollable: true, tabBarKey: tabBarKey));
      TabBarSelectionState<String> selection = TabBarSelection.of(tester.findText('AAAAAA'));
      expect(selection, isNotNull);
      expect(selection.value, equals('AAAAAA'));

      // Fling-scroll the TabBar to the left
      expect(tester.getCenter(tester.findText('HHHHHH')).x, lessThan(700.0));
      tester.fling(tester.findElementByKey(tabBarKey), const Offset(-20.0, 0.0), 1000.0);
      tester.pump();
      tester.pump(const Duration(seconds: 1)); // finish the scroll animation
      expect(tester.getCenter(tester.findText('HHHHHH')).x, lessThan(500.0));

      // Scrolling the TabBar doesn't change the selection
      expect(selection.value, equals('AAAAAA'));
    });
  });
}
