import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import 'mock.dart';

void main() {
  testWidgets('diagnostics', (tester) async {
    await tester.pumpWidget(
      HookBuilder(builder: (context) {
        useValueChanged<int, int>(0, (_, __) => 21);
        return const SizedBox();
      }),
    );

    await tester.pumpWidget(
      HookBuilder(builder: (context) {
        useValueChanged<int, int>(42, (_, __) => 21);
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
        ' │ useValueChanged: _ValueChangedHookState<int, int>#00000(21,\n'
        ' │   value: 42, result: 21)\n'
        ' └SizedBox(renderObject: RenderConstrainedBox#00000)\n',
      ),
    );
  });

  testWidgets('useValueChanged basic', (tester) async {
    var value = 42;
    final _useValueChanged = MockValueChanged();
    late String? result;

    Future<void> pump() {
      return tester.pumpWidget(
        HookBuilder(builder: (context) {
          result = useValueChanged(value, _useValueChanged);
          return Container();
        }),
      );
    }

    await pump();

    final context = find.byType(HookBuilder).evaluate().first;

    expect(result, null);
    verifyNoMoreInteractions(_useValueChanged);
    expect(context.dirty, false);

    await pump();

    expect(result, null);
    verifyNoMoreInteractions(_useValueChanged);
    expect(context.dirty, false);

    value++;
    when(_useValueChanged(any, any)).thenReturn('Hello');
    await pump();

    verify(_useValueChanged(42, null));
    expect(result, 'Hello');
    verifyNoMoreInteractions(_useValueChanged);
    expect(context.dirty, false);

    await pump();

    expect(result, 'Hello');
    verifyNoMoreInteractions(_useValueChanged);
    expect(context.dirty, false);

    value++;
    when(_useValueChanged(any, any)).thenReturn('Foo');
    await pump();

    expect(result, 'Foo');
    verify(_useValueChanged(43, 'Hello'));
    verifyNoMoreInteractions(_useValueChanged);
    expect(context.dirty, false);

    await pump();

    expect(result, 'Foo');
    verifyNoMoreInteractions(_useValueChanged);
    expect(context.dirty, false);

    // dispose
    await tester.pumpWidget(const SizedBox());
  });
}

class MockValueChanged extends Mock {
  String? call(int? value, String? previous);
}
