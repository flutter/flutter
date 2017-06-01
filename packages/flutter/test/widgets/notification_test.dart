// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';

class MyNotification extends Notification { }

void main() {
  testWidgets('Notification basics - toString', (WidgetTester tester) async {
    expect(new MyNotification(), hasOneLineDescription);
  });

  testWidgets('Notification basics - dispatch', (WidgetTester tester) async {
    final List<dynamic> log = <dynamic>[];
    final GlobalKey key = new GlobalKey();
    await tester.pumpWidget(new NotificationListener<MyNotification>(
      onNotification: (MyNotification value) {
        log.add('a');
        log.add(value);
        return true;
      },
      child: new NotificationListener<MyNotification>(
        onNotification: (MyNotification value) {
          log.add('b');
          log.add(value);
          return false;
        },
        child: new Container(key: key),
      ),
    ));
    expect(log, isEmpty);
    final Notification notification = new MyNotification();
    expect(() { notification.dispatch(key.currentContext); }, isNot(throwsException));
    expect(log, <dynamic>['b', notification, 'a', notification]);
  });

  testWidgets('Notification basics - cancel', (WidgetTester tester) async {
    final List<dynamic> log = <dynamic>[];
    final GlobalKey key = new GlobalKey();
    await tester.pumpWidget(new NotificationListener<MyNotification>(
      onNotification: (MyNotification value) {
        log.add('a - error');
        log.add(value);
        return true;
      },
      child: new NotificationListener<MyNotification>(
        onNotification: (MyNotification value) {
          log.add('b');
          log.add(value);
          return true;
        },
        child: new Container(key: key),
      ),
    ));
    expect(log, isEmpty);
    final Notification notification = new MyNotification();
    expect(() { notification.dispatch(key.currentContext); }, isNot(throwsException));
    expect(log, <dynamic>['b', notification]);
  });

  testWidgets('Notification basics - listener null return value', (WidgetTester tester) async {
    final List<Type> log = <Type>[];
    final GlobalKey key = new GlobalKey();
    await tester.pumpWidget(new NotificationListener<MyNotification>(
      onNotification: (MyNotification value) {
        log.add(value.runtimeType);
      },
      child: new NotificationListener<MyNotification>(
        onNotification: (MyNotification value) { },
        child: new Container(key: key),
      ),
    ));
    expect(() { new MyNotification().dispatch(key.currentContext); }, isNot(throwsException));
    expect(log, <Type>[MyNotification]);
  });
}
