import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import 'mock.dart';

void main() {
  final effect = MockEffect();
  final unrelated = MockWidgetBuild();
  List<Object>? parameters;

  Widget builder() {
    return HookBuilder(builder: (context) {
      useEffect(effect, parameters);
      unrelated();
      return Container();
    });
  }

  tearDown(() {
    parameters = null;
    reset(unrelated);
    reset(effect);
  });

  testWidgets('debugFillProperties', (tester) async {
    await tester.pumpWidget(
      HookBuilder(builder: (context) {
        useEffect(() {
          return null;
        }, []);
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
        ' │ useEffect\n'
        ' └SizedBox(renderObject: RenderConstrainedBox#00000)\n',
      ),
    );
  });

  testWidgets('useEffect calls callback on every build', (tester) async {
    final effect = MockEffect();
    final dispose = MockDispose();

    when(effect()).thenReturn(dispose);

    Widget builder() {
      return HookBuilder(builder: (context) {
        useEffect(effect);
        unrelated();
        return Container();
      });
    }

    await tester.pumpWidget(builder());

    verifyInOrder([
      effect(),
      unrelated(),
    ]);
    verifyNoMoreInteractions(dispose);
    verifyNoMoreInteractions(effect);

    await tester.pumpWidget(builder());

    verifyInOrder([
      dispose(),
      effect(),
      unrelated(),
    ]);
    verifyNoMoreInteractions(dispose);
    verifyNoMoreInteractions(effect);
  });

  testWidgets(
      'useEffect with parameters calls callback when changing from null to something',
      (tester) async {
    await tester.pumpWidget(builder());

    verifyInOrder([
      effect(),
      unrelated(),
    ]);
    verifyNoMoreInteractions(effect);

    parameters = ['foo'];
    await tester.pumpWidget(builder());

    verifyInOrder([
      effect(),
      unrelated(),
    ]);
    verifyNoMoreInteractions(effect);
  });

  testWidgets('useEffect adding parameters call callback', (tester) async {
    parameters = ['foo'];
    await tester.pumpWidget(builder());

    verifyInOrder([
      effect(),
      unrelated(),
    ]);
    verifyNoMoreInteractions(effect);

    parameters = ['foo', 42];
    await tester.pumpWidget(builder());

    verifyInOrder([
      effect(),
      unrelated(),
    ]);
    verifyNoMoreInteractions(effect);
  });

  testWidgets('useEffect removing parameters call callback', (tester) async {
    parameters = ['foo'];
    await tester.pumpWidget(builder());

    verifyInOrder([
      effect(),
      unrelated(),
    ]);
    verifyNoMoreInteractions(effect);

    parameters = [];
    await tester.pumpWidget(builder());

    verifyInOrder([
      effect(),
      unrelated(),
    ]);
    verifyNoMoreInteractions(effect);
  });
  testWidgets('useEffect changing parameters call callback', (tester) async {
    parameters = ['foo'];
    await tester.pumpWidget(builder());

    verifyInOrder([
      effect(),
      unrelated(),
    ]);
    verifyNoMoreInteractions(effect);

    parameters = ['bar'];
    await tester.pumpWidget(builder());

    verifyInOrder([
      effect(),
      unrelated(),
    ]);
    verifyNoMoreInteractions(effect);
  });
  testWidgets(
      'useEffect with same parameters but different arrays don t call callback',
      (tester) async {
    parameters = ['foo'];
    await tester.pumpWidget(builder());

    verifyInOrder([
      effect(),
      unrelated(),
    ]);
    verifyNoMoreInteractions(effect);

    parameters = ['foo'];
    await tester.pumpWidget(builder());

    verifyNoMoreInteractions(effect);
  });
  testWidgets(
      'useEffect with same array but different parameters don t call callback',
      (tester) async {
    parameters = ['foo'];
    await tester.pumpWidget(builder());

    verifyInOrder([
      effect(),
      unrelated(),
    ]);
    verifyNoMoreInteractions(effect);

    parameters!.add('bar');
    await tester.pumpWidget(builder());

    verifyNoMoreInteractions(effect);
  });

  testWidgets('useEffect disposer called whenever callback called',
      (tester) async {
    final effect = MockEffect();
    List<Object>? parameters;

    Widget builder() {
      return HookBuilder(builder: (context) {
        useEffect(effect, parameters);
        return Container();
      });
    }

    parameters = ['foo'];
    final disposerA = MockDispose();
    when(effect()).thenReturn(disposerA);

    await tester.pumpWidget(builder());

    verify(effect()).called(1);
    verifyNoMoreInteractions(effect);
    verifyZeroInteractions(disposerA);

    await tester.pumpWidget(builder());

    verifyNoMoreInteractions(effect);
    verifyZeroInteractions(disposerA);

    parameters = ['bar'];
    final disposerB = MockDispose();
    when(effect()).thenReturn(disposerB);

    await tester.pumpWidget(builder());

    verifyInOrder([
      effect(),
      disposerA(),
    ]);
    verifyNoMoreInteractions(disposerA);
    verifyNoMoreInteractions(effect);
    verifyZeroInteractions(disposerB);

    await tester.pumpWidget(builder());

    verifyNoMoreInteractions(disposerA);
    verifyNoMoreInteractions(effect);
    verifyZeroInteractions(disposerB);

    await tester.pumpWidget(Container());

    verify(disposerB()).called(1);
    verifyNoMoreInteractions(disposerB);
    verifyNoMoreInteractions(disposerA);
    verifyNoMoreInteractions(effect);
  });
}

class MockEffect extends Mock {
  VoidCallback? call();
}

class MockWidgetBuild extends Mock {
  void call();
}
