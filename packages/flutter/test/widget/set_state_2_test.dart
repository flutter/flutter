// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:test/test.dart';

void main() {
  test('setState() overbuild test', () {
    testWidgets((WidgetTester tester) {
      List<String> log = <String>[];
      Builder inner = new Builder(
        builder: (BuildContext context) {
          log.add('inner');
          return new Text('inner');
        }
      );
      int value = 0;
      tester.pumpWidget(new Builder(
        builder: (BuildContext context) {
          log.add('outer');
          return new StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              log.add('stateful');
              return new GestureDetector(
                onTap: () {
                  setState(() {
                    value += 1;
                  });
                },
                child: new Builder(
                  builder: (BuildContext context) {
                    log.add('middle $value');
                    return inner;
                  }
                )
              );
            }
          );
        }
      ));
      log.add('---');
      tester.tap(tester.findText('inner'));;
      tester.pump();
      log.add('---');
      expect(log, equals(<String>[
        'outer',
        'stateful',
        'middle 0',
        'inner',
        '---',
        'stateful',
        'middle 1',
        '---',
      ]));
    });
  });
}
