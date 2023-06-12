import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Whether to behave like in release mode or allow hot-reload for hooks.
///
/// `true` by default. It has no impact on release builds.
bool debugHotReloadHooksEnabled = true;

/// Registers a [Hook] and returns its value.
///
/// [use] must be called within the `build` method of either [HookWidget] or [StatefulHookWidget].
/// All calls of [use] must be made outside of conditional checks and always in the same order.
///
/// See [Hook] for more explanations.
// ignore: deprecated_member_use, deprecated_member_use_from_same_package
R use<R>(Hook<R> hook) => Hook.use(hook);

/// [Hook] is similar to a [StatelessWidget], but is not associated
/// to an [Element].
///
/// A [Hook] is typically the equivalent of [State] for [StatefulWidget],
/// with the notable difference that a [HookWidget] can have more than one [Hook].
/// A [Hook] is created within the [HookState.build] method of a [HookWidget] and the creation
/// must be made unconditionally, always in the same order.
///
/// ### Good:
/// ```
/// class Good extends HookWidget {
///   @override
///   Widget build(BuildContext context) {
///     final name = useState("");
///     // ...
///   }
/// }
/// ```
///
/// ### Bad:
/// ```
/// class Bad extends HookWidget {
///   @override
///   Widget build(BuildContext context) {
///     if (condition) {
///       final name = useState("");
///       // ...
///     }
///   }
/// }
/// ```
///
/// The reason for such restrictions is that [HookState] are obtained based on their index.
/// So the index must never ever change, or it will lead to undesired behavior.
///
/// ## Usage
///
/// [Hook] is a powerful tool which enables the reuse of [State] logic between multiple [Widget].
/// They are used to extract logic that depends on a [Widget] life-cycle (such as [HookState.dispose]).
///
/// While mixins are a good candidate too, they do not allow sharing values. A mixin cannot reasonably
/// define a variable, as this can lead to variable conflicts in bigger widgets.
///
/// Hooks are designed so that they get the benefits of mixins, but are totally independent from each other.
/// This means that hooks can store and expose values without needing to check if the name is already taken by another mixin.
///
/// ## Example
///
/// A common use-case is to handle disposable objects such as [AnimationController].
///
/// With the usual [StatefulWidget], we would typically have the following:
///
/// ```
/// class Usual extends StatefulWidget {
///   @override
///   _UsualState createState() => _UsualState();
/// }
///
/// class _UsualState extends State<Usual>
///     with SingleTickerProviderStateMixin {
///   late final _controller = AnimationController(
///     vsync: this,
///     duration: const Duration(seconds: 1),
///   );
///
///   @override
///   void dispose() {
///     _controller.dispose();
///     super.dispose();
///   }
///
///   @override
///   Widget build(BuildContext context) {
///     return Container();
///   }
/// }
/// ```
///
/// This is undesired because every single widget that wants to use an [AnimationController] will have to
/// rewrite this exact piece of code.
///
/// With hooks, it is possible to extract that exact piece of code into a reusable one.
///
/// This means that with [HookWidget] the following code is functionally equivalent to the previous example:
///
/// ```
/// class Usual extends HookWidget {
///   @override
///   Widget build(BuildContext context) {
///     final animationController = useAnimationController(duration: const Duration(seconds: 1));
///     return Container();
///   }
/// }
/// ```
///
/// This is visibly less code then before, but in this example, the `animationController` is still
/// guaranteed to be disposed when the widget is removed from the tree.
///
/// In fact, this has a secondary bonus: `duration` is kept updated with the latest value.
/// If we were to pass a variable as `duration` instead of a constant, then on value change the [AnimationController] will be updated.
@immutable
abstract class Hook<R> with Diagnosticable {
  /// Allows subclasses to have a `const` constructor
  const Hook({this.keys});

  /// Registers a [Hook] and returns its value.
  ///
  /// [use] must be called within the `build` method of either [HookWidget] or [StatefulHookWidget].
  /// All calls to [use] must be made outside of conditional statements and always on the same order.
  ///
  /// See [Hook] for more explanations.
  @Deprecated('Use `use` instead of `Hook.use`')
  static R use<R>(Hook<R> hook) {
    assert(HookElement._currentHookElement != null, '''
Hooks can only be called from the build method of a widget that mix-in `Hooks`.

Hooks should only be called within the build method of a widget.
Calling them outside of build method leads to an unstable state and is therefore prohibited.
''');
    return HookElement._currentHookElement!._use(hook);
  }

