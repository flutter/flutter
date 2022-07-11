// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_widgets.dart';

class TestInherited extends InheritedWidget {
  const TestInherited({ super.key, required super.child, this.shouldNotify = true });

  final bool shouldNotify;

  @override
  bool updateShouldNotify(InheritedWidget oldWidget) {
    return shouldNotify;
  }
}

class ValueInherited extends InheritedWidget {
  const ValueInherited({ super.key, required super.child, required this.value });

  final int value;

  @override
  bool updateShouldNotify(ValueInherited oldWidget) => value != oldWidget.value;
}

class ExpectFail extends StatefulWidget {
  const ExpectFail(this.onError, { super.key });
  final VoidCallback onError;

  @override
  ExpectFailState createState() => ExpectFailState();
}

class ExpectFailState extends State<ExpectFail> {
  @override
  void initState() {
    super.initState();
    try {
      context.dependOnInheritedWidgetOfExactType<TestInherited>(); // should fail
    } catch (e) {
      widget.onError();
    }
  }

  @override
  Widget build(BuildContext context) => Container();
}

class ChangeNotifierInherited extends InheritedNotifier<ChangeNotifier> {
  const ChangeNotifierInherited({ super.key, required super.child, super.notifier });
}

@optionalTypeArgs
class RemoveDependencySpy<T> extends InheritedWidget {
  const RemoveDependencySpy({
    super.key,
    required super.child,
    this.onRemoveDependency,
    this.clearDependencyOnRebuild = true,
  });

  final void Function(Element dependency)? onRemoveDependency;
  final bool clearDependencyOnRebuild;

  @override
  RemoveDependencySpyElement createElement() => RemoveDependencySpyElement(this);

  @override
  bool updateShouldNotify(covariant RemoveDependencySpy oldWidget) {
    assert(clearDependencyOnRebuild == oldWidget.clearDependencyOnRebuild);
    return false;
  }
}

class RemoveDependencySpyElement extends InheritedElement {
  RemoveDependencySpyElement(super.widget);

  @override
  bool get clearDependencyOnRebuild => (widget as RemoveDependencySpy).clearDependencyOnRebuild;

  @override
  void removeDependent(Element dependent) {
    final RemoveDependencySpy widget = this.widget as RemoveDependencySpy;
    widget.onRemoveDependency?.call(dependent);
    super.removeDependent(dependent);
  }

  Object? publicGetDependencies(Element dependent) {
    return getDependencies(dependent);
  }

  @override
  void updateDependencies(Element dependent, Object? aspect) {
    setDependencies(dependent, Object());
  }
}

