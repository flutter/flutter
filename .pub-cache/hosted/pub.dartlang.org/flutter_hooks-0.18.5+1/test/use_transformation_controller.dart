import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/src/framework.dart';
import 'package:flutter_hooks/src/hooks.dart';

import 'mock.dart';

void main() {
  testWidgets('debugFillProperties', (tester) async {
    await tester.pumpWidget(
      HookBuilder(builder: (context) {
        useTransformationController();
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
        ' │ useTransformationController: TransformationController#00000(no clients)\n'
        ' └SizedBox(renderObject: RenderConstrainedBox#00000)\n',
      ),
    );
  });

  group('useTransformationController', () {
    testWidgets('initial values matches with real constructor', (tester) async {
      late TransformationController controller;
      late TransformationController controller2;

      await tester.pumpWidget(
        HookBuilder(builder: (context) {
          controller2 = TransformationController();
          controller = useTransformationController();
          return Container();
        }),
      );

      expect(controller.value, controller2.value);
    });
    testWidgets("returns a TransformationController that doesn't change",
        (tester) async {
      late TransformationController controller;
      late TransformationController controller2;

      await tester.pumpWidget(
        HookBuilder(builder: (context) {
          controller = useTransformationController();
          return Container();
        }),
      );

      expect(controller, isA<TransformationController>());

      await tester.pumpWidget(
        HookBuilder(builder: (context) {
          controller2 = useTransformationController();
          return Container();
        }),
      );

      expect(identical(controller, controller2), isTrue);
    });

    testWidgets('passes hook parameters to the TransformationController',
        (tester) async {
      late TransformationController controller;

      await tester.pumpWidget(
        HookBuilder(
          builder: (context) {
            controller = useTransformationController(
              initialValue: Matrix4.translationValues(1, 2, 3),
            );

            return Container();
          },
        ),
      );

      expect(controller.value, Matrix4.translationValues(1, 2, 3));
    });
  });
}

class TickerProviderMock extends Mock implements TickerProvider {}
