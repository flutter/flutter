// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui show window;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stocks/main.dart' as stocks;
import 'package:stocks/stock_data.dart' as stock_data;
import 'package:test/test.dart';

Element findElementOfExactWidgetTypeGoingDown(Element node, Type targetType) {
  void walker(Element child) {
    if (child.widget.runtimeType == targetType)
      throw child;
    child.visitChildElements(walker);
  }
  try {
    walker(node);
  } on Element catch (result) {
    return result;
  }
  return null;
}

Element findElementOfExactWidgetTypeGoingUp(Element node, Type targetType) {
  Element result;
  bool walker(Element ancestor) {
    if (ancestor.widget.runtimeType == targetType)
      result = ancestor;
    return result == null;
  }
  node.visitAncestorElements(walker);
  return result;
}

final RegExp materialIconAssetNameColorExtractor = new RegExp(r'[^/]+/ic_.+_(white|black)_[0-9]+dp\.png');

void checkIconColor(WidgetTester tester, String label, Color color) {
  // The icon is going to be in the same merged semantics box as the text
  // regardless of how the menu item is represented, so this is a good
  // way to find the menu item. I hope.
  Element semantics = findElementOfExactWidgetTypeGoingUp(tester.element(find.text(label)), MergeSemantics);
  expect(semantics, isNotNull);
  Element asset = findElementOfExactWidgetTypeGoingDown(semantics, Text);
  Text text = asset.widget;
  expect(text.style.color, equals(color));
}

void main() {
  stock_data.StockDataFetcher.actuallyFetchData = false;

  testWidgets("Test icon colors", (WidgetTester tester) {
    stocks.main(); // builds the app and schedules a frame but doesn't trigger one
    tester.pump(); // see https://github.com/flutter/flutter/issues/1865
    tester.pump(); // triggers a frame

    // sanity check
    expect(find.text('MARKET'), findsOneWidget);
    expect(find.text('Help & Feedback'), findsNothing);
    tester.pump(new Duration(seconds: 2));
    expect(find.text('MARKET'), findsOneWidget);
    expect(find.text('Help & Feedback'), findsNothing);

    // drag the drawer out
    Point left = new Point(0.0, ui.window.size.height / 2.0);
    Point right = new Point(ui.window.size.width, left.y);
    TestGesture gesture = tester.startGesture(left);
    tester.pump();
    gesture.moveTo(right);
    tester.pump();
    gesture.up();
    tester.pump();
    expect(find.text('MARKET'), findsOneWidget);
    expect(find.text('Help & Feedback'), findsOneWidget);

    // check the colour of the icon - light mode
    checkIconColor(tester, 'Stock List', Colors.purple[500]); // theme primary color
    checkIconColor(tester, 'Account Balance', Colors.black45); // enabled
    checkIconColor(tester, 'Help & Feedback', Colors.black26); // disabled

    // switch to dark mode
    tester.tap(find.text('Pessimistic'));
    tester.pump(); // get the tap and send the notification that the theme has changed
    tester.pump(); // start the theme transition
    tester.pump(const Duration(seconds: 5)); // end the transition

    // check the colour of the icon - dark mode
    checkIconColor(tester, 'Stock List', Colors.redAccent[200]); // theme accent color
    checkIconColor(tester, 'Account Balance', Colors.white); // enabled
    checkIconColor(tester, 'Help & Feedback', Colors.white30); // disabled
  });
}
