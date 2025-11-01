// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Nested TickerMode cannot turn tickers back on', (WidgetTester tester) async {
    int outerTickCount = 0;
    int innerTickCount = 0;

    Widget nestedTickerModes({required bool innerEnabled, required bool outerEnabled}) {
      return Directionality(
        textDirection: TextDirection.rtl,
        child: TickerMode(
          enabled: outerEnabled,
          child: Row(
            children: <Widget>[
              _TickingWidget(
                onTick: () {
                  outerTickCount++;
                },
              ),
              TickerMode(
                enabled: innerEnabled,
                child: _TickingWidget(
                  onTick: () {
                    innerTickCount++;
                  },
                ),
              ),
            ],
          ),
        ),
      );
    }

    await tester.pumpWidget(nestedTickerModes(outerEnabled: false, innerEnabled: true));

    expect(outerTickCount, 0);
    expect(innerTickCount, 0);
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(outerTickCount, 0);
    expect(innerTickCount, 0);

    await tester.pumpWidget(nestedTickerModes(outerEnabled: true, innerEnabled: false));
    outerTickCount = 0;
    innerTickCount = 0;
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(outerTickCount, 4);
    expect(innerTickCount, 0);

    await tester.pumpWidget(nestedTickerModes(outerEnabled: true, innerEnabled: true));
    outerTickCount = 0;
    innerTickCount = 0;
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(outerTickCount, 4);
    expect(innerTickCount, 4);

    await tester.pumpWidget(nestedTickerModes(outerEnabled: false, innerEnabled: false));
    outerTickCount = 0;
    innerTickCount = 0;
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(outerTickCount, 0);
    expect(innerTickCount, 0);
  });

  testWidgets('Changing TickerMode does not rebuild widgets with SingleTickerProviderStateMixin', (
    WidgetTester tester,
  ) async {
    Widget widgetUnderTest({required bool tickerEnabled}) {
      return TickerMode(enabled: tickerEnabled, child: const _TickingWidget());
    }

    _TickingWidgetState state() => tester.state<_TickingWidgetState>(find.byType(_TickingWidget));

    await tester.pumpWidget(widgetUnderTest(tickerEnabled: true));
    expect(state().ticker.isTicking, isTrue);
    expect(state().buildCount, 1);

    await tester.pumpWidget(widgetUnderTest(tickerEnabled: false));
    expect(state().ticker.isTicking, isFalse);
    expect(state().buildCount, 1);

    await tester.pumpWidget(widgetUnderTest(tickerEnabled: true));
    expect(state().ticker.isTicking, isTrue);
    expect(state().buildCount, 1);
  });

  testWidgets('Changing TickerMode does not rebuild widgets with TickerProviderStateMixin', (
    WidgetTester tester,
  ) async {
    Widget widgetUnderTest({required bool tickerEnabled}) {
      return TickerMode(enabled: tickerEnabled, child: const _MultiTickingWidget());
    }

    _MultiTickingWidgetState state() =>
        tester.state<_MultiTickingWidgetState>(find.byType(_MultiTickingWidget));

    await tester.pumpWidget(widgetUnderTest(tickerEnabled: true));
    expect(state().ticker.isTicking, isTrue);
    expect(state().buildCount, 1);

    await tester.pumpWidget(widgetUnderTest(tickerEnabled: false));
    expect(state().ticker.isTicking, isFalse);
    expect(state().buildCount, 1);

    await tester.pumpWidget(widgetUnderTest(tickerEnabled: true));
    expect(state().ticker.isTicking, isTrue);
    expect(state().buildCount, 1);
  });

  testWidgets(
    'Moving widgets with SingleTickerProviderStateMixin to a new TickerMode ancestor works',
    (WidgetTester tester) async {
      final GlobalKey tickingWidgetKey = GlobalKey();
      Widget widgetUnderTest({required LocalKey tickerModeKey, required bool tickerEnabled}) {
        return TickerMode(
          key: tickerModeKey,
          enabled: tickerEnabled,
          child: _TickingWidget(key: tickingWidgetKey),
        );
      }

      // Using different local keys to simulate changing TickerMode ancestors.
      await tester.pumpWidget(widgetUnderTest(tickerEnabled: true, tickerModeKey: UniqueKey()));
      final State tickerModeState = tester.state(find.byType(TickerMode));
      final _TickingWidgetState tickingState = tester.state<_TickingWidgetState>(
        find.byType(_TickingWidget),
      );
      expect(tickingState.ticker.isTicking, isTrue);

      await tester.pumpWidget(widgetUnderTest(tickerEnabled: false, tickerModeKey: UniqueKey()));
      expect(tester.state(find.byType(TickerMode)), isNot(same(tickerModeState)));
      expect(tickingState, same(tester.state<_TickingWidgetState>(find.byType(_TickingWidget))));
      expect(tickingState.ticker.isTicking, isFalse);
    },
  );

  testWidgets('Moving widgets with TickerProviderStateMixin to a new TickerMode ancestor works', (
    WidgetTester tester,
  ) async {
    final GlobalKey tickingWidgetKey = GlobalKey();
    Widget widgetUnderTest({required LocalKey tickerModeKey, required bool tickerEnabled}) {
      return TickerMode(
        key: tickerModeKey,
        enabled: tickerEnabled,
        child: _MultiTickingWidget(key: tickingWidgetKey),
      );
    }

    // Using different local keys to simulate changing TickerMode ancestors.
    await tester.pumpWidget(widgetUnderTest(tickerEnabled: true, tickerModeKey: UniqueKey()));
    final State tickerModeState = tester.state(find.byType(TickerMode));
    final _MultiTickingWidgetState tickingState = tester.state<_MultiTickingWidgetState>(
      find.byType(_MultiTickingWidget),
    );
    expect(tickingState.ticker.isTicking, isTrue);

    await tester.pumpWidget(widgetUnderTest(tickerEnabled: false, tickerModeKey: UniqueKey()));
    expect(tester.state(find.byType(TickerMode)), isNot(same(tickerModeState)));
    expect(
      tickingState,
      same(tester.state<_MultiTickingWidgetState>(find.byType(_MultiTickingWidget))),
    );
    expect(tickingState.ticker.isTicking, isFalse);
  });

  testWidgets('Ticking widgets in old route do not rebuild when new route is pushed', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        routes: <String, WidgetBuilder>{'/foo': (BuildContext context) => const Text('New route')},
        home: const Row(
          children: <Widget>[_TickingWidget(), _MultiTickingWidget(), Text('Old route')],
        ),
      ),
    );

    _MultiTickingWidgetState multiTickingState() => tester.state<_MultiTickingWidgetState>(
      find.byType(_MultiTickingWidget, skipOffstage: false),
    );
    _TickingWidgetState tickingState() =>
        tester.state<_TickingWidgetState>(find.byType(_TickingWidget, skipOffstage: false));

    expect(find.text('Old route'), findsOneWidget);
    expect(find.text('New route'), findsNothing);

    expect(multiTickingState().ticker.isTicking, isTrue);
    expect(multiTickingState().buildCount, 1);
    expect(tickingState().ticker.isTicking, isTrue);
    expect(tickingState().buildCount, 1);

    tester.state<NavigatorState>(find.byType(Navigator)).pushNamed('/foo');
    await tester.pumpAndSettle();
    expect(find.text('Old route'), findsNothing);
    expect(find.text('New route'), findsOneWidget);

    expect(multiTickingState().ticker.isTicking, isFalse);
    expect(multiTickingState().buildCount, 1);
    expect(tickingState().ticker.isTicking, isFalse);
    expect(tickingState().buildCount, 1);
  });

  testWidgets('TickerMode.forceFrames propagates to SingleTickerProviderStateMixin', (
    WidgetTester tester,
  ) async {
    Widget widgetUnderTest({required bool forceFrames}) {
      return TickerMode(enabled: true, forceFrames: forceFrames, child: const _TickingWidget());
    }

    _TickingWidgetState state() => tester.state<_TickingWidgetState>(find.byType(_TickingWidget));

    await tester.pumpWidget(widgetUnderTest(forceFrames: false));
    expect(state().ticker.forceFrames, isFalse);
    expect(state().buildCount, 1);

    await tester.pumpWidget(widgetUnderTest(forceFrames: true));
    expect(state().ticker.forceFrames, isTrue);
    expect(state().buildCount, 1);

    await tester.pumpWidget(widgetUnderTest(forceFrames: false));
    expect(state().ticker.forceFrames, isFalse);
    expect(state().buildCount, 1);
  });

  testWidgets('TickerMode.forceFrames propagates to TickerProviderStateMixin', (
    WidgetTester tester,
  ) async {
    Widget widgetUnderTest({required bool forceFrames}) {
      return TickerMode(
        enabled: true,
        forceFrames: forceFrames,
        child: const _MultiTickingWidget(),
      );
    }

    _MultiTickingWidgetState state() =>
        tester.state<_MultiTickingWidgetState>(find.byType(_MultiTickingWidget));

    await tester.pumpWidget(widgetUnderTest(forceFrames: false));
    expect(state().ticker.forceFrames, isFalse);
    expect(state().buildCount, 1);

    await tester.pumpWidget(widgetUnderTest(forceFrames: true));
    expect(state().ticker.forceFrames, isTrue);
    expect(state().buildCount, 1);

    await tester.pumpWidget(widgetUnderTest(forceFrames: false));
    expect(state().ticker.forceFrames, isFalse);
    expect(state().buildCount, 1);
  });

  testWidgets('Nested TickerMode.forceFrames uses OR semantics', (WidgetTester tester) async {
    Widget nestedTickerModes({required bool innerForce, required bool outerForce}) {
      return Directionality(
        textDirection: TextDirection.rtl,
        child: TickerMode(
          enabled: true,
          forceFrames: outerForce,
          child: Row(
            children: <Widget>[
              const _TickingWidget(key: ValueKey<String>('outer')),
              TickerMode(
                enabled: true,
                forceFrames: innerForce,
                child: const _TickingWidget(key: ValueKey<String>('inner')),
              ),
            ],
          ),
        ),
      );
    }

    _TickingWidgetState outerState() =>
        tester.state<_TickingWidgetState>(find.byKey(const ValueKey<String>('outer')));
    _TickingWidgetState innerState() =>
        tester.state<_TickingWidgetState>(find.byKey(const ValueKey<String>('inner')));

    // Both false -> both should not force frames
    await tester.pumpWidget(nestedTickerModes(outerForce: false, innerForce: false));
    expect(outerState().ticker.forceFrames, isFalse);
    expect(innerState().ticker.forceFrames, isFalse);

    // Outer true -> both should force frames (OR semantics)
    await tester.pumpWidget(nestedTickerModes(outerForce: true, innerForce: false));
    expect(outerState().ticker.forceFrames, isTrue);
    expect(innerState().ticker.forceFrames, isTrue);

    // Inner true -> only inner should force frames
    await tester.pumpWidget(nestedTickerModes(outerForce: false, innerForce: true));
    expect(outerState().ticker.forceFrames, isFalse);
    expect(innerState().ticker.forceFrames, isTrue);

    // Both true -> both should force frames
    await tester.pumpWidget(nestedTickerModes(outerForce: true, innerForce: true));
    expect(outerState().ticker.forceFrames, isTrue);
    expect(innerState().ticker.forceFrames, isTrue);
  });

  testWidgets('TickerMode.merge preserves ambient enabled and overrides forceFrames', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      TickerMode(
        enabled: false,
        child: TickerMode.merge(forceFrames: true, child: const _TickingWidget()),
      ),
    );

    final _TickingWidgetState state = tester.state<_TickingWidgetState>(
      find.byType(_TickingWidget),
    );
    // enabled should be false (inherited from ancestor)
    expect(state.ticker.muted, isTrue);
    // forceFrames should be true (merged override)
    expect(state.ticker.forceFrames, isTrue);
  });

  testWidgets('TickerMode.merge respects AND semantics for enabled', (WidgetTester tester) async {
    // Test that merge cannot override parent's enabled=false due to AND semantics
    await tester.pumpWidget(
      TickerMode(
        enabled: false,
        child: TickerMode.merge(enabled: true, child: const _TickingWidget()),
      ),
    );

    final _TickingWidgetState state = tester.state<_TickingWidgetState>(
      find.byType(_TickingWidget),
    );
    // enabled uses AND semantics - child cannot re-enable when parent disables
    expect(state.ticker.muted, isTrue);
    // forceFrames should be false (inherited)
    expect(state.ticker.forceFrames, isFalse);
  });

  testWidgets('TickerMode.merge can disable when parent is enabled', (WidgetTester tester) async {
    // Test that merge can set enabled=false when parent is enabled=true
    await tester.pumpWidget(
      TickerMode(
        enabled: true,
        child: TickerMode.merge(enabled: false, child: const _TickingWidget()),
      ),
    );

    final _TickingWidgetState state = tester.state<_TickingWidgetState>(
      find.byType(_TickingWidget),
    );
    // enabled=false overrides parent's enabled=true (AND: true && false = false)
    expect(state.ticker.muted, isTrue);
    // forceFrames should be false (inherited)
    expect(state.ticker.forceFrames, isFalse);
  });

  testWidgets('TickerMode.merge with no ancestor uses fallback values', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(TickerMode.merge(forceFrames: true, child: const _TickingWidget()));

    final _TickingWidgetState state = tester.state<_TickingWidgetState>(
      find.byType(_TickingWidget),
    );
    // enabled should be true (fallback)
    expect(state.ticker.muted, isFalse);
    // forceFrames should be true (merged override)
    expect(state.ticker.forceFrames, isTrue);
  });

  testWidgets('TickerMode.valuesOf returns correct values', (WidgetTester tester) async {
    late TickerModeData capturedValues;

    await tester.pumpWidget(
      TickerMode(
        enabled: false,
        forceFrames: true,
        child: Builder(
          builder: (BuildContext context) {
            capturedValues = TickerMode.valuesOf(context);
            return Container();
          },
        ),
      ),
    );

    expect(capturedValues.enabled, isFalse);
    expect(capturedValues.forceFrames, isTrue);
  });

  testWidgets('TickerMode.valuesOf returns fallback when no ancestor', (WidgetTester tester) async {
    late TickerModeData capturedValues;

    await tester.pumpWidget(
      Builder(
        builder: (BuildContext context) {
          capturedValues = TickerMode.valuesOf(context);
          return Container();
        },
      ),
    );

    expect(capturedValues.enabled, isTrue);
    expect(capturedValues.forceFrames, isFalse);
    expect(capturedValues, equals(TickerModeData.fallback));
  });

  testWidgets('TickerMode.getValuesNotifier notifies listeners', (WidgetTester tester) async {
    late ValueListenable<TickerModeData> notifier;
    final List<TickerModeData> notifiedValues = <TickerModeData>[];

    await tester.pumpWidget(
      TickerMode(
        enabled: true,
        child: Builder(
          builder: (BuildContext context) {
            notifier = TickerMode.getValuesNotifier(context);
            return Container();
          },
        ),
      ),
    );

    notifier.addListener(() {
      notifiedValues.add(notifier.value);
    });

    expect(notifier.value.enabled, isTrue);
    expect(notifier.value.forceFrames, isFalse);

    // Change forceFrames
    await tester.pumpWidget(
      TickerMode(
        enabled: true,
        forceFrames: true,
        child: Builder(
          builder: (BuildContext context) {
            return Container();
          },
        ),
      ),
    );

    expect(notifiedValues.length, 1);
    expect(notifiedValues.last.enabled, isTrue);
    expect(notifiedValues.last.forceFrames, isTrue);
  });

  test('TickerModeData equality works correctly', () {
    const TickerModeData data1 = TickerModeData.fallback;
    const TickerModeData data2 = TickerModeData.fallback;
    const TickerModeData data3 = TickerModeData(enabled: false, forceFrames: false);
    const TickerModeData data4 = TickerModeData(enabled: true, forceFrames: true);

    expect(data1, equals(data2));
    expect(data1, isNot(equals(data3)));
    expect(data1, isNot(equals(data4)));
    expect(data1.hashCode, equals(data2.hashCode));
    expect(data1, equals(TickerModeData.fallback));
  });

  testWidgets('Deprecated TickerMode.of still works', (WidgetTester tester) async {
    late bool capturedEnabled;

    await tester.pumpWidget(
      TickerMode(
        enabled: false,
        forceFrames: true,
        child: Builder(
          builder: (BuildContext context) {
            // ignore: deprecated_member_use
            capturedEnabled = TickerMode.of(context);
            return Container();
          },
        ),
      ),
    );

    expect(capturedEnabled, isFalse);
  });

  testWidgets('Deprecated TickerMode.getNotifier still works', (WidgetTester tester) async {
    late ValueListenable<bool> notifier;

    await tester.pumpWidget(
      TickerMode(
        enabled: false,
        forceFrames: true,
        child: Builder(
          builder: (BuildContext context) {
            // ignore: deprecated_member_use
            notifier = TickerMode.getNotifier(context);
            return Container();
          },
        ),
      ),
    );

    expect(notifier.value, isFalse);
  });
}

