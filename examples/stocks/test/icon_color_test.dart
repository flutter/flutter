// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui show window;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stocks/main.dart' as stocks;
import 'package:stocks/stock_data.dart' as stock_data;

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

final RegExp materialIconAssetNameColorExtractor = RegExp(r'[^/]+/ic_.+_(white|black)_[0-9]+dp\.png');

void checkIconColor(WidgetTester tester, String label, Color color) {
  final Element listTile = findElementOfExactWidgetTypeGoingUp(tester.element(find.text(label)), ListTile);
  expect(listTile, isNotNull);
  final Element asset = findElementOfExactWidgetTypeGoingDown(listTile, RichText);
  final RichText richText = asset.widget;
  expect(richText.text.style.color, equals(color));
}

void main() {
  stock_data.StockData.actuallyFetchData = false;

  testWidgets('Icon colors', (WidgetTester tester) async {
    stocks.main(); // builds the app and schedules a frame but doesn't trigger one
    await tester.pump(); // see https://github.com/flutter/flutter/issues/1865
    await tester.pump(); // triggers a frame

    // sanity check
    expect(find.text('MARKET'), findsOneWidget);
    expect(find.text('Account Balance'), findsNothing);
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('MARKET'), findsOneWidget);
    expect(find.text('Account Balance'), findsNothing);

    // drag the drawer out
    final Offset left = Offset(0.0, (ui.window.physicalSize / ui.window.devicePixelRatio).height / 2.0);
    final Offset right = Offset((ui.window.physicalSize / ui.window.devicePixelRatio).width, left.dy);
    final TestGesture gesture = await tester.startGesture(left);
    await tester.pump();
    await gesture.moveTo(right);
    await tester.pump();
    await gesture.up();
    await tester.pump();
    expect(find.text('MARKET'), findsOneWidget);
    expect(find.text('Account Balance'), findsOneWidget);

    // check the colour of the icon - light mode
    checkIconColor(tester, 'Stock List', Colors.purple); // theme primary color
    checkIconColor(tester, 'Account Balance', Colors.black38); // disabled
    checkIconColor(tester, 'About', Colors.black45); // enabled

    // switch to dark mode
    await tester.tap(find.text('Pessimistic'));
    await tester.pump(); // get the tap and send the notification that the theme has changed
    await tester.pump(); // start the theme transition
    await tester.pump(const Duration(seconds: 5)); // end the transition

    // check the colour of the icon - dark mode
    checkIconColor(tester, 'Stock List', Colors.redAccent); // theme accent color
    checkIconColor(tester, 'Account Balance', Colors.white30); // disabled
    checkIconColor(tester, 'About', Colors.white); // enabled
  });
}
