// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:test/test.dart';

Widget buildFrame({ List<String> tabs, String value, bool isScrollable: false }) {
  return new Material(
    child: new TabBarSelection<String>(
      value: value,
      values: tabs,
      child: new TabBar<String>(
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
}
