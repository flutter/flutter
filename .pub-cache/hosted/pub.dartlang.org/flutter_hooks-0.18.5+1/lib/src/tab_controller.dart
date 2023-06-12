part of 'hooks.dart';

/// Creates a [TabController] that will be disposed automatically.
///
/// See also:
/// - [TabController]
TabController useTabController({
  required int initialLength,
  TickerProvider? vsync,
  int initialIndex = 0,
  List<Object?>? keys,
}) {
  vsync ??= useSingleTickerProvider(keys: keys);

  return use(
    _TabControllerHook(
      vsync: vsync,
      length: initialLength,
      initialIndex: initialIndex,
      keys: keys,
    ),
  );
}

class _TabControllerHook extends Hook<TabController> {
  const _TabControllerHook({
    required this.length,
    required this.vsync,
    required this.initialIndex,
    List<Object?>? keys,
  }) : super(keys: keys);

  final int length;
  final TickerProvider vsync;
  final int initialIndex;

  @override
  HookState<TabController, Hook<TabController>> createState() =>
      _TabControllerHookState();
}

class _TabControllerHookState
    extends HookState<TabController, _TabControllerHook> {
  late final controller = TabController(
    length: hook.length,
    initialIndex: hook.initialIndex,
    vsync: hook.vsync,
  );

  @override
  TabController build(BuildContext context) => controller;

  @override
  void dispose() => controller.dispose();

  @override
  String get debugLabel => 'useTabController';
}
