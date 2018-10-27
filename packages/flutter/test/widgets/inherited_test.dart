// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

import 'test_widgets.dart';

class TestInherited extends InheritedWidget {
  const TestInherited({ Key key, Widget child, this.shouldNotify = true })
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
  ExpectFailState createState() => ExpectFailState();
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
  Widget build(BuildContext context) => Container();
}

class ChangeNotifierInherited extends InheritedNotifier<ChangeNotifier> {
  const ChangeNotifierInherited({ Key key, Widget child, ChangeNotifier notifier })
    : super(key: key, child: child, notifier: notifier);
}

void main() {
  testWidgets('Inherited notifies dependents', (WidgetTester tester) async {
    final List<TestInherited> log = <TestInherited>[];

    final Builder builder = Builder(
      builder: (BuildContext context) {
        log.add(context.inheritFromWidgetOfExactType(TestInherited));
        return Container();
      }
    );

    final TestInherited first = TestInherited(child: builder);
    await tester.pumpWidget(first);

    expect(log, equals(<TestInherited>[first]));

    final TestInherited second = TestInherited(child: builder, shouldNotify: false);
    await tester.pumpWidget(second);

    expect(log, equals(<TestInherited>[first]));

    final TestInherited third = TestInherited(child: builder, shouldNotify: true);
    await tester.pumpWidget(third);

    expect(log, equals(<TestInherited>[first, third]));
  });

  testWidgets('Update inherited when reparenting state', (WidgetTester tester) async {
    final GlobalKey globalKey = GlobalKey();
    final List<TestInherited> log = <TestInherited>[];

    TestInherited build() {
      return TestInherited(
        key: UniqueKey(),
        child: Container(
          key: globalKey,
          child: Builder(
            builder: (BuildContext context) {
              log.add(context.inheritFromWidgetOfExactType(TestInherited));
              return Container();
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
      Container(
        child: ValueInherited(
          value: 1,
          child: Container(
            child: FlipWidget(
              left: Container(
                child: ValueInherited(
                  value: 2,
                  child: Container(
                    child: ValueInherited(
                      value: 3,
                      child: Container(
                        child: Builder(
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
              right: Container(
                child: ValueInherited(
                  value: 2,
                  child: Container(
                    child: Container(
                      child: Builder(
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

    final Key key = GlobalKey();

    await tester.pumpWidget(
      Container(
        child: ValueInherited(
          value: 1,
          child: Container(
            child: FlipWidget(
              left: Container(
                child: ValueInherited(
                  value: 2,
                  child: Container(
                    child: ValueInherited(
                      value: 3,
                      child: Container(
                        key: key,
                        child: Builder(
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
              right: Container(
                child: ValueInherited(
                  value: 2,
                  child: Container(
                    child: Container(
                      key: key,
                      child: Builder(
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

    final Key key = GlobalKey();

    final Widget child = Builder(
      builder: (BuildContext context) {
        final ValueInherited v = context.inheritFromWidgetOfExactType(ValueInherited);
        log.add(v.value);
        return const Text('', textDirection: TextDirection.ltr);
      }
    );

    await tester.pumpWidget(
      Container(
        child: ValueInherited(
          value: 1,
          child: Container(
            child: FlipWidget(
              left: Container(
                child: ValueInherited(
                  value: 2,
                  child: Container(
                    child: ValueInherited(
                      value: 3,
                      child: Container(
                        key: key,
                        child: child
                      )
                    )
                  )
                )
              ),
              right: Container(
                child: ValueInherited(
                  value: 2,
                  child: Container(
                    child: Container(
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

    final Widget child = Builder(
      key: GlobalKey(),
      builder: (BuildContext context) {
        final ValueInherited v = context.inheritFromWidgetOfExactType(ValueInherited);
        log.add(v.value);
        return const Text('', textDirection: TextDirection.ltr);
      }
    );

    await tester.pumpWidget(
      ValueInherited(
        value: 2,
        child: FlipWidget(
          left: ValueInherited(
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

    final Widget inner = Container(
      key: GlobalKey(),
      child: Builder(
        builder: (BuildContext context) {
          final ValueInherited widget = context.inheritFromWidgetOfExactType(ValueInherited);
          inheritedValue = widget?.value;
          return Container();
        }
      )
    );

    await tester.pumpWidget(
      inner
    );
    expect(inheritedValue, isNull);

    inheritedValue = -2;
    await tester.pumpWidget(
      ValueInherited(
        value: 3,
        child: inner
      )
    );
    expect(inheritedValue, equals(3));
  });

  testWidgets('Inherited widget doesn\'t notify descendants when descendant did not previously fail to find a match and had no dependencies', (WidgetTester tester) async {
    int buildCount = 0;

    final Widget inner = Container(
      key: GlobalKey(),
      child: Builder(
        builder: (BuildContext context) {
          buildCount += 1;
          return Container();
        }
      )
    );

    await tester.pumpWidget(
      inner
    );
    expect(buildCount, equals(1));

    await tester.pumpWidget(
      ValueInherited(
        value: 3,
        child: inner
      )
    );
    expect(buildCount, equals(1));
  });

  testWidgets('Inherited widget does notify descendants when descendant did not previously fail to find a match but did have other dependencies', (WidgetTester tester) async {
    int buildCount = 0;

    final Widget inner = Container(
      key: GlobalKey(),
      child: TestInherited(
        shouldNotify: false,
        child: Builder(
          builder: (BuildContext context) {
            context.inheritFromWidgetOfExactType(TestInherited);
            buildCount += 1;
            return Container();
          }
        )
      )
    );

    await tester.pumpWidget(
      inner
    );
    expect(buildCount, equals(1));

    await tester.pumpWidget(
      ValueInherited(
        value: 3,
        child: inner
      )
    );
    expect(buildCount, equals(2));
  });

  testWidgets('initState() dependency on Inherited asserts', (WidgetTester tester) async {
    // This is a regression test for https://github.com/flutter/flutter/issues/5491
    bool exceptionCaught = false;

    final TestInherited parent = TestInherited(child: ExpectFail(() {
      exceptionCaught = true;
    }));
    await tester.pumpWidget(parent);

    expect(exceptionCaught, isTrue);
  });

  testWidgets('InheritedNotifier', (WidgetTester tester) async {
    int buildCount = 0;
    final ChangeNotifier notifier = ChangeNotifier();

    final Widget builder = Builder(
      builder: (BuildContext context) {
        context.inheritFromWidgetOfExactType(ChangeNotifierInherited);
        buildCount += 1;
        return Container();
      }
    );

    final Widget inner = ChangeNotifierInherited(
      notifier: notifier,
      child: builder,
    );
    await tester.pumpWidget(inner);
    expect(buildCount, equals(1));

    await tester.pumpWidget(inner);
    expect(buildCount, equals(1));

    await tester.pump();
    expect(buildCount, equals(1));

    notifier.notifyListeners(); // ignore: invalid_use_of_protected_member
    await tester.pump();
    expect(buildCount, equals(2));

    await tester.pumpWidget(inner);
    expect(buildCount, equals(2));

    await tester.pumpWidget(ChangeNotifierInherited(
      notifier: null,
      child: builder,
    ));
    expect(buildCount, equals(3));
  });
}
