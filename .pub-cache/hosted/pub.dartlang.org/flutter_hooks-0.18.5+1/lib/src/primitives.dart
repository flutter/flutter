part of 'hooks.dart';

/// A class that stores a single value.
///
/// It is typically created by [useRef].
class ObjectRef<T> {
  /// A class that stores a single value.
  ///
  /// It is typically created by [useRef].
  ObjectRef(this.value);

  /// A mutable property that will be preserved across rebuilds.
  ///
  /// Updating this property will not cause widgets to rebuild.
  T value;
}

/// Creates an object that contains a single mutable property.
///
/// Mutating the object's property has no effect.
/// This is useful for sharing state across `build` calls, without causing
/// unnecessary rebuilds.
ObjectRef<T> useRef<T>(T initialValue) {
  return useMemoized(() => ObjectRef<T>(initialValue));
}

/// Cache a function across rebuilds based on a list of keys.
///
/// This is syntax sugar for [useMemoized], so that instead of:
///
/// ```dart
/// final cachedFunction = useMemoized(() => () {
///   print('doSomething');
/// }, [key]);
/// ```
///
/// we can directly do:
///
/// ```dart
/// final cachedFunction = useCallback(() {
///   print('doSomething');
/// }, [key]);
/// ```
T useCallback<T extends Function>(
  T callback,
  List<Object?> keys,
) {
  return useMemoized(() => callback, keys);
}

/// Caches the instance of a complex object.
///
/// [useMemoized] will immediately call [valueBuilder] on first call and store its result.
/// Later, when the [HookWidget] rebuilds, the call to [useMemoized] will return the previously created instance without calling [valueBuilder].
///
/// A subsequent call of [useMemoized] with different [keys] will call [useMemoized] again to create a new instance.
T useMemoized<T>(
  T Function() valueBuilder, [
  List<Object?> keys = const <Object>[],
]) {
  return use(
    _MemoizedHook(
      valueBuilder,
      keys: keys,
    ),
  );
}

class _MemoizedHook<T> extends Hook<T> {
  const _MemoizedHook(
    this.valueBuilder, {
    required List<Object?> keys,
  }) : super(keys: keys);

  final T Function() valueBuilder;

  @override
  _MemoizedHookState<T> createState() => _MemoizedHookState<T>();
}

class _MemoizedHookState<T> extends HookState<T, _MemoizedHook<T>> {
  late final T value = hook.valueBuilder();

  @override
  T build(BuildContext context) {
    return value;
  }

  @override
  String get debugLabel => 'useMemoized<$T>';
}

/// Watches a value and triggers a callback whenever the value changed.
///
/// [useValueChanged] takes a [valueChange] callback and calls it whenever [value] changed.
/// [valueChange] will _not_ be called on the first [useValueChanged] call.
///
/// [useValueChanged] can also be used to interpolate
/// Whenever [useValueChanged] is called with a different [value], calls [valueChange].
/// The value returned by [useValueChanged] is the latest returned value of [valueChange] or `null`.
///
/// The following example calls [AnimationController.forward] whenever `color` changes
///
/// ```dart
/// AnimationController controller;
/// Color color;
///
/// useValueChanged(color, (_, __) {
///   controller.forward();
/// });
/// ```
R? useValueChanged<T, R>(
  T value,
  R? Function(T oldValue, R? oldResult) valueChange,
) {
  return use(_ValueChangedHook(value, valueChange));
}

class _ValueChangedHook<T, R> extends Hook<R?> {
  const _ValueChangedHook(this.value, this.valueChanged);

  final R? Function(T oldValue, R? oldResult) valueChanged;
  final T value;

  @override
  _ValueChangedHookState<T, R> createState() => _ValueChangedHookState<T, R>();
}

class _ValueChangedHookState<T, R>
    extends HookState<R?, _ValueChangedHook<T, R>> {
  R? _result;

  @override
  void didUpdateHook(_ValueChangedHook<T, R> oldHook) {
    super.didUpdateHook(oldHook);
    if (hook.value != oldHook.value) {
      _result = hook.valueChanged(oldHook.value, _result);
    }
  }

  @override
  R? build(BuildContext context) {
    return _result;
  }

  @override
  String get debugLabel => 'useValueChanged';

  @override
  bool get debugHasShortDescription => false;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty('value', hook.value));
    properties.add(DiagnosticsProperty('result', _result));
  }
}