void main() {
  testWidgets('Calls removeDependency when dependents are unmounted', (WidgetTester tester) async {
    final List<Key> log = <Key>[];

    void onRemoveDependency(Element element) {
      log.add(element.widget.key!);
    }

    const Key firstKey = ValueKey<int>(1);
    const Key secondKey = ValueKey<int>(2);

    Widget builder(BuildContext context) {
      context.dependOnInheritedWidgetOfExactType<RemoveDependencySpy>();
      return Container();
    }

    await tester.pumpWidget(
      RemoveDependencySpy(
        onRemoveDependency: onRemoveDependency,
        child: Column(
          children: <Widget>[
            Builder(key: firstKey, builder: builder),
            Builder(key: secondKey, builder: builder),
          ],
        ),
      ),
    );

    expect(log, isEmpty);

    await tester.pumpWidget(
      RemoveDependencySpy(
        onRemoveDependency: onRemoveDependency,
        child: Container(),
      ),
    );

    expect(log, unorderedEquals(<Key>[firstKey, secondKey]));
  });

  testWidgets(
    'Calls removeDependency on InheritedElements with clearDependencyOnRebuild: true '
    'when dependents rebuild', (WidgetTester tester) async {
    final List<Key> log = <Key>[];

    const Key key = ValueKey<int>(0);

    void onRemoveDependency(Element element) {
      log.add(element.widget.key!);
    }

    Widget build() {
      return RemoveDependencySpy(
        onRemoveDependency: onRemoveDependency,
        child: Builder(
          key: key,
          builder: (BuildContext context) {
            context.dependOnInheritedWidgetOfExactType<RemoveDependencySpy>();
            return Container();
          },
        ),
      );
    }

    await tester.pumpWidget(build());

    expect(log, isEmpty);

    await tester.pumpWidget(build());

    expect(log, const <Key>[key]);
  });

  testWidgets(
    'Does not call removeDependency on InheritedElements with clearDependencyOnRebuild: false '
    'when dependents rebuild', (WidgetTester tester) async {
    final List<Key> log = <Key>[];

    const Key key = ValueKey<int>(0);

    void onRemoveDependency(Element element) {
      log.add(element.widget.key!);
    }

    Widget build() {
      return RemoveDependencySpy(
        onRemoveDependency: onRemoveDependency,
        clearDependencyOnRebuild: false,
        child: Builder(
          key: key,
          builder: (BuildContext context) {
            context.dependOnInheritedWidgetOfExactType<RemoveDependencySpy>();
            return Container();
          },
        ),
      );
    }

    await tester.pumpWidget(build());

    expect(log, isEmpty);

    await tester.pumpWidget(build());

    expect(log, isEmpty);
  });

  testWidgets(
    'On dependent rebuild, only clears dependencies with clearDependencyOnRebuild: true', (WidgetTester tester) async {
    const ValueKey<int> firstKey = ValueKey<int>(0);
    const ValueKey<int> secondKey = ValueKey<int>(2);

    Widget build({required bool isFirstBuild}) {
      return RemoveDependencySpy<int>(
        key: firstKey,
        clearDependencyOnRebuild: false,
        child: RemoveDependencySpy(
        key: secondKey,
          child: Builder(
            builder: (BuildContext context) {
              if (isFirstBuild) {
                context.dependOnInheritedWidgetOfExactType<RemoveDependencySpy>();
                context.dependOnInheritedWidgetOfExactType<RemoveDependencySpy<int>>();
              }
              return Container();
            },
          ),
        ),
      );
    }

    await tester.pumpWidget(build(isFirstBuild: true));

    final RemoveDependencySpyElement notifierElement = tester.element<RemoveDependencySpyElement>(find.byKey(firstKey));
    final RemoveDependencySpyElement spyElement = tester.element<RemoveDependencySpyElement>(find.byKey(secondKey));
    final Element builderElement = tester.element(find.byType(Builder));

    expect(spyElement.publicGetDependencies(builderElement), isNotNull);
    expect(notifierElement.publicGetDependencies(builderElement), isNotNull);

    await tester.pumpWidget(build(isFirstBuild: false));

    expect(spyElement.publicGetDependencies(builderElement), isNull);
    expect(notifierElement.publicGetDependencies(builderElement), isNotNull);
  });

  testWidgets(
    'Does not call removeDependency twice on InheritedElements with clearDependencyOnRebuild: false '
    'when dependents rebuild then are unmounted', (WidgetTester tester) async {
    final List<Key> log = <Key>[];

    const Key key = ValueKey<int>(0);

    void onRemoveDependency(Element element) {
      log.add(element.widget.key!);
    }

    Widget build({required bool callDependOn}) {
      return RemoveDependencySpy(
        onRemoveDependency: onRemoveDependency,
        child: Builder(
          key: key,
          builder: (BuildContext context) {
            if (callDependOn) {
              context.dependOnInheritedWidgetOfExactType<RemoveDependencySpy>();
            }
            return Container();
          },
        ),
      );
    }

    await tester.pumpWidget(build(callDependOn: true));

    expect(log, isEmpty);

    await tester.pumpWidget(build(callDependOn: false));

    expect(log, const <Key>[key]);

    await tester.pumpWidget(
      RemoveDependencySpy(
        onRemoveDependency: onRemoveDependency,
        child: Container(),
      ),
    );

    expect(log, const <Key>[key]);
  });

  testWidgets('Inherited notifies dependents', (WidgetTester tester) async {
    final List<TestInherited> log = <TestInherited>[];

    final Builder builder = Builder(
      builder: (BuildContext context) {
        log.add(context.dependOnInheritedWidgetOfExactType<TestInherited>()!);
        return Container();
      },
    );

    final TestInherited first = TestInherited(child: builder);
    await tester.pumpWidget(first);

    expect(log, equals(<TestInherited>[first]));

    final TestInherited second = TestInherited(shouldNotify: false, child: builder);
    await tester.pumpWidget(second);

    expect(log, equals(<TestInherited>[first]));

    final TestInherited third = TestInherited(child: builder);
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
              log.add(context.dependOnInheritedWidgetOfExactType<TestInherited>()!);
              return Container();
            },
          ),
        ),
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
      ValueInherited(
        value: 1,
        child: FlipWidget(
          left: ValueInherited(
            value: 2,
            child: ValueInherited(
              value: 3,
              child: Builder(
                builder: (BuildContext context) {
                  final ValueInherited v = context.dependOnInheritedWidgetOfExactType<ValueInherited>()!;
                  log.add('a: ${v.value}');
                  return const Text('', textDirection: TextDirection.ltr);
                },
              ),
            ),
          ),
          right: ValueInherited(
            value: 2,
            child: Builder(
              builder: (BuildContext context) {
                final ValueInherited v = context.dependOnInheritedWidgetOfExactType<ValueInherited>()!;
                log.add('b: ${v.value}');
                return const Text('', textDirection: TextDirection.ltr);
              },
            ),
          ),
        ),
      ),
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
      ValueInherited(
        value: 1,
        child: FlipWidget(
          left: ValueInherited(
            value: 2,
            child: ValueInherited(
              value: 3,
              child: Container(
                key: key,
                child: Builder(
                  builder: (BuildContext context) {
                    final ValueInherited v = context.dependOnInheritedWidgetOfExactType<ValueInherited>()!;
                    log.add('a: ${v.value}');
                    return const Text('', textDirection: TextDirection.ltr);
                  },
                ),
              ),
            ),
          ),
          right: ValueInherited(
            value: 2,
            child: Container(
              key: key,
              child: Builder(
                builder: (BuildContext context) {
                  final ValueInherited v = context.dependOnInheritedWidgetOfExactType<ValueInherited>()!;
                  log.add('b: ${v.value}');
                  return const Text('', textDirection: TextDirection.ltr);
                },
              ),
            ),
          ),
        ),
      ),
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
        final ValueInherited v = context.dependOnInheritedWidgetOfExactType<ValueInherited>()!;
        log.add(v.value);
        return const Text('', textDirection: TextDirection.ltr);
      },
    );

    await tester.pumpWidget(
      ValueInherited(
        value: 1,
        child: FlipWidget(
          left: ValueInherited(
            value: 2,
            child: ValueInherited(
              value: 3,
              child: Container(
                key: key,
                child: child,
              ),
            ),
          ),
          right: ValueInherited(
            value: 2,
            child: Container(
              key: key,
              child: child,
            ),
          ),
        ),
      ),
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
        final ValueInherited v = context.dependOnInheritedWidgetOfExactType<ValueInherited>()!;
        log.add(v.value);
        return const Text('', textDirection: TextDirection.ltr);
      },
    );

    await tester.pumpWidget(
      ValueInherited(
        value: 2,
        child: FlipWidget(
          left: ValueInherited(
            value: 3,
            child: child,
          ),
          right: child,
        ),
      ),
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
    int? inheritedValue = -1;

    final Widget inner = Container(
      key: GlobalKey(),
      child: Builder(
        builder: (BuildContext context) {
          final ValueInherited? widget = context.dependOnInheritedWidgetOfExactType<ValueInherited>();
          inheritedValue = widget?.value;
          return Container();
        },
      ),
    );

    await tester.pumpWidget(
      inner,
    );
    expect(inheritedValue, isNull);

    inheritedValue = -2;
    await tester.pumpWidget(
      ValueInherited(
        value: 3,
        child: inner,
      ),
    );
    expect(inheritedValue, equals(3));
  });

  testWidgets("Inherited widget doesn't notify descendants when descendant did not previously fail to find a match and had no dependencies", (WidgetTester tester) async {
    int buildCount = 0;

    final Widget inner = Container(
      key: GlobalKey(),
      child: Builder(
        builder: (BuildContext context) {
          buildCount += 1;
          return Container();
        },
      ),
    );

    await tester.pumpWidget(
      inner,
    );
    expect(buildCount, equals(1));

    await tester.pumpWidget(
      ValueInherited(
        value: 3,
        child: inner,
      ),
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
            context.dependOnInheritedWidgetOfExactType<TestInherited>();
            buildCount += 1;
            return Container();
          },
        ),
      ),
    );

    await tester.pumpWidget(
      inner,
    );
    expect(buildCount, equals(1));

    await tester.pumpWidget(
      ValueInherited(
        value: 3,
        child: inner,
      ),
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
        context.dependOnInheritedWidgetOfExactType<ChangeNotifierInherited>();
        buildCount += 1;
        return Container();
      },
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

    notifier.notifyListeners();
    await tester.pump();
    expect(buildCount, equals(2));

    await tester.pumpWidget(inner);
    expect(buildCount, equals(2));

    await tester.pumpWidget(ChangeNotifierInherited(
      child: builder,
    ));
    expect(buildCount, equals(3));
  });
}