  /// A list of objects that specify if a [HookState] should be reused or a new one should be created.
  ///
  /// When a new [Hook] is created, the framework checks if keys matches using [Hook.shouldPreserveState].
  /// If they don't, the previously created [HookState] is disposed, and a new one is created
  /// using [Hook.createState], followed by [HookState.initHook].
  final List<Object?>? keys;

  /// The algorithm to determine if a [HookState] should be reused or disposed.
  ///
  /// This compares [Hook.keys] to see if they contains any difference.
  /// A state is preserved when:
  ///
  /// - `hook1.keys == hook2.keys` (typically if the list is immutable)
  /// - If there's any difference in the content of [Hook.keys], using `operator==`.
  static bool shouldPreserveState(Hook hook1, Hook hook2) {
    final p1 = hook1.keys;
    final p2 = hook2.keys;

    if (p1 == p2) {
      return true;
    }
    // if one list is null and the other one isn't, or if they have different sizes
    if (p1 == null || p2 == null || p1.length != p2.length) {
      return false;
    }

    final i1 = p1.iterator;
    final i2 = p2.iterator;
    // ignore: literal_only_boolean_expressions, returns will abort the loop
    while (true) {
      if (!i1.moveNext() || !i2.moveNext()) {
        return true;
      }
      if (i1.current != i2.current) {
        return false;
      }
    }
  }

  /// Creates the mutable state for this [Hook] linked to its widget creator.
  ///
  /// Subclasses should override this method to return a newly created instance of their associated [State] subclass:
  ///
  /// ```
  /// @override
  /// HookState createState() => _MyHookState();
  /// ```
  ///
  /// The framework can call this method multiple times over the lifetime of a [HookWidget]. For example,
  /// if the hook is used multiple times, a separate [HookState] must be created for each usage.
  @protected
  HookState<R, Hook<R>> createState();
}

/// The logic and internal state for a [HookWidget]
abstract class HookState<R, T extends Hook<R>> with Diagnosticable {
  /// Equivalent of [State.context] for [HookState]
  @protected
  BuildContext get context => _element!;
  HookElement? _element;

  R? _debugLastBuiltValue;

  /// The value shown in the devtool.
  ///
  /// Defaults to the last value returned by [build].
  Object? get debugValue => _debugLastBuiltValue;

  /// A flag to prevent showing [debugValue] in the devtool for a [Hook] that returns nothing.
  bool get debugSkipValue => false;

  /// A label used by the devtool to show the state of a [Hook].
  String? get debugLabel => null;

  /// Whether or not the devtool description should skip [debugFillProperties].
  bool get debugHasShortDescription => true;

  /// Equivalent of [State.widget] for [HookState].
  T get hook => _hook!;
  T? _hook;

  /// Equivalent of [State.initState] for [HookState].
  @protected
  void initHook() {}

  /// Equivalent of [State.dispose] for [HookState].
  @protected
  void dispose() {}

  /// Called everytime the [HookState] is requested.
  ///
  /// [build] is where a [HookState] may use other hooks. This restriction is made to ensure that hooks are always unconditionally requested.
  @protected
  R build(BuildContext context);

  /// Equivalent of [State.didUpdateWidget] for [HookState].
  @protected
  void didUpdateHook(T oldHook) {}

  /// Equivalent of [State.deactivate] for [HookState].
  void deactivate() {}

  /// {@macro flutter.widgets.reassemble}
  ///
  /// In addition to this method being invoked, it is guaranteed that the
  /// [build] method will be invoked when a reassemble is signaled. Most
  /// widgets therefore do not need to do anything in the [reassemble] method.
  ///
  /// See also:
  ///
  ///  * [State.reassemble]
  void reassemble() {}

  /// Called before a [build] triggered by [markMayNeedRebuild].
  ///
  /// If [shouldRebuild] returns `false` on all the hooks that called [markMayNeedRebuild]
  /// then this aborts the rebuild of the associated [HookWidget].
  ///
  /// There is no guarantee that this method will be called after [markMayNeedRebuild]
  /// was called.
  /// Some situations where [shouldRebuild] will not be called:
  ///
  /// - [setState] was called
  /// - a previous hook's [shouldRebuild] returned `true`
  /// - the associated [HookWidget] changed.
  bool shouldRebuild() => true;

  /// Mark the associated [HookWidget] as **potentially** needing to rebuild.
  ///
  /// As opposed to [setState], the rebuild is optional and can be cancelled right
  /// before `build` is called, by having [shouldRebuild] return false.
  void markMayNeedRebuild() {
    if (_element!._isOptionalRebuild != false) {
      _element!
        .._isOptionalRebuild = true
        .._shouldRebuildQueue.add(_Entry(shouldRebuild))
        ..markNeedsBuild();
    }
    assert(_element!.dirty, 'Bad state');
  }

