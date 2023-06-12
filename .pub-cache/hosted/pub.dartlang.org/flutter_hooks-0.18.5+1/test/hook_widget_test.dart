// ignore_for_file: invalid_use_of_protected_member, only_throw_errors
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import 'mock.dart';

class InheritedInitHook extends Hook<void> {
  @override
  InheritedInitHookState createState() => InheritedInitHookState();
}

class InheritedInitHookState extends HookState<void, InheritedInitHook> {
  @override
  void initHook() {
    context.dependOnInheritedWidgetOfExactType<InheritedWidget>();
  }

  @override
  void build(BuildContext context) {}
}

void main() {
  final build = MockBuild<int?>();
  final dispose = MockDispose();
  final deactivate = MockDeactivate();
  final initHook = MockInitHook();
  final didUpdateHook = MockDidUpdateHook();
  final reassemble = MockReassemble();

  HookTest<int?> createHook() {
    return HookTest<int?>(
      build: build,
      dispose: dispose,
      didUpdateHook: didUpdateHook,
      reassemble: reassemble,
      initHook: initHook,
      deactivate: deactivate,
    );
  }

  void verifyNoMoreHookInteraction() {
    verifyNoMoreInteractions(build);
    verifyNoMoreInteractions(dispose);
    verifyNoMoreInteractions(initHook);
    verifyNoMoreInteractions(didUpdateHook);
  }

  tearDown(() {
    reset(build);
    reset(dispose);
    reset(deactivate);
    reset(initHook);
    reset(didUpdateHook);
    reset(reassemble);
  });

  testWidgets('hooks are disposed in reverse order when their keys changes',
      (tester) async {
    final first = MockDispose();
    final second = MockDispose();

    await tester.pumpWidget(
      HookBuilder(builder: (c) {
        useEffect(() => first, [0]);
        useEffect(() => second, [0]);
        return Container();
      }),
    );

    verifyZeroInteractions(first);
    verifyZeroInteractions(second);

    await tester.pumpWidget(
      HookBuilder(builder: (c) {
        useEffect(() => first, [1]);
        useEffect(() => second, [1]);
        return Container();
      }),
    );

    verifyInOrder([
      second(),
      first(),
    ]);
    verifyNoMoreInteractions(first);
    verifyNoMoreInteractions(second);

    await tester.pumpWidget(Container());

    verifyInOrder([
      second(),
      first(),
    ]);
    verifyNoMoreInteractions(first);
    verifyNoMoreInteractions(second);
  });
  testWidgets('hooks are disposed in reverse order on unmount', (tester) async {
    final first = MockDispose();
    final second = MockDispose();

    await tester.pumpWidget(
      HookBuilder(builder: (c) {
        useEffect(() => first);
        useEffect(() => second);
        return Container();
      }),
    );

    verifyNoMoreInteractions(first);
    verifyNoMoreInteractions(second);

    await tester.pumpWidget(Container());

    verifyInOrder([
      second(),
      first(),
    ]);
    verifyNoMoreInteractions(first);
    verifyNoMoreInteractions(second);
  });

  testWidgets('StatefulHookWidget', (tester) async {
    final notifier = ValueNotifier(0);

    await tester.pumpWidget(MyStatefulHook(value: 0, notifier: notifier));

    expect(find.text('0 0'), findsOneWidget);

    await tester.pumpWidget(MyStatefulHook(value: 1, notifier: notifier));

    expect(find.text('1 0'), findsOneWidget);

    notifier.value++;
    await tester.pump();

    expect(find.text('1 1'), findsOneWidget);
  });

  testWidgets(
      'should call deactivate when removed from and inserted into another place',
      (tester) async {
    final _key1 = GlobalKey();
    final _key2 = GlobalKey();
    final state = ValueNotifier(false);
    final deactivate1 = MockDeactivate();
    final deactivate2 = MockDeactivate();

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.rtl,
        child: ValueListenableBuilder<bool>(
          valueListenable: state,
          builder: (context, value, _) {
            return Stack(children: [
              Container(
                key: const Key('1'),
                child: HookBuilder(
                  key: value ? _key2 : _key1,
                  builder: (context) {
                    use(HookTest<int?>(deactivate: deactivate1));
                    return Container();
                  },
                ),
              ),
              HookBuilder(
                key: !value ? _key2 : _key1,
                builder: (context) {
                  use(HookTest<int?>(deactivate: deactivate2));
                  return Container();
                },
              ),
            ]);
          },
        ),
      ),
    );

    await tester.pump();

    verifyNever(deactivate1());
    verifyNever(deactivate2());
    state.value = true;

    await tester.pump();

    verifyInOrder([
      deactivate1(),
      deactivate2(),
    ]);

    await tester.pump();

    verifyNoMoreInteractions(deactivate1);
    verifyNoMoreInteractions(deactivate2);
  });

  testWidgets('should call other deactivates even if one fails',
      (tester) async {
    final onError = MockOnError();
    final oldOnError = FlutterError.onError;
    FlutterError.onError = onError;

    final errorBuilder = ErrorWidget.builder;
    ErrorWidget.builder = MockErrorBuilder();
    final mockError = MockFlutterErrorDetails();
    when(ErrorWidget.builder(mockError)).thenReturn(Container());

    final deactivate = MockDeactivate();
    when(deactivate()).thenThrow(42);
    final deactivate2 = MockDeactivate();

    final _key = GlobalKey();

    final widget = HookBuilder(
      key: _key,
      builder: (context) {
        use(HookTest<int?>(deactivate: deactivate));
        use(HookTest<int?>(deactivate: deactivate2));
        return Container();
      },
    );

    try {
      await tester.pumpWidget(SizedBox(child: widget));

      verifyNoMoreInteractions(deactivate);
      verifyNoMoreInteractions(deactivate2);

      await tester.pumpWidget(widget);

      verifyInOrder([
        deactivate(),
        deactivate2(),
      ]);

      verify(onError(any)).called(1);
      verifyNoMoreInteractions(deactivate);
      verifyNoMoreInteractions(deactivate2);
    } finally {
      // reset the exception because after the test
      // flutter tries to deactivate the widget and it causes
      // and exception
      when(deactivate()).thenAnswer((_) {});
      FlutterError.onError = oldOnError;
      ErrorWidget.builder = errorBuilder;
    }
  });

  testWidgets('should not allow using inheritedwidgets inside initHook',
      (tester) async {
    await tester.pumpWidget(
      HookBuilder(builder: (_) {
        use(InheritedInitHook());
        return Container();
      }),
    );

    expect(tester.takeException(), isAssertionError);
  });

  testWidgets('allows using inherited widgets outside of initHook',
      (tester) async {
    when(build(any)).thenAnswer((invocation) {
      final context = invocation.positionalArguments.first as BuildContext;
      context.dependOnInheritedWidgetOfExactType<InheritedWidget>();
      return null;
    });

    await tester.pumpWidget(
      HookBuilder(builder: (_) {
        use(HookTest<void>(build: build));
        return Container();
      }),
    );
  });
  testWidgets("release mode don't crash", (tester) async {
    late ValueNotifier<int> notifier;
    debugHotReloadHooksEnabled = false;
    addTearDown(() => debugHotReloadHooksEnabled = true);

    await tester.pumpWidget(
      HookBuilder(builder: (_) {
        notifier = useState(0);

        return Text(notifier.value.toString(),
            textDirection: TextDirection.ltr);
      }),
    );

    expect(find.text('0'), findsOneWidget);

    notifier.value++;
    await tester.pump();

    expect(find.text('1'), findsOneWidget);
  });

  testWidgets('HookElement exposes an immutable list of hooks', (tester) async {
    await tester.pumpWidget(
      HookBuilder(builder: (_) {
        use(HookTest<int?>());
        use(HookTest<String?>());
        return Container();
      }),
    );

    final element = tester.element(find.byType(HookBuilder)) as HookElement;

    expect(element.debugHooks, [
      isA<HookStateTest<int?>>(),
      isA<HookStateTest<String?>>(),
    ]);
  });
  testWidgets(
      'until one build finishes without crashing, it is possible to add hooks',
      (tester) async {
    await tester.pumpWidget(
      HookBuilder(builder: (_) {
        throw 0;
      }),
    );
    expect(tester.takeException(), 0);

    await tester.pumpWidget(
      HookBuilder(builder: (_) {
        use(HookTest<int?>());
        throw 1;
      }),
    );
    expect(tester.takeException(), 1);

    await tester.pumpWidget(
      HookBuilder(builder: (_) {
        use(HookTest<int?>());
        use(HookTest<String?>());
        throw 2;
      }),
    );
    expect(tester.takeException(), 2);

    await tester.pumpWidget(
      HookBuilder(builder: (_) {
        use(HookTest<int?>());
        use(HookTest<String?>());
        use(HookTest<double?>());
        return Container();
      }),
    );
  });
  testWidgets(
      'until one build finishes without crashing, it is possible to add hooks #2',
      (tester) async {
    await tester.pumpWidget(
      HookBuilder(builder: (_) {
        throw 0;
      }),
    );
    expect(tester.takeException(), 0);

    await tester.pumpWidget(
      HookBuilder(builder: (_) {
        use(HookTest<int?>());
        throw 1;
      }),
    );
    expect(tester.takeException(), 1);

    await tester.pumpWidget(
      HookBuilder(builder: (_) {
        use(HookTest<int?>());
        use(HookTest<String?>());
        use(HookTest<double?>());
        throw 2;
      }),
    );
    expect(tester.takeException(), 2);
  });

  testWidgets(
      "After hot-reload that throws it's still possible to add hooks until one build succeeds",
      (tester) async {
    await tester.pumpWidget(
      HookBuilder(builder: (_) {
        return Container();
      }),
    );

    hotReload(tester);

    await tester.pumpWidget(
      HookBuilder(builder: (_) {
        throw 0;
      }),
    );
    expect(tester.takeException(), 0);

    await tester.pumpWidget(
      HookBuilder(builder: (_) {
        use(HookTest<int?>());
        return Container();
      }),
    );
  });

  testWidgets(
      'After hot-reload that throws, hooks are correctly disposed when build succeeds with less hooks',
      (tester) async {
    await tester.pumpWidget(
      HookBuilder(builder: (_) {
        use(createHook());
        return Container();
      }),
    );

    hotReload(tester);

    await tester.pumpWidget(
      HookBuilder(builder: (_) {
        throw 0;
      }),
    );

    expect(tester.takeException(), 0);

    verify(dispose()).called(1);
    verifyNoMoreInteractions(dispose);

    await tester.pumpWidget(
      HookBuilder(builder: (_) {
        return Container();
      }),
    );

    verifyNoMoreInteractions(dispose);
  });

  testWidgets('hooks can be disposed independently with keys', (tester) async {
    final dispose2 = MockDispose();

    await tester.pumpWidget(
      HookBuilder(builder: (context) {
        use(HookTest<int?>(dispose: dispose));
        use(HookTest<String?>(dispose: dispose2));
        return Container();
      }),
    );

    verifyZeroInteractions(dispose);
    verifyZeroInteractions(dispose2);

    await tester.pumpWidget(
      HookBuilder(builder: (context) {
        use(HookTest<int?>(dispose: dispose, keys: const []));
        use(HookTest<String?>(dispose: dispose2));
        return Container();
      }),
    );

    verify(dispose()).called(1);
    verifyZeroInteractions(dispose2);

    await tester.pumpWidget(
      HookBuilder(builder: (context) {
        use(HookTest<int?>(dispose: dispose, keys: const []));
        use(HookTest<String?>(dispose: dispose2, keys: const []));
        return Container();
      }),
    );

    verify(dispose2()).called(1);
    verifyNoMoreInteractions(dispose);
  });
  testWidgets('keys recreate hookstate', (tester) async {
    List<Object?>? keys;

    final createState =
        MockCreateState<HookStateTest<int?>>(HookStateTest<int?>());
    // when(createState()).thenReturn(HookStateTest<int>());

    late HookTest<int?> hookTest;

    Widget $build() {
      return HookBuilder(builder: (context) {
        hookTest = HookTest<int?>(
          build: build,
          dispose: dispose,
          didUpdateHook: didUpdateHook,
          initHook: initHook,
          keys: keys,
          createStateFn: createState,
        );
        use(hookTest);
        return Container();
      });
    }

    await tester.pumpWidget($build());

    final context = tester.element(find.byType(HookBuilder));

    verifyInOrder([
      createState(),
      initHook(),
      build(context),
    ]);
    verifyNoMoreHookInteraction();

    await tester.pumpWidget($build());

    verifyInOrder([
      didUpdateHook(any),
      build(context),
    ]);
    verifyNoMoreHookInteraction();

    // from null to array
    keys = [];
    await tester.pumpWidget($build());

    verifyInOrder([
      createState(),
      initHook(),
      build(context),
      dispose(),
    ]);
    verifyNoMoreHookInteraction();

    // array immutable
    keys.add(42);

    await tester.pumpWidget($build());

    verifyInOrder([
      didUpdateHook(any),
      build(context),
    ]);
    verifyNoMoreHookInteraction();

    // new array but content equal
    keys = [42];

    await tester.pumpWidget($build());

    verifyInOrder([
      didUpdateHook(any),
      build(context),
    ]);
    verifyNoMoreHookInteraction();

    // new array new content
    keys = [44];

    await tester.pumpWidget($build());

    verifyInOrder([
      createState(),
      initHook(),
      build(context),
      dispose(),
    ]);
    verifyNoMoreHookInteraction();
  });

  testWidgets('hook & setState', (tester) async {
    final setState = MockSetState();
    final hook = MyHook();
    late HookElement hookContext;
    late MyHookState state;

    await tester.pumpWidget(HookBuilder(
      builder: (context) {
        hookContext = context as HookElement;
        state = use(hook);
        return Container();
      },
    ));

    expect(state.hook, hook);
    expect(state.context, hookContext);
    expect(hookContext.dirty, false);

    state.setState(setState);
    verify(setState()).called(1);

    expect(hookContext.dirty, true);
  });

  testWidgets('life-cycles in order', (tester) async {
    late int? result;
    late HookTest<int?> hook;

    when(build(any)).thenReturn(42);

    await tester.pumpWidget(HookBuilder(
      builder: (context) {
        hook = createHook();
        result = use(hook);
        return Container();
      },
    ));

    final context = tester.firstElement(find.byType(HookBuilder));
    expect(result, 42);
    verifyInOrder([
      initHook(),
      build(any),
    ]);
    verifyNoMoreHookInteraction();

    when(build(context)).thenReturn(24);
    var previousHook = hook;

    await tester.pumpWidget(HookBuilder(
      builder: (context) {
        hook = createHook();
        result = use(hook);
        return Container();
      },
    ));

    expect(result, 24);
    verifyInOrder([
      didUpdateHook(previousHook),
      build(context),
    ]);
    verifyNoMoreHookInteraction();

    previousHook = hook;
    await tester.pump();

    verifyNoMoreHookInteraction();

    await tester.pumpWidget(const SizedBox());

    verify(dispose()).called(1);
    verifyNoMoreHookInteraction();
  });

  testWidgets('dispose all called even on failed', (tester) async {
    final dispose2 = MockDispose();

    when(build(any)).thenReturn(42);

    await tester.pumpWidget(
      HookBuilder(builder: (context) {
        use(createHook());
        use(HookTest<int?>(dispose: dispose2));
        return Container();
      }),
    );

    when(dispose()).thenThrow(24);
    await tester.pumpWidget(const SizedBox());

    expect(tester.takeException(), 24);

    verifyInOrder([
      dispose2(),
      dispose(),
    ]);
  });

  testWidgets('hook update with same instance do not call didUpdateHook',
      (tester) async {
    final hook = createHook();

    await tester.pumpWidget(
      HookBuilder(builder: (context) {
        use(hook);
        return Container();
      }),
    );

    verifyInOrder([
      initHook(),
      build(any),
    ]);
    verifyZeroInteractions(didUpdateHook);
    verifyZeroInteractions(dispose);

    await tester.pumpWidget(
      HookBuilder(builder: (context) {
        use(hook);
        return Container();
      }),
    );

    verifyInOrder([
      build(any),
    ]);
    verifyNever(didUpdateHook(hook));
    verifyNever(initHook());
    verifyNever(dispose());
  });

  testWidgets('rebuild with different hooks crash', (tester) async {
    await tester.pumpWidget(
      HookBuilder(builder: (context) {
        use(HookTest<int?>());
        return Container();
      }),
    );

    await tester.pumpWidget(
      HookBuilder(builder: (context) {
        use(HookTest<String?>());
        return Container();
      }),
    );

    expect(tester.takeException(), isStateError);
  });
  testWidgets('rebuilds can add new hooks', (tester) async {
    await tester.pumpWidget(
      HookBuilder(builder: (context) {
        final a = useState(false).value;
        return Text('$a', textDirection: TextDirection.ltr);
      }),
    );

    expect(find.text('false'), findsOneWidget);

    await tester.pumpWidget(
      HookBuilder(builder: (context) {
        final a = useState(true).value;
        final b = useState(42).value;

        return Text('$a $b', textDirection: TextDirection.ltr);
      }),
    );

    expect(find.text('false 42'), findsOneWidget);
  });

  testWidgets('rebuild can remove hooks', (tester) async {
    await tester.pumpWidget(
      HookBuilder(builder: (context) {
        final a = useState(false).value;
        final b = useState(42).value;

        return Text('$a $b', textDirection: TextDirection.ltr);
      }),
    );

    expect(find.text('false 42'), findsOneWidget);

    await tester.pumpWidget(
      HookBuilder(builder: (context) {
        final a = useState(true).value;
        return Text('$a', textDirection: TextDirection.ltr);
      }),
    );

    expect(find.text('false'), findsOneWidget);
  });

  testWidgets('use call outside build crash', (tester) async {
    await tester.pumpWidget(
      HookBuilder(builder: (context) {
        return Container();
      }),
    );

    expect(() => use(HookTest<int?>()), throwsAssertionError);
  });

  testWidgets('hot-reload triggers a build', (tester) async {
    late int? result;
    late HookTest<int?> previousHook;

    when(build(any)).thenReturn(42);

    await tester.pumpWidget(
      HookBuilder(builder: (context) {
        previousHook = createHook();
        result = use(previousHook);
        return Container();
      }),
    );

    expect(result, 42);
    verifyInOrder([
      initHook(),
      build(any),
    ]);
    verifyZeroInteractions(didUpdateHook);
    verifyZeroInteractions(dispose);

    when(build(any)).thenReturn(24);

    hotReload(tester);
    await tester.pump();

    expect(result, 24);
    verifyInOrder([
      didUpdateHook(any),
      build(any),
    ]);
    verifyNever(initHook());
    verifyNever(dispose());
  });

  testWidgets('hot-reload calls reassemble', (tester) async {
    final reassemble2 = MockReassemble();
    final didUpdateHook2 = MockDidUpdateHook();
    await tester.pumpWidget(
      HookBuilder(builder: (context) {
        use(createHook());
        use(HookTest<void>(
          reassemble: reassemble2,
          didUpdateHook: didUpdateHook2,
        ));
        return Container();
      }),
    );

    verifyNoMoreInteractions(reassemble);

    hotReload(tester);
    await tester.pump();

    verifyInOrder([
      reassemble(),
      reassemble2(),
      didUpdateHook(any),
      didUpdateHook2(any),
    ]);
    verifyNoMoreInteractions(reassemble);
  });

  testWidgets("hot-reload don't reassemble newly added hooks", (tester) async {
    await tester.pumpWidget(
      HookBuilder(builder: (context) {
        use(HookTest<int?>());
        return Container();
      }),
    );

    verifyNoMoreInteractions(reassemble);

    hotReload(tester);
    await tester.pumpWidget(
      HookBuilder(builder: (context) {
        use(HookTest<int?>());
        use(createHook());
        return Container();
      }),
    );

    verifyNoMoreInteractions(didUpdateHook);
    verifyNoMoreInteractions(reassemble);
  });

  testWidgets('hot-reload can add hooks at the end of the list',
      (tester) async {
    late HookTest hook1;

    final dispose2 = MockDispose();
    final initHook2 = MockInitHook();
    final didUpdateHook2 = MockDidUpdateHook();
    final build2 = MockBuild<String?>();

    await tester.pumpWidget(
      HookBuilder(builder: (context) {
        use(hook1 = createHook());
        return Container();
      }),
    );

    final context = tester.element(find.byType(HookBuilder));

    verifyInOrder([
      initHook(),
      build(any),
    ]);
    verifyZeroInteractions(dispose);
    verifyZeroInteractions(didUpdateHook);

    hotReload(tester);

    await tester.pumpWidget(
      HookBuilder(builder: (context) {
        use(createHook());
        use(
          HookTest<String?>(
            initHook: initHook2,
            build: build2,
            didUpdateHook: didUpdateHook2,
            dispose: dispose2,
          ),
        );
        return Container();
      }),
    );

    verifyInOrder([
      didUpdateHook(hook1),
      build(any),
      initHook2(),
      build2(context),
    ]);
    verifyNoMoreInteractions(initHook);
    verifyZeroInteractions(dispose);
    verifyZeroInteractions(dispose2);
    verifyZeroInteractions(didUpdateHook2);
  });

  testWidgets('hot-reload can add hooks in the middle of the list',
      (tester) async {
    final dispose2 = MockDispose();
    final initHook2 = MockInitHook();
    final didUpdateHook2 = MockDidUpdateHook();
    final build2 = MockBuild<String?>();

    await tester.pumpWidget(
      HookBuilder(builder: (context) {
        use(createHook());
        return Container();
      }),
    );

    final context = tester.element(find.byType(HookBuilder));

    verifyInOrder([
      initHook(),
      build(any),
    ]);
    verifyZeroInteractions(dispose);
    verifyZeroInteractions(didUpdateHook);

    hotReload(tester);

    await tester.pumpWidget(
      HookBuilder(builder: (context) {
        use(HookTest<String?>(
          initHook: initHook2,
          build: build2,
          didUpdateHook: didUpdateHook2,
          dispose: dispose2,
        ));
        use(createHook());
        return Container();
      }),
    );

    verifyInOrder([
      initHook2(),
      build2(context),
      initHook(),
      build(any),
      dispose(),
    ]);
    verifyNoMoreInteractions(didUpdateHook);
    verifyNoMoreInteractions(dispose);
    verifyZeroInteractions(dispose2);
    verifyZeroInteractions(didUpdateHook2);
  });
  testWidgets('hot-reload can remove hooks', (tester) async {
    final dispose2 = MockDispose();
    final initHook2 = MockInitHook();
    final didUpdateHook2 = MockDidUpdateHook();
    final build2 = MockBuild<int?>();

    await tester.pumpWidget(
      HookBuilder(builder: (context) {
        use(createHook());
        use(
          HookTest<int?>(
            initHook: initHook2,
            build: build2,
            didUpdateHook: didUpdateHook2,
            dispose: dispose2,
          ),
        );
        return Container();
      }),
    );
    final context = tester.element(find.byType(HookBuilder));

    verifyInOrder([
      initHook(),
      build(any),
      initHook2(),
      build2(context),
    ]);

    verifyZeroInteractions(dispose);
    verifyZeroInteractions(didUpdateHook);
    verifyZeroInteractions(dispose2);
    verifyZeroInteractions(didUpdateHook2);

    hotReload(tester);

    await tester.pumpWidget(
      HookBuilder(builder: (context) {
        return Container();
      }),
    );

    verifyInOrder([
      dispose2(),
      dispose(),
    ]);

    verifyNoMoreInteractions(initHook);
    verifyNoMoreInteractions(initHook2);
    verifyNoMoreInteractions(build2);
    verifyNoMoreInteractions(build);

    verifyZeroInteractions(didUpdateHook);
    verifyZeroInteractions(didUpdateHook2);
  });
  testWidgets('hot-reload disposes hooks when type change', (tester) async {
    late HookTest hook1;

    final dispose2 = MockDispose();
    final initHook2 = MockInitHook();
    final didUpdateHook2 = MockDidUpdateHook();
    final build2 = MockBuild<int?>();

    final dispose3 = MockDispose();
    final initHook3 = MockInitHook();
    final didUpdateHook3 = MockDidUpdateHook();
    final build3 = MockBuild<int?>();

    final dispose4 = MockDispose();
    final initHook4 = MockInitHook();
    final didUpdateHook4 = MockDidUpdateHook();
    final build4 = MockBuild<int?>();

    await tester.pumpWidget(
      HookBuilder(builder: (context) {
        use(hook1 = createHook());
        use(HookTest<String?>(dispose: dispose2));
        use(HookTest<Object?>(dispose: dispose3));
        use(HookTest<void>(dispose: dispose4));
        return Container();
      }),
    );

    final context = tester.element(find.byType(HookBuilder));

    // We don't care about the data from the first render
    clearInteractions(initHook);
    clearInteractions(didUpdateHook);
    clearInteractions(dispose);
    clearInteractions(build);

    clearInteractions(initHook2);
    clearInteractions(didUpdateHook2);
    clearInteractions(dispose2);
    clearInteractions(build2);

    clearInteractions(initHook3);
    clearInteractions(didUpdateHook3);
    clearInteractions(dispose3);
    clearInteractions(build3);

    clearInteractions(initHook4);
    clearInteractions(didUpdateHook4);
    clearInteractions(dispose4);
    clearInteractions(build4);

    hotReload(tester);

    await tester.pumpWidget(
      HookBuilder(builder: (context) {
        use(createHook());
        // changed type from HookTest<String>
        use(
          HookTest<int?>(
            initHook: initHook2,
            build: build2,
            didUpdateHook: didUpdateHook2,
          ),
        );
        use(
          HookTest<int?>(
            initHook: initHook3,
            build: build3,
            didUpdateHook: didUpdateHook3,
          ),
        );
        use(
          HookTest<int?>(
            initHook: initHook4,
            build: build4,
            didUpdateHook: didUpdateHook4,
          ),
        );
        return Container();
      }),
    );

    verifyInOrder([
      didUpdateHook(hook1),
      build(any),
      initHook2(),
      build2(context),
      initHook3(),
      build3(context),
      initHook4(),
      build4(context),
      dispose4(),
      dispose3(),
      dispose2(),
    ]);
    verifyZeroInteractions(initHook);
    verifyZeroInteractions(dispose);
    verifyZeroInteractions(didUpdateHook2);
    verifyZeroInteractions(didUpdateHook3);
    verifyZeroInteractions(didUpdateHook4);
  });

  testWidgets('hot-reload disposes hooks when type change', (tester) async {
    late HookTest hook1;

    final dispose2 = MockDispose();
    final initHook2 = MockInitHook();
    final didUpdateHook2 = MockDidUpdateHook();
    final build2 = MockBuild<int?>();

    final dispose3 = MockDispose();
    final initHook3 = MockInitHook();
    final didUpdateHook3 = MockDidUpdateHook();
    final build3 = MockBuild<int?>();

    final dispose4 = MockDispose();
    final initHook4 = MockInitHook();
    final didUpdateHook4 = MockDidUpdateHook();
    final build4 = MockBuild<int?>();

    await tester.pumpWidget(
      HookBuilder(builder: (context) {
        use(hook1 = createHook());
        use(HookTest<String?>(dispose: dispose2));
        use(HookTest<Object?>(dispose: dispose3));
        use(HookTest<void>(dispose: dispose4));
        return Container();
      }),
    );

    final context = tester.element(find.byType(HookBuilder));

    // We don't care about the data from the first render
    clearInteractions(initHook);
    clearInteractions(didUpdateHook);
    clearInteractions(dispose);
    clearInteractions(build);

    clearInteractions(initHook2);
    clearInteractions(didUpdateHook2);
    clearInteractions(dispose2);
    clearInteractions(build2);

    clearInteractions(initHook3);
    clearInteractions(didUpdateHook3);
    clearInteractions(dispose3);
    clearInteractions(build3);

    clearInteractions(initHook4);
    clearInteractions(didUpdateHook4);
    clearInteractions(dispose4);
    clearInteractions(build4);

    hotReload(tester);
    await tester.pumpWidget(
      HookBuilder(builder: (context) {
        use(createHook());
        // changed type from HookTest<String>
        use(HookTest<int?>(
          initHook: initHook2,
          build: build2,
          didUpdateHook: didUpdateHook2,
        ));
        use(HookTest<int?>(
          initHook: initHook3,
          build: build3,
          didUpdateHook: didUpdateHook3,
        ));
        use(HookTest<int?>(
          initHook: initHook4,
          build: build4,
          didUpdateHook: didUpdateHook4,
        ));
        return Container();
      }),
    );

    verifyInOrder([
      didUpdateHook(hook1),
      build(any),
      initHook2(),
      build2(context),
      initHook3(),
      build3(context),
      initHook4(),
      build4(context),
      dispose4(),
      dispose3(),
      dispose2(),
    ]);
    verifyZeroInteractions(initHook);
    verifyZeroInteractions(dispose);
    verifyZeroInteractions(didUpdateHook2);
    verifyZeroInteractions(didUpdateHook3);
    verifyZeroInteractions(didUpdateHook4);
  });

  testWidgets('hot-reload without hooks do not crash', (tester) async {
    await tester.pumpWidget(
      HookBuilder(builder: (c) {
        return Container();
      }),
    );

    hotReload(tester);
    await tester.pump();
  });

  testWidgets('refreshes identical widgets on hot-reload', (tester) async {
    var value = 0;
    final child = HookBuilder(builder: (context) {
      use(MayHaveChangedOnReassemble());

      return Text('$value', textDirection: TextDirection.ltr);
    });

    await tester.pumpWidget(child);

    expect(find.text('0'), findsOneWidget);

    value = 1;

    // ignore: unawaited_futures
    tester.binding.reassembleApplication();
    await tester.pump();

    expect(find.text('1'), findsOneWidget);
  });
}

