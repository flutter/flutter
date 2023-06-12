import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import 'mock.dart';

void main() {
  testWidgets('debugFillProperties', (tester) async {
    await tester.pumpWidget(
      HookBuilder(builder: (context) {
        useSingleTickerProvider();
        return const SizedBox();
      }),
    );

    await tester.pump();

    final element = tester.element(find.byType(HookBuilder));

    expect(
      element
          .toDiagnosticsNode(style: DiagnosticsTreeStyle.offstage)
          .toStringDeep(),
      equalsIgnoringHashCodes(
        'HookBuilder\n'
        ' │ useSingleTickerProvider\n'
        ' └SizedBox(renderObject: RenderConstrainedBox#00000)\n',
      ),
    );
  });

  testWidgets('useSingleTickerProvider basic', (tester) async {
    late TickerProvider provider;

    await tester.pumpWidget(TickerMode(
      enabled: true,
      child: HookBuilder(builder: (context) {
        provider = useSingleTickerProvider();
        return Container();
      }),
    ));

    final animationController = AnimationController(
        vsync: provider, duration: const Duration(seconds: 1))
      ..forward();

    expect(() => AnimationController(vsync: provider), throwsFlutterError);

    animationController.dispose();

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('useSingleTickerProvider unused', (tester) async {
    await tester.pumpWidget(HookBuilder(builder: (context) {
      useSingleTickerProvider();
      return Container();
    }));

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('useSingleTickerProvider still active', (tester) async {
    late TickerProvider provider;

    await tester.pumpWidget(TickerMode(
      enabled: true,
      child: HookBuilder(builder: (context) {
        provider = useSingleTickerProvider();
        return Container();
      }),
    ));

    final animationController = AnimationController(
      vsync: provider,
      duration: const Duration(seconds: 1),
    );

    try {
      // ignore: unawaited_futures
      animationController.forward();

      await tester.pumpWidget(const SizedBox());

      expect(tester.takeException(), isFlutterError);
    } finally {
      animationController.dispose();
    }
  });

  testWidgets('useSingleTickerProvider pass down keys', (tester) async {
    late TickerProvider provider;
    List<Object?>? keys;

    await tester.pumpWidget(HookBuilder(builder: (context) {
      provider = useSingleTickerProvider(keys: keys);
      return Container();
    }));

    final previousProvider = provider;
    keys = [];

    await tester.pumpWidget(HookBuilder(builder: (context) {
      provider = useSingleTickerProvider(keys: keys);
      return Container();
    }));

    expect(previousProvider, isNot(provider));
  });
}