  /// Equivalent of [State.setState] for [HookState].
  @protected
  void setState(VoidCallback fn) {
    fn();
    _element!
      .._isOptionalRebuild = false
      ..markNeedsBuild();
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    final value = debugValue;
    if (value != this) {
      properties.add(DiagnosticsProperty(null, value));
    }
    hook.debugFillProperties(properties);
  }
}

class _Entry<T> extends LinkedListEntry<_Entry<T>> {
  _Entry(this.value);
  T value;
}

extension on HookElement {
  HookState<R, Hook<R>> _createHookState<R>(Hook<R> hook) {
    assert(() {
      _debugIsInitHook = true;
      return true;
    }(), '');

    final state = hook.createState()
      .._element = this
      .._hook = hook
      ..initHook();

    assert(() {
      _debugIsInitHook = false;
      return true;
    }(), '');

    return state;
  }

  void _appendHook<R>(Hook<R> hook) {
    final result = _createHookState<R>(hook);
    _currentHookState = _Entry(result);
    _hooks.add(_currentHookState!);
  }

  void _unmountAllRemainingHooks() {
    if (_currentHookState != null) {
      _needDispose ??= LinkedList();
      // Mark all hooks >= this one as needing dispose
      while (_currentHookState != null) {
        final previousHookState = _currentHookState!;
        _currentHookState = _currentHookState!.next;
        previousHookState.unlink();
        _needDispose!.add(previousHookState);
      }
    }
  }
}

/// An [Element] that uses a [HookWidget] as its configuration.
@visibleForTesting
mixin HookElement on ComponentElement {
  static HookElement? _currentHookElement;

  _Entry<HookState>? _currentHookState;
  final _hooks = LinkedList<_Entry<HookState>>();
  final _shouldRebuildQueue = LinkedList<_Entry<bool Function()>>();
  LinkedList<_Entry<HookState>>? _needDispose;
  bool? _isOptionalRebuild = false;
  Widget? _buildCache;

  bool _debugIsInitHook = false;
  bool _debugDidReassemble = false;

  /// A read-only list of all available hooks.
  ///
  /// In release mode, returns `null`.
  List<HookState>? get debugHooks {
    if (!kDebugMode) {
      return null;
    }
    return [
      for (final hook in _hooks) hook.value,
    ];
  }

  @override
  void update(Widget newWidget) {
    _isOptionalRebuild = false;
    super.update(newWidget);
  }

  @override
  void didChangeDependencies() {
    _isOptionalRebuild = false;
    super.didChangeDependencies();
  }

  @override
  void reassemble() {
    super.reassemble();
    _isOptionalRebuild = false;
    _debugDidReassemble = true;
    for (final hook in _hooks) {
      hook.value.reassemble();
    }
  }

  @override
  Widget build() {
    // Check whether we can cancel the rebuild (caused by HookState.mayNeedRebuild).
    final mustRebuild = _isOptionalRebuild != true ||
        _shouldRebuildQueue.any((cb) => cb.value());

    _isOptionalRebuild = null;
    _shouldRebuildQueue.clear();

    if (!mustRebuild) {
      return _buildCache!;
    }

    if (kDebugMode) {
      _debugIsInitHook = false;
    }
    _currentHookState = _hooks.isEmpty ? null : _hooks.first;
    HookElement._currentHookElement = this;
    try {
      _buildCache = super.build();
    } finally {
      _isOptionalRebuild = null;
      _unmountAllRemainingHooks();
      HookElement._currentHookElement = null;
      if (_needDispose != null && _needDispose!.isNotEmpty) {
        for (_Entry<HookState<dynamic, Hook<dynamic>>>? toDispose =
                _needDispose!.last;
            toDispose != null;
            toDispose = toDispose.previous) {
          toDispose.value.dispose();
        }
        _needDispose = null;
      }
    }

    return _buildCache!;
  }

  R _use<R>(Hook<R> hook) {
    /// At the end of the hooks list
    if (_currentHookState == null) {
      _appendHook(hook);
    } else if (hook.runtimeType != _currentHookState!.value.hook.runtimeType) {
      final previousHookType = _currentHookState!.value.hook.runtimeType;
      _unmountAllRemainingHooks();
      if (kDebugMode && _debugDidReassemble) {
        _appendHook(hook);
      } else {
        throw StateError('''
Type mismatch between hooks:
- previous hook: $previousHookType
- new hook: ${hook.runtimeType}
''');
      }
    } else if (hook != _currentHookState!.value.hook) {
      final previousHook = _currentHookState!.value.hook;
      if (Hook.shouldPreserveState(previousHook, hook)) {
        _currentHookState!.value
          .._hook = hook
          ..didUpdateHook(previousHook);
      } else {
        _needDispose ??= LinkedList();
        _needDispose!.add(_Entry(_currentHookState!.value));
        _currentHookState!.value = _createHookState<R>(hook);
      }
    }

    final result = _currentHookState!.value.build(this) as R;
    assert(() {
      _currentHookState!.value._debugLastBuiltValue = result;
      return true;
    }(), '');
    _currentHookState = _currentHookState!.next;
    return result;
  }

  @override
  T? dependOnInheritedWidgetOfExactType<T extends InheritedWidget>({
    Object? aspect,
  }) {
    assert(
      !_debugIsInitHook,
      'Cannot listen to inherited widgets inside HookState.initState.'
      ' Use HookState.build instead',
    );
    return super.dependOnInheritedWidgetOfExactType<T>(aspect: aspect);
  }

  @override
  void unmount() {
    super.unmount();
    if (_hooks.isNotEmpty) {
      for (_Entry<HookState<dynamic, Hook<dynamic>>>? hook = _hooks.last;
          hook != null;
          hook = hook.previous) {
        try {
          hook.value.dispose();
        } catch (exception, stack) {
          FlutterError.reportError(
            FlutterErrorDetails(
              exception: exception,
              stack: stack,
              library: 'hooks library',
              context: DiagnosticsNode.message(
                'while disposing ${hook.runtimeType}',
              ),
            ),
          );
        }
      }
    }
  }

  @override
  void deactivate() {
    for (final hook in _hooks) {
      try {
        hook.value.deactivate();
      } catch (exception, stack) {
        FlutterError.reportError(
          FlutterErrorDetails(
            exception: exception,
            stack: stack,
            library: 'hooks library',
            context: DiagnosticsNode.message(
              'while deactivating ${hook.runtimeType}',
            ),
          ),
        );
      }
    }
    super.deactivate();
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    for (final hookState in debugHooks!) {
      if (hookState.debugHasShortDescription) {
        if (hookState.debugSkipValue) {
          properties.add(
            StringProperty(hookState.debugLabel!, '', ifEmpty: ''),
          );
        } else {
          properties.add(
            DiagnosticsProperty<dynamic>(
              hookState.debugLabel,
              hookState.debugValue,
            ),
          );
        }
      } else {
        properties.add(
          DiagnosticsProperty(hookState.debugLabel, hookState),
        );
      }
    }
  }
}