class _TickingWidget extends StatefulWidget {
  const _TickingWidget({super.key, this.onTick});

  final VoidCallback? onTick;

  @override
  State<_TickingWidget> createState() => _TickingWidgetState();
}

class _TickingWidgetState extends State<_TickingWidget> with SingleTickerProviderStateMixin {
  late Ticker ticker;
  int buildCount = 0;

  @override
  void initState() {
    super.initState();
    ticker = createTicker((Duration _) {
      widget.onTick?.call();
    })..start();
  }

  @override
  Widget build(BuildContext context) {
    buildCount += 1;
    return Container();
  }

  @override
  void dispose() {
    ticker.dispose();
    super.dispose();
  }
}

class _MultiTickingWidget extends StatefulWidget {
  const _MultiTickingWidget({super.key});

  @override
  State<_MultiTickingWidget> createState() => _MultiTickingWidgetState();
}

class _MultiTickingWidgetState extends State<_MultiTickingWidget> with TickerProviderStateMixin {
  late Ticker ticker;
  int buildCount = 0;

  @override
  void initState() {
    super.initState();
    ticker = createTicker((Duration _) {})..start();
  }

  @override
  Widget build(BuildContext context) {
    buildCount += 1;
    return Container();
  }

  @override
  void dispose() {
    ticker.dispose();
    super.dispose();
  }
}
