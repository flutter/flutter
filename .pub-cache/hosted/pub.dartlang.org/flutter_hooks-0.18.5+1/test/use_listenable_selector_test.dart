import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import 'mock.dart';

void main() {
  testWidgets('debugFillProperties', (tester) async {
    await tester.pumpWidget(
      HookBuilder(
        builder: (context) {
          final listenable = ValueNotifier<int>(42);
          useListenableSelector<bool>(listenable, () => listenable.value.isOdd);
          return const SizedBox();
        },
      ),
    );

    final element = tester.element(find.byType(HookBuilder));

    expect(
      element
          .toDiagnosticsNode(style: DiagnosticsTreeStyle.offstage)
          .toStringDeep(),
      equalsIgnoringHashCodes(
        'HookBuilder\n'
        ' │ useListenableSelector<bool>\n'
        ' └SizedBox(renderObject: RenderConstrainedBox#00000)\n'
        '',
      ),
    );
  });

  testWidgets('basic', (tester) async {
    final listenable = ValueNotifier(0);
    // ignore: prefer_function_declarations_over_variables
    final isOddSelector = () => listenable.value.isOdd;
    var isOdd = listenable.value.isOdd;

    await tester.pumpWidget(
      HookBuilder(
        builder: (context) {
          isOdd = useListenableSelector(listenable, isOddSelector);
          return Container();
        },
      ),
    );

    final element = tester.firstElement(find.byType(HookBuilder));

    // ignore: invalid_use_of_protected_member
    expect(listenable.hasListeners, true);
    expect(listenable.value, 0);
    expect(isOdd, false);
    expect(element.dirty, false);

    listenable.value++;

    expect(element.dirty, true);
    expect(listenable.value, 1);

    await tester.pump();

    expect(isOdd, true);
    expect(element.dirty, false);

    listenable.value++;

    expect(element.dirty, true);

    await tester.pump();

    expect(listenable.value, 2);
    expect(isOdd, false);

    listenable.value = listenable.value + 2;

    expect(element.dirty, false);

    await tester.pump();

    expect(listenable.value, 4);
    expect(isOdd, false);

    listenable.dispose();
  });

  testWidgets('update selector', (tester) async {
    final listenable = ValueNotifier(0);
    var isOdd = false;
    // ignore: prefer_function_declarations_over_variables
    bool isOddSelector() => listenable.value.isOdd;
    var isEven = false;
    bool isEvenSelector() => listenable.value.isEven;

    await tester.pumpWidget(
      HookBuilder(
        builder: (context) {
          isOdd = useListenableSelector(listenable, isOddSelector);
          return Container();
        },
      ),
    );

    final element = tester.firstElement(find.byType(HookBuilder));

    // ignore: invalid_use_of_protected_member
    expect(listenable.hasListeners, true);
    expect(listenable.value, 0);
    expect(isOdd, false);
    expect(element.dirty, false);

    listenable.value++;

    expect(element.dirty, true);
    expect(listenable.value, 1);

    await tester.pump();

    expect(isOdd, true);
    expect(element.dirty, false);

    await tester.pumpWidget(
      HookBuilder(
        builder: (context) {
          isEven = useListenableSelector(listenable, isEvenSelector);
          return Container();
        },
      ),
    );

    expect(listenable.value, 1);
    expect(isEven, false);

    listenable.dispose();
  });

  testWidgets('update listenable', (tester) async {
    var listenable = ValueNotifier(0);
    bool isOddSelector() => listenable.value.isOdd;
    var isOdd = false;

    await tester.pumpWidget(
      HookBuilder(
        builder: (context) {
          isOdd = useListenableSelector(listenable, isOddSelector);
          return Container();
        },
      ),
    );

    expect(isOdd, false);

    final previousListenable = listenable;
    listenable = ValueNotifier(1);

    await tester.pumpWidget(
      HookBuilder(
        builder: (context) {
          isOdd = useListenableSelector(listenable, isOddSelector);
          return Container();
        },
      ),
    );

    // ignore: invalid_use_of_protected_member
    expect(previousListenable.hasListeners, false);
    expect(isOdd, true);

    listenable.dispose();
    previousListenable.dispose();
  });
}
