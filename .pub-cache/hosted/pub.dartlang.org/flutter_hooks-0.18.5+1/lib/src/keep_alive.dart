part of 'hooks.dart';

/// Mark a widget using this hook as needing to stay alive even when it's in a
/// lazy list that would otherwise remove it.
///
/// See also:
/// - [AutomaticKeepAlive]
/// - [KeepAlive]
void useAutomaticKeepAlive({
  bool wantKeepAlive = true,
}) {
  use(_AutomaticKeepAliveHook(
    wantKeepAlive: wantKeepAlive,
  ));
}

class _AutomaticKeepAliveHook extends Hook<void> {
  const _AutomaticKeepAliveHook({required this.wantKeepAlive});

  final bool wantKeepAlive;

  @override
  HookState<void, _AutomaticKeepAliveHook> createState() =>
      _AutomaticKeepAliveHookState();
}

class _AutomaticKeepAliveHookState
    extends HookState<void, _AutomaticKeepAliveHook> {
  KeepAliveHandle? _keepAliveHandle;

  void _ensureKeepAlive() {
    _keepAliveHandle = KeepAliveHandle();
    KeepAliveNotification(_keepAliveHandle!).dispatch(context);
  }

  void _releaseKeepAlive() {
    _keepAliveHandle?.release();
    _keepAliveHandle = null;
  }

  @override
  void initHook() {
    super.initHook();

    if (hook.wantKeepAlive) {
      _ensureKeepAlive();
    }
  }

  @override
  void build(BuildContext context) {
    if (hook.wantKeepAlive && _keepAliveHandle == null) {
      _ensureKeepAlive();
    }
  }

  @override
  void deactivate() {
    if (_keepAliveHandle != null) {
      _releaseKeepAlive();
    }
    super.deactivate();
  }

  @override
  Object? get debugValue => _keepAliveHandle;

  @override
  String get debugLabel => 'useAutomaticKeepAlive';
}
