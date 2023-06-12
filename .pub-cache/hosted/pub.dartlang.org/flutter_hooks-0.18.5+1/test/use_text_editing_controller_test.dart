import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/src/framework.dart';
import 'package:flutter_hooks/src/hooks.dart';
import 'package:flutter_test/flutter_test.dart';

import 'mock.dart';

void main() {
  testWidgets('debugFillProperties', (tester) async {
    await tester.pumpWidget(
      HookBuilder(builder: (context) {
        useTextEditingController();
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
        ' │ useTextEditingController:\n'
        ' │   TextEditingController#00000(TextEditingValue(text: ┤├,\n'
        ' │   selection: TextSelection.invalid, composing: TextRange(start:\n'
        ' │   -1, end: -1)))\n'
        ' └SizedBox(renderObject: RenderConstrainedBox#00000)\n',
      ),
    );
  });

  testWidgets('useTextEditingController returns a controller', (tester) async {
    final rebuilder = ValueNotifier(0);
    late TextEditingController controller;

    await tester.pumpWidget(HookBuilder(
      builder: (context) {
        controller = useTextEditingController();
        useValueListenable(rebuilder);
        return Container();
      },
    ));

    expect(controller, isNotNull);
    controller.addListener(() {});

    // rebuild hook
    final firstController = controller;
    rebuilder.notifyListeners();
    await tester.pumpAndSettle();
    expect(identical(controller, firstController), isTrue,
        reason: 'Controllers should be identical after rebuilds');

    // pump another widget so that the old one gets disposed
    await tester.pumpWidget(Container());

    expect(
      () => controller.addListener(() {}),
      throwsA(isFlutterError.having(
          (e) => e.message, 'message', contains('disposed'))),
    );
  });

  testWidgets('respects initial text property', (tester) async {
    final rebuilder = ValueNotifier(0);
    late TextEditingController controller;
    const initialText = 'hello hooks';
    var targetText = initialText;

    await tester.pumpWidget(HookBuilder(
      builder: (context) {
        controller = useTextEditingController(text: targetText);
        useValueListenable(rebuilder);
        return Container();
      },
    ));

    expect(controller.text, targetText);

    // change text and rebuild - the value of the controller shouldn't change
    targetText = "can't see me!";
    rebuilder.notifyListeners();
    await tester.pumpAndSettle();
    expect(controller.text, initialText);
  });

  testWidgets('respects initial value property', (tester) async {
    final rebuilder = ValueNotifier(0);
    const initialValue = TextEditingValue(
      text: 'foo',
      selection: TextSelection.collapsed(offset: 2),
    );
    var targetValue = initialValue;
    late TextEditingController controller;

    await tester.pumpWidget(HookBuilder(
      builder: (context) {
        controller = useTextEditingController.fromValue(targetValue);
        useValueListenable(rebuilder);
        return Container();
      },
    ));

    expect(controller.value, targetValue);

    // similar to above - the value should not change after a rebuild
    targetValue = const TextEditingValue(text: 'another');
    rebuilder.notifyListeners();
    await tester.pumpAndSettle();
    expect(controller.value, initialValue);
  });
}
