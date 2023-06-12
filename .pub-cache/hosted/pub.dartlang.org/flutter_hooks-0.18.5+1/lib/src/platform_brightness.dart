part of 'hooks.dart';

/// A callback triggered when the platform brightness changes.
typedef BrightnessCallback = FutureOr<void> Function(
  Brightness previous,
  Brightness current,
);

/// Returns the current platform [Brightness] value and rebuilds the widget when it changes.
Brightness usePlatformBrightness() {
  return use(const _PlatformBrightnessHook(rebuildOnChange: true));
}

/// Listens to the platform [Brightness].
void useOnPlatformBrightnessChange(BrightnessCallback onBrightnessChange) {
  return use(_PlatformBrightnessHook(onBrightnessChange: onBrightnessChange));
}

class _PlatformBrightnessHook extends Hook<Brightness> {
  const _PlatformBrightnessHook({
    this.rebuildOnChange = false,
    this.onBrightnessChange,
  }) : super();

  final bool rebuildOnChange;
  final BrightnessCallback? onBrightnessChange;

  @override
  _PlatformBrightnessState createState() => _PlatformBrightnessState();
}

class _PlatformBrightnessState
    extends HookState<Brightness, _PlatformBrightnessHook>
    with
        // ignore: prefer_mixin
        WidgetsBindingObserver {
  late Brightness _brightness;

  @override
  String? get debugLabel => 'usePlatformBrightness';

  @override
  void initHook() {
    super.initHook();
    _brightness = WidgetsBinding.instance.window.platformBrightness;
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  Brightness build(BuildContext context) => _brightness;

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangePlatformBrightness() {
    super.didChangePlatformBrightness();
    final _previous = _brightness;
    _brightness = WidgetsBinding.instance.window.platformBrightness;
    hook.onBrightnessChange?.call(_previous, _brightness);

    if (hook.rebuildOnChange) {
      setState(() {});
    }
  }
}
