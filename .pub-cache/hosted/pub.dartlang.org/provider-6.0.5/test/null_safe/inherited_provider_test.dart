import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:provider/src/provider.dart';

import 'common.dart';

class Context extends StatelessWidget {
  const Context({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}

BuildContext get context => find.byType(Context).evaluate().single;

T of<T>([BuildContext? c]) => Provider.of<T>(c ?? context, listen: false);

void main() {
  // TODO DeferredInheritedProvider accepts non-nullable values

  testWidgets('regression test #377', (tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          StateNotifierProvider<_Controller1, Counter1>(
            create: (context) => _Controller1(),
          ),
          StateNotifierProvider<_Controller2, Counter2>(
            create: (context) => _Controller2(),
          ),
        ],
        child: Consumer<Counter2>(
          builder: (c, value, _) {
            return Text('${value.count}', textDirection: TextDirection.ltr);
          },
        ),
      ),
    );
  });

  testWidgets('rebuild on dependency flags update', (tester) async {
    await tester.pumpWidget(
      InheritedProvider<int>(
        lazy: false,
        update: (context, value) {
          assert(!debugIsInInheritedProviderCreate);
          assert(debugIsInInheritedProviderUpdate);
          return 0;
        },
        child: Container(),
      ),
    );

    await tester.pumpWidget(
      InheritedProvider<int>(
        lazy: false,
        update: (context, value) {
          assert(!debugIsInInheritedProviderCreate);
          assert(debugIsInInheritedProviderUpdate);
          return 0;
        },
        child: Container(),
      ),
    );
  });

  testWidgets(
      'properly update debug flags if a create triggers another deferred create',
      (tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          DeferredInheritedProvider<double, double>(
            create: (context) {
              assert(debugIsInInheritedProviderCreate);
              assert(!debugIsInInheritedProviderUpdate);
              return 42.0;
            },
            startListening: (_, setState, c, __) {
              setState(c);
              return () {};
            },
          ),
          DeferredInheritedProvider<int, int>(
            create: (context) {
              assert(debugIsInInheritedProviderCreate);
              assert(!debugIsInInheritedProviderUpdate);
              return context.read<double>().round();
            },
            startListening: (_, setState, c, __) {
              setState(c);
              return () {};
            },
          ),
          InheritedProvider<String>(
            lazy: false,
            update: (context, value) {
              assert(!debugIsInInheritedProviderCreate);
              assert(debugIsInInheritedProviderUpdate);
              context.watch<double>();

              assert(!debugIsInInheritedProviderCreate);
              assert(debugIsInInheritedProviderUpdate);
              return context.watch<int>().toString();
            },
          ),
        ],
        child: Container(),
      ),
    );
  });

  testWidgets(
      'properly update debug flags if a create triggers another deferred create',
      (tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          DeferredInheritedProvider<double, double>(
            create: (context) {
              assert(debugIsInInheritedProviderCreate);
              assert(!debugIsInInheritedProviderUpdate);
              return 42.0;
            },
            startListening: (_, setState, c, __) {
              setState(c);
              return () {};
            },
          ),
          DeferredInheritedProvider<int, int>(
            create: (context) {
              assert(debugIsInInheritedProviderCreate);
              assert(!debugIsInInheritedProviderUpdate);
              return context.read<double>().round();
            },
            startListening: (_, setState, c, __) {
              setState(c);
              return () {};
            },
          ),
          InheritedProvider<String>(
            lazy: false,
            create: (context) {
              assert(debugIsInInheritedProviderCreate);
              assert(!debugIsInInheritedProviderUpdate);
              context.read<double>();
              assert(debugIsInInheritedProviderCreate);
              assert(!debugIsInInheritedProviderUpdate);

              return context.read<int>().toString();
            },
          ),
        ],
        child: Container(),
      ),
    );
  });

  testWidgets(
      'properly update debug flags if an update triggers another create/update',
      (tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          InheritedProvider<double>(
            create: (context) {
              assert(debugIsInInheritedProviderCreate);
              assert(!debugIsInInheritedProviderUpdate);
              return 42.0;
            },
            update: (context, _) {
              assert(!debugIsInInheritedProviderCreate);
              assert(debugIsInInheritedProviderUpdate);
              return 42.0;
            },
          ),
          InheritedProvider<int>(
            create: (context) {
              assert(debugIsInInheritedProviderCreate);
              assert(!debugIsInInheritedProviderUpdate);
              return context.read<double>().round();
            },
            update: (context, _) {
              assert(!debugIsInInheritedProviderCreate);
              assert(debugIsInInheritedProviderUpdate);
              return context.watch<double>().round();
            },
          ),
          InheritedProvider<String>(
            lazy: false,
            update: (context, value) {
              assert(!debugIsInInheritedProviderCreate);
              assert(debugIsInInheritedProviderUpdate);
              context.watch<double>();

              assert(!debugIsInInheritedProviderCreate);
              assert(debugIsInInheritedProviderUpdate);
              return context.watch<int>().toString();
            },
          ),
        ],
        child: Container(),
      ),
    );
  });

  testWidgets(
      'properly update debug flags if a create triggers another create/update',
      (tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          InheritedProvider<double>(
            create: (context) {
              assert(debugIsInInheritedProviderCreate);
              assert(!debugIsInInheritedProviderUpdate);
              return 42.0;
            },
            update: (context, _) {
              assert(!debugIsInInheritedProviderCreate);
              assert(debugIsInInheritedProviderUpdate);
              return 42.0;
            },
          ),
          InheritedProvider<int>(
            create: (context) {
              assert(debugIsInInheritedProviderCreate);
              assert(!debugIsInInheritedProviderUpdate);
              return context.read<double>().round();
            },
            update: (context, _) {
              assert(!debugIsInInheritedProviderCreate);
              assert(debugIsInInheritedProviderUpdate);
              return context.watch<double>().round();
            },
          ),
          InheritedProvider<String>(
            lazy: false,
            create: (context) {
              assert(debugIsInInheritedProviderCreate);
              assert(!debugIsInInheritedProviderUpdate);
              context.read<double>();
              assert(debugIsInInheritedProviderCreate);
              assert(!debugIsInInheritedProviderUpdate);

              return context.read<int>().toString();
            },
            update: (context, value) {
              assert(!debugIsInInheritedProviderCreate);
              assert(debugIsInInheritedProviderUpdate);
              context.watch<double>();

              assert(!debugIsInInheritedProviderCreate);
              assert(debugIsInInheritedProviderUpdate);
              return context.watch<int>().toString();
            },
          ),
        ],
        child: Container(),
      ),
    );
  });

  testWidgets(
      'Provider.of(listen: false) outside of build works when it loads a provider',
      (tester) async {
    final notifier = ValueNotifier(42);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: notifier),
          ProxyProvider<ValueNotifier<int>, String>(update: (a, b, c) {
            return '${b.value}';
          }),
        ],
        child: const Context(),
      ),
    );

    expect(Provider.of<String>(context, listen: false), '42');

    notifier.value = 21;
    await tester.pump();

    expect(Provider.of<String>(context, listen: false), '21');
  });

  testWidgets('new value is available in didChangeDependencies',
      (tester) async {
    final didChangeDependencies = ValueBuilderMock<int>(-1);
    final build = ValueBuilderMock<int>(-1);

    await tester.pumpWidget(
      InheritedProvider.value(
        value: 0,
        child: Test<int>(
          didChangeDependencies: didChangeDependencies,
          build: build,
        ),
      ),
    );
    verify(didChangeDependencies(argThat(isNotNull), 0)).called(1);
    verify(build(argThat(isNotNull), 0)).called(1);

    verifyNoMoreInteractions(didChangeDependencies);
    verifyNoMoreInteractions(build);

    await tester.pumpWidget(
      InheritedProvider.value(
        value: 1,
        child: Test<int>(
          didChangeDependencies: didChangeDependencies,
          build: build,
        ),
      ),
    );
    verify(didChangeDependencies(argThat(isNotNull), 1)).called(1);
    verify(build(argThat(isNotNull), 1)).called(1);
    verifyNoMoreInteractions(didChangeDependencies);
    verifyNoMoreInteractions(build);
  });

  testWidgets(
      'builder receives the current value and updates independently from `update`',
      (tester) async {
    final child = Container();

    final notifier = ValueNotifier(0);
    final builder = TransitionBuilderMock((c, child) {
      final notifier = Provider.of<ValueNotifier<int>>(c);
      return Text(
        '${notifier.value}',
        textDirection: TextDirection.ltr,
      );
    });

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: notifier,
        builder: builder,
        child: child,
      ),
    );

    verify(builder(argThat(isNotNull), child)).called(1);
    verifyNoMoreInteractions(builder);
    expect(find.text('0'), findsOneWidget);

    notifier.value++;
    await tester.pump();

    verify(builder(argThat(isNotNull), child)).called(1);
    verifyNoMoreInteractions(builder);
    expect(find.text('1'), findsOneWidget);
  });

  testWidgets('builder can _not_ rebuild when provider updates',
      (tester) async {
    final child = Container();

    final notifier = ValueNotifier(0);
    final builder = TransitionBuilderMock((c, child) {
      return const Text('foo', textDirection: TextDirection.ltr);
    });

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: notifier,
        builder: builder,
        child: child,
      ),
    );

    verify(builder(argThat(isNotNull), child)).called(1);
    verifyNoMoreInteractions(builder);
    expect(find.text('foo'), findsOneWidget);

    notifier.value++;
    await tester.pump();

    verifyNoMoreInteractions(builder);
    expect(find.text('foo'), findsOneWidget);
  });

  testWidgets('builder rebuilds if provider is recreated', (tester) async {
    final child = Container();

    final notifier = ValueNotifier(0);
    final builder = TransitionBuilderMock((c, child) {
      return const Text('foo', textDirection: TextDirection.ltr);
    });

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: notifier,
        builder: builder,
        child: child,
      ),
    );

    verify(builder(argThat(isNotNull), child)).called(1);
    verifyNoMoreInteractions(builder);
    expect(find.text('foo'), findsOneWidget);

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: notifier,
        builder: builder,
        child: child,
      ),
    );

    verify(builder(argThat(isNotNull), child)).called(1);
    verifyNoMoreInteractions(builder);
    expect(find.text('foo'), findsOneWidget);
  });

  testWidgets('provider.of throws if listen:true outside of the widget tree',
      (tester) async {
    await tester.pumpWidget(
      InheritedProvider<int>.value(
        value: 42,
        child: const Context(),
      ),
    );

    expect(
      () => Provider.of<int>(context),
      throwsA(
        isA<AssertionError>().having(
          (source) => source.toString(),
          'toString',
          endsWith('''
Tried to listen to a value exposed with provider, from outside of the widget tree.

This is likely caused by an event handler (like a button's onPressed) that called
Provider.of without passing `listen: false`.

To fix, write:
Provider.of<int>(context, listen: false);

It is unsupported because may pointlessly rebuild the widget associated to the
event handler, when the widget tree doesn't care about the value.

The context used was: Context
'''),
        ),
      ),
    );

    expect(Provider.of<int>(context, listen: false), equals(42));
  });

  testWidgets(
      'InheritedProvider throws if no child is provided with default constructor',
      (tester) async {
    await tester.pumpWidget(
      InheritedProvider<int>(
        create: (_) => 42,
      ),
    );

    expect(
      tester.takeException(),
      isA<AssertionError>().having(
        (source) => source.toString(),
        'toString',
        contains(
            'InheritedProvider<int> used outside of MultiProvider must specify a child'),
      ),
    );
  });

  testWidgets(
      'InheritedProvider throws if no child is provided with value constructor',
      (tester) async {
    await tester.pumpWidget(
      InheritedProvider<int>.value(
        value: 42,
      ),
    );

    expect(
      tester.takeException(),
      isA<AssertionError>().having(
        (source) => source.toString(),
        'toString',
        contains(
            'InheritedProvider<int> used outside of MultiProvider must specify a child'),
      ),
    );
  });

  testWidgets(
      'DeferredInheritedProvider throws if no child is provided with default constructor',
      (tester) async {
    await tester.pumpWidget(
      DeferredInheritedProvider<int, int>(
        create: (_) => 42,
        startListening: (_, __, ___, ____) {
          return () {};
        },
      ),
    );

    expect(
      tester.takeException(),
      isA<AssertionError>().having(
        (source) => source.toString(),
        'toString',
        contains(
            'DeferredInheritedProvider<int, int> used outside of MultiProvider must specify a child'),
      ),
    );
  });

  testWidgets(
      'DeferredInheritedProvider throws if no child is provided with value constructor',
      (tester) async {
    await tester.pumpWidget(
      DeferredInheritedProvider<int, int>.value(
        value: 42,
        startListening: (_, __, ___, ____) {
          return () {};
        },
      ),
    );

    expect(
      tester.takeException(),
      isA<AssertionError>().having(
        (source) => source.toString(),
        'toString',
        contains(
            'DeferredInheritedProvider<int, int> used outside of MultiProvider must specify a child'),
      ),
    );
  });

  group('diagnostics', () {
    testWidgets('InheritedProvider.value', (tester) async {
      await tester.pumpWidget(
        InheritedProvider<int>.value(
          value: 42,
          startListening: (_, __) => throw Error(),
          child: Container(),
        ),
      );

      final rootElement =
          tester.element(find.byWidgetPredicate((w) => w is InheritedProvider));

      expect(
        rootElement.toString(),
        contains('InheritedProvider<int>(value: 42)'),
      );

      await tester.pumpWidget(
        InheritedProvider<int>.value(
          value: 42,
          startListening: (_, __) => () {},
          child: TextOf<int>(),
        ),
      );

      expect(
        rootElement.toString(),
        contains('InheritedProvider<int>(value: 42, listening to value)'),
      );
    });

    testWidgets("InheritedProvider doesn't break lazy loading", (tester) async {
      await tester.pumpWidget(
        InheritedProvider<int>(
          create: (_) => 42,
          child: Container(),
        ),
      );

      final rootElement =
          tester.element(find.byWidgetPredicate((w) => w is InheritedProvider));

      expect(
        rootElement.toString(),
        contains('InheritedProvider<int>(value: <not yet loaded>)'),
      );

      Provider.of<int>(tester.element(find.byType(Container)), listen: false);

      expect(
        rootElement.toString(),
        contains('InheritedProvider<int>(value: 42)'),
      );
    });

    testWidgets('InheritedProvider show if listening', (tester) async {
      await tester.pumpWidget(
        InheritedProvider<int>(
          create: (_) => 24,
          startListening: (_, __) => () {},
          child: Container(),
        ),
      );

      final rootElement =
          tester.element(find.byWidgetPredicate((w) => w is InheritedProvider));

      expect(
        rootElement.toString(),
        contains('InheritedProvider<int>(value: <not yet loaded>)'),
      );

      Provider.of<int>(tester.element(find.byType(Container)), listen: false);

      expect(
        rootElement.toString(),
        contains('InheritedProvider<int>(value: 24, listening to value)'),
      );
    });

    testWidgets('DeferredInheritedProvider.value', (tester) async {
      await tester.pumpWidget(
        DeferredInheritedProvider<int, int>.value(
          value: 42,
          startListening: (_, setState, __, ___) {
            setState(24);
            return () {};
          },
          child: Container(),
        ),
      );

      final rootElement = tester.element(
          find.byWidgetPredicate((w) => w is DeferredInheritedProvider));

      expect(
        rootElement.toString(),
        contains(
          '''
DeferredInheritedProvider<int, int>(controller: 42, value: <not yet loaded>)''',
        ),
      );

      Provider.of<int>(tester.element(find.byType(Container)), listen: false);

      expect(
        rootElement.toString(),
        contains('''
DeferredInheritedProvider<int, int>(controller: 42, value: 24)'''),
      );
    });

    testWidgets('DeferredInheritedProvider', (tester) async {
      await tester.pumpWidget(
        DeferredInheritedProvider<int, int>(
          create: (_) => 42,
          startListening: (_, setState, __, ___) {
            setState(24);
            return () {};
          },
          child: Container(),
        ),
      );

      final rootElement =
          tester.element(find.byWidgetPredicate((w) => w is InheritedProvider));

      expect(
        rootElement.toString(),
        contains(
          '''
DeferredInheritedProvider<int, int>(controller: <not yet loaded>, value: <not yet loaded>)''',
        ),
      );

      Provider.of<int>(tester.element(find.byType(Container)), listen: false);

      expect(
        rootElement.toString(),
        contains('''
DeferredInheritedProvider<int, int>(controller: 42, value: 24)'''),
      );
    });
  });

  group('InheritedProvider.value()', () {
    testWidgets('markNeedsNotifyDependents during startListening is noop',
        (tester) async {
      await tester.pumpWidget(
        InheritedProvider<int>.value(
          value: 42,
          startListening: (e, value) {
            e.markNeedsNotifyDependents();
            return () {};
          },
          child: TextOf<int>(),
        ),
      );
    });

    testWidgets('startListening called again when create returns new value',
        (tester) async {
      final stopListening = StopListeningMock();
      final startListening = StartListeningMock<int>(stopListening);

      await tester.pumpWidget(
        InheritedProvider<int>.value(
          value: 42,
          startListening: startListening,
          child: TextOf<int>(),
        ),
      );

      final element = findInheritedContext<int>();

      verify(startListening(element, 42)).called(1);
      verifyNoMoreInteractions(startListening);
      verifyZeroInteractions(stopListening);

      final stopListening2 = StopListeningMock();
      final startListening2 = StartListeningMock<int>(stopListening2);

      await tester.pumpWidget(
        InheritedProvider<int>.value(
          value: 24,
          startListening: startListening2,
          child: TextOf<int>(),
        ),
      );

      verifyNoMoreInteractions(startListening);
      verifyInOrder([
        stopListening(),
        startListening2(element, 24),
      ]);
      verifyNoMoreInteractions(startListening2);
      verifyZeroInteractions(stopListening2);

      await tester.pumpWidget(Container());

      verifyNoMoreInteractions(startListening);
      verify(stopListening2()).called(1);
    });

    testWidgets('startListening', (tester) async {
      final stopListening = StopListeningMock();
      final startListening = StartListeningMock<int>(stopListening);

      await tester.pumpWidget(
        InheritedProvider<int>.value(
          value: 42,
          startListening: startListening,
          child: Container(),
        ),
      );

      verifyZeroInteractions(startListening);

      await tester.pumpWidget(
        InheritedProvider<int>.value(
          value: 42,
          startListening: startListening,
          child: TextOf<int>(),
        ),
      );

      final element = findInheritedContext<int>();

      verify(startListening(element, 42)).called(1);
      verifyNoMoreInteractions(startListening);
      verifyZeroInteractions(stopListening);

      await tester.pumpWidget(
        InheritedProvider<int>.value(
          value: 42,
          startListening: startListening,
          child: TextOf<int>(),
        ),
      );

      verifyNoMoreInteractions(startListening);
      verifyZeroInteractions(stopListening);

      await tester.pumpWidget(Container());

      verifyNoMoreInteractions(startListening);
      verify(stopListening()).called(1);
    });

    testWidgets(
      "stopListening not called twice if rebuild doesn't have listeners",
      (tester) async {
        final stopListening = StopListeningMock();
        final startListening = StartListeningMock<int>(stopListening);

        await tester.pumpWidget(
          InheritedProvider<int>.value(
            value: 42,
            startListening: startListening,
            child: TextOf<int>(),
          ),
        );
        verify(startListening(argThat(isNotNull), 42)).called(1);
        verifyZeroInteractions(stopListening);

        final stopListening2 = StopListeningMock();
        final startListening2 = StartListeningMock<int>(stopListening2);
        await tester.pumpWidget(
          InheritedProvider<int>.value(
            value: 24,
            startListening: startListening2,
            child: Container(),
          ),
        );

        verifyNoMoreInteractions(startListening);
        verify(stopListening()).called(1);
        verifyZeroInteractions(startListening2);
        verifyZeroInteractions(stopListening2);

        await tester.pumpWidget(Container());

        verifyNoMoreInteractions(startListening);
        verifyNoMoreInteractions(stopListening);
        verifyZeroInteractions(startListening2);
        verifyZeroInteractions(stopListening2);
      },
    );

    testWidgets('pass down current value', (tester) async {
      int? value;
      final child = Consumer<int>(
        builder: (_, v, __) {
          value = v;
          return Container();
        },
      );

      await tester.pumpWidget(
        InheritedProvider<int>.value(value: 42, child: child),
      );

      expect(value, equals(42));

      await tester.pumpWidget(
        InheritedProvider<int>.value(value: 43, child: child),
      );

      expect(value, equals(43));
    });

    testWidgets('default updateShouldNotify', (tester) async {
      var buildCount = 0;

      final child = Consumer<int>(builder: (_, __, ___) {
        buildCount++;
        return Container();
      });

      await tester.pumpWidget(
        InheritedProvider<int>.value(value: 42, child: child),
      );
      expect(buildCount, equals(1));

      await tester.pumpWidget(
        InheritedProvider<int>.value(value: 42, child: child),
      );
      expect(buildCount, equals(1));

      await tester.pumpWidget(
        InheritedProvider<int>.value(value: 43, child: child),
      );
      expect(buildCount, equals(2));
    });

    testWidgets('custom updateShouldNotify', (tester) async {
      var buildCount = 0;
      final updateShouldNotify = UpdateShouldNotifyMock<int>();

      final child = Consumer<int>(builder: (_, __, ___) {
        buildCount++;
        return Container();
      });

      await tester.pumpWidget(
        InheritedProvider<int>.value(
          value: 42,
          updateShouldNotify: updateShouldNotify,
          child: child,
        ),
      );
      expect(buildCount, equals(1));
      verifyZeroInteractions(updateShouldNotify);

      when(updateShouldNotify(any, any)).thenReturn(false);
      await tester.pumpWidget(
        InheritedProvider<int>.value(
          value: 43,
          updateShouldNotify: updateShouldNotify,
          child: child,
        ),
      );
      expect(buildCount, equals(1));
      verify(updateShouldNotify(42, 43)).called(1);

      when(updateShouldNotify(any, any)).thenReturn(true);
      await tester.pumpWidget(
        InheritedProvider<int>.value(
          value: 44,
          updateShouldNotify: updateShouldNotify,
          child: child,
        ),
      );
      expect(buildCount, equals(2));
      verify(updateShouldNotify(43, 44)).called(1);

      verifyNoMoreInteractions(updateShouldNotify);
    });
  });

  group('InheritedProvider()', () {
    testWidgets('hasValue', (tester) async {
      await tester.pumpWidget(InheritedProvider(
        create: (_) => 42,
        child: const Context(),
      ));

      final inheritedContext = tester.element(find.byElementPredicate((e) {
        return e is InheritedContext;
      })) as InheritedContext;

      expect(inheritedContext.hasValue, isFalse);

      inheritedContext.value;

      expect(inheritedContext.hasValue, isTrue);
    });

    testWidgets(
        'provider calls update if rebuilding only due to didChangeDependencies',
        (tester) async {
      final mock = ValueBuilderMock<String>('');

      final provider = ProxyProvider0<String>(
        create: (_) => '',
        update: (c, p) {
          mock(c, p);
          return c.watch<int>().toString();
        },
        child: TextOf<String>(),
      );

      await tester.pumpWidget(Provider.value(value: 0, child: provider));

      expect(find.text('0'), findsOneWidget);
      verify(mock(any, '')).called(1);
      verifyNoMoreInteractions(mock);

      await tester.pumpWidget(Provider.value(value: 1, child: provider));

      expect(find.text('1'), findsOneWidget);
      verify(mock(any, '0')).called(1);
      verifyNoMoreInteractions(mock);
    });

    testWidgets("provider notifying dependents doesn't call update",
        (tester) async {
      final notifier = ValueNotifier(0);
      final mock = ValueBuilderMock<ValueNotifier<int>>(notifier);

      await tester.pumpWidget(
        ChangeNotifierProxyProvider0<ValueNotifier<int>>(
          create: (_) => notifier,
          update: mock,
          child: TextOf<ValueNotifier<int>>(),
        ),
      );

      verify(mock(any, notifier)).called(1);
      verifyNoMoreInteractions(mock);

      notifier.value++;
      await tester.pump();

      verifyNoMoreInteractions(mock);

      await tester.pumpWidget(
        ChangeNotifierProxyProvider0<ValueNotifier<int>>(
          create: (_) => notifier,
          update: mock,
          child: TextOf<ValueNotifier<int>>(),
        ),
      );

      verify(mock(any, notifier)).called(1);
      verifyNoMoreInteractions(mock);
    });

    testWidgets('update can call Provider.of with listen:true', (tester) async {
      await tester.pumpWidget(
        InheritedProvider<int>.value(
          value: 42,
          child: InheritedProvider<String>(
            update: (context, __) => Provider.of<int>(context).toString(),
            child: TextOf<String>(),
          ),
        ),
      );

      expect(find.text('42'), findsOneWidget);
    });

    testWidgets('update lazy loaded can call Provider.of with listen:true',
        (tester) async {
      await tester.pumpWidget(
        InheritedProvider<int>.value(
          value: 42,
          child: InheritedProvider<String>(
            update: (context, __) => Provider.of<int>(context).toString(),
            child: const Context(),
          ),
        ),
      );

      expect(Provider.of<String>(context, listen: false), equals('42'));
    });

    testWidgets('markNeedsNotifyDependents during startListening is noop',
        (tester) async {
      await tester.pumpWidget(
        InheritedProvider<int>(
          update: (_, __) => 24,
          startListening: (e, value) {
            e.markNeedsNotifyDependents();
            return () {};
          },
          child: TextOf<int>(),
        ),
      );
    });

    testWidgets(
      'update can obtain parent of the same type than self',
      (tester) async {
        await tester.pumpWidget(
          InheritedProvider<String>.value(
            value: 'root',
            child: InheritedProvider<String>(
              update: (context, _) {
                return Provider.of(context);
              },
              child: TextOf<String>(),
            ),
          ),
        );

        expect(find.text('root'), findsOneWidget);
      },
    );
    testWidgets('_debugCheckInvalidValueType', (tester) async {
      final checkType = DebugCheckValueTypeMock<int>();

      await tester.pumpWidget(
        InheritedProvider<int>(
          create: (_) => 0,
          update: (_, __) => 1,
          debugCheckInvalidValueType: checkType,
          child: TextOf<int>(),
        ),
      );

      verifyInOrder([
        checkType(0),
        checkType(1),
      ]);
      verifyNoMoreInteractions(checkType);

      await tester.pumpWidget(
        InheritedProvider<int>(
          create: (_) => 0,
          update: (_, __) => 1,
          debugCheckInvalidValueType: checkType,
          child: TextOf<int>(),
        ),
      );

      verifyNoMoreInteractions(checkType);

      await tester.pumpWidget(
        InheritedProvider<int>(
          create: (_) => 0,
          update: (_, __) => 2,
          debugCheckInvalidValueType: checkType,
          child: TextOf<int>(),
        ),
      );

      verify(checkType(2)).called(1);
      verifyNoMoreInteractions(checkType);
    });

    testWidgets('startListening', (tester) async {
      final stopListening = StopListeningMock();
      final startListening = StartListeningMock<int>(stopListening);
      final dispose = DisposeMock<int>();

      await tester.pumpWidget(
        InheritedProvider<int>(
          update: (_, __) => 42,
          startListening: startListening,
          dispose: dispose,
          child: TextOf<int>(),
        ),
      );

      final element = findInheritedContext<int>();

      verify(startListening(element, 42)).called(1);
      verifyNoMoreInteractions(startListening);
      verifyZeroInteractions(stopListening);
      verifyZeroInteractions(dispose);

      await tester.pumpWidget(
        InheritedProvider<int>(
          update: (_, __) => 42,
          startListening: startListening,
          dispose: dispose,
          child: TextOf<int>(),
        ),
      );

      verifyNoMoreInteractions(startListening);
      verifyZeroInteractions(stopListening);
      verifyZeroInteractions(dispose);

      await tester.pumpWidget(Container());

      verifyNoMoreInteractions(startListening);
      verifyInOrder([
        stopListening(),
        dispose(element, 42),
      ]);
      verifyNoMoreInteractions(dispose);
      verifyNoMoreInteractions(stopListening);
    });

    testWidgets('startListening called again when create returns new value',
        (tester) async {
      final stopListening = StopListeningMock();
      final startListening = StartListeningMock<int>(stopListening);

      await tester.pumpWidget(
        InheritedProvider<int>(
          update: (_, __) => 42,
          startListening: startListening,
          child: TextOf<int>(),
        ),
      );

      final element = findInheritedContext<int>();

      verify(startListening(element, 42)).called(1);
      verifyNoMoreInteractions(startListening);
      verifyZeroInteractions(stopListening);

      final stopListening2 = StopListeningMock();
      final startListening2 = StartListeningMock<int>(stopListening2);

      await tester.pumpWidget(
        InheritedProvider<int>(
          update: (_, __) => 24,
          startListening: startListening2,
          child: TextOf<int>(),
        ),
      );

      verifyNoMoreInteractions(startListening);
      verifyInOrder([
        stopListening(),
        startListening2(element, 24),
      ]);
      verifyNoMoreInteractions(startListening2);
      verifyZeroInteractions(stopListening2);

      await tester.pumpWidget(Container());

      verifyNoMoreInteractions(startListening);
      verify(stopListening2()).called(1);
    });

    testWidgets(
      "stopListening not called twice if rebuild doesn't have listeners",
      (tester) async {
        final stopListening = StopListeningMock();
        final startListening = StartListeningMock<int>(stopListening);

        await tester.pumpWidget(
          InheritedProvider<int>(
            update: (_, __) => 42,
            startListening: startListening,
            child: TextOf<int>(),
          ),
        );
        verify(startListening(argThat(isNotNull), 42)).called(1);
        verifyZeroInteractions(stopListening);

        final stopListening2 = StopListeningMock();
        final startListening2 = StartListeningMock<int>(stopListening2);
        await tester.pumpWidget(
          InheritedProvider<int>(
            update: (_, __) => 24,
            startListening: startListening2,
            child: Container(),
          ),
        );

        verifyNoMoreInteractions(startListening);
        verify(stopListening()).called(1);
        verifyZeroInteractions(startListening2);
        verifyZeroInteractions(stopListening2);

        await tester.pumpWidget(Container());

        verifyNoMoreInteractions(startListening);
        verifyNoMoreInteractions(stopListening);
        verifyZeroInteractions(startListening2);
        verifyZeroInteractions(stopListening2);
      },
    );

    testWidgets(
      'fails if initialValueBuilder calls inheritFromElement/inheritFromWidgetOfExactType',
      (tester) async {
        await tester.pumpWidget(
          InheritedProvider<int>.value(
            value: 42,
            child: InheritedProvider<double>(
              create: (context) => Provider.of<int>(context).toDouble(),
              child: Consumer<double>(
                builder: (_, __, ___) => Container(),
              ),
            ),
          ),
        );

        expect(tester.takeException(), isAssertionError);
      },
    );
    testWidgets(
      'builder is called on every rebuild '
      'and after a dependency change',
      (tester) async {
        int? lastValue;
        final child = Consumer<int>(
          builder: (_, value, __) {
            lastValue = value;
            return Container();
          },
        );
        final update = ValueBuilderMock<int>(-1);
        when(update(any, any))
            .thenAnswer((i) => (i.positionalArguments[1] as int) * 2);

        await tester.pumpWidget(
          InheritedProvider<int>(
            create: (_) => 42,
            update: update,
            child: Container(),
          ),
        );

        final inheritedElement = findInheritedContext<int>();
        verifyZeroInteractions(update);

        await tester.pumpWidget(
          InheritedProvider<int>(
            create: (_) => 42,
            update: update,
            child: child,
          ),
        );

        verify(update(inheritedElement, 42)).called(1);
        expect(lastValue, equals(84));

        await tester.pumpWidget(
          InheritedProvider<int>(
            create: (_) => 42,
            update: update,
            child: child,
          ),
        );

        verify(update(inheritedElement, 84)).called(1);
        expect(lastValue, equals(168));

        verifyNoMoreInteractions(update);
      },
    );
    testWidgets(
      'builder with no updateShouldNotify use ==',
      (tester) async {
        int? lastValue;
        var buildCount = 0;
        final child = Consumer<int?>(
          builder: (_, value, __) {
            lastValue = value;
            buildCount++;
            return Container();
          },
        );

        await tester.pumpWidget(
          InheritedProvider<int?>(
            create: (_) => null,
            update: (_, __) => 42,
            child: child,
          ),
        );

        expect(lastValue, equals(42));
        expect(buildCount, equals(1));

        await tester.pumpWidget(
          InheritedProvider<int?>(
            create: (_) => null,
            update: (_, __) => 42,
            child: child,
          ),
        );

        expect(lastValue, equals(42));
        expect(buildCount, equals(1));

        await tester.pumpWidget(
          InheritedProvider<int?>(
            create: (_) => null,
            update: (_, __) => 43,
            child: child,
          ),
        );

        expect(lastValue, equals(43));
        expect(buildCount, equals(2));
      },
    );
    testWidgets(
      'builder calls updateShouldNotify callback',
      (tester) async {
        final updateShouldNotify = UpdateShouldNotifyMock<int>();

        int? lastValue;
        var buildCount = 0;
        final child = Consumer<int>(
          builder: (_, value, __) {
            lastValue = value;
            buildCount++;
            return Container();
          },
        );

        await tester.pumpWidget(
          InheritedProvider<int>(
            update: (_, __) => 42,
            updateShouldNotify: updateShouldNotify,
            child: child,
          ),
        );

        verifyZeroInteractions(updateShouldNotify);
        expect(lastValue, equals(42));
        expect(buildCount, equals(1));

        when(updateShouldNotify(any, any)).thenReturn(true);
        await tester.pumpWidget(
          InheritedProvider<int>(
            update: (_, __) => 42,
            updateShouldNotify: updateShouldNotify,
            child: child,
          ),
        );

        verify(updateShouldNotify(42, 42)).called(1);
        expect(lastValue, equals(42));
        expect(buildCount, equals(2));

        when(updateShouldNotify(any, any)).thenReturn(false);
        await tester.pumpWidget(
          InheritedProvider<int>(
            update: (_, __) => 43,
            updateShouldNotify: updateShouldNotify,
            child: child,
          ),
        );

        verify(updateShouldNotify(42, 43)).called(1);
        expect(lastValue, equals(42));
        expect(buildCount, equals(2));

        verifyNoMoreInteractions(updateShouldNotify);
      },
    );
    testWidgets('initialValue is transmitted to valueBuilder', (tester) async {
      int? lastValue;
      await tester.pumpWidget(
        InheritedProvider<int>(
          create: (_) => 0,
          update: (_, last) {
            lastValue = last;
            return 42;
          },
          child: const Context(),
        ),
      );

      expect(of<int>(), equals(42));
      expect(lastValue, equals(0));
    });

    testWidgets('calls builder again if dependencies change', (tester) async {
      final valueBuilder = ValueBuilderMock<int>(-1);

      when(valueBuilder(any, any)).thenAnswer((invocation) {
        return int.parse(Provider.of<String>(
          invocation.positionalArguments.first as BuildContext,
        ));
      });

      var buildCount = 0;
      final child = InheritedProvider<int>(
        create: (_) => 0,
        update: valueBuilder,
        child: Consumer<int>(
          builder: (_, value, __) {
            buildCount++;
            return Text(
              value.toString(),
              textDirection: TextDirection.ltr,
            );
          },
        ),
      );

      await tester.pumpWidget(
        InheritedProvider<String>.value(
          value: '42',
          child: child,
        ),
      );

      expect(buildCount, equals(1));
      expect(find.text('42'), findsOneWidget);

      await tester.pumpWidget(
        InheritedProvider<String>.value(
          value: '24',
          child: child,
        ),
      );

      expect(buildCount, equals(2));
      expect(find.text('24'), findsOneWidget);

      await tester.pumpWidget(
        InheritedProvider<String>.value(
          value: '24',
          updateShouldNotify: (_, __) => true,
          child: child,
        ),
      );

      expect(buildCount, equals(2));
      expect(find.text('24'), findsOneWidget);
    });

    testWidgets('exposes initialValue if valueBuilder is null', (tester) async {
      await tester.pumpWidget(
        InheritedProvider<int>(
          create: (_) => 42,
          child: const Context(),
        ),
      );

      expect(of<int>(), equals(42));
    });

    testWidgets('call dispose on unmount', (tester) async {
      final dispose = DisposeMock<int>();
      await tester.pumpWidget(
        InheritedProvider<int>(
          update: (_, __) => 42,
          dispose: dispose,
          child: const Context(),
        ),
      );

      expect(of<int>(), equals(42));

      verifyZeroInteractions(dispose);

      final context = findInheritedContext<int>();

      await tester.pumpWidget(Container());

      verify(dispose(context, 42)).called(1);
      verifyNoMoreInteractions(dispose);
    });

    testWidgets('builder unmount, dispose not called if value never read',
        (tester) async {
      final dispose = DisposeMock<int>();

      await tester.pumpWidget(
        InheritedProvider<int>(
          update: (_, __) => 42,
          dispose: dispose,
          child: Container(),
        ),
      );

      await tester.pumpWidget(Container());

      verifyZeroInteractions(dispose);
    });

    testWidgets('call dispose after new value', (tester) async {
      final dispose = DisposeMock<int>();
      await tester.pumpWidget(
        InheritedProvider<int>(
          update: (_, __) => 42,
          dispose: dispose,
          child: const Context(),
        ),
      );

      expect(of<int>(), equals(42));

      final dispose2 = DisposeMock<int>();
      await tester.pumpWidget(
        InheritedProvider<int>(
          update: (_, __) => 42,
          dispose: dispose2,
          child: Container(),
        ),
      );

      verifyZeroInteractions(dispose);
      verifyZeroInteractions(dispose2);

      final context = findInheritedContext<int>();

      final dispose3 = DisposeMock<int>();
      await tester.pumpWidget(
        InheritedProvider<int>(
          update: (_, __) => 24,
          dispose: dispose3,
          child: Container(),
        ),
      );

      verifyZeroInteractions(dispose);
      verifyZeroInteractions(dispose3);
      verify(dispose2(context, 42)).called(1);
      verifyNoMoreInteractions(dispose);
    });

    testWidgets('valueBuilder works without initialBuilder', (tester) async {
      int? lastValue;
      await tester.pumpWidget(
        InheritedProvider<int>(
          update: (_, last) {
            lastValue = last;
            return 42;
          },
          child: const Context(),
        ),
      );

      expect(of<int>(), equals(42));
      expect(lastValue, equals(null));

      await tester.pumpWidget(
        InheritedProvider<int>(
          update: (_, last) {
            lastValue = last;
            return 24;
          },
          child: const Context(),
        ),
      );

      expect(of<int>(), equals(24));
      expect(lastValue, equals(42));
    });
    test('throws if both builder and initialBuilder are missing', () {
      expect(
        () => InheritedProvider<int>(child: Container()),
        throwsAssertionError,
      );
    });

    testWidgets('calls initialValueBuilder lazily once', (tester) async {
      final initialValueBuilder = InitialValueBuilderMock<int>(-1);
      when(initialValueBuilder(any)).thenReturn(42);

      await tester.pumpWidget(
        InheritedProvider<int>(
          create: initialValueBuilder,
          child: const Context(),
        ),
      );

      verifyZeroInteractions(initialValueBuilder);

      final inheritedProviderElement = findInheritedContext<int>();

      expect(of<int>(), equals(42));
      verify(initialValueBuilder(inheritedProviderElement)).called(1);

      await tester.pumpWidget(
        InheritedProvider<int>(
          create: initialValueBuilder,
          child: const Context(),
        ),
      );

      expect(of<int>(), equals(42));
      verifyNoMoreInteractions(initialValueBuilder);
    });
  });

  group('DeferredInheritedProvider.value()', () {
    testWidgets('hasValue', (tester) async {
      await tester.pumpWidget(InheritedProvider.value(
        value: 42,
        child: Container(),
      ));

      final inheritedContext = tester.element(find.byElementPredicate((e) {
        return e is InheritedContext;
      })) as InheritedContext;

      expect(inheritedContext.hasValue, isTrue);

      inheritedContext.value;

      expect(inheritedContext.hasValue, isTrue);
    });

    testWidgets('startListening', (tester) async {
      final stopListening = StopListeningMock();
      final startListening =
          DeferredStartListeningMock<ValueNotifier<int>, int>(
        (e, setState, controller, value) {
          setState(controller.value);
          return stopListening;
        },
      );
      final controller = ValueNotifier<int>(0);

      await tester.pumpWidget(
        DeferredInheritedProvider<ValueNotifier<int>, int>.value(
          value: controller,
          startListening: startListening,
          child: const Context(),
        ),
      );

      verifyZeroInteractions(startListening);

      expect(of<int>(), equals(0));

      verify(startListening(
        argThat(isNotNull),
        argThat(isNotNull),
        controller,
        null,
      )).called(1);

      expect(of<int>(), equals(0));
      verifyNoMoreInteractions(startListening);
      verifyZeroInteractions(stopListening);

      await tester.pumpWidget(
        DeferredInheritedProvider<ValueNotifier<int>, int>.value(
          value: controller,
          startListening: startListening,
          child: const Context(),
        ),
      );

      verifyNoMoreInteractions(startListening);
      verifyZeroInteractions(stopListening);

      await tester.pumpWidget(Container());

      verifyNoMoreInteractions(startListening);
      verify(stopListening()).called(1);
    });

    testWidgets("startListening doesn't need setState if already initialized",
        (tester) async {
      final startListening =
          DeferredStartListeningMock<ValueNotifier<int>, int>(
        (e, setState, controller, value) {
          setState(controller.value);
          return () {};
        },
      );
      final controller = ValueNotifier<int>(0);

      await tester.pumpWidget(
        DeferredInheritedProvider<ValueNotifier<int>, int>.value(
          value: controller,
          startListening: startListening,
          child: TextOf<int>(),
        ),
      );

      expect(find.text('0'), findsOneWidget);

      final startListening2 =
          DeferredStartListeningMock<ValueNotifier<int>, int>();
      when(startListening2(any, any, any, any)).thenReturn(() {});
      final controller2 = ValueNotifier<int>(0);

      await tester.pumpWidget(
        DeferredInheritedProvider<ValueNotifier<int>, int>.value(
          value: controller2,
          startListening: startListening2,
          child: TextOf<int>(),
        ),
      );

      expect(
        find.text('0'),
        findsOneWidget,
        reason: 'startListening2 did not call setState but startListening did',
      );
    });

    testWidgets('setState without updateShouldNotify', (tester) async {
      void Function(int value)? setState;
      var buildCount = 0;

      await tester.pumpWidget(
        DeferredInheritedProvider<int, int>.value(
          value: 0,
          startListening: (_, s, __, ___) {
            setState = s;
            setState!(0);
            return () {};
          },
          child: Consumer<int>(
            builder: (_, value, __) {
              buildCount++;
              return Text('$value', textDirection: TextDirection.ltr);
            },
          ),
        ),
      );

      expect(find.text('0'), findsOneWidget);
      expect(buildCount, equals(1));

      setState!(0);
      await tester.pump();

      expect(buildCount, equals(1));
      expect(find.text('0'), findsOneWidget);

      setState!(1);
      await tester.pump();

      expect(find.text('1'), findsOneWidget);
      expect(buildCount, equals(2));

      setState!(1);
      await tester.pump();

      expect(find.text('1'), findsOneWidget);
      expect(buildCount, equals(2));
    });

    testWidgets('setState with updateShouldNotify', (tester) async {
      final updateShouldNotify = UpdateShouldNotifyMock<int>();
      when(updateShouldNotify(any, any)).thenAnswer((i) {
        return i.positionalArguments[0] != i.positionalArguments[1];
      });
      void Function(int value)? setState;
      var buildCount = 0;

      await tester.pumpWidget(
        DeferredInheritedProvider<int, int>.value(
          value: 0,
          updateShouldNotify: updateShouldNotify,
          startListening: (_, s, __, ___) {
            setState = s;
            setState!(0);
            return () {};
          },
          child: Consumer<int>(
            builder: (_, value, __) {
              buildCount++;
              return Text('$value', textDirection: TextDirection.ltr);
            },
          ),
        ),
      );

      expect(find.text('0'), findsOneWidget);
      expect(buildCount, equals(1));
      verifyZeroInteractions(updateShouldNotify);

      setState!(0);
      await tester.pump();

      verify(updateShouldNotify(0, 0)).called(1);
      verifyNoMoreInteractions(updateShouldNotify);
      expect(buildCount, equals(1));
      expect(find.text('0'), findsOneWidget);

      setState!(1);
      await tester.pump();

      verify(updateShouldNotify(0, 1)).called(1);
      verifyNoMoreInteractions(updateShouldNotify);
      expect(find.text('1'), findsOneWidget);
      expect(buildCount, equals(2));

      setState!(1);
      await tester.pump();

      verify(updateShouldNotify(1, 1)).called(1);
      verifyNoMoreInteractions(updateShouldNotify);
      expect(find.text('1'), findsOneWidget);
      expect(buildCount, equals(2));
    });

    testWidgets('startListening never leave the widget uninitialized',
        (tester) async {
      final startListening =
          DeferredStartListeningMock<ValueNotifier<int>, int>();
      when(startListening(any, any, any, any)).thenReturn(() {});
      final controller = ValueNotifier<int>(0);

      await tester.pumpWidget(
        DeferredInheritedProvider<ValueNotifier<int>, int>.value(
          value: controller,
          startListening: startListening,
          child: TextOf<int>(),
        ),
      );

      expect(
        tester.takeException(),
        isAssertionError,
        reason: 'startListening did not call setState',
      );
    });

    testWidgets('startListening called again on controller change',
        (tester) async {
      var buildCount = 0;
      final child = Consumer<int>(builder: (_, value, __) {
        buildCount++;
        return Text('$value', textDirection: TextDirection.ltr);
      });

      final stopListening = StopListeningMock();
      final startListening =
          DeferredStartListeningMock<ValueNotifier<int>, int>(
        (e, setState, controller, value) {
          setState(controller.value);
          return stopListening;
        },
      );
      final controller = ValueNotifier<int>(0);

      await tester.pumpWidget(
        DeferredInheritedProvider<ValueNotifier<int>, int>.value(
          value: controller,
          startListening: startListening,
          child: child,
        ),
      );

      expect(buildCount, equals(1));
      expect(find.text('0'), findsOneWidget);
      verify(startListening(any, any, controller, null)).called(1);
      verifyZeroInteractions(stopListening);

      final stopListening2 = StopListeningMock();
      final startListening2 =
          DeferredStartListeningMock<ValueNotifier<int>, int>(
        (e, setState, controller, value) {
          setState(controller.value);
          return stopListening2;
        },
      );
      final controller2 = ValueNotifier<int>(1);

      await tester.pumpWidget(
        DeferredInheritedProvider<ValueNotifier<int>, int>.value(
          value: controller2,
          startListening: startListening2,
          child: child,
        ),
      );

      expect(buildCount, equals(2));
      expect(find.text('1'), findsOneWidget);
      verifyInOrder([
        stopListening(),
        startListening2(argThat(isNotNull), argThat(isNotNull), controller2, 0),
      ]);
      verifyNoMoreInteractions(startListening);
      verifyNoMoreInteractions(stopListening);
      verifyZeroInteractions(stopListening2);

      await tester.pumpWidget(Container());

      verifyNoMoreInteractions(startListening);
      verifyNoMoreInteractions(stopListening);
      verifyNoMoreInteractions(startListening2);
      verify(stopListening2()).called(1);
    });
  });

  group('DeferredInheritedProvider()', () {
    testWidgets("create can't call inherited widgets", (tester) async {
      await tester.pumpWidget(
        InheritedProvider<String>.value(
          value: 'hello',
          child: DeferredInheritedProvider<int, int>(
            create: (context) {
              Provider.of<String>(context);
              return 42;
            },
            startListening: (_, setState, ___, ____) {
              setState(0);
              return () {};
            },
            child: TextOf<int>(),
          ),
        ),
      );

      expect(tester.takeException(), isFlutterError);
    });

    testWidgets('creates the value lazily', (tester) async {
      final create = InitialValueBuilderMock<String>('0');
      final stopListening = StopListeningMock();
      final startListening = DeferredStartListeningMock<String, int>(
        (_, setState, __, ___) {
          setState(0);
          return stopListening;
        },
      );

      await tester.pumpWidget(
        DeferredInheritedProvider<String, int>(
          create: create,
          startListening: startListening,
          child: const Context(),
        ),
      );

      verifyZeroInteractions(create);
      verifyZeroInteractions(startListening);
      verifyZeroInteractions(stopListening);

      expect(of<int>(), equals(0));

      verify(create(argThat(isNotNull))).called(1);
      verify(startListening(argThat(isNotNull), argThat(isNotNull), '0', null))
          .called(1);

      expect(of<int>(), equals(0));

      verifyNoMoreInteractions(create);
      verifyNoMoreInteractions(startListening);
      verifyZeroInteractions(stopListening);
    });

    testWidgets('dispose', (tester) async {
      final dispose = DisposeMock<String>();
      final stopListening = StopListeningMock();

      await tester.pumpWidget(
        DeferredInheritedProvider<String, int>(
          create: (_) => '42',
          startListening: (_, setState, __, ___) {
            setState(0);
            return stopListening;
          },
          dispose: dispose,
          child: const Context(),
        ),
      );

      expect(of<int>(), equals(0));

      verifyZeroInteractions(dispose);

      await tester.pumpWidget(Container());

      verifyInOrder([
        stopListening(),
        dispose(argThat(isNotNull), '42'),
      ]);
      verifyNoMoreInteractions(dispose);
    });

    testWidgets('dispose no-op if never built', (tester) async {
      final dispose = DisposeMock<String>();

      await tester.pumpWidget(
        DeferredInheritedProvider<String, int>(
          create: (_) => '42',
          startListening: (_, setState, __, ___) {
            setState(0);
            return () {};
          },
          dispose: dispose,
          child: const Context(),
        ),
      );

      verifyZeroInteractions(dispose);

      await tester.pumpWidget(Container());

      verifyZeroInteractions(dispose);
    });
  });

  testWidgets('startListening markNeedsNotifyDependents', (tester) async {
    InheritedContext<int?>? element;
    var buildCount = 0;

    await tester.pumpWidget(
      InheritedProvider<int>(
        update: (_, __) => 24,
        startListening: (e, value) {
          element = e;
          return () {};
        },
        child: Consumer<int>(
          builder: (_, __, ___) {
            buildCount++;
            return Container();
          },
        ),
      ),
    );

    expect(buildCount, equals(1));

    element!.markNeedsNotifyDependents();
    await tester.pump();

    expect(buildCount, equals(2));

    await tester.pump();

    expect(buildCount, equals(2));
  });

  testWidgets('InheritedProvider can be subclassed', (tester) async {
    await tester.pumpWidget(
      SubclassProvider(
        key: UniqueKey(),
        create: (_) => 42,
        child: const Context(),
      ),
    );

    expect(of<int>(), equals(42));

    await tester.pumpWidget(
      SubclassProvider.value(
        key: UniqueKey(),
        value: 24,
        child: const Context(),
      ),
    );

    expect(of<int>(), equals(24));
  });

  testWidgets('DeferredInheritedProvider can be subclassed', (tester) async {
    await tester.pumpWidget(
      DeferredSubclassProvider(
        key: UniqueKey(),
        value: 42,
        child: const Context(),
      ),
    );

    expect(of<int>(), equals(42));

    await tester.pumpWidget(
      DeferredSubclassProvider.value(
        key: UniqueKey(),
        value: 24,
        child: const Context(),
      ),
    );

    expect(of<int>(), equals(24));
  });

  testWidgets('can be used with MultiProvider', (tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          InheritedProvider.value(value: 42),
        ],
        child: const Context(),
      ),
    );

    expect(of<int>(), equals(42));
  });

  testWidgets('throw if the widget ctor changes', (tester) async {
    await tester.pumpWidget(
      InheritedProvider<int>(
        update: (_, __) => 42,
        child: Container(),
      ),
    );

    expect(tester.takeException(), isNull);

    await tester.pumpWidget(
      InheritedProvider<int>.value(
        value: 42,
        child: Container(),
      ),
    );

    expect(tester.takeException(), isStateError);
  });

  testWidgets('InheritedProvider lazy loading can be disabled', (tester) async {
    final startListening = StartListeningMock<int>(() {});

    await tester.pumpWidget(
      InheritedProvider(
        key: UniqueKey(),
        create: (_) => 42,
        startListening: startListening,
        lazy: false,
        child: Container(),
      ),
    );
    verify(startListening(argThat(isNotNull), 42)).called(1);
  });

  testWidgets('InheritedProvider.value lazy loading can be disabled',
      (tester) async {
    final startListening = StartListeningMock<int>(() {});

    await tester.pumpWidget(
      InheritedProvider.value(
        key: UniqueKey(),
        value: 42,
        startListening: startListening,
        lazy: false,
        child: Container(),
      ),
    );

    verify(startListening(argThat(isNotNull), 42)).called(1);
    verifyNoMoreInteractions(startListening);
  });

  testWidgets(
    "InheritedProvider subclass don't have to specify default lazy value",
    (tester) async {
      final create = InitialValueBuilderMock<int>(42);

      await tester.pumpWidget(
        SubclassProvider(
          key: UniqueKey(),
          create: create,
          child: const Context(),
        ),
      );

      verifyZeroInteractions(create);
      expect(of<int>(), equals(42));
      verify(create(argThat(isNotNull))).called(1);
      verifyNoMoreInteractions(create);
    },
  );
  testWidgets('DeferredInheritedProvider lazy loading can be disabled',
      (tester) async {
    final startListening =
        DeferredStartListeningMock<int, int>((a, setState, c, d) {
      setState(0);
      return () {};
    });

    await tester.pumpWidget(
      DeferredInheritedProvider<int, int>(
        key: UniqueKey(),
        create: (_) => 42,
        startListening: startListening,
        lazy: false,
        child: Container(),
      ),
    );

    verify(startListening(argThat(isNotNull), argThat(isNotNull), 42, null))
        .called(1);
    verifyNoMoreInteractions(startListening);
  });

  testWidgets('DeferredInheritedProvider.value lazy loading can be disabled',
      (tester) async {
    final startListening =
        DeferredStartListeningMock<int, int>((a, setState, c, d) {
      setState(0);
      return () {};
    });

    await tester.pumpWidget(
      DeferredInheritedProvider<int, int>.value(
        key: UniqueKey(),
        value: 42,
        startListening: startListening,
        lazy: false,
        child: Container(),
      ),
    );

    verify(startListening(argThat(isNotNull), argThat(isNotNull), 42, null))
        .called(1);
    verifyNoMoreInteractions(startListening);
  });

  testWidgets('selector', (tester) async {
    final notifier = ValueNotifier(0);
    var buildCount = 0;

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => notifier,
        child: Builder(builder: (context) {
          buildCount++;
          final isEven =
              context.select((ValueNotifier<int> value) => value.value.isEven);

          return Text('$isEven', textDirection: TextDirection.ltr);
        }),
      ),
    );

    expect(buildCount, 1);
    expect(find.text('true'), findsOneWidget);

    notifier.value = 1;
    await tester.pump();

    expect(buildCount, 2);
    expect(find.text('false'), findsOneWidget);

    notifier.value = 3;
    await tester.pump();

    expect(buildCount, 2);
    expect(find.text('false'), findsOneWidget);
  });

  testWidgets('can select multiple types from same provider', (tester) async {
    var buildCount = 0;

    final builder = Builder(builder: (context) {
      buildCount++;
      final isNotNull = context.select((int? value) => value != null);
      final isAbove0 = context.select((int? value) {
        return (value == null || value > 0).toString();
      });

      return Text('$isNotNull $isAbove0', textDirection: TextDirection.ltr);
    });

    await tester.pumpWidget(Provider<int?>.value(value: 0, child: builder));

    expect(buildCount, 1);
    expect(find.text('true false'), findsOneWidget);

    await tester.pumpWidget(Provider<int?>.value(value: -1, child: builder));

    expect(buildCount, 1);

    await tester.pumpWidget(Provider<int?>.value(value: 1, child: builder));

    expect(buildCount, 2);
    expect(find.text('true true'), findsOneWidget);

    await tester.pumpWidget(Provider<int?>.value(value: null, child: builder));

    expect(buildCount, 3);
    expect(find.text('false true'), findsOneWidget);
  });

  testWidgets('can select same type on two different providers',
      (tester) async {
    var buildCount = 0;

    final builder = Builder(builder: (context) {
      buildCount++;
      final intValue = context.select((int value) => value.toString());
      final stringValue = context.select((String value) => value);

      return Text('$intValue $stringValue', textDirection: TextDirection.ltr);
    });

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider.value(value: 0),
          Provider.value(value: 'a'),
        ],
        child: builder,
      ),
    );

    expect(buildCount, 1);
    expect(find.text('0 a'), findsOneWidget);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider.value(value: 0),
          Provider.value(value: 'a'),
        ],
        child: builder,
      ),
    );

    expect(buildCount, 1);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider.value(value: 1),
          Provider.value(value: 'a'),
        ],
        child: builder,
      ),
    );

    expect(buildCount, 2);
    expect(find.text('1 a'), findsOneWidget);
  });

  testWidgets('can select same type twice on same provider', (tester) async {
    var buildCount = 0;
    final child = Builder(builder: (context) {
      buildCount++;
      final value = context.select((int value) => value.isEven);
      final value2 = context.select((int value) => value.isNegative);

      return Text('$value $value2', textDirection: TextDirection.ltr);
    });

    await tester.pumpWidget(Provider.value(value: 0, child: child));

    expect(find.text('true false'), findsOneWidget);
    expect(buildCount, 1);

    await tester.pumpWidget(Provider.value(value: 2, child: child));

    expect(find.text('true false'), findsOneWidget);
    expect(buildCount, 1);

    await tester.pumpWidget(Provider.value(value: -2, child: child));

    expect(find.text('true true'), findsOneWidget);
    expect(buildCount, 2);

    await tester.pumpWidget(Provider.value(value: -4, child: child));

    expect(find.text('true true'), findsOneWidget);
    expect(buildCount, 2);

    await tester.pumpWidget(Provider.value(value: -3, child: child));

    expect(find.text('false true'), findsOneWidget);
    expect(buildCount, 3);

    await tester.pumpWidget(Provider.value(value: -2, child: child));

    expect(find.text('true true'), findsOneWidget);
    expect(buildCount, 4);
  });

  testWidgets('StateError is thrown when lookup fails within create',
      (tester) async {
    const expected =
        'Tried to read a provider that threw during the creation of its value.\n'
        'The exception occurred during the creation of type int.';
    final onError = FlutterError.onError;
    final flutterErrors = <FlutterErrorDetails>[];
    FlutterError.onError = flutterErrors.add;

    await tester.pumpWidget(
      Provider(
        lazy: false,
        create: (context) {
          context.read<String>();
          return 42;
        },
        child: const SizedBox(),
      ),
    );

    FlutterError.onError = onError;

    expect(
      flutterErrors,
      contains(
        isA<FlutterErrorDetails>().having(
          (e) => e.exception,
          'exception',
          isA<StateError>().having(
            (s) => s.message,
            'message',
            startsWith(expected),
          ),
        ),
      ),
    );
  });

  testWidgets('StateError is thrown when exception occurs in create',
      (tester) async {
    final onError = FlutterError.onError;
    final flutterErrors = <FlutterErrorDetails>[];
    FlutterError.onError = flutterErrors.add;

    await tester.pumpWidget(
      Provider<String>(
        lazy: false,
        create: (_) => throw Exception('oops'),
        child: const SizedBox(),
      ),
    );

    FlutterError.onError = onError;

    expect(
      flutterErrors,
      contains(
        isA<FlutterErrorDetails>().having(
          (e) => e.exception,
          'exception',
          isA<StateError>().having(
            (s) => s.message,
            'message',
            startsWith('''
Tried to read a provider that threw during the creation of its value.
The exception occurred during the creation of type String.

══╡ EXCEPTION CAUGHT BY PROVIDER ╞═══════════════════════════════
The following _Exception was thrown:
Exception: oops

When the exception was thrown, this was the stack:
#0'''),
          ),
        ),
      ),
    );
  });

  testWidgets('Exception is thrown when exception occurs in rebuild',
      (tester) async {
    const errorMessage = 'oops';
    final onError = FlutterError.onError;
    final flutterErrors = <FlutterErrorDetails>[];
    FlutterError.onError = flutterErrors.add;

    final provider = InheritedProvider<String>(
      create: (_) => '',
      update: (c, p) {
        throw Exception(errorMessage);
      },
      child: TextOf<String>(),
    );
    await tester.pumpWidget(Provider.value(value: 0, child: provider));

    FlutterError.onError = onError;

    expect(
      flutterErrors,
      contains(
        isA<FlutterErrorDetails>().having(
          (e) => e.exception,
          'exception',
          isA<Exception>().having(
            (s) => s.toString(),
            'toString',
            contains(errorMessage),
          ),
        ),
      ),
    );
  });

  testWidgets(
      'Exception is propagated when context.watch is called after a provider threw',
      (tester) async {
    final onError = FlutterError.onError;
    final flutterErrors = <FlutterErrorDetails>[];
    final exception = Exception('oops');
    FlutterError.onError = flutterErrors.add;

    await tester.pumpWidget(
      Provider<String>(
        create: (_) => throw exception,
        child: Builder(
          builder: (context) {
            return Text(context.watch<String>());
          },
        ),
      ),
    );

    FlutterError.onError = onError;

    expect(
      flutterErrors,
      contains(
        isA<FlutterErrorDetails>().having(
          (e) => e.exception,
          'exception',
          exception,
        ),
      ),
    );
  });
}

