import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart' as mockito show when;
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

void mockImplementation<T extends Function>(dynamic Function() when, T mock) {
  mockito.when<dynamic>(when()).thenAnswer((invo) {
    return Function.apply(mock, invo.positionalArguments, invo.namedArguments);
  });
}

void main() {
  final selector = MockSelector<int>(-1);
  final builder = MockBuilder<int>();

  tearDown(() {
    clearInteractions(builder);
    clearInteractions(selector);
  });

  void mockBuilder(ValueWidgetBuilder<int> implementation) {
    mockImplementation(() => builder(any, any, any), implementation);
  }

  testWidgets('Deep compare maps by default', (tester) async {
    var value = <int, int>{};
    final builder = MockBuilder<Map<int, int>>();
    when(builder(any, any, any)).thenReturn(Container());

    final selector = Selector0<Map<int, int>>(
      selector: (_) => value,
      builder: builder,
    );
    await tester.pumpWidget(selector);

    verify(builder(argThat(isNotNull), value, null)).called(1);
    verifyNoMoreInteractions(builder);

    final element = tester.element(find.byWidget(selector));

    value = {0: 0, 1: 1};
    element.markNeedsBuild();
    await tester.pump();

    verify(builder(argThat(isNotNull), value, null)).called(1);
    verifyNoMoreInteractions(builder);

    value = {0: 0, 1: 1};
    element.markNeedsBuild();
    await tester.pump();

    verifyNoMoreInteractions(builder);
  });

  testWidgets('Deep compare iterables by default', (tester) async {
    var value = <int>[].whereType<int>();
    final builder = MockBuilder<Iterable<int>>();
    when(builder(any, any, any)).thenReturn(Container());

    final selector = Selector0<Iterable<int>>(
      selector: (_) => value,
      builder: builder,
    );
    await tester.pumpWidget(selector);

    verify(builder(argThat(isNotNull), value, null)).called(1);
    verifyNoMoreInteractions(builder);

    final element = tester.element(find.byWidget(selector));

    value = [1, 2].whereType<int>();
    element.markNeedsBuild();
    await tester.pump();

    verify(builder(argThat(isNotNull), value, null)).called(1);
    verifyNoMoreInteractions(builder);

    value = [1, 2].whereType<int>();
    element.markNeedsBuild();
    await tester.pump();

    verifyNoMoreInteractions(builder);
  });

  testWidgets('Deep compare sets by default', (tester) async {
    var value = <int>{};
    final builder = MockBuilder<Set<int>>();
    when(builder(any, any, any)).thenReturn(Container());

    final selector = Selector0<Set<int>>(
      selector: (_) => value,
      builder: builder,
    );
    await tester.pumpWidget(selector);

    verify(builder(argThat(isNotNull), value, null)).called(1);
    verifyNoMoreInteractions(builder);

    final element = tester.element(find.byWidget(selector));

    value = {1, 2};
    element.markNeedsBuild();
    await tester.pump();

    verify(builder(argThat(isNotNull), value, null)).called(1);
    verifyNoMoreInteractions(builder);

    value = {1, 2};
    element.markNeedsBuild();
    await tester.pump();

    verifyNoMoreInteractions(builder);
  });

  testWidgets('Deep compare lists by default', (tester) async {
    var value = <int>[];
    final builder = MockBuilder<List<int>>();
    when(builder(any, any, any)).thenReturn(Container());

    final selector = Selector0<List<int>>(
      selector: (_) => value,
      builder: builder,
    );
    await tester.pumpWidget(selector);

    verify(builder(argThat(isNotNull), value, null)).called(1);
    verifyNoMoreInteractions(builder);

    final element = tester.element(find.byWidget(selector));

    value = [1, 2];
    element.markNeedsBuild();
    await tester.pump();

    verify(builder(argThat(isNotNull), value, null)).called(1);
    verifyNoMoreInteractions(builder);

    value = [1, 2];
    element.markNeedsBuild();
    await tester.pump();

    verifyNoMoreInteractions(builder);
  });

  testWidgets('custom shouldRebuid', (tester) async {
    var value = 0;
    var shouldRebuild = true;
    final mockShouldRebuild = MockShouldRebuild<int>();
    when(mockShouldRebuild(any, any)).thenAnswer((_) => shouldRebuild);

    final builder = MockBuilder<int>();
    when(builder(any, any, any)).thenReturn(Container());

    final selector = Selector0<int>(
      selector: (_) => value,
      shouldRebuild: mockShouldRebuild,
      builder: builder,
    );
    await tester.pumpWidget(selector);

    verifyZeroInteractions(mockShouldRebuild);
    verify(builder(argThat(isNotNull), 0, null)).called(1);
    verifyNoMoreInteractions(builder);

    final element = tester.element(find.byWidget(selector));

    value = 1;
    element.markNeedsBuild();
    await tester.pump();

    verify(mockShouldRebuild(0, 1)).called(1);
    verifyNoMoreInteractions(mockShouldRebuild);
    verify(builder(argThat(isNotNull), 1, null)).called(1);
    verifyNoMoreInteractions(builder);

    shouldRebuild = false;
    value = 2;
    element.markNeedsBuild();
    await tester.pump();

    verify(mockShouldRebuild(1, 2)).called(1);
    verifyNoMoreInteractions(mockShouldRebuild);
    verifyNoMoreInteractions(builder);
  });

  testWidgets('passes `child` and `key`', (tester) async {
    final key = GlobalKey();
    await tester.pumpWidget(
      Selector0<void>(
        key: key,
        selector: (_) {},
        builder: (_, __, child) => child!,
        child: const Text('42', textDirection: TextDirection.ltr),
      ),
    );

    expect(key.currentContext, isNotNull);

    expect(find.text('42'), findsOneWidget);
  });

  testWidgets('calls builder if the callback changes', (tester) async {
    await tester.pumpWidget(
      Selector0<int>(
        selector: (_) => 42,
        builder: (_, __, ___) =>
            const Text('foo', textDirection: TextDirection.ltr),
      ),
    );

    expect(find.text('foo'), findsOneWidget);

    await tester.pumpWidget(
      Selector0<int>(
        selector: (_) => 42,
        builder: (_, __, ___) =>
            const Text('bar', textDirection: TextDirection.ltr),
      ),
    );

    expect(find.text('bar'), findsOneWidget);
  });

  testWidgets('works with MultiProvider', (tester) async {
    final key = GlobalKey();
    int selector(BuildContext _) => 42;
    Widget builder(BuildContext _, int __, Widget? child) => child!;
    const child = Text('foo', textDirection: TextDirection.ltr);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Selector0<int>(
            key: key,
            selector: selector,
            builder: builder,
          ),
        ],
        child: child,
      ),
    );

    final widget = tester.widget(
      find.byWidgetPredicate((w) => w is Selector0<int>),
    ) as Selector0<int>;

    expect(find.text('foo'), findsOneWidget);
    expect(widget.key, key);
    expect(
      widget.selector,
      equals(selector),
    );
    expect(
      widget.builder,
      equals(builder),
    );
  });

  testWidgets(
      "don't call builder again if it rebuilds "
      'but selector returns the same thing', (tester) async {
    when(selector(any)).thenReturn(42);

    mockBuilder((_, value, ___) {
      return Text(value.toString(), textDirection: TextDirection.ltr);
    });

    await tester.pumpWidget(
      Selector0<int>(
        selector: selector,
        builder: builder,
      ),
    );

    verify(selector(argThat(isNotNull))).called(1);
    verifyNoMoreInteractions(selector);

    verify(builder(argThat(isNotNull), 42, null)).called(1);
    verifyNoMoreInteractions(selector);

    expect(find.text('42'), findsOneWidget);

    tester
        .element(find.byWidgetPredicate((w) => w is Selector0))
        .markNeedsBuild();

    await tester.pump();

    verify(selector(argThat(isNotNull))).called(1);
    verifyNoMoreInteractions(builder);
    verifyNoMoreInteractions(selector);
    expect(find.text('42'), findsOneWidget);
  });

  testWidgets(
      'call builder again if it rebuilds '
      'abd selector returns the a different variable', (tester) async {
    when(selector(any)).thenReturn(42);

    mockBuilder((_, value, ___) {
      return Text(value.toString(), textDirection: TextDirection.ltr);
    });

    await tester.pumpWidget(
      Selector0<int>(
        selector: selector,
        builder: builder,
      ),
    );

    verify(selector(argThat(isNotNull))).called(1);
    verifyNoMoreInteractions(selector);

    verify(builder(argThat(isNotNull), 42, null)).called(1);
    verifyNoMoreInteractions(selector);

    expect(find.text('42'), findsOneWidget);

    tester
        .element(find.byWidgetPredicate((w) => w is Selector0))
        .markNeedsBuild();

    when(selector(any)).thenReturn(24);

    await tester.pump();

    verify(selector(argThat(isNotNull))).called(1);
    verify(builder(argThat(isNotNull), 24, null)).called(1);
    verifyNoMoreInteractions(selector);
    verifyNoMoreInteractions(builder);
    expect(find.text('24'), findsOneWidget);
  });

  testWidgets('debugFillProperties', (tester) async {
    final builder = DiagnosticPropertiesBuilder();
    final key = UniqueKey();
    final selector = Selector0<int>(
      key: key,
      selector: (_) => 0,
      builder: (_, __, ___) => const SizedBox(),
    );

    await tester.pumpWidget(selector);

    final element = tester.element(find.byKey(key)) as StatefulElement;
    final selectorState = element.state as SingleChildState<Selector0<int>>;
    selectorState.debugFillProperties(builder);
    final description = builder.properties
        .where(
          (DiagnosticsNode node) => !node.isFiltered(DiagnosticLevel.info),
        )
        .map((DiagnosticsNode node) => node.toString())
        .toList();
    expect(description, <String>['value: 0']);
  });

  testWidgets('Selector', (tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider.value(value: A()),
        ],
        child: Selector<A, String>(
          selector: (_, a) => '$a',
          builder: (_, value, __) =>
              Text(value, textDirection: TextDirection.ltr),
        ),
      ),
    );

    expect(find.text('A'), findsOneWidget);
  });

  testWidgets('Selector2', (tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider.value(value: A()),
          Provider.value(value: B()),
        ],
        child: Selector2<A, B, String>(
          selector: (_, a, b) => '$a $b',
          builder: (_, value, __) =>
              Text(value, textDirection: TextDirection.ltr),
        ),
      ),
    );

    expect(find.text('A B'), findsOneWidget);
  });

  testWidgets('Selector3', (tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider.value(value: A()),
          Provider.value(value: B()),
          Provider.value(value: C()),
        ],
        child: Selector3<A, B, C, String>(
          selector: (_, a, b, c) => '$a $b $c',
          builder: (_, value, __) =>
              Text(value, textDirection: TextDirection.ltr),
        ),
      ),
    );

    expect(find.text('A B C'), findsOneWidget);
  });

  testWidgets('Selector4', (tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider.value(value: A()),
          Provider.value(value: B()),
          Provider.value(value: C()),
          Provider.value(value: D()),
        ],
        child: Selector4<A, B, C, D, String>(
          selector: (_, a, b, c, d) => '$a $b $c $d',
          builder: (_, value, __) =>
              Text(value, textDirection: TextDirection.ltr),
        ),
      ),
    );

    expect(find.text('A B C D'), findsOneWidget);
  });

  testWidgets('Selector5', (tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider.value(value: A()),
          Provider.value(value: B()),
          Provider.value(value: C()),
          Provider.value(value: D()),
          Provider.value(value: E()),
        ],
        child: Selector5<A, B, C, D, E, String>(
          selector: (_, a, b, c, d, e) => '$a $b $c $d $e',
          builder: (_, value, __) =>
              Text(value, textDirection: TextDirection.ltr),
        ),
      ),
    );

    expect(find.text('A B C D E'), findsOneWidget);
  });

  testWidgets('Selector6', (tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider.value(value: A()),
          Provider.value(value: B()),
          Provider.value(value: C()),
          Provider.value(value: D()),
          Provider.value(value: E()),
          Provider.value(value: F()),
        ],
        child: Selector6<A, B, C, D, E, F, String>(
          selector: (_, a, b, c, d, e, f) => '$a $b $c $d $e $f',
          builder: (_, value, __) =>
              Text(value, textDirection: TextDirection.ltr),
        ),
      ),
    );

    expect(find.text('A B C D E F'), findsOneWidget);
  });
}

mixin _ToString {
  @override
  String toString() {
    return runtimeType.toString();
  }
}

class A with _ToString {}

class B with _ToString {}

class C with _ToString {}

class D with _ToString {}

class E with _ToString {}

class F with _ToString {}

class MockSelector<T> extends Mock {
  MockSelector(this._fallback);

  final T _fallback;

  T call(BuildContext? context) {
    return super.noSuchMethod(
      Invocation.method(#call, [context]),
      returnValue: _fallback,
    ) as T;
  }
}

class MockShouldRebuild<T> extends Mock {
  bool call(T? prev, T? next) {
    return super.noSuchMethod(
      Invocation.method(#call, [prev, next]),
      returnValue: false,
    ) as bool;
  }
}

class MockBuilder<T> extends Mock {
  Widget call(BuildContext? context, T? value, Widget? child) {
    return super.noSuchMethod(
      Invocation.method(#call, [context, value, child]),
      returnValue: Container(),
    ) as Widget;
  }
}