class MayHaveChangedOnReassemble extends Hook<void> {
  @override
  MayHaveChangedOnReassembleState createState() =>
      MayHaveChangedOnReassembleState();
}

class MayHaveChangedOnReassembleState
    extends HookState<void, MayHaveChangedOnReassemble> {
  @override
  void reassemble() {
    markMayNeedRebuild();
  }

  @override
  bool shouldRebuild() {
    return false;
  }

  @override
  void build(BuildContext context) {}
}

class MyHook extends Hook<MyHookState> {
  @override
  MyHookState createState() => MyHookState();
}

class MyHookState extends HookState<MyHookState, MyHook> {
  @override
  MyHookState build(BuildContext context) {
    return this;
  }
}

class MyStatefulHook extends StatefulHookWidget {
  const MyStatefulHook({Key? key, this.value, this.notifier}) : super(key: key);

  final int? value;
  final ValueNotifier<int>? notifier;

  @override
  _MyStatefulHookState createState() => _MyStatefulHookState();
}

class _MyStatefulHookState extends State<MyStatefulHook> {
  int? value;

  @override
  void initState() {
    super.initState();
    // voluntarily ues widget.value to verify that state life-cycles are called
    value = widget.value;
  }

  @override
  void didUpdateWidget(MyStatefulHook oldWidget) {
    super.didUpdateWidget(oldWidget);
    value = widget.value;
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      '$value ${useValueListenable<int>(widget.notifier ?? ValueNotifier(value ?? 42))}',
      textDirection: TextDirection.ltr,
    );
  }
}
