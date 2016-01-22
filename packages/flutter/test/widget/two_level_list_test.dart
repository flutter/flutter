// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart';
import 'package:test/test.dart';

void main() {
  test('TwoLeveList basics', () {
    final Key topKey = new UniqueKey();
    final Key sublistKey = new UniqueKey();
    final Key bottomKey = new UniqueKey();

    final Map<String, RouteBuilder> routes = <String, RouteBuilder>{
      '/': (_) {
        return new Material(
          child: new Viewport(
            child: new TwoLevelList(
              items: <Widget>[
                new TwoLevelListItem(center: new Text('Top'), key: topKey),
                new TwoLevelSublist(
                  key: sublistKey,
                  center: new Text('Sublist'),
                  children: <Widget>[
                    new TwoLevelListItem(center: new Text('0')),
                    new TwoLevelListItem(center: new Text('1'))
                  ]
                ),
                new TwoLevelListItem(center: new Text('Bottom'), key: bottomKey)
              ]
            )
          )
        );
      }
    };

    testWidgets((WidgetTester tester) {
      tester.pumpWidget(new MaterialApp(routes: routes));

      expect(tester.findText('Top'), isNotNull);
      expect(tester.findText('Sublist'), isNotNull);
      expect(tester.findText('Bottom'), isNotNull);

      double getY(Key key) => tester.getTopLeft(tester.findElementByKey(key)).y;
      double getHeight(Key key) => tester.getSize(tester.findElementByKey(key)).height;

      expect(getY(topKey), lessThan(getY(sublistKey)));
      expect(getY(sublistKey), lessThan(getY(bottomKey)));

      expect(getHeight(topKey), equals(getHeight(sublistKey)));
      expect(getHeight(sublistKey), equals(getHeight(bottomKey)));

      tester.tap(tester.findText('Sublist'));
      tester.pump(const Duration(seconds: 1));
      tester.pump(const Duration(seconds: 1));

      expect(tester.findText('Top'), isNotNull);
      expect(tester.findText('Sublist'), isNotNull);
      expect(tester.findText('0'), isNotNull);
      expect(tester.findText('1'), isNotNull);
      expect(tester.findText('Bottom'), isNotNull);

      expect(getY(topKey), lessThan(getY(sublistKey)));
      expect(getY(sublistKey), lessThan(getY(bottomKey)));
      expect(getY(bottomKey) - getY(sublistKey), greaterThan(getHeight(topKey)));
      expect(getY(bottomKey) - getY(sublistKey), greaterThan(getHeight(bottomKey)));
    });
  });
}
