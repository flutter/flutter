import 'package:flutter/widgets.dart';

typedef ContextMenuChangedCallback = void Function(bool isOpen, [dynamic value]);

@immutable
/// TODO
abstract class ActionBase {
  /// TODO
  Future<void> execute(BuildContext context);
}

/// TODO
class Action implements ActionBase {
  /// TODO
  Action({
    @required Future<void> Function(BuildContext) callback,
  }) : assert(callback != null),
       _callback = callback;

  final Future<void> Function(BuildContext) _callback;

  @override
  Future<void> execute(BuildContext context) {
    return _callback(context);
  }
}

/// TODO
/// "Content" is widget-dependent and platform-neutral.
@immutable
class ContextMenuContent {
  /// TODO
  const ContextMenuContent({
    @required this.entries,
  }) : assert(entries != null);

  /// TODO
  final List<ContextMenuEntry> entries;
}

/// TODO
/// "Entry" is platform-neutral and widget-neutral.
abstract class ContextMenuEntry {
  /// TODO
  ActionBase get value;
}

/// TODO
class ContextMenuItem implements ContextMenuEntry {
  /// TODO
  ContextMenuItem({
    @required ActionBase action,
    @required this.text,
    this.enabled = true,
  })
    : assert(action != null),
      assert(text != null),
      _action = action;

  /// TODO
  final ActionBase _action;
  @override
  ActionBase get value => _action;

  /// TODO
  final String text;

  /// TODO
  final bool enabled;
}

/// TODO
class ContextMenuDivider implements ContextMenuEntry {

  @override
  ActionBase get value => null;
}

/// TODO
class ContextMenuSubmenu implements ContextMenuEntry {
  /// TODO
  ContextMenuSubmenu({
    @required this.children,
    @required this.text,
  })
    : assert(children != null);

  /// TODO
  final List<ContextMenuEntry> children;

  @override
  ActionBase get value => null;

  /// TODO
  final String text;
}

/// TODO
/// "Render" is platform-dependent and widget-neutral.
abstract class RenderContextMenu {
  /// TODO
  Future<Action> showMenu({
    @required ContextMenuContent content,
    @required Offset globalPosition,
    @required BuildContext context,
  });
}
