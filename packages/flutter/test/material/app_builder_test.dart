// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('builder doesn\'t get called if app doesn\'t change', (WidgetTester tester) async {
    final List<String> log = <String>[];
    final Widget app = new MaterialApp(
      theme: new ThemeData(
        primarySwatch: Colors.green,
      ),
      home: const Placeholder(),
      builder: (BuildContext context, Widget child) {
        log.add('build');
        expect(Theme.of(context).primaryColor, Colors.green);
        expect(Directionality.of(context), TextDirection.ltr);
        expect(child, const isInstanceOf<Navigator>());
        return const Placeholder();
      },
    );
    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.rtl,
        child: app,
      ),
    );
    expect(log, <String>['build']);
    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.ltr,
        child: app,
      ),
    );
    expect(log, <String>['build']);
  });

  testWidgets('builder doesn\'t get called if app doesn\'t change', (WidgetTester tester) async {
    final List<String> log = <String>[];
    await tester.pumpWidget(
      new MaterialApp(
        theme: new ThemeData(
          primarySwatch: Colors.yellow,
        ),
        home: new Builder(
          builder: (BuildContext context) {
            log.add('build');
            expect(Theme.of(context).primaryColor, Colors.yellow);
            expect(Directionality.of(context), TextDirection.rtl);
            return const Placeholder();
          },
        ),
        builder: (BuildContext context, Widget child) {
          return new Directionality(
            textDirection: TextDirection.rtl,
            child: child,
          );
        },
      ),
    );
    expect(log, <String>['build']);
  });
}
