 // Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

class TestNotifier extends ChangeNotifier {
  void notify() {
    notifyListeners();
  }
}

void main() {
  testWidgets('ChangeNotifier', (WidgetTester tester) async {
    final List<String> log = <String>[];
    final VoidCallback listener = () { log.add('listener'); };
    final VoidCallback listener1 = () { log.add('listener1'); };
    final VoidCallback listener2 = () { log.add('listener2'); };
    final VoidCallback badListener = () { log.add('badListener'); throw null; };

    final TestNotifier test = new TestNotifier();

    test.addListener(listener);
    test.addListener(listener);
    test.notify();
    expect(log, equals(<String>['listener', 'listener']));
    log.clear();

    test.removeListener(listener);
    test.notify();
    expect(log, equals(<String>['listener']));
    log.clear();

    test.removeListener(listener);
    test.notify();
    expect(log, equals(<String>[]));
    log.clear();

    test.removeListener(listener);
    test.notify();
    expect(log, equals(<String>[]));
    log.clear();

    test.addListener(listener);
    test.notify();
    expect(log, equals(<String>['listener']));
    log.clear();

    test.addListener(listener1);
    test.notify();
    expect(log, equals(<String>['listener', 'listener1']));
    log.clear();

    test.addListener(listener2);
    test.notify();
    expect(log, equals(<String>['listener', 'listener1', 'listener2']));
    log.clear();

    test.removeListener(listener1);
    test.notify();
    expect(log, equals(<String>['listener', 'listener2']));
    log.clear();

    test.addListener(listener1);
    test.notify();
    expect(log, equals(<String>['listener', 'listener2', 'listener1']));
    log.clear();

    test.addListener(badListener);
    test.notify();
    expect(log, equals(<String>['listener', 'listener2', 'listener1', 'badListener']));
    expect(tester.takeException(), isNullThrownError);
    log.clear();

    test.addListener(listener1);
    test.removeListener(listener);
    test.removeListener(listener1);
    test.removeListener(listener2);
    test.addListener(listener2);
    test.notify();
    expect(log, equals(<String>['badListener', 'listener1', 'listener2']));
    expect(tester.takeException(), isNullThrownError);
    log.clear();
  });

  testWidgets('ChangeNotifier with mutating listener', (WidgetTester tester) async {
    final TestNotifier test = new TestNotifier();
    final List<String> log = <String>[];

    final VoidCallback listener1 = () { log.add('listener1'); };
    final VoidCallback listener3 = () { log.add('listener3'); };
    final VoidCallback listener4 = () { log.add('listener4'); };
    final VoidCallback listener2 = () {
      log.add('listener2');
      test.removeListener(listener1);
      test.removeListener(listener3);
      test.addListener(listener4);
    };

    test.addListener(listener1);
    test.addListener(listener2);
    test.addListener(listener3);
    test.notify();
    expect(log, equals(<String>['listener1', 'listener2', 'listener3']));
    log.clear();

    test.notify();
    expect(log, equals(<String>['listener2', 'listener4']));
    log.clear();

    test.notify();
    expect(log, equals(<String>['listener2', 'listener4', 'listener4']));
    log.clear();
  });
}
