part of 'hooks.dart';

/// Rebuild only when there is a change in the selector result.
///
/// The following example showcases If no text is entered, you will not be able to press the button.
/// ```dart
/// class Example extends HookWidget {
///   @override
///   Widget build(BuildContext context) {
///    final listenable = useTextEditingController();
///    final bool textIsEmpty =
///         useListenableSelector(listenable, () => listenable.text.isEmpty);
///    return Column(
///       children: [
///         TextField(controller: listenable),
///         ElevatedButton(
///             // If no text is entered, the button cannot be pressed
///             onPressed: textIsEmpty ? null : () => print("Button can be pressed!"),
///             child: Text("Button")),
///       ],
///     );
///   }
/// }
/// ```
///

R useListenableSelector<R>(
  Listenable listenable,
  R Function() selector,
) {
  return use(_ListenableSelectorHook(listenable, selector));
}

class _ListenableSelectorHook<R> extends Hook<R> {
  const _ListenableSelectorHook(this.listenable, this.selector);

  final Listenable listenable;
  final R Function() selector;

  @override
  _ListenableSelectorHookState<R> createState() =>
      _ListenableSelectorHookState<R>();
}

class _ListenableSelectorHookState<R>
    extends HookState<R, _ListenableSelectorHook<R>> {
  late R _selectorResult = hook.selector();

  @override
  void initHook() {
    super.initHook();
    hook.listenable.addListener(_listener);
  }

  @override
  void didUpdateHook(_ListenableSelectorHook<R> oldHook) {
    super.didUpdateHook(oldHook);

    if (hook.selector != oldHook.selector) {
      setState(() {
        _selectorResult = hook.selector();
      });
    }

    if (hook.listenable != oldHook.listenable) {
      oldHook.listenable.removeListener(_listener);
      hook.listenable.addListener(_listener);
      _selectorResult = hook.selector();
    }
  }

  @override
  R build(BuildContext context) => _selectorResult;

  void _listener() {
    final latestSelectorResult = hook.selector();
    if (_selectorResult != latestSelectorResult) {
      setState(() {
        _selectorResult = latestSelectorResult;
      });
    }
  }

  @override
  void dispose() {
    hook.listenable.removeListener(_listener);
  }

  @override
  String get debugLabel => 'useListenableSelector<$R>';

  @override
  bool get debugSkipValue => true;
}
