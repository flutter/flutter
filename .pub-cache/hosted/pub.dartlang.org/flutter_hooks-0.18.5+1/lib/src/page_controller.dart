part of 'hooks.dart';

/// Creates a [PageController] that will be disposed automatically.
///
/// See also:
/// - [PageController]
PageController usePageController({
  int initialPage = 0,
  bool keepPage = true,
  double viewportFraction = 1.0,
  List<Object?>? keys,
}) {
  return use(
    _PageControllerHook(
      initialPage: initialPage,
      keepPage: keepPage,
      viewportFraction: viewportFraction,
      keys: keys,
    ),
  );
}

class _PageControllerHook extends Hook<PageController> {
  const _PageControllerHook({
    required this.initialPage,
    required this.keepPage,
    required this.viewportFraction,
    List<Object?>? keys,
  }) : super(keys: keys);

  final int initialPage;
  final bool keepPage;
  final double viewportFraction;

  @override
  HookState<PageController, Hook<PageController>> createState() =>
      _PageControllerHookState();
}

class _PageControllerHookState
    extends HookState<PageController, _PageControllerHook> {
  late final controller = PageController(
    initialPage: hook.initialPage,
    keepPage: hook.keepPage,
    viewportFraction: hook.viewportFraction,
  );

  @override
  PageController build(BuildContext context) => controller;

  @override
  void dispose() => controller.dispose();

  @override
  String get debugLabel => 'usePageController';
}
