import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import 'mock.dart';

void main() {
  testWidgets('diagnostics', (tester) async {
    await tester.pumpWidget(
      HookBuilder(builder: (context) {
        useValueListenable(ValueNotifier(0));
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
        ' │ useValueListenable: 0\n'
        ' └SizedBox(renderObject: RenderConstrainedBox#00000)\n',
      ),
    );
  });
  testWidgets('useValueListenable', (tester) async {
    var listenable = ValueNotifier(0);
    late int result;

    Future<void> pump() {
      return tester.pumpWidget(HookBuilder(
        builder: (context) {
          result = useValueListenable(listenable);
          return Container();
        },
      ));
    }

    await pump();

    final element = tester.firstElement(find.byType(HookBuilder));

    expect(result, 0);
    // ignore: invalid_use_of_protected_member
    expect(listenable.hasListeners, true);
    expect(element.dirty, false);
    listenable.value++;
    expect(element.dirty, true);
    await tester.pump();
    expect(result, 1);
    expect(element.dirty, false);

    final previousListenable = listenable;
    listenable = ValueNotifier(0);

    await pump();

    expect(result, 0);
    // ignore: invalid_use_of_protected_member
    expect(previousListenable.hasListeners, false);
    // ignore: invalid_use_of_protected_member
    expect(listenable.hasListeners, true);
    expect(element.dirty, false);
    listenable.value++;
    expect(element.dirty, true);
    await tester.pump();
    expect(result, 1);
    expect(element.dirty, false);

    await tester.pumpWidget(const SizedBox());

    // ignore: invalid_use_of_protected_member
    expect(listenable.hasListeners, false);

    listenable.dispose();
    previousListenable.dispose();
  });
}
