import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import 'mock.dart';

void main() {
  testWidgets('useAnimationController basic', (tester) async {
    late AnimationController controller;

    await tester.pumpWidget(
      HookBuilder(builder: (context) {
        controller = useAnimationController();
        return Container();
      }),
    );

    expect(controller.duration, isNull);
    expect(controller.reverseDuration, isNull);
    expect(controller.lowerBound, 0);
    expect(controller.upperBound, 1);
    expect(controller.value, 0);
    expect(controller.animationBehavior, AnimationBehavior.normal);
    expect(controller.debugLabel, isNull);

    controller
      ..duration = const Duration(seconds: 1)
      ..reverseDuration = const Duration(seconds: 1)
      // check has a ticker
      ..forward();

    // dispose
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('diagnostics', (tester) async {
    await tester.pumpWidget(
      HookBuilder(builder: (context) {
        useAnimationController(
          animationBehavior: AnimationBehavior.preserve,
          duration: const Duration(seconds: 1),
          reverseDuration: const Duration(milliseconds: 500),
          initialValue: 42,
          lowerBound: 24,
          upperBound: 84,
          debugLabel: 'Foo',
        );
        return const SizedBox();
      }),
    );

    final element = tester.element(find.byType(HookBuilder));

    expect(
      element
          .toDiagnosticsNode(style: DiagnosticsTreeStyle.offstage)
          .toStringDeep(),
      equalsIgnoringHashCodes(
        'HookBuilder\n'
        ' │ useSingleTickerProvider\n'
        ' │ useAnimationController:\n'
        ' │   _AnimationControllerHookState#00000(AnimationController#00000(▶\n'
        ' │   42.000; paused; for Foo), duration: 0:00:01.000000,\n'
        ' │   reverseDuration: 0:00:00.500000)\n'
        ' └SizedBox(renderObject: RenderConstrainedBox#00000)\n',
      ),
    );
  });

  testWidgets('useAnimationController complex', (tester) async {
    late AnimationController controller;

    TickerProvider provider;
    provider = _TickerProvider();
    void onTick(Duration _) {}
    when(provider.createTicker(onTick)).thenAnswer((_) {
      return tester.createTicker(onTick);
    });

    await tester.pumpWidget(
      HookBuilder(builder: (context) {
        controller = useAnimationController(
          vsync: provider,
          animationBehavior: AnimationBehavior.preserve,
          duration: const Duration(seconds: 1),
          reverseDuration: const Duration(milliseconds: 500),
          initialValue: 42,
          lowerBound: 24,
          upperBound: 84,
          debugLabel: 'Foo',
        );
        return Container();
      }),
    );

    verify(provider.createTicker(onTick)).called(1);
    verifyNoMoreInteractions(provider);

    // check has a ticker
    // ignore: unawaited_futures
    controller.forward();
    expect(controller.duration, const Duration(seconds: 1));
    expect(controller.reverseDuration, const Duration(milliseconds: 500));
    expect(controller.lowerBound, 24);
    expect(controller.upperBound, 84);
    expect(controller.value, 42);
    expect(controller.animationBehavior, AnimationBehavior.preserve);
    expect(controller.debugLabel, 'Foo');

    final previousController = controller;
    provider = _TickerProvider();
    when(provider.createTicker(onTick)).thenAnswer((_) {
      return tester.createTicker(onTick);
    });

    await tester.pumpWidget(
      HookBuilder(builder: (context) {
        controller = useAnimationController(
          vsync: provider,
          duration: const Duration(seconds: 2),
          reverseDuration: const Duration(seconds: 1),
          debugLabel: 'Bar',
        );
        return Container();
      }),
    );

    verify(provider.createTicker(onTick)).called(1);
    verifyNoMoreInteractions(provider);
    expect(controller, previousController);
    expect(controller.duration, const Duration(seconds: 2));
    expect(controller.reverseDuration, const Duration(seconds: 1));
    expect(controller.lowerBound, 24);
    expect(controller.upperBound, 84);
    expect(controller.value, 42);
    expect(controller.animationBehavior, AnimationBehavior.preserve);
    expect(controller.debugLabel, 'Foo');

    // dispose
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('switch from uncontrolled to controlled throws', (tester) async {
    await tester.pumpWidget(HookBuilder(
      builder: (context) {
        useAnimationController();
        return Container();
      },
    ));

    await tester.pumpWidget(HookBuilder(
      builder: (context) {
        useAnimationController(vsync: tester);
        return Container();
      },
    ));

    expect(tester.takeException(), isStateError);
  });
  testWidgets('switch from controlled to uncontrolled throws', (tester) async {
    await tester.pumpWidget(HookBuilder(
      builder: (context) {
        useAnimationController(vsync: tester);
        return Container();
      },
    ));

    await tester.pumpWidget(HookBuilder(
      builder: (context) {
        useAnimationController();
        return Container();
      },
    ));

    expect(tester.takeException(), isStateError);
  });

  testWidgets('useAnimationController pass down keys', (tester) async {
    List<Object?>? keys;
    late AnimationController controller;
    await tester.pumpWidget(HookBuilder(
      builder: (context) {
        controller = useAnimationController(keys: keys);
        return Container();
      },
    ));

    final previous = controller;
    keys = [];

    await tester.pumpWidget(HookBuilder(
      builder: (context) {
        controller = useAnimationController(keys: keys);
        return Container();
      },
    ));

    expect(previous, isNot(controller));
  });
}

class _TickerProvider extends Mock implements TickerProvider {
  @override
  Ticker createTicker(TickerCallback onTick) => super.noSuchMethod(
        Invocation.getter(#createTicker),
        returnValue: Ticker(onTick),
      ) as Ticker;
}

class MockEffect extends Mock {
  VoidCallback call();
}
