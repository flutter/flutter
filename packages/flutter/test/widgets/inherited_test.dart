// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

import 'test_widgets.dart';

class TestInherited extends InheritedWidget {
  const TestInherited({ Key key, Widget child, this.shouldNotify: true })
    : super(key: key, child: child);

  final bool shouldNotify;

  @override
  bool updateShouldNotify(InheritedWidget oldWidget) {
    return shouldNotify;
  }
}

class ValueInherited extends InheritedWidget {
  const ValueInherited({ Key key, Widget child, this.value })
    : super(key: key, child: child);

  final int value;

  @override
  bool updateShouldNotify(ValueInherited oldWidget) => value != oldWidget.value;
}

class ExpectFail extends StatefulWidget {
  const ExpectFail(this.onError);
  final VoidCallback onError;

  @override
  ExpectFailState createState() => new ExpectFailState();
}

class ExpectFailState extends State<ExpectFail> {
  @override
  void initState() {
    super.initState();
    try {
      context.inheritFromWidgetOfExactType(TestInherited); // should fail
    } catch (e) {
      widget.onError();
    }
  }

  @override
  Widget build(BuildContext context) => new Container();
}

void main() {
  testWidgets('Inherited notifies dependents', (WidgetTester tester) async {
    final List<TestInherited> log = <TestInherited>[];

    final Builder builder = new Builder(
      builder: (BuildContext context) {
        log.add(context.inheritFromWidgetOfExactType(TestInherited));
        return new Container();
      }
    );

    final TestInherited first = new TestInherited(child: builder);
    await tester.pumpWidget(first);

    expect(log, equals(<TestInherited>[first]));

    final TestInherited second = new TestInherited(child: builder, shouldNotify: false);
    await tester.pumpWidget(second);

    expect(log, equals(<TestInherited>[first]));

    final TestInherited third = new TestInherited(child: builder, shouldNotify: true);
    await tester.pumpWidget(third);

    expect(log, equals(<TestInherited>[first, third]));
  });

  testWidgets('Update inherited when reparenting state', (WidgetTester tester) async {
    final GlobalKey globalKey = new GlobalKey();
    final List<TestInherited> log = <TestInherited>[];

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

    final TestInherited first = build();
    await tester.pumpWidget(first);

    expect(log, equals(<TestInherited>[first]));

    final TestInherited second = build();
    await tester.pumpWidget(second);

    expect(log, equals(<TestInherited>[first, second]));
  });

  testWidgets('Update inherited when removing node', (WidgetTester tester) async {
    final List<String> log = <String>[];

    await tester.pumpWidget(
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
                            final ValueInherited v = context.inheritFromWidgetOfExactType(ValueInherited);
                            log.add('a: ${v.value}');
                            return const Text('', textDirection: TextDirection.ltr);
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
                          final ValueInherited v = context.inheritFromWidgetOfExactType(ValueInherited);
                          log.add('b: ${v.value}');
                          return const Text('', textDirection: TextDirection.ltr);
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

    await tester.pump();

    expect(log, equals(<String>[]));
    log.clear();

    flipStatefulWidget(tester);
    await tester.pump();

    expect(log, equals(<String>['b: 2']));
    log.clear();

    flipStatefulWidget(tester);
    await tester.pump();

    expect(log, equals(<String>['a: 3']));
    log.clear();
  });

  testWidgets('Update inherited when removing node and child has global key', (WidgetTester tester) async {

    final List<String> log = <String>[];

    final Key key = new GlobalKey();

    await tester.pumpWidget(
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
                            final ValueInherited v = context.inheritFromWidgetOfExactType(ValueInherited);
                            log.add('a: ${v.value}');
                            return const Text('', textDirection: TextDirection.ltr);
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
                          final ValueInherited v = context.inheritFromWidgetOfExactType(ValueInherited);
                          log.add('b: ${v.value}');
                          return const Text('', textDirection: TextDirection.ltr);
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

    await tester.pump();

    expect(log, equals(<String>[]));
    log.clear();

    flipStatefulWidget(tester);
    await tester.pump();

    expect(log, equals(<String>['b: 2']));
    log.clear();

    flipStatefulWidget(tester);
    await tester.pump();

    expect(log, equals(<String>['a: 3']));
    log.clear();
  });

  testWidgets('Update inherited when removing node and child has global key with constant child', (WidgetTester tester) async {
    final List<int> log = <int>[];

    final Key key = new GlobalKey();

    final Widget child = new Builder(
      builder: (BuildContext context) {
        final ValueInherited v = context.inheritFromWidgetOfExactType(ValueInherited);
        log.add(v.value);
        return const Text('', textDirection: TextDirection.ltr);
      }
    );

    await tester.pumpWidget(
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

    await tester.pump();

    expect(log, equals(<int>[]));
    log.clear();

    flipStatefulWidget(tester);
    await tester.pump();

    expect(log, equals(<int>[2]));
    log.clear();

    flipStatefulWidget(tester);
    await tester.pump();

    expect(log, equals(<int>[3]));
    log.clear();
  });

  testWidgets('Update inherited when removing node and child has global key with constant child, minimised', (WidgetTester tester) async {

    final List<int> log = <int>[];

    final Widget child = new Builder(
      key: new GlobalKey(),
      builder: (BuildContext context) {
        final ValueInherited v = context.inheritFromWidgetOfExactType(ValueInherited);
        log.add(v.value);
        return const Text('', textDirection: TextDirection.ltr);
      }
    );

    await tester.pumpWidget(
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

    await tester.pump();

    expect(log, equals(<int>[]));
    log.clear();

    flipStatefulWidget(tester);
    await tester.pump();

    expect(log, equals(<int>[2]));
    log.clear();

    flipStatefulWidget(tester);
    await tester.pump();

    expect(log, equals(<int>[3]));
    log.clear();
  });

  testWidgets('Inherited widget notifies descendants when descendant previously failed to find a match', (WidgetTester tester) async {
    int inheritedValue = -1;

    final Widget inner = new Container(
      key: new GlobalKey(),
      child: new Builder(
        builder: (BuildContext context) {
          final ValueInherited widget = context.inheritFromWidgetOfExactType(ValueInherited);
          inheritedValue = widget?.value;
          return new Container();
        }
      )
    );

    await tester.pumpWidget(
      inner
    );
    expect(inheritedValue, isNull);

    inheritedValue = -2;
    await tester.pumpWidget(
      new ValueInherited(
        value: 3,
        child: inner
      )
    );
    expect(inheritedValue, equals(3));
  });

  testWidgets('Inherited widget doesn\'t notify descendants when descendant did not previously fail to find a match and had no dependencies', (WidgetTester tester) async {
    int buildCount = 0;

    final Widget inner = new Container(
      key: new GlobalKey(),
      child: new Builder(
        builder: (BuildContext context) {
          buildCount += 1;
          return new Container();
        }
      )
    );

    await tester.pumpWidget(
      inner
    );
    expect(buildCount, equals(1));

    await tester.pumpWidget(
      new ValueInherited(
        value: 3,
        child: inner
      )
    );
    expect(buildCount, equals(1));
  });

  testWidgets('Inherited widget does notify descendants when descendant did not previously fail to find a match but did have other dependencies', (WidgetTester tester) async {
    int buildCount = 0;

    final Widget inner = new Container(
      key: new GlobalKey(),
      child: new TestInherited(
        shouldNotify: false,
        child: new Builder(
          builder: (BuildContext context) {
            context.inheritFromWidgetOfExactType(TestInherited);
            buildCount += 1;
            return new Container();
          }
        )
      )
    );

    await tester.pumpWidget(
      inner
    );
    expect(buildCount, equals(1));

    await tester.pumpWidget(
      new ValueInherited(
        value: 3,
        child: inner
      )
    );
    expect(buildCount, equals(2));
  });

  testWidgets('initState() dependency on Inherited asserts', (WidgetTester tester) async {
    // This is a regression test for https://github.com/flutter/flutter/issues/5491
    bool exceptionCaught = false;

    final TestInherited parent = new TestInherited(child: new ExpectFail(() {
      exceptionCaught = true;
    }));
    await tester.pumpWidget(parent);

    expect(exceptionCaught, isTrue);
  });
}
