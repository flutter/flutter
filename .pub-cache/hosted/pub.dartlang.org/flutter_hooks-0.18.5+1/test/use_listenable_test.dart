import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import 'mock.dart';

void main() {
  testWidgets('debugFillProperties', (tester) async {
    await tester.pumpWidget(
      HookBuilder(builder: (context) {
        useListenable(const AlwaysStoppedAnimation(42));
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
        ' │ useListenable: AlwaysStoppedAnimation<int>#00000(▶ 42; paused)\n'
        ' └SizedBox(renderObject: RenderConstrainedBox#00000)\n',
      ),
    );
  });

  testWidgets('useListenable', (tester) async {
    var listenable = ValueNotifier(0);

    Future<void> pump() {
      return tester.pumpWidget(HookBuilder(
        builder: (context) {
          useListenable(listenable);
          return Container();
        },
      ));
    }

    await pump();

    final element = tester.firstElement(find.byType(HookBuilder));

    // ignore: invalid_use_of_protected_member
    expect(listenable.hasListeners, true);
    expect(element.dirty, false);
    listenable.value++;
    expect(element.dirty, true);
    await tester.pump();
    expect(element.dirty, false);

    final previousListenable = listenable;
    listenable = ValueNotifier(0);

    await pump();

    // ignore: invalid_use_of_protected_member
    expect(previousListenable.hasListeners, false);
    // ignore: invalid_use_of_protected_member
    expect(listenable.hasListeners, true);
    expect(element.dirty, false);
    listenable.value++;
    expect(element.dirty, true);
    await tester.pump();
    expect(element.dirty, false);

    await tester.pumpWidget(const SizedBox());

    // ignore: invalid_use_of_protected_member
    expect(listenable.hasListeners, false);

    listenable.dispose();
    previousListenable.dispose();
  });

  testWidgets('useListenable should handle null', (tester) async {
    ValueNotifier<int>? listenable;

    Future<void> pump() {
      return tester.pumpWidget(HookBuilder(
        builder: (context) {
          useListenable(listenable);
          return Container();
        },
      ));
    }

    await pump();

    final element = tester.firstElement(find.byType(HookBuilder));
    expect(element.dirty, false);

    final notifier = ValueNotifier(0);
    listenable = notifier;
    await pump();

    // ignore: invalid_use_of_protected_member
    expect(listenable.hasListeners, true);

    listenable = null;
    await pump();

    // ignore: invalid_use_of_protected_member
    expect(notifier.hasListeners, false);

    await tester.pumpWidget(const SizedBox());

    notifier.dispose();
  });
}