class Model {
  int? a;
  String? b;
}

class Example extends StatelessWidget {
  const Example({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final a = context.select((Model model) => model.a);
    final b = context.select((Model model) => model.b);
    return Text('$a $b');
  }
}

class Test<T> extends StatefulWidget {
  const Test({
    Key? key,
    this.didChangeDependencies,
    this.build,
  }) : super(key: key);

  final ValueBuilderMock<T>? didChangeDependencies;
  final ValueBuilderMock<T>? build;

  @override
  _TestState<T> createState() => _TestState<T>();
}

class _TestState<T> extends State<Test<T>> {
  @override
  void didChangeDependencies() {
    widget.didChangeDependencies
        ?.call(this.context, Provider.of<T>(this.context));
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    widget.build?.call(this.context, Provider.of<T>(this.context));
    return Container();
  }
}

class SubclassProvider extends InheritedProvider<int> {
  SubclassProvider({
    Key? key,
    required int Function(BuildContext c) create,
    bool? lazy,
    Widget? child,
  }) : super(key: key, create: create, lazy: lazy, child: child);

  SubclassProvider.value({
    Key? key,
    required int value,
    Widget? child,
  }) : super.value(key: key, value: value, child: child);
}

class DeferredSubclassProvider extends DeferredInheritedProvider<int, int> {
  DeferredSubclassProvider({
    Key? key,
    required int value,
    Widget? child,
  }) : super(
          key: key,
          create: (_) => value,
          startListening: (_, setState, ___, ____) {
            setState(value);
            return () {};
          },
          child: child,
        );

