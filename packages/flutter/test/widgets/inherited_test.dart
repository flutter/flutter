// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_widgets.dart';

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

class CleanupInheritedA extends InheritedWidget {
  const CleanupInheritedA({required super.child, super.key, this.value = 0});

  final int value;

  @override
  bool get cleanupUnusedDependents => true;

  @override
  bool updateShouldNotify(CleanupInheritedA oldWidget) => value != oldWidget.value;
}

class CleanupInheritedB extends InheritedWidget {
  const CleanupInheritedB({required super.child, super.key, this.value = 0});

  final int value;

  @override
  bool get cleanupUnusedDependents => false;

  @override
  bool updateShouldNotify(CleanupInheritedB oldWidget) => value != oldWidget.value;
}

class CleanupInheritedC extends InheritedWidget {
  const CleanupInheritedC({required super.child, super.key, this.value = 0});

  final int value;

  @override
  bool get cleanupUnusedDependents => true;

  @override
  bool updateShouldNotify(CleanupInheritedC oldWidget) => value != oldWidget.value;
}

class CleanupInheritedD extends InheritedWidget {
  const CleanupInheritedD({required super.child, super.key, this.value = 0});

  final int value;

  @override
  bool get cleanupUnusedDependents => false;

  @override
  bool updateShouldNotify(CleanupInheritedD oldWidget) => value != oldWidget.value;
}

/// An InheritedWidget that allows toggling cleanupUnusedDependents dynamically.
/// Used to test behavior when cleanupUnusedDependents changes during widget lifetime.
class ToggleableCleanupInherited extends InheritedWidget {
  const ToggleableCleanupInherited({
    required super.child,
    required this.shouldCleanup,
    this.value = 0,
    super.key,
  });

  final bool shouldCleanup;
  final int value;

  @override
  bool get cleanupUnusedDependents => shouldCleanup;

  @override
  bool updateShouldNotify(ToggleableCleanupInherited oldWidget) =>
      value != oldWidget.value || shouldCleanup != oldWidget.shouldCleanup;
}

class DependencyCleanupTestWidget extends StatefulWidget {
  const DependencyCleanupTestWidget({super.key});

  @override
  State<DependencyCleanupTestWidget> createState() => DependencyCleanupTestWidgetState();
}

class DependencyCleanupTestWidgetState extends State<DependencyCleanupTestWidget> {
  bool useDependencyA = false;
  bool useDependencyB = false;
  bool useDependencyC = false;
  bool useDependencyD = false;
  bool useToggleableDependency = false;
  int buildCount = 0;
  int didChangeDependenciesCount = 0;

  void updateDependencies({bool? useA, bool? useB, bool? useC, bool? useD}) {
    setState(() {
      if (useA != null) {
        useDependencyA = useA;
      }
      if (useB != null) {
        useDependencyB = useB;
      }
      if (useC != null) {
        useDependencyC = useC;
      }
      if (useD != null) {
        useDependencyD = useD;
      }
    });
  }

