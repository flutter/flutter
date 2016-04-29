// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:test/test.dart';

class TestInherited extends InheritedWidget {
  TestInherited({ Key key, Widget child, this.shouldNotify: true })
    : super(key: key, child: child);

  final bool shouldNotify;

  @override
  bool updateShouldNotify(InheritedWidget oldWidget) {
    return shouldNotify;
  }
}

void main() {
  testWidgets('Inherited notifies dependents', (WidgetTester tester) {
    List<TestInherited> log = <TestInherited>[];

    Builder builder = new Builder(
      builder: (BuildContext context) {
        log.add(context.inheritFromWidgetOfExactType(TestInherited));
        return new Container();
      }
    );

    TestInherited first = new TestInherited(child: builder);
    tester.pumpWidget(first);

    expect(log, equals([first]));

    TestInherited second = new TestInherited(child: builder, shouldNotify: false);
    tester.pumpWidget(second);

    expect(log, equals([first]));

    TestInherited third = new TestInherited(child: builder, shouldNotify: true);
    tester.pumpWidget(third);

    expect(log, equals([first, third]));
  });

  testWidgets('Update inherited when reparenting state', (WidgetTester tester) {
    GlobalKey globalKey = new GlobalKey();
    List<TestInherited> log = <TestInherited>[];

    TestInherited build() {
      return new TestInherited(
        key: new UniqueKey(),
        child: new Container(
          key: globalKey,
          child: new Builder(
            builder: (BuildContext context) {
              log.add(context.inheritFromWidgetOfExactType(TestInherited));
              return new Container();
            }
          )
        )
      );
    }

    TestInherited first = build();
    tester.pumpWidget(first);

    expect(log, equals([first]));

    TestInherited second = build();
    tester.pumpWidget(second);

    expect(log, equals([first, second]));
  });
}