  DeferredSubclassProvider.value({
    Key? key,
    required int value,
    Widget? child,
  }) : super.value(
          key: key,
          value: value,
          startListening: (_, setState, ___, ____) {
            setState(value);
            return () {};
          },
          child: child,
        );
}

class StateNotifier<T> extends ValueNotifier<T> {
  StateNotifier(T value) : super(value);

  Locator? read;

  void update(Locator watch) {}
}

class _Controller1 extends StateNotifier<Counter1> {
  _Controller1() : super(Counter1(0));

  void increment() => value = Counter1(value.count + 1);
}

class Counter1 {
  Counter1(this.count);

  final int count;
}

class _Controller2 extends StateNotifier<Counter2> {
  _Controller2() : super(Counter2(0));

  void increment() => value = Counter2(value.count + 1);

  @override
  void update(T Function<T>() watch) {
    watch<Counter1>();
    watch<_Controller1>();
  }
}

class Counter2 {
  Counter2(this.count);

  final int count;
}

// A stripped version of StateNotifierProvider
class StateNotifierProvider<Controller extends StateNotifier<Value>, Value>
    extends SingleChildStatelessWidget {
  const StateNotifierProvider({
    Key? key,
    required this.create,
    this.lazy,
    Widget? child,
  }) : super(key: key, child: child);

  final Create<Controller> create;
  final bool? lazy;

  @override
  Widget buildWithChild(BuildContext context, Widget? child) {
    return InheritedProvider<Controller>(
      create: (context) {
        assert(debugIsInInheritedProviderCreate);
        assert(!debugIsInInheritedProviderUpdate);
        return create(context)..read = context.read;
      },
      update: (context, controller) {
        assert(!debugIsInInheritedProviderCreate);
        assert(debugIsInInheritedProviderUpdate);
        return controller!..update(context.watch);
      },
      dispose: (_, controller) => controller.dispose(),
      child: DeferredInheritedProvider<Controller, Value>(
        lazy: lazy,
        create: (context) {
          assert(debugIsInInheritedProviderCreate);
          assert(!debugIsInInheritedProviderUpdate);
          return context.read<Controller>();
        },
        startListening: (context, setState, controller, _) {
          setState(controller.value);
          void listener() => setState(controller.value);
          controller.addListener(listener);
          return () => controller.removeListener(listener);
        },
        child: child,
      ),
    );
  }
}
