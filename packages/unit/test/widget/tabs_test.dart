// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:test/test.dart';

int selectedIndex = 2;

Widget buildFrame({ List<String> tabs, bool isScrollable: false }) {
  return new TabBar(
    labels: tabs.map((String tab) => new TabLabel(text: tab)).toList(),
    selectedIndex: selectedIndex,
    isScrollable: isScrollable,
    onChanged: (int tabIndex) {
      selectedIndex = tabIndex;
    }
  );
}

void main() {
  test('TabBar tap selects tab', () {
    testWidgets((WidgetTester tester) {
      List<String> tabs = <String>['A', 'B', 'C'];
      selectedIndex = 2;

      tester.pumpWidget(buildFrame(tabs: tabs, isScrollable: false));
      expect(tester.findText('A'), isNotNull);
      expect(tester.findText('B'), isNotNull);
      expect(tester.findText('C'), isNotNull);
      expect(selectedIndex, equals(2));

      tester.pumpWidget(buildFrame(tabs: tabs, isScrollable: false));
      tester.tap(tester.findText('B'));
      tester.pump();
      expect(selectedIndex, equals(1));

      tester.pumpWidget(buildFrame(tabs: tabs, isScrollable: false));
      tester.tap(tester.findText('C'));
      tester.pump();
      expect(selectedIndex, equals(2));

      tester.pumpWidget(buildFrame(tabs: tabs, isScrollable: false));
      tester.tap(tester.findText('A'));
      tester.pump();
      expect(selectedIndex, equals(0));
    });
  });

  test('Scrollable TabBar tap selects tab', () {
    testWidgets((WidgetTester tester) {
      List<String> tabs = <String>['A', 'B', 'C'];
      selectedIndex = 2;

      tester.pumpWidget(buildFrame(tabs: tabs, isScrollable: true));
      expect(tester.findText('A'), isNotNull);
      expect(tester.findText('B'), isNotNull);
      expect(tester.findText('C'), isNotNull);
      expect(selectedIndex, equals(2));

      tester.pumpWidget(buildFrame(tabs: tabs, isScrollable: true));
      tester.tap(tester.findText('B'));
      tester.pump();
      expect(selectedIndex, equals(1));

      tester.pumpWidget(buildFrame(tabs: tabs, isScrollable: true));
      tester.tap(tester.findText('C'));
      tester.pump();
      expect(selectedIndex, equals(2));

      tester.pumpWidget(buildFrame(tabs: tabs, isScrollable: true));
      tester.tap(tester.findText('A'));
      tester.pump();
      expect(selectedIndex, equals(0));
    });
  });
}
