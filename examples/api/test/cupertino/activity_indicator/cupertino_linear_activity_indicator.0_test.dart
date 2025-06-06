// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter_api_samples/cupertino/activity_indicator/cupertino_linear_activity_indicator.0.dart'
    as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Default and customized cupertino activity indicators', (WidgetTester tester) async {
    await tester.pumpWidget(const example.CupertinoLinearActivityIndicatorApp());

    final Finder firstIndicator = find.byType(CupertinoLinearActivityIndicator).first;
    final CupertinoLinearActivityIndicator firstWidget = tester
        .widget<CupertinoLinearActivityIndicator>(firstIndicator);
    expect(firstWidget.progress, 0);
    expect(firstWidget.height, 4.5);
    expect(firstWidget.color, isNull);

    final Finder secondIndicator = find.byType(CupertinoLinearActivityIndicator).at(1);
    final CupertinoLinearActivityIndicator secondWidget = tester
        .widget<CupertinoLinearActivityIndicator>(secondIndicator);
    expect(secondWidget.progress, 0.2);
    expect(secondWidget.height, 4.5);
    expect(secondWidget.color, isNull);

    final Finder thirdIndicator = find.byType(CupertinoLinearActivityIndicator).at(2);
    final CupertinoLinearActivityIndicator thirdWidget = tester
        .widget<CupertinoLinearActivityIndicator>(thirdIndicator);
    expect(thirdWidget.progress, 0.4);
    expect(thirdWidget.height, 10);
    expect(thirdWidget.color, isNull);

    final Finder lastIndicator = find.byType(CupertinoLinearActivityIndicator).last;
    final CupertinoLinearActivityIndicator lastWidget = tester
        .widget<CupertinoLinearActivityIndicator>(lastIndicator);
    expect(lastWidget.progress, 0.6);
    expect(lastWidget.height, 4.5);
    expect(lastWidget.color, CupertinoColors.activeGreen);
  });
}