/// A [Widget] that can use a [Hook].
///
/// Its usage is very similar to [StatelessWidget].
/// [HookWidget] does not have any life cycle and only implements
/// the [build] method.
///
/// The difference is that it can use a [Hook], which allows a
/// [HookWidget] to store mutable data without implementing a [State].
abstract class HookWidget extends StatelessWidget {
  /// Initializes [key] for subclasses.
  const HookWidget({Key? key}) : super(key: key);

  @override
  _StatelessHookElement createElement() => _StatelessHookElement(this);
}

class _StatelessHookElement extends StatelessElement with HookElement {
  _StatelessHookElement(HookWidget hooks) : super(hooks);
}

/// A [StatefulWidget] that can use a [Hook].
///
/// Its usage is very similar to that of [StatefulWidget], but uses hooks inside [State.build].
///
/// The difference is that it can use a [Hook], which allows a
/// [HookWidget] to store mutable data without implementing a [State].
abstract class StatefulHookWidget extends StatefulWidget {
  /// Initializes [key] for subclasses.
  const StatefulHookWidget({Key? key}) : super(key: key);

  @override
  _StatefulHookElement createElement() => _StatefulHookElement(this);
}

class _StatefulHookElement extends StatefulElement with HookElement {
  _StatefulHookElement(StatefulHookWidget hooks) : super(hooks);
}

/// Obtains the [BuildContext] of the building [HookWidget].
BuildContext useContext() {
  assert(
    HookElement._currentHookElement != null,
    '`useContext` can only be called from the build method of HookWidget',
  );
  return HookElement._currentHookElement!;
}

/// A [HookWidget] that delegates its `build` to a callback.
class HookBuilder extends HookWidget {
  /// Creates a widget that delegates its build to a callback.
  ///
  /// The [builder] argument must not be null.
  const HookBuilder({
    required this.builder,
    Key? key,
  }) : super(key: key);

  /// The callback used by [HookBuilder] to create a [Widget].
  ///
  /// If a [Hook] requests a rebuild, [builder] will be called again.
  /// [builder] must not return `null`.
  final Widget Function(BuildContext context) builder;

  @override
  Widget build(BuildContext context) => builder(context);
}
