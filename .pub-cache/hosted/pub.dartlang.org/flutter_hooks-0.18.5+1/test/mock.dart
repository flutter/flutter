// ignore_for_file: one_member_abstracts

import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

export 'package:flutter_test/flutter_test.dart'
    hide
        Func0,
        Func1,
        Func2,
        Func3,
        Func4,
        Func5,
        Func6,
        // ignore: undefined_hidden_name, Fake is only available in master
        Fake;
export 'package:mockito/mockito.dart';

class HookTest<R> extends Hook<R?> {
  // ignore: prefer_const_constructors_in_immutables
  HookTest({
    this.build,
    this.dispose,
    this.initHook,
    this.didUpdateHook,
    this.reassemble,
    this.createStateFn,
    this.didBuild,
    this.deactivate,
    List<Object?>? keys,
  }) : super(keys: keys);

  final R Function(BuildContext context)? build;
  final void Function()? dispose;
  final void Function()? didBuild;
  final void Function()? initHook;
  final void Function()? deactivate;
  final void Function(HookTest<R> previousHook)? didUpdateHook;
  final void Function()? reassemble;
  final HookStateTest<R> Function()? createStateFn;

  @override
  HookStateTest<R> createState() =>
      createStateFn != null ? createStateFn!() : HookStateTest<R>();
}

class HookStateTest<R> extends HookState<R?, HookTest<R>> {
  @override
  void initHook() {
    super.initHook();
    hook.initHook?.call();
  }

  @override
  void dispose() {
    hook.dispose?.call();
  }

  @override
  void didUpdateHook(HookTest<R> oldHook) {
    super.didUpdateHook(oldHook);
    hook.didUpdateHook?.call(oldHook);
  }

  @override
  void reassemble() {
    super.reassemble();
    hook.reassemble?.call();
  }

  @override
  void deactivate() {
    super.deactivate();
    hook.deactivate?.call();
  }

  @override
  R? build(BuildContext context) {
    if (hook.build != null) {
      return hook.build!(context);
    }
    return null;
  }
}

Element _rootOf(Element element) {
  late Element root;
  element.visitAncestorElements((e) {
    root = e;
    return true;
  });
  return root;
}

void hotReload(WidgetTester tester) {
  final root = _rootOf(tester.allElements.first);

  TestWidgetsFlutterBinding.ensureInitialized()
      .buildOwner
      ?.reassemble(root, null);
}

class MockSetState extends Mock {
  void call();
}

class MockInitHook extends Mock {
  void call();
}

class MockCreateState<T extends HookState<dynamic, Hook>> extends Mock {
  MockCreateState(this.value);
  final T value;

  T call() {
    return super.noSuchMethod(
      Invocation.method(#call, []),
      returnValue: value,
      returnValueForMissingStub: value,
    ) as T;
  }
}

class MockBuild<T> extends Mock {
  T call(BuildContext? context);
}

class MockDeactivate extends Mock {
  void call();
}

class MockFlutterErrorDetails extends Mock implements FlutterErrorDetails {
  @override
  String toString({DiagnosticLevel? minLevel}) => super.toString();
}

class MockErrorBuilder extends Mock {
  Widget call(FlutterErrorDetails error) => super.noSuchMethod(
        Invocation.getter(#call),
        returnValue: Container(),
      ) as Widget;
}

class MockOnError extends Mock {
  void call(FlutterErrorDetails? error);
}

class MockReassemble extends Mock {
  void call();
}

class MockDidUpdateHook extends Mock {
  void call(HookTest? hook);
}

class MockDispose extends Mock {
  void call();
}
