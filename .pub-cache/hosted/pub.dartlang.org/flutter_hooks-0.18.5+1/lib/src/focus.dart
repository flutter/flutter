part of 'hooks.dart';

/// Creates an automatically disposed [FocusNode].
///
/// See also:
/// - [FocusNode]
FocusNode useFocusNode({
  String? debugLabel,
  FocusOnKeyCallback? onKey,
  FocusOnKeyEventCallback? onKeyEvent,
  bool skipTraversal = false,
  bool canRequestFocus = true,
  bool descendantsAreFocusable = true,
}) {
  return use(
    _FocusNodeHook(
      debugLabel: debugLabel,
      onKey: onKey,
      onKeyEvent: onKeyEvent,
      skipTraversal: skipTraversal,
      canRequestFocus: canRequestFocus,
      descendantsAreFocusable: descendantsAreFocusable,
    ),
  );
}

class _FocusNodeHook extends Hook<FocusNode> {
  const _FocusNodeHook({
    this.debugLabel,
    this.onKey,
    this.onKeyEvent,
    required this.skipTraversal,
    required this.canRequestFocus,
    required this.descendantsAreFocusable,
  });

  final String? debugLabel;
  final FocusOnKeyCallback? onKey;
  final FocusOnKeyEventCallback? onKeyEvent;
  final bool skipTraversal;
  final bool canRequestFocus;
  final bool descendantsAreFocusable;

  @override
  _FocusNodeHookState createState() {
    return _FocusNodeHookState();
  }
}

class _FocusNodeHookState extends HookState<FocusNode, _FocusNodeHook> {
  late final FocusNode _focusNode = FocusNode(
    debugLabel: hook.debugLabel,
    onKey: hook.onKey,
    onKeyEvent: hook.onKeyEvent,
    skipTraversal: hook.skipTraversal,
    canRequestFocus: hook.canRequestFocus,
    descendantsAreFocusable: hook.descendantsAreFocusable,
  );

  @override
  void didUpdateHook(_FocusNodeHook oldHook) {
    _focusNode
      ..debugLabel = hook.debugLabel
      ..skipTraversal = hook.skipTraversal
      ..canRequestFocus = hook.canRequestFocus
      ..descendantsAreFocusable = hook.descendantsAreFocusable
      ..onKey = hook.onKey
      ..onKeyEvent = hook.onKeyEvent;
  }

  @override
  FocusNode build(BuildContext context) => _focusNode;

  @override
  void dispose() => _focusNode.dispose();

  @override
  String get debugLabel => 'useFocusNode';
}
