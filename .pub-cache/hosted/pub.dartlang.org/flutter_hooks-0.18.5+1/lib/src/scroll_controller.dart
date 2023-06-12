part of 'hooks.dart';

/// Creates [ScrollController] that will be disposed automatically.
///
/// See also:
/// - [ScrollController]
ScrollController useScrollController({
  double initialScrollOffset = 0.0,
  bool keepScrollOffset = true,
  String? debugLabel,
  List<Object?>? keys,
}) {
  return use(
    _ScrollControllerHook(
      initialScrollOffset: initialScrollOffset,
      keepScrollOffset: keepScrollOffset,
      debugLabel: debugLabel,
      keys: keys,
    ),
  );
}

class _ScrollControllerHook extends Hook<ScrollController> {
  const _ScrollControllerHook({
    required this.initialScrollOffset,
    required this.keepScrollOffset,
    this.debugLabel,
    List<Object?>? keys,
  }) : super(keys: keys);

  final double initialScrollOffset;
  final bool keepScrollOffset;
  final String? debugLabel;

  @override
  HookState<ScrollController, Hook<ScrollController>> createState() =>
      _ScrollControllerHookState();
}

class _ScrollControllerHookState
    extends HookState<ScrollController, _ScrollControllerHook> {
  late final controller = ScrollController(
    initialScrollOffset: hook.initialScrollOffset,
    keepScrollOffset: hook.keepScrollOffset,
    debugLabel: hook.debugLabel,
  );

  @override
  ScrollController build(BuildContext context) => controller;

  @override
  void dispose() => controller.dispose();

  @override
  String get debugLabel => 'useScrollController';
}
