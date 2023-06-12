import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import 'mock.dart';

void main() {
  testWidgets('debugFillProperties', (tester) async {
    await tester.pumpWidget(
      HookBuilder(builder: (context) {
        useAnimation(const AlwaysStoppedAnimation(42));
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
        ' │ useAnimation: 42\n'
        ' └SizedBox(renderObject: RenderConstrainedBox#00000)\n',
      ),
    );
  });

  testWidgets('useAnimation', (tester) async {
    var listenable = AnimationController(vsync: tester);
    late double result;

    Future<void> pump() {
      return tester.pumpWidget(HookBuilder(
        builder: (context) {
          result = useAnimation(listenable);
          return Container();
        },
      ));
    }

    await pump();

    final element = tester.firstElement(find.byType(HookBuilder));

    expect(result, 0);
    expect(element.dirty, false);
    listenable.value++;
    expect(element.dirty, true);
    await tester.pump();
    expect(result, 1);
    expect(element.dirty, false);

    final previousListenable = listenable;
    listenable = AnimationController(vsync: tester);

    await pump();

    expect(result, 0);
    expect(element.dirty, false);
    previousListenable.value++;
    expect(element.dirty, false);
    listenable.value++;
    expect(element.dirty, true);
    await tester.pump();
    expect(result, 1);
    expect(element.dirty, false);

    await tester.pumpWidget(const SizedBox());

    listenable.dispose();
    previousListenable.dispose();
  });
}
