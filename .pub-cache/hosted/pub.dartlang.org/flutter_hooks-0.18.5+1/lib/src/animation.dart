part of 'hooks.dart';

/// Subscribes to an [Animation] and returns its value.
///
/// See also:
///   * [Animation]
///   * [useValueListenable], [useListenable], [useStream]
T useAnimation<T>(Animation<T> animation) {
  use(_UseAnimationHook(animation));
  return animation.value;
}

class _UseAnimationHook extends _ListenableHook {
  const _UseAnimationHook(Animation animation) : super(animation);

  @override
  _UseAnimationStateHook createState() {
    return _UseAnimationStateHook();
  }
}

class _UseAnimationStateHook extends _ListenableStateHook {
  @override
  String get debugLabel => 'useAnimation';

  @override
  Object? get debugValue => (hook.listenable as Animation?)?.value;
}

/// Creates an [AnimationController] and automatically disposes it when necessary.
///
/// If no [vsync] is provided, the [TickerProvider] is implicitly obtained using [useSingleTickerProvider].
/// If a [vsync] is specified, changing the instance of [vsync] will result in a call to [AnimationController.resync].
/// It is not possible to switch between implicit and explicit [vsync].
///
/// Changing the [duration] parameter automatically updates the [AnimationController.duration].
///
/// [initialValue], [lowerBound], [upperBound] and [debugLabel] are ignored after the first call.
///
/// See also:
///   * [AnimationController], the created object.
///   * [useAnimation], to listen to the created [AnimationController].
AnimationController useAnimationController({
  Duration? duration,
  Duration? reverseDuration,
  String? debugLabel,
  double initialValue = 0,
  double lowerBound = 0,
  double upperBound = 1,
  TickerProvider? vsync,
  AnimationBehavior animationBehavior = AnimationBehavior.normal,
  List<Object?>? keys,
}) {
  vsync ??= useSingleTickerProvider(keys: keys);

  return use(
    _AnimationControllerHook(
      duration: duration,
      reverseDuration: reverseDuration,
      debugLabel: debugLabel,
      initialValue: initialValue,
      lowerBound: lowerBound,
      upperBound: upperBound,
      vsync: vsync,
      animationBehavior: animationBehavior,
      keys: keys,
    ),
  );
}

class _AnimationControllerHook extends Hook<AnimationController> {
  const _AnimationControllerHook({
    this.duration,
    this.reverseDuration,
    this.debugLabel,
    required this.initialValue,
    required this.lowerBound,
    required this.upperBound,
    required this.vsync,
    required this.animationBehavior,
    List<Object?>? keys,
  }) : super(keys: keys);

  final Duration? duration;
  final Duration? reverseDuration;
  final String? debugLabel;
  final double initialValue;
  final double lowerBound;
  final double upperBound;
  final TickerProvider vsync;
  final AnimationBehavior animationBehavior;

  @override
  _AnimationControllerHookState createState() =>
      _AnimationControllerHookState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty('duration', duration));
    properties.add(DiagnosticsProperty('reverseDuration', reverseDuration));
  }
}

class _AnimationControllerHookState
    extends HookState<AnimationController, _AnimationControllerHook> {
  late final AnimationController _animationController = AnimationController(
    vsync: hook.vsync,
    duration: hook.duration,
    reverseDuration: hook.reverseDuration,
    debugLabel: hook.debugLabel,
    lowerBound: hook.lowerBound,
    upperBound: hook.upperBound,
    animationBehavior: hook.animationBehavior,
    value: hook.initialValue,
  );

  @override
  void didUpdateHook(_AnimationControllerHook oldHook) {
    super.didUpdateHook(oldHook);
    if (hook.vsync != oldHook.vsync) {
      _animationController.resync(hook.vsync);
    }

    if (hook.duration != oldHook.duration) {
      _animationController.duration = hook.duration;
    }

    if (hook.reverseDuration != oldHook.reverseDuration) {
      _animationController.reverseDuration = hook.reverseDuration;
    }
  }

  @override
  AnimationController build(BuildContext context) {
    return _animationController;
  }

  @override
  void dispose() {
    _animationController.dispose();
  }

  @override
  bool get debugHasShortDescription => false;

  @override
  String get debugLabel => 'useAnimationController';
}

/// Creates a single usage [TickerProvider].
///
/// See also:
///  * [SingleTickerProviderStateMixin]
TickerProvider useSingleTickerProvider({List<Object?>? keys}) {
  return use(
    keys != null
        ? _SingleTickerProviderHook(keys)
        : const _SingleTickerProviderHook(),
  );
}

class _SingleTickerProviderHook extends Hook<TickerProvider> {
  const _SingleTickerProviderHook([List<Object?>? keys]) : super(keys: keys);

  @override
  _TickerProviderHookState createState() => _TickerProviderHookState();
}

class _TickerProviderHookState
    extends HookState<TickerProvider, _SingleTickerProviderHook>
    implements TickerProvider {
  Ticker? _ticker;

  @override
  Ticker createTicker(TickerCallback onTick) {
    assert(() {
      if (_ticker == null) {
        return true;
      }
      throw FlutterError(
          '${context.widget.runtimeType} attempted to use a useSingleTickerProvider multiple times.\n'
          'A SingleTickerProviderStateMixin can only be used as a TickerProvider once. '
          'If you need multiple Ticker, consider using useSingleTickerProvider multiple times '
          'to create as many Tickers as needed.');
    }(), '');
    return _ticker = Ticker(onTick, debugLabel: 'created by $context');
  }

  @override
  void dispose() {
    assert(() {
      if (_ticker == null || !_ticker!.isActive) {
        return true;
      }
      throw FlutterError(
          'useSingleTickerProvider created a Ticker, but at the time '
          'dispose() was called on the Hook, that Ticker was still active. Tickers used '
          ' by AnimationControllers should be disposed by calling dispose() on '
          ' the AnimationController itself. Otherwise, the ticker will leak.\n');
    }(), '');
  }

  @override
  TickerProvider build(BuildContext context) {
    if (_ticker != null) {
      _ticker!.muted = !TickerMode.of(context);
    }
    return this;
  }

  @override
  String get debugLabel => 'useSingleTickerProvider';

  @override
  bool get debugSkipValue => true;
}
