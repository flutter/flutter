import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_hooks/src/framework.dart';
import 'package:flutter_hooks/src/hooks.dart';

import 'mock.dart';

void main() {
  testWidgets('debugFillProperties', (tester) async {
    await tester.pumpWidget(
      HookBuilder(builder: (context) {
        useTabController(initialLength: 4);
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
        " │ useTabController: Instance of 'TabController'\n"
        ' └SizedBox(renderObject: RenderConstrainedBox#00000)\n',
      ),
    );
  });

  group('useTabController', () {
    testWidgets('initial values matches with real constructor', (tester) async {
      late TabController controller;
      late TabController controller2;

      await tester.pumpWidget(
        HookBuilder(builder: (context) {
          final vsync = useSingleTickerProvider();
          controller2 = TabController(length: 4, vsync: vsync);
          controller = useTabController(initialLength: 4);
          return Container();
        }),
      );

      expect(controller.index, controller2.index);
    });
    testWidgets("returns a TabController that doesn't change", (tester) async {
      late TabController controller;
      late TabController controller2;

      await tester.pumpWidget(
        HookBuilder(builder: (context) {
          controller = useTabController(initialLength: 1);
          return Container();
        }),
      );

      expect(controller, isA<TabController>());

      await tester.pumpWidget(
        HookBuilder(builder: (context) {
          controller2 = useTabController(initialLength: 1);
          return Container();
        }),
      );

      expect(identical(controller, controller2), isTrue);
    });
    testWidgets('changing length is no-op', (tester) async {
      late TabController controller;

      await tester.pumpWidget(
        HookBuilder(builder: (context) {
          controller = useTabController(initialLength: 1);
          return Container();
        }),
      );

      expect(controller.length, 1);

      await tester.pumpWidget(
        HookBuilder(builder: (context) {
          controller = useTabController(initialLength: 2);
          return Container();
        }),
      );

      expect(controller.length, 1);
    });

    testWidgets('passes hook parameters to the TabController', (tester) async {
      late TabController controller;

      await tester.pumpWidget(
        HookBuilder(
          builder: (context) {
            controller = useTabController(initialIndex: 2, initialLength: 4);

            return Container();
          },
        ),
      );

      expect(controller.index, 2);
      expect(controller.length, 4);
    });
    testWidgets('allows passing custom vsync', (tester) async {
      final vsync = TickerProviderMock();
      final ticker = Ticker((_) {});
      when(vsync.createTicker((_) {})).thenReturn(ticker);

      await tester.pumpWidget(
        HookBuilder(
          builder: (context) {
            useTabController(initialLength: 1, vsync: vsync);

            return Container();
          },
        ),
      );

      verify(vsync.createTicker((_) {})).called(1);
      verifyNoMoreInteractions(vsync);

      await tester.pumpWidget(
        HookBuilder(
          builder: (context) {
            useTabController(initialLength: 1, vsync: vsync);
            return Container();
          },
        ),
      );

      verifyNoMoreInteractions(vsync);
      ticker.dispose();
    });
  });
}

class TickerProviderMock extends Mock implements TickerProvider {
  @override
  Ticker createTicker(TickerCallback onTick) => super.noSuchMethod(
        Invocation.getter(#createTicker),
        returnValue: Ticker(onTick),
      ) as Ticker;
}