/// A function called when the state of a widget is destroyed.
typedef Dispose = void Function();

/// Useful for side-effects and optionally canceling them.
///
/// [useEffect] is called synchronously on every `build`, unless
/// [keys] is specified. In which case [useEffect] is called again only if
/// any value inside [keys] as changed.
///
/// It takes an [effect] callback and calls it synchronously.
/// That [effect] may optionally return a function, which will be called when the [effect] is called again or if the widget is disposed.
///
/// By default [effect] is called on every `build` call, unless [keys] is specified.
/// In which case, [effect] is called once on the first [useEffect] call and whenever something within [keys] change/
///
/// The following example call [useEffect] to subscribes to a [Stream] and cancels the subscription when the widget is disposed.
/// Also if the [Stream] changes, it will cancel the listening on the previous [Stream] and listen to the new one.
///
/// ```dart
/// Stream stream;
/// useEffect(() {
///     final subscription = stream.listen(print);
///     // This will cancel the subscription when the widget is disposed
///     // or if the callback is called again.
///     return subscription.cancel;
///   },
///   // when the stream changes, useEffect will call the callback again.
///   [stream],
/// );
/// ```
void useEffect(Dispose? Function() effect, [List<Object?>? keys]) {
  use(_EffectHook(effect, keys));
}

class _EffectHook extends Hook<void> {
  const _EffectHook(this.effect, [List<Object?>? keys]) : super(keys: keys);

  final Dispose? Function() effect;

  @override
  _EffectHookState createState() => _EffectHookState();
}

class _EffectHookState extends HookState<void, _EffectHook> {
  Dispose? disposer;

  @override
  void initHook() {
    super.initHook();
    scheduleEffect();
  }

  @override
  void didUpdateHook(_EffectHook oldHook) {
    super.didUpdateHook(oldHook);

    if (hook.keys == null) {
      disposer?.call();
      scheduleEffect();
    }
  }

  @override
  void build(BuildContext context) {}

  @override
  void dispose() => disposer?.call();

  void scheduleEffect() {
    disposer = hook.effect();
  }

  @override
  String get debugLabel => 'useEffect';

  @override
  bool get debugSkipValue => true;
}

/// Creates a variable and subscribes to it.
///
/// Whenever [ValueNotifier.value] updates, it will mark the caller [HookWidget]
/// as needing a build.
/// On the first call, it initializes [ValueNotifier] to [initialData]. [initialData] is ignored
/// on subsequent calls.
///
/// The following example showcases a basic counter application:
///
/// ```dart
/// class Counter extends HookWidget {
///   @override
///   Widget build(BuildContext context) {
///     final counter = useState(0);
///
///     return GestureDetector(
///       // automatically triggers a rebuild of the Counter widget
///       onTap: () => counter.value++,
///       child: Text(counter.value.toString()),
///     );
///   }
/// }
/// ```
///
/// See also:
///
///  * [ValueNotifier]
///  * [useStreamController], an alternative to [ValueNotifier] for state.
ValueNotifier<T> useState<T>(T initialData) {
  return use(_StateHook(initialData: initialData));
}

class _StateHook<T> extends Hook<ValueNotifier<T>> {
  const _StateHook({required this.initialData});

  final T initialData;

  @override
  _StateHookState<T> createState() => _StateHookState();
}

class _StateHookState<T> extends HookState<ValueNotifier<T>, _StateHook<T>> {
  late final _state = ValueNotifier<T>(hook.initialData)
    ..addListener(_listener);

  @override
  void dispose() {
    _state.dispose();
  }

  @override
  ValueNotifier<T> build(BuildContext context) => _state;

  void _listener() {
    setState(() {});
  }

  @override
  Object? get debugValue => _state.value;

  @override
  String get debugLabel => 'useState<$T>';
}
