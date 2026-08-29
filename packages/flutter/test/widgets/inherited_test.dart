// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_widgets.dart';

const _kWhite = Color(0xFFFFFFFF);
const _kBlack = Color(0xFF000000);

class TestInherited extends InheritedWidget {
  const TestInherited({super.key, required super.child, this.shouldNotify = true});

  final bool shouldNotify;

  @override
  bool updateShouldNotify(InheritedWidget oldWidget) {
    return shouldNotify;
  }
}

class ValueInherited extends InheritedWidget {
  const ValueInherited({super.key, required super.child, required this.value});

  final int value;

  @override
  bool updateShouldNotify(ValueInherited oldWidget) => value != oldWidget.value;
}

class ExpectFail extends StatefulWidget {
  const ExpectFail(this.onError, {super.key});
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
  const ChangeNotifierInherited({super.key, required super.child, super.notifier});
}

@immutable
class TestWidgetData {
  const TestWidgetData({
    this.color,
    this.elevation,
    this.shadowColor,
    this.shape,
    this.clipBehavior,
  });

  final Color? color;
  final double? elevation;
  final Color? shadowColor;
  final ShapeBorder? shape;
  final Clip? clipBehavior;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other.runtimeType != runtimeType) {
      return false;
    }
    return other is TestWidgetData &&
        other.color == color &&
        other.elevation == elevation &&
        other.shadowColor == shadowColor &&
        other.shape == shape &&
        other.clipBehavior == clipBehavior;
  }

  @override
  int get hashCode => Object.hash(color, elevation, shadowColor, shape, clipBehavior);
}

class TestDataWidget extends InheritedWidget {
  const TestDataWidget({super.key, required super.child, required this.data});

  final TestWidgetData data;

  static TestWidgetData of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<TestDataWidget>()?.data ??
        const TestWidgetData();
  }

  @override
  bool updateShouldNotify(TestDataWidget oldWidget) => data != oldWidget.data;
}

class ThemedWidget extends SingleChildRenderObjectWidget {
  const ThemedWidget({super.key}) : super(child: const SizedBox.expand());

