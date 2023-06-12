part of 'hooks.dart';

/// Creates and disposes a [TransformationController].
///
/// See also:
/// - [TransformationController]
TransformationController useTransformationController({
  Matrix4? initialValue,
  List<Object?>? keys,
}) {
  return use(
    _TransformationControllerHook(
      initialValue: initialValue,
      keys: keys,
    ),
  );
}

class _TransformationControllerHook extends Hook<TransformationController> {
  const _TransformationControllerHook({
    required this.initialValue,
    List<Object?>? keys,
  }) : super(keys: keys);

  final Matrix4? initialValue;

  @override
  HookState<TransformationController, Hook<TransformationController>>
      createState() => _TransformationControllerHookState();
}

class _TransformationControllerHookState
    extends HookState<TransformationController, _TransformationControllerHook> {
  late final controller = TransformationController(hook.initialValue);

  @override
  TransformationController build(BuildContext context) => controller;

  @override
  void dispose() => controller.dispose();

  @override
  String get debugLabel => 'useTransformationController';
}
