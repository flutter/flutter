// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:test/test.dart';

import 'test_widgets.dart';

class TestInherited extends InheritedWidget {
  TestInherited({ Key key, Widget child, this.shouldNotify: true })
    : super(key: key, child: child);

  final bool shouldNotify;

  @override
  bool updateShouldNotify(InheritedWidget oldWidget) {
    return shouldNotify;
  }
}

class ValueInherited extends InheritedWidget {
  ValueInherited({ Key key, Widget child, this.value })
    : super(key: key, child: child);

  final int value;

  @override
  bool updateShouldNotify(ValueInherited oldWidget) => value != oldWidget.value;
}

void main() {
  test('Inherited notifies dependents', () {
    testWidgets((WidgetTester tester) {
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
  });

  test('Update inherited when reparenting state', () {
    testWidgets((WidgetTester tester) {
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
  });

  test('Update inherited when removing node', () {
    testWidgets((WidgetTester tester) {

      final List<String> log = <String>[];

      tester.pumpWidget(
        new Container(
          child: new ValueInherited(
            value: 1,
            child: new Container(
              child: new FlipWidget(
                left: new Container(
                  child: new ValueInherited(
                    value: 2,
                    child: new Container(
                      child: new ValueInherited(
                        value: 3,
                        child: new Container(
                          child: new Builder(
                            builder: (BuildContext context) {
                              ValueInherited v = context.inheritFromWidgetOfExactType(ValueInherited);
                              log.add('a: ${v.value}');
                              return new Text('');
                            }
                          )
                        )
                      )
                    )
                  )
                ),
                right: new Container(
                  child: new ValueInherited(
                    value: 2,
                    child: new Container(
                      child: new Container(
                        child: new Builder(
                          builder: (BuildContext context) {
                            ValueInherited v = context.inheritFromWidgetOfExactType(ValueInherited);
                            log.add('b: ${v.value}');
                            return new Text('');
                          }
                        )
                      )
                    )
                  )
                )
              )
            )
          )
        )
      );

      expect(log, equals(<String>['a: 3']));
      log.clear();

      tester.pump();

      expect(log, equals(<String>[]));
      log.clear();

      flipStatefulWidget(tester);
      tester.pump();

      expect(log, equals(<String>['b: 2']));
      log.clear();

      flipStatefulWidget(tester);
      tester.pump();

      expect(log, equals(<String>['a: 3']));
      log.clear();
    });
  });

  test('Update inherited when removing node and child has global key', () {
    testWidgets((WidgetTester tester) {

      final List<String> log = <String>[];

      Key key = new GlobalKey();

      tester.pumpWidget(
        new Container(
          child: new ValueInherited(
            value: 1,
            child: new Container(
              child: new FlipWidget(
                left: new Container(
                  child: new ValueInherited(
                    value: 2,
                    child: new Container(
                      child: new ValueInherited(
                        value: 3,
                        child: new Container(
                          key: key,
                          child: new Builder(
                            builder: (BuildContext context) {
                              ValueInherited v = context.inheritFromWidgetOfExactType(ValueInherited);
                              log.add('a: ${v.value}');
                              return new Text('');
                            }
                          )
                        )
                      )
                    )
                  )
                ),
                right: new Container(
                  child: new ValueInherited(
                    value: 2,
                    child: new Container(
                      child: new Container(
                        key: key,
                        child: new Builder(
                          builder: (BuildContext context) {
                            ValueInherited v = context.inheritFromWidgetOfExactType(ValueInherited);
                            log.add('b: ${v.value}');
                            return new Text('');
                          }
                        )
                      )
                    )
                  )
                )
              )
            )
          )
        )
      );

      expect(log, equals(<String>['a: 3']));
      log.clear();

      tester.pump();

      expect(log, equals(<String>[]));
      log.clear();

      flipStatefulWidget(tester);
      tester.pump();

      expect(log, equals(<String>['b: 2']));
      log.clear();

      flipStatefulWidget(tester);
      tester.pump();

      expect(log, equals(<String>['a: 3']));
      log.clear();
    });
  });

  test('Update inherited when removing node and child has global key with constant child', () {
    testWidgets((WidgetTester tester) {

      final List<int> log = <int>[];

      Key key = new GlobalKey();

      Widget child = new Builder(
        builder: (BuildContext context) {
          ValueInherited v = context.inheritFromWidgetOfExactType(ValueInherited);
          log.add(v.value);
          return new Text('');
        }
      );

      tester.pumpWidget(
        new Container(
          child: new ValueInherited(
            value: 1,
            child: new Container(
              child: new FlipWidget(
                left: new Container(
                  child: new ValueInherited(
                    value: 2,
                    child: new Container(
                      child: new ValueInherited(
                        value: 3,
                        child: new Container(
                          key: key,
                          child: child
                        )
                      )
                    )
                  )
                ),
                right: new Container(
                  child: new ValueInherited(
                    value: 2,
                    child: new Container(
                      child: new Container(
                        key: key,
                        child: child
                      )
                    )
                  )
                )
              )
            )
          )
        )
      );

      expect(log, equals(<int>[3]));
      log.clear();

      tester.pump();

      expect(log, equals(<int>[]));
      log.clear();

      flipStatefulWidget(tester);
      tester.pump();

      expect(log, equals(<int>[2]));
      log.clear();

      flipStatefulWidget(tester);
      tester.pump();

      expect(log, equals(<int>[3]));
      log.clear();
    });
  });

  test('Update inherited when removing node and child has global key with constant child, minimised', () {
    testWidgets((WidgetTester tester) {

      final List<int> log = <int>[];

      Widget child = new Builder(
        key: new GlobalKey(),
        builder: (BuildContext context) {
          ValueInherited v = context.inheritFromWidgetOfExactType(ValueInherited);
          log.add(v.value);
          return new Text('');
        }
      );

      tester.pumpWidget(
        new ValueInherited(
          value: 2,
          child: new FlipWidget(
            left: new ValueInherited(
              value: 3,
              child: child
            ),
            right: child
          )
        )
      );

      expect(log, equals(<int>[3]));
      log.clear();

      tester.pump();

      expect(log, equals(<int>[]));
      log.clear();

      flipStatefulWidget(tester);
      tester.pump();

      expect(log, equals(<int>[2]));
      log.clear();

      flipStatefulWidget(tester);
      tester.pump();

      expect(log, equals(<int>[3]));
      log.clear();
    });
  });
}
