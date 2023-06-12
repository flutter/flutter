part of 'hooks.dart';

/// A callback triggered when the app life cycle changes.
typedef LifecycleCallback = FutureOr<void> Function(
  AppLifecycleState? previous,
  AppLifecycleState current,
);

/// Returns the current [AppLifecycleState] value and rebuilds the widget when it changes.
AppLifecycleState? useAppLifecycleState() {
  return use(const _AppLifecycleHook(rebuildOnChange: true));
}

/// Listens to the [AppLifecycleState].
void useOnAppLifecycleStateChange(LifecycleCallback? onStateChanged) {
  use(_AppLifecycleHook(onStateChanged: onStateChanged));
}

class _AppLifecycleHook extends Hook<AppLifecycleState?> {
  const _AppLifecycleHook({
    this.rebuildOnChange = false,
    this.onStateChanged,
  }) : super();

  final bool rebuildOnChange;
  final LifecycleCallback? onStateChanged;

  @override
  __AppLifecycleStateState createState() => __AppLifecycleStateState();
}

class __AppLifecycleStateState
    extends HookState<AppLifecycleState?, _AppLifecycleHook>
    with
        // ignore: prefer_mixin
        WidgetsBindingObserver {
  AppLifecycleState? _state;

  @override
  void initHook() {
    super.initHook();
    _state = WidgetsBinding.instance.lifecycleState;
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  AppLifecycleState? build(BuildContext context) => _state;

  @override
  void dispose() {
    super.dispose();
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final previous = _state;
    _state = state;
    hook.onStateChanged?.call(previous, state);

    if (hook.rebuildOnChange) {
      setState(() {});
    }
  }
}