  @override
  RenderPhysicalShape createRenderObject(BuildContext context) {
    final TestWidgetData data = TestDataWidget.of(context);

    return RenderPhysicalShape(
      clipper: ShapeBorderClipper(shape: data.shape ?? const RoundedRectangleBorder()),
      clipBehavior: data.clipBehavior ?? Clip.antiAlias,
      color: data.color ?? _kWhite,
      elevation: data.elevation ?? 0.0,
      shadowColor: data.shadowColor ?? _kBlack,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderPhysicalShape renderObject) {
    final TestWidgetData data = TestDataWidget.of(context);

    renderObject
      ..clipper = ShapeBorderClipper(shape: data.shape ?? const RoundedRectangleBorder())
      ..clipBehavior = data.clipBehavior ?? Clip.antiAlias
      ..color = data.color ?? _kWhite
      ..elevation = data.elevation ?? 0.0
      ..shadowColor = data.shadowColor ?? _kBlack;
  }
}

void main() {
  testWidgets('Inherited notifies dependents', (WidgetTester tester) async {
    final log = <TestInherited>[];

    final builder = Builder(
      builder: (BuildContext context) {
        log.add(context.dependOnInheritedWidgetOfExactType<TestInherited>()!);
        return Container();
      },
    );

    final first = TestInherited(child: builder);
    await tester.pumpWidget(first);

    expect(log, equals(<TestInherited>[first]));

    final second = TestInherited(shouldNotify: false, child: builder);
    await tester.pumpWidget(second);

    expect(log, equals(<TestInherited>[first]));

    final third = TestInherited(child: builder);
    await tester.pumpWidget(third);

    expect(log, equals(<TestInherited>[first, third]));
  });

  testWidgets('Update inherited when reparenting state', (WidgetTester tester) async {
    final GlobalKey globalKey = GlobalKey();
    final log = <TestInherited>[];

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
    final log = <String>[];

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
                  final ValueInherited v = context
                      .dependOnInheritedWidgetOfExactType<ValueInherited>()!;
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
                final ValueInherited v = context
                    .dependOnInheritedWidgetOfExactType<ValueInherited>()!;
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

  testWidgets('Update inherited when removing node and child has global key', (
    WidgetTester tester,
  ) async {
    final log = <String>[];

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
                    final ValueInherited v = context
                        .dependOnInheritedWidgetOfExactType<ValueInherited>()!;
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
                  final ValueInherited v = context
                      .dependOnInheritedWidgetOfExactType<ValueInherited>()!;
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

  testWidgets('Update inherited when removing node and child has global key with constant child', (
    WidgetTester tester,
  ) async {
    final log = <int>[];

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
              child: Container(key: key, child: child),
            ),
          ),
          right: ValueInherited(
            value: 2,
            child: Container(key: key, child: child),
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

  testWidgets(
    'Update inherited when removing node and child has global key with constant child, minimised',
    (WidgetTester tester) async {
      final log = <int>[];

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
            left: ValueInherited(value: 3, child: child),
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
    },
  );

  testWidgets(
    'Inherited widget notifies descendants when descendant previously failed to find a match',
    (WidgetTester tester) async {
      int? inheritedValue = -1;

      final Widget inner = Container(
        key: GlobalKey(),
        child: Builder(
          builder: (BuildContext context) {
            final ValueInherited? widget = context
                .dependOnInheritedWidgetOfExactType<ValueInherited>();
            inheritedValue = widget?.value;
            return Container();
          },
        ),
      );

      await tester.pumpWidget(inner);
      expect(inheritedValue, isNull);

      inheritedValue = -2;
      await tester.pumpWidget(ValueInherited(value: 3, child: inner));
      expect(inheritedValue, equals(3));
    },
  );

  testWidgets(
    "Inherited widget doesn't notify descendants when descendant did not previously fail to find a match and had no dependencies",
    (WidgetTester tester) async {
      var buildCount = 0;

      final Widget inner = Container(
        key: GlobalKey(),
        child: Builder(
          builder: (BuildContext context) {
            buildCount += 1;
            return Container();
          },
        ),
      );

      await tester.pumpWidget(inner);
      expect(buildCount, equals(1));

      await tester.pumpWidget(ValueInherited(value: 3, child: inner));
      expect(buildCount, equals(1));
    },
  );

  testWidgets(
    'Inherited widget does notify descendants when descendant did not previously fail to find a match but did have other dependencies',
    (WidgetTester tester) async {
      var buildCount = 0;

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

      await tester.pumpWidget(inner);
      expect(buildCount, equals(1));

      await tester.pumpWidget(ValueInherited(value: 3, child: inner));
      expect(buildCount, equals(2));
    },
  );

  testWidgets("BuildContext.getInheritedWidgetOfExactType doesn't create a dependency", (
    WidgetTester tester,
  ) async {
    var buildCount = 0;
    final GlobalKey<void> inheritedKey = GlobalKey();
    final notifier = ChangeNotifier();
    addTearDown(notifier.dispose);

    final Widget builder = Builder(
      builder: (BuildContext context) {
        expect(
          context.getInheritedWidgetOfExactType<ChangeNotifierInherited>(),
          equals(inheritedKey.currentWidget),
        );
        buildCount += 1;
        return Container();
      },
    );

    final Widget inner = ChangeNotifierInherited(
      key: inheritedKey,
      notifier: notifier,
      child: builder,
    );

    await tester.pumpWidget(inner);
    expect(buildCount, equals(1));
    notifier.notifyListeners();
    await tester.pumpWidget(inner);
    expect(buildCount, equals(1));
  });

  testWidgets('initState() dependency on Inherited asserts', (WidgetTester tester) async {
    // This is a regression test for https://github.com/flutter/flutter/issues/5491
    var exceptionCaught = false;

    final parent = TestInherited(
      child: ExpectFail(() {
        exceptionCaught = true;
      }),
    );
    await tester.pumpWidget(parent);

    expect(exceptionCaught, isTrue);
  });

  testWidgets('InheritedNotifier', (WidgetTester tester) async {
    var buildCount = 0;
    final notifier = ChangeNotifier();
    addTearDown(notifier.dispose);

    final Widget builder = Builder(
      builder: (BuildContext context) {
        context.dependOnInheritedWidgetOfExactType<ChangeNotifierInherited>();
        buildCount += 1;
        return Container();
      },
    );

    final Widget inner = ChangeNotifierInherited(notifier: notifier, child: builder);
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

    await tester.pumpWidget(ChangeNotifierInherited(child: builder));
    expect(buildCount, equals(3));
  });

  testWidgets('InheritedWidgets can trigger RenderObject updates', (WidgetTester tester) async {
    var data = const TestWidgetData(color: _kWhite);
    late StateSetter setState;

    // Verifies that the "themed widget" is rendered
    // with the appropriate inherited theme data.
    void expectWidgetToMatchTheme() {
      final RenderPhysicalShape renderShape = tester.renderObject(find.byType(ThemedWidget));

      if (data.color != null) {
        expect(renderShape.color, data.color);
      }
      if (data.elevation != null) {
        expect(renderShape.elevation, data.elevation);
      }
      if (data.shadowColor != null) {
        expect(renderShape.shadowColor, data.shadowColor);
      }
      if (data.shape != null) {
        final CustomClipper<Path>? clipper = renderShape.clipper;
        expect(clipper, isA<ShapeBorderClipper>());
        expect((clipper! as ShapeBorderClipper).shape, data.shape);
      }
      if (data.clipBehavior != null) {
        expect(renderShape.clipBehavior, data.clipBehavior);
      }
    }

    await tester.pumpWidget(
      StatefulBuilder(
        builder: (BuildContext context, StateSetter stateSetter) {
          setState = stateSetter;
          return TestDataWidget(data: data, child: const ThemedWidget());
        },
      ),
    );
    expectWidgetToMatchTheme();

    setState(() {
      data = const TestWidgetData(
        shape: BeveledRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20))),
      );
    });
    await tester.pump();
    expectWidgetToMatchTheme();

    setState(() {
      data = const TestWidgetData(clipBehavior: Clip.hardEdge);
    });
    await tester.pump();
    expectWidgetToMatchTheme();

    setState(() {
      data = const TestWidgetData(
        elevation: 5.0,
        shadowColor: Color(0xFF0000FF),
        shape: ContinuousRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(8.0))),
        clipBehavior: Clip.antiAliasWithSaveLayer,
      );
    });
    await tester.pump();
    expectWidgetToMatchTheme();
  });
}