  void updateToggleableDependency(bool use) {
    setState(() {
      useToggleableDependency = use;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    didChangeDependenciesCount++;
  }

  @override
  Widget build(BuildContext context) {
    buildCount++;

    if (useDependencyA) {
      context.dependOnInheritedWidgetOfExactType<CleanupInheritedA>();
    }

    if (useDependencyB) {
      context.dependOnInheritedWidgetOfExactType<CleanupInheritedB>();
    }

    if (useDependencyC) {
      context.dependOnInheritedWidgetOfExactType<CleanupInheritedC>();
    }

    if (useDependencyD) {
      context.dependOnInheritedWidgetOfExactType<CleanupInheritedD>();
    }

    if (useToggleableDependency) {
      context.dependOnInheritedWidgetOfExactType<ToggleableCleanupInherited>();
    }

    return const SizedBox();
  }
}

class TriggerInherited extends InheritedWidget {
  const TriggerInherited({required super.child, this.value = 0, super.key});

  final int value;

  @override
  bool updateShouldNotify(TriggerInherited oldWidget) => value != oldWidget.value;
}

class DidChangeDependenciesCleanupTestWidget extends StatefulWidget {
  const DidChangeDependenciesCleanupTestWidget({super.key});

  @override
  State<DidChangeDependenciesCleanupTestWidget> createState() =>
      DidChangeDependenciesCleanupTestWidgetState();
}

class DidChangeDependenciesCleanupTestWidgetState
    extends State<DidChangeDependenciesCleanupTestWidget> {
  bool useDependencyA = false;
  bool useDependencyB = false;
  bool useDependencyC = false;
  bool useDependencyD = false;
  bool useToggleableDependency = false;
  int buildCount = 0;
  int didChangeDependenciesCount = 0;

  void updateDependencies({bool? useA, bool? useB, bool? useC, bool? useD}) {
    if (useA != null) {
      useDependencyA = useA;
    }
    if (useB != null) {
      useDependencyB = useB;
    }
    if (useC != null) {
      useDependencyC = useC;
    }
    if (useD != null) {
      useDependencyD = useD;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    didChangeDependenciesCount++;

    // Always depend on TriggerInherited to ensure didChangeDependencies gets called
    context.dependOnInheritedWidgetOfExactType<TriggerInherited>();

    if (useDependencyA) {
      context.dependOnInheritedWidgetOfExactType<CleanupInheritedA>();
    }

    if (useDependencyB) {
      context.dependOnInheritedWidgetOfExactType<CleanupInheritedB>();
    }

    if (useDependencyC) {
      context.dependOnInheritedWidgetOfExactType<CleanupInheritedC>();
    }

    if (useDependencyD) {
      context.dependOnInheritedWidgetOfExactType<CleanupInheritedD>();
    }

    if (useToggleableDependency) {
      context.dependOnInheritedWidgetOfExactType<ToggleableCleanupInherited>();
    }
  }

  @override
  Widget build(BuildContext context) {
    buildCount++;
    return const SizedBox();
  }
}

class LayoutBuilderCleanupTestWidget extends StatefulWidget {
  const LayoutBuilderCleanupTestWidget({super.key});

  @override
  State<LayoutBuilderCleanupTestWidget> createState() => LayoutBuilderCleanupTestWidgetState();
}

class LayoutBuilderCleanupTestWidgetState extends State<LayoutBuilderCleanupTestWidget> {
  bool useDependencyA = false;
  bool useDependencyB = false;
  bool useDependencyC = false;
  bool useDependencyD = false;
  int buildCount = 0;
  int layoutBuilderCallbackCount = 0;
  int didChangeDependenciesCount = 0;

  void updateDependencies({bool? useA, bool? useB, bool? useC, bool? useD}) {
    setState(() {
      if (useA != null) {
        useDependencyA = useA;
      }
      if (useB != null) {
        useDependencyB = useB;
      }
      if (useC != null) {
        useDependencyC = useC;
      }
      if (useD != null) {
        useDependencyD = useD;
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    didChangeDependenciesCount++;
  }

  @override
  Widget build(BuildContext context) {
    buildCount++;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        layoutBuilderCallbackCount++;

        if (useDependencyA) {
          context.dependOnInheritedWidgetOfExactType<CleanupInheritedA>();
        }

        if (useDependencyB) {
          context.dependOnInheritedWidgetOfExactType<CleanupInheritedB>();
        }

        if (useDependencyC) {
          context.dependOnInheritedWidgetOfExactType<CleanupInheritedC>();
        }

        if (useDependencyD) {
          context.dependOnInheritedWidgetOfExactType<CleanupInheritedD>();
        }

        return const SizedBox();
      },
    );
  }
}

class ThemedCard extends SingleChildRenderObjectWidget {
  const ThemedCard({super.key}) : super(child: const SizedBox.expand());

  @override
  RenderPhysicalShape createRenderObject(BuildContext context) {
    final CardThemeData cardTheme = CardTheme.of(context);

    return RenderPhysicalShape(
      clipper: ShapeBorderClipper(shape: cardTheme.shape ?? const RoundedRectangleBorder()),
      clipBehavior: cardTheme.clipBehavior ?? Clip.antiAlias,
      color: cardTheme.color ?? Colors.white,
      elevation: cardTheme.elevation ?? 0.0,
      shadowColor: cardTheme.shadowColor ?? Colors.black,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderPhysicalShape renderObject) {
    final CardThemeData cardTheme = CardTheme.of(context);

    renderObject
      ..clipper = ShapeBorderClipper(shape: cardTheme.shape ?? const RoundedRectangleBorder())
      ..clipBehavior = cardTheme.clipBehavior ?? Clip.antiAlias
      ..color = cardTheme.color ?? Colors.white
      ..elevation = cardTheme.elevation ?? 0.0
      ..shadowColor = cardTheme.shadowColor ?? Colors.black;
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
    var cardThemeData = const CardThemeData(color: Colors.white);
    late StateSetter setState;

    // Verifies that the "themed card" is rendered
    // with the appropriate inherited theme data.
    void expectCardToMatchTheme() {
      final RenderPhysicalShape renderShape = tester.renderObject(find.byType(ThemedCard));

      if (cardThemeData.color != null) {
        expect(renderShape.color, cardThemeData.color);
      }
      if (cardThemeData.elevation != null) {
        expect(renderShape.elevation, cardThemeData.elevation);
      }
      if (cardThemeData.shadowColor != null) {
        expect(renderShape.shadowColor, cardThemeData.shadowColor);
      }
      if (cardThemeData.shape != null) {
        final CustomClipper<Path>? clipper = renderShape.clipper;
        expect(clipper, isA<ShapeBorderClipper>());
        expect((clipper! as ShapeBorderClipper).shape, cardThemeData.shape);
      }
      if (cardThemeData.clipBehavior != null) {
        expect(renderShape.clipBehavior, cardThemeData.clipBehavior);
      }
    }

    await tester.pumpWidget(
      StatefulBuilder(
        builder: (BuildContext context, StateSetter stateSetter) {
          setState = stateSetter;
          return Theme(
            data: ThemeData(cardTheme: cardThemeData),
            child: const ThemedCard(),
          );
        },
      ),
    );
    expectCardToMatchTheme();

    setState(() {
      cardThemeData = const CardThemeData(
        shape: BeveledRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20))),
      );
    });
    await tester.pump();
    expectCardToMatchTheme();

    setState(() {
      cardThemeData = const CardThemeData(clipBehavior: Clip.hardEdge);
    });
    await tester.pump();
    expectCardToMatchTheme();

    setState(() {
      cardThemeData = const CardThemeData(
        elevation: 5.0,
        shadowColor: Colors.blueGrey,
        shape: ContinuousRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(8.0))),
        clipBehavior: Clip.antiAliasWithSaveLayer,
      );
    });
    await tester.pump();
    expectCardToMatchTheme();
  });

  testWidgets(
    'Mixed cleanupUnusedDependents - only widgets with cleanup enabled should be cleaned up',
    (WidgetTester tester) async {
      final key = GlobalKey<DependencyCleanupTestWidgetState>();

      await tester.pumpWidget(
        CleanupInheritedA(
          value: 1,
          child: CleanupInheritedB(value: 1, child: DependencyCleanupTestWidget(key: key)),
        ),
      );

      final DependencyCleanupTestWidgetState state = key.currentState!;
      expect(state.buildCount, 1);

      state.updateDependencies(useA: true, useB: true);
      await tester.pump();
      expect(state.buildCount, 2);

      state.updateDependencies(useA: false, useB: true);
      await tester.pump();
      expect(state.buildCount, 3);

      final int didChangeCountBeforeB = state.didChangeDependenciesCount;
      await tester.pumpWidget(
        CleanupInheritedA(
          value: 1,
          child: CleanupInheritedB(value: 2, child: DependencyCleanupTestWidget(key: key)),
        ),
      );

      expect(
        state.didChangeDependenciesCount,
        greaterThan(didChangeCountBeforeB),
        reason:
            'CleanupInheritedB dependency (cleanupUnusedDependents=false) should persist and '
            'trigger didChangeDependencies when CleanupInheritedB changes.',
      );

      final int didChangeCountBeforeA = state.didChangeDependenciesCount;
      await tester.pumpWidget(
        CleanupInheritedA(
          value: 2,
          child: CleanupInheritedB(value: 2, child: DependencyCleanupTestWidget(key: key)),
        ),
      );

      expect(
        state.didChangeDependenciesCount,
        didChangeCountBeforeA,
        reason:
            'CleanupInheritedA dependency (cleanupUnusedDependents=true) should have been '
            'cleaned up and should NOT trigger didChangeDependencies.',
      );
    },
  );

  testWidgets('All dependencies with cleanupUnusedDependents=true should be cleaned up', (
    WidgetTester tester,
  ) async {
    final key = GlobalKey<DependencyCleanupTestWidgetState>();

    await tester.pumpWidget(
      CleanupInheritedA(
        value: 1,
        child: CleanupInheritedC(value: 1, child: DependencyCleanupTestWidget(key: key)),
      ),
    );

    final DependencyCleanupTestWidgetState state = key.currentState!;
    expect(state.buildCount, 1);

    state.updateDependencies(useA: true, useC: true);
    await tester.pump();
    expect(state.buildCount, 2);

    state.updateDependencies(useA: false, useC: false);
    await tester.pump();
    expect(state.buildCount, 3);

    final int didChangeCountBefore = state.didChangeDependenciesCount;
    await tester.pumpWidget(
      CleanupInheritedA(
        value: 2,
        child: CleanupInheritedC(value: 2, child: DependencyCleanupTestWidget(key: key)),
      ),
    );

    expect(
      state.didChangeDependenciesCount,
      didChangeCountBefore,
      reason:
          'All dependencies with cleanupUnusedDependents=true should be removed '
          'and should NOT trigger didChangeDependencies.',
    );
  });

  testWidgets('All dependencies with cleanupUnusedDependents=false should persist', (
    WidgetTester tester,
  ) async {
    final key = GlobalKey<DependencyCleanupTestWidgetState>();

    await tester.pumpWidget(
      CleanupInheritedB(
        value: 1,
        child: CleanupInheritedD(value: 1, child: DependencyCleanupTestWidget(key: key)),
      ),
    );

    final DependencyCleanupTestWidgetState state = key.currentState!;
    expect(state.buildCount, 1);

    state.updateDependencies(useB: true, useD: true);
    await tester.pump();
    expect(state.buildCount, 2);

    state.updateDependencies(useB: false, useD: false);
    await tester.pump();
    expect(state.buildCount, 3);

    final int didChangeCountBefore = state.didChangeDependenciesCount;
    await tester.pumpWidget(
      CleanupInheritedB(
        value: 2,
        child: CleanupInheritedD(value: 2, child: DependencyCleanupTestWidget(key: key)),
      ),
    );

    expect(
      state.didChangeDependenciesCount,
      greaterThan(didChangeCountBefore),
      reason:
          'Dependencies with cleanupUnusedDependents=false should persist and '
          'trigger didChangeDependencies even when not re-established.',
    );
  });

  testWidgets('cleanupUnusedDependents changing from true to false should prevent cleanup', (
    WidgetTester tester,
  ) async {
    // This tests the scenario where an InheritedWidget's cleanupUnusedDependents
    // starts as true, but changes to false. The dependency should NOT be cleaned
    // up because the current value is false at cleanup time.

    final key = GlobalKey<DependencyCleanupTestWidgetState>();

    await tester.pumpWidget(
      ToggleableCleanupInherited(shouldCleanup: true, child: DependencyCleanupTestWidget(key: key)),
    );

    final DependencyCleanupTestWidgetState state = key.currentState!;
    expect(state.buildCount, 1);

    state.updateToggleableDependency(true);
    await tester.pump();
    expect(state.buildCount, 2);

    await tester.pumpWidget(
      ToggleableCleanupInherited(
        shouldCleanup: false,
        child: DependencyCleanupTestWidget(key: key),
      ),
    );

    state.updateToggleableDependency(false);
    await tester.pump();

    final int didChangeCountBefore = state.didChangeDependenciesCount;

    await tester.pumpWidget(
      ToggleableCleanupInherited(
        shouldCleanup: false,
        value: 1,
        child: DependencyCleanupTestWidget(key: key),
      ),
    );

    expect(
      state.didChangeDependenciesCount,
      greaterThan(didChangeCountBefore),
      reason:
          'Dependency should persist when cleanupUnusedDependents changes from true to false. '
          'The dependent should still be notified of changes via didChangeDependencies.',
    );
  });

  testWidgets('cleanupUnusedDependents changing from false to true should enable cleanup', (
    WidgetTester tester,
  ) async {
    // This tests the scenario where an InheritedWidget's cleanupUnusedDependents
    // starts as false, but changes to true. The dependency SHOULD be cleaned up
    // because the current value is true at cleanup time.

    final key = GlobalKey<DependencyCleanupTestWidgetState>();

    await tester.pumpWidget(
      ToggleableCleanupInherited(
        shouldCleanup: false,
        child: DependencyCleanupTestWidget(key: key),
      ),
    );

    final DependencyCleanupTestWidgetState state = key.currentState!;
    expect(state.buildCount, 1);

    state.updateToggleableDependency(true);
    await tester.pump();
    expect(state.buildCount, 2);

    state.updateToggleableDependency(false);
    await tester.pump();
    expect(state.buildCount, 3);

    await tester.pumpWidget(
      ToggleableCleanupInherited(shouldCleanup: true, child: DependencyCleanupTestWidget(key: key)),
    );

    final int didChangeCountAfterCleanup = state.didChangeDependenciesCount;

    await tester.pumpWidget(
      ToggleableCleanupInherited(
        shouldCleanup: true,
        value: 1,
        child: DependencyCleanupTestWidget(key: key),
      ),
    );

    expect(
      state.didChangeDependenciesCount,
      didChangeCountAfterCleanup,
      reason:
          'Dependency should be cleaned up when cleanupUnusedDependents changes from false to true. '
          'didChangeDependencies should not be called after cleanup.',
    );
  });

  testWidgets('Mixed cleanupUnusedDependents - dependencies in didChangeDependencies', (
    WidgetTester tester,
  ) async {
    final key = GlobalKey<DidChangeDependenciesCleanupTestWidgetState>();
    var triggerValue = 0;

    await tester.pumpWidget(
      TriggerInherited(
        value: triggerValue,
        child: CleanupInheritedA(
          value: 1,
          child: CleanupInheritedB(
            value: 1,
            child: DidChangeDependenciesCleanupTestWidget(key: key),
          ),
        ),
      ),
    );

    final DidChangeDependenciesCleanupTestWidgetState state = key.currentState!;
    expect(state.buildCount, 1);
    expect(state.didChangeDependenciesCount, 1);

    // Enable dependencies and trigger didChangeDependencies
    state.updateDependencies(useA: true, useB: true);
    triggerValue++;
    await tester.pumpWidget(
      TriggerInherited(
        value: triggerValue,
        child: CleanupInheritedA(
          value: 1,
          child: CleanupInheritedB(
            value: 1,
            child: DidChangeDependenciesCleanupTestWidget(key: key),
          ),
        ),
      ),
    );
    expect(state.didChangeDependenciesCount, 2);

    // Disable dependency A but keep B, then trigger didChangeDependencies
    state.updateDependencies(useA: false, useB: true);
    triggerValue++;
    await tester.pumpWidget(
      TriggerInherited(
        value: triggerValue,
        child: CleanupInheritedA(
          value: 1,
          child: CleanupInheritedB(
            value: 1,
            child: DidChangeDependenciesCleanupTestWidget(key: key),
          ),
        ),
      ),
    );
    expect(state.didChangeDependenciesCount, 3);

    // Now test if CleanupInheritedB still triggers didChangeDependencies (it should)
    final int didChangeCountBeforeB = state.didChangeDependenciesCount;
    await tester.pumpWidget(
      TriggerInherited(
        value: triggerValue,
        child: CleanupInheritedA(
          value: 1,
          child: CleanupInheritedB(
            value: 2,
            child: DidChangeDependenciesCleanupTestWidget(key: key),
          ),
        ),
      ),
    );

    expect(
      state.didChangeDependenciesCount,
      greaterThan(didChangeCountBeforeB),
      reason:
          'CleanupInheritedB dependency (cleanupUnusedDependents=false) should persist and '
          'trigger didChangeDependencies when CleanupInheritedB changes.',
    );

    // Now test if CleanupInheritedA still triggers didChangeDependencies (it should NOT)
    final int didChangeCountBeforeA = state.didChangeDependenciesCount;
    await tester.pumpWidget(
      TriggerInherited(
        value: triggerValue,
        child: CleanupInheritedA(
          value: 2,
          child: CleanupInheritedB(
            value: 2,
            child: DidChangeDependenciesCleanupTestWidget(key: key),
          ),
        ),
      ),
    );

    expect(
      state.didChangeDependenciesCount,
      didChangeCountBeforeA,
      reason:
          'CleanupInheritedA dependency (cleanupUnusedDependents=true) should have been '
          'cleaned up and should NOT trigger didChangeDependencies.',
    );
  });

  testWidgets(
    'Mixed cleanupUnusedDependents - dependencies in LayoutBuilder callback',
    (WidgetTester tester) async {
      // This test verifies that dependency cleanup works correctly when dependencies
      // are established in LayoutBuilder.builder callbacks, which are invoked during
      // the layout phase (after the build phase completes).
      //
      // Current implementation issue (framework.dart:5916):
      // _cleanupRemovedDependencies() is called at the end of performRebuild(),
      // which happens BEFORE the layout phase. This means:
      // 1. Build phase: widget.build() returns LayoutBuilder
      // 2. _cleanupRemovedDependencies() runs (doesn't see layout dependencies yet)
      // 3. Layout phase: LayoutBuilder.builder callback establishes dependencies
      // 4. Dependencies established in step 3 were already cleaned up in step 2
      //
      // Expected behavior:
      // Cleanup should happen AFTER the layout phase completes (e.g., in a
      // post-frame callback) to correctly handle dependencies established during
      // layout callbacks like LayoutBuilder, CustomMultiChildLayout, etc.
      final key = GlobalKey<LayoutBuilderCleanupTestWidgetState>();

      await tester.pumpWidget(
        CleanupInheritedA(
          value: 1,
          child: CleanupInheritedB(value: 1, child: LayoutBuilderCleanupTestWidget(key: key)),
        ),
      );

      final LayoutBuilderCleanupTestWidgetState state = key.currentState!;
      expect(state.buildCount, 1);
      expect(state.layoutBuilderCallbackCount, 1);

      state.updateDependencies(useA: true, useB: true);
      await tester.pump();
      expect(state.buildCount, 2);
      expect(state.layoutBuilderCallbackCount, 2);

      state.updateDependencies(useA: false, useB: true);
      await tester.pump();
      expect(state.buildCount, 3);
      expect(state.layoutBuilderCallbackCount, 3);

      final int didChangeCountBeforeB = state.didChangeDependenciesCount;
      await tester.pumpWidget(
        CleanupInheritedA(
          value: 1,
          child: CleanupInheritedB(value: 2, child: LayoutBuilderCleanupTestWidget(key: key)),
        ),
      );

      expect(
        state.didChangeDependenciesCount,
        greaterThan(didChangeCountBeforeB),
        reason:
            'CleanupInheritedB dependency (cleanupUnusedDependents=false) should persist and '
            'trigger didChangeDependencies when CleanupInheritedB changes, even when dependency '
            'is established in LayoutBuilder callback during layout phase.',
      );

      final int didChangeCountBeforeA = state.didChangeDependenciesCount;
      await tester.pumpWidget(
        CleanupInheritedA(
          value: 2,
          child: CleanupInheritedB(value: 2, child: LayoutBuilderCleanupTestWidget(key: key)),
        ),
      );

      expect(
        state.didChangeDependenciesCount,
        didChangeCountBeforeA,
        reason:
            'CleanupInheritedA dependency (cleanupUnusedDependents=true) should have been '
            'cleaned up and should NOT trigger didChangeDependencies, even when dependency '
            'was established in LayoutBuilder callback during layout phase.',
      );
    },
    skip: true, // Skip until cleanup is moved to post-frame callback
  );
}
